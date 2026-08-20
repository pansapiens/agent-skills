# batari Basic Score, pfscore Bars & Lives Reference

Everything about the bB score: the `score` variable (a 6-digit BCD number), score arithmetic and its BCD quirks, `scorecolor`, score fade, score background color, `noscore`, reading/changing individual score digits, saving a high score, the pfscore bars (`pfscore1`/`pfscore2`/`pfscorecolor`) for lives and health, and the lives minikernels (`lives`, `lifecolor`, `statusbarlength`, `statusbarcolor`).

**Contents:** [The score variable](#the-score-variable) · [Score arithmetic](#score-arithmetic-what-works-and-what-breaks) · [BCD-compliant numbers](#bcd-compliant-numbers-why-score-math-is-weird) · [dec](#dec-bcd-math-for-variables) · [scorecolor](#scorecolor) · [scorefade](#scorefade) · [Score background color](#score-background-color) · [noscore](#noscore) · [Custom score fonts](#custom-score-fonts) · [Reading & comparing the score](#reading-and-comparing-the-score) · [Changing individual digits](#changing-individual-score-digits) · [Points roll up](#points-roll-up-score-climbs-instead-of-jumping) · [Saving a high score](#saving-a-high-score) · [pfscore bars](#pfscore-bars-liveshealth-bars-beside-the-score) · [Lives bar patterns](#pfscore-lives-bar-dots) · [Health bar patterns](#pfscore-health-bar) · [pfscorecolor](#pfscorecolor) · [Lives minikernels](#lives-minikernel-6livesasm--6lives_statusbarasm) · [Other score minikernels](#other-score-minikernels) · [Common mistakes](#common-mistakes)

**Big bB vs normal BASIC differences:** the score is **not** a normal variable — it is a fixed 6-digit display (000000-999999) permanently at the bottom of the screen, stored as **3 bytes in BCD** (binary-coded decimal). You can assign and add/subtract, but **`if score < 10` compiles yet does not work**, and adding a plain variable garbles the score unless the variable holds a BCD-compliant value. Lives/health bars are not "graphics" — they are 8-bit variables (`pfscore1`, `pfscore2`) where **each set bit draws one bar unit** next to the score.

## The score variable

The `score` keyword changes the score. The score is fixed at 6 digits and resides permanently at the bottom of the screen (all kernels). Unlike other variables, bB accepts values from **0-999999**. It is not one of the 26 user variables (a-z) — it is a special object: a **24-bit BCD number** stored as 3 bytes.

Break the 6 digits into 3 sets of two digits with `dim` aliases (this uses **none** of your 26 variables):

```
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2
```

| Alias | Bytes   | Digits held                          |
|-------|---------|--------------------------------------|
| _sc1  | score   | 100-thousands and 10-thousands      |
| _sc2  | score+1 | thousands and hundreds               |
| _sc3  | score+2 | tens and ones                        |

Inside each byte, the **left digit is bits 7-4** and the **right digit is bits 3-0**; each digit holds 0-9:

| Digit            | Read with     |
|------------------|---------------|
| 100 thousands    | _sc1 & $F0    |
| 10 thousands     | _sc1 & $0F    |
| thousands        | _sc2 & $F0    |
| hundreds         | _sc2 & $0F    |
| tens             | _sc3 & $F0    |
| ones             | _sc3 & $0F    |

Before the score will appear on screen you **must** set its color (see [scorecolor](#scorecolor)).

## Score arithmetic: what works and what breaks

Documented valid operations:

```
   score = 1000
   score = score + 2000
   score = score - 10
   score = score + a
```

What works:

- Assigning a plain decimal value: `score = 123456`.
- Adding/subtracting decimal constants, e.g. `score = score + 2000` or `score = score - 10` (a working standard-kernel example uses `score = score + 10`).
- Adding in "round" hundreds/thousands is the classic safe pattern. Because `score = score + 100` adds 1 to the **middle** (hundreds) score digits, you can bypass the low digits entirely with large round numbers (100, 1000, 2000, …).
- `score = score + a` — compiles, but `a` must **always contain a BCD-compliant number** ($00-$99 with only decimal digits, e.g. $05, $10, $99). If a non-BCD number (like $3E) is in `a`, part of your score ends up garbled.

What breaks or needs care:

- **Conditionals do not work.** `if score < 10` will compile but will NOT check whether the score is less than 10 — the score is a 24-bit BCD number. See [Reading and comparing the score](#reading-and-comparing-the-score).
- **Adding a normally-computed variable garbles the score.** `_Lithium = _Lithium + 5` then `score = score + _Lithium` works only a few times before the score goes wrong, because normal bB math is binary while the score is decimal. Fix: use the [`dec`](#dec-bcd-math-for-variables) statement.
- **Hex is not decimal.** In normal math, `a = a + $10` adds **16**, not 10. Values that end up inside the score must always look like two decimal digits per byte.
- **Adding 10s/ones through a variable:** change the tens/ones digits reliably with `dec _sc3 = _sc3 + $10` (tens) / `+ $01` (ones), or by writing `_sc3` directly — not by adding a binary-math variable to `score`.
- **Wraparound:** each two-digit BCD byte rolls over past 99 and rolls back under 0 ($99+$01 is $00; $99+$02 is $01). Subtracting more points than the score contains wraps the score around to a huge number, so compare first (byte by byte) if that matters.

## BCD-compliant numbers (why score math is weird)

BCD = binary-coded decimal: a hexadecimal number that *looks like* a decimal number.

- `$99` is the BCD number for decimal 99. `$23` is BCD for 23.
- The hex letters A-F are never used: there is **no BCD number for `$3E`** because E is not a decimal digit.
- A BCD-compliant value always looks like a one- or two-digit decimal number with a `$` on the left: $00-$09, $10, $14, $25, $99, …
- If a variable added to the score contains a non-BCD value like $3E, the score ends up incorrect or garbled.

## dec (BCD math for variables)

`dec` is a variation of `let` that adds and subtracts in decimal mode, so the variable stays safe to add to the score. Syntax (assignment with `+` or `-` only — other math operations are not valid in decimal mode):

```
   dec _Lithium = _Lithium + $02
   dec _Lithium = _Lithium - $05
   if _Lithium < $80 then dec _Lithium = _Lithium + $10
```

Rules and gotchas:

- You **must use BCD numbers**: to add 14, write `$14`, not `14` (14 decimal = $0E, a non-BCD value).
- Numbers are never more than two digits and the result never gets larger than **$99** — it rolls over: $99+$01 is $00, $99+$02 is $01, and so on.
- Comparing with `if` works fine: `if _Lithium < $80 then …`
- `dec` is compact and can be used in the middle of a long if-then.

Typical pattern — accumulate points in a variable with `dec`, then add it to the score:

```
   if _Weather_Wars{0} then dec _Lithium = _Lithium + $02
   if _Weather_Wars{1} then dec _Lithium = _Lithium + $05
   if _Weather_Wars{2} then dec _Lithium = _Lithium + $10
   if _Weather_Wars{3} then dec _Lithium = _Lithium + $20

   score = score + _Lithium
```

Before `dec` existed you wrapped the math in assembly `sed` / `cld` (set/clear decimal mode) around the addition — still works. Or you bypassed the low digits entirely with large round numbers (`score = score + 100` adds 1 to the middle score digits). Trade-offs: the large-number method can overflow a score digit into higher digits; with `dec`, a digit rolls over once it goes past 99 (or back under 0).

## scorecolor

Sets the score color so it will be visible. Value is 0-255 from the color chart.

```
   scorecolor = $1A
```

- **The score is invisible until you set scorecolor.**
- Standard/multisprite kernels: one color for the whole score. **DPC+ kernel:** each of the 8 pixel-rows of the score can have its own color using a `scorecolors:` block (good for gradients):

```
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

- Gotcha: the score is actually drawn with the player objects, so **COLUP0 and COLUP1 must be set during every frame or the sprites' colors will revert to the score color**.

## scorefade

In the **standard kernel**, `const scorefade=1` enables the score fade effect (adds shading to the score):

```
   const scorefade = 1
   scorecolor = $9C

__Main_Loop
   drawscreen
   goto __Main_Loop
```

If you keep incrementing scorecolor, you get the typical Atari color-bar effect (`x = x + 1 : scorecolor = x` inside the main loop before `drawscreen`).

**Warning:** scorefade is **not available** if you are using pfscore bars.

## Score background color

The thin strip behind the score can have its own background color.

**Standard kernel** — put this asm block in the last bank, or (no bankswitching) at the end of your code outside of any loops:

```
   asm
minikernel
   sta WSYNC
   lda _SC_Back
   sta COLUBK
   rts
end
```

Then dim a variable for it and use it any time:

```
   dim _SC_Back = x
   _SC_Back = $C4
```

Remember: you must still set COLUBK inside your main loop, or the rest of the background will become the same color as the score background.

**DPC+ kernel** — the asm goes in the **first bank, after the `goto` that jumps to bank 2** (`dim _Score_Background = y` is used by the asm to set the score background color):

```
   set kernel DPC+
   goto __Start_Restart bank2

   asm
minikernel
   ldx _Score_Background
   stx COLUBK
   rts
end

   bank 2
   temp1=temp1
__Start_Restart
```

For a fixed color, use an immediate value (`#` = the number itself, not a memory location) instead of a variable: `ldx #$84`.

## noscore

Disables the score completely:

```
   const noscore = 1
```

- Frees the time and space the score display uses (one remedy when a minikernel costs too many cycles).
- The `const` method will eventually be deprecated in favor of the `set` command, but will continue to work.
- Alternative score kernels exist (by batari): use `const noscore=1`, then place `inline scoreXX.asm` (XX = 33, 42, or 51) after your bB code, in the last bank if applicable.

## Custom score fonts

Works in any batari kernel: `const font=<fontname>`. Available fonts: `.21stcentury`, `alarmclock`, `handwritten`, `interrupted`, `retroputer`, `whimsey`, `tiny`.

```
   const font = retroputer
```

## Reading and comparing the score

Never compare `score` directly. Dim the three byte aliases (see [The score variable](#the-score-variable)) and compare each byte. Because these are BCD numbers, **put a `$` in front of every value you check**.

Check if the score is less than 10:

```
   if _sc1 = $00 && _sc2 = $00 && _sc3 < $10 then ...
```

Check if the score is greater than 123456 (compare one byte pair at a time, highest first):

```
   if _sc1 > $12 then COLUBK = $30 : goto __Skip_Greater_Test
   if _sc1 < $12 then goto __Skip_Greater_Test
   if _sc2 > $34 then COLUBK = $30 : goto __Skip_Greater_Test
   if _sc2 < $34 then goto __Skip_Greater_Test
   if _sc3 > $56 then COLUBK = $30
__Skip_Greater_Test
```

You can also watch a single digit with a bitwise AND — remember the digit before adding points, then compare after (temp variables reset after drawscreen, so copy into a user variable if it must survive):

```
   temp5 = _sc2 & $F0   ; thousands digit before
   score = score + 10
   temp6 = _sc2 & $F0   ; thousands digit after
   if temp5 = temp6 then goto __Skip_Change
   ; thousands digit changed — do something
__Skip_Change
```

Complete working examples: `mini_ex_score_123456.bas` (select and edit score digits, tests greater-than-123456) in `examples/`.

## Changing individual score digits

Each byte holds two BCD digits (left = bits 7-4, right = bits 3-0). Use bitwise AND to keep the digit you are not changing and OR to set the other one. `_Number` is 0-9; multiply by 16 to place a value in the left digit:

```
   dim _Number = q  ; Persistent variable for digit value (0-9)
   _Number = 5

   ; Sets left digit of _sc1 to _Number (100 thousands digit).
   temp6 = _sc1 & $0F  ; Preserves right digit (10 thousands).
   temp6 = temp6 | (_Number * 16)  ; Sets left digit.
   _sc1 = temp6

   ; Sets right digit of _sc1 to _Number (10 thousands digit):
   temp6 = _sc1 & $F0  ; ...preserves left digit...
   temp6 = temp6 | _Number  ; ...sets right digit.
   _sc1 = temp6
```

(The same pattern with _sc2 sets thousands/hundreds; with _sc3 sets tens/ones. Temp variables reset after drawscreen, so use a user variable like `_Number` for values you keep.)

Adding/subtracting a single digit with `dec` (from the digit-selector example):

```
   dec _sc1 = _sc1 + $10   ; add 1 to the 10-thousands digit
   dec _sc2 = _sc2 - $01   ; subtract 1 from the hundreds digit
   dec _sc3 = _sc3 + $10   ; add 1 to the tens digit
```

Working example: `z_bb_mini_ex_score_individual_digits.bas` in `examples/` (select a score digit with the joystick, press up/down to change it; also displays a score digit on player1).

## Points roll up (score climbs instead of jumping)

Nukey Shay's method (adapted by Random Terrain): points accumulate in a variable, then the score rolls up 1 point per frame instead of instantly jumping. The accumulator does **not** need to be BCD:

```
   dim _Points_Roll_Up = z
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2

   ; in the main loop (before drawscreen):
   asm
   lda  _Points_Roll_Up
   beq  No_Points_To_Add
   dec  _Points_Roll_Up
   sed
   clc
   lda  _sc3
   adc  #1
   sta  _sc3
   lda  _sc2
   adc  #0
   sta  _sc2
   lda  _sc1
   adc  #0
   sta  _sc1
   cld
No_Points_To_Add:
end
```

- `_Points_Roll_Up` can never hold more than **255** pending points.
- **Warning:** do not put a BCD-compliant number into `_Points_Roll_Up` — it is used as a normal (hexadecimal) number here. `a = a + $10` would add 16, not 10.
- Used in the game Seaweed Assault.

## Saving a high score

There is no automatic high score. Keep the high score in **three variables** (one per score byte), copy the score bytes into them when a new high score happens, and it survives until the game is turned off (RAM only — power off erases it).

Byte-by-byte check (highest byte first):

```
   if _sc1 > _High_Score1 then goto __New_High_Score
   if _sc1 < _High_Score1 then goto __Skip_High_Score
   if _sc2 > _High_Score2 then goto __New_High_Score
   if _sc2 < _High_Score2 then goto __Skip_High_Score
   if _sc3 > _High_Score3 then goto __New_High_Score
   if _sc3 < _High_Score3 then goto __Skip_High_Score
   goto __Skip_High_Score

__New_High_Score

   _High_Score1 = _sc1 : _High_Score2 = _sc2 : _High_Score3 = _sc3

__Skip_High_Score
```

Smaller/faster asm version (original by supercat, adapted by Karl G with input from bogax) — after it, fall through into "new high score" code only when the score is higher:

```
   asm
   sed                    ; Set the Decimal Mode Flag
   lda _High_Score3       ; Load the Accumulator
   cmp _sc3               ; Compare Memory and the Accumulator
   lda _High_Score2       ; Load the Accumulator
   sbc _sc2               ; Subtract With Carry
   lda _High_Score1       ; Load the Accumulator
   sbc _sc1               ; Subtract With Carry
   cld                    ; Clear the Decimal Flag
   bcs .__Skip_High_Score ; Branch if Carry Set (goto label if carry is set)
end

   ; New high score!
   _High_Score1 = _sc1 : _High_Score2 = _sc2 : _High_Score3 = _sc3

__Skip_High_Score
```

Working example: `ex_save_high_score.bas` in `examples/` (joystick up increases the score; fire flips between current score and high score every 2 seconds).

## pfscore bars (lives/health bars beside the score)

Two 8-wide bars built into the score area, one on each side of the score, enabled with `const` (the value doesn't matter — bB only checks that it is defined; this will eventually move to the `set` command):

```
   const pfscore = 1
```

Three special variables control them:

- **pfscore1** — binary value displayed **left** of the score. Each bit that is 1 draws one unit of the bar.
- **pfscore2** — binary value displayed **right** of the score, in **reversed bit order**.
- **pfscorecolor** — color of the bars.

Initializing (left bar = 3 dots for lives, right bar = full health):

```
   pfscore1 = 21
   pfscore2 = 255
```

Binary is usually more intuitive:

```
   pfscore1 = %00010101   ; 3 dots (lives)
   pfscore2 = %11111111   ; full-width bar (health)
```

Rules:

- Either bar can be lives, health, or anything else — two dot bars or two health bars are fine.
- **Decrease:** if it is a health bar, divide by 2; if it is a dots (lives) bar, divide by 4. (See the pattern sections below.)
- **Warning:** if pfscore2 flips and partially covers the score, your CTRLPF is wrong — you probably used a playfield setting of 0 instead of a valid value from the CTRLPF chart.
- pfscore bars **cannot** be combined with the HUD minikernels (6lives, etc.) without hacking the source files — they use the same memory locations. If you need an extra variable, `aux6`/statusbarlength is still available when using pfscore bars.
- Remember: pfscore **bars** are not the same thing as the Life Counter and Status Bar **minikernels**.
- scorefade is not available while pfscore bars are enabled.

Interactive demo: `ex_pfscore_lives_health_selector.bas` in `examples/` (choose lives-style or health-style for each side, then increase/decrease both bars; the pfscore values are shown in the score). Game example: Tinkernut World Deluxe.

## pfscore lives bar (dots)

Each **2 bits = one life icon** (a dot), so use multiples of 4 when changing it.

```
   pfscore1 = %00010101   ; 3 lives starting at bit 0 (closer to score)
   pfscore1 = %00101010   ; 3 lives starting at bit 1 (farther from score)

   pfscore1 = pfscore1/4  ; subtract a life (left side; use pfscore2/4 for right)

   pfscore1 = pfscore1*4|2  ; add a life starting at bit 1 (left side)
   pfscore2 = pfscore2*4|2  ; add a life starting at bit 1 (right side)

   pfscore1 = pfscore1*4|1  ; add a life starting at bit 0 (left side)
   pfscore2 = pfscore2*4|1  ; add a life starting at bit 0 (right side)
```

Game example: `tinkernut_world_deluxe_lives_bar.bas` in `examples/`.

## pfscore health bar

A solid bar where every bit = one unit (8 units total; 255 = full). Shift by 1 bit, not 2:

```
   pfscore1 = pfscore1/2  ; subtract from a health bar on the left side
   pfscore2 = pfscore2/2  ; subtract from a health bar on the right side

   pfscore1 = pfscore1*2|1  ; add to a health bar on the left side
   pfscore2 = pfscore2*2|1  ; add to a health bar on the right side
```

Game example: `tinkernut_world_deluxe_health_bar.bas` in `examples/`.

## pfscorecolor

Sets the color of the pfscore bars (if they are enabled). Example:

```
   pfscorecolor = $84
```

## Lives minikernel (6lives.asm & 6lives_statusbar.asm)

Two minikernels ship with bB: **6lives** shows up to six life icons with a variety of display configurations; **6lives_statusbar** shows a fixed, left-aligned life counter **plus** a 28-unit status bar (health, time, power, speed, …). The HUD is drawn just below the bB screen but above the score.

Add one as inline asm (one line, outside loops):

```
   inline 6lives.asm
```

or

```
   inline 6lives_statusbar.asm
```

- **8K or larger games:** the `inline` command must go in the **last bank** (the game looks for the module there). In a 4K game you may use `include` instead of `inline`.
- **Cost:** a typical minikernel takes around **700 machine cycles each frame** — roughly one-quarter to one-third of the available time. If you cannot spare that: shrink the screen (`pfres`/`pfrowheight` in the standard kernel, `screenheight` in the multisprite kernel, or `pfheights` with total height under 88), use `const noscore=1`, or use the pfscore bars instead.

### lives: (icon definition)

Required by both minikernels. Works like a player definition but is fixed at **8 units high**:

```
   lives:
   %01000100
   %11111110
   %11111110
   %01111100
   %00111000
   %00010000
   %00010000
   %00010000
end
```

Layout options (6lives.asm only; 6lives_statusbar.asm is always left-aligned and compact). Default is left-aligned + expanded (8 pixels between icons). To change, place at the beginning of your code:

```
   dim lives_centered = 1
   dim lives_compact = 1
```

The compact layout puts the lives so close together they touch if the icon is 8 pixels wide.

### lives (variable)

Shared variable: the **lower 5 bits are the icon graphics pointer**, the **upper 3 bits are the number of lives** (0-7 possible, but **no more than 6 will display**). To set the lives count, use these values:

| Lives | Command     | | Lives | Command     |
|-------|-------------|-|-------|-------------|
| 0     | lives=0     | | 4     | lives=128    |
| 1     | lives=32    | | 5     | lives=160    |
| 2     | lives=64    | | 6     | lives=192    |
| 3     | lives=96    | | 7     | lives=224    |

- **Whenever you assign a lives count, you must also define (or redefine) the icon with `lives:`**, or the icon will not display correctly.
- Add a life: `lives=lives+32`. Subtract a life: `lives=lives-32`. These do **not** require redefining `lives:` because they do not touch the icon pointer.
- Check for zero lives: `if lives < 32 then ...` — check for 7 lives: `if lives > 223 then ...`
- Wraparound: subtracting a life from zero results in **seven** lives; adding a life to seven results in **zero** lives.

### lifecolor

Sets the color of the lives. **When using bankswitching, this must be in your main loop** (or called from your main loop).

```
   lifecolor = $1C
```

### statusbarlength (6lives_statusbar.asm only)

Sets the length of the 28-unit status bar:

```
   statusbarlength = 200
```

- Valid values: the full range 0-255, but numbers **greater than 224 show the bar at full length**.
- The bar is **28 discrete units wide**, so it only changes in **multiples of 8** in the variable.
- If you know what you are doing, the lower 3 bits can be used for something else.

### statusbarcolor (6lives_statusbar.asm only; optional)

If not used, the status bar uses the playfield color. To use it you must **reserve one of your 26 user variables with dim**:

```
   dim statusbarcolor = t

   statusbarcolor = $1C
```

## Other score minikernels

- **playerscores minikernel** (by CurtisP): two or four independently colored two-digit scores — e.g. a separate score per player while the main 6-digit score is used for something else. (Multi-bank use needs RevEng's AtariAge fix; a revised single-digit version by Karl G also exists.)
- **4scores minikernel** (by Karl G): 4 separate single-digit player scores in 4 different colors, all on the same line.
- **Minikernel Developer's Guide** (by Karl G): how to write your own minikernels — also a good intro to Atari assembly.

## Common mistakes

- Using `if score < 10 then …` — it compiles but never checks the score. Compare `_sc1`/`_sc2`/`_sc3` byte by byte with `$`-prefixed BCD values instead.
- `score = score + a` where `a` was computed with normal math — the score garbles once `a` holds a non-BCD value. Use `dec` math (with $xx values) on the variable before adding it.
- Wrong number style: `dec _Var = _Var + 14` is wrong because decimal 14 is $0E — write `$14`. In normal (non-dec) math, `$10` means 16, not ten.
- Forgetting `scorecolor = value` — the score is invisible without it.
- Forgetting `const pfscore = 1` before using pfscore1/pfscore2, or enabling `const scorefade = 1` while using pfscore bars (scorefade is unavailable then).
- Dividing the wrong amount: dots (lives) bars change by **4** (2 bits per life); health bars change by **2**.
- CTRLPF set to 0 or another invalid chart value makes pfscore2 flip over the score.
- Using pfscore bars together with HUD minikernels — they share memory locations.
- `lives = 3` instead of `lives = 96` (each life = 32), or assigning a lives count without defining the `lives:` icon.
- Expecting `lives-32` at zero lives to go negative — it wraps to seven lives. Check `if lives < 32` first.
- Using `statusbarcolor` without first dimming it to a user variable, or expecting values above 224 in `statusbarlength` to draw more bar (224+ is already full); also, `lifecolor` must be inside the main loop in bankswitched games.
- Subtracting more points than the score holds — BCD bytes wrap, producing a huge score.
