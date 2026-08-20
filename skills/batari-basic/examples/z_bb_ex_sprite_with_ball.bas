   ;***************************************************************
   ;
   ;  Sprite With Ball
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
   ;  Use the joystick to move the sprite. Watch ball bounce.
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
   ;  Bits that do various jobs.
   ;
   dim _Bit0_Reset_Restrainer = y
   dim _Bit5_B_Direction_X = y
   dim _Bit6_B_Direction_Y = y

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z



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
   ;  Defines the edges of the playfield for the ball. If the
   ;  ball is a different size, you'll need to adjust the numbers.
   ;
   const _B_Edge_Top = 3
   const _B_Edge_Bottom = 86
   const _B_Edge_Left = 2
   const _B_Edge_Right = 159



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
   ;  Clears 25 of the normal 26 variables (fastest way).
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
   player0x = 77 : player0y = 53


   ;***************************************************************
   ;
   ;  Sets random starting position of ball.
   ;
   ballx = (rand/2) + (rand&15) + (rand/32) + 5 : bally = 9


   ;***************************************************************
   ;
   ;  Defines ball size.
   ;
   CTRLPF = $11 : ballheight = 2


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
   ;  Sets color of player0 sprite.
   ;
   COLUP0 = $9C



   ;***************************************************************
   ;
   ;  Moves player0 sprite with the joystick while keeping the
   ;  sprite within the playfield area.
   ;
   if joy0up && player0y > _P_Edge_Top then player0y = player0y - 1

   if joy0down && player0y < _P_Edge_Bottom then player0y = player0y + 1

   if joy0left && player0x > _P_Edge_Left then player0x = player0x - 1

   if joy0right && player0x < _P_Edge_Right then player0x = player0x + 1



   ;***************************************************************
   ;
   ;  Bounces the ball if it hits the edge of the screen.
   ;
   if ballx < _B_Edge_Left || ballx > _B_Edge_Right then _Bit5_B_Direction_X = _Bit5_B_Direction_X ^ %00100000

   if bally < _B_Edge_Top || bally > _B_Edge_Bottom then _Bit6_B_Direction_Y = _Bit6_B_Direction_Y ^ %01000000



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