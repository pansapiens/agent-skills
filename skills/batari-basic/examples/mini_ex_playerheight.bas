   player0:
   %00000000
   %00111100
   %01111110
   %11000011
   %10111101
   %11111111
   %11011011
   %01111110
   %00111100
end

   COLUBK = 0

   player0x = 77
   player0y = 53

__Main_Loop

   COLUP0 = $9C

   if !joy0up then goto __Skip_Up
   if player0height < 8 then player0height = player0height + 1
__Skip_Up

   if !joy0down then goto __Skip_Down
   if player0height > 0 then player0height = player0height - 1
__Skip_Down

   drawscreen

   goto __Main_Loop