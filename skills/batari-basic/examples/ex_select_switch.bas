   ;***************************************************************
   ;
   ;  Select Switch Example
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain) using
   ;  hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;
   ;  There is a multicolored sprite on the screen. Pressing the
   ;  select switch changes the sprite colors. If you repeatedly
   ;  press and let go of the select switch, you can change the
   ;  colors as fast as you want. If you hold down the select
   ;  switch, there is a half second delay. That's based on
   ;  Atari's Game Standards and Procedures.
   ;  
   ;```````````````````````````````````````````````````````````````
   ;
   ;  If this program will not compile for you, get the latest
   ;  version of batari Basic:
   ;  
   ;  http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
   ;  
   ;***************************************************************


   ;***************************************************************
   ;
   ;  Provides one multicolored sprite.
   ;
   set kernel_options player1colors



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
   ;  Select switch variables.
   ;
   dim _Select_Color = w
   dim _Select_Counter = x

   ;```````````````````````````````````````````````````````````````
   ;  This bit restrains the reset switch.
   ;
   dim _Bit0_Reset_Restrainer = y





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Clears the normal 26 variables (fastest way).
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0


   ;***************************************************************
   ;
   ;  Restrains the reset switch for the main loop.
   ;
   ;  This bit fixes it so the reset switch becomes inactive if
   ;  it hasn't been released after being pressed once.
   ;
   _Bit0_Reset_Restrainer{0} = 1


   ;***************************************************************
   ;
   ;  Sets starting position of player1.
   ;
   player1x = 77 : player1y = 53


   ;***************************************************************
   ;
   ;  Defines shape of player1 sprite.
   ;
   player1:
   %00111100
   %01111110
   %11000011
   %10111101
   %11111111
   %11011011
   %01111110
   %00111100
end


   ;***************************************************************
   ;
   ;  Sets color of player1 sprite.
   ;
   player1color:
   $94
   $96
   $98
   $9A
   $9C
   $9A
   $98
   $96
end





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Select switch check.
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
   ;  Clears the select counter, but holding down the reset switch
   ;  and the select switch rapidly changes the selection. The
   ;  closer the number is to 30, the faster the change happens.
   ;
   _Select_Counter = 0 : if switchreset then _Select_Counter = 20

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the select color variable.
   ;
   _Select_Color = _Select_Color + 1 : if _Select_Color > 5 then _Select_Color = 0

   ;```````````````````````````````````````````````````````````````
   ;  Changes color of sprite.
   ;
   on _Select_Color goto __P1_00 __P1_01 __P1_02 __P1_03 __P1_04 __P1_05 

__Done_Select



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
   ;  Turns off reset restrainer bit and jumps to beginning of
   ;  main loop if the select switch is pressed.
   ;
   if switchselect then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop

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
   ;  Select switch colors.
   ;
__P1_00
   player1color:
   $94
   $96
   $98
   $9A
   $9C
   $9A
   $98
   $96
end
   goto __Done_Select


__P1_01
   player1color:
   $44
   $46
   $48
   $4A
   $4C
   $4A
   $48
   $46
end
   goto __Done_Select


__P1_02
   player1color:
   $C4
   $C6
   $C8
   $CA
   $CC
   $CA
   $C8
   $C6
end
   goto __Done_Select


__P1_03
   player1color:
   $14
   $16
   $18
   $1A
   $1C
   $1A
   $18
   $16
end
   goto __Done_Select


__P1_04
   player1color:
   $64
   $66
   $68
   $6A
   $6C
   $6A
   $68
   $66
end
   goto __Done_Select


__P1_05
   player1color:
   $04
   $06
   $08
   $0A
   $0C
   $0A
   $08
   $06
end
   goto __Done_Select