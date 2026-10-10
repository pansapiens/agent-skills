"""Shared helpers for the M3 weather report: SLURM parsing, hostlists and the day cache.

The M3 slurmdbd silently returns an empty result set -- exit 0, no error, no
warning -- for sacct queries above some size it does not disclose. Measured
2026-08-29: a cluster-wide 8-day query returned 168,639 rows and a 9-day one
returned nothing, while a 3-day query returned 214,569 wider rows successfully,
so it is neither a clean row count nor a clean day count. Scoping to one user or
partition lifts it entirely -- 30 days of a single user's history comes back
fine, and the database holds at least two years.

Every query here is therefore chunked into single calendar days, which is well
inside the limit however busy the cluster gets. Days in the past are immutable and
cached as Parquet; a day is refetched only while its cached copy predates the end
of that day.
"""

import os
import re
import sys
import glob
import html
import json
import logging
import subprocess
import urllib.request
from typing import Iterator, Optional
from datetime import datetime, timedelta, date

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)

# Job-level fields come from the allocation row; MaxRSS/TotalCPU only exist on steps.
SACCT_FIELDS = [
    "JobIDRaw", "JobID", "User", "Account", "Partition", "QOS", "State",
    "Submit", "Eligible", "Start", "End", "ElapsedRaw", "TimelimitRaw",
    "NNodes", "NCPUS", "ReqTRES", "AllocTRES", "TotalCPU", "CPUTimeRaw",
    "MaxRSS", "JobName", "ExitCode", "NodeList", "Priority", "WorkDir",
]

CACHE_VERSION = 5


# --------------------------------------------------------------------------- #
# hostlist
# --------------------------------------------------------------------------- #

_RANGE_RE = re.compile(r"^([^\[]*)\[([^\]]+)\](.*)$")


def expand_hostlist(hostlist: str) -> list[str]:
    """Expand a SLURM compressed hostlist, e.g. 'm3d[100-102],m3e100'.

    Written out rather than shelling to `scontrol show hostnames` because the
    reports expand tens of thousands of node lists per period.
    """
    if not hostlist or hostlist in ("None assigned", "None", "(null)"):
        return []

    # Split on commas that are not inside brackets.
    parts, depth, current = [], 0, ""
    for ch in hostlist:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += ch
    if current:
        parts.append(current)

    out = []
    for part in parts:
        m = _RANGE_RE.match(part)
        if not m:
            out.append(part)
            continue
        prefix, body, suffix = m.groups()
        for item in body.split(","):
            if "-" in item:
                lo, hi = item.split("-", 1)
                width = len(lo)
                for n in range(int(lo), int(hi) + 1):
                    out.extend(expand_hostlist(f"{prefix}{n:0{width}d}{suffix}"))
            else:
                out.extend(expand_hostlist(f"{prefix}{item}{suffix}"))
    return out


# --------------------------------------------------------------------------- #
# field parsing
# --------------------------------------------------------------------------- #

def parse_slurm_time(value: str) -> Optional[datetime]:
    if not value or value in ("Unknown", "None", "N/A"):
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%dT%H:%M:%S")
    except ValueError:
        return None


def parse_cpu_time(value: str) -> float:
    """Parse a SLURM elapsed/TotalCPU string into seconds.

    Handles 'DD-HH:MM:SS', 'HH:MM:SS', 'MM:SS.mmm' and 'SS.mmm'.
    """
    if not value or value in ("Unknown", "INVALID", ""):
        return 0.0
    days = 0
    if "-" in value:
        d, value = value.split("-", 1)
        days = int(d)
    bits = value.split(":")
    try:
        nums = [float(b) for b in bits]
    except ValueError:
        return 0.0
    if len(nums) == 3:
        h, m, s = nums
    elif len(nums) == 2:
        h, m, s = 0, nums[0], nums[1]
    else:
        h, m, s = 0, 0, nums[0]
    return days * 86400 + h * 3600 + m * 60 + s


def parse_tres(value: str) -> dict[str, float]:
    """Parse 'billing=13,cpu=13,gres/gpu=1,mem=240000M,node=1' into a dict.

    Memory is normalised to MB.
    """
    out: dict[str, float] = {}
    if not value:
        return out
    for item in value.split(","):
        if "=" not in item:
            continue
        k, v = item.split("=", 1)
        if k == "mem":
            out["mem_mb"] = _parse_mem(v)
        else:
            try:
                out[k] = float(v)
            except ValueError:
                pass
    return out


_MEM_UNITS = {"K": 1 / 1024, "M": 1, "G": 1024, "T": 1024 * 1024, "": 1}


def _parse_mem(value: str) -> float:
    if not value:
        return 0.0
    value = value.strip().rstrip("n")  # trailing 'n' = per-node in ReqMem
    m = re.match(r"^([\d.]+)\s*([KMGTkmgt]?)", value)
    if not m:
        return 0.0
    return float(m.group(1)) * _MEM_UNITS[m.group(2).upper()]


CANCELLED_RE = re.compile(r"^CANCELLED by (\d+)$")


def normalise_state(state: str) -> tuple[str, Optional[int]]:
    """'CANCELLED by 16115' -> ('CANCELLED', 16115). Other states pass through."""
    m = CANCELLED_RE.match(state or "")
    if m:
        return "CANCELLED", int(m.group(1))
    return (state or "UNKNOWN").split()[0] if state else "UNKNOWN", None


# --------------------------------------------------------------------------- #
# sacct collection
# --------------------------------------------------------------------------- #

def run_sacct(start: datetime, end: datetime, extra: Optional[list[str]] = None) -> str:
    cmd = [
        "sacct", "-a", "-P", "-n", "--units=M",
        "-S", start.strftime("%Y-%m-%dT%H:%M:%S"),
        "-E", end.strftime("%Y-%m-%dT%H:%M:%S"),
        "-o", ",".join(SACCT_FIELDS),
    ] + (extra or [])
    logger.info("sacct %s -> %s", start.date(), end.date())
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
    if res.returncode != 0:
        raise RuntimeError(f"sacct failed: {res.stderr.strip()}")
    return res.stdout


def _raw_rows(text: str) -> Iterator[list[str]]:
    n = len(SACCT_FIELDS)
    for line in text.splitlines():
        if not line:
            continue
        bits = line.split("|")
        if len(bits) == n:
            yield bits


def collect_day(day: date) -> pd.DataFrame:
    """Fetch every job overlapping `day` and reduce step rows into job rows.

    A job that spans several days appears in each day's frame; deduplicate on
    job_id when combining. `overlap_s` is the seconds the job ran within `day`,
    which is what utilisation should be computed from.
    """
    start = datetime.combine(day, datetime.min.time())
    end = start + timedelta(days=1)
    text = run_sacct(start, end)

    jobs: dict[str, dict] = {}
    step_cpu: dict[str, float] = {}
    step_rss: dict[str, float] = {}
    step_nodes: dict[str, set] = {}

    for r in _raw_rows(text):
        rec = dict(zip(SACCT_FIELDS, r))
        job_id = rec["JobID"]

        if "." in job_id:
            # Step row: only useful for the resource-usage counters.
            base, step = job_id.split(".", 1)
            if step != "extern":
                step_cpu[base] = step_cpu.get(base, 0.0) + parse_cpu_time(rec["TotalCPU"])
                # extern spans every allocated node by construction, so only
                # real steps say which nodes the job actually used.
                step_nodes.setdefault(base, set()).update(expand_hostlist(rec["NodeList"]))
            if rec["MaxRSS"]:
                step_rss[base] = max(step_rss.get(base, 0.0), _parse_mem(rec["MaxRSS"]))
            continue

        state, cancelled_by = normalise_state(rec["State"])
        alloc = parse_tres(rec["AllocTRES"])
        req = parse_tres(rec["ReqTRES"])
        submit = parse_slurm_time(rec["Submit"])
        st = parse_slurm_time(rec["Start"])
        en = parse_slurm_time(rec["End"])

        # Seconds of this job that fall inside the day being cached.
        overlap = 0.0
        if st is not None:
            eff_end = en or end
            overlap = max(0.0, (min(eff_end, end) - max(st, start)).total_seconds())

        jobs[job_id] = {
            "job_id": job_id,
            "array_job": "_" in job_id,
            "user": rec["User"],
            "account": rec["Account"],
            "partition": rec["Partition"],
            "qos": rec["QOS"],
            "state": state,
            "cancelled_by_uid": cancelled_by,
            "submit": submit,
            "eligible": parse_slurm_time(rec["Eligible"]),
            "start": st,
            "end": en,
            "elapsed_s": float(rec["ElapsedRaw"] or 0),
            "timelimit_s": float(rec["TimelimitRaw"] or 0) * 60,
            "overlap_s": overlap,
            "nnodes": int(float(rec["NNodes"] or 0)),
            "ncpus": int(float(rec["NCPUS"] or 0)),
            "req_cpus": int(req.get("cpu", 0)),
            "req_mem_mb": req.get("mem_mb", 0.0),
            "alloc_mem_mb": alloc.get("mem_mb", 0.0),
            "ngpus": int(alloc.get("gres/gpu", req.get("gres/gpu", 0))),
            "billing": alloc.get("billing", 0.0),
            "cpu_time_s": float(rec["CPUTimeRaw"] or 0),
            "job_name": rec["JobName"],
            "exit_code": rec["ExitCode"],
            "nodelist": rec["NodeList"],
            "priority": float(rec["Priority"] or 0),
            "workdir": rec["WorkDir"],
        }

    for job_id, rec in jobs.items():
        rec["total_cpu_s"] = step_cpu.get(job_id, 0.0)
        rec["max_rss_mb"] = step_rss.get(job_id, np.nan)
        rec["active_nodes"] = float(len(step_nodes[job_id])) if step_nodes.get(job_id) else np.nan

    df = pd.DataFrame(list(jobs.values()))
    if df.empty:
        return df
    df["day"] = pd.Timestamp(day)
    return _derive(df)


def _derive(df: pd.DataFrame) -> pd.DataFrame:
    """Add the efficiency and timing columns every report wants."""
    df = df.copy()
    df["wait_s"] = (df["start"] - df["submit"]).dt.total_seconds()
    df.loc[df["wait_s"] < 0, "wait_s"] = np.nan

    # CPU efficiency: actual CPU seconds burnt vs core-seconds held.
    held = df["elapsed_s"] * df["ncpus"]
    df["cpu_eff"] = np.where(held > 0, df["total_cpu_s"] / held, np.nan)
    df.loc[df["total_cpu_s"] <= 0, "cpu_eff"] = np.nan

    # A near-zero CPU efficiency usually means SLURM never saw the work rather
    # than that no work happened: MPI codes launched with mpirun instead of srun
    # report a couple of seconds of TotalCPU for a multi-day run. Treating those
    # as "wasteful" would be defamatory, so flag them as unmeasured instead.
    df["cpu_eff_measured"] = df["cpu_eff"].notna() & (df["cpu_eff"] >= 0.01)
    df["mem_eff_measured"] = df["max_rss_mb"].notna() & (df["max_rss_mb"] > 0)

    # MaxRSS is the peak of any single task, so this is a lower bound on the
    # job's real footprint. Treated as indicative, never as a hard verdict.
    df["mem_eff"] = np.where(df["alloc_mem_mb"] > 0,
                             df["max_rss_mb"] / df["alloc_mem_mb"], np.nan)

    df["timelimit_used"] = np.where(df["timelimit_s"] > 0,
                                    df["elapsed_s"] / df["timelimit_s"], np.nan)
    df["core_hours"] = df["ncpus"] * df["overlap_s"] / 3600.0
    df["gpu_hours"] = df["ngpus"] * df["overlap_s"] / 3600.0
    return compact(df)


# Low-cardinality string columns. A month is over a million rows, and as Python
# objects these alone run to several GB -- enough to be OOM-killed inside a
# modest SLURM allocation.
# job_name and nodelist look high-cardinality but are dominated by repeats -- one
# array job contributes 100k identical names, and most jobs land on a single node
# -- so they compress as well as the genuinely low-cardinality columns.
_CATEGORICAL = ["user", "account", "partition", "qos", "state", "exit_code",
                "workdir", "job_name", "nodelist"]


def compact(df: pd.DataFrame) -> pd.DataFrame:
    for c in _CATEGORICAL:
        if c in df.columns and df[c].dtype == object:
            df[c] = df[c].astype("category")
    # Floats are deliberately kept at float64: downcasting saves little next to
    # the categoricals and reintroduces representation noise into every rounded
    # figure in the report (a median of 7.4 printing as 7.4000000954). Upcast
    # rather than merely leaving alone, so caches written by earlier versions
    # come out clean too.
    for c in df.select_dtypes("float32").columns:
        df[c] = df[c].astype("float64")
    for c in df.select_dtypes("int64").columns:
        df[c] = pd.to_numeric(df[c], downcast="integer")
    return df


# --------------------------------------------------------------------------- #
# cache
# --------------------------------------------------------------------------- #

class DayCache:
    def __init__(self, cache_dir: str):
        self.dir = os.path.join(cache_dir, f"days-v{CACHE_VERSION}")
        os.makedirs(self.dir, exist_ok=True)

    def path(self, day: date) -> str:
        return os.path.join(self.dir, f"{day.isoformat()}.parquet")

    def is_complete(self, day: date) -> bool:
        """True if the cached file was written after `day` had ended.

        A file fetched while its day was still in progress is missing every job
        that started later that day, so it must be refetched once the day is over
        rather than trusted forever.
        """
        p = self.path(day)
        if not os.path.exists(p):
            return False
        day_end = datetime.combine(day + timedelta(days=1), datetime.min.time())
        return datetime.fromtimestamp(os.path.getmtime(p)) >= day_end

    def get(self, day: date, refresh: bool = False) -> pd.DataFrame:
        p = self.path(day)
        if not refresh and self.is_complete(day):
            return pd.read_parquet(p)
        if os.path.exists(p):
            logger.info("refetching %s: cached before the day had ended", day)
        df = collect_day(day)
        if not df.empty:
            df.to_parquet(p, index=False)
        return df

    def load_range(self, start: date, end: date, refresh: bool = False) -> pd.DataFrame:
        """Inclusive of `start`, exclusive of `end`."""
        frames = []
        d = start
        while d < end:
            df = self.get(d, refresh=refresh)
            if not df.empty:
                frames.append(df)
            d += timedelta(days=1)
        if not frames:
            return pd.DataFrame()
        # Categories differ per day, so concat would otherwise fall back to
        # object dtype and undo the compaction.
        return compact(pd.concat(frames, ignore_index=True))


def dedupe_jobs(df: pd.DataFrame) -> pd.DataFrame:
    """One row per job, with overlap_s/core_hours summed across the day chunks.

    Keeps the last chunk's copy of the mutable fields (state, end, elapsed) so a
    job that finished mid-period is reported in its final state.
    """
    if df.empty:
        return df
    sums = df.groupby("job_id", sort=False)[["overlap_s", "core_hours", "gpu_hours"]].sum()
    active = (df.groupby("job_id", sort=False)["active_nodes"].max()
              if "active_nodes" in df else None)
    # Positional selection of the last chunk per job, rather than sort + copy:
    # a month is over a million rows and each full-frame copy is expensive.
    order = np.argsort(df["day"].values, kind="stable")
    last = df.iloc[order]
    last = last[~last["job_id"].duplicated(keep="last")].set_index("job_id")
    last[["overlap_s", "core_hours", "gpu_hours"]] = sums.reindex(last.index)
    if active is not None:
        # Each day chunk only sees the steps that ran that day.
        last["active_nodes"] = active.reindex(last.index)
    return last.reset_index()


# --------------------------------------------------------------------------- #
# live cluster state
# --------------------------------------------------------------------------- #

def node_inventory() -> pd.DataFrame:
    """One row per node (deduplicated across partitions) plus a partition list."""
    # Delimited rather than fixed-width: Gres strings routinely overflow any
    # column width you pick and silently shift every field after them.
    res = subprocess.run(["sinfo", "-N", "-h", "-o", "%N|%P|%c|%m|%G|%T|%E"],
                         capture_output=True, text=True, timeout=120)
    rows = []
    for line in res.stdout.splitlines():
        f = [x.strip() for x in line.split("|")]
        if len(f) != 7 or not f[0]:
            continue
        gpu_type, gpu_count = None, 0
        m = re.search(r"gpu:([A-Za-z0-9_]+):(\d+)", f[4])
        if m:
            gpu_type, gpu_count = m.group(1), int(m.group(2))
        # sinfo marks the default partition with '*' and appends status flags
        # such as '*' (not responding) or '-' to the state; neither is data.
        rows.append({"node": f[0], "partition": f[1].rstrip("*"), "cpus": int(f[2] or 0),
                     "mem_mb": float(f[3] or 0), "gpu_type": gpu_type,
                     "gpus": gpu_count, "state": f[5].rstrip("*~#%$@-"),
                     "state_flags": f[5][len(f[5].rstrip("*~#%$@-")):],
                     "reason": f[6]})
    df = pd.DataFrame(rows)
    if df.empty:
        return df
    parts = df.groupby("node")["partition"].apply(lambda s: sorted(set(s)))
    out = df.drop_duplicates("node").set_index("node")
    out["partitions"] = parts
    # A node's "home" partition for grouping: the most specific one it sits in.
    out["primary_partition"] = out["partitions"].apply(
        lambda ps: sorted(ps, key=lambda p: (p == "comp", len(p)))[0] if ps else "")
    return out.reset_index().drop(columns=["partition"])


def queue_snapshot() -> pd.DataFrame:
    fmt = "%i|%u|%a|%P|%q|%T|%D|%C|%m|%b|%V|%S|%L|%Q|%r|%j"
    cols = ["job_id", "user", "account", "partition", "qos", "state", "nnodes",
            "ncpus", "min_memory", "tres_per_node", "submit", "start_est",
            "timeleft", "priority", "reason", "job_name"]
    res = subprocess.run(["squeue", "-a", "-h", "-o", fmt],
                         capture_output=True, text=True, timeout=300)
    rows = [line.split("|") for line in res.stdout.splitlines()]
    rows = [r for r in rows if len(r) == len(cols)]
    df = pd.DataFrame(rows, columns=cols)
    if df.empty:
        return df
    for c in ("nnodes", "ncpus", "priority"):
        df[c] = pd.to_numeric(df[c], errors="coerce")
    df["submit"] = pd.to_datetime(df["submit"], errors="coerce")
    df["ngpus"] = df["tres_per_node"].str.extract(r"gpu:?\w*:?(\d+)").astype(float).fillna(0)
    return df


MOTD_GLOB = "/etc/motd.d/*"
LOGIN_HOST = "m3-login1"
DOCS_URL = "https://docs.erc.monash.edu/Compute/HPC/M3/"


def _html_text(page: str) -> str:
    body = re.search(r"<main.*?</main>", page, re.S)
    body = re.sub(r"<(script|style)\b.*?</\1>", "", body.group(0) if body else page, flags=re.S)
    text = html.unescape(re.sub(r"<[^>]+>", " ", body))
    return "\n".join(" ".join(line.split()) for line in text.splitlines() if line.strip())


def announcements() -> str:
    """Operator notices (login banners, docs front page) as Markdown.

    Both sources only ever show what is current, so an outage notice is gone a
    week later; this has to be captured at collection time to be any use to a
    report written afterwards. The banners are installed on login nodes only,
    which is where this cannot run, hence the ssh fallback.
    """
    parts = []
    files = sorted(glob.glob(MOTD_GLOB))
    motd = "".join(f"==> {f} <==\n{open(f, errors='replace').read()}\n" for f in files)
    source = "local"
    if not motd:
        source = LOGIN_HOST
        try:
            res = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
                                  LOGIN_HOST, f"tail -n +1 {MOTD_GLOB}"],
                                 capture_output=True, text=True, timeout=60)
            motd = res.stdout
        except (OSError, subprocess.TimeoutExpired) as exc:
            logger.warning("could not read login banners from %s: %s", LOGIN_HOST, exc)
    if motd.strip():
        motd = re.sub(r"\x1b\[[0-9;]*m", "", motd)
        parts.append(f"## Login banners ({MOTD_GLOB}, {source})\n\n```\n{motd.strip()}\n```")
    else:
        logger.warning("no login banners found")
    try:
        with urllib.request.urlopen(DOCS_URL, timeout=30) as resp:
            page = resp.read().decode("utf-8", errors="replace")
        parts.append(f"## M3 docs front page ({DOCS_URL})\n\n{_html_text(page)}")
    except (OSError, ValueError) as exc:
        logger.warning("could not fetch %s: %s", DOCS_URL, exc)
    return "\n\n".join(parts)


def fmt_nodes(row: dict) -> str:
    """Node count for a table cell, noting when steps ran on fewer nodes."""
    n = int(row.get("nnodes") or 0)
    active = row.get("active_nodes")
    if n > 1 and active is not None and not pd.isna(active) and active < n:
        return f"{n} (only {int(active)} used)"
    return str(n)


def resolve_users(usernames) -> dict[str, dict]:
    """Look up real names via getent. Returns {} entries for unknown users."""
    out = {}
    for u in usernames:
        if not u or u in out:
            continue
        try:
            res = subprocess.run(["getent", "passwd", u], capture_output=True,
                                 text=True, timeout=15)
        except Exception:
            continue
        if res.returncode != 0 or not res.stdout.strip():
            out[u] = {"username": u, "name": None, "email": None}
            continue
        f = res.stdout.strip().split(":")
        gecos = f[4] if len(f) > 4 else ""
        g = gecos.split(",")
        email = next((x for x in g if "@" in x), None)
        # GECOS on M3 looks like "Given Family (Monash University)".
        raw_name = (g[0].strip() if g else "")
        m = re.match(r"^(.*?)\s*\(([^)]+)\)\s*$", raw_name)
        name, org = (m.group(1), m.group(2)) if m else (raw_name, None)
        out[u] = {"username": u, "name": name or None, "org": org, "email": email}
    return out


def setup_logging(verbose: bool = False) -> None:
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        stream=sys.stderr,
    )
