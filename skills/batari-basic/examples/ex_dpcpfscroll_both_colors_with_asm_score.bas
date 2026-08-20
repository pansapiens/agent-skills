   ;***************************************************************
   ;
   ;  DPC+ Example Program
   ;
   ;  Playfield/Background Color Scrolling With Score Background
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, and GroovyBee.
   ;
   ;  Score background color asm code provided by RevEng.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  Press fire button to change score background color. Hold
   ;  to change colors slowly. Quickly press and release
   ;  repeatedly to change colors faster. You can also press the
   ;  fire button while holding the joystick in any direction to
   ;  rapidly change the colors.
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
   ;  Slows fire button when held down.
   ;
   dim _Speed_Counter = a

   ;```````````````````````````````````````````````````````````````
   ;  Speed of background scroll.
   ;
   dim _Background_Scroll_Counter = b

   ;```````````````````````````````````````````````````````````````
   ;  Reset switch bit.
   ;
   dim _Bit0_Reset_Restrainer = t

   ;```````````````````````````````````````````````````````````````
   ;  Used by asm code to set score bg color.
   ;
   dim _Score_Background = y




   goto __Start_Restart bank2




   ;***************************************************************
   ;
   ;  Score background color. If you don't want the score 
   ;  background color to change during your game, use a color 
   ;  after ldx instead of a variable. Example: ldx $84
   ;
   asm
minikernel
   ldx _Score_Background
   stx COLUBK
   rts
end





   bank 2
   temp1=temp1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  Playfield data.
   ;
   playfield:
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
   XXXXXXXX................XXXXXXXX
end


   ;***************************************************************
   ;
   ;  Playfield colors.
   ;
   pfcolors:
   $0E
   $0C
   $0A
   $08
   $06
   $1E
   $1C
   $1A
   $18
   $16
   $2E
   $2C
   $2A
   $28
   $26
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
   $6E
   $6C
   $6A
   $68
   $66
   $7E
   $7C
   $7A
   $78
   $76
   $9E
   $9C
   $9A
   $98
   $96
   $AE
   $AC
   $AA
   $A8
   $A6
   $BE
   $BC
   $BA
   $B8
   $B6
   $CE
   $CC
   $CA
   $C8
   $C6
   $DE
   $DC
   $DA
   $D8
   $D6
   $EE
   $EC
   $EA
   $E8
   $E6
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
   $6E
   $6C
   $6A
   $68
   $66
   $0E
   $0C
   $0A
   $08
   $06
   $1E
   $1C
   $1A
   $18
   $16
   $2E
   $2C
   $2A
   $28
   $26
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
   $6E
   $6C
   $6A
   $68
   $66
   $7E
   $7C
   $7A
   $78
   $76
   $9E
   $9C
   $9A
   $98
   $96
   $AE
   $AC
   $AA
   $A8
   $A6
   $BE
   $BC
   $BA
   $B8
   $B6
   $CE
   $CC
   $CA
   $C8
   $C6
   $DE
   $DC
   $DA
   $D8
   $D6
   $EE
   $EC
   $EA
   $E8
   $E6
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
   $6E
   $6C
   $6A
   $68
   $66
   $0E
   $0C
   $0A
   $08
   $06
   $1E
   $1C
   $1A
   $18
   $16
   $2E
   $2C
   $2A
   $28
   $26
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
   $6E
   $6C
   $6A
   $68
   $66
   $7E
   $7C
   $7A
   $78
   $76
   $9E
   $9C
   $9A
   $98
   $96
   $0E
   $0C
   $0A
   $08
   $06
   $1E
   $1C
   $1A
   $18
   $16
   $2E
   $2C
   $2A
   $28
   $26
   $3E
   $3C
   $3A
   $38
   $36
   $4E
   $4C
   $4A
   $48
   $46
   $5E
   $5C
   $5A
   $58
   $56
end

   ;```````````````````````````````````````````````````````````````
   ;  RevEng trick to get 256 playfield colors. Read more here:
   ;
   ;  http://atariage.com/forums/topic/214909-bb-with-native-64k-cart-support-11dreveng/page-12#entry2910997
   ;
   pfscroll 255 4 4

   pfcolors:
   $54
end


   ;***************************************************************
   ;
   ;  Background color data.
   ;
   bkcolors:
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
   $04
   $02
   $02
   $02
   $02
   $02
   $04
   $04
end

   ;```````````````````````````````````````````````````````````````
   ;  RevEng trick to get 256 background colors.
   ;
   pfscroll 255 6 6

   bkcolors:
   $04
end


   ;***************************************************************
   ;
   ;  Score colors.
   ;
   scorecolors:
   $3E
   $3C
   $3A
   $3A
   $38
   $38
   $36
   $36
end


   ;***************************************************************
   ;
   ;  Clears the variable used with score background color.
   ;
   _Score_Background = 0


   ;***************************************************************
   ;
   ;  Sets the background color scroll speed counter.
   ;
   _Background_Scroll_Counter = 3


   ;***************************************************************
   ;
   ;  Sets repetition restrainer for the reset switch.
   ;  (Holding it down won't make it keep resetting.)
   ;
   _Bit0_Reset_Restrainer{0} = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Fire button section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Sets speed counter to maximum and skips this section if the
   ;  fire button is not pressed.
   ;
   if !joy0fire then _Speed_Counter = 20 : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the speed counter.
   ;
   _Speed_Counter = _Speed_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if speed counter value is less than 20.
   ;
   if _Speed_Counter < 20 then goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Clears the speed counter, but holding the joystick in any
   ;  direction while pressing the fire button rapidly changes the
   ;  color. The closer the number is to 20, the faster the change
   ;  happens.
   ;
   _Speed_Counter = 0

   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joy0_Fast_Speed

   _Speed_Counter = 13

__Skip_Joy0_Fast_Speed

   ;```````````````````````````````````````````````````````````````
   ;  Changes score background color.
   ;
   _Score_Background = _Score_Background + 2

__Skip_Joy0



   ;***************************************************************
   ;
   ;  Scrolls the foreground color.
   ;
   pfscroll 255 4 4



   ;***************************************************************
   ;
   ;  Scrolls the background color at a slower speed than the
   ;  foreground color.
   ;
   _Background_Scroll_Counter = _Background_Scroll_Counter - 1

   if !_Background_Scroll_Counter then _Background_Scroll_Counter = 3 : pfscroll 255 6 6



   ;***************************************************************
   ;
   ;  Sets DFxFRACINC registers.
   ;
   DF6FRACINC = 255 ; Background colors.
   DF4FRACINC = 255 ; Playfield colors.

   DF0FRACINC = 128 ; Column 0.
   DF1FRACINC = 128 ; Column 1.
   DF2FRACINC = 128 ; Column 2.
   DF3FRACINC = 128 ; Column 3.



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





   bank 3
   temp1=temp1




   bank 4
   temp1=temp1




   bank 5
   temp1=temp1




   bank 6
   temp1=temp1