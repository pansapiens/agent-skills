# Figures

## Honesty rules

- **The layout is never the evidence.** A statistic must come from the underlying data, never
  from a drawing of it. Adjacency in a 1-D leaf ordering is a different and weaker quantity than
  nearest-neighbour in the full space. A layout bug can invent the exact result the figure was
  drawn to display, and it will look convincing.
- **Judge an ordination by whether it preserves the claim**, not by percent variance explained.
  Recompute the statistic being claimed using distances in the plane and divide by its
  full-space value. Variance share gets the answer wrong in both directions.
- **Do not use a method that optimises the thing you are trying to show.** A neighbourhood-
  preserving embedding showing clean neighbourhood structure is displaying its own objective,
  not evidence.
- **Pick the display by measurement, not preference**, and say in Methods which measurement
  decided it.

## Scale choice

Truncate, do not log, a quantity that is effectively binary past a threshold. If beyond the gate
a value simply means "failed" and how far beyond says little, a log axis spends most of the
figure resolving distinctions that do not mean anything. House construction:

- linear axis truncated a little above the gate; dashed line at the gate
- distinct markers for pass and fail
- over-ceiling points drawn on a dotted ceiling line, with their count and true maximum
  annotated (white `bbox`, high `zorder`)
- boxes computed on untruncated values, with only the drawn whisker clipped - otherwise a wide
  group's upper whisker runs off the axis as a bare vertical line

Use the same construction for every figure of that quantity, and cross-reference the first one
from the others so a reader knows it is a house style.

## Plotting traps that have produced wrong figures

- **`sns.clustermap` autoscales every panel to its own range** unless `vmin`/`vmax` are passed.
  Panels of the same quantity then get different colour scales and "this one is darker" means
  nothing. Pin one scale per quantity type and share it across every panel of that type; never
  compare panels of different types by colour.
- **`row_colors` wants a DataFrame with a matching index**, not `.values` - passing values raises
  an opaque `IndexError ... axis 1 with size 3`. But `pd.DataFrame({"x": series}, index=other_series)`
  reindexes on the index values and silently yields all-NaN, which renders as blank bars with
  axes and labels still present, looking like a sizing problem. Pass `.values` into the frame,
  and set `colors_ratio` explicitly (the default is split across all bars).
- **`fig.colorbar(im, ax=axes)` steals space from a panel.** Call `tight_layout()`, then add a
  dedicated `fig.add_axes` cax.
- **Annotations land on top of clipped points.** Clipped values pile up exactly on the ceiling
  line. Give the text a white `bbox` and a high `zorder`.
- **Two factors with the same palette are indistinguishable** on a figure carrying both as
  annotation strips. Do not fix this by recolouring if the palette has to stay stable across the
  report - label each strip with a letter at the margin and prefix the legend entries to match.
  State the strip order inner-first if that is how they are drawn, and check the drawn offsets
  against the caption rather than trusting the caption.
