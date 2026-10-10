"""Victorian public holiday and school holiday lookup for the weather reports.

M3 is a Melbourne cluster and its load follows Melbourne's calendar. Without this,
a five-day trough over Easter or a fortnight of quiet in the July school holidays
reads as an unexplained outage; with it, the report can say why.

Dates live in ``assets/calendar-vic.toml`` because they cannot be derived -- Easter
moves and Victoria gazettes one-off holidays each year.
"""

import os
import logging
import tomllib
from datetime import date, datetime
from typing import Optional

logger = logging.getLogger(__name__)

DEFAULT_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                            "assets", "calendar-vic.toml")


class Calendar:
    def __init__(self, public_holidays: list[dict], school_holidays: list[dict],
                 meta: Optional[dict] = None):
        self.public_holidays = public_holidays
        self.school_holidays = school_holidays
        self.meta = meta or {}

    @classmethod
    def load(cls, path: Optional[str] = None) -> "Calendar":
        path = path or DEFAULT_PATH
        try:
            with open(path, "rb") as fh:
                data = tomllib.load(fh)
        except FileNotFoundError:
            logger.warning("no calendar file at %s; holiday band disabled", path)
            return cls([], [], {})
        return cls(data.get("public_holiday", []),
                   data.get("school_holiday", []),
                   data.get("meta", {}))

    # ------------------------------------------------------------------ query --

    def spans(self, start: datetime, end: datetime) -> dict:
        """Everything overlapping [start, end), as half-open datetime spans.

        Public holidays become whole-day spans so they can be drawn as bands
        rather than lines, and are clipped to the window.
        """
        s, e = _as_date(start), _as_date(end)
        pub, school = [], []

        for h in self.public_holidays:
            d = _as_date(h["date"])
            if s <= d <= e:
                pub.append({"start": _dt(d), "end": _dt(d, plus=1),
                            "name": h["name"],
                            "provisional": bool(h.get("provisional", False))})

        for h in self.school_holidays:
            hs, he = _as_date(h["start"]), _as_date(h["end"])
            if he >= s and hs <= e:
                school.append({"start": _dt(max(hs, s)), "end": _dt(min(he, e), plus=1),
                               "name": h["name"],
                               "clipped": hs < s or he > e})

        years = {d.year for d in (s, e)}
        covered = set(self.meta.get("populated_years", []))
        return {
            "public_holidays": sorted(pub, key=lambda x: x["start"]),
            "school_holidays": sorted(school, key=lambda x: x["start"]),
            # A window in a year the file knows nothing about would show an empty
            # band that looks identical to a genuinely holiday-free window.
            "years_covered": sorted(years & covered),
            "years_missing": sorted(years - covered),
            "verified_years": self.meta.get("verified_years", []),
        }


def _as_date(value) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return datetime.fromisoformat(str(value)).date()


def _dt(d: date, plus: int = 0) -> datetime:
    from datetime import timedelta
    return datetime.combine(d + timedelta(days=plus), datetime.min.time())
