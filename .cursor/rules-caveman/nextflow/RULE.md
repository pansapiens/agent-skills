---
description: Nextflow workflow language guidelines including variable escaping, channel types, and operator usage
alwaysApply: false
---

# Nextflow .nf files

- DSL based on Groovy.
  - Docs: https://www.nextflow.io/docs/latest/overview.html
- Inside `script:`, escape `$` for shell (e.g., `\${BASH_VAR}`, `\$(basename x)`). Do not escape Nextflow variables (`${nf_var}`).
- Pass files via channels as `path()` or `file()`. Avoid `val()`.
- Channels are not lists. Check [operators](https://www.nextflow.io/docs/latest/reference/operator.html).
