---
name: deslop
description: Remove AI writing patterns from prose, documentation, PR descriptions, and code comments. Use this skill when writing, drafting, editing, reviewing, or revising any text to eliminate predictable AI tells, Claudisms, slop, and formulaic patterns. Trigger this skill whenever the user asks to "deslop", "de-AI", "make it sound human," "remove AI patterns," "remove AI tropes," "clean up AI writing," fix "slop," "avoid terse jargon," or review prose for authenticity. Also use when writing or revising scientific writing (manuscripts, abstracts, cover letters, grant narratives, discussion sections, peer review responses), technical documentation, engineering logs/notes, PR descriptions, commit messages, docstrings, code comments, blog posts, newsletters, memos, and reports.
---

# Deslop: Remove AI Writing Patterns from Prose and Code Comments

Assembled and modified from several sources; see [NOTICE.md](NOTICE.md) for credits, licences and local changes.

Strip predictable AI patterns from writing. Make it sound like a specific human wrote it for a specific reader, not like a language model generated it.

## When to Apply

- Any request to "make it sound human" or "deslop" writing
- Any prose (articles, blog posts, essays, memos, newsletters, reports), engineering logs/notes (bench notes, PRDs, technical docs), or scientific writing (manuscripts, abstracts, cover letters, grant narratives, discussion sections, peer review responses)
- **Code comments, docstrings, commit messages, PR descriptions, dev-facing docs, and log/warning strings** where the writing should read as one developer talking to the next
- Editing, reviewing, or auditing existing files or documentation sites for AI tells and Claudisms

## Who Should Run the Deslop Pass

Where the agent harness supports subagents, run the deslop pass in a subagent rather than inline, and choose a model different from the one that wrote the original text. A model is poor at seeing its own habitual patterns, and a different model family does not share the same ones. Prefer Gemini or Gemma family models for deslopping where the harness makes them available; otherwise use another model family, and only fall back to a fresh-context subagent of the same model if nothing else is available.

Give the subagent the text, the register (scientific, documentation, blog, code comments), the list of keeps (facts, quotations, required terms, length target), any project style guide, and the path to this skill. When the edit comes back, the original author checks that no fact, number, citation or claim strength changed, since a rewrite by another model can alter meaning while improving style.

## Primary Deslopping Workflow (Detector-Driven Loop)

Static regexes and phrase checklists only catch surface buzzwords (`delve`, `tapestry`, `—`). Subtle AI slop and **Claudisms** come from conversational section titles (`What...`, `Where...`, `Why...`, `How...`), noun-phrase captions, inanimate objects taking volitional/postural verbs (`refuses`, `carries forward`, `sits`, `lands`, `holds`, `survives`), and combinations of high-lift words (`nothing`, `whose`, `whichever`, `alone`, `rather`, `merely`, `deliberately`, `silently`, `bare`, `vacuous`, `machinery`).

Whenever you are deslopping existing files or reviewing a draft you wrote, run this **three-step detector-driven loop** using the bundled Multinomial Naive Bayes classifier (`scripts/load_bearing_detector.py`, ported from [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing)):

### Step 1: Scan at Title, Sentence, and Paragraph Granularities First

Before editing, run `load_bearing_detector.py` on the target file(s) or directory. Scoring at **title**, **sentence**, and **paragraph** granularities is essential because localized Claudisms get diluted over a long technical document:

```bash
# Scan documents, titles/headings, paragraphs, and sentences in one pass:
python3 ~/.agents/skills/deslop/scripts/load_bearing_detector.py path/to/target

# Or focus specifically on headings/titles and individual sentences:
python3 ~/.agents/skills/deslop/scripts/load_bearing_detector.py --mode titles --threshold 0.4 path/to/target
python3 ~/.agents/skills/deslop/scripts/load_bearing_detector.py --mode sentences --threshold 0.7 path/to/target

# Score a single sentence or paragraph and inspect per-word log-likelihood contributions:
python3 ~/.agents/skills/deslop/scripts/load_bearing_detector.py --text "Nothing about how a candidate was scored or selected at one checkpoint carries forward to the next."
```

Each flagged item reports `p0` (posterior probability of Claude cluster `0` under a uniform prior), `llr` (log-likelihood gap in nats against the nearest human cluster), and the top positive-evidence words `[word(+d), ...]`.

### Step 2: Diagnose the Evidence Words and Rewrite the Clause

For every high-scoring title, sentence, or paragraph:
1. **Leave legitimate domain nouns intact.** Words like `scaffold`, `binder`, `checkpoint`, `latent`, `oracle`, `residue`, or `chain` have positive weights in the PR corpus only because AI PRs often touch ML/bio code. Never synonym-swap domain terms into worse terminology.
2. **Rewrite the syntactic frame and surrounding Claudisms** that drove the score up:
   - **Conversational/interrogative/narrative headings** (`What...`, `Where...`, `Why...`, `How...`, `"The shape of..."`, `"Three ways to..."`, `"Where things land"`, `"It's still a CIF"`) -> replace with direct noun phrases (`"Outputs"`, `"Workflow overview"`, `"Creating an X"`, `"Output directory layout"`, `"Compatibility with standard mmCIF tools"`).
   - **Noun-phrase captions and narrating the machine's inner life** (`"What the store observed about a row"`, `"The sampler neither knows nor cares..."`) -> rewrite as an imperative to the reader or a plain mechanical statement (Rule 11 / [references/address.md](references/address.md)).
   - **Inanimate subjects taking volitional, social, or postural verbs** (`refuses`, `declines`, `judged`, `decides`, `arrives`, `carries forward`, `hands`, `holds`, `sits`, `lands`, `lives`, `survives`, `invents`) -> restate the condition or mechanical action plainly (Rule 12 / [references/address.md](references/address.md)).
   - **Sweeping negation-carry clauses** (`"Nothing about how X was scored carries forward to the next"`, `"so nothing gets committed by accident"`) -> state what persists or happens directly (`"Candidate scores do not persist between checkpoints"`).

### Step 3: Re-Score and Verify Links

Re-run `load_bearing_detector.py` on the modified files to confirm that `p0` and `llr` dropped and that your rewrites did not introduce new Claudisms. If you renamed section headings in Markdown/MyST/Sphinx documentation, update any `#old-heading-slug` cross-references across the docs and verify the documentation build.

---

## Why These Patterns Appear (Behavior Classes, Not Just Blacklists)

Treat the reference files as **examples of behavior classes**, not closed blacklists:
1. **Language style matching:** The model mirrors the register of its prompt or surrounding draft. Decide what register the reader should hear before writing.
2. **RLHF agreeableness / safe defaults under uncertainty:** Models hedge or validate before making a claim (`"Great question,"`, `"Certainly,"`, `"It's worth noting,"`, `"Here's the thing:"`). Cut the preamble; start with the substantive sentence.
3. **No stopping criterion:** Models default to extending with another caveat, summary, or tricolon. When the point is made, stop.
4. **Repetition penalty pushing toward ornate substitutes:** Under a repetition penalty, simple `"is"`, `"has"`, or `"contains"` get replaced by `"serves as"`, `"stands as"`, `"holds"`, `"carries"`, `"sits"`, or `"lands"`. Prefer the plain verb.
5. **Categorical vs. proportional rules:** Proportional rules ("don't use too many em dashes or tricolons") fail because the model rationalizes each local instance. Em dashes are therefore a hard ban. The remaining limits (one tricolon per piece, one or two quotable lines, one correction frame) are enforced by counting across the whole piece in the counting pass, never by judging each instance as it is written.

## Core Rules

### 1. Cut filler phrases and sentence-start affirmations

Remove throat-clearing openers (`"Here's the thing:"`), sentence-start affirmations (`"Great question."`, `"Absolutely."`, `"Certainly."`, `"Honestly,"`, `"I think,"`), emphasis crutches (`"Let that sink in."`), business jargon (`"navigate the landscape"`), and meta-commentary (`"In this section, we'll explore..."`). See [references/phrases.md](references/phrases.md).

### 2. Break formulaic structures

Avoid binary contrasts / epanorthosis (`"Not X. Y."`), negative listings (`"Not a X. Not a Y. A Z."`), dramatic fragmentation (`"Speed. That's it. That's the tradeoff."`), self-posed rhetorical questions (`"The result? Devastating."`), and anaphora/tricolon abuse. See [references/structures.md](references/structures.md).

### 3. Eliminate AI tropes - by class, not just by phrase

Watch for magic adverbs (`"quietly"`, `"deeply"`, `"fundamentally"`, `"merely"`, `"deliberately"`, `"silently"`), `"delve"` vocabulary, the `"serves as"` dodge, false ranges (`"from X to Y"` where no spectrum exists), superficial participle analyses (`"highlighting its importance"`), invented concept labels (`"the supervision paradox"`), grandiose stakes inflation, patronizing analogies (`"Think of it as..."`), and false vulnerability. See [references/tropes.md](references/tropes.md).

### 4. Choose the voice by register, then hold it

**Scientific prose** (manuscripts, abstracts, theses, grant narratives): default to the passive voice for the work performed (`"Samples were incubated at 37 C"`, `"Binders were designed against site 2"`), and use it consistently through the document. Do not switch between `"we"` and the passive. Name other groups as subjects when attributing their work (`"Smith et al. (2021) showed..."`), and never use the passive to hide who holds a claim (`"It is believed that..."`): cite the source. Correspondence (cover letters, responses to reviewers) may use `"we"`. A project or venue style guide that specifies otherwise takes precedence (for example, a report template that requires first person plural).

**All other prose:** prefer active constructions with named actors. `"The complaint becomes a fix"` is wrong; `"The team fixed it"` is right. If no specific person fits, use `"you"` for instructions in docs/tutorials and blog posts, or `"I"` in individual bench/test notes.

When no person is involved at all (which is common in technical writing), do **not** invent one; see Rule 12.

### 5. Be specific

No vague declaratives (`"The reasons are structural"`). Name the specific thing. No lazy extremes (`"every"`, `"always"`, `"never"`) doing vague work. No vague attributions (`"Experts argue..."`).

In scientific and technical writing, domain terminology is expected (`"weighted interval score"`, `"scRMSD"`). The problem is business buzzwords (`"leverage"`, `"landscape"`, `"ecosystem"`) and AI vocabulary tells (`"delve"`, `"tapestry"`, `"nuanced"`, `"load-bearing"`, `"machinery"`) leaking into technical prose.

### 6. Match register to context

In blog posts, tutorials, and how-to docs, address the reader directly with `"you"` and concrete commands. In scientific writing, maintain appropriate formality, keep the consistent passive voice of Rule 4, and cite specific authors instead of `"researchers have shown"`.

### 7. Vary rhythm

Mix sentence lengths. Two items beat three. End paragraphs differently. Do not stack short punchy fragments for manufactured emphasis. Do not write listicles disguised as prose (`"The first wall... The second wall..."`).

### 8. Trust readers

State facts directly. Skip softening, justification, and hand-holding (`"Let's break this down"`, `"Think of it as..."`). No fractal summaries (telling the reader what you are about to say, saying it, then summarizing what you said). Most technical readers value concise, direct statements.

### 9. Watch formatting tells and replace em dashes properly

No bold-first bullets (every list item starting with a bolded keyword). No unicode arrows (`→`). No signposted conclusions (`"In conclusion..."`). No `"Despite these challenges..."` formulas.

**Never use the em dash (`—`) or its `--` stand-in in prose, with no exceptions.** Most people cannot type one easily, so it reads as machine-written. Choose the replacement that matches the clause relationship:
- If what follows elaborates or explains: use a **colon** (`"The problem is systemic: nobody talks about it."`).
- If it is a parenthetical aside: use **commas**, **parentheses**, or a normal spaced dash (` - `).
- If both sides are independent clauses: start a **new sentence**.
- If it is a trailing filler clause: **cut it**.

### 10. Do not dilute

One point per section. Do not restate the same argument in ten different ways across thousands of words. Do not beat a single metaphor to death. Do not stack historical analogies for false authority (`"Apple didn't build Uber. Facebook didn't build Spotify..."`).

### 11. Address the reader, not the subject matter

Every explanatory sentence in docs, comments, or technical notes should be an **imperative to the reader**, a **"we"/"you" sentence**, or a **direct mechanical statement**. (Scientific manuscripts follow Rule 4 instead.) Do not write noun-phrase captions describing the subject matter from a distance, and do not narrate the machine's inner life.

| Observed from a distance (Caption / Machine POV) | Addressed to the reader |
| --- | --- |
| `What the store observed about a row, so an out-of-order response can't undo a newer one.` | `Sequence row writes so an out-of-order response can't clobber newer data.` |
| `Every type the last response delivered, both matches and included resources.` | `Keep track of all types in the latest response (including matches and included resources).` |
| `The sampler neither knows nor cares which oracle scored the branch.` | `The sampler does not depend on which oracle scored the branch.` |

Also apply this to **section headings**: replace conversational `What`/`Where`/`Why`/`How` titles and narrative hooks (`"Where to go next"`, `"What you get back"`, `"Where things land"`, `"Why charges and bonds matter"`, `"The shape of the workflow"`, `"Three ways to make an X"`) with direct noun phrases (`"Next steps"`, `"Outputs"`, `"Output directory layout"`, `"Formal charges and bond orders"`, `"Workflow overview"`, `"Creating an X"`). See [references/address.md](references/address.md) and [references/structures.md](references/structures.md).

### 12. Inanimate subjects do not take volitional or postural verbs

Things do not arrive, carry, hold, ask, refuse, decline, want, know, learn, suspect, answer, admit, judge, decide, come back, reach, sit, land, live, or survive. When you catch one, **restate the condition or mechanical operation plainly** rather than inventing a person to put in the subject slot.

| Personified / Postural | Plain |
| --- | --- |
| `for mutations that arrive without one` | `in case the mutation did not define it` |
| `a row carrying an xid is keyed by that xid` | `if a row has an xid, we key it by that xid` |
| `a tombstone that refuses the row when it comes back` | `the leftover tombstone rejects the row the next time we fetch it` |
| `nothing about how a candidate was scored carries forward to the next` | `candidate scores do not persist between checkpoints` |
| `conditions.py sits outside any subpackage because it holds shared vocabulary` | `conditions.py is placed at the package root because it defines shared constants` |
| `results land in per_example_metrics.csv` | `results are written to per_example_metrics.csv` |

Also eliminate **mannered metaphors and non-monetary cost/payment/shipping language**: replace `"a dial worth turning"` with `"a parameter worth varying"`, and `"this point earns its keep"` with `"this point matters"`. Do not write `"the price we pay"`, `"what this buys us"`, `"it pays off where..."`, or `"what the jobs cost"` when referring to compute, walltime, or memory rather than money; state the trade-off, advantage, disadvantage, or runtime overhead directly. Avoid `"ship"` / `"ships with"`; use `"provide"`, `"deliver"`, or `"include"`. See [references/address.md](references/address.md) and [references/phrases.md](references/phrases.md).

### 13. Cap the quotables and vary the paragraph shape

One or two turned phrases (aphorism, chiasmus, mirrored re-description, `"What began as X now Y"`) can carry a piece; one per paragraph is a metronome. Most paragraphs should end on a fact, not a landing. Do not let adjacent sentences share one syntactic template, and do not build every paragraph as claim, explanation, widened conclusion. See [references/discourse.md](references/discourse.md).

### 14. Do not over-correct, and do not invent

Removing tells leaves its own fingerprint: semicolons and comma splices taking over from banned em dashes, colloquialism dosed one per paragraph, subjects and grammar stripped in the name of density, every paragraph sealed and ending on a cadence. Aim for the natural distribution of edited prose, not a perfect scorecard. Never fill a gap with invented specifics: verify every superlative and worked example, size claims to the evidence, and when editing someone else's text, flag changes to claim strength rather than making them silently. See [references/discourse.md](references/discourse.md).

## Counting Pass (After Drafting)

1. **Before drafting, list the keeps.** Facts, quotations, required terminology, and any length target. All of it survives the rewrite.
2. **Draft with the core rules and the pre-write check, not the reference catalogs.** Drafting against a full catalog produces checklist-shaped prose.
3. **Count.** After the draft exists, open the reference files and count occurrences mechanically across the whole piece. Authors cannot see their own tics by impression: in one field test, a writer who believed a piece held two aphorisms found eight. [references/discourse.md](references/discourse.md) ends with the counting checklist.
4. **Revise.** Fix what the count found, then apply the excerpt test: could any paragraph, read alone, appear in a journal, a broadsheet or a reference work without drawing attention? If a spot gets flagged again after one repair, restructure the thought (split it, reorder it) instead of trying a third wording.

## Pre-Write / Pre-Edit Check (Active Reasoning)

Recency-weighted attention means rules stated once at the top of a context window lose weight as drafting progresses. Before each paragraph you write or revise, check:
1. **Register & Address:** Is this written *to* the reader (imperative, `"we"`, `"you"`, or plain mechanical statement) rather than a distant caption or narrator voice? In scientific prose, is it in the same passive voice as the rest of the document?
2. **Opener:** Does the first sentence start with a hedged opener, affirmation, or meta-comment (`"Here's..."`, `"It's worth noting..."`, `"What..."`)? If yes, cut it.
3. **Verbs on inanimate subjects:** Are any files, structs, parsers, or configs "sitting", "landing", "holding", "carrying", "refusing", "knowing", or "surviving"? Replace with literal mechanical verbs.
4. **One point & stop:** Does the paragraph state its point once and stop without a trailing summary or tricolon?

## Quick Checks (Post-Draft Pass)

Run these before delivering any prose, documentation, or code comment:

- Did you run `scripts/load_bearing_detector.py` on the titles, sentences, and paragraphs, and rewrite the high-scoring items?
- Heavy use of adverbs or -ly words (`merely`, `deliberately`, `silently`, `empirically`, `quietly`, `fundamentally`)? Cut them.
- Outside scientific prose: any passive voice where a human actor should be named? Find the actor, make them the subject.
- Scientific prose: any switching between `"we"` and the passive? Make it consistently passive. Any `"It is believed/suggested that"`? Cite the source.
- Docs or comments: sentence is a noun-phrase caption describing the subject matter from a distance? Rewrite as an imperative or a `"we"`/`"you"` sentence.
- Inanimate subject with a volitional or postural verb (`arrives`, `carries`, `holds`, `asks`, `refuses`, `declines`, `knows`, `wants`, `judges`, `sits`, `lands`, `lives`, `survives`)? Restate the condition or mechanical operation.
- Conversational or narrative section headings (`What...`, `Where...`, `Why...`, `How...`, `"The shape of..."`, `"Three ways to..."`)? Replace with direct noun phrases (and update any `#anchor` links).
- Non-monetary cost/payment metaphors (`"what this buys us"`, `"the price we pay"`, `"pays off"`, `"what the jobs cost"`) or `"ship"` / `"ships"`? State the trade-off, walltime, or `"provide"`/`"deliver"` directly.
- Clever aside that adds no information? Delete it.
- Any `"here's what/this/that"` throat-clearing or sentence-start affirmation (`"Great question,"`, `"Absolutely,"`, `"Honestly,"`)? Cut to the point.
- Any `"not X, it's Y"` binary contrasts? State Y directly.
- Any self-posed rhetorical question answered immediately? Fold into a statement.
- Three consecutive sentences match length? Break one.
- Paragraph ends with a punchy one-liner? Vary it.
- Em dash (`—`) or `--` anywhere? Remove every one, with no exceptions (colon for elaboration, commas/parentheses/normal `-` for aside, period for independent clause).
- Vague declarative (`"The implications are significant"`)? Name the specific implication.
- Any sentence starting with What/When/Where/Which/Who/Why/How as a crutch? Restructure.
- Meta-joiners (`"The rest of this essay..."`, `"The rest of this page walks through..."`)? Delete or state contents directly.
- `"It's worth noting"` or similar filler transitions? Delete.
- `"Serves as"`, `"stands as"`, `"represents"`, `"marks"` used as a copula? Replace with `"is"`.
- Same metaphor used more than twice? Replace or cut repeats.
- `"Despite these challenges..."` formula? Rewrite.
- Bold-first bullet pattern? Remove bold leads.
- More than one tricolon (three-item list or three parallel clauses) in the piece? Cut the extras to two items or one.
- First sentence a categorical verdict? Open on the situation first.
- More than two quotable closers in the piece? Flatten the extras.
- Thesis restated without new material? Cut the echo.
- Several names for one thing (`"the tool"`, `"the platform"`)? Pick one term.
- Semicolons or comma splices standing in for removed dashes? Use rule 9's replacements.
- Any `"first"`, `"only"`, `"proves"` or other absolute? Verify it or soften it.
- Mixed style conventions (dates, spelling, units)? Pick one and hold it.

## Scoring

When reviewing text, rate 1-10 on each of the six dimensions:

| Dimension | Question |
|-----------|----------|
| Directness | Statements or announcements? |
| Rhythm | Varied or metronomic? |
| Trust | Respects reader intelligence? |
| Authenticity | Sounds like a specific human wrote it (low `load_bearing_detector.py` score)? |
| Density | Anything cuttable, without dropping subjects or grammar? |
| Address | Written to a reader who will act, or about the subject from a distance? |

Below 42/60: revise.

## Reference Files and Scripts

Treat the reference files as catalogs of **instances** of the behavior classes above, not closed lists:

- [scripts/load_bearing_detector.py](scripts/load_bearing_detector.py): Standalone CLI port of [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing) Multinomial Naive Bayes detector (with bundled `scripts/model.js`) for scoring titles, sentences, paragraphs, and documents for Claude-characteristic vocabulary
- [references/address.md](references/address.md): Rules 11 and 12 in depth (reader address, noun-phrase captions, volitional and postural verb lists, worked examples for docs, comments, and warnings)
- [references/phrases.md](references/phrases.md): Phrases to remove or replace (throat-clearing, sentence-start affirmations, emphasis crutches, business jargon, adverbs, meta-commentary, vague declaratives, load-bearing Claudisms, cost/pay/ship metaphors)
- [references/structures.md](references/structures.md): Structural patterns to avoid (binary contrasts, negative listings, conversational/interrogative headings, sweeping negation-carry clauses, dramatic fragmentation, rhetorical setups, false agency, passive voice, rhythm problems)
- [references/tropes.md](references/tropes.md): Full catalog of AI writing tropes (word choice, sentence structure, paragraph structure, tone, formatting, composition)
- [references/discourse.md](references/discourse.md): Paragraph- and argument-level tells (cold-open verdicts, sentence-skeleton runs, quotable saturation, abstraction chains, overclaims), tells left by over-correcting, and the counting checklist
- [references/examples.md](references/examples.md): Before/after transformations showing how to fix common patterns

## Examples

See [references/examples.md](references/examples.md) for prose transformations and [references/address.md](references/address.md) for documentation and code-comment transformations.

**Quick inline example (technical documentation with `load_bearing_detector.py`):**

Before (`p0 = 0.998`):
> "### Checkpoints: where the trajectory branches
>
> Nothing about how a candidate was scored or selected at one checkpoint carries forward to the next: the survivors are simply the new beam, and the next checkpoint judges their children from scratch."

After (`p0 = 0.092`):
> "### Checkpoints
>
> Candidate scores do not persist between checkpoints. Retained candidates form the active beam for the next interval, and the next checkpoint evaluates their branches independently."

Changes: Replaced conversational `where` heading with a noun phrase (`Checkpoints`). Removed sweeping negation-carry phrasing (`Nothing about how... carries forward`), anthropomorphic verbs (`survivors`, `judges`), and high-lift Claude words (`simply`, `from scratch`).

**Quick inline example (code comment):**

Before:
> ```ts
> // What the store observed about a row, so an out-of-order response cannot undo a
> // newer one. Held in each collection's own row metadata rather than in a map here,
> // because the library deletes a row's metadata with the row. A map would need
> // clearing at every path that drops a row, and missing one leaves a tombstone that
> // refuses the row when it comes back.
> ```

After:
> ```ts
> // Sequence row writes so an out-of-order response can't clobber newer data.
> //
> // Store this in each collection's row metadata rather than a map on the store, since
> // the library drops row metadata along with the row. A map would need clearing on
> // every delete path, and if we miss one, the leftover tombstone rejects the row the
> // next time we fetch it.
> ```

Changes: Rewrote the caption as an instruction (Rule 11). Replaced `"refuses the row when it comes back"` with `"rejects the row the next time we fetch it"` (Rule 12).

**Quick inline example (scientific writing):**

Before:
> "It's worth noting that these findings have important implications for how we navigate the challenges of forecast ensembling moving forward. Despite these challenges, this work contributes meaningfully to the growing body of literature, highlighting the need for continued evaluation."

After:
> "If individual model rankings are unstable across geography and time, ensemble methods that weight models by past performance may not improve on equal-weight approaches."

Changes: Replaced filler transition, vague declarative, `"despite these challenges"` formula, and superficial participle analysis with the specific implication.
