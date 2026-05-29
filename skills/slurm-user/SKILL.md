---
name: slurm-user
description: Submit, monitor and troubleshoot SLURM HPC job submission. Use this skill whenever the user needs help writing sbatch scripts, using srun, checking job status with squeue or sacct, understanding SLURM exit codes or job states, or debugging failed HPC jobs on any SLURM cluster.
compatibility: sbatch, srun, squeue, scancel, sinfo, scontrol, sacct, salloc, and other SLURM tools.
---

# SLURM User

Guide for submitting, monitoring and troubleshooting jobs on SLURM-managed HPC clusters. This covers generic SLURM usage — for cluster-specific details (partitions, storage, modules), refer to the relevant cluster skill (e.g. [M3 HPC](../m3-hpc/SKILL.md)).

## When to Use This Skill

Use this skill when you see:
- "How do I write an sbatch script?"
- "What does this SLURM error mean?"
- "My job is stuck in PENDING"
- "How do I check what resources my job used?"
- "How do I submit an array job?"
- "What's the difference between srun and sbatch?"
- "Why was my job killed / OOM?"

## Submitting jobs

### Batch jobs with sbatch

Write a job script and submit it:

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

echo "Running on $(hostname)"
./my_program
```

Submit: `sbatch my_job.sh`

### Common sbatch directives

| Directive | Description | Example |
|-----------|-------------|---------|
| `--job-name=NAME` | Job name (shown in squeue) | `--job-name=alignment` |
| `--account=ACCOUNT` | Billing/project account | `--account=ab12` |
| `--partition=PART` | Partition/queue to submit to | `--partition=comp` |
| `--qos=QOS` | Quality of Service | `--qos=genomics` |
| `--ntasks=N` | Number of tasks (MPI ranks) | `--ntasks=8` |
| `--cpus-per-task=N` | CPU cores per task (threads) | `--cpus-per-task=4` |
| `--mem=SIZE` | Memory per node | `--mem=32G` |
| `--mem-per-cpu=SIZE` | Memory per CPU core | `--mem-per-cpu=4G` |
| `--time=HH:MM:SS` | Maximum wall-time | `--time=24:00:00` |
| `--gres=TYPE:COUNT` | Generic resources (e.g. GPUs) | `--gres=gpu:2` |
| `--nodes=N` | Number of nodes | `--nodes=2` |
| `--array=RANGE` | Submit as array job | `--array=1-100` |
| `--dependency=TYPE:JOBID` | Job dependency | `--dependency=afterok:12345` |
| `--output=FILE` | stdout file (`%j`=jobid, `%x`=name, `%a`=array index) | `--output=%x_%j.out` |
| `--error=FILE` | stderr file | `--error=%x_%j.err` |
| `--mail-type=TYPE` | Email notifications | `--mail-type=END,FAIL` |
| `--mail-user=EMAIL` | Email address | `--mail-user=user@example.com` |
| `--export=VARS` | Environment variables to export | `--export=ALL` or `--export=NONE` |
| `--constraint=FEATURE` | Node feature constraint | `--constraint=avx2` |

Use `--mem` (per node) or `--mem-per-cpu` (per core) — not both.

### Interactive jobs with srun

Start an interactive shell on a compute node:

```bash
srun --ntasks=1 --cpus-per-task=4 --mem=8G --time=01:00:00 --pty bash
```

With a GPU:
```bash
srun --ntasks=1 --cpus-per-task=4 --mem=16G --gres=gpu:1 --time=01:00:00 --pty bash
```

### Allocate then run with salloc

Reserve resources first, then run commands within the allocation:

```bash
salloc --ntasks=4 --cpus-per-task=2 --mem=32G --time=02:00:00
# Now run commands within the allocation:
srun ./my_mpi_program
exit  # release the allocation
```

### Array jobs

Submit many similar jobs as a single array:

```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --array=1-100
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00

echo "Task ID: ${SLURM_ARRAY_TASK_ID}"
INPUT="data/sample_${SLURM_ARRAY_TASK_ID}.txt"
./process "${INPUT}"
```

Array range variants:
- `--array=1-100` — tasks 1 through 100
- `--array=1-100%10` — max 10 running concurrently
- `--array=1,3,5,7` — specific indices
- `--array=1-100:2` — step of 2 (1, 3, 5, ... 99)

### Array output files

By default, stdout/stderr will write to `slurm-<JobID>_<TaskID>.out`. You can customise this file path using:
- `%A` — array master Job ID
- `%a` — task index/ID

Example:
```bash
#SBATCH --output=logs/array_%A_%a.out
#SBATCH --error=logs/array_%A_%a.err
```

### Job dependencies

Chain jobs so one starts after another completes:

```bash
JOB1=$(sbatch --parsable job1.sh)
sbatch --dependency=afterok:${JOB1} job2.sh
```

| Dependency type | Meaning |
|-----------------|---------|
| `afterok:JOBID` | Start after JOBID completes successfully |
| `afternotok:JOBID` | Start after JOBID fails |
| `afterany:JOBID` | Start after JOBID finishes (success or fail) |
| `after:JOBID` | Start after JOBID starts |
| `singleton` | Only one job of this name can run at a time |

## Monitoring jobs

### squeue — view running/pending jobs

```bash
# Your jobs
squeue -u "${USER}"

# Custom format
squeue -u "${USER}" -o "%.18i %.9P %.30j %.8u %.8T %.10M %.6D %R"

# Just pending jobs
squeue -u "${USER}" -t PENDING

# Why is my job pending?
squeue -u "${USER}" -o "%.18i %.9P %.30j %.8T %R" -t PENDING

# JSON format (recommended for programmatic parsing by agents)
squeue --json

# Parsable format (pipe-delimited)
squeue --parsable
```

Common `REASON` codes for pending jobs:

| Reason | Meaning |
|--------|---------|
| `Priority` | Waiting for higher-priority jobs to start |
| `Resources` | Waiting for resources to become available |
| `QOSMaxJobsPerUserLimit` | Hit per-user job limit for this QoS |
| `AssocGrpCPUMinutesLimit` | Account has used its CPU allocation |
| `ReqNodeNotAvail` | Requested node is unavailable (maintenance, down) |
| `Dependency` | Waiting for a dependent job to finish |
| `PartitionTimeLimit` | Requested time exceeds partition limit |

### scontrol — detailed job/node info

```bash
# Detailed info on a job
scontrol show job {jobid}

# Show node details
scontrol show node {nodename}

# JSON format (recommended for programmatic parsing by agents)
scontrol show job {jobid} --json
scontrol show node {nodename} --json

# Hold a pending job (prevent it from starting)
scontrol hold {jobid}

# Release a held job
scontrol release {jobid}

# Update a pending job
scontrol update JobId={jobid} TimeLimit=48:00:00
```

### scancel — cancel jobs

```bash
# Cancel a single job
scancel {jobid}

# Cancel all your jobs
scancel -u "${USER}"

# Cancel all pending jobs
scancel -u "${USER}" -t PENDING

# Cancel a specific array task
scancel {jobid}_{array_task_id}

# Cancel by job name
scancel --name=my_job

# Send a specific signal
scancel --signal=USR1 {jobid}
```

### sinfo — cluster/partition info

```bash
# Show all partitions
sinfo

# Show only idle nodes
sinfo -t idle

# Compact summary
sinfo -s

# Custom format
sinfo -o "%P %a %l %D %T %N"

# JSON format (recommended for programmatic parsing by agents)
sinfo --json

# Parsable format (pipe-delimited)
sinfo --parsable
```

## Job history and accounting

### sacct — completed job info

For easier parsing and filtering, prefer `--json`, `--json=list` or `--parsable2` (pipe-delimited) output.

```bash
# Recent jobs (last 7 days)
sacct -u "${USER}" -S now-7days \
  --format=JobID,JobName,Partition,State,Elapsed,MaxRSS,NCPUS,TotalCPU

# Specific job with detailed resources
sacct -j {jobid} \
  --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,MaxVMSize,NCPUS,TotalCPU,ReqMem,AllocTRES

# JSON output
sacct -j {jobid} --json

# Parsable output (pipe-delimited)
sacct -j {jobid} --parsable2 \
  --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS
```

Key sacct fields:

| Field | Description |
|-------|-------------|
| `JobID` | Job ID (sub-jobs shown as `JOBID.batch`, `JOBID.0`, etc.) |
| `State` | Final job state |
| `ExitCode` | Exit code as `exit_code:signal` |
| `Elapsed` | Wall-clock time used |
| `TotalCPU` | Total CPU time consumed (user + system) |
| `MaxRSS` | Maximum resident memory (peak RAM usage) |
| `ReqMem` | Requested memory |
| `NCPUS` | Number of CPUs allocated |
| `AllocTRES` | All allocated trackable resources |

### Evaluating resource efficiency

- **CPU efficiency**: compare `TotalCPU` vs `Elapsed × NCPUS`. Low ratio → over-requesting CPUs or poor parallelism.
- **Memory efficiency**: compare `MaxRSS` vs `ReqMem`. If you requested 64G but used 2G, request less.
- **Time efficiency**: compare `Elapsed` vs requested `--time`. If your job finishes in 10 minutes but you requested 24 hours, tighten your estimate.

Right-sizing resource requests improves your queue priority and helps other users.

## Job states

| State | Meaning |
|-------|---------|
| `PENDING` (PD) | Waiting for resources |
| `RUNNING` (R) | Currently executing |
| `COMPLETED` (CD) | Finished successfully (exit code 0) |
| `FAILED` (F) | Exited with non-zero exit code |
| `TIMEOUT` (TO) | Exceeded wall-time limit |
| `OUT_OF_MEMORY` (OOM) | Exceeded memory allocation |
| `CANCELLED` (CA) | Cancelled by user or admin |
| `PREEMPTED` (PR) | Preempted by higher-priority job |
| `NODE_FAIL` (NF) | Node the job was on failed |
| `SUSPENDED` (S) | Job has been suspended |
| `REQUEUED` (RQ) | Job was requeued after a failure |

Check final state: `sacct -j {jobid} --format=JobID,State,ExitCode,DerivedExitCode`

## Exit codes

SLURM reports exit codes as `exit_code:signal`. The exit code comes from the job script or program; the signal comes from the OS or SLURM.

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General error (check your script/program) |
| 2 | Misuse of shell command (bash syntax error) |
| 126 | Permission denied or command not executable |
| 127 | Command not found |
| 137 | Killed by signal 9 (SIGKILL) — usually OOM killer |
| 139 | Segmentation fault (signal 11, SIGSEGV) |
| 143 | Killed by signal 15 (SIGTERM) — usually timeout or scancel |

When the signal field is non-zero, the job was killed by that signal rather than exiting on its own.

## Troubleshooting failed jobs

### Step 1: Check the job state and exit code

```bash
sacct -j {jobid} --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem
```

### Step 2: Read the log files

Check both stdout (`--output`) and stderr (`--error`) files. If you used `%x_%j.out`, look for `jobname_jobid.out`.

### Inspecting running jobs

To debug or check the environment of a currently active job without requesting a new node allocation, you can attach an interactive shell directly to the running job:
```bash
srun --jobid=<JOB_ID> --overlap --pty bash
```

### Common failure patterns

**Out of memory (OOM)**:
- State: `OUT_OF_MEMORY` or exit code `137` (SIGKILL)
- Log: `slurmstepd: error: Detected 1 oom_kill event` or `Killed`
- Fix: increase `--mem` or `--mem-per-cpu`, or reduce memory usage

**Timeout**:
- State: `TIMEOUT`, exit code `143` (SIGTERM)
- Fix: increase `--time`, or optimise the workload

**Command not found**:
- Exit code `127`
- Log: `command not found`
- Fix: check `module load` statements, verify $PATH, check script has correct shebang

**Permission denied**:
- Exit code `126`
- Fix: `chmod +x script.sh`, check file ownership

**Invalid account or partition**:
- Log: `sbatch: error: Batch job submission failed: Invalid account or account/partition association`
- Fix: explicitly declare your valid account and target partition at the top of your `#SBATCH` script:
  ```bash
  #SBATCH --account=<your_account_name>
  #SBATCH --partition=<your_partition>
  ```

**Node failure**:
- State: `NODE_FAIL`
- Not your fault — resubmit the job

**Job stuck in PENDING**:
- Run `squeue -j {jobid} -o "%R"` to see the reason
- `Priority` / `Resources` → normal queue wait, be patient
- `ReqNodeNotAvail` → check if you requested a node in maintenance
- `QOSMaxJobsPerUserLimit` → wait for existing jobs to finish

## SLURM environment variables

These are set automatically inside a running job:

| Variable | Description |
|----------|-------------|
| `SLURM_JOB_ID` | The job's ID |
| `SLURM_JOB_NAME` | The job's name |
| `SLURM_SUBMIT_DIR` | Directory the job was submitted from |
| `SLURM_JOB_NODELIST` | List of nodes allocated |
| `SLURM_NTASKS` | Number of tasks |
| `SLURM_CPUS_PER_TASK` | CPUs per task |
| `SLURM_MEM_PER_NODE` | Memory per node (in MB) |
| `SLURM_ARRAY_TASK_ID` | Array task index (array jobs only) |
| `SLURM_ARRAY_JOB_ID` | Parent array job ID (array jobs only) |
| `SLURM_TMPDIR` | Path to temporary directory (if configured) |
| `SLURM_GPUS` | Number of GPUs allocated |

## Common patterns

### Output filename templates

Use these in `--output` and `--error`:

| Pattern | Expands to |
|---------|------------|
| `%j` | Job ID |
| `%x` | Job name |
| `%a` | Array task ID |
| `%A` | Array parent job ID |
| `%N` | Short hostname of first node |
| `%u` | Username |

Example: `--output=logs/%x_%j.out` creates `logs/my_job_12345.out`

### Capturing job ID for scripting

```bash
JOBID=$(sbatch --parsable my_job.sh)
echo "Submitted job ${JOBID}"
```

### Retrieving default user account

To assign your default SLURM account to a variable in a bash script (without headers or trailing spaces):
```bash
DEFAULT_ACCOUNT=$(sacctmgr -n -P show user "${USER}" format=DefaultAccount)
```

### Email notifications

```bash
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=your.email@example.com
```

Types: `NONE`, `BEGIN`, `END`, `FAIL`, `REQUEUE`, `ALL`, `TIME_LIMIT_90` (warn at 90% of time).

### Multi-node MPI job

```bash
#!/bin/bash
#SBATCH --job-name=mpi_job
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=16
#SBATCH --mem-per-cpu=2G
#SBATCH --time=08:00:00

module load openmpi
srun ./my_mpi_program
```

Use `srun` (not `mpirun`) to launch MPI programs within a SLURM job for correct task binding.

### Hybrid MPI + OpenMP job

```bash
#!/bin/bash
#SBATCH --job-name=hybrid_job
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G
#SBATCH --time=08:00:00

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
module load openmpi
srun ./my_hybrid_program
```

## Reference guides

- **SLURM Command Reference Guide**: For advanced node and partition querying, QOS/limits checking, custom monitoring commands, and regex job cancellation, see the [SLURM Command Reference Guide](file:///home/perry/projects/agent-skills/skills/slurm-user/references/reference-guide.md).

## Official documentation

- [sbatch](https://slurm.schedmd.com/sbatch.html)
- [srun](https://slurm.schedmd.com/srun.html)
- [squeue](https://slurm.schedmd.com/squeue.html)
- [scancel](https://slurm.schedmd.com/scancel.html)
- [sinfo](https://slurm.schedmd.com/sinfo.html)
- [scontrol](https://slurm.schedmd.com/scontrol.html)
- [sacct](https://slurm.schedmd.com/sacct.html)
- [salloc](https://slurm.schedmd.com/salloc.html)
- [SLURM quickstart](https://slurm.schedmd.com/quickstart.html)
- [Job array support](https://slurm.schedmd.com/job_array.html)
- [Resource limits](https://slurm.schedmd.com/resource_limits.html)
- [Troubleshooting](https://slurm.schedmd.com/troubleshoot.html)
