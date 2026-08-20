   ;***************************************************************
   ;
   ;  Variable aliases go here (DIMs).
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Data counter.
   ;
   dim _D_Counter = m

   ;```````````````````````````````````````````````````````````````
   ;  Remembers data.
   ;
   dim _D_Mem = n

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

   ;```````````````````````````````````````````````````````````````
   ;  Joy0 restrainer bit.
   ;
   dim _Bit6_Joy0_Restrainer = y



   ;***************************************************************
   ;
   ;  Sets score color.
   ;
   scorecolor = $9C





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Joystick section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the joystick restrainer bit and skips this section if
   ;  joystick not moved.
   ;
   if !joy0left && !joy0right then _Bit6_Joy0_Restrainer{6} = 0 : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if joystick already moved.
   ;
   if _Bit6_Joy0_Restrainer{6} then goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Turns on the joystick restrainer bit.
   ;
   _Bit6_Joy0_Restrainer{6} = 1

   ;```````````````````````````````````````````````````````````````
   ;  Gets data if joystick moved left.
   ;
   if joy0left then _D_Mem = _Data_Baked_Potato[_D_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Gets other data if joystick moved right.
   ;
   if joy0right then _D_Mem = _Data_Toenail_Fungus[_D_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Increments and limits data counter.
   ;
   _D_Counter = _D_Counter + 1 : if _D_Counter > 6 then _D_Counter = 0

__Skip_Joy0



   ;***************************************************************
   ;
   ;  Puts _D_Mem in the three score digits on the right side.
   ;   
   temp4 = _D_Mem
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
   ;  Displays the screen.
   ;
   drawscreen



   goto __Main_Loop





   ;***************************************************************
   ;
   ;  Data table 01.
   ;
   data _Data_Baked_Potato
   11, 22, 33, 44, 55, 66, 77
end



   ;***************************************************************
   ;
   ;  Data table 02.
   ;
   data _Data_Toenail_Fungus
   1, 2, 3, 4, 5, 6, 7
end