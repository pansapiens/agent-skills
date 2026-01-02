---
description: Shell scripting standards for bash including error handling, syntax conventions, and debugging
alwaysApply: false
---

# Shell scripting
- Assume we have /bin/bash
- Unless specified, use the options: set -euo pipefail
- For debugging, the -x option may help: set -x
- Syntax: 
  - When redirecting to a file, don't add a space after >, do >output_file
  - Use "${VARIBLE}" naming, not $VARIABLE
- If available, run shellcheck and fix any errors highlighted

