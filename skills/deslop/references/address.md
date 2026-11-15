# Address, Agency, and "Load-Bearing" Claudisms

Adapted from [jchook/skill-deslop](https://github.com/jchook/skill-deslop) and combined with findings from [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing).

Text can be free of em dashes, tricolons, and "delve" and still read unmistakably like Claude wrote it. Three patterns account for most of that signal in technical prose, documentation, PR descriptions, and code comments:

1. **Writing *about* the subject matter from a distance** (noun-phrase captions and narrating the machine's inner life) instead of addressing the reader.
2. **Giving inanimate subjects volitional, social, or postural verbs** (`refuses`, `declines`, `arrives`, `carries forward`, `hands`, `holds`, `sits`, `lands`, `knows`, `cares`, `survives`, `invents`).
3. **Conversational `What`/`Where`/`Why`/`How` headings and sweeping negation-carry clauses** (`"Where things land"`, `"Nothing about how X was scored carries forward to the next"`).

## Contents

- [Rule 11: Address the reader, not the subject matter](#rule-11-address-the-reader-not-the-subject-matter)
- [Rule 12: Inanimate subjects do not take volitional or postural verbs](#rule-12-inanimate-subjects-do-not-take-volitional-or-postural-verbs)
- [The volitional and postural verb list](#the-volitional-and-postural-verb-list)
- [Worked example: technical documentation](#worked-example-technical-documentation)
- [Worked example: a doc comment](#worked-example-a-doc-comment)
- [Worked example: a warning string](#worked-example-a-warning-string)
- [What this is not](#what-this-is-not)

## Rule 11: Address the reader, not the subject matter

**Every explanatory sentence should be an imperative to the reader, a "we"/"you" sentence, or a direct mechanical statement.**

Write to the person who will act on the text: the user configuring a run, the next implementor, the reviewer, or the operator. Do not write *about* the subject matter as a museum exhibit observed from a distance.

### Tell 1: A noun-phrase caption where a sentence belongs

Machine-generated explanation gravitates to captions. A caption names a thing and stops. A sentence tells the reader what to do or states how the system works.

| Caption (Observed from a distance) | Addressed to the reader |
| --- | --- |
| `What the store observed about a row, so an out-of-order response can't undo a newer one.` | `Sequence row writes so an out-of-order response can't clobber newer data.` |
| `Every type the last response delivered, both matches and included resources.` | `Keep track of all types in the latest response (including matches and included resources).` |
| `The distinction a clinical surface cannot lose.` | `A clinical surface must never confuse these two.` |
| `The one search that finds a resource by its stable key.` | `Build the single search that finds a resource by its stable key.` |
| `What a rejected write does is the subject here.` | `These tests cover rejected writes.` |

### Tell 2: Narrating the machine's inner life

Describing a parser, sampler, store, or file format as though it has beliefs, suspicions, or intentions.

| Machine has a mind | Plain |
| --- | --- |
| `What the store observed about a row` | `The last value we applied for this row` |
| `Focus only suspects staleness` | `On focus we only guess that data might be stale` |
| `It answers "could a change to this type affect this subset?"` | `Use it to check whether a change to a type affects this subset` |
| `The sampler neither knows nor cares which oracle scored the branch` | `The sampler does not depend on which oracle scored the branch` |
| `an answer this store will not pretend to have` | `a result we cannot compute from local state` |

### Tell 3: Essayistic framing of the reason

Keep the technical reason; drop the theatrical framing around it.

| Framed | Direct |
| --- | --- |
| `That partitioning is the load mechanism, not a detail: one search populates three collections.` | `Splitting the bundle is how we load data: one search fills three collections.` |
| ``after: "outage"` is the difference between a guess and a recovery.` | `Pass `after: "outage"` to skip the staleness check.` |
| `Not a missing feature - a refusal.` | `Reject the input rather than falling back to a bare POST.` |
| `The backbone has moved, and that is what separates this step from inverse folding.` | `Unlike inverse folding, partial diffusion updates the backbone coordinates as well as the sequence.` |

## Rule 12: Inanimate subjects do not take volitional or postural verbs

**Things do not act on their own initiative. Restate the condition or mechanical action instead.**

When you catch personification in technical writing, do **not** invent a human actor just to satisfy "use active voice with human subjects" ("when a developer passes a mutation that..."). Usually there is no person in the clause. State the condition or mechanical operation directly.

| Personified / Postural | Plain |
| --- | --- |
| `for mutations that arrive without one` | `in case the mutation did not define it` |
| `a row carrying an xid is keyed by that xid` | `if a row has an xid, we key it by that xid` |
| `paths that arrive holding a plain Resource` | `internal callers only have a plain Resource` |
| `leaves the schedule deaf to every Encounter change` | `would make the schedule miss every Encounter change` |
| `a tombstone that refuses the row when it comes back` | `the leftover tombstone rejects the row the next time we fetch it` |
| `rows arrive with the parent` | `the parent's reverse include already fetched those rows` |
| `the query reaches past search` | `the query bypasses search` |
| `nothing about how a candidate was scored carries forward to the next` | `candidate scores do not persist between checkpoints` |
| `conditions.py sits outside any subpackage because it holds shared vocabulary` | `conditions.py is placed at the package root because it defines shared constants` |
| `results land in per_example_metrics.csv` | `results are written to per_example_metrics.csv` |

### Cut the clever aside

Decoration that reads as insight but adds no information:

- `including the 3 that never fetched`
- `a dangling reference available to resolve, rather than a booking that vanished`
- `so nothing gets committed by accident`

State what happens and stop.

## The volitional and postural verb list

Check for these when they have an inanimate subject (`the parser`, `the config`, `a row`, `the checkpoint`, `the directory`).

- **Perception and knowledge:** `observes`, `knows`, `learns`, `sees`, `suspects`, `notices`, `realizes`, `understands`, `is aware`, `is blind to`, `is deaf to`, `cares`
- **Speech and reasoning:** `answers`, `says`, `argues`, `claims`, `admits`, `asserts`, `explains`, `reports` (when meaning "concludes"), `decides`, `judges`, `judged`, `pretends`, `restates`, `declares`
- **Volition and desire:** `wants`, `prefers`, `tries`, `attempts`, `intends`, `chooses`, `refuses`, `declines`, `insists`, `agrees`, `disagrees`, `is willing`, `forgives`, `invents`
- **Travel, posture, and possession:** `arrives`, `comes back`, `shows up`, `lands`, `sits`, `lives`, `rests`, `stands`, `travels`, `carries`, `carries forward`, `holds`, `keeps`, `owns`, `brings`, `takes`, `hands`, `handing`, `rides along`, `reaches past`, `walks`, `survives`, `survivors`
- **Social:** `asks`, `tells`, `demands`, `expects`, `waits on`, `trusts`, `blames`, `cooperates`, `negotiates`
- **Dramatic framing:** `is the one thing that`, `is the whole story`, `is the point`, `is the reason`, `is what makes it`, `is what separates`

### Mechanical verbs that are fine

`returns`, `contains`, `throws`, `raises`, `fails`, `resolves`, `rejects`, `matches`, `differs`, `points at`, `references`, `includes`, `writes`, `reads`, `parses`, `computes`, `evaluates`, `persists`, `expires`, `overflows`. These describe mechanical operations, not intent.

## Worked example: technical documentation

Before (`p0 = 0.998` on `load_bearing_detector.py`):

```markdown
### Checkpoints: where the trajectory branches

Nothing about how a candidate was scored or selected at one checkpoint carries forward to the
next: the survivors are simply the new beam, and the next checkpoint judges their children from
scratch. Results land in `out_dir`, which holds one subdirectory per surviving beam.
```

After (`p0 = 0.092` on `load_bearing_detector.py`):

```markdown
### Checkpoints

Candidate scores do not persist between checkpoints. Retained candidates form the active beam for
the next interval, and the next checkpoint evaluates their branches independently. Results are
written to `out_dir`, with one subdirectory per retained beam.
```

## Worked example: a doc comment

Before:

```ts
/**
 * What the store observed about a row, so an out-of-order response cannot undo a
 * newer one.
 *
 * `appliedGeneration` is a causal counter over local requests, needed because
 * Medplum version ids are opaque uuids that cannot be ordered. `lastUpdated` is the
 * server's own instant and is comparable, so it settles the case where two
 * independent searches deliver different snapshots of one resource.
 *
 * Held in each collection's own row metadata rather than in a map here, because the
 * library deletes a row's metadata with the row. A map would need clearing at every
 * path that drops a row, and missing one leaves a tombstone that refuses the row when
 * it comes back.
 */
```

After:

```ts
/**
 * Sequence row writes so an out-of-order response can't clobber newer data.
 *
 * `appliedGeneration` counts local requests. We need it because Medplum version ids are
 * opaque uuids we can't order. `lastUpdated` is the server timestamp, which we can
 * compare, so it breaks ties when two independent searches return different snapshots of
 * one resource.
 *
 * Store this in each collection's row metadata rather than a map on the store, since the
 * library drops row metadata along with the row. A map would need clearing on every
 * delete path, and if we miss one, the leftover tombstone rejects the row the next time
 * we fetch it.
 */
```

## Worked example: a warning string

Before:

```text
[IHR] Provenance demanded nothing: every compared path is a local join key
(_db.joins.targetEncounter), so no FHIR request was made.
Expected for a reverse-join arm: those rows arrive with the parent, through its
reverse include.
```

After:

```text
[IHR] No FHIR request was made for Provenance, because every compared path is a
local join key (_db.joins.targetEncounter).
That is expected for a reverse-join arm, where the parent's reverse include already
fetched these rows.
```

## What this is not

- **Not a call for cryptic terseness.** `Seq. row writes, OOO-safe` is worse than the slop it replaces. Plain, complete sentences addressed to a person are the goal.
- **Not a rule for scientific manuscripts.** Rule 11 targets documentation, code comments and technical notes. Formal scientific prose defaults to a consistent passive voice (SKILL.md rule 4).
- **Not a ban on legitimate domain terms.** In `load_bearing_detector.py`, technical nouns like `scaffold`, `binder`, `checkpoint`, or `latent` may have positive log-likelihood weights simply because they appear in ML/bio pull requests. Keep domain terminology intact and rewrite the personified verbs, captions, and rhetorical framing around them.
