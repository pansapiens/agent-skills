# batari Basic (bB) — Compilation Errors, Runtime Problems, and Inline Assembly

Purpose: a troubleshooting reference — how the bB compilation pipeline works, how to read error output, a dictionary of common error messages with fixes, runtime problems (blank screen, wrong colors, jitter), and the basics of inline assembly (`asm`...`end`, `include`, `includesfile`, `inline`). For LLMs that know normal BASIC but little about bB or the Atari 2600.

Contents: [Pipeline](#the-compilation-pipeline-which-stage-each-error-comes-from) · [Compile output](#reading-compile-output-and-generated-files) · [Searching the .asm file](#searching-the-generated-asm-file) · [Error dictionary](#error-dictionary) · [Verbose-error quirks](#verbose-error-quirks-message--cause--fix) · [Unresolved symbol names](#specific-unresolved-symbol-names) · [Blank screen](#blank-screen) · [Silent runtime failures](#silent-runtime-failures-black-or-frozen-screen-no-compiler-error) · [Score color bleed](#players-use-the-score-color) · [Timing problems](#timing-problems-jitter-shaking-rolling) · [Old versions](#games-for-earlier-versions-of-bb--upgrading) · [Emulator arrow keys](#arrow-keys-not-working-in-an-emulator) · [asm blocks](#asm--end--inline-assembly) · [include/includesfile/inline](#include--includesfile--inline--adding-asm-modules) · [Hacking .asm files](#hacking-bbs-asm-files) · [Debugging workflow](#debugging-workflow) · [Common mistakes](#common-mistakes)

## The compilation pipeline (which stage each error comes from)

bB is compiled in stages. When you build `mygame.bas`, roughly this happens:

1. **Preprocess** — bB scans the source. It only catches the most obvious errors, such as unrecognized characters.
2. **Compile** — the preprocessed BASIC is translated to 6502 assembly and written to an intermediate assembly file. A wider range of errors is caught here, but many errors sneak past.
3. **Postprocess/link** — bB rewrites and optimizes the assembly and links in the kernel and module `.asm` files listed in your includes file, producing the **composite assembly file** (`mygame.bas.asm`, next to your `.bas` file).
4. **Assemble** — the DASM assembler turns the composite `.asm` file into `mygame.bin`. DASM errors are the most cryptic.

There are **3 stages where errors may be caught: the preprocessor, the compiler, or the assembler.** Knowing which stage produced a message tells you where to look:

| Stage | Error line numbers refer to | Example |
|---|---|---|
| Preprocessor | The Nth **line of code in your .bas source** | `(34) unrecognized character: "@"` |
| Compiler | The Nth line of code in your .bas source | `(34) Error: Unknown Keyword: hgoto` |
| Assembler | The Nth line of the **composite .asm file** (often a big number, sometimes > 10000) | `(1767) Error: Value in 'cmp #512' must be <$100` |

- Preprocessor and compiler errors point you at your BASIC source, so they are usually easy to fix. Note that compiler error text "doesn't always make a lot of sense, but at least they usually point you to the right place."
- A common cause of **compiler** errors: failing to indent keywords, or indenting labels and line numbers (bB is indentation-sensitive — this is a big difference from normal BASIC).
- Assembler errors only appear after conversion to assembly, so the connection to your BASIC line is indirect — see [Searching the .asm file](#searching-the-generated-asm-file).

## Reading compile output and generated files

Files land **in the same directory as your `.bas` file**:

| File | What it is |
|---|---|
| `mygame.bin` | The finished binary — run it in an emulator or flash cart |
| `mygame.bas.asm` | The composite assembly file: your compiled code plus all linked kernel/module `.asm` files. Your original bB lines appear in it as comments after a semicolon |
| `mygame.lst` | DASM's listing file — assembler errors and messages land here |
| `mygame.sym` | DASM's symbol table — useful for looking up where labels ended up |

**"Compilation Completed: ____ Bytes of ROM Space Left"** — how much ROM is free.

- Sometimes bB sticks your code into otherwise-wasted space and the reported number doesn't change even though you added code. Graphics data must be aligned on memory page boundaries, so bB sometimes pads with empty ROM before a boundary. New code quietly fills that padding — then one day an addition pushes the graphics data past its alignment and you "lose" a bunch of reported space at once.
- To compare which of two code styles uses less ROM, do it in a small throwaway test program so you can see the actual bytes saved or wasted — in a big program the alignment slack hides the difference.

## Searching the generated .asm file

For most assembler errors, the offending line of the composite `.asm` file is echoed in parentheses. To track the error back to your BASIC source:

1. Open `mygame.bas.asm` in an editor that can jump to a line number (or at least show the current cursor line). The number is often large (> 10000), so hand-counting is not feasible.
2. Jump to that line, then **look upward for a line of bB code inserted as a comment (after a semicolon)** — that is usually where the error occurred in your `.bas` file. The error may be subtle, but it is usually there somewhere.
3. If no bB code comment is nearby, the error is probably in a `player`/`playfield` (or other graphics) definition — find the data in the graphical object and match it to where you defined it in bB.
4. If that doesn't apply either, the error may be in inline `asm` code you inserted.

## Error dictionary

Table format: message → meaning → fix.

| Error message | Meaning | Fix |
|---|---|---|
| `(34) unrecognized character: "@"` (preprocessor) | An illegal character in the source | Remove the character; preprocessor only catches the most obvious errors like this |
| `(34) Error: Unknown Keyword: hgoto` (compiler) | Typo'd keyword, OR a keyword that wasn't indented, OR a label/line number that was indented | Fix spelling; make sure keywords are indented and labels/line numbers start at the left margin |
| `Branch out of range` (assembler) | An `if-then` jump target is too far away — a plain `then` jump can only go **forward 127 bytes or backward 128 bytes** | Easiest: add `set smartbranching on` at the top of your program (compiler then picks `then` vs `then goto` for you). Alternative: write `if a=1 then goto 40` instead of `if a=1 then 40` — but the assembler gives little help finding which line failed, so you may have to change all relevant `then`s to `then goto` |
| `Duplicate label ...` (assembler) | The same label or line number used on two different lines (e.g. `__Lizard_Meat` twice) | Rename one of the labels in your BASIC source. **Note:** the assembler sometimes reports bogus duplicate labels (an assembler bug — sometimes hundreds, only the first is shown). Ignore them if the game builds successfully, or if the build fails but the unresolved-symbol list is non-empty (fix the symbols first) |
| `Unresolved symbol ...` (assembler) | See [next topic](#unresolved-symbols) | See below |
| `(1767) Error: Value in 'cmp #512' must be <$100` (assembler) | A value used in a comparison or assignment (here 512) is too large — **all values must be 0–255, except score** (and score can't be compared normally either) | Keep values in 0–255; split larger numbers across variables or compare the score digit-by-digit |
| Syntax errors (assembler) | Typographical error in a `data` statement, `player`/`playfield` declaration, inline asm, or other places | Often only fixable by searching the composite `.asm` file (see above) |
| `2600 Basic Compilation Failed!` (any stage) | Generic bB failure banner | Use the messages above/below it to find the stage and cause |
| `LINE --> complex condition detected` | An `if-then` that is **missing its `then`**, or things in the if-condition that aren't supposed to be there | Add the missing `then`; simplify the condition |
| `Segmentation fault (core dumped)` right after `batari Basic v1.9` | **Compiler bug** (native build of v1.9), not your syntax — triggered by programs that switch playfield colors with MANY `pfcolors:` blocks (reproduced with 17+ blocks used as runtime-switchable color tables, e.g. the original RT `ex_pause.bas`/`seaweed_assault.bas`) | Reduce the program to ONE `pfcolors:` block (choose colors at compile time). If you need per-frame color animation, animate `COLUPF`/`COLUBK` or `pfheights` instead. If a segfault appears in an incremental build, the feature you just added is the trigger — bisect by deleting that feature's block |

## Verbose-error quirks (message → cause → fix)

These all produce `LINE --> complex condition detected` plus a `--VERBOSE ERROR MESSAGE --`. A normal BASIC programmer trips on these constantly:

| Bad code | Cause | Fixed code |
|---|---|---|
| `if _Answer == 42 then ...` | **Double equal sign in an if-then.** Unlike C/Python, bB uses a **single** `=` for comparison; `&&` and `||` are still used for compound conditions | `if _Answer = 42 then ...` |
| `if _Dog - _Cat then __Eat` | **Minus sign instead of equal sign** in the condition. With a bare `then` you get the verbose error; with `then goto` it even compiles — but it's still wrong | `if _Dog = _Cat then goto __Eat` |
| `if player1x => player0x then ...` | **Equal sign before greater/less.** The equal sign always comes AFTER: `>=`, `<=` — never `=>`, `=<` | `if player1x >= player0x then ...` |
| `if a = 5 goto __Flying_Frog` | **Missing `then` directly before `goto`** — also reports `Error: invalid operator: goto` | `if a = 5 then goto __Flying_Frog` |
| `rem----------` | `rem` with **no space after the keyword** — bB needs room around `rem` to recognize it | `rem ------` (space after rem) |
| `_Bit6_LR_Joy_Movement {6} = 0` | **Space before the curly brackets** in a bit operation — bit aliases must touch their `{n}` | `_Bit6_LR_Joy_Movement{6} = 0` |

## Unresolved symbols

Any time the assembler finds an error it prints an unresolved-symbol list:

- **If the list is empty, ignore it** — the real problem lies elsewhere.
- **If something is on the list, that is likely your error.** Common causes:

| Cause | Example | Fix |
|---|---|---|
| `goto`/`if-then`/`gosub` target label doesn't exist | `goto __Flying_Bicycle` with no such label | Define the label, or fix the spelling |
| Call to a non-existent function | `a = myfunction(33)` | Define the function (bB `function` or asm) |
| Module not included — internal routine referenced but its module isn't compiled in | `a = e/17` produces `div8` as an unresolved symbol if the module `div_mul.asm` is not included | Add `include div_mul.asm` at the very top of your program |
| Anything else | — | Search the composite `.asm` file (see above) |

### Specific unresolved symbol names

| Symbol | Cause | Fix |
|---|---|---|
| `BS_jsr` | You pasted code from a bankswitching program into a 4k program and left `... bank n` calls in | Remove every use of `bank` |
| `qtcontroller` | Duplicate labels (each mismatch is listed with the error), or a stray **question mark in a label** (e.g. copy-pasted from sound-effect template code) | Fix the labels; remove the `?` |

## Blank screen

Symptom: the game compiles to a `.bin`, but the emulator shows a black screen.

1. **Are you calling `drawscreen` somewhere in your game loop — and does the game actually run in a loop?** bB programs must loop forever; code that runs off the end = blank/garbage screen.
2. If you are drawing, **you probably never set any colors — everything defaults to black** (invisible on a black background). Set these every game loop:

```bb
   COLUP0 = $0E : rem color of player0 and missile0
   COLUP1 = $64 : rem color of player1 and missile1
   COLUPF = $1C : rem color of playfield and ball
   COLUBK = $00 : rem background color
```

## Silent runtime failures (black or frozen screen, no compiler error)

These all compile cleanly to a ROM of the right size and then misbehave at
run time. They are the expensive bugs, because the compiler is happy and the
symptom (a black frame, or a frame that never changes) looks the same for
every one of them. `scripts/frame-check.py` exists to tell the two symptoms
apart from a batch of screenshots without opening each one.

**Black screen: `on x goto` ran off the end of its label list.** `on x goto`
is 0-based *and unchecked* — if `x` is greater than the number of labels, the
jump goes somewhere undefined and the program dies. This bites whenever the
variable is a 1-based "type" or "state" number:

```bb
   rem  _type is 1-4, but index 4 does not exist in a 4-label list
   on _type goto __A __B __C __D          ; WRONG - dies when _type = 4

   rem  either subtract first, or pad index 0 with a do-nothing label
   on _type goto __None __A __B __C __D   ; __None just does `return`
```

Minimal reproduction: a program whose only oddity is `_i = 3` followed by
`on _i goto __A __B __C` renders a 100%-black frame.

**Black screen or wrong sprite: a `player0:` block that never executes.**
A graphics block is not a declaration — it is a *statement* that sets the
sprite's pointer when control flows through it. A block parked at the end of
the file, after the main loop and all the subroutines, never runs, so the
sprite keeps whatever pointer it had (often another sprite's data, or
nothing). Put graphics blocks in the setup code that runs before the main
loop, or inside a subroutine you actually call.

**Frozen screen: a subroutine clobbered the loop counter.** There are no
local variables — all 26 are global, and so are `temp1`-`temp6`. A counting
loop that calls a helper using the same scratch variable never terminates:

```bb
   _tmp = 0
__FadeLoop
   _tmp = _tmp + 1
   gosub __PlaceSprites     ; ...which also uses _tmp for its own arithmetic
   drawscreen
   if _tmp < 60 then goto __FadeLoop    ; _tmp never gets past __PlaceSprites
```

Give animation and wait loops a counter variable that no subroutine touches.

**Wrong behaviour, no crash: an unbalanced `return`.** A shared tail block
reached by `goto` from two places, where only one of them arrived through a
`gosub`, will `return` to whatever happens to be on the stack:

```bb
   rem  path A:  gosub __Judge   -> goto __EndTurn -> return   (balanced)
   rem  path B:  goto __CompTurn -> goto __EndTurn -> return   (NOT balanced)
```

Symptom in a real game: one player's turn worked and the other silently did
nothing. Make every path into a shared block use the same convention — either
all `gosub` into it, or end it with a `goto` back to the main loop rather
than a `return`.

**Scrambled playfield: writing `CTRLPF` by hand.** Setting `CTRLPF` to get a
wider ball (`CTRLPF = $20`) displaced the whole playfield horizontally in the
standard kernel — bB relies on that register. Leave it alone unless a
reference tells you otherwise.

## Players use the score color

Symptom: your sprites/missiles briefly show the wrong color (the score's color).

The score is drawn using the player objects. **COLUP0 and COLUP1 must be set during every frame** (inside the main loop, before `drawscreen`) or the players' colors will revert to that of the score. Do not set colors just once at the top of the program — that works in normal BASIC thinking, but not here.

## Timing problems (jitter, shaking, rolling)

Symptom: "My game jitters, shakes or rolls!"

Your program spends too much time in the game loop:

- You have only **about 2 milliseconds between successive calls to `drawscreen` — about 2,700 machine cycles**. That's all your game logic gets per frame.
- `drawscreen` itself must run **60 times a second** and takes **about 12 milliseconds** to render the television display; your code runs while the picture is off-screen.
- Most common cause: too many calls to playfield plotting/scrolling routines, or too many large loops.

The only solution is to **reduce the complexity of the code between `drawscreen` calls**:

- Call `drawscreen` more than once throughout the program (split a long loop into pieces around drawscreens), or
- Spread calculations across several frames (e.g., update AI every other frame).
- Warning: calling `drawscreen` several times **without also moving your objects each time** will slow down your game.
- `set debug cycles on` (or `set debug cyclescore on`) helps find which part of a frame uses too many machine cycles.

## Games for earlier versions of bB & upgrading

**Old game broken under bB 1.0:** bB 1.0 has many changes that can break programs written for earlier versions. Chances are the players are no longer in the correct places — specifically, **14 pixels to the right** (the standard kernel now positions sprites accurately: 0 = left edge, 159 = right edge, because the new positioning routine runs at least twice as fast). Fix options:

```bb
   set legacy 0.99
```

- `set legacy 0.99` (or less) restores the old positioning and most old behavior. Recommended: actually fix the old game to account for the shift instead.
- You can also add `legacy = 99` (version × 100) to `2600basic.h` to always compile in 0.99 legacy mode — not recommended except when compiling many old programs.
- Legacy mode does NOT fix everything. Known un-fixed differences: a thin playfield line that bB 0.99c drew with the `no_blank_lines` kernel option (some used it as a health bar); the score moved 1 pixel left when the black HMOVE bar was eliminated; the score moved 1 more pixel left to accommodate the pfscore bars; if you redefine score graphics to be 8 pixels wide, the rightmost edge of the leftmost score digit may not display correctly.
- If legacy doesn't solve it, ask on the Atari 2600 Basic forum on AtariAge.

**Upgrading bB fixed nothing?** Make sure an **old `std_kernel.asm` file is not sitting in your project folder** — bB searches the current directory before the includes directory, so a stale copy there means you will always use the old kernel instead of the one that came with the new bB version. Delete it.

## Arrow keys not working in an emulator

When testing on a computer: the space bar stops working as the fire button while using the arrow keys to move diagonally. This is not a bug in your game — most computer keyboards can't handle certain simultaneous key presses (key rollover). **Use the left Ctrl key instead of the space bar** as fire and the problem goes away.

## `asm` ... `end` — inline assembly

Syntax (mnemonics indented by at least one space; labels NOT indented; `asm` and `end` on their own lines):

```bb
   asm
   lda #20
   sta a
end
```

Inserts 6502 assembly language directly into your program. Equivalent to the bB statement `a = 20`.

- **Register preservation: you do not need to preserve any register values except the stack pointer.** bB expects the accumulator, X, and Y to be clobbered; only the stack must be intact.
- You may access any variables defined in bB directly by name (`a`–`z`, temp variables, aliases like `player0x`).
- Inside `asm` blocks, indentation rules flip: mnemonics need at least one leading space, and assembly labels start at the left margin — the opposite of bB's keyword rule.

Example — clears the playfield (from the bB manual):

```bb
   asm
   ldx #47
   lda #0
playfieldclear
   sta playfield,x
   dex
   bne playfieldclear
end
```

Example — clears all normal variables (fastest way, from iesposta):

```bb
   asm
   LDA #0
   STA a
   STA b
   STA c
   STA d
   STA e
   STA f
   STA g
   STA h
   STA i
   STA j
   STA k
   STA l
   STA m
   STA n
   STA o
   STA p
   STA q
   STA r
   STA s
   STA t
   STA u
   STA v
   STA w
   STA x
   STA y
   STA z
end
```

**asm functions** (writing a bB-callable function in assembly — brief rules):

- Pass up to six values and return one — same as bB functions, except the **first argument goes in the accumulator (A) and the second in the Y register** (not temp1/temp2); arguments 3–6 go in temp3–temp6.
- To return a value, load it into the accumulator and `rts`. The function is entered with the S and Z flags set according to the accumulator's value.
- In a **bankswitched** game, return with `RETURN` (an assembler macro) instead of `rts`, so control returns to the calling bank.
- Use it via inline `asm` in your program, or compile separately and pull it in with `include`.

## `include` / `includesfile` / `inline` — adding asm modules

### include

Syntax:

```bb
   include div_mul.asm
   includesfile bankswitch_SC.inc
   set romsize 8kSC
```

- Pulls an extra module (general routine, function, or custom display kernel) into the final binary that isn't included by default — e.g. `include fixed_point_math.asm` for some fixed-point functions, or `include div_mul.asm` for division/multiplication routines. Lets you share source without attaching a custom includes file.
- **`include` should come before `includesfile` and before `set romsize`, or it may not compile.** There is no checking — include commands placed after an includesfile/kernel statement are silently ignored. Put all `include` statements at the very beginning of your program.
- bB places the module where it sees fit (typically the first bank). For control over placement, use `includesfile` or `inline`.

### includesfile

Syntax:

```bb
   includesfile myincludes.inc
```

- The includes file lists the filenames of **all** modules that will be in the final binary, and **the order they appear in (crucial)**. Default: `default.inc` (standard kernel plus commonly used modules) — you don't need this command to use it.
- Make your own by copying `default.inc` as a template (it contains guide comments), saving with the `.inc` extension.
- Use it to trade space for features — e.g., drop the playfield-scrolling module when you need ROM space more than scrolling.
- If you share your BASIC code, share the includes file too, or others can't compile it. If you also use `include` commands, they must come before `includesfile`.

### inline

Syntax:

```bb
   inline 6lives.asm
```

- Like `include`, but inserts the `.asm` file **exactly where the statement appears** — useful for external asm code or inserting a minikernel into your game without copying it into your source.
- **Warning:** because the code is inserted verbatim at that spot, putting `inline` in the wrong place (such as the beginning of your program) will probably crash your game. Put it with your subroutines/after the main loop, wherever the code actually belongs.

## Hacking bB's .asm files

You are encouraged to hack the `.asm` files that ship with bB — it extends bB and is a good way to learn assembly:

- bB searches **both the current directory and the includes directory** for the `.asm` files it needs, **current directory first**. So: copy an `.asm` file from the includes directory into your project folder and modify the copy — the original stays intact and other games still compile normally.
- You can distribute modified `.asm` files with your source so others build the game exactly as you intend.
- Most-modified file: `score_graphics.asm` — define your own digits (and modify digits A–F for custom score displays; some assembly directives in the file must change too if you define A–F).
- The same trick works for includes files (`.inc`) and header files (`.h`).

## Debugging workflow

1. **Compile often.** After every small change, rebuild. The moment a new error appears, you know exactly which 1–3 lines caused it — much cheaper than writing 200 lines and debugging everything at once.
2. **Bisect changes.** If a previously-working build breaks, comment out (`rem`) or re-add your changes in halves until the guilty line is isolated. For "branch out of range" and mystery assembler errors, changing all relevant `then`s to `then goto` is a quick test.
3. **Check the generated `.asm` file.** Preprocessor/compiler errors name your BASIC line; assembler errors only name a line in `mygame.bas.asm` — open it, jump to that line, and look upward for your bB code quoted after a semicolon. The `.lst` file holds the assembler's messages; the `.sym` file shows where labels landed.
4. **When it compiles but misbehaves:** blank screen → `drawscreen` in a loop + set the four color registers every frame (see above); jitter/roll → too many cycles between drawscreens, use `set debug cycles on` to find the hot spot; sprites flash the score color → set COLUP0/COLUP1 every frame.
5. Test in an emulator, but remember emulators are forgiving about timing — real hardware (Harmony cart) shows timing problems first.

## Common mistakes

- Using `==` for comparison in `if-then` (bB uses single `=`, even though it uses `&&`/`||`).
- Writing `=>` or `=<` — the equal sign always comes second: `>=`, `<=`.
- Omitting `then` before `goto`: `if a = 5 goto label` is an error.
- Putting a space between a bit alias and its `{n}`: `_Bit0 {6}` is invalid; write `_Bit0{6}`.
- `rem` with no space after it (`rem----`) breaks the compiler.
- Long plain `then` jumps → "branch out of range"; fix with `set smartbranching on` or `then goto`. (Smartbranching can itself occasionally fail compilation — then use `then goto`. One veteran dropped smartbranching entirely after mysterious problems in a very long program, using `then goto` everywhere instead.)
- Trusting every "duplicate label" message — bogus duplicates are an assembler bug; ignore them if the build succeeds or the unresolved-symbol list is non-empty.
- Comparing or assigning values > 255 (`cmp #512` must be <$100) — everything but score is a single byte.
- Forgetting `include div_mul.asm` when using `/` or `*` math → unresolved `div8`-style symbols.
- Placing `include` after `includesfile` or `set romsize` — it gets silently ignored.
- Setting colors once outside the loop — the score steals COLUP0/COLUP1 every frame, so sprites revert to score color.
- Leaving a stale `std_kernel.asm` in the project folder so an upgraded bB still builds with the old kernel.
- Inserting `inline` file content at the start of the program — the asm runs in the wrong place and probably crashes the game.
