# Keeping results current

The failure this guards against is not a broken build. It is a report that renders cleanly and
contradicts itself - a recomputed table saying one thing and a hand-typed sentence two
paragraphs down saying what it used to say.

Recomputed cells update themselves. Hand-written sentences do not.

## Quoting numbers

- **Quote a number from a variable, not from memory.** Prefer an inline
  `` `{python} f"{n_pass}"` `` expression built off the same variables the table uses, so a
  sentence and the table above it cannot disagree.
- **Re-derive any statistic you are about to quote, if the data is to hand.** Report-wide reviews
  reliably turn up ranges that were tight at both ends, counts that double-counted a subset, and
  captions disagreeing with their own chapter's text.
- **When a chapter reports a headline statistic, say which variant it is** - gated or ungated,
  pruned or plain, filtered or all. Two chapters quoting the same quantity at two values are
  usually both right and neither labelled; that reads as an error and costs an afternoon to
  re-derive.
- **Descriptive counts change even when conclusions do not.** "No conclusion changed" is not a
  licence to skip the prose sweep - pass rates, usable counts and N move with a threshold and are
  exactly what a reader checks.

## When a threshold, gate or estimator changes

Grep the chapter for typed numbers, then grep the whole report for them. A statistic quoted in
three chapters changes in three chapters.

```bash
# every occurrence of a recurring statistic, with its chapter
grep -rn 'AUROC \|rho = \|p = ' --include='*.qmd' report/ | sort -t: -k1,1
```

**Methods does not re-render when you edit a chapter, and nothing makes it.** It is perfectly
possible to change a criterion in a chapter and leave Methods asserting the opposite. That is
worse than either being wrong alone, because Methods is what a reader trusts. When a criterion,
threshold or display choice changes, `grep methods.qmd` for it in the same edit.

**When you add a chapter, grep the report for the chapter that produced its inputs.** A new
chapter does not update the one upstream of it, which can be left asserting that the work the
new chapter just did has never been done.

## Superseding a result

Rewrite the chapter to state the new result on its own terms. No "this is a change from what
this chapter previously said", no "the earlier claim does not survive", no "X still holds".

A reader wants the current analysis, not its edit history, and every backward reference is a
sentence that must be re-checked the next time the numbers move. Rewrite the whole passage
rather than appending a correction to it, then re-read the surrounding section for consistency:
captions, the chapter conclusions, the `index.qmd` summary table, and any other section quoting
the same statistic. A partial rewrite that leaves a stale sentence two paragraphs down is worse
than no rewrite, because the chapter now contradicts itself.

Comparison between *different* experiments, phases or arms is a result and belongs in the
report. Comparison between successive revisions of the *same* experiment is edit history and
belongs in the Experiment log. A larger re-run supersedes an undersampled one outright; at most
note in one sentence that the earlier N was underpowered.

A result invalid enough to be worth keeping visible - a serious bug, parameters far outside any
sensible range - moves to Retired rather than being deleted, flagged as superseded. A route
abandoned for a reason should stay pointable-at, and the reason is often the most reusable thing
the work produced.

## The Experiment log chapter

The log is where the edit history goes, so the experiment chapters do not have to carry it. It
is append-only and terse: one row per event, newest at the bottom, never rewritten.

Log an entry when:

- an experiment is run or re-run (note what changed: N, the gate, the inputs)
- a chapter is added, substantially revised, or moved to Retired
- an experiment, arm, phase or variable is renamed
- a headline number changes - record the old value, the new one, and the cause
- a bug is found that invalidates a result already reported
- an iteration happens that is not worth its own place in the narrative

```markdown
| Date | Experiment | Notes |
| ---- | ---------- | ----- |
| 2026-03-04 | 02-gate-sweep | First run, N=15 pilot. |
| 2026-03-07 | 02-gate-sweep | Re-run at N=200. Pass rate 0.31 -> 0.19; the pilot was underpowered, do not quote 0.31. |
| 2026-03-09 | 02-gate-sweep | Renamed "arm C" to "loose gate" report-wide. |
| 2026-03-11 | 01-baseline | Moved to Retired: normalisation applied twice, all effect sizes invalid. |
```

Use `date -Is` or a plain ISO date. When a number changes, the "do not quote the old value" note
is the load-bearing part - it is what stops the superseded figure being reintroduced from an old
draft or from memory after a context compaction.
