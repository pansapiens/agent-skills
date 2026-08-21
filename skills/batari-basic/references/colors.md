Complete reference for Atari 2600 colors in batari Basic: how the hue+luminance byte works, which register colors which object, usable color values, PAL differences, and pulsating/blinking effects.

**Covers:** how color works · color byte format · NTSC color table · COLUBK · COLUPF · COLUP0 · COLUP1 · scorecolor · pfscorecolor/lifecolor/statusbarcolor · pfcolors · playercolors · DPC+ colors · drawscreen timing · PAL/PAL-60 · swappable color constants · pulsating/blinking techniques

## How Atari 2600 color works (NOT RGB)

The Atari 2600 does **not** use RGB color values. There is no `$RRGGBB`. It uses a **hue + luminance** system: every color is one byte holding a hue (which color family) plus a luminance (how bright). NTSC consoles can display up to **128 unique colors** — **16 unique hues with 8 luminance levels each**. PAL consoles can display **104 unique colors** (**13 hues with 8 luminance levels**). SECAM consoles display only **8 colors**.

Color numbers look the same in every kernel (standard, multisprite, DPC+). What differs per kernel is *which registers/variables* you use to apply them (see below).

Because it is hue+luminance and not RGB, a color like `$1C` cannot be "made brighter by adding white" — you brighten it by raising the luminance nibble (`$1C` → `$1E`), and you change color family by changing the hue nibble (`$1C` → `$2C`).

## Color byte format: hue + luminance

A color value is one byte `$xy` where:

- **High nibble `x` = hue** (0–F): 0 is gray, 1–F are colored hues (gold through cream — see table below).
- **Low nibble `y` = luminance** (brightness): only even values `0, 2, 4, 6, 8, A, C, E` are normally used.

So `$C2` = hue C (green), dark. `$CE` = hue C (green), bright. `$0A` = light gray. Same hue + higher luminance = same color, brighter.

The TIA color chart is laid out exactly this way: hue columns 0–F, luminance rows 2, 4, 6, 8, A, C, E.

**Gotcha — colors are darker on real televisions than in emulators.** Some of the darker grays may appear black. The source gives a concrete example: if you are using 2, 4, and 6 (grays `$02`, `$04`, `$06`), you might need to bump up to 6, 8, and 10 (`$06`, `$08`, `$0A`) to display brightly enough on most televisions.

### Odd luminance values (avoid them)

Only **even** luminance values should be used. Every chart, table, and color-constants list in the bB documentation uses only even luminance values (`$x2`, `$x4`, `$x6`, `$x8`, `$xA`, `$xC`, `$xE`). The 2600's real palette is 8 luminance steps per hue; odd values just squeeze in half-steps that are nearly indistinguishable from the even ones, and they are wasted on PAL consoles (PAL has only 13 usable hues and 8 luminance steps — a PAL machine does not see the same thing you previewed in an NTSC emulator). Odd values also make color math messy. Unless a technique deliberately walks through every value (see the pulsating cursor below), stick to even luminances.

## Compact NTSC color table

Approximate NTSC hue names (individual TVs and emulators vary slightly; pick final colors with the online "TIA Color Charts and Tools" / Color Compatibility Tool, then copy the number it displays). Hue 0 is gray — the luminance nibble alone picks the shade. Use this table to pick a starting value, then adjust the luminance nibble up/down in steps of 2.

| Hue | Color name (NTSC, approx.) | Usable values, dark → bright |
|-----|----------------------------|------------------------------|
| 0   | Gray / white               | `$02` `$06` `$0A` `$0E` (dark grays look black on TVs) |
| 1   | Gold / brown-gold          | `$12` `$16` `$1A` `$1E` |
| 2   | Gold-orange / orange       | `$22` `$26` `$2A` `$2E` |
| 3   | Orange-red                 | `$32` `$36` `$3A` `$3E` |
| 4   | Red / salmon-pink          | `$42` `$46` `$4A` `$4E` |
| 5   | Lavender / purple          | `$52` `$56` `$5A` `$5E` |
| 6   | Purple / violet            | `$62` `$66` `$6A` `$6E` |
| 7   | Indigo / blue-violet       | `$72` `$76` `$7A` `$7E` |
| 8   | Blue                       | `$82` `$86` `$8A` `$8E` |
| 9   | Sky blue / light blue      | `$92` `$96` `$9A` `$9E` |
| A   | Cyan / turquoise           | `$A2` `$A6` `$AA` `$AE` |
| B   | Teal / sea green           | `$B2` `$B6` `$BA` `$BE` |
| C   | Green                      | `$C2` `$C6` `$CA` `$CE` |
| D   | Olive / dark yellow-green  | `$D2` `$D6` `$DA` `$DE` |
| E   | Yellow / mustard           | `$E2` `$E6` `$EA` `$EE` |
| F   | Cream / light yellow       | `$F2` `$F6` `$FA` `$FE` |

Mid-values like `$24`, `$28`, `$2C` etc. fill the gaps between the listed steps. Examples used elsewhere in the docs: `$2C` (medium gold-orange), `$CE` (bright green), `$0A` (light gray), `$FE` (bright cream), `$68` (purple), `$84` (medium blue), `$1C` (bright gold).

## Which register colors what

| Register/variable | Colors |
|-------------------|--------|
| `COLUBK` | Background |
| `COLUPF` | Playfield **and** ball |
| `COLUP0` | player0 sprite **and** missile0 |
| `COLUP1` | player1 sprite **and** missile1 |
| `scorecolor` | Score |
| `pfscorecolor` | pfscore bars (if enabled) |
| `lifecolor` | Lives (lifecounter minikernel) |
| `statusbarcolor` | Status bar minikernel (optional) |

Key facts:

- The **missiles must share their colors with their respective player objects** (missile0 = COLUP0, missile1 = COLUP1). You cannot give missile0 its own color register.
- The **ball is generally the same color as the playfield** (COLUPF).
- Each player object can be colored independently, as can the playfield, background, score, and objects drawn in a minikernel. Multicolored objects are possible via kernel options (see pfcolors and playercolors below).
- **In the DPC+ kernel**, missile0 and missile1 colors are set with `COLUM0` and `COLUM1` instead of sharing the player colors.
- **In the multisprite kernel**, virtual sprites 1–5 use special RAM variables `_COLUP1`, `COLUP2`–`COLUP5` that resemble TIA registers but are not — they are persistent. (Also, bit 3 of `_NUSIZ1`/`NUSIZ2`–`NUSIZ5` holds the REFP value in that kernel.)

## COLUBK (background)

Sets the background color.

```bb
   COLUBK = $80
```

- A multicolored background is possible with the standard kernel via the `background` kernel option (which reuses `pfcolors` data — see below), or with the DPC+ kernel (`bkcolors:`).

**Write-Only:** COLUBK cannot be read. `a = COLUBK` will not work properly.

## COLUPF (playfield + ball)

Sets the playfield color and the ball color.

```bb
   COLUPF = $CE
```

- If you use pfscore bars, you must have `COLUPF` in your main loop or the playfield will become the color of the pfscore bars.
- Multicolored playfield: use the `pfcolors` kernel option (standard kernel) or the DPC+ kernel.
- If you use the `background` kernel option, `COLUPF` won't work (and neither will `pfcolors` inside the main loop, unless `no_blank_lines` is also used) — use `COLUBK` for the top-row color instead.

**Write-Only:** COLUPF cannot be read.

## COLUP0 and COLUP1 (players + missiles)

Set the colors for player0/missile0 and player1/missile1. These are **ephemeral** — set them inside the game loop (see drawscreen timing below).

```bb
   COLUP0 = $0A
   COLUP1 = $FE
```

- Multicolored sprites: standard kernel `player1colors`/`playercolors` kernel options, or any player in the DPC+ kernel (`player0color:`/`player1color:` tables).
- DPC+ kernel: missile colors are `COLUM0`/`COLUM1`.

**Write-Only:** neither register can be read.

## scorecolor

Sets the score color — the score will not appear until you set it. Value is a number 0–255 per the color chart.

```bb
   scorecolor = $68
```

- Standard kernel: `const scorefade = 1` enables a score fade effect that adds shading to the score.
- DPC+ kernel: use `scorecolors:` (one color per score row, followed by `end`) for gradients:

```bb
   scorecolors:
   $3E
   $3C
   $3A
   $38
   $36
   $36
   $34
   $32
end
```

## pfscorecolor, lifecolor, statusbarcolor

- `pfscorecolor = $84` — color of the pfscore bars, if enabled.
- `lifecolor = value` — color of the lives. When using bankswitching, this must be in your main loop or called from your main loop.
- `statusbarcolor` — optional status bar minikernel color; if unused, the status bar is the same color as the playfield. You must reserve one of your 26 user variables with `dim`:

```bb
   dim statusbarcolor = t
   statusbarcolor = $1C
```

## pfcolors (playfield color per row)

Standard-kernel kernel option that specifies the color of each playfield row. Must specify **11 or more values, one to a line, followed by `end`** (11 rows in the standard playfield; use 12–13 to work around row bugs). You can redefine it as many times as you want. Enable it with `set kernel_options pfcolors` (see the kernel_options chart for legal combinations).

```bb
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

Warnings (all from the source):

- **Top row bug:** if `pfcolors` is outside your main loop, the top row may not be the color you selected. Fix: put `pfcolors` inside your main loop, or put `COLUPF` in your main loop set to the top row's color. With `no_blank_lines`, the top row is correct but the **bottom** row color will be wrong — use 12 colors and make the 12th the same as the 11th.
- With the `background` kernel option added, `COLUPF` stops working; put `COLUBK` in your main loop set to the top-row color. Without `no_blank_lines`, `background` also causes a stairstep timing effect.
- **PF0 color taint fix:** if you use PF0 as a side border and the bottom of the border is tainted with another color, use 12 colors and make the 12th row match the 11th.
- When using `pfcolors` and `pfheights` together, you can only define `pfheights:` and `pfcolors:` **one time**, and `pfheights:` must be defined **first**. If you use pfcolors and compile without defining `pfcolors:`, you will probably get an error.

**background kernel option:** instead of a multicolored playfield, the `pfcolors` data colors the *background* rows (loss of missile0), with the usual single-color playfield pixels on top. See the full example in the kernel options documentation.

## player1colors / playercolors (multicolored sprites)

Standard-kernel options that define player colors a row at a time using `player0color:` / `player1color:` tables:

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

- `player1colors` loses missile1; adding `playercolors` (which enables it for both players, and cannot be set alone) also loses missile0. Decide whether multicolored sprites are worth losing the missiles.
- The DPC+ kernel has per-row `player0color:`/`player1color:` tables built in (called playerxcolor there).
- The Colorplayers standard-kernel mod (by RevEng) lets you use `no_blank_lines` and have **two** multicolored sprites; the trade-offs are losing both missiles and the center bytes of the playfield become symmetric.

## DPC+ color extras

- `bkcolors:` — one color per **scanline** of background, followed by `end` (the example walks $80 → $8E blues then $F0 → $F8 creams). `DF6FRACINC = 0` makes the whole background one color (define a single value). The value in DF6FRACINC determines how many times the background color can change from top to bottom.
- `scorecolors:` — per-row score colors (gradient) as shown above.
- `COLUM0` / `COLUM1` — missile0/missile1 colors.

## When color changes take effect (drawscreen)

TIA registers latch when `drawscreen` draws the screen, so a color assignment never shows up instantly — it appears on the **next drawscreen**. Change the value, then `drawscreen`.

Which registers survive a drawscreen:

- **Persistent** (set once, stay set): `COLUBK` (unless the `background` kernel option is set), `COLUPF` (unless pfscorecolor variables are used and/or the `pfcolors` kernel option is set), `CTRLPF`, and the audio registers.
- **Wiped every drawscreen:** `COLUP0` and `COLUP1` are reset to the same value as `scorecolor`. If you want a player color different from the score color, you must set `COLUP0`/`COLUP1` **inside your main loop** before every `drawscreen`.

```bb
__Main_Loop
   COLUP0 = $46
   COLUP1 = $C6
   drawscreen
   goto __Main_Loop
```

## PAL, PAL-60, and SECAM

- **Same numbers, different colors.** The PAL palette is different from NTSC: the same color byte renders different hues on a PAL console, and some NTSC colors have no PAL counterpart. PAL has 13 hues × 8 luminance = 104 colors; SECAM has only 8 colors.
- PAL televisions will play NTSC binaries without problems, but the colors won't look the same.
- **Do not use `set tv pal`** — it builds a 50-frames-per-second PAL game (runs at a different speed than your 60 fps NTSC version). The `set tv pal` directive only changes timing and sync signals, **not the colors**.
- The recommended approach is **PAL-60**: keep NTSC timing (60 fps) and just swap in PAL palette color values.

## Swappable color constants (_xx)

To convert a game between NTSC and PAL-60 in seconds, never write raw `$xx` colors. Instead define constants with an underscore in front of the number, e.g. `const _2C = $2C`, and use `_2C` in your code. Then to make a PAL-60 version, swap the whole const list for the PAL values (`const _2C = $4C`, etc.) — every color in the game converts at once. (Only do this to *colors*, never to non-color registers like CTRLPF or NUSIZ values.)

```bb
   const _CE = $CE   ; NTSC: bright green
   const _46 = $46
   COLUPF = _CE
   COLUP0 = _46
```

Row tables convert the same way — replace the dollar signs with underscores inside the table:

```bb
   player1color:
   _06
   _04
   _08
   _0A
   _0C
end
```

The full NTSC and PAL constant lists (every even value `$00`–`$FE` in hue order, with the PAL equivalents) are on the bB page: "NTSC Color Constants and Instant PAL-60 Conversion". If your game already uses raw colors, just replace each `$` with `_` and add the matching `const` lines.

## Pulsating / blinking color techniques

Instead of flashing objects off and on or cycling random colors at eye-abusing speed, change the **luminance of one hue** at a pleasing pace (also called throbbing, fade in/fade out, ebb and flow, pulsating...). The examples live in `examples/` of this skill: `mini_ex_pulsating_hue.bas`, `mini_ex_pulsating_color_cycling.bas`, `mini_ex_pulsating_cursor.bas`.

**Warning from the source:** avoid cycling the background or playfield colors — it can be wearing on the eyes, causing eyestrain or headaches, and could possibly trigger epileptic symptoms or seizures in people with no prior history.

### Technique 1: pulsate one hue (luminance up/down)

Keep the hue nibble fixed, ramp the luminance up to a cap and back down using a **fixed-point variable** added/subtracted every frame (the frame-to-frame increment is the speed control). A bit variable flips direction at the limits. From `mini_ex_pulsating_hue.bas` (hue 1, gold — stays inside `$10`–`$1F`):

```bb
   dim _P0_Luminosity = a.b   ; 8.8 fixed point: a = whole, b = fraction
   ...
   _P0_Luminosity = $10

__Main_Loop
   ; Brighter while switch bit is off; flip at the top.
   if !_Bit6_Sequence_Switch{6} then _P0_Luminosity = _P0_Luminosity + 0.30 : if _P0_Luminosity >= $20 then _Bit6_Sequence_Switch{6} = 1

   ; Darker while switch bit is on; reset at the bottom.
   if _Bit6_Sequence_Switch{6} then _P0_Luminosity = _P0_Luminosity - 0.30 : if _P0_Luminosity <= $12 then _P0_Luminosity = $10 : _Bit6_Sequence_Switch{6} = 0

   COLUP0 = _P0_Luminosity
   drawscreen
   goto __Main_Loop
```

Note `0.30` is a fixed-point increment — the fraction builds up so the whole part steps up about every 3–4 frames, which keeps the pulse easy on the eyes. Change every frame = fast pulse; update only on a frame counter if you want it slower.

### Technique 2: pulsating color cycling (hue advances each pulse)

Same up/down luminance pulse, but when each pulse completes, add `$10` to the high and low bounds so the **next pulse uses the next hue**. From `mini_ex_pulsating_color_cycling.bas` (starts gray, low bound `$04`, high bound `$0C`):

```bb
   _Hue_Brightness_High = $0C
   _Hue_Brightness_Low  = $04
   _P0_Luminosity = $02
   ...
   ; Brightness increase section (switch bit off).
   _P0_Luminosity = _P0_Luminosity + 0.22
   if _P0_Luminosity >= _Hue_Brightness_High then _Bit6_Sequence_Switch{6} = 1 : _Hue_Brightness_High = _Hue_Brightness_High + $10

   ; Brightness decrease section (switch bit on).
   _P0_Luminosity = _P0_Luminosity - 0.22
   if _P0_Luminosity <= _Hue_Brightness_Low then _Bit6_Sequence_Switch{6} = 0 : _Hue_Brightness_Low = _Hue_Brightness_Low + $10 : _P0_Luminosity = _Hue_Brightness_Low
```

### Technique 3: pulsating cursor (gray throb)

A gray cursor that throbs from `$02` to `$0B` and back in `0.25` steps (`mini_ex_pulsating_cursor.bas`). This one deliberately walks through consecutive values including odd ones for smoothness within hue 0:

```bb
   _Cursor_Luminosity = $02
   ...
   if !_Bit6_Cursor_Throb{6} then _Cursor_Luminosity = _Cursor_Luminosity + 0.25 : if _Cursor_Luminosity >= $0C then _Cursor_Luminosity = $0B : _Bit6_Cursor_Throb{6} = 1
   if _Bit6_Cursor_Throb{6} then _Cursor_Luminosity = _Cursor_Luminosity - 0.25 : if _Cursor_Luminosity <= $01 then _Cursor_Luminosity = $02 : _Bit6_Cursor_Throb{6} = 0
   COLUP0 = _Cursor_Luminosity
```

### Technique 4: rand-based color changes

Use `rand` to pick hue or luminance on the fly. Random hue with a fixed luminance (from a border-changing example — `rand&15` gives hue 0–15, `*16` shifts it into the high nibble, `+10` is luminance `$0A`):

```bb
   _Border_Color = ((rand&15)*16)+10
```

Random *luminance* variation on a fixed hue (derived pattern — keep `rand` results even so you stay on the normal luminance steps):

```bb
   COLUP0 = $40 + (rand&14)   ; random brightness red, $42-$4E
```

As the pulsation docs warn, don't reroll colors every single frame at full speed — cycle or pulse at a gentle pace instead.

## Common mistakes

- **Assuming RGB.** The 2600 is hue+luminance, one byte: high nibble hue (0–F), low nibble luminance. `$FF` is not "white", it's bright cream; white is `$0E`.
- **Using odd luminance values.** Only even low-nibble values (2,4,6,8,A,C,E) are normal; odds are wasted on PAL and nearly indistinguishable half-steps on NTSC. All official charts/constant lists use even values only.
- **Expecting a color change to appear instantly.** Registers latch at `drawscreen` — the new color shows up on the next screen refresh.
- **Setting COLUP0/COLUP1 outside the main loop.** They are wiped back to `scorecolor` on every drawscreen; set them every frame inside the loop.
- **Expecting COLUPF to stick when using pfscore bars or pfcolors.** With pfscore bars the playfield becomes the bar color unless COLUPF is in the main loop; with the `pfcolors`/`background` options COLUPF behaves differently (see pfcolors above).
- **Trying to read a color register.** COLUBK, COLUPF, COLUP0, COLUP1 are write-only; `a = COLUP0` will not work properly.
- **Giving a missile its "own" color.** missile0/missile1 share COLUP0/COLUP1 with their players (DPC+: use COLUM0/COLUM1), and the ball is generally the playfield color.
- **Using `set tv pal` for a PAL version.** It changes timing to 50 fps, not colors — use PAL-60 (NTSC timing + PAL palette values via swappable constants) instead.
- **Assuming your emulator colors match a TV.** 2600 colors are darker on televisions; dark grays like `$02`/`$04` can look black — bump luminances up if needed.
- **Cycling background/playfield colors fast.** Per the source, this can cause eyestrain or possibly trigger seizures — pulse luminance of one hue at a gentle pace instead.

## Color tools (online)

- **TIA Color Charts and Tools** — NTSC/PAL conversion tool and color
  compatibility helpers (finds hues that work together):
  https://www.randomterrain.com/atari-2600-memories-tia-color-charts.html
- The charts above are the source this file distills; the `$XY`
  hue/luminance table here covers everyday needs.
