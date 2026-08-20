   ;***************************************************************
   ;
   ;  Find Border Coordinates With All Objects (Standard Kernel)
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, and GroovyBee.
   ;
   ;  Score coordinate code provided by bogax.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  All 5 standard kernel objects and a playfield pixel are on
   ;  the screen. The player0 sprite is selected by default. Move
   ;  it around to see the coordinates for the sprite in the score.
   ;  
   ;  To select another object, hold down the fire button and
   ;  press the joystick either up or down.
   ;  
   ;  To change the size of a selected object, hold down the fire
   ;  button and press left or right. Pressing right makes it
   ;  larger. Pressing left makes it smaller.
   ;  
   ;  The joystick has been restrained to make it easier for you
   ;  to select objects and to change their sizes, so you won't
   ;  be able to hold the joystick in a certain direction while
   ;  the fire button is pressed. You can keep the fire button
   ;  pressed down, but you'll need to press the joystick in a
   ;  direction and let go, press and let go, press and let go...
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
   ;  Switches between objects.
   ;
   dim _Current_Object = g

   ;```````````````````````````````````````````````````````````````
   ;  Width of player0.
   ;
   dim _Player0_Width = h

   ;```````````````````````````````````````````````````````````````
   ;  Width of player1.
   ;
   dim _Player1_Width = i

   ;```````````````````````````````````````````````````````````````
   ;  Width of missile0.
   ;
   dim _Missile0_Width = j

   ;```````````````````````````````````````````````````````````````
   ;  Width of missile1.
   ;
   dim _Missile1_Width = k

   ;```````````````````````````````````````````````````````````````
   ;  Width of ball.
   ;
   dim _Ball_Width = l

   ;```````````````````````````````````````````````````````````````
   ;  Object jiggle counter.
   ;
   dim _Jiggle_Counter = m

   ;```````````````````````````````````````````````````````````````
   ;  Playfield pixel x variable.
   ;
   dim _PF_Pixel_x = n.o

   ;```````````````````````````````````````````````````````````````
   ;  Playfield pixel y variable.
   ;
   dim _PF_Pixel_y = p.q

   ;```````````````````````````````````````````````````````````````
   ;  Remembers position of jiggled object.
   ;
   dim _Memx = r
   dim _Memy = s

   ;```````````````````````````````````````````````````````````````
   ;  Used with NUSIZ0 and NUSIZ1.
   ;
   dim _My_NUSIZ0 = t
   dim _My_NUSIZ1 = u


   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _BitOp_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit5_Activate_Jiggle = y
   dim _Bit6_Joy0_Restrainer = y

   ;```````````````````````````````````````````````````````````````
   ;  Converts 6 digit score to 3 sets of two digits.
   ;
   ;  The 100 thousands and 10 thousands digits are held by _sc1.
   ;  The thousands and hundreds digits are held by _sc2.
   ;  The tens and ones digits are held by _sc3.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Constants for the 6 objects.
   ;  [The c stands for constant.]
   ;
   const _c_Player0 = 0
   const _c_Missile0 = 1
   const _c_Player1 = 2
   const _c_Missile1 = 3
   const _c_Ball = 4
   const _c_PF_Pixel = 5



   ;***************************************************************
   ;
   ;  Default object colors.
   ;  [The c stands for constant.]
   ;
   const _c_PlayerMissile0_Color = $9C
   const _c_PlayerMissile1_Color = $38
   const _c_Ball_Color = $FC
   const _c_PF_Color = $0A





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
   player0x = 79 : player0y = 64


   ;***************************************************************
   ;
   ;  Sets starting position of missile1.
   ;
   missile0x = 83 : missile0y = player0y - 16


   ;***************************************************************
   ;
   ;  Sets starting position of player0.
   ;
   player1x = 79 : player1y = missile0y - 8


   ;***************************************************************
   ;
   ;  Sets starting position of missile1.
   ;
   missile1x = 83 : missile1y = player1y - 16


   ;***************************************************************
   ;
   ;  Sets starting position of ball.
   ;
   ballx = 83 : bally = missile1y - 16


   ;***************************************************************
   ;
   ;  Sets starting position of playfield pixel.
   ;
   _PF_Pixel_x = 16 : _PF_Pixel_y = 9


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
   ;  Defines shape of player0 sprite.
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
   ;  Defines shape of player0 sprite.
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
   ;  Turns off joystick restrainer bit and skips this section if
   ;  fire button is not pressed.
   ;
   if !joy0fire then _Bit6_Joy0_Restrainer{6} = 0 : goto __Skip_Fire_Button

   ;```````````````````````````````````````````````````````````````
   ;  Clears the joystick restrainer bit if joystick is not moved.
   ;
   if !joy0up && !joy0down && !joy0left && !joy0right then _Bit6_Joy0_Restrainer{6} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick already moved.
   ;
   if _Bit6_Joy0_Restrainer{6} then goto __Skip_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved up or down.
   ;
   if joy0up then _Bit6_Joy0_Restrainer{6} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object + 1 : if _Current_Object > 5 then _Current_Object = 0

   if joy0down then _Bit6_Joy0_Restrainer{6} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object - 1 : if _Current_Object > 200 then _Current_Object = 5

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved left.
   ;
   if !joy0left then goto __Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases size of selected object.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Player0 dec check.
   ;
   if _Current_Object > _c_Player0 then goto __Skip_P0_dec

   if _Player0_Width > 0 then _Player0_Width = _Player0_Width - 1

   if player0x = 0 && _Player0_Width = 0 then player0x = 1

__Skip_P0_dec

   ;```````````````````````````````````````````````````````````````
   ;  Missile0 dec check.
   ;
   if _Current_Object = _c_Missile0 then if _Missile0_Width > 0 then _Missile0_Width = _Missile0_Width - 1

   ;```````````````````````````````````````````````````````````````
   ;  Player1 dec check.
   ;
   if _Current_Object <> _c_Player1 then goto __Skip_P1_dec

   if _Player1_Width > 0 then _Player1_Width = _Player1_Width - 1

   if player1x = 0 && _Player1_Width = 0 then player1x = 1

__Skip_P1_dec

   ;```````````````````````````````````````````````````````````````
   ;  Missile1 dec check.
   ;
   if _Current_Object = _c_Missile1 then if _Missile1_Width > 0 then _Missile1_Width = _Missile1_Width - 1

   ;```````````````````````````````````````````````````````````````
   ;  Ball dec check.
   ;
   if _Current_Object = _c_Ball then if _Ball_Width > 0 then _Ball_Width = _Ball_Width - 1

__Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved right.
   ;
   if !joy0right then goto __Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Increases size of selected object.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Player0 inc check.
   ;
   if _Current_Object > _c_Player0 then goto __Skip_P0_inc

   if _Player0_Width < 2 then _Player0_Width = _Player0_Width + 1

   temp5 = _Data_Right_Edge[_Player0_Width]
   if player0x > temp5 then player0x = temp5 : goto __Skip_P0_inc

   if player0x = 1 then player0x = 0

__Skip_P0_inc

   ;```````````````````````````````````````````````````````````````
   ;  Missile0 inc check.
   ;
   if _Current_Object <> _c_Missile0 then goto __Skip_M0_inc

   if _Missile0_Width < 3 then _Missile0_Width = _Missile0_Width + 1

   temp5 = _Data_MB_x_Right_Edge[_Missile0_Width]
   if missile0x > temp5 then missile0x = temp5

   temp5 = _Data_MB_y_Top_Edge[_Missile0_Width]
   if missile0y < temp5 then missile0y = temp5


__Skip_M0_inc

   ;```````````````````````````````````````````````````````````````
   ;  Player1 inc check.
   ;
   if _Current_Object <> _c_Player1 then goto __Skip_P1_inc

   if _Player1_Width < 2 then _Player1_Width = _Player1_Width + 1

   temp5 = _Data_Right_Edge[_Player1_Width]
   if player1x > temp5 then player1x = temp5 : goto __Skip_P1_inc

   if player1x = 1 then player1x = 0

__Skip_P1_inc

   ;```````````````````````````````````````````````````````````````
   ;  Missile1 inc check.
   ;
   if _Current_Object <> _c_Missile1 then goto __Skip_M1_inc

   if _Missile1_Width < 3 then _Missile1_Width = _Missile1_Width + 1

   temp5 = _Data_MB_x_Right_Edge[_Missile1_Width]
   if missile1x > temp5 then missile1x = temp5

   temp5 = _Data_MB_y_Top_Edge[_Missile1_Width]
   if missile1y < temp5 then missile1y = temp5

__Skip_M1_inc

   ;```````````````````````````````````````````````````````````````
   ;  Ball inc check.
   ;
   if _Current_Object <> _c_Ball then goto __Skip_Size_Increase

   if _Ball_Width < 3 then _Ball_Width = _Ball_Width + 1

   temp5 = _Data_MB_x_Right_Edge[_Ball_Width]
   if ballx > temp5 then ballx = temp5

   temp5 = _Data_MB_y_Top_Edge[_Ball_Width]
   if bally < temp5 then bally = temp5

__Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Skips object movement (skips the whole next section).
   ;
   goto __Skip_Movement

__Skip_Fire_Button



   ;***************************************************************
   ;
   ;  Moves selected object when fire button is not pressed.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not player0.
   ;
   if _Current_Object > _c_Player0 then goto __Skip_Sprite0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if joystick is moved.
   ;
   if joy0up then if player0y > 9 then player0y = player0y - 1

   if joy0down then if player0y < 88 then player0y = player0y + 1

   temp5 = 2 : if _Player0_Width then temp5 = 1

   if joy0left then if player0x >= temp5 then player0x = player0x - 1

   if joy0right then temp5 = _Data_Right_Edge[_Player0_Width] : if player0x < temp5 then player0x = player0x + 1

   goto __Skip_Movement

__Skip_Sprite0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not missile0.
   ;
   if _Current_Object > _c_Missile0 then goto __Skip_Missile0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 if joystick is moved.
   ;
   if joy0up then temp5 = _Data_MB_y_Top_Edge[_Missile0_Width]: if missile0y > temp5 then missile0y = missile0y - 1

   if joy0down then if missile0y < 88 then missile0y = missile0y + 1

   if joy0left then if missile0x > 2 then missile0x = missile0x - 1

   if joy0right then temp5 = _Data_MB_x_Right_Edge[_Missile0_Width] : if missile0x < temp5 then missile0x = missile0x + 1

   goto __Skip_Movement

__Skip_Missile0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not player1.
   ;
   if _Current_Object > _c_Player1 then goto __Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves player1 if joystick is moved.
   ;
   if joy0up then if player1y > 9 then player1y = player1y - 1

   if joy0down then if player1y < 88 then player1y = player1y + 1

   temp5 = 2 : if _Player1_Width then temp5 = 1

   if joy0left then if player1x >= temp5 then player1x = player1x - 1

   if joy0right then temp5 = _Data_Right_Edge[_Player1_Width] : if player1x < temp5 then player1x = player1x + 1

   goto __Skip_Movement

__Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not missile1.
   ;
   if _Current_Object > _c_Missile1 then goto __Skip_Missile_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile1 if joystick is moved.
   ;
   if joy0up then temp5 = _Data_MB_y_Top_Edge[_Missile1_Width]: if missile1y > temp5 then missile1y = missile1y - 1

   if joy0down then if missile1y < 88 then missile1y = missile1y + 1

   if joy0left then if missile1x > 2 then missile1x = missile1x - 1

   if joy0right then temp5 = _Data_MB_x_Right_Edge[_Missile1_Width] : if missile1x < temp5 then missile1x = missile1x + 1

   goto __Skip_Movement

__Skip_Missile_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not the ball.
   ;
   if _Current_Object > _c_Ball then goto __Skip_Ball_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball if joystick is moved.
   ;
   if joy0up then temp5 = _Data_MB_y_Top_Edge[_Ball_Width]: if bally > temp5 then bally = bally - 1

   if joy0down then if bally < 88 then bally = bally + 1

   if joy0left then if ballx > 2 then ballx = ballx - 1

   if joy0right then temp5 = _Data_MB_x_Right_Edge[_Ball_Width]: if ballx < temp5 then ballx = ballx + 1

   goto __Skip_Movement

__Skip_Ball_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves playfield pixel if joystick is moved.
   ;
   if joy0up then if _PF_Pixel_y > 0 then _PF_Pixel_y = _PF_Pixel_y - 0.25

   if joy0down then if _PF_Pixel_y < 10 then _PF_Pixel_y = _PF_Pixel_y + 0.25

   if joy0left then if _PF_Pixel_x > 0 then _PF_Pixel_x = _PF_Pixel_x - 0.40

   if joy0right then if _PF_Pixel_x < 31 then _PF_Pixel_x = _PF_Pixel_x + 0.40

__Skip_Movement



   ;***************************************************************
   ;
   ;  Player0/missile0 width.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Prepares player0 width for NUSIZ0.
   ;
   _My_NUSIZ0 = _My_NUSIZ0 & $F0
   _My_NUSIZ0 = _My_NUSIZ0 | _Data_Player_Width[_Player0_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Prepares missile0 width for NUSIZ0.
   ;
   _My_NUSIZ0 = _My_NUSIZ0 & $0F
   _My_NUSIZ0 = _My_NUSIZ0 | _Data_MB_Width[_Missile0_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Sets player0 width and missile0 width.
   ;
   NUSIZ0 = _My_NUSIZ0

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile0 height using data.
   ;
   missile0height = _Data_MB_Height[_Missile0_Width]



   ;***************************************************************
   ;
   ;  Player1/missile1 width.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Prepares player1 width for NUSIZ1.
   ;
   _My_NUSIZ1 = _My_NUSIZ1 & $F0
   _My_NUSIZ1 = _My_NUSIZ1 | _Data_Player_Width[_Player1_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Prepares missile1 width for NUSIZ1.
   ;
   _My_NUSIZ1 = _My_NUSIZ1 & $0F
   _My_NUSIZ1 = _My_NUSIZ1 | _Data_MB_Width[_Missile1_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Sets player1 width and missile1 width.
   ;
   NUSIZ1 = _My_NUSIZ1

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile1 height using data.
   ;
   missile1height = _Data_MB_Height[_Missile1_Width]



   ;***************************************************************
   ;
   ;  Sets the width and height of the ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Puts ball width data into CTRLPF.
   ;
   CTRLPF = _Data_MB_Width[_Ball_Width] + 1

   ;```````````````````````````````````````````````````````````````
   ;  Sets ball height using data.
   ;
   ballheight = _Data_MB_Height[_Ball_Width]



   ;***************************************************************
   ;
   ;  Object jiggle check.
   ;
   ;  Activates object jiggle if new object has been selected.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if object has not been changed.
   ;
   if !_Bit5_Activate_Jiggle{5} then goto __Skip_Object_Jiggle

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if object is jiggling.
   ;
   if _Jiggle_Counter >= 1 then goto __Skip_Memory

   if _Current_Object = _c_Player0 then _Memx = player0x : _Memy = player0y

   if _Current_Object = _c_Missile0 then _Memx = missile0x : _Memy = missile0y

   if _Current_Object = _c_Player1 then _Memx = player1x : _Memy = player1y

   if _Current_Object = _c_Missile1 then _Memx = missile1x : _Memy = missile1y

   if _Current_Object = _c_Ball then _Memx = ballx : _Memy = bally

   if _Current_Object = _c_PF_Pixel then _Memx = _PF_Pixel_x : _Memy = _PF_Pixel_y

__Skip_Memory

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the object jiggle counter.
   ;
   _Jiggle_Counter = _Jiggle_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Applies jiggle to the currently selected object.
   ;
   if _Current_Object = _c_Player0 then temp5 = 255 + (rand&3) : player0x = player0x + temp5: temp5 = 255 + (rand&3) : player0y = player0y + temp5

   if _Current_Object = _c_Missile0 then temp5 = 255 + (rand&3) : missile0x = missile0x + temp5: temp5 = 255 + (rand&3) : missile0y = missile0y + temp5

   if _Current_Object = _c_Player1 then temp5 = 255 + (rand&3) : player1x = player1x + temp5: temp5 = 255 + (rand&3) : player1y = player1y + temp5

   if _Current_Object = _c_Missile1 then temp5 = 255 + (rand&3) : missile1x = missile1x + temp5: temp5 = 255 + (rand&3) : missile1y = missile1y + temp5

   if _Current_Object = _c_Ball then temp5 = 255 + (rand&3) : ballx = ballx + temp5: temp5 = 255 + (rand&3) : bally = bally + temp5

   if _Current_Object = _c_PF_Pixel then temp5 = (rand&3) : _PF_Pixel_x = _PF_Pixel_x - 1.0 :_PF_Pixel_x = _PF_Pixel_x + temp5 : temp5 = (rand&3) : _PF_Pixel_y = _PF_Pixel_y - 1.0 : _PF_Pixel_y = _PF_Pixel_y + temp5

   ;```````````````````````````````````````````````````````````````
   ;  Keeps playfield pixel from trying to leave the playfield.
   ;
   if _PF_Pixel_y > 250 then _PF_Pixel_y = 0
   if _PF_Pixel_y > 10 then _PF_Pixel_y = 10
   if _PF_Pixel_x > 250 then _PF_Pixel_x = 0
   if _PF_Pixel_x > 31 then _PF_Pixel_x = 31

   ;```````````````````````````````````````````````````````````````
   ;  Stops jiggling and restores position of the selected object
   ;  if counter limit has been reached.
   ;
   if _Jiggle_Counter <= 4 then goto __Skip_Object_Jiggle

   _Bit5_Activate_Jiggle{5} = 0 : _Jiggle_Counter = 0

   if _Current_Object = _c_Player0 then player0x = _Memx : player0y = _Memy

   if _Current_Object = _c_Missile0 then missile0x = _Memx : missile0y = _Memy

   if _Current_Object = _c_Player1 then player1x = _Memx : player1y = _Memy

   if _Current_Object = _c_Missile1 then missile1x = _Memx : missile1y = _Memy

   if _Current_Object = _c_Ball then ballx = _Memx : bally = _Memy

   if _Current_Object = _c_PF_Pixel then _PF_Pixel_x = _Memx : _PF_Pixel_y = _Memy

__Skip_Object_Jiggle



   ;***************************************************************
   ;
   ;  Sets color of player0 sprite and missile0.
   ;
   COLUP0 = _c_PlayerMissile0_Color 



   ;***************************************************************
   ;
   ;  Sets color of player1 sprite and missile1.
   ;
   COLUP1 = _c_PlayerMissile1_Color 



   ;***************************************************************
   ;
   ;  Sets playfield and ball color.
   ;
   COLUPF = _c_Ball_Color



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   if _Current_Object = _c_Player0 then temp4 = player0x : scorecolor = _c_PlayerMissile0_Color
   if _Current_Object = _c_Missile0 then temp4 = missile0x : scorecolor = _c_PlayerMissile0_Color
   if _Current_Object = _c_Player1 then temp4 = player1x : scorecolor = _c_PlayerMissile1_Color
   if _Current_Object = _c_Missile1 then temp4 = missile1x : scorecolor = _c_PlayerMissile1_Color
   if _Current_Object = _c_Ball then temp4 = ballx : scorecolor = _c_Ball_Color
   if _Current_Object = _c_PF_Pixel then temp4 = _PF_Pixel_x : scorecolor = _c_PF_Color

   _sc1 = 0 : _sc2 = _sc2 & 15
   if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc1 = _sc1 + 5 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc1 = _sc1 + 3 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc1 = _sc1 + 2 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc1 = _sc1 + 1 : temp4 = temp4 - 10
   _sc2 = (temp4 * 4 * 4) | _sc2



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the right side.
   ;   
   if _Current_Object = _c_Player0 then temp4 = player0y
   if _Current_Object = _c_Missile0 then temp4 = missile0y
   if _Current_Object = _c_Player1 then temp4 = player1y
   if _Current_Object = _c_Missile1 then temp4 = missile1y
   if _Current_Object = _c_Ball then temp4 = bally
   if _Current_Object = _c_PF_Pixel then temp4 = _PF_Pixel_y

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
   ;  Clears the screen and draws the playfield pixel.
   ;
   pfclear

   pfpixel _PF_Pixel_x _PF_Pixel_y on



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
   ;
   ;  Player0/player1 width data for use with NUSIZ0 and NUSIZ1.
   ;
   data _Data_Player_Width
   $00, $05, $07
end



   ;***************************************************************
   ;
   ;  Missile/ball width data.
   ;
   data _Data_MB_Width
   $00, $10, $20, $30
end



   ;***************************************************************
   ;
   ;  Missile/ball x right edge limit.
   ;
   data _Data_MB_x_Right_Edge
   161, 160, 158, 154
end



   ;***************************************************************
   ;
   ;  Missile/ball y size data.
   ;
   data _Data_MB_y_Top_Edge
   1, 2, 4, 7
end



   ;***************************************************************
   ;
   ;  Missile/ball height data.
   ;
   data _Data_MB_Height
   0, 1, 3, 6
end



   ;***************************************************************
   ;
   ;  Player right edge data.
   ;
   data _Data_Right_Edge
   153, 144, 128
end