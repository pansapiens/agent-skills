#!/usr/bin/env python
"""Run RCSB PDB Search API queries. See references/rcsb-search-api.md."""

# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "requests>=2.31.0",
# ]
# ///

import argparse
import json
import logging
import sys

import requests

SEARCH_URL = "https://search.rcsb.org/rcsbsearch/v2/query"

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def search(query: dict) -> dict:
    r = requests.post(SEARCH_URL, json=query, timeout=60)
    r.raise_for_status()
    if r.status_code == 204:
        return {"result_set": [], "total_count": 0}
    return r.json()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run RCSB Search API query. Request JSON from stdin or --request."
    )
    parser.add_argument(
        "-r", "--request",
        type=str,
        help="Search request JSON (or read from stdin)",
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="-",
        help="Output file (default: stdout)",
    )
    parser.add_argument(
        "--ids-only",
        action="store_true",
        help="Print only identifiers, one per line",
    )
    args = parser.parse_args()

    raw = args.request
    if not raw:
        raw = sys.stdin.read().strip()
    if not raw:
        logger.error("No request JSON provided (use -r or stdin)")
        return 1

    try:
        request = json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON: %s", e)
        return 1

    try:
        result = search(request)
    except requests.RequestException as e:
        logger.error("Request failed: %s", e)
        return 1

    if args.ids_only:
        for hit in result.get("result_set", []):
            ident = hit.get("identifier") if isinstance(hit, dict) else hit
            if ident is not None:
                print(ident)
        return 0

    out = json.dumps(result, indent=2)
    if args.output == "-":
        print(out)
    else:
        with open(args.output, "w") as f:
            f.write(out)
        logger.info("Wrote %s (total_count=%s)", args.output, result.get("total_count", 0))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
