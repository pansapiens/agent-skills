# batari Basic Flow Control Reference

Everything that redirects program flow in batari Basic (bB): labels, goto, gosub/return, if-then (all forms), on…goto/on…gosub, for…next loops, and the smartbranching compiler directive.

**Contents:** Labels · goto · gosub · return / return thisbank / return otherbank · pop · if-then overview · Simple true/false checks · Simple comparisons · Compound conditions (&& || !) · What may follow then · else · Multiple if-thens on one line · Multiline if blocks (no endif!) · on…goto · on…gosub · for…next and next · set smartbranching on · Cycle counts · Common mistakes

**Big bB vs normal BASIC differences:** labels have NO colon after them, there is no endif keyword, `=` (not `==`) tests equality, `<>` (not `!=`) tests inequality, and only one `||` is allowed per if statement.

## Labels

A label names a jump target for goto/gosub. You may use line numbers instead if you prefer, but both are optional — you only need them where you want a goto or gosub target.

Jump rules: (a label is a line by itself, or followed by statements on the same line)

```
labelname
labelname statement
linenumber
linenumber statement
```

Example:

```
10 pfpixel 2 3 on

20
   drawscreen

__My_Location
   x = x + 1

__My_Location_2 x = x - 1
```

Rules:

- A label may contain any combination of letters (upper or lowercase), numbers, and underscores — even as the first character.
- **Never use a dot/period in a label** — not at the beginning, not at the end, not in between.
- **NO COLON after a label.** Unlike most BASICs, `__My_Label:` is invalid bB; write just `__My_Label`.
- A label must not match or begin with a known bB keyword or any label internal to bB (like `end`, `kernel`, and so on). You cannot name a label `next` or `pfpixel`; `scorechange` is invalid (begins with `score`) but `changescore` is fine.
- A label must not match any of your variable aliases.
- Labels, line numbers, and `end` must NOT be indented. All program statements MUST be indented (3 spaces is the usual bB style).
- Convention from the source: start variable aliases with one underscore and labels with two underscores, capitalizing each word (e.g. `__Flying_Cat_Data`). Then you never collide with bB keywords or with your own variable aliases.

## goto

Jumps to a line number or label anywhere in your program.

Syntax:

```
   goto labelname
   goto linenumber
   goto labelname bankN
```

- `goto` alone: 3 cycles. `goto` with a bankswitch: 49 cycles.
- In bankswitched games, if you jump to code in another bank, you MUST specify the bank. `goto` without a bank suffix only stays within the current bank.

Example:

```
   goto 100
   goto __My_Subroutine
   goto __Section_2_of_Code bank2
```

Warning: `goto` inside a subroutine that was called with gosub skips the matching `return` (see pop below for how to cancel a return address deliberately).

## gosub

Calls a subroutine from multiple locations in your program. Control comes back when the subroutine executes a return.

Syntax:

```
   gosub labelname
   gosub linenumber
   gosub labelname bankN
   if condition then gosub labelname
```

Examples:

```
   gosub __My_Subroutine
   gosub 100
   gosub __Move_Monster bank2
   if x > 10 then gosub __Sink_Ship

__My_Subroutine
   a = a - 1
   x = x + 10
   return
```

Stack limit (critical!): each gosub uses 2 bytes of stack space, recovered by the matching return. Only 6 bytes of stack space are reserved for this — that is at most 3 levels of nested gosub. Using too many nested subroutines overwrites variables and causes strange, hair-pulling problems. Try to avoid nested subroutines. (Also note this limit may change in later bB versions.)

Bankswitched games: jumping to a subroutine in another bank requires the bank suffix (e.g. `gosub __Move_Monster bank2`). If you use gosub with bankswitching, read the return section below about `return thisbank` and `return otherbank`.

Cycle counts: gosub + return = 12 cycles; gosub with bankswitch + return = 122 cycles; gosub with bankswitch + `return otherbank` = 110 cycles.

## return / return thisbank / return otherbank

Returns from a subroutine to the statement right after the gosub that called it.

Syntax:

```
   return
   return thisbank
   return otherbank
```

- `return` — always works, but in bankswitched games it adds ROM space and cycles of overhead to automatically figure out which bank called the subroutine.
- `return thisbank` — returns only to the current bank. Much faster; use it whenever possible. **The program will crash if the subroutine was called from another bank.**
- `return otherbank` — can be used anywhere, just like plain `return`; faster than plain `return` for returning to other banks, slower for returns within the same bank.

Example:

```
__My_Subroutine
   a = a - 1
   return thisbank
```

Warning: if a running program hits a `return` with no gosub that called it, the program will crash or strange things may happen. (Also, `return` can return a value when used in a user-defined function — see the functions reference.)

## pop

Cancels the return address pushed by the last gosub. This essentially makes the last gosub behave as if it had been a goto.

Syntax:

```
   pop
```

Example (subroutine that never returns to its caller):

```
   gosub __Next_Level

__Next_Level
   pop
   goto __Draw_Level
```

## if-then overview

The basic syntax:

```
   if condition then action
```

`action` can be a statement, a label, or a line number. If the condition is true, the statement is executed (or the program jumps to the label/line number). Numerically: any comparison result that equals zero is false; all other numbers are true.

There are three types of if-then statements: (1) simple true/false, (2) simple comparison, (3) compound statement.

Branch out of range: an if-then with a label or line number as the target is assembled as a short branch — it can only jump forward 127 bytes or backward 128 bytes. If the target is farther, assembly fails with a "branch out of range" error. Fix it by writing `then goto`, or turn on smartbranching (see set smartbranching on below) and let the compiler pick for you.

## if-then type 1: simple true/false

The condition is a single item checked for nonzero. This is the usual way to read joysticks, console switches, hardware collisions, and single bits.

Examples:

```
   if a then goto __Fried_Fish
   if joy0up then x = x + 1
   if switchreset then goto __Mucus_Membrane
   if collision(player1,playfield) then t = 1
   if a{0} then x = x + 1
   if !a{3} then a{4} = 1
```

- `if a then …` fires when a is anything except zero.
- `if joy0up then …` fires while joystick 0 is pushed up.
- `if switchreset then …` fires when the console reset switch is set.
- `if collision(player1,playfield) then …` fires when player1 overlaps the playfield.
- Bit checks: `if a{0} then …` is true when bit 0 of a is 1; `if !a{3} then …` is true when bit 3 of a is 0.

## if-then type 2: simple comparison

One comparison per condition. Valid comparison operators: `=`, `<`, `>`, `<=`, `>=`, `<>`.

Examples:

```
   if a < 2 then goto __Doggy_Dip
   if f = g then f = f + 1
   if r <> e then r = e
```

- Use single `=` for equality. `==` is NOT valid bB and triggers errors ("complex condition detected" / "invalid operator").
- Use `<>` for not-equal. `!=` is NOT valid bB syntax.
- bB always assembles one comparison and one branch no matter whether you use `<`, `<=`, `>`, or `>=`, so there is no size or speed advantage in choosing one operator over another.

## if-then type 3: compound conditions (&& || !)

Boolean logic operators, tokenized as: `&&` = AND, `||` = OR, `!` = NOT.

Rules (from the bB AND/OR/NOT chart):

| Operator | Meaning | How many allowed per if | Safe to use with | Cannot be used with |
|----------|---------|--------------------------|------------------|---------------------|
| `&&` | AND | more than one | `!`, `<` `>` `=` | `\|\|` (OR) |
| `\|\|` | OR | only one | `!`, `<` `>` `=` | `&&` (AND) |
| `!` | NOT | more than one | `&&`, `\|\|` | comparisons (`<` `>` `=` etc.) |

- You cannot mix `&&` and `||` in one if-then.
- Only one `||` is allowed per statement; multiple `&&` are fine.
- The NOT operator (`!`) may only be used on conditions that do not themselves contain a comparison token (such as `=`, `<`, `>`, `<>`). `if !joy0up` is fine; `if !a = 5` is not.

Examples:

```
   if x < 10 && x > 2 then b = b - 1
   if !joy0up && _Game_Over = 0 then goto __Pig_Knuckle
   if x = 5 || x = 6 then x = x - 4
   if a < 31 && a > 0 then goto __64_Tetrahedron
   if a = 2 || a = 4 then a = a + 1
   if !joy0up then goto __Vesica_Piscis
```

Warning: if you use `||` in an if-then, the statement must be located at the beginning of a line. Otherwise compilation will currently succeed but the program will probably not work correctly.

## What may follow then

Be precise — the action after `then` may be any ONE of these:

1. **A label** — jumps there if true: `if a = 1 then __Skip_This`. Subject to the 127-byte forward / 128-byte backward branch limit (see smartbranching).
2. **A line number** — jumps there if true: `if a = 1 then 40`. Same branch limit applies.
3. **goto + label/line number** — `if a = 1 then goto __Skip_This`. Always works regardless of distance, but uses more code space than a bare then-target.
4. **gosub + label** — `if x > 10 then gosub __Sink_Ship`.
5. **One or more statements** — `if joy0up then x = x + 1`. Multiple statements separated by colons all belong to the then-branch: `if a > b then r = 2 : pfpixel 3 5 on : d = d - 1`.
6. **Another if** — chaining, which acts as a logical AND (see next section).
7. **… else …** — any of the above actions, then `else`, then another action (single line only).

Not allowed after then:

- `endif` — there is no endif in bB (see multiline if blocks below).
- A block of statements on the following lines.
- Omitting `then` entirely: `if a = 5 goto __Flying_Frog` fails with "Error: invalid operator: goto" plus "complex condition detected". You must write `if a = 5 then goto __Flying_Frog`.

## Multiple if-thens on a single line

Placing another `if` immediately after a `then` is valid syntax and acts as a logical AND. The compiler evaluates each condition in turn; if all are true it executes the final command, otherwise it skips the rest of the line.

```
   if a = 1 then if b = 2 then c = 3
```

Compiles like:

```
   if a <> 1 then goto __Skip_Line
   if b <> 2 then goto __Skip_Line
   c = 3
__Skip_Line
```

This became a reliable, space-saving workaround for historical bB quirks when evaluating multiple boolean (&& and ||) operators in complex statements.

Warnings: multiple if-thens on one line might not work correctly if you combine them with boolean operators (&&, ||). Also be careful combining `then if` with `else` on the same line — the compiler may not assign the else to the condition you expect.

## else

`else` lets one if-then divert flow two different ways: then-action if true, else-action if false.

Rules:

- The else MUST be on the same line as its if-then.
- You may put colon-separated statements between the then and the else, but **the else itself must not come after a colon** — never write `: else` (or `else :`); the else attaches directly to the end of the last then-statement.
- Single line only — there is no multiline else in bB.

Examples:

```
   if r = 2 then goto __Jump else goto __Swim
   if a > b then r = 2 : pfpixel 3 5 on : d = d-1 else d = d+1 : r = 3
   if a > b then goto __Jump else c[4] = 12
```

Warnings: the else keyword might not work correctly in a statement containing `&&`. The else may also not work as expected when there is more than one if-then on a single line. (The source author avoids else entirely and uses the reverse-condition trick below instead.)

## Multiline if blocks (no endif in bB!)

bB has NO endif — `if x = 4 then` followed by a block of lines and an `endif` line will not compile. To run several statements conditionally, reverse the condition, `goto` a label past the block, and label the end of the block:

```
   if x <> 4 then goto __Skip_Monster_Kill
   x = t - 2 : _mosterheight = (_monsterheight&7) + 1
   pfhline 3 4 x off : a = (rand&127) + 16 : r{0} = 1
__Skip_Monster_Kill
```

- Reverse each comparison: `=` ↔ `<>`, `<` ↔ `>=`, `>` ↔ `<=`.
- If the original used `&&`, the inverted form uses `||` (and vice-versa):

```
   if x = 4 && y = 2 then r = 4
```
becomes
```
   if x <> 4 || y <> 2 then goto __Skip_Ninja_Stab
   r = 4
__Skip_Ninja_Stab
```
```
   if r < 4 then e = e + 1
```
becomes
```
   if r >= 4 then goto __Skip_Fish_Jump
   e = e + 1
__Skip_Fish_Jump
```

(The alternative is `if x = 4 then gosub __Monster_Kill` and put the block in the subroutine.)

## on…goto

Works like a case statement — replaces multiple if-thens when conditions are ordinal (first, second, third, …). The variable's value selects a label: **the index is 0-based** (value 0 jumps to the first label, 1 to the second, and so on).

Syntax:

```
   on variable goto label0 label1 label2 label3
```

Example:

```
   on _Walk_Up goto __P0U0 __P0U1 __P0U2 __P0U3
```

is the same as:

```
   if _Walk_Up = 0 then goto __P0U0
   if _Walk_Up = 1 then goto __P0U1
   if _Walk_Up = 2 then goto __P0U2
   if _Walk_Up = 3 then goto __P0U3
```

The variable can hold its 0-to-N values in any order (3, then 0, then 1, then 0 again is fine) — you will usually just increment it by 1 for animation frames.

Restrictions and warnings:

- **You cannot use expressions.** `on _Walk_Up-8 goto …` is invalid. Compute into a temp variable first:

```
   _My_Temp = _Walk_Up - 8 : on _My_Temp goto __P0U0 __P0U1 __P0U2 __P0U3
```

- **No bounds checking:** there is no automatic check that the variable's value coincides with a label in the list. If the value is 4 or more with only 4 labels, the statement tries anyway, which almost always crashes the program. Guard the variable first:

```
   if _Walk_Up < 4 then on _Walk_Up goto __P0U0 __P0U1 __P0U2 __P0U3
```

- **Too many labels:** there seems to be a limit of around 45 labels on a single on…goto line. Split into multiple guarded on…goto statements:

```
   if _Walk_Up < 4 then on _Walk_Up goto __P0U0 __P0U1 __P0U2 __P0U3
   _My_Temp = _Walk_Up - 4
   if _My_Temp < 4 then on _My_Temp goto __P0U4 __P0U5 __P0U6 __P0U7
   _My_Temp = _Walk_Up - 8
   if _My_Temp < 4 then on _My_Temp goto __P0U8 __P0U9 __P0U10 __P0U11
```

- **Bankswitching:** on…goto can only jump within the current bank. To dispatch to labels in another bank, jump to a dispatcher in that bank:

```
   goto __Color_Fun bank2
   ...
   bank 2

__Color_Fun
   on _Walk_Up goto __Red __Green __Blue __Purple
```

## on…gosub

Identical to on…goto except control returns to the statement following the on…gosub list when the selected subroutine executes a return. Same restrictions: 0-based index, no expressions, no bounds checking, ~45-label limit, current-bank-only (use the same dispatcher workaround shown above).

Syntax:

```
   on variable gosub label0 label1 label2 label3
```

Example:

```
   on _Walk_Up gosub __P0U0 __P0U1 __P0U2 __P0U3
   drawscreen
```

When a return is encountered, control resumes at the drawscreen after the list.

No expressions allowed — use a temp variable:

```
   _My_Temp = _Walk_Up - 8 : on _My_Temp gosub __P0U0 __P0U1 __P0U2 __P0U3
```

Bounds-check the variable first (value beyond the label list almost always crashes the program):

```
   if _Walk_Up < 4 then on _Walk_Up gosub __P0U0 __P0U1 __P0U2 __P0U3
```

Bankswitching: same current-bank-only restriction and the same dispatcher workaround as on…goto — `goto __Dispatcher bankN`, put the `on … gosub` list in that bank, and have each branch return to just after the dispatcher call.

## for…next and next

for…next loops work like other Basics.

Syntax:

```
   for variable = value1 to value2 [step value3]
   ...
   next
```

`step` is optional and defaults to 1; a negative step is allowed. value1, value2, value3 may be variables or numbers.

Examples:

```
   for x = 1 to 10
   for a = b to c step d
   for l = player0y to 0 step -1
   for x = 1 to 10 : a[x] = x : next
```

next quirks:

- Normally you would put a variable after next, but bB ignores it and jumps to the nearest preceding for. The usual call is therefore a bare `next`.
- next does not care about program flow — it finds the nearest preceding for based on distance in the code, even if that for was never executed:

```
   for x = 1 to 20
   goto __Zero_Point_Energy
   for g = 2 to 49
__Zero_Point_Energy
   next
```

The next above WILL NOT jump back to the first for — it jumps to the nearest one. Be very careful when using next.

Loops in general: all bB programs must be loops (the program never exits). Limit your use of loops that do not include a drawscreen somewhere — too many loops eat the limited frame time. It might be tempting to use a for…next with drawscreen in it to slow down a game, but a counter is better because you can slow down specific things while others run at full speed.

## set smartbranching on

Compiler directive, not a statement. Tells the compiler to generate optimal assembly when it sees an if-then with a label or line number after the then.

Syntax (place near the beginning of your program):

```
   set smartbranching on
```

Why: without it, `if condition then label` compiles to a short branch that can only jump forward 127 bytes or backward 128 bytes. Farther targets make the assembler fail with "branch out of range". With smartbranching on, the compiler decides for each if-then whether it needs `then` or `then goto`, eliminating practically all such errors.

- Smartbranching is OFF by default, because it makes the generated assembly file harder for a human to read (bB's original vision was that you could study the .asm file to learn assembly). It does NOT slow down your program, so don't be afraid to use it.
- Alternative: use `then goto` everywhere and skip smartbranching — but `then goto` uses more code space than plain `then`.
- Warning: smartbranching will sometimes cause the compilation to fail. In that case, use `then goto` instead of plain `then` for the if-then statement that caused the problem.
- Note from the source author: he had all kinds of mysterious problems using smartbranching with a very long program; switching to `then goto` fixed them, so he dropped smartbranching.
- The directive was designed to be turned on/off throughout your code, but it is unclear whether that actually works — keep it near the top.

## Cycle counts (summary)

| Operation | Cycles |
|-----------|--------|
| goto | 3 |
| goto with bankswitch | 49 |
| gosub + return | 12 |
| gosub with bankswitch + return | 122 |
| gosub with bankswitch + return otherbank | 110 |

## Common mistakes

- **Putting a colon after a label.** bB labels never take colons — `__My_Label:` is invalid; write `__My_Label`.
- **Indenting a label or line number.** Labels, line numbers, and `end` must not be indented; all statements must be.
- **Naming a label with a keyword prefix or a dot.** No `next`, `pfpixel`, `scorechange`…; no periods anywhere in a label; labels must not match your variable aliases.
- **"Branch out of range" assembler error.** An if-then with a label/line number target is limited to 127 bytes forward / 128 bytes backward. Fix with `then goto` or `set smartbranching on`.
- **Forgetting then:** `if a = 5 goto __Flying_Frog` → "Error: invalid operator: goto" / "complex condition detected". Always `if a = 5 then goto __Flying_Frog`.
- **Using == or != in conditions.** bB uses single `=` for equality and `<>` for not-equal; both wrong forms trigger "complex condition detected" / "invalid operator" errors.
- **Mixing && and ||, using two ||, or using ! on a comparison.** Only one `||` per if; multiple `&&` allowed; `!` only on comparison-free conditions like `!joy0up`.
- **`||` statement not at the beginning of a line.** It currently compiles but the program will probably not work correctly.
- **else after a colon** (`… : else : …`) is invalid — else attaches directly to the last then-statement, on the same line as the if-then. else is also unreliable with `&&` and with multiple if-thens on one line.
- **Using endif** — bB has no endif; reverse the condition, `goto` a label, and put the label after the block.
- **Deeply nested gosubs.** 2 bytes of stack per gosub, only 6 bytes reserved (about 3 levels). Overflow overwrites variables and causes bizarre bugs.
- **return without a matching gosub** crashes the program; `return thisbank` crashes if the subroutine was gosub'd from another bank.
- **on…goto/on…gosub with an out-of-range value.** No bounds checking — guard with `if x < N then on x …` or the program will likely crash.
- **Expressions inside on…goto/on…gosub.** Not allowed — assign to a temp variable first.
- **Forgetting the bank suffix** when goto/gosub targets another bank in a bankswitched game.
- **Expecting next to follow program flow.** It jumps to the nearest preceding for by distance, even one that never executed; and any variable written after next is ignored.
