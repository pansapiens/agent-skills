   ;***************************************************************
   ;
   ;  Easy Way to Set Player Graphic to Number Mixed With
   ;  Multisprite: 9 Objects With Coordinates
   ;
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, and GroovyBee.
   ;
   ;  Score coordinate code provided by bogax.
   ;  Easy Way to Set Player Graphic to Number code by Karl G.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions
   ;  
   ;  There are 6 sprites (player0 at the top, down to player5 at
   ;  the bottom), 2 missiles (missile0 above missile1) and 1 ball
   ;  on the screen. Hold down the fire button and press the
   ;  joystick up or down to select an object. Hold down the fire
   ;  button and move the joystick left or right to change the size
   ;  of the currently selected object.
   ;  
   ;  To move the currently selected object, release the fire
   ;  button and press the joystick in any direction.
   ;
   ;  Double click the fire button to change the number.
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
   ;  Kernel setup.
   ;
   includesfile multisprite_bankswitch.inc
   set kernel multisprite
   set romsize 16k



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
   ;  Switches between sprites, missiles, and the ball.
   ;
   dim _Current_Object = a

   ;```````````````````````````````````````````````````````````````
   ;  Width of sprites.
   ;
   dim _Sprite_Size0 = b
   dim _Sprite_Size1 = c
   dim _Sprite_Size2 = d
   dim _Sprite_Size3 = e
   dim _Sprite_Size4 = f
   dim _Sprite_Size5 = g

   ;```````````````````````````````````````````````````````````````
   ;  Width of missiles.
   ;
   dim _Missile0_Width = h
   dim _Missile1_Width = i

   ;```````````````````````````````````````````````````````````````
   ;  Width of ball.
   ;
   dim _Ball_Width = j

   ;```````````````````````````````````````````````````````````````
   ;  Object jiggle counter.
   ;
   dim _Jiggle_Counter = k

   ;```````````````````````````````````````````````````````````````
   ;  Remembers NUSIZ0.
   ;
   dim _P0_NUSIZ = l

   ;```````````````````````````````````````````````````````````````
   ;  Timer for double click.
   ;
   dim _Timer = m

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber1 = n

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber2 = o

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber3 = p

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber4 = q

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber5 = r

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = w
   dim _Bit1_1st_Click = w
   dim _Bit2_2nd_Click = w
   dim _Bit3_Finish_Double_Click = w
   dim _Bit4_Joy0_Restrainer = w
   dim _Bit5_Activate_Jiggle = w
   dim _Bit6_Flip_p0 = w
   dim _Bit7_FireB_Restrainer = w

   ;```````````````````````````````````````````````````````````````
   ;  Remembers position of jiggled object.
   ;
   dim _Memx = x
   dim _Memy = y

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Constants for the 9 objects.
   ;
   const _Sprite0 = 0
   const _Sprite1 = 1
   const _Sprite2 = 2
   const _Sprite3 = 3
   const _Sprite4 = 4
   const _Sprite5 = 5
   const _Missile0 = 6
   const _Missile1 = 7
   const _Ball = 8



   ;***************************************************************
   ;
   ;  Constants for number graphics.
   ;  [The c stands for constant.]
   ;
   const _c_score_table_high = >scoretable
   const _c_score_table_low = <scoretable



   ;***************************************************************
   ;
   ;  Double click speed (how much time you have between clicks).
   ;  [The c stands for constant.]
   ;
   const _c_Double_Click_Speed = 15





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
   ;  Sprite0 shape.
   ;
   player0:
   %00001111
   %00000110
   %11111111
   %00111110
   %11111111
   %00000110
   %00001111
end


   ;***************************************************************
   ;
   ;  Object placement.
   ;
   player0x = 77 : player0y = 88
   player1x = 85 : player1y = player0y - 18
   player2x = 85 : player2y = player1y - 15
   player3x = 85 : player3y = player2y - 15
   player4x = 85 : player4y = player3y - 15
   player5x = 85 : player5y = player4y - 15
   missile0x = 98 : missile0y = 78
   missile1x = 98 : missile1y = missile0y - 15
   ballx = 98 : bally = missile1y - 15


   ;***************************************************************
   ;
   ;  Makes all sprites face the same way.
   ;
   _NUSIZ1{3} = 0 : NUSIZ2{3} = 0 : NUSIZ3{3} = 0
   NUSIZ4{3} = 0 : NUSIZ5{3} = 0


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Clears 25 of the normal 26 variables.
   ;  The variable z is used for random numbers in this program
   ;  and clearing it would mess up those random numbers.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0


   ;***************************************************************
   ;
   ;  Sets repetition restrainer for the reset switch.
   ;  (Holding it down won't make it keep resetting.)
   ;
   _Bit0_Reset_Restrainer{0} = 1


   ;***************************************************************
   ;
   ;  Sets starting width for missiles and ball.
   ;
   _Missile0_Width = 0 : _Missile1_Width = 0 : _Ball_Width = 0


   ;***************************************************************
   ;
   ;  Defines heights of player1 through player5 sprites.
   ;
   for temp6 = 0 to 4
   player1height[temp6] = 9
   next


   ;***************************************************************
   ;
   ;  Grabs number graphic for virtual sprites.
   ;
   for temp6 = 0 to 4
   temp5 = temp6
   player1pointerhi[temp6] = _c_score_table_high
   temp5 = (temp5 * 8)
   player1pointerlo[temp6] = temp5 + _c_score_table_low
   next


   ;***************************************************************
   ;
   ;  Starting number for virtual sprites.
   ;
   _DisplayNumber1 = 0 : _DisplayNumber2 = 1 : _DisplayNumber3 = 2 : _DisplayNumber4 = 3 : _DisplayNumber5 = 4


   ;***************************************************************
   ;
   ;  Turns off double click timer (200 = off).
   ;
   _Timer = 200





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Sets colors.
   ;
   COLUP0 = $08 : COLUP1 = $BA : _COLUP1 = $1A : COLUP2 = $3A : COLUP3 = $6A

   COLUP4 = $8A : COLUP5 = $CA : COLUBK= 0 : COLUPF = $4A



   ;***************************************************************
   ;
   ;  Fire button section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Turns off joystick repetition restrainer bit and skips this
   ;  section if button is not pressed.
   ;
   if !joy0fire then _Bit7_FireB_Restrainer{7} = 0 : _Bit4_Joy0_Restrainer{4} = 0 : goto __Skip_Fire_Button

   ;```````````````````````````````````````````````````````````````
   ;  Turns off joystick repetition restrainer bit if joystick not
   ;  moved.
   ;
   if !joy0up && !joy0down && !joy0left && !joy0right then _Bit4_Joy0_Restrainer{4} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Turns on fire button restrainer bit if new selection.
   ;
   _Bit7_FireB_Restrainer{7} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips everything if joystick already moved.
   ;
   if _Bit4_Joy0_Restrainer{4} then goto __Skip_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved up.
   ;
   if !joy0up then goto __Skip_Joy0U_Object_Switch

   _Bit4_Joy0_Restrainer{4} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object - 1

   if _Current_Object >= 250 then _Current_Object = 8

__Skip_Joy0U_Object_Switch

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved down.
   ;
   if !joy0down then goto __Skip_Joy0D_Object_Switch

   _Bit4_Joy0_Restrainer{4} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object + 1

   if _Current_Object >= 9 then _Current_Object = 0

__Skip_Joy0D_Object_Switch

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved left.
   ;
   if !joy0left then goto __Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick repetition restrainer bit.
   ;
   _Bit4_Joy0_Restrainer{4} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases size of appropriate object.
   ;
   if _Current_Object = _Sprite0 then _Sprite_Size0 = _Sprite_Size0 - 1 : if _Sprite_Size0 >= 250 then _Sprite_Size0 = 2
   if _Current_Object = _Sprite1 then _Sprite_Size1 = _Sprite_Size1 - 1 : if _Sprite_Size1 >= 250 then _Sprite_Size1 = 2
   if _Current_Object = _Sprite2 then _Sprite_Size2 = _Sprite_Size2 - 1 : if _Sprite_Size2 >= 250 then _Sprite_Size2 = 2
   if _Current_Object = _Sprite3 then _Sprite_Size3 = _Sprite_Size3 - 1 : if _Sprite_Size3 >= 250 then _Sprite_Size3 = 2
   if _Current_Object = _Sprite4 then _Sprite_Size4 = _Sprite_Size4 - 1 : if _Sprite_Size4 >= 250 then _Sprite_Size4 = 2
   if _Current_Object = _Sprite5 then _Sprite_Size5 = _Sprite_Size5 - 1 : if _Sprite_Size5 >= 250 then _Sprite_Size5 = 2
   if _Current_Object = _Missile0 then _Missile0_Width = _Missile0_Width - 1 : if _Missile0_Width = 255 then _Missile0_Width = 3
   if _Current_Object = _Missile1 then _Missile1_Width = _Missile1_Width - 1 : if _Missile1_Width = 255 then _Missile1_Width = 3
   if _Current_Object = _Ball then _Ball_Width = _Ball_Width - 1 : if _Ball_Width = 255 then _Ball_Width = 3

   goto __Skip_Size_Increase

__Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved right.
   ;
   if !joy0right then goto __Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick repetition restrainer bit.
   ;
   _Bit4_Joy0_Restrainer{4} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Increases size of appropriate object.
   ;
   if _Current_Object = _Sprite0 then _Sprite_Size0 = _Sprite_Size0 + 1 : if _Sprite_Size0 >= 3 then _Sprite_Size0 = 0
   if _Current_Object = _Sprite1 then _Sprite_Size1 = _Sprite_Size1 + 1 : if _Sprite_Size1 >= 3 then _Sprite_Size1 = 0
   if _Current_Object = _Sprite2 then _Sprite_Size2 = _Sprite_Size2 + 1 : if _Sprite_Size2 >= 3 then _Sprite_Size2 = 0
   if _Current_Object = _Sprite3 then _Sprite_Size3 = _Sprite_Size3 + 1 : if _Sprite_Size3 >= 3 then _Sprite_Size3 = 0
   if _Current_Object = _Sprite4 then _Sprite_Size4 = _Sprite_Size4 + 1 : if _Sprite_Size4 >= 3 then _Sprite_Size4 = 0
   if _Current_Object = _Sprite5 then _Sprite_Size5 = _Sprite_Size5 + 1 : if _Sprite_Size5 >= 3 then _Sprite_Size5 = 0
   if _Current_Object = _Missile0 then _Missile0_Width = _Missile0_Width + 1 : if _Missile0_Width >= 4 then _Missile0_Width = 0
   if _Current_Object = _Missile1 then _Missile1_Width = _Missile1_Width + 1 : if _Missile1_Width >= 4 then _Missile1_Width = 0
   if _Current_Object = _Ball then _Ball_Width = _Ball_Width + 1 : if _Ball_Width >= 4 then _Ball_Width = 0

__Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Skips object movement section.
   ;
   goto __Skip_Movement

__Skip_Fire_Button



   ;***************************************************************
   ;
   ;  Moves selected object when fire button is not pressed.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite0.
   ;
   if _Current_Object > _Sprite0 then goto __Skip_Sprite0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite0 if joystick is moved.
   ;
   if joy0up then if player0y <= 89 then player0y = player0y + 1

   if joy0down then if player0y >= 2 + player0height then player0y = player0y - 1

   if joy0left then if player0x >= 1 then player0x = player0x - 1 : _Bit6_Flip_p0{6} = 0

   if joy0right then temp5 = _Data_Sprite0_Width[_Sprite_Size0] : if player0x <= temp5 then player0x = player0x + 1 : _Bit6_Flip_p0{6} = 1

   goto __Skip_Movement

__Skip_Sprite0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite1.
   ;
   if _Current_Object > _Sprite1 then goto __Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite1 if joystick is moved.
   ;
   if joy0up then if player1y <= 83 then player1y = player1y + 1

   if joy0down then if player1y >= player1height then player1y = player1y - 1

   if joy0left then if player1x >= 9 then player1x = player1x - 1 : _NUSIZ1{3} = 0 : _NUSIZ1{6} = 0

   if joy0right then temp5 = _Data_1to5_Width[_Sprite_Size1] : if player1x <= temp5 then player1x = player1x + 1 : _NUSIZ1{3} = 1 : _NUSIZ1{6} = 1

   goto __Skip_Movement

__Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite2.
   ;
   if _Current_Object > _Sprite2 then goto __Skip_Sprite2_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite2 if joystick is moved.
   ;
   if joy0up then if player2y <= 83 then player2y = player2y + 1

   if joy0down then if player2y >= player2height then player2y = player2y - 1

   if joy0left then if player2x >= 9 then player2x = player2x - 1 : NUSIZ2{3} = 0 : NUSIZ2{6} = 0

   if joy0right then temp5 = _Data_1to5_Width[_Sprite_Size2] : if player2x <= temp5 then player2x = player2x + 1 : NUSIZ2{3} = 1 : NUSIZ2{6} = 1

   goto __Skip_Movement

__Skip_Sprite2_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite3.
   ;
   if _Current_Object > _Sprite3 then goto __Skip_Sprite3_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite3 if joystick is moved.
   ;
   if joy0up then if player3y <= 83 then player3y = player3y + 1

   if joy0down then if player3y >= player3height then player3y = player3y - 1

   if joy0left then if player3x >= 9 then player3x = player3x - 1 : NUSIZ3{3} = 0 : NUSIZ3{6} = 0

   if joy0right then temp5 = _Data_1to5_Width[_Sprite_Size3] : if player3x <= temp5 then player3x = player3x + 1 : NUSIZ3{3} = 1 : NUSIZ3{6} = 1

   goto __Skip_Movement

__Skip_Sprite3_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite4.
   ;
   if _Current_Object > _Sprite4 then goto __Skip_Sprite4_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite4 if joystick is moved.
   ;
   if joy0up then if player4y <= 83 then player4y = player4y + 1

   if joy0down then if player4y >= player4height then player4y = player4y - 1

   if joy0left then if player4x >= 9 then player4x = player4x - 1 : NUSIZ4{3} = 0 : NUSIZ4{6} = 0

   if joy0right then temp5 = _Data_1to5_Width[_Sprite_Size4] : if player4x <= temp5 then player4x = player4x + 1 : NUSIZ4{3} = 1 : NUSIZ4{6} = 1

   goto __Skip_Movement

__Skip_Sprite4_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite5.
   ;
   if _Current_Object > _Sprite5 then goto __Skip_Sprite5_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite5 if joystick is moved.
   ;
   if joy0up then if player5y <= 83 then player5y = player5y + 1

   if joy0down then if player5y >= player5height then player5y = player5y - 1

   if joy0left then if player5x >= 9 then player5x = player5x - 1 : NUSIZ5{3} = 0 : NUSIZ5{6} = 0

   if joy0right then temp5 = _Data_1to5_Width[_Sprite_Size5] : if player5x <= temp5 then player5x = player5x + 1 : NUSIZ5{3} = 1 : NUSIZ5{6} = 1

   goto __Skip_Movement

__Skip_Sprite5_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not missile0.
   ;
   if _Current_Object <> _Missile0 then goto __Skip_Missile0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 if joystick is moved.
   ;
   if joy0up then if missile0y <= 87 then missile0y = missile0y + 1

   if joy0down then if missile0y >= 3 then missile0y = missile0y - 1

   if joy0left then if missile0x >= 2 then missile0x = missile0x - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Missile0_Width] : if missile0x <= temp5 then missile0x = missile0x + 1

   goto __Skip_Movement

__Skip_Missile0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not missile1.
   ;
   if _Current_Object <> _Missile1 then goto __Skip_Missile1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile1 if joystick is moved.
   ;
   if joy0up then if missile1y <= 87 then missile1y = missile1y + 1
   
   if joy0down then if missile1y >= 3 then missile1y = missile1y - 1

   if joy0left then if missile1x >= 2 then missile1x = missile1x - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Missile1_Width] : if missile1x <= temp5 then missile1x = missile1x + 1

   goto __Skip_Movement

__Skip_Missile1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not the ball.
   ;
   if _Current_Object <> _Ball then goto __Skip_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball if joystick is moved.
   ;
   if joy0up then if bally <= 87 then bally = bally + 1

   if joy0down then if bally >= 3 then bally = bally - 1

   if joy0left then if ballx >= 2 then ballx = ballx - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Ball_Width]: if ballx <= temp5 then ballx = ballx + 1

__Skip_Movement



   goto __Bank_2 bank2





   ;***************************************************************
   ;
   ;  Missile/ball x size data.
   ;
   data _Data_M_B_x_Size
   158, 157, 155, 151
end



   ;***************************************************************
   ;
   ;  Sprite width data.
   ;
   data _Data_Sprite0_Width
   150, 141, 125
end


   ;***************************************************************
   ;
   ;  Sprite width data.
   ;
   data _Data_1to5_Width
   158, 150, 134
end



   bank 2



__Bank_2


   ;****************************************************************
   ;
   ;  Flips player0 sprite when necessary.
   ;
   if _Bit6_Flip_p0{6} then REFP0 = 8



   ;***************************************************************
   ;
   ;  Sets the size of all sprites.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears sprite0 width, but leaves the missile0 stuff alone.
   ;
   _P0_NUSIZ = _P0_NUSIZ & %11111000

   ;```````````````````````````````````````````````````````````````
   ;  Sets sprite0 width from data.
   ;
   _P0_NUSIZ = _P0_NUSIZ | _Data_Sprite_Size[_Sprite_Size0]

   ;```````````````````````````````````````````````````````````````
   ;  Puts sprite0 data into NUSIZ0.
   ;
   NUSIZ0 = _P0_NUSIZ

   ;```````````````````````````````````````````````````````````````
   ;  Clears sprite widths, but leaves the missile1 stuff alone,
   ;  then sets sprite widths.
   ;
   _NUSIZ1 = _NUSIZ1 & %11111000 : _NUSIZ1 = _NUSIZ1 | _Data_Sprite_Size[_Sprite_Size1]
   NUSIZ2 = NUSIZ2 & %11111000 : NUSIZ2 = NUSIZ2 | _Data_Sprite_Size[_Sprite_Size2]
   NUSIZ3 = NUSIZ3 & %11111000 : NUSIZ3 = NUSIZ3 | _Data_Sprite_Size[_Sprite_Size3]
   NUSIZ4 = NUSIZ4 & %11111000 : NUSIZ4 = NUSIZ4 | _Data_Sprite_Size[_Sprite_Size4]
   NUSIZ5 = NUSIZ5 & %11111000 : NUSIZ5 = NUSIZ5 | _Data_Sprite_Size[_Sprite_Size5]



   ;****************************************************************
   ;
   ;  Sets the width of missile0.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears missile0 width, but leaves the sprite stuff alone.
   ;
   _P0_NUSIZ = _P0_NUSIZ & %11001111

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile0 width from data.
   ;
   _P0_NUSIZ = _P0_NUSIZ | _Data_MB_Width[_Missile0_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Puts data into NUSIZ0.
   ;
   NUSIZ0 = _P0_NUSIZ



   ;***************************************************************
   ;
   ;  Sets the width of missile1.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Gets the correct missile1 width from data.
   ;
   temp5 = _Data_MB_Width[_Missile1_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile1 width, but leaves the sprite stuff alone,
   ;  then sets missile1 width.
   ;
   NUSIZ1 = NUSIZ1 & %11001111 : NUSIZ1 = NUSIZ1 | temp5
   _NUSIZ1 = _NUSIZ1 & %11001111 : _NUSIZ1 = _NUSIZ1 | temp5
   NUSIZ2 = NUSIZ2 & %11001111 : NUSIZ2 = NUSIZ2 | temp5
   NUSIZ3 = NUSIZ3 & %11001111 : NUSIZ3 = NUSIZ3 | temp5
   NUSIZ4 = NUSIZ4 & %11001111 : NUSIZ4 = NUSIZ4 | temp5
   NUSIZ5 = NUSIZ5 & %11001111 : NUSIZ5 = NUSIZ5 | temp5



   ;***************************************************************
   ;
   ;  Sets the width of the ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Puts ball width data into CTRLPF.
   ;
   CTRLPF = _Data_MB_Width[_Ball_Width] + 1



   ;***************************************************************
   ;
   ;  Object jiggle check.
   ;
   ;  Activates object jiggle if new object has been selected.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skip this section if object has not been changed.
   ;
   if !_Bit5_Activate_Jiggle{5} then goto __Skip_Object_Jiggle

   ;```````````````````````````````````````````````````````````````
   ;  Clears double click bits and turns off timer.
   ;
   _Timer = 200 : _Bit1_1st_Click{1} = 0 : _Bit2_2nd_Click{2} = 0 : _Bit3_Finish_Double_Click{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if object is jiggling.
   ;
   if _Jiggle_Counter >= 1 then goto __Skip_Memory
   if _Current_Object = _Sprite0 then  _Memx = player0x : _Memy = player0y
   if _Current_Object = _Sprite1 then  _Memx = player1x : _Memy = player1y
   if _Current_Object = _Sprite2 then  _Memx = player2x : _Memy = player2y
   if _Current_Object = _Sprite3 then  _Memx = player3x : _Memy = player3y
   if _Current_Object = _Sprite4 then  _Memx = player4x : _Memy = player4y
   if _Current_Object = _Sprite5 then  _Memx = player5x : _Memy = player5y
   if _Current_Object = _Missile0 then _Memx = missile0x : _Memy = missile0y
   if _Current_Object = _Missile1 then _Memx = missile1x : _Memy = missile1y
   if _Current_Object = _Ball then _Memx = ballx : _Memy = bally

__Skip_Memory

   ;```````````````````````````````````````````````````````````````
   ;  Increases the object jiggle counter.
   ;
   _Jiggle_Counter = _Jiggle_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Applies jiggle to the currently selected object.
   ;
   if _Current_Object = _Sprite0 then temp5 = 255 + (rand&3) : player0x = player0x + temp5: temp5 = 255 + (rand&3) : player0y = player0y + temp5
   if _Current_Object = _Sprite1 then temp5 = 255 + (rand&3) : player1x = player1x + temp5: temp5 = 255 + (rand&3) : player1y = player1y + temp5
   if _Current_Object = _Sprite2 then temp5 = 255 + (rand&3) : player2x = player2x + temp5: temp5 = 255 + (rand&3) : player2y = player2y + temp5
   if _Current_Object = _Sprite3 then temp5 = 255 + (rand&3) : player3x = player3x + temp5: temp5 = 255 + (rand&3) : player3y = player3y + temp5
   if _Current_Object = _Sprite4 then temp5 = 255 + (rand&3) : player4x = player4x + temp5: temp5 = 255 + (rand&3) : player4y = player4y + temp5
   if _Current_Object = _Sprite5 then temp5 = 255 + (rand&3) : player5x = player5x + temp5: temp5 = 255 + (rand&3) : player5y = player5y + temp5
   if _Current_Object = _Missile0 then temp5 = 255 + (rand&3) : missile0x = missile0x + temp5: temp5 = 255 + (rand&3) : missile0y = missile0y + temp5
   if _Current_Object = _Missile1 then temp5 = 255 + (rand&3) : missile1x = missile1x + temp5: temp5 = 255 + (rand&3) : missile1y = missile1y + temp5
   if _Current_Object = _Ball then temp5 = 255 + (rand&3) : ballx = ballx + temp5: temp5 = 255 + (rand&3) : bally = bally + temp5

   ;```````````````````````````````````````````````````````````````
   ;  Stops jiggling and restores position of the selected object
   ;  if counter limit has been reached.
   ;
   if _Jiggle_Counter <= 4 then goto __Skip_Object_Jiggle

   _Bit5_Activate_Jiggle{5} = 0 : _Jiggle_Counter = 0

   if _Current_Object = _Sprite0 then  player0x = _Memx : player0y = _Memy
   if _Current_Object = _Sprite1 then  player1x = _Memx : player1y = _Memy
   if _Current_Object = _Sprite2 then  player2x = _Memx : player2y = _Memy
   if _Current_Object = _Sprite3 then  player3x = _Memx : player3y = _Memy
   if _Current_Object = _Sprite4 then  player4x = _Memx : player4y = _Memy
   if _Current_Object = _Sprite5 then  player5x = _Memx : player5y = _Memy
   if _Current_Object = _Missile0 then missile0x = _Memx : missile0y = _Memy
   if _Current_Object = _Missile1 then missile1x = _Memx : missile1y = _Memy
   if _Current_Object = _Ball then ballx = _Memx : bally = _Memy

__Skip_Object_Jiggle



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   if _Current_Object = _Sprite0 then scorecolor = $08 : temp4 = player0x
   if _Current_Object = _Sprite1 then scorecolor = $1A : temp4 = player1x
   if _Current_Object = _Sprite2 then scorecolor = $3A : temp4 = player2x
   if _Current_Object = _Sprite3 then scorecolor = $6A : temp4 = player3x
   if _Current_Object = _Sprite4 then scorecolor = $8A : temp4 = player4x
   if _Current_Object = _Sprite5 then scorecolor = $CA : temp4 = player5x
   if _Current_Object = _Missile0 then scorecolor = $5A : temp4 = missile0x
   if _Current_Object = _Missile1 then scorecolor = $BA : temp4 = missile1x
   if _Current_Object = _Ball then scorecolor = $4A : temp4 = ballx

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
   if _Current_Object = _Sprite0 then temp4 = player0y
   if _Current_Object = _Sprite1 then temp4 = player1y
   if _Current_Object = _Sprite2 then temp4 = player2y
   if _Current_Object = _Sprite3 then temp4 = player3y
   if _Current_Object = _Sprite4 then temp4 = player4y
   if _Current_Object = _Sprite5 then temp4 = player5y
   if _Current_Object = _Missile0 then temp4 = missile0y
   if _Current_Object = _Missile1 then temp4 = missile1y
   if _Current_Object = _Ball then temp4 = bally

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
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Timer section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if timer is off (200 = off).
   ;
   if _Timer = 200 then goto __Skip_Timer

   ;```````````````````````````````````````````````````````````````
   ;  Increases the timer.
   ;
   _Timer = _Timer + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips rest of section if timer is not at the limit.
   ;
   if _Timer < _c_Double_Click_Speed then goto __Skip_Timer

   ;```````````````````````````````````````````````````````````````
   ;  Time ran out! Turns off timer and clears double click bits.
   ;
   _Timer = 200

   _Bit1_1st_Click{1} = 0 : _Bit2_2nd_Click{2} = 0 : _Bit3_Finish_Double_Click{3} = 0

__Skip_Timer



   ;***************************************************************
   ;
   ;  Double click section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Fire button ON subsection.
   ;
   ;  Skips subsection if fire button is off or finish bit is on.
   ;
   if !joy0fire || _Bit3_Finish_Double_Click{3} then goto __Skip_DC_Fire_01

   ;```````````````````````````````````````````````````````````````
   ;  First click check (fire button ON).
   ;
   ;  If 2nd click bit is OFF and 1st click bit is OFF, turns on
   ;  the 1st click bit and restarts the timer.
   ;
   if !_Bit2_2nd_Click{2} && !_Bit1_1st_Click{1} then _Bit1_1st_Click{1} = 1 : _Timer = 0

   ;```````````````````````````````````````````````````````````````
   ;  Second click check (fire button ON).
   ;
   ;  If the 2nd click bit is ON, clears the 2nd click bit, turns
   ;  on the finish bit and restarts the timer.
   ;
   if _Bit2_2nd_Click{2} then _Bit2_2nd_Click{2} = 0 : _Bit3_Finish_Double_Click{3} = 1 : _Timer = 0

__Skip_DC_Fire_01

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Fire button OFF subsection.
   ;
   ;  Skips subsection if fire button is on.
   ;
   if joy0fire then goto __Skip_DC_Fire_02

   ;```````````````````````````````````````````````````````````````
   ;  First click done check (fire button OFF).
   ;
   ;  If 1st click bit is ON, clears the 1st click bit, turns on
   ;  the 2nd click bit, and restarts the timer.
   ;
   if _Bit1_1st_Click{1} then _Bit1_1st_Click{1} = 0 : _Bit2_2nd_Click{2} = 1 : _Timer = 0

   ;```````````````````````````````````````````````````````````````
   ;  Double click finish check (fire button OFF).
   ; 
   ;  If finish bit is OFF, skips finish of double click.
   ;
   if !_Bit3_Finish_Double_Click{3} then goto __Skip_DC_Fire_02

   ;```````````````````````````````````````````````````````````````
   ;  Finish bit is on, so the it's the end of the double click.
   ;
   ;  Turns off the double click bits and turns off the timer.
   ;
   _Bit3_Finish_Double_Click{3} = 0 : _Bit1_1st_Click{1} = 0 : _Bit2_2nd_Click{2} = 0 : _Timer = 200

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if not a virtual sprite.
   ;
   if _Current_Object = 0 || _Current_Object > 5 then goto __Skip_DC_Fire_02

   ;```````````````````````````````````````````````````````````````
   ;  Prepares for number graphic grab.
   ;
   temp6 = _Current_Object - 1

   ;```````````````````````````````````````````````````````````````
   ;  Changes number graphic and rolls over back to 0 if needed.
   ;
   _DisplayNumber1[temp6] = _DisplayNumber1[temp6] + 1 : if _DisplayNumber1[temp6] > 9 then _DisplayNumber1[temp6] = 0

   ;```````````````````````````````````````````````````````````````
   ;  Grabs number graphic for current virtual sprite.
   ;
   temp5 = _DisplayNumber1[temp6]
   player1pointerhi[temp6] = _c_score_table_high
   temp5 = temp5 * 8
   player1pointerlo[temp6] = temp5 + _c_score_table_low

__Skip_DC_Fire_02



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
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop bank1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if the reset switch hasn't
   ;  been released after being pressed.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop bank1

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart bank1





   ;***************************************************************
   ;
   ;  Sprite size data.
   ;
   data _Data_Sprite_Size
   0, 5, 7
end



   ;***************************************************************
   ;
   ;  Missile/ball width data.
   ;
   data _Data_MB_Width
   $00, $10, $20, $30
end



   bank 3



   bank 4

