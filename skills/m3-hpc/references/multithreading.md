# Running Multithreaded and Hybrid MPI/OpenMP Jobs on M3

This reference document provides guidelines and sample scripts for running multithreaded, OpenMP, and hybrid OpenMP/MPI parallel jobs on the Monash M3 HPC cluster.

## Multithreaded Jobs (Single Process, Multi-core)

A multithreaded job executes a single Unix process that spawns multiple threads to run parallel calculations across multiple CPU cores. Examples include:
- **OpenMP** programs.
- **Matlab** scripts leveraging the Parallel Computing Toolbox.
- Custom applications built using threading libraries (e.g. Python's `threading` or `multiprocessing` modules, C++ `std::thread`).

### Basic Multithreaded Slurm Template

In Slurm, request 1 task (`--ntasks=1`) and specify the number of CPU cores required per task (`--cpus-per-task=N`):

```bash
#!/bin/bash
#SBATCH --job-name=multithread_job
#SBATCH --account={project_id}
#SBATCH --partition=comp
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# Configure the program to use the correct number of CPU cores
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

./my_multithreaded_program.exe
```

> [!NOTE]
> Make sure to pass the number of allocated CPU cores to your application. This is typically done via command-line arguments (e.g. `--cores=8`), environment variables (e.g. `OMP_NUM_THREADS`), or by querying the environment.

---

## OpenMP Jobs

OpenMP is a shared-memory multiprocessing API built directly into major compilers (GCC, Intel, Clang). Since it relies on shared memory, an OpenMP job **cannot span multiple physical nodes** and must execute on a single compute node.

### Compiler Flags for OpenMP
To compile your source code with OpenMP support, use the appropriate compiler option:
- **GCC**: `-fopenmp`
- **Intel**: `-qopenmp` (or `-openmp` in older versions)

### OpenMP Slurm Script

```bash
#!/bin/bash
#SBATCH --job-name=openmp_job
#SBATCH --account={project_id}
#SBATCH --partition=comp
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-socket=1
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# Set the thread count using the Slurm environment variable
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

./openmp_program.exe
```

---

## NUMA and Hardware Mapping

By default, Slurm does not restrict how threads are mapped to the compute node's hardware layout (NUMA nodes and sockets). Threads might be allocated all on a single socket or spread across multiple sockets, which can lead to cache line bouncing and performance degradation.

To control this mapping and keep threads localized within sockets, use the `--cores-per-socket` parameter:

```bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --cores-per-socket=4
```

This ensures that the 8 requested cores are aligned with socket boundaries.

---

## Hybrid OpenMP/MPI Jobs

Hybrid jobs leverage both distributed-memory parallelism (MPI tasks across different nodes or sockets) and shared-memory parallelism (multiple OpenMP threads per MPI task).

### Hybrid Slurm Script Example
The following script allocates **2 MPI tasks** (1 task per node) and launches **16 OpenMP threads** per task (utilising 16 cores per node, for a total of 32 cores):

```bash
#!/bin/bash
#SBATCH --job-name=hybrid_mpi_openmp
#SBATCH --account={project_id}
#SBATCH --partition=comp
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G
#SBATCH --time=00:30:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# Load MPI and compiler modules (adjust to your required modules)
module load openmpi/4.1.5-gcc-12.3.0

# Export threads per MPI process
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

# Use srun to spawn the hybrid MPI tasks
srun ./hybrid_mpi_openmp_program.exe
```

For more details on managing task and thread affinity, see the [official Running Multi-threaded Jobs documentation](https://docs.erc.monash.edu/Compute/HPC/M3/RunningJobsOnM3/RunningOpenMP/).
