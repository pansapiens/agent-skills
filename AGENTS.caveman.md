# AGENTS.caveman.md

## Cautious Coding

---
description: Guidelines to reduce LLM coding mistakes - bias to less code, caution
  over speed
alwaysApply: true
---

Guidelines to reduce LLM coding mistakes. Merge with project instructions if needed.

**Tradeoff:** Bias to less code, caution over speed. Use judgment for trivial tasks.

### 1. Think Before Coding

**No assumption. No hidden confusion. Surface tradeoffs.**

Before coding:
- State assumptions explicitly. If uncertain, ask.
- If multiple options exist, present them — no silent picks.
- If simpler approach exists, say so. Push back if warranted.
- If unclear, stop. Name what confusing. Ask.

### 2. Simplicity First

**Min code to solve problem. No speculation.**

- No extra features.
- No single-use abstractions.
- No unrequested flexibility/configurability.
- No error handling for impossible cases.
- If 200 lines could be 50, rewrite.

Ask: "Is this overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what must change. Clean own mess.**

When editing:
- No adjacent improvements (code, comments, formatting).
- No refactoring working code.
- Match existing style.
- Mention unrelated dead code — do not delete.

When changes create orphans:
- Remove imports/vars/fns made unused by changes.
- Do not remove pre-existing dead code.

Test: Every changed line must trace to user request.

### 4. Goal-Driven Execution

**Define success criteria. Loop to verify.**

Goals:
- "Add validation" → "Write tests for invalid input, make pass"
- "Fix bug" → "Write test reproducing bug, make pass"
- "Refactor X" → "Tests pass before + after"

For multi-step task, state plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Success criteria must be strong. Weak criteria ("make work") cause delay.

---

**Working if:** fewer unused diff changes, fewer rewrites, clarifying questions before coding.

## CHANGELOG.md

---
description: Guidelines for maintaining CHANGELOG.md with proper categorization and
  versioning
alwaysApply: false
---

If CHANGELOG.md exists, update with notable features/fixes after implementation.
- Categories:
  - `Added` for new features.
  - `Changed` for changes in existing functionality.
  - `Deprecated` for soon-to-be removed features.
  - `Removed` for now removed features.
  - `Fixed` for bug fixes.
  - `Security` for vulnerabilities.
- For `[Unreleased]`, do not keep history of intermediate/reverted changes. Only document net changes relative to last release. OK to edit/delete in `[Unreleased]`.

Concise bullets. No implementation details.

## Code style

---
description: Code style guidelines including comments, emojis, language preferences,
  and naming conventions
alwaysApply: false
---

- Avoid excessive comments.
- Avoid emojis. If unsure, use text.
- Do not remove TODO comments unless out of date.
- Comment sparingly. Explain WHY (uncommon/unconventional logic), not WHAT.
- Use Australian English in comments (e.g., colour). Use `color` in code variables.
- DO NOT hardcode secrets (keys, passwords). Load from env, `.env`, or config files.
- Match existing casing/punctuation style for vars, fns, classes, methods.
- Ask for clarification before coding if task unclear.

## Config files

---
description: Preferences for implementing configuration file support in apps
alwaysApply: false
---

- Prefer TOML format.
- Support auto-detect in CWD and system paths like `~/.config/{app_name}/config.toml`.
- Use [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/) for default paths. Use `platformdirs` in Python.
- Support `-c` / `--config` to set path explicitly.
- Allow override of config variables via env vars and CLI args (e.g. 'foo.bar' → `$APPNAME_FOO_BAR` or `--foo-bar`).
- Precedence:
  1. CLI arguments
  2. Env variables (UPPERCASE, prefix `APPNAME_`)
  3. Config in CWD
  4. User config
  5. System config
  6. Default values
- Support env var expansion in config files, e.g. `${MY_VAR}`.

## Docker

---
description: Docker and docker compose best practices including Dockerfile optimizations
  and package management
alwaysApply: false
---

- Use `docker compose`, not `docker-compose`.
- No "version" field in docker-compose files.
- If using `apt-get`, set `ENV DEBIAN_FRONTEND=noninteractive` and clean `/var/lib/apt/lists/`.
- If using `pip install`, use `--no-cache-dir` and set `ENV PIP_BREAK_SYSTEM_PACKAGES=1`.

## .env files (12 factor app)

---
description: Guidelines for managing environment variables and .env files following
  12 factor app principles
alwaysApply: false
---

Web services focus.

- Use `.env` file and provide `.env.example`.
- Add new env vars to `.env.example`.
- Add `.env` to `.gitignore`.
- NEVER delete existing `.env` file.

## FastAPI and SQLAlchemy

---
description: FastAPI and SQLAlchemy best practices including async patterns, migrations,
  and schema management
alwaysApply: false
---

- Use async.
- Use alembic for Postgres migrations.
- Update Pydantic schema + alembic migrations when modifying models.
- If editing migrations, provide alembic command. Early dev: can edit initial migration + provide SQL to update dev DB. Ask preference.

## Git and version control

---
description: Git commit message guidelines and version control best practices
alwaysApply: false
---

- DO NOT include AI/Claude attribution or co-author info in commit messages.
- DO NOT use emojis in commits (unless emoji-specific).
- First line short + concise. Details in bullets after blank line.

## Nextflow .nf files

---
description: Nextflow workflow language guidelines including variable escaping, channel
  types, and operator usage
alwaysApply: false
---

- DSL based on Groovy.
  - Docs: https://www.nextflow.io/docs/latest/overview.html
- Inside `script:`, escape `$` for shell (e.g., `\${BASH_VAR}`, `\$(basename x)`). Do not escape Nextflow variables (`${nf_var}`).
- Pass files via channels as `path()` or `file()`. Avoid `val()`.
- Channels are not lists. Check [operators](https://www.nextflow.io/docs/latest/reference/operator.html).

## PR checklist

---
description: Pre-pull request checklist for updating documentation and configuration
  files
alwaysApply: false
---

- Update `README.md` if needed.
- Update `.env.example` if env vars change.
- Update `CHANGELOG.md` with summarized `[Unreleased]` changes.

## Python

---
description: Python coding standards including type hints, dependency management,
  imports, and tooling preferences
alwaysApply: false
---

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

## R

---
description: R programming guidelines for debugging and working with RMarkdown and
  Quarto documents
alwaysApply: false
---

- Debug R code → provide R example, not Python.
- RMarkdown Rmd or Quarto Qmd: ensure closed code blocks (```).

## Shell scripting

---
description: Shell scripting standards for bash including error handling, syntax conventions,
  and debugging
alwaysApply: false
---

- Assume `/bin/bash`.
- Use `set -euo pipefail`.
- Use `set -x` for debug.
- Syntax:
  - Redirect: no space after `>` (e.g. `>output_file`).
  - Use `${VARIABLE}`, not `$VARIABLE`.
- Run `shellcheck` + fix errors.

## Vue.js

---
description: Vue.js component structure, tooling preferences, and UI toolkit recommendations
alwaysApply: false
---

- Order: `<template>`, `<script>`, `<style>`.
- CDN/simple: use JS.
- Large: `pnpm` + `vite` + TS.
- UI toolkits: PrimeVue (https://primevue.org/cdn/), shadcn/vue (https://github.com/unovue/shadcn-vue).
