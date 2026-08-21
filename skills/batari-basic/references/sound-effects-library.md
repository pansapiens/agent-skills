# batari Basic Sound Effects Library (117 effects)

Ready-to-use sound effect data for bB games: all 117 effects from
**RevEng's Sound Effects Collection** ported to bB `sdata` format by
Karl G. Source: https://www.randomterrain.com/rt-bb-sound-effects.html
(original 7800/TIA collection:
https://forums.atariage.com/topic/301293-7800-tia-sfx-library-sound2tia/ ;
bB port thread:
https://forums.atariage.com/topic/348849-revengs-sound-collection-in-bb/ ).

The complete library ships with this skill as a compilable browser
program: **`examples/ex_sfx_library_browser.bas`** (32k ROM). Compile it,
run it, browse with the joystick, and copy the data block of any effect
you like straight into your own game.

## Data format

Each effect is one `sdata` stream of 4-byte groups plus a 255 sentinel:

```bb
   ; s1  sfx_spaceinvshoot
   sdata _Sfx1=q
   8,8,24      ; AUDV0, AUDC0, AUDF0
   4           ; duration in frames
   5,8,25
   4
   ...
   255         ; end of effect
end
```

The three-value lines are AUDV/AUDC/AUDF for channel 0 (see
`sound.md` for what each register does); the single value is how many
frames (~1/60 s) to hold that sound. 255 ends the effect.

## Playing one in your game

Copy the stream (keep it in the SAME bank as this code — see
`kernels-and-memory.md`) and drive it with this reader, the same one the
browser uses:

```bb
   dim _SfxDur = b        ; your own duration variable

__PlaySfx
   sdata _Sfx1=q          ; execution passing here (re)starts the stream
   8,8,24
   4
   ...
   255
end
__SfxRead
   temp1 = sread(_Sfx1)
   if temp1 = 255 then goto __SfxDone
   AUDV0 = temp1
   AUDC0 = sread(_Sfx1)
   AUDF0 = sread(_Sfx1)
   _SfxDur = sread(_Sfx1)
__SfxWait
   drawscreen
   ; ...your game logic for this frame goes here...
   if _SfxDur = 0 then goto __SfxRead
   _SfxDur = _SfxDur - 1
   goto __SfxWait
__SfxDone
   AUDV0 = 0
```

Notes:
- All streams in one program can share the SAME pointer variable (`=q`)
  as long as only one plays at a time; each `sdata` line re-initialises
  the pointer when execution passes over it.
- Use channel 1 (`AUDV1/AUDC1/AUDF1`) in the reader to play over
  background music on channel 0.
- Several effects strung together make simple music; for real music see
  the `sdata`/`sread` music pattern in `sound.md`.

## The browser program (audition effects)

`2600bas ex_sfx_library_browser.bas` compiles in ~1 s to a 32k ROM.
Controls: joystick right/left steps through effects 0-116 (score shows
the number), fire plays it (score turns red while playing). Inputs
during playback are ignored until the effect finishes (longest is ~2 s).

Agent testing without ears: run the ROM in ALE (rename to a supported
game stem, e.g. `adventure.bin` — see `running-in-an-emulator.md`) and
read RAM — selection variable `_Sel` and the stream pointer (`q`,
variables `a`-range addresses from the build's `.sym` file) prove which
effect is selected and that playback is advancing (pointer grows 4
bytes per duration unit). Verified with ale-py 0.12.1.

## Index (all 117 effects)

Frames column = playing time at 60 fps (~frames/60 s).

| # | name | frames | bytes |
|---|------|-------:|------:|
| s0 | salvolasershot | 22 | 89 |
| s1 | spaceinvshoot | 15 | 61 |
| s2 | berzerkrobotdeath | 15 | 61 |
| s3 | echo1 | 8 | 33 |
| s4 | echo2 | 5 | 21 |
| s5 | jumpman | 5 | 21 |
| s6 | cavalry | 7 | 29 |
| s7 | alientrill1 | 5 | 21 |
| s8 | alientrill2 | 5 | 21 |
| s9 | pitfalljump | 5 | 21 |
| s10 | advpickup | 4 | 17 |
| s11 | advdrop | 4 | 17 |
| s12 | advbite | 15 | 61 |
| s13 | advdragonslain | 15 | 61 |
| s14 | bling | 16 | 65 |
| s15 | dropmedium | 16 | 65 |
| s16 | electrobump | 9 | 37 |
| s17 | explosion | 46 | 185 |
| s18 | humanoid | 35 | 141 |
| s19 | transporter | 63 | 253 |
| s20 | twinkle | 48 | 193 |
| s21 | electroswitch | 4 | 17 |
| s22 | nonobounce | 19 | 77 |
| s23 | 70stvcomputer | 61 | 245 |
| s24 | alienlife | 17 | 69 |
| s25 | chirp | 7 | 29 |
| s26 | plonk | 14 | 57 |
| s27 | spawn | 10 | 41 |
| s28 | maser | 16 | 65 |
| s29 | rubbermallet | 15 | 61 |
| s30 | alienkitty | 20 | 81 |
| s31 | electropunch | 11 | 45 |
| s32 | drip | 16 | 65 |
| s33 | ribbit | 22 | 89 |
| s34 | wolfwhistle | 67 | 269 |
| s35 | cabwhistle | 41 | 165 |
| s36 | jumpo | 34 | 137 |
| s37 | pulsecannon | 26 | 105 |
| s38 | spring | 40 | 161 |
| s39 | buzzbomb | 22 | 89 |
| s40 | bassbump | 13 | 53 |
| s41 | hophop | 26 | 105 |
| s42 | distressed | 19 | 77 |
| s43 | ouch | 25 | 101 |
| s44 | laserrecoil | 19 | 77 |
| s45 | electrosplosion | 29 | 117 |
| s46 | hophip | 23 | 93 |
| s47 | hophipquick | 15 | 61 |
| s48 | bassbump2 | 16 | 65 |
| s49 | pickupprize | 22 | 89 |
| s50 | distressed2 | 24 | 97 |
| s51 | pewpew | 20 | 81 |
| s52 | denied | 21 | 85 |
| s53 | teleported | 76 | 305 |
| s54 | alienklaxon | 66 | 265 |
| s55 | crystalchimes | 68 | 273 |
| s56 | oneup | 50 | 201 |
| s57 | babywah | 33 | 133 |
| s58 | gotthecoin | 23 | 93 |
| s59 | babyribbit | 15 | 61 |
| s60 | squeek | 27 | 109 |
| s61 | whoa | 42 | 169 |
| s62 | gotthering | 35 | 141 |
| s63 | yahoo | 49 | 197 |
| s64 | warcry | 42 | 169 |
| s65 | downthepipe | 48 | 193 |
| s66 | powerup | 53 | 213 |
| s67 | falling | 56 | 225 |
| s68 | eek | 26 | 105 |
| s69 | uhoh | 47 | 189 |
| s70 | anotherup | 49 | 197 |
| s71 | bubbleup | 40 | 161 |
| s72 | jump1 | 19 | 77 |
| s73 | plainlaser | 14 | 57 |
| s74 | aliencoo | 16 | 65 |
| s75 | simplebuzz | 18 | 73 |
| s76 | jump2 | 19 | 77 |
| s77 | jump3 | 17 | 69 |
| s78 | dunno | 22 | 89 |
| s79 | snore | 22 | 89 |
| s80 | uncovered | 34 | 137 |
| s81 | doorpound | 18 | 73 |
| s82 | distressed3 | 28 | 113 |
| s83 | eek2 | 19 | 77 |
| s84 | rubberhammer | 16 | 65 |
| s85 | alienbuzz | 29 | 117 |
| s86 | anotherjumpman | 37 | 149 |
| s87 | anotherjumpdies | 74 | 297 |
| s88 | longgongsilver | 92 | 369 |
| s89 | strum | 24 | 97 |
| s90 | dropped | 30 | 121 |
| s91 | alienaggressor | 32 | 129 |
| s92 | electroswitch2 | 12 | 49 |
| s93 | gooditem | 46 | 185 |
| s94 | babyribbithop | 13 | 53 |
| s95 | distressed4 | 27 | 109 |
| s96 | hahaha | 63 | 253 |
| s97 | yeah | 23 | 93 |
| s98 | arfarf | 26 | 105 |
| s99 | activate | 25 | 101 |
| s100 | hahaha2 | 27 | 109 |
| s101 | wilhelm | 64 | 257 |
| s102 | poof1 | 12 | 49 |
| s103 | poof2 | 12 | 49 |
| s104 | dragit | 10 | 41 |
| s105 | roarcheep | 34 | 137 |
| s106 | roarroar | 36 | 145 |
| s107 | deeproar | 70 | 281 |
| s108 | echobang | 34 | 137 |
| s109 | tom | 16 | 65 |
| s110 | clopclop | 20 | 81 |
| s111 | museboom | 61 | 245 |
| s112 | bigboom | 85 | 341 |
| s113 | thud | 11 | 45 |
| s114 | bump | 18 | 73 |
| s115 | shouty | 45 | 181 |
| s116 | quack | 12 | 49 |

## Quick picks by use
- **shoot**: s0 salvolasershot (22f), s1 spaceinvshoot (15f), s73 plainlaser (14f), s37 pulsecannon (26f), s51 pewpew (20f), s44 laserrecoil (19f)
- **explosion**: s17 explosion (46f), s45 electrosplosion (29f), s112 bigboom (85f), s111 museboom (61f), s102 poof1 (12f), s103 poof2 (12f), s108 echobang (34f)
- **jump**: s5 jumpman (5f), s72 jump1 (19f), s76 jump2 (19f), s77 jump3 (17f), s36 jumpo (34f), s41 hophop (26f), s46 hophip (23f)
- **pickup**: s58 gotthecoin (23f), s62 gotthering (35f), s49 pickupprize (22f), s10 advpickup (4f), s93 gooditem (46f), s66 powerup (53f), s56 oneup (50f), s70 anotherup (49f)
- **hurt/death**: s43 ouch (25f), s2 berzerkrobotdeath (15f), s13 advdragonslain (15f), s87 anotherjumpdies (74f), s90 dropped (30f), s113 thud (11f), s114 bump (18f)
- **ui/feedback**: s14 bling (16f), s21 electroswitch (4f), s52 denied (21f), s99 activate (25f), s80 uncovered (34f)
- **creatures**: s33 ribbit (22f), s59 babyribbit (15f), s116 quack (12f), s34 wolfwhistle (67f), s106 roarroar (36f), s107 deeproar (70f), s74 aliencoo (16f), s85 alienbuzz (29f)
- **ambient**: s67 falling (56f), s65 downthepipe (48f), s19 transporter (63f), s20 twinkle (48f), s55 crystalchimes (68f), s25 chirp (7f)
- **voice-ish**: s18 humanoid (35f), s64 warcry (42f), s96 hahaha (63f), s97 yeah (23f), s63 yahoo (49f), s69 uhoh (47f), s68 eek (26f), s83 eek2 (19f), s78 dunno (22f), s61 whoa (42f)

Effect numbers here match the `; sN` comments in the example program
and on the randomterrain page, so page-searching sN finds the same
effect everywhere.