   ;***************************************************************
   ;
   ;  8 Way Animation Example Program based on Seaweed Assault
   ;
   ;  By Duane Alan Hahn (Random Terrain) using hints, tips,
   ;  code snippets, and more from AtariAge members such as
   ;  batari, SeaGtGruff, RevEng, Robert M, Atarius Maximus,
   ;  jrok, Nukey Shay, supercat, GroovyBee, and bogax.
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
   ;  Player movement.
   ;
   dim _P0_Left_Right = player0x.a

   dim _P0_Up_Down = player0y.b

   ;```````````````````````````````````````````````````````````````
   ;  _Master_Counter can be used for many things, but it is 
   ;  really useful for animating sprite frames when used
   ;  with _Frame_Counter.
   ;
   dim _Master_Counter = c
   dim _Frame_Counter = d

   ;```````````````````````````````````````````````````````````````
   ;  Remembers SWCHA joystick movement.
   ;
   dim _Mem_SWCHA = e

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Reset switch becomes inactive if it hasn't been released.
   ;
   dim _Bit0_Reset_Restrainer = y

   ;```````````````````````````````````````````````````````````````
   ;  Flips player sprite when necessary.
   ;
   dim _Bit3_Flip_P0 = y

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
   ;  Defines the edges of the playfield. The _c_ stands for const
   ;  so I'll remember it's a constant and not a normal variable.
   ;
   const _c_Edge_Top = 10
   const _c_Edge_Bottom = 87
   const _c_Edge_Left = 1
   const _c_Edge_Right = 152




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
   ;  Sets background color.
   ;
   COLUBK = $00


   ;***************************************************************
   ;
   ;  Sets player0 position and starting shape.
   ;
   player0x = 77 : player0y = 53

   player0:
   %00011000
   %00011000
   %00011000
   %11111111
   %01111110
   %00111100
   %01100110
   %01011010
end


   ;***************************************************************
   ;
   ;  Restrains the reset switch for the main loop.
   ;
   ;  This bit fixes it so the reset switch becomes inactive if
   ;  it hasn't been released after being pressed once.
   ;
   _Bit0_Reset_Restrainer{0} = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Sets player0 color.
   ;
   COLUP0 = $0A



   ;***************************************************************
   ;
   ;  Main counters.
   ;
   ;  Controls animation speed.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Increments the master counter.
   ;
   _Master_Counter = _Master_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips section if master counter is less than 7.
   ;
   if _Master_Counter < 7 then goto __Skip_Frame_Counter

   ;```````````````````````````````````````````````````````````````
   ;  Increments frame counter.
   ;
   _Frame_Counter = _Frame_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Clears master counter.
   ;
   _Master_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Clears frame counter when it's time.
   ;
   if _Frame_Counter = 4 then _Frame_Counter = 0

__Skip_Frame_Counter



   ;***************************************************************
   ;
   ;  Advanced joystick reading.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Reads joystick. See SWCHA on the bB page for more info.
   ;
   _Mem_SWCHA = SWCHA/16

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to ship movement or skips movement.
   ;                       0         1         2         3         4        5      6      7      8        9     10     11      12      13    14     15
   on _Mem_SWCHA goto __Skip_J0 __Skip_J0 __Skip_J0 __Skip_J0 __Skip_J0 __GoDR __GoUR __GoR __Skip_J0 __GoDL __GoUL __GoL __Skip_J0 __GoD __GoU __Skip_J0



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Player Movement Routines
   ;
   ;***************************************************************
   ;***************************************************************
   ;
   ;  Up joystick direction.
   ;
__GoU

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down > _c_Edge_Top then _P0_Up_Down = _P0_Up_Down - 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is not reflected. 
   ;
   _Bit3_Flip_P0{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame.
   ;
   on _Frame_Counter goto __P0_U_00 __P0_U_01 __P0_U_02 __P0_U_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Down joystick direction.
   ;
__GoD

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down < _c_Edge_Bottom then _P0_Up_Down = _P0_Up_Down + 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is not reflected. 
   ;
   _Bit3_Flip_P0{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame.
   ;
   on _Frame_Counter goto __P0_D_00 __P0_D_01 __P0_D_02 __P0_D_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Joystick direction: Left.
   ;
__GoL

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Left_Right > _c_Edge_Left then _P0_Left_Right = _P0_Left_Right - 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is not reflected. 
   ;
   _Bit3_Flip_P0{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame.
   ;
   on _Frame_Counter goto __P0_L_00 __P0_L_01 __P0_L_02 __P0_L_03

   
   
   ;***************************************************************
   ;***************************************************************
   ;
   ;  Joystick direction: Right.
   ;
__GoR

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Left_Right < _c_Edge_Right then _P0_Left_Right = _P0_Left_Right + 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is reflected. 
   ;
   _Bit3_Flip_P0{3} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame (shared with __GoL).
   ;
   on _Frame_Counter goto __P0_L_00 __P0_L_01 __P0_L_02 __P0_L_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Up-Left joystick direction.
   ;
__GoUL

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down > _c_Edge_Top then _P0_Up_Down = _P0_Up_Down - 1.42
   if _P0_Left_Right > _c_Edge_Left then _P0_Left_Right = _P0_Left_Right - 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is not reflected. 
   ;
   _Bit3_Flip_P0{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame.
   ;
   on _Frame_Counter goto __P0_UL_00 __P0_UL_01 __P0_UL_02 __P0_UL_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Up-Right joystick direction.
   ;
__GoUR

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down > _c_Edge_Top then _P0_Up_Down = _P0_Up_Down - 1.42

   if _P0_Left_Right < _c_Edge_Right then _P0_Left_Right = _P0_Left_Right + 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is reflected. 
   ;
   _Bit3_Flip_P0{3} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame (shared with __GoUL).
   ;
   on _Frame_Counter goto __P0_UL_00 __P0_UL_01 __P0_UL_02 __P0_UL_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Down-Left joystick direction.
   ;
__GoDL

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down < _c_Edge_Bottom then _P0_Up_Down = _P0_Up_Down + 1.42
   if _P0_Left_Right > _c_Edge_Left then _P0_Left_Right = _P0_Left_Right - 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is not reflected. 
   ;
   _Bit3_Flip_P0{3} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame.
   ;
   on _Frame_Counter goto __P0_DL_00 __P0_DL_01 __P0_DL_02 __P0_DL_03



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Joystick direction: Down-Right.
   ;
__GoDR

   ;```````````````````````````````````````````````````````````````
   ;  Moves player0 if not hitting the border. 
   ;
   if _P0_Up_Down < _c_Edge_Bottom then _P0_Up_Down = _P0_Up_Down + 1.42
   if _P0_Left_Right < _c_Edge_Right then _P0_Left_Right = _P0_Left_Right + 1.42

   ;```````````````````````````````````````````````````````````````
   ;  Sprite is reflected. 
   ;
   _Bit3_Flip_P0{3} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the next animation frame (shared with __GoDL).
   ;
   on _Frame_Counter goto __P0_DL_00 __P0_DL_01 __P0_DL_02 __P0_DL_03


__Skip_J0



   ;***************************************************************
   ;
   ;  Flips player sprite if necessary.
   ;
   if _Bit3_Flip_P0{3} then REFP0 = 8



   ;***************************************************************
   ;
   ;  Sets color of the score.
   ;
   scorecolor = $9C



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Replace "_Mem_SWCHA" with whatever you need to check.
   ;
   temp4 = _Mem_SWCHA

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





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Animation frames for player0 sprite.
   ;
__P0_U_00
   player0:
   %01011010
   %01100110
   %00111100
   %01111110
   %11111111
   %00011000
   %00011000
   %00011000
end
   goto __Skip_J0


__P0_U_01
   player0:
   %01100110
   %01000010
   %10111101
   %01111110
   %11111111
   %00011000
   %00011000
   %00011000
end
   goto __Skip_J0


__P0_U_02
   player0:
   %01000010
   %11000011
   %10111101
   %01111110
   %11111111
   %00011000
   %00011000
   %00011000
end
   goto __Skip_J0


__P0_U_03
   player0:
   %11100111
   %11000011
   %10111101
   %01111110
   %11111111
   %00011000
   %00011000
   %00011000
end
   goto __Skip_J0


__P0_D_00
   player0:
   %00011000
   %00011000
   %00011000
   %11111111
   %01111110
   %00111100
   %01100110
   %01011010
end
   goto __Skip_J0


__P0_D_01
   player0:
   %00011000
   %00011000
   %00011000
   %11111111
   %01111110
   %10111101
   %01000010
   %01100110
end
   goto __Skip_J0


__P0_D_02
   player0:
   %00011000
   %00011000
   %00011000
   %11111111
   %01111110
   %10111101
   %11000011
   %01000010
end
   goto __Skip_J0


__P0_D_03
   player0:
   %00011000
   %00011000
   %00011000
   %11111111
   %01111110
   %10111101
   %11000011
   %11100111
end
   goto __Skip_J0


__P0_L_00
   player0:
   %00010000
   %00011011
   %00011110
   %11111101
   %11111101
   %00011110
   %00011011
   %00010000
end
   goto __Skip_J0


__P0_L_01
   player0:
   %00010100
   %00011011
   %00011101
   %11111100
   %11111100
   %00011101
   %00011011
   %00010100
end
   goto __Skip_J0


__P0_L_02
   player0:
   %00010110
   %00011011
   %00011100
   %11111100
   %11111100
   %00011100
   %00011011
   %00010110
end
   goto __Skip_J0


__P0_L_03
   player0:
   %00010111
   %00011011
   %00011101
   %11111100
   %11111100
   %00011101
   %00011011
   %00010111
end
   goto __Skip_J0


__P0_UL_00
   player0:
   %00001000
   %10010010
   %11111000
   %01111101
   %00111110
   %01111100
   %11101100
   %11000110
end
   goto __Skip_J0


__P0_UL_01
   player0:
   %00001100
   %11010000
   %11111001
   %01111101
   %00111110
   %01111110
   %11101100
   %11000110
end
   goto __Skip_J0


__P0_UL_02
   player0:
   %00101000
   %11010000
   %11111000
   %01111101
   %00111110
   %01111111
   %11101100
   %11000110
end
   goto __Skip_J0


__P0_UL_03
   player0:
   %00111100
   %11110000
   %11111001
   %01111101
   %00111111
   %01111111
   %11101100
   %11000110
end
   goto __Skip_J0


__P0_DL_00
   player0:
   %11000110
   %11101100
   %01111100
   %00111110
   %01111101
   %11111000
   %10010010
   %00001000
end
   goto __Skip_J0


__P0_DL_01
   player0:
   %11000110
   %11101100
   %01111110
   %00111110
   %01111101
   %11111001
   %11010000
   %00001100
end
   goto __Skip_J0


__P0_DL_02
   player0:
   %11000110
   %11101100
   %01111111
   %00111110
   %01111101
   %11111000
   %11010000
   %00101000
end
   goto __Skip_J0


__P0_DL_03
   player0:
   %11000110
   %11101100
   %01111111
   %00111111
   %01111101
   %11111001
   %11110000
   %00111100
end
   goto __Skip_J0