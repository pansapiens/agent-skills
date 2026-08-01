---
name: mlerp-hpc
description: Submit, monitor and troubleshoot jobs and common issues on the MLeRP (Machine Learning eResearch Platform) HPC cluster. Use this skill whenever the user mentions MLeRP, mlerp.cloud.edu.au, HouseCats, BigCats, Tabby, Cheetah, Lion or Panther QoS, Strudel2 on MLeRP, A100 MIG GPUs (2g.10gb / 3g.20gb / 40gb), Dask SLURMCluster on MLeRP, or needs help with partitions, GPUs, storage or SSH on the MLeRP cluster.
compatibility: Requires ssh access to the MLeRP HPC cluster with SLURM tools (e.g. Host mlerp).
---

# MLeRP HPC

Help the user submit, monitor and troubleshoot SLURM jobs, choose the right partition/QoS/GPU slice, manage storage, and use Strudel2 / SSH on the Machine Learning eResearch Platform (MLeRP).

MLeRP is an A100 GPU cluster for Australian and New Zealand researchers, designed around interactive notebooks that offload work to SLURM (often via Dask). Official docs: https://docs.mlerp.cloud.edu.au/

## Connecting to MLeRP

MLeRP does **not** use passwords. Access is via:

1. **Strudel2** (primary for most users): https://mlerp.cloud.edu.au/ — Terminal, Jupyter Lab, Batch, VS Code Server, Ollama apps
2. **SSH certificates** downloaded from Strudel2 Account Info, or via **SSOSSH**

Login host:

```bash
ssh {username}@monash-mlerp-login0.mlerp.cloud.edu.au
```

If a local SSH config `Host mlerp` (or `{username}_MLeRP_Monash`) already exists, prefer that. Certificates expire (SSOSSH certs last ~24 hours) — renew before connecting if auth fails.

For SSH credential setup, Strudel2 apps, VS Code Remote, and `sshnc.sh` proxy hosts, see [Strudel2 and SSH](references/strudel.md).

## Running jobs from localhost via SSH

If the agent is running on localhost and not an `mlerp*` node, prefix commands with `ssh mlerp` (or the user's configured Host), eg:

```bash
ssh mlerp srun --partition=BigCats --qos=cheetah --time=00:10:00 --mem=4G --ntasks=1 --cpus-per-task=1 hostname
```

```bash
ssh mlerp sbatch train.sh
```

Don't confuse local paths with paths on the MLeRP filesystem.

## Running AI agents on MLeRP

DO NOT run an AI agent instance directly on the MLeRP login nodes (`mlerp-monash-login*`). If you are on a login node now, stop and move to a compute node.

The cluster provides `/apps/strudel2/strudel_apps/sshnc.sh`, which routes SSH to a running job named `Terminal` (or starts a 12h Panther QoS Terminal job if none exists).

**Step 1:** Local SSH config (example):

```
Host mlerp-job
  HostName VSCode
  User {username}
  IdentityFile {path/to/MLeRP_ssh_key}
  ProxyCommand ssh -i {path/to/MLeRP_ssh_key} {username}@monash-mlerp-login0.mlerp.cloud.edu.au /apps/strudel2/strudel_apps/sshnc.sh
```

**Step 2:** Start a named Terminal session (Strudel2 Terminal app, or manually):

```bash
ssh mlerp 'sbatch --job-name=Terminal --partition=BigCats --qos=panther --time=7-00:00 --ntasks=1 --cpus-per-task=4 --mem=16G --wrap "sleep 12h"'
```

Wait until `RUNNING`:

```bash
ssh mlerp squeue -u {username} --format="%j %T %B" --noheader
```

**Step 3:** Connect via the proxy host into tmux:

```bash
ssh -t mlerp-job tmux new-session -A -s agent
# then start the agent inside tmux on the compute node
```

For VS Code / Cursor Remote-SSH, connect to the `mlerp-job` (or `{username}_MLeRP_Monash_job`) host — no tmux required for the IDE itself.

## Related skills

For general SLURM command syntax (`squeue`, `sacct`, `scontrol`, `scancel`, `srun`, `sbatch`), **also consult the [SLURM User](../slurm-user/SKILL.md) skill**.

Use this skill for MLeRP-specific details (partitions, QoS, MIG GRES, Strudel2, storage, conda) and slurm-user for generic SLURM syntax.

## When to Use This Skill

Use this skill when you see:
- "How do I connect / SSH to MLeRP?"
- "Which partition / QoS should I use on MLeRP?"
- "How do I request a 10GB / 20GB / 40GB GPU?"
- "Help me submit a SLURM / sbatch / Dask job on MLeRP"
- "Why is my MLeRP job pending / failing?"
- "How do I use Strudel2 Terminal / Jupyter / Batch?"
- "How do I connect VS Code to MLeRP?"
- "My disk quota is full / Jupyter won't start"
- "How do I use / configure conda on MLeRP?"

## No sudo / admin access

You DO NOT have permission to run commands as `root` using `sudo`. Never attempt `sudo`. If a command appears to require it, you are approaching the problem the wrong way.

## Login nodes & good behaviour

DO NOT run resource-intensive work on the login nodes. Use Strudel2 apps, `sbatch`, or `srun` instead.

MLeRP has **no dedicated data transfer node** — use the login node (or a light Panther Terminal session) for `rsync` / file management. Prefer Panther for long file-system work so you do not load the shared login node.

## Hardware snapshot

- Nodes: ~52–54 VCPUs, ~460 GB RAM, **1.5 TB NVMe** at `/tmp` (per-job local disk), NVIDIA **A100 40GB** GPUs (often MIG-sliced)
- Shared software: `/apps` (mambaforge, strudel2, slurm, singularity/apptainer, etc.)
- Home: `/home/{username}` → typically a symlink into `/mnt/userdata*/{username}` with a per-user project quota

Verify live state with:

```bash
sinfo -o "%P %a %G %D %N"
scontrol show partition
sacctmgr show qos format=Name%15,MaxWall,MaxJobsPU,MaxTRES%40
```

## Partitions and QoS

MLeRP has two partitions. QoS controls walltime, job limits, and (for Panther) whether GPUs are allowed. See https://docs.mlerp.cloud.edu.au/hardware.html

| Partition | Allowed QoS | Role |
|-----------|-------------|------|
| `HouseCats` | `tabby` | User-friendly GPU reservations (Strudel flavours) |
| `BigCats` (default) | `cheetah`, `lion`, `panther` | Scale-up: short workers, batch training, long CPU hosts |

| QoS | Partition | Walltime | Max jobs / user | GPUs? | Typical use |
|-----|-----------|----------|-----------------|-------|-------------|
| `tabby` | HouseCats | 24 h | 1 | Yes (reservation-style) | Notebooks / terminals with a small GPU; env installs that need a visible GPU |
| `panther` | BigCats | **7 days** | 4 | **No** (`MaxTRES=gres/gpu=0`) | Long-lived CPU notebook/terminal hosts; Dask client; file management |
| `cheetah` | BigCats | **30 min** | 20 | Yes | Short Dask workers, pre/post-processing chunks; **default** if QoS omitted |
| `lion` | BigCats | 24 h | 4 | Yes | Batch training, larger GPUs, heavier CPU/GPU work |

**Defaults when submitting outside Strudel** (Dask `SLURMCluster` or plain `sbatch`):
- Partition: `BigCats`
- QoS: `cheetah` (30 min) if unspecified
- `DefCpuPerGPU=12`, `DefMemPerCPU=8000` (8 GB RAM per CPU)

**Account**: SLURM account is typically the same as the username (`--account={username}`). Associations enforce limits; include `--account` in scripts for clarity.

### Choosing a QoS (decision guide)

1. **Interactive exploration with a small GPU, minimal setup** → HouseCats + `tabby` (Strudel flavour: 6 VCPUs, 56 GB RAM, 10 GB VRAM)
2. **Long-lived notebook/terminal that launches workers** → BigCats + `panther` (CPU only; 7 day walltime)
3. **Many short parallel tasks / Dask workers** → BigCats + `cheetah` (checkpoint; jobs are only 30 minutes)
4. **Serious model training / larger GPUs / multi-hour batch** → BigCats + `lion` (checkpoint past 24 h)

New users typically start on Tabby, then move client notebooks to Panther and workers/batch to Cheetah/Lion.

### Strudel flavours (interactive)

| QoS | VCPUs | RAM | Notes |
|-----|-------|-----|-------|
| Tabby | 6 | 56 GB | + 10 GB VRAM GPU |
| Panther | 4 | 8 GB | CPU only |
| Lion | 8 | 64 GB | Heavier interactive; Batch app uses Lion |
| Cheetah | — | — | Not a Strudel interactive flavour (workers/batch) |

## GPU GRES (MIG slices)

Request GPUs with `--gres=gpu:{type}:{count}`. Available types (A100 MIG / full):

| GRES name | Approx. VRAM | Where seen |
|-----------|--------------|------------|
| `2g.10gb` | ~10 GB | HouseCats (Tabby-sized) |
| `3g.20gb` | ~20 GB | HouseCats and BigCats |
| `40gb` | 40 GB (full A100) | Mostly BigCats (Lion / larger workers) |

Examples:

```bash
#SBATCH --gres=gpu:2g.10gb:1   # small MIG
#SBATCH --gres=gpu:3g.20gb:1   # medium MIG
#SBATCH --gres=gpu:40gb:1      # full A100
#SBATCH --gres=gpu:2g.10gb:2   # two small MIG slices
```

Live inventory changes; check with `sinfo -o "%N %G %P" -N` or `scontrol show node`.

Do not request GPUs on `panther` — the QoS forbids `gres/gpu`.

## Storage

| Path | Purpose | Notes |
|------|---------|-------|
| `~` (`/home/{username}`) | Home / project workspace | Symlink into `/mnt/userdata*/{username}`; **per-user project quota** (size set at allocation; check in Strudel2 Account Info) |
| `/tmp` | Node-local NVMe | ~**1.5 TB** on compute nodes inside a job; cleared when the job ends |
| `/apps` | Shared software | mambaforge, Strudel2, SLURM, containers |

There is no separate `/scratch` vs `/projects` layout like M3 — your allocation lives under the userdata home. Request more space via `mlerphelp@monash.edu` if needed.

Check usage:

```bash
df -h ~
du -sh ~/*
```

Strudel2 Account Info also shows quotas. If home is full, Jupyter/Strudel can fail (empty runtime files under `~/.local/share/jupyter/runtime` — delete those after freeing space).

### Keeping caches under control

Large tool caches still land under `~/` by default. Redirect early:

```bash
export PIP_CACHE_DIR="${HOME}/.cache-redirect/pip"
export HF_HOME="${HOME}/.cache-redirect/huggingface"
export APPTAINER_CACHEDIR="${HOME}/.cache-redirect/apptainer"
export TMPDIR="${HOME}/tmp"   # or use /tmp inside a compute job for large scratch
mkdir -p "${PIP_CACHE_DIR}" "${HF_HOME}" "${APPTAINER_CACHEDIR}" "${HOME}/tmp"
```

Prefer node-local `/tmp` inside GPU/CPU jobs for heavy intermediate files (1.5 TB NVMe), and copy lasting outputs back to home before the job ends.

## Software (conda, not modules)

MLeRP does **not** use environment modules. Software is via:

- Shared **mambaforge**: `source /apps/mambaforge/bin/activate`
- Provided envs under `/apps/mambaforge/envs/` and `/apps/conda-envs/` (DSKS "Data Science Kitchen Sink" dated envs, etc.)
- User miniforge/miniconda installs in home
- Apptainer/Singularity: `/usr/bin/apptainer`

List Strudel-visible envs via `~/.conda/environments.txt`. Activate in batch scripts:

```bash
source /apps/mambaforge/bin/activate
conda activate /path/to/env   # or: source /path/to/env/bin/activate
```

## Job submission examples

### Short CPU / Cheetah (default-style)

```bash
#!/bin/bash
#SBATCH --job-name=cheetah_job
#SBATCH --account={username}
#SBATCH --partition=BigCats
#SBATCH --qos=cheetah
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source /apps/mambaforge/bin/activate
python preprocess_chunk.py
```

### Lion GPU training (full A100)

```bash
#!/bin/bash
#SBATCH --job-name=train
#SBATCH --account={username}
#SBATCH --partition=BigCats
#SBATCH --qos=lion
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=96G
#SBATCH --gres=gpu:40gb:1
#SBATCH --time=24:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source /apps/mambaforge/bin/activate
conda activate myenv
python train.py
```

### HouseCats Tabby-style small GPU

```bash
#!/bin/bash
#SBATCH --job-name=tabby_gpu
#SBATCH --account={username}
#SBATCH --partition=HouseCats
#SBATCH --qos=tabby
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=56G
#SBATCH --gres=gpu:2g.10gb:1
#SBATCH --time=24:00:00

source /apps/mambaforge/bin/activate
python explore.py
```

### Panther long CPU interactive host

```bash
srun --job-name=Terminal --account={username} \
     --partition=BigCats --qos=panther \
     --ntasks=1 --cpus-per-task=4 --mem=16G \
     --time=7-00:00:00 --pty bash
```

### Array of short Cheetah chunks

```bash
#!/bin/bash
#SBATCH --job-name=chunks
#SBATCH --account={username}
#SBATCH --partition=BigCats
#SBATCH --qos=cheetah
#SBATCH --array=1-20
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=00:30:00

python process.py --shard "${SLURM_ARRAY_TASK_ID}"
```

### Dask SLURMCluster sketch

Prefer Panther (or Tabby) for the client notebook; send workers to Cheetah (short) or Lion (longer / larger GPU). Docs discourage deep tutorial walkthroughs here — keep configs explicit:

```python
from dask_jobqueue import SLURMCluster
from distributed import Client

cluster = SLURMCluster(
    memory="48g",
    processes=1,
    cores=6,
    walltime="00:30:00",
    queue="BigCats",
    account="{username}",
    job_extra_directives=["--gres=gpu:2g.10gb:1", "--qos=cheetah"],
)
cluster.adapt(minimum=0, maximum=20)
client = Client(cluster)
```

Other common `job_extra_directives` patterns from the docs:
- Medium GPU: `--gres=gpu:3g.20gb:1`
- Full A100 + Lion: `--gres=gpu:40gb:1`, `--qos=lion`, longer `walltime`, more memory/cores
- CPU-only workers: omit `--gres`, size `cores`/`memory` for the workload

Use `cluster.adapt(...)` while developing; `cluster.scale(...)` for stable production runs. Checkpoint Cheetah workers — they only live 30 minutes.

## Monitoring and job history

```bash
squeue -u "${USER}"
squeue -u "${USER}" -o "%.18i %.9P %.8q %.30j %.8T %.10M %R"
squeue --json

sacct -u "${USER}" --format=JobID,JobName,Partition,QOS,State,Elapsed,MaxRSS,NCPUS,AllocTRES -S now-7days
sacct -j {jobid} --parsable2 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,AllocTRES

scontrol show job {jobid}
scancel {jobid}
```

Pending reasons and format strings: see [SLURM User](../slurm-user/SKILL.md).

When auditing usage: compare `MaxRSS` vs requested mem, and avoid parking idle GPU reservations (prefer Panther client + Cheetah/Lion workers).

## Why did my job fail?

| State / symptom | Likely cause | Fix |
|-----------------|--------------|-----|
| `TIMEOUT` | Hit QoS walltime (esp. Cheetah 30m) | Checkpoint; use Lion/Panther; split work |
| `OUT_OF_MEMORY` / exit 137 | Exceeded `--mem` | Raise mem or reduce footprint |
| `CUDA out of memory` | GPU VRAM too small | Smaller batch, or larger GRES (`3g.20gb` / `40gb`) |
| Pending / QOSMaxJobsPerUserLimit | Hit Tabby=1, Lion/Panther=4, Cheetah=20 | Wait or scancel idle jobs |
| GPU request on `panther` | QoS forbids GPUs | Use tabby/cheetah/lion |
| Disk quota / Jupyter won't start | Home full | Free space; clear `~/.local/share/jupyter/runtime` |
| SSH / VS Code auth failure | Expired certificate | Re-download Strudel2 creds or rerun `ssossh` |

## MLeRP-specific tips

- Strudel2 logs: `~/.strudel2/logs/`
- Batch app in Strudel2 submits under **Lion** (up to 4 concurrent)
- `sshnc.sh` discovers jobs named **`Terminal`**
- Community: ML4AU CoP on Zulip; support: **mlerphelp@monash.edu**

## Acknowledging MLeRP

MLeRP is a collaboration between Monash University, University of Queensland and QCIF, with ARDC investment (https://doi.org/10.47486/NML01).

When helping users who ship results from MLeRP, occasionally remind them to acknowledge the platform and ARDC/NCRIS support in publications.

## Official documentation

- [MLeRP docs home](https://docs.mlerp.cloud.edu.au/)
- [Partitions and QoS (hardware)](https://docs.mlerp.cloud.edu.au/hardware.html)
- [Getting started](https://docs.mlerp.cloud.edu.au/getting_started.html)
- [SSH credentials](https://docs.mlerp.cloud.edu.au/connecting/ssh.html)
- [Strudel2](https://docs.mlerp.cloud.edu.au/usage/strudel2.html)
- [Data management](https://docs.mlerp.cloud.edu.au/usage/data_management.html)
- [Provided conda environments](https://docs.mlerp.cloud.edu.au/usage/conda.html)
- Support: mlerphelp@monash.edu
