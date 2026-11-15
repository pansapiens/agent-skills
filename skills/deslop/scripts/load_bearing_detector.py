#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Multinomial Naive Bayes detector for Claude-characteristic ("load-bearing") vocabulary.

Adapted from Louis Abraham's `load-bearing` project:
  https://github.com/louisabraham/load-bearing
  Copyright (c) 2026 Louis Abraham (MIT License)

This script evaluates text against the 10-component KL k-means multinomial model
(`model.js`) fitted on 467,000+ GitHub pull request descriptions, where component 0
is the vocabulary cluster strongly associated with Claude.

It supports scoring:
  - Arbitrary text strings (`--text "..."` or stdin `-`)
  - Individual files or entire directories (`.md`, `.rst`, `.ipynb`, `.qmd`, `.Rmd`, `.tex`, `.txt`)
  - Multiple granularities: `titles`, `sentences`, `paragraphs`, `docs`, or `all`
"""

from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple
import logging
import sys
import os
import argparse
from collections import Counter
import gzip
import io
import json
import math
from pathlib import Path
import re

logger = logging.getLogger(__name__)

URL_RE = re.compile(r"https?://[^\s<>\"'`)\]}]+")
TAG_RE = re.compile(r"<[a-z/!][^<>]*>")
EM_DASH = "\u2014"
WORD_RE = re.compile(r"[a-z0-9_/-]*[a-z][a-z0-9_/-]*")
SNYK_ID_RE = re.compile(r"^snyk-.+-\d{4,}$")

SUPPORTED_EXTENSIONS = (".md", ".rst", ".ipynb", ".qmd", ".rmd", ".tex", ".txt")


def domain_token(url: str) -> str:
    """Collapse a URL to a single token naming its registrable domain."""
    host = url.split("//", 1)[-1].split("/", 1)[0].split("@")[-1].split(":")[0]
    labels = [x for x in host.split(".") if x and x != "www"]
    name = labels[-2] if len(labels) >= 2 else (labels[0] if labels else "link")
    return f"[{name}-url]"


def tokens(body: str) -> List[str]:
    """Tokenize text identically to `analyze.tokens` and `detector.html` in `load-bearing`."""
    body = body.lower()
    out = [domain_token(m.group(0)) for m in URL_RE.finditer(body)]
    out += [EM_DASH] * body.count(EM_DASH)
    rest = TAG_RE.sub(" ", URL_RE.sub(" ", body))
    for w in WORD_RE.findall(rest):
        w = w.strip("_/").rstrip("-")
        if w:
            out.append("[snyk-id]" if w.startswith("snyk-") and SNYK_ID_RE.match(w) else w)
    return out


def un_front_coded(text: str) -> List[str]:
    """Decode front-coded vocabulary string from `model.js`."""
    out: List[str] = []
    prev = ""
    i = 0
    n = len(text)
    while i < n:
        j = i + 1
        while j < n and not ("A" <= text[j] <= "Z"):
            j += 1
        prev = prev[: ord(text[i]) - 65] + text[i + 1 : j]
        out.append(prev)
        i = j
    return out


def decode_weights(
    text: str,
    k: int,
    vocab_size: int,
    grid: Sequence[float],
    esc: int,
    alphabet: str,
) -> List[float]:
    """Decode quantized log-weight offsets `E` (word-major flat array of length `vocab_size * k`)."""
    lo, split, hi = grid[0], grid[1], grid[2]
    n_alphabet = len(alphabet)
    n_esc = n_alphabet - 1 - esc
    code = {ch: idx for idx, ch in enumerate(alphabet)}
    step_lo = (split - lo) / (esc - 1)
    step_hi = (hi - split) / (n_esc * n_alphabet - 1)
    total = vocab_size * k
    out = [0.0] * total
    i = 0
    for n in range(total):
        a = code[text[i]]
        i += 1
        if a > esc:
            out[n] = split + ((a - 1 - esc) * n_alphabet + code[text[i]]) * step_hi
            i += 1
        elif a:
            out[n] = lo + (a - 1) * step_lo
    if i != len(text):
        raise ValueError("Weight string length mismatch in model file.")
    return out


class LoadBearingDetector:
    """Multinomial Naive Bayes classifier using the `load-bearing` 10-component model."""

    def __init__(self, model_path: Optional[Path] = None) -> None:
        if model_path is None:
            model_path = Path(__file__).resolve().parent / "model.js"
        raw = self._read_raw(model_path)
        prefix = "window.MODEL = "
        if raw.startswith(prefix):
            raw = raw[len(prefix) : raw.rstrip().rfind(";")]
        data = json.loads(raw)

        self.k: int = int(data["k"])
        self.words: int = int(data["words"])
        self.generated: str = str(data.get("generated", "unknown"))
        self.floor: List[float] = [float(v) for v in data["floor"]]
        self.vocab: List[str] = un_front_coded(data["vocab"])
        if len(self.vocab) != self.words:
            raise ValueError(f"Decoded {len(self.vocab)} words, expected {self.words}")
        self.index: Dict[str, int] = {w: j for j, w in enumerate(self.vocab)}
        self.weights: List[float] = decode_weights(
            data["weights"],
            self.k,
            self.words,
            data["grid"],
            int(data["escape"]),
            str(data["alphabet"]),
        )

    @staticmethod
    def _read_raw(path: Path) -> str:
        if path.suffix == ".gz":
            with gzip.open(path, "rt", encoding="utf-8") as f:
                return f.read()
        return path.read_text(encoding="utf-8")

    def classify(self, text: str) -> Dict[str, Any]:
        """Classify `text` and return posterior probabilities, log-likelihood ratio, and word evidence."""
        all_tokens = tokens(text)
        counts: Counter[int] = Counter()
        known = 0
        for w in all_tokens:
            j = self.index.get(w)
            if j is not None:
                known += 1
                counts[j] += 1

        k = self.k
        score = [known * self.floor[c] for c in range(k)]
        weights = self.weights
        for j, x in counts.items():
            off = j * k
            for c in range(k):
                score[c] += x * weights[off + c]

        top = max(score)
        exp_scores = [math.exp(s - top) for s in score]
        total_exp = sum(exp_scores)
        p = [v / total_exp for v in exp_scores]

        other = 1
        for c in range(2, k):
            if score[c] > score[other]:
                other = c

        llr = score[0] - score[other] if known > 0 else 0.0

        word_evidence: List[Tuple[str, float, int]] = []
        floor_diff = self.floor[0] - self.floor[other]
        for j, x in counts.items():
            off = j * k
            d = x * (floor_diff + weights[off] - weights[off + other])
            word_evidence.append((self.vocab[j], d, x))

        word_evidence.sort(key=lambda item: item[1], reverse=True)
        return {
            "p0": p[0] if known > 0 else 0.1,
            "p": p,
            "llr": llr,
            "known": known,
            "total_tokens": len(all_tokens),
            "other_component": other,
            "evidence": word_evidence,
        }


def strip_code_blocks(text: str) -> str:
    """Remove fenced code blocks and inline code literals so prose is scored rather than identifiers."""
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"~~~.*?~~~", " ", text, flags=re.S)
    text = re.sub(r"\.\.\s+code-block::.*?(?=\n\S|\Z)", " ", text, flags=re.S)
    text = re.sub(r"`[^`\n]+`", " ", text)
    return text


def extract_items_from_file(path: Path) -> Dict[str, List[Tuple[str, str]]]:
    """Extract whole document, titles/headings, paragraphs, and sentences from a file."""
    titles: List[Tuple[str, str]] = []
    paragraphs: List[Tuple[str, str]] = []
    sentences: List[Tuple[str, str]] = []
    docs: List[Tuple[str, str]] = []

    raw = path.read_text(encoding="utf-8", errors="replace")

    if path.suffix.lower() == ".ipynb":
        try:
            nb = json.loads(raw)
        except json.JSONDecodeError:
            return {"docs": [], "titles": [], "paragraphs": [], "sentences": []}
        md_chunks: List[Tuple[str, str]] = []
        for idx, cell in enumerate(nb.get("cells", [])):
            if cell.get("cell_type") == "markdown":
                src = "".join(cell.get("source", []))
                md_chunks.append((f"cell{idx}", src))
        full_prose = "\n\n".join(strip_code_blocks(src) for _, src in md_chunks)
        if full_prose.strip():
            docs.append(("doc", full_prose))
        for loc, src in md_chunks:
            in_fence = False
            for line in src.splitlines():
                stripped = line.strip()
                if stripped.startswith(("```", "~~~")):
                    in_fence = not in_fence
                    continue
                if not in_fence:
                    m = re.match(r"^(#{1,6})\s+(.+)$", stripped)
                    if m:
                        titles.append((loc, m.group(2).strip()))
            cleaned = strip_code_blocks(src)
            for para in re.split(r"\n\s*\n", cleaned):
                p = para.strip()
                if not p or p.startswith("#"):
                    continue
                paragraphs.append((loc, p))
                for sent in re.split(r"(?<=[.!?])\s+", re.sub(r"\s+", " ", p)):
                    if len(sent.split()) >= 5:
                        sentences.append((loc, sent))
        return {"docs": docs, "titles": titles, "paragraphs": paragraphs, "sentences": sentences}

    lines = raw.splitlines()
    if path.suffix.lower() == ".rst":
        for i in range(len(lines) - 1):
            line = lines[i].strip()
            under = lines[i + 1].strip()
            if (
                line
                and len(under) >= len(line)
                and len(set(under)) == 1
                and under[0] in "=-~^\"'+*#"
                and not line.startswith("..")
            ):
                titles.append((f"L{i + 1}", line))
    else:
        in_fence = False
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith(("```", "~~~")):
                in_fence = not in_fence
                continue
            if not in_fence:
                m = re.match(r"^(#{1,6})\s+(.+)$", stripped)
                if m:
                    titles.append((f"L{i}", m.group(2).strip()))

    cleaned = strip_code_blocks(raw)
    if cleaned.strip():
        docs.append(("doc", cleaned))

    for para in re.split(r"\n\s*\n", cleaned):
        p = para.strip()
        if not p or p.startswith("#") or p.startswith(".."):
            continue
        first_line = p.splitlines()[0].strip()
        loc_line = 1
        for idx, orig_line in enumerate(lines, 1):
            if first_line[:30] and first_line[:30] in orig_line:
                loc_line = idx
                break
        loc = f"L{loc_line}"
        paragraphs.append((loc, p))
        for sent in re.split(r"(?<=[.!?])\s+", re.sub(r"\s+", " ", p)):
            if len(sent.split()) >= 5:
                sentences.append((loc, sent))

    return {"docs": docs, "titles": titles, "paragraphs": paragraphs, "sentences": sentences}


def iter_target_files(paths: Iterable[Path]) -> List[Path]:
    """Collect supported prose/documentation files from file or directory paths."""
    found: List[Path] = []
    for p in paths:
        if p.is_file():
            found.append(p)
        elif p.is_dir():
            for root, dirs, files in os.walk(p):
                dirs[:] = [
                    d
                    for d in sorted(dirs)
                    if not d.startswith(".") and d not in ("_build", "node_modules", "__pycache__", ".venv", "venv")
                ]
                for fname in sorted(files):
                    fpath = Path(root) / fname
                    if fpath.suffix.lower() in SUPPORTED_EXTENSIONS:
                        found.append(fpath)
    return found


def run_selftest(detector: LoadBearingDetector) -> bool:
    """Verify exact agreement with `tests/test_detector.py` from `louisabraham/load-bearing`."""
    arriving = (
        "The failing assertion was not the bug \u2014 it was load-bearing. The cache handed back a stale "
        "row before the write had landed, so the test passed for a reason nobody had written down."
    )
    ordinary = "bump grpc to 1.62 and regen the protos. fixes #4412, tested locally, ci is green."

    r_empty = detector.classify("")
    assert all(abs(p - 0.1) < 1e-12 for p in r_empty["p"]), "Uniform prior check failed"

    r_arr = detector.classify(arriving)
    r_ord = detector.classify(ordinary)
    assert r_arr["p0"] > 0.99 and r_arr["llr"] > 10.0, f"Expected Yes on ARRIVING, got {r_arr['p0']}"
    assert r_ord["p0"] < 0.15 and r_ord["llr"] < -1.5, f"Expected No on ORDINARY, got {r_ord['p0']}"

    r_unk = detector.classify(arriving + " zzqqxxwv frobnicatoriumly")
    assert abs(r_unk["p0"] - r_arr["p0"]) < 1e-12, "Out-of-vocabulary invariance check failed"

    for r in (r_arr, r_ord):
        summed = sum(d for _, d, _ in r["evidence"])
        assert abs(r["llr"] - summed) < 1e-6, "Evidence sum check failed"

    logger.info("Selftest passed (model generated %s, %d words, K=%d).", detector.generated, detector.words, detector.k)
    return True


def format_single_result(text: str, res: Dict[str, Any], top_words: int = 12) -> str:
    """Format a human-readable report for a single text snippet."""
    buf = io.StringIO()
    if res["known"] == 0:
        buf.write("Verdict: None (0 known words in model vocabulary)\n")
        return buf.getvalue()
    verdict = "YES (Claude cluster 0)" if res["p0"] > 0.5 else "NO"
    buf.write(
        f"Verdict: {verdict} | p0={res['p0']:.3f} ({res['p0'] * 100:.1f}%) | "
        f"llr={res['llr']:+.2f} nats (vs component {res['other_component']}) | "
        f"{res['known']}/{res['total_tokens']} words in vocab\n"
    )
    pos = [(w, d, x) for w, d, x in res["evidence"] if d > 0][:top_words]
    neg = sorted([(w, d, x) for w, d, x in res["evidence"] if d < 0], key=lambda item: item[1])[:top_words]
    if pos:
        pos_str = ", ".join(f"{w} ({d:+.2f})" if x == 1 else f"{w}x{x} ({d:+.2f})" for w, d, x in pos)
        buf.write(f"  Toward Claude cluster (+): {pos_str}\n")
    if neg:
        neg_str = ", ".join(f"{w} ({d:+.2f})" if x == 1 else f"{w}x{x} ({d:+.2f})" for w, d, x in neg)
        buf.write(f"  Against Claude cluster (-): {neg_str}\n")
    return buf.getvalue()


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Score text or documentation files for Claude-characteristic ('load-bearing') vocabulary "
            "using Louis Abraham's Multinomial Naive Bayes model (https://github.com/louisabraham/load-bearing)."
        )
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Files or directories to scan, or '-' to read raw text from stdin.",
    )
    parser.add_argument(
        "-t",
        "--text",
        help="Score a single text string directly.",
    )
    parser.add_argument(
        "-m",
        "--mode",
        choices=("all", "titles", "sentences", "paragraphs", "docs", "text"),
        default="all",
        help="Granularity to report when scanning files (default: all).",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.5,
        help="Minimum posterior probability p0 to flag an item (default: 0.5).",
    )
    parser.add_argument(
        "--min-llr",
        type=float,
        default=0.5,
        help="Minimum log-likelihood ratio (in nats) to flag an item (default: 0.5).",
    )
    parser.add_argument(
        "--min-known",
        type=int,
        default=4,
        help="Minimum known vocabulary tokens required to flag a sentence/paragraph (default: 4; titles use 2).",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=50,
        help="Maximum flagged items to display per section (default: 50).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit results as JSON.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="-",
        help="Output file path, or '-' for stdout (default: '-').",
    )
    parser.add_argument(
        "--model",
        type=Path,
        default=None,
        help="Path to model.js (defaults to bundled scripts/model.js).",
    )
    parser.add_argument(
        "--selftest",
        action="store_true",
        help="Run built-in verification checks against reference test cases and exit.",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s", stream=sys.stderr)
    detector = LoadBearingDetector(args.model)

    if args.selftest:
        run_selftest(detector)
        return 0

    out_buf = io.StringIO()

    if args.text is not None or args.paths == ["-"]:
        raw_text = args.text if args.text is not None else sys.stdin.read()
        res = detector.classify(raw_text)
        if args.json:
            out_buf.write(json.dumps(res, indent=2) + "\n")
        else:
            out_buf.write(format_single_result(raw_text, res))
    else:
        if not args.paths:
            parser.error("Provide one or more files/directories, '-' for stdin, '--text', or '--selftest'.")
        target_paths = [Path(p) for p in args.paths]
        files = iter_target_files(target_paths)
        if not files:
            logger.warning("No supported files found in %s", args.paths)
            return 0

        base_dir = target_paths[0] if len(target_paths) == 1 and target_paths[0].is_dir() else Path.cwd()
        categories = (
            ("docs", "titles", "paragraphs", "sentences")
            if args.mode == "all"
            else ("docs",)
            if args.mode == "text"
            else (args.mode,)
        )

        results_by_cat: Dict[str, List[Dict[str, Any]]] = {cat: [] for cat in categories}
        for fpath in files:
            try:
                rel = str(fpath.relative_to(base_dir))
            except ValueError:
                rel = str(fpath)
            extracted = extract_items_from_file(fpath)
            for cat in categories:
                min_k = 2 if cat == "titles" else args.min_known
                for loc, text_item in extracted.get(cat, []):
                    res = detector.classify(text_item)
                    if res["known"] < min_k:
                        continue
                    if res["p0"] >= args.threshold and res["llr"] >= args.min_llr:
                        pos_words = [
                            {"word": w, "d": round(d, 2), "count": x}
                            for w, d, x in res["evidence"]
                            if d > 0.15
                        ][:6]
                        results_by_cat[cat].append(
                            {
                                "file": rel,
                                "location": loc,
                                "p0": round(res["p0"], 4),
                                "llr": round(res["llr"], 2),
                                "known": res["known"],
                                "text": re.sub(r"\s+", " ", text_item.strip()),
                                "top_words": pos_words,
                            }
                        )

        for cat in categories:
            results_by_cat[cat].sort(key=lambda item: (item["p0"], item["llr"]), reverse=True)

        if args.json:
            out_buf.write(
                json.dumps(
                    {cat: items[: args.top] for cat, items in results_by_cat.items()},
                    indent=2,
                )
                + "\n"
            )
        else:
            for cat in categories:
                items = results_by_cat[cat]
                out_buf.write(
                    f"=== HIGH-SCORING {cat.upper()} (flagged {len(items)}, showing top {min(len(items), args.top)}) ===\n"
                )
                for item in items[: args.top]:
                    tw = ", ".join(f"{w['word']}({w['d']:+.2f})" for w in item["top_words"])
                    snippet = item["text"]
                    if len(snippet) > 140 and cat != "titles":
                        snippet = snippet[:137] + "..."
                    out_buf.write(
                        f"p0={item['p0']:.3f} llr={item['llr']:+.2f} ({item['known']}w) "
                        f"{item['file']}:{item['location']} | {snippet} | [{tw}]\n"
                    )
                out_buf.write("\n")

    output_text = out_buf.getvalue()
    if args.output == "-":
        sys.stdout.write(output_text)
    else:
        Path(args.output).write_text(output_text, encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
