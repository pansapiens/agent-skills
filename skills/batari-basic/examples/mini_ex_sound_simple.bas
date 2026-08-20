   dim _Ch0_Sound = c
   dim _Ch0_Duration = d
   dim _C0 = e
   dim _V0 = f
   dim _F0 = g





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Fire button check.
   ;
   ;  Turns on channel 0 sound effect 1 if fire button is pressed.
   ;
   if joy0fire then if !_Ch0_Sound then _Ch0_Sound = 1 : _Ch0_Duration = 15



   ;***************************************************************
   ;
   ;  Channel 0 sound effect check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 0 sounds if sounds are off.
   ;
   if !_Ch0_Sound then goto __Skip_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the channel 0 duration counter.
   ;
   _Ch0_Duration = _Ch0_Duration - 1

   ;```````````````````````````````````````````````````````````````
   ;  Turns off sound if channel 0 duration counter is zero.
   ;
   if !_Ch0_Duration then goto __Clear_Ch_0



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 001.
   ;
   ;  A simple/plain/lazy sound.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 001 isn't on.
   ;
   if _Ch0_Sound <> 1 then goto __Skip_Ch0_Sound_001

   ;```````````````````````````````````````````````````````````````
   ;  Sets the tone, volume and frequency.
   ;
   AUDC0 = 4 : AUDV0 = 8 : AUDF0 = 19

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_001



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Other channel 0 sound effects go here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;
   ;  Jumps to end of channel 0 area. (Catches any mistakes.)
   ;
   goto __Skip_Ch_0



   ;***************************************************************
   ;
   ;  Clears channel 0.
   ;
__Clear_Ch_0
   
   _Ch0_Sound = 0 : AUDV0 = 0



   ;***************************************************************
   ;
   ;  End of channel 0 area.
   ;
__Skip_Ch_0



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   goto __Main_Loop