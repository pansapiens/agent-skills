# Running a compiled game in an emulator

How to actually run, screenshot, and test the `.bas.bin` ROMs this skill
produces — headless (agent) and interactive (human).

Quick pick by goal:

| Goal | Use |
|---|---|
| Agent tests/screenshots with **no display at all** | gopher2600 `HEADLESS` (below) |
| Agent plays game with scripted joystick input | gopher2600 `HEADLESS` (`STICK`, `PANEL` commands) |
| Agent needs RL interface / observation arrays | ALE (below) |
| Inspect a ROM (mapper, size, controllers) headless | `stella -rominfo rom.bin` |
| Human plays your game, zero install | javatari.js (browser link, below) |
| Browser page shows `Error: 0` or an endless loading screen | javatari.js embedding traps (below) |
| Browser game ignores the arrow keys / moves on A and Space | javatari paddle-mode guess (below) |
| Human plays, native | Stella or gopher2600 GUI on a desktop |

> **Safety: wrap any GUI-capable emulator command in `timeout`.**
> Stella and gopher2600 both open a **blocking** SDL window in their
> default interactive mode. If a command runs on a machine with a display —
> or you mis-flag it so it falls back to the GUI (e.g. `stella --help`) —
> it will block the shell until killed, stalling the agent indefinitely.
> Prefix the command with a timeout so a hung GUI can't hold the turn:
> `timeout 30 stella game.bas.bin`. The headless paths below (gopher2600
> `HEADLESS`, `stella -rominfo`, the Xvfb screenshot loop) are already
> self-bounding, but `timeout` is a cheap safety net there too. Use a
> larger value (e.g. `timeout 120`) only for a legitimately long run.

---

## gopher2600 — recommended agent testbed

https://github.com/jetsetilly/gopher2600 (Go, GPL3, actively maintained).
**Pre-compiled single Linux binary** — no build, no Rust toolchain, no
display server needed for HEADLESS mode:

```bash
# FIRST: look for a binary the project already has. Most repos that use this
# skill keep one at the repo root. Only download if this finds nothing.
ls ./gopher2600 ../gopher2600 2>/dev/null || command -v gopher2600

scripts/get-gopher2600.sh     # preferred: caches outside any git tree,
                              # prints the path, picks the right build
```

`scripts/get-gopher2600.sh` fetches **https://github.com/pansapiens/Gopher2600**,
a fork carrying one documentation fix, because upstream's `HELP STICK` and
`HELP KEYPAD` are wrong in a way that costs hours:

> upstream: *"Specify the player with the 0 or 1 arguments."*

`STICK 0 RIGHT` is rejected (`* unrecognised argument (0)`). Both commands take
`[LEFT|RIGHT]` — the console **port**, LEFT being Player 0 — and upstream's
help never says so, which leaves the first argument looking like a direction.
The fork says so explicitly. **Emulation is upstream's, unchanged**; only help
strings differ, so anything you learn here applies to upstream too.

```bash
BB_GOPHER2600_UPSTREAM=1 scripts/get-gopher2600.sh   # upstream release instead
BB_GOPHER2600=/path/to/gopher2600                    # or point at your own
```

The fork's `master` carries the fix, and its releases are built from `master`
by `.github/workflows/release-linux.yml` on any pushed `v*` tag — so
`releases/latest/download/` always has a current binary. Tags are named
`<upstream version>-pansapiens.<n>` (e.g. `v0.58.0-preview-pansapiens.2`):
the upstream version the source came from, plus a fork-owned counter.

Two costs to know about. The fix is **not yet submitted upstream**, and the
fork tracks upstream *master* (`v0.58.0-preview`) rather than the last tagged
release, so it is slightly less battle-tested than upstream's binary. Use the
upstream override if that matters more to you than the help text. Downloading
by hand also works:

```bash
curl -sfL -o gopher2600 \
  https://github.com/pansapiens/Gopher2600/releases/latest/download/gopher2600_linux_amd64
chmod +x gopher2600
./gopher2600            # no args → launches the SDL GUI (RUN mode); NOT a help menu
./gopher2600 --help     # prints the execution modes: RUN DEBUG HEADLESS DISASM ...
```

> **Never `git clone` or `go build` the gopher2600 source to work out command
> syntax.** The binary documents itself — `HELP` and `HELP <CMD>` inside
> HEADLESS mode print the authoritative usage string (see below). Cloning the
> repo to grep `.go` files is a dead end that has burned dozens of turns in
> past sessions. `strings ./gopher2600` is also useless — Go binaries
> concatenate string constants, so the output is unparseable soup.

### Ask the emulator, don't guess

Any time a HEADLESS command doesn't behave as expected, get the real usage
string from the binary before experimenting:

```bash
{ sleep 1; echo "HELP"; sleep 1; echo "QUIT"; } | ./gopher2600 HEADLESS "$ROM"
{ sleep 1; echo "HELP STICK"; sleep 1; echo "QUIT"; } | ./gopher2600 HEADLESS "$ROM"
```

`HELP STICK` ends with an exact `Usage:` line. Trust it over any recipe,
including this document — the binary is the source of truth and its syntax
can change between releases.

### HEADLESS mode (verified recipe)

`HEADLESS` loads a ROM and reads **debugger commands from stdin**, one per
line. You drive the game frame-by-frame, inject controller input, and save
PNG/JPEG screenshots — a full gameplay smoke test with no display server.

**The reliable pattern is a command *script file***, not raw piped lines.
Commands typed directly on stdin are flaky: a command issued immediately
after one that runs the emulation (`STEP`/`GOTO`/`RUN`) gets swallowed. The
`SCRIPT` command reads a whole file, so nothing is dropped:

```bash
# 1. write a command script (absolute paths everywhere)
STEPS=/tmp/steps.txt
{ for i in $(seq 1 300); do echo "STEP FRAME"; done   # advance 300 frames
  echo "SCREENSHOT /abs/path/shot.png"                # save a frame
  echo "QUIT"; } > "$STEPS"

# 2. run it. sleep 2 lets the emulator init before we send SCRIPT;
#    sleep 4 gives the script time to finish before QUIT
{ sleep 2; echo "SCRIPT $STEPS"; sleep 4; echo "QUIT"; } \
    | ./gopher2600 HEADLESS /abs/path/game.bas.bin
```

300 frames ≈ 5 s of game time; the whole thing runs in a second or two. DPC+
ROMs work. `SCREENSHOT` must be issued when the emulator is past the first
scanline of a new frame (not mid-frame) or you get a black image.

#### The command vocabulary (verified)

```
STEP FRAME            # advance exactly one frame (repeat to play)
SCREENSHOT /abs/p.png # save the current frame (also .jpg)
PANEL HOLD SELECT     # hold a console switch: SELECT or RESET
PANEL RELEASE SELECT  # release it
STICK LEFT RIGHT      # player 0's stick pushed right (see STICK below)
STICK LEFT UP         # player 0's stick pushed up
TV                    # current frame / scanline / clock position
HELP [CMD]            # list commands, or detail one (e.g. HELP STICK)
QUIT                  # exit
```

#### `STICK` — the first argument is a PORT, not a direction

This is the single biggest time-sink in headless testing. `HELP STICK` gives
the exact grammar (and on an **upstream** binary, ignore its prose line
"Specify the player with the 0 or 1 arguments" — that form is rejected; the
fork this skill fetches has it corrected, but the `Usage:` line is right in
both):

```
Usage: STICK [LEFT|RIGHT] [LEFT|RIGHT|UP|DOWN|FIRE|NOLEFT|NORIGHT|NOUP|NODOWN|NOFIRE|SECOND|NOSECOND]
```

**Argument 1 is the console port — which player.** Argument 2 is the action.
`LEFT` appears in both lists, which is what makes this so easy to get wrong.

| Port arg | Console socket | bB variables |
|---|---|---|
| `LEFT`  | left port  = player 0 | `joy0up/down/left/right`, `joy0fire` |
| `RIGHT` | right port = player 1 | `joy1up/down/left/right`, `joy1fire` |

Verified by `PEEK 0x280` (SWCHA): `STICK LEFT LEFT` → `0xbf` (bit 6 clear =
P0 left); `STICK RIGHT LEFT` → `0xfb` (bit 2 clear = P1 left).

```
STICK LEFT UP         # P0 up        — almost every bB game uses joy0, so
STICK LEFT DOWN       # P0 down        nearly every command starts "STICK LEFT"
STICK LEFT LEFT       # P0 left
STICK LEFT RIGHT      # P0 right
STICK LEFT FIRE       # P0 fire button
STICK LEFT NOUP       # release P0 up (likewise NODOWN NOLEFT NORIGHT NOFIRE)
STICK RIGHT FIRE      # P1 fire button
```

**A one-argument `STICK` is rejected, and does nothing:**

```
STICK LEFT            # REJECTED: "* LEFT or RIGHT or UP or ... required".
                      # It selects the left port with no action; it does NOT
                      # push left. Nothing reaches the ROM.
STICK RIGHT           # same
STICK UP              # "* unrecognised argument (UP)" — UP is not a port
STICK 0 RIGHT         # "* unrecognised argument (0)" — use LEFT/RIGHT, not a
                      # player number
```

The emulator does tell you — but two habits make it easy to miss, and that is
how this ends up costing hours (see the error-checking section below). Always
pass two arguments.

- Input is **sticky**: it persists across every subsequent frame until you
  change it. `STICK LEFT RIGHT` then 100× `STEP FRAME` drives right the whole
  time — no need to re-issue.
- **Always release** with the matching `NO<dir>`. Because state is cumulative,
  `STICK LEFT RIGHT` followed by `STICK LEFT LEFT` holds *both* directions
  (net zero) until you send `STICK LEFT NORIGHT`. Directions you never release
  keep applying and will corrupt every later step of the test.
- `FIRE` needs no direction held first. Earlier notes claiming "`STICK FIRE`
  fails so fire needs a direction" misread the grammar: `STICK FIRE` fails
  because `FIRE` is not a *port*, and `STICK LEFT FIRE` works because `LEFT`
  is the port. It is a plain fire press on player 0.

#### Always check for `*` — the debugger's error prefix

Every rejected command prints a line starting with `* ` **on stdout**, and a
valid command prints nothing. That single rule catches every input mistake:

```bash
{ sleep 2; echo "SCRIPT $STEPS"; sleep 4; echo "QUIT"; } \
    | ./gopher2600 HEADLESS "$ROM" 2>/dev/null | grep '^\*' \
    && echo "^^ commands were REJECTED — the ROM never saw that input" \
    || echo "no command errors"
```

Two habits will hide these messages from you, and together they are what turns
a one-line typo into an afternoon of debugging the wrong thing:

- **`>/dev/null 2>&1` on the emulator call.** Tempting, because HEADLESS is
  chatty. It also throws away every error. Discard *stderr* if you must
  (`2>/dev/null`), never stdout.
- **Grepping for the word "error".** The debugger never uses it. Real messages
  read `* unrecognised argument (UP)`, `* unrecognised command (FOO)`, and
  `* LEFT or RIGHT or UP or ... required`. A `grep -iE "unrecognised|error"`
  misses the whole "... required" family — which is exactly what a
  one-argument `STICK` produces. Match `^\*` instead.

If a scripted input appears to do nothing, check for `*` lines *before* you
touch the game's input handling. The command was probably never accepted.

#### Worked example — start a game, drive, and verify

A complete headless test of a game that shows a title screen, starts on
`SELECT`, and moves a player with the stick. This is the pattern to copy:

```bash
ROM=/abs/path/game.bas.bin
STEPS=/tmp/steps.txt
{
  for i in $(seq 1 60); do echo "STEP FRAME"; done        # let the title screen settle
  echo "SCREENSHOT /tmp/title.png"                        # capture the title screen
  echo "PANEL HOLD SELECT"                                # press start
  for i in $(seq 1 6);  do echo "STEP FRAME"; done
  echo "PANEL RELEASE SELECT"
  for i in $(seq 1 30); do echo "STEP FRAME"; done        # gameplay begins
  echo "SCREENSHOT /tmp/play.png"                         # capture gameplay
  echo "STICK LEFT RIGHT"                                 # P0 (left port) pushes right
  for i in $(seq 1 60); do echo "STEP FRAME"; done        # drive for ~1 s
  echo "SCREENSHOT /tmp/move.png"                         # capture after input
  echo "STICK LEFT NORIGHT"                               # ALWAYS release; input is sticky
} > "$STEPS"
{ sleep 2; echo "SCRIPT $STEPS"; sleep 4; echo "QUIT"; } \
    | ./gopher2600 HEADLESS "$ROM" 2>/dev/null | grep '^\*' || echo "no command errors"
```

Verify by diffing the screenshots (PIL): `title` vs `play` should differ
(the game started), and `play` vs `move` should differ (the player responded
to input):

```bash
python3 - <<'PY'
from PIL import Image, ImageChops
def d(a,b):
    a=Image.open(a).convert('RGB'); b=Image.open(b).convert('RGB')
    if a.size!=b.size: return -1
    h=ImageChops.difference(a,b).convert('L').histogram()  # 256 intensity bins
    return sum(h[21:])  # count pixels that changed by more than ~20
print('title vs play :', d('/tmp/title.png','/tmp/play.png'), 'px changed (start worked)')
print('play  vs move :', d('/tmp/play.png','/tmp/move.png'), 'px changed (input worked)')
PY
```

Other useful HEADLESS commands: `TV` (frame/scanline position), `MEM`,
`PEEK`/`POKE`, `CPU`, `TIA`, `DISASM`, `BREAK`/`TRAP`/`HALT`, `PANEL`,
`KEYPAD`, `HELP`.

Caveats (verified):
- `GOTO <clock> <scanline> <frame>` does NOT work for screenshots (renders
  black); use repeated `STEP FRAME`.
- A command piped immediately after a running command (STEP/GOTO/RUN) can
  be swallowed — the `SCRIPT` recipe above avoids this.
- `STICK` needs **two** arguments: `<PORT> <ACTION>`, e.g. `STICK LEFT UP`.
  A player number (`STICK 0 RIGHT`) is rejected, and a lone `STICK LEFT` is
  accepted but does nothing. See the STICK section above.
- GUI modes (`RUN`, `DEBUG`) panic under Xvfb (`divide by zero` on the
  0 Hz refresh rate Xvfb reports) — GUI needs a real desktop display. For
  headless CI, `HEADLESS` is the only mode that works without a display.

### Human play (desktop)

`./gopher2600 RUN game.bas.bin` — SDL GUI with debugger, rewind, etc.

---

## Stella — the reference emulator

https://github.com/stella-emu/stella. Often packaged: `sudo apt install
stella` (Ubuntu 24.04 ships 6.7.1 — what most bB users test against).

Get the full option list with **`stella -help`**.

> _Footnote: Stella uses single-dash flags, not `--flag`. `--help` is not
> a valid flag, so `stella --help` is read as a ROM filename and opens the
> interactive GUI launcher instead of printing help — if a Stella window
> pops up, `pkill stella` to close it. All options below use one dash._

### Useful CLI options (full list: `stella -help`)

```bash
stella game.bas.bin            # play: arrows, Left Ctrl/Space fire,
                               # F1 SELECT, F2 RESET, F12 screenshot
stella -rominfo game.bas.bin   # print mapper/format/MD5/controllers —
                               # works fully headless, exits immediately
stella -holdreset game.bas.bin # power on with RESET held (automation)
stella -holdselect game.bas.bin
stella -holdjoy0 F game.bas.bin   # start with P1 fire held (U/D/L/R/F)
stella -video software game.bas.bin  # SDL software renderer (Xvfb-safe)
stella -snapsavedir DIR game.bas.bin # where F12 screenshots are written
stella -basedir DIR game.bas.bin     # keep config out of ~ (sandboxing)
```

### Headless screenshot via Xvfb (verified)

Stella always opens a window, but runs fine under Xvfb; send F12 with
xdotool:

```bash
export DISPLAY=:95
Xvfb :95 -screen 0 1024x768x24 & XVFB=$!
sleep 1
stella -video software game.bas.bin & STELLA=$!
sleep 5                                   # let the game reach gameplay
xdotool search --onlyvisible --name "Stella" key --window %1 F12
sleep 1
kill $STELLA $XVFB 2>/dev/null
# PNG lands in -snapsavedir (or the ROM's directory), named after the ROM
```

Headless automation (`-holdreset`, `-holdjoy0`) plus this screenshot loop
is enough for scripted smoke tests when gopher2600 isn't available.

### Building Stella from source (verified, Ubuntu 24.04)

- **Master now requires SDL3**, which Ubuntu 24.04 doesn't package —
  build the latest SDL2-era release instead:
  `git clone --depth 1 --branch 6.7.1 https://github.com/stella-emu/stella.git`
- Dependencies: `libsdl2-dev libpng-dev zlib1g-dev libsqlite3-dev`
  (plain build: `./configure --prefix=$PWD/install && make -j$(nproc) &&
  make install`).
- If `configure` picks a **conda/Anaconda compiler** (e.g.
  `x86_64-conda-linux-gnu-c++`), force the system one — the conda sysroot
  clashes with Ubuntu glibc headers:
  `CXX=/usr/bin/g++ CC=/usr/bin/gcc ./configure ...`
- Ubuntu multiarch quirk: if compilation dies on
  `SDL2/_real_SDL_config.h: No such file or directory`, edit `config.mak`
  and change `-I/usr/include/SDL2` to
  `-I/usr/include/x86_64-linux-gnu -I/usr/include/SDL2`.

---

## ALE — Arcade Learning Environment (RL interface)

https://ale.farama.org (pip name `ale-py`, Stella-powered core). Fully
headless, no display server: gives you the frame buffer as a numpy RGB
array plus reward/lives signals — the right tool if you want an agent
(greedy/random/scripted policy) to *play* the game and score it.

```bash
# /// script
# requires-python = ">=3.10"
# dependencies = ["ale-py", "gymnasium", "numpy", "pillow"]
# ///
import gymnasium as gym, ale_py
gym.register_envs(ale_py)
env = gym.make("ALE/Pong-v5", obs_type="rgb", frameskip=4)
obs, info = env.reset(seed=42)
obs, reward, terminated, truncated, info = env.step(env.action_space.sample())
```

`obs` is the raw frame (NTSC: 210×160×3) — save with PIL, diff frames to
verify your game actually changes state, etc.

**Naming rule (do this from the start):** name the `.bas` file with a
snake_case stem matching a supported ALE game — default `adventure.bas`,
or a genre fit like `space_invaders.bas` / `breakout.bas` / `pong.bas`.
bB emits `<name>.bas.bin`, and ALE matches ROMs by exact lowercase stem,
so testing in ALE then needs just one copy: `cp adventure.bas.bin
adventure.bin`. Verified names and caveats: `references/running-in-an-emulator.md`.

### Running your own bB ROM in ALE (verified, with caveats)

```python
from ale_py import ALEInterface
ale = ALEInterface()
ale.loadROM("/path/adventure.bin")   # stem must match a KNOWN game name
for _ in range(240):
    ale.act(0)                            # 0 = NOOP; see getLegalActionSet()
img = ale.getScreenRGB()                  # numpy RGB frame
```

- ALE refuses unknown ROMs (`buildRomRLWrapper` matches only its ~103
  bundled games by MD5 **or lowercase filename stem**) and a mismatch
  kills the process (C-level `exit(1)`, no Python exception). Hence the
  naming rule above: `adventure.bas` → `adventure.bas.bin` → copy to
  `adventure.bin`.
- Verified-working stems for custom ROMs (ale-py 0.12.1): `adventure
  breakout freeway pong seaquest space_invaders tetris video_chess
  yars_revenge pitfall2` (`adventure` is the safe default). Names like
  `combat`/`warlords` have no wrapper and die instantly;
  `frogger`/`surround` hang (their wrappers wait for real-game state).
  `get_all_rom_ids()` is a superset — don't trust it for this.
- The reward/lives logic is then that of the *name-matched* game (wrong
  for your game) — only trust frames/observations/actions, not rewards.
- **No DPC+ support** (no ARM) — only standard-kernel and older
  bankswitched bB ROMs (2K/4K, F6/F8 etc.). DPC+ kernel games won't run.
- Actions include NOOP/fire/directions (`ale.getLegalActionSet()`), so
  scripted input sequences are easy.

---

## javatari.js (browser, no install — easiest for humans)

javatari.js (https://github.com/ppeccin/javatari.js, playable at
https://javatari.org) is a single-file HTML5 Atari 2600 emulator. Best
option for handing a human a playable link.

### Option A — drag & drop (zero setup)

```bash
git clone --depth 1 https://github.com/ppeccin/javatari.js.git
# open the standalone page in a browser, then drag game.bas.bin onto it:
xdg-open javatari.js/release/stable/5.0/standalone/index.html
```

### Option B — local server + auto-load link (repeatable)

The `?ROM=` URL parameter loads and powers on the console automatically
(ROM must be on the same server — browsers block cross-origin loads):

```bash
cd javatari.js/release/stable/5.0/standalone
cp /path/to/game.bas.bin .
python3 -m http.server 8600
xdg-open "http://localhost:8600/?ROM=game.bas.bin"
```

**`?ROM=` paths resolve relative to the HTML page's URL**, not to the
javatari.js script or the server root. In this example the page is the
server root's `index.html`, so `game.bas.bin` (same directory) is correct;
`roms/game.bas.bin` would also work if the ROM lived in a `roms/` subdir.

ROM format (4K, F8, F6, DPC+, ...) is auto-detected; to force one use
`&FORMAT=F6` etc. ZIPped ROMs are accepted too. Power-on happens ~1.2 s
after load (`AUTO_POWER_ON_DELAY`).

### Option C — embed in your own HTML page (verified)

The `embedded/javatari.js` build is one self-contained file — no images or
other assets needed. Any page with a `javatari-screen` div can host it:

```html
<!DOCTYPE html>
<html><head><title>My game</title></head>
<body>
<div id="javatari-screen"></div>
<script src="path/to/javatari.js"></script>
</body></html>
```

Minimum requirements (defaults, no config needed):

- The div **id must be `javatari-screen`** (`SCREEN_ELEMENT_ID` default).
- `ALLOW_URL_PARAMETERS` is true by default, so `?ROM=` works on your own
  pages exactly as on javatari.org.
- Serve over `http://` (or https) — see the `Error: 0` trap below.

Instead of `?ROM=`, a page can name its ROM in script. Set the config
**after** the javatari.js script tag; javatari defers its own init, so this
is read in time:

```html
<div id="javatari-screen"></div>
<script src="../javatari.js"></script>
<script>
  Javatari.CARTRIDGE_URL = "game.bas.bin";   // relative to THIS page
  Javatari.AUTO_START = true;
</script>
```

### `Error: 0` means file://, not a bad path

```
Could not load file: game.bas.bin
Error: 0
```

That dialog is the single most common javatari failure, and it is
**misleading**: it names the ROM, so it reads like a path bug. It is not.
Javatari fetches the cartridge with XHR, and browsers refuse XHR on
`file://` origins:

```
Access to XMLHttpRequest at 'file:///.../game.bas.bin' from origin 'null'
has been blocked by CORS policy: Cross origin requests are only supported
for protocol schemes: chrome, chrome-extension, data, http, https, ...
```

`Error: 0` is an XHR status of zero — the request never left the browser.
The number is a status code, not a path error. Double-clicking the HTML
file, or `xdg-open`ing it, always produces this however correct the path is.
Fix by serving the directory:

```bash
scripts/bb-serve.sh . 8600           # then http://localhost:8600/page.html
scripts/bb-page-check.py http://localhost:8600/page.html
```

Since a human will eventually open the page the wrong way, make the page
say so itself rather than letting the emulator report a bare error code:

```html
<script>
  if (location.protocol === "file:") {
    document.getElementById("javatari-screen").insertAdjacentHTML("beforebegin",
      "<p>Open this over http:// — the browser blocks ROM loading on file:// URLs.</p>");
  } else {
    Javatari.CARTRIDGE_URL = "game.bas.bin";
    Javatari.AUTO_START = true;
  }
</script>
```

Leaving `CARTRIDGE_URL` unset in the `file:` branch matters: javatari then
shows its normal "Select Cartridge / Open ROM File..." screen, so the reader
still has a way to play the game by hand.

**The `?ROM=` path is relative to YOUR page, not to javatari.js.** This is
the classic embedding mistake. Verified layout — page in `pages/`, ROM in
`roms/`, script at the root:

```
server-root/
├── javatari.js              # copied from release/stable/5.0/embedded/
├── pages/play.html          # your embedding page
└── roms/game.bas.bin
```

- Page URL: `http://localhost:8601/pages/play.html`
- Correct: `?ROM=../roms/game.bas.bin` (up from `pages/`, into `roms/`)
- WRONG: `?ROM=roms/game.bas.bin` — resolves to `/pages/roms/...`, a 404.
  The emulator then just sits on its loading screen — **no error dialog**,
  only a 404 in the browser console (F12) tells you why.
- Simplest fix: put the page and the ROM in the same directory and use
  `?ROM=game.bas.bin` (same rule as Option B).

Tested end-to-end with Chromium: page-relative `../roms/...` loads and
runs (verified by pixel-sampling the canvas); the missing-`../` form
stays white/loading with a silent 404.

`scripts/bb-page-check.py <page-url>` checks both of these for you — it
resolves the page's ROM reference the way the browser will and fetches it,
so a 404 or a `file://` URL is reported in one line instead of being found
by a human staring at a loading screen.

### javatari guesses the controller from the ROM's FILENAME

Symptom: the arrow keys do nothing, and the game is steered by **Space and
A** instead — two keys that are not a left/right pair on any layout. What
they actually are is the P1 and P2 *fire* buttons.

Cause: `Javatari.PADDLES_MODE` defaults to `-1`, meaning "auto". For a ROM
javatari does not recognise by hash — i.e. every ROM you compile — "auto"
resolves by matching the **filename** against a built-in list of ~65 paddle
game titles:

```js
if (!a.p && (a.p = 0, !e.match(l+"JOYSTICK(S)?"+m)))   // e = ROM name, uppercased
    if (e.match(l+"PADDLE(S)?"+m)) a.p = 1;
    else for (n = 0; n < j.length; n++) if (e.match(j[n])) { a.p = 1; break a }
```

A joystick remake named after a paddle original therefore boots in paddle
mode. The two paddle buttons sit on the *same SWCHA bits* as joystick right
and left:

```js
PADDLE1_BUTTON: case f.JOY0_LEFT:  return void(b ? k&=191 : k|=64)    // bit 6
PADDLE0_BUTTON: case f.JOY0_RIGHT: return void(b ? k&=127 : k|=128)   // bit 7
```

so `if joy0left` fires when the *paddle 1 button* (key `A`) is pressed and
`if joy0right` when the *paddle 0 button* (key `Space`) is. The arrow keys
are mapped to paddle motion instead and the game never sees them.

Patterns that trigger it include `BREAKOUT`, `WARLORDS`, `KABOOM`,
`CIRCUS.*ATARI`, `NIGHT.*DRIVER`, `STREET.*RACER`, `BUGS` (unless followed
by `BUNNY`), `CASINO`, `GUARDIAN`, `PICNIC`, `PIECE.*O.*CAKE`, and anything
containing `PADDLE`. Note **`breakout.bas` is one of them** — see the ALE
naming note in `SKILL.md`, which pulls the other way.

**Fix — pin the mode on the page rather than relying on auto:**

```js
Javatari.CARTRIDGE_URL = "game.bas.bin";
Javatari.PADDLES_MODE = 0;    // 0 = joysticks, 1 = paddles, -1 = guess (default)
```

Set it for *every* game, not just ones you think are affected — it costs one
line and removes a silent dependency on your choice of filename. If your
game really does read paddles, set `1` for the same reason. The alternative
escape hatch is the `JOYSTICK` check on the first line above: a ROM named
`game (Joystick).bin` is forced to joysticks. `scripts/bb-page-check.py`
warns when a page's ROM name would trip the heuristic and the page has not
pinned the mode.

The user-facing toggle, if someone hits this on a page you did not write, is
the emulator's own **Controllers: JOYSTICKS/PADDLES** item in the bar menu.

### Default keys

| Key | Action |
|---|---|
| Arrow keys | P1 joystick up/down/left/right |
| Space | **P1 fire** |
| T / G / F / H | P2 joystick up/down/left/right |
| A | **P2 fire** |
| F5 / F6 | load ROM from file / URL |
| F1 | console POWER (Shift+F1 = fry) |
| F2 | console B/W switch |
| F11 | console **SELECT** |
| F12 | console **RESET** |
| F4 / F9 | left / right difficulty switch |
| TAB | fast speed |
| Alt+P / Alt+F | pause / advance one frame |

The console switches are the ones to get right in your instructions, because
by Atari convention RESET is what starts a bB game (`if switchreset then
...`). **RESET is F12; F11 is SELECT** — verified from the key map, not from
javatari's menu labels. Telling a player "press F11 to start" sends them to
SELECT and the game appears not to respond.

Worth memorising the two fire keys: if a game responds to **Space and A but
not the arrows**, that is not a broken control scheme, it is paddle mode —
see the filename-heuristic section above.

Frame advance (`Alt+F`) is handy for debugging collision or animation
logic one frame at a time.

### Headless screenshot (optional smoke test)

```bash
chromium --headless --disable-gpu --screenshot=/tmp/shot.png \
  --window-size=900,700 --virtual-time-budget=5000 \
  "http://localhost:8600/?ROM=game.bas.bin"
```

Gives you a PNG of whatever the screen shows ~5 s in — enough to catch a
blank/black screen without any emulator install.

---

## Other emulators (investigated — not recommended)

All need building from source, ship no pre-compiled Linux binaries, and
have no headless/screenshot CLI:

- **rustella** (unrenormalizable/rustella) — clean-room no_std Rust core,
  wasm-hostable, non-commercial license; GUI/early stage, dormant since
  2024.
- **atari2600-rust** (sl4ureano/atari2600-rust) — active SDL windowed
  emulator, no headless mode.
- **vcsgo** (theinternetftw/vcsgo) — Go/ebiten GUI emulator, dormant
  since 2024.

For agent use, gopher2600 (single binary, HEADLESS screenshots + scripted
input) does everything these would.

---

## Notes for bB games in any emulator

- Press **F2 in Stella** / hold reset to test your reset-switch restart
  code; F1 for select-switch handling.
- bB title screens often wait for fire or reset — remember this when
  scripting input or taking early screenshots (advance ~60–300 frames
  first).
- Emulators are tolerant of timing overruns — if a game rolls or jitters
  in Stella, it will be worse on real hardware (see `troubleshooting.md`
  → Timing problems).
- When output must be verified but no emulator is available: compile
  success + ROM size (power of 2, boot bytes `78 D8` for standard kernel)
  is the practical check. Never ship a .bas that hasn't compiled.
