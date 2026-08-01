# Strudel2 and SSH on MLeRP

Interactive access, SSH certificates, and IDE remote connections for the Machine Learning eResearch Platform.

## Strudel2

Web portal: https://mlerp.cloud.edu.au/

Strudel2 shows cluster usage and disk quota, and launches interactive apps:

| App | Role |
|-----|------|
| **Terminal** | Shell on requested CPU/GPU resources; good for conda installs, git, file ops |
| **Jupyter Lab** | Notebook IDE; can use provided DSKS envs or custom envs listed in `~/.conda/environments.txt` |
| **Batch** | Submit Python/bash scripts via a form; runs under **Lion** QoS (up to 4 jobs) |
| **VS Code Server** | Browser-based code-server on a compute job |
| **Ollama** | Chat / API access to installed LLMs (`/apps/ollama/ollama list`) |

Login-node web terminal exists for quick tasks but is a shared limited resource — prefer a real Terminal/Panther job for heavy work.

Logs for Strudel2-spawned jobs live under `~/.strudel2/logs/`.

### Jupyter will not connect

Usually home quota is full. Free space, then remove empty runtime files:

```bash
rm -f ~/.local/share/jupyter/runtime/*
```

Brave browser "shields" can also block Strudel2 Jupyter — disable shields for the Strudel2 origin.

## SSH credentials

MLeRP does not use passwords.

### Option A — Download from Strudel2

1. Open **Account Info** in Strudel2
2. **Download SSH Credentials** (key + certificate)
3. Rename files if the browser added `(1)` suffixes
4. `chmod 600` both key and certificate; keep them in the same directory

Credentials expire periodically — re-download when SSH starts failing.

### Option B — SSOSSH

```bash
pip install git+https://github.com/HecticHPCSolutions/ssossh
```

Configure `~/.authservers.json` for MLeRP (see https://docs.mlerp.cloud.edu.au/connecting/ssh.html), then:

```bash
ssossh --setssh   # first time: writes SSH config
ssossh            # refresh ~24h certificates before connecting
```

## Suggested SSH config

```
Host {username}_MLeRP_Monash
    HostName monash-mlerp-login0.mlerp.cloud.edu.au
    User {username}
    IdentityFile {/path/to/ssh/key}

Host {username}_MLeRP_Monash_job
    HostName VSCode
    User {username}
    IdentityFile {/path/to/ssh/key}
    ProxyCommand ssh -i {/path/to/ssh/key} {username}@monash-mlerp-login0.mlerp.cloud.edu.au /apps/strudel2/strudel_apps/sshnc.sh
```

- `{username}_MLeRP_Monash` → login node (admin, light file ops, `sbatch`)
- `{username}_MLeRP_Monash_job` → compute node running a **Terminal** job; if none exists, `sshnc.sh` starts a ~12h **Panther** Terminal job (4 CPUs, 16 GB)

Windows: use `ssh.exe` in the ProxyCommand.

## VS Code / Cursor Remote-SSH

1. Renew certificates (`ssossh` or re-download)
2. Launch a Strudel2 Terminal (or Jupyter) job, **or** rely on `sshnc.sh` to create a Terminal job
3. Remote-SSH connect to `{username}_MLeRP_Monash_job`

Known issues:
- Expired 24h SSOSSH certificates
- Another SSH client open at the same time can confuse VS Code Remote

### Python interpreters

Remote VS Code does not auto-detect MLeRP conda envs. Add interpreters manually (provided paths under `/apps/mambaforge/envs/` or your own env path).

## Data transfer

No dedicated DTN. Options:

- Drag-and-drop in Jupyter Lab or VS Code (VS Code supports folders)
- `git clone` / `git pull` on the cluster
- `wget` / `curl` for public URLs
- `rsync` via the login Host once SSH works:

```bash
rsync -auv -e ssh ./local_dir/ {username}_MLeRP_Monash:~/project/
```

## Official docs

- https://docs.mlerp.cloud.edu.au/connecting/ssh.html
- https://docs.mlerp.cloud.edu.au/usage/strudel2.html
- https://docs.mlerp.cloud.edu.au/usage/data_management.html
- https://docs.mlerp.cloud.edu.au/connecting/vscode.html
