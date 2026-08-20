# Collision Detection and Input (batari Basic reference)

How to detect object collisions with `collision()`, and read the joystick/fire buttons, console switches, and paddle controllers. bB input and collision are **not** read like normal BASIC — no `= 1` comparisons anywhere.

**Contents:** collision() · joystick functions (joy0up…joy1fire) · SWCHA 8-way reading · fire button restrainer / rapid fire / double-click · console switches (switchreset, switchselect, switchbw, switchleftb, switchrightb) · paddles (readpaddle, currentpaddle, paddle)

## collision()

**Syntax (only valid inside an if-then):**

```
   if collision(object1,object2) then statement
   if collision(object1,object2) then goto label
   if !collision(object1,object2) then statement
```

Valid arguments are: `playfield`, `ball`, `player0`, `player1`, `missile0`, `missile1`. The two objects can be specified in **any order**, so any pair of different objects works, e.g.:

- player0 / player1
- player0 / missile0, player0 / missile1, player1 / missile0, player1 / missile1
- player0 / ball, player1 / ball
- player0 / playfield, player1 / playfield
- missile0 / missile1
- missile0 / ball, missile1 / ball
- missile0 / playfield, missile1 / playfield
- ball / playfield

**What it does:** returns true if the two objects have overlapped on screen. The detection is done by the Atari 2600 hardware (TIA collision registers) and is pixel-perfect. Pixel-perfect may or may not suit your game.

```
   if collision(playfield,player0) then a = a + 1

   if !collision(player0,missile1) then goto __Polly_Tricks
```

**WHEN collisions are valid (important):** the collision registers only get triggered while the 2600 is drawing a frame. So you must place `drawscreen` **before** the code that checks for collisions. The registers are cleared on the next `drawscreen`, so a hit is only reportable for one loop iteration — check it right after `drawscreen`, in the same pass through the loop.

Standard main-loop pattern:

```
__Main_Loop
   rem  * move objects, read joystick, etc. here
   drawscreen
   rem  * collision checks go AFTER drawscreen
   if collision(player0,playfield) then goto __Wall_Hit
   if collision(missile0,player1) then score = score + 10
   if collision(player0,ball) then goto __Got_Ball
   goto __Main_Loop
```

Gotchas:

- `collision()` may **only** be used in an if-then statement. `a = collision(...)` or using it outside `if` is invalid.
- Checking collisions before the first `drawscreen` of the loop reads last frame's (already cleared) result — a very common beginner bug is putting checks before `drawscreen`.
- Collision prevention: to keep a sprite from sticking to playfield walls, don't just bounce — undo the move that caused the collision so the sprite glides smoothly along walls. (The skill's example programs include collision-prevention versions.)

### collision() in the multisprite kernel

You can define objects player2 through player5 in the multisprite kernel, but they are **not valid arguments** to `collision()`. Player2-5 are virtual sprites — player1 redrawn at several positions during the visible screen. A collision with `player1` means you hit player1 **or one or more virtual players**; you must do further checks (for example, comparing y-positions) to find which one.

### collision() in the DPC+ kernel

DPC+ collision is pixel-perfect, but it doesn't take hardware-reflected sprites into account and doesn't support NUSIZ copies or wide players. Since bB release 1.1d, `collision()` also works between the virtual sprites (player2-player9):

```
   if !collision(player2,player9) then goto __Skip_p2_p9_Hit
   rem  * collided: react here
__Skip_p2_p9_Hit
```

- If you use NUSIZ0 to make a double/quadruple-sized player0, only player1 can collide with all of it; player2-player9 only register a collision with the first 8 bits as if player0 were still small.
- `set kernel_options collision(player1,playfield)` makes the kernel return the y-coordinate of the first player1/virtual-sprite collision with the playfield in `temp4` (after drawscreen) so you can figure out which sprite it was. The temp4 value isn't always an exact match — it can be a little less or a little more. The highest playfield collision always wins: a virtual sprite touching a playfield pixel higher on screen is the only one reported.
- With many virtual sprites, one `if collision(player0,player1)` plus coordinate checks (y-overlap then x-overlap, e.g. `(player0y + 10) >= player1y && player0y <= (player1y + 10) && ...` for 11-pixel-tall sprites) is cheaper than nine separate collision checks.

## Joystick functions: joy0up, joy0down, joy0left, joy0right, joy0fire (and joy1*)

**Syntax (true/false, use directly in if-then — never `= 1` or `= 0`):**

```
   if joy0up then ...
   if !joy0up then ...
```

| Function | True when... |
|---|---|
| `joy0up` | left joystick pushed up |
| `joy0down` | left joystick pushed down |
| `joy0left` | left joystick pushed left |
| `joy0right` | left joystick pushed right |
| `joy0fire` | left joystick's fire button is pushed |
| `joy1up` / `joy1down` / `joy1left` / `joy1right` / `joy1fire` | same, for the right joystick |

Each is true the **whole time** the stick/button is held (checked once per `drawscreen`). Joysticks and fire buttons are read like bit operations — an equal sign is not used:

```
   rem  WRONG:
  if joy0fire = 1 then ...
   if joy0fire = 0 then ...

   rem  CORRECT:
   if joy0fire then ...
   if !joy0fire then ...
```

Moving a sprite (up on screen = smaller y, left = smaller x):

```
   if joy0up then player0y = player0y - 1
   if joy0down then player0y = player0y + 1
   if joy0left then player0x = player0x - 1
   if joy0right then player0x = player0x + 1
   if joy0fire then goto __Purple_Monkey
```

**Diagonal movement:** with four separate if-then lines as above, holding up+left runs both lines in the same frame, so diagonals work automatically — you don't need (and shouldn't add) else/endif chains that block them.

**Emulator key mappings:** in Stella, joystick directions are the arrow keys and fire is left Ctrl. Use **left Ctrl**, not the space bar, as the fire button — most computer keyboards can't handle certain simultaneous key presses (key rollover), and the space bar can stop you from moving diagonally with the arrow keys.

## Advanced joystick reading with SWCHA (diagonal animation, on…goto)

The position of **both** joysticks is stored in the RIOT register `SWCHA`. When a bit in SWCHA is 0, the joystick is pushed in that direction; there is one bit each for Right, Left, Up, and Down. The four direction bits can form 16 combinations, but a joystick is mechanical and only has **9 valid positions** (center + 4 directions + 4 diagonals); the other 7 are invalid (broken stick). A good program ignores the invalid positions (some old Atari games didn't, letting players pass through walls).

To isolate one joystick's 4 bits into the low nibble:

```
   temp1 = SWCHA / 16        : rem  * joy0 (discards joy1 bits, shifts joy0 to low 4 bits)
   temp1 = SWCHA & %00001111 : rem  * joy1
```

Then dispatch with one `on…goto` or `on…gosub` instead of a long list of if-thens. The dispatch table needs an entry for each of the 16 possible nibble values (0-15): the 9 valid joystick positions get useful direction labels, and the 7 invalid combinations all point at a do-nothing label. (Direction bit layout and the finished table: see `examples/ex_advanced_joystick_reading_bare_bones.bas` — don't guess the entry order.)

Notes:

- Surprisingly, the SWCHA method is often **less** efficient in cycles and space than plain if-thens. It becomes the better choice when you do something *different* for a diagonal than for the two directions individually — for example, showing a diagonal-facing animation frame.
- 8-way animation example (sprite with animations for 8 directions, from Seaweed Assault): `examples/z_bb_mini_ex_8_way_animation.bas`.

## Fire button patterns

### Repetition restrainer (one shot per press)

Prevents rapid-fire and repeat-triggers using a single **bit** instead of wasting a whole variable. The button must be released and pressed again to trigger again. Same idea works for console switches (reset, select) and stops a title-screen/game-over button press from leaking into the game. Atari's Game Standards and Procedures: "When a game is started with the joystick button, the game should not use the same button depression for a game action (like firing a shot, for instance). The Reset switch should be debounced so it does not start another game until it is first released." (Atari's word "debounce" meant preventing repeat-while-held; "repetition restrainer" is the modern term.)

```
   if joy0fire then goto __Check_Fire
   _FireHold{0} = 0
   goto __Skip_Fire

__Check_Fire
   if _FireHold{0} then goto __Skip_Fire   : rem  * already fired on this press
   _FireHold{0} = 1
   missile0y = player0y                    : rem  * fire the missile here

__Skip_Fire
```

(`_FireHold{0}` is bit 0 of a variable; bit tests also use no equal sign: `if _FireHold{0} then ...` / `if !_FireHold{0} then ...`. Once you use bits of a variable, don't use the whole variable for anything else.)

### Variable-speed rapid fire

Fire repeats while the button is held, at a speed set by a frame counter between shots. `_FBSpeed` is 20 by default in the example; **larger numbers slow it down** (20 frames ≈ 3 shots/second at 60 fps). Full program: `examples/ex_variable_speed_rapid_fire.bas`.

```
   const _FBSpeed = 20

   if joy0fire then goto __Check_Fire
   _FB_Timer = 0
   goto __Skip_Fire

__Check_Fire
   _FB_Timer = _FB_Timer + 1
   if _FB_Timer < _FBSpeed then goto __Skip_Fire
   _FB_Timer = 0
   missile0y = player0y                    : rem  * fire the missile here

__Skip_Fire
```

### Double-click detection

Double-click the left joystick fire button to trigger an action (in the example: changes the background color). Track frames since the first press: on a fresh press, if the timer from the previous press hasn't expired yet, it's a double click; otherwise start the timer for the next press. Full program: `examples/ex_double_click.bas`.

### Two-button games (Sega Genesis controllers)

RevEng's bB technique reads the B and C buttons on a Sega Genesis-compatible controller — an extra button for, e.g., fire + jump. Genesis gamepads are inexpensive, work unmodified on a real 2600, and Stella emulates them: press Tab → Game Properties → Controller tab → set P0 Controller to Sega Genesis, then rerun. Button 1 is the normal joystick button; button 2 is tied to the BoosterGrip Booster button (default key 5 in Stella, remappable under Input Settings).

## Console switches: switchreset, switchselect, switchbw, switchleftb, switchrightb

**Syntax (read with if-then, invertible with !):**

```
   if switchreset then goto __Start_Restart
   if !switchreset then goto __Bouncing_Baboon
```

| Function | True when... |
|---|---|
| `switchreset` | Reset switch is pressed (held) |
| `switchselect` | Select switch is pressed (held) |
| `switchbw` | COLOR/BW switch is set to BW (false = COLOR) |
| `switchleftb` | left difficulty switch is B / beginner (false = A / advanced) |
| `switchrightb` | right difficulty switch is B / beginner (false = A / advanced) |

All of these are **true the entire time the switch is held/flipped that way** — there is no automatic single-trigger. For one action per press, use the bit repetition restrainer from the fire-button section (works identically). Example: the reset-switch restrainer example makes you release and press Reset again before the background color changes again.

Convention uses (per Atari's Game Standards and Procedures, consensus since around 1982):

- **Reset = start/restart the game.** A game should start when the Reset switch is pressed and/or the left fire button is pressed (player's choice).
- **Select = select game mode/variation.** In the select-switch example, pressing select cycles sprite colors: tapping repeatedly changes as fast as you want; **holding it down gives a half-second delay** between changes; holding Reset + Select simultaneously changes the selection rapidly.
- **COLOR/BW = pause** (common convention, e.g. in many games). To pause on an Atari 2600, flip the COLOR/BW switch; on an Atari 7800, press the pause button. Pause program: `examples/ex_pause.bas` — also pauses on right-controller fire; unpause by pressing and releasing the left fire button.

Warning about `switchbw`: the COLOR/BW switch starts in the same position in most emulators, but you never know its position on a real Atari. A couple of naive `if switchbw` checks can make the game **start out paused** (player must flip the switch to begin) and break on the Atari 7800. Use the pause example program's approach instead.

Difficulty switches are read-only state (A/B) — typical uses: beginner vs advanced mode, or per-player speed/size settings checked each frame.

## Paddle controllers (readpaddle)

**Standard kernel only.** Paddles do not work in the multisprite or DPC+ kernels. Before reading paddles you must set the `readpaddle` and `no_blank_lines` kernel options:

```
   set kernel_options no_blank_lines readpaddle
```

`readpaddle` **must** be used with `no_blank_lines`. The cost of `no_blank_lines` is the loss of missile0; if you add `player1colors` you also lose missile1:

```
   set kernel_options player1colors no_blank_lines readpaddle
```

Hardware: paddles come in pairs (two paddles on one plug). Paddles **0 and 1** plug into the **left** controller port; paddles **2 and 3** plug into the **right** port.

**Reading sequence:** set `currentpaddle` to the paddle you want (0-3), then call `drawscreen` — the selected paddle is read *during* drawscreen, so you can't know its value until after drawscreen finishes. Then read the `paddle` variable (in an if-then, or copy it into another variable):

```
   currentpaddle = 0
   drawscreen
   if paddle = 10 then do_something   : rem  * not very useful
   player0x = paddle                  : rem  * more useful
```

The value of `paddle` is between **0 and 77**. Convert it to a screen coordinate with a formula (adjust for direction, desired screen range, and object size). A single-width 8-pixel sprite moving across the full screen width with no wraparound can have x from 1 (farthest left) to 161 - 8 = 153 (farthest right):

```
   player0x = paddle * 2 + 1
   if player0x > 140 then player0x = 140
```

**Only one paddle is read per drawscreen.** To use two paddles, alternate `currentpaddle` each frame and process the matching paddle after drawscreen:

```
__Main_Loop
   currentpaddle = currentpaddle + 1
   if currentpaddle = 2 then currentpaddle = 0   : rem  * 1, 0, 1, 0, ...
   drawscreen

   if currentpaddle <> 0 then goto __Skip_Paddle0
   player0x = paddle * 2 + 1
   if player0x > 140 then player0x = 140
__Skip_Paddle0

   if currentpaddle <> 1 then goto __Skip_Paddle1
   player1x = paddle * 2 + 1
   if player1x > 140 then player1x = 140
__Skip_Paddle1

   goto __Main_Loop
```

Full program: `examples/ex_readpaddle.bas` (Breakout-style paddle; a playfield-collision version also exists in the source page).

**Paddle buttons:** the button on paddle 0 is read with `joy0right`, paddle 1 = `joy0left`, paddle 2 = `joy1right`, paddle 3 = `joy1left`.

**Stella setup for paddle testing:** use the latest Stella version. Tab → Input Settings → Devices & Ports tab → check "grab mouse in emulation mode" → OK. Then Game Properties → Controller tab → change both controllers to Paddles → OK → **Ctrl+R** to reload (settings don't apply until you do). For two-paddle games, change Swap Paddles from No to Yes under the Controller tab to test the other paddle (Ctrl+R after changing).

## Common mistakes

- Comparing input functions to numbers: `if joy0fire = 1 then ...` or `if switchreset = 0 then ...` — bB reads these like bits; use `if joy0fire then ...` / `if !switchreset then ...`. Same for bit variables: `if a{0} = 1` is wrong; `if a{0}` is right.
- Checking `collision()` **before** `drawscreen` — collision registers latch while the frame is being drawn and clear on the next drawscreen, so checks go after drawscreen in the main loop.
- Using `collision()` outside an if-then statement — it is only valid inside `if`.
- Expecting a switch/button press to trigger once — `switchreset`, `switchselect`, `joy0fire` etc. stay true while held; add a bit-based repetition restrainer for single-trigger actions.
- Forgetting that a game-start button press (fire or reset) also reads as a game action unless restrained — Atari standards say don't reuse the same depression for firing.
- Using paddles without `set kernel_options no_blank_lines readpaddle`, in a non-standard kernel, or reading `paddle` before `drawscreen` has run since setting `currentpaddle`.
- Assuming missile0 exists when `no_blank_lines` is on (it doesn't — that's the price of paddle reading), or missile1 with `player1colors` added.
- Pausing with bare `if switchbw` checks — the switch position is unknown on real hardware (game may start paused; breaks on Atari 7800).
- Using the space bar for fire in an emulator instead of left Ctrl — key rollover kills diagonal movement.
