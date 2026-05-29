# SLURM Command Reference Guide

This reference guide provides advanced commands and recipes to query cluster info, manage accounting, monitor usage, and control jobs on SLURM clusters.

---

## Node & Partition Information

### How to list node types and their physical resources?
To cleanly format `sinfo`, showing CPUs, memory, hostname, generic resources (like GPUs), and partition, sorted by partition:
```bash
sinfo -o "%c %m %n %G %R" --sort "P"
```

### How to show the QOS associated with each partition?
Because QOS (Quality of Service) is not a physical node property, parse `scontrol` JSON output to show partition names alongside their allowed and denied QOS limits:
```bash
scontrol show partition --json | jq -r '.partitions[] | "PartitionName=\(.name) AllowQos=\(.allow_qos) DenyQos=\(.deny_qos)"'
```

### How to see which accounts or groups are allowed to use each partition?
Use `sinfo` to output the partition name (`%P`), allowed groups/accounts (`%g`), CPUs (`%c`), and memory (`%m`). If `%g` says `all`, any valid account can use it.
```bash
sinfo -o "%P %g %c %m"
```

### How to check deep details or restrictions for a specific partition?
If you are getting access errors, use this command and look for the `AllowAccounts` or `AllowGroups` lines to see if your account/group is permitted on this partition:
```bash
scontrol show partition <partition_name>
```

### How to show the node utilisation and state of each node on the cluster?
To see the current status (e.g., down, drained, allocated) alongside exactly how many cores, memory, and GPUs are allocated versus the total available per node:
```bash
sinfo -N -O "NodeList:30,Partition:15,StateLong:15,CPUsState:15,AllocMem:15,Memory:15,Gres:25,GresUsed:25"
```
* **NodeList**: The hostname of the node (widened to 30 characters).
* **Partition**: The partition the node belongs to.
* **StateLong**: The current operational state of the node (`allocated`, `idle`, `down`, `drained`, `mixed`).
* **CPUsState**: Shows CPU cores in the format `Allocated/Idle/Other/Total`.
* **AllocMem & Memory**: Shows the currently allocated memory next to the total physical memory (in Megabytes).
* **Gres & GresUsed**: Shows the total generic resources (like GPUs) installed, followed by how many are currently allocated.

---

## User Limits & Accounting (`sacct`, `sacctmgr`)

### How to get exactly the default SLURM account value (for bash scripting)?
If you need to assign your default account to a variable in a script without any headers or trailing spaces, use the `-n` (no header) and `-P` (parsable) flags:
```bash
DEFAULT_ACCOUNT=$(sacctmgr -n -P show user "${USER}" format=DefaultAccount)
```

### How to check which QOS policies and accounts are available to me?
```bash
sacctmgr show user "${USER}" withassoc format=user,account,qos%30,defaultqos
```

### How to check which accounts I belong to and their permitted partitions?
To see a clean list of your projects/accounts and any specific partitions those accounts are restricted to:
```bash
sacctmgr show associations user="${USER}" format=Account,Partition,QOS
```

### How to view all jobs run under a specific account over the last year?
Use the `--allusers` (`-a`) flag to ensure you see jobs submitted by anyone in that account, not just yourself:
```bash
sacct --allusers --account yf49 --starttime $(date -d "-365 days" +%Y-%m-%d) --format=User,JobID,Jobname%128,partition,state,exitcode,time,start,end,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist
```
*(Note: Output depends on your cluster's `PurgeJobAfter` database retention policy, which may be shorter than 365 days.)*

### How to stop long output strings from being truncated in `sacct`?
Append a percentage sign and a number to the format field to widen the column. For example, to widen the requested TRES column:
```bash
sacct --format=JobID,JobName,ReqTRES%50
```

---

## Queue & Usage Monitoring

### How to see a summary of running and pending jobs per user?
To query the queue and print a summary table of running and pending jobs grouped by user, sorted by running jobs:
```bash
squeue --json | jq -r '.jobs[] | "\(.user_name) \(.job_state)"' | awk '{run[$1]+=($2=="RUNNING"); pend[$1]+=($2=="PENDING")} END {for (u in run) printf "%-15s %-10d %-10d\n", u, run[u], pend[u]}' | sort -k2,2nr
```

---

## Job Control & Execution

### How to fix account/partition access errors in a job script?
If SLURM complains about invalid accounts or partitions, explicitly declare your valid account and target partition at the top of your `#SBATCH` script:
```bash
#SBATCH --account=<your_account_name>
#SBATCH --partition=<your_partition>
```

### How to cancel jobs by name using regex?
To cancel your own jobs matching a specific string or pattern:

**Cancel ALL matching jobs (running and pending):**
```bash
squeue -u "${USER}" --json | jq -r '.jobs[] | select(.name | test("<pattern>")) | .job_id' | xargs -r scancel
```

**Cancel ONLY RUNNING matching jobs:**
```bash
squeue -u "${USER}" --json | jq -r '.jobs[] | select(.job_state == "RUNNING" and (.name | test("<pattern>"))) | .job_id' | xargs -r scancel
```

**Cancel ONLY PENDING matching jobs:**
```bash
squeue -u "${USER}" --json | jq -r '.jobs[] | select(.job_state == "PENDING" and (.name | test("<pattern>"))) | .job_id' | xargs -r scancel
```

### How to run an interactive command on a node where a job is already running?
This is highly useful for checking on the exact environment of an active job without requesting a new node allocation:
```bash
srun --jobid=<JOB_ID> --overlap --pty bash
```

---

## Resource Allocation (GPUs)

### How to properly request GPUs?
* **Total GPUs across the whole job**: Use `--gpus=<N>`
* **GPUs tied explicitly to individual nodes**: Use `--gres=gpu:<N>`
* **Requesting a specific GPU model**: Append the GPU type to the `--gres` flag. For example, to request exactly one A100 GPU per node:
  ```bash
  #SBATCH --gres=gpu:A100:1
  ```

### How to list the GPU types available by partition or node?
To get a clean list summarising GPU types available per partition:
```bash
sinfo --parsable -o "%P|%G" | tail -n +2 | sort -u
```

To see the exact GPU types available on every individual node:
```bash
sinfo -o "%P %N %G" --sort="P"
```

---

## Workflow Integration

### How to find the underlying SLURM Job ID from a Nextflow task?
If Nextflow submits jobs to SLURM, you can query the Nextflow log to map the Nextflow task name to the SLURM `native_id`:
```bash
nextflow log <RUN_NAME_OR_SESSION_ID> -f name,native_id
```

### How do job array output files get named?
When running arrays, SLURM substitutes standard variables. By default, standard out/error will land in a file structured like `slurm-<JobID>_<TaskID>.out` (or whatever custom directory/filename you dictate in your script using `%A` for the array master job ID and `%a` for the task ID).
