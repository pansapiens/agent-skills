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
curl -sfL -o gopher2600 \
  https://github.com/jetsetilly/gopher2600/releases/latest/download/gopher2600_linux_amd64
chmod +x gopher2600
./gopher2600            # no args → launches the SDL GUI (RUN mode); NOT a help menu
./gopher2600 --help     # prints the execution modes: RUN DEBUG HEADLESS DISASM ...
```

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
STICK RIGHT           # hold P1 stick right  (see STICK notes below)
STICK LEFT            # hold P1 stick left
TV                    # current frame / scanline / clock position
HELP [CMD]            # list commands, or detail one (e.g. HELP STICK)
QUIT                  # exit
```

**`STICK` — verified syntax** (the in-emulator `HELP STICK` text is
misleading; these are the forms that actually work):

```
STICK RIGHT           # 1-token form: must be LEFT or RIGHT
STICK LEFT
STICK RIGHT FIRE      # 2-token form: <LEFT|RIGHT> <state>
STICK RIGHT UP        #   2nd token ∈ LEFT RIGHT UP DOWN FIRE
STICK RIGHT NORIGHT   #   or a release: NOLEFT NORIGHT NOUP NODOWN NOFIRE
```

- **No player number** — `STICK 0 RIGHT` errors with `unrecognised argument
  (0)`. Just `STICK RIGHT`.
- A **lone** token must be `LEFT` or `RIGHT`; `UP`/`DOWN`/`FIRE`/`NO*` must
  be the **second** token (paired with a `LEFT`/`RIGHT`). Three or more
tokens are rejected.
- Input is **sticky**: it persists across all subsequent frames until you
  issue another `STICK`. So `STICK RIGHT` then 100× `STEP FRAME` drives the
  car right the whole time — no need to re-issue it.
- To **release** a direction, use its `NO<dir>` form (e.g. `STICK RIGHT
  NORIGHT`). Because input is cumulative, a held direction you don't release
  keeps applying — e.g. `STICK RIGHT` then `STICK LEFT` holds *both* (net
  zero) until you `NORIGHT`.

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
  echo "STICK RIGHT"                                      # hold right
  for i in $(seq 1 60); do echo "STEP FRAME"; done        # drive for ~1 s
  echo "SCREENSHOT /tmp/move.png"                         # capture after input
} > "$STEPS"
{ sleep 2; echo "SCRIPT $STEPS"; sleep 4; echo "QUIT"; } \
    | ./gopher2600 HEADLESS "$ROM" 2>&1 | grep -iE "unrecognised|error" || echo "no command errors"
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
- `STICK` with a player number (`STICK 0 RIGHT`) or 3+ tokens is rejected;
  see the STICK notes above.
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

### Default keys (P1)

| Key | Action |
|---|---|
| Arrow keys | joystick up/down/left/right |
| Space | fire |
| F5 / F6 | load ROM from file / URL |
| TAB | fast speed |
| Alt+P / Alt+F | pause / advance one frame |

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
