---
description: Nextflow workflow language guidelines including variable escaping, channel types, and operator usage
alwaysApply: false
---

# Nextflow .nf files

- Nextflow is a domain specific language based on Groovy
  - Nextflow docs: https://www.nextflow.io/docs/latest/overview.html
- Inside `script:` sections, ensure $ is correctly escaped - use \${BASH_VARIABLE} or \$(basename x) for shell variables or subshells, and no escaping for ${nextflow_variables}
- Files passed between processes via channels should be or type `path()` or `file()` - passing files as a `val()` is almost always incorrect
- Be aware that Nextflow channels do not behave like regular lists - consult the documentation (https://www.nextflow.io/docs/latest/reference/operator.html) to understand the methods ("operators") available on channels

