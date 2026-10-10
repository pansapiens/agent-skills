# Statistics and claims

## Wording

- **Name a quantity by what it measures, with any internal code in brackets** - `predicted
  binding energy (Axis D)`, not `Axis D`; `loose gate (arm C)`, not `arm C`. A bare letter or
  index carries no meaning to a reader arriving at a
  figure. Apply it wherever the name appears without a nearby definition (index page, figures,
  diagrams, captions); inside a chapter that defines its terms on first use, the short form is
  correct anaphora. Convert opportunistically rather than in one sweep.
- **Say what a number is before saying what it means.** A model-derived or sequence-derived score
  is not evidence of the physical property it correlates with. State the distinction once in
  Methods and never let a chapter blur it.
- **Prefer "no detectable difference" to "X is better"** when the test did not separate them, and
  pair every null with a power statement if one is available. A null with a minimum detectable
  effect is a result; a null without one is an absence of information.
- **Report what was filtered out and why.** Silent truncation of a candidate list reads as full
  coverage when it is not.
- Define every acronym and piece of jargon in the Glossary. Do not assume the reader knows the
  shorthand.

## Declare the analysis before the numbers arrive

State in the chapter what was fixed in advance - arms, N, the held-out criterion, the primary
outcome, and the power available. Anything added after the numbers arrive is marked
**EXPLORATORY** and stays out of every corrected family.

Where the experiment trades one quantity against another, make the primary outcome the ratio,
not the two rates side by side. "Saves 40% of compute, loses 12% of hits" invites the reader to
do the division and get it wrong; state the efficiency directly and say where break-even is.

## Tests

Never present raw counts or rates as if conclusive.

- Proportions: **Wilson** confidence intervals.
- Paired-by-seed arms: **McNemar's exact** on the discordant pairs. Unpaired 2x2: Fisher's exact.
  Continuous paired: Wilcoxon signed-rank.
- Say clearly when a difference is **not** significant, and label descriptive-but-untested
  observations as such. N=45 rarely resolves a 5-vs-1 split.
- Always annotate a ROC or operating-characteristic curve with its AUC (and p) in the legend or
  title. A curve without its AUC makes the reader estimate by eye the one number that decides
  the panel.

## Multiple testing

Use **Benjamini-Hochberg, not Bonferroni**, and report a q-value alongside the raw p. Bonferroni
is conservative enough to call a real AUC of 0.63 non-significant, which turns a correct
conclusion into an argument from the wrong quantity. BH stays valid under the positive
dependence typical of several predictors derived from one source.

- The **family is one table** - the predictors tried against a single outcome.
- **Declared negative controls stay out of the family.** Including one inflates every other q by
  n/(n-1).
- **A pre-specified hypothesis is one test.** Say so, and report it uncorrected as well as
  corrected.
- **A q near the threshold is not stable.** Unlike Bonferroni, BH's verdict on one test depends
  on the other p-values. Say so rather than leaning on it, and argue from effect size wherever
  effect size settles the question.
- If `statsmodels` is unavailable, BH is about ten lines by hand; `scipy.stats` covers Fisher and
  the binomial McNemar.
