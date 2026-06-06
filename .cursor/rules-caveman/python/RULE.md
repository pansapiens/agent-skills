---
description: Python coding standards including type hints, dependency management, imports, and tooling preferences
alwaysApply: false
---

# Python

- Include type hints where practical.
- Prefer `uv venv` or `uv sync` for pure Python.
- Prefer `pyproject.toml` over `setup.py`.
- `pyproject.toml` (unpinned/major) and `requirements.txt` (pinned) can coexist.
- Executable scripts (`#!/usr/bin/env python`): use PEP 722 headers (`# /// script`).
- Import order: stdlib (typing, logging, sys, os, time, datetime), external (numpy, pandas, requests), other external, internal.
- Include all required imports.
- CLI scripts: use `#!/usr/bin/env python` and `if __name__ == "__main__":`.
- Use `argparse` for CLI args, unless told to use `typer`.
- Use `logging` to stderr for status/errors.
- Modern CLI conventions: support `-` for stdout if `-o`/`--output` exists. Use `io.StringIO`.
- Conda for complex dependencies: use `-y` for install/create, conda-forge/bioconda channels. Prefer miniforge3.
- Use `platformdirs` following [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/) for defaults.
