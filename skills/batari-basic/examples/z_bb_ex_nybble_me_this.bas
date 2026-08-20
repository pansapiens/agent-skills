   ;***************************************************************
   ;
   ;  Nybble me this, Batman!
   ;
   ;  By SeaGtGruff (adapted by Duane Alan Hahn).
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
   ;  You need to include div_mul.asm for this.
   ;
   include div_mul.asm



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
   ;  This variable will be used to store two nybble values.
   ;
   dim _Batman = a

   ;```````````````````````````````````````````````````````````````
   ;  A bit used to jump between sections of the program.
   ;
   dim _Bit0_Loop_Jump = y

   ;```````````````````````````````````````````````````````````````
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2




   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart



   ;***************************************************************
   ;
   ;  Stores the two values in "temp5" and "temp6," just for now.
   ;
   temp5 = 5
   temp6 = 10



   ;***************************************************************
   ;
   ;  Uses multiplication and addition to set "_Batman."
   ;  The "temp5" value will go in the high nybble,
   ;  and the "temp6" value will go in the low nybble.
   ;
   _Batman = temp5 * 16 + temp6



   ;***************************************************************
   ;
   ;  Clears "temp5" and "temp6."
   ;
   temp5 = 0
   temp6 = 0



   ;***************************************************************
   ;
   ;  Retrieves the two nybbles.
   ;
   temp5 = _Batman / 16
   temp6 = _Batman & %00001111



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;  (Code provided by bogax.)
   ;
   temp4 = temp5

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
   ;  (Code provided by bogax.)
   ;
   temp4 = temp6

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
   ;  Sets background color and score color.
   ;
   COLUBK = $00 : scorecolor = $1A





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Loop 01
   ;
   ;
__Loop_01



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Fire button check.
   ;
   if !joy0fire then _Bit0_Loop_Jump{0} = 0 : goto __Loop_01

   if _Bit0_Loop_Jump{0} then goto __Loop_01

   _Bit0_Loop_Jump{0} = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Loop 02 SETUP
   ;
   ;
   ;***************************************************************
   ;
   ;  Here's how to change just the high nybble (to 3).
   ;
   _Batman = _Batman & %00001111
   _Batman = _Batman | 16 * 3



   ;***************************************************************
   ;
   ;  Here's how to change just the low nybble (to 6).
   ;
   _Batman = _Batman & %11110000
   _Batman = _Batman | 6



   ;***************************************************************
   ;
   ;  Gets new values.
   ;
   temp5 = _Batman / 16
   temp6 = _Batman & %00001111



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;  (Code provided by bogax.)
   ;
   temp4 = temp5

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
   ;  (Code provided by bogax.)
   ;
   temp4 = temp6

   _sc2 = _sc2 & 240 : _sc3 = 0
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
   _sc3 = _sc3 | temp4





   ;***************************************************************
   ;***************************************************************
   ;
   ;  Loop 02
   ;
   ;
__Loop_02



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Fire button check.
   ;
   if !joy0fire then _Bit0_Loop_Jump{0} = 0 : goto __Skip_Fire

   if !_Bit0_Loop_Jump{0} then _Bit0_Loop_Jump{0} = 1 : goto __Start_Restart

__Skip_Fire



   ;***************************************************************
   ;
   ;  Restarts program if reset switch is pressed.
   ;
   if switchreset then goto __Start_Restart



   goto __Loop_02