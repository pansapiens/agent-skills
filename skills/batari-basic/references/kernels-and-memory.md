# batari Basic Kernels & Memory Reference

Display kernels (`set kernel`: standard, multisprite, DPC+), standard-kernel options (`set kernel_options`), ROM sizes and bankswitching (`set romsize`), Superchip extra RAM, optimization settings, per-kernel memory maps, multisprite `screenheight`, and the titlescreen kernel.

**Contents:** [Kernels overview](#kernels-overview) · [set kernel](#set-kernel) · [Standard kernel](#the-standard-kernel) · [set kernel_options](#set-kernel_options-standard-kernel-only) · [Option combos](#valid-kernel_options-combinations) · [Multisprite kernel](#the-multisprite-kernel) · [Virtual sprite registers](#multisprite-virtual-sprite-registers) · [DPC+ kernel](#the-dpc-kernel) · [DPC+ stack](#the-stack-dpc-only) · [set romsize & bankswitching](#set-romsize--bankswitching) · [return thisbank/otherbank](#return-thisbankotherbank) · [Superchip RAM](#superchip-ram-extra-ram) · [Superchip charts](#superchip-playfield-charts) · [set optimization](#set-optimization) · [Memory maps](#memory-maps-per-kernel) · [pfheight (multisprite)](#pfheight-multisprite-kernel) · [screenheight](#screenheight-multisprite-kernel) · [Titlescreen kernel](#titlescreen-kernel-brief) · [Examples](#example-programs) · [Common mistakes](#common-mistakes)

**Big bB vs normal BASIC differences:** there is no single graphics system — which sprites, playfield shape, and RAM you get depends entirely on the kernel you pick, and ROM "banks" can't see each other's data.

## Kernels overview

The **kernel** is the pre-written assembly routine that draws the TV display every `drawscreen`. bB has **29 kernels**: 1 standard, 1 multisprite, 1 DPC+, and 26 more that are the standard kernel plus options (chosen with `set kernel_options`).

| Kernel | Line mode | Sprites | Missiles/ball | Playfield |
|---|---|---|---|---|
| standard (default) | 2-line (double-height pixels) | player0, player1 (8 wide, any height up to 256) | missile0, missile1, ball | 32 x 11 visible (32 x 12 counting hidden row), asymmetric, in RAM |
| multisprite | 2-line | player0 + player1-5 **virtual** (6 total, mono-colored) | missile0, missile1, ball — but **fixed at one unit high** | mirrored, in ROM, up to 44 rows, no plotting commands |
| DPC+ | 1-line (single-height pixels) | player0 + player1-9 **virtual** (10 total, multicolored) | missile0, missile1, ball | asymmetric, non-mirrored, multicolored, highest resolution |

**When to use which:** use the standard kernel by default. Use DPC+ **only when you need it** (more objects, single-line sprite detail, better playfield) — it requires Melody/Harmony cartridge hardware or Stella released after October 2012, and you get fewer cycles and variables. The multisprite kernel predates DPC+; most people now choose DPC+ over it (10 multicolored single-height sprites vs 6 mono-colored double-height sprites).

## set kernel

```bB
   set kernel DPC+
   set kernel multisprite
```

No directive is needed for the standard kernel — it is the default. Put this at the very top of your code (before other code). The DPC+ kernel uses no standard kernel_options (see its one exception below).

## The standard kernel

- Objects: player0, player1, missile0, missile1, ball, plus a 32 x 11 bitmapped asymmetric playfield (32 x 12 counting the hidden row only seen when scrolled).
- The score is drawn at the top of the screen; all game objects are drawn below it (nothing displays over the score area).
- Your game code normally runs in overscan: about **2 milliseconds ≈ 2710 cycles** between drawscreens (plus 1675 cycles in vblank if you use the `vblank` command).
- Sprite data bytes are **upside down in your code** — bB flips them at runtime; the first data line is the bottom row of the sprite.

## set kernel_options (standard kernel ONLY)

```bB
   set kernel_options option [option2 option3 ...]
   set kernel_options pfcolors pfheights
   set kernel_options playercolors player1colors no_blank_lines readpaddle
```

Customizes the standard kernel. **These options do not work with the DPC+ or multisprite kernels.** Generally, adding options means some objects will no longer be displayed (the kernel spends its cycles on the feature instead). Option order does not matter, but only certain singles/combinations are valid.

The 7 options:

| Option | What it does | Cost |
|---|---|---|
| `player1colors` | multicolored player1 (`player1color:` data) | loss of missile1 |
| `playercolors` | multicolored player0 too (requires `player1colors`) | loss of missile0 |
| `no_blank_lines` | no gaps between playfield rows | loss of missile0 |
| `pfcolors` | per-row playfield colors (`pfcolors:` data) | free |
| `pfheights` | per-row playfield heights (`pfheights:` data) | free |
| `readpaddle` | read a paddle controller (sets `currentpaddle`, `paddle`) | must be used **with** `no_blank_lines` |
| `background` | multicolored background instead of multicolored playfield (uses `pfcolors:` data) | — (needs `pfcolors`) |

**Acceptable singles** (from the official list):

| Single option | Cost |
|---|---|
| `player1colors` | loss of missile1 |
| `no_blank_lines` | loss of missile0 |
| `pfcolors` | free |
| `pfheights` | free |

**Invalid singles** (these cannot be used alone): `playercolors`, `readpaddle`, `background`.

## Valid kernel_options combinations

All acceptable combinations and their costs (order does not matter):

| Combination | Cost |
|---|---|
| `pfcolors pfheights` | colors and height are fixed |
| `pfcolors pfheights background` | colors and height are fixed |
| `pfcolors no_blank_lines` | loss of missile0 |
| `pfcolors no_blank_lines background` | loss of missile0 |
| `player1colors no_blank_lines` | loss of missile1 and missile0 |
| `player1colors pfcolors` | loss of missile1 |
| `player1colors pfheights` | loss of missile1 |
| `player1colors pfcolors pfheights` | loss of missile1 and colors/height fixed |
| `player1colors pfcolors background` | loss of missile1 |
| `player1colors pfheights background` | loss of missile1 |
| `player1colors pfcolors pfheights background` | loss of missile1 and colors/height fixed |
| `player1colors no_blank_lines readpaddle` | loss of missile1 and missile0 |
| `player1colors no_blank_lines pfcolors` | loss of missile1 and missile0 |
| `player1colors no_blank_lines pfcolors background` | loss of missile1 and missile0 |
| `playercolors player1colors pfcolors` | loss of missile1 and missile0 |
| `playercolors player1colors pfheights` | loss of missile1 and missile0 |
| `playercolors player1colors pfcolors pfheights` | loss of both missiles and colors/height fixed |
| `playercolors player1colors pfcolors background` | loss of missile1 and missile0 |
| `playercolors player1colors pfheights background` | loss of missile1 and missile0 |
| `playercolors player1colors pfcolors pfheights background` | loss of both missiles and colors/height fixed |
| `no_blank_lines readpaddle` | loss of missile0 |

Note: "colors and height are fixed" means `pfcolors:`/`pfheights:` data can only be defined once, not changed on the fly.

## The multisprite kernel

```bB
   set kernel multisprite
```

- 6 sprites: player0 works like in the standard kernel; **player1-player5 are virtual sprites**, drawn by repositioning the 2600's second hardware sprite several times per screen. You can define sprites 2 through 5 with `player2:` … `player5:`, but underneath they are all player1 (see collision below).
- Virtual sprites may **flicker** if two or more share the same vertical region; the kernel detects overlap and flickers automatically. Avoid flicker by keeping vertical separation. The flicker algorithm isn't perfect — occasionally some sprites may not display correctly (known bug).
- **collision() only accepts player1** for virtual sprites: `if collision(player0,player1)` means player0 hit *one or more* of player1-5 — check y-positions to find which.
- **Y-values are inverted** vs the standard kernel: bottom of screen = 0, top ≈ 88.
- The virtual sprites are drawn **upside-down (vertically flipped)** relative to the standard kernel — if a shape renders inverted, flip the order of its data rows.
- The **playfield is mirrored** (left/right reversed; right half always equals left half) **and located in ROM**, which means: no playfield plotting commands (`pfpixel`, `pfhline`, `pfvline`), `pfclear` will not compile, horizontal scrolling is essentially impossible, vertical scrolling isn't implemented, and the **only** way to draw it is one full `playfield:` block. Upside: up to **44 rows** (vs 11) with settable vertical resolution.
- No kernel options (yet). Missiles and ball are **fixed at one unit high**. missile1's appearance may be affected by any of sprites 1-5's NUSIZx/COLUPx values.
- Some bB versions require player0's graphics to be redefined every pass through the game loop — if player0 vanishes, move its `player0:` block inside the loop.
- To use more than 4k, the **first line** of your program must be `includesfile multisprite_bankswitch.inc`; for Superchip RAM use `includesfile multisprite_superchip.inc`:

```bB
   includesfile multisprite_bankswitch.inc
   set kernel multisprite
   set romsize 8k
```

## Multisprite virtual sprite registers

Each virtual sprite has its own x, y, height, color, and NUSIZ variables. The color/NUSIZ ones *look like* TIA registers but are not — they point to RAM (so they're persistent), and the real TIA `COLUP1`/`NUSIZ1` will probably have no effect here.

| Sprite | x / y / height | Color | NUSIZ |
|---|---|---|---|
| player1 | player1x, player1y, player1height | `_COLUP1` | `_NUSIZ1` |
| player2 | player2x, player2y, player2height | `COLUP2` | `NUSIZ2` |
| player3 | player3x, player3y, player3height | `COLUP3` | `NUSIZ3` |
| player4 | player4x, player4y, player4height | `COLUP4` | `NUSIZ4` |
| player5 | player5x, player5y, player5height | `COLUP5` | `NUSIZ5` |

- There are no REFPx variables for virtual sprites: set the reflection bit with **bit 3 of `_NUSIZ1` or `NUSIZ2`-`NUSIZ5`** (that bit is unused by the hardware register). Example: `NUSIZ3{3} = 1`.

## The DPC+ kernel

```bB
   set kernel DPC+
```

Hardware-assisted kernel based on David Crane's DPC chip (Pitfall II). **Only works on Melody/Harmony cartridges and Stella versions released after October 2012.** Use only when you actually need its power (see [Kernels overview](#kernels-overview)).

**Layout / limits:**

- ROM is fixed at **32k** — do not declare `set romsize 32k`. Breakdown: 4k bB system + 20k your code (banks 2-6 free) + 4k graphics bank (sprite/playfield data go there automatically; you can't put code in it) + 4k ARM code = 32k.
- The kernel lives in bank 1 with **less than 100 bytes free** (shrinking over time) — put only a `goto __Bank_2 bank2` in bank 1 and start your real code in bank 2:

```bB
   set kernel DPC+
   goto __Bank_2 bank2
   bank 2
   temp1=temp1
__Bank_2
```

- To fix Harmony cart issues, put `temp1=temp1` right after **each** bank declaration (see the DPC+ template in `examples/`).
- Cycles: **2398 in overscan** (vs 2710 standard). **Avoid `vblank`** — only ~524 free cycles there and it must go in bank 1 where there's no room.
- **35 variables**: a-z and var0-var8 (no rand16 needed — ARM-based 32-bit LFSR random numbers).
- `pfpixel`, `pfvline`, `pfhline`, `pfread`, `pfclear`, `pfscroll` all work. You can't poke data directly into playfield variables (playfield is in ARM memory).

**Sprites:** player0-9, each 8 pixels wide, any height up to 256, **single-height pixels** (to mimic the old double-thick look, double the data lines: a 10-line standard-kernel sprite needs 20 lines). player1-9 are virtual (repositioned hardware sprite 1) and flicker automatically when overlapping — keep vertical separation for no flicker.

- Disable a sprite by setting its y to **~200** (y = 0 still shows it).
- player1 **wraps automatically** above 165 (to prevent crashes); you must wrap player0, missiles, and ball yourself.
- Virtual NUSIZ registers: `_NUSIZ1`, `NUSIZ2`-`NUSIZ9` (not real TIA registers). Reflection = bit 3.
- **Masking** (virtual sprites only): bit 7 of NUSIZx enables masking (1 = on) so a sprite can slide off-screen without appearing on the other side; bit 6 picks the side (0 = left, 1 = right). Move the sprite once its last pixel is off screen, or it wraps. Doesn't work with NUSIZ0 (player0) or with double/quadruple-wide sprites.
- **Sharing data:** sequential sprites with the same shape/colors can share one definition:

```bB
   player1-9:
   %00001111
   %00000110
end

   player2-3color:
   $38
   $3C
end
```

- **dpcspritemax:** don't waste RAM on unused virtual sprites — `set dpcspritemax #` (# = 1-9) frees **4 variables per disabled sprite** (playerNx, playerNy, NUSIZN, playerNheight), usable with `dim`. E.g. `set dpcspritemax 4` frees 20 variables; `3` frees 24; `2` frees 28.

**Missiles/ball:** colors via `COLUM0`/`COLUM1`; heights via `missile0height`/`missile1height` (minimum useful height is 2; 0 hides it; 1 makes it show on even rows only). Width via NUSIZx — for missile1 wider than 1 pixel you must set every on-screen virtual sprite's NUSIZx, using OR to preserve other bits: `_NUSIZ1 = _NUSIZ1 | $10` (2 px), `| $20` (4 px), `| $30` (8 px). Hardware quirk: a missile on the same scanline as its player shows that player's colors (missile0 inherits player0's colors, missile1 inherits player1-9's).

**Collision:** pixel-perfect, but ignores hardware-reflected sprites, NUSIZ copies, and wide players. Virtual-vs-virtual `collision(player2,player9)` works (bB 1.1d+). Playfield: only the highest colliding virtual sprite registers. The DPC+ kernel's **one kernel option**:

```bB
   set kernel_options collision(player1,playfield)
```

returns the y-coordinate of the first player1-9/playfield collision in **temp4** after drawscreen (approximate — a little less or more), so one collision check plus coordinate checking can replace nine.

**Colors:** `player0color:` … `player9color:` (per-row sprite colors), `pfcolors:` (per-row playfield), `bkcolors:` (per-scanline background, count controlled by `DF6FRACINC`), `scorecolors:` (8 rows for gradient score).

## The stack (DPC+ only)

Advanced feature — you can finish a game without it. 256 bytes, 100% yours (nothing else uses it). Location #0 = top, #255 = bottom.

```bB
   stack 200
   push player0x
   ; ...code that reuses player0x...
   stack 199
   pull player0x

   push j-m                          ; push a range
   push a x missile0x player0y       ; push several at once
```

`stack` needs a **number** (0-255), not a variable. Too many nested subroutines will overwrite variables like var8 — avoid nesting.

## set romsize & bankswitching

```bB
   set romsize 2k
   set romsize 4k    ; default
   set romsize 8k
   set romsize 16k
   set romsize 32k
   set romsize 64k
   set romsize 8kSC  ; SC = Superchip RAM appended (8k or larger only)
   set romsize 16kSC
   set romsize 32kSC
   set romsize 64kSC
```

The 2600 only addresses 4k at a time. **8k or larger uses bankswitching**: 8k = 2 banks, 16k = 4, 32k = 8, 64k = 16. The DPC+ kernel is fixed at 32k (don't declare romsize).

Bank layout: bank 1 starts at the beginning of your code (never declare it). Begin each later bank with `bank n` (**space** between bank and number):

```bB
   set romsize 16k
   bank 2
   bank 3
   bank 4
```

**Jumping between banks** — specify the bank with goto/gosub, **no space** (e.g. `bank2`):

```bB
   goto __Section_2_of_Code bank2
   gosub __Move_Monster bank2
```

**Verified failure modes if you get this wrong (bB 1.9, tested):**

- A cross-bank `goto label` **without** the `bankN` suffix silently
  compiles to a plain `jmp` into the wrong bank's mirror address — the
  program runs random code instead of erroring. Same for `if ... then
  goto cross_bank_label` (the suffix can't be used inside if-then;
  route through a local label with a bare `goto ... bankN`).
- **`on x goto ...` never supports bankswitching** (the compiler says
  so itself) — the jumptable raw-addresses into other banks. Use it
  only for same-bank targets; dispatch across banks with an if-chain
  of local labels + bare `goto ... bankN`.
- `include` statements in bankswitched ROMs only work at the **very
  top of the file, before `set romsize`** — anywhere else the file is
  silently not inlined and its routines (e.g. `div8` from
  `div_mul.asm`) fail to resolve at assembly.

**Data placement rules (important!):**

- **A bank cannot access data in another bank** — data tables are only reachable from the bank they live in. Keep each `data` statement in the same bank as the code that reads it.
- Sprite graphics automatically go in the **last bank** no matter where you define them (leave animation frames in your main-loop bank). The kernel and most bB modules/functions also go in the last bank. `drawscreen` needs nothing special.
- Playfield graphics data: standard kernel → stored in whatever bank you place it in; multisprite kernel → automatically in the last bank; DPC+ kernel → automatically in the "graphics" bank.

**Efficiency best practices:** cross-bank jumps cost cycles and space — limit them to a few per frame; chain your main loop sequentially across banks (part 1 ends in bank 1 jumping to part 2 in bank 2, etc.) instead of one bank constantly calling out; prefer cross-bank `goto` over cross-bank `gosub`; inside one bank, only `gosub` code used from several places.

## return thisbank/otherbank

A plain `return` automatically tracks which bank called the subroutine, but that costs ROM and cycles. Be explicit instead:

```bB
   return thisbank   ; subroutine was called from the same bank — fastest; CRASHES if called cross-bank
   return otherbank  ; called from a different bank — faster than plain return for cross-bank
```

## Superchip RAM (extra RAM)

The Superchip (SARA) adds **128 bytes of RAM**; only used with bankswitching. Enable by appending **SC (capitalized)** to `set romsize` (8k or larger) — that's all it takes for the standard kernel; multisprite needs `includesfile multisprite_superchip.inc` as the first line instead (see above).

- Superchip binaries need 256 bytes of filler per 4k, slightly reducing available ROM. Emulators and programmable carts (Harmony, Cuttle Cart, Krokodile Cart, Maxcart) support it; standalone carts cost slightly more.
- **+48 free normal variables:** the playfield moves into Superchip RAM, freeing the old playfield bytes as regular variables **var0-var47** (no special rules).
- **The other 80 bytes are special r/w variables:** because the chip reads and writes at different addresses, they are 128 write-only (`w000`-`w127`) plus 128 read-only (`r000`-`r127`) mirrors. Write to `w000`, read it back as `r000`. Rules: **w-vars only on the left of `=`, r-vars only on the right** (or in if-then comparisons, or as function arguments):

```bB
   w010 = r010 + 1
   w000 = r001 + r002 + 4
   if r001 < 4 then 20
   w004 = myfunction(r001, r002)
   COLUP0 = r001
   pfpixel r001 r002 on
```

- These r/w variables **cannot** be used for: on…goto/gosub, fixed-point math, 16-bit multiplication/division (include div_mul16.asm), the counter of for…next, or anything that `dim`s a value to a user variable. Safe uses: add/subtract, multiply/divide (without div_mul16), and if-then (read side only). Save them for simple things.
- Don't confuse this with `set smartbranching` — that directive is about generating optimal code for if-then branches and has nothing to do with RAM.

**Playfield resolution with Superchip:** default is 12 rows; `const pfres=n` (3-32; values that don't evenly divide 96 — 3, 4, 6, 8, 12, 16, 24, 32 — may shrink the screen) raises it up to 31+1 visible rows at 4 Superchip bytes per row. Drawback of the double-height playfield: horizontal scrolling isn't supported (too slow — twice the data). The playfield always ends at r/w127, so count free r/w variables backwards from 127.

## Superchip playfield charts

| Rows | Setting | Row height | Superchip bytes used | Free r/w variables |
|---|---|---|---|---|
| 12 | pfres not used | 8 | 48 (playfield starts at r/w080) | 80 (r/w000-r/w079) |
| 18 | `const pfres=18` | 5 | 72 (starts at r/w056) | 56 (r/w000-r/w055) |
| 23 | `const pfres=23` | 4 | 92 (starts at r/w036) | 36 (r/w000-r/w035) |
| 32 | `const pfres=32` | 3 | 128 (starts at r/w000) | 0 |

(Row 0 always uses the lowest 4 playfield bytes, e.g. r/w080-r/w083 for 12 rows; each row = 4 variables.)

Standard kernel without Superchip can lower pfres 3-11 to *free* variables (playfield stays in normal RAM): pfres 12→row height 8, none freed; 11→8, var0-var3; 10→9, var0-var7; 9→10, var0-var11; 8→12, var0-var15; 7→13, var0-var19; 6→16, var0-var23; 5→19, var0-var27; 4→24, var0-var31; 3→32, var0-var35.

## set optimization

```bB
   set optimization speed
   set optimization size
   set optimization noinlinedata
   set optimization inlinerand
```

Tells the compiler to generate faster or smaller code. Options: `speed`, `size`, `noinlinedata`, `inlinerand`, `none`. Any combination may be used **except** with `none`, and — unlike kernel_options — **each option must be on its own line**.

| Option | Effect | When to use |
|---|---|---|
| `speed` | may increase speed (especially multiplication/division) at the cost of code size | math-heavy code |
| `size` | may shrink generated code by reusing bytes wasted on sprite data alignment | **multisprite kernel only** |
| `noinlinedata` | removes overhead from data tables, saving space | when you can keep all data tables outside of code |
| `inlinerand` | inlines random number calls | bankswitched games — avoids a bank switch per rand (speeds code, minimal size cost) |

Warning: `set optimization none` disables all previous optimization lines — don't combine it with the others. All options apply to DPC+ except `size`.

`noinlinedata` gotcha: data tables can no longer sit inline with code — your program may crash if you place them there.

## Memory maps (per kernel)

User variables you can `dim`: a-z in all kernels; var0-var47 (standard + Superchip playfield move), var0-var8 (DPC+), **none** in multisprite (its playfield lives in ROM). temp1-temp7 are wiped by the kernel/functions — short-term only. stack1-stack4 and $FA-$FF are reserved for the hardware stack.

**Standard kernel** (var0-var47 = old playfield bytes):

| Address | Variable |
|---|---|
| $80-$81 | player0x, player1x |
| $82 | player0colorstore / missile0x |
| $83-$84 | missile1x, ballx |
| $85-$86 | player0y (objecty), player1y |
| $87-$89 | player1color (missile1height), missile1y, bally |
| $8a-$8d | player0/player1 pointer lo/hi |
| $8e-$8f | player0height, player1height |
| $90-$92 | player0color (currentpaddle, missile0height), paddle (missile0y), ballheight |
| $93-$9b | score, scorepointers |
| $9c-$a1 | temp1-temp6 |
| $a2-$a3 | rand, scorecolor |
| $a4-$d3 | var0-var47 |
| $d4-$ed | a-z |
| $ee-$ef | temp7, playfieldpos |
| $f0-$f5 | pfheighttable/pfcolortable (aux1), aux2, lifepointer/pfscore1 (aux3), pfscore2/lives (aux4), statusbarlength/pfscorecolor/lifecolor (aux5), aux6 |
| $f6-$f9 | stack1-stack4 |

**Multisprite kernel** (no var0-var47!):

| Address | Variable |
|---|---|
| $80-$85 | missile0x, missile1x, ballx, objecty/missile0y, missile1y, bally |
| $86 | SpriteIndex |
| $87 | player0x |
| $88-$8c | player1x-player5x (NewSpriteX) |
| $8d | player0y |
| $8e-$92 | player1y-player5y (NewSpriteY) |
| $93-$97 | _NUSIZ1 (NewNUSIZ), NUSIZ2-NUSIZ5 |
| $98-$9c | _COLUP1 (NewCOLUP1), COLUP2-COLUP5 |
| $9d | SpriteGfxIndex |
| $a2-$af | player0 pointer lo/hi, P0Bottom, P1Bottom, player1-5 pointer lo, player1-5 pointer hi |
| $b0-$b5 | player0height, player1height-player5height (spriteheight) |
| $b6-$ba | PF1temp1/2, PF2temp1/2, pfpixelheight |
| $bb-$be | playfield PF1pointer, PF2pointer |
| $bf-$c2 | aux3/statusbarlength, pfscorecolor/lifecolor/aux4, aux5/pfscore1/lifepointer, lives/aux6/pfscore2 |
| $c3 | playfieldpos |
| $c4-$d0 | scorepointers, temp1-temp7 (some shared: temp2/P1Display, temp4/RepoLine, temp5/P0Top) |
| $d1-$d6 | score, pfheight, scorecolor, rand |
| $d7-$f0 | a-z |
| $f1-$f9 | spritesort, spritesort2-5, stack1-stack4 |

**DPC+ kernel**:

| Address | Variable |
|---|---|
| $80-$81 | player0x, topP1x (temp7) |
| $82-$84 | missile0x, missile1x, ballx |
| $85 | SpriteGfxIndex |
| $8e-$8f | spritedisplay, player0xcoll |
| $90-$98 | player1x-player9x (NewSpriteX) |
| $99 | player0y |
| $9a-$a2 | player1y-player9y (NewSpriteY) |
| $a3-$a4 | player0color |
| $a5-$ae | player0height-player9height |
| $af-$b7 | _NUSIZ1, NUSIZ2-NUSIZ9 |
| $b8-$ba | score |
| $bb-$bc | COLUM0, COLUM1 |
| $bd-$c4 | player0 pointer lo/hi, missile0y, missile1y, bally, missile0height, missile1height, ballheight |
| $c5-$c9 | statusbarlength/aux3, lifecolor/pfscorecolor, aux4, lifepointer/pfscore1/aux5, lives/pfscore2/aux6 |
| $ca | playfieldpos |
| $cb-$d0 | temp1-temp6 |
| $d1-$ea | a-z |
| $eb | scorecolor |
| $ec-$f4 | var0-var8 |
| $f6-$f9 | stack1-stack4 |

## pfheight (multisprite kernel)

`pfheight` is a variable setting playfield block height minus one. Valid values: **31, 15, 7, 3, 1, 0**.

- `pfheight = 0` gives ~88 rows but misbehaves when sprites are on screen — only useful for static displays like title screens.
- `pfheight = 1` is the highest resolution for general-purpose use.

```bB
   set kernel multisprite
   pfheight = 1
```

## screenheight (multisprite kernel)

```bB
   const screenheight = 80
```

Shrinks the multisprite screen by 8 pixels. Only **80** and **84** are supported; 80 only works for row heights < 8, 84 only for row heights < 4. Other values may do strange things.

## Titlescreen kernel (brief)

The Titlescreen Kernel (by RevEng) is a separate assembly module for high-quality title screens without writing assembly — it can scroll images, animate frames, change colors, etc. Gotchas: set **REFP0 and REFP1 to zero before jumping back to it** or the image gets reversed/scrambled; when leaving the title screen, set missile0height and missile1height to zero (or set them in your setup) and move missiles off screen; if you use pfheights, redefine the heights after leaving.

## Example programs

(See `examples/` in the skill.) `sprite_missile_bankswitching_example` — bankswitching with title/game-over screens; `ex_dpc_13_objects` — DPC+ 10 sprites + 2 missiles + ball with coordinates; `ex_dpc_shooting_nusiz` — 7 virtual sprites become 17 via NUSIZ copies; `ex_multisprite_9_objects` — multisprite 6 sprites + 2 missiles + ball; `dpc_harmony` — DPC+ template with `temp1=temp1` fixes; `ex_princess_rescue` and `ex_seaweed_assault` — full games; `ex_dpc_lilla_score_change_color` — DPC+ score color without minikernels.

## Common mistakes

- Using `set kernel_options` with the multisprite or DPC+ kernels — they only work with the standard kernel (DPC+'s single exception is `collision(player1,playfield)`).
- Using an invalid single option (`playercolors`, `readpaddle`, `background` alone) or forgetting `readpaddle` needs `no_blank_lines`.
- Forgetting a cost: `player1colors` kills missile1; `playercolors`/`no_blank_lines`/`readpaddle` kill missile0; `pfcolors`+`pfheights` locks colors/heights.
- With multisprite: expecting `collision(player0,player2)` to work (only player1 is valid), using playfield plotting commands or `pfclear` (won't compile), forgetting the playfield is mirrored and y is inverted (bottom = 0, top ≈ 88), or forgetting virtual sprites render upside-down.
- With multisprite >4k: forgetting `includesfile multisprite_bankswitch.inc` as the first line.
- With DPC+: declaring `set romsize 32k` (it's automatic), putting code in bank 1 (only a `goto` fits), using `vblank` (no room/cycles), disabling sprites with y=0 instead of y≈200, or expecting 48+ extra variables (only var0-var8).
- In bankswitched games: reading a data table from a different bank than where it's defined (impossible), constantly cross-bank `gosub`bing (cycle penalty), or forgetting the bank suffix (`goto label bank2`).
- `return thisbank` in a subroutine that is ever called from another bank — it crashes.
- Using Superchip r/w variables as for…next counters, in fixed-point math, or on the wrong side of `=`.
- Using `set optimization none` alongside other optimization lines (it disables them), or putting multiple optimization options on one line (each needs its own line).
