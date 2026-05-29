# Strudel Desktops and IDE Setup on M3

This reference document provides detailed instructions for accessing interactive desktop sessions, configuring local IDEs (VS Code and JupyterLab), and running custom containerised environments (RStudio via `rocker-ultra`) on the Monash M3 HPC cluster.

## Strudel Remote Desktops

Strudel allows you to run interactive remote desktops on M3 compute nodes, accessible directly from your web browser via noVNC.

### Basic Usage
1. Log in to [Strudel Web](https://m3-desktop.erc.monash.edu/).
2. Select the **Desktop** tab.
3. Configure your session:
   - **Operating System**: Select `Rocky 9`.
   - **Time**: Specify the wall-time limit.
   - **GPU/CPU**: Select the required resources (select `No GPUs` for CPU-only tasks).
4. Click **Launch**. Once the session state changes to `RUNNING`, click **Connect**.

### Troubleshooting Connection Failures
- **Home Directory Quota Issues**: If a desktop session fails to start or connection fails, check your home directory quota. Run `user_info` on an M3 login node. VNC cannot write session files if your home directory is over its hard quota (20 GB) or has been over its soft quota (15 GB) for more than a week. Clean up your home space to resolve this.
- **noVNC "Failed to connect to server"**: If you receive this error after clicking connect on the noVNC splash screen, close the noVNC tab and click **Connect** in Strudel again. If it continues to fail, cancel the current desktop session and launch a new one.

---

## Visual Studio Code Remote Setup

To run VS Code (or Cursor) on an M3 compute node rather than on a shared login node (which wastes login node resources and violates cluster usage policies), you must configure SSH tunnelling through a compute job.

### 1. Configure Local VS Code
1. Install **Visual Studio Code** on your local machine.
2. Install the **Remote Development Extension Pack**.
3. Open VS Code Settings (`Ctrl+,` or `Cmd+,` on macOS), search for `Remote.SSH: Remote Server Listen On Socket`, and select the checkbox.

### 2. Configure SSH Connection Info
Open the command palette (`F1` or `Ctrl+Shift+P` / `Cmd+Shift+P`), select **Remote-SSH: Add New SSH Host...**, and enter the command matching your operating system (replace `username` with your M3 username):

- **macOS and Linux**:
  ```bash
  ssh -l username m3-remote-vscode -o ProxyCommand="ssh username@m3.massive.org.au /usr/local/sv2/sshnc.sh"
  ```
- **Windows**:
  ```bash
  ssh -l username m3-remote-vscode -o ProxyCommand="ssh.exe username@m3.massive.org.au /usr/local/sv2/sshnc.sh"
  ```

This `ProxyCommand` executes `sshnc.sh` on M3, which automatically routes your local VS Code SSH traffic to the compute node running your interactive Strudel session.

### 3. Usage Workflow
1. Go to [Strudel Web](https://m3-desktop.erc.monash.edu/) and launch a **Terminal** or **Jupyter Lab** job with your required resources (CPU/GPU, time).
2. Wait until the job state is `RUNNING` (you do not need to connect to it in the browser).
3. On your local machine, open VS Code, open the command palette, select **Remote-SSH: Connect to Host...**, and select `m3-remote-vscode`.

---

## JupyterLab Custom Environments

When launching JupyterLab from Strudel, you can select custom Conda environments from the **Conda environment** dropdown menu.

### How Environments are Discovered
- The dropdown menu is populated from the list of environments registered in your `~/.conda/environments.txt` file.
- Global environment options (such as `dsks_2024.06`) are pre-configured for all users.
- In order for your custom Conda environment to appear in the dropdown menu, it **must** have the `jupyterlab` package installed. Ensure you run:
  ```bash
  conda install jupyterlab
  ```
  inside your active Conda environment.

---

## Rocker-Ultra (RStudio) Setup

The `rocker-ultra` project provides containerised RStudio Server environments optimised for HPC clusters using Singularity/Apptainer.

### Method 1: Launching via Strudel Web (Recommended)
You can add RStudio as a launch option directly in Strudel:
1. Run the following command on M3 to copy the application template:
   ```bash
   mkdir -p ~/.strudel2/apps.d
   curl -L https://raw.githubusercontent.com/MonashBioinformaticsPlatform/rocker-ultra/main/m3/rocker-seurat_4.4.1-5.1.0.strudel.yaml.j2 > ~/.strudel2/apps.d/rocker-seurat_4.4.1-5.1.0.strudel.yaml.j2
   ```
2. Refresh your Strudel Web page. You will now see an RStudio option in the sidebar.

### Method 2: Command-line Tunnelling
If you do not want to use Strudel, you can launch RStudio on a compute node using the command line:
1. Download the `rstudio.sh` wrapper script from the repository and make it executable.
2. Request a compute job (interactive session shown here):
   ```bash
   srun --mem=1G --time=0-12:00 --job-name=my-rstudio ./rstudio.sh
   ```
3. Look at the output of the script to find the assigned compute node (e.g. `m3a002`), port, and generated password.
4. Establish an SSH tunnel from your local machine, using a proxy jump via the login node:
   ```bash
   ssh -i ~/.ssh/id_rsa -J username@m3.massive.org.au -L 8787:localhost:8787 username@m3a002
   ```
   *(Ensure you replace `username` and `m3a002` with your M3 username and the assigned compute node name respectively).*
5. Open your browser and navigate to `http://localhost:8787`, logging in with your username and the generated session password.
