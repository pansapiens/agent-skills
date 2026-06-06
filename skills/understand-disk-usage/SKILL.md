---
name: understand-disk-usage
description: Investigate Linux disk space. Use for 'disk full', 'storage usage', or finding large files.
priority: 5
---

# Understand Disk Usage

Systematically investigate disk space usage to identify what is consuming storage, without deleting anything.

## When to Use

Use this skill when:
- The system is out of space ("disk full", "Insufficient disk space", "Disk quota exceeded", "No space left on device")
- The user is trying to free up storage
- You need to find large files or directories safely

## Tool Setup & Verification

Our preferred tool is `dust`. First, check if it is available:

```bash
command -v dust || command -v /usr/bin/dust
```

**Need `dust`?** 
If available, use `dust` in the commands below.
If not, drop `-d` flags and use `du -h --max-depth=1 <path> | sort -hr` instead of `dust -d 1 <path>`.

Optional: `dust` can be installed from https://github.com/bootandy/dust (however if disk space is running low, you may need to put it in `/dev/shm`)

## Quick Check

Start with overall disk usage to identify which partition is full:

```bash
df -h
```

## Priority Paths to Check First

Before scanning the whole disk, check these common offenders. They accumulate large amounts of data silently:

```bash
dust -d 1 ~/ai-models ~/.cache ~/.apptainer ~/Downloads ~/Desktop /data /var/lib/docker /var /tmp 2>/dev/null
```

### Common High-Consumption Paths

| Path | Typical contents |
|---|---|
| `~/ai-models` or `~/.local/share/models` | LLM weights (GGUF files), ML model checkpoints |
| `~/.cache` | Package manager caches (uv, pip, conda), HuggingFace model cache |
| `~/.apptainer` | Container images (SIF files), each 5-15GB |
| `~/Downloads` | Installers, large archives |
| `/data` | Docker volumes, service data, backups |
| `/var/lib/docker` | Docker images, containers, volumes, build cache |
| `/var` | System logs, snap/flatpak packages, apt cache |

## Detailed Investigation

Once you know which paths are large, drill into them.

### Scan a Directory Tree

```bash
dust -d 2 /path/to/dir
```

Use `-d` to control depth. Start with `-d 1` for an overview, then increase.

### Filter by Minimum Size

Skip small files to focus on what matters:

```bash
dust -z 1G /path/to/dir
```

### Exclude Directories

```bash
dust -X node_modules -X .git /path/to/dir
```

## Docker-Specific Investigation

```bash
# Overview of Docker disk usage
docker system df

# Reclaimable space (dry run, does not delete)
docker system df -v | grep "Total reclaimable"
```

## System Paths Investigation

```bash
# /var breakdown (logs, packages, caches)
sudo dust -d 2 /var

# Journal log size
journalctl --disk-usage

# Snap packages (can accumulate old revisions)
snap list --all | awk '/disabled/{print $1, $3}' | while read name rev; do echo "$name $rev"; done
```

### Old Kernels

Old kernels accumulate as apt marks newer versions as auto-installed dependencies. They eat **1-3G** each and **are not reliably cleaned by `apt autopurge`** — it often misses them because they're not marked `auto`.

**Always confirm the running kernel first:**

```bash
uname -r
```

**List all installed kernels:**

```bash
dpkg --list | grep linux-image
```
Packages with status `ii` are still installed. `rc` means already removed (config remnants only).

**Safe explicit purge (remove all but current kernel + one backup):**

```bash
# Identify old kernels (anything older than the running kernel)
dpkg --list | grep '^ii.*linux-image-*[0-9]' | grep -v "$(uname -r | sed 's/-generic//')" | awk '{print $2}'

# Then purge them. Example: if running 6.14.0-33-generic, remove 6.11.x:
sudo apt purge linux-image-6.11.0-19-generic linux-headers-6.11.0-17-generic linux-headers-6.11.0-19-generic
```

**Safety rule:** Never remove the currently running kernel. Keep at least 1-2 newer kernels as fallback. If in doubt, keep the three most recent.

## Home Directory Hidden Caches

Hidden directories in home are often the biggest silent consumers:

```bash
dust -d 1 ~/.cache ~/.apptainer ~/.local/share ~/.config
```

## Full Disk Scan (Last Resort)

If priority paths don't explain the usage, ask the user to scan from root:

```bash
sudo dust -d 1 -x -i / | tee /dev/shm/dust-disk-usage.txt
```

This skips hidden files (`-i`) and stays on the root filesystem (`-x`). Read `/dev/shm/dust-disk-usage.txt` and drill into any surprisingly large directories.

## Reporting Format

Present results as a prioritized summary:
1. Overall disk status (`df -h` output)
2. Top offenders ranked by size
3. Reclaimable space (Docker, caches with known cleanup)
4. Note what is safe to clean vs what needs user decision

**Never delete anything.** Only report and summarise.
