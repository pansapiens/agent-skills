   ;***************************************************************
   ;
   ;  Change Playfield Color of Any Row (DPC+)
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
   ;  Push joystick up or down to select any row. Push joystick
   ;  right to change color of the selected row. Push joystick
   ;  left while pushing up or down to paint playfield with the
   ;  last color that was selected. Push joystick right while
   ;  pushing up or down to paint with multiple colors. Holding
   ;  down the fire button slows down row selection and color
   ;  selection.
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
   ;  Current row. (a is integer, b is fraction).
   ;
   dim _Row = a.b

   ;```````````````````````````````````````````````````````````````
   ;  Current row integer.
   ;
   dim _Row_Integer = a

   ;```````````````````````````````````````````````````````````````
   ;  Row color of playfield.
   ;
   dim _pfRow_Color = e.f

   ;```````````````````````````````````````````````````````````````
   ;  Row color integer for playfield.
   ;
   dim _pfRowColor_Integer = e

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = y ; Reset switch becomes inactive if it hasn't been released.

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2



   ;***************************************************************
   ;
   ;  Playfield color constants.
   ;  [The c stands for constant.]
   ;
   const _c_PFCOLS_Lo = #<(PFCOLS)
   const _c_PFCOLS_Hi = #(>PFCOLS) & $0F



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
   ;  Score colors.
   ;
   scorecolors:
   $0E
   $0E
   $0C
   $0C
   $0A
   $0A
   $08
   $08
end


   ;***************************************************************
   ;
   ;  Cursor color.
   ;
   player0color:
   $08
   $08
end


   ;***************************************************************
   ;
   ;  Cursor shape.
   ;
   player0:
   %11111111
   %11111111
end


   ;***************************************************************
   ;
   ;  Fills the playfield.
   ;
   playfield: 
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;10
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;20
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;30
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;40
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;50
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;60
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;70
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;80
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;88
end


   ;***************************************************************
   ;
   ;  Starting cursor position.
   ;
   player0x = 0 : player0y = 0


   ;***************************************************************
   ;
   ;  Displays the screen to keep from going over 262.
   ;
   drawscreen


   ;***************************************************************
   ;
   ;  Starting row color for loop.
   ;
   _pfRowColor_Integer = 1


   ;***************************************************************
   ;
   ;  Creates colors for bottom half of screen.
   ;
   for _Row_Integer = 88 to 45 step -1

   DF0LOW = _c_PFCOLS_Lo + _Row_Integer
   DF0HI = _c_PFCOLS_Hi
   DF0PUSH = _pfRowColor_Integer

   _pfRowColor_Integer = _pfRowColor_Integer + 2

   next


   ;***************************************************************
   ;
   ;  Displays the screen to keep from going over 262.
   ;
   drawscreen


   ;***************************************************************
   ;
   ;  Creates colors for top half of screen.
   ;
   for _Row_Integer = 44 to 1 step -1

   DF0LOW = _c_PFCOLS_Lo + _Row_Integer
   DF0HI = _c_PFCOLS_Hi
   DF0PUSH = _pfRowColor_Integer

   _pfRowColor_Integer = _pfRowColor_Integer + 2

   next


   ;***************************************************************
   ;
   ;  Displays the screen to keep from going over 262.
   ;
   drawscreen


   ;***************************************************************
   ;
   ;  Starting row and color.
   ;
   _Row = 1.0 : _pfRow_Color = $1E


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
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  1 pixel wide missile. Double-sized player.
   ;
   NUSIZ0 = $05



   ;***************************************************************
   ;
   ;  Up joystick section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips section if joystick not pushed up.
   ;
   if !joy0up then goto __Skip_Joy0_Up

   ;```````````````````````````````````````````````````````````````
   ;  Temporarily remembers the integer and moves up a little.
   ;
   temp5 = _Row_Integer : _Row = _Row - 0.25

   ;```````````````````````````````````````````````````````````````
   ;  Moves faster if fire button not pressed.
   ;
   if !joy0fire then _Row = _Row - 0.75

   ;```````````````````````````````````````````````````````````````
   ;  Moves cursor if integer changed.
   ;
   if _Row_Integer <> temp5 then player0y = player0y - 2

   ;```````````````````````````````````````````````````````````````
   ;  Moves to bottom if cursor moved past top of screen.
   ;
   if _Row_Integer = 0 || _Row_Integer > 200 then _Row = 88.0 : player0y = 174
   
__Skip_Joy0_Up



   ;***************************************************************
   ;
   ;  Down joystick section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips section if joystick not pushed down.
   ;
   if !joy0down then goto __Skip_Joy0_Down

   ;```````````````````````````````````````````````````````````````
   ;  Temporarily remembers the integer and moves down a little.
   ;
   temp5 = _Row_Integer : _Row = _Row + 0.25

   ;```````````````````````````````````````````````````````````````
   ;  Moves faster if fire button not pressed.
   ;
   if !joy0fire then _Row = _Row + 0.75

   ;```````````````````````````````````````````````````````````````
   ;  Moves cursor if integer changed.
   ;
   if _Row_Integer <> temp5 then player0y = player0y + 2

   ;```````````````````````````````````````````````````````````````
   ;  Moves to top if cursor moved past bottom of screen.
   ;
   if _Row > 88 then _Row = 1.0 : player0y = 0
   
__Skip_Joy0_Down



   ;***************************************************************
   ;
   ;  Left joystick section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips section if joystick not pushed left.
   ;
   if !joy0left then goto __Skip_Joy0Left

   ;```````````````````````````````````````````````````````````````
   ;  Color change. This is the important code.
   ;
   DF0LOW = _c_PFCOLS_Lo + _Row_Integer
   DF0HI = _c_PFCOLS_Hi
   DF0PUSH = _pfRowColor_Integer

__Skip_Joy0Left



   ;***************************************************************
   ;
   ;  Right joystick section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips section if joystick not pushed right.
   ;
   if !joy0right then goto __Skip_Joy0Right

   ;```````````````````````````````````````````````````````````````
   ;  Temporarily remembers the integer and changes color slowly.
   ;
   temp5 = _pfRowColor_Integer : _pfRow_Color = _pfRow_Color + 0.15

   ;```````````````````````````````````````````````````````````````
   ;  Changes color faster if fire button not pressed.
   ;
   if !joy0fire then _pfRow_Color = _pfRow_Color + 0.85

   ;```````````````````````````````````````````````````````````````
   ;  Jumps color by one if integer changed.
   ;
   if _pfRowColor_Integer <> temp5 then _pfRow_Color = _pfRow_Color + 1.0

   ;```````````````````````````````````````````````````````````````
   ;  Color change. This is the important code.
   ;
   DF0LOW = _c_PFCOLS_Lo + _Row_Integer
   DF0HI = _c_PFCOLS_Hi
   DF0PUSH = _pfRowColor_Integer

__Skip_Joy0Right



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the right side.
   ;
   temp4 = _Row_Integer

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
   DF6FRACINC = 255 : DF4FRACINC = 255

   DF0FRACINC = 128 : DF1FRACINC = 128 : DF2FRACINC = 128 : DF3FRACINC = 128



   ;***************************************************************
   ;
   ;  Simple fix for the top two lines having the same color.
   ;
   asm
   lda DF6FRACDATA ; bgcolor priming read (first value will be read twice)
   lda DF4FRACDATA ; pfcolor priming read (first value will be read twice)
end



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