   ;***************************************************************
   ;
   ;  Move cursor left/right with joystick to select score digit.
   ;  Press up to add to the digit or down to subtract from it.
   ;
   ;***************************************************************

   dim _Bit0_Reset_Restrainer = y
   dim _Bit1_Joy0_Restrainer = y
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2


__Start_Restart

   ; Sets ball cursor position and height.
   ballx = 64
   bally = 87
   ballheight = 0

   ; Sets score and score color.
   score = 123456
   scorecolor = $1A

   ; Makes reset inactive if held.
   _Bit0_Reset_Restrainer{0} = 1


__Main_Loop

   COLUBK = $00 ; Sets background color.
   COLUPF = $2C ; Sets ball/playfield color (cursor).
   CTRLPF = $21 ; Sets ball to 4 pixels wide.


   ; Determines if score is greater than 123456.
   if _sc1 > $12 then COLUBK = $30 : goto __Skip_Greater_Test
   if _sc1 < $12 then goto __Skip_Greater_Test
   if _sc2 > $34 then COLUBK = $30 : goto __Skip_Greater_Test
   if _sc2 < $34 then goto __Skip_Greater_Test
   if _sc3 > $56 then COLUBK = $30
__Skip_Greater_Test


   ; Debounces joystick to keep it from repeating when held in the same position.
   if !joy0up && !joy0down && !joy0left && !joy0right then _Bit1_Joy0_Restrainer{1} = 0 : goto __Skip_Joy0
   if _Bit1_Joy0_Restrainer{1} then goto __Skip_Joy0
   _Bit1_Joy0_Restrainer{1} = 1

   ; Checks for left/right cursor movement.
   if joy0left then if ballx > 64 then ballx = ballx - 8
   if joy0right then if ballx < 104 then ballx = ballx + 8

   ; Adds to selected score digit when joystick moved up.
   if !joy0up then goto __Skip_Up
   if ballx = 64 then dec _sc1 = _sc1 + $10
   if ballx = 72 then dec _sc1 = _sc1 + $01
   if ballx = 80 then dec _sc2 = _sc2 + $10
   if ballx = 88 then dec _sc2 = _sc2 + $01
   if ballx = 96 then dec _sc3 = _sc3 + $10
   if ballx = 104 then dec _sc3 = _sc3 + $01
__Skip_Up

   ; Subtracts from selected score digit when joystick moved down.
   if !joy0down then goto __Skip_Joy0
   if ballx = 64 then dec _sc1 = _sc1 - $10
   if ballx = 72 then dec _sc1 = _sc1 - $01
   if ballx = 80 then dec _sc2 = _sc2 - $10
   if ballx = 88 then dec _sc2 = _sc2 - $01
   if ballx = 96 then dec _sc3 = _sc3 - $10
   if ballx = 104 then dec _sc3 = _sc3 - $01
__Skip_Joy0


   drawscreen ; Activates kernel and displays all visual elements.


   ;  Reset switch check and end of main loop.
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop
   goto __Start_Restart