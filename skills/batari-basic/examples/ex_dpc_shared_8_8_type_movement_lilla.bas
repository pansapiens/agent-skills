   ;***************************************************************
   ;
   ;  Shared 8.8 Type Movement
   ;
   ;  Example program by Lillapojkenpaon and adapted by Duane Alan
   ;  Hahn (Random Terrain) using hints, tips, code snippets, and
   ;  more from AtariAge members such as batari, SeaGtGruff,
   ;  RevEng, Robert M, Nukey Shay, Atarius Maximus, jrok,
   ;  supercat, GroovyBee, and bogax.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  Push the joystick left or right to change the speed.
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
   ;  This program uses the DPC+ kernel.
   ;
   set kernel DPC+



   ;****************************************************************
   ;
   ;  Standard used in North America and most of South America.
   ;
   set tv ntsc



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
   ;  a is integer, b is fraction.
   ;
   dim _8_8_Speed = a.b
   dim _Integer = a
   dim _Fraction = b

   ;```````````````````````````````````````````````````````````````
   ;  Counter for the fraction.
   ;
   dim _Fraction_Counter = c

   ;```````````````````````````````````````````````````````````````
   ;  Temporarily remembers the fraction counter value.
   ;
   dim _Frac_Mem = temp5

   ;```````````````````````````````````````````````````````````````
   ;  Temporarily remembers the speed.
   ;
   dim _Speed = temp6

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = y ; Reset switch becomes inactive if it hasn't been released.



   goto __Bank_2 bank2



   bank 2
   temp1=temp1



__Bank_2




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
   ;  Clears all normal variables and the extra 9.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0
   var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
   var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0


   ;***************************************************************
   ;
   ;  Sets colors for player1 through player8.
   ;
   player1-8color:
   $8E
   $8C
   $8A
   $88
   $86
end


   ;***************************************************************
   ;
   ;  Sets same shape for player1 through player8.
   ;
   player1-8:
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
end


   ;***************************************************************
   ;
   ;  Sets positions for player1 through player4.
   ;
   player1x = 69 : player2x = 69 : player3x = 69 : player4x = 69
   player5x = 69 : player6x = 69 : player7x = 69 : player8x = 69

   player1y = 17 : player2y = player1y + 18 : player3y = player2y + 17
   player4y = player3y + 18 : player5y = player4y + 17 : player6y = player5y + 18
   player7y = player6y + 17 : player8y = player7y + 18


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
   ;  Sets startup speed.
   ;
   _8_8_Speed  = 0.85





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Fraction counter section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Remembers fraction counter value.
   ;
   _Frac_Mem = _Fraction_Counter

   ;```````````````````````````````````````````````````````````````
   ;  Increases fraction counter.
   ;
   _Fraction_Counter = _Fraction_Counter + _Fraction

   ;```````````````````````````````````````````````````````````````
   ;  Speed is increased when fraction counter is rolled over.
   ;
   _Speed = _Integer : if _Fraction_Counter < _Frac_Mem then _Speed = _Speed + 1



   ;***************************************************************
   ;
   ;  Moves 8 sprites.
   ;
   player1x = player1x - _Speed
   player2x = player2x + _Speed
   player3x = player3x - _Speed
   player4x = player4x + _Speed
   player5x = player5x - _Speed
   player6x = player6x + _Speed
   player7x = player7x - _Speed
   player8x = player8x + _Speed



   ;***************************************************************
   ;
   ;  Decreases speed if joystick is pushed left.
   ;
   if joy0left then _8_8_Speed = _8_8_Speed - 0.05



   ;***************************************************************
   ;
   ;  Increases speed if joystick is pushed right.
   ;
   if joy0right then _8_8_Speed = _8_8_Speed + 0.05



   ;***************************************************************
   ;
   ;  88 rows that are 2 scanlines high.
   ;
   DF6FRACINC = 0 : DF4FRACINC = 0

   DF0FRACINC = 128 : DF1FRACINC = 128 : DF2FRACINC = 128 : DF3FRACINC = 128



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





   bank 3
   temp1=temp1





   bank 4
   temp1=temp1





   bank 5
   temp1=temp1





   bank 6
   temp1=temp1