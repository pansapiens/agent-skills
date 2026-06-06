#!/usr/bin/env python
"""Submit RCSB PDB Structure Alignment job and poll for results. See references/rcsb-alignment-api.md."""

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
import time

import requests

BASE = "https://alignment.rcsb.org/api/v1/structures"

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def submit(query: dict, files: Optional[list] = None) -> str:
    data = {"query": json.dumps(query)}
    if files:
        r = requests.post(f"{BASE}/submit", data=data, files=files, timeout=60)
    else:
        r = requests.post(f"{BASE}/submit", data=data, timeout=60)
    r.raise_for_status()
    return r.json()["uuid"]


def get_results(uuid: str) -> dict:
    r = requests.get(f"{BASE}/results", params={"uuid": uuid}, timeout=30)
    r.raise_for_status()
    return r.json()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Submit pairwise structure alignment and wait for results."
    )
    parser.add_argument(
        "entry1",
        type=str,
        help="First PDB entry ID",
    )
    parser.add_argument(
        "entry2",
        type=str,
        help="Second PDB entry ID",
    )
    parser.add_argument(
        "--chain1",
        type=str,
        default="A",
        help="Chain (asym_id) for entry1 (default: A)",
    )
    parser.add_argument(
        "--chain2",
        type=str,
        default="A",
        help="Chain (asym_id) for entry2 (default: A)",
    )
    parser.add_argument(
        "--method",
        type=str,
        default="fatcat-rigid",
        choices=["fatcat-rigid", "fatcat-flexible", "ce", "ce-cp", "tmalign", "smith-waterman-3d"],
        help="Alignment method (default: fatcat-rigid)",
    )
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=2.0,
        help="Seconds between status polls (default: 2)",
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="-",
        help="Write full JSON result here (default: stdout)",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print only summary scores, then exit",
    )
    args = parser.parse_args()

    query = {
        "context": {
            "mode": "pairwise",
            "method": {"name": args.method},
            "structures": [
                {"entry_id": args.entry1, "selection": {"asym_id": args.chain1}},
                {"entry_id": args.entry2, "selection": {"asym_id": args.chain2}},
            ],
        }
    }

    try:
        uuid = submit(query)
        logger.info("Submitted job %s", uuid)
    except requests.RequestException as e:
        logger.error("Submit failed: %s", e)
        return 1

    while True:
        try:
            data = get_results(uuid)
        except requests.RequestException as e:
            logger.error("Results request failed: %s", e)
            return 1

        status = data.get("info", {}).get("status")
        if status == "COMPLETE":
            break
        if status == "ERROR":
            msg = data.get("info", {}).get("message", "Alignment failed")
            logger.error("Job failed: %s", msg)
            return 1
        logger.info("Status: %s", status)
        time.sleep(args.poll_interval)

    results = data.get("results", [])
    if not results:
        logger.warning("No results in response")
        return 0

    if args.summary_only:
        summary = results[0].get("summary", {})
        scores = summary.get("scores", [])
        for s in scores:
            print(f"  {s.get('type')}: {s.get('value')}")
        print(f"  n_aln_residue_pairs: {summary.get('n_aln_residue_pairs')}")
        return 0

    out = json.dumps(data, indent=2)
    if args.output == "-":
        print(out)
    else:
        with open(args.output, "w") as f:
            f.write(out)
        logger.info("Wrote %s", args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
