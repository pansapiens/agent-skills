---
name: batari-basic
description: Write, compile, and debug batari Basic (bB) programs and games for the Atari 2600. Use this skill whenever the task involves batari Basic, bB, .bas files compiled to 2600 ROMs, Atari 2600 game programming in BASIC, sprites/playfields/score on the 2600, or running bB output in Stella or on hardware — even if the user just says "make an Atari 2600 game" or "compile this .bas". Includes the full bB language reference distilled from randomterrain.com, 90+ working example programs, and cross-platform compiler setup (portable wasm toolchain or native build).
---

# batari Basic (bB) skill

batari Basic is a compiled BASIC-like language for the Atari 2600. It is NOT
standard BASIC: the 2600 has 128 bytes of RAM, no video memory, and every
frame of the picture is drawn by a kernel inside `drawscreen`. Models that
write bB successfully internalize the constraints below and consult the
reference files instead of guessing syntax — bB looks like BASIC but almost
every construct has 2600-specific limits, and invented syntax will not
compile.

## Workflow

1. **Read the routing table** below and load the reference files your task
   needs (they are comprehensive — syntax, valid values, and examples).
2. **Write the .bas file** starting from the skeleton in this file or from
   the closest example in `examples/` (see `examples/README.md`). Give it
   a snake_case stem matching a supported ALE game from the start —
   default `adventure.bas` (genre fits: `space_invaders.bas`,
   `breakout.bas`, `pong.bas`) — so the compiled ROM stays ALE-testable
   with one copy: `cp adventure.bas.bin adventure.bin` (details in
   `references/running-in-an-emulator.md`). **Caveat:** javatari guesses
   the controller from the ROM's filename, so a name matching a paddle
   title (`breakout`, `kaboom`, `warlords`, `bugs`, …) boots in paddle
   mode and ignores the arrow keys. Harmless if you set
   `Javatari.PADDLES_MODE = 0` on the page — see the same reference.
3. **Compile often, in small increments.** After each feature is added:
   `scripts/bb-build.sh game.bas` (finds the compiler, keeps its intermediate
   files out of your project, and exits non-zero if no valid ROM appeared), or
   `batari-Basic/2600bas game.bas` directly. Success prints `Complete. (0)`
   and `N bytes of ROM space left` and produces `game.bas.bin`. When it fails,
   fix before adding more — error meanings are in
   `references/troubleshooting.md`.
4. **Never trust untested code.** Every code block you write should have
   been compiled before you hand it over. If the compiler is not installed,
   the fastest route is `scripts/get-bb-wasm.sh` — one command, works on
   Linux/macOS/Windows, no C toolchain, and emits byte-identical ROMs to a
   native build. Build natively instead per `references/installation.md` if
   you want the last 60 ms per compile.
5. **Compiling is not evidence that the game works.** The bugs that cost the
   most time all compile cleanly and then show a black or frozen screen —
   see the silent-failure list in `references/troubleshooting.md`. Run the
   ROM (`scripts/bb-headless.sh`), then **look at the screenshots**; the
   compiler cannot tell you the sprite is invisible or the grid is
   misaligned.

If no batari-Basic directory exists nearby, either run
`scripts/get-bb-wasm.sh` (portable, no build) or install natively per
`references/installation.md` and use `/path/to/batari-Basic/2600bas`.

## The canonical game skeleton

```bb
   set smartbranching on
   set kernel_options no_blank_lines    ; standard kernel options, optional

   rem  <dims and constants go at the top>
   dim framecounter = a
   const speed = 2

   rem  <setup: runs once>
   COLUBK = $00
   scorecolor = $1E
   player0x = 75 : player0y = 50
   COLUP0 = $9C
   player0:
   %00100100
   %00100100
   %01111110
   %11011011
   %11111111
   %10111101
   %00100100
   %00100100
end

   rem  <main loop>
mainloop
   framecounter = framecounter + 1
   if joy0left then player0x = player0x - 1
   if joy0right then player0x = player0x + 1
   if joy0up then player0y = player0y - 1
   if joy0down then player0y = player0y + 1
   if joy0fire then score = score + 10
   drawscreen
   goto mainloop

   rem  <subroutines always go AFTER the main loop's goto>
```

Structure rules: `set`/`dim`/`const`/`def`/`data`/sprite-playfield blocks may
appear anywhere, but convention is top of file; executable setup code next;
then the main loop; subroutines after. Indent code (3 spaces), never indent
labels. Labels have **no colon**. `rem` starts a comment.

## Non-negotiable facts (violating these = broken game)

**Machine & memory**
- 26 user variables `a`–`z`, each 0–255 (one byte), wrap on overflow. No
  arrays (except ROM `data` tables), no strings, no floats.
- `temp1`–`temp6` are scratch — clobbered by many commands.
- Default ROM 4K; `set romsize 8k`/`16k`/`32k`... for bankswitched games
  (see kernels-and-memory.md). **64k is the ceiling** - there is no
  128k/512k romsize, so a bigger cartridge means leaving bB behind.
- A `data` table is only readable **from the bank it was written in**.
  Sprite graphics and pfcolors data are placed automatically (last bank);
  plain `data` is not.
- Game logic between drawscreens: ~2700 cycles / 2 ms. Long loops make the
  screen roll.

**The display**
- `drawscreen` draws one TV frame (~60/sec) and returns. Set all positions,
  colors, playfield before it; changes appear only on the NEXT drawscreen.
- Standard kernel objects: player0, player1 (8-px-wide sprites),
  missile0, missile1 (rectangles), ball, 32×12 playfield, 6-digit score.
- `COLUP0`/`COLUP1` (sprite+missile colors) are reset by every drawscreen
  to the score color — set them inside the main loop. `COLUBK`
  (background) and `COLUPF` (playfield/ball) persist.
- Colors are `$XY`: high nibble hue (1–C), low nibble luminance — use EVEN
  luminance values ($02–$0E). Not RGB.
- Sprites are black by default — invisible on the default black background
  until you set their color.
- **Sprite data is upside down:** the first line of a `player0:`/`player1:`
  block is the sprite's **bottom** row, and `player0color:`/`player1color:`
  tables are in the same bottom-first order. Write them the way they look
  and your sprite renders inverted. Corollary: once they are authored
  bottom-first they are right, so an inverted sprite after that is a
  different bug - do not add a reversal pass, it inverts everything.
- **`pfcolors` is offset by one row:** playfield row `r` takes entry
  `r + 1`, and each row's top two scanlines take entry `r`. Emit 12
  entries with the first colour repeated (`c0, c0, c1, ... c10`).

**Movement & coordinates (standard kernel)**
- player0x/player1x: usable 1–159; player0y/player1y: usable 1–88.
  `x = x + 1` moves ~1 pixel per frame; faster = bigger steps or 8.8
  fixed point (dim a.b + `include fixed_point_math.asm`) for sub-pixel
  smooth motion.
- Playfield grid: x 0–31, y 0–11 (**row 11 is off screen**; only 0-10 show).
- To line sprites up with playfield cells, use the measured mapping in
  sprites.md rather than guessing: a sprite's **last** scanline is
  `2*y + 9` (y anchors the bottom, whatever the sprite's height), its
  edges are `x-1` and `x+6`, playfield row `r` spans scanlines
  `9+16r .. 24+16r`, and column `c` spans x `16+4c .. 19+4c`. So a sprite
  stands on row `r` at `y = 8*r`, and the cell under its feet is `y/8`.

**Syntax that differs from BASIC**
- Labels: no colon. `mylabel` not `mylabel:`
- `=` is both assignment and equality test; `==` is an error. `<>` is
  not-equal.
- Compound conditions: `&&` (AND), `||` (OR, max ONE per if), `!` (NOT).
  The words AND/OR/NOT are not operators.
- All ifs are single-line: `if a = 5 then label` or
  `if a = 5 then b = b + 1`. There is no `endif`.
- `then` may be followed by a statement, goto, gosub, or label only.
- `on x goto label1 label2 ...` is 0-based (x = 0 → first label) **and
  unchecked** — an x past the last label jumps somewhere undefined and kills
  the program (black screen, no error). For a 1-based type/state variable,
  pad index 0 with a do-nothing label.
- One-line `:` separators exist but keep them out of if-then lines except
  carefully (see flow-control.md).
- `dim` can only alias a whole variable: `dim _Flag = a{0}` fails with
  `Not enough args passed to Macro` from a generated include. Alias the
  byte and write `a{0}` at each use. A bit can only be assigned a literal
  0/1 or another bit — `a{0} = table[i]` emits `AND #65536`.
- `set smartbranching on` always — prevents "branch out of range" errors.
- `gosub`/`return` nesting: max ~5 levels deep (6 crashes; stack limit).
- Random: `rand` (0–255, changes every call), ranges via `rand & 15`
  (0–15), `rand / 32` (0–7), etc. Never use `rand = rand` to reseed.

**Interaction**
- Joystick: `if joy0up then ...` — joy0up/down/left/right/fire (and joy1*)
  are true while held; diagonals combine automatically.
- `collision(player0,playfield)` / `(player0,player1)` /
  `(missile0,player1)` / `(player0,ball)` etc. — valid only immediately
  AFTER a drawscreen (before the next one).
- Console switches: switchreset, switchselect, switchbw, switchleftb,
  switchrightb (true while held; Atari convention: RESET starts game).
- Start new games with a reset-switch wait loop (see getting-started.md).

**Score & sound**
- `score = score + 100` works (decimal constants). `if score < x` does NOT
  work (BCD) — compare via `score + 0` byte reads or a separate variable.
- Sound: 2 channels; `AUDV0 = 8 : AUDC0 = 12 : AUDF0 = 10` then drawscreen;
  silence = `AUDV0 = 0`. Effects via data tables (sound.md).

**Kernels**
- Default = standard kernel. `set kernel multisprite` (virtual sprites
  player2–5, no missiles, mirrored playfield) or `set kernel DPC+` (10
  objects, needs Harmony/emulator) change MANY rules — read
  kernels-and-memory.md before using them.

## Reference routing

Read only what the task needs (each file has a contents list at top):

| Task | Read |
|---|---|
| Install the toolchain (wasm or native), cross-platform | `references/installation.md` |
| First game, program structure, title/game-over screens | `references/getting-started.md` |
| Variables, dim, const, bit ops, fixed point, rand, data | `references/variables-and-data.md` |
| goto/gosub/if-then/on-goto, smartbranching | `references/flow-control.md` |
| Sprites, missiles, ball, NUSIZ, animation, movement | `references/sprites.md` |
| Playfield drawing, pfpixel/pfhline/pfvline, pfscroll | `references/playfield.md` |
| Colors, COLUxx registers, color values | `references/colors.md` |
| collision(), joystick, switches, paddles | `references/collision-and-input.md` |
| Score, lives bars, health bars, BCD | `references/score-and-lives.md` |
| Sound effects and music | `references/sound.md` |
| Ready-made sound effects (117, indexed, with data) | `references/sound-effects-library.md` |
| Kernels, kernel_options, romsize, bankswitching, superchip | `references/kernels-and-memory.md` |
| Compile errors, blank screen, timing, silent runtime failures | `references/troubleshooting.md` |
| Inline `asm` blocks, TIA registers, memory map, cycle budgets, assembly tutorials | `references/inline-asm-and-machine.md` |
| Run/test the ROM headless or for a human (gopher2600, Stella, javatari.js, ALE) | `references/running-in-an-emulator.md` |
| Complete programs to copy from | `examples/README.md` + `examples/*.bas` |
| Build, headless-test & browser-page helper scripts | `scripts/README.md` |

## Running the ROM

The `.bin` runs in any Atari 2600 emulator or on real hardware via flash
cart (Harmony). Full walkthrough with verified commands:
`references/running-in-an-emulator.md`.

**Run GUI-capable emulator commands under `timeout`** (e.g.
`timeout 30 stella game.bas.bin`). Stella and gopher2600 open a blocking
SDL window in interactive mode; a mis-flag or a real display will hang the
shell until killed. `timeout` guarantees a hung GUI can't stall the agent.

- **gopher2600** (agent testing, no display): single pre-compiled Linux
  binary from GitHub releases; `HEADLESS` mode runs scripted input and
  saves PNG screenshots with zero X server — the best way to verify a
  game actually renders and responds. Check for a binary the project
  already ships (`ls ./gopher2600`), then `scripts/get-gopher2600.sh`. That
  fetches the `pansapiens/Gopher2600` fork (master), which fixes a wrong
  `HELP STICK` (upstream says the argument is `0` or `1`; it is really the
  `LEFT`/`RIGHT` port) and makes `SCREENSHOT` write the raw **160x214 TIA
  frame** (unscaled, one pixel per TIA cell) instead of the GUI's 1026x700
  render. Emulation is upstream's; `BB_GOPHER2600_UPSTREAM=1` opts out.
  **Never clone or `go build` the source to look up syntax** — run
  `HELP <CMD>` inside HEADLESS mode instead. Joystick input is
  `STICK <LEFT|RIGHT-port> <ACTION>`, e.g. `STICK LEFT UP` for player 0 up;
  a one-argument `STICK LEFT` is a port with no action, not a leftward push.
  Check rejected commands with `grep '^\*'` on the emulator's **stdout** —
  the debugger prefixes errors with `*` and never says "error".
- **Stella** (reference emulator): `stella game.bas.bin` — arrows move,
  Left Ctrl or Space fires, F2 = console RESET, F1 = SELECT, F12 =
  screenshot. `stella -rominfo rom.bin` works fully headless. Full option
  list: `stella -help`. _Footnote: single-dash flags only — `--help` is
  not a valid flag and opens the interactive GUI instead of printing help;
  `pkill stella` if a window pops up._
- **ALE** (`ale-py`): headless RL interface with RGB frame observations
  if you need an agent policy to play/score the game. Name the .bas
  after a supported game from the beginning (default `adventure.bas`;
  bB emits `adventure.bas.bin`, copy to `adventure.bin` for ALE).
- **javatari.js** (browser, zero install): drag & drop the .bin, or serve
  the standalone release and open `http://localhost:PORT/?ROM=game.bas.bin`
  for an auto-loading playable link to hand a human. It can also be
  embedded in your own HTML page (`<div id="javatari-screen">` + one
  script tag). Two traps: ROM paths resolve relative to **the page's URL**
  (not the script's), and a wrong one fails silently on the loading
  screen; and the page **must be served over http** — over `file://` the
  browser blocks the ROM fetch and javatari reports the misleading
  `Could not load file: game.bas.bin / Error: 0`, which is an XHR status
  of zero, not a path problem. A third trap costs nothing to pre-empt:
  set `Javatari.PADDLES_MODE = 0` on the page, or javatari may infer
  paddles from the ROM's filename and silently ignore the arrow keys.
  `scripts/bb-serve.sh` and `scripts/bb-page-check.py` check all three.
  Details in `references/running-in-an-emulator.md`.

## Advice for games that actually work

- Start from `examples/ex_move_sprite.bas` (movement) or the skeleton
  above; add one feature, compile, repeat.
- Prefer simple patterns that compile: single-line ifs, separate movement
  checks per direction, collision checks right after drawscreen.
- Watch "bytes of ROM space left" when adding playfields/data; switch to
  bigger romsize before you run out.
- When output must be verified but no emulator is available: compile
  success + ROM size (power of 2, boot bytes `78 D8` for standard kernel)
  is the practical check. Never ship a .bas that hasn't compiled.

## Bankswitched-game bug catalogue (from 117-commit SMB project)

Discovered building an 8-level Super Mario Bros demake in 32K. Each
entry was empirically confirmed — some cost hours. Violating these
produces code that **compiles cleanly** and then fails at runtime.

1. **Never `goto` to a label inside a `for-next` loop.** The generated
   branch table corrupts the loop's return path — execution escapes to
   un-assembled ROM (observed: PC at an address with no code, game
   hangs, screen goes black). The goto-free pattern is safe: pairs of
   `if cond then statement` inside the for-next, with no labels.
   Proof: `for j = 0 to 31 : if u{0} then pfpixel j 0 on : next` runs
   millions of times in the shipped game. The equivalent with a
   `goto __skip` inside = wild jump.

2. **Bank 8 is broken for cross-bank gosubs AND table reads.** bB's
   trampoline doesn't generate for bank 8 targets. Data placed in bank 8
   resolves to wrong addresses when read from other banks. Bank 8 is
   kernel-only — put ALL user code and data in banks 1–7.

3. **Deleting a `bank N` statement renumbers every subsequent bank.**
   If you remove `bank 3` to relocate code, the compiler silently maps
   what was bank 4 to bank 3, etc. — every `gosub X bank4` now targets
   the wrong code. Always replace the statement with a stub, never
   delete it.

4. **`if a then b : c` — statement c is unconditional.** The colon
   extends past the if. `if x = 5 then _gstate = 3 : _sfx = 1` plays
   the sfx every frame regardless of x. Flatten to separate lines or
   use if/goto pairs.

5. **Data tables must be in the same bank as the reading code.** A
   `for i = 0 to N : if _table[i] = x ...` in bank 4 reading a table
   in bank 2 silently reads garbage (wrong address space). This is
   absolute — no cross-bank table access exists in bB.

6. **`def` bit aliases share the parent variable.** If `dim _flags = e`
   and `def _lvl2 = e{5}`, then `_duck = 0` (another e{5} alias) clears
   your level flag. Audit ALL bit definitions for shared parent vars.

7. **Signed/unsigned comparison confusion in movement clamps.**
   `if _vyi > 5` clamps 252 (= -4) to 5 — breaking upward velocity.
   Use bit tests for sign: `if _vyi{7}` = negative, `if !_vyi{7}` =
   positive. Only compare magnitudes after confirming sign.

8. **The gopher2600 debugger's `PEEK` reads kernel scratch mid-frame**
   for player0x/player0y and TIA registers. A PEEK of player0x at a
   frame boundary can show stale/garbage data. Verify positions from
   SCREENSHOTs, not position peeks, when values look impossible.

9. **pfpixel/pfread clobber temp1–temp6.** Never keep loop counters or
   computed values in temps across a pfpixel call. Recompute after,
   or store in a user variable (a–z).

10. **pfscroll's injected column needs direct var writes.** After
    `pfscroll left`, the incoming column's bits are set via
    `varN = varN | 128` (or `& 127` to clear) — NOT via pfpixel, which
    would work but is ~40 bytes slower per column.

11. **`set tv pal60` compiles byte-identical to `set tv pal`.** The
    50/60Hz distinction is handled by the console/flash cart at runtime.
    Ship one PAL ROM for both.

12. **The `dim` and `def` statement count affects RAM allocation.**
    Every `def` creates a bit alias; every `dim` a byte alias. With all
    26 vars used (a–z), adding aliases for existing vars is free but
    new `dim` entries for unused letters will fail at compile time
    ("no more variables").
