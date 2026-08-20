# batari Basic Variables, Data, and Math Reference

Everything about variables (a-z), aliases (dim), constants (const), def, bit operations, nybbles, fixed-point math, temp variables, data tables, random numbers, and integer math. Covers: variables, let, var0-var47, dim, const, def, bit operations, bitwise operators, nybble variables, temp1-temp6, fixed point (4.4 and 8.8), math operators, decimal/hex/binary, negative numbers, data, data _length, sdata/sread, rand, rand16, random range charts, random percentages.

## Variables (the built-in a-z)

batari Basic gives you exactly **26 general-purpose variables, fixed as a-z**. Each is one byte: values 0-255.

```
   a = 10
   b = a + 5
   if b > 200 then b = 0
```

Key facts a normal BASIC programmer gets wrong:

- You cannot declare new variables. There are only 26 (plus the extras listed below). Use `dim` to give them descriptive names.
- Each variable holds 0-255 only. **Overflow wraps around**: 255+1=0, 255+2=1, ... 255+255=254. Underflow wraps too: 0-1=255, 1-2=255, ... 0-255=1. There is no error — it just wraps.
- There is no floating point. Use fixed-point types (below) for fractions.
- Exception: the 6-digit `score` works with values 0-999999.
- 26 variables run out fast. Use bit operations for on/off flags and nybble variables for values that never exceed 15.

Recommended setup template (put dims near the top of your program):

```
   dim _Monster_xpos = a
   dim _Monster_ypos = b
   dim _Corbomite_Maneuver_Data = c
   dim _Tranya_Supply = d
```

## let (optional)

`let` is optional for assignment and is ignored by the compiler. It exists only because an early unreleased version of bB required it. Using it does not affect program length.

```
   let x = x + 1
```

## var0-var47 (playfield variables — warning!)

In the **standard kernel without Superchip RAM**, var0-var47 are the playfield. The chart: row 0 = var0-var3, row 1 = var4-var7, ... row 11 = var44-var47 (each row uses 4 variables). **Do not use them as general variables** — writing to them redraws/corrupts the playfield.

- If you are **not scrolling and not using pfclear during gameplay**, you may borrow the last four: var44-var47 (standard kernel only):
   ```
   dim _Extra_One = var44
   dim _Extra_Two = var45
   ```
- If you **enable Superchip RAM**, the playfield moves to extra RAM and var0-var47 become **48 free regular variables** you can dim like any others (80 more special read/write variables r/w000-r/w079 are also available). See the Superchip RAM page of the bB manual for details.
- **Multisprite kernel**: do not use var0-var47 as variables (the playfield lives there).

Other borrowable variables (standard kernel): `statusbarlength` if you don't use the Life Counter or Status Bar minikernels; `lives` and `lifecolor` if you also don't use pfscore bars. `dim` works on all of these.

## dim — descriptive variable aliases

`dim` maps a descriptive name to a variable. Unlike other BASICs, dim is **not** for arrays in bB — it's for aliases (and fixed-point types, below).

```
   dim _Monster_xpos = a
   dim _Hero_Lives = g
```

Rules and facts:

- First character of an alias: a letter (upper or lower) or an underscore. Following characters: letters, numbers, underscores. **Never use a dot/period** in an alias.
- An alias must not match or begin with a known bB keyword or internal label (e.g., you can't use `next` or `pfpixel`; `scorechange` is bad but `changescore` or `Change_Score` are fine).
- Recommended convention: one underscore + capitalized words for aliases (`_Flying_Cat_Data`), two underscores for labels (`__Game_Over`). Then you never collide with keywords or labels.
- More than one alias may be mapped to the same variable — useful when reusing a variable in different parts of the game.
- Aliases cost zero ROM. Dim for aliases can appear anywhere in the program (but put them all together near the top so helpers can read your code). This anywhere-rule is **not** true for fixed-point dims.

## const — constants

`const` declares a value the compiler substitutes everywhere the name is used. It cannot change while the program runs. Use it for values repeated in several places or values you want to tweak in one spot.

```
   const _MYCONST = 200
   const _MONSTER_HEIGHT = $12
   ...
   if player0y < _MYCONST then player0y = player0y + 1
```

- Values may be decimal or hexadecimal (`$12`), just like normal numbers.
- Older bB versions had a limit of 50 constants; later versions allow 500.
- Convention: SCREAMING_SNAKE_CASE with a leading underscore (e.g., `_M_TOP_EDGE`, `_P_LEFT_EDGE`).
- A `const` is compile-time substitution, not a variable — writing `_MYCONST = 5` later is impossible.

## def — text-substitution definitions

`def` assigns an entire string to a name. Everywhere bB sees the name, it pastes the string in. It works for single bits (which `dim` can't do) and even math expressions.

```
   def _Hero_Shot=a{0}
   def _Hero_Thrust=a{1}
   def _Hero_Crash=a{2}

   _Hero_Shot = 1
   if _Hero_Crash then goto __Blow_Up
```

Rules and facts:

- **No spaces before or after the equals sign** in a def.
- def strings must be different from each other — one def string cannot be a substring of another (if you use `_PullMyLeg`, you can't also use `Pull`, `My`, or `Leg`).
- Limit: 50 defs.
- Bit defs must be tested like bit operations: `if _Hero_Shot then` / `if !_Hero_Shot then` — **not** `if _Hero_Shot=1 then`.
- `def MyVar=a + b - c` works (it pastes `a + b - c`), but def is search-and-replace, not a function call — it saves no bytes or cycles.
- def and dim can be combined:
   ```
   dim _Game_Flags = a
   def _Game_Level=_Game_Flags & $0F
   def _Game_Over=_Game_Flags{7}
   ```
- def is fragile: some users report mysterious problems with it. Use with care (the bit-alias style `dim _Bit0_Name = a` plus `_Bit0_Name{0}` is the safe alternative).

## Bit operations (a{0} through a{7})

The 8 bits of a variable are numbered 0-7, right to left (bit 0 is the least significant bit):

```
   bit:  7  6  5  4  3  2  1  0
```

Access a bit with curly brackets `{}` — a variable becomes eight tiny on/off variables (26 variables → up to 208 bits). Each bit holds only 0 or 1.

```
   a{0} = 1
   a{0} = 0
   if a{0} then gosub __Moose_Gizzard
   if !a{0} then goto __Game_Over
```

Critical syntax rules:

- Bit tests do **not use an equal sign**: `if a{0} then` (not `if a{0} = 1 then`) and `if !a{0} then` (not `if a{0} = 0 then`).
- Use curly brackets `{}`, never parentheses `()`.
- The number inside `{}` must be a constant 0-7, **not a variable**.
- Flip a bit: `a{0} = !a{0}`. Copy bit to bit: `d{3} = r{4}` or `f{5} = !f{5}`.
- Speed: `a{0} = 0` and `a{0} = 1` take 8 cycles each; flipping or bit-to-bit copy takes 23-24 cycles.

Use dim to make bit flags readable (include the bit number in the alias so you remember which is which):

```
   dim _Bit0_Hero_Shot = a
   dim _Bit1_Hero_Thrust = a
   dim _Bit2_Hero_Crash = a
   ...
   _Bit0_Hero_Shot{0} = 0
   _Bit1_Hero_Thrust{1} = 0
   _Bit2_Hero_Crash{2} = 1
   rem  * that sets a (and every alias of a) to 4, or %00000100
```

**Warning:** once you use individual bits of a variable, that whole variable is off-limits elsewhere. `a = 48` or `a = a + 1` somewhere else in the program will overwrite your bits. (Bad examples — `dim _my_variable = a{1}`, `dim _my_variable{1} = a` — are illegal; use the alias style above or `def`.)

Checking whether two bits differ:

```
   if a{0} then if !a{5} then goto __Pause_Game
   if !a{0} then if a{5} then goto __Pause_Game
```

Handy trick: bit 0 of a variable is 1 when the value is odd, 0 when even — `if a{0} then odd`.

## Bitwise operators & | ^

Three bitwise operators change or mask individual bits (not to be confused with the logical `&&`, `||`, `!` used in if-thens):

- `&` = AND — mask/force bits OFF: use 0 in the mask to force a bit off, 1 to leave it alone.
- `|` = OR — force bits ON: use 1 to force a bit on, 0 to leave it alone.
- `^` = XOR — FLIP: use 1 to flip a bit, 0 to leave it alone.

```
   a = a & $0F
   a = b ^ %00110000
   a = a | 1
```

Example with binary: `a = %10101010`, then `a = a & %00001111` gives `%00001010` (top nibble forced off); `a = a | %00001111` gives `%10101111` (bottom nibble forced on); `a = a ^ %00001111` gives `%10100101` (bottom nibble flipped).

**Warning:** AND/OR/XOR cannot be used with write-only registers — anything like `NUSIZ0 = NUSIZ0 & $0F` fails because the register appears on the right side of the `=` and gets read.

## Nybble variables (two 4-bit values per variable)

If a value never exceeds 15, split a variable into two nybbles: 26 variables can become 52. Nybbles roll over 15→0 and 0→15 (like variables roll 255→0).

bB has no native nybble support; use SeaGtGruff's macro/def method. You need two defs per nybble — one for reading, one for writing (e.g., `_PEEK_Bonus_Item` to read, `_POKE_Bonus_Item` to write):

- To set: no equal sign — name, space, value: `_POKE_Space_Nugget 5`
- To read: `if _PEEK_Space_Nugget = 5 then ...`
- To increment/decrement, go through a temp variable (parentheses required):
   ```
   temp5 = (_PEEK_Game_Level) + 1
   _POKE_Game_Level temp5
   ```
Comment your nybble variables well — they're the most confusing thing in bB. See the bB manual's "Nybble Me This, Batman!" section for the full macro/def source.

## Temporary variables (temp1-temp6)

There are 7 temp variables, temp1-temp7. **temp7 is reserved for bankswitching — never use it in a bankswitched game.** temp1-temp6 are used by the kernel and by various bB statements:

- They are **obliterated by drawscreen** and by some playfield commands and math routines.
- `div_mul.asm` and `div_mul16.asm` (multiplication/division modules) use **temp1 and temp2** — anything you stored there is destroyed by math that uses those routines. (`temp1 = a * 23` is fine; the result lands in temp1 after the math.)
- User functions may also clobber temp variables.
- bB tends to use them in order (temp1 first), so they are generally **safest in reverse order**: temp6 is safer than temp5, temp5 safer than temp4, etc.

```
   temp5 = (rand & %00000001)
   a = a ^ temp5
```

Use them sparingly, only for brief scratch values that are consumed immediately.

## Fixed point variables (4.4 and 8.8)

Fixed point lets you use fractional values. You **must** use `dim` — you cannot use a-z as fixed point without it. bB has exactly two fixed-point types:

- **8.8** — two bytes: the first variable is the whole/integer part (high byte), the second is the fraction (low byte). Range 0 to 255, fraction accurate to 1/256 (0.00390625).
- **4.4** — one byte: four bits integer, four bits fraction. Range **-8 to 7.9375**, accurate to 1/16 (0.0625). Always signed.

Declare with `dim name = var.var2` (8.8 uses two different variables; 4.4 repeats the same variable):

```
   dim _My_Var = a.b        rem  * 8.8: a = whole, b = fraction
   dim _Monster_x = d.r     rem  * 8.8
   dim _xvelocity = c.c     rem  * 4.4
```

How 8.8 works: the high byte holds the whole part, the low byte the fraction (0-255 representing 0 to 255/256). Adding 0.5 to a sprite position adds 128 to the fraction byte; the sprite moves one whole pixel only when the fraction overflows. This gives subpixel/smooth movement:

```
   dim _P0_L_R = player0x.a
   dim _P0_U_D = player0y.b

   _P0_L_R = _P0_L_R - 0.85
   _P0_L_R = _P0_L_R - 2.0
   _P0_L_R = _P0_L_R - 1.052
```

(Note how player0x/player0y themselves can serve as the whole-byte of an 8.8 — extremely handy for sprite movement.)

Rules and limitations:

- Assigning an 8.8 where an integer is expected (e.g., to player0x) drops the fraction, like `int()` in other BASICs.
- 4.4 types can only be assigned/added/subtracted with themselves, integers, or 8.8s. Used any other way, a 4.4's value gets multiplied by 16.
- In if-thens: an 8.8's fraction is ignored; comparing a 4.4 with a number or other type multiplies the 4.4 by 16 (two 4.4s can be compared directly).
- To test just the fraction in an if-then, access the fraction's variable directly (e.g., `b`) — note that reading it directly shows the fraction multiplied by 256 (i.e., raw 0-255).
- Multiplication/division of fixed point types follow the same limitations.
- Negative fixed point values work: `my88 = -12.662`, `my44 = -4.67`.

**The fixed_point_math.asm module:** you only need `include fixed_point_math.asm` (near the beginning of the program) when you **mix 8.8 and 4.4 types** in the same math assignments. Pure 8.8 or pure 4.4 math is built into the parser. Because the mixed-type routine is fixed to bank 1, you **cannot** mix 8.8 and 4.4 math in a DPC+ kernel game.

Valid operations (my44 = 4.4, myint = integer, my88 = 8.8; (*) = requires fixed_point_math.asm):

```
   my88 = 12.662        my88 = -12.662       my44 = 4.67
   my88 = myint         my44 = myint         myint = my44      myint = my88
   my88 = my44 (*)      my44 = my88 (*)
   my88 = my88+1.45     my44 = my44+2.55     my88 = my88-1.45  my44 = my44-2.55
   my88 = my44+6.45 (*) my44 = my88+3.45 (*) my88 = my44-6.45 (*) my44 = my88-3.45 (*)
   my88 = my88+my88     my44 = my44+my44     my88 = my88-my88  my44 = my44-my44
   my88 = my44+my88 (*) my44 = my88+my44 (*) my88 = my44-my88 (*) my44 = my88-my44 (*)
```

Complete example programs in this skill: `examples/ex_8_8_type_speed_change.bas` (joystick up/down = faster, left/right = slower; fire+up/down selects object) and `examples/ex_fixed_point_sprite.bas` (smooth 8.8 sprite movement with wall collision prevention).

## Integer math operators

bB supports full expression evaluation for **integer** math in variable assignments only — you can't (yet) use expressions as arguments in functions, bB commands, comparisons, or fixed-point math.

Order of operations: `()` first; then `*` and `/`; then `+` and `-`; then `&`, `^`, `|`.

```
   a = e-4*2
   a = (e-4)*2
   a = (e-4)*2*(myarray[4]-(4+c[r]))+2|e
```

Operators:

- **+ / -**: any mix of registers, variables, unsigned 0-255 or signed -128 to 127. Wraps at 0/255 (255+1=0, 0-1=255). Unary minus works: `a = -a`.
- *****: multiplication of a variable by a number 10 or less needs no module. Multiplying two variables, or by constants whose prime factors aren't only 2, 3, 5, and/or 7, requires `include div_mul.asm`. Results over 255 are bogus unless you use `**`, which stores a 16-bit result: low byte to your variable, upper byte in temp1 (`**` needs `include div_mul16.asm`; 16-bit multiplication is not fully tested). Note `a = a*2` is faster and smaller than `a = a+a`.
- **/**: division returns an integer result; remainder is lost. Dividing by 2, 4, 8, 16, 32, 64, or 128 (or 1) needs no module; any other divisor or variable÷variable requires `include div_mul.asm`. Division by zero silently does nothing. The division/multiplication module is one package (`div_mul.asm`; `div_mul16.asm` for `**` and `//`).
- **//**: bB's substitute for the modulus operator (%) — divides and stores the **remainder in temp1** (requires `include div_mul16.asm`).
- Put `include` lines near the top of the program, before `includesfile` and `set romsize`.

Warnings: complex expressions can produce localized overflow (intermediate values over 255 or below 0); complex statements, functions, subroutines, and bankswitching all use the stack, so excessive nesting can overflow the stack into variable space. Division modules may not work properly in bankswitched games.

## Number formats: decimal, hex, binary

- **Decimal** is the default: `a = 10`.
- **Hexadecimal**: prefix with `$` — `COLUPF = $2E`, `NUSIZ0 = $20`. ($01=1, $09=9, $0A=10, $0F=15.)
- **Binary**: prefix with `%` — define all 8 bits: `CTRLPF = %00100010`. Especially useful for TIA registers and sprite graphics data.

```
   player0:
   %00100010
   %11100111
end
```

## Negative numbers

Negative numbers are "somewhat supported." Variables hold 0-255; values 128-255 double as -128 to -1 (two's complement — the high bit is the "sign" bit). Adding 255 is exactly the same as subtracting 1.

- Unary minus is supported: `a = -a` (older bB: use `a = 0-a`).
- `a = -1` works in current bB; in older versions integers weren't handled, so use 256-n instead: `a = -1` → `a = 255`, `a = -8` → `a = 248`.
- Warning: bB before 1.0 shipped with DASM 2.20.10, which doesn't process negative numbers correctly; DASM 2.20.07 (bundled with bB 1.0) does.

## data — read-only ROM tables

`data` creates a read-only array in ROM. Unlike other BASICs, access does not need to be linear (no READ statement) — you index it like an array. Maximum size: **256 elements**. No bounds checking — reading past the end gives garbage but no error.

```
   data _D_My_Data
   200, 43, 33, 93, 255, 54, 22
end

   a = _D_My_Data[0]    rem  * 200
   b = _D_My_Data[1]    rem  * 43
   c = _D_My_Data[6]    rem  * 22
```

- Values are read-only ROM: `_D_My_Data[1] = 200` compiles but does nothing.
- All data tables must live in the **same bank where they are read** — cross-bank reads give wrong data with no error.
- Use any variable as the index: `temp5 = (rand/32) : _Freq_Mem = _D_Wall_Freq[temp5]`.

## data _length constants

Every data statement automatically defines a constant holding the number of elements: the data name + `_length`.

```
   data _D_My_Data
   1,2,3,4,5,6,7,8,9
end

   a = _D_My_Data_length     rem  * a = 9
```

The `_length` constant only works **after** the data statement appears in the source. To use it earlier, re-declare it as a const near the top:

```
   const _D_My_Data_length=_D_My_Data_length
```

## sdata / sread — sequential data

`sdata` defines sequential data, read in order like other BASICs' DATA/READ. No 256-element limit (limited only by bank size, 4K) and no pointer to manage. Cost: it consumes **two adjacent regular variables** (not Superchip) to remember the current position.

```
   sdata _My_Music=a
   1,2,3,4,5,6,7,255
end

   t = sread(_My_Music)
```

- `<name>` is what you read with sread; `<variable>` is the first of the two variables it uses (here a and b).
- The program must actually **run over** the sdata statement to initialize the pointer, so define it outside the game loop — running over it again resets it to the beginning (that's also how you "restore").
- There is **no end-of-data indication and no length constant** — put a terminal value (here 255) at the end and check for it: `if t = 255 then ...`
- As with data, sequential tables must be in the bank where they're read.

## rand and rand16

`rand` is a special variable that calls the random number generator every time it's used. It returns a pseudo-random number from **1 to 255** (0 to 255 when using rand16 or the DPC+ kernel).

```
   a = rand
   if rand < 32 then r = r + 1
```

- **rand16** (better randomness): set aside one variable at the top of the program — `dim rand16 = <var>` where <var> is one of a-z or var0-var47 (Superchip). Never use that variable for anything else, never clear it (that ruins the sequence), and never write "rand16" anywhere else — keep using `rand` in your code.
- **DPC+ kernel**: has its own ARM-based 32-bit LFSR — do **not** use `dim rand16`.
- Seeding: you can assign to rand (`rand = 17`), but storing **0 breaks it** (all later reads are 0).
- Bankswitched games: rand may slow the game if used often (bankswitch on each call); the `inlinerand` optimization option avoids this.

**Randomizing a bit** (by RevEng) — to randomly flip, say, bit 0 of a:

```
   temp5 = (rand & %00000001)
   a = a ^ temp5
```

For bit 7, use `(rand & %10000000)`; move the 1 to whichever bit position you want.

**Random -1 or 1:** `a = 255 + (rand&2)`

## Random ranges: rand&N charts

Use AND (&) with 1, 3, 7, 15, 31, 63, or 127 for a quick random range. AND uses the fewest cycles (`a = (rand&7)` is faster than `a = (rand/32)`). Division is the slower alternative with the same range.

| Faster way | Binary mask | Range | Slower way | Faster +1 | Range |
|---|---|---|---|---|---|
| `a = (rand&1)` | 00000001 | 0 to 1 | `a = (rand/128)` | `a = (rand&1) + 1` | 1 to 2 |
| `a = (rand&3)` | 00000011 | 0 to 3 | `a = (rand/64)` | `a = (rand&3) + 1` | 1 to 4 |
| `a = (rand&7)` | 00000111 | 0 to 7 | `a = (rand/32)` | `a = (rand&7) + 1` | 1 to 8 |
| `a = (rand&15)` | 00001111 | 0 to 15 | `a = (rand/16)` | `a = (rand&15) + 1` | 1 to 16 |
| `a = (rand&31)` | 00011111 | 0 to 31 | `a = (rand/8)` | `a = (rand&31) + 1` | 1 to 32 |
| `a = (rand&63)` | 00111111 | 0 to 63 | `a = (rand/4)` | `a = (rand&63) + 1` | 1 to 64 |
| `a = (rand&127)` | 01111111 | 0 to 127 | `a = (rand/2)` | `a = (rand&127) + 1` | 1 to 128 |

Adding a constant shifts the range: `a = (rand&7) + 8` gives 8 to 15 (7+8=15).

**Warning:** even with rand16, using *only* division or *only* AND can create visible patterns. If you see a pattern, mix in a little division (e.g., replace one `rand&63` term with `rand/4`).

**Random sprite placement** — combine terms to hit an exact window. For a minimum of 21 and maximum of 131 (110-wide span: 63+31+15+1 = 110):

```
   player1x = (rand&63) + (rand&31) + (rand&15) + (rand&1) + 21
```

If patterns appear: `player1x = (rand/4) + (rand&31) + (rand&15) + (rand&1) + 21`

## Random percentages

To limit the chance of something happening, compare rand against a threshold (out of 256):

```
   5%   temp5 = rand : if temp5 < 13 then
  10%   temp5 = rand : if temp5 < 26 then
  15%   temp5 = rand : if temp5 < 38 then
  20%   temp5 = rand : if temp5 < 51 then
  25%   temp5 = rand : if temp5 < 64 then
  30%   temp5 = rand : if temp5 < 77 then
  35%   temp5 = rand : if temp5 < 90 then
  40%   temp5 = rand : if temp5 < 102 then
  45%   temp5 = rand : if temp5 < 115 then
  50%   temp5 = rand : if temp5 < 128 then
  55%   temp5 = rand : if temp5 < 141 then
  60%   temp5 = rand : if temp5 < 154 then
  65%   temp5 = rand : if temp5 < 166 then
  70%   temp5 = rand : if temp5 < 179 then
  75%   temp5 = rand : if temp5 < 192 then
  80%   temp5 = rand : if temp5 < 205 then
  85%   temp5 = rand : if temp5 < 218 then
  90%   temp5 = rand : if temp5 < 230 then
  95%   temp5 = rand : if temp5 < 243 then
```

(An imperfect but close-enough list.)

## Common mistakes

- Assuming values can exceed 255 or go below 0 — variables wrap (255+1=0, 0-1=255) with no error.
- Writing `if a{0} = 1 then` — bit tests take no equal sign; use `if a{0} then` / `if !a{0} then`.
- Using var0-var47 as general variables when the kernel needs them for the playfield (standard kernel without Superchip: only var44-var47, and only if not scrolling / not using pfclear).
- Storing a value in a variable whose bits you're using as flags — `a = a + 1` clobbers every flag bit in a.
- Expecting temp1-temp6 to survive drawscreen or math routines — they don't.
- Using parentheses `()` instead of `{}` for bits, or a variable instead of a constant 0-7 inside `{}`.
- Writing to data tables (`_D_My_Data[1] = 200` compiles but does nothing — they're ROM).
- Reading a data table from a different bank — no error, just wrong values.
- Forgetting the 255 terminal value in sdata (no end-of-data detection exists).
- Assigning 0 to rand — it breaks permanently; also clearing the variable you dimmed as rand16.
- Using `dim rand16 = <var>` with the DPC+ kernel (it already has a 32-bit LFSR).
- Using AND/OR/XOR on write-only registers (`NUSIZ0 = NUSIZ0 & $0F` fails).
- Multiplying/dividing without `include div_mul.asm` when the operation needs it (look for "mul8"/"mul16" in unknown-symbol errors).
- Using `dim` where you wanted `def` for single bits, or putting spaces around the equals sign in a def.
