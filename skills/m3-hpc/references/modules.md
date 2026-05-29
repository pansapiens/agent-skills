# Environment Modules on M3

M3 uses Environment Modules to manage most software. Each version of a software package has its own module prepared by the M3 administrators. You load a module to configure your environment to use that software.

## Module Locations and OS Compatibility

Modules on M3 are located in a few different directories. Depending on the operating system migration state, some modules may be deprecated or broken:

| Directory | Status | Notes |
|-----------|--------|-------|
| `/apps/modulefiles/` | **Active / Current** | Modules installed and built for Rocky Linux 9. These are the most up-to-date and reliable. |
| `/apps/spack/modulefiles/` | **Active / Current** | Spack-managed software modules for Rocky Linux 9. |
| `/usr/local/Modules/modulefiles` | **Deprecated** | Legacy modules installed under CentOS 7. Many of these are broken or incompatible since the upgrade to Rocky Linux 9. |

> [!WARNING]
> While deprecated CentOS 7 modules are still visible under `/usr/local`, they are not removed to prevent breaking legacy scripts. However, they may fail with library errors. Always prefer modules located under `/apps/modulefiles/` where available.

## Command Reference

### Listing Available Modules (`module avail`)

To see all modules available on the cluster:
```bash
module avail
```

To narrow down the search, append a partial software name (case-sensitive) or specific family:
```bash
# List all modules whose name starts with "tra"
module avail tra

# List all versions of the "amber" module
module avail amber/
```

To search for a module across all hierarchies or view more description, you can also use:
```bash
module spider {name}
```

### Loading Modules (`module load`)

To load the default version of a software package:
```bash
module load amber
```
> [!NOTE]
> Loading a module without a version loads its default version (e.g., `amber/24-single-gpu` for `amber`). This default version may change when software is updated.

**For research reproducibility, you should always specify the exact version of the module in your submit scripts:**
```bash
module load amber/24
```

### Listing Loaded Modules (`module list`)

To check what modules are currently active in your current session:
```bash
module list
```

### Unloading Modules (`module unload` & `module purge`)

To unload a specific module (which also unloads any automatically loaded dependent modules that are no longer required):
```bash
module unload amber/24-single-gpu
```

To completely clear your environment of all loaded modules:
```bash
module purge
```
This is highly recommended at the beginning of job submission scripts to ensure a clean environment.

## Inspecting Module Actions (`module show`)

To see what changes a module makes to environment variables without actually loading it:
```bash
module show {name}/{version}
```

### Explanation of `module show` Output

Common fields and directives shown in the output include:
- `module-whatis {Description}`: A brief summary of the software.
- `module load {dependency}`: Indicates that loading this module will automatically load `{dependency}`.
- `prepend-path PATH {path}`: Prepends the software's binary directory to your `PATH` environment variable, enabling you to run its command line executables.
- `setenv AMBERHOME {path}`: Sets a specific environment variable needed by the software or custom paths created by admins.
- `conflict {name}`: Prevents loading another module of the same family (e.g., loading different versions of `amber` simultaneously) to avoid runtime library conflicts.

## Licensed and Restricted Software

Some modules are visible via `module avail` but cannot be run immediately because they are restricted due to licensing. If you load a restricted module and attempt to run it, you may see `Permission denied` or `Command not found` errors.

### Requesting Access via Karaage

To request access to restricted software (e.g. `alphafold`):
1. Navigate to the [Karaage Software Page](https://hpc.erc.monash.edu/karaage/software/).
2. Find the software name and click on it.
3. Review the **Software details**:
   - **Restricted**: If "Yes", your request must be approved by an administrator (takes up to 2 weeks). If "No", you are added to the group automatically upon accepting the licence.
   - **Group**: The Linux group used to manage filesystem permissions for the software.
4. Scroll down, read the terms of use or licence agreement, and click **I accept**.

### Propagation and Verification

- **Propagation Delay**: Once approved, changes take a few minutes to propagate to the HPC backend.
- **Session Limitations**: Access applies only to **new** shell/desktop sessions. Any active terminal or Strudel session started before approval will not have access.
- **Verification**: Connect via a new SSH session and run the `groups` command:
  ```bash
  groups
  ```
  Verify that the software group name (from Karaage) is listed in your groups.
