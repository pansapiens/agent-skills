# Inline assembly and the machine model

Everything under batari Basic sits on the bare 6507/TIA hardware. This file
covers the verified way to drop to 6502 assembly inside a bB program, the
memory map and TIA register addresses the compiler is abstracting, the
cycle budgets that motivate bB's limits, and the canonical free tutorials
(Andrew Davie's course et al.) for going deeper.

Contents:
- When you need this
- Inline `asm` in bB (verified)
- The 6507 memory map
- Where bB puts your variables (RAM map)
- TIA register quick reference
- Cycle budget facts
- Free assembly tutorials and guides

---

## When you need this

- An effect bB cannot express: mid-line colour changes, fine (1-pixel)
  sprite/missile positioning beyond bB's player0x/player1x, timed
  scanline tricks, custom kernel overrides.
- Reading or writing other people's `.asm` include files (many bB
  libraries ship as assembly: fixed_point_math.asm, multisprite kernels).
- Understanding the generated `game.bas.asm` / `.lst` listing when
  debugging ROM layout, bankswitching, or "ran out of ROM space".

For pure-bB game logic you never need this — bB already wraps everything
below.

## Inline `asm` in bB (verified)

6502 code goes between `asm` and `end`, indented like normal bB code:

```bb
   a = 5 : b = 3
   asm
   lda a          ; bB variables ARE 6502 symbols
   clc
   adc b
   sta a          ; a is now 8 — visible to bB code after the block
end
   if a = 8 then score = score + 1
```

Verified with bB v1.9 (standard kernel, `Complete. (0)`):

- **bB variables are assembler symbols.** `a`–`z`, `temp1`–`temp6`, and
  special vars (`score`, `scorecolor`, ...) can be `lda`/`sta`d directly;
  values flow both directions across the block boundary.
- **TIA registers are symbols too** (`sta COLUBK`, `sta WSYNC`) — the
  `vcs.h` the compiler includes defines them all (table below).
- **bB labels are asm jump targets** (`jmp mainloop` inside `asm`). The
  reverse is NOT true: labels defined inside an `asm` block are invisible
  to bB `goto`/`then` (verified: "Fatal assembly error: Source is not
  resolvable") — keep asm-internal labels for asm-internal jumps only.
- `include filename.asm` splices a whole assembly file into the build.
  In bankswitched ROMs includes must appear **before `set romsize`** —
  see the bankswitching gotchas in kernels-and-memory.md.

Cautions:

- Cycles spent in `asm` blocks come out of the **same ~2700-cycle
  inter-`drawscreen` budget** as your bB code (see below). Big unrolled
  loops = screen roll, exactly like big bB loops.
- `temp1`–`temp6` are clobbered by many bB commands — if you park a
  value in one inside `asm`, expect it gone after the next `drawscreen`.
- The 6502 has no `mul`/`div`; multiplication is shifts/adds (or the
  fixed_point_math.asm include).

## The 6507 memory map

The 6507 only wires out **13 address lines**, so everything is mirrored
through the $0000–$1FFF address space (upper bits ignored — classic
$F000 vs $1000 mirroring of the reset vector):

| Range | Size | Contents |
|---|---|---|
| $0000–$002F | 48 B | **TIA registers** (read and write have *separate* maps — see below) |
| $0080–$00FF | 128 B | **All the RAM there is** (zero page) |
| $0280–$029F | 32 B | **RIOT**: I/O ports + timer |
| $1000–$1FFF | 4 KB | **Cartridge ROM** (where bB puts your program) |

Mirroring: TIA repeats every $40 bytes, RAM every $80, RIOT every $100.
This is why "128 bytes of RAM" in SKILL.md is literally the whole machine.

## Where bB puts your variables (RAM map)

From the standard kernel's `2600basic.h` (DPC+ relocates things — check
the generated `.bas.asm` symbol list when it matters):

| Symbol | Address | Notes |
|---|---|---|
| `score` | $93–$95 | 3-byte BCD |
| `scorepointers` | $96–$9B | digit graphics pointers |
| `temp1` | $9C | then temp2–temp6 follow |
| `scorecolor` | $A3 | |
| `a`–`z` | $D4–$ED | the 26 user variables |
| `pfscore1`/`pfscore2` | $F2–$F3 | lives-bar bytes (optional) |

## TIA register quick reference

Write map (`SEG TIA_REGISTERS_WRITE`, from the `vcs.h` bB includes —
authoritative for bB builds). Registers in **bold** are already exposed
to plain bB code as variables — you only need `asm` for the rest:

| Addr | Reg | Function |
|---|---|---|
| $00 | VSYNC | vertical sync set-clear |
| $01 | VBLANK | vertical blank set-clear |
| $02 | WSYNC | wait for horizontal blank (strobing halts CPU to scanline end) |
| $03 | RSYNC | reset horizontal sync counter |
| $04 | NUSIZ0 | **player/missile 0 number-size** |
| $05 | NUSIZ1 | **player/missile 1 number-size** |
| $06 | COLUP0 | **player 0 + missile 0 colour** |
| $07 | COLUP1 | **player 1 + missile 1 colour** |
| $08 | COLUPF | **playfield + ball colour** |
| $09 | COLUBK | **background colour** |
| $0A | CTRLPF | playfield control (score mode, reflection, ball size) |
| $0B | REFP0 | reflect player 0 |
| $0C | REFP1 | reflect player 1 |
| $0D | PF0 | playfield byte 0 (high nibble, reversed) |
| $0E | PF1 | playfield byte 1 |
| $0F | PF2 | playfield byte 2 (reversed) |
| $10 | RESP0 | strobe: reset player 0 position |
| $11 | RESP1 | strobe: reset player 1 position |
| $12 | RESM0 | strobe: reset missile 0 position |
| $13 | RESM1 | strobe: reset missile 1 position |
| $14 | RESBL | strobe: reset ball position |
| $15/$16 | AUDC0/AUDC1 | **audio control (waveform)** |
| $17/$18 | AUDF0/AUDF1 | **audio frequency divisor** |
| $19/$1A | AUDV0/AUDV1 | **audio volume** |
| $1B | GRP0 | player 0 graphics (bB writes via `player0:`) |
| $1C | GRP1 | player 1 graphics |
| $1D | ENAM0 | **missile 0 enable/size** |
| $1E | ENAM1 | **missile 1 enable/size** |
| $1F | ENABL | **ball enable/size** |
| $20 | HMP0 | horizontal motion player 0 (signed nibble) |
| $21 | HMP1 | horizontal motion player 1 |
| $22/$23 | HMM0/HMM1 | horizontal motion missiles |
| $24 | HMBL | horizontal motion ball |
| $25–$27 | VDELP0/P1/BL | vertical delay (framebuffer trick) |
| $28/$29 | RESMP0/RESMP1 | lock missile to player position |
| $2A | HMOVE | strobe: apply all horizontal motion |
| $2B | HMCLR | clear motion registers |
| $2C | CXCLR | strobe: clear collision latches |

Read map (separate addresses, $0000–$000F): collision latches
`CXM0P` $00, `CXP0FB` $02, `CXPPMM` $07 etc. — bB's `collision()`
function reads these; `INPT0`–`INPT4` $08–$0C are paddle/pot inputs.
RIOT at $0280: `SWCHA` $280 (joysticks — what `joy0up` etc. decode),
`SWCHB` $282 (console switches), `INTIM` $284 (timer value),
`TIM64T` $296 (set timer, 64-cycle interval).

## Cycle budget facts

The numbers behind "game logic between drawscreens: ~2700 cycles":

- CPU clock ≈ 1.19 MHz; **1 scanline = 76 cycles**.
- NTSC frame = **262 scanlines** = 19,912 cycles, at 60 Hz.
- Of those: 3 VSYNC + 37 VBLANK + **192 visible** + 30 overscan.
- `drawscreen` spends the visible + blanking period running the display
  kernel; your bB code runs in the leftover **~2700 cycles (~2 ms)**.
  That budget is why long loops roll the screen (troubleshooting.md).

`WSYNC` (strobed by the kernel every scanline) is the classic tool for
cycle-exact code: `sta WSYNC` parks the CPU until the next scanline.

## Free assembly tutorials and guides

All of these are 6502 assembly, *not* bB — the value for a bB author is
understanding the machine bB wraps (memory map, TIA timing, kernels),
plus asm snippets to lift into `asm` blocks.

- **Andrew Davie — Atari 2600 Programming for Newbies** (the classic
  25-session course, originally on AtariAge 2003–2012):
  - HTML sessions: https://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-01.html
  - Single revised PDF (Dion Olsthoorn's 2018 print edition, includes
    later corrections):
    https://cdn.hackaday.io/files/1646277043401568/Atari_2600_Programming_for_Newbies_Revised_Edition.pdf
  - Covers: TV display basics, TIA + 6502, memory architecture, first
    kernel, DASM, playfields (incl. asymmetrical), sprite horizontal/
    vertical positioning, addressing modes, timeslicing.
- **Darrell Spice Jr — Let's Make a Game!** (14 steps, a full game):
  https://www.randomterrain.com/atari-2600-lets-make-a-game-spiceware-00.html
- **Robert M lessons** (7 lessons, from first principles):
  https://www.randomterrain.com/atari-2600-memories-tutorial-robert-m-01.html
- **Nick Bensema — Guide to Cycle Counting** (6502/TIA timing made
  easy): https://www.randomterrain.com/atari-2600-memories-guide-to-cycle-counting.html
- **Nick Bensema — How to Draw A Playfield** (program flow + display
  routine walkthrough):
  https://www.randomterrain.com/atari-2600-memories-how-to-draw-a-playfield.html

All also linked from RT's index:
https://www.randomterrain.com/atari-2600-memories.html#assembly_language
