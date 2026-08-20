__Main_Loop

   temp1 = SWCHA / 16

   ;  NOTE: To get the same 4 bit value for Joy1, use this code:

   ;  temp1 = SWCHA & %00001111

   on temp1 gosub __Still __Still __Still __Still __Still __GoDownRight __GoUpRight __GoRight __Still __GoDownLeft __GoUpLeft __GoLeft __Still __GoDown __GoUp __Still

   drawscreen

   goto __Main_Loop

__Still
   ;  Code goes here.
   return thisbank

__GoUp
   ;  Code goes here.
   return thisbank

__GoDown
   ;  Code goes here.
   return thisbank

__GoLeft
   ;  Code goes here.
   return thisbank

__GoRight
   ;  Code goes here.
   return thisbank

__GoUpLeft
   ;  Code goes here.
   return thisbank

__GoUpRight
   ;  Code goes here.
   return thisbank

__GoDownLeft
   ;  Code goes here.
   return thisbank

__GoDownRight
   ;  Code goes here.
   return thisbank