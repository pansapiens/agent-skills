# batari Basic Playfield Reference

Everything about the bB playfield: drawing it with `playfield:` … `end`, the plotting commands (`pfpixel`, `pfhline`, `pfvline`), clearing (`pfclear`), scrolling (`pfscroll`, `playfieldpos`), reading pixels (`pfread`), resolution controls (`pfres`, `pfrowheight`), colors (`COLUPF`, `COLUBK`, `pfcolors`, `pfheights`, `background`), and DPC+ kernel differences.

**Contents:** [Overview & coordinate system](#playfield-overview-and-coordinate-system) · [Pixel size vs sprites](#playfield-pixel-size-compared-to-sprite-pixels) · [playfield: block](#playfield--end-defining-a-full-screen) · [var0-var47](#playfield-variables-var0var47-and-the-reversed-byte-gotcha) · [pfclear](#pfclear) · [pfpixel](#pfpixel) · [pfhline](#pfhline) · [pfvline](#pfvline) · [pfscroll](#pfscroll) · [playfieldpos](#playfieldpos) · [pfread](#pfread) · [Colors: COLUPF/COLUBK](#playfield-and-background-colors-colupf--colubk) · [pfcolors option](#pfcolors-kernel-option-per-row-colors) · [pfheights option](#pfheights-kernel-option-per-row-heights) · [background option](#background-kernel-option) · [pfres](#pfres-playfield-resolution) · [pfrowheight](#pfrowheight) · [Making pixels smaller](#making-playfield-pixels-smaller) · [Maze examples](#maze-examples) · [DPC+ kernel](#dpc-kernel-playfield) · [Common mistakes](#common-mistakes)

**Big bB vs normal BASIC differences:** the "graphics screen" is one shared playfield of chunky blocks, commands like `pfpixel 16 2 on` are statements (not functions), `playfield:` is a data block (not an assignment), and `pfread(x,y)` may **only** be used inside an `if…then`.

## Playfield overview and coordinate system

The playfield is the blocky background behind the sprites. In the standard kernel you get a 32 x 11 bitmapped, **asymmetric** playfield — 32 x 12 if you count the hidden row that is only seen if scrolled. Coordinates:

- **x (xpos): 0-31**, left to right, one playfield pixel per x value.
- **y (ypos): 0-11** — rows 0-10 are visible; **row 11 is hidden off the bottom of the screen and only appears if you scroll** (it is "scrolled in" by `pfscroll up`/`down`).
- If you use Superchip RAM with `pfres`, or the DPC+ kernel, you can have more than 11 rows (the multisprite kernel has its own rules — see below).

Screen coverage quirks (all kernels of the 2600 hardware):

- Vertically, the playfield spans the whole screen except the area reserved for the score.
- Horizontally, the playfield only uses the **center 80%** of the screen (timing constraints). You have limited access to the left and right 10%: you can only draw full-height vertical lines there. For example `PF0 = 128` (`%10000000`) puts a thin border next to the playfield on both sides; `PF0 = %11110000` gives a 4-column-thick border. PF0 is write-only and must be set inside your main loop (see the PF0 section of the bB manual).

A normal BASIC programmer expects a pixel-addressable bitmap everywhere; here rows are 8 scanlines tall by default, the screen edges are off-limits, and everything must be redrawn by `drawscreen` inside your main loop.

## Playfield pixel size compared to sprite pixels

A playfield pixel is **as wide as a sprite that is 4 pixels wide** and, at the default row height, **about as tall as a sprite that is 8 pixels tall**. So each playfield "pixel" is roughly a 4 x 8 sprite-sized rectangle (wide and squat), not a square. Ways to shrink or square them up: `pfrowheight`, `pfres`, the `pfheights` kernel option, `pfheight` (multisprite kernel), Superchip RAM, or the DPC+ playfield resolution — see [Making playfield pixels smaller](#making-playfield-pixels-smaller).

## playfield: … end (defining a full screen)

Defines an entire playfield screen at once. Syntax (bB indents the block 3 spaces; each row is exactly 32 characters of `X` = on and `.` = off in the standard kernel):

```
playfield:
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   X..............................X
   X...XXXXXXXXXX....XXXXXXXXXX...X
   X...X......................X...X
   X...X......................X...X
   X...X......................X...X
   X..............................X
   X..............................X
   X...XXXX....XXXXXXXX....XXXX...X
   X..............................X
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
end
```

- Each line is one playfield row; row 0 (the first line) is the top. Use exactly **32 characters per line** in the standard kernel.
- `X` = on (playfield color), `.` = off (background color shows through). The documented form `playfield: <off> <on>` for choosing your own symbols has a preprocessor bug and **does not work** — always use `.` and `X`.
- You may specify as many lines as you want, but some may not display if you specify too many (11 visible + 1 hidden = 12 in the standard kernel).
- **You do not need this in your main loop.** Whatever you set the playfield to before the main loop starts is what it looks like forever, until you change it (with this block or the plotting commands). This surprises normal BASIC programmers who expect to redraw every frame.
- Multisprite kernel: only **16 characters wide**, and those 16 are mirrored/reflected on the right half of the screen.
- DPC+ kernel: same `playfield:` … `end` form but can hold far more rows (87+ lines in the manual's example); see [DPC+ kernel playfield](#dpc-kernel-playfield).

## Playfield variables (var0-var47) and the reversed-byte gotcha

Advanced use: the standard-kernel playfield lives in 48 variables, 4 per row (8 bits x 4 = 32 pixels). You may read/write them directly:

| Row  | Variables   | | Row  | Variables   |
|------|-------------|-|------|-------------|
| 0    | var0-var3   | | 6    | var24-var27 |
| 1    | var4-var7   | | 7    | var28-var31 |
| 2    | var8-var11  | | 8    | var32-var35 |
| 3    | var12-var15 | | 9    | var36-var39 |
| 4    | var16-var19 | | 10   | var40-var43 |
| 5    | var20-var23 | | 11   | var44-var47 (hidden row) |

**Warning — reversed bytes:** the **second and fourth** playfield variables of each row (var1, var3, var5, var7, …) have a **reversed bit order**. Setting

```
   var0=1 : var1=1 : var2=1 : var3=1
```

you'd expect one lit pixel every 8 columns, but the reversed bytes give you **two pairs of adjacent pixels** instead. As long as you remember that the 2nd and 4th variables of each row are reversed, you won't wonder if you've lost your mind. Prefer `pfpixel`/`pfhline`/`pfvline` and the `playfield:` block, which handle the bit order for you.

Two payoffs of direct access: (1) with `pfres` smaller than 12, the freed vars are yours to use; (2) with Superchip RAM, **var0-var47 are always free** for general use (the playfield lives in the Superchip instead).

## pfclear

Clears the playfield (standard kernel), or fills playfield RAM with a value:

```
   pfclear
   pfclear %10101010   ; fills all playfield RAM with 10101010
```

If you are using the standard kernel and are **not** scrolling, you can clear the screen while keeping the four hidden-row variables (var44-var47) for your own use — either define an all-dots `playfield:` block (12 rows of 32 dots) or set `var0` through `var43` to 0 (`var0 = 0 : var1 = 0 : … : var43 = 0`), which is even faster. The fastest way is inline asm: `asm` / `LDA #0` then `STA var0` … `STA var43` / `end`.

**Warning:** pfclear does not work with the multisprite kernel.

## pfpixel

Draws a single pixel with playfield blocks. Uses **80 processor cycles** every frame.

```
pfpixel xpos ypos function
```

- `xpos` 0-31, `ypos` 0-11 (11 is hidden and only seen if scrolled; more rows possible with Superchip RAM + pfres, or DPC+).
- `function` is `on`, `off`, or `flip` (flip turns it off if it was on, on if it was off).

```
   pfpixel 16 2 on
   pfpixel 8 4 off
   pfpixel 24 8 flip
```

**Warning:** there is **no bounds checking**. If you exceed the limits, strange things may happen, including crashing your program.

**Arguments must be plain variables or constants — not expressions.**
Variables work (`pfpixel _x _y on` is fine), but `pfpixel _x+2 _y on` mis-parses
and emits broken assembly, which surfaces later as a bare `Syntax Error ''`
from DASM pointing at a line of generated code. Precompute into a variable:

```bb
   _x1 = _x + 1
   _x2 = _x + 2
   pfpixel _x  _y on
   pfpixel _x1 _y on
   pfpixel _x2 _y on
```

**Screen coordinates:** the 32-column playfield spans screen x **16 to 144**,
4 screen pixels per column — so playfield column `c` starts at screen
`x = 16 + 4*c`. That is the conversion you need to line a sprite up with a
playfield cell (a sprite at `player0x = 16 + 4*c` sits on column `c`).

## pfhline

Draws a horizontal (left and right) line with playfield blocks. Uses **250 to 1500 cycles** depending on length (approx 210 + 42*length).

```
pfhline xpos ypos endxpos function
```

- `xpos` 0-31, `ypos` 0-11, `endxpos` is the last x to fill.
- `endxpos` should be **greater than** `xpos` or the command will not work properly and strange things may happen.
- `function` is `on`, `off`, or `flip`.

```
   pfhline 0 0 31 on     ; full-width top line
   pfhline 4 2 8 off
   pfhline 2 8 24 flip
```

**Warning:** no bounds checking — going out of range may crash the program. (Multisprite kernel: does not work.)

## pfvline

Draws a vertical (up and down) line with playfield blocks. Uses **230 to 600 cycles** depending on length (approx 200 + 34*length).

```
pfvline xpos ypos endypos function
```

- `xpos` 0-31, `ypos` 0-11, `endypos` is the last y to fill (must be **greater than** ypos).
- `function` is `on`, `off`, or `flip`.

```
   pfvline 0 0 10 on
   pfvline 31 4 8 off
   pfvline 8 2 4 flip
```

**Warning:** no bounds checking — going out of range may crash the program. (Multisprite kernel: does not work.)

## pfscroll

Scrolls the playfield (standard kernel). Useful for moving backgrounds. Valid values: `left`, `right`, `up`, `down`, `upup`, `downdown`.

```
   pfhline 8 5 23 on

   scorecolor = $C4
   COLUBK = $C4
   COLUPF = $CE

__Main_Loop

   pfscroll down

   drawscreen

   goto __Main_Loop
```

Joystick-driven version (full program: `examples/mini_ex_pfscroll.bas`):

```
__Main_Loop

   if joy0up then pfscroll up
   if joy0down then pfscroll down
   if joy0left then pfscroll left
   if joy0right then pfscroll right

   drawscreen

   goto __Main_Loop
```

What each direction does and costs:

- `pfscroll left` / `pfscroll right`: shifts the whole playfield left or right one pixel. Uses quite a few cycles — **500 cycles every frame** — so use sparingly.
- `pfscroll up` / `pfscroll down`: shifts rows up or down by one scanline; every 8th call the entire playfield memory is shifted one row (**650 cycles every 8th call, 30 cycles otherwise**).
- `pfscroll upup` / `pfscroll downdown`: scrolls **two lines at a time** without calling the routine twice.
- The hidden blocks at y=11 are scrolled in by up/down — they're never directly seen, but up/down scrolling pulls them onto the visible screen, so you can pre-fill rows off-screen to simulate a changing background.

**Warning:** playfield plotting **and** scrolling commands do not work with the multisprite kernel — the program may not compile, or may crash. For DPC+ scrolling, see [DPC+ pfscroll](#dpc-pfscroll).

## playfieldpos

Internal system variable that controls which scanline the top playfield block starts drawing on. The scrolling routines update it automatically, so you normally don't need it unless you want to know where the playfield is — or jump it somewhere:

- `playfieldpos = 8` resets the scroll position to normal (with the normal 32 x 11-resolution playfield).
- `playfieldpos = 1` through `8` scrolls the playfield that many lines (e.g. `playfieldpos = 4` scrolls 4 lines = half of one playfield row).

For 7 out of 8 calls, playfieldpos is updated/checked; every 8th call it resets to zero and the playfield memory shifts (Superchip RAM: scrolling takes more time and the memory move may happen more often).

## pfread

Tests whether an existing playfield pixel is on. **Can only be used in an if-then statement.** Arguments may be numbers, variables, or array elements.

```
if pfread(xpos,ypos) then …
```

- `xpos` 0-31, `ypos` 0-11 (11 hidden; more rows possible with Superchip RAM + pfres or DPC+).
- True if the pixel is on. Use `!pfread(...)` for "is off".

```
   if pfread(10,8) then goto __Star_Doink
   if !pfread(a[x], b) then goto __Higher_Frequency_Manifesting
```

Multisprite kernel: needs the special module `pfread_msk.asm`, not enabled by default — use `include pfread_msk.asm` in a 2K or 4K game, or `inline pfread_msk.asm` (last bank only) in a bankswitched game. In that module y-values are reversed compared to the standard kernel.

Typical use — delete a block that a missile hits (from `examples/ex_pfpixel_shoot.bas` and `examples/ex_sprite_with_missile_and_pfpixel_destruction.bas`):

```
   if !collision(playfield,missile0) then goto __Skip_Coll
   if !pfread(_pf_x,_pf_y) then goto __Skip_Coll
   pfpixel _pf_x _pf_y off
```

## Playfield and background colors: COLUPF & COLUBK

- `COLUPF` — sets the playfield color (and ball color). Example: `COLUPF = $CE`. Write-only (you can't do `a = COLUPF`). If you use pfscore bars, COLUPF must be in your main loop or the playfield takes on the pfscore bar color.
- `COLUBK` — sets the background color. Example: `COLUBK = $80`. Write-only. (For a multicolored background see the `background` kernel option, or use the DPC+ kernel.)

Both take hex color/luminance values — see the color chart reference for values.

## pfcolors kernel option (per-row colors)

Standard kernel: `set kernel_options pfcolors` enables a **multicolored playfield**. Then define row colors with a data block — one value per line, **11 or more values**, followed by `end`. You may redefine `pfcolors:` as many times as you want (e.g., change levels):

```
   set kernel_options pfcolors

   pfcolors:
   $32
   $34
   $36
   $38
   $3A
   $3C
   $3E
   $3C
   $3A
   $38
   $36
   $34
end
```

Top row bug and fixes:

- If `pfcolors:` sits outside your main loop, the top row may not get your chosen color. Fix: move `pfcolors:` inside the main loop, **or** keep `COLUPF` in your main loop set to the top row's color.
- With `no_blank_lines`, the top row color will be correct but the bottom row's will be wrong — use **12 colors** and make the 12th the same as the 11th.
- With the `background` option, neither COLUPF nor in-loop `pfcolors:` works (without `no_blank_lines`) — use `COLUBK` in your main loop for the top row instead; with `no_blank_lines`+`background` you may need 12-13 colors with adjusted placement.
- PF0 border color taint: if the bottom of your PF0 side border picks up another color, use 12 colors and repeat the 11th.

**Warning:** when using pfcolors and pfheights together, you may define `pfheights:` and `pfcolors:` only **one time each**, and you must define **pfheights: first**. Also, if you enable either option but never define its block, you will probably get a compile error.

## pfheights kernel option (per-row heights)

Standard kernel: `set kernel_options pfheights` lets each playfield row have its own height. Define **11 values, one per line**, followed by `end`:

```
   set kernel_options pfheights

   pfheights:
   8
   8
   15
   1
   8
   8
   8
   8
   8
   8
   8
end
```

- Default row height is 8 (scanlines). The **total should not exceed 88** or you cut into the time available for your bB program; less than 88 is fine but shrinks the visible screen.
- Bug: at this time, if the first row isn't 8, things might not work quite correctly.
- You may redefine `pfheights:` as many times as you want.
- Same combined-use warning as pfcolors: define each once only, `pfheights:` first.

## background kernel option

`set kernel_options background` (usually with `no_blank_lines`) makes the `pfcolors:` data color the **background** rows instead of the playfield, so you get horizontal color bands in the background with normal single-color playfield pixels drawn on top. Cost: **loss of missile0**.

```
   set kernel_options pfcolors no_blank_lines background

   pfcolors:
   $32
   $34
   $36
   $38
   $3A
   $3C
   $3E
   $3C
   $3A
   $38
   $36
   $34
end

   COLUPF = $CE        ; playfield pixel color
   COLUBK = $32        ; top row background color (inside main loop)

__Main_Loop
   COLUBK = $32
   drawscreen
   goto __Main_Loop
```

**Warning:** if you use `background` without `no_blank_lines`, timing issues cause a stairstep effect (rows won't be perfectly straight). With `background`, `COLUPF` won't work (and neither will putting `pfcolors:` inside the main loop) unless `no_blank_lines` is also used — read the pfcolors top-row notes above.

## pfres (playfield resolution)

Standard kernel only. The playfield is no longer fixed at 11+1 rows — `const pfres=n` changes the number of rows, freeing the variables of the removed rows for general use:

```
   const pfres=10
```

- Default `pfres` is 12. Valid values **3-11** (up to **32 with Superchip RAM**, in which case var0-var47 are always free anyway).
- The playfield uses 4 bytes per row, so `pfres=10` frees 8 bytes (var0-var7 become ordinary variables).
- Reducing rows may or may not shrink the visible screen — bB tries to fill the screen by varying row height. Default row heights and freed variables:

| pfres | Row height | Variables freed |
|-------|-----------|-----------------|
| 12 (default) | 8 | none |
| 11 | 8 | var0-var3 |
| 10 | 9 | var0-var7 |
| 9 | 10 | var0-var11 |
| 8 | 12 | var0-var15 |
| 7 | 13 | var0-var19 |
| 6 | 16 | var0-var23 |
| 5 | 19 | var0-var27 |
| 4 | 24 | var0-var31 |
| 3 | 32 | var0-var35 |

With Superchip RAM + `pfres=23` you get a 32 x 23 maze playfield — see [Maze examples](#maze-examples).

## pfrowheight

Standard kernel only: sets a single uniform height for every playfield row (default 8):

```
   const pfrowheight=7
```

**Warning:** if `pfres * pfrowheight` exceeds 96, the screen grows and cuts into your bB program's time — in extreme cases the screen will jitter, shake, or roll. (For different heights per row, use the `pfheights` kernel option instead.) Working example: `examples/ex_sprite_with_collision_prevention_and_pfrowheight7.bas`.

## Making playfield pixels smaller

Default playfield pixels are wide, squat blocks (4 sprite-pixels wide, ~8 tall). To square them or shrink them: `pfrowheight`, `pfres`, `pfheights` (kernel option), `pfheight` (multisprite kernel), Superchip RAM (enables pfres up to 32), or the DPC+ playfield resolution.

## Maze examples

Complete example programs in `examples/`:

- `z_bb_ex_maze_32x23.bas` — 32 x 23 maze with animated sprite and roaming sprite (8.8 fixed point movement). Uses `set kernel_options no_blank_lines`, Superchip RAM (`set romsize 16kSC`), `const pfres=23`, bankswitching, vblank, and `pfread` for wall checks.
- `z_bb_ex_maze_32x12.bas` — same idea with the standard 32 x 12 playfield; uses bankswitching.
- `z_bb_ex_maze_dpc.bas` — the maze using the DPC+ kernel's taller playfield.

Other playfield example programs: `mini_ex_pfscroll.bas` (scrolling), `ex_pfpixel_shoot.bas` (missile destroys pfpixels), `ex_sprite_with_missile_and_pfpixel_destruction.bas` (same idea, different layout).

## DPC+ kernel playfield

The DPC+ kernel's playfield is very different from the standard kernel's — do not carry standard-kernel assumptions over.

**Resolution.** Horizontal is 32 playfield pixels across (same as standard). Vertical is controlled by 4 registers — `DF0FRACINC`, `DF1FRACINC`, `DF2FRACINC`, `DF3FRACINC` (Data Fetcher Fractional Increment) — one per playfield column, so **each of the 4 columns can have a different resolution**. You don't think in "number of rows" but in **how many scanlines tall each row is** (the kernel displays 176 scanlines; subject to change). The value stored is the fractional increment; the table below gives working values. `DF4FRACINC` controls how many times playfield pixels can change color top-to-bottom; `DF6FRACINC` the same for background color (useful for gradients). DFxFRACINC assignments must be placed in the main loop, before/with drawscreen.

| Scanlines/row | Resolution | DF(0-3)FRACINC | DF4FRACINC |
|---------------|-----------|----------------|------------|
| 1 | 176 | 255 | - |
| 2 | 88 | 128 | 255 |
| 3 | 59 * | 86 | - |
| 4 | 44 | 64 | 128 |
| 5 | 36 * | 52 | - |
| 6 | 30 * | 43 | 86 |
| 7 | 26 * | 37 | - |
| 8 | 22 | 32 | 64 |
| 9 | 20 * | 29 | - |
| 10 | 18 * | 26 | 52 |
| 11 | 16 | 24 | - |
| 12 | 15 * | 22 | 44 |
| 13 | 14 * | 20 | - |
| 14 | 13 * | 19 | 38 |
| 15 | 12 * | 18 | - |
| 16 | 11 | 16 | 32 |
| 18 | 10 * | 15 | 30 |
| 19 | 10 * | 14 | - |
| 20 | 9 * | 13 | 26 |
| 22 | 8 | 12 | 24 |
| 24 | 8 * | 11 | 22 |
| 26 | 7 * | 10 | 20 |
| 29 | 7 * | 9 | - |
| 32 | 6 * | 8 | 16 |
| 37 | 5 * | 7 | - |
| 44 | 4 | 6 | 12 |
| 52 | 4 * | 5 | 10 |
| 64 | 3 * | 4 | 8 |
| 86 | 3 * | 3 | 6 |
| 128 | 2 * | 2 | 4 |
| 176 | 1 | 1 or 0 | 1 or 0 |

A `*` in the resolution column means the bottom row isn't full height. A `-` means color updates happen half as often as rows, so no DF4FRACINC value lines up nicely. These aren't the only working values — experiment. Ready-made settings:

```
   ; 176 rows, 1 scanline high (top/bottom rows come out 2 high):
   DF6FRACINC = 255 : DF4FRACINC = 255
   DF0FRACINC = 255 : DF1FRACINC = 255
   DF2FRACINC = 255 : DF3FRACINC = 255

   ; 88 rows, 2 scanlines high:
   DF6FRACINC = 255 : DF4FRACINC = 255
   DF0FRACINC = 128 : DF1FRACINC = 128
   DF2FRACINC = 128 : DF3FRACINC = 128

   ; 44 rows, 4 scanlines high:
   DF6FRACINC = 128 : DF4FRACINC = 128
   DF0FRACINC = 64 : DF1FRACINC = 64
   DF2FRACINC = 64 : DF3FRACINC = 64

   ; 22 rows, 8 scanlines high (close to standard kernel look):
   DF6FRACINC = 64 : DF4FRACINC = 64
   DF0FRACINC = 32 : DF1FRACINC = 32
   DF2FRACINC = 32 : DF3FRACINC = 32

   ; 11 rows, 16 scanlines high:
   DF6FRACINC = 32 : DF4FRACINC = 32
   DF0FRACINC = 16 : DF1FRACINC = 16
   DF2FRACINC = 16 : DF3FRACINC = 16
```

(The DFxFRACINC Tool example program lets you tweak these registers live with the joystick; the DPC+ scroll example program demonstrates scrolling playfield colors and background colors.)

**Per-row colors / gradients.** With `DF4FRACINC` you can have far more playfield color changes than the standard kernel's 11, and `DF6FRACINC` gives multicolor/gradient backgrounds. Because color updates happen at half the row rate, set DF4FRACINC to **twice** the DF(0-3)FRACINC value to keep colors lock-step with the rows.

**pfclear (DPC+).** Works, and is faster than standard-kernel pfclear because the ARM CPU clears its memory faster than a 6507.

### DPC+ pfscroll

No horizontal DPC+ scrolling. Coarse **vertical** scrolling only, one PF line at a time (use a fine DF#FRACINC resolution if you want it to look smooth). Playfield strips are 256 bytes, so to scroll **down** you count backwards: `pfscroll 255` scrolls down 1, `pfscroll 254` scrolls down 2, and so on; `pfscroll 1` scrolls up 1. Syntax:

```
pfscroll [value or variable] [queue value] [queue value]
```

Queue values (optional) select a range of data fetchers to scroll; only constants work for the queue numbers (variables work for the scroll value):

| Queue | Data |
|-------|------|
| 0-3 | DF0FRACINC-DF3FRACINC playfield data (columns 0-3) |
| 4 | Playfield color data |
| 6 | Background color data |

```
   pfscroll 1        ; scrolls the whole DPC+ playfield one line
   pfscroll 1 0 1    ; scrolls DF0 and DF1 one line
   pfscroll 1 2 3    ; scrolls DF2 and DF3 one line
   pfscroll 1 1 3    ; scrolls DF1 through DF3 one line
   pfscroll 1 0 4    ; scrolls playfield and PF colors one line
   pfscroll 1 4 4    ; scrolls only the PF colors one line
   pfscroll 1 0 6    ; scrolls playfield and background colors one line
   pfscroll 1 6 6    ; scrolls only the background colors one line
```

Because colors update at half rate, either set DF4FRACINC (or DF6FRACINC) to twice the graphics fetchers' value, or scroll the color queue twice as often, to keep colors in lock-step.

## Common mistakes

- Writing `playfield:` rows with the wrong width (must be exactly 32 characters in the standard kernel, 16 in multisprite), or expecting more than 12 rows to display.
- Putting playfield setup inside the main loop "to refresh it" — the playfield persists until you change it.
- Directly setting var1/var3/etc. and expecting normal left-to-right bit order — the **2nd and 4th variables of every row are reversed**.
- Passing out-of-range values to `pfpixel`/`pfhline`/`pfvline` — there is **no bounds checking**; the program may crash. Also `endxpos`/`endypos` must be greater than the start.
- Using `pfscroll left`/`right` every frame and wondering why the game logic slows down (500 cycles/frame) — scroll less often.
- Using plotting/scrolling commands (or pfclear) with the multisprite kernel — they don't work; the program may not compile or may crash. (pfread works there only via `pfread_msk.asm`.)
- Using `pfread` outside an if-then — it only works as `if pfread(x,y) then …`.
- Expecting COLUPF/COLUBK to be readable — both are write-only TIA registers.
- With `pfcolors`: forgetting the top-row color bug fixes, or defining `pfcolors:`/`pfheights:` more than once when both options are used (and forgetting `pfheights:` must come first).
- With `pfheights`: totaling more than 88, or making the first row something other than 8 (currently buggy).
- With `background`: not using `no_blank_lines` (stairstepped rows) or trying to use COLUPF.
- `pfres * pfrowheight` over 96 — screen grows, time shrinks, screen may jitter/shake/roll.
- Treating the hidden row 11 as useless — it's your scroll-in buffer, and (unscrolled) var44-var47 double as free variables.
- Assuming DPC+ pfscroll matches standard-kernel pfscroll — no left/right, down is `pfscroll 255`, and queues 4/6 scroll colors.
- Writing to DFxFRACINC registers outside the main loop — they must be set before/with drawscreen.

## Playfield tools (online)

- **bB Playfield Editor** — draw standard-kernel and DPC+ playfields in
  the browser, copy out bB code:
  https://www.randomterrain.com/bb-playfield-editor.html
- Agents can usually skip it — `pfpixel`/`pfhline`/`pfvline` plus the
  playfield: data block syntax in this file are enough to generate any
  layout programmatically.
