# scripts/

Four small helpers for the compile → run → look loop. They wrap only the
parts that are the same for every bB game; everything game-specific stays in
your hands.

| Script | Does |
|---|---|
| `bb-build.sh <game.bas> [args]` | Compile and verify a ROM appeared. Exits non-zero on failure. |
| `get-gopher2600.sh` | Ensure the headless emulator exists; prints its path. |
| `bb-headless.sh <rom> <steps.txt> [secs]` | Run the ROM under gopher2600 HEADLESS with a command script. |
| `frame-check.py <shot.png>...` | Flag blank and frozen frames in a batch of screenshots. |

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

## What these scripts deliberately do not do

**They do not write the steps file.** How long the title screen takes, which
switch starts the game, whether fire is a tap or a hold, how many frames a
drop takes — all of that differs per game, and a canned input sequence would
quietly test nothing. Write the steps by hand from what the game does. The
command vocabulary, and the `STICK` syntax quirks that the emulator's own
`HELP` gets wrong, are in `references/running-in-an-emulator.md`.

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
- `get-gopher2600.sh` caches the binary in `${XDG_CACHE_HOME:-~/.cache}/batari-basic`
  (override with `BB_CACHE`) so it never lands in a git tree, and honours an
  existing `$BB_GOPHER2600` or a `gopher2600` on `$PATH`. Only linux/amd64 is
  published upstream; on anything else it tells you to `go install` instead.
- `bb-headless.sh` requires absolute paths, warns about a relative
  `SCREENSHOT` path or a missing `QUIT`, and fails if the emulator rejected a
  command or wrote fewer screenshots than the steps file asked for (usually
  means the run needs more seconds).
- `frame-check.py` needs Pillow.
