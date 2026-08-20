   ;***************************************************************
   ;
   ;  pfscore Lives and Health Toy
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain) using
   ;  hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;  Special thanks to Nukey Shay for the increment code.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  When the program starts, there will be two icons that stand
   ;  for Lives and Health. Move the joystick left to choose the
   ;  type of bar you want on the left and move the joystick right
   ;  to choose the type of bar on the right. When you are done,
   ;  press the fire button.
   ;
   ;  You will now see your choices near the bottom of the screen.
   ;  
   ;  Left Bar: Move the joystick right/left to decrease/increase.
   ;  
   ;  Right Bar: Move the joystick down/up to decrease/increase.
   ;
   ;  Hit the reset switch if you want to restart the program.
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
   ;  This joystick restrainer slows down joystick input so things
   ;  will not move at the speed of light. When the joystick is
   ;  moved, _Joy0_Restrainer_Counter gets a value of 15 and until
   ;  it counts down to zero, the program will ignore joystick
   ;  movement.
   ;
   dim _Joy0_Restrainer_Counter = m

   ;```````````````````````````````````````````````````````````````
   ;  Left selection bit:
   ;      0 = Lives
   ;      1 = Health
   ;
   dim _Bit0_Left_Selection = p

   ;```````````````````````````````````````````````````````````````
   ;  Right selection bit:
   ;      0 = Lives
   ;      1 = Health
   ;
   dim _Bit1_Right_Selection = p

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Enables pfscore bars.
   ;
   const pfscore = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart



   ;***************************************************************
   ;
   ;  Sets the default look of the sprites.
   ;
   player0:
   %10101010
end

   player1:
   %11111111
end


   ;***************************************************************
   ;
   ;  Sets up pfscore bar selection bits.
   ;
   _Bit0_Left_Selection{0} = 0 :  _Bit1_Right_Selection{1}= 1


   ;***************************************************************
   ;
   ;  Sets up pfscore bars.
   ;
   pfscore1 = %10101010 : pfscore2 = %11111111


   ;***************************************************************
   ;
   ;  Sets color for pfscore bars.
   ;
   pfscorecolor = 0


   ;***************************************************************
   ;
   ;  Sets joystick restrainer counter.
   ;
   _Joy0_Restrainer_Counter = 15


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0


   ;***************************************************************
   ;
   ;  Sets starting position of player0.
   ;
   player0x = 70 : player0y = 50


   ;***************************************************************
   ;
   ;  Sets starting position of player1.
   ;
   player1x = 86 : player1y = 50





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Select Lives or Health Bars
   ;
   ;
__Choose_Lives_Health



   ;***************************************************************
   ;
   ;  Sets the score color and color of the sprites.
   ;
   scorecolor = 0 : COLUP0 = $CB : COLUP1 = $CB



   ;***************************************************************
   ;
   ;  Skips joystick input if _Joy0_Restrainer_Counter is not zero.
   ;
   if _Joy0_Restrainer_Counter <> 0 then goto __R_Done



   ;***************************************************************
   ;
   ;  Left choice.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved left.
   ;
   if !joy0left then goto __L_Done

   _Joy0_Restrainer_Counter = 15 : if !_Bit0_Left_Selection{0} then goto __Skip_L

   ;```````````````````````````````````````````````````````````````
   ;  pfscore1 will be a lives bar.
   ;
   _Bit0_Left_Selection{0} = 0 : pfscore1 = %10101010

   player0:
   %10101010
end

   goto __L_Done

__Skip_L

   ;```````````````````````````````````````````````````````````````
   ;  pfscore1 will be a health bar.
   ;
   _Bit0_Left_Selection{0} = 1 : pfscore1 = %11111111

   player0:
   %11111111
end

__L_Done



   ;***************************************************************
   ;
   ;  Right choice.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved right.
   ;
   if !joy0right then goto __R_Done

   _Joy0_Restrainer_Counter = 15 : if !_Bit1_Right_Selection{1} then goto __Skip_R

   ;```````````````````````````````````````````````````````````````
   ;  pfscore2 will be a lives bar.
   ;
   _Bit1_Right_Selection{1} = 0 : pfscore2 = %10101010

   player1:
   %10101010
end

   goto __R_Done

__Skip_R

   ;```````````````````````````````````````````````````````````````
   ;  pfscore2 will be a health bar.
   ;
   _Bit1_Right_Selection{1} = 1 : pfscore2 = %11111111

   player1:
   %11111111
end

__R_Done



   ;***************************************************************
   ;
   ;  Decreases joystick restrainer counter. When counter reaches
   ;  zero, joystick movement is allowed again.
   ;
   if _Joy0_Restrainer_Counter then _Joy0_Restrainer_Counter = _Joy0_Restrainer_Counter - 1



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Fire button check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Loops back if fire button not pressed.
   ;
   if !joy0fire then goto __Choose_Lives_Health

   ;```````````````````````````````````````````````````````````````
   ;  Sets up variables and any colors for main loop.
   ;
   _Joy0_Restrainer_Counter = 15 : pfscorecolor = $CB

   goto __Main_Loop





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Sets colors for score and sprites.
   ;
   scorecolor = 28 : COLUP0 = $CB : COLUP1 = $CB



   ;***************************************************************
   ;
   ;  Skips joystick input if joystick restrainer is not zero.
   ;
   if _Joy0_Restrainer_Counter <> 0 then goto __Skip_All_Joystick_Input



   ;***************************************************************
   ;
   ;  Increases the bar on the left (pfscore1).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved left.
   ;
   if !joy0left then goto __Joy0Left_Check_Done

   ;```````````````````````````````````````````````````````````````
   ;  Sets joystick restrainer counter.
   ;
   _Joy0_Restrainer_Counter = 15

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if selection bit is set to health bar.
   ;
   if _Bit0_Left_Selection{0} then goto __Increase_Left_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Increases lives bar on the left.
   ;
   ;  Full lives bar looks like this: 10101010
   ;
   ;  How to increase lives bar on left side of screen:
   ;
   ;  Multiply pfscore1 by 4, then use OR 2.
   ;
   pfscore1 = pfscore1*4|2

   goto __Joy0Left_Check_Done

__Increase_Left_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Increases health bar on the left.
   ;
   ;  Full health bar looks like this: 11111111
   ;
   ;  How to increase health bar on left side of screen:
   ;
   ;  Multiply pfscore1 by 2 then use OR 1.
   ;
   pfscore1 = pfscore1*2|1

__Joy0Left_Check_Done



   ;***************************************************************
   ;
   ;  Decreases the bar on the left (pfscore1).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved right.
   ;
   if !joy0right then goto __Joy0Right_Check_Done

   ;```````````````````````````````````````````````````````````````
   ;  Sets joystick restrainer counter.
   ;
   _Joy0_Restrainer_Counter = 15

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if selection bit is set to health bar, skip ahead.
   ;
   if _Bit0_Left_Selection{0} then goto __Decrease_Left_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Decreases lives bar on the left.
   ;
   ;  Full lives bar looks like this: 10101010
   ;
   ;  How to decrease lives bar on left side of screen:
   ;
   ;  Divide pfscore1 by 4.
   ;
   pfscore1 = pfscore1/4

   goto __Joy0Right_Check_Done

__Decrease_Left_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Decreases lives bar on the left.
   ;
   ;  Full health bar looks like this: 11111111
   ;
   ;  How to decrease health bar on left side of screen:
   ;
   ;  Divide pfscore1 by 2.
   ;
   pfscore1 = pfscore1/2

__Joy0Right_Check_Done



   ;***************************************************************
   ;
   ;  Increases the bar on the right (pfscore2).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved up.
   ;
   if !joy0up then goto __Joy0Up_Check_Done

   ;```````````````````````````````````````````````````````````````
   ;  Sets joystick restrainer counter.
   ;
   _Joy0_Restrainer_Counter = 15

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if selection bit is set to health bar.
   ;
   if _Bit1_Right_Selection{1} then goto __Increase_Right_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Increases lives bar on the right.
   ;
   ;  Full lives bar looks like this: 10101010
   ;
   ;  How to increase lives bar on right side of screen:
   ;
   ;  Multiply pfscore2 by 4, then use OR 2.
   ;
   pfscore2 = pfscore2*4|2

   goto __Joy0Up_Check_Done

__Increase_Right_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Increases health bar on the right.
   ;
   ;  Full health bar looks like this: 11111111
   ;
   ;  How to increase health bar on right side of screen:
   ;
   ;  Multiply pfscore2 by 2 then use OR 1.
   ;
   pfscore2 = pfscore2*2|1

__Joy0Up_Check_Done



   ;***************************************************************
   ;
   ;  Decreases the bar on the right (pfscore2).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick not moved down.
   ;
   if !joy0down then goto __Skip_All_Joystick_Input

   ;```````````````````````````````````````````````````````````````
   ;  Sets joystick restrainer counter.
   ;
   _Joy0_Restrainer_Counter = 15

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if selection bit is set to health bar.
   ;
   if _Bit1_Right_Selection{1} then goto __Decrease_Right_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Decreases lives bar on the right.
   ;
   ;  Full lives bar looks like this: 10101010
   ;
   ;  How to decrease lives bar on right side of screen:
   ;
   ;  Divide pfscore2 by 4.
   ;
   pfscore2 = pfscore2/4

   goto __Skip_All_Joystick_Input

__Decrease_Right_Health_Bar

   ;```````````````````````````````````````````````````````````````
   ;  Decreases health bar on the right.
   ;
   ;  Full health bar looks like this: 11111111
   ;
   ;  How to decrease health bar on right side of screen:
   ;
   ;  Divide pfscore2 by 2.
   ;
   pfscore2 = pfscore2/2

__Skip_All_Joystick_Input



   ;***************************************************************
   ;
   ;  Decreases joystick restrainer counter. When counter reaches
   ;  zero, joystick movement is allowed again.
   ;
   if _Joy0_Restrainer_Counter then _Joy0_Restrainer_Counter = _Joy0_Restrainer_Counter - 1



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   temp4 = pfscore1

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
   temp4 = pfscore2

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
   ;  Reset switch check and end of main loop.
   ;
   ;  Any Atari 2600 program should restart when the reset  
   ;  switch is pressed. It is part of the usual standards
   ;  and procedures.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if reset switch not pressed.
   ;
   if !switchreset then goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart