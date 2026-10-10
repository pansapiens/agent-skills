#!/usr/bin/env python
"""Persistent, activity-flavoured pseudonyms for the people in a weather report.

Reports name people, and a utilisation bulletin that circulates beyond the team
running the cluster should not do that with real names. But a report where
everyone is "user-7" is unreadable, and one where the handles are reshuffled each
week is worse than useless -- nobody can tell whether last month's Nimbus is this
month's Nimbus.

So: a pseudonym is derived from what the person actually does on the cluster
("The Indefatigable Pipeline Baron" for someone drowning in Nextflow tasks), and
it is written to a mapping file the first time they appear so it stays theirs.
The mapping file is the only place real names live; it is written 0600 and must
not be committed or circulated with the report.

The pool is meant to be affectionate rather than pointed. These land next to
tables about over-allocated memory, and a nickname that reads as an accusation
would be worse than the real name it replaced.

    from pseudonyms import Pseudonyms
    book = Pseudonyms.load("pseudonyms.toml")
    handle = book.assign("abcd0001", signature="nextflow",
                         name="Given Family", email="g.f@monash.edu")
    book.save()
"""

import os
import logging
import tomllib
from datetime import date, datetime, timezone
from typing import Optional

import tomli_w

logger = logging.getLogger("pseudonyms")

DEFAULT_PATH = "pseudonyms.toml"

# Keyed by the activity signature digest.py works out for each person. The
# adjective is drawn from a shared pool, so the combinations run to thousands and
# two people with the same habit still read as different characters.
NOUNS = {
    "nextflow": ["Pipeline Baron", "Channel Operator", "Process Herder",
                 "Workflow Whisperer", "DAG Wrangler", "Task Shepherd"],
    "snakemake": ["Rule Collector", "Snakecharmer", "Wildcard Enthusiast",
                  "Dependency Diagrammer", "Target Chaser"],
    "interactive": ["Terminal Perennial", "Session Keeper", "Prompt Dweller",
                    "Tab Collector", "Shell Companion"],
    "desktop": ["Desktop Resident", "Window Custodian", "Long Session",
                "Remote Homesteader", "Screen Tenant"],
    "gpu": ["Accelerator Fancier", "Tensor Tamer", "CUDA Devotee",
            "Kernel Launcher", "Card Collector", "Warp Navigator"],
    "memory": ["Gigabyte Optimist", "Terabyte Landlord", "Allocation Romantic",
               "Headroom Enthusiast", "Spacious Requester"],
    "array": ["Job Firehose", "Task Multiplier", "Array Artillery",
              "Thousand-Job Storm", "Index Enthusiast"],
    "bigcpu": ["Core Baron", "Node Monopolist", "Rank Marshal",
               "Parallel Enthusiast", "Socket Sovereign"],
    "nocturnal": ["Small-Hours Submitter", "Three-AM Correspondent",
                  "Night Shift", "Insomniac Scheduler"],
    "weekend": ["Saturday Regular", "Weekend Warrior", "Sunday Submitter"],
    # Everyone else gets the weather handles the report is themed around.
    "default": ["Cumulus", "Nimbus", "Stratus", "Cirrus", "Zephyr", "Monsoon",
                "Sirocco", "Chinook", "Mistral", "Squall", "Haboob",
                "Southerly", "Thunderhead", "Fogbank", "Anvil", "Updraft",
                "Contrail", "Halo", "Aurora", "Willy-Willy"],
}

ADJECTIVES = [
    "Indefatigable", "Nocturnal", "Serene", "Restless", "Prodigious",
    "Unflappable", "Stoic", "Genial", "Punctual", "Ambitious", "Industrious",
    "Cheerful", "Persistent", "Meticulous", "Intrepid", "Patient", "Redoubtable",
    "Sanguine", "Tireless", "Methodical", "Venerable", "Resolute",
]


def _hash(text: str) -> int:
    """Small stable hash. Not PYTHONHASHSEED-dependent, unlike hash()."""
    h = 2166136261
    for ch in text.encode("utf-8"):
        h = ((h ^ ch) * 16777619) & 0xFFFFFFFF
    return h


def _mint(username: str, signature: str, taken: set[str]) -> str:
    """A pseudonym for this person: stable in the username, flavoured by what
    they do, and nudged along if something else already holds it."""
    nouns = NOUNS.get(signature) or NOUNS["default"]
    # Two independent hashes: one hash split into two indices correlates them, so
    # half the report ends up Indefatigable.
    n_seed, a_seed = _hash(username), _hash(username + "/adjective")
    for attempt in range(len(ADJECTIVES) * len(nouns)):
        noun = nouns[(n_seed + attempt) % len(nouns)]
        adj = ADJECTIVES[(a_seed + attempt // len(nouns)) % len(ADJECTIVES)]
        candidate = f"The {adj} {noun}"
        if candidate not in taken:
            return candidate
    return f"Anonymous {n_seed % 10000:04d}"


class Pseudonyms:
    """A username -> pseudonym lookup that survives between reports."""

    def __init__(self, path: str, users: Optional[dict] = None):
        self.path = path
        self.users = users or {}
        self._dirty = False

    @classmethod
    def load(cls, path: str = DEFAULT_PATH) -> "Pseudonyms":
        if not os.path.exists(path):
            logger.info("no pseudonym book at %s; starting one", path)
            return cls(path)
        with open(path, "rb") as fh:
            data = tomllib.load(fh)
        return cls(path, data.get("users", {}))

    def assign(self, username: str, signature: str = "default",
               name: Optional[str] = None, email: Optional[str] = None) -> str:
        """This person's pseudonym, minting one on first sight.

        An existing pseudonym is never changed, even if the signature has moved
        on -- continuity across reports is the entire point, and someone who
        stopped running Nextflow in March is still recognisable as the Pipeline
        Baron. Edit the file by hand to override one.
        """
        rec = self.users.get(username)
        if rec and rec.get("pseudonym"):
            # Backfill identity details if they were not resolvable last time.
            for key, val in (("name", name), ("email", email)):
                if val and not rec.get(key):
                    rec[key] = val
                    self._dirty = True
            return rec["pseudonym"]

        taken = {r.get("pseudonym") for r in self.users.values()}
        handle = _mint(username, signature, taken)
        self.users[username] = {
            "pseudonym": handle,
            "name": name or "",
            "email": email or "",
            "signature": signature,
            "first_seen": date.today().isoformat(),
        }
        self._dirty = True
        return handle

    def save(self) -> None:
        """Write the book back, 0600. It holds real names and addresses."""
        if not self._dirty:
            return
        payload = {
            "meta": {
                "note": ("Maps M3 usernames to the pseudonyms used in weather "
                         "reports. Contains real names and email addresses -- "
                         "keep it out of version control and do not circulate "
                         "it with a report. Edit a pseudonym here to change it "
                         "everywhere; it will not be regenerated."),
                "updated": datetime.now(timezone.utc).replace(microsecond=0),
            },
            "users": dict(sorted(self.users.items())),
        }
        tmp = f"{self.path}.tmp"
        with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600),
                  "wb") as fh:
            tomli_w.dump(payload, fh)
        os.replace(tmp, self.path)
        os.chmod(self.path, 0o600)
        self._dirty = False
        logger.info("pseudonym book: %d people in %s", len(self.users), self.path)
