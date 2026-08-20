   ;***************************************************************
   ;
   ;  New and Improved Nybble Variables
   ;
   ;  By SeaGtGruff (with help from RevEng and bogax) 
   ;
   ;
   ;  One variable is split into two thanks to macro and def.
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
   ;  Splits up the score into 3 parts.
   ;
   dim _sc1 = score
   dim _sc2 = score+1
   dim _sc3 = score+2

   ;```````````````````````````````````````````````````````````````
   ;  Makes better random numbers.
   ;
   dim rand16 = z



   ;***************************************************************
   ;
   ;  Reusable macros for nybble variables. Leave these macros
   ;  alone. You don't have to worry about them. They do all of
   ;  the hard work for you.
   ;
   ;  For those who would like to know, 4*4 and 4/4 are used so
   ;  that include div_mul.asm won't have to be used and
   ;  everything will work when bankswitching is used.
   ;
   macro _Set_Lo_Nibble
   {1}=(({2}^{1})&$0F)^{1}
end

   macro _Set_Hi_Nibble
   {1}=(({2}*4*4^{1})&$F0)^{1}
end



   ;***************************************************************
   ;
   ;  Aliases using dim can be created for use with
   ;  nybble variables to make it easier. You don't 
   ;  have to use a, b, and c. You can change them
   ;  to whatever you want of the 26 variables that
   ;  are still available in your program. Although
   ;  this example uses 3 variables, you can use
   ;  more than that or trim it down to one. It all
   ;  depends on how many nybble variables you
   ;  need that are limited to 0 through 15.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  The following examples show where to put
   ;  your own variable names.
   ;
   ;  Anywhere you see "Replace_Me" in the
   ;  example below, you'd put your first alias:
   ;
   ;  dim Replace_Me=<variable you want to use>
   ;  def PEEK_Replace_Me=Replace_Me&$0F
   ;  def POKE_Replace_Me=callmacro _Set_Lo_Nibble Replace_Me
   ;
   ;  And anywhere you see "Replace_Me_Too" in the
   ;  example below, you'd put your second alias:
   ;
   ;  dim Replace_Me_Too=<same variable you want to use>
   ;  def PEEK_Replace_Me_Too=Replace_Me_Too/4/4
   ;  def POKE_Replace_Me_Too=callmacro _Set_Hi_Nibble Replace_Me_Too
   ;
   ;  Once you set up your dims and defs, you're all done
   ;  and ready to use nybble variables the easy way.
   ;
   ;***************************************************************



   ;***************************************************************
   ;
   ;  Two nybbles made from the variable a.
   ;
   dim _Game_Level=a
   def _PEEK_Game_Level=_Game_Level&$0F
   def _POKE_Game_Level=callmacro _Set_Lo_Nibble _Game_Level

   dim _Hit_Points=a
   def _PEEK_Hit_Points=_Hit_Points/4/4
   def _POKE_Hit_Points=callmacro _Set_Hi_Nibble _Hit_Points



   ;***************************************************************
   ;
   ;  Two nybbles made from the variable b.
   ;
   ;
   dim _Moose_Tracks=b
   def _PEEK_Moose_Tracks=_Moose_Tracks&$0F
   def _POKE_Moose_Tracks=callmacro _Set_Lo_Nibble _Moose_Tracks

   dim Rabbit_Ears=b
   def PEEK_Rabbit_Ears=Rabbit_Ears/4/4
   def POKE_Rabbit_Ears=callmacro _Set_Hi_Nibble Rabbit_Ears



   ;***************************************************************
   ;
   ;  Two nybbles made from the variable c.
   ;
   dim _Saucer_Speed=c
   def _PEEK_Saucer_Speed=_Saucer_Speed&$0F
   def _POKE_Saucer_Speed=callmacro _Set_Lo_Nibble _Saucer_Speed

   dim _Something_Else=c
   def _PEEK_Something_Else=_Something_Else/4/4
   def _POKE_Something_Else=callmacro _Set_Hi_Nibble _Something_Else



   ;***************************************************************
   ;
   ;  Sets up score and background colors. 
   ;
   scorecolor = $1A : COLUBK = $C4





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Slows things down. 
   ;
   w = w + 1 : if w < 30 then goto __Skip_It_All

   w = 0



   ;***************************************************************
   ;
   ;  Adds 1 to _Game_Level. 
   ;
   temp5 = (_PEEK_Game_Level) + 1 : _POKE_Game_Level temp5



   ;***************************************************************
   ;
   ;  Assigns a random number to _Hit_Points. 
   ;
   temp5 = rand & 15 : _POKE_Hit_Points temp5



   ;***************************************************************
   ;
   ;  Puts temp4 in the three score digits on the left side.
   ;  (Code provided by bogax.)
   ;
   temp4 = _PEEK_Game_Level

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
   temp4 = _PEEK_Hit_Points

   _sc2 = _sc2 & 240 : _sc3 = 0
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
   if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
   if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
   if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
   if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
   _sc3 = _sc3 | temp4

__Skip_It_All



   ;***************************************************************
   ;
   ;  The screen would be blank without drawscreen. 
   ;
   drawscreen



   goto __Main_Loop





   ;***************************************************************
   ;  
   ;  Remember, this is supposed to make things easier.
   ;  Once you set up your dims and defs, you're all done.
   ;  From then on all you do is use your PEEK and POKE
   ;  variables.
   ;  
   ;  Here are various ways you can use POKE:
   ;  
   ;  POKE_Ship 7
   ;  
   ;  temp5 = rand & 15 : POKE_Ship temp5
   ;  
   ;  temp5 = (PEEK_Ship) + 1 : POKE_Ship temp5
   ;  
   ;  temp5 = (PEEK_Ship) - 1 : POKE_Ship temp5
   ;  
   ;```````````````````````````````````````````````````````````````
   ;  
   ;  Here are various ways you can use PEEK:
   ;  
   ;  temp5 = PEEK_Ship
   ;  
   ;  if PEEK_Ship = 5 then goto Skip_Goober_Glob
   ;  
   ;  temp5 = (PEEK_Ship) + 1
   ;  
   ;  
   ;  It may take a few minutes to get used to,
   ;  but once you start using PEEK and POKE
   ;  nybble variables, you'll see how easy
   ;  it is. All of the complicated stuff is
   ;  done for us. Of course, when batari
   ;  makes nybble variables an official
   ;  part of bB, we won't have to use 
   ;  PEEK and POKE. Until then, at least
   ;  we have an easier, less confusing
   ;  way to use nybble variables.
   ;  
   ;  If you don't like this new and improved way,
   ;  you can always use the "Nybble me this, Batman!"
   ;  version where you have to do everything
   ;  instead of letting macro and def do all of
   ;  hard work for you.
   ;  
   ;***************************************************************
