   ;***************************************************************
   ;
   ;  Shoot pfpixel
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain) using
   ;  hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;***************************************************************
   ;
   ;  Instructions:
   ;  
   ;  Shoot the pfpixels using the fire button.
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
   ;  Kernel options for this program.
   ;
   set kernel_options pfcolors pfheights



   ;****************************************************************
   ;
   ;  Some multiplication operations require you to include
   ;  a module.
   ;
   include div_mul.asm



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
   ;  8.8 fixed point movement for player0 sprite.
   ;
   dim _P0_x = player0x.a

   ;```````````````````````````````````````````````````````````````
   ;  Counts the number of blocks destroyed.
   ;
   dim _Block_Count = b

   ;```````````````````````````````````````````````````````````````
   ;  Converted ball coordinates for playfield.
   ;
   dim _pf_x = c
   dim _pf_y = d

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _BitOp_All_Purpose_01 = e

   ;```````````````````````````````````````````````````````````````
   ;  Fixes it so holding it down will not make it keep resetting.
   ;
   dim _Bit0_Reset_Restrainer = e

   ;```````````````````````````````````````````````````````````````
   ;  One fire button press at a time.
   ;
   dim _Bit1_FireB_Restrainer = e

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z



   ;****************************************************************
   ;
   ;  Sets playfield heights.
   ;
   pfheights:
   8
   3
   3
   3
   3
   3
   3
   3
   3
   3
   53
end



   ;***************************************************************
   ;
   ;  Sets playfield colors.
   ;
   pfcolors:
   $00
   $44
   $46
   $48
   $1A
   $1C
   $1E
   $C6
   $C8
   $CA
   $00
end






   ;***************************************************************
   ;***************************************************************
   ;
   ;  Program Start/Restart
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
   ;  Clears 25 of the normal 26 variables (fastest way).
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0



   ;***************************************************************
   ;
   ;  Draws the blocks.
   ;
   playfield:
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
end



   ;***************************************************************
   ;
   ;  Creates shape of player0 sprite.
   ;
   player0:
   %1111111
   %1111111
   %0111110
   %0011100
end



   ;***************************************************************
   ;
   ;  Starting position of player0 sprite.
   ;
   player0x = 75 : player0y = 83



   ;***************************************************************
   ;
   ;  Makes sure missile0 is off the screen.
   ;
   missile0y = 222



   ;***************************************************************
   ;
   ;  Defines missile0 height.
   ;
   missile0height = 5



   ;***************************************************************
   ;
   ;  Sets repetition restrainer for the reset switch.
   ;  (Holding it down won't make it keep resetting.)
   ;
   _Bit0_Reset_Restrainer{0} = 1



   ;***************************************************************
   ;
   ;  Sets repetition restrainer for the fire button.
   ;
   _Bit1_FireB_Restrainer{1} = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Main Loop
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Player sprite section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite if joystick is pressed left or right.
   ;
   if joy0left then _P0_x = _P0_x - 1.500
   if joy0right then _P0_x = _P0_x + 1.500

   ;```````````````````````````````````````````````````````````````
   ;  Limits player sprite movement.
   ;
   if _P0_x < 14 then _P0_x = 14
   if _P0_x > 139 then _P0_x = 139



   ;***************************************************************
   ;
   ;  Missile0 check and fire button check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Jumps to fire button check if missile0 is off the screen.
   ;
   if missile0y > 220 then goto __FireB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 and skips fire button check.
   ;
   missile0y = missile0y - 2 : goto __Skip_FireB

__FireB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Clears the restrainer bit and skips this section if fire
   ;  button is not pressed.
   ;
   if !joy0fire then _Bit1_FireB_Restrainer{1} = 0 : goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if fire button hasn't been released since
   ;  program started.
   ;
   if _Bit1_FireB_Restrainer{1} then goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Starts the firing of missile0.
   ;
   missile0y = player0y - 2 : missile0x = player0x + 4

__Skip_FireB



   ;***************************************************************
   ;
   ;  Missile0/playfield collision check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if there is no collision.
   ;
   if !collision(playfield,missile0) then goto __Skip_miss0_to_pf_Coll

   ;```````````````````````````````````````````````````````````````
   ;  Missile0 y coordinate conversion.
   ;
   temp5 = missile0height + 3 : _pf_y = (missile0y-temp5)/3

   ;```````````````````````````````````````````````````````````````
   ;  Missile0 x coordinate conversion.
   ;
   _pf_x = (missile0x-17)/4

   ;```````````````````````````````````````````````````````````````
   ;  If a block is there, skip this subsection.
   ;
   if !pfread(_pf_x,_pf_y) then goto __Skip_miss0_to_pf_Coll

   ;```````````````````````````````````````````````````````````````
   ;  Deletes pfpixel.
   ;
   pfpixel _pf_x _pf_y off

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 off the screen.
   ;
   missile0y = 222 

   ;```````````````````````````````````````````````````````````````
   ;  Remembers how many blocks have been hit.
   ;
   _Block_Count = _Block_Count + 1

   ;```````````````````````````````````````````````````````````````
   ;  Deletes pfpixel to the left or right based on whether the 
   ;  currently deleted pfpixel was odd or even.
   ;
   if _pf_x{0} then temp4 = _pf_x - 1 : pfpixel temp4 _pf_y off : goto __Skip_miss0_to_pf_Coll

   temp4 = _pf_x + 1 : pfpixel temp4 _pf_y off  : temp4 = _pf_x

__Skip_miss0_to_pf_Coll



   ;***************************************************************
   ;
   ;  Sets color of player0 sprite.
   ;
   COLUP0 = $0C



   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0



   ;***************************************************************
   ;
   ;  Sets up size of missile0.
   ;
   NUSIZ0 = $10



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  If all blocks destroyed, get new blocks.
   ;
   if _Block_Count > 143 then goto __New_Blocks

__Return_from_Blocks



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






   ;***************************************************************
   ;***************************************************************
   ;
   ;  New blocks.
   ;
   ;
__New_Blocks

   ;```````````````````````````````````````````````````````````````
   ;  Clears the block count variable.
   ;
   _Block_Count = 0

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 off the screen.
   ;
   missile0y = 222

   ;```````````````````````````````````````````````````````````````
   ;  Draws the blocks.
   ;
   playfield:
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ................................
end

   goto __Return_from_Blocks
