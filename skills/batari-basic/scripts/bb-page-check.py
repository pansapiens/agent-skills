#!/usr/bin/env python3
"""Check that a javatari.js page will actually load its ROM.

Embedding javatari.js has exactly two failure modes that a human only
discovers by opening a browser and staring at a loading screen:

  1. The page is opened over file://, so the browser blocks the ROM fetch.
     Javatari reports this as "Could not load file: game.bas.bin / Error: 0".
     An XHR status of 0 means the request never left the browser — the path
     was fine, the protocol was not.

  2. The ROM reference is resolved against *the page's URL*, not against the
     javatari.js script or the server root. A page in pages/play.html asking
     for roms/game.bas.bin gets /pages/roms/game.bas.bin — a 404, which
     Javatari swallows into an indefinite loading screen.

This fetches the page over HTTP, finds however it names its ROM
(?ROM= in the URL, or Javatari.CARTRIDGE_URL in a script), resolves that the
way the browser will, and fetches it. Exits non-zero if anything is wrong.

    bb-page-check.py http://localhost:8600/kabobber/index.html
    bb-page-check.py http://localhost:8600/*/index.html

Uses only the standard library.
"""
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

TIMEOUT = 10

# Javatari.CARTRIDGE_URL = "game.bas.bin"   (also accepts CART / ROM aliases)
CART_RE = re.compile(
    r"""Javatari\s*\.\s*(?:CARTRIDGE_URL|CART|ROM)\s*=\s*["']([^"']+)["']"""
)
SCREEN_RE = re.compile(r"""id\s*=\s*["']javatari-screen["']""")
SCRIPT_RE = re.compile(r"""<script[^>]+src\s*=\s*["']([^"']*javatari[^"']*\.js)["']""", re.I)


def fetch(url):
    """Return (status, body_bytes). Raises for anything that isn't HTTP."""
    req = urllib.request.Request(url, headers={"User-Agent": "bb-page-check"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, b""


def check(page_url):
    problems = []
    scheme = urllib.parse.urlparse(page_url).scheme

    if scheme not in ("http", "https"):
        print(f"FAIL {page_url}")
        print("  Not an http(s) URL. Javatari fetches the ROM with XHR, which")
        print("  browsers block on file:// — you would get 'Error: 0' no matter")
        print("  how correct the ROM path is. Serve the directory first:")
        print("      scripts/bb-serve.sh <dir> 8600")
        return False

    try:
        status, body = fetch(page_url)
    except Exception as e:  # connection refused, DNS, timeout
        print(f"FAIL {page_url}\n  Could not fetch the page: {e}")
        print("  Is the server running? scripts/bb-serve.sh <dir> 8600")
        return False

    if status != 200:
        print(f"FAIL {page_url}\n  Page returned HTTP {status}.")
        return False

    html = body.decode("utf-8", "replace")

    if not SCREEN_RE.search(html):
        problems.append(
            'No element with id="javatari-screen". The emulator has nowhere '
            "to draw (SCREEN_ELEMENT_ID default)."
        )

    # The javatari.js script itself must resolve, and it resolves relative to
    # the page just like the ROM does.
    m = SCRIPT_RE.search(html)
    if not m:
        problems.append("No <script src=...javatari.js> tag found on the page.")
    else:
        src = urllib.parse.urljoin(page_url, m.group(1))
        st, _ = fetch(src)
        if st != 200:
            problems.append(f"javatari.js is HTTP {st} at {src}")

    # How does the page name its ROM?
    rom = None
    q = urllib.parse.parse_qs(urllib.parse.urlparse(page_url).query)
    for key in ("ROM", "CART", "CARTRIDGE_URL"):
        if key in q:
            rom = q[key][0]
            break
    if rom is None:
        m = CART_RE.search(html)
        if m:
            rom = m.group(1)

    if not rom:
        problems.append(
            "Page names no ROM (no ?ROM= parameter and no Javatari.CARTRIDGE_URL). "
            "It will sit on the cartridge-select screen."
        )
    else:
        rom_url = urllib.parse.urljoin(page_url, rom)
        st, data = fetch(rom_url)
        if st != 200:
            problems.append(
                f"ROM {rom!r} resolves to {rom_url} -> HTTP {st}.\n"
                "    Remember the path is relative to THE PAGE's URL, not to\n"
                "    javatari.js and not to the server root."
            )
        elif len(data) < 4096 or len(data) & (len(data) - 1):
            problems.append(
                f"ROM {rom_url} is {len(data)} bytes — not a power of two >= 4096. "
                "Javatari will fail to pick a cartridge format."
            )

    if problems:
        print(f"FAIL {page_url}")
        for p in problems:
            print(f"  - {p}")
        return False

    print(f"ok   {page_url}  (ROM {rom} loads)")
    return True


def main(argv):
    if not argv:
        print((__doc__ or "").strip())
        return 2
    return 0 if all([check(u) for u in argv]) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
