# Phrases to Remove or Replace

## Throat-Clearing Openers

Remove these. State the content directly.

- "Here's the thing:"
- "Here's what [X]"
- "Here's this [X]"
- "Here's that [X]"
- "Here's why [X]"
- "Here's the kicker"
- "Here's where it gets interesting"
- "Here's what most people miss"
- "Here's the deal"
- "The uncomfortable truth is"
- "It turns out"
- "The real [X] is"
- "Let me be clear"
- "The truth is,"
- "I'll say it again:"
- "I'm going to be honest"
- "Can we talk about"
- "Here's what I find interesting"
- "Here's the problem though"

Any "here's what/this/that" construction is throat-clearing before the point. Cut it and state the point.

## Sentence-Start Affirmations and Acknowledgments

Driven by RLHF-trained agreeableness and by the model defaulting to a low-risk acknowledgment under uncertainty. If a phrase opens a sentence with validation, agreement, or hedged self-attribution without adding content, cut it; the next sentence does the work.

- "Great question." / "That's a great question."
- "That's a really good point." / "Excellent point." / "Interesting point." / "Fair point."
- "Absolutely." / "Certainly." / "Of course." / "Sure thing."
- "Got it." / "Makes sense." / "Right."
- "Yes - and..."
- "Honestly," / "To be honest,"
- "I think," / "I would say," / "In my opinion,"

## Emphasis Crutches

These add no meaning. Delete them.

- "Full stop." / "Period."
- "Let that sink in."
- "This matters because"
- "Make no mistake"
- "Here's why that matters"

## Pedagogical Hand-Holding

Phrases that assume the reader needs a teacher. Cut them.

- "Let's break this down"
- "Let's unpack this"
- "Let's explore"
- "Let's dive in"
- "Let's delve into"
- "Think of it as..."
- "Think of it like..."
- "Imagine a world where..."

## Business Jargon

Replace with plain language.

| Avoid | Use instead |
|-------|-------------|
| Navigate (challenges) | Handle, address |
| Unpack (analysis) | Explain, examine |
| Lean into | Accept, embrace |
| Landscape (context) | Situation, field |
| Game-changer | Significant, important |
| Double down | Commit, increase |
| Deep dive | Analysis, examination |
| Take a step back | Reconsider |
| Moving forward | Next, from now |
| Circle back | Return to, revisit |
| On the same page | Aligned, agreed |
| Leverage (verb) | Use |
| Utilize | Use |
| Robust | Strong, solid |
| Streamline | Simplify |
| Harness | Use, apply |
| Paradigm | Model, approach |
| Synergy | Cooperation, combined effect |
| Ecosystem | System, field, community |
| Framework | Structure, approach |

## AI Vocabulary Tells

Words that became dramatically overrepresented in AI-generated text. Avoid or replace.

- "delve" (use: examine, look at, explore)
- "tapestry" (use: mix, combination, range)
- "certainly" (usually deletable)
- "landscape" when meaning "field" or "situation"
- "nuanced" (use: complex, subtle, specific)

## The "Serves As" Dodge

AI replaces simple "is" or "are" with pompous alternatives. Use the simple verb.

| Avoid | Use instead |
|-------|-------------|
| serves as | is |
| stands as | is |
| marks (when meaning "is") | is |
| represents (when meaning "is") | is |

## Adverbs

Kill all adverbs. No -ly words. No softeners, no intensifiers, no hedges.

Specific offenders:

- "really"
- "just"
- "literally"
- "genuinely"
- "honestly"
- "simply"
- "actually"
- "deeply"
- "truly"
- "fundamentally"
- "inherently"
- "inevitably"
- "interestingly"
- "importantly"
- "crucially"
- "quietly" (AI's favorite for conveying subtle importance)
- "remarkably"
- "arguably"

Also cut these filler phrases:

- "At its core"
- "In today's [X]"
- "It's worth noting"
- "It bears mentioning"
- "Notably"
- "At the end of the day"
- "When it comes to"
- "In a world where"
- "The reality is"

## Meta-Commentary

Remove self-referential asides. The text should move, not announce its own structure.

- "Hint:"
- "Plot twist:" / "Spoiler:"
- "You already know this, but"
- "But that's another post"
- "X is a feature, not a bug"
- "Dressed up as"
- "The rest of this essay explains..."
- "Let me walk you through..."
- "In this section, we'll..."
- "As we'll see..."
- "I want to explore..."
- "In conclusion" / "To sum up" / "In summary"
- "As we've seen in this section..."
- "And so we return to where we began."

## Performative Emphasis

False intimacy or manufactured sincerity:

- "creeps in"
- "I promise"
- "They exist, I promise"

## False Vulnerability

Simulated self-awareness that reads as performative:

- "And yes, I'm openly..."
- "And yes, since we're being honest..."
- "This is not a rant; it's a diagnosis"

## Telling Instead of Showing

Announcing difficulty or significance rather than demonstrating it:

- "This is genuinely hard"
- "This is what leadership actually looks like"
- "This is what X actually looks like"
- "actually matters"

## "The Truth Is Simple"

Asserting clarity instead of demonstrating it:

- "The reality is simpler"
- "History is unambiguous on this point"
- "History is clear, the metrics are clear, the examples are clear"
- "but none of them is the real story. The real story is..."

## Vague Declaratives

Sentences that announce importance without naming the specific thing. Kill these or replace with the specific thing.

- "The reasons are structural"
- "The implications are significant"
- "This is the deepest problem"
- "The stakes are high"
- "The consequences are real"

## Vague Attributions

Attributing claims to unnamed authorities. If you cannot name the source, you do not have one.

- "Experts argue that..."
- "Industry reports suggest that..."
- "Observers have cited..."
- "Several publications have noted..."

## Grandiose Stakes Inflation

Inflating every argument to world-historical significance. Scale claims to match the actual stakes.

- "This will fundamentally reshape how we think about everything."
- "will define the next era of computing"
- "something entirely new"

## Claude-Characteristic ("Load-Bearing") Vocabulary

Identified by statistical analysis of post-2025 pull requests in [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing) (5x to 18x lift in the Claude vocabulary cluster). Even when individual words are ordinary English, stacking them produces an unmistakable "Claude voice":

- **Engineering & architectural cliches**: `load-bearing`, `vacuous`, `machinery`, `plumbing`, `ceiling`, `floor`, `surface` ("review surface", "surface area"), `blast radius`, `footgun`, `guardrail`, `escape hatch`, `first-class`, `single source of truth`, `out of the box`
- **Anthropomorphic refusal, judgment, and transfer verbs on code/data**:
  - `refuses` / `refused` / `declines` ("the parser refuses inputs that..." -> "the parser rejects...")
  - `disagrees` / `agrees` ("when the two flags disagree..." -> "when the two flags conflict...")
  - `decides` / `judged` ("how a candidate was judged" -> "how a candidate was scored")
  - `asks` / `asked` / `answers` / `tells` / `told` / `knows` / `cares` ("the sampler neither knows nor cares" -> "the sampler does not depend on")
  - `hands` / `handing` ("hands the tensor to the trunk" -> "passes the tensor to the trunk")
  - `carries` / `carrying` / `carries forward` ("carries forward to the next step" -> "persists to the next step")
  - `survives` / `survivors` / `surviving` ("only the strongest survive" -> "only the top-scoring candidates are retained")
  - `invents` ("invents a structure from nothing" -> "generates a structure from noise")
  - `catches` / `caught` / `pins` / `pinned` / `restates`
- **Spatial & postural filler verbs for files, configs, and outputs**:
  - `sits` / `sitting` ("`conditions.py` sits outside any subpackage" -> "`conditions.py` is at the package root")
  - `lands` / `landed` ("results land in `out_dir`" -> "results are written to `out_dir`")
  - `lives` ("the config lives in `configs/`" -> "the config is in `configs/`")
  - `holds` / `holding` ("this directory holds..." -> "this directory contains...")
  - `rests` / `stands` / `beside` / `apart`
- **High-lift qualifiers, pronouns, and adverbs**:
  - `merely`, `deliberately`, `silently`, `empirically`, `mechanically`, `precisely`, `exact`, `exactly`, `bare` ("a bare `AtomArray`" -> "a single-model `AtomArray`"), `whole`, `alone`, `neither`, `whichever`, `whose`, `rather`, `afterwards`, `partway`

## Mannered Prose & Non-Monetary Cost/Payment/Shipping Metaphors

Mannered prose substitutes metaphor and flourish for direct statement. When a literal phrase is available, use it:

| Avoid | Use instead |
|-------|-------------|
| "a dial worth turning" / "a knob to turn" | a parameter worth varying / a configurable parameter |
| "this point earns its keep" | this point matters |
| "what this buys us" / "what X buys you" | the advantage of X / the benefit of X |
| "the price we pay" / "footing the bill" | the trade-off / the disadvantage / the overhead |
| "it pays off where..." | this reduces overhead when... / this is effective when... |
| "what the jobs cost" (when referring to compute/time) | job walltime summary / compute resource usage |
| "ships" / "ships with" / "every metric that ships" | provides / delivers / includes / built-in metrics |
