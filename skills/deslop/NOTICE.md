# Attribution

Based on [stephenturner/skill-deslop](https://github.com/stephenturner/skill-deslop) by
Stephen D. Turner, retrieved 2026-10-20. MIT licensed; the licence text is `LICENSE` in this
directory. Upstream combines two sources, and both should be credited with it:

- The AI writing tropes catalog at [tropes.fyi](https://tropes.fyi) by Ossama Hassanein.
  `references/tropes.md` is adapted from that catalog.
- [stop-slop](https://github.com/hardikpandya/stop-slop) by Hardik Pandya. The phrase lists,
  structural patterns, before/after examples, scoring rubric and quick checks draw from that
  project.

Later additions:

- Rules from community forks of `skill-deslop`:
  [jchook/skill-deslop](https://github.com/jchook/skill-deslop) (reader address and
  volitional verbs on inanimate subjects; `references/address.md` is adapted from it),
  [zencohen/skill-deslop](https://github.com/zencohen/skill-deslop) (behaviour-class framing,
  sentence-start affirmations, pre-write active check),
  [alexchunlin/skill-deslop](https://github.com/alexchunlin/skill-deslop) (engineering logs,
  PRs and bench notes), and
  [isobelscott/skill-deslop](https://github.com/isobelscott/skill-deslop) (targeted em-dash
  replacements).
- `scripts/load_bearing_detector.py` and `scripts/model.js`, ported from
  [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing) by Louis Abraham.
- `references/discourse.md`, core rules 13-14, the Counting Pass section and the later Quick
  Checks, adapted from the English-language material of the `humanizer` skill in
  [Prism-Shadow/penguin-harness](https://github.com/Prism-Shadow/penguin-harness/tree/main/plugins/humanizer/skills/humanizer)
  (Apache-2.0), retrieved 2026-11-13. Non-English cue files were not used.

Local decisions that override the sources:

- Em dashes (and `--`) are banned outright. Upstream allowed 2-3 per piece; humanizer allows
  an occasional one.
- One tricolon per piece is allowed; upstream wording varied between none and one.
- Scientific prose defaults to a consistent passive voice (rule 4). Upstream preferred
  active "we"; examples 4, 8 and 11 in `references/examples.md` were rewritten to match.

The same skill is kept in two places, which should stay identical:
`agent-skills/skills/deslop` (installed via `~/.agents/skills` and `~/.claude/skills`
symlinks) and `agentic-protein-design-pipeline/skills/deslop`.
