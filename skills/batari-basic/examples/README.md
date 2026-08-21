# Example programs

All `.bas` files here compile with `2600bas <file>.bas`. They are the official
Random Terrain (randomterrain.com) example programs plus a few samples from the
batari Basic repository, lightly curated. Use them as copy-paste starting points —
they are known-good syntax.

## Start here (simplest, most instructive)

| File | What it teaches |
|---|---|
| `ex_move_sprite.bas` | Canonical joystick sprite movement |
| `ex_sprite_with_missile.bas` | Fire a missile from a sprite |
| `ex_sprite_with_collision_prevention.bas` | Keep sprite on screen |
| `ex_sprite_with_missile_and_pfpixel_destruction.bas` | Shoot playfield pixels |
| `ex_pfpixel_shoot.bas` | Playfield pixel shooting, minimal |
| `ex_pulsation.bas` (mini_ex_pulsating_*) | Color cycling/pulsing |
| `mini_ex_sound_simple.bas` | Smallest sound example |
| `ex_reset.bas` | Restart game on console RESET switch |
| `ex_title_screen_and_game_over.bas` | Title + game over screens |
| `ex_save_high_score.bas` | Saving high score |
| `ex_pause.bas` | Pause via COLOR/BW switch (patched: single pfcolors block — the original's 17 pfcolors blocks crash the bB v1.9 compiler; see troubleshooting) |
| `ex_readpaddle.bas` | Paddle controller reading |
| `z_bb_ex_find_border_coordinates_all_objects.bas` | Exact on/off-screen coordinates per object |

## Complete bigger games (read for structure)

| File | What it shows |
|---|---|
| `princess_rescue_with_new_rems.bas` | Full bankswitched game |
| `zombie_chase.bas` | Full 4K game from the bB repo, fixed-point movement |
| `bbstarfield.bas` | Starfield background effect |
| `64kSC.bas` | Superchip 64K bankswitching |
| `tinkernut_world_deluxe_*.bas` | Scrolling world variants with lives/health bars |

## By topic

- **Missiles/ball**: `ex_sprite_with_missile.bas`, `z_bb_ex_sprite_with_ball.bas`, `mini_ex_enam_multi*.bas`
- **Collision**: `ex_sprite_with_collision_prevention*.bas`, `ex_dpc_collision.bas`
- **NUSIZ multi-copies**: `mini_ex_enam_multi.bas`, `ex_dpc_shooting_nusiz_copies.bas`
- **Multisprite kernel**: `ex_multisprite_9_objects.bas`, `z_bb_ex_multisprite_9_objects_and_collision.bas`
- **DPC+ kernel**: `ex_dpc_template.bas`, `ex_dpc_13_objects.bas`, `z_bb_ex_maze_dpc.bas`
- **Mazes**: `z_bb_ex_maze_32x23.bas`, `z_bb_ex_maze_32x12.bas`
- **Score**: `mini_ex_score_123456.bas`, `z_bb_mini_ex_score_individual_digits.bas`, `mini_ex_score_digit_check.bas`
- **Sound**: `mini_ex_sound_simple.bas`, `mini_ex_sound_5_sounds.bas`, `ex_sound_using_data_*.bas`, `z_bb_ex_sound_with_background.bas`
- **Sound effects library browser** (all 117 RevEng/Karl G effects, playable): `ex_sfx_library_browser.bas`
- **Lives/health bars**: `ex_pfscore_lives_health_selector.bas`, `tinkernut_world_deluxe_lives_bar.bas`, `tinkernut_world_deluxe_health_bar.bas`
- **Paddles**: `ex_readpaddle.bas`, `ex_readpaddle_with_pf_collision.bas`, `mini_ex_two_paddles.bas`
- **Bankswitching**: `ex_princess_rescue` (see above), `z_bb_ex_8x8_world_bankswitched.bas`, `z_bb_ex_16x16_world_bankswitched.bas`
- **Fixed point 8.8**: `ex_8_8_type_speed_change.bas`, `ex_fixed_point_sprite.bas`, `z_bb_ex_8.8_fixed_point_sprite.bas`
- **Numbers as graphics**: `ex_numbers_standard_kernel_with_coordinates.bas`, `ex_numbers_mini_standard_kernel.bas`

Attribution: examples by Duane Alan Hahn (Random Terrain) with contributions
from AtariAge members (batari, SeaGtGruff, RevEng, Robert M and others), and by
the batari Basic project authors. See the headers in each file.
