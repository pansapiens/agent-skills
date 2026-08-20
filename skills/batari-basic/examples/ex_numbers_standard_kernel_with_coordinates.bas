   ;***************************************************************
   ;
   ;  Easy Way to Set Player Graphic to Number Mixed With Find
   ;  Border Coordinates Program (Standard Kernel)
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
   ;  Instructions:
   ;  
   ;  There is a ball, a missile, a sprite, and a playfield pixel
   ;  on the screen. The sprite is selected by default. Move it
   ;  around to see the coordinates for the sprite in the score.
   ;
   ;  Double click the fire button to change the number.
   ;  
   ;  To select another object, hold down the fire button and
   ;  press the joystick either up or down.
   ;  
   ;  To change the size of a selected object, hold down the fire
   ;  button and press left or right to cycle through the
   ;  different sizes.
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
   ;  Switches between sprite (0), missile (1) ball (2) and PF (3).
   ;
   dim _Current_Object = g

   ;```````````````````````````````````````````````````````````````
   ;  Width of sprite.
   ;
   dim _Sprite_Size = h

   ;```````````````````````````````````````````````````````````````
   ;  Width of missile.
   ;
   dim _Missile_Width = i

   ;```````````````````````````````````````````````````````````````
   ;  Width of ball.
   ;
   dim _Ball_Width = j

   ;```````````````````````````````````````````````````````````````
   ;  Object jiggle counter.
   ;
   dim _Jiggle_Counter = k

   ;```````````````````````````````````````````````````````````````
   ;  Playfield pixel x variable.
   ;
   dim _PF_Pixel_x = l.m

   ;```````````````````````````````````````````````````````````````
   ;  Playfield pixel y variable.
   ;
   dim _PF_Pixel_y = n.o

   ;```````````````````````````````````````````````````````````````
   ;  Number graphic variable.
   ;
   dim _DisplayNumber = p

   ;```````````````````````````````````````````````````````````````
   ;  Timer for double click.
   ;
   dim _Timer = q

   ;```````````````````````````````````````````````````````````````
   ;  Remembers position of jiggled object.
   ;
   dim _Memx = s
   dim _Memy = t

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _BitOp_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit1_1st_Click = y
   dim _Bit2_2nd_Click = y
   dim _Bit3_Finish_Double_Click = y
   dim _Bit5_Activate_Jiggle = y
   dim _Bit6_Joy0_Restrainer = y
   dim _Bit7_FireB_Restrainer = y

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z

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
   ;  Constants for the 3 objects.
   ;  [The c stands for constant.]
   ;
   const _c_The_Sprite = 0
   const _c_The_Missile = 1
   const _c_The_Ball = 2
   const _c_The_PF_Pixel = 3



   ;***************************************************************
   ;
   ;  Default object colors.
   ;  [The c stands for constant.]
   ;
   const _c_Default_Sprite_Color = $9C
   const _c_Default_Missile_Color = $38
   const _c_Default_Ball_Color = $FC
   const _c_Default_PF_Color = $0A



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
   ;  Sets starting position of player0.
   ;
   player0x = 79 : player0y = 56


   ;***************************************************************
   ;
   ;  Sets starting position of missile1.
   ;
   missile1x = 83 : missile1y = 38


   ;***************************************************************
   ;
   ;  Sets starting position of ball.
   ;
   ballx = 83 : bally = 23


   ;***************************************************************
   ;
   ;  Sets starting position of playfield pixel.
   ;
   _PF_Pixel_x = 16 : _PF_Pixel_y = 8


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
   ;  Defines height of player0 sprite.
   ;
   player0height = 7


   ;***************************************************************
   ;
   ;  Starting number for player0 sprite.
   ;
   _DisplayNumber = 0


   ;***************************************************************
   ;
   ;  Grabs number graphic for player0 sprite.
   ;
   temp5 = _DisplayNumber
   player0pointerhi = _c_score_table_high
   temp5 = temp5 * 8
   player0pointerlo = temp5 + _c_score_table_low


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
   ;  Fire button section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Turns off joystick restrainer bit and skips this section if
   ;  fire button is not pressed.
   ;
   if !joy0fire then _Bit7_FireB_Restrainer{7} = 0 : _Bit6_Joy0_Restrainer{6} = 0 : goto __Skip_Fire_Button

   ;```````````````````````````````````````````````````````````````
   ;  Clears the joystick restrainer bit if joystick is not moved.
   ;
   if !joy0up && !joy0down && !joy0left && !joy0right then _Bit6_Joy0_Restrainer{6} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Turns on fire button restrainer bit if new selection.
   ;
   _Bit7_FireB_Restrainer{7} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick already moved.
   ;
   if _Bit6_Joy0_Restrainer{6} then goto __Skip_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved up or down.
   ;
   if joy0up then _Bit6_Joy0_Restrainer{6} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object + 1 : if _Current_Object > 3 then _Current_Object = 0

   if joy0down then _Bit6_Joy0_Restrainer{6} = 1 : _Bit5_Activate_Jiggle{5} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object - 1 : if _Current_Object = 255 then _Current_Object = 3

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved left.
   ;
   if !joy0left then goto __Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases size of appropriate object.
   ;
   if _Current_Object = _c_The_Sprite then _Sprite_Size = _Sprite_Size - 1 : if _Sprite_Size = 255 then _Sprite_Size = 2

   if _Current_Object = _c_The_Missile then _Missile_Width = _Missile_Width - 1 : if _Missile_Width = 255 then _Missile_Width = 3

   if _Current_Object = _c_The_Ball then _Ball_Width = _Ball_Width - 1 : if _Ball_Width = 255 then _Ball_Width = 3

__Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved right.
   ;
   if !joy0right then goto __Skip_Size_Increase

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Increases size of appropriate object.
   ;
   if _Current_Object = _c_The_Sprite then _Sprite_Size = _Sprite_Size + 1 : if _Sprite_Size >= 3 then _Sprite_Size = 0

   if _Current_Object = _c_The_Missile then _Missile_Width = _Missile_Width + 1 : if _Missile_Width >= 4 then _Missile_Width = 0

   if _Current_Object = _c_The_Ball then _Ball_Width = _Ball_Width + 1 : if _Ball_Width >= 4 then _Ball_Width = 0

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
   ;  Skips ahead if current object is not the sprite.
   ;
   if _Current_Object > _c_The_Sprite then goto __Skip_Sprite_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite if joystick is moved.
   ;
   if joy0up then if player0y > 9 then player0y = player0y - 1

   if joy0down then if player0y < 88 then player0y = player0y + 1

   temp5 = 2 : if _Sprite_Size then temp5 = 1

   if joy0left then if player0x >= temp5 then player0x = player0x - 1

   if joy0right then temp5 = _Data_Width[_Sprite_Size] : if player0x <= temp5 then player0x = player0x + 1

   goto __Skip_Movement

__Skip_Sprite_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not the missile.
   ;
   if _Current_Object > _c_The_Missile then goto __Skip_Missile_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile1 if joystick is moved.
   ;
   if joy0up then temp5 = _Data_M_B_y_Size[_Missile_Width]: if missile1y >= temp5 then missile1y = missile1y - 1

   if joy0down then if missile1y <= 87 then missile1y = missile1y + 1

   if joy0left then if missile1x >= 3 then missile1x = missile1x - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Missile_Width] : if missile1x <= temp5 then missile1x = missile1x + 1

   goto __Skip_Movement

__Skip_Missile_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not the missile.
   ;
   if _Current_Object > _c_The_Ball then goto __Skip_Ball_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball if joystick is moved.
   ;
   if joy0up then temp5 = _Data_M_B_y_Size[_Ball_Width]: if bally >= temp5 then bally = bally - 1

   if joy0down then if bally <= 87 then bally = bally + 1

   if joy0left then if ballx >= 3 then ballx = ballx - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Ball_Width]: if ballx <= temp5 then ballx = ballx + 1

   goto __Skip_Movement

__Skip_Ball_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves playfield pixel if joystick is moved.
   ;
   if joy0up then if _PF_Pixel_y >= 1 then _PF_Pixel_y = _PF_Pixel_y - 0.40

   if joy0down then if _PF_Pixel_y <= 9 then _PF_Pixel_y = _PF_Pixel_y + 0.40

   if joy0left then if _PF_Pixel_x >= 1 then _PF_Pixel_x = _PF_Pixel_x - 0.40

   if joy0right then if _PF_Pixel_x <= 30 then _PF_Pixel_x = _PF_Pixel_x + 0.40

__Skip_Movement



   ;***************************************************************
   ;
   ;  Sets the size of sprite0.
   ;
   NUSIZ0 = _Data_Sprite_Size[_Sprite_Size]



   ;***************************************************************
   ;
   ;  Sets the width and height of missile1.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Sets missile1 width using data.
   ;
   NUSIZ1 = _Data_MB_Width[_Missile_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile1 height using data.
   ;
   missile1height = _Data_MB_Height[_Missile_Width]



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

   if _Current_Object = _c_The_Sprite then _Memx = player0x : _Memy = player0y

   if _Current_Object = _c_The_Missile then _Memx = missile1x : _Memy = missile1y

   if _Current_Object = _c_The_Ball then _Memx = ballx : _Memy = bally

   if _Current_Object = _c_The_PF_Pixel then _Memx = _PF_Pixel_x : _Memy = _PF_Pixel_y

__Skip_Memory

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the object jiggle counter.
   ;
   _Jiggle_Counter = _Jiggle_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Applies jiggle to the currently selected object.
   ;
   if _Current_Object = _c_The_Sprite then temp5 = 255 + (rand&3) : player0x = player0x + temp5: temp5 = 255 + (rand&3) : player0y = player0y + temp5

   if _Current_Object = _c_The_Missile then temp5 = 255 + (rand&3) : missile1x = missile1x + temp5: temp5 = 255 + (rand&3) : missile1y = missile1y + temp5

   if _Current_Object = _c_The_Ball then temp5 = 255 + (rand&3) : ballx = ballx + temp5: temp5 = 255 + (rand&3) : bally = bally + temp5

   if _Current_Object = _c_The_PF_Pixel then temp5 = (rand&3) : _PF_Pixel_x = _PF_Pixel_x - 1.0 :_PF_Pixel_x = _PF_Pixel_x + temp5 : temp5 = (rand&3) : _PF_Pixel_y = _PF_Pixel_y - 1.0 : _PF_Pixel_y = _PF_Pixel_y + temp5

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

   if _Current_Object = _c_The_Sprite then player0x = _Memx : player0y = _Memy

   if _Current_Object = _c_The_Missile then missile1x = _Memx : missile1y = _Memy

   if _Current_Object = _c_The_Ball then ballx = _Memx : bally = _Memy

   if _Current_Object = _c_The_PF_Pixel then _PF_Pixel_x = _Memx : _PF_Pixel_y = _Memy

__Skip_Object_Jiggle



   ;***************************************************************
   ;
   ;  Sets color of player0 sprite.
   ;
   COLUP0 = _c_Default_Sprite_Color



   ;***************************************************************
   ;
   ;  Sets color of missile1.
   ;
   COLUP1 = _c_Default_Missile_Color



   ;***************************************************************
   ;
   ;  Sets playfield and ball color.
   ;
   COLUPF = _c_Default_Ball_Color



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   if _Current_Object = _c_The_Sprite then temp4 = player0x : scorecolor = _c_Default_Sprite_Color
   if _Current_Object = _c_The_Missile then temp4 = missile1x : scorecolor = _c_Default_Missile_Color
   if _Current_Object = _c_The_Ball then temp4 = ballx : scorecolor = _c_Default_Ball_Color
   if _Current_Object = _c_The_PF_Pixel then temp4 = _PF_Pixel_x : scorecolor = _c_Default_PF_Color

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
   if _Current_Object = _c_The_Sprite then temp4 = player0y
   if _Current_Object = _c_The_Missile then temp4 = missile1y
   if _Current_Object = _c_The_Ball then temp4 = bally
   if _Current_Object = _c_The_PF_Pixel then temp4 = _PF_Pixel_y

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
   ;  Changes number graphic and rolls over back to 0 if needed.
   ;
   _DisplayNumber = _DisplayNumber + 1 : if _DisplayNumber > 9 then _DisplayNumber = 0

   ;```````````````````````````````````````````````````````````````
   ;  Grabs number graphic for player0 sprite.
   ;
   temp5 = _DisplayNumber
   player0pointerhi = _c_score_table_high
   temp5 = temp5 * 8
   player0pointerlo = temp5 + _c_score_table_low

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
   ;  Sprite size data for use with NUSIZ0.
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



   ;***************************************************************
   ;
   ;  Missile/ball x size data.
   ;
   data _Data_M_B_x_Size
   159, 158, 156, 152
end



   ;***************************************************************
   ;
   ;  Missile/ball y size data.
   ;
   data _Data_M_B_y_Size
   2, 3, 5, 8
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
   ;  Sprite width data.
   ;
   data _Data_Width
   151, 142, 126
end
