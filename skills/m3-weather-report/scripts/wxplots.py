"""Charts for the M3 weather report.

Everything here takes a period directory and returns a matplotlib figure, so the
Quarto template stays readable and the report author can call one function per
chunk instead of writing plotting code. Nothing here decides what is
interesting -- that is the author's job.
"""

import gc
import os
import json

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import ScalarFormatter, NullFormatter
from matplotlib.dates import DayLocator, WeekdayLocator, DateFormatter, MONDAY

from slurmwx import fmt_nodes

try:
    from IPython.display import Markdown
except ImportError:  # importable outside a notebook kernel, e.g. for tests
    def Markdown(text):  # noqa: N802 - mirrors the IPython name
        return text

# A sky-to-storm ramp: empty cluster reads as clear sky, saturated as thundercloud.
SKY = LinearSegmentedColormap.from_list(
    "sky", ["#f2f7fb", "#cfe4f2", "#8fc0dd", "#4f8fbf", "#2f5f8f", "#3b3b54", "#241f2e"])

PARTITION_COLOURS = {}
_PALETTE = ["#4f8fbf", "#e0813c", "#5fa77c", "#c05f6b", "#8a6bb0", "#a07b56",
            "#d38fb8", "#7f8b93", "#b8ab48", "#4bacc6"]

plt.rcParams.update({
    "figure.dpi": 130, "savefig.bbox": "tight", "font.size": 9,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.grid": True, "grid.alpha": 0.25, "grid.linewidth": 0.5,
})


def _fmt_duration(seconds) -> str:
    """Human runtime: minutes, hours, or days-and-hours, whichever reads best."""
    s = float(seconds or 0)
    if s < 3600:
        return f"{s / 60:.0f} min"
    if s < 48 * 3600:
        return f"{s / 3600:.1f} h"
    days, rem = divmod(s, 86400)
    return f"{int(days)}d {rem / 3600:.0f}h"


def _fmt_cpu_eff(row: dict) -> str:
    """CPU efficiency, or an honest blank where SLURM never recorded any.

    A missing TotalCPU is an accounting gap, not evidence of idleness, so it must
    not render as "0.0%" beside a name -- see references/data-notes.md.
    """
    if not row.get("cpu_eff_measured") or row.get("cpu_eff") is None:
        return "_not recorded_"
    return f"{row['cpu_eff'] * 100:.1f}%"


def _colour(key: str) -> str:
    if key not in PARTITION_COLOURS:
        PARTITION_COLOURS[key] = _PALETTE[len(PARTITION_COLOURS) % len(_PALETTE)]
    return PARTITION_COLOURS[key]


class Report:
    """Loads one collected period and serves up the frames and figures."""

    def __init__(self, period_dir: str):
        self.dir = period_dir
        self.meta = json.load(open(os.path.join(period_dir, "meta.json")))
        self.digest = json.load(open(os.path.join(period_dir, "digest.json")))
        self.start = pd.Timestamp(self.meta["window_start"])
        self.end = pd.Timestamp(self.meta["window_end"])

        from slurmwx import compact, dedupe_jobs
        from digest import clip_to_window, DIGEST_COLUMNS
        # Same column pruning as the digest: a month is over a million rows, and
        # reading every column here is enough to kill the Quarto kernel.
        raw = compact(pd.read_parquet(os.path.join(period_dir, "jobs.parquet"),
                                      columns=DIGEST_COLUMNS))
        self.jobs = clip_to_window(dedupe_jobs(raw), self.start, self.end)
        del raw
        gc.collect()
        self.nodes = pd.read_parquet(os.path.join(period_dir, "nodes.parquet"))
        qp = os.path.join(period_dir, "queue.parquet")
        self.queue = pd.read_parquet(qp) if os.path.exists(qp) else pd.DataFrame()
        hp = os.path.join(period_dir, "node_heatmap.parquet")
        self.heat = pd.read_parquet(hp) if os.path.exists(hp) else pd.DataFrame()
        gp = os.path.join(period_dir, "gpu_heatmap.parquet")
        self.gpu_heat = pd.read_parquet(gp) if os.path.exists(gp) else pd.DataFrame()
        self.calendar_spans = self.digest.get("calendar")

    # ----------------------------------------------------------- named tables --

    def who(self, username):
        """Render a username per the digest's naming mode.

        In anon mode there is deliberately no fallback to the username: an
        unrecognised user is a privacy leak rather than a formatting problem, and
        the whole point of the mode is that a report cannot print a real
        identifier even if new prose reaches for a field nobody anticipated.
        """
        rec = (self.digest.get("identities") or {}).get(username)
        if self.digest.get("names_mode") == "anon":
            return (rec or {}).get("handle") or "an unnamed user"
        if not rec:
            return f"`{username}`"
        name = rec.get("name")
        return f"{name} (`{username}`)" if name else f"`{username}`"

    def top_users(self, n=10):
        """Markdown table of the period's heaviest users.

        Shared rather than hand-rolled in each report, because a report that
        formats `r["user"]` itself is one edit away from printing a real
        identifier in anon mode.
        """
        rows = self.digest.get("top_users") or []
        if not rows:
            return Markdown("_No user totals for this period._")
        lines = ["| Researcher | Core-hours | GPU-hours | Jobs | Median CPU eff. |",
                 "|---|---:|---:|---:|---:|"]
        for r in rows[:n]:
            eff = r.get("median_cpu_eff")
            eff_s = "-" if eff is None else f"{eff * 100:.0f}%"
            lines.append(f"| {self.who(r['user'])} | {r['core_hours']:,.0f} "
                         f"| {r['gpu_hours']:,.0f} | {r['jobs']:,} | {eff_s} |")
        return Markdown("\n".join(lines))

    def memory_ledger(self, n=8, scope="batch"):
        """Markdown table of the largest over-allocated memory requests.

        A table rather than prose because the point is a comparison -- requested
        against actually used -- and a bullet list makes the reader hold six
        numbers in their head. Runtime is included because it is what turns an
        over-request into a cost: 1.4 TB held for six days is a different problem
        from 1.4 TB held for an hour.

        `scope` is "batch" or "desktop". They are separate tables because the
        same numbers carry opposite verdicts: a desktop reserving memory while
        its CPU idles is the product working as designed, whereas the identical
        profile on comp or genomicsb is a batch node held out of the pool. Print
        both, but do not write the same paragraph under each.

        Job IDs are shown so anyone named can run `jobstats <id>` and check.
        """
        key = ("worst_memory_offenders_desktop" if scope == "desktop"
               else "worst_memory_offenders")
        rows = (self.digest.get("efficiency") or {}).get(key, [])
        if not rows:
            return Markdown("_No jobs met the memory-ledger threshold this period._")
        head = ("| Job | ID | Who | Partition | Nodes | Ran for | Requested | Peak used "
                "| Mem used | CPU used |\n"
                "|---|---|---|---|---:|---:|---:|---:|---:|---:|\n")
        body = "\n".join(
            f"| `{r['job_name']}` | `{r['job_id']}` | {self.who(r['user'])} "
            f"| {r['partition']} | {fmt_nodes(r)} | {_fmt_duration(r['elapsed_s'])} "
            f"| {r['alloc_mem_mb'] / 1024:,.0f} GB "
            f"| {(r['max_rss_mb'] or 0) / 1024:,.1f} GB "
            f"| **{(r['mem_eff'] or 0) * 100:.1f}%** "
            f"| {_fmt_cpu_eff(r)} |"
            for r in rows[:n])
        return Markdown(head + body)

    def idle_node_jobs(self, n=8):
        """Markdown table of multi-node jobs whose steps all ran on one node.

        Idle core-hours assume the job's cores were spread evenly over its nodes.
        An MPI job launched over ssh instead of srun leaves no steps on the other
        nodes and lands here too, so present each row as a question, not a
        finding.
        """
        idle = (self.digest.get("efficiency") or {}).get("idle_nodes") or {}
        if not idle.get("measured"):
            return Markdown("_Per-step node lists were not collected for this period._")
        rows = idle.get("worst") or []
        if not rows:
            return Markdown("_No multi-node job ran on only one of its nodes this period._")
        head = ("| Job | ID | Who | Partition | Nodes | Cores | Ran for | Idle core-hours "
                "| CPU used |\n"
                "|---|---|---|---|---:|---:|---:|---:|---:|\n")
        body = "\n".join(
            f"| `{r['job_name']}` | `{r['job_id']}` | {self.who(r['user'])} "
            f"| {r['partition']} | {fmt_nodes(r)} | {r['ncpus']} "
            f"| {_fmt_duration(r['elapsed_s'])} | **{r['idle_core_hours']:,.0f}** "
            f"| {_fmt_cpu_eff(r)} |"
            for r in rows[:n])
        return Markdown(head + body)

    # ---------------------------------------------------------------- charts --

    def node_heatmap(self, width=10, row_height=0.085):
        """Every node as a row, time across the x axis, colour = fraction of
        cores allocated."""
        return self._heatmap(self.heat, width, row_height,
                             title="Cluster weather map: core allocation by node",
                             cbar="fraction of cores allocated")

    def gpu_heatmap(self, width=10, row_height=0.16):
        """The same map restricted to GPU nodes, showing the fraction of GPUs
        allocated rather than cores.

        Worth its own figure because the two rarely agree: a GPU node can look
        half-idle on the CPU map while every accelerator in it is committed.
        Rows are taller here simply because there are far fewer of them.
        """
        if self.gpu_heat.empty:
            return None
        labels = {
            n: f"{n}  {t if isinstance(t, str) else '?'}x{int(c)}"
            for n, t, c in zip(self.gpu_heat.index, self.gpu_heat["gpu_type"],
                               self.gpu_heat["gpu_count"].fillna(0))
        }
        return self._heatmap(self.gpu_heat.drop(columns=["gpu_type", "gpu_count"]),
                             width, row_height,
                             title="GPU synoptics: accelerator allocation by node",
                             cbar="fraction of GPUs allocated",
                             row_labels=labels)

    def _weekend_marks(self, cols):
        """x positions of Saturday 00:00 and Monday 00:00 within the map.

        Returned in axis coordinates rather than bin indices: bins are uniform in
        time but rarely start at midnight (a weekly map runs in six-hour bins
        from 08:00), so snapping to the nearest bin edge would put the lines up
        to three hours out.
        """
        if len(cols) < 2:
            return []
        origin, step = cols[0], cols[1] - cols[0]
        right = len(cols) - 0.5
        marks = []
        day = pd.Timestamp(self.start).normalize()
        stop = pd.Timestamp(self.end).normalize() + pd.Timedelta(days=1)
        while day <= stop:
            # Saturday opens the weekend; the following Monday closes it.
            if day.dayofweek in (5, 0):
                x = (day - origin) / step - 0.5
                if -0.5 <= x <= right:
                    marks.append(x)
            day += pd.Timedelta(days=1)
        return marks

    HOLIDAY_COLOURS = {"school": "#e0a13c", "public": "#8a6bb0"}

    def _x_of(self, t, cols):
        """Map a timestamp onto the heatmap's bin axis (bin i spans i-0.5..i+0.5)."""
        step = cols[1] - cols[0]
        return (pd.Timestamp(t) - cols[0]) / step - 0.5

    def _calendar_band(self, ax, cols, n):
        """A strip above the map showing Victorian school and public holidays.

        Drawn as a proper inset axes rather than floating patches so it keeps a
        constant physical thickness whether the map is five inches tall or
        twenty-two. Rendered even when empty, because a missing band and a band
        with nothing in it would otherwise look the same.
        """
        spans = self.calendar_spans
        if spans is None:
            return 0.0
        # Work in inches and convert: the heatmap is anywhere between five and
        # twenty-two inches tall, so a fixed axes fraction would give a hairline
        # on one report and a stripe on another. The gap has to clear the rotated
        # date labels, which sit on top of the map.
        fig_h = ax.figure.get_size_inches()[1]
        ax_h = max(ax.get_position().height * fig_h, 0.1)
        gap_in, band_in = 0.80, 0.22
        band_h, gap = band_in / ax_h, gap_in / ax_h

        band = ax.inset_axes([0, 1 + gap, 1, band_h], transform=ax.transAxes, zorder=6)
        band.set_xlim(-0.5, n - 0.5)
        band.set_ylim(0, 1)
        band.set_xticks([])
        band.set_yticks([])
        for s in band.spines.values():
            s.set_edgecolor("#c8ced3")
            s.set_linewidth(0.6)
        band.set_facecolor("#fbfcfd")

        drawn = []
        for kind, key in (("school", "school_holidays"), ("public", "public_holidays")):
            for h in spans[key]:
                x0 = max(self._x_of(h["start"], cols), -0.5)
                x1 = min(self._x_of(h["end"], cols), n - 0.5)
                if x1 <= x0:
                    continue
                band.axvspan(x0, x1, color=self.HOLIDAY_COLOURS[kind],
                             alpha=0.95, lw=0)
                drawn.append((x0, x1, h["name"], kind))

        for x0, x1, name, kind in drawn:
            # Only label a span with room for the text; the rest go in the legend.
            if (x1 - x0) / max(n, 1) > 0.12:
                band.text((x0 + x1) / 2, 0.5, name, ha="center", va="center",
                          fontsize=6.5, color="white", fontweight="bold")

        extra_in = 0.0
        if not drawn:
            msg = "no Victorian public or school holidays in this window"
            if spans["years_missing"]:
                msg = ("Melbourne calendar has no data for "
                       + ", ".join(str(y) for y in spans["years_missing"]))
            band.text(0.5, 0.5, msg, transform=band.transAxes, ha="center",
                      va="center", fontsize=6.5, color="#7f8b93", style="italic")
        else:
            handles = [Patch(facecolor=self.HOLIDAY_COLOURS[k], label=lbl)
                       for k, lbl in (("school", "VIC school holidays"),
                                      ("public", "VIC public holiday"))]
            band.legend(handles=handles, loc="lower left",
                        bbox_to_anchor=(0, 1.25), ncol=2, fontsize=6.5,
                        frameon=False, handlelength=1.2, handleheight=0.8)
            extra_in = 0.22
        # Headroom the title has to clear, in inches.
        return gap_in + band_in + extra_in

    def _heatmap(self, frame, width, row_height, title, cbar, row_labels=None):
        """Nodes as rows grouped into partition bands, time across the x axis.

        Height scales with the node count rather than being fixed: 276 rows
        squeezed into a fixed figure gives node labels nobody can read, which
        defeats the purpose of naming the cold nodes in the first place.
        """
        if frame is None or frame.empty:
            return None
        h = frame.copy()
        part = h.pop("primary_partition").fillna("(none)")
        # Group by partition, then by node name so numbering runs in order.
        order = {p: i for i, p in enumerate(
            part.groupby(part).size().sort_values(ascending=False).index)}
        idx = sorted(h.index, key=lambda n: (order.get(part[n], 99), n))
        h, part = h.loc[idx], part.reindex(idx)

        n = len(h)
        fig, ax = plt.subplots(figsize=(width, max(5.0, n * row_height)))
        im = ax.imshow(h.values, aspect="auto", cmap=SKY, vmin=0, vmax=1,
                       interpolation="nearest")
        ax.set_yticks(range(n))
        ticks = [row_labels.get(i, i) for i in h.index] if row_labels else list(h.index)
        ax.set_yticklabels(ticks, fontsize=6 if row_height < 0.12 else 7,
                           fontfamily="monospace")
        ax.tick_params(axis="y", length=0, pad=1)

        cols = pd.to_datetime(h.columns)
        step = max(1, len(cols) // 14)
        ax.set_xticks(range(0, len(cols), step))
        fmt = "%H:%M" if self.meta["days"] <= 1 else ("%a %d" if self.meta["days"] <= 7 else "%d %b")
        ax.set_xticklabels([c.strftime(fmt) for c in cols[::step]], rotation=45, ha="right")
        ax.xaxis.set_ticks_position("top")
        ax.grid(False)

        # Weekend boundaries: a line down the left of Saturday and the right of
        # Sunday, so the working-week rhythm is readable without counting dates.
        for x in self._weekend_marks(cols):
            ax.axvline(x, color="#d92b2b", lw=1.4, zorder=5)

        band_in = self._calendar_band(ax, cols, n) or 0.0

        # Partition bands: a white rule between them and a label to the right,
        # which stays readable however thin the band is.
        bounds = np.where(part.values[1:] != part.values[:-1])[0] + 0.5
        for b in bounds:
            ax.axhline(b, color="white", lw=1.5)
        edges = np.concatenate([[-0.5], bounds, [n - 0.5]])
        for i in range(len(edges) - 1):
            lo, hi = edges[i], edges[i + 1]
            label = part.values[int((lo + hi) / 2)]
            ax.annotate(f"{label} ({int(hi - lo)})",
                        xy=(1.005, 1 - ((lo + hi) / 2 + 0.5) / n),
                        xycoords="axes fraction", va="center", ha="left",
                        fontsize=7.5, color=_colour(label), fontweight="bold",
                        annotation_clip=False)

        cb = fig.colorbar(im, ax=ax, shrink=min(0.9, 60 / max(n, 1)), pad=0.16, aspect=25)
        cb.set_label(cbar, fontsize=8)
        # Clear the date labels and whatever the calendar band added above them.
        ax.set_title(title, pad=34 + band_in * 72)
        return fig

    def gpu_by_type(self, figsize=(8, 4)):
        """Mean allocation per GPU model. Usually the sharpest chart in the
        report, because generations of accelerator are in wildly different
        demand and the fix (steer people to the idle ones) is concrete."""
        g = self.digest.get("gpus")
        if not g or not g.get("by_type"):
            return None
        rows = sorted(g["by_type"].items(), key=lambda kv: kv[1]["mean_alloc_pct"] or 0)
        labels = [f"{t}  ({v['gpus']} on {v['nodes']} nodes)" for t, v in rows]
        vals = [v["mean_alloc_pct"] or 0 for _, v in rows]
        fig, ax = plt.subplots(figsize=figsize)
        ax.barh(labels, vals, color=[SKY(v / 100) for v in vals], edgecolor="#7f8b93", lw=0.4)
        for y, v in enumerate(vals):
            ax.text(v + 1.2, y, f"{v:.0f}%", va="center", fontsize=8)
        ax.set_xlim(0, 112)
        ax.set_xlabel("mean share of that model's GPUs allocated")
        ax.set_title("Which accelerators are in demand")
        return fig

    def partition_utilisation(self, figsize=(8, 4.5)):
        """Core pressure, CPU partitions only.

        GPU partitions are deliberately absent: their core utilisation is an
        artefact of how many cores happen to sit beside each accelerator, so
        putting them on the same axis invites exactly the wrong conclusion.
        They get `gpu_partition_utilisation()` instead.
        """
        p = pd.DataFrame(self.digest["partitions"]).dropna(subset=["utilisation_pct"])
        p = p[p.get("kind", "cpu") == "cpu"].sort_values("utilisation_pct")
        if p.empty:
            return None
        fig, ax = plt.subplots(figsize=figsize)
        ax.barh(p["partition"], p["utilisation_pct"],
                color=[_colour(x) for x in p["partition"]])
        ax.axvline(100, color="#c05f6b", ls="--", lw=1)
        for y, (v, ch) in enumerate(zip(p["utilisation_pct"], p["core_hours"])):
            ax.text(v + 1, y, f"{v:.0f}%  ({ch:,.0f} ch)", va="center", fontsize=7)
        ax.set_xlabel("core-hours allocated as % of partition capacity")
        ax.set_xlim(0, max(115, p["utilisation_pct"].max() * 1.25))
        ax.set_title("Pressure by partition (CPU partitions)")
        return fig

    def gpu_partition_utilisation(self, figsize=(8, 4)):
        """The same idea for GPU partitions, measured in accelerators held.

        On a GPU node the GPUs are the resource that runs out; the cores beside
        them are a rounding error in the scheduling decision.
        """
        g = self.digest.get("gpus")
        if not g or not g.get("by_partition"):
            return None
        rows = sorted(g["by_partition"].items(),
                      key=lambda kv: kv[1]["mean_alloc_pct"] or 0)
        labels = [f"{p}  ({v['nodes']} nodes)" for p, v in rows]
        vals = [v["mean_alloc_pct"] or 0 for _, v in rows]
        fig, ax = plt.subplots(figsize=figsize)
        ax.barh(labels, vals, color=[SKY(v / 100) for v in vals],
                edgecolor="#7f8b93", lw=0.4)
        for y, v in enumerate(vals):
            ax.text(v + 1.2, y, f"{v:.0f}%", va="center", fontsize=7.5)
        ax.set_xlim(0, 112)
        ax.set_xlabel("mean share of the partition's GPUs allocated")
        ax.set_title("Pressure by partition (GPU partitions, accelerators not cores)")
        return fig

    def timeline(self, figsize=(9, 4)):
        """Allocated cores over time, stacked by partition."""
        nbins = {1: 48, 7: 84}.get(self.meta["days"], 60)
        edges = pd.date_range(self.start, self.end, periods=nbins + 1)
        j = self.jobs[self.jobs["start"].notna()]
        js = j["start"].values.astype("datetime64[s]").astype(np.int64)
        je = j["end"].fillna(self.end).values.astype("datetime64[s]").astype(np.int64)
        bs = edges[:-1].values.astype("datetime64[s]").astype(np.int64)
        be = edges[1:].values.astype("datetime64[s]").astype(np.int64)
        width = (be - bs)[0]
        ncpus = j["ncpus"].values.astype(np.float32)
        codes = j["partition"].astype("category")
        parts = list(codes.cat.categories)
        codes = codes.cat.codes.to_numpy()

        # Accumulated in chunks: a month's jobs-by-bins matrix is several hundred
        # megabytes per temporary, which is enough to kill the Quarto kernel.
        series = {p: np.zeros(nbins, dtype=np.float64) for p in parts}
        CHUNK = 100_000
        for lo in range(0, len(j), CHUNK):
            hi = min(lo + CHUNK, len(j))
            cores = np.clip(np.minimum(je[lo:hi, None], be)
                            - np.maximum(js[lo:hi, None], bs), 0, None).astype(np.float32)
            cores *= (ncpus[lo:hi] / width)[:, None]
            for ci, p in enumerate(parts):
                m = codes[lo:hi] == ci
                if m.any():
                    series[p] += cores[m].sum(axis=0)
            del cores
        s = pd.DataFrame(series, index=edges[:-1])
        s = s[s.sum().sort_values(ascending=False).index]
        keep = list(s.columns[:8])
        if len(s.columns) > 8:
            s["other"] = s[[c for c in s.columns if c not in keep]].sum(axis=1)
            s = s[keep + ["other"]]

        fig, ax = plt.subplots(figsize=figsize)
        ax.stackplot(s.index, [s[c] for c in s.columns], labels=list(s.columns),
                     colors=[_colour(c) for c in s.columns], alpha=0.9)
        total = self.nodes["cpus"].sum()
        ax.axhline(total, color="#241f2e", ls=":", lw=1.2)
        ax.annotate(f"{total:,} cores installed", xy=(1.0, total), xytext=(-4, 3),
                    textcoords="offset points", xycoords=("axes fraction", "data"),
                    ha="right", va="bottom", fontsize=7, color="#241f2e")
        ax.set_ylim(0, total * 1.12)
        ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.22), ncol=5,
                  fontsize=7.5, frameon=False)
        ax.set_ylabel("cores allocated")
        ax.set_title("The barometric trace: cores under allocation")
        self._date_axis(ax)
        return fig

    def _date_axis(self, ax):
        """Label the time axis with the day of the week.

        The shape of this trace is a weekly rhythm -- the Monday morning surge,
        the Saturday trough -- and a reader cannot see that in bare dates. Which
        day a dip landed on is usually the whole explanation for it.

        Density is chosen by period: a week gets every day, a month gets Mondays
        only (thirty weekday labels is noise, and once the reader has the Mondays
        they can count). A single day is left on clock time, where the weekday is
        already in the report's subtitle.
        """
        days = self.meta["days"]
        if days <= 1:
            ax.figure.autofmt_xdate()
            return
        if days <= 10:
            ax.xaxis.set_major_locator(DayLocator())
            ax.xaxis.set_major_formatter(DateFormatter("%a %-d"))
        else:
            ax.xaxis.set_major_locator(WeekdayLocator(byweekday=MONDAY))
            ax.xaxis.set_major_formatter(DateFormatter("%a %-d %b"))
            ax.xaxis.set_minor_locator(DayLocator())
        ax.tick_params(axis="x", labelsize=7.5)
        for label in ax.get_xticklabels():
            label.set_ha("center")

    def submission_clock(self, figsize=(5.2, 5.2)):
        """Submissions by hour of day on a 24-hour polar dial."""
        r = self.digest.get("rhythms", {}).get("submissions_by_hour", {})
        if not r:
            return None
        counts = np.array([r.get(str(h), r.get(h, 0)) for h in range(24)], dtype=float)
        theta = np.linspace(0, 2 * np.pi, 24, endpoint=False)
        fig, ax = plt.subplots(figsize=figsize, subplot_kw={"projection": "polar"})
        ax.bar(theta, counts, width=2 * np.pi / 24 * 0.9,
               color=SKY(counts / max(counts.max(), 1)), edgecolor="white", lw=0.4)
        ax.set_theta_zero_location("N")
        ax.set_theta_direction(-1)
        ax.set_xticks(theta[::2])
        ax.set_xticklabels([f"{h:02d}" for h in range(0, 24, 2)], fontsize=8)
        ax.set_yticklabels([])
        ax.set_title("When jobs are submitted (local time)", pad=18)
        return fig

    def wait_distribution_cpu(self, figsize=(8, 4)):
        """Queue waits for jobs that did not ask for a GPU."""
        return self._wait_hist(asked_for_gpu=False, colour="#4f8fbf",
                               title="How long the queue made you wait — CPU jobs",
                               figsize=figsize)

    def wait_distribution_gpu(self, figsize=(8, 4)):
        """Queue waits for jobs that asked for at least one GPU.

        Kept separate because the two queues have almost nothing to do with each
        other: CPU jobs wait for cores, GPU jobs wait for accelerators and for
        per-user GPU limits. Pooling them produces a bimodal blur whose median
        describes neither population.
        """
        return self._wait_hist(asked_for_gpu=True, colour="#8a6bb0",
                               title="How long the queue made you wait — GPU jobs",
                               figsize=figsize)

    def _wait_hist(self, asked_for_gpu, colour, title, figsize):
        j = self.jobs
        # Jobs that actually started inside the window -- the same population the
        # digest reports, so the chart and the tables cannot disagree. Including
        # jobs that started earlier would count waits served in a previous period.
        started = j["start"].notna() & (j["start"] >= self.start) & (j["start"] <= self.end)
        # Every such job falls into exactly one of the two plots. Splitting on what
        # was requested rather than on the partition means nothing is silently
        # dropped, which matters for a distribution.
        base = started & j["wait_s"].notna()
        w_all = (j.loc[base, "wait_s"] / 60)
        sel = (j["ngpus"] > 0) if asked_for_gpu else (j["ngpus"] == 0)
        w = (j.loc[base & sel, "wait_s"] / 60)
        if w.empty or w_all.empty:
            return None

        # Shared bin edges across both plots so the two are read side by side
        # without an axis change doing the arguing.
        lo = 0.05
        bins = np.logspace(np.log10(lo), np.log10(max(w_all.max(), 1)), 50)
        # A log axis cannot show a zero wait, so jobs that started immediately are
        # clamped into the first bin rather than dropped -- otherwise the chart's
        # job count would quietly disagree with the digest's.
        w = w.clip(lower=lo)

        fig, ax = plt.subplots(figsize=figsize)
        ax.hist(w, bins=bins, color=colour, edgecolor="white", lw=0.3)
        ax.set_xscale("log")
        ax.set_xlim(bins[0], bins[-1])
        for q, c in ((0.5, "#e0813c"), (0.9, "#c05f6b")):
            v = w.quantile(q)
            ax.axvline(v, color=c, ls="--", lw=1.2,
                       label=f"p{int(q*100)} = {v:,.0f} min")
        ax.legend(frameon=False, fontsize=8, title=f"{len(w):,} jobs",
                  title_fontsize=8)
        ax.set_xlabel("queue wait (minutes, log scale)")
        ax.set_ylabel("jobs")
        ax.set_title(title)
        return fig

    def efficiency_scatter(self, figsize=(8, 5)):
        """Allocation size against CPU efficiency: the bottom-right is where
        the wasted core-hours live.

        CPU partitions only. A GPU job holding twelve cores to feed one
        accelerator scores terribly here and is doing nothing wrong, so including
        them would put well-run work at the top of a list headed "waste".
        """
        gpu_parts = set(self.digest.get("gpu_partitions", []))
        j = self.jobs[self.jobs["cpu_eff_measured"] & (self.jobs["ncpus"] >= 4)
                      & (self.jobs["elapsed_s"] > 600) & (self.jobs["ngpus"] == 0)
                      & ~self.jobs["partition"].astype(str).isin(gpu_parts)]
        if j.empty:
            return None
        fig, ax = plt.subplots(figsize=figsize)
        sizes = np.clip(j["core_hours"] / 8, 3, 400)
        ax.scatter(j["ncpus"], j["cpu_eff"] * 100, s=sizes, alpha=0.35,
                   c=[_colour(p) for p in j["partition"]], linewidths=0)
        # Log base 2: people request cores in powers of two, and on a log10 axis
        # the 4/8/16/32 cluster that most jobs live in is squashed into the first
        # third of the plot.
        ax.set_xscale("log", base=2)
        ax.xaxis.set_major_formatter(ScalarFormatter())
        ax.xaxis.set_minor_formatter(NullFormatter())
        ax.axhline(100, color="#5fa77c", ls=":", lw=1)
        ax.axhline(20, color="#c05f6b", ls="--", lw=1)
        ax.text(j["ncpus"].min(), 22, " below here, most of the allocation idles",
                fontsize=7, color="#c05f6b")
        ax.set_xlabel("cores allocated (log$_2$ scale)")
        ax.set_ylabel("CPU efficiency (%)")
        ax.set_ylim(0, 140)
        ax.set_title("Allocation vs. actual CPU use (bubble size = core-hours)")
        return fig

    def state_bars(self, figsize=(8, 3.2)):
        c = self.digest["outcomes"]["core_hours_by_state"]
        if not c:
            return None
        s = pd.Series(c).sort_values()
        colours = {"COMPLETED": "#5fa77c", "FAILED": "#c05f6b", "TIMEOUT": "#e0813c",
                   "OUT_OF_MEMORY": "#8a6bb0", "CANCELLED": "#7f8b93",
                   "PREEMPTED": "#b8ab48", "NODE_FAIL": "#241f2e"}
        fig, ax = plt.subplots(figsize=figsize)
        ax.barh(s.index, s.values, color=[colours.get(k, "#4f8fbf") for k in s.index])
        for y, v in enumerate(s.values):
            ax.text(v, y, f" {v:,.0f}", va="center", fontsize=7)
        ax.set_xlabel("core-hours")
        ax.set_title("Where the compute ended up")
        return fig
