#!/usr/bin/env python
"""Fetch and cache the SLURM accounting data a weather report needs.

Splits the requested period into calendar days, fetches each day once and caches
it as Parquet. Re-running for an overlapping period costs nothing beyond the
current day. Also snapshots the live queue, node inventory and operator
announcements, which are point-in-time and cannot be backfilled.

    ./collect.py --period daily   --ending "2026-08-28 08:00"
    ./collect.py --period monthly --ending "2026-08-28 08:00" --cache-dir ./cache
"""

import os
import sys
import json
import logging
import argparse
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from slurmwx import DayCache, announcements, node_inventory, queue_snapshot, setup_logging

logger = logging.getLogger(__name__)

PERIOD_DAYS = {"daily": 1, "weekly": 7, "monthly": 30}


def parse_ending(value: str) -> datetime:
    """Accept '2026-08-28 08:00', '2026-Aug-28 8am', ISO, or 'now'."""
    v = (value or "now").strip()
    if v.lower() == "now":
        return datetime.now()
    v = v.replace("am", " AM").replace("pm", " PM")
    for fmt in ("%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S",
                "%Y-%b-%d %I %p", "%Y-%b-%d %H:%M", "%Y-%m-%d %I %p", "%Y-%m-%d"):
        try:
            return datetime.strptime(" ".join(v.split()), fmt)
        except ValueError:
            continue
    raise argparse.ArgumentTypeError(f"cannot parse --ending {value!r}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--period", choices=sorted(PERIOD_DAYS), default="daily")
    ap.add_argument("--ending", type=parse_ending, default="now",
                    help="End of the reporting window (default: now)")
    ap.add_argument("--days", type=int, default=None,
                    help="Override the window length implied by --period")
    ap.add_argument("--cache-dir", default="cache")
    ap.add_argument("--out-dir", default=None,
                    help="Where to write the period dataset (default: <cache-dir>/periods)")
    ap.add_argument("--refresh", action="store_true",
                    help="Refetch days already cached")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    setup_logging(args.verbose)

    if isinstance(args.ending, str):
        args.ending = parse_ending(args.ending)
    ndays = args.days or PERIOD_DAYS[args.period]
    end = args.ending
    start = end - timedelta(days=ndays)

    out_dir = args.out_dir or os.path.join(args.cache_dir, "periods")
    tag = f"{args.period}-{end.date().isoformat()}"
    out_dir = os.path.join(out_dir, tag)
    os.makedirs(out_dir, exist_ok=True)

    logger.info("collecting %s: %s -> %s", args.period, start, end)

    cache = DayCache(args.cache_dir)
    # Day chunks are whole days; the window is trimmed to `start`/`end` later.
    jobs = cache.load_range(start.date(), end.date() + timedelta(days=1),
                            refresh=args.refresh)
    if jobs.empty:
        logger.error("no job records returned for %s -> %s", start, end)
        return 1

    jobs.to_parquet(os.path.join(out_dir, "jobs.parquet"), index=False)
    logger.info("%d job-day rows cached", len(jobs))

    nodes = node_inventory()
    nodes.to_parquet(os.path.join(out_dir, "nodes.parquet"), index=False)
    logger.info("%d nodes", len(nodes))

    queue = queue_snapshot()
    if not queue.empty:
        queue.to_parquet(os.path.join(out_dir, "queue.parquet"), index=False)
    logger.info("%d jobs in queue", len(queue))

    notices = announcements()
    if notices:
        with open(os.path.join(out_dir, "announcements.md"), "w") as fh:
            fh.write(notices + "\n")

    meta = {
        "period": args.period,
        "window_start": start.isoformat(),
        "window_end": end.isoformat(),
        "days": ndays,
        "collected_at": datetime.now().isoformat(),
        "cluster": os.environ.get("SLURM_CLUSTER_NAME", "m3"),
        "job_day_rows": int(len(jobs)),
        "n_nodes": int(len(nodes)),
        "n_queued": int(len(queue)),
    }
    with open(os.path.join(out_dir, "meta.json"), "w") as fh:
        json.dump(meta, fh, indent=2)

    print(out_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
