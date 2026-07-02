---
description: Document experiments in JOURNAL.md including datetime stamping and git commits
alwaysApply: false
---

## JOURNAL.md

Document each step you take with reproducible commands in a datetime stamped (`date -Is`) JOURNAL.md file, including git commits it relates to. JOURNAL.md should be considered append-only.

eg:

----

```markdown
## 2026-06-19T12:11:39+10:00 (commits: 123456, abcdefg)

Plots in the "Save outputs" cell now also write a PNG alongside each PDF (`dpi=200`), since PNGs
are easier to drop into chat/slides/docs than PDFs. Updated README.md's Files/Outputs sections to
say "PDF and PNG" instead of "PDF".

Verified with `uvx marimo check analysis.py` (0 issues) and `python analysis.py` (same counts:
131/40/57/6); confirmed `plots/` now contains both `.pdf` and `.png` for all 7 figures.
 
```bash
uvx marimo check analysis.py
source .venv/bin/activate && python analysis.py   # writes plots/*.pdf and plots/*.png
```

```

----