   ;***************************************************************
   ;
   ;  Sound Example Without Data
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain) using
   ;  hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Instructions:
   ;  
   ;  Move the joystick in 4 directions and press the fire button
   ;  to hear sounds.
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
   ;  Channel 0 sound variables.
   ;
   dim _Ch0_Sound = c
   dim _Ch0_Duration = d
   dim _C0 = e
   dim _V0 = f
   dim _F0 = g



   ;***************************************************************
   ;
   ;  Disables the score.
   ;
   const noscore = 1





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Joystick check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips joystick section if a channel 0 sound effect is on.
   ;
   if _Ch0_Sound then goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Fire button check.
   ;  Turns on channel 0 sound effect 1 if fire button is pressed.
   ;
   if joy0fire then _Ch0_Sound = 1 : _Ch0_Duration = 15 :  COLUBK = $4A : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Up check.
   ;  Turns on channel 0 sound effect 2 if joystick is moved up.
   ;
   if joy0up then _Ch0_Sound = 2 : _Ch0_Duration = 30 : _V0 = 12 : COLUBK = $9E : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Down check.
   ;  Turns on channel 0 sound effect 3 if joystick is moved down.
   ;
   if joy0down then _Ch0_Sound = 3 : _Ch0_Duration = 32 : _F0 = 31 : COLUBK = $DE : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Left check.
   ;  Turns on channel 0 sound effect 4 if joystick is moved left.
   ;
   if joy0left then _Ch0_Sound = 4 : _Ch0_Duration = 32 : _V0 = 12 : _F0 = 31 : COLUBK = $6E : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Right check.
   ;  Turns on channel 0 sound effect 5 if joystick is moved right.
   ;
   if joy0right then _Ch0_Sound = 5 : _Ch0_Duration = 32 : _C0 = 4 : _V0 = 12 : _F0 = 31 : COLUBK = $1E

__Skip_Joy0



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



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 002.
   ;
   ;  A slightly less lazy sound since the volume changes.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 002 isn't on.
   ;
   if _Ch0_Sound <> 2 then goto __Skip_Ch0_Sound_002

   ;```````````````````````````````````````````````````````````````
   ;  Sets the tone, volume and frequency.
   ;
   AUDC0 = 4 : AUDV0 = _V0 : AUDF0 = 19

   ;```````````````````````````````````````````````````````````````
   ;  Only looks at the even/odd bit.
   ;
   temp5 = _Ch0_Duration & %00000001

   ;```````````````````````````````````````````````````````````````
   ;  Decreases volume only when _Ch0_Duration is an odd number.
   ;
   if temp5 && _V0 then _V0 = _V0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_002



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 003.
   ;
   ;  Only the frequency changes.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 003 isn't on.
   ;
   if _Ch0_Sound <> 3 then goto __Skip_Ch0_Sound_003

   ;```````````````````````````````````````````````````````````````
   ;  Sets the tone, volume and frequency.
   ;
   AUDC0 = 4 : AUDV0 = 8 : AUDF0 = _F0

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the frequency variable.
   ;
   _F0 = _F0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_003



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 004.
   ;
   ;  The volume and the frequency changes.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 004 isn't on.
   ;
   if _Ch0_Sound <> 4 then goto __Skip_Ch0_Sound_004

   ;```````````````````````````````````````````````````````````````
   ;  Sets the tone, volume and frequency.
   ;
   AUDC0 = 4 : AUDV0 = _V0 : AUDF0 = _F0

   ;```````````````````````````````````````````````````````````````
   ;  Only looks at the even/odd bit.
   ;
   temp5 = _Ch0_Duration & %00000001

   ;```````````````````````````````````````````````````````````````
   ;  Decreases volume only when _Ch0_Duration is an odd number.
   ;
   if temp5 && _V0 then _V0 = _V0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the frequency variable.
   ;
   if _F0 then _F0 = _F0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_004



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 005.
   ;
   ;  The tone, volume, and frequency changes.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 005 isn't on.
   ;
   if _Ch0_Sound <> 5 then goto __Skip_Ch0_Sound_005

   ;```````````````````````````````````````````````````````````````
   ;  Sets the tone, volume and frequency.
   ;
   AUDC0 = _C0 : AUDV0 = _V0 : AUDF0 = _F0

   ;```````````````````````````````````````````````````````````````
   ;  Flips the tone between 4 and 12.
   ;
   _C0 = _C0 ^ 8

   ;```````````````````````````````````````````````````````````````
   ;  Only looks at the even/odd bit.
   ;
   temp5 = _Ch0_Duration & %00000001

   ;```````````````````````````````````````````````````````````````
   ;  Decreases volume only when _Ch0_Duration is an odd number.
   ;
   if temp5 && _V0 then _V0 = _V0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the frequency variable.
   ;
   if _F0 then _F0 = _F0 - 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_005



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Other channel 0 sound effects go here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;
   ;  Jumps to end of channel 0 area. (This catches any mistakes.)
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