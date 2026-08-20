   set kernel_options no_blank_lines readpaddle


   ;***************************************************************
   ;
   ;  Sets sprite locations.
   ;
   player0y = 12: player1y = 85


   ;***************************************************************
   ;
   ;  Creates paddles.
   ;
   player0:
   %1111111
   %1111111
end

   player1:
   %1111111
   %1111111
end



__Main_Loop



   ;***************************************************************
   ;
   ;  Sets up color and size of player0 (double size).
   ;
   COLUP0 = $9C : NUSIZ0 = $05



   ;***************************************************************
   ;
   ;  Sets up color and size of player1 (double size).
   ;
   COLUP1 = $3C : NUSIZ1 = $05



   ;***********************************************************
   ;
   ;  Selects the next paddle to be read.
   ;
   currentpaddle = currentpaddle + 1

   ;```````````````````````````````````````````````````````````
   ;  Paddle 1, then paddle 0, then paddle 1 again, etc.
   ;
   if currentpaddle = 2 then currentpaddle = 0



   ;***********************************************************
   ;
   ;  Draws the screen and reads the current paddle.
   ;
   drawscreen



   ;***********************************************************
   ;
   ;  Paddle 0 check.
   ;
   ;```````````````````````````````````````````````````````````
   ;  Skips this subsection if not paddle 0.
   ;
   if currentpaddle <> 0 then goto __Skip_Paddle0

   ;```````````````````````````````````````````````````````````
   ;  Converts value to useable coordinate.
   ;
   player0x = paddle * 2 + 1

   ;```````````````````````````````````````````````````````````
   ;  Limits player0 movement.
   ;
   if player0x > 140 then player0x = 140

__Skip_Paddle0 



   ;***********************************************************
   ;
   ;  Paddle 1 check.
   ;
   ;```````````````````````````````````````````````````````````
   ;  Skips this subsection if not paddle 1.
   ;
   if currentpaddle <> 1 then goto __Skip_Paddle1

   ;```````````````````````````````````````````````````````````
   ;  Converts value to useable coordinate.
   ;
   player1x = paddle * 2 + 1

   ;```````````````````````````````````````````````````````````
   ;  Limits player1 movement.
   ;
   if player1x > 140 then player1x = 140

__Skip_Paddle1



   ;***********************************************************
   ;
   ;  More code that you want to add goes here.
   ;
   ;***********************************************************


   goto __Main_Loop