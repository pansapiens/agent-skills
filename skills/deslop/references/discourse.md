# Discourse and Over-Correction Tells

Adapted from the English material in the `humanizer` skill of
[Prism-Shadow/penguin-harness](https://github.com/Prism-Shadow/penguin-harness/tree/main/plugins/humanizer/skills/humanizer)
(Apache-2.0). That skill's authors ran seven rounds of drafting, blind editorial review and
revision, and found two things the phrase and structure catalogs in this skill do not catch:

1. Text can pass every sentence-level check and still read as AI, because the tells live in the
   shape of paragraphs and the argument.
2. The deslop pass leaves its own fingerprint. Blind reviewers called one batch "prose written
   under an anti-AI blacklist". The target is the natural distribution of edited prose, not zero
   hits on every counter.

Use this file during the census step (see SKILL.md), not while drafting. Drafting against a
checklist produces prose that reads as checklist-compliant.

## Discourse tells

These surface only when you read for structure rather than wording.

### Cold-open verdict

The first sentence is a categorical pronouncement, often hinged on a colon: "LLMs only generate
text: they cannot query a database or drive software." This is what deleting every
throat-clearing opener produces when taken too far. **Fix:** open on the situation the piece
answers (a problem, a dated event, an observable fact) and let the verdict follow. One grounding
sentence that states a fact is orientation, not filler; an era opener or throat-clearing line
(see [phrases.md](phrases.md)) is still filler.

### Sentence-skeleton runs

Adjacent sentences reuse one syntactic template with no repeated words: "Write one server, and
every compatible app can call it; add support, and every existing server plugs in." Maxim
anaphora is the loud version: "Cutting scope beats estimating harder. Team history beats
introspection. Ranges beat points." Each sentence is fine alone; three on one template is a
stencil. **Fix:** rebuild one unit on a different frame. Lead with the condition, subordinate one
event under another so the weights differ, or swap an abstract half for a concrete instance.

### Quotable saturation

Every paragraph runs claim, explanation, widened conclusion, and ends on a quotable line. Count
every turned phrase, not only verdict punchlines:

- chiasmus ("engages with detail / the detail it engages with")
- mirrored re-description ("a resolution to fall for the same thing more slowly")
- balanced paired verbs ("softened his law without repealing it")
- "X dressed up as Y"
- bookend kickers ("What began as X now Y") and ring closers ("That, in the end, is...")

In a field test, an essay whose author believed it held two aphorisms held eight. One or two can
carry a piece. **Fix:** keep the best one or two, flatten the rest, and let some paragraphs end
on a fact, a number or an open question. A paragraph that ends flat is fine.

### Restatement dressed as development

The thesis reappears every few paragraphs in new abstractions. This extends "One-Point Dilution"
in [tropes.md](tropes.md): real development adds a mechanism, a case, a number, a
counterexample or a limit. **Fix:** state the thesis once; give each later echo new material or
cut it. Expect to cut 20-30% of an affected draft.

### Abstraction chains

Sentences whose subject and object are both concepts: "the invisible structure around the
model", "each expansion absorbs what sat outside it". Nothing observable happens. **Fix:** ground
at least every second abstraction in a mechanism a practitioner could point to (what is retried,
where state is saved, which file is written). If you cannot supply that detail, the piece is
missing material, and rewording will not fix it.

### Overclaimed conclusions

Absolutes hung on thin evidence: "this proves", "no precedent existed", "the first". One case
shows at most that something is possible. **Fix:** size the claim to the evidence and leave honest
uncertainty standing. When editing someone else's text, calibration changes what they claim, so
flag these edits rather than making them silently.

### Strawman pivots and before/after frames

Two members of the "not X, but Y" family that [structures.md](structures.md) does not list:

- The negation pivot: "He was not trying to advance maritime technology; he wanted to stop paying
  by the hour." It corrects a position nobody holds.
- The before/after frame: "Previously... Now..." stages the old state only to land the new one.
  It reads as release notes even after the parallelism is softened.

All correction-shaped frames share one budget: at most one per piece, and it must correct
something a reader might actually believe. **Fix:** state the present and leave the past out.

### Mechanical concession pivot

A bare turn-announcer opens the obligatory caveat paragraph: "To be sure, challenges remain.
But..." The closing cousin is "remains to be seen". **Fix:** attach each caveat to the specific
claim it qualifies, inside the paragraph that makes the claim, instead of quarantining all
reservations in one signposted paragraph.

### Smaller tells not covered elsewhere

- **Phantom crowds:** "faster than most expected". Who expected it, and when?
- **Self-certifying hedges:** "a well-documented concern" with no document cited.
- **Unanchored references:** "the author argues", "he recalls" with no name, date or source.
  Anchor it (who, where, when) or drop it. Gloss a proper noun at first use.
- **Synonym rotation (elegant variation):** "the tool", "the platform", "the solution" for one
  product. Technical and scientific prose repeats the exact term; rotation makes a careful
  reader wonder whether three things are meant.
- **Scare quotes** on ordinary words. Reserve quotation marks for real quotations and for a coined
  term at its first mention.
- **Vivid concrete triad:** three specific items with an expanding final one ("the sick week, the
  flaky test suite, the dependency upgrade that breaks the build"). Concreteness does not exempt
  it from the one-tricolon-per-piece limit.
- **Scope-widener transitions:** "The implications extend far beyond..."

## Over-correction tells

These are the marks a deslop pass leaves when applied too hard.

### Visible avoidance

Removing a mark mechanically leaves a visible gap. When em dashes are stripped, semicolons and
comma splices take over their job ("did not improve the old system, they replaced it").
Parentheses and colons may vanish from prose that needs them, and every ordinary contrast gets
routed around. The em-dash ban stays absolute (the upstream humanizer allows an occasional dash;
this skill does not, because most people cannot type one easily). **Fix:** replace each dash
according to the clause relationship (SKILL.md rule 9: colon, commas, parentheses, a spaced
hyphen, or a new sentence), not with a semicolon or comma splice. Count semicolons and comma
splices after the pass.

### Rationed humanity

Colloquialism dosed one per paragraph, fragments added For Effect where clichés were removed, an
abstract phrase swapped for a folksy one when a plain one was wanted, anecdotes with no owner
("The feature was scoped at two weeks": whose feature, where?), first person removed from opinion
writing. **Fix:** own the anecdote, risk one judgment of your own, and let warmth cluster where
the material warrants it. When replacing an abstract phrase, the plainest statement beats the
folksiest.

### Uniform, sealed paragraphs

Every paragraph is a sealed module: one move, a hinge opener, a cadenced closer, no digression,
no dud. Across several pieces from one session, the same architecture repeats (four paragraphs,
scene lede, quiet kicker). **Fix:** let one digression in, let one paragraph end flat, and vary
paragraph count and opening move between pieces. When reviewing several pieces from one session,
compare them side by side.

### Telegraph compression

The density rule overshot until the grammar thins: consecutive clauses each opening with a year
(a changelog wearing prose), semicolons stringing narrative events like list items, subjects
dropped until the reader must ask "the first version of what?", whole episodes folded into a
trailing phrase. **Fix:** give the event that matters its own full sentence, subordinate the
minor ones, use relative time ("three years later") instead of a run of years, and give the full
noun at first mention. Expand any packed clause as a test: if expanding it adds clarity, the
compression was cutting meaning.

### Genre without its material

Reportage with no scene, no named person, no quotation; a case study with no case. This is what
the never-invent rule produces when nobody gathered the material. **Fix:** get the material from
the user or the sources, or relabel the piece (essay, explainer, summary). Never fake it.

### Canonical everything

Every fact from the single standard account, exactly the two most-cited references, the default
arc and default title shape, a famous adjacent fact swapped in where the precise one belongs.
**Fix:** add one verifiable, less obvious specific, or narrow the claim to what the standard
account supports.

### Fluent wrongness

The deepest tell: a confident illustration that contradicts the mechanism it illustrates, two
milestones fused into one date and name, a "first" or "only" the record does not support. One
caught instance makes a reader re-read the whole text as synthetic. **Fix:** re-derive every
worked example from the stated mechanism, split fused attributions, and verify or delete every
superlative.

### Inconsistent typography

Mixed style conventions ("26 April 1956" beside "aluminum"; ", TEU" where print uses "(TEU)";
"%" and "percent" in the same section). **Fix:** pick the venue's style guide (journal, house
style, en-GB or en-US) and hold it throughout.

## Census counters

Count mechanically after drafting; impressions miss these.

- Correction frames of every kind (contrast templates, negation pivots, before/after frames).
- Every three-part structure, including concrete triads.
- Turned phrases of every shape against the one-or-two quota.
- Restatements of the central thesis.
- Sentences with a concept as both subject and object.
- Adjacent sentences or clauses sharing one template.
- Absolutes and superlatives, each checked against a source.
- Semicolons and comma splices (inflation after an em-dash ban).
- Distinct terms used for one referent.
- Across several pieces from one session: shared paragraph count, opening and closing moves.
