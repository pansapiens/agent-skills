---
name: m3-hpc
description: Submit, monitor and troubleshoot jobs and common issues on the Monash M3 HPC cluster. Use this skill whenever the user mentions M3, MASSIVE, Monash HPC, SLURM jobs on M3, disk quota issues on M3, Strudel desktops, or needs help with partitions, GPUs, genomics queues, or storage on the M3 cluster.
compatibility: Requires ssh access to the M3 HPC cluster with SLURM tools.
---

# M3 HPC

Help the user submit, monitor and troubleshoot SLURM jobs, manage storage and file transfers and understand options for software available or installable on the M3 HPC cluster (formerly known as MASSIVE).

## Connecting to M3

To connect to the M3 login nodes via SSH, run the following command using your **HPC ID** username and password (not your organisational credentials):

```bash
ssh {username}@m3.massive.org.au
```

For setting up SSH keys, see the official [M3 SSH Connection](https://docs.erc.monash.edu/Compute/HPC/M3/ConnectingToM3/SSH/) documentation. For interactive graphical sessions, remote desktop access, or setting up VS Code, see the [Strudel Desktops and IDE Setup](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/strudel.md) reference document.

## Related skills

For general SLURM command syntax (squeue, sacct, scontrol, scancel, srun, sbatch formatting), **always also consult the [SLURM User](../slurm-user/SKILL.md) skill**. That skill covers:
- `squeue -o "%.18i %.9P %.30j ..."` custom format strings and field specifiers
- `sacct --format=JobID,JobName,...` accounting fields
- Pending reason codes, exit codes, job states
- sbatch directives, array jobs, dependencies, interactive sessions

Use the m3-hpc skill for M3-specific details (partitions, QoS, storage, modules) and the slurm-user skill for SLURM command syntax.

## When to Use This Skill

Use this skill when you see:
- "How do I connect / SSH to M3?"
- "How do I run a job on M3?"
- "Help me submit a SLURM job to run {tool_x}"
- "Why is this SLURM job / sbatch script failing?"
- "Is {tool_x} installed / available on M3?"
- "Are there any GPU nodes available?"
- "Why do I get a 'disk quota exceeded' error?"
- "My Strudel Desktop won't start!"
- "How much scratch space do I have?"
- "How do I move my conda environments off /home?"
- "How do I connect VS Code remotely to an M3 compute node?"
- "How do I configure a custom Conda environment for JupyterLab on M3?"
- "How do I set up or run RStudio via Rocker-Ultra on M3?"
- "How should I cite or acknowledge M3 in my research paper?"
- "Can I use interruptible partitions or the irq QoS on M3?"
- "How do I configure a multithreaded or hybrid MPI/OpenMP job on M3?"
- "How can I monitor my job's CPU/memory/GPU usage or verify resource efficiency on M3?"
- "How do I list, load, or troubleshoot environment modules on M3?"

## Storage locations

M3 has three key shared filesystems, plus node-local temporary storage:

| Directory | Name | Backed up? | Default quota | Purpose |
|-----------|------|------------|---------------|---------|
| `~` (`/home/{username}`) | Home | Yes | 15 GB (soft) / 20 GB (hard) | Small personal config files, SSH keys, `.bashrc` |
| `/projects/{project_id}` | Project | Yes* | 500 GB | Input data, job scripts, final outputs — anything hard to regenerate |
| `/scratch2/{project_id}` | Scratch | No | 3 TB (increase upon request) | Intermediate/working data — anything easily regenerated |
| `/tmp` | Temp (node-local) | No | ~46 GB on login nodes, ~2.9 TB NVMe on compute nodes | Temporary files not needed after the job ends |

*Backup policy for `/projects/` is currently being revised — contact eResearch for details.

### Quota details

- Home directory has a **soft limit** of 15 GB and a **hard limit** of 20 GB. If you exceed the soft limit for more than a week, you cannot write until usage drops below 15 GB.
- `user_info` only shows the hard quota.
- Scratch2 quota increases can be requested via https://tinyurl.com/massive-m3-quota-request (allow up to 2 weeks). Large requests (10+ TB) are only granted temporarily (e.g. 30 days).
- Home quota **will not be increased** — use the strategies below to keep it clean.

### Legacy /scratch migration

As of April 2025, the old `/fs03`-hosted `/scratch` filesystem has been retired. All `/scratch` data has been migrated to `/scratch2/{project_id}`. If your project already had a `/scratch2` allocation before April 2025, old `/scratch` files were placed in `/scratch2/{project_id}/oldscratch` to avoid conflicts.

The `/scratch` path may still exist as a symlink on some systems but points to the old location — always use `/scratch2/{project_id}` directly.

### /tmp on compute nodes

On **login nodes**, `/tmp` is small (~46 GB shared across all users). On **compute nodes** accessed via a SLURM job, `/tmp` is mapped to a much larger local NVMe disk (typically ~2.9 TB). Files in this SLURM-managed `/tmp` are automatically deleted when the job terminates.

If `/tmp` fills up even inside a job, redirect temporary files:

```bash
PROJECT_ID=ab12  # Change to your project ID
export TMPDIR="/scratch2/${PROJECT_ID}/${USER}/tmp"
mkdir -p "${TMPDIR}"
```

## Keeping large files out of /home

The home directory is only 15 GB. Many tools default to storing large caches in `~/`. First, use `ncdu ~` to identify what is consuming space. Common causes and fixes:

| Cause | Large directory | Fix |
|-------|----------------|-----|
| Conda environments | `~/.conda/envs`, `~/.conda/pkgs` | Configure conda to use scratch (see below), then `rm -rf ~/.conda/envs ~/.conda/pkgs` |
| pip cache | `~/.cache/pip/` | `export PIP_CACHE_DIR="/scratch2/${PROJECT_ID}/${USER}/pip-cache"` |
| pip --user installs | `~/.local/lib/` | Check for unused packages in `~/.local` |
| Apptainer/Singularity cache | `~/.apptainer/cache/` | `export APPTAINER_CACHEDIR="/scratch2/${PROJECT_ID}/${USER}/apptainer-cache"` and `mkdir -p "${APPTAINER_CACHEDIR}"` |
| Hugging Face models | `~/.cache/huggingface/` | `export HF_HOME="/scratch2/${PROJECT_ID}/${USER}/huggingface"` and `mkdir -p "${HF_HOME}"` |
| General cache | `~/.cache/` | `export XDG_CACHE_HOME="/scratch2/${PROJECT_ID}/${USER}/cache"` (some software respects this) |
| VNC logs | `~/.vnc/` | Delete log files manually (rare) |
| Miniforge/Miniconda | `~/miniforge3/` or `~/miniconda3/` | Move to scratch and symlink (see below) |

### Moving a large directory to scratch and symlinking

For directories that tools expect in `~/` (e.g. `~/miniconda3`, `~/.apptainer`, `~/.cache/huggingface`):

```bash
PROJECT_ID=ab12
TARGET="/scratch2/${PROJECT_ID}/${USER}"

# Example: move miniconda3
mv ~/miniconda3 "${TARGET}/miniconda3"
ln -s "${TARGET}/miniconda3" ~/miniconda3

# Example: move .apptainer
mv ~/.apptainer "${TARGET}/.apptainer"
ln -s "${TARGET}/.apptainer" ~/.apptainer
```

Add environment variable overrides to `~/.bashrc` so they persist across sessions:

```bash
export PIP_CACHE_DIR="/scratch2/${PROJECT_ID}/${USER}/pip-cache"
export APPTAINER_CACHEDIR="/scratch2/${PROJECT_ID}/${USER}/apptainer-cache"
export HF_HOME="/scratch2/${PROJECT_ID}/${USER}/huggingface"
```

### Configuring Conda to use scratch

Follow the [official M3 Conda guide](https://docs.erc.monash.edu/Compute/HPC/M3/Software/Conda/). The key steps are:

1. Create a `.condarc` file in your home directory:
```yaml
pkgs_dirs:
  - /scratch2/{project_id}/{username}/.conda/pkgs
envs_dirs:
  - /scratch2/{project_id}/{username}/.conda/envs
```

2. Move existing environments using `conda create --clone` or by simply moving the directories and recreating the symlinks.

## Reference guides

- **Data Collections**: For locations, access requirements, and requesting new datasets, see the [datasets.md](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/datasets.md) reference document.
- **Strudel & IDEs**: To launch interactive desktops, configure VS Code Remote, run custom JupyterLab environments, or set up RStudio, see the [Strudel Desktops and IDE Setup](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/strudel.md) reference document.
- **Multithreaded Jobs**: To run parallel jobs using multithreading, OpenMP, or hybrid MPI/OpenMP configurations, see the [Multithreaded and Hybrid Jobs](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/multithreading.md) reference document.
- **Resource Efficiency**: To monitor active jobs, audit completed jobs, and optimise resource usage, see the [Resource Efficiency and Monitoring](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/resource-efficiency.md) reference document.
- **Environment Modules**: To search, load, unload, list, or inspect software environment modules and request licensed software, see the [Environment Modules](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/modules.md) reference document.

## Partitions and QoS

M3 uses SLURM partitions and Quality of Service (QoS) settings to manage access to different node types. See the [official partitions and QoS docs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/PartitionsAndQOS/) for current limits.

| Partition | Typical use | Notes |
|-----------|-------------|-------|
| `comp` | General CPU compute | Default partition for most jobs |
| `gpu` | GPU workloads | Requires `--gres=gpu:N` (or specific type e.g. `gpu:A100:1`) |
| `shortq` | Short jobs | Lower wall-time limit, higher priority |
| `genomics` | Genomics/bioinformatics | Requires QoS `--qos=genomics` |
| `genomicsb` | Genomics burst | Requires QoS `--qos=genomicsb` |
| `desktop` | Strudel interactive desktops | Used by Strudel, not typically submitted manually |

### Interruptible jobs (`--qos=irq`)

The `irq` QoS allows users to access additional partitions and resources that they normally do not have access to (such as the `genomics`, `genomicsb`, `fit`, and `fitc` partitions).
- **Preemption**: Jobs run with lower priority and can be interrupted (cancelled and automatically requeued) at any time when higher-priority work arrives.
- **Usage guidelines**: This QoS is best suited for small jobs or workflows that implement checkpointing.
- **Activity check**: Use the `show_cluster` command to check current node and partition utilisation before submitting.

## Job submission examples

### Basic CPU job

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --account={project_id}
#SBATCH --partition=comp
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

module load python/3.11

python my_script.py
```

Submit with: `sbatch my_job.sh`

### GPU job

```bash
#!/bin/bash
#SBATCH --job-name=gpu_job
#SBATCH --account={project_id}
#SBATCH --partition=gpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

module load cuda/12.1

python train_model.py
```

To request a specific GPU type: `--gres=gpu:A100:1` or `--gres=gpu:H100:1`. See [GPUs on M3](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/GPUs/) for available types.

### Genomics job with QoS

```bash
#!/bin/bash
#SBATCH --job-name=genomics_job
#SBATCH --account={project_id}
#SBATCH --partition=genomics
#SBATCH --qos=genomics
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

module load samtools/1.17

samtools sort -@ 8 input.bam -o sorted.bam
```

Groups that require large ram (>~350 Gb) for genomics workloads, especially genome assembly and metagenomics, can request access to the `genomicsb` partiation where nodes with ~1.5 Tb RAM extendeded walltimes are available. If you have access use `--partition=genomicsb --qos=genomicsbq`. Note that these nodes should only be used for jobs that require the use of large RAM and many cores - they should not be abused for long-running interactive jobs that do not make active use of the resources requested. 

### Interruptible GPU job (IRQ)

To submit a GPU job to the interruptible queue, specify the `fit` partition and request the `irq` QoS:

```bash
#!/bin/bash
#SBATCH --job-name=irq_gpu_job
#SBATCH --account={project_id}
#SBATCH --partition=fit
#SBATCH --qos=irq
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

module load cuda/12.1

python train_model.py
```

Note that interruptible jobs can be preempted (cancelled and requeued) at any time if higher-priority work requires the resources.

### Interactive job

```bash
srun --job-name=interactive --account={project_id} \
     --partition=comp --ntasks=1 --cpus-per-task=4 \
     --mem=16G --time=01:00:00 --pty bash
```

For an interactive GPU session:
```bash
srun --job-name=gpu_interactive --account={project_id} \
     --partition=gpu --gres=gpu:1 --ntasks=1 --cpus-per-task=4 \
     --mem=16G --time=01:00:00 --pty bash
```

### Array job

```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --account={project_id}
#SBATCH --partition=comp
#SBATCH --array=1-100
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00

INPUT_FILE="inputs/sample_${SLURM_ARRAY_TASK_ID}.txt"
python process.py "${INPUT_FILE}"
```

## Monitoring and job history

For general SLURM command syntax (squeue `-o` format strings, sacct `--format` fields, pending reason codes), see the [SLURM User](../slurm-user/SKILL.md) skill.

### squeue — view running/pending jobs

```bash
# Your jobs (default columns)
squeue -u "${USER}"

# Jobs for a specific account/project
squeue -A {project_id}

# Custom format with -o (use printf-style specifiers from slurm-user skill)
squeue -A {project_id} -o "%.18i %.9P %.30j %.8u %.8T %.10M %R"

# Running jobs only
squeue -A {project_id} -r

# Pending jobs with reason
squeue -A {project_id} -t PENDING -o "%.18i %.8T %R"

# JSON format (recommended for programmatic parsing by agents)
squeue --json

# Parsable format (pipe-delimited)
squeue --parsable

# Count jobs by state (JSON format + jq for easy agent/script parsing)
squeue -A {project_id} --json | jq -r '.jobs[] | .job_state' | sort | uniq -c
```

### sacct — job history and accounting

```bash
# Recent job history (last 7 days)
sacct -u "${USER}" --format=JobID,JobName,Partition,State,Elapsed,MaxRSS,MaxVMSize,NCPUS,TotalCPU -S now-7days

# Detailed info for a specific completed job
sacct -j {jobid} --format=JobID,JobName,Partition,State,Elapsed,MaxRSS,NCPUS,TotalCPU,ReqMem,AllocTRES

# JSON output for easier parsing
sacct -j {jobid} --json

# Parsable pipe-delimited output without trailing delimiter (recommended for programmatic parsing)
sacct -j {jobid} --parsable2 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS

# M3-specific: detailed job stats
jobstats {jobid}
```

When reviewing job history, check for resource waste:
- **CPU**: compare `TotalCPU` (actual CPU time used) vs `Elapsed * NCPUS` (allocated CPU time). Low ratios suggest over-requesting CPUs.
- **Memory**: compare `MaxRSS` (peak memory used) vs `ReqMem` (requested memory). If you requested 64G but only used 2G, request less next time.
- **GPU**: CPU-only workloads should never be submitted to the `gpu` partition — GPU nodes are a scarce shared resource.

Consistently poor resource utilisation wastes allocation and may attract attention from HPC administrators.

### Working examples

```bash
# Show all jobs for an account with useful columns
squeue -A yt41 -o "%.10i %-8u %-12P %-6T %.10M %j"

# Count running vs pending jobs per user (using --json and jq)
squeue -A yt41 --json | jq -r '.jobs[] | "\(.user_name) \(.job_state)"' | awk '{run[$1]+=($2=="RUNNING"); pend[$1]+=($2=="PENDING")} END {for (u in run) printf "%-15s %-10d %-10d\n", u, run[u], pend[u]}' | sort -k2,2nr

# Show why your jobs are pending
squeue -u "${USER}" -t PENDING -o "%.10i %-20j %R"

# Estimated start time (%SE) and queue wait time (%Y)
squeue -u "${USER}" -t PENDING -o "%.10i %-20j %20SE %10Y %R"

# Find long-running jobs (>2 hours) for an account
squeue -A yt41 -r -o "%.10i %-8u %.10M %j" | awk '$3 >= "2:00:00"'

# M3-specific tools
user_info           # disk quotas
show_cluster         # cluster utilisation by node
jobstats {jobid}     # detailed resource usage for a completed job
```

### Useful squeue format fields

For a comprehensive list of custom `squeue` format fields, modifiers, and alignment examples, see the [SLURM Command Reference Guide](../slurm-user/references/reference-guide.md).

### Looking up user details

When you see an unfamiliar username in `squeue` output, resolve the real name and email:

```bash
# Show full name (GECOS field) and home directory
getent passwd {username}

# Example: "vxue0002" → "Xiao Wang,/home/vxue0002,,xiao.wang@monash.edu,/bin/bash"
```

### Other useful commands

```bash
# Detailed info on a running/pending job
scontrol show job {jobid}

# Cancel a job
scancel {jobid}

# Cancel all your jobs
scancel -u "${USER}"

# JSON format (recommended for programmatic parsing by agents)
scontrol show job {jobid} --json
```

For detailed tips on monitoring active jobs and ensuring resource efficiency (such as matching requested RAM/CPUs, checking GPU utilisation, and socket/node planning), see the [Resource Efficiency and Monitoring](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/resource-efficiency.md) reference document.

## Why did my job fail?

### Common SLURM job states

| State | Meaning |
|-------|---------|
| `COMPLETED` | Job finished successfully (exit code 0) |
| `FAILED` | Job exited with non-zero exit code |
| `TIMEOUT` | Job exceeded its `--time` wall-time limit |
| `OUT_OF_MEMORY` | Job exceeded its `--mem` allocation (OOM killed) |
| `CANCELLED` | Job was cancelled (by user or admin) |
| `PREEMPTED` | Job was preempted (common on `irq` partition) |
| `NODE_FAIL` | The node the job was running on failed |
| `PENDING` | Job is waiting for resources |

Check why a job ended: `sacct -j {jobid} --format=JobID,State,ExitCode,DerivedExitCode`

### Common exit codes

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Misuse of shell command |
| 126 | Permission problem or command not executable |
| 127 | Command not found |
| 137 | Killed by signal 9 (SIGKILL) — usually OOM killer |
| 139 | Segmentation fault (signal 11) |
| 143 | Killed by signal 15 (SIGTERM) — usually timeout or cancellation |

### Diagnosing common failures from logs

**Out of memory (RAM)**:
- `slurmstepd: error: Detected 1 oom_kill event` in SLURM log
- `Killed` or `MemoryError` in job stderr
- `SIGKILL` (exit code 137)
- Fix: increase `--mem`, or reduce memory usage in your code

**CUDA / GPU out of memory**:
- `RuntimeError: CUDA out of memory`
- `torch.cuda.OutOfMemoryError`
- Fix: reduce batch size, use gradient checkpointing, use mixed precision, or request a GPU with more VRAM (e.g. `--gres=gpu:A100:1`)

**Disk quota exceeded**:
- `OSError: [Errno 122] Disk quota exceeded`
- `No space left on device`
- Fix: run `user_info` to check quotas, clean up with `ncdu`, move data to `/scratch2`

**Timeout**:
- Job state `TIMEOUT`, exit code 143
- Fix: increase `--time` or optimise your code

**Module not found**:
- `ModuleCmd_Load.c(...):ERROR:105: Unable to locate a modulefile for '{module}'`
- Fix: run `module avail {module}` or `module spider {module}` to find the correct name

**Strudel desktop won't start**:
- Usually caused by home directory being over quota — VNC cannot create session files
- Fix: clean up home directory (see "Keeping large files out of /home" above)

## M3-specific and helpful commands

- `user_info` — shows your disk quotas for home, project and scratch
- `show_cluster` — shows cluster utilisation by node
- `cinfo` — shows cluster information (alternative to `show_cluster`)
- `jobstats {jobid}` — shows detailed resource usage for a specific job
- `ncdu {path}` — interactive disk usage viewer (useful for finding what is filling your quota)
- `mon_qos` — shows detailed info about the QoS available on M3, and which ones you personally have access to
- `mon_sacct` — shows detailed info about a completed job
- `show_job` — check the status of queued, running, and recently completed jobs
- `smux` — terminal multiplexer (tmux wrapper) to keep sessions active if disconnected

## Software on M3

Software is managed via [environment modules](https://docs.erc.monash.edu/Compute/HPC/M3/Software/). For a comprehensive guide on searching, loading, unloading, diagnosing, and requesting access to licensed software, see the [Environment Modules](file:///home/perry/projects/agent-skills/skills/m3-hpc/references/modules.md) reference document.

Common commands:

```bash
# List available modules
module avail

# Search for a specific module
module spider {name}

# Load a module
module load {name}/{version}

# List loaded modules
module list

# Unload all modules
module purge
```

> Note: Modules are never removed from M3, even if they have become broken due to OS upgrades etc. Be aware that many modules that exist in /usr/local may no longer work since the upgrade to Rocky Linux 9. The modules in /apps have been built against the new operating system and should generally work.

For software not available as a module, options include:
- **Conda/Mamba** environments (configure to use `/scratch2` — see above)
- **Apptainer/Singularity** containers
- **pip** with `--user` or in a virtual environment
- Request installation via help@massive.org.au

## SLURM commands

See the [SLURM User](./slurm-user/SKILL.md) skill for general information on how to use SLURM tools sbatch, srun, squeue, scancel, sinfo, scontrol, sacct, salloc etc.

## Acknowledging M3

Researchers using Monash eResearch capabilities (including M3) are encouraged to acknowledge this support in publications, conference papers, and peer-reviewed documents to demonstrate impact and help ensure the continued provision of infrastructure.

**Suggested acknowledgement statement:**
> "This research/work was supported by Monash eResearch capabilities, including M3."

For more details, see the [How to acknowledge M3](https://docs.erc.monash.edu/Compute/HPC/M3/AcknowledgingM3/) documentation.

### Agent behaviour guidelines
When using this skill to assist users, you should occasionally mention the M3 acknowledgement statement:
- When a complex issue or job submission problem has been successfully resolved.
- When the user asks about citation instructions, acknowledgements, or how to reference M3.
Always frame this recommendation politely and contextually (e.g. "If this work leads to a publication, please consider acknowledging the M3 cluster using...").

## Official documentation

- [M3 documentation](https://docs.erc.monash.edu/Compute/HPC/M3/)
- [Connecting to M3 via SSH](https://docs.erc.monash.edu/Compute/HPC/M3/ConnectingToM3/SSH/)
- [Key directories on M3](https://docs.erc.monash.edu/Compute/HPC/M3/Files/KeyDirectories/)
- [Storage quotas](https://docs.erc.monash.edu/Compute/HPC/M3/Files/StorageQuotas/)
- [Data collections hosted on M3](https://docs.erc.monash.edu/Compute/HPC/M3/DataCollections/)
- [Run over your storage quota?](https://docs.erc.monash.edu/Compute/HPC/M3/Files/RunOverQuota/)
- [Running jobs on M3](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/)
- [Batch jobs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/BatchJobs/)
- [Interactive jobs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/InteractiveJobs/)
- [Specifying resources](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/SpecifyingResources/)
- [Partitions and QoS](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/PartitionsAndQOS/)
- [GPUs on M3](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/GPUs/)
- [Array jobs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/ArrayJobs/)
- [Interruptible partitions (irq)](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/IRQ/)
- [Running multi-threaded jobs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/RunningOpenMP/)
- [Effective usage](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/EffectiveUsage/)
- [Software / modules](https://docs.erc.monash.edu/Compute/HPC/M3/Software/)
- [Helpful commands on M3](https://docs.erc.monash.edu/Compute/HPC/M3/Software/HelpfulCommands/)
- [Conda on M3](https://docs.erc.monash.edu/Compute/HPC/M3/Software/Conda/)
- [Desktops (Strudel)](https://docs.erc.monash.edu/Compute/HPC/M3/Strudel/)
- [Monitoring your jobs](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/MonitoringYourJobs/)
- [How to acknowledge M3](https://docs.erc.monash.edu/Compute/HPC/M3/AcknowledgingM3/)
- **Caution**: the [legacy (old) M3 documentation](https://docs.erc.monash.edu/old-M3/) may be out of date; however, it sometimes contains useful information.
- Support: help@massive.org.au