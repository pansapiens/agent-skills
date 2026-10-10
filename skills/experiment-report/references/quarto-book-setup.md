# Quarto book setup

For general Quarto mechanics (divs and spans, citations, shortcodes, layout, conditional
content, PDF/revealjs output) use the **quarto-authoring** skill. This file covers only what an
experiment report needs on top of that.

## Layout

```
report/
  _quarto.yml                # book config: format, execute, crossref, jupyter - ALL of it
  index.qmd                  # introduction + summary table of experiments
  NN-experiment-<name>.qmd    # one chapter per experiment
  methods.qmd                # common methods, shared definitions
  glossary.qmd
  experiment-log.qmd         # append-only timestamped log
  supplementary/             # appendix material
  retired/                   # invalid or superseded-beyond-use experiments
  _book/                     # render output (not tracked)
  _freeze/                   # (not tracked)
```

Chapter order is dependency order, not chronological. What everything is computed on comes
first, then what decides which of those computations can be trusted, then the work itself, then
its evaluation. The `NN` prefixes are historical once assigned - keep them stable so run
directories stay findable, and explain the ordering in `index.qmd` rather than renumbering.

Commit the `.qmd` files and every data file they read. The rendered output is a build artifact;
if the inputs are not committed the report cannot be re-rendered.

## `_quarto.yml`

```yaml
project:
  type: book

book:
  title: "<project> experiment report"
  date: today
  chapters:
    - index.qmd
    - part: "Experiments"
      chapters:
        - 01-experiment-baseline.qmd
        - 02-experiment-gate-sweep.qmd
    - methods.qmd
    - glossary.qmd
    - experiment-log.qmd
  appendices:
    - supplementary/index.qmd
    - retired/index.qmd

format:
  html:
    toc: true
    toc-depth: 3
    number-sections: true
    code-fold: true          # the report reads as prose
    code-tools: true
    page-layout: full        # wide figures don't need horizontal scrolling
    fig-width: 8.5
    fig-height: 5

crossref:
  chapters: true             # gives "Figure 6.7.1" / "Table 1.2" style numbering

execute:
  warning: false

jupyter: python3
mermaid:
  theme: neutral
```

`crossref: chapters: true` is what produces the chapter-prefixed figure and table numbers the
report requires. Without it every figure in the book is numbered from a single flat sequence.

Chapters carry only `title:` and `subtitle:`. A `format:` block inside a chapter overrides the
book and silently emits a stray standalone HTML alongside the book output.

Keep figures moderate. `fig-width: 8.5` / `fig-height: 5` with per-figure overrides only where a
wider panel is genuinely needed; 15-inch widths overflow the column. Computed matplotlib figures
carry an intrinsic pixel width but no responsive CSS, so if wide panels overflow, cap them:

```yaml
    include-in-header:
      text: |
        <style>
        .figure-img, .cell-output-display img, .quarto-figure img { max-width: 100%; height: auto; }
        </style>
```

## Numbering tables and figures

Every table and figure needs a label *and* a caption. Both are required - a `tbl-` label without
a caption is not numbered, and the label alone does nothing.

```python
#| label: tbl-gate-counts
#| tbl-cap: "Candidates passing each gate. Percentages are of the column to the left."
```

- A cell emitting several tables or figures takes a YAML **list** of captions
  (`#| tbl-cap:` / `#| fig-subcap:` as a list).
- A markdown table takes its caption on the following line, `: Caption text. {#tbl-axes}`, or is
  wrapped in a div:

  ```markdown
  ::: {#tbl-axes}

  | Axis | Quantity |
  | ---- | -------- |
  | A    | ...      |

  Caption text.
  :::
  ```

- **Never leave a table anonymous.** Review comments have to be able to name what they refer to.
- **Do not mix a figure and a table in one cell.** The table inherits the figure's caption slot
  and goes unnumbered. Split the cell.
- A cell emitting two figures becomes Quarto subfigures. Either give it `fig-subcap:`
  deliberately, or return one figure.

Write captions that say how to read the panel, not what it is. A caption is the only text a
reader who skims has. State the units, the threshold lines, what a marker shape means, and what
the reader is meant to notice.

## Cross-references

Label prefixes: `fig-`, `tbl-`, `sec-`, `eq-`. Give each experiment chapter's major headings
`{#sec-...}` labels so the `index.qmd` summary table can link with `@sec-...` and the links
survive a chapter being renamed or renumbered.

```markdown
## Results {#sec-gate-sweep-results}

Gate choice is discussed in @sec-gate-sweep-results.
```

Sweep for unresolved references before declaring a render clean:

```bash
cd report
refs=$(grep -rho '@\(fig\|tbl\|sec\|eq\)-[a-zA-Z0-9-]*' --include='*.qmd' . | sed 's/@//' | sort -u)
defs=$( { grep -rho '#| label: \(fig\|tbl\)-[a-zA-Z0-9-]*'  --include='*.qmd' . | sed 's/.*label: //';
          grep -rho '%%| label: \(fig\|tbl\)-[a-zA-Z0-9-]*' --include='*.qmd' . | sed 's/.*label: //';
          grep -rho '{#\(fig\|tbl\|sec\|eq\)-[a-zA-Z0-9-]*' --include='*.qmd' . | sed 's/{#//'; } | sort -u)
comm -23 <(echo "$refs") <(echo "$defs")
```

There are three definition syntaxes and forgetting one produces false alarms: `#| label:` in a
code cell, `{#...}` after a markdown table, image or heading, and `%%| label:` inside a mermaid
block. A sweep that greps only `#| label:` reports every mermaid figure as unresolved.

Confirm in the rendered HTML rather than only in source, since an anchor that fails to attach is
invisible in the `.qmd`:

```bash
grep -o 'id="fig-[a-z0-9-]*"' _book/index.html
```

## Callouts

Use callouts for things that are true *now* and will be edited away later - a pending run, a
caveat on an underpowered result, a warning that a chapter's inputs are being regenerated.
Putting them in a callout makes them visible and makes them easy to find and delete.

```markdown
::: {.callout-warning}
## Results pending

The N=200 replicate array is still running. The N=15 pilot is not plotted here because the
completed subset is biased toward tasks that happened not to be preempted.
:::
```

Types: `note`, `warning`, `important`, `tip`, `caution`.

## Numbering on the landing page

Quarto numbers `index.qmd` headings `0.x` and its figures `Figure 1`, `Figure 2`, ... rather
than `1.1`. That is Quarto's index-page convention, not a misconfiguration, and `@fig-...`
cross-references to them resolve normally, including from other chapters.
