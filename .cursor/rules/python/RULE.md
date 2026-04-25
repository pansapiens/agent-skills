---
description: Python coding standards including type hints, dependency management, imports, and tooling preferences
alwaysApply: false
---

# Python

- When writing Python code, include type hints where practical.
- For pure Python projects, prefer using `uv venv` or `uv sync` over conda environments or pip.
- Prefer `pyproject.toml` over `setup.py`. 	
- `pyproject.toml` and `requirements.txt` can coexist.
  - Use `pyproject.toml` for unpinned dependencies (or major version pinned) 
  - Use `requirements.txt` for exact version pinned dependencies
- For executable scripts with `#!/usr/bin/env python` include PEP 722 headers for dependencies like `# /// script` etc.
- Order Python imports with most common built-in packages first (typing, logging, sys, os, time, datetime), followed by most common external packages (numpy as np, pandas as pd, requests), followed by other external packages grouped, and finally internal package imports (eg from .utils import foo).
- Include all required imports, both for typing and other parts of the code. 
- For commandline Python scripts, add `#!/usr/bin/env python` and use `if __name__ == "__main__":`.
- Use argparse to make key variables sensible commandline arguments, UNLESS you are told to use typer (https://typer.tiangolo.com/tutorial/)
- Use the logging package writing to stderr for status messages and errors. 
- Follow common conventions for modern Unix commandline tools. 
	- If there is an output file option (-o / --output), allow `-` to indicate printing to stdout. Use io.StringIO, not pd.compat.StringIO.
- For Python projects that might require significant non-Python dependencies (eg bioinformatics projects with additional commandline software), we may use conda.
  - Use -y for conda install and create.
  - Use the conda-forge and bioconda channels
  - If installing conda from scratch, prefer the miniforge3 distribution instead of miniconda3.
- For determining default config file paths etc, used the `platformdirs` package following the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/)
