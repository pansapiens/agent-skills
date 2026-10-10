# Mermaid diagrams

Use mermaid for experimental designs, data flows and pipelines. Quarto renders mermaid natively
- do not load a JS library. Set `mermaid: theme: neutral` in `_quarto.yml`.

## Numbered figures

Quarto cell options go in `%%|` comments at the top of the block and coexist with mermaid's own
`---` config frontmatter, which follows them:

````markdown
```{mermaid}
%%| label: fig-pipeline-phase3
%%| fig-cap: "Phase 3 pipeline. Green nodes are new; dashed amber nodes are the parameters varied."
---
config:
  flowchart:
    wrappingWidth: 320
---
flowchart TD
  ...
```
````

## Pipeline diagram conventions

Place the pipeline diagram immediately after the aims, **before any numbers**, so a reader sees
which moving parts are in play before reading a result.

Diff the diagram against the baseline pipeline, or against the previous experiment if this one
builds directly on it. Mark the gates and parameters under test on the diagram itself. Leave
untouched nodes in the plain baseline style - the diff is the message. A stage deliberately not
run gets an explicit greyed "NOT RUN" node, not omission.

```
classDef io      fill:#eef,stroke:#88a
classDef changed fill:#d7f5dd,stroke:#1a7f37,stroke-width:2px                       %% added/replaced
classDef testing fill:#fff3cd,stroke:#a67c00,stroke-width:2px,stroke-dasharray:5 3  %% varied
classDef absent  fill:#f5f5f5,stroke:#999,stroke-dasharray:3 3,color:#777           %% NOT RUN
```

Edge labels carry the parameter under test and its arms.

Use `flowchart TD`, not `LR`, for a pipeline: a left-to-right chain of many stages shrinks the
boxes past readability at page width. `LR` is fine for a small fan-out sub-diagram.

## The three traps

**1. Subgraphs render dark and unreadable.** Quarto's `themeCSS` sets
`.cluster rect{fill:var(--mermaid-fg-color--lightest)}`, which under common bootstrap themes is a
mid-dark slate; and because `--mermaid-node-bg-color` is semi-transparent, the nodes inside the
cluster go dark too. Fix per subgraph:

```
style <id> fill:#F6F8FA,stroke:#C6CFD8,color:#343A40
```

This is not a mermaid bug. Leave a comment in the block saying why the style line is there, or
someone will delete it.

**2. A syntax error is silent.** Quarto emits the `<pre class="mermaid">` and exits 0; the
failure appears only in a browser. Either parse offline (`npm i mermaid jsdom`, extract the
blocks, `await mermaid.parse(block)` - jsdom needs `window`, `document` and `navigator` defined
via `Object.defineProperty`, and `CSSStyleSheet` and friends copied off `dom.window` if you want
`render` rather than `parse`), or screenshot the rendered page:

```bash
chromium-browser --headless --screenshot=out.png --window-size=1400,20000 \
  "file://$PWD/_book/index.html"
```

**3. Labels wrap mid-phrase.** Node labels wrap at `flowchart.wrappingWidth` (raise it to ~320 in
the block's frontmatter) so lines break at your `<br>` rather than mid-word, but only if each
`<br>`-delimited line actually fits. Long subgraph titles wrap too and collide with edges
entering the cluster; keep them to one short line.

Only a screenshot catches traps 1 and 3. Render, screenshot, crop to each diagram, and look at
it. A diagram is the first thing a reader looks at and the last thing a render check verifies.

Quarto 1.10 bundles mermaid 11.12 and initialises it with `{startOnLoad: false}` plus a
`themeCSS`, with no `securityLevel` - so the default applies and `<b>` / `<br>` inside node
labels both render.
