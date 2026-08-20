   ;***************************************************************
   ;
   ;  Read Paddle
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
   ;  Bounce the ball back up with the paddle.
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
   ;  Kernel options for this program eliminate the blank lines
   ;  and allow the paddles to be read.
   ;
   set kernel_options no_blank_lines readpaddle



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
   ;  Paddle direction.
   ;
   dim _Paddle_Direction = c

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _BitOp_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit5_B_Direction_X = y
   dim _Bit6_B_Direction_Y = y

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers. 
   ;
   dim rand16 = z



   ;***************************************************************
   ;
   ;  Defines the edges of the playfield for the ball. If the
   ;  ball is a different size, you'll need to adjust the numbers.
   ;
   const _B_Edge_Top = 3
   const _B_Edge_Bottom = 88
   const _B_Edge_Left = 3
   const _B_Edge_Right = 159





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
   ;  Clears 25 of the normal 26 variables (fastest way).
   ;  The variable z is used for random numbers in this program
   ;  and clearing it would mess up those random numbers.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0


   ;***************************************************************
   ;
   ;  Sets positions of player0 and ball.
   ;
   player0y = 85 : bally = 200


   ;***************************************************************
   ;
   ;  Sets background color and foreground color.
   ;
   COLUBK = $00 : COLUPF = $2C


   ;***************************************************************
   ;
   ;  Makes the ball 2 pixels wide and 2 pixels high.
   ;
   CTRLPF = $11 : ballheight = 2


   ;***************************************************************
   ;
   ;  Sets random starting position of ball.
   ;
   ballx = (rand/2) + (rand&15) + (rand/32) + 5 : bally = 6


   ;***************************************************************
   ;
   ;  Ballx starting direction is random. It will either go left
   ;  or right.
   ;
   temp5 = (rand & %00100000)

   _Bit5_B_Direction_X = _Bit5_B_Direction_X ^ temp5


   ;***************************************************************
   ;
   ;  Bally starting direction is down.
   ;
   _Bit6_B_Direction_Y{6} = 1


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
   ;  Creates shape of paddle.
   ;
   player0:
   %1111111
   %1111111
end





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE GAME GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Sets up color and size of player0 (double size).
   ;
   COLUP0 = $9C : NUSIZ0 = $05



   ;***************************************************************
   ;
   ;  Bounces the ball if it hits the edge of the screen.
   ;
   if ballx < _B_Edge_Left || ballx > _B_Edge_Right then _Bit5_B_Direction_X = _Bit5_B_Direction_X ^ %00100000

   if bally < _B_Edge_Top then _Bit6_B_Direction_Y = _Bit6_B_Direction_Y ^ %01000000



   ;***************************************************************
   ;
   ;  Moves the ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Moves ball right if direction isn't left.
   ;
   temp5 = 255 : if _Bit5_B_Direction_X{5} then temp5 = 1

   ballx = ballx + temp5

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball down if direction isn't up.
   ;
   temp5 = 255 : if _Bit6_B_Direction_Y{6} then temp5 = 1

   bally = bally + temp5



   ;***************************************************************
   ;
   ;  Lost ball check. Resets ball if it hits the bottom.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if ball isn't at bottom of screen.
   ;
   if bally < 100 then goto __Skip_Ball_Reset

   ;```````````````````````````````````````````````````````````````
   ;  Chooses a new random location at the top of the screen.
   ;
   ballx = (rand/2) + (rand&15) + (rand/32) + 5 : bally = 6

   ;```````````````````````````````````````````````````````````````
   ;  Selects a random x direction.
   ;
   temp5 = (rand & %00100000)

   _Bit5_B_Direction_X = _Bit5_B_Direction_X ^ temp5

   ;```````````````````````````````````````````````````````````````
   ;  Bally starting direction is down.
   ;
   _Bit6_B_Direction_Y{6} = 1

__Skip_Ball_Reset



   ;***************************************************************
   ;
   ;  Paddle 0 will be read.
   ;
   currentpaddle = 0



   ;***************************************************************
   ;
   ;  Draws the screen and reads the paddle.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Gets old position of player0x.
   ;
   _Paddle_Direction = player0x



   ;***************************************************************
   ;
   ;  Converts value of paddle to useable coordinate.
   ;
   player0x = (paddle * 2) + 1

   ;```````````````````````````````````````````````````````````````
   ;  Limits player movement.
   ;
   if player0x > 141 then player0x = 141



   ;***************************************************************
   ;
   ;  Paddle collision. Influences direction of ball with paddle.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if there is no collision.
   ;
   if !collision(player0,ball) then goto __Skip_Paddle_Influence

   ;```````````````````````````````````````````````````````````````
   ;  Ball will move up now.
   ;
   _Bit6_B_Direction_Y{6} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if player hasn't moved.
   ;
   if _Paddle_Direction = player0x then goto __Skip_Paddle_Influence

   ;```````````````````````````````````````````````````````````````
   ;  Sets ball direction to the left.
   ;
   _Bit5_B_Direction_X{5} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Sets ball direction to the right if paddle has moved right.
   ;
   if player0x > _Paddle_Direction then _Bit5_B_Direction_X{5} = 1

__Skip_Paddle_Influence



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