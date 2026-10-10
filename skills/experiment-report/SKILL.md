---
name: experiment-report
description: Write and update a Quarto book reporting ongoing computational experiments - a lab notebook for computational work, one chapter per experiment. Use this skill whenever starting, editing, rendering, reviewing or restructuring such a report, whenever a new experiment or analysis run needs writing up, and whenever a result changes and the prose, figures and summary tables have to follow - even if the user just says "write up this experiment" or "update the report".
compatibility: Requires quarto, and python virtual environments (eg uv, conda, pixi)
---

# Experiment Report

Maintain a Quarto book (Jupyter/Python) with the goal and outcomes of each experiment.

Think of it a bit like a lab notebook for computational experiments.

# Rules

- Every table and figure must be numbered, eg: Figure 6.7.1 or Table 1.2

- For detailed rules and guidance on language use and formatting, see [language-and-formatting.md](references/language-and-formatting.md).

- Unless otherwise specified, put the documents in `./report`.

- If an analysis has been revised, tweaked and re-run, don't refer to the old version, and DON'T compare and contrast the new results with the old results - sometimes we iteratively revise/debug an experiment and supersede the original finding rapidly - we don't need to compare each step in that process. If we run a larger version of an experiment (greater N, more sampling), we will generally ignore the original undersampled result and just treat the new result as the result of the experiment (we can comment briefly the a lower N is underpowered with justification).

- You CAN compare findings between different experiments / phases / sections if a similar experiment was repeated in a different way.

- Don't type a number into prose that a cell already computes - quote it from a variable with an inline `` `{python} f"{n_pass}"` `` expression. See [keeping-results-current.md](references/keeping-results-current.md).

- For general Quarto mechanics not covered here (divs, citations, layout, shortcodes, non-HTML output), use the **quarto-authoring** skill.

# Report structure

The report should have the following sections:

## index.qmd

This should have a short introductory paragraph in an 'Introduction' or 'Background' section, followed by a summary table of each experiment, with links to that section/chapter.

## {NN}-experiment-{short_name}.qmd

Each experiment chapter should have sections:

- Aims/Goals
- Methods (can link to Methods section and describe the variation of the core method)
- Results
- Conclusions
- Next steps

Use appropriate figures and tables to describe results.

Put the pipeline/design diagram in Methods, before any numbers, marking what this experiment varies. State what was fixed in advance before reporting it; mark anything decided after seeing the numbers as EXPLORATORY.

## Methods

Put common methods used across multiple experiments in here, and only describe the variation of the method in the experiment itself.

Use mermaid diagrams to describe experimental designs, data flows and pipelines as appropriate.

## Glossary

Every acronym and piece of jargon used anywhere in the report.

## Experiment log

This document is an append-only, terse timestamped log of when each experiment was run, report updates or revisions, renamings, major new findings, and any other significant events related to the experiment. It can include log entries iterations on experiments that aren't explicitly discussed in the experiment section itself. Keep it as a table with columns: | Date | Experiment | Notes |

This is where edit history goes, so the experiment chapters don't have to carry it. When a number changes, record the old value, the new one and the cause - that note is what stops a superseded figure being reintroduced later.

```markdown
| Date | Experiment | Notes |
| ---- | ---------- | ----- |
| 2026-03-07 | 02-gate-sweep | Re-run at N=200. Pass rate 0.31 -> 0.19; the pilot was underpowered, do not quote 0.31. |
| 2026-03-11 | 01-baseline | Moved to Retired: normalisation applied twice, all effect sizes invalid. |
```

See [keeping-results-current.md](references/keeping-results-current.md) for what to log.

## Supplementary / Appendix

## Retired

This is a section where we put experiments that should generally be ignored and sit outside the clean narrative - cases where a serious bug made the results invalid, or parameters were so comically wrong there is little insight to be gained. We maintain these for transparency but should generally ignore them.

# Review your work

After writing a new section or updating an existing one, review the entire document for consistency. Did the conclusions change ? Have experiment names or variable, phase, gate, arm names changed and need to be updated document wide ?

Work through [checklists.md](references/checklists.md) before calling an edit done.

# Reference documents

- [quarto-book-setup.md](references/quarto-book-setup.md) - directory layout, `_quarto.yml` (including the `crossref` setting that gives chapter-prefixed numbering), labels and captions, cross-reference sweeps, callouts.
- [rendering-and-gotchas.md](references/rendering-and-gotchas.md) - rendering, stale output, verifying a render actually produced output, Python cell traps.
- [keeping-results-current.md](references/keeping-results-current.md) - quoting numbers, superseding a result, what belongs in the Experiment log.
- [figures.md](references/figures.md) - what a figure may and may not be evidence for, scale choice, plotting traps.
- [mermaid-diagrams.md](references/mermaid-diagrams.md) - numbered mermaid figures, pipeline diagram conventions, the three rendering traps.
- [statistics-and-claims.md](references/statistics-and-claims.md) - naming quantities, stating nulls, confidence intervals and tests, multiple testing.
- [language-and-formatting.md](references/language-and-formatting.md) - prose style.
- [checklists.md](references/checklists.md) - before an edit is done, after superseding a result, at a phase boundary.
