# scripts/

Six small helpers for the compile → run → look loop, plus handing the game
to a human in a browser. They wrap only the parts that are the same for
every bB game; everything game-specific stays in your hands.

| Script | Does |
|---|---|
| `bb-build.sh <game.bas> [args]` | Compile and verify a ROM appeared. Exits non-zero on failure. |
| `get-bb-wasm.sh` | Ensure a portable wasm bB toolchain exists; prints its dir. |
| `get-gopher2600.sh` | Ensure the headless emulator exists; prints its path. |
| `bb-headless.sh <rom> <steps.txt> [secs]` | Run the ROM under gopher2600 HEADLESS with a command script. |
| `frame-check.py <shot.png>...` | Flag blank and frozen frames in a batch of screenshots. |
| `bb-serve.sh [dir] [port]` | Serve a directory so javatari.js can fetch the ROM at all. |
| `bb-page-check.py <page-url>...` | Verify a javatari page's ROM reference resolves, and warn on the paddle-mode trap. |

Typical loop:

```bash
scripts/bb-build.sh game.bas || exit 1

STEPS=/tmp/steps.txt
{ for i in $(seq 1 60); do echo "STEP FRAME"; done   # let the title settle
  echo "SCREENSHOT /tmp/shots/1-title.png"
  echo "STICK LEFT FIRE"; echo "STEP FRAME"          # start the game
  echo "STICK LEFT NOFIRE"
  for i in $(seq 1 90); do echo "STEP FRAME"; done
  echo "SCREENSHOT /tmp/shots/2-play.png"
  echo "QUIT"; } > "$STEPS"

scripts/bb-headless.sh game.bas.bin "$STEPS" 10
scripts/frame-check.py /tmp/shots/*.png
```

then **open the screenshots and look at them**.

Handing the game to a human in a browser:

```bash
scripts/bb-serve.sh . 8600 &
scripts/bb-page-check.py http://localhost:8600/mygame/index.html
```

## What these scripts deliberately do not do

**They do not write the steps file.** How long the title screen takes, which
switch starts the game, whether fire is a tap or a hold, how many frames a
drop takes — all of that differs per game, and a canned input sequence would
quietly test nothing. Write the steps by hand from what the game does. The
command vocabulary, and the `STICK` port-vs-direction trap, are in
`references/running-in-an-emulator.md`. When in doubt about any command's
syntax, run `HELP <CMD>` inside HEADLESS mode — the binary's own usage string
is authoritative. Never clone or build the gopher2600 source to find out.

If you drive the emulator yourself rather than through `bb-headless.sh`, keep
its **stdout**: rejected commands are reported there, prefixed with `* `, and
`grep '^\*'` is the check. Do not `>/dev/null 2>&1` the emulator, and do not
grep for "error" — the debugger never uses the word.

**They do not decide whether the game is correct.** `frame-check.py` answers
one narrow question — "is this frame blank, or identical to the last one?" —
because those two symptoms cover most compile-clean crashes and hangs and are
tedious to spot by hand across a dozen screenshots. It says nothing about
whether the sprite is the right colour, whether the playfield lines up with
the grid, or whether the cake landed on the platter. Those need eyes on the
image, every time.

A pixel-diff between consecutive screenshots sounds useful and mostly is not:
it reports that something changed without saying what, and in practice
looking at the frame is both faster and more informative.

## Notes

- `bb-build.sh` finds the compiler via `$BB_HOME`, then a `batari-Basic/`
  directory beside the `.bas` file or any parent, then `$PATH`. It compiles
  from a scratch directory because `2600bas` drops `bB.asm`, `includes.bB`
  and `2600basic_variable_redefs.h` into the current directory.
- `BB_TOOLCHAIN=auto|native|wasm` picks the compiler. `auto` (default) uses a
  native bB if it can find one and otherwise falls back to the wasm build, so
  `get-bb-wasm.sh` alone is enough to work on a machine with no C toolchain —
  the point being macOS and Windows, where upstream ships nothing else. Both
  toolchains were verified to emit byte-identical ROMs.
- `get-bb-wasm.sh` fetches the bB wasm distribution *and* a `wasmtime` binary
  into the cache. It deliberately does not run wasmtime's official installer
  script, which writes to `$HOME` and edits shell profiles; a cached binary is
  reversible by deleting one directory.
- `get-gopher2600.sh` caches the binary in `${XDG_CACHE_HOME:-~/.cache}/batari-basic`
  (override with `BB_CACHE`) so it never lands in a git tree, and honours an
  existing `$BB_GOPHER2600` or a `gopher2600` on `$PATH`. Only linux/amd64 is
  published; on anything else it tells you to build from source.
  It fetches **pansapiens/Gopher2600**, a fork whose only change is fixing
  `HELP STICK`/`HELP KEYPAD` — upstream's says to "specify the player with the
  0 or 1 arguments", which the parser rejects, and never mentions that the
  argument is the console *port* (LEFT = Player 0). Emulation is unchanged.
  `BB_GOPHER2600_UPSTREAM=1` takes upstream's release instead; the two cache
  under different filenames so neither masks the other.
- `bb-headless.sh` requires absolute paths, warns about a relative
  `SCREENSHOT` path or a missing `QUIT`, and fails if the emulator rejected a
  command or wrote fewer screenshots than the steps file asked for (usually
  means the run needs more seconds).
- `frame-check.py` needs Pillow.
- `bb-page-check.py` is standard-library only. It exists because the
  browser's own report of the commonest embedding failure is actively
  misleading: a page opened over `file://` shows **"Could not load file:
  game.bas.bin / Error: 0"**, which names the ROM and reads like a bad path,
  but `Error: 0` is an XHR status of zero — the browser blocked the request
  over CORS and the path was never at fault. The script separates that case
  from a genuinely wrong relative path (which javatari reports as *nothing
  at all*, just an endless loading screen) in one line. It also warns when
  the ROM's *filename* will make javatari guess paddles — a joystick game
  called `piece-o-cake.bas.bin` or `breakout.bas.bin` boots in paddle mode
  and appears to be steered by A and Space while the arrow keys do nothing.
  All three traps, and the page snippets that pre-empt them, are in
  `references/running-in-an-emulator.md`.
