#!/usr/bin/env python
"""Turn a collected period into a digest of facts worth writing about.

This script does the arithmetic so the report author does not have to. It emits
digest.json (everything, machine-readable) and digest.md (a readable briefing).
The narrative is deliberately NOT generated here -- picking which of these facts
make a good forecast is the interesting part, and a script would only ever
produce the same three sentences every week.

    ./digest.py cache/periods/daily-2026-08-28 --names full
"""

import gc
import os
import re
import sys
import json
import logging
import argparse
from datetime import datetime, timedelta

from typing import Optional

import numpy as np
import pandas as pd
import pyarrow.parquet as pq

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from slurmwx import (compact, dedupe_jobs, expand_hostlist, fmt_nodes,
                     resolve_users, setup_logging)
from wxcalendar import Calendar
from pseudonyms import Pseudonyms, DEFAULT_PATH as PSEUDONYM_PATH

logger = logging.getLogger(__name__)

TOP_N = 12

# Job names that suggest a workflow manager is driving the submissions.
#
# Nextflow's giveaway is `nf-` followed by the process name in capitals
# (nf-GENERATE_REPORT_(sample)), because Nextflow uppercases process names by
# convention and generates the prefix itself. Matching a bare case-insensitive
# "nf-" would sweep in any job whose name happens to contain those characters,
# so the capitals are load-bearing and that branch is deliberately case-sensitive.
WORKFLOW_PATTERNS = {
    "nextflow": re.compile(r"^nf-[A-Z][A-Z0-9_]+|(?i:nextflow)|(?i:^nxf[-_])"),
    "snakemake": re.compile(r"snakejob|snakemake|smk", re.I),
    "interactive": re.compile(r"^(bash|sh|interactive|srun|Terminal|smux)", re.I),
    "desktop": re.compile(r"^(Desktop|VS\.?Code|Jupyter|RStudio|vnc)", re.I),
}

# A partition is treated as GPU-oriented when most of its nodes carry
# accelerators. Core utilisation is close to meaningless for those: a one-GPU job
# on a 52-core node strands the cores by design, so they are reported on the GPU
# charts instead of dragging down the CPU ones.
GPU_PARTITION_NODE_FRACTION = 0.5

# The memory ledger names people, so it only reports jobs that held their
# over-sized allocation long enough for it to have cost anyone anything. A job
# that asked for 900 GB and exited after four minutes is a typo, not a story --
# and MaxRSS on a short job may simply have missed the peak.
MEMORY_LEDGER_MIN_ELAPSED_S = 3600

# Multi-node jobs whose steps all ran on one node, below which the idle nodes are
# too brief to matter.
IDLE_NODES_MIN_ELAPSED_S = 3600

# Strudel desktop nodes are judged by a different standard to batch nodes, so the
# memory ledger splits on this. Matched against the comma-joined partition list.
DESKTOP_PARTITION = re.compile(r"(^|,)desktop(,|$)")

FAILURE_STATES = {"FAILED", "TIMEOUT", "OUT_OF_MEMORY", "NODE_FAIL", "BOOT_FAIL"}

DIGEST_COLUMNS = [
    "job_id", "user", "account", "partition", "qos", "state", "submit", "start",
    "end", "elapsed_s", "timelimit_s", "overlap_s", "nnodes", "ncpus",
    "alloc_mem_mb", "ngpus", "total_cpu_s", "max_rss_mb", "job_name",
    "exit_code", "nodelist", "day", "core_hours", "gpu_hours", "wait_s",
    "cpu_eff", "mem_eff", "cpu_eff_measured", "mem_eff_measured", "active_nodes",
]


# --------------------------------------------------------------------------- #

def _top(df: pd.DataFrame, by: str, cols: list[str], n: int = TOP_N,
         unique: Optional[list[str]] = None) -> list[dict]:
    """Top-n rows by `by`. `unique` collapses repeats so an array job with 400
    identically-named tasks does not fill the whole table with one story."""
    if df.empty or by not in df:
        return []
    d = df.sort_values(by, ascending=False)
    if unique:
        d = d.drop_duplicates(subset=unique, keep="first")
    return json.loads(d.head(n)[cols].to_json(orient="records", date_format="iso"))


def _match(series: pd.Series, test) -> np.ndarray:
    """Boolean mask for a string test, evaluated over a categorical's categories
    rather than its rows. Job names repeat heavily -- one array job supplies a
    hundred thousand identical ones -- so this is far cheaper than .str on rows.
    """
    if not isinstance(series.dtype, pd.CategoricalDtype):
        return series.fillna("").map(test).to_numpy(dtype=bool)
    hits = np.array([bool(test(c)) for c in series.cat.categories])
    codes = series.cat.codes.to_numpy()
    return np.where(codes >= 0, hits[np.clip(codes, 0, None)], False)


def _fmt_hours(seconds) -> str:
    """Human runtime for the digest tables; mirrors wxplots._fmt_duration."""
    s = float(seconds or 0)
    if s < 3600:
        return f"{s / 60:.0f} min"
    if s < 48 * 3600:
        return f"{s / 3600:.1f} h"
    days, rem = divmod(s, 86400)
    return f"{int(days)}d {rem / 3600:.0f}h"


def _pct(x) -> Optional[float]:
    # numpy scalars are not Python floats, so test the value rather than the type.
    if x is None or pd.isna(x):
        return None
    return round(float(x) * 100, 1)


def _all_usernames(obj, found=None) -> set[str]:
    """Every username anywhere in the digest, under a `user` key or a `users`
    list. Used to make sure nobody reaches the report without a pseudonym."""
    found = set() if found is None else found
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "user" and isinstance(v, str) and v:
                found.add(v)
            elif k == "users" and isinstance(v, list):
                found |= {x for x in v if isinstance(x, str) and x}
            else:
                _all_usernames(v, found)
    elif isinstance(obj, list):
        for v in obj:
            _all_usernames(v, found)
    return found


def _scrub_usernames(obj, handles: dict[str, str]) -> None:
    """Rewrite every username in the digest to its pseudonym, in place.

    The mirror of _all_usernames, and the reason anon mode is safe rather than
    merely careful: once this has run there is no real identifier in the digest
    for a later section to print by accident.
    """
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "user" and isinstance(v, str):
                obj[k] = handles.get(v, v)
            elif k == "users" and isinstance(v, list):
                obj[k] = [handles.get(x, x) if isinstance(x, str) else x for x in v]
            else:
                _scrub_usernames(v, handles)
    elif isinstance(obj, list):
        for v in obj:
            _scrub_usernames(v, handles)


def user_signatures(jobs: pd.DataFrame, users: set[str],
                    gpu_partitions: dict) -> dict[str, str]:
    """What each person is chiefly recognisable for, as a pseudonym flavour.

    The point is a handle that reads like the person: someone whose week is
    100,000 Nextflow tasks should not be "user-7". Tested most-distinctive first
    -- a Nextflow habit says more about someone than their core count does -- and
    everyone who is simply getting on with ordinary batch work falls through to
    the weather handles, which is most people and is fine.
    """
    if not users:
        return {}
    j = jobs[jobs["user"].isin(users)]
    if j.empty:
        return {u: "default" for u in users}
    names = j["job_name"].astype(str)
    flags = pd.DataFrame({
        "user": j["user"].astype(str).to_numpy(),
        "nextflow": _match(names, WORKFLOW_PATTERNS["nextflow"].search),
        "snakemake": _match(names, WORKFLOW_PATTERNS["snakemake"].search),
        "interactive": _match(names, WORKFLOW_PATTERNS["interactive"].search),
        "desktop": _match(names, WORKFLOW_PATTERNS["desktop"].search),
        "gpu": (j["ngpus"] > 0).to_numpy(),
        "bigmem": (j["alloc_mem_mb"] > 200_000).to_numpy(),
        "wide": (j["ncpus"] >= 32).to_numpy(),
    })
    frac = flags.groupby("user").mean()
    count = flags.groupby("user").size()

    out = {}
    for u in users:
        if u not in frac.index:
            out[u] = "default"
            continue
        f = frac.loc[u]
        if f["nextflow"] > 0.4:
            out[u] = "nextflow"
        elif f["snakemake"] > 0.3:
            out[u] = "snakemake"
        elif f["desktop"] > 0.5:
            out[u] = "desktop"
        elif f["interactive"] > 0.5:
            out[u] = "interactive"
        elif f["gpu"] > 0.5:
            out[u] = "gpu"
        elif f["bigmem"] > 0.5:
            out[u] = "memory"
        elif count[u] >= 2000:
            out[u] = "array"
        elif f["wide"] > 0.5:
            out[u] = "bigcpu"
        else:
            out[u] = "default"
    return out


# --------------------------------------------------------------------------- #

def classify_gpu_partitions(nodes: pd.DataFrame) -> dict[str, float]:
    """Fraction of each partition's nodes that carry GPUs.

    Uses full partition membership rather than the primary partition, because a
    job runs in the partition it was submitted to, not the one a node is filed
    under.
    """
    if nodes.empty or "partitions" not in nodes:
        return {}
    exploded = nodes[["partitions", "gpus"]].explode("partitions")
    frac = exploded.assign(has_gpu=exploded["gpus"] > 0).groupby(
        "partitions", observed=True)["has_gpu"].mean()
    return {str(k): float(v) for k, v in frac.items()}


def gpu_fraction_for(partition: str, gpu_partitions: dict[str, float]) -> float:
    """GPU-node fraction for a partition field, which may list several.

    `sbatch -p gpu,fit,bdi` records all three, so take the most GPU-heavy of
    them: such a job can land on an accelerator node and should be judged as GPU
    work rather than scored on cores it was never going to use.
    """
    parts = [p.strip() for p in str(partition).split(",") if p.strip()]
    return max((gpu_partitions.get(p, 0.0) for p in parts), default=0.0)


def clip_to_window(jobs: pd.DataFrame, start: datetime, end: datetime) -> pd.DataFrame:
    """Keep jobs touching [start, end) and recompute their in-window occupancy."""
    if jobs.empty:
        return jobs
    ts, te = pd.Timestamp(start), pd.Timestamp(end)
    touches = ((jobs["end"].isna() | (jobs["end"] > ts))
               & (jobs["submit"].isna() | (jobs["submit"] < te)))
    j = jobs[touches].copy()
    eff_end = j["end"].fillna(te).clip(upper=te)
    eff_start = j["start"].clip(lower=ts)
    j["overlap_s"] = (eff_end - eff_start).dt.total_seconds().clip(lower=0).fillna(0)
    j["core_hours"] = j["ncpus"] * j["overlap_s"] / 3600.0
    j["gpu_hours"] = j["ngpus"] * j["overlap_s"] / 3600.0
    return j


RESOURCE_COLUMNS = {"cpu": ("ncpus", "cpus"), "gpu": ("ngpus", "gpus")}


def node_utilisation(jobs: pd.DataFrame, nodes: pd.DataFrame,
                     start: datetime, end: datetime, nbins: int,
                     resource: str = "cpu") -> pd.DataFrame:
    """Allocated resource-hours per node per time bin, as a fraction of capacity.

    `resource` selects cores ("cpu") or GPUs ("gpu"); the GPU view only makes
    sense over the nodes that have any, so pass a filtered `nodes` frame.

    Multi-node jobs have their allocation split evenly across their node list,
    which is exact for the usual homogeneous allocation and close enough
    otherwise.
    """
    job_col, cap_col = RESOURCE_COLUMNS[resource]
    nodes = nodes[nodes[cap_col] > 0]
    running = jobs.loc[jobs["start"].notna() & (jobs[job_col] > 0),
                       ["start", "end", job_col, "nnodes", "nodelist"]].copy()
    if running.empty or nodes.empty:
        return pd.DataFrame()

    edges = pd.date_range(start, end, periods=nbins + 1)
    bin_starts = edges[:-1].values.astype("datetime64[s]").astype(np.int64)
    bin_ends = edges[1:].values.astype("datetime64[s]").astype(np.int64)

    js = running["start"].values.astype("datetime64[s]").astype(np.int64)
    je = running["end"].fillna(pd.Timestamp(end)).values.astype("datetime64[s]").astype(np.int64)
    nodelists = running["nodelist"].fillna("").tolist()
    per_node = (running[job_col].values.astype(np.float32)
                / np.maximum(running["nnodes"].values.astype(np.float32), 1))

    # Chunked: the jobs-by-bins overlap matrix for a month is large enough that
    # building it in one go, with numpy's temporaries, exhausts a small job.
    acc: dict[str, np.ndarray] = {}
    CHUNK = 50_000
    for lo in range(0, len(running), CHUNK):
        hi = min(lo + CHUNK, len(running))
        ov = np.clip(np.minimum(je[lo:hi, None], bin_ends[None, :])
                     - np.maximum(js[lo:hi, None], bin_starts[None, :]),
                     0, None).astype(np.float32) / 3600.0
        ov *= per_node[lo:hi, None]
        for i in range(hi - lo):
            for node in expand_hostlist(nodelists[lo + i]):
                if node not in acc:
                    acc[node] = np.zeros(nbins, dtype=np.float32)
                acc[node] += ov[i]
        del ov

    if not acc:
        return pd.DataFrame()

    used = pd.DataFrame(acc, index=edges[:-1]).T
    idx = nodes.set_index("node")
    # Nodes in the job records but absent from sinfo have been decommissioned or
    # renamed; there is no honest capacity to divide by, so drop them rather than
    # invent one.
    unknown = used.index.difference(idx.index)
    if len(unknown):
        logger.info("%s map: dropping %d node(s) absent from sinfo (%s)",
                    resource, len(unknown), ", ".join(sorted(unknown)[:5]))
    # Reindex onto every known node, not just the ones that saw work. A node that
    # ran nothing at all is the single most interesting row on the map, and
    # building the frame from the job records alone would silently omit it.
    used = used.reindex(idx.index).fillna(0.0)
    if used.empty:
        return pd.DataFrame()

    bin_hours = (edges[1] - edges[0]).total_seconds() / 3600.0
    capacity = idx[cap_col].reindex(used.index) * bin_hours
    frac = used.div(capacity, axis=0)

    # A node cannot be more than fully allocated, but the arithmetic can say so:
    # sacct reports a job's *final* node list, so a job that was requeued onto a
    # different node still has its whole elapsed time attributed to the last one.
    # Cap at 1.0 and keep the overshoot rate as a data-quality signal.
    over = float((frac.to_numpy() > 1.01).mean())
    if over > 0.005:
        logger.info("%s map: %.1f%% of node-bins exceeded capacity before capping",
                    resource, over * 100)
    frac = frac.clip(upper=1.0)
    frac.attrs["overallocated_bin_frac"] = over
    frac["primary_partition"] = idx["primary_partition"].reindex(frac.index)
    if resource == "gpu":
        frac["gpu_type"] = idx["gpu_type"].reindex(frac.index)
        frac["gpu_count"] = idx["gpus"].reindex(frac.index)
    return frac


# --------------------------------------------------------------------------- #

def build_digest(period_dir: str, names: str = "anon",
                 pseudonyms_path: str = PSEUDONYM_PATH) -> dict:
    meta = json.load(open(os.path.join(period_dir, "meta.json")))
    start = datetime.fromisoformat(meta["window_start"])
    end = datetime.fromisoformat(meta["window_end"])

    # Read only what the digest uses. A month is over a million rows and the
    # unused string columns (workdir especially) dominate the footprint.
    jobs_path = os.path.join(period_dir, "jobs.parquet")
    # Periods collected before cache v5 have no active_nodes; they read as unknown.
    present = set(pq.read_schema(jobs_path).names)
    raw = compact(pd.read_parquet(jobs_path, columns=[c for c in DIGEST_COLUMNS if c in present]))
    if "active_nodes" not in raw:
        raw["active_nodes"] = np.nan
    nodes = pd.read_parquet(os.path.join(period_dir, "nodes.parquet"))
    qpath = os.path.join(period_dir, "queue.parquet")
    queue = pd.read_parquet(qpath) if os.path.exists(qpath) else pd.DataFrame()

    jobs = dedupe_jobs(raw)
    del raw
    gc.collect()
    # Day chunks are whole days, so recompute the overlap against the real window
    # rather than trusting the summed per-day figures, which would otherwise
    # report more core-hours than the cluster physically has.
    jobs = clip_to_window(jobs, start, end)
    gc.collect()

    gpu_partitions = classify_gpu_partitions(nodes)

    # Views, not copies: a month is around a million rows and these three
    # together would otherwise triple peak memory for no benefit.
    finished = jobs[jobs["end"].notna() & (jobs["end"] >= start) & (jobs["end"] <= end)]
    started = jobs[jobs["start"].notna() & (jobs["start"] >= start) & (jobs["start"] <= end)]
    submitted = jobs[jobs["submit"].notna() & (jobs["submit"] >= start) & (jobs["submit"] <= end)]

    d: dict = {"meta": meta, "generated_at": datetime.now().isoformat()}

    # -- headline numbers ---------------------------------------------------- #
    total_core_hours = float(jobs["core_hours"].sum())
    capacity_core_hours = float(nodes["cpus"].sum() * (end - start).total_seconds() / 3600.0)
    d["headline"] = {
        "window_start": start.isoformat(),
        "window_end": end.isoformat(),
        "days": meta["days"],
        "jobs_touching_window": int(len(jobs)),
        "jobs_submitted": int(len(submitted)),
        "jobs_finished": int(len(finished)),
        "jobs_started": int(len(started)),
        "distinct_users": int(jobs["user"].replace("", np.nan).nunique()),
        "distinct_accounts": int(jobs["account"].replace("", np.nan).nunique()),
        "core_hours_delivered": round(total_core_hours, 1),
        "gpu_hours_delivered": round(float(jobs["gpu_hours"].sum()), 1),
        "cluster_cores": int(nodes["cpus"].sum()),
        "cluster_nodes": int(len(nodes)),
        "cluster_gpus": int(nodes["gpus"].sum()),
        "capacity_core_hours": round(capacity_core_hours, 1),
        "utilisation_pct": _pct(total_core_hours / capacity_core_hours) if capacity_core_hours else None,
        "queued_now": int(len(queue)),
        "queued_pending_now": int((queue["state"] == "PENDING").sum()) if not queue.empty else 0,
    }

    # -- outcomes ------------------------------------------------------------ #
    states = finished["state"].value_counts()
    d["outcomes"] = {
        "counts": {k: int(v) for k, v in states.items()},
        "success_pct": _pct(states.get("COMPLETED", 0) / len(finished)) if len(finished) else None,
        "failure_pct": _pct(sum(states.get(s, 0) for s in FAILURE_STATES) / len(finished)) if len(finished) else None,
        "core_hours_by_state": {k: round(float(v), 1) for k, v in
                                finished.groupby("state", observed=True)["core_hours"].sum().sort_values(ascending=False).items()},
    }
    # Wasted effort: core-hours spent on jobs that did not complete.
    wasted = finished[finished["state"].isin(FAILURE_STATES)]["core_hours"].sum()
    d["outcomes"]["core_hours_lost_to_failure"] = round(float(wasted), 1)
    d["outcomes"]["core_hours_lost_pct"] = _pct(wasted / total_core_hours) if total_core_hours else None

    # -- partitions ---------------------------------------------------------- #
    pcap = nodes.groupby("primary_partition")["cpus"].sum() * (end - start).total_seconds() / 3600.0
    pu = jobs.groupby("partition", observed=True).agg(
        core_hours=("core_hours", "sum"), gpu_hours=("gpu_hours", "sum"),
        jobs=("job_id", "count"), users=("user", "nunique")).sort_values("core_hours", ascending=False)
    pu["capacity_core_hours"] = pcap.reindex(pu.index)
    pu["utilisation_pct"] = (pu["core_hours"] / pu["capacity_core_hours"] * 100).round(1)
    pu["median_wait_min"] = (jobs.groupby("partition", observed=True)["wait_s"].median() / 60).round(1)
    pu["gpu_node_frac"] = [gpu_fraction_for(p, gpu_partitions) for p in pu.index]
    pu["kind"] = np.where(pu["gpu_node_frac"] >= GPU_PARTITION_NODE_FRACTION,
                          "gpu", "cpu")
    d["partitions"] = json.loads(pu.round(3).reset_index().to_json(orient="records"))
    d["gpu_partitions"] = sorted(p for p, f in gpu_partitions.items()
                                 if f >= GPU_PARTITION_NODE_FRACTION)

    # -- busiest users and accounts ------------------------------------------ #
    # Mask the one column rather than .where() on the frame, which would copy
    # every column of a million-row month.
    ua = jobs.assign(_eff=jobs["cpu_eff"].where(jobs["cpu_eff_measured"])).groupby(
        "user", observed=True).agg(
        core_hours=("core_hours", "sum"), gpu_hours=("gpu_hours", "sum"),
        jobs=("job_id", "count"), accounts=("account", "nunique"),
        median_cpu_eff=("_eff", "median"), median_mem_eff=("mem_eff", "median"),
    ).sort_values("core_hours", ascending=False)
    ua = ua[ua.index != ""]
    d["top_users"] = json.loads(ua.head(TOP_N).round(3).reset_index().to_json(orient="records"))

    aa = jobs.groupby("account", observed=True).agg(
        core_hours=("core_hours", "sum"), gpu_hours=("gpu_hours", "sum"),
        jobs=("job_id", "count"), users=("user", "nunique")).sort_values("core_hours", ascending=False)
    d["top_accounts"] = json.loads(aa.head(TOP_N).round(1).reset_index().to_json(orient="records"))

    # -- resource efficiency ------------------------------------------------- #
    # Only judge jobs big and long enough that the numbers mean something, and
    # only where SLURM actually recorded CPU time (see cpu_eff_measured).
    #
    # GPU work is excluded from the CPU efficiency view entirely: a job that
    # holds 12 cores to feed one accelerator is doing exactly the right thing,
    # and scoring it on core utilisation would put well-run GPU jobs at the top
    # of a "wasteful" list. GPU jobs are covered by the GPU synoptics instead.
    part_is_gpu = {p: gpu_fraction_for(p, gpu_partitions) >= GPU_PARTITION_NODE_FRACTION
                   for p in finished["partition"].astype(str).unique()}
    on_cpu = ~finished["partition"].astype(str).map(part_is_gpu).fillna(False) \
             & (finished["ngpus"] == 0)
    sizeable = finished[on_cpu & (finished["elapsed_s"] > 1800)
                        & (finished["ncpus"] >= 8)].copy()
    judged = sizeable[sizeable["cpu_eff_measured"]].copy()
    unmeasured = sizeable[~sizeable["cpu_eff_measured"]].copy()

    cols = ["job_id", "user", "account", "partition", "job_name", "ncpus", "nnodes",
            "active_nodes", "elapsed_s", "core_hours", "cpu_eff", "mem_eff", "alloc_mem_mb",
            "max_rss_mb", "state"]

    d["efficiency"] = {
        "sizeable_jobs": int(len(sizeable)),
        "judged_jobs": int(len(judged)),
        "unmeasured_jobs": int(len(unmeasured)),
        "unmeasured_core_hours": round(float(unmeasured["core_hours"].sum()), 1),
        "unmeasured_note": ("Jobs holding cores with essentially no TotalCPU recorded. "
                            "This is usually an accounting gap (MPI launched via mpirun "
                            "rather than srun) rather than proof of idleness, so these are "
                            "excluded from the efficiency figures below."),
        "median_cpu_eff_pct": _pct(judged["cpu_eff"].median()),
        "median_mem_eff_pct": _pct(judged["mem_eff"].median()),
        "core_hours_at_under_20pct_cpu": round(
            float(judged[judged["cpu_eff"] < 0.2]["core_hours"].sum()), 1),
    }
    hogs = judged[(judged["cpu_eff"] < 0.25) & (judged["core_hours"] > 24)]
    d["efficiency"]["worst_cpu_offenders"] = _top(hogs, "core_hours", cols,
                                                 unique=["user", "job_name"])
    # Memory over-allocation is the more reliable signal: MaxRSS is recorded even
    # when TotalCPU is not, though it is the peak of a single task rather than
    # the whole job, so it under-reports multi-process workloads.
    #
    # The ledger deliberately does NOT inherit the 8-core floor used above. Core
    # count is irrelevant to a memory story: a single-core job holding a terabyte
    # blocks a node just as effectively as a 48-core one, and is arguably the
    # more fixable mistake. Its own filters -- a real memory request, a real
    # runtime, measured RSS -- already keep the trivia out.
    #
    # Desktop-partition work is ledgered separately rather than mixed in. A
    # Strudel desktop is *supposed* to sit on a lot of memory with an idle CPU
    # while somebody thinks -- that is the product working. The same profile on
    # comp, genomics or especially genomicsb is holding a scarce batch node out
    # of the pool. Same numbers, opposite verdicts, so they need separate tables.
    mem_pool = finished[finished["elapsed_s"] >= MEMORY_LEDGER_MIN_ELAPSED_S]
    memhogs = mem_pool[mem_pool["mem_eff_measured"] & (mem_pool["mem_eff"] < 0.1)
                       & (mem_pool["alloc_mem_mb"] > 100_000)]
    on_desktop = _match(memhogs["partition"], DESKTOP_PARTITION.search)
    mem_cols = cols + ["cpu_eff_measured"]
    d["efficiency"]["memory_ledger_min_hours"] = MEMORY_LEDGER_MIN_ELAPSED_S / 3600
    d["efficiency"]["worst_memory_offenders"] = _top(
        memhogs[~on_desktop & on_cpu.loc[memhogs.index].to_numpy()],
        "alloc_mem_mb", mem_cols, unique=["user", "job_name"])
    d["efficiency"]["worst_memory_offenders_desktop"] = _top(
        memhogs[on_desktop], "alloc_mem_mb", mem_cols, unique=["user", "job_name"])
    d["efficiency"]["biggest_unmeasured"] = _top(unmeasured, "core_hours", cols,
                                                unique=["user", "job_name"])
    d["biggest_jobs"] = _top(jobs, "core_hours", cols, unique=["user", "job_name"])

    # Multi-node allocations where every recorded step ran on a single node: the
    # other nodes were held for the whole job with nothing launched on them.
    one_node = finished[(finished["nnodes"] > 1) & (finished["active_nodes"] == 1)
                        & (finished["elapsed_s"] >= IDLE_NODES_MIN_ELAPSED_S)]
    one_node = one_node.assign(
        idle_core_hours=one_node["core_hours"] * (one_node["nnodes"] - 1) / one_node["nnodes"])
    d["efficiency"]["idle_nodes"] = {
        "measured": bool(finished["active_nodes"].notna().any()),
        "min_hours": IDLE_NODES_MIN_ELAPSED_S / 3600,
        "multi_node_jobs": int((finished["nnodes"] > 1).sum()),
        "one_node_used_jobs": int(len(one_node)),
        "idle_core_hours": round(float(one_node["idle_core_hours"].sum()), 1),
        "worst": _top(one_node, "idle_core_hours", cols + ["idle_core_hours", "cpu_eff_measured"],
                      unique=["user", "job_name"]),
    }

    # -- waiting ------------------------------------------------------------- #
    w = started["wait_s"].dropna()
    d["waiting"] = {
        "median_wait_min": round(float(w.median()) / 60, 1) if len(w) else None,
        "p90_wait_min": round(float(w.quantile(0.9)) / 60, 1) if len(w) else None,
        "max_wait_hours": round(float(w.max()) / 3600, 1) if len(w) else None,
        "by_partition_median_min": {k: round(float(v) / 60, 1) for k, v in
                                    started.groupby("partition", observed=True)["wait_s"].median().dropna().sort_values(ascending=False).items()},
        "longest_waits": _top(started.assign(wait_hours=started["wait_s"] / 3600),
                              "wait_hours", ["job_id", "user", "account", "partition",
                                             "job_name", "ncpus", "ngpus", "wait_hours"]),
    }
    # CPU and GPU queues are effectively separate systems -- one waits for cores,
    # the other for accelerators and per-user GPU limits -- so a pooled median
    # describes neither. Split on what the job asked for, which puts every job in
    # exactly one bucket.
    d["waiting"]["by_resource"] = {}
    for label, sel in (("cpu", started["ngpus"] == 0), ("gpu", started["ngpus"] > 0)):
        ws = started.loc[sel, "wait_s"].dropna()
        d["waiting"]["by_resource"][label] = {
            "jobs": int(len(ws)),
            "median_min": round(float(ws.median()) / 60, 1) if len(ws) else None,
            "p90_min": round(float(ws.quantile(0.9)) / 60, 1) if len(ws) else None,
            "max_hours": round(float(ws.max()) / 3600, 1) if len(ws) else None,
        }

    if not queue.empty:
        pend = queue[queue["state"] == "PENDING"]
        d["waiting"]["pending_reasons"] = {k: int(v) for k, v in
                                           pend["reason"].value_counts().head(12).items()}
        d["waiting"]["pending_cores_requested"] = int(pend["ncpus"].sum())
        # Same split for the live queue: which of the two is actually backed up.
        is_gpu_pending = pend["ngpus"] > 0
        d["waiting"]["pending_by_resource"] = {
            "cpu": int((~is_gpu_pending).sum()), "gpu": int(is_gpu_pending.sum())}
        d["waiting"]["pending_reasons_gpu"] = {
            k: int(v) for k, v in
            pend[is_gpu_pending]["reason"].value_counts().head(8).items()}
        d["waiting"]["pending_reasons_cpu"] = {
            k: int(v) for k, v in
            pend[~is_gpu_pending]["reason"].value_counts().head(8).items()}

    # -- human rhythms ------------------------------------------------------- #
    if not submitted.empty:
        sub = submitted.copy()
        sub["hour"] = sub["submit"].dt.hour
        sub["dow"] = sub["submit"].dt.dayofweek
        d["rhythms"] = {
            "submissions_by_hour": {int(k): int(v) for k, v in
                                    sub["hour"].value_counts().sort_index().items()},
            "submissions_by_dow": {int(k): int(v) for k, v in
                                   sub["dow"].value_counts().sort_index().items()},
            "weekend_jobs": int(sub["dow"].isin([5, 6]).sum()),
            "weekend_pct": _pct(sub["dow"].isin([5, 6]).mean()),
        }
        # Small-hours submissions are only interesting if they look hand-typed:
        # a user with a handful of them, not an automated firehose.
        wee = sub[sub["hour"].isin([1, 2, 3, 4])]
        wee_by_user = wee.groupby("user", observed=True).agg(
            n=("job_id", "count"),
            distinct_names=("job_name", "nunique")).sort_values("n", ascending=False)
        plausible_human = wee_by_user[(wee_by_user["n"] <= 30) & (wee_by_user["n"] >= 2)]
        d["rhythms"]["small_hours_total"] = int(len(wee))
        d["rhythms"]["small_hours_likely_human"] = json.loads(
            plausible_human.head(TOP_N).reset_index().to_json(orient="records"))
        weekend_by_user = sub[sub["dow"].isin([5, 6])].groupby("user", observed=True)["job_id"].count()
        d["rhythms"]["weekend_warriors"] = json.loads(
            weekend_by_user.sort_values(ascending=False).head(TOP_N)
            .rename("jobs").reset_index().to_json(orient="records"))

    # -- job name colour ----------------------------------------------------- #
    names_series = jobs["job_name"]
    d["job_names"] = {"most_common": {str(k): int(v) for k, v in
                                      names_series.value_counts().head(20).items()}}
    for label, pat in WORKFLOW_PATTERNS.items():
        hit = jobs[_match(names_series, pat.search)]
        d["job_names"][label] = {
            "jobs": int(len(hit)),
            "core_hours": round(float(hit["core_hours"].sum()), 1),
            "users": sorted(u for u in hit["user"].unique() if u)[:TOP_N],
        }
    # Long, unusual or expressive names tend to be the human-written ones.
    quirky = jobs[_match(names_series, lambda s: len(s) > 12)].drop_duplicates("job_name")
    d["job_names"]["unusual_sample"] = json.loads(
        quirky.nlargest(40, "core_hours")[["job_name", "user", "account", "partition", "core_hours"]]
        .to_json(orient="records"))

    # -- node health --------------------------------------------------------- #
    bad = nodes[~nodes["state"].str.contains("idle|alloc|mix|comp", case=False, na=False)]
    d["nodes"] = {
        "total": int(len(nodes)),
        "by_state": {k: int(v) for k, v in nodes["state"].value_counts().items()},
        "unavailable": json.loads(bad[["node", "primary_partition", "state", "reason", "cpus"]]
                                  .to_json(orient="records")),
        "cores_offline": int(bad["cpus"].sum()),
    }

    # -- node/time heatmap --------------------------------------------------- #
    nbins = {1: 24, 7: 7 * 4, 30: 30}.get(meta["days"], min(48, meta["days"] * 4))
    heat = node_utilisation(jobs, nodes, start, end, nbins)
    if not heat.empty:
        heat_path = os.path.join(period_dir, "node_heatmap.parquet")
        heat.to_parquet(heat_path)
        by_part = heat.drop(columns=["primary_partition"]).groupby(
            heat["primary_partition"]).mean().mean(axis=1).sort_values()
        d["heatmap_file"] = heat_path
        d["quietest_partitions"] = {k: _pct(v) for k, v in by_part.head(8).items()}
        node_mean = heat.drop(columns=["primary_partition"]).mean(axis=1)
        d["coldest_nodes"] = json.loads(
            node_mean.nsmallest(15).rename("mean_alloc_frac").reset_index()
            .rename(columns={"index": "node"}).to_json(orient="records"))

    # -- GPU synoptics ------------------------------------------------------- #
    # GPUs are the scarce resource on M3 and behave nothing like cores: a node
    # can be idle on CPU while every accelerator in it is committed, so they
    # deserve their own map rather than a footnote on the CPU one.
    gpu_nodes = nodes[nodes["gpus"] > 0]
    gheat = node_utilisation(jobs, gpu_nodes, start, end, nbins, resource="gpu")
    if not gheat.empty:
        gpath = os.path.join(period_dir, "gpu_heatmap.parquet")
        gheat.to_parquet(gpath)
        meta_cols = ["primary_partition", "gpu_type", "gpu_count"]
        gvals = gheat.drop(columns=meta_cols)
        total_gpus = int(gpu_nodes["gpus"].sum())
        hours = (end - start).total_seconds() / 3600.0
        gpu_jobs = jobs[jobs["ngpus"] > 0]

        d["gpus"] = {
            "heatmap_file": gpath,
            "gpu_nodes": int(len(gpu_nodes)),
            "total_gpus": total_gpus,
            "gpu_hours_delivered": round(float(jobs["gpu_hours"].sum()), 1),
            "capacity_gpu_hours": round(total_gpus * hours, 1),
            "utilisation_pct": _pct(float(jobs["gpu_hours"].sum()) / (total_gpus * hours))
                               if total_gpus else None,
            "jobs_using_gpus": int(len(gpu_jobs)),
            "users_using_gpus": int(gpu_jobs["user"].replace("", np.nan).nunique()),
            "overallocated_bin_pct": _pct(gheat.attrs.get("overallocated_bin_frac", 0.0)),
            "by_type": {}, "by_partition": {},
        }
        for t, grp in gvals.groupby(gheat["gpu_type"].fillna("unknown")):
            sel = gheat["gpu_type"].fillna("unknown") == t
            d["gpus"]["by_type"][str(t)] = {
                "nodes": int(sel.sum()),
                "gpus": int(gheat.loc[sel, "gpu_count"].sum()),
                "mean_alloc_pct": _pct(grp.to_numpy().mean()),
                "peak_alloc_pct": _pct(grp.mean(axis=0).max()),
            }
        for p, grp in gvals.groupby(gheat["primary_partition"].fillna("(none)")):
            d["gpus"]["by_partition"][str(p)] = {
                "nodes": int(len(grp)),
                "mean_alloc_pct": _pct(grp.to_numpy().mean()),
            }
        gnode_mean = gvals.mean(axis=1)
        cols = ["node", "gpu_type", "gpu_count", "primary_partition", "mean_alloc_frac"]
        summary = gheat[["gpu_type", "gpu_count", "primary_partition"]].assign(
            mean_alloc_frac=gnode_mean).reset_index().rename(columns={"index": "node"})
        d["gpus"]["coldest_nodes"] = json.loads(
            summary.nsmallest(12, "mean_alloc_frac")[cols].to_json(orient="records"))
        d["gpus"]["hottest_nodes"] = json.loads(
            summary.nlargest(12, "mean_alloc_frac")[cols].to_json(orient="records"))
        d["gpus"]["top_users"] = json.loads(
            gpu_jobs.groupby("user", observed=True).agg(
                gpu_hours=("gpu_hours", "sum"), jobs=("job_id", "count"),
                max_gpus=("ngpus", "max"))
            .sort_values("gpu_hours", ascending=False).head(TOP_N)
            .round(1).reset_index().to_json(orient="records"))

    # -- Melbourne calendar --------------------------------------------------- #
    # Load lazily so a missing or malformed calendar file degrades to "no band"
    # rather than taking the whole digest down.
    try:
        d["calendar"] = Calendar.load().spans(start, end)
    except Exception as exc:  # noqa: BLE001 - never fatal
        logger.warning("calendar unavailable: %s", exc)
        d["calendar"] = None

    # -- identities ---------------------------------------------------------- #
    # Everyone the digest mentions anywhere, not just the headline lists. A
    # username that reaches the digest without a pseudonym is one that a future
    # section could print verbatim, so the sweep is over the whole structure
    # rather than over the handful of buckets that name people today.
    featured = _all_usernames(d)

    if names == "anon":
        # Real names are resolved so the mapping file can record who is who, but
        # they never reach the digest. Anything downstream -- digest.json,
        # digest.md, the rendered report -- sees only the pseudonym, so a report
        # cannot leak a name by accident even if someone writes new prose against
        # a field they did not expect to be sensitive.
        sigs = user_signatures(jobs, featured, gpu_partitions)
        for r in d.get("rhythms", {}).get("small_hours_likely_human", []):
            if sigs.get(r.get("user")) == "default":
                sigs[r["user"]] = "nocturnal"
        for r in d.get("rhythms", {}).get("weekend_warriors", []):
            if sigs.get(r.get("user")) == "default":
                sigs[r["user"]] = "weekend"

        book = Pseudonyms.load(pseudonyms_path)
        real = resolve_users(sorted(featured))
        d["identities"] = {}
        for u in sorted(featured):
            rec = real.get(u, {})
            handle = book.assign(u, signature=sigs.get(u, "default"),
                                 name=rec.get("name"), email=rec.get("email"))
            d["identities"][u] = {"username": None, "handle": handle, "name": None}
        book.save()
        # Replace the usernames themselves, throughout. Rendering correctly is
        # not enough: a report section that reaches into d["top_users"] directly
        # and formats r["user"] itself will leak, and that is a plausible thing
        # for someone writing new prose to do. After this pass there is no
        # username left in the digest to leak, so the safe thing is also the
        # only thing available. The book on disk remains the sole mapping.
        handles = {u: rec["handle"] for u, rec in d["identities"].items()}
        _scrub_usernames(d, handles)
        d["identities"] = {h: {"username": None, "handle": h, "name": None}
                           for h in handles.values()}
        d["names_mode"] = "anon"
    else:
        d["identities"] = resolve_users(sorted(featured))
        d["names_mode"] = "full"

    return d


# --------------------------------------------------------------------------- #

def render_markdown(d: dict) -> str:
    h = d["headline"]
    ids = d.get("identities", {})
    anon = d.get("names_mode") == "anon"

    def who(u):
        rec = ids.get(u)
        if anon:
            # No fallback to the username: an unrecognised user in anon mode is a
            # leak, not a formatting inconvenience.
            return rec["handle"] if rec else "an unnamed user"
        if not rec:
            return u
        return f"{rec.get('name') or u} ({u})"

    L = [f"# Digest: {d['meta']['period']} {h['window_start'][:16]} -> {h['window_end'][:16]}", ""]
    L += [
        "## Headline",
        f"- {h['jobs_finished']:,} jobs finished, {h['jobs_submitted']:,} submitted, "
        f"{h['jobs_started']:,} started",
        f"- {h['distinct_users']} users across {h['distinct_accounts']} accounts",
        f"- {h['core_hours_delivered']:,.0f} core-hours delivered "
        f"({h['utilisation_pct']}% of the {h['cluster_cores']:,}-core cluster's capacity)",
        f"- {h['gpu_hours_delivered']:,.0f} GPU-hours across {h['cluster_gpus']} GPUs",
        f"- {h['queued_pending_now']:,} jobs pending right now",
        "",
        "## Outcomes",
        f"- success {d['outcomes']['success_pct']}%, failure {d['outcomes']['failure_pct']}%",
        f"- {d['outcomes']['core_hours_lost_to_failure']:,.0f} core-hours lost to failed/timed-out/OOM jobs "
        f"({d['outcomes']['core_hours_lost_pct']}% of all compute)",
        "- states: " + ", ".join(f"{k} {v:,}" for k, v in d["outcomes"]["counts"].items()),
        "",
        "## Partitions",
        "| partition | core-hours | util% | jobs | users | median wait (min) |",
        "|---|---|---|---|---|---|",
    ]
    for p in d["partitions"][:16]:
        L.append(f"| {p['partition']} | {p['core_hours']:,.0f} | {p.get('utilisation_pct')} | "
                 f"{p['jobs']:,} | {p['users']} | {p.get('median_wait_min')} |")

    L += ["", "## Busiest users", "| who | core-hours | GPU-hours | jobs | median CPU eff |", "|---|---|---|---|---|"]
    for u in d["top_users"][:10]:
        eff = _pct(u.get("median_cpu_eff"))
        L.append(f"| {who(u['user'])} | {u['core_hours']:,.0f} | {u['gpu_hours']:,.0f} | "
                 f"{u['jobs']:,} | {eff if eff is not None else '-'}% |")

    L += ["", "## Busiest accounts", "| account | core-hours | jobs | users |", "|---|---|---|---|"]
    for a in d["top_accounts"][:10]:
        L.append(f"| {a['account']} | {a['core_hours']:,.0f} | {a['jobs']:,} | {a['users']} |")

    e = d["efficiency"]
    L += ["", "## Efficiency",
          f"- {e['sizeable_jobs']:,} jobs were long and wide enough to judge (>30 min, >=8 cores)",
          f"- {e['judged_jobs']:,} of those had usable CPU accounting; "
          f"{e['unmeasured_jobs']:,} did not ({e['unmeasured_core_hours']:,.0f} core-hours)",
          f"- CAVEAT: {e['unmeasured_note']}",
          f"- median CPU efficiency {e['median_cpu_eff_pct']}%, median memory efficiency {e['median_mem_eff_pct']}%",
          f"- {e['core_hours_at_under_20pct_cpu']:,.0f} core-hours went to jobs running under 20% CPU efficiency",
          "", "### Largest low-CPU-efficiency jobs (measured)"]
    for j in e["worst_cpu_offenders"][:8]:
        L.append(f"- `{j['job_name']}` [job {j['job_id']}] ({who(j['user'])}, {j['partition']}): "
                 f"{j['ncpus']} cores on {fmt_nodes(j)} node(s) for {j['elapsed_s']/3600:.1f} h = "
                 f"{j['core_hours']:,.0f} core-hours at {_pct(j['cpu_eff'])}% CPU")
    min_h = e.get("memory_ledger_min_hours", 1)
    for bucket, heading in (
            ("worst_memory_offenders",
             f"### Memory ledger, batch nodes — largest over-allocations "
             f"(jobs running at least {min_h:g} h)"),
            ("worst_memory_offenders_desktop",
             "### Memory ledger, desktop partition (judge this one more gently — "
             "an idle CPU beside a large memory reservation is what a Strudel "
             "desktop is for)")):
        L += ["", heading, "",
              "| Job | ID | Who | Partition | Nodes | Ran for | Requested | Peak used | Mem used | CPU used |",
              "|---|---|---|---|---:|---:|---:|---:|---:|---:|"]
        for j in e.get(bucket, [])[:8]:
            cpu = f"{_pct(j['cpu_eff'])}%" if j.get("cpu_eff_measured") else "not recorded"
            L.append(f"| `{j['job_name']}` | {j['job_id']} | {who(j['user'])} "
                     f"| {j['partition']} | {fmt_nodes(j)} | {_fmt_hours(j['elapsed_s'])} "
                     f"| {j['alloc_mem_mb']/1024:,.0f} GB "
                     f"| {(j['max_rss_mb'] or 0)/1024:,.1f} GB | {_pct(j['mem_eff'])}% | {cpu} |")
    L += ["", "### Largest jobs with no usable CPU accounting (interpret with care)"]
    for j in e["biggest_unmeasured"][:8]:
        L.append(f"- `{j['job_name']}` [job {j['job_id']}] ({who(j['user'])}, {j['partition']}): "
                 f"{j['ncpus']} cores on {fmt_nodes(j)} node(s) for {j['elapsed_s']/3600:.1f} h = "
                 f"{j['core_hours']:,.0f} core-hours")
    idle = e.get("idle_nodes") or {}
    L += ["", "### Multi-node jobs that only used one node"]
    if not idle.get("measured"):
        L.append("- not measured: this period was collected before per-step node lists were cached")
    else:
        L.append(f"- {idle['one_node_used_jobs']:,} of {idle['multi_node_jobs']:,} multi-node jobs "
                 f"(running at least {idle['min_hours']:g} h) launched every step on one node; "
                 f"{idle['idle_core_hours']:,.0f} core-hours were held on the others")
        L.append("- CAVEAT: MPI started over ssh rather than srun leaves no step on the other "
                 "nodes, so a flag here is a question to ask, not a verdict")
        for j in idle["worst"][:8]:
            L.append(f"- `{j['job_name']}` [job {j['job_id']}] ({who(j['user'])}, {j['partition']}): "
                     f"{j['nnodes']} nodes, {j['ncpus']} cores for {_fmt_hours(j['elapsed_s'])}; "
                     f"{j['idle_core_hours']:,.0f} core-hours on nodes with no step")

    w = d["waiting"]
    L += ["", "## Waiting",
          f"- median wait {w['median_wait_min']} min, 90th percentile {w['p90_wait_min']} min, "
          f"longest {w['max_wait_hours']} h"]
    if w.get("by_resource"):
        L += ["", "| queue | jobs started | median wait | p90 | longest |",
              "|---|---|---|---|---|"]
        for label, r in w["by_resource"].items():
            L.append(f"| {label.upper()} jobs | {r['jobs']:,} | {r['median_min']} min | "
                     f"{r['p90_min']} min | {r['max_hours']} h |")
        L.append("")
    if w.get("pending_by_resource"):
        L.append(f"- pending now: {w['pending_by_resource']['cpu']:,} CPU, "
                 f"{w['pending_by_resource']['gpu']:,} GPU")
        L.append("- GPU pending reasons: " + ", ".join(
            f"{k} ({v})" for k, v in w["pending_reasons_gpu"].items()))
        L.append("- CPU pending reasons: " + ", ".join(
            f"{k} ({v})" for k, v in w["pending_reasons_cpu"].items()))
    if w.get("pending_reasons"):
        L.append("- pending reasons now: " + ", ".join(f"{k} ({v})" for k, v in w["pending_reasons"].items()))
    L.append("- slowest partitions by median wait: " + ", ".join(
        f"{k} {v} min" for k, v in list(w["by_partition_median_min"].items())[:6]))

    r = d.get("rhythms", {})
    if r:
        L += ["", "## Human rhythms",
              f"- {r['weekend_jobs']:,} submissions landed on a weekend ({r['weekend_pct']}%)",
              f"- {r['small_hours_total']:,} submissions between 1am and 5am"]
        if r.get("small_hours_likely_human"):
            L.append("- plausibly hand-typed at that hour: " + ", ".join(
                f"{who(x['user'])} ({x['n']})" for x in r["small_hours_likely_human"][:6]))
        if r.get("weekend_warriors"):
            L.append("- weekend workers: " + ", ".join(
                f"{who(x['user'])} ({x['jobs']})" for x in r["weekend_warriors"][:6]))

    jn = d["job_names"]
    L += ["", "## Job names",
          "- workflow managers: " + ", ".join(
              f"{k} {jn[k]['jobs']:,} jobs / {jn[k]['core_hours']:,.0f} core-h"
              for k in ("nextflow", "snakemake", "interactive", "desktop")),
          "- most common names: " + ", ".join(f"{k} ({v})" for k, v in
                                              list(jn["most_common"].items())[:12]),
          "- notable names (longest-running, distinct): " + ", ".join(
              f"`{x['job_name']}`" for x in jn["unusual_sample"][:25])]

    n = d["nodes"]
    L += ["", "## Node health",
          f"- {n['total']} nodes; {n['cores_offline']:,} cores unavailable",
          "- states: " + ", ".join(f"{k} {v}" for k, v in n["by_state"].items())]
    for x in n["unavailable"][:15]:
        L.append(f"  - {x['node']} ({x['primary_partition']}, {x['cpus']} cores): "
                 f"{x['state']} - {x['reason']}")

    g = d.get("gpus")
    if g:
        L += ["", "## GPU synoptics",
              f"- {g['total_gpus']} GPUs across {g['gpu_nodes']} nodes; "
              f"{g['gpu_hours_delivered']:,.0f} of {g['capacity_gpu_hours']:,.0f} GPU-hours "
              f"allocated ({g['utilisation_pct']}%)",
              f"- {g['jobs_using_gpus']:,} jobs from {g['users_using_gpus']} users asked for a GPU",
              "", "| GPU type | nodes | GPUs | mean allocated | busiest bin |",
              "|---|---|---|---|---|"]
        for t, v in sorted(g["by_type"].items(),
                           key=lambda kv: -(kv[1]["mean_alloc_pct"] or 0)):
            L.append(f"| {t} | {v['nodes']} | {v['gpus']} | {v['mean_alloc_pct']}% | "
                     f"{v['peak_alloc_pct']}% |")
        L += ["", "- GPU allocation by partition: " + ", ".join(
            f"{k} {v['mean_alloc_pct']}%" for k, v in
            sorted(g["by_partition"].items(), key=lambda kv: -(kv[1]["mean_alloc_pct"] or 0)))]
        L.append("- coldest GPU nodes: " + ", ".join(
            f"{x['node']} ({x['gpu_type']}x{x['gpu_count']}, {_pct(x['mean_alloc_frac'])}%)"
            for x in g["coldest_nodes"][:8]))
        L.append("- hottest GPU nodes: " + ", ".join(
            f"{x['node']} ({x['gpu_type']}x{x['gpu_count']}, {_pct(x['mean_alloc_frac'])}%)"
            for x in g["hottest_nodes"][:8]))
        L += ["", "### Heaviest GPU users", "| who | GPU-hours | jobs | largest request |",
              "|---|---|---|---|"]
        for u in g["top_users"][:10]:
            n_gpu = int(u["max_gpus"])
            L.append(f"| {who(u['user'])} | {u['gpu_hours']:,.0f} | {u['jobs']:,} | "
                     f"{n_gpu} GPU{'s' if n_gpu != 1 else ''} |")
        if (g.get("overallocated_bin_pct") or 0) > 0.5:
            L.append(f"- NOTE: {g['overallocated_bin_pct']}% of node-time bins computed above "
                     "100% of a node's GPUs and were capped; sacct attributes a requeued "
                     "job's whole runtime to its final node.")

    if d.get("quietest_partitions"):
        L += ["", "## Quiet corners",
              "- least-allocated partitions: " + ", ".join(
                  f"{k} {v}%" for k, v in d["quietest_partitions"].items()),
              "- coldest nodes: " + ", ".join(
                  f"{x['node']} ({_pct(x['mean_alloc_frac'])}%)" for x in d["coldest_nodes"][:10])]

    return "\n".join(L) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("period_dir", help="Directory produced by collect.py")
    ap.add_argument("--names", choices=["anon", "full"], default="anon",
                    help="anon (default): persistent activity-based pseudonyms; "
                         "full: real names via getent, for internal use only")
    ap.add_argument("--pseudonyms", default=PSEUDONYM_PATH,
                    help=f"pseudonym mapping file (default: {PSEUDONYM_PATH}). "
                         "Holds real names and addresses; written 0600.")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()
    setup_logging(args.verbose)

    d = build_digest(args.period_dir, names=args.names,
                     pseudonyms_path=args.pseudonyms)
    with open(os.path.join(args.period_dir, "digest.json"), "w") as fh:
        json.dump(d, fh, indent=2, default=str)
    md_path = os.path.join(args.period_dir, "digest.md")
    with open(md_path, "w") as fh:
        fh.write(render_markdown(d))
    print(md_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
