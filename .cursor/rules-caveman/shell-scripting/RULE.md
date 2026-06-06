---
description: Shell scripting standards for bash including error handling, syntax conventions, and debugging
alwaysApply: false
---

# Shell scripting

- Assume `/bin/bash`.
- Use `set -euo pipefail`.
- Use `set -x` for debug.
- Syntax:
  - Redirect: no space after `>` (e.g. `>output_file`).
  - Use `${VARIABLE}`, not `$VARIABLE`.
- Run `shellcheck` + fix errors.
