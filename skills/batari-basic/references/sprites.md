# batari Basic Sprites, Missiles, and the Ball

Purpose: complete reference for the movable objects — player0/player1 sprites (graphics, colors, sizes, copies, heights, flipping, animation, movement), missile0/missile1, and the ball — with exact coordinates, value tables, and kernel differences. For LLMs that know normal BASIC but little about the Atari 2600.

Contents: [The five objects](#the-five-objects) · [player0: / player1: graphics](#player0--player1-graphics-blocks) · [COLUP0 / COLUP1](#sprite-colors-colup0--colup1) · [player0x/player0y coordinates](#position-player0x-player0y-player1x-player1y) · [Edge clamping and wall collision prevention](#keeping-objects-on-screen-edge-clamping--wall-collision-prevention) · [8.8 fixed-point movement](#smooth-movement-88-fixed-point) · [playerheight](#sprite-height-player0height--player1height) · [Animation via pointerlo/pointerhi](#animation-swapping-graphics-with-player0pointerlo--player0pointerhi) · [NUSIZ0/NUSIZ1](#size-and-copies-nusiz0--nusiz1) · [REFP0/REFP1](#flipping-refp0--refp1) · [Missiles](#missiles-missile0x-missile0y-missile0height) · [Ball](#the-ball-ballx--bally--ballheight) · [player1colors/playercolors](#multicolored-sprites-player1colors--playercolors-kernel-options) · [Priority](#object-priority) · [Multisprite/DPC+ differences](#multisprite-and-dpc-kernel-differences) · [Common mistakes](#common-mistakes)

## The five objects

The standard kernel can move five objects plus a background playfield:

| Object | Variables | Color comes from |
|---|---|---|
| player0 (sprite) | player0x, player0y, player0height | COLUP0 |
| player1 (sprite) | player1x, player1y, player1height | COLUP1 |
| missile0 (solid rectangle) | missile0x, missile0y, missile0height | COLUP0 (same as player0) |
| missile1 (solid rectangle) | missile1x, missile1y, missile1height | COLUP1 (same as player1) |
| ball (solid rectangle) | ballx, bally, ballheight | COLUPF (same as the playfield) |

- A "sprite" is 8 pixels wide. Players can be **any height up to 256 rows**; missiles/ball are solid rectangles of settable height.
- The standard kernel draws double-height pixels (2 scanlines per pixel row) — that's why bB sprites look chunkier than classic-game sprites. The DPC+ kernel uses single-height sprite pixels.
- x/y/height variables **keep their values across drawscreen** — set once, then change only when you want movement.

## player0: / player1: graphics blocks

Syntax (defines sprite shape; standard kernel):

```bb
   player0:
   %00111100
   %01111110
   %11000011
   %10111101
   %11111111
   %11011011
   %01111110
   %00111100
end
```

- Each line is one row of the sprite, 8 pixels wide, written in binary: `%` then eight `0`/`1` digits (`%0110` style is not allowed — always all 8 bits). `1` = pixel on, `0` = off.
- The first line in the block is the **bottom** row of the sprite — sprite data is upside down in your code.
- Any number of rows (up to 256 total height). The block above (8 rows) is the classic 8x8 sprite.
- The block ends with `end` on its own line, and the rows must be indented (3 spaces shown here).
- Sprite definitions can be placed **outside the main loop** — the standard kernel keeps displaying them until you change them. (Exception: some multisprite kernel versions need player0: redefined inside the loop.)
- Redefining `player0:` … `end` inside the game loop also works (that's how `examples/ex_jumping_sprite.bas` animates), but every inline block costs ROM bytes and **resets player0height** (see below).

Wider or multiple sprites: you cannot draw wider data — the data is always 8 wide. Use NUSIZx (double/quadruple width or 2-3 copies) or stack objects. See [NUSIZ](#size-and-copies-nusiz0--nusiz1).

## Sprite colors: COLUP0 / COLUP1

Syntax: `COLUP0 = $9C` / `COLUP1 = $AE` (NTSC color values, e.g. `$9C` pink, `$1E` yellow, `$0A` gray).

- COLUP0 colors player0 **and missile0**; COLUP1 colors player1 **and missile1**.
- Players are **black by default** and will be invisible on a black background — set the color before the first drawscreen.
- **Set COLUP0/COLUP1 inside the game loop, every frame.** drawscreen resets them to the score color (the score is drawn with these two registers). COLUBK (background) and COLUPF, by contrast, are persistent.
- Write-only: `a = COLUP0` does not work.
- In the DPC+ kernel, missile colors are set separately with COLUM0/COLUM1.
- Multicolored sprites (standard kernel): see [player1colors/playercolors](#multicolored-sprites-player1colors--playercolors-kernel-options); DPC+ sprites are multicolored by default.

## Position: player0x, player0y, player1x, player1y

Syntax: `player0x = 77 : player0y = 53` (whole numbers 0-255).

Useful ranges (standard kernel): player0x/player1x **0 to 159**, player0y/player1y **0 to about 88**. Higher y values or x values above 159 just move the object off screen (you may see some jumping near the extreme edges).

For an 8-row, 8-pixel-wide sprite to stay **fully visible**, clamp to these edges (constants used by `examples/ex_move_sprite.bas`):

| Constant (8x8 sprite) | Value |
|---|---|
| _P_Edge_Top | 9 |
| _P_Edge_Bottom | 88 |
| _P_Edge_Left | 1 |
| _P_Edge_Right | 153 |

Gotchas:

- **Avoid player x = 0** with normal width — sprites can wrap/jump at the screen edges; Random Terrain's border-coordinates program forces x back to 1 at normal width.
- If you widen a player with NUSIZx, the right edge shrinks: **153** (normal 8 px), **144** (double width), **128** (quadruple width).
- Ball/missile coordinates are offset from player coordinates by about 1 pixel — align by hand (e.g. `missile0x = player0x + 4` roughly centers a missile on the sprite).

## Keeping objects on screen (edge clamping + wall collision prevention)

Canonical joystick movement with edge clamping (from `examples/ex_move_sprite.bas`):

```bb
   if joy0up && player0y > _P_Edge_Top then player0y = player0y - 1
   if joy0down && player0y < _P_Edge_Bottom then player0y = player0y + 1
   if joy0left && player0x > _P_Edge_Left then player0x = player0x - 1
   if joy0right && player0x < _P_Edge_Right then player0x = player0x + 1
```

To also stop the sprite from entering playfield walls (collision **prevention** — no sticky walls, the sprite glides along walls when moved diagonally), check the playfield pixels with `pfread` **before** moving. From `examples/ex_sprite_with_collision_prevention.bas` (sprite is 8x8, standard playfield rows are 8 scanlines / 4 pixels wide):

```bb
   rem  Moving up: check the row the top edge will enter.
   temp5 = (player0x-10)/4
   temp6 = (player0y-9)/8
   if temp5 < 34 then if pfread(temp5,temp6) then goto __Skip_Joy0_Up
   temp4 = (player0x-17)/4
   if temp4 < 34 then if pfread(temp4,temp6) then goto __Skip_Joy0_Up
   temp3 = temp5 - 1
   if temp3 < 34 then if pfread(temp3,temp6) then goto __Skip_Joy0_Up
   player0y = player0y - 1
__Skip_Joy0_Up
```

Test left/right movement the same way (x uses `(player0x-18)/4` into the pfread column, y uses `(player0y-1)/8`). A variant for `const pfrowheight=7` with an 11-row sprite is `examples/ex_sprite_with_collision_prevention_and_pfrowheight7.bas`; one that also bounces the ball and shoots the missile is `examples/ex_sprite_ball_missile_collision_prevention.bas`.

## Smooth movement: 8.8 fixed point

Whole-number coordinates make sprites move in whole pixels — fast and choppy. For smooth sub-pixel speed, attach a fractional byte directly to the sprite coordinate with `dim`:

```bb
   dim _P0_L_R = player0x.a
   dim _P0_U_D = player0y.b
   dim _P1_L_R = player1x.c
   dim _P1_U_D = player1y.d
```

Now `_P0_L_R` is an 8.8 fixed-point value (0 to 255, fraction accurate to 1/256):

```bb
   _P0_L_R = _P0_L_R - 0.85
   _P0_L_R = _P0_L_R + 2.0
   _P0_U_D = _P0_U_D - 1.052
```

drawscreen uses the integer part (player0x) automatically. Rules that surprise normal BASIC programmers:

- Assigning an 8.8 to a plain integer drops the fraction (like `int()`): `player0x = _P0_L_R` works but rounds down.
- In `if` statements the fraction is ignored: `if _P0_L_R = 5 then …` is true for 5.00 to 5.99.
- To test the fraction, read the aliased variable (`a`, `b`, …) directly — note the value is then the fraction × 256.
- Mixing 4.4 and 8.8 types in one statement requires `include fixed_point_math.asm` near the top of the program.
- A cheaper smooth-look alternative is the Bresenham-style chase in `examples/ex_smooth_chase.bas`.

## Sprite height: player0height / player1height

Syntax: `player0height = 8` / `player1height = 5`.

- The height variable is **set automatically** by the `player0:`/`player1:` block (an 8-row sprite gives height 7; a 9-row sprite gives height 8).
- Change it at runtime to make a sprite appear to "melt away" or grow without drawing new frames. From `examples/mini_ex_playerheight.bas`:

```bb
   if !joy0up then goto __Skip_Up
   if player0height < 8 then player0height = player0height + 1
__Skip_Up
   if !joy0down then goto __Skip_Down
   if player0height > 0 then player0height = player0height - 1
__Skip_Down
```

- Values: 0 (about one pixel row visible) up to the number of drawn rows minus 1. You cannot grow taller than the data that's in ROM — each extra row of sprite data costs 1 ROM byte.
- To melt away completely or grow from nothing, keep a blank row `%00000000` at the very bottom of the sprite data.
- Redefining the sprite with `player0:` resets the height — re-set player0height afterwards if you use custom heights and animation together.
- Kernel availability: standard kernel has player0height/player1height; multisprite kernel player0height-player5height; DPC+ kernel player0height-player9height.

## Animation: swapping graphics with player0pointerlo / player0pointerhi

Faster than re-issuing `player0:` blocks: point the sprite at existing graphics data in ROM. Each sprite has a two-byte pointer (standard kernel): **player0pointerlo** (also writable as `player0pointer`) and **player0pointerhi**; likewise **player1pointerlo / player1pointerhi**. Set both bytes every time you swap frames:

```bb
   temp5 = _Anim_Frame * 8
   player0pointerhi = _Frames_High
   player0pointerlo = temp5 + _Frames_Low
```

The classic trick (from Random Terrain) reuses the built-in score-digit graphics for numbers:

```bb
   const _c_score_table_high = >scoretable
   const _c_score_table_low = <scoretable

   dim _DisplayNumber = q

   rem  Inside the game loop — grab digit graphic for player0:
   temp5 = _DisplayNumber
   player0pointerhi = _c_score_table_high
   temp5 = temp5 * 8
   player0pointerlo = temp5 + _c_score_table_low
```

- Set color, position, and NUSIZx as normal; a double-width NUSIZx value makes the digit look proportioned like the score.
- This works with player1 too (change the 0s to 1s). In the multisprite kernel it works for player1-player5 (set the height to 9 instead of 7) but **not** player0. It does not work in the DPC+ kernel.
- Warning for hand-built frame tables: if a frame's 8 rows cross a 256-byte page boundary, the sprite breaks up — keep each sprite's frames within one page (the score-table version is safe; scoretable is page-aligned).
- Changing pointers does not change player0height — keep all frames the same height, or set the height when you set the pointers.

## Size and copies: NUSIZ0 / NUSIZ1

Syntax: `NUSIZ0 = $mp` where **m** is the missile0 setting (high nibble) and **p** is the player0 setting (low nibble). Same for NUSIZ1.

Full table (both nibbles, values 0-7):

| m | missile0 width | p | player0 effect |
|---|---|---|---|
| 0 | 1 pixel wide | 0 | 1 copy of player and missile |
| 1 | 2 pixels wide | 1 | 2 close-spaced copies |
| 2 | 4 pixels wide | 2 | 2 medium-spaced copies |
| 3 | 8 pixels wide | 3 | 3 close-spaced copies |
|   |   | 4 | 2 wide-spaced copies |
|   |   | 5 | double-sized player (2× width) |
|   |   | 6 | 3 medium-spaced copies |
|   |   | 7 | quadruple-sized player (4× width) |

Examples: `NUSIZ0 = $30` makes missile0 8 pixels wide; `NUSIZ1 = $10` makes missile1 2 pixels wide; `NUSIZ0 = $33` makes missile0 8 pixels wide **plus** three close-spaced copies of player0 and missile0.

- Copies of a player and copies of its missile are positioned together — this is the only way to display multiple copies of a sprite, and all copies share the same graphics, color, and y position (they are one object repeated).
- This is also how you make a sprite *wider* than 8 pixels: p=5 or p=7 (each pixel is stretched 2× or 4× wide — the sprite is not sharper, just bigger). Right-edge x limits: 144 (double), 128 (quadruple).
- **NUSIZ0/NUSIZ1 reset to 0 at every drawscreen — set them inside the game loop every frame.**
- Write-only: `a = NUSIZ0` does not work. To remember the setting, keep it in your own variable and combine nibbles with `&`/`|` before assigning.
- DPC+ kernel: NUSIZ/REFP behavior is different (see the DPC+ kernel notes in `kernels-and-memory.md`).

## Flipping: REFP0 / REFP1

Syntax: `REFP0 = 8` (reflect) / `REFP0 = 0` (normal). Same for REFP1. Value is 0 or 8 only.

Flips a sprite **horizontally** — useful for asymmetric sprites so they appear to change direction without new graphics. From `examples/mini_ex_flip_sprite.bas`:

```bb
   if joy0left then _Bit6_Flip_P0{6} = 0 : _Bit7_Flip_P1{7} = 0
   if joy0right then _Bit6_Flip_P0{6} = 1 : _Bit7_Flip_P1{7} = 1
   if _Bit6_Flip_P0{6} then REFP0 = 8
   if _Bit7_Flip_P1{7} then REFP1 = 8
```

- **REFP0/REFP1 are reset to 0 by every drawscreen** (bB uses them to draw the score), so set them inside the game loop when needed — and you get the "unflip" for free each frame (no code needed to clear them).
- Write-only: they cannot be read.
- (Vertical flipping is not a TIA feature — draw the sprite data upside down instead; remember the data is already stored bottom-row-first.)

## Missiles: missile0x, missile0y, missile0height

Syntax:

```bb
   missile0x = 64
   missile0y = 64
   missile0height = 8
```

- Missiles are solid rectangles. Only width, height, and color can be changed — **no sprite graphics** can be applied to them. They share their player's color (COLUP0/COLUP1).
- Width: only 1, 2, 4, or 8 pixels, set by the **m nibble of NUSIZ0/NUSIZ1** (see table above). Width applies to the missile; copies settings (p nibble) repeat the missile with the player.
- Height: `missile0height` in pixel-row units; a missile can be as tall as the screen.
  - Standard kernel: smallest height is 0, which still shows a missile about 2 scanlines (one pixel row) tall. You cannot make it shorter.
  - Multisprite kernel: missiles are fixed at one unit high; the height variables do not exist. One or both missiles can be unavailable depending on kernel options.
  - DPC+ kernel: smallest usable height is 2. Height 0 makes the missile seem to disappear; height 1 makes it appear on even rows and vanish on odd rows.
- For a roughly square missile, pair width and height like this (from Random Terrain's border-coordinates program):

| Missile/ball width | NUSIZ m nibble | height value | top y limit | right x limit |
|---|---|---|---|---|
| 1 pixel | 0 ($x0) | 0 | 1 | 161 |
| 2 pixels | 1 ($x1) | 1 | 2 | 160 |
| 4 pixels | 2 ($x2) | 3 | 4 | 158 |
| 8 pixels | 3 ($x3) | 6 | 7 | 154 |

- Visible coordinate ranges (standard kernel, from the same program): x from 2 to the right limit above; y from the top limit above to 88. A simpler working set used by `examples/ex_sprite_with_missile.bas`: y 2-88, x 2-159.
- **Hiding a missile:** move it off screen — `missile0x = 200 : missile0y = 200`. (Height 0 still draws ~2 scanlines in the standard kernel, so don't rely on height to hide it.)
- Shooting pattern (`examples/ex_sprite_with_missile.bas`): park the missile off screen, set `NUSIZ0 = $10 : missile0height = 1` (2-pixel missile), on fire copy a position relative to the player (`missile0x = player0x + 6 : missile0y = player0y - 3` for shooting right, `+ 4 / - 5` up, `+ 2 / - 3` left, `+ 4 / - 1` down), then move it 2 pixels per frame, deleting it with the off-screen trick when it passes an edge or hits the playfield (`if collision(playfield,missile0)`).
- **Reviving lost missiles:** kernel options can eat missile0/missile1. You can turn a lost missile back on as a full-height (top-to-bottom) strip with `ENAM0 = 2` or `ENAM0{1} = 1` (turn off with `ENAM0 = 0` or `ENAM0{1} = 0`). Next to a multicolored sprite, the strip shows the sprite's row colors — `examples/mini_ex_enam_multi.bas` turns missile1 into a tall multicolored strip (with `NUSIZ1 = $20` for 4 pixels wide). Such strips also make good side borders.

## The ball: ballx, bally, ballheight

Syntax:

```bb
   ballx = 64
   bally = 64
   ballheight = 4 : rem * Ball 4 pixels high.
   CTRLPF = $21 : rem * Ball 4 pixels wide, normal playfield.
   COLUPF = $1E : rem * Ball/playfield color.
```

- The ball is one solid rectangle, accessed like the missiles: ballx, bally, ballheight.
- **The ball is always the same color as the playfield** (COLUPF). With a multicolored playfield (pfcolors), the ball takes the color of whatever playfield row it is on.
- Width (1, 2, 4, or 8 pixels) is set by the **b nibble of CTRLPF**: use value `$bp` where b is 0/1/2/3 for 1/2/4/8 pixels wide.

| b | ball width | p | playfield effect |
|---|---|---|---|
| 0 | 1 pixel | 1 | normal bB playfield |
| 1 | 2 pixels | 3 | split-color playfield (left half player0 color, right half player1 color) |
| 2 | 4 pixels | 5 | players move behind playfield (priority) |
| 3 | 8 pixels | 7 | both split-color and players-behind |

- Keep the p nibble **odd** (1, 3, 5, or 7) — the bB standard kernel expects that low bit set; setting CTRLPF with p=0 can make the playfield display incorrectly.
- CTRLPF is **persistent** (unlike NUSIZ/REFP/COLUP0/COLUP1) — set once and it sticks across drawscreens. Write-only: it cannot be read.
- Ball height: same behavior as missile heights, including height 0 ≈ 2 scanlines in the standard kernel. Multisprite kernel: the ball is fixed at one unit high and ballheight does not exist.
- Visible ranges are the same table as missiles (x 2-161/160/158/154, y 1/2/4/7-88 by width; bottom limit 88).
- A bouncing ball plus shooting plus wall-collision prevention in one program: `examples/ex_sprite_ball_missile_collision_prevention.bas`.

## Multicolored sprites: player1colors / playercolors (kernel options)

Standard-kernel only kernel options (see also `kernels-and-memory.md`):

```bb
   set kernel_options player1colors      rem  player1 multicolored (loses missile1)
   set kernel_options player1colors playercolors   rem  both (also loses missile0)
```

- `player1colors`: player1 can have a different color per row. **Cost: loss of missile1.**
- `playercolors`: both players multicolored. **Must be used together with player1colors.** **Cost: also loss of missile0.**
- Define colors with `player0color:` and `player1color:` blocks — one color value per line, matching the sprite's rows (also bottom-row-first, same upside-down order as the graphics):

```bb
   player1color:
   $94
   $96
   $98
   $9A
   $9C
   $9A
   $98
   $96
end
```

- Changing player colors this way also affects the missile colors on the scanlines where the colors change (the missile shares the player's color pipeline).
- Full program: `examples/ex_multicolored_sprite.bas`. The DPC+ kernel has multicolored sprites without these options.

## Object priority

Default TIA draw order (front to back), when CTRLPF priority is off:

```text
   player0 > missile0 > ball > player1 > missile1 > playfield > background
```

- Note player1 is behind player0, and everything is in front of the playfield by default.
- To put players (and missiles) **behind the playfield**, set the playfield-priority bit: CTRLPF p nibble = 5 (or 7 with split colors). Order becomes playfield > ball > player0 > missile0 > player1 > missile1 > background.
- Toggle priority with the fire button as in `examples/ex_priority.bas`:

```bb
   temp5 = 1 : temp5{2} = _Bit7_Flip_CTRLPF{7} : CTRLPF = temp5
```

Bit 2 (value 4) is the priority bit; keep bit 0 set. Do not change the `2` in `temp5{2}` — the example only works with that bit.
- For "player in front when lower on the screen" tricks, swap which sprite you draw to (player0 is always on top) instead of fighting the hardware.

## Multisprite and DPC+ kernel differences

Brief — full details in `kernels-and-memory.md`:

- **Multisprite kernel** (`set kernel multisprite`): six sprites. player0 works much like the standard kernel (some versions require defining player0: inside the game loop). **player1-player5 are virtual sprites** — they are the 2600's second hardware sprite (player1) repositioned several times down the screen, so they **share player1's hardware**: they are drawn **vertically flipped (upside down)** — draw their data upside down or flip them with bit 3 of `_NUSIZ1` / `NUSIZ2`-`NUSIZ5` (set value 8). Virtual sprites flicker automatically if two occupy the same vertical region. `player2`-`player5` are not valid in `collision()` — a collision with player1 means you hit one of the virtuals (check y positions to find out which). Their color/size variables `_COLUP1`, `COLUP2`-`COLUP5`, `_NUSIZ1`, `NUSIZ2`-`NUSIZ5` live in RAM and are persistent. Missiles are fixed 1 unit high and may be lost to kernel options; missile1's appearance can be affected by any of player1-5's NUSIZ/COLUP values depending on where it is.
- **DPC+ kernel** (`set kernel DPC+`): ten multicolored single-height-pixel sprites (player1-player9 are virtual); missile colors use COLUM0/COLUM1; missile heights 0/1 misbehave (see [Missiles](#missiles-missile0x-missile0y-missile0height)); NUSIZx and REFPx work differently than described above — check the DPC+ docs before using them. The score-digit pointer trick does not work in DPC+.

## Common mistakes

- Setting COLUP0/COLUP1, NUSIZ0/NUSIZ1, or REFP0/REFP1 **outside the main loop** — drawscreen resets them (COLUP0/COLUP1 to the score color, NUSIZ/REFP to 0). Set them every frame inside the loop. (CTRLPF is the persistent one.)
- Forgetting to set a sprite color — sprites default to black and vanish on a black background.
- Drawing sprite data top-row-first — the first line of a `player0:` block is the **bottom** row.
- Expecting 4-wide/16-wide sprite data — player data is always 8 pixels wide; use NUSIZx p=5/p=7 to stretch.
- Letting a sprite reach x = 0 (wrap/jump glitches) or x > 153 / y > 88 (off screen), or widening a sprite without pulling in the right-edge limit (144/128).
- Trying to hide a standard-kernel missile with height 0 — it still shows ~2 scanlines; move it off screen (x=200, y=200).
- Using missile0 after enabling `playercolors`/`no_blank_lines`, or missile1 after `player1colors` — those options delete the missiles (revive as strips with `ENAM0{1} = 1` / `ENAM1{1} = 1` if useful).
- Reading TIA registers (`a = NUSIZ0`, `a = REFP0`, `a = CTRLPF`, `a = COLUP0`) — they are write-only; mirror values in your own variables.
- Setting `playercolors` without `player1colors` — invalid; they must be used together.
- Expecting player2-player5 in the multisprite kernel to be independent objects for collision() — they are virtual reuses of player1.
- Animating by re-issuing `player0:` blocks every frame when pointer-swapping (player0pointerlo/player0pointerhi) would be smaller and faster — and forgetting that `player0:` resets player0height.
