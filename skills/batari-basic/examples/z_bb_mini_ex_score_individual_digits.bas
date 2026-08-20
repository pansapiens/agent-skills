   ;***************************************************************
   ;
   ;  Change Individual Score Digits
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain), adapted
   ;  from "Easy Way to Set Player Graphic to Number" by Karl G.
   ;  and other AtariAge contributions. Code merged by Grok 3.
   ;
   ;  Uses hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  Displays player1 as a score digit (0-9) using score graphics.
   ;  Press joystick up to increase the digit (0 to 9, wraps to 0)
   ;  or down to decrease it (9 to 0, wraps to 9). Move the ball 
   ;  cursor left or right with the joystick to select a score
   ;  digit. Press the fire button to set the selected score digit
   ;  to match player1's digit.
   ;  
   ;***************************************************************


   ;***************************************************************
   ;  Variable aliases
   ;
   dim _Number = q                   ; Tracks player1 digit (0-9).
   dim _Bit0_Reset_Restrainer = y    ; Restrains reset switch.
   dim _Bit1_Joy0_Restrainer = y     ; Restrains joystick.
   dim _sc1 = score                  ; Score digit pair 1 (leftmost).
   dim _sc2 = score+1                ; Score digit pair 2.
   dim _sc3 = score+2                ; Score digit pair 3 (rightmost).


   ;***************************************************************
   ;  CONSTANTS for score graphics
   ;
   const _SCORE_TABLE_HIGH = >scoretable
   const _SCORE_TABLE_LOW = <scoretable



   ;***************************************************************
   ;  Program Start/Restart
   ;
__Start_Restart

   ; Mutes sound channels.
   AUDV0 = 0 : AUDV1 = 0

   ;  Clears variables.
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

   ; Sets ball cursor position and height.
   ballx = 64
   bally = 87
   ballheight = 0

   ; Sets player1 (digit sprite) position and height.
   player1x = 81
   player1y = 53
   player1height = 7  ; Matches score graphic height.

   ; Sets score and score color.
   score = 123456
   scorecolor = $1A  ; Yellow.

   ; Initializes player1 graphic (digit 0).
   temp6 = _Number
   player1pointerhi = _SCORE_TABLE_HIGH
   temp6 = temp6 * 8
   player1pointerlo = temp6 + _SCORE_TABLE_LOW

   ; Makes reset inactive if held.
   _Bit0_Reset_Restrainer{0} = 1



   ;***************************************************************
   ;  Main Loop
   ;
__Main_Loop

   COLUBK = $00 ; Sets background color.
   COLUPF = $9C ; Sets ball/playfield color (cursor).
   COLUP1 = $2C ; Sets p1 sprite color.
   CTRLPF = $21 ; Sets ball to 4 pixels wide.


   ; Debounces joystick to keep it from repeating when held in the same position.
   if !joy0up && !joy0down && !joy0left && !joy0right && !joy0fire then _Bit1_Joy0_Restrainer{1} = 0 : goto __Skip_Joy0
   if _Bit1_Joy0_Restrainer{1} then goto __Skip_Joy0
   _Bit1_Joy0_Restrainer{1} = 1

   ; Changes player1 sprite digit when joy0 moved up/down.
   if joy0up then _Number = _Number + 1 : if _Number > 9 then _Number = 0
   if joy0down then _Number = _Number - 1 : if _Number > 200 then _Number = 9
   if joy0up || joy0down then temp6 = _Number : player1pointerhi = _SCORE_TABLE_HIGH : temp6 = temp6 * 8 : player1pointerlo = temp6 + _SCORE_TABLE_LOW

   ; Checks for left/right cursor movement.
   if joy0left then if ballx > 64 then ballx = ballx - 8
   if joy0right then if ballx < 104 then ballx = ballx + 8

   ; Sets selected score digit to _Number value when fire button is pressed.
   if !joy0fire then goto __Skip_Joy0
   if ballx = 64 then temp6 = _sc1 & $0F : temp6 = temp6 | (_Number * 16) : _sc1 = temp6  ; 100 thousands digit.
   if ballx = 72 then temp6 = _sc1 & $F0 : temp6 = temp6 | _Number : _sc1 = temp6         ; 10 thousands digit.
   if ballx = 80 then temp6 = _sc2 & $0F : temp6 = temp6 | (_Number * 16) : _sc2 = temp6  ; Thousands digit.
   if ballx = 88 then temp6 = _sc2 & $F0 : temp6 = temp6 | _Number : _sc2 = temp6         ; Hundreds digit.
   if ballx = 96 then temp6 = _sc3 & $0F : temp6 = temp6 | (_Number * 16) : _sc3 = temp6  ; Tens digit.
   if ballx = 104 then temp6 = _sc3 & $F0 : temp6 = temp6 | _Number : _sc3 = temp6        ; Ones digit.
__Skip_Joy0


   drawscreen ; Activates kernel and displays all visual elements.


   ;  Reset switch check and end of main loop.
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop
   goto __Start_Restart