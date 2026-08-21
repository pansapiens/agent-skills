# batari Basic (bB) — Program Structure and the Display Model

Purpose: how a batari Basic program is put together (skeleton, setup, main loop, subroutines, data) and how the Atari 2600 display loop (`drawscreen`) works. For LLMs that know normal BASIC but nothing about bB. Sprites, playfield, sound, score, and collision details live in the other reference files — this file only covers structure.

Contents: [What bB is](#what-batari-basic-is-and-is-not) · [Display model](#the-2600-display-model-drawscreen-and-the-frame-loop) · [Parts of a program](#parts-of-a-program) · [Game template](#minimal-working-game-template) · [Indentation](#indentation) · [Labels](#labels-and-line-numbers) · [rem](#rem--comments) · [: separator](#--multiple-statements-on-one-line) · [end](#end) · [goto/gosub/return](#goto--gosub--return--subroutines-after-the-main-loop) · [reboot & clearing](#reboot--startrestart-and-clearing-variables) · [ROM/RAM limits](#rom-and-ram-limits) · [BASIC-programmer traps](#what-a-normal-basic-programmer-gets-wrong-in-bb) · [Common mistakes](#common-mistakes)

## What batari Basic is (and is not)

bB is a BASIC-like language for creating Atari 2600 games (original beta 2005, version 1.0 in 2007). Key facts a normal BASIC programmer must absorb immediately:

- **bB is compiled, not interpreted.** Your `.bas` file is compiled to a 2600 binary. `rem` comments cost nothing — "you can use rem as much as you want and it will not affect the length or speed of your compiled program."
- **The Atari 2600 has 128 bytes of RAM, 26 bytes of which are yours** as the variables `a`–`z`. Each holds a whole number 0–255 (one byte). There are no arrays of thousands of elements, no strings, no floats.
- **A bB program never exits.** All bB programs must be loops; the program repeats forever. There is no END that quits to a menu — `end` is an unrelated data-terminator command (see below).
- **Line numbers are optional** (use labels instead), and indentation is mandatory where noted below — bB is closer to a modern BASIC dialect than to Atari BASIC.

## The 2600 display model: `drawscreen` and the frame loop

Syntax:

```bb
   drawscreen
```

The 2600 has no video memory. The picture is redrawn by the display kernel one scanline at a time, and in bB that happens inside `drawscreen`:

- Your game logic runs, then `drawscreen` draws **one entire TV frame** (~12 milliseconds) and returns control to your bB code.
- **Everything you want visible in a frame — object positions, colors, heights, playfield, score — must be set BEFORE `drawscreen`.** Changes made after a `drawscreen` won't show up until the next one.
- `drawscreen` must run **at least 60 times a second** (it also sends the synchronization signals to the TV). Your game logic between drawscreens can only take **about 2 milliseconds — roughly 2,700 machine cycles** (there are 2380 cycles in exactly 2 ms at 1,190,000 cycles/second). Complicated math, loops, and playfield scrolling eat this fast.
- If the loop takes too long, the display **shakes, jitters, or rolls**. Fixes: simplify the code, or spread work across two or more frames (e.g., flip a bit each frame and do half the work per frame; move sprites between drawscreen calls so the game doesn't slow down). Emulators are very forgiving about timing — real hardware shows problems first.

Where your code runs: bB code normally executes during **overscan** (the ~2 ms after the visible screen). The other usable period is the **vertical blank (vblank)** before the visible screen. As of March 2016 the standard kernel has **2710 cycles available in overscan and 1675 in vblank** (these numbers may change with kernel versions). You can put extra code in vblank with the special `vblank … return` block placed outside your loops at the end of the program (runs automatically at every drawscreen). Kernel differences: the multisprite kernel has considerably fewer vblank cycles; **the DPC+ kernel has no room for vblank code at all — avoid vblank with DPC+**.

Consequences of the 60-frames-per-second model:

- Count time in **frames**: 60 frames = 1 second, 120 frames = 2 seconds.
- Limit loops that do NOT contain a `drawscreen` — they burn your 2 ms budget and freeze the display.

The canonical main loop shape:

```bb
__Main_Loop
   rem  <- read input, move objects, check collisions, update score here
   drawscreen
   goto __Main_Loop
```

## Parts of a program

A bB game is organized as sequential "boxes." Not every game follows this exactly, but this is the standard outline (per Random Terrain's Parts of a Program):

1. **Program setup** — kernel options, `set` commands, `romsize`, includes, `dim` variable aliases, `def` statements, `const` constants.
2. **Start/Restart** — where the program jumps on reset and after game over. Sound is muted, objects moved off screen, most variables cleared. A few variables (high score, game-over bit) are left alone. If the game-over bit is on, jump to main-loop setup instead of the title screen.
3. **Title screen setup** — colors and variables for the title screen; a reset/fire "repetition restrainer" bit (keeps a held button from contaminating the next section).
4. **Title screen loop** — `drawscreen`; check reset switch and fire button; if pressed, jump to main-loop setup. Optional: an auto-play attract counter; flip score between current score and high score every 2 seconds.
5. **Main loop setup** — everything for the actual game: variable values, object locations and shapes, playfield data. Reset/fire restrainer bits turned ON here.
6. **Main loop** — the engine: if-thens, collision detection, input, movement, then `drawscreen` / `goto`.
7. **Game over setup** — check high score, draw the game-over playfield, turn ON the game-over bit, set the restrainer bit.
8. **Game over loop** — `drawscreen`; score flips between current score and high score every 2 seconds; ignore fire/reset for 2 seconds; after that, if fire or reset is pressed, jump to Start/Restart.
9. **Subroutines** — placed after the main loop, reached with `gosub`/`return`.
10. **Data** — `data`/`sdata` and sprite/playfield pixel blocks live outside the main loop (usually at the bottom); your code must never "run into" them, but you don't need `goto`/`gosub` to use them.

## Minimal working game template

A complete, compilable skeleton implementing the parts above (standard kernel; movement/game-over logic is just a placeholder — replace it):

```bb
   rem  ************************************************************
   rem  *  Skeleton game template (standard kernel)
   rem  ************************************************************

   set tv ntsc
   set smartbranching on

   dim _Frame_Counter = a
   dim _High_Score = b
   dim _GO_Counter = c

   def _Bit0_Reset_Restrainer=a{0}
   def _Bit1_Game_Over=a{1}

   const _SPEED = 1

__Start_Restart
   rem  Clear all normal variables EXCEPT the ones holding the
   rem  high score and the game over bit (they must survive).
   c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0
   AUDV0 = 0 : AUDV1 = 0

   rem  Coming back from game over? Skip the title screen.
   if _Bit1_Game_Over then goto __Main_Loop_Setup

__Title_Screen_Setup
   score = 0
   _Bit0_Reset_Restrainer = 0

__Title_Screen_Loop
   drawscreen
   if !_Bit0_Reset_Restrainer then if switchreset then goto __Main_Loop_Setup
   if switchreset then _Bit0_Reset_Restrainer = 1
   goto __Title_Screen_Loop

__Main_Loop_Setup
   player0x = 76 : player0y = 53
   _Frame_Counter = 0
   _Bit0_Reset_Restrainer = 1 : _Bit1_Game_Over = 0

__Main_Loop
   _Frame_Counter = _Frame_Counter + 1
   if joy0left then player0x = player0x - _SPEED
   if joy0right then player0x = player0x + _SPEED
   if joy0up then player0y = player0y - _SPEED
   if joy0down then player0y = player0y + _SPEED

   rem  Placeholder: end the game after 2 seconds.
   if _Frame_Counter = 120 then goto __Game_Over_Setup

   drawscreen
   goto __Main_Loop

__Game_Over_Setup
   _Bit1_Game_Over = 1
   _Bit0_Reset_Restrainer = 1
   _GO_Counter = 0

__Game_Over_Loop
   drawscreen
   _GO_Counter = _GO_Counter + 1
   rem  Ignore fire/reset for 2 seconds (120 frames).
   if _GO_Counter < 120 then goto __Game_Over_Loop
   if switchreset || joy0fire then goto __Start_Restart
   goto __Game_Over_Loop

__Move_Enemy
   rem  Example subroutine (only for large, shared code chunks).
   return

   data _Enemy_Pattern
   4, 12, 20, 28, 36, 44, 52, 60
end

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

Notes on the template:

- Labels are flush left; every statement is indented 3 spaces; `end` is flush left. Sprite and `data` blocks sit outside every loop so code never runs over them.
- The restrainer pattern (`if switchreset then _Bit0_Reset_Restrainer = 1`, only act when the bit is off) follows Atari's Game Standards and Procedures so a held reset/fire button can't leak from one section into the next. See the Reset Switch Restrainer and Fire Button examples if present in `examples/`.
- `score` is a special BCD variable — see the score reference file before doing math or comparisons on it.

## Indentation

bB requires indentation to tell statements apart from labels:

- **All program statements, data, and sprite/playfield pixel data must be indented by at least one space.**
- **Labels, line numbers, and `end` must NOT be indented.**
- Blank lines need no indentation.
- Convention (Random Terrain's): indent with **3 spaces** so indentation is obvious.

```bb
   if _Cabal > 42 then _Cabal = 0

   player0:
   %00111100
   %01111110
end

__Georgia_Guidestones
   x = x + 1
```

## Labels and line numbers

Syntax (all valid; a label may also share a line with a statement):

```bb
__My_Location
__My_Location_2 x = x - 1
```

- Letters (any case), numbers, and underscores only — even as the first character. **Never use a dot** in a label, anywhere.
- A label must not match or begin with a known keyword or a label internal to bB (e.g., `end`, `kernel`; you cannot name a label `next` or `pfpixel`). Don't reuse variable alias names either. `scorechange` is illegal; `changescore` is fine.
- Safe convention: **one leading underscore for variable aliases (`_Flying_Cat`), two for labels (`__Flying_Cat_Data`)**, plus capitalized words. Then you can never collide.
- Line numbers are supported but optional — use them like labels (as jump targets), not on every line as in old-school BASIC.

## rem  (comments)

Syntax variants:

```bb
   rem  Your comment here
   a = 5 ; I like pizza          ; semicolon comment
   /* C-style block comment
       spanning lines */
```

- `rem` **must have at least one space after it** or the program may not compile.
- Comments are free — they never affect compiled size or speed (bB is compiled, not interpreted).
- Semicolon `;` and C-style `/* */` comments are also supported. Subtle difference: `;` and `/* */` comments do NOT appear in the generated assembly; `rem` comments do.
- Inside `data`/`sdata` blocks use semicolons only (no `rem`, no colon):

```bb
   data _Music_Data
   5,7,18 ; Mango knee bone butter
   0,0,0
   255 ; End of data
end
```

## :  (multiple statements on one line)

Statements on one line are separated by a colon:

```bb
   AUDV0 = 0 : AUDV1 = 0
   player0x = 77 : player0y = 53 : missile0x = 200 : missile0y = 220
   if temp5 > 128 then player1x = (rand&7) + 5 : goto __Skip_Enemy_Setup
```

**Warning: always put a space before and after each colon.** People have had various problems when they didn't.

Related whitespace rules:

- Keywords and commands must be spaced properly (`for l = 1 to 10`), or bB thinks they're variables and compilation fails (`forl=1to10:...` is invalid).
- Around separators like `+ - = : * / & && | || ^`, spacing is completely free: `t=t+4`, `t = t + 4`, and `t= t+ 4` all parse the same.
- Blank lines between code are fine and recommended.

## end

Syntax: the single word `end`, **never indented**. It tells the compiler you are finished with a data entry, graphics definition, or inline assembly block — i.e., `data`, `sdata`, `asm`, and any data command that ends with a colon (`playfield:`, `player0:`, `lives:`, etc.):

```bb
   playfield:
   X.X...X..XX..X.XX.X....XX..X.X
end

   data _D_My_Data
   200, 43, 33, 93, 255, 54, 22
end

   asm
   sta WSYNC
   rts
end
```

**Warning:** do not sprinkle `end` anywhere else (e.g., before `return`, or at the bottom of loops "just in case"). Random extra `end`s cause errors. `end` does not end a program, loop, or subroutine.

## goto  /  gosub  /  return  (subroutines after the main loop)

`goto` jumps to a label or line number anywhere in the program; `gosub` jumps and a `return` jumps back:

```bb
   goto __My_Subroutine
   goto 100
   goto __Section_2_of_Code bank2      ; bankswitched games must name the bank

   gosub __Move_Monster
   gosub __Move_Monster bank2

__My_Subroutine
   a = a - 1
   return
```

Rules and gotchas:

- Subroutines are placed after the main loop. `return` without a matching `gosub` crashes the program or causes strange behavior.
- Each `gosub` uses **2 bytes of stack; only 6 bytes are reserved** — avoid nested subroutines (they overwrite variables and cause hair-pulling bugs).
- `gosub` + `return` costs **12 cycles** vs **3 cycles** for `goto`. Use `gosub` only when a significantly large chunk of code is needed from many places. For small code, repeating it is cheaper. Excessive `gosub` turns code into spaghetti.
- Trick from batari (Relief for ENDIF Addicts): keep a chunk of code between an `if…then` and a label — little "packages" of code that only run when the condition is true — instead of using `gosub`.
- Large one-place code blocks can live outside the main loop, reached with `goto` (or `on…goto`), jumping back to a label placed right after the `goto`. This also becomes necessary once a program spans multiple banks.

## reboot  /  Start-Restart and clearing variables

Syntax:

```bb
   if switchreset then reboot
```

`reboot` warm-boots the game — it clears **everything**, like turning the console off and on. You should probably never use it:

- Don't use it if you store anything across games (highest level, high score, game selections…).
- Don't use it with `rand` — reboot can mess up random numbers.

Instead, make a **Start/Restart section** you jump to (as in the template above) that clears and sets up variables, sprite positions, colors, and so on. bB does not clear variables for you, so every game needs this. Two ways to clear all 26 normal variables:

```bb
   ;  Clear with a loop:
   for temp5 = 0 to 25 : a[temp5] = 0 : next

   ;  Faster way:
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0
```

In a real game, skip the few variables you want to remember (high score, game-over bit) so they survive the restart.

## ROM and RAM limits

- The 2600's CPU can only address **4K of ROM at a time**, and the console has only **128 bytes of RAM**, **26 bytes** of which are available as your variables `a`–`z`.
- Mitigations: **bankswitching** (programs up to **64K**) and the **Superchip** (another **128 bytes of RAM**) — both with drawbacks; see the bankswitching/Superchip references.

After compiling you'll see: `Compilation Completed: ____ Bytes of ROM Space Left`. What it means:

- Graphics data must be aligned on memory page boundaries, so bB sometimes sticks empty ROM before a boundary. Code you add can silently fill that wasted space, so the reported number doesn't change — then suddenly "loses" a bunch at once when the graphics data gets pushed past its alignment.
- Moral: to compare which of two code styles uses more space, test in a small standalone program so you can see the actual bytes saved or wasted.

## What a normal BASIC programmer gets wrong in bB

- **Only 26 variables** (`a`–`z`), each a single byte (0–255). No strings, no big arrays, no floating point. Use `dim` to give them descriptive names and `def` for bit aliases (`def _Flag=a{0}`, limit of **50 defs**; `const` limit is **500** in current versions, was 50 in older ones).
- **Programs never exit** — an infinite main loop with `drawscreen` is mandatory, and time between drawscreen calls is capped (~2 ms / ~2,700 cycles).
- **`end` is not END.** It only terminates data/graphics blocks.
- **`rem` is free** — unlike memory-constrained interpreted BASICs, comment fearlessly.
- **Line numbers are optional**; indentation is mandatory (statements indented, labels and `end` not).
- **Statements limited to 50 strings**; bB doesn't like lines **over ~190 characters**; **~45 labels max** on one `on…goto`/`on…gosub` line (use fewer for readability); a macro can take up to **46 parameters**.
- **Colon separator**: usable, but keep a space on both sides of each `:`.
- **Old habits like GOTO-less structured programming don't apply**: `goto` (3 cycles) is cheaper than `gosub`/`return` (12 cycles) — spaghetti-ish main loops are normal and expected in bB.
- **DOS compatibility** (from the bB manual): bB is a command-line program expected to run under Windows 95 or later because it requires a DPMI (DOS protected mode interface) and uses long filenames. To run under pure DOS you must obtain and run a DPMI program (such as cwsdpmi.exe) first, rename all filenames to 8.3 format, edit the includes files to point to the renamed files, and use the command-line parameter `-r` to specify an alternate variable redefinition file that conforms to 8.3.
- bB is not built into any IDE — Visual batari Basic (VbB) is just a tool around it. Always download/install the latest bB version before compiling.

## Common mistakes

- Forgetting `drawscreen` in a loop, or doing visible updates after `drawscreen` instead of before it.
- Letting the main loop exceed ~2 ms / ~2,700 cycles, then wondering why the screen rolls on real hardware (emulators are forgiving).
- Indenting labels or `end`; failing to indent statements/data (compilation errors).
- Putting `end` before `return` or sprinkling random `end`s around.
- Using `reboot` as a restart (wipes high score; breaks `rand`) instead of a Start/Restart section.
- Not clearing variables at Start/Restart (variables are not cleared for you).
- Deeply nesting `gosub`s (6 bytes of stack total; 2 bytes per call) — crashes and "strange things."
- Name collisions: labels that match keywords, bB internals, or variable aliases (use `_alias` / `__label` conventions; no dots in labels).
- `rem` with no space after it; colons with no surrounding spaces; keywords run together (`forl=1to10`).
- Comparing/doing math on `score` as if it were a normal variable (it's BCD — see the score reference).
- Expecting the "bytes of ROM space left" number to move linearly as you add code (page alignment makes it jump).

## Online tools (humans)

- **bB Tools and Toys** — hex/decimal/binary conversions, bit twiddling,
  calculator, REM spellchecker: https://www.randomterrain.com/atari-2600-memories-batari-basic-tools-toys.html
- Agents don't need it — do number conversion in Python or awk instead.
