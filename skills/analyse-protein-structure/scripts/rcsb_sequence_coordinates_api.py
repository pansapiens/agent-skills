#!/usr/bin/env python
"""Run RCSB PDB Sequence Coordinates API GraphQL queries. See references/rcsb-sequence-coordinates-api.md."""

# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "requests>=2.31.0",
# ]
# ///

from typing import Optional
import argparse
import json
import logging
import sys

import requests

SEQ_COORD_URL = "https://sequence-coordinates.rcsb.org/graphql"

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def graphql(query: str, variables: Optional[dict] = None) -> dict:
    payload: dict = {"query": query}
    if variables:
        payload["variables"] = variables
    r = requests.post(SEQ_COORD_URL, json=payload, timeout=30)
    r.raise_for_status()
    return r.json()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run Sequence Coordinates API GraphQL query. Query from stdin or --query."
    )
    parser.add_argument(
        "-q", "--query",
        type=str,
        help="GraphQL query string (or read from stdin)",
    )
    parser.add_argument(
        "-v", "--variables",
        type=str,
        default=None,
        help="JSON object of variables",
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="-",
        help="Output file (default: stdout)",
    )
    args = parser.parse_args()

    query = args.query
    if not query:
        query = sys.stdin.read().strip()
    if not query:
        logger.error("No query provided (use -q or stdin)")
        return 1

    variables = None
    if args.variables:
        try:
            variables = json.loads(args.variables)
        except json.JSONDecodeError as e:
            logger.error("Invalid --variables JSON: %s", e)
            return 1

    try:
        result = graphql(query, variables)
    except requests.RequestException as e:
        logger.error("Request failed: %s", e)
        return 1

    out = json.dumps(result, indent=2)
    if args.output == "-":
        print(out)
    else:
        with open(args.output, "w") as f:
            f.write(out)
        logger.info("Wrote %s", args.output)

    if "errors" in result and result["errors"]:
        logger.warning("GraphQL returned errors: %s", result["errors"])
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
