   ;***************************************************************
   ;
   ;  SWCHA Joystick Example Using ON..GOTO
   ;
   ;  By Robert M (adapted by Duane Alan Hahn)
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  The goal of this example is to demonstrate how to use a
   ;  single bBasic ON..GOTO statement to decide which one of many
   ;  possible tasks to perform, rather than using a long list of
   ;  IF...THEN statements. The resulting bBasic code is faster,
   ;  easier to read and maintain.
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
   ;  Remembers the color of the sprite.
   ;
   dim _Sprite_Color = a

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _BitOp_All_Purpose_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit1_FireB_Restrainer = y

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z



   ;***************************************************************
   ;
   ;  These constants mark the boundary of a rectangle to restrict
   ;  movement of player0.
   ;
   const _PLAYER0_X_MIN = 1
   const _PLAYER0_X_MAX = 154
   const _PLAYER0_Y_MIN = 9
   const _PLAYER0_Y_MAX = 89





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;****************************************************************
   ;
   ;  Clears the screen.
   ;
   pfclear


   ;****************************************************************
   ;
   ;  Sets up variables, colors, and so on.
   ;
   player0x = 80 : player0y = 54 : COLUBK  =  0 : _Sprite_Color = 28


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
   ;  Restrains the fire button.
   ;
   ;  This bit fixes it so the fire button becomes inactive if
   ;  it hasn't been released after being pressed once.
   ;
   _Bit1_FireB_Restrainer{1} = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Processes the state of the joystick0 fire button.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  If button not pressed, clear restrainer bit and skip this
   ;  subsection.
   ;
   if !joy0fire then _Bit1_FireB_Restrainer{1} = 0 : goto __Done_Fire

   ;```````````````````````````````````````````````````````````````
   ;  If fire button hasn't been released, skip this subsection.
   ;
   if _Bit1_FireB_Restrainer{1} then goto __Done_Fire

   ;```````````````````````````````````````````````````````````````
   ;  Turn on fire button restrainer bit and reset counter.
   ;
   _Bit1_FireB_Restrainer{1} = 1

__Fire

   ;```````````````````````````````````````````````````````````````
   ;  Do everything you need to do if the fire button is pressed
   ;  between the labels __Fire and __Done_Fire.
   ;
   ;  For this demo we randomly color the P0 sprite.
   ;
   _Sprite_Color  =  rand | %00001100

__Done_Fire



   ;****************************************************************
   ;
   ;  Sets the sprite color.
   ;
   COLUP0  =  _Sprite_Color



   ;***************************************************************
   ;
   ;  How it works:
   ;
   ;  The position of both joysticks is stored in an IO
   ;  memory  register of the RIOT labeled SWCHA. When a
   ;  bit in SWCHA is 0, the joystick is pushed in that
   ;  direction. There is one bit for each direction Right, Left,
   ;  Up, and Down. Mechanically a joystick has only 9 valid
   ;  positions. The four joystick direction bits can form 16
   ;  combinations. Only 9 of those 16 combinations are valid
   ;  joystick positions. The other seven are invalid (broken
   ;  joystick). A good program will ignore the invalid positions.
   ;  Some Atari games do not ignore the invalid positions.  
   ;  In those games, pressing invalid combination will cause
   ;  illegal player movement such as passing through walls.  
   ;
   ;      SWCHA
   ;          RLDURLDU
   ;      bit 76543210
   ;          ||||||||
   ;          |||||||+--> 0  =  Joy1 Up 
   ;          ||||||+---> 0  =  Joy1 Down
   ;          |||||+----> 0  =  Joy1 Left
   ;          ||||+-----> 0  =  Joy1 Right
   ;          ||||
   ;          |||+------> 0  =  Joy0 Up
   ;          ||+-------> 0  =  Joy0 Down
   ;          |+--------> 0  =  Joy0 Left
   ;          +---------> 0  =  Joy0 Right
   ;
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  For this example, we want to move sprite 0 in the direction
   ;  indicated by Joy0. So we read the value in SWCHA and divide
   ;  it by 16 which discards the Joy1 bits and shifts the joy0 bits
   ;  into the lower 4 bit positons: 
   ;
   ;      temp1 
   ;          0000RLDU
   ;      bit 76543210
   ;              ||||
   ;              ||+-->  0  =  Joy0 Up 
   ;              ||+---> 0  =  Joy0 Down
   ;              |+----> 0  =  Joy0 Left
   ;              +-----> 0  =  Joy0 Right
   ;
   ;  NOTE: To get the same 4 bit value for Joy1, use this code:
   ;  temp1  =  SWCHA & %00001111
   ;
   ;  The resulting 4 bit joy0 value in temp1 can be interpreted as a
   ;  number in the  range 0 to 15 which is perfect for the ON...GOSUB
   ;  or ON...GOTO statement.
   ;
   temp1  =  SWCHA / 16



   ;***************************************************************
   ;
   ;  Use the ON...GOTO statement to jump to the routine of code for
   ;  each legal or illegal joystick position. This is a GOTO, so each
   ;  directional routine will need to end with a GOTO __Done_Joy0 to
   ;  return to the main loop.
   ;
   ;  Alternately, you can use an ON...GOSUB statement and treat the
   ;  directional code as subroutines.
   ;  
   ;   RLDU =  0000    0001    0010    0011    0100          0101        0110      0111    1000         1001       1010     1011    1100     1101   1110    1111
   on temp1 goto __Still __Still __Still __Still __Still __GoDownRight __GoUpRight __GoRight __Still __GoDownLeft __GoUpLeft __GoLeft __Still __GoDown __GoUp __Still


__Done_Joy0




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
   ;  If the reset switch is not pressed, turn off reset
   ;  restrainer bit and jump to beginning of main loop.
   ;
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  If the reset switch hasn't been released after being
   ;  pressed, jump to beginning of main loop.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Reset pressed appropriately. Restart the program.
   ;
   goto __Start_Restart





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Joystick gotos start here.
   ;
   ;
__Still
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %01111100
   %01111100
   %00111000
   %00000000
end

   goto __Done_Joy0



__GoUp
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %01111100
   %01111100
   %00101000
   %00010000
end

   if player0y > _PLAYER0_Y_MIN then player0y = player0y-1
   goto __Done_Joy0



__GoDown
   player0:
   %00000000
   %00010000
   %00101000
   %01111100
   %01111100
   %01111100
   %00111000
   %00000000
end
   if player0y < _PLAYER0_Y_MAX then player0y = player0y+1
   goto __Done_Joy0



__GoLeft
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %10111100
   %01111100
   %00111000
   %00000000
end

   if player0x > _PLAYER0_X_MIN then player0x = player0x-1
   goto __Done_Joy0



__GoRight
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %01111010
   %01111100
   %00111000
   %00000000
end

   if player0x < _PLAYER0_X_MAX then player0x = player0x+1
   goto __Done_Joy0



__GoUpLeft
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %01111100
   %00111100
   %01011000
   %00000000
end

   if player0y > _PLAYER0_Y_MIN then player0y = player0y-1
   if player0x > _PLAYER0_X_MIN then player0x = player0x-1
   goto __Done_Joy0



__GoUpRight
   player0:
   %00000000
   %00000000
   %00111000
   %01111100
   %01111100
   %01111000
   %00110100
   %00000000
end

   if player0y > _PLAYER0_Y_MIN then player0y = player0y-1
   if player0x < _PLAYER0_X_MAX then player0x = player0x+1
   goto __Done_Joy0



__GoDownLeft
   player0:
   %00000000
   %00000000
   %01011000
   %00111100
   %01111100
   %01111100
   %00111000
   %00000000
end

   if player0y < _PLAYER0_Y_MAX then player0y = player0y+1
   if player0x > _PLAYER0_X_MIN then player0x = player0x-1
   goto __Done_Joy0



__GoDownRight
   player0:
   %00000000
   %00000000
   %00110100
   %01111000
   %01111100
   %01111100
   %00111000
   %00000000
end

   if player0y < _PLAYER0_Y_MAX then player0y = player0y+1
   if player0x < _PLAYER0_X_MAX then player0x = player0x+1
   goto __Done_Joy0