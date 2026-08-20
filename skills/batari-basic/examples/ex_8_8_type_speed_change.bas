   ;***************************************************************
   ;
   ;  8.8 Speed Change
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, and GroovyBee.
   ;
   ;  Special data provided by bogax.
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
   dim _Current_Object = a

   ;```````````````````````````````````````````````````````````````
   ;  Object jiggle counter.
   ;
   dim _Jiggle_Counter = b

   ;```````````````````````````````````````````````````````````````
   ;  Remembers position of jiggled object.
   ;
   dim _Memx = c
   dim _Memy = d

   ;```````````````````````````````````````````````````````````````
   ;  Player0 left/right movement.
   ;
   dim _P0_LR = player0x.e

   ;```````````````````````````````````````````````````````````````
   ;  Player1 left/right movement.
   ;
   dim _P1_LR = player1x.f

   ;```````````````````````````````````````````````````````````````
   ;  Ball left/right movement.
   ;
   dim _B_LR = ballx.g

   ;```````````````````````````````````````````````````````````````
   ;  Player0 left/right movement.
   ;
   dim _P0_Speed = h.i

   ;```````````````````````````````````````````````````````````````
   ;  Player0 left number.
   ;
   dim _P0_Left_Number = h

   ;```````````````````````````````````````````````````````````````
   ;  Player0 right number.
   ;
   dim _P0_Right_Number = i

   ;```````````````````````````````````````````````````````````````
   ;  Player1 left/right movement.
   ;
   dim _P1_Speed = j.k

   ;```````````````````````````````````````````````````````````````
   ;  Player1 left number.
   ;
   dim _P1_Left_Number = j

   ;```````````````````````````````````````````````````````````````
   ;  Player1 right number.
   ;
   dim _P1_Right_Number = k

   ;```````````````````````````````````````````````````````````````
   ;  Ball left/right movement.
   ;
   dim _B_Speed = l.m

   ;```````````````````````````````````````````````````````````````
   ;  Ball left number.
   ;
   dim _B_Left_Number = l

   ;```````````````````````````````````````````````````````````````
   ;  Ball right number.
   ;
   dim _B_Right_Number = m

   ;```````````````````````````````````````````````````````````````
   ;  Score speed counter.
   ;
   dim _Score_Counter = n

   ;```````````````````````````````````````````````````````````````
   ;  Score slowdown variable.
   ;
   dim _Score_Slowdown = o

   ;```````````````````````````````````````````````````````````````
   ;  Tracks the score.
   ;
   dim _Score_Right_Number = p

   ;```````````````````````````````````````````````````````````````
   ;  Remembers object speed.
   ;
   dim _P0Left_Mem = q
   dim _P0Right_Mem = r

   dim _P1Left_Mem = s
   dim _P1Right_Mem = t

   dim _BLeft_Mem = u
   dim _BRight_Mem = v

   ;```````````````````````````````````````````````````````````````
   ;  Used to figure out the left number.
   ;
   dim _Left_Number = w

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _BitOp_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit1_P0_Direction = y
   dim _Bit2_P1_Direction = y
   dim _Bit5_Ball_Direction = y
   dim _Bit6_Joy0_Restrainer = y
   dim _Bit7_Activate_Jiggle = y

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
   const _c_Ball = 1
   const _c_Player1 = 2



   ;***************************************************************
   ;
   ;  Default object colors.
   ;  [The c stands for constant.]
   ;
   const _c_PlayerMissile0_Color = $9C
   const _c_Ball_Color = $FC
   const _c_PlayerMissile1_Color = $CA




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
   ;  Sets starting position of ball.
   ;
   ballx = 83 : bally = player0y - 16


   ;***************************************************************
   ;
   ;  Sets starting position of player0.
   ;
   player1x = 79 : player1y = bally - 8


   ;***************************************************************
   ;
   ;  Sets ball properties.
   ;
   CTRLPF = $01 : ballheight = 0


   ;***************************************************************
   ;
   ;  Sets the speed of the ball and player0 and player1.
   ;
   _P0_Speed = 0.72 : _B_Speed = 1.00 : _P1_Speed = 1.50


   ;***************************************************************
   ;
   ;  Sets number left of period. (Must match above.)
   ;
   _P0_Left_Number = 0 : _B_Left_Number = 1 : _P1_Left_Number = 1

   
   ;***************************************************************
   ;
   ;  Sets right score number tracker. Must be same as _P0_Speed.
   ;
    _Score_Right_Number = 72


   ;***************************************************************
   ;
   ;  Sets starting speed memory for objects.
   ;
   _P0Left_Mem = $00 : _P0Right_Mem = $72
   _BLeft_Mem = $10 : _BRight_Mem = $00
   _P1Left_Mem = $10 : _P1Right_Mem = $50


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


   goto __Score_Color_Start




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
   if !joy0up && !joy0down then _Bit6_Joy0_Restrainer{6} = 0 : goto __Skip_Fire_Button

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick already moved.
   ;
   if _Bit6_Joy0_Restrainer{6} then goto __Skip_Score_Change

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved up or down.
   ;
   if joy0up then _Bit6_Joy0_Restrainer{6} = 1 : _Bit7_Activate_Jiggle{7} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object + 1 : if _Current_Object > 2 then _Current_Object = 0

   if joy0down then _Bit6_Joy0_Restrainer{6} = 1 : _Bit7_Activate_Jiggle{7} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object - 1 : if _Current_Object > 200 then _Current_Object = 2

__Score_Color_Start

   ;```````````````````````````````````````````````````````````````
   ;  Changes score color and speed info in score.
   ;
   if _Current_Object = _c_Player0 then scorecolor = _c_PlayerMissile0_Color : _sc2  = _P0Left_Mem : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A : _sc3 = _P0Right_Mem : _Left_Number = _P0_Left_Number 
   if _Current_Object = _c_Ball then scorecolor = _c_Ball_Color : _sc2  = _BLeft_Mem : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A : _sc3 = _BRight_Mem : _Left_Number = _B_Left_Number 
   if _Current_Object = _c_Player1 then scorecolor = _c_PlayerMissile1_Color : _sc2  = _P1Left_Mem : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A : _sc3 = _P1Right_Mem : _Left_Number = _P1_Left_Number 

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips score change (skips the whole next section).
   ;
   goto __Skip_Score_Change

__Skip_Fire_Button



   ;***************************************************************
   ;
   ;  Score change section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Increments _Score_Counter.
   ;
   _Score_Counter = _Score_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips section if _Score_Counter is less than _Score_Slowdown.
   ;
   if _Score_Counter < _Score_Slowdown then goto __Skip_Score_Change

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Left check.
   ;
   if !joy0left then goto __Skip_Score_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Subtracts from the tracker counter and sets selection speed.
   ;
   _Score_Right_Number = _Score_Right_Number - 1 : _Score_Slowdown = 10

   ;```````````````````````````````````````````````````````````````
   ;  Skips if tracker hasn't gone below zero.
   ;
   if _Score_Right_Number < 200 then goto __Skip_Left_Decrement 

   ;```````````````````````````````````````````````````````````````
   ;  Skips if left number is zero.
   ;
   if !_Left_Number then _Score_Right_Number = 0 : goto __Skip_Score_Joy0_Left

   ;```````````````````````````````````````````````````````````````
   ;  Tracker went below zero, so tracker and score changed to 99.
   ;
   _Score_Right_Number = 99 : _sc3 = $99

   ;```````````````````````````````````````````````````````````````
   ;  Subtracts thousands digit if it's not zero.
   ;
   if _Left_Number then _Left_Number = _Left_Number - 1 : _sc2 = _sc2 - $10 : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A 

   goto __Skip_Score_Joy0_Left

__Skip_Left_Decrement

   ;```````````````````````````````````````````````````````````````
   ;  Subtracts from score only if it's above zero.
   ;
   dec _sc3 = _sc3 - $01

__Skip_Score_Joy0_Left

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Right check.
   ;
   if !joy0right then goto __Skip_Score_Joy0_Right

   ;```````````````````````````````````````````````````````````````
   ;  Adds to the tracker counter and sets selection speed.
   ;
   _Score_Right_Number = _Score_Right_Number + 1 : _Score_Slowdown = 10

   ;```````````````````````````````````````````````````````````````
   ;  Resets tracker and score if it's time to increment thousands digit.
   ;
   if _Score_Right_Number < 100 then goto __Skip_Right_Increment

   if _Left_Number > 8 then _Score_Right_Number = 99 : _sc3 = $99 : goto __Skip_Score_Joy0_Right

   _Score_Right_Number = 0 : _sc3 = $00 : _Left_Number = _Left_Number + 1 : _sc2 = _sc2 + $10 : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A : goto __Skip_Score_Joy0_Right

__Skip_Right_Increment

   ;```````````````````````````````````````````````````````````````
   ;  Adds to score only if range is between 0 and 99.
   ;
   dec _sc3 = _sc3 + $01

__Skip_Score_Joy0_Right

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Up check.
   ;
   if !joy0up then goto __Skip_Score_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Adds to the tracker counter and sets selection speed.
   ;
   _Score_Right_Number = _Score_Right_Number + 1 : _Score_Slowdown = 1

   ;```````````````````````````````````````````````````````````````
   ;  Resets tracker and score if it's time to increment thousands digit.
   ;
   if _Score_Right_Number < 100 then goto __Skip_Up_Increment

   if _Left_Number > 8 then _Score_Right_Number = 99 : _sc3 = $99 : goto __Skip_Score_Joy0_Up

   _Score_Right_Number = 0 : _sc3 = $00 : _Left_Number = _Left_Number + 1 : _sc2 = _sc2 + $10 : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A : goto __Skip_Score_Joy0_Up

__Skip_Up_Increment

   ;```````````````````````````````````````````````````````````````
   ;  Adds to score only if range is between 0 and 99.
   ;
   dec _sc3 = _sc3 + $01

__Skip_Score_Joy0_Up

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Down check.
   ;
  if !joy0down then goto __Skip_Score_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Subtracts from the tracker counter and sets selection speed.
   ;
   _Score_Right_Number = _Score_Right_Number - 1 : _Score_Slowdown = 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips if tracker hasn't gone below zero.
   ;
   if _Score_Right_Number < 200 then goto __Skip_Down_Decrement 

   ;```````````````````````````````````````````````````````````````
   ;  Skips if left number is zero.
   ;
   if !_Left_Number then _Score_Right_Number = 0 : goto __Skip_Score_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Tracker went below zero, so tracker and score changed to 99.
   ;
   _Score_Right_Number = 99 : _sc3 = $99

   ;```````````````````````````````````````````````````````````````
   ;  Grabs the thousands digit and subtracts if it's not zero.
   ;
   if _Left_Number then _Left_Number = _Left_Number - 1 : _sc2 = _sc2 - $10 : _sc2 = _sc2  & %11110000 : _sc2 = _sc2 | $0A

   goto __Skip_Score_Joy0_Down

__Skip_Down_Decrement

   ;```````````````````````````````````````````````````````````````
   ;  Subtracts from score only if it's above zero.
   ;
   dec _sc3 = _sc3 - $01

__Skip_Score_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Sets the current object speed.
   ;
   temp5 = _sc3 & $0F
   temp6 = _sc3 / 16

   if _Current_Object = _c_Player0 then _P0Left_Mem = _sc2  & %11110000 : _P0Right_Mem = _sc3 : _P0_Left_Number = _Left_Number : _P0_Right_Number = _DATA_Lo_Table[temp5] + _DATA_Hi_Table[temp6]

   if _Current_Object = _c_Ball then _BLeft_Mem = _sc2  & %11110000 : _BRight_Mem = _sc3 : _B_Left_Number = _Left_Number : _B_Right_Number = _DATA_Lo_Table[temp5] + _DATA_Hi_Table[temp6]

   if _Current_Object = _c_Player1 then _P1Left_Mem = _sc2  & %11110000 : _P1Right_Mem = _sc3 : _P1_Left_Number = _Left_Number : _P1_Right_Number = _DATA_Lo_Table[temp5] + _DATA_Hi_Table[temp6]

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Clears score counter.
   ;
   _Score_Counter = 0

__Skip_Score_Change



   ;***************************************************************
   ;
   ;  Object jiggle check.
   ;
   ;  Activates object jiggle if new object has been selected.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if object has not been changed.
   ;
   if !_Bit7_Activate_Jiggle{7} then goto __Skip_Object_Jiggle

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if object is jiggling.
   ;
   if _Jiggle_Counter >= 1 then goto __Skip_Memory

   if _Current_Object = _c_Player0 then _Memx = player0x : _Memy = player0y

   if _Current_Object = _c_Ball then _Memx = ballx : _Memy = bally

   if _Current_Object = _c_Player1 then _Memx = player1x : _Memy = player1y

__Skip_Memory

   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the object jiggle counter.
   ;
   _Jiggle_Counter = _Jiggle_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Applies jiggle to the currently selected object.
   ;
   if _Current_Object = _c_Player0 then temp5 = 255 + (rand&3) : player0x = player0x + temp5: temp5 = 255 + (rand&3) : player0y = player0y + temp5

   if _Current_Object = _c_Ball then temp5 = 255 + (rand&3) : ballx = ballx + temp5: temp5 = 255 + (rand&3) : bally = bally + temp5

   if _Current_Object = _c_Player1 then temp5 = 255 + (rand&3) : player1x = player1x + temp5: temp5 = 255 + (rand&3) : player1y = player1y + temp5

   ;```````````````````````````````````````````````````````````````
   ;  Stops jiggling and restores position of the selected object
   ;  if counter limit has been reached.
   ;
   if _Jiggle_Counter <= 4 then goto __Skip_Object_Jiggle

   _Bit7_Activate_Jiggle{7} = 0 : _Jiggle_Counter = 0

   if _Current_Object = _c_Player0 then player0x = _Memx : player0y = _Memy

   if _Current_Object = _c_Ball then ballx = _Memx : bally = _Memy

   if _Current_Object = _c_Player1 then player1x = _Memx : player1y = _Memy

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
   ;  Moves player0 horizontally from edge to edge.
   ;
   if !_Bit1_P0_Direction{1} then _P0_LR = _P0_LR - _P0_Speed : temp6 = 2 + _P0_Left_Number : if player0x < temp6 then _Bit1_P0_Direction{1} = 1

   if _Bit1_P0_Direction{1} then _P0_LR = _P0_LR + _P0_Speed : temp6 = 152 - _P0_Left_Number : if player0x > temp6 then _Bit1_P0_Direction{1} = 0



   ;***************************************************************
   ;
   ;  Moves the ball horizontally from edge to edge.
   ;
   if !_Bit5_Ball_Direction{5} then _B_LR = _B_LR - _B_Speed : temp6 = 3 + _B_Left_Number : if ballx < temp6 then _Bit5_Ball_Direction{5} = 1

   if _Bit5_Ball_Direction{5} then _B_LR = _B_LR + _B_Speed : temp6 = 160 - _B_Left_Number : if ballx > temp6 then _Bit5_Ball_Direction{5} = 0



   ;***************************************************************
   ;
   ;  Moves player1 horizontally from edge to edge.
   ;
   if !_Bit2_P1_Direction{2} then _P1_LR = _P1_LR - _P1_Speed : temp6 = 2 + _P1_Left_Number : if player1x < temp6 then _Bit2_P1_Direction{2} = 1

   if _Bit2_P1_Direction{2} then _P1_LR = _P1_LR + _P1_Speed : temp6 = 152 - _P1_Left_Number : if player1x > temp6 then _Bit2_P1_Direction{2} = 0



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
   ;  BCD conversion data by bogax.
   ;
    data _DATA_Lo_Table
    0,   5,   3,   8,  10,  13,  15,  18,  20,  23
end

    data _DATA_Hi_Table
    0,  26,  51,  77, 102, 128, 154, 179, 205, 230
end