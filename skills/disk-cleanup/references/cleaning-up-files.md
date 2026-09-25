# Cleaning Up Files

This reference provides safe guidelines and commands for clearing tool-specific caches and reclaiming disk space. Before running these commands, ensure you've investigated what is consuming space as outlined in the [Understand Disk Usage](../SKILL.md) skill.

## Python Package Managers

### `uv`

The `uv` package manager uses aggressive caching to speed up operations. The cache can safely be cleared without breaking existing virtual environments.

- **`uv cache clean`**: Safely removes completely unused or outdated cache entries.
  - *Implication*: Only removes data that is no longer needed. Very safe.
- **`uv cache prune`**: More aggressive; removes everything in the cache.
  - *Implication*: The next time you create an environment or install a package, `uv` will have to re-download the required files from the internet, which will take longer.

### `pip`

Pip caches wheel files locally to speed up future installations of the same package version.

- **`pip cache purge`**: Clears the entire pip cache.
  - *Implication*: Safe, but subsequent `pip install` commands will require downloading packages again.

### `conda`

Conda keeps tarballs and extracted packages inside its `pkgs` cache directory (`~/.conda/pkgs` or `envs` depending on setup).

- **`conda clean --all`** (or `conda clean -a`): Removes unused packages and caches (tarballs, index cache, log files).
  - *Implication*: Cannot easily roll back to previous package versions without re-downloading them. Safe for existing environments.
- **`conda clean --packages`**: Removes unused extracted packages.
  - *Implication*: Less aggressive than `--all`, targets only extracted unused packages.

## Container Runtimes

### Docker

Docker caches images, containers, and build layers locally, which can quickly consume gigabytes of storage.

- **`docker system prune`**: Removes all stopped containers, unused networks, dangling images, and build cache.
  - *Implication*: Safe for actively running services. However, if you have stopped containers you intend to restart later, they will be deleted along with their non-persisted data.
- **`docker system prune -a`**: Removes all unused images, not just dangling ones.
  - *Implication*: Very aggressive. Any image not currently used by a running container will be deleted. Next time you run a container based on those images, Docker will have to re-download them.
- **`docker builder prune`**: Removes build cache.
  - *Implication*: Your next `docker build` may take significantly longer as the cache is rebuilt from scratch.

### Apptainer / Singularity

Apptainer caches downloaded SIF images (which can be huge for scientific containers).

- **`apptainer cache clean`**: Gives an interactive prompt to clean the Apptainer cache.
  - *Implication*: Completely safe. Does not delete images you have already saved in your working directory, but requires re-downloading them if you `apptainer pull` the same URI again.

## System Level

### APT (Debian/Ubuntu)

APT caches local copies of downloaded `.deb` package files.

- **`sudo apt-get clean`**: Clears out the local repository of retrieved package files.
  - *Implication*: Very safe. Only affects you if you reinstall the exact same package versions, forcing a re-download.
- **`sudo apt-get autoremove`**: Removes packages that were automatically installed to satisfy dependencies for other packages and are now no longer needed.
  - *Implication*: Generally safe, frees up space from orphaned dependencies without removing packages you explicitly installed.
