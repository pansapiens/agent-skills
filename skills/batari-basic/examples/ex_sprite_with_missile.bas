   ;***************************************************************
   ;
   ;  Sprite with Missile
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
   ;  Use the joystick to move the sprite. Press the fire button
   ;  to shoot the missile.
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
   ;  Player0/missile0 direction bits.
   ;
   dim _BitOp_P0_M0_Dir = g
   dim _Bit0_P0_Dir_Up = g
   dim _Bit1_P0_Dir_Down = g
   dim _Bit2_P0_Dir_Left = g
   dim _Bit3_P0_Dir_Right = g
   dim _Bit4_M0_Dir_Up = g
   dim _Bit5_M0_Dir_Down = g
   dim _Bit6_M0_Dir_Left = g
   dim _Bit7_M0_Dir_Right = g

   ;```````````````````````````````````````````````````````````````
   ;  Bits that do various jobs.
   ;
   dim _Bit0_Reset_Restrainer = y
   dim _Bit7_M0_Moving = y



   ;***************************************************************
   ;
   ;  Defines the edges of the playfield for an 8 x 8 sprite.
   ;  If your sprite is a different size, you`ll need to adjust
   ;  the numbers.
   ;
   const _P_Edge_Top = 9
   const _P_Edge_Bottom = 88
   const _P_Edge_Left = 1
   const _P_Edge_Right = 153



   ;***************************************************************
   ;
   ;  Defines the edges of the playfield for the missile.
   ;  If the missile is a different size, you'll need to adjust
   ;  the numbers.
   ;
   const _M_Edge_Top = 2
   const _M_Edge_Bottom = 88
   const _M_Edge_Left = 2
   const _M_Edge_Right = 159



   ;***************************************************************
   ;
   ;  Disables the score. (We don't need it in this program.)
   ;
   const noscore = 1





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
   ;  Clears all normal variables.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0


   ;***************************************************************
   ;
   ;  Sets starting position of player0.
   ;
   player0x = 77 : player0y = 53


   ;***************************************************************
   ;
   ;  Makes sure missile0 is off the screen.
   ;
   missile0x = 200 : missile0y = 200


   ;***************************************************************
   ;
   ;  Defines missile0 size.
   ;
   NUSIZ0 = $10 : missile0height = 1


   ;***************************************************************
   ;
   ;  Sets playfield color.
   ;
   COLUPF = $2C


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0


   ;***************************************************************
   ;
   ;  Sets beginning direction that missile0 will shoot if the
   ;  player doesn't move.
   ;
   _Bit3_P0_Dir_Right{3} = 1


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
   ;  Defines shape of Player0 sprite.
   ;
   player0:
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
   ;  Sets up the playfield.
   ;
   playfield:
   ................................
   ................................
   ....XXXXXXXXXX....XXXXXXXXXX....
   ....X......................X....
   ....X......................X....
   ....X......................X....
   ................................
   ................................
   ....XXXX....XXXXXXXX....XXXX....
   ................................
   ................................
end





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Sets color of player0 sprite and missile.
   ;
   COLUP0 = $9C



   ;***************************************************************
   ;
   ;  Joystick movement precheck.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips section if joystick hasn't been moved.
   ;
   if !joy0up && !joy0down && !joy0left && !joy0right then goto __Skip_Joystick_Precheck

   ;```````````````````````````````````````````````````````````````
   ;  Clears player0 direction bits since joystick has been moved.
   ;
   _BitOp_P0_M0_Dir = _BitOp_P0_M0_Dir & %11110000

__Skip_Joystick_Precheck



   ;***************************************************************
   ;
   ;  Joy0 up check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved up.
   ;
   if !joy0up then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the up direction bit.
   ;
   _Bit0_P0_Dir_Up{0} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0y <= _P_Edge_Top then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 up.
   ;
   player0y = player0y - 1

__Skip_Joy0_Up



   ;***************************************************************
   ;
   ;  Joy0 down check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved down.
   ;
   if !joy0down then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the down direction bit.
   ;
   _Bit1_P0_Dir_Down{1} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0y >= _P_Edge_Bottom then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 down.
   ;
   player0y = player0y + 1

__Skip_Joy0_Down



   ;***************************************************************
   ;
   ;  Joy0 left check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved to the left.
   ;
   if !joy0left then goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the left direction bit.
   ;
   _Bit2_P0_Dir_Left{2} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0x <= _P_Edge_Left then goto __Skip_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 to the left.
   ;
   player0x = player0x - 1

__Skip_Joy0_Left



   ;***************************************************************
   ;
   ;  Joy0 right check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick isn't moved to the right.
   ;
   if !joy0right then goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the right direction bit.
   ;
   _Bit3_P0_Dir_Right{3} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if hitting the edge.
   ;
   if player0x >= _P_Edge_Right then goto __Skip_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 to the right.
   ;
   player0x = player0x + 1

__Skip_Joy0_Right



   ;***************************************************************
   ;
   ;  Fire button check.
   ;  
   ;  Turns on missile1 movement if fire button is pressed and
   ;  missile1 is not moving.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if the fire button is not pressed.
   ;
   if !joy0fire then goto __Skip_Fire

   ;```````````````````````````````````````````````````````````````
   ;  If missile0 is moving, skip this subsection.
   ;
   if _Bit7_M0_Moving{7} then goto __Skip_Fire

   ;```````````````````````````````````````````````````````````````
   ;  Turns on missile0 movement.
   ;
   _Bit7_M0_Moving{7} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Takes a 'snapshot' of player0 direction so missile0 will
   ;  stay on track until it hits something.
   ;
   _Bit4_M0_Dir_Up{4} = _Bit0_P0_Dir_Up{0}
   _Bit5_M0_Dir_Down{5} = _Bit1_P0_Dir_Down{1}
   _Bit6_M0_Dir_Left{6} = _Bit2_P0_Dir_Left{2}
   _Bit7_M0_Dir_Right{7} = _Bit3_P0_Dir_Right{3}

   ;```````````````````````````````````````````````````````````````
   ;  Sets up starting position of missile0.
   ;
   if _Bit4_M0_Dir_Up{4} then missile0x = player0x + 4 : missile0y = player0y - 5
   if _Bit5_M0_Dir_Down{5} then missile0x = player0x + 4 : missile0y = player0y - 1
   if _Bit6_M0_Dir_Left{6} then missile0x = player0x + 2 : missile0y = player0y - 3
   if _Bit7_M0_Dir_Right{7} then missile0x = player0x + 6 : missile0y = player0y - 3

__Skip_Fire



   ;***************************************************************
   ;
   ;  Missile0 movement check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if missile0 isn't moving.
   ;
   if !_Bit7_M0_Moving{7} then goto __Skip_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 in the appropriate direction.
   ;
   if _Bit4_M0_Dir_Up{4} then missile0y = missile0y - 2
   if _Bit5_M0_Dir_Down{5} then missile0y = missile0y + 2
   if _Bit6_M0_Dir_Left{6} then missile0x = missile0x - 2
   if _Bit7_M0_Dir_Right{7} then missile0x = missile0x + 2

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile0 if it hits the edge of the screen.
   ;
   if missile0y < _M_Edge_Top then goto __Delete_Missile
   if missile0y > _M_Edge_Bottom then goto __Delete_Missile
   if missile0x < _M_Edge_Left then goto __Delete_Missile
   if missile0x > _M_Edge_Right then goto __Delete_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Skips rest of section if no collision.
   ;
   if !collision(playfield,missile0) then goto __Skip_Missile

__Delete_Missile

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile0 moving bit and moves missile0 off the screen.
   ;
   _Bit7_M0_Moving{7} = 0 : missile0x = 200 : missile0y = 200

__Skip_Missile



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