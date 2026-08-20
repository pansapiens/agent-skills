   ;***************************************************************
   ;
   ;  13 Objects With Coordinates and Collision (DPC+)
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
   ;  Instructions
   ;  
   ;  There are 10 sprites (player0 at the top, down to player9 at
   ;  the bottom), 2 missiles (missile0 above missile1) and 1 ball
   ;  on the screen. Hold down the fire button and press the
   ;  joystick up or down to select an object. Hold down the fire
   ;  button and move the joystick left or right to change the size
   ;  of the currently selected object.
   ;  
   ;  To move the currently selected object, release the fire
   ;  button and press the joystick in any direction.
   ;
   ;  When you move the player0 sprite over the other sprites, a
   ;  playfield pixel is turned on next to the starting position of
   ;  the touched sprite.
   ;
   ;  When a sprite touches the green column on the screen, a
   ;  playfield pixel is turned on across from the starting
   ;  position of the sprite on the other side of the column.
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



   ;****************************************************************
   ;
   ;  Helps player1 sprites register a collision with the playfield.
   ;
   set kernel_options collision(player1,playfield)



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
   dim _Sprite_Size6 = h
   dim _Sprite_Size7 = i
   dim _Sprite_Size8 = j
   dim _Sprite_Size9 = k

   ;```````````````````````````````````````````````````````````````
   ;  Width of missiles.
   ;
   dim _Missile0_Width = l
   dim _Missile1_Width = m

   ;```````````````````````````````````````````````````````````````
   ;  Width of ball.
   ;
   dim _Ball_Width = n

   ;```````````````````````````````````````````````````````````````
   ;  Object jiggle counter.
   ;
   dim _Jiggle_Counter = o

   ;```````````````````````````````````````````````````````````````
   ;  Remembers NUSIZ0.
   ;
   dim _P0_NUSIZ = p

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = t
   dim _Bit1_Joy0_Restrainer = t
   dim _Bit2_Activate_Jiggle = t
   dim _Bit3_Flip_p0 = t

   ;```````````````````````````````````````````````````````````````
   ;  Remembers position of jiggled object.
   ;
   dim _Memx = x
   dim _Memy = y

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Constants for the 13 objects.
   ;
   const _Sprite0 = 0
   const _Sprite1 = 1
   const _Sprite2 = 2
   const _Sprite3 = 3
   const _Sprite4 = 4
   const _Sprite5 = 5
   const _Sprite6 = 6
   const _Sprite7 = 7
   const _Sprite8 = 8
   const _Sprite9 = 9
   const _Missile0 = 10
   const _Missile1 = 11
   const _Ball = 12




   goto __Start_Restart bank2




   bank 2
   temp1=temp1




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
   ;  Sprite shapes and colors.
   ;
   player0:
   %00001111
   %00000110
   %00000111
   %00011111
   %11111111
   %00111110
   %11111111
   %00011111
   %00000111
   %00000110
   %00001111
end

   player0color:
   $0A
   $02
   $06
   $08
   $0C
   $06
   $0C
   $08
   $06
   $02
   $0A
end

   player1:
   %00000011
   %00000110
   %00011111
   %11111111
   %11111110
   %11111110
   %11111110
   %11111111
   %00011111
   %00000110
   %00000011
end

   player1color:
   $1A
   $12
   $16
   $18
   $1C
   $16
   $1C
   $18
   $16
   $12
   $1A
end

   player2:
   %00001111
   %00000110
   %11111111
   %11111111
   %00000111
   %00001110
   %00000111
   %11111111
   %11111111
   %00000110
   %00001111
end

   player2color:
   $2A
   $22
   $26
   $28
   $2C
   $26
   $2C
   $28
   $26
   $22
   $2A
end

   player3:
   %00111111
   %00111110
   %00000111
   %00011111
   %00111111
   %11111110
   %00111111
   %00011111
   %00000111
   %00111110
   %00111111
end

   player3color:
   $3A
   $32
   $36
   $38
   $3C
   $36
   $3C
   $38
   $36
   $32
   $3A
end

   player4:
   %00001111
   %00000110
   %00000110
   %00011110
   %11111111
   %11111111
   %11111111
   %00011110
   %00000110
   %00000110
   %00001111
end

   player4color:
   $4A
   $42
   $46
   $48
   $4A
   $4E
   $4A
   $48
   $46
   $42
   $4A
end

   player5:
   %00011111
   %00011111
   %00000100
   %11111110
   %00111110
   %11111110
   %00111110
   %11111110
   %00000100
   %00011111
   %00011111
end

   player5color:
   $5A
   $56
   $52
   $56
   $5C
   $5E
   $5C
   $56
   $52
   $56
   $5A
end

   player6:
   %11111111
   %01111111
   %01111111
   %00011110
   %00111110
   %00111110
   %00111110
   %00011110
   %01111111
   %01111111
   %11111111
end

   player6color:
   $6A
   $66
   $62
   $66
   $68
   $6C
   $68
   $66
   $62
   $66
   $6A
end

   player7:
   %00001111
   %00000110
   %11111110
   %11111110
   %00111110
   %00111110
   %00111110
   %11111110
   %11111110
   %00000110
   %00001111
end

   player7color:
   $7A
   $72
   $76
   $78
   $7C
   $76
   $7C
   $78
   $76
   $72
   $7A
end

   player8:
   %00001111
   %00001111
   %00001111
   %11111110
   %11111110
   %00000110
   %11111110
   %11111110
   %00001111
   %00001111
   %00001111
end

   player8color:
   $8A
   $88
   $84
   $88
   $8C
   $86
   $8C
   $88
   $84
   $88
   $8A
end

   player9:
   %00011111
   %00011111
   %00011111
   %00000110
   %11101110
   %01111110
   %11101110
   %00000110
   %00011111
   %00011111
   %00011111
end

   player9color:
   $96
   $9A
   $94
   $94
   $96
   $9C
   $96
   $94
   $94
   $9A
   $96
end


   ;***************************************************************
   ;
   ;  Sets playfield color.
   ;
   pfcolors:
   $C8
end


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   bkcolors:
   $00
end


   ;***************************************************************
   ;
   ;  Sets color of missiles.
   ;
   COLUM0 = $FE : COLUM1 = $AC


   ;***************************************************************
   ;
   ;  Object placement.
   ;
   player0x = 61 : player0y = 0
   player1x = 61 : player1y = 17
   player2x = 61 : player2y = player1y + 18
   player3x = 61 : player3y = player2y + 17
   player4x = 61 : player4y = player3y + 18
   player5x = 61 : player5y = player4y + 17
   player6x = 61 : player6y = player5y + 18
   player7x = 61 : player7y = player6y + 17
   player8x = 61 : player8y = player7y + 18
   player9x = 61 : player9y = player8y + 17
   missile0x = 120 : missile0y = 14
   missile1x = 120 : missile1y = 31
   ballx = 120 : bally = 48


   ;***************************************************************
   ;
   ;  Turns on virtual sprite masking.
   ;
   _NUSIZ1{7} = 1 : NUSIZ2{7} = 1 : NUSIZ3{7} = 1
   NUSIZ4{7} = 1 : NUSIZ5{7} = 1 : NUSIZ6{7} = 1
   NUSIZ7{7} = 1 : NUSIZ8{7} = 1 : NUSIZ9{7} = 1


   ;***************************************************************
   ;
   ;  Makes all sprites face the same way.
   ;
   _NUSIZ1{3} = 0 : NUSIZ2{3} = 0 : NUSIZ3{3} = 0
   NUSIZ4{3} = 0 : NUSIZ5{3} = 0 : NUSIZ6{3} = 0
   NUSIZ7{3} = 0 : NUSIZ8{3} = 0 : NUSIZ9{3} = 0


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Clears all normal variables and the extra 9 (fastest way).
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0
   var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
   var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0


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
   ;  Clears the playfield.
   ;
   pfclear


   ;***************************************************************
   ;
   ;  Draws a column on the screen.
   ;
   pfvline 16 0 86 on





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
   ;  Turns off joystick repetition restrainer bit and skips this
   ;  section if fire button is not pressed.
   ;
   if !joy0fire then _Bit1_Joy0_Restrainer{1} = 0 : goto __Skip_Fire_Button

   ;```````````````````````````````````````````````````````````````
   ;  Turns off joystick repetition restrainer bit if joystick not
   ;  moved.
   ;
   if !joy0up && !joy0down && !joy0left && !joy0right then _Bit1_Joy0_Restrainer{1} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips everything if joystick already moved.
   ;
   if _Bit1_Joy0_Restrainer{1} then goto __Skip_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Switches object if joystick is moved up or down.
   ;
   if joy0up then _Bit1_Joy0_Restrainer{1} = 1 : _Bit2_Activate_Jiggle{2} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object - 1 : if _Current_Object = 255 then _Current_Object = 12

   if joy0down then _Bit1_Joy0_Restrainer{1} = 1 : _Bit2_Activate_Jiggle{2} = 1 : _Jiggle_Counter = 0 : _Current_Object = _Current_Object + 1 : if _Current_Object > 12 then _Current_Object = 0

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if joystick not moved left.
   ;
   if !joy0left then goto __Skip_Size_Decrease

   ;```````````````````````````````````````````````````````````````
   ;  Turns on joystick repetition restrainer bit.
   ;
   _Bit1_Joy0_Restrainer{1} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases size of appropriate object.
   ;
   if _Current_Object = _Sprite0 then _Sprite_Size0 = _Sprite_Size0 - 1 : if _Sprite_Size0 = 255 then _Sprite_Size0 = 2
   if _Current_Object = _Sprite1 then _Sprite_Size1 = _Sprite_Size1 - 1 : if _Sprite_Size1 = 255 then _Sprite_Size1 = 2
   if _Current_Object = _Sprite2 then _Sprite_Size2 = _Sprite_Size2 - 1 : if _Sprite_Size2 = 255 then _Sprite_Size2 = 2
   if _Current_Object = _Sprite3 then _Sprite_Size3 = _Sprite_Size3 - 1 : if _Sprite_Size3 = 255 then _Sprite_Size3 = 2
   if _Current_Object = _Sprite4 then _Sprite_Size4 = _Sprite_Size4 - 1 : if _Sprite_Size4 = 255 then _Sprite_Size4 = 2
   if _Current_Object = _Sprite5 then _Sprite_Size5 = _Sprite_Size5 - 1 : if _Sprite_Size5 = 255 then _Sprite_Size5 = 2
   if _Current_Object = _Sprite6 then _Sprite_Size6 = _Sprite_Size6 - 1 : if _Sprite_Size6 = 255 then _Sprite_Size6 = 2
   if _Current_Object = _Sprite7 then _Sprite_Size7 = _Sprite_Size7 - 1 : if _Sprite_Size7 = 255 then _Sprite_Size7 = 2
   if _Current_Object = _Sprite8 then _Sprite_Size8 = _Sprite_Size8 - 1 : if _Sprite_Size8 = 255 then _Sprite_Size8 = 2
   if _Current_Object = _Sprite9 then _Sprite_Size9 = _Sprite_Size9 - 1 : if _Sprite_Size9 = 255 then _Sprite_Size9 = 2
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
   _Bit1_Joy0_Restrainer{1} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Increases size of appropriate object.
   ;
   if _Current_Object = _Sprite0 then _Sprite_Size0 = _Sprite_Size0 + 1 : if _Sprite_Size0 > 2 then _Sprite_Size0 = 0
   if _Current_Object = _Sprite1 then _Sprite_Size1 = _Sprite_Size1 + 1 : if _Sprite_Size1 > 2 then _Sprite_Size1 = 0
   if _Current_Object = _Sprite2 then _Sprite_Size2 = _Sprite_Size2 + 1 : if _Sprite_Size2 > 2 then _Sprite_Size2 = 0
   if _Current_Object = _Sprite3 then _Sprite_Size3 = _Sprite_Size3 + 1 : if _Sprite_Size3 > 2 then _Sprite_Size3 = 0
   if _Current_Object = _Sprite4 then _Sprite_Size4 = _Sprite_Size4 + 1 : if _Sprite_Size4 > 2 then _Sprite_Size4 = 0
   if _Current_Object = _Sprite5 then _Sprite_Size5 = _Sprite_Size5 + 1 : if _Sprite_Size5 > 2 then _Sprite_Size5 = 0
   if _Current_Object = _Sprite6 then _Sprite_Size6 = _Sprite_Size6 + 1 : if _Sprite_Size6 > 2 then _Sprite_Size6 = 0
   if _Current_Object = _Sprite7 then _Sprite_Size7 = _Sprite_Size7 + 1 : if _Sprite_Size7 > 2 then _Sprite_Size7 = 0
   if _Current_Object = _Sprite8 then _Sprite_Size8 = _Sprite_Size8 + 1 : if _Sprite_Size8 > 2 then _Sprite_Size8 = 0
   if _Current_Object = _Sprite9 then _Sprite_Size9 = _Sprite_Size9 + 1 : if _Sprite_Size9 > 2 then _Sprite_Size9 = 0
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
   if joy0up then if player0y >= 1 then player0y = player0y - 1

   if joy0down then if player0y <= 165 then player0y = player0y + 1

   if joy0left then if player0x >= 1 then player0x = player0x - 1 : _Bit3_Flip_p0{3} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size0] : if player0x <= temp5 then player0x = player0x + 1 : _Bit3_Flip_p0{3} = 1

   goto __Skip_Movement

__Skip_Sprite0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite1.
   ;
   if _Current_Object > _Sprite1 then goto __Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite1 if joystick is moved.
   ;
   if joy0up then if player1y >= 1 then player1y = player1y - 1

   if joy0down then if player1y <= 165 then player1y = player1y + 1

   if joy0left then if player1x >= 1 then player1x = player1x - 1 : _NUSIZ1{3} = 0 : _NUSIZ1{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size1] : if player1x <= temp5 then player1x = player1x + 1 : _NUSIZ1{3} = 1 : _NUSIZ1{6} = 1

   goto __Skip_Movement

__Skip_Sprite1_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite2.
   ;
   if _Current_Object > _Sprite2 then goto __Skip_Sprite2_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite2 if joystick is moved.
   ;
   if joy0up then if player2y >= 1 then player2y = player2y - 1

   if joy0down then if player2y <= 165 then player2y = player2y + 1

   if joy0left then if player2x >= 1 then player2x = player2x - 1 : NUSIZ2{3} = 0 : NUSIZ2{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size2] : if player2x <= temp5 then player2x = player2x + 1 : NUSIZ2{3} = 1 : NUSIZ2{6} = 1

   goto __Skip_Movement

__Skip_Sprite2_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite3.
   ;
   if _Current_Object > _Sprite3 then goto __Skip_Sprite3_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite3 if joystick is moved.
   ;
   if joy0up then if player3y >= 1 then player3y = player3y - 1

   if joy0down then if player3y <= 165 then player3y = player3y + 1

   if joy0left then if player3x >= 1 then player3x = player3x - 1 : NUSIZ3{3} = 0 : NUSIZ3{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size3] : if player3x <= temp5 then player3x = player3x + 1 : NUSIZ3{3} = 1 : NUSIZ3{6} = 1

   goto __Skip_Movement

__Skip_Sprite3_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite4.
   ;
   if _Current_Object > _Sprite4 then goto __Skip_Sprite4_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite4 if joystick is moved.
   ;
   if joy0up then if player4y >= 1 then player4y = player4y - 1

   if joy0down then if player4y <= 165 then player4y = player4y + 1

   if joy0left then if player4x >= 1 then player4x = player4x - 1 : NUSIZ4{3} = 0 : NUSIZ4{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size4] : if player4x <= temp5 then player4x = player4x + 1 : NUSIZ4{3} = 1 : NUSIZ4{6} = 1

   goto __Skip_Movement

__Skip_Sprite4_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite5.
   ;
   if _Current_Object > _Sprite5 then goto __Skip_Sprite5_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite5 if joystick is moved.
   ;
   if joy0up then if player5y >= 1 then player5y = player5y - 1

   if joy0down then if player5y <= 165 then player5y = player5y + 1

   if joy0left then if player5x >= 1 then player5x = player5x - 1 : NUSIZ5{3} = 0 : NUSIZ5{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size5] : if player5x <= temp5 then player5x = player5x + 1 : NUSIZ5{3} = 1 : NUSIZ5{6} = 1

   goto __Skip_Movement

__Skip_Sprite5_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite6.
   ;
   if _Current_Object > _Sprite6 then goto __Skip_Sprite6_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite6 if joystick is moved.
   ;
   if joy0up then if player6y >= 1 then player6y = player6y - 1

   if joy0down then if player6y <= 165 then player6y = player6y + 1

   if joy0left then if player6x >= 1 then player6x = player6x - 1 : NUSIZ6{3} = 0 : NUSIZ6{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size6] : if player6x <= temp5 then player6x = player6x + 1 : NUSIZ6{3} = 1 : NUSIZ6{6} = 1

   goto __Skip_Movement

__Skip_Sprite6_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite7.
   ;
   if _Current_Object > _Sprite7 then goto __Skip_Sprite7_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite7 if joystick is moved.
   ;
   if joy0up then if player7y >= 1 then player7y = player7y - 1

   if joy0down then if player7y <= 165 then player7y = player7y + 1

   if joy0left then if player7x >= 1 then player7x = player7x - 1 : NUSIZ7{3} = 0 : NUSIZ7{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size7] : if player7x <= temp5 then player7x = player7x + 1 : NUSIZ7{3} = 1 : NUSIZ7{6} = 1

   goto __Skip_Movement

__Skip_Sprite7_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite8.
   ;
   if _Current_Object > _Sprite8 then goto __Skip_Sprite8_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite8 if joystick is moved.
   ;
   if joy0up then if player8y >= 1 then player8y = player8y - 1

   if joy0down then if player8y <= 165 then player8y = player8y + 1

   if joy0left then if player8x >= 1 then player8x = player8x - 1 : NUSIZ8{3} = 0 : NUSIZ8{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size8] : if player8x <= temp5 then player8x = player8x + 1 : NUSIZ8{3} = 1 : NUSIZ8{6} = 1

   goto __Skip_Movement

__Skip_Sprite8_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not sprite9.
   ;
   if _Current_Object > _Sprite9 then goto __Skip_Sprite9_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves sprite9 if joystick is moved.
   ;
   if joy0up then if player9y >= 1 then player9y = player9y - 1

   if joy0down then if player9y <= 165 then player9y = player9y + 1

   if joy0left then if player9x >= 1 then player9x = player9x - 1 : NUSIZ9{3} = 0 : NUSIZ9{6} = 0

   if joy0right then temp5 = _Data_Width[_Sprite_Size9] : if player9x <= temp5 then player9x = player9x + 1 : NUSIZ9{3} = 1 : NUSIZ9{6} = 1

   goto __Skip_Movement

__Skip_Sprite9_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if current object is not missile0.
   ;
   if _Current_Object <> _Missile0 then goto __Skip_Missile0_Movement

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 if joystick is moved.
   ;
   if joy0up then if missile0y >= 2 then missile0y = missile0y - 1

   if joy0down then temp5 = _Data_M_B_y_Size[_Missile0_Width] : if missile0y <= temp5 then missile0y = missile0y + 1

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
   if joy0up then if missile1y >= 2 then missile1y = missile1y - 1

   if joy0down then temp5 = _Data_M_B_y_Size[_Missile1_Width]: if missile1y <= temp5 then missile1y = missile1y + 1

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
   if joy0up then if bally >= 2 then bally = bally - 1

   if joy0down then temp5 = _Data_M_B_y_Size[_Ball_Width]: if bally <= temp5 then bally = bally + 1

   if joy0left then if ballx >= 2 then ballx = ballx - 1

   if joy0right then temp5 = _Data_M_B_x_Size[_Ball_Width]: if ballx <= temp5 then ballx = ballx + 1

__Skip_Movement



   ;****************************************************************
   ;
   ;  Flips player0 sprite when necessary.
   ;
   if _Bit3_Flip_p0{3} then REFP0 = 8



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
   NUSIZ6 = NUSIZ6 & %11111000 : NUSIZ6 = NUSIZ6 | _Data_Sprite_Size[_Sprite_Size6]
   NUSIZ7 = NUSIZ7 & %11111000 : NUSIZ7 = NUSIZ7 | _Data_Sprite_Size[_Sprite_Size7]
   NUSIZ8 = NUSIZ8 & %11111000 : NUSIZ8 = NUSIZ8 | _Data_Sprite_Size[_Sprite_Size8]
   NUSIZ9 = NUSIZ9 & %11111000 : NUSIZ9 = NUSIZ9 | _Data_Sprite_Size[_Sprite_Size9]



   ;****************************************************************
   ;
   ;  Sets the width and height of missile0.
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

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile0 height.
   ;
   missile0height = _Data_MB_Height[_Missile0_Width]



   ;***************************************************************
   ;
   ;  Sets the width and height of missile1.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Gets the correct missile1 width from data.
   ;
   temp5 = _Data_MB_Width[_Missile1_Width]

   ;```````````````````````````````````````````````````````````````
   ;  Clears missile1 width, but leaves the sprite stuff alone,
   ;  then sets missile1 width.
   ;
   _NUSIZ1 = _NUSIZ1 & %11001111 : _NUSIZ1 = _NUSIZ1 | temp5
   NUSIZ2 = NUSIZ2 & %11001111 : NUSIZ2 = NUSIZ2 | temp5
   NUSIZ3 = NUSIZ3 & %11001111 : NUSIZ3 = NUSIZ3 | temp5
   NUSIZ4 = NUSIZ4 & %11001111 : NUSIZ4 = NUSIZ4 | temp5
   NUSIZ5 = NUSIZ5 & %11001111 : NUSIZ5 = NUSIZ5 | temp5
   NUSIZ6 = NUSIZ6 & %11001111 : NUSIZ6 = NUSIZ6 | temp5
   NUSIZ7 = NUSIZ7 & %11001111 : NUSIZ7 = NUSIZ7 | temp5
   NUSIZ8 = NUSIZ8 & %11001111 : NUSIZ8 = NUSIZ8 | temp5
   NUSIZ9 = NUSIZ9 & %11001111 : NUSIZ9 = NUSIZ9 | temp5

   ;```````````````````````````````````````````````````````````````
   ;  Sets missile1 height.
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
   ;  Sets ball height.
   ;
   ballheight = _Data_MB_Height[_Ball_Width]




   goto __Bank_3 bank3




   ;***************************************************************
   ;
   ;  Sprite size data.
   ;
   data _Data_Sprite_Size
   0, 5, 7
end


   ;***************************************************************
   ;
   ;  Sprite width data.
   ;
   data _Data_Width
   150, 141, 125
end



   ;***************************************************************
   ;
   ;  Missile/ball x size data.
   ;
   data _Data_M_B_x_Size
   158, 157, 155, 151
end



   ;***************************************************************
   ;
   ;  Missile/ball y size data.
   ;
   data _Data_M_B_y_Size
   172, 170, 168, 161
end



   ;***************************************************************
   ;
   ;  Missile/ball height data.
   ;
   data _Data_MB_Height
   2, 4, 8, 14
end



   ;***************************************************************
   ;
   ;  Missile/ball width data.
   ;
   data _Data_MB_Width
   $00, $10, $20, $30
end




   bank 3
   temp1=temp1



__Bank_3



   ;***************************************************************
   ;
   ;  Object jiggle check.
   ;
   ;  Activates object jiggle if new object has been selected.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if object has not been changed.
   ;
   if !_Bit2_Activate_Jiggle{2} then goto __Skip_Object_Jiggle

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if object is jiggling.
   ;
   if _Jiggle_Counter > 0 then goto __Skip_Memory
   if _Current_Object = _Sprite0 then  _Memx = player0x : _Memy = player0y
   if _Current_Object = _Sprite1 then  _Memx = player1x : _Memy = player1y
   if _Current_Object = _Sprite2 then  _Memx = player2x : _Memy = player2y
   if _Current_Object = _Sprite3 then  _Memx = player3x : _Memy = player3y
   if _Current_Object = _Sprite4 then  _Memx = player4x : _Memy = player4y
   if _Current_Object = _Sprite5 then  _Memx = player5x : _Memy = player5y
   if _Current_Object = _Sprite6 then  _Memx = player6x : _Memy = player6y
   if _Current_Object = _Sprite7 then  _Memx = player7x : _Memy = player7y
   if _Current_Object = _Sprite8 then  _Memx = player8x : _Memy = player8y
   if _Current_Object = _Sprite9 then  _Memx = player9x : _Memy = player9y
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
   if _Current_Object = _Sprite6 then temp5 = 255 + (rand&3) : player6x = player6x + temp5: temp5 = 255 + (rand&3) : player6y = player6y + temp5
   if _Current_Object = _Sprite7 then temp5 = 255 + (rand&3) : player7x = player7x + temp5: temp5 = 255 + (rand&3) : player7y = player7y + temp5
   if _Current_Object = _Sprite8 then temp5 = 255 + (rand&3) : player8x = player8x + temp5: temp5 = 255 + (rand&3) : player8y = player8y + temp5
   if _Current_Object = _Sprite9 then temp5 = 255 + (rand&3) : player9x = player9x + temp5: temp5 = 255 + (rand&3) : player9y = player9y + temp5
   if _Current_Object = _Missile0 then temp5 = 255 + (rand&3) : missile0x = missile0x + temp5: temp5 = 255 + (rand&3) : missile0y = missile0y + temp5
   if _Current_Object = _Missile1 then temp5 = 255 + (rand&3) : missile1x = missile1x + temp5: temp5 = 255 + (rand&3) : missile1y = missile1y + temp5
   if _Current_Object = _Ball then temp5 = 255 + (rand&3) : ballx = ballx + temp5: temp5 = 255 + (rand&3) : bally = bally + temp5

   ;```````````````````````````````````````````````````````````````
   ;  Stops jiggling and restores position of the selected object
   ;  if counter limit has been reached.
   ;
   if _Jiggle_Counter < 5 then goto __Skip_Object_Jiggle

   _Bit2_Activate_Jiggle{2} = 0 : _Jiggle_Counter = 0

   if _Current_Object = _Sprite0 then  player0x = _Memx : player0y = _Memy
   if _Current_Object = _Sprite1 then  player1x = _Memx : player1y = _Memy
   if _Current_Object = _Sprite2 then  player2x = _Memx : player2y = _Memy
   if _Current_Object = _Sprite3 then  player3x = _Memx : player3y = _Memy
   if _Current_Object = _Sprite4 then  player4x = _Memx : player4y = _Memy
   if _Current_Object = _Sprite5 then  player5x = _Memx : player5y = _Memy
   if _Current_Object = _Sprite6 then  player6x = _Memx : player6y = _Memy
   if _Current_Object = _Sprite7 then  player7x = _Memx : player7y = _Memy
   if _Current_Object = _Sprite8 then  player8x = _Memx : player8y = _Memy
   if _Current_Object = _Sprite9 then  player9x = _Memx : player9y = _Memy
   if _Current_Object = _Missile0 then missile0x = _Memx : missile0y = _Memy
   if _Current_Object = _Missile1 then missile1x = _Memx : missile1y = _Memy
   if _Current_Object = _Ball then ballx = _Memx : bally = _Memy

__Skip_Object_Jiggle



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;
   if _Current_Object = _Sprite0 then gosub __S0 : temp4 = player0x
   if _Current_Object = _Sprite1 then gosub __S1 : temp4 = player1x
   if _Current_Object = _Sprite2 then gosub __S2 : temp4 = player2x
   if _Current_Object = _Sprite3 then gosub __S3 : temp4 = player3x
   if _Current_Object = _Sprite4 then gosub __S4 : temp4 = player4x
   if _Current_Object = _Sprite5 then gosub __S5 : temp4 = player5x
   if _Current_Object = _Sprite6 then gosub __S6 : temp4 = player6x
   if _Current_Object = _Sprite7 then gosub __S7 : temp4 = player7x
   if _Current_Object = _Sprite8 then gosub __S8 : temp4 = player8x
   if _Current_Object = _Sprite9 then gosub __S9 : temp4 = player9x
   if _Current_Object = _Missile0 then gosub __M0 : temp4 = missile0x
   if _Current_Object = _Missile1 then gosub __M1 : temp4 = missile1x
   if _Current_Object = _Ball then gosub __B : temp4 = ballx

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
   if _Current_Object = _Sprite0 then gosub __S0 : temp4 = player0y
   if _Current_Object = _Sprite1 then gosub __S1 : temp4 = player1y
   if _Current_Object = _Sprite2 then gosub __S2 : temp4 = player2y
   if _Current_Object = _Sprite3 then gosub __S3 : temp4 = player3y
   if _Current_Object = _Sprite4 then gosub __S4 : temp4 = player4y
   if _Current_Object = _Sprite5 then gosub __S5 : temp4 = player5y
   if _Current_Object = _Sprite6 then gosub __S6 : temp4 = player6y
   if _Current_Object = _Sprite7 then gosub __S7 : temp4 = player7y
   if _Current_Object = _Sprite8 then gosub __S8 : temp4 = player8y
   if _Current_Object = _Sprite9 then gosub __S9 : temp4 = player9y
   if _Current_Object = _Missile0 then gosub __M0 : temp4 = missile0y
   if _Current_Object = _Missile1 then gosub __M1 : temp4 = missile1y
   if _Current_Object = _Ball then gosub __B : temp4 = bally

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
   ;  88 rows that are 2 scanlines high.
   ;
   DF6FRACINC = 0 ; Background colors.
   DF4FRACINC = 0 ; Playfield colors.

   DF0FRACINC = 128 ; Column 0.
   DF1FRACINC = 128 ; Column 1.
   DF2FRACINC = 128 ; Column 2.
   DF3FRACINC = 128 ; Column 3.



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Playfield collision with 10 sprites, 2 missiles and ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the column.
   ;
   pfvline 19 0 81 off
   pfvline 23 0 24 off

   ;```````````````````````````````````````````````````````````````
   ;  Checks for playfield collision.
   ;
   if collision(playfield,player0) then pfpixel 19 2 on
   if collision(playfield,missile0) then pfpixel 23 6 on
   if collision(playfield,missile1) then pfpixel 23 15 on
   if collision(playfield,ball) then pfpixel 23 24 on

   if !collision(playfield,player1) then goto __Skip_PF_Collision
   if (temp4 + 5) >= player1y && temp4 <= (player1y + 5) then pfpixel 19 11 on
   if (temp4 + 5) >= player2y && temp4 <= (player2y + 5) then pfpixel 19 20 on
   if (temp4 + 5) >= player3y && temp4 <= (player3y + 5) then pfpixel 19 28 on
   if (temp4 + 5) >= player4y && temp4 <= (player4y + 5) then pfpixel 19 37 on
   if (temp4 + 5) >= player5y && temp4 <= (player5y + 5) then pfpixel 19 46 on
   if (temp4 + 5) >= player6y && temp4 <= (player6y + 5) then pfpixel 19 55 on
   if (temp4 + 5) >= player7y && temp4 <= (player7y + 5) then pfpixel 19 63 on
   if (temp4 + 5) >= player8y && temp4 <= (player8y + 5) then pfpixel 19 72 on
   if (temp4 + 5) >= player9y && temp4 <= (player9y + 5) then pfpixel 19 81 on

__Skip_PF_Collision



   goto __Bank_4 bank4





   ;***************************************************************
   ;
   ;  Score color data starts here.
   ;
__S0
   scorecolors:
   $0E
   $0C
   $0A
   $0A
   $08
   $08
   $06
   $06
end

   return thisbank

__S1
   scorecolors:
   $1E
   $1C
   $1A
   $1A
   $18
   $18
   $16
   $16
end

   return thisbank

__S2
   scorecolors:
   $2E
   $2C
   $2A
   $2A
   $28
   $28
   $26
   $26
end

   return thisbank

__S3
   scorecolors:
   $3E
   $3C
   $3A
   $3A
   $38
   $38
   $36
   $36
end

   return thisbank

__S4
   scorecolors:
   $4E
   $4C
   $4A
   $4A
   $48
   $48
   $46
   $46
end

   return thisbank

__S5
   scorecolors:
   $5E
   $5C
   $5A
   $5A
   $58
   $58
   $56
   $56
end

   return thisbank

__S6
   scorecolors:
   $6E
   $6C
   $6A
   $6A
   $68
   $68
   $66
   $66
end

   return thisbank

__S7
   scorecolors:
   $7E
   $7C
   $7A
   $7A
   $78
   $78
   $76
   $76
end

   return thisbank

__S8
   scorecolors:
   $8E
   $8C
   $8A
   $8A
   $88
   $88
   $86
   $86
end

   return thisbank

__S9
   scorecolors:
   $9E
   $9C
   $9A
   $9A
   $98
   $98
   $96
   $96
end

   return thisbank

__M0
   scorecolors:
   $FE
   $FC
   $FA
   $FA
   $F8
   $F8
   $F6
   $F6
end

   return thisbank

__M1
   scorecolors:
   $AE
   $AC
   $AA
   $AA
   $A8
   $A8
   $A6
   $A6
end

   return thisbank


__B
   scorecolors:
   $CE
   $CC
   $CA
   $CA
   $C8
   $C8
   $C6
   $C6
end

   return thisbank




   bank 4
   temp1=temp1




__Bank_4



   ;***************************************************************
   ;
   ;  Player0 collision with other 9 sprites
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the column.
   ;
   pfvline 9 0 81 off

   ;```````````````````````````````````````````````````````````````
   ;  Checks for player0 collision with other 9 sprites.
   ; 10 is used for the y check because these sprites are 11
   ; pixels high (11 - 1 = 10). For example, if your sprite is
   ; 40 pixels tall, use 39 instead of 10.
   ;
   if !collision(player0,player1) then goto __Skip_p0_Collision
   temp5 = _Data_Sprite_Width[_Sprite_Size0]
   if (player0y + 10) >= player1y && player0y <= (player1y + 10) && (player0x + temp5) >= player1x && player0x <= (player1x + 7) then pfpixel 9 11 on
   if (player0y + 10) >= player2y && player0y <= (player2y + 10) && (player0x + temp5) >= player2x && player0x <= (player2x + 7) then pfpixel 9 20 on
   if (player0y + 10) >= player3y && player0y <= (player3y + 10) && (player0x + temp5) >= player3x && player0x <= (player3x + 7) then pfpixel 9 28 on
   if (player0y + 10) >= player4y && player0y <= (player4y + 10) && (player0x + temp5) >= player4x && player0x <= (player4x + 7) then pfpixel 9 37 on
   if (player0y + 10) >= player5y && player0y <= (player5y + 10) && (player0x + temp5) >= player5x && player0x <= (player5x + 7) then pfpixel 9 46 on
   if (player0y + 10) >= player6y && player0y <= (player6y + 10) && (player0x + temp5) >= player6x && player0x <= (player6x + 7) then pfpixel 9 55 on
   if (player0y + 10) >= player7y && player0y <= (player7y + 10) && (player0x + temp5) >= player7x && player0x <= (player7x + 7) then pfpixel 9 63 on
   if (player0y + 10) >= player8y && player0y <= (player8y + 10) && (player0x + temp5) >= player8x && player0x <= (player8x + 7) then pfpixel 9 72 on
   if (player0y + 10) >= player9y && player0y <= (player9y + 10) && (player0x + temp5) >= player9x && player0x <= (player9x + 7) then pfpixel 9 81 on

__Skip_p0_Collision



   ;***************************************************************
   ;
   ;  Missile0 collision with 10 sprites, 1 missile and ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the columns.
   ;
   pfvline 8 0 81 off
   pfvline 29 0 24 off

   ;```````````````````````````````````````````````````````````````
   ;  Checks for missile0 collision.
   ;
   if collision(missile0,player0) then pfpixel 8 2 on
   if collision(missile0,missile1) then pfpixel 29 15 on
   if collision(missile0,ball) then pfpixel 29 24 on

   if !collision(missile0,player1) then goto __Skip_M0_Collision
   temp5 = _Data_Missile_Size[_Missile0_Width]
   if (missile0y + missile0height) >= player1y && missile0y <= (player1y + 10) && (missile0x + temp5) >= player1x && missile0x <= (player1x + 8) then pfpixel 8 11 on
   if (missile0y + missile0height) >= player2y && missile0y <= (player2y + 10) && (missile0x + temp5) >= player2x && missile0x <= (player2x + 8) then pfpixel 8 20 on
   if (missile0y + missile0height) >= player3y && missile0y <= (player3y + 10) && (missile0x + temp5) >= player3x && missile0x <= (player3x + 8) then pfpixel 8 28 on
   if (missile0y + missile0height) >= player4y && missile0y <= (player4y + 10) && (missile0x + temp5) >= player4x && missile0x <= (player4x + 8) then pfpixel 8 37 on
   if (missile0y + missile0height) >= player5y && missile0y <= (player5y + 10) && (missile0x + temp5) >= player5x && missile0x <= (player5x + 8) then pfpixel 8 46 on
   if (missile0y + missile0height) >= player6y && missile0y <= (player6y + 10) && (missile0x + temp5) >= player6x && missile0x <= (player6x + 8) then pfpixel 8 55 on
   if (missile0y + missile0height) >= player7y && missile0y <= (player7y + 10) && (missile0x + temp5) >= player7x && missile0x <= (player7x + 8) then pfpixel 8 63 on
   if (missile0y + missile0height) >= player8y && missile0y <= (player8y + 10) && (missile0x + temp5) >= player8x && missile0x <= (player8x + 8) then pfpixel 8 72 on
   if (missile0y + missile0height) >= player9y && missile0y <= (player9y + 10) && (missile0x + temp5) >= player9x && missile0x <= (player9x + 8) then pfpixel 8 81 on

__Skip_M0_Collision



   ;***************************************************************
   ;
   ;  Missile1 collision with 10 sprites, 1 missile and ball.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the columns.
   ;
   pfvline 7 0 81 off
   pfvline 30 0 24 off

   ;```````````````````````````````````````````````````````````````
   ;  Checks for missile1 collision.
   ;
   if collision(missile1,player0) then pfpixel 7 2 on
   if collision(missile1,missile0) then pfpixel 30 6 on
   if collision(missile1,ball) then pfpixel 30 24 on

   if !collision(missile1,player1) then goto __Skip_M1_Collision
   temp5 = _Data_Missile_Size[_Missile1_Width]
   if (missile1y + missile1height) >= player1y && missile1y <= (player1y + 10) && (missile1x + temp5) >= player1x && missile1x <= (player1x + 8) then pfpixel 7 11 on
   if (missile1y + missile1height) >= player2y && missile1y <= (player2y + 10) && (missile1x + temp5) >= player2x && missile1x <= (player2x + 8) then pfpixel 7 20 on
   if (missile1y + missile1height) >= player3y && missile1y <= (player3y + 10) && (missile1x + temp5) >= player3x && missile1x <= (player3x + 8) then pfpixel 7 28 on
   if (missile1y + missile1height) >= player4y && missile1y <= (player4y + 10) && (missile1x + temp5) >= player4x && missile1x <= (player4x + 8) then pfpixel 7 37 on
   if (missile1y + missile1height) >= player5y && missile1y <= (player5y + 10) && (missile1x + temp5) >= player5x && missile1x <= (player5x + 8) then pfpixel 7 46 on
   if (missile1y + missile1height) >= player6y && missile1y <= (player6y + 10) && (missile1x + temp5) >= player6x && missile1x <= (player6x + 8) then pfpixel 7 55 on
   if (missile1y + missile1height) >= player7y && missile1y <= (player7y + 10) && (missile1x + temp5) >= player7x && missile1x <= (player7x + 8) then pfpixel 7 63 on
   if (missile1y + missile1height) >= player8y && missile1y <= (player8y + 10) && (missile1x + temp5) >= player8x && missile1x <= (player8x + 8) then pfpixel 7 72 on
   if (missile1y + missile1height) >= player9y && missile1y <= (player9y + 10) && (missile1x + temp5) >= player9x && missile1x <= (player9x + 8) then pfpixel 7 81 on

__Skip_M1_Collision



   ;***************************************************************
   ;
   ;  Ball collision with 10 sprites and 2 missiles.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the columns.
   ;
   pfvline 6 0 81 off
   pfvline 31 0 15 off

   ;```````````````````````````````````````````````````````````````
   ;  Checks for ball collision.
   ;
   if collision(ball,player0) then pfpixel 6 2 on
   if collision(ball,missile0) then pfpixel 31 6 on
   if collision(ball,missile1) then pfpixel 31 15 on

   if !collision(ball,player1) then goto __Skip_ball_Collision
   temp5 = _Data_Missile_Size[_Ball_Width]
   if (bally + ballheight) >= player1y && bally <= (player1y + 10) && (ballx + temp5) >= player1x && ballx <= (player1x + 8) then pfpixel 6 11 on
   if (bally + ballheight) >= player2y && bally <= (player2y + 10) && (ballx + temp5) >= player2x && ballx <= (player2x + 8) then pfpixel 6 20 on
   if (bally + ballheight) >= player3y && bally <= (player3y + 10) && (ballx + temp5) >= player3x && ballx <= (player3x + 8) then pfpixel 6 28 on
   if (bally + ballheight) >= player4y && bally <= (player4y + 10) && (ballx + temp5) >= player4x && ballx <= (player4x + 8) then pfpixel 6 37 on
   if (bally + ballheight) >= player5y && bally <= (player5y + 10) && (ballx + temp5) >= player5x && ballx <= (player5x + 8) then pfpixel 6 46 on
   if (bally + ballheight) >= player6y && bally <= (player6y + 10) && (ballx + temp5) >= player6x && ballx <= (player6x + 8) then pfpixel 6 55 on
   if (bally + ballheight) >= player7y && bally <= (player7y + 10) && (ballx + temp5) >= player7x && ballx <= (player7x + 8) then pfpixel 6 63 on
   if (bally + ballheight) >= player8y && bally <= (player8y + 10) && (ballx + temp5) >= player8x && ballx <= (player8x + 8) then pfpixel 6 72 on
   if (bally + ballheight) >= player9y && bally <= (player9y + 10) && (ballx + temp5) >= player9x && ballx <= (player9x + 8) then pfpixel 6 81 on

__Skip_ball_Collision



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
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop bank2

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if the reset switch hasn't
   ;  been released after being pressed.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop bank2

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart bank2




   ;***************************************************************
   ;
   ;  Missile size data.
   ;
   data _Data_Missile_Size
   0, 0, 2, 4, 8
end



   ;***************************************************************
   ;
   ;  Sprite width data.
   ;
   data _Data_Sprite_Width
   8, 16, 32
end




   bank 5
   temp1=temp1




   bank 6
   temp1=temp1