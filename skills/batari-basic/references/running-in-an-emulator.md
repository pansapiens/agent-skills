# Running a compiled game in an emulator

How to actually run and test the `.bas.bin` ROMs this skill produces.

Quick pick: **Stella** if installed (`stella game.bas.bin`) — otherwise
**javatari.js** runs in any browser with zero install, and its URL/`?ROM=`
auto-load makes it the easiest way to hand someone a playable link or to
eyeball your ROM from a headless agent session (serve + open, or screenshot).

## javatari.js (browser, no install)

javatari.js (https://github.com/ppeccin/javatari.js, playable at
https://javatari.org) is a single-file HTML5 Atari 2600 emulator.

### Option A — drag & drop (zero setup)

```bash
git clone --depth 1 https://github.com/ppeccin/javatari.js.git
# open the standalone page in a browser, then drag game.bas.bin onto it:
xdg-open javatari.js/release/stable/5.0/standalone/index.html
```

The emulator starts as soon as the ROM is dropped. This works from a plain
local file — no web server needed.

### Option B — local server + auto-load link (repeatable, agent-friendly)

The `?ROM=` URL parameter loads and powers on the console automatically
(ROM must be on the same server — browsers block cross-origin loads):

```bash
cd javatari.js/release/stable/5.0/standalone
cp /path/to/game.bas.bin .
python3 -m http.server 8600
xdg-open "http://localhost:8600/?ROM=game.bas.bin"
```

ROM format (4K, F8, F6, DPC+, ...) is auto-detected; to force one use
`&FORMAT=F6` etc. ZIPped ROMs are accepted too. Power-on happens ~1.2 s
after load (`AUTO_POWER_ON_DELAY`).

### Embedding in your own page

```html
<script src="javatari.js"></script>
<div id="javatari-screen"></div>
<script>
  Javatari.CARTRIDGE_URL = "game.bas.bin";  // set AFTER loading javatari.js
</script>
```

### Default keys (P1)

| Key | Action |
|---|---|
| Arrow keys | joystick up/down/left/right |
| Space | fire |
| F5 / F6 | load ROM from file / URL |
| TAB | fast speed |
| Alt+P / Alt+F | pause / advance one frame |

Frame advance (`Alt+F`) is handy for debugging collision or animation
logic one frame at a time. If Space+arrow diagonal presses ghost on your
keyboard, remap fire (or use a gamepad) — same rollover issue as any emulator.

### Headless screenshot (optional smoke test)

```bash
chromium --headless --disable-gpu --screenshot=/tmp/shot.png \
  --window-size=900,700 --virtual-time-budget=5000 \
  "http://localhost:8600/?ROM=game.bas.bin"
```

Gives you a PNG of whatever the screen shows ~5 s in — enough to catch a
blank/black screen. Real gameplay testing still needs a human or scripted
input; compile success + screenshot is the practical automated bar.

## Stella (native, best for testing)

Check availability first: `which stella`. If missing: `sudo apt install
stella` (Debian/Ubuntu package `stella`).

```bash
stella game.bas.bin      # run the game
stella -holdreset game.bas.bin   # power on with RESET held (automation)
```

| Key | Action |
|---|---|
| Arrow keys | P1 joystick |
| Left Ctrl or Space | P1 fire |
| F1 / F2 | console SELECT / RESET switches |
| F3 / F4 | color / black-and-white switch |
| F9 / F10 / F11 | save state / slot / load state |
| F12 | PNG screenshot (saved to ROM dir or as configured) |
| Escape | exit to launcher |

Notes for bB games: press **F2** to test your reset-switch restart code,
F1 to exercise select-switch handling, F12 to grab screenshots for a
gallery. Emulators are tolerant of timing overruns — if a game rolls or
jitters in Stella, it will be worse on real hardware (see
`troubleshooting.md` → Timing problems).
