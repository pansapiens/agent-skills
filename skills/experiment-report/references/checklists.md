# Checklists

## Before saying an edit is done

- [ ] chapter renders, and `index.qmd` / `methods.qmd` were rebuilt **by name** if either changed
- [ ] no stale `_book/*.html` - compare source and output mtimes
- [ ] output counts verified in the rendered HTML, not just "all cells reported Done"
- [ ] cross-reference sweep clean, with all three label syntaxes in the definition set
- [ ] every new table and figure has both a label and a caption
- [ ] any number you typed is either recomputed or an inline expression
- [ ] diagrams screenshotted and actually looked at

## After a result is superseded

- [ ] passage rewritten on its own terms, no backward references to the previous version
- [ ] surrounding section re-read: captions, chapter conclusions, `index.qmd` summary row
- [ ] report-wide grep for the old number
- [ ] `methods.qmd` grepped if a definition, criterion or threshold moved
- [ ] Experiment log row added: old value, new value, cause, and "do not quote the old number"

## At an experiment or phase boundary

- [ ] `index.qmd` introduction and summary table updated
- [ ] upstream chapter told about the new chapter that consumes its outputs
- [ ] Glossary covers every acronym the new chapter introduced
- [ ] Experiment log rows added for every run, revision and rename since the last boundary
- [ ] full render, cross-reference sweep, and a read-through of the main chapters
- [ ] `CHANGELOG.md` and `JOURNAL.md` updated if the project keeps them
- [ ] checkpoint to the project log
