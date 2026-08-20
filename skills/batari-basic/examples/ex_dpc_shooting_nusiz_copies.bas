   ;***************************************************************
   ;
   ;  Shooting NUSIZ copies (DPC+)
   ;
   ;  Example program by iesposta. Code and graphics adapted by
   ;  Duane Alan Hahn (Random Terrain) using hints, tips, code
   ;  snippets, and more from AtariAge members such as batari,
   ;  SeaGtGruff, RevEng, Robert M, Nukey Shay, Atarius Maximus,
   ;  jrok, supercat, GroovyBee, and bogax.
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
   ;  Removes overhead from data tables, saving space. Doing so
   ;  will limit them to outside of code. That is, you can no
   ;  longer place data tables inline with code, or your program
   ;  may crash!
   ;
   set optimization noinlinedata



   ;****************************************************************
   ;
   ;  Will place calls to the random number generator inline with
   ;  your code. This is particularly useful for bankswitched games,
   ;  where a call to the random number generator would normally
   ;  have to switch banks, so this will speed up your code with a
   ;  minimal increase in code size.
   ;
   set optimization inlinerand



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
   ;  The following 7 must be sequential for _VSPointer to work.
   ;
   dim _EnemyP2 = a
   dim _EnemyP3 = b
   dim _EnemyP4 = c
   dim _EnemyP5 = d
   dim _EnemyP6 = e
   dim _EnemyP7 = f
   dim _EnemyP8 = g

   ;```````````````````````````````````````````````````````````````
   ;  Virtual sprite pointer.
   ;
   dim _VSPointer = h

   ;```````````````````````````````````````````````````````````````
   ;  _Master_Counter can be used for many things, but it is 
   ;  really useful for animating sprite frames when used
   ;  with _Frame_Counter.
   ;
   dim _Master_Counter = i
   dim _Frame_Counter = j

   ;```````````````````````````````````````````````````````````````
   ;  Enemy data counters.
   ;
   dim _Enemy_D_Counter_y = k
   dim _Enemy_D_Counter_x = l

   ;```````````````````````````````````````````````````````````````
   ;  Destroyed enemy counter.
   ;
   dim _Dead_Enemy_Counter = m

   ;```````````````````````````````````````````````````````````````
   ;  Channel 0 sound variables.
   ;
   dim _Ch0_Sound = n
   dim _Ch0_Duration = o
   dim _Ch0_Counter = p

   ;```````````````````````````````````````````````````````````````
   ;  Channel 1 sound variables. Only used for background "music,"
   ;  so we can save a variable here by leaving out _Ch1_Sound.
   ;
   dim _Ch1_Duration = q
   dim _Ch1_Counter = r

   ;```````````````````````````````````````````````````````````````
   ;  In charge of how hard the game is. Controls the enemy
   ;  movement data that is used and how often shots are dropped.
   ;
   dim _Wave = s

   ;```````````````````````````````````````````````````````````````
   ;  Keeps track of player damage.
   ;
   dim _Damage_Counter = t

   ;```````````````````````````````````````````````````````````````
   ;  Fixes it so the player can't restart after death until 2
   ;  seconds has gone by.
   ;
   dim _Game_Over_Counter = u

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose variable for temporary jobs.
   ;
   dim _MyTemp01 = v

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _BitOp_All_Purpose_01 = y
   dim _Bit0_Reset_Restrainer = y
   dim _Bit1_FireB_Restrainer = y
   dim _Bit2_Game_Over = y
   dim _Bit3_Swap_Scores = y
   dim _Bit7_Last_Life = y

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _BitOp_All_Purpose_02 = z
   dim _Bit0_Enemy_Bottom = z



   ;****************************************************************
   ;
   ;  Built-in custom score font.
   ;
   const font = retroputer



   ;****************************************************************
   ;
   ;  Height of the enemy sprites minus one. Or just ignore row 0 in
   ;  the sprite editor and the last row number is the one you use.
   ;
   const _c_SpriteHeight = 7



   ;***************************************************************
   ;
   ;  Constants for channel 0 sound effects (_Ch0_Sound).
   ;  [The c stands for constant.]
   ;
   const _c_Enemy_Boom = 1
   const _c_Player_Missile = 2
   const _c_Player_Hurt = 3
   const _c_Player_Destroyed = 4



   ;****************************************************************
   ;
   ;  Jumps to bank 6 to set up the program.
   ;
   goto __Start_Restart bank6



   ;****************************************************************
   ;
   ;  Score background color.
   ;
   asm
minikernel
   ldx #$94
   stx COLUBK
   rts
end



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   bank 2
   temp1 = temp1
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



__Bank_2



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Main Loop
   ;
__Main_Loop


   
   ;***************************************************************
   ;
   ;  Animation counters.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Increments _Master_Counter.
   ;
   _Master_Counter = _Master_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if _Master_Counter is less than 8.
   ;
   if _Master_Counter < 8 then __Skip_Counters

   ;```````````````````````````````````````````````````````````````
   ;  Increments _Frame_Counter and clears _Master_Counter.
   ;
   _Frame_Counter = _Frame_Counter + 1 : _Master_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Clears _Frame_Counter if it is greater than 5.
   ;
   if _Frame_Counter > 5 then _Frame_Counter = 0

__Skip_Counters

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to enemy animation frames and player0 color cycling.
   ;
   on _Frame_Counter goto __1A_Enemy __1B_Enemy __1C_Enemy __1D_Enemy __1E_Enemy __1F_Enemy

__End_Enemy_Animation



   ;***************************************************************
   ;
   ;  Enemy movement.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Gets a number between 0 and 15 from _Master_Counter.
   ;
   temp6 = _Master_Counter & $0F

   ;```````````````````````````````````````````````````````````````
   ;  Increments enemy x and y data counters if the number is 0.
   ;
   if !temp6 then _Enemy_D_Counter_y = _Enemy_D_Counter_y + 1 : _Enemy_D_Counter_x = _Enemy_D_Counter_x + 1

   ;```````````````````````````````````````````````````````````````
   ;  Gets enemy Y movement data.
   ;
   temp6 = _D_EnemyY[_Enemy_D_Counter_y]

   ;```````````````````````````````````````````````````````````````
   ;  Starts the Y data over if the number $80 is read.
   ;
   if temp6 = $80 then _Enemy_D_Counter_y = 11 : temp6 = 0

   ;```````````````````````````````````````````````````````````````
   ;  Gets enemy X movement data.
   ;
   if _Wave = 10 then temp5 = _D_EnemyX_W1[_Enemy_D_Counter_x]
   if _Wave = 13 then temp5 = _D_EnemyX_W2[_Enemy_D_Counter_x]
   if _Wave = 16 then temp5 = _D_EnemyX_W3[_Enemy_D_Counter_x]
   if _Wave = 19 then temp5 = _D_EnemyX_W4[_Enemy_D_Counter_x]
   if _Wave = 22 then temp5 = _D_EnemyX_W5[_Enemy_D_Counter_x]
   if _Wave = 25 then temp5 = _D_EnemyX_W6[_Enemy_D_Counter_x]
   if _Wave = 28 || _Wave = 31 then temp5 = _D_EnemyX_W7[_Enemy_D_Counter_x]

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the 11th position of the X data if the number $80
   ;  is read.
   ;
   if temp5 = $80 then _Enemy_D_Counter_x = 0 : temp5 = 255

__Skip_Read

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Moves any enemy sprite rows that haven't been destroyed.
   ;
   for _MyTemp01 = 6 to 0 step -1

   ;```````````````````````````````````````````````````````````````
   ;  Skips all movement if row of enemies has been destroyed.
   ;
   if !_EnemyP2[_MyTemp01] then goto __Skip_Move

   ;```````````````````````````````````````````````````````````````
   ;  Gets the next Y position.
   ;
   temp3 = player2y[_MyTemp01]+temp6

   ;```````````````````````````````````````````````````````````````
   ;  Limits how low the first enemy row can go. The bit keeps any
   ;  rows above from moving down too.
   ;
   if temp3 > 140 && temp3 < 180 then _Bit0_Enemy_Bottom{0} = 1

   ;```````````````````````````````````````````````````````````````
   ;  If the bottom row hit the limit, all rows that are left move
   ;  up and the Y data is ignored.
   ;
   if _Bit0_Enemy_Bottom{0} then temp3 = temp3 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Moves the row up or down or neither.
   ;
   player2y[_MyTemp01] = temp3

__Skip_Move_Y

   ;```````````````````````````````````````````````````````````````
   ;  Moves the row left or right or neither.
   ;
   player2x[_MyTemp01] = player2x[_MyTemp01]+temp5

__Skip_Move

   next

   ;```````````````````````````````````````````````````````````````
   ;  Clears the bottom limit bit.
   ;
   _Bit0_Enemy_Bottom{0} = 0



   ;***************************************************************
   ;
   ;  Missile0 check and fire button check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Jumps to fire button check if missile0 is off the screen.
   ;
   if missile0y > 240 && missile0y < 250 then goto __FireB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Moves missile0 and skips fire button check.
   ;
   missile0y = missile0y - 5 : goto __Skip_FireB

__FireB_Check

   ;```````````````````````````````````````````````````````````````
   ;  Skips subsection if game is over.
   ;
   if _Bit2_Game_Over{2} then goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Checks fire button since missile0 is off the screen.
   ;  Skips this subsection if fire button is not pressed.
   ;
   if !joy0fire then _Bit1_FireB_Restrainer{1} = 0 : goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if fire button hasn't been released
   ;  since beginning of game.
   ;
   if _Bit1_FireB_Restrainer{1} then goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Starts the firing of missile0.
   ;
   missile0y = player0y - 4 : missile0x = player0x + 5

   ;```````````````````````````````````````````````````````````````
   ;  Won't let the missile shooting sound happen if an enemy boom
   ;  explosion sound is happening (unless enough of the boom
   ;  sound has played).
   ;
   if _Ch0_Sound = _c_Enemy_Boom && _Ch0_Counter < 20 then goto __Skip_FireB

   ;```````````````````````````````````````````````````````````````
   ;  Starts the missile shooting sound effect.
   ;
   _Ch0_Sound = _c_Player_Missile : _Ch0_Duration = 1 : _Ch0_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Randomly selects from 2 other missile shooting sound
   ;  effects. Keeps it from getting monotonous.
   ;
   temp5 = rand : if temp5 > 128 then _Ch0_Counter = 57
   temp5 = rand : if temp5 > 128 then _Ch0_Counter = 114

__Skip_FireB



   ;***************************************************************
   ;
   ;  Joystick movement (left/right).
   ;
   if joy0right && player0x < 136 then player0x = player0x + 1
   if joy0left && player0x > 15 then player0x = player0x - 1



   ;***************************************************************
   ;
   ;  Firing enemies. (S7 = which of the 7 sprites is Shooting)
   ;
   ;  An enemy ship randomly fires a playfield pixel.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Gets a randomish number between 0 and 7. This subsection is
   ;  skipped if the number is 7.
   ;
   temp6 = (rand&7) : if temp6 = 7 then goto __Skip_Enemy_Firing

   ;```````````````````````````````````````````````````````````````
   ;  There is a small chance that an enemy will fire based on
   ;  the wave. The higher the wave, the more the enemies will
   ;  shoot.
   ;
   temp5 = rand : if temp5 > _Wave then goto __Skip_Enemy_Firing

   ;```````````````````````````````````````````````````````````````
   ;  Converts sprite x and y postions to playfield coordinates.
   ;
   temp4 = (player2x[temp6]-12)/4 : temp5 = player2y[temp6]+3 

   ;```````````````````````````````````````````````````````````````
   ;  Skips to the odd subsection if the random enemy is odd. The
   ;  odd numbered enemies can have 3 copies.
   ;
   if temp6{0} then goto __Odd_Enemy_Shooting

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Even jump subsection for rows that have 2 enemy sprites.
   ;
   temp1 = _EnemyP2[temp6]

   on temp1 goto __Skip_Enemy_Firing __S73C00 __S7_2_Medium_Copies

   goto __Skip_Enemy_Firing

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Odd jump subsection for rows that have 3 enemy sprites.
   ;
__Odd_Enemy_Shooting

   temp2 = _EnemyP2[temp6]

   on temp2 goto __Skip_Enemy_Firing __S73C00 __S73C00 __S7_2_Medium_Copies __S73C00 __S7_2_Wide_Copies __S7_2_Medium_Copies __S7_3_Copies

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to 1 of 3 medium copies based on location of player.
   ;
__S7_3_Copies

   ;```````````````````````````````````````````````````````````````
   ;  Shoots from the enemy ship in the middle if the player is in
   ;  the middle 3rd of the screen.
   ;
   temp3 = 1

   ;```````````````````````````````````````````````````````````````
   ;  Shoots from the enemy ship on the left if the player is on
   ;  the left 3rd of the screen.
   ;
   if player0x < 40 then temp3 = 0

   ;```````````````````````````````````````````````````````````````
   ;  Shoots from the enemy ship on the right if the player is on
   ;  the right 3rd of the screen.
   ;
   if player0x > 96 then temp3 = 2

   ;```````````````````````````````````````````````````````````````
   ;  This does the actual jumping.
   ;
   on temp3 goto __S73C00 __S73C01 __S73C02

__S73C00

   pfpixel temp4 temp5 on : goto __Skip_Enemy_Firing

__S73C01

   temp3 = temp4+8 : pfpixel temp3 temp5 on : goto __Skip_Enemy_Firing

__S73C02

   temp3 = temp4+16 : pfpixel temp3 temp5 on : goto __Skip_Enemy_Firing

   ;```````````````````````````````````````````````````````````````
   ;  Randomly jumps to 1 of 2 wide copies.
   ;
__S7_2_Wide_Copies

   temp3 = (rand&1)

   on temp3 goto __S73C00 __S73C02

   ;```````````````````````````````````````````````````````````````
   ;  Randomly jumps to 1 of 2 medium copies.
   ;
__S7_2_Medium_Copies

   temp3 = (rand&1)

   on temp3 goto __S73C00 __S73C01

__Skip_Enemy_Firing



   ;***************************************************************
   ;
   ;  Scrolls the playfield pixels down the screen.
   ;
   pfscroll 255



   ;***************************************************************
   ;
   ;  Doubles width of player's health indicator.
   ;
   rem _NUSIZ1 = $05



   ;***************************************************************
   ;
   ;  176 rows that are 1 scanline high except the top and bottom
   ;  rows (which seem to be 2 scanlines high). All of the colors
   ;  seem to be 2 scanlines high.
   ;
   DF6FRACINC = 0 : DF4FRACINC = 0
   DF0FRACINC = 255 : DF1FRACINC = 255 : DF2FRACINC = 255 : DF3FRACINC = 255



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Player collision check.
   ;   
   ;```````````````````````````````````````````````````````````````
   ;  Checks for player0/playfield collision.
   ;
   if !collision(player0,playfield) then goto __Skip_Player_Collision

   ;```````````````````````````````````````````````````````````````
   ;  Skips subsection if game is over.
   ;
   if _Bit2_Game_Over{2} then goto __Skip_Player_Collision

   ;```````````````````````````````````````````````````````````````
   ;  Starts the player hurt sound effect.
   ;
   _Ch0_Sound = _c_Player_Hurt : _Ch0_Duration = 1 : _Ch0_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  This controls the damage the player receives.
   ;
   if _Damage_Counter > 1 then _Damage_Counter = _Damage_Counter - 2

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to the damage images and colors.
   ;
   if _Damage_Counter = 223 then goto __Player_Damage01
   if _Damage_Counter = 193 then goto __Player_Damage02
   if _Damage_Counter = 163 then goto __Player_Damage03
   if _Damage_Counter = 131 then goto __Player_Damage04
   if _Damage_Counter = 101 then goto __Player_Damage05
   if _Damage_Counter = 69 then goto __Player_Damage06
   if _Damage_Counter = 37 then goto __Player_Damage07
   if _Damage_Counter = 7 then goto __Player_Damage08

   ;```````````````````````````````````````````````````````````````
   ;  Skips ahead if the player's ship isn't destroyed.
   ;
   if _Damage_Counter <> 1 then goto __Skip_Player_Collision

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the game over bit, fire button restrainer bit, and
   ;  the sound effect. Also gets rid of the health indicator.
   ;
   _Bit2_Game_Over{2} = 1 : _Bit1_FireB_Restrainer{1} = 1  : _Ch0_Duration = 1
   _Damage_Counter = 0 : _Ch0_Counter = 0
   _Ch0_Sound = _c_Player_Destroyed : player1y = 241

__Skip_Player_Collision



   ;***************************************************************
   ;
   ;  Game over.
   ;   
   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if the game isn't over.
   ;
   if !_Bit2_Game_Over{2} then goto __Skip_Game_over

   ;```````````````````````````````````````````````````````````````
   ;  Erases the player's ship.
   ;
   if player0height > 0 then player0height = player0height - 1

   ;```````````````````````````````````````````````````````````````
   ;  Increments the game over counter.
   ;
   _Game_Over_Counter = _Game_Over_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if 2 seconds haven't gone by.
   ;
   if _Game_Over_Counter < 120 then goto __Skip_Game_over

   ;```````````````````````````````````````````````````````````````
   ;  Keeps the game over counter from rolling over.
   ;
   _Game_Over_Counter = 130

   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if fire button is not pressed.
   ;
   if !joy0fire then _Bit1_FireB_Restrainer{1} = 0 : goto __Skip_Game_over

   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if fire button hasn't been released
   ;  since the game ended.
   ;
   if _Bit1_FireB_Restrainer{1} then goto __Skip_Game_over

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the game.
   ;
   goto __Start_Restart bank6

__Skip_Game_over



   ;***************************************************************
   ;
   ;  Missile0 collision check. (W7 = Which of the 7 sprites)
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this subsection if there is no collision between
   ;  missile0 and an enemy sprite.
   ;
   if !collision(missile0,player1) then goto __Skip_Missile0_Collision

   ;```````````````````````````````````````````````````````````````
   ;  Checks for missile0 collision with other 7 sprites.
   ;  7 is used for the y check because these sprites are 8
   ;  pixels high (8 - 1 = 7). For example, if your sprite is
   ;  40 pixels tall, use 39 instead of 10. This finds the row that
   ;  was hit.
   ;
   if (missile0y + missile0height) >= player2y && missile0y <= (player2y + _c_SpriteHeight) then _VSPointer = 0 : goto __Which_1_of_2_Copies
   if (missile0y + missile0height) >= player3y && missile0y <= (player3y + _c_SpriteHeight) then _VSPointer = 1 : goto __Which_1_of_3_Copies
   if (missile0y + missile0height) >= player4y && missile0y <= (player4y + _c_SpriteHeight) then _VSPointer = 2 : goto __Which_1_of_2_Copies
   if (missile0y + missile0height) >= player5y && missile0y <= (player5y + _c_SpriteHeight) then _VSPointer = 3 : goto __Which_1_of_3_Copies
   if (missile0y + missile0height) >= player6y && missile0y <= (player6y + _c_SpriteHeight) then _VSPointer = 4 : goto __Which_1_of_2_Copies
   if (missile0y + missile0height) >= player7y && missile0y <= (player7y + _c_SpriteHeight) then _VSPointer = 5 : goto __Which_1_of_3_Copies
   if (missile0y + missile0height) >= player8y && missile0y <= (player8y + _c_SpriteHeight) then _VSPointer = 6 : goto __Which_1_of_2_Copies

   goto __Skip_Missile0_Collision

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Jump subsection for rows that have 2 enemy sprites.
   ;
__Which_1_of_2_Copies

   temp1 = _EnemyP2[_VSPointer]

   on temp1 goto __Reset_Missile0 __W7_1_Copy __W7_2_Medium_Copies 

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Jump subsection for rows that have 3 enemy sprites.
   ;
__Which_1_of_3_Copies

   temp2 = _EnemyP2[_VSPointer]

   on temp2 goto __Skip_Missile0_Collision __W7_1_Copy __W7_1_Copy __W7_2_Medium_Copies __W7_1_Copy __W7_2_Wide_Copies __W7_2_Medium_Copies __W7_3_Copies

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Collision with 1 of 3 medium copies.
   ;
__W7_3_Copies

   ;```````````````````````````````````````````````````````````````
   ;  If sprite on the left was hit, switches to 2 medium copies
   ;  and moves copies to the right side.
   ;
   if missile0x <= player2x[_VSPointer]+9 then NUSIZ2[_VSPointer] = $02 : player2x[_VSPointer] = player2x[_VSPointer]+32 : _EnemyP2[_VSPointer] = 3 : goto __Reset_Missile0

   ;```````````````````````````````````````````````````````````````
   ;  If sprite in the middle was hit, switches to 2 wide copies.
   ;
   if missile0x >= player2x[_VSPointer]+33 && missile0x <= player2x[_VSPointer]+41 then NUSIZ2[_VSPointer] = $04 : _EnemyP2[_VSPointer] = 5 : goto __Reset_Missile0

   ;```````````````````````````````````````````````````````````````
   ;  If sprite on the right was hit, switches to 2 medium copies
   ;  and moves copies to the left side.
   ;
   if missile0x >= player2x[_VSPointer]+65 && missile0x <= player2x[_VSPointer]+73 then NUSIZ2[_VSPointer] = $02 : _EnemyP2[_VSPointer] = 3 : goto __Reset_Missile0

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Collision with 1 copy.
   ;
__W7_1_Copy

   ;```````````````````````````````````````````````````````````````
   ;  Last copy on current row is removed and missile0 is reset.
   ;
   if missile0x <= player2x[_VSPointer]+9 then player2y[_VSPointer] = 200 : _EnemyP2[_VSPointer] = 0 : goto __Reset_Missile0

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Collision with 1 of 2 wide copies.
   ;
__W7_2_Wide_Copies

   ;```````````````````````````````````````````````````````````````
   ;  If sprite on the left was hit, switches to 1 copy and moves
   ;  it to the right side.
   ;
   if missile0x <= player2x[_VSPointer]+9 then player2x[_VSPointer] = player2x[_VSPointer]+64 : goto __W7_1_Copy_Remaining

   ;```````````````````````````````````````````````````````````````
   ;  If sprite on the right was hit, switches to 1 copy and moves
   ;  it to the left side.
   ;
   if missile0x >= player2x[_VSPointer]+65 && missile0x <= player2x[_VSPointer]+73 then goto __W7_1_Copy_Remaining

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Collision with 1 of 2 medium copies.
   ;
__W7_2_Medium_Copies

   ;```````````````````````````````````````````````````````````````
   ;  If sprite to the left was hit, switches to 1 copy and moves
   ;  it to the right.
   ;
   if missile0x <= player2x[_VSPointer]+9 then player2x[_VSPointer] = player2x[_VSPointer]+32 : goto __W7_1_Copy_Remaining

   ;```````````````````````````````````````````````````````````````
   ;  If sprite to the right was hit, switches to 1 copy and moves
   ;  it to the left.
   ;
   if missile0x >= player2x[_VSPointer]+33 && missile0x <= player2x[_VSPointer]+41 then goto __W7_1_Copy_Remaining

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Only 1 copy of enemy sprite remaining on current row.
   ;
__W7_1_Copy_Remaining

   NUSIZ2[_VSPointer] = $00 : _EnemyP2[_VSPointer] = 1 : goto __Reset_Missile0

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Missile0 reset after enemy death.
   ;
__Reset_Missile0

   ;```````````````````````````````````````````````````````````````
   ;  Removes missile0 from the screen.
   ;
   missile0y = 241

   ;```````````````````````````````````````````````````````````````
   ;  Clears the fire button restrainer bit so the player can fire. 
   ;
   _Bit1_FireB_Restrainer{1} = 0

   ;```````````````````````````````````````````````````````````````
   ;  Adds to the score based on the wave number.
   ;
   if _Wave = 10 then score = score + 10
   if _Wave = 13 then score = score + 20
   if _Wave = 16 then score = score + 30
   if _Wave = 19 then score = score + 40
   if _Wave = 22 then score = score + 50
   if _Wave = 25 then score = score + 60
   if _Wave = 28 then score = score + 70
   if _Wave = 31 then score = score + 100

   ;```````````````````````````````````````````````````````````````
   ;  Adds to the dead enemy counter.
   ;
   _Dead_Enemy_Counter = _Dead_Enemy_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips sound if game is over.
   ;
   if _Bit2_Game_Over{2} then goto __Skip_Missile0_Collision

   ;```````````````````````````````````````````````````````````````
   ;  Starts the enemy death boom sound effect.
   ;
   _Ch0_Sound = _c_Enemy_Boom : _Ch0_Duration = 1 : _Ch0_Counter = 0

__Skip_Missile0_Collision



   ;****************************************************************
   ;
   ;  Starts a new wave if last enemy has been destroyed.
   ;
   if _Dead_Enemy_Counter > 16 then if _Ch0_Sound <> _c_Enemy_Boom then goto __Enemy_Reset bank6



   ;****************************************************************
   ;
   ;  Erases a line so the enemy shots won't keep coming back on.
   ;
   pfhline 0 173 31 off



   ;***************************************************************
   ;
   ;  Code continues in next bank.
   ;
   goto __Code_Section_2 bank3



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  End of first section of main loop.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````




   ;***************************************************************
   ;***************************************************************
   ;
   ;  Enemy animation data.
   ;
__1A_Enemy
   player2-8:
   %00011000
   %00111100
   %00111100
   %00111110
   %00111110
   %10110111
   %11111111
   %11001101
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $98
   $96
   $98
   $96
   $94
   $96
   $94
end


   goto __End_Enemy_Animation
   
__1B_Enemy
   player2-8:
   %00001000
   %00111100
   %00111100
   %01011110
   %01011110
   %11011011
   %11111111
   %10100111
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $16
   $9A
   $98
   $96
   $98
   $96
   $94
   $96
   $94
end

   goto __End_Enemy_Animation

__1C_Enemy
   player2-8:
   %00010000
   %00111100
   %00111100
   %01101110
   %01101110
   %11101101
   %11111111
   %10010011
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $16
   $96
   $98
   $96
   $94
   $96
   $94
end
   goto __End_Enemy_Animation


__1D_Enemy
   player2-8:
   %00011000
   %00111100
   %00111100
   %01110110
   %01110110
   %10110111
   %11111111
   %11001001
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $98
   $96
   $16
   $96
   $94
   $96
   $94
end

   goto __End_Enemy_Animation

__1E_Enemy
   player2-8:
   %00011000
   %00111100
   %00111100
   %01111010
   %01111010
   %11011011
   %11111111
   %10100101
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $98
   $96
   $98
   $96
   $14
   $96
   $94
end

   goto __End_Enemy_Animation

__1F_Enemy
   player2-8:
   %00011000
   %00111100
   %00111100
   %01111100
   %01111100
   %11101101
   %11111111
   %10010011
end

   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $98
   $96
   $98
   $96
   $94
   $96
   $14
end

   goto __End_Enemy_Animation



   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 1 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage01

   player0:
   %00001000
   %00011000
   %00010100
   %00101000
   %00111110
   %00101010
   %00001000
   %01001001
   %01001001
   %01011101
   %01010101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
   $C8
end

   player1y = 160


   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 2 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage02

   player0:
   %00001000
   %00001000
   %00010100
   %00101000
   %00011110
   %00101010
   %00001000
   %01001001
   %01001001
   %01011101
   %01010101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
   $C6
end

   player1y = 162


   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 3 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage03

   player0:
   %00001000
   %00001000
   %00010100
   %00001000
   %00011100
   %00101110
   %00001000
   %01001001
   %01001001
   %01011101
   %01010101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
   $1C
end

   player1y = 164

   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 4 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage04

   player0:
   %00001000
   %00001000
   %00010100
   %00001000
   %00011100
   %00101110
   %00001000
   %01001000
   %01001001
   %01011001
   %01010101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $1A
   $1A
   $1A
   $1A
   $1A
   $1A
   $1A
   $1A
   $1A
   $1A
end

   player1y = 166

   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 5 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage05

   player0:
   %00001000
   %00001000
   %00010100
   %00001000
   %00011100
   %00101110
   %00001000
   %00001000
   %01001001
   %01011001
   %01000101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $18
   $18
   $18
   $18
   $18
   $18
   $18
   $18
end

   player1y = 168

   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 6 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage06

   player0:
   %00001000
   %00001000
   %00000100
   %00001000
   %00011100
   %00011110
   %00001000
   %00001000
   %01001001
   %01011001
   %01000101
   %01010101
   %00101011
   %01011101
   %01001001
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $48
   $48
   $48
   $48
   $48
   $48
end

   player1y = 170

   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 7 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage07

   player0:
   %00001000
   %00001000
   %00000100
   %00001000
   %00011100
   %00001100
   %00001100
   %00001000
   %01001001
   %00011000
   %01000101
   %01010101
   %00101011
   %01011101
   %01001000
   %01010101
   %01010101
end

   player1:
   %00001111
   %00001111
   %00001111
   %00001111
end

   player1color:
   $46
   $46
   $46
   $46
end

   player1y = 172

   goto __Skip_Player_Collision


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship with 8 damage and sets
   ;  shape and color of health indicator.
   ;
__Player_Damage08

   player0:
   %00001000
   %00001000
   %00000100
   %00001000
   %00011000
   %00001100
   %00001100
   %00001000
   %01001001
   %00011000
   %01000101
   %01010101
   %00101011
   %01011101
   %01001000
   %00000101
   %01000101
end

   player1:
   %00001111
   %00001111
end

   player1color:
   $44
   $44
end

   player1y = 174

   goto __Skip_Player_Collision



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 1).
   ;
   ;  $FE = -2, $FF = -1, $00 = sit still, $01 = 1, $02 = 2
   ;
   data _D_EnemyX_W1
   $FF,$FE,$FF,$FF,$00,$00,$01,$00,$00,$01,$00,$00,$00,$00
   $01,$02,$01,$01,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00
   $FF,$00,$01,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 2).
   ;
   data _D_EnemyX_W2
   $FF,$FE,$FF,$FF,$00,$00,$01,$00,$00,$01,$00,$00,$00
   $01,$02,$01,$01,$00,$00,$FF,$00,$00,$FF,$00,$00,$00
   $FF,$00,$01,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 3).
   ;
   data _D_EnemyX_W3
   $FF,$FE,$FE,$00,$01,$00,$01,$00,$00
   $01,$02,$02,$00,$FF,$00,$FF,$00,$00
   $FF,$00,$01,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 4).
   ;
   data _D_EnemyX_W4
   $FF,$FE,$FE,$00,$02,$00,$00,$00
   $01,$02,$02,$00,$FE,$00,$00,$00
   $FF,$00,$01,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 5).
   ;
   data _D_EnemyX_W5
   $FF,$FE,$FE,$00,$02,$00,$00
   $01,$02,$02,$00,$FE,$00,$00
   $FF,$00,$01,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 6).
   ;
   data _D_EnemyX_W6
   $FF,$FE,$FE,$00,$00,$02,$00
   $01,$02,$02,$00,$00,$FE,$00
   $02,$00,$FE,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for enemy x movement (wave 7).
   ;
   data _D_EnemyX_W7
   $FF,$FE,$FE,$00,$02
   $01,$02,$02,$00,$FE
   $FE,$00,$00,$02,$00,$80
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Data for y enemy movement. Jumps to the 11th spot after
   ;  the data has been read once.
   ;
   data _D_EnemyY
   $01,$01,$01,$01,$01,$01,$01,$00,$FF,$FE,$FF,$00,$00,$00,$00,$00
   $00,$01,$02,$01,$00,$FF,$FE,$FF,$00,$01,$00,$00,$00,$00,$80
end



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   bank 3
   temp1 = temp1
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Second section of main loop.
   ;
__Code_Section_2



   ;***************************************************************
   ;
   ;  Channel 0 sound effect check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 0 sounds if sounds are off.
   ;
   if !_Ch0_Sound then goto __Skip_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the channel 0 duration counter.
   ;
   _Ch0_Duration = _Ch0_Duration - 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 0 sounds if duration counter is greater
   ;  than zero
   ;
   if _Ch0_Duration then goto __Skip_Ch_0



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 001.
   ;
   ;  Enemy explosion sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 001 isn't on.
   ;
   if _Ch0_Sound <> _c_Enemy_Boom then goto __Skip_Ch0_Sound_001

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Enemy_Boom[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Enemy_Boom[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Enemy_Boom[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets Duration.
   ;
   _Ch0_Duration = _SD_Enemy_Boom[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_001



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 002.
   ;
   ;  Player0 missile sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 002 isn't on.
   ;
   if _Ch0_Sound <> _c_Player_Missile then goto __Skip_Ch0_Sound_002

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Player_Missile[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Player_Missile[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Player_Missile[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Player_Missile[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_002



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 003.
   ;
   ;  Player hurt sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 003 isn't on.
   ;
   if _Ch0_Sound <> 3 then goto __Skip_Ch0_Sound_003

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Player_Hurt[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Player_Hurt[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Player_Hurt[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Player_Hurt[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_003



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 004.
   ;
   ;  Player destroyed sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 004 isn't on.
   ;
   if _Ch0_Sound <> 4 then goto __Skip_Ch0_Sound_004

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Player_Destroyed[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Player_Destroyed[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Player_Destroyed[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Player_Destroyed[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_004



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Other channel 0 sound effects go here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;
   ;  Jumps to end of channel 0 area. (This catches any mistakes.)
   ;
   goto __Skip_Ch_0



   ;***************************************************************
   ;
   ;  Clears channel 0.
   ;
__Clear_Ch_0
   
   _Ch0_Sound = 0 : AUDV0 = 0



   ;***************************************************************
   ;
   ;  End of channel 0 area.
   ;
__Skip_Ch_0



   ;***************************************************************
   ;
   ;  Channel 1 sound effect area.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Decreases the channel 1 duration counter.
   ;
   _Ch1_Duration = _Ch1_Duration - 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 1 sounds if duration counter is greater
   ;  than zero.
   ;
   if _Ch1_Duration then goto __Skip_Ch_1


   ;***************************************************************
   ;
   ;  Channel 1 sound effect 001.
   ;
   ;  Fire button sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if left difficulty is switched to A.
   ;
   if !switchleftb then goto __Skip_Chan1_Sound_001

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 1 data.
   ;
   temp4 = _SD_Background[_Ch1_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Restart_Ch_1

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 1 data.
   ;
   _Ch1_Counter = _Ch1_Counter + 1
   temp5 = _SD_Background[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1
   temp6 = _SD_Background[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 1.
   ;
   AUDV1 = temp4
   AUDC1 = temp5
   AUDF1 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch1_Duration = _SD_Background[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Randomly resets the counter so we won't hear the same 3
   ;  notes in a row over and over and over and over.
   ;
   if _Ch1_Counter = 84 then temp5 = rand : if rand > 128 then _Ch1_Counter = 84
   if _Ch1_Counter = 84 then temp5 = rand : if rand > 128 then _Ch1_Counter = 0

   if _Ch1_Counter = 168 then temp5 = rand : if rand > 128 then _Ch1_Counter = 84
   if _Ch1_Counter = 168 then temp5 = rand : if rand > 128 then _Ch1_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 1 area.
   ;
   goto __Skip_Ch_1

__Skip_Chan1_Sound_001



   ;***************************************************************
   ;
   ;  Restarts channel 1 background "music."
   ;
__Restart_Ch_1
   
   _Ch1_Duration = 1 : _Ch1_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Randomly changes the counter so we won't hear the same 3
   ;  notes in a row over and over and over and over.
   ;
   temp5 = rand : if rand > 128 then _Ch1_Counter = 84
   temp5 = rand : if rand > 128 then _Ch1_Counter = 168



   ;***************************************************************
   ;
   ;  End of channel 1 area.
   ;
__Skip_Ch_1



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
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0: goto __Main_Loop bank2

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if the reset switch hasn't
   ;  been released after being pressed.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop bank2

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart bank6




   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  End of main loop.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;***************************************************************
   ;
   ;
   ;  Sound effect data starts here.
   ;
   ;
   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for enemy boom explosion sound effect.
   ;
   data _SD_Enemy_Boom
   10,14,2
   1
   9,8,2
   1
   8,8,31
   1
   12,2,12
   2
   11,2,11
   2
   10,2,10
   2
   9,2,9
   2
   8,2,8
   2
   7,2,7
   2
   6,2,6
   2
   5,2,5
   2
   4,2,4
   2
   3,2,3
   2
   2,2,2
   2
   1,8,31
   8
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for shooting sound effect.
   ;
   data _SD_Player_Missile
   7,8,31
   1
   7,8,0
   1
   6,12,5
   1
   5,8,31
   1
   4,12,8
   1
   3,8,31
   1
   2,12,11
   1
   2,8,31
   1
   2,12,14
   1
   2,8,31
   1
   2,12,17
   1
   2,8,31
   1
   2,12,20
   1
   1,8,31
   8
   255
   7,8,31
   1
   7,8,0
   1
   6,12,5
   1
   5,8,31
   1
   4,12,7
   1
   3,8,31
   1
   2,12,9
   1
   2,8,31
   1
   2,12,11
   1
   2,8,31
   1
   2,12,13
   1
   2,8,31
   1
   2,12,15
   1
   1,8,31
   8
   255
   7,8,31
   1
   7,8,0
   1
   6,12,5
   1
   5,8,31
   1
   4,12,9
   1
   3,8,31
   1
   2,12,13
   1
   2,8,31
   1
   2,12,17
   1
   2,8,31
   1
   2,12,21
   1
   2,8,31
   1
   2,12,25
   1
   1,8,31
   8
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for player hurt sound effect.
   ;
   data _SD_Player_Hurt
   5,8,11
   1
   4,8,11
   1
   3,8,11
   1
   2,8,11
   1
   3,8,11
   1
   2,8,11
   1
   2,8,11
   8
   1,8,11
   8
   255
end


   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for player destroid sound effect.
   ;
   data _SD_Player_Destroyed
   10,8,31
   2
   12,2,12
   2
   11,2,11
   2
   10,2,10
   2
   10,8,31
   2
   9,2,9
   2
   9,8,31
   2
   8,2,8
   2
   7,2,7
   2
   6,2,6
   2
   5,2,5
   2
   5,8,31
   2
   4,2,4
   2
   3,2,3
   2
   3,8,31
   2
   2,2,2
   2
   1,8,31
   16
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for background "music."
   ;
   data _SD_Background
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,28
   4
   2,6,30
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,25
   4
   2,6,27
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   2,6,22
   4
   2,6,24
   4
   255
end



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   bank 4
   temp1 = temp1
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   bank 5
   temp1 = temp1
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   bank 6
   temp1 = temp1
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  176 rows that are 1 scanline high except the top and bottom
   ;  rows (which seem to be 2 scanlines high). All of the colors
   ;  seem to be 2 scanlines high.
   ;
   DF6FRACINC = 0 : DF4FRACINC = 0
   DF0FRACINC = 255 : DF1FRACINC = 255 : DF2FRACINC = 255 : DF3FRACINC = 255


   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen


   ;***************************************************************
   ;
   ;  Clears the screen.
   ;
   pfclear


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Sets playfield colors.
   ;
   pfcolors:
   $94
end


   ;***************************************************************
   ;
   ;  Sets background colors.
   ;
   bkcolors:
   $00
end


   ;***************************************************************
   ;
   ;  Clears the score.
   ;
   score = 0


   ;***************************************************************
   ;
   ;  Sets score colors.
   ;
   scorecolors:
   $AE
   $AE
   $AC
   $AC
   $AA
   $AA
   $A8
   $A8
end


   ;***************************************************************
   ;
   ;  Sets the color used by enemies.
   ;
   player2-8color:
   $18
   $42
   $44
   $46
   $46
   $44
   $42
   $38
end


   ;***************************************************************
   ;
   ;  Sets the color of the player's ship.
   ;
   player0color:
   $1A
   $98
   $96
   $9A
   $96
   $94
   $94
   $18
   $98
   $9A
   $98
   $96
   $98
   $96
   $94
   $96
   $94
end


   ;***************************************************************
   ;
   ;  Sets the shape of the player's ship.
   ;
   player0:
   %00001000
   %00011100
   %00010100
   %00101010
   %00111110
   %00101010
   %00001000
   %01001001
   %01001001
   %01011101
   %01010101
   %01010101
   %01101011
   %01011101
   %01001001
   %01010101
   %01010101
end


   ;***************************************************************
   ;
   ;  Sets the color of the player's health indicator.
   ;
   player1color:
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
   $CA
end


   ;***************************************************************
   ;
   ;  Sets the shape of the player's health indicator.
   ;
   player1:
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
   %00001111
end


   ;***************************************************************
   ;
   ;  Clears all normal variables and the extra 9 (fastest way).
   ;
   asm
   LDA #0
   STA a
   STA b
   STA c
   STA d
   STA e
   STA f
   STA g
   STA h
   STA i
   STA j
   STA k
   STA l
   STA m
   STA n
   STA o
   STA p
   STA q
   STA r
   STA s
   STA t
   STA u
   STA v
   STA w
   STA x
   STA y
   STA z
   STA var0
   STA var1
   STA var2
   STA var3
   STA var4
   STA var5
   STA var6
   STA var7
   STA var8
end


   ;***************************************************************
   ;
   ;  Restrains the reset switch for the main loop.
   ;
   ;  This bit fixes it so the reset switch becomes inactive if
   ;  it hasn't been released after being pressed once. The fire
   ;  button is also restrained.
   ;
   _Bit0_Reset_Restrainer{0} = 1 : _Bit1_FireB_Restrainer{1} = 1

   
   ;***************************************************************
   ;
   ;  Puts borders on the sides of the playfield.
   ;
   PF0 = %10000000


   ;***************************************************************
   ;
   ;  Sets missile height.
   ;
   missile0height = 5


   ;***************************************************************
   ;
   ;  Sets color of missile.
   ;
   COLUM0 = $CC


   ;***************************************************************
   ;
   ;  Sets the position of the player's ship.
   ;
   player0x = 77 : player0y = 158


   ;***************************************************************
   ;
   ;  Sets the position of the player's health indicator.
   ;
   player1x = 0 : player1y = 158


   ;***************************************************************
   ;
   ;  Sets player damage counter.
   ;
   _Damage_Counter = 255


   ;***************************************************************
   ;
   ;  Starts background "music."
   ;
   _Ch1_Duration = 1 : _Ch1_Counter = 0


   ;***************************************************************
   ;
   ;  Sets wave at 7 so it will start at 10 when 3 is added to it.
   ;
   _Wave = 7


   ;***************************************************************
   ;
   ;  Game jumps here when a new wave starts.
   ;
__Enemy_Reset


   ;***************************************************************
   ;
   ;  Makes sure the missile is off screen.
   ;
   missile0y = 241


   ;***************************************************************
   ;
   ;  Clears certain counters.
   ;
   _Master_Counter = 0 : _Enemy_D_Counter_y = 0 : _Enemy_D_Counter_x = 0 : _Dead_Enemy_Counter = 0


   ;***************************************************************
   ;
   ;  Sets NUSIZ and variables related to the enemy sprites.
   ;
   NUSIZ2 = $02 : NUSIZ4 = $02 : NUSIZ6 = $02 : NUSIZ8 = $02 : _EnemyP8 = 2 : _EnemyP6 = 2 : _EnemyP4 = 2 : _EnemyP2 = 2
   NUSIZ3 = $06 : NUSIZ5 = $06 : NUSIZ7 = $06
   _EnemyP7 = 7 : _EnemyP5 = 7 : _EnemyP3 = 7


   ;***************************************************************
   ;
   ;  Sets positions of enemy sprites.
   ;
   player2y = 201
   player3y = player2y + 14
   player4y = player3y + 14
   player5y = player4y + 14
   player6y = player5y + 14
   player7y = player6y + 14
   player8y = player7y + 14

   player2x = 71 :  player4x = 71 : player6x = 71 :  player8x = 71
   player3x = 55 :  player5x = 55 : player7x = 55


   ;***************************************************************
   ;
   ;  Increases the wave. Makes the "game" harder.
   ;
   if _Wave < 31 then _Wave = _Wave + 3


   goto __Main_Loop bank2