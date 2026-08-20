   ;***************************************************************
   ;
   ;  DFxFRACINC Tool (DPC+)
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, and GroovyBee.
   ;
   ;  Score code provided by bogax.
   ;  Score background color asm code provided by RevEng.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions
   ;  
   ;  Press the joystick left or right to select DF6FRACINC,
   ;  DF0FRACINC, DF1FRACINC, DF2FRACINC, DF3FRACINC or
   ;  DF4FRACINC. Press the joystick up or down to increase or
   ;  decrease the selected register. Press the fire button to
   ;  slow things down when you get near a number that you'd like
   ;  to stop on. Hit reset to go back to the default settings.
   ;  Use the select switch to choose a preset selection.
   ;  
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Date created: 2013y_09m_11d_0149t
   ;
   ;  Date Updated: 2025y_01m_19d_2347t
   ;
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  If this program will not compile for you, get the latest
   ;  version of batari Basic:
   ;  
   ;  http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
   ;  
   ;***************************************************************


   ;****************************************************************
   ;
   ;  This program uses the DPC+ kernel.
   ;
   set kernel DPC+



   ;****************************************************************
   ;
   ;  Standard used in North America and most of South America.
   ;
   set tv ntsc




   goto __Start_Restart bank2




   ;***************************************************************
   ;
   ;  Sets score background color.
   ;
   asm
minikernel
   ldx #$00
   stx COLUBK
   rts
end





   bank 2
   temp1=temp1





   ;***************************************************************
   ;
   ;  Variable aliases go here (DIMs).
   ;
   ;  You can have more than one alias for each variable.
   ;  If you use different aliases for bit operations,
   ;  it's easier to understand and remember what they do.
   ;
   ;  I start variable aliases with one underscore so I won't
   ;  have to worry that I might be using bB keywords by mistake.
   ;  I also start labels with two underscores for the same
   ;  reason. The second underscore also makes labels stand out 
   ;  so I can tell at a glance that they are labels and not
   ;  variables.
   ;
   ;  Use bit operations any time you need a simple off/on
   ;  variable. One variable essentially becomes 8 smaller
   ;  variables when you use bit operations.
   ;
   ;  I start my bit aliases with "_Bit" then follow that
   ;  with the bit number from 0 to 7, then another underscore
   ;  and the name. Example: _Bit0_Reset_Restrainer 
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Switches between DFxFRACINC registers.
   ;
   dim _Current_Selection = a

   ;```````````````````````````````````````````````````````````````
   ;  DFxFRACINC register values.
   ;
   dim _Frac0 = b
   dim _Frac1 = c
   dim _Frac2 = d
   dim _Frac3 = e
   dim _Frac4 = f
   dim _Frac6 = h

   ;```````````````````````````````````````````````````````````````
   ;  Select switch preset variable.
   ;
   dim _Select_Switch = i

   ;```````````````````````````````````````````````````````````````
   ;  Select switch counter.
   ;
   dim _Select_Counter = j

   ;```````````````````````````````````````````````````````````````
   ;  Fire button counter.
   ;
   dim _FB_Counter = p

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = t
   dim _Bit1_Joy0_Restrainer = t

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Constants for DFxFRACINC.
   ;  [The c stands for constant.]
   ;
   const _c_Background_Color = 0
   const _c_Column0 = 1
   const _c_Column1 = 2
   const _c_Column2 = 3
   const _c_Column3 = 4
   const _c_Forground_Color = 5



   ;****************************************************************
   ;
   ;  NTSC colors.
   ;
   ;  Use these constants so you can quickly and easily swap them
   ;  out for PAL-60 colors. Or use this if you created a PAL-60
   ;  game and want to instantly convert the colors to NTSC (if you
   ;  were already using the PAL-60 constants).
   ;
   const _00 = $00
   const _02 = $02
   const _04 = $04
   const _06 = $06
   const _08 = $08
   const _0A = $0A
   const _0C = $0C
   const _0E = $0E
   const _10 = $10
   const _12 = $12
   const _14 = $14
   const _16 = $16
   const _18 = $18
   const _1A = $1A
   const _1C = $1C
   const _1E = $1E
   const _20 = $20
   const _22 = $22
   const _24 = $24
   const _26 = $26
   const _28 = $28
   const _2A = $2A
   const _2C = $2C
   const _2E = $2E
   const _30 = $30
   const _32 = $32
   const _34 = $34
   const _36 = $36
   const _38 = $38
   const _3A = $3A
   const _3C = $3C
   const _3E = $3E
   const _40 = $40
   const _42 = $42
   const _44 = $44
   const _46 = $46
   const _48 = $48
   const _4A = $4A
   const _4C = $4C
   const _4E = $4E
   const _50 = $50
   const _52 = $52
   const _54 = $54
   const _56 = $56
   const _58 = $58
   const _5A = $5A
   const _5C = $5C
   const _5E = $5E
   const _60 = $60
   const _62 = $62
   const _64 = $64
   const _66 = $66
   const _68 = $68
   const _6A = $6A
   const _6C = $6C
   const _6E = $6E
   const _70 = $70
   const _72 = $72
   const _74 = $74
   const _76 = $76
   const _78 = $78
   const _7A = $7A
   const _7C = $7C
   const _7E = $7E
   const _80 = $80
   const _82 = $82
   const _84 = $84
   const _86 = $86
   const _88 = $88
   const _8A = $8A
   const _8C = $8C
   const _8E = $8E
   const _90 = $90
   const _92 = $92
   const _94 = $94
   const _96 = $96
   const _98 = $98
   const _9A = $9A
   const _9C = $9C
   const _9E = $9E
   const _A0 = $A0
   const _A2 = $A2
   const _A4 = $A4
   const _A6 = $A6
   const _A8 = $A8
   const _AA = $AA
   const _AC = $AC
   const _AE = $AE
   const _B0 = $B0
   const _B2 = $B2
   const _B4 = $B4
   const _B6 = $B6
   const _B8 = $B8
   const _BA = $BA
   const _BC = $BC
   const _BE = $BE
   const _C0 = $C0
   const _C2 = $C2
   const _C4 = $C4
   const _C6 = $C6
   const _C8 = $C8
   const _CA = $CA
   const _CC = $CC
   const _CE = $CE
   const _D0 = $D0
   const _D2 = $D2
   const _D4 = $D4
   const _D6 = $D6
   const _D8 = $D8
   const _DA = $DA
   const _DC = $DC
   const _DE = $DE
   const _E0 = $E0
   const _E2 = $E2
   const _E4 = $E4
   const _E6 = $E6
   const _E8 = $E8
   const _EA = $EA
   const _EC = $EC
   const _EE = $EE
   const _F0 = $F0
   const _F2 = $F2
   const _F4 = $F4
   const _F6 = $F6
   const _F8 = $F8
   const _FA = $FA
   const _FC = $FC
   const _FE = $FE





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  Displays the screen to avoid going over 262.
   ;
   drawscreen


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Clears all normal variables.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0


   ;***************************************************************
   ;
   ;  Sets playfield.
   ;
   playfield:
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .X....X..X....X..X....X..X....X.
end


   ;***************************************************************
   ;
   ;  Sets playfield colors.
   ;
   pfcolors:
   _0E
   _0C
   _0A
   _08
   _06
   _1E
   _1C
   _1A
   _18
   _16
   _2E
   _2C
   _2A
   _28
   _26
   _3E
   _3C
   _3A
   _38
   _36
   _4E
   _4C
   _4A
   _48
   _46
   _5E
   _5C
   _5A
   _58
   _56
   _6E
   _6C
   _6A
   _68
   _66
   _7E
   _7C
   _7A
   _78
   _76
   _9E
   _9C
   _9A
   _98
   _96
   _AE
   _AC
   _AA
   _A8
   _A6
   _BE
   _BC
   _BA
   _B8
   _B6
   _CE
   _CC
   _CA
   _C8
   _C6
   _DE
   _DC
   _DA
   _D8
   _D6
   _EE
   _EC
   _EA
   _E8
   _E6
   _3E
   _3C
   _3A
   _38
   _36
   _4E
   _4C
   _4A
   _48
   _46
   _5E
   _5C
   _5A
   _58
   _56
   _6E
   _6C
   _6A
   _68
   _66
end


   ;***************************************************************
   ;
   ;  Sets background colors.
   ;
   bkcolors:
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _8E
   _80
   _82
   _84
   _86
   _88
   _8A
   _8C
   _80
end


   ;***************************************************************
   ;
   ;  Sprite colors.
   ;
   player0color:
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
   _FE
end


   ;***************************************************************
   ;
   ;  Sets color of missiles.
   ;
   COLUM0 = _FE : COLUM1 = _FE


   ;***************************************************************
   ;
   ;  Sets height of missiles.
   ;
   missile0height = 220 : missile1height = 220


   ;***************************************************************
   ;
   ;  Sets repetition restrainer for the reset switch.
   ;  (Holding it down won't make it keep resetting.)
   ;
   _Bit0_Reset_Restrainer{0} = 1


   ;***************************************************************
   ;
   ;  Sets starting values used by DFxFRACINC registers.
   ;
   _Frac0 = 128 : _Frac1 = 128 : _Frac2 = 128 : _Frac3 = 128
   _Frac4 = 255 : _Frac6 = 255


   ;***************************************************************
   ;
   ;  Sets starting value for select switch.
   ;
   _Select_Switch = 1


   ;***************************************************************
   ;
   ;  Sets default DFxFRACINC register selection.
   ;
   _Current_Selection = _c_Column0


   ;***************************************************************
   ;
   ;  Gets default sprite info, missile info, and score colors.
   ;
   goto __DF0





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Current selection.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears joystick restrainer bit and skips this section if 
   ;  joy0 not moved left or right.
   ;
   if !joy0left && !joy0right then _Bit1_Joy0_Restrainer{1} = 0 : goto __Skip_Selection

   ;```````````````````````````````````````````````````````````````
   ;  Skips all movement if joystick already moved.
   ;
   if _Bit1_Joy0_Restrainer{1} then goto __Skip_All

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the joystick repetition restrainer bit.
   ;
   _Bit1_Joy0_Restrainer{1} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Switches selection if joystick is moved left or right.
   ;
   if joy0left then _Current_Selection = _Current_Selection - 1 : if _Current_Selection = 255 then _Current_Selection = _c_Forground_Color

   if joy0right then _Current_Selection = _Current_Selection + 1 : if _Current_Selection > _c_Forground_Color then _Current_Selection = _c_Background_Color

   if _Current_Selection = _c_Background_Color then goto __DF6
   if _Current_Selection = _c_Column0 then goto __DF0
   if _Current_Selection = _c_Column1 then goto __DF1
   if _Current_Selection = _c_Column2 then goto __DF2
   if _Current_Selection = _c_Column3 then goto __DF3
   if _Current_Selection = _c_Forground_Color then goto __DF4

__Skip_Selection



   ;***************************************************************
   ;
   ;  Decreases or increases selected DFxFRACINC register.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved up or down.
   ;
   if !joy0up && !joy0down then goto __Skip_All

   ;```````````````````````````````````````````````````````````````
   ;  Skips slowdown code if fire button not pressed.
   ;
   if !joy0fire then goto __Skip_FB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Slows down size change.
   ;
   if _FB_Counter <= 9 then _FB_Counter = _FB_Counter + 1 : goto __Skip_Size_Increase

__Skip_FB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Resets the slowdown counter.
   ;
   _FB_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved down.
   ;
   if !joy0down then goto __Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Joystick moved down. Decreases size of appropriate object.
   ;
   if _Current_Selection = _c_Background_Color then _Frac6 = _Frac6 - 1
   if _Current_Selection = _c_Column0 then _Frac0 = _Frac0 - 1
   if _Current_Selection = _c_Column1 then _Frac1 = _Frac1 - 1
   if _Current_Selection = _c_Column2 then _Frac2 = _Frac2 - 1
   if _Current_Selection = _c_Column3 then _Frac3 = _Frac3 - 1
   if _Current_Selection = _c_Forground_Color then _Frac4 = _Frac4 - 1

   goto __Skip_Size_Increase

__Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved up.
   ;
   if !joy0up then goto __Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Joystick moved up. Increases size of appropriate object.
   ;
   if _Current_Selection = _c_Background_Color then _Frac6 = _Frac6 + 1
   if _Current_Selection = _c_Column0 then _Frac0 = _Frac0 + 1
   if _Current_Selection = _c_Column1 then _Frac1 = _Frac1 + 1
   if _Current_Selection = _c_Column2 then _Frac2 = _Frac2 + 1
   if _Current_Selection = _c_Column3 then _Frac3 = _Frac3 + 1
   if _Current_Selection = _c_Forground_Color then _Frac4 = _Frac4 + 1

__Skip_Size_Increase

__Skip_All



   ;***************************************************************
   ;
   ;  Select switch presets.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Sets select counter to maximum and skips this section if
   ;  the select switch is not pressed.
   ;
   if !switchselect then _Select_Counter = 30 : goto __Done_Select

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the select counter.
   ;
   _Select_Counter = _Select_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if select counter value is less than 30.
   ;
   if _Select_Counter < 30 then goto __Done_Select

   ;```````````````````````````````````````````````````````````````
   ;  Clears the select counter.
   ;
   _Select_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Increases select switch preset counter.
   ;
   _Select_Switch = _Select_Switch + 1

   ;```````````````````````````````````````````````````````````````
   ;  Limits the select switch preset counter.
   ;
   if _Select_Switch > 5 then _Select_Switch = 0

   ;```````````````````````````````````````````````````````````````
   ;  Gets preset information.
   ;
   on _Select_Switch goto __Preset255 __Preset128 __Preset64 __Preset32 __Preset16 __Preset8

__Done_Select



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the right side.
   ;
   if _Current_Selection = _c_Background_Color then temp4 = _Frac6
   if _Current_Selection = _c_Column0 then temp4 = _Frac0
   if _Current_Selection = _c_Column1 then temp4 = _Frac1
   if _Current_Selection = _c_Column2 then temp4 = _Frac2
   if _Current_Selection = _c_Column3 then temp4 = _Frac3
   if _Current_Selection = _c_Forground_Color then temp4 = _Frac4

   _sc2 = _sc2 & 240 : _sc3 = 0
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
   _sc3 = _sc3 | temp4



   ;***************************************************************
   ;
   ;  Sets DFxFRACINC registers.
   ;
   DF6FRACINC = _Frac6 ; Background colors.
   DF4FRACINC = _Frac4 ; Playfield colors.

   DF0FRACINC = _Frac0 ; Column 0.
   DF1FRACINC = _Frac1 ; Column 1.
   DF2FRACINC = _Frac2 ; Column 2.
   DF3FRACINC = _Frac3 ; Column 3.



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Reset switch check and end of main loop.
   ;
   ;  Any Atari 2600 program should restart when the reset  
   ;  switch is pressed. It is part of the usual standards
   ;  and procedures.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Turns off reset restrainer bit and jumps to beginning of
   ;  main loop if the reset switch is not pressed.
   ;
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if the reset switch hasn't
   ;  been released after being pressed.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart





   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  END OF MAIN LOOP
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Selections start here.
   ;
__DF6
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %01000000
   %10100000
   %10000000
   %11000000
   %10100000
   %10100000
   %01000000
end

   player0x = 8 : player0y = 3
   missile0x = 2 : missile1x = missile0x + 16

   scorecolors:
   $AE
   $AC
   $AA
   $AA
   $A8
   $A8
   $A6
   $A6
end

   goto __Skip_Selection


   ;***************************************************************
   ;
__DF0
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %01000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %01000000
end

   player0x = 14 : player0y = 3
   missile0x = 19 : missile1x = missile0x + 27

   scorecolors:
   $4E
   $4C
   $4A
   $4A
   $48
   $48
   $46
   $46
end

   goto __Skip_Selection


   ;***************************************************************
   ;
__DF1
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %01000000
   %01000000
   %01000000
   %01000000
   %01000000
   %01000000
   %01000000
end

   player0x = 46 : player0y = 3
   missile0x = 51 : missile1x = missile0x + 27

   scorecolors:
   $CE
   $CC
   $CA
   $CA
   $C8
   $C8
   $C6
   $C6
end

   goto __Skip_Selection


   ;***************************************************************
   ;
__DF2
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %01000000
   %10100000
   %00100000
   %01000000
   %10000000
   %10000000
   %11100000
end

   player0x = 78 : player0y = 3
   missile0x = 83 : missile1x = missile0x + 27

   scorecolors:
   $2E
   $2C
   $2A
   $2A
   $28
   $28
   $26
   $26
end

   goto __Skip_Selection


   ;***************************************************************
   ;
__DF3
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %01000000
   %10100000
   %00100000
   %01000000
   %00100000
   %10100000
   %01000000
end

   player0x = 110 : player0y = 3
   missile0x = 115 : missile1x = missile0x + 27

   scorecolors:
   $6E
   $6C
   $6A
   $6A
   $68
   $68
   $66
   $66
end

   goto __Skip_Selection


   ;***************************************************************
   ;
__DF4
   player0:
   %11000000
   %10100000
   %10100000
   %10100000
   %10100000
   %10100000
   %11000000
   %00000000
   %00000000
   %11100000
   %10000000
   %10000000
   %11000000
   %10000000
   %10000000
   %10000000
   %00000000
   %00000000
   %10100000
   %10100000
   %10100000
   %11100000
   %00100000
   %00100000
   %00100000
end

   player0x = 149 : player0y = 3
   missile0x = 143 : missile1x = missile0x + 15

   scorecolors:
   $1E
   $1C
   $1A
   $1A
   $18
   $18
   $16
   $16
end

   goto __Skip_Selection




   ;***************************************************************
   ;***************************************************************
   ;
   ;  Presets start here.
   ;
__Preset255

   _Frac0 = 255 : _Frac1 = 255 : _Frac2 = 255 : _Frac3 = 255
   _Frac4 = 255 : _Frac6 = 255

   goto __Done_Select


   ;***************************************************************
   ;
__Preset128

   _Frac0 = 128 : _Frac1 = 128 : _Frac2 = 128 : _Frac3 = 128
   _Frac4 = 255 : _Frac6 = 255

   goto __Done_Select


   ;***************************************************************
   ;
__Preset64

   _Frac0 = 64 : _Frac1 = 64 : _Frac2 = 64 : _Frac3 = 64
   _Frac4 = 128 : _Frac6 = 128

   goto __Done_Select


   ;***************************************************************
   ;
__Preset32

   _Frac0 = 32 : _Frac1 = 32 : _Frac2 = 32 : _Frac3 = 32
   _Frac4 = 64 : _Frac6 = 64

   goto __Done_Select


   ;***************************************************************
   ;
__Preset16

   _Frac0 = 16 : _Frac1 = 16 : _Frac2 = 16 : _Frac3 = 16
   _Frac4 = 32 : _Frac6 = 32

   goto __Done_Select


   ;***************************************************************
   ;
__Preset8

   _Frac0 = 8 : _Frac1 = 8 : _Frac2 = 8 : _Frac3 = 8
   _Frac4 = 16 : _Frac6 = 16

   goto __Done_Select




   bank 3
   temp1=temp1




   bank 4
   temp1=temp1




   bank 5
   temp1=temp1




   bank 6
   temp1=temp1