# What the numbers mean, and where SLURM lies

Read this before writing anything that characterises a job, a user or a project
as wasteful. Several of the most tempting statistics in the digest are partly
artefacts, and a bulletin that names someone on the strength of an artefact is
worse than no bulletin.

## CPU efficiency is frequently missing, not zero

`cpu_eff` is `TotalCPU / (Elapsed x NCPUS)`, with `TotalCPU` summed over job
steps. On M3 a large minority of substantial jobs record essentially **no**
`TotalCPU` at all — a 48-core VASP run lasting three days reporting 2.5 seconds
of CPU time. Those jobs were not idle. SLURM's accounting only sees processes it
launched, so an MPI code started with `mpirun` rather than `srun` is invisible to
it, and jobs that fork their real work into a container or a scheduler of their
own can be too.

The digest therefore splits sizeable jobs into:

- `judged_jobs` — CPU efficiency of at least 1%, believable, safe to discuss.
- `unmeasured_jobs` — near-zero recorded CPU time, reported separately under
  `biggest_unmeasured` and **excluded** from every efficiency figure.

Never present an unmeasured job as an idle one. If it is worth mentioning at all,
say the accounting is missing and move on. The honest framing is "we cannot see
what these jobs did", and it is a legitimate small segment in its own right —
occasionally worth noting that `srun` would make the work visible.

Genuinely low-but-measured efficiency (2–20%) is real and fair game, though even
then a single-threaded step in a multi-core allocation may be a deliberate
memory-per-core request rather than an error.

## MaxRSS under-reports, so memory over-allocation is safe to report

`MaxRSS` is the peak resident set of the single largest **task**, not the sum
across a job. For a multi-process job the real footprint is higher than reported.

This bias runs in the forgiving direction: if a job asked for 700 GB and the
largest task peaked at 1.3 GB, the request is over-sized however many tasks there
were. Memory over-allocation is consequently the most defensible efficiency story
in the digest, and usually the most useful — over-requested memory blocks other
people's jobs far more effectively than idle cores do.

State it as request versus observed peak and let the reader draw the conclusion.

### The ledger's thresholds

`worst_memory_offenders` only includes jobs that requested over 100 GB, used
under 10% of it, and **ran for at least an hour**
(`MEMORY_LEDGER_MIN_ELAPSED_S`). The runtime floor matters twice over: a job that
asked for 900 GB and exited after four minutes inconvenienced nobody, and
`MaxRSS` sampling on a very short job may simply have missed the peak, which
would make the entry not merely trivial but wrong. Since the ledger names people,
it should only carry entries that are both real and consequential.

Runtime is reported alongside the memory figures because it is what converts an
over-request into a cost — 1.2 TB held for seven days is a different problem from
1.2 TB held for an hour, and the table should let a reader tell them apart.

The ledger deliberately does **not** apply the 8-core floor that the CPU
efficiency section uses. Core count is beside the point here: a single-core job
sitting on a terabyte blocks a node exactly as effectively as a 48-core one, and
is usually the more fixable mistake — nobody chose that memory figure for a
reason, it was copied from a template.

### Desktops are ledgered separately, and judged differently

`worst_memory_offenders` covers **batch** partitions (CPU partitions other than
`desktop`); `worst_memory_offenders_desktop` covers the `desktop` partition. They
are two tables because the same row means opposite things depending which side it
is on.

A Strudel desktop holding a large memory reservation with an idle CPU is the
product working as intended — someone is reading a figure, or has stepped away
from a session they will come back to, and interactivity is the whole point of
the partition. Report that side gently, as capacity planning rather than
misbehaviour: it says something about how desktops are sized and how long people
keep them, not about anyone's submission script.

The identical profile on `comp`, `genomics` or especially `genomicsb` is a scarce
batch node held out of the pool for no return, and `genomicsb`'s large-memory
nodes are the scarcest thing on the cluster. That is the table to lead with, and
the only one on which the word "waste" is fair.

Do not write the same paragraph under both.

CPU efficiency is shown as a column so the reader can tell an over-request from
an idle job, but it is subject to the accounting gap above: where `TotalCPU` was
never recorded the cell reads *not recorded* rather than 0%. That distinction
matters most in exactly this table, because it is the one that names people.

### Multi-node rows: requested memory is the sum across nodes

`Requested` is the memory SLURM **allocated**, summed over every node, while
`Peak used` is the largest single task. For a one-node job those are comparable.
For a multi-node job they are not. On 9 Sep 2026 an `interactive_session`
(job 59916418) that asked for 400 GB and 128 cores, without fixing a node count,
was spread over seven `genomicsb` nodes at 400 GB each. The ledger read
"2,800 GB requested, 1.7 GB used", which sounds like a mistyped `--mem`. It was
actually six large-memory nodes held with nothing running on them. That calls
for a different fix, `--nodes=1`, and describing it as a 2.8 TB request would
be wrong.

The ledger therefore carries a `Nodes` column. Whenever it is above 1, divide
before describing the request, and say how many nodes were held.

## Multi-node jobs that only used one node

The collector records `active_nodes`: the number of distinct nodes on which any
job step ran (`batch` or an `srun` step). The `extern` step is ignored, because
SLURM places it on every allocated node whether or not anything runs there.
When `active_nodes` is 1 and the job held several nodes, the table cell reads
`7 (only 1 used)`. The digest summarises these jobs under
`efficiency.idle_nodes`, and `rpt.idle_node_jobs()` tables the largest. Idle
core-hours assume cores were spread evenly across the nodes.

The usual causes are a script that never uses `srun` in a multi-node allocation,
a missing `--nodes=1` on an interactive or desktop request, or a core count too
big for one node that SLURM satisfied by adding nodes.

It is a strong signal, not proof. An MPI code started over **ssh** rather than
through SLURM leaves no steps on the other nodes and shows as `only 1 used`
while working on all of them. On M3 this looks uncommon: on 9 Sep 2026,
multi-node `mpirun` jobs whose CPU time was not recorded still showed a step on
every node, because OpenMPI and Intel MPI launch through `srun` under SLURM. The
two cases need different handling:

- **An interactive, desktop or `bash` session.** A multi-node session using one
  node is almost certainly what it looks like.
- **A batch job with a scientific name and unrecorded CPU.** Treat the flag as a
  question. Say the other nodes show no recorded steps, and suggest checking it
  with `jobstats <id>` rather than stating that they sat idle.

Periods collected before this was added (cache v4 and earlier) have no
`active_nodes` column. Their cells show only the node count, and the digest says
the flag was not measured.

## Core-hours are allocated, not consumed

Every core-hour figure counts cores *held* for the time they were held. This is
the right measure for scheduling pressure and for "who is using the cluster", and
the wrong measure for "who did the most computing". Say "delivered" or
"allocated", not "used".

Jobs spanning the window boundary are clipped to the window, so a seven-day job
contributes only its overlap. Utilisation above 100% for a partition means the
capacity denominator is off, not that physics broke — see below.

## Partition capacity is approximate

Nodes belong to several partitions at once. Capacity is attributed to each node's
*primary* partition, chosen as the most specific one it belongs to, while a job's
core-hours are attributed to the partition it actually ran in. Where those
disagree — a job in `comp` landing on a node whose primary partition is `peach` —
per-partition utilisation can drift somewhat above or below the truth.

Treat per-partition utilisation as a strong signal of relative pressure and a
weak one of absolute capacity. "Much busier than `genomics`" is supportable; "at
exactly 99.0% of capacity" is more precision than the method earns. Cluster-wide
utilisation, which uses every node once, is sound.

### The heatmap and the partition table can disagree

This bites hardest where a partition's nodes are wholly contained in a larger
one. `m3j`'s nodes are also `comp` nodes, so the heatmap band labelled `m3j`
looks fully dark (those nodes are busy) while the partition table shows `m3j` at
around 1% (almost nobody submits *to* `m3j`). Both are correct: the heatmap is a
**node** view and the table is a **job** view.

Before calling a partition idle, check whether its nodes are shared. `sinfo -N -o
"%N %P"` shows every node's partition memberships. Genuinely idle partitions —
ones whose nodes appear nowhere else — are pale in the heatmap *and* low in the
table; anything else deserves the extra sentence of explanation.

## Node-level allocation splits evenly

For the heatmaps, a multi-node job's cores (or GPUs) are divided equally across
the nodes in its list. That is exact for the usual homogeneous allocation and
approximate otherwise. Fine for spotting cold nodes and busy blocks; not an audit
trail.

`sacct` also records a job's **final** node list. A job that was requeued or
preempted onto a different node has its whole elapsed time attributed to wherever
it finished, so a node can appear to hold more than 100% of its cores or GPUs.
Both maps cap the fraction at 1.0 and record the overshoot rate as
`overallocated_bin_pct`; on M3 it typically runs around 1% of node-time bins,
which is small enough to ignore and large enough that you should not quote a
single node's utilisation to three significant figures.

## The GPU map is not the CPU map

`gpu_heatmap()` and the `gpus` block in the digest cover only nodes with
accelerators, and measure the fraction of **GPUs** held rather than cores. The
two maps routinely disagree, and the disagreement is the point: a GPU node
frequently sits at 20% on cores and 100% on accelerators, because a one-GPU job
on a 52-core node strands the other 48 cores by design. Never infer GPU pressure
from the CPU map.

Break GPU utilisation down **by model** before drawing any conclusion. An
aggregate figure like "54% of GPUs allocated" is close to meaningless on a fleet
where the current generation runs at 85-95% and the previous one at 11-40%; the
aggregate is the average of a saturated fleet and an idle one, describing
neither. `by_type` in the digest carries the split.

GPU counts and models come from `sinfo`'s Gres field (`gpu:A100:2`), which is
current state — if a node's cards were changed mid-window, the whole window is
attributed to whatever it reports now.

### Idle GPUs are usually idle for a reason — check reachability before advising

Splitting GPU utilisation by model is necessary but **not sufficient**, and
stopping there produces confidently wrong advice. The older cards look idle
because most of them are not openly available, so "the T4s are free, use those"
sends people at capacity they cannot actually submit to.

Measured on 2026-08-29, the idle GPU-hours broke down as:

| Where | Capacity | Idle | Allocated |
|---|---:|---:|---:|
| Open batch partitions (`gpu`, `fit`, `bdi`, `m3h`, `bdi-imaging`) | 5,472 | 308 | 94.4% |
| `ccemmp` + `sexton` (need `--qos=irq`) | 3,792 | 3,418 | 9.9% |
| `desktop` (Strudel, not for batch) | 4,752 | 2,137 | 55.0% |
| `hudson` (closed QoS) | 96 | 96 | 0.0% |

The cluster-wide figure was 58% allocated; the number that describes what a user
can actually get was **94.4%**. Those are different claims about different
populations, and only the second one is actionable.

So before writing any sentence recommending under-used GPUs, group the idle
GPU-hours by `primary_partition` and check each partition's `AllowQos` with
`scontrol show partition <name>`. The three cases need different sentences:

- **Open partitions** (`AllowQos=ALL`, or a QoS every user holds) — genuinely
  available; recommend freely.
- **`AllowQos` including `irq`** — reachable, but only as preemptible work.
  Recommend it *and say so*: it suits checkpointing jobs and sweeps, and
  recommending it without the caveat will get someone's twelve-hour run killed.
- **A partition-specific QoS only** (`hudson`, and `ccemmp`/`sexton` for anyone
  without `irq`) — not available; exclude it from the advice entirely, and
  consider excluding it from any "spare capacity" figure you quote.

The `desktop` partition is a fourth case: its GPUs are real but the partition is
for interactive Strudel sessions, so idle capacity there is a sizing observation,
not somewhere to send batch work.

Node states matter here too. A node at exactly 0% is often `reserved`, `drained`
or `down` rather than merely unwanted — cross-check `node_health` before calling
a cold node an opportunity.

## Queue waits include jobs that were never ready

`wait_s` is `Start - Submit`. A job held by a dependency, or submitted with a
future start time, or held by the user, spent much of that "wait" ineligible
rather than queuing. Medians are robust enough to quote; individual extreme waits
(hundreds of hours) are almost always dependencies or holds, so check the pending
reasons in the digest before calling any of them a scheduling problem.

`bdi` showing a 28-hour median wait alongside 5% utilisation is the signature of
this: a QOS or association limit, not scarcity. The `pending_reasons` breakdown
distinguishes them — `Priority` and `Resources` mean contention, while
`QOSMax*`, `AssocGrp*` and `Dependency` do not.

### Never quote a pooled median wait

CPU and GPU are two separate queues that happen to share a scheduler, and their
waits differ by orders of magnitude — on a typical M3 day, a CPU median under two
minutes against a GPU median over ninety. The pooled median sits between them and
describes neither population; quoting it makes the cluster sound uniformly
responsive to people who are in fact waiting all afternoon for an A100.

`waiting.by_resource` in the digest splits both the started-job waits and the
live pending queue on whether the job asked for a GPU. Every job with a wait falls
into exactly one side, so nothing is dropped. Both plots share bin edges so they
can be read against each other without an axis change doing the arguing, and jobs
that started instantly are clamped into the first bin rather than dropped, so the
chart's job count matches the digest's.

The population for both is jobs that **started inside the window**. A job still
pending at the end of the window has no wait yet, and one that started before it
did its waiting in a previous report.

## States and what counts as failure

`FAILED`, `TIMEOUT`, `OUT_OF_MEMORY`, `NODE_FAIL` and `BOOT_FAIL` count as
failure. `CANCELLED` deliberately does not — users cancel jobs for good reasons
all the time, and counting it as failure makes the success rate meaningless.
`PREEMPTED` is not failure either; it is the `irq` QOS working as designed, and
preempted jobs are normally requeued.

`NODE_FAIL` is worth calling out separately when it appears in volume: unlike the
others it is the cluster's fault, not the user's.

## Live snapshots cannot be backfilled

`squeue` and `sinfo` data is captured at collection time. Pending counts, pending
reasons and node states describe the moment `collect.py` ran, not the reporting
window. Say "right now" or "at the time of writing", and note that a monthly
report's node-health section is a snapshot rather than a month of downtime.

## Job name heuristics are heuristics

Nextflow, Snakemake, interactive and desktop jobs are detected by name pattern.

**Nextflow** is the reliable one, and the rule is specific: a name beginning
`nf-` followed by **capitals** — `nf-GENERATE_REPORT_(M24033)`,
`nf-BINDCRAFT_BINDCRAFT_PROCESS_(89)` — is almost certainly a Nextflow pipeline
task, because Nextflow generates that prefix itself and process names are
uppercase by convention. The capitals are load-bearing: matching a
case-insensitive bare `nf-` sweeps in unrelated jobs that merely contain those
characters. That branch of the pattern is deliberately case-sensitive. A
lowercase `nf-something` job will be missed, which is the right trade — a
Nextflow count that is slightly low beats one inflated by false positives.

**Interactive** detection is much weaker: a batch job named `bash` is
indistinguishable from a real interactive session. Use these counts for colour
and scale, not for precise accounting.

## CPU and GPU partitions are reported separately

A partition is treated as GPU-oriented when at least half its nodes carry
accelerators (`GPU_PARTITION_NODE_FRACTION`). Those partitions are **excluded**
from the core-utilisation chart and from the CPU efficiency scatter, and appear
instead on the GPU charts measured in accelerators.

This is not cosmetic. A job holding twelve cores to feed one GPU has a CPU
efficiency near zero and is doing exactly the right thing; a partition whose
nodes carry 52 cores beside four GPUs will show low core utilisation whenever the
GPUs are the binding constraint. Mixing them into the CPU views puts well-run work
at the top of a list headed "waste", which is both wrong and unfair to name people
under.

The partition field can list several (`sbatch -p gpu,fit,bdi`); such a job is
classified by the most GPU-heavy partition it could land on.

## The Melbourne calendar

The band across the top of each heatmap marks Victorian public holidays and
government-school holiday periods, from `assets/calendar-vic.toml`. It exists
because M3's load follows Melbourne's calendar: without it, the Easter trough or a
fortnight of quiet in the July school holidays reads as an unexplained outage.

The dates cannot be computed — Easter moves and Victoria gazettes one-off
holidays such as the Friday before the AFL Grand Final — so they are typed into
the file and must be **verified and extended** for each new year. The file
records which years it has data for; a window in an unlisted year draws a band
saying so, rather than an empty band that would look identical to a genuinely
holiday-free stretch. Treat a report whose narrative leans on holiday timing as
unverified until someone has checked the file against the sources listed in it.

School holidays are the Victorian **government** school dates. Independent and
Catholic schools differ by a few days, and university teaching periods differ
entirely, so treat the band as an indication of when parents are likely to be
away rather than a precise driver of cluster load.
