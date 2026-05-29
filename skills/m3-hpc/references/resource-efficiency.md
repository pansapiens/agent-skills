# Resource Efficiency and Monitoring on M3

Since the cluster is a shared resource, managing resource utilisation efficiently is critical. Minimising resource requests to only what your job requires will help reduce your queue time and speed up your overall time to solution.

---

## Key Resources to Optimise

When designing your Slurm scripts, consider the following parameters:

### 1. Job Wall Time (`--time`)
- **Time Limits**: If a job reaches its wall time, it is terminated. 
- **Time Buffers**: Estimate your runtime accurately and add a reasonable buffer (e.g. 10–20%) for safety.
- **Checkpointing**: Design your code to checkpoint regularly so that if it is terminated early (or preempted on the `irq` queue), it can resume from the last saved state.

### 2. CPU Cores (`--cpus-per-task`)
- **Parallel Code**: Ensure your application actually supports multithreading before requesting multiple CPU cores. Running a single-threaded program with more cores does not speed it up; it simply wastes resources.
- **Scaling**: Check if your job scales well. Doubling the cores rarely halves the runtime due to communication overhead.

### 3. CPU Memory (`--mem` or `--mem-per-cpu`)
- **RAM Limits**: Requesting more RAM than required does not speed up your job. However, exceeding your requested RAM will trigger an Out Of Memory (OOM) error, killing the job.
- **Sizing Memory**: Use the methods below to check actual peak usage and adjust future allocations accordingly.

### 4. GPUs (`--gres=gpu:N`)
- **GPU Selection**: High-end GPUs (like A100s or H100s) have long queue times. If your job can fit in the memory of a lower-end GPU, using it can reduce your queue wait time significantly.
- **Multi-GPU Overhead**: Only request multiple GPUs if your code is explicitly written to support distributed GPU execution. Ensure you have fully exhausted the capabilities of a single GPU first.

### 5. Number of Nodes (`--nodes`)
- **Node Allocation**: Always specify `--nodes` to prevent Slurm from splitting tasks inefficiently across different nodes.
- **Task Exhaustion**: Exhaust all cores on a single node before requesting additional nodes to avoid inter-node network latency.

---

## Monitoring and Auditing Resource Usage

### Monitoring Active Jobs
If your job is currently running, you can connect directly to the compute node to check live usage:
1. Locate the assigned node name:
   ```bash
   # Default columns show JobID, Partition, Name, User, State, Time, Nodes
   squeue -u "${USER}"

   # Custom format: JobID, Partition, Name, User, State, Time, Reason
   squeue -u "${USER}" -o "%.18i %.9P %.30j %.8u %.8T %.10M %R"
   ```
2. SSH into the node:
   ```bash
   ssh {node_name}
   ```
3. Run diagnostic tools:
   - `htop -u "${USER}"` (check CPU utilisation and the `RES` column for memory usage).
   - `nvidia-smi` (check GPU utilisation and VRAM consumption).

### Auditing Completed Jobs
To view resource efficiency after a job has completed, use these tools:

- **`jobstats` (M3-specific)**: Shows a detailed breakdown of CPU and memory utilisation for a job.
  ```bash
  jobstats {jobid}
  ```
- **`sacct`**: Query Slurm history to compare requested vs. actual usage.
  ```bash
  sacct -j {jobid} --format=JobID,JobName,State,Elapsed,MaxRSS,ReqMem,NCPUS,TotalCPU

  # JSON output for easier parsing and scripting
  sacct -j {jobid} --json

  # Parsable pipe-delimited output
  sacct -j {jobid} --parsable2 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS
  ```
  - **Memory Efficiency**: Compare `MaxRSS` (actual peak RAM used) against `ReqMem` (requested RAM). If `MaxRSS` is significantly lower than `ReqMem`, request less memory in future submissions.
  - **CPU Efficiency**: Compare `TotalCPU` (actual CPU time used) to `Elapsed * NCPUS`. If `TotalCPU` is low, your code is not utilising all requested cores.

---

## Common Efficiency Pitfalls

- **Unused CPU Cores**: Requesting a high `--cpus-per-task` count but failing to configure the application (e.g. setting `OMP_NUM_THREADS` or application-specific flags) to use them.
- **Requesting the Entire Node for Single-threaded Tasks**: Requesting all CPU cores or all memory when your application is single-threaded or only uses a single GPU.
- **Unused GPUs**: Requesting multiple GPUs when the software only supports single-GPU execution.
- **Array Job Multipliers**: Forgetting that parameters in an array job script apply to **each** sub-job. An array job of 100 tasks requesting 4 cores each will allocate 400 cores in total.

For more details, consult the [official M3 Effective Resource Usage documentation](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/EffectiveUsage/).
