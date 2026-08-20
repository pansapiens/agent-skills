   dim _Bit6_Flip_P0 = y
   dim _Bit7_Flip_P1 = y

   player0:
   %01111110
   %11111111
   %00011111
   %00000111
   %00011111
   %11111111
   %01111110
end

   player1:
   %10101010
   %11111111
   %10000011
   %10101011
   %11111111
   %10010011
   %11011011
   %10010011
   %01111110
end

   COLUBK = 0

   player0x = 68 : player1x = player0x + 20

   player0y = 55 : player1y = 55



__Main_Loop


   COLUP0 = $1E : COLUP1 = $AE


   if joy0left then _Bit6_Flip_P0{6} = 0 : _Bit7_Flip_P1{7} = 0
   if joy0right then _Bit6_Flip_P0{6} = 1 : _Bit7_Flip_P1{7} = 1


   ;****************************************************************
   ;
   ;  Flips player0 sprite when necessary.
   ;
   if _Bit6_Flip_P0{6} then REFP0 = 8


   ;****************************************************************
   ;
   ;  Flips player1 sprite when necessary.
   ;
   if _Bit7_Flip_P1{7} then REFP1 = 8


   drawscreen


   goto __Main_Loop