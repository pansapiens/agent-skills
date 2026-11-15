# deslop
 
Source: [stephenturner/skill-deslop](https://github.com/stephenturner/skill-deslop) by Stephen D. Turner
 
A Claude skill for removing AI writing patterns from prose.

## What it does

When you write, draft, edit, or review text, `deslop` identifies and eliminates predictable AI tells: formulaic sentence structures, filler phrases, false agency, dramatic fragmentation, vague declaratives, and dozens of other patterns that signal machine-generated writing.

The skill works across any prose context. Examples are weighted toward scientific writing and technical blog posts, but the rules apply to any writing where you want a human voice without the AI veneer. For scientific contexts specifically, the skill accounts for conventions like passive voice in methods sections and domain-specific terminology.

## Installation

**Option 1: Download ZIP**

Click the green **Code** button at the top of this repo, then **Download ZIP**. Extract the ZIP and add the folder to your Claude skills directory.

**Option 2: Releases**

Go to the [Releases](https://github.com/stephenturner/skill-deslop/releases) page and download the latest `.skill` file. Add it to your Claude skills in [customize/skills](https://claude.ai/customize/skills) on the web, or double-click it if you have Claude Desktop installed.

**Option 3: Build it yourself**

Build a `.skill` file from the source code, then add it to your Claude skills as described above.

```sh
git clone https://github.com/stephenturner/skill-deslop.git
cd skill-deslop
zip -r deslop.skill SKILL.md references/
```

## How to use it

Install as described above, then use it like you normally talk to Claude. The skill triggers automatically when you:

- Ask Claude to write prose (blog posts, essays, articles, memos, newsletters) making it sound natural instead of AI-generated
- Ask Claude to "deslop", "de-AI" or "make it sound human"
- Ask Claude to check for "slop" or AI patterns

You can also reference the skill directly:

- "Review this draft using the deslop checklist"
- "Score this text on the deslop rubric"
- "Rewrite this paragraph to pass the deslop quick checks"

## Scoring rubric

The skill includes a 1-10 scoring rubric across six dimensions:

| Dimension | Question |
|-----------|----------|
| Directness | Statements or announcements? |
| Rhythm | Varied or metronomic? |
| Trust | Respects reader intelligence? |
| Authenticity | Sounds like a specific human wrote it (low `load_bearing_detector.py` score)? |
| Density | Anything cuttable? |
| Address | Written to a reader who will act, or about the subject from a distance? |

Below 42/60: revise.

## Skill structure

```
deslop/
├── SKILL.md                        # Detector-driven workflow, core rules, quick checks, scoring rubric
├── README.md                       # This file
├── NOTICE.md                       # Sources, licences, and local changes
├── scripts/
│   ├── load_bearing_detector.py    # Zero-dependency CLI port of Louis Abraham's Naive Bayes detector
│   └── model.js                    # 10-component multinomial model from louisabraham/load-bearing
└── references/
    ├── address.md                  # Reader address, volitional/postural verbs, code-comment examples
    ├── discourse.md                # Paragraph/argument-level tells, over-correction tells, counting checklist
    ├── phrases.md                  # Phrases to remove or replace
    ├── structures.md               # Structural patterns to avoid
    ├── tropes.md                   # Full catalog of AI writing tropes
    └── examples.md                 # Before/after transformations
```

## Statistical detection for Claudisms (`load_bearing_detector.py`)

`scripts/load_bearing_detector.py` is a standalone, zero-dependency Python CLI tool adapted from [louisabraham/load-bearing](https://github.com/louisabraham/load-bearing) by Louis Abraham. It scores documents, section headings/titles, paragraphs, and individual sentences against a 10-component KL k-means multinomial model (`scripts/model.js`) fitted on 467,000+ GitHub pull requests, where component `0` captures the post-2025 Claude vocabulary cluster.

```sh
# Run built-in verification test suite
python3 scripts/load_bearing_detector.py --selftest

# Score a single sentence or paragraph and inspect per-word log-likelihood contributions
python3 scripts/load_bearing_detector.py --text "Nothing about how a candidate was scored or selected at one checkpoint carries forward to the next."

# Scan a documentation directory across docs, titles, paragraphs, and sentences
python3 scripts/load_bearing_detector.py path/to/docs

# Scan only section titles/headings or only sentences
python3 scripts/load_bearing_detector.py --mode titles --threshold 0.4 path/to/docs
python3 scripts/load_bearing_detector.py --mode sentences --threshold 0.7 path/to/docs
```

## Acknowledgments

This skill combines and synthesizes material from open-source projects and community forks:

- **skill-deslop** from [github.com/stephenturner/skill-deslop](https://github.com/stephenturner/skill-deslop) by [Stephen D. Turner](https://github.com/stephenturner), the original version of this skill, and community fork additions from [jchook/skill-deslop](https://github.com/jchook/skill-deslop) (reader address and volitional verbs on inanimate subjects), [zencohen/skill-deslop](https://github.com/zencohen/skill-deslop) (behavior-class framing, sentence-start affirmations, pre-write active check), [alexchunlin/skill-deslop](https://github.com/alexchunlin/skill-deslop) (engineering logs and PRs), and [isobelscott/skill-deslop](https://github.com/isobelscott/skill-deslop) (targeted em-dash replacements).
- **load-bearing** from [github.com/louisabraham/load-bearing](https://github.com/louisabraham/load-bearing) by [Louis Abraham](https://louisabraham.github.io/) (MIT License). `scripts/load_bearing_detector.py` and `scripts/model.js` are adapted from its Multinomial Naive Bayes detector (`detector.html` and `analyze.py`).
- **AI writing tropes catalog** from [tropes.fyi](https://tropes.fyi/) by [Ossama Hassanein](https://ossama.is). The `references/tropes.md` file is adapted from this source, and trope patterns are integrated throughout the other reference files.
- **stop-slop** from [github.com/hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) by [Hardik Pandya](https://hvpandya.com). The phrase lists, structural patterns, before/after examples, scoring rubric, and quick checks draw from this project.

## License

MIT
