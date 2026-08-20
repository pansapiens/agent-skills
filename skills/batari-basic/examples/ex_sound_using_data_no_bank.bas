   ;***************************************************************
   ;
   ;  Sound Example Using Data
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
   dim _Ch0_Sound = q
   dim _Ch0_Duration = r
   dim _Ch0_Counter = s

   ;```````````````````````````````````````````````````````````````
   ;  Channel 1 sound variables.
   ;
   dim _Ch1_Sound = t
   dim _Ch1_Duration = u
   dim _Ch1_Counter = v

   ;```````````````````````````````````````````````````````````````
   ;  Keeps the reset switch from repeating when pressed.
   ;
   dim _Bit0_Reset_Restrainer = y



   ;***************************************************************
   ;
   ;  Disables the score.
   ;
   const noscore = 1





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
   ;  Clears all normal variables (fastest way).
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0


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
   ;  Joystick check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips joystick section if a channel 0 sound effect is on.
   ;
   if _Ch0_Sound then goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Up check.
   ;  Turns on channel 0 sound effect 1 if joystick is moved up.
   ;
   if joy0up then _Ch0_Sound = 1 : _Ch0_Duration = 1 : _Ch0_Counter = 0 : COLUBK = $9E : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Down check.
   ;  Turns on channel 0 sound effect 2 if joystick is moved down.
   ;
   if joy0down then _Ch0_Sound = 2 : _Ch0_Duration = 1 : _Ch0_Counter = 0 : COLUBK = $DE : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Left check.
   ;  Turns on channel 0 sound effect 3 if joystick is moved left.
   ;
   if joy0left then _Ch0_Sound = 3 : _Ch0_Duration = 1 : _Ch0_Counter = 0 : COLUBK = $6E : goto __Skip_Joy0

   ;```````````````````````````````````````````````````````````````
   ;  Right check.
   ;  Turns on channel 0 sound effect 4 if joystick is moved right.
   ;
   if joy0right then _Ch0_Sound = 4 : _Ch0_Duration = 1 : _Ch0_Counter = 0 : COLUBK = $1E

__Skip_Joy0



   ;***************************************************************
   ;
   ;  Fire button check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips fire button section if a channel 1 sound effect is on.
   ;
   if _Ch1_Sound then goto __Skip_Fire

   ;```````````````````````````````````````````````````````````````
   ;  Fire button check.
   ;  Turns on channel 1 sound effect 1 if fire button is pressed.
   ;
   if joy0fire then _Ch1_Sound = 1 : _Ch1_Duration = 1 : _Ch1_Counter = 0 : COLUBK = $4A

__Skip_Fire



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
   ;  Skips all channel 0 sounds if duration counter is greater
   ;  than zero
   ;
   if _Ch0_Duration then goto __Skip_Ch_0



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 001.
   ;
   ;  Up sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 001 isn't on.
   ;
   if _Ch0_Sound <> 1 then goto __Skip_Ch0_Sound_001

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Up[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Up[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Up[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets Duration.
   ;
   _Ch0_Duration = _SD_Up[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_001



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 002.
   ;
   ;  Down sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 002 isn't on.
   ;
   if _Ch0_Sound <> 2 then goto __Skip_Ch0_Sound_002

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Down[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Down[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Down[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Down[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_002



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 003.
   ;
   ;  Left sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 003 isn't on.
   ;
   if _Ch0_Sound <> 3 then goto __Skip_Ch0_Sound_003

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Left[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Left[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Left[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Left[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_003



   ;***************************************************************
   ;
   ;  Channel 0 sound effect 004.
   ;
   ;  Right sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 004 isn't on.
   ;
   if _Ch0_Sound <> 4 then goto __Skip_Ch0_Sound_004

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 0 data.
   ;
   temp4 = _SD_Right[_Ch0_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_0

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 0 data.
   ;
   _Ch0_Counter = _Ch0_Counter + 1
   temp5 = _SD_Right[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1
   temp6 = _SD_Right[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 0.
   ;
   AUDV0 = temp4
   AUDC0 = temp5
   AUDF0 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch0_Duration = _SD_Right[_Ch0_Counter] : _Ch0_Counter = _Ch0_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 0 area.
   ;
   goto __Skip_Ch_0

__Skip_Ch0_Sound_004



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
   ;  Channel 1 sound effect check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 1 sounds if sounds are off.
   ;
   if !_Ch1_Sound then goto __Skip_Ch_1

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the channel 1 duration counter.
   ;
   _Ch1_Duration = _Ch1_Duration - 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips all channel 1 sounds if duration counter is greater
   ;  than zero.
   ;
   if _Ch1_Duration then goto __Skip_Ch_1



   ;***************************************************************
   ;
   ;  Channel 1 sound effect 001.
   ;
   ;  Fire button sound effect.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if sound 001 isn't on.
   ;
   if _Ch1_Sound <> 1 then goto __Skip_Chan1_Sound_001

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves first part of channel 1 data.
   ;
   temp4 = _SD_FireB[_Ch1_Counter]

   ;```````````````````````````````````````````````````````````````
   ;  Checks for end of data.
   ;
   if temp4 = 255 then goto __Clear_Ch_1

   ;```````````````````````````````````````````````````````````````
   ;  Retrieves more channel 1 data.
   ;
   _Ch1_Counter = _Ch1_Counter + 1
   temp5 = _SD_FireB[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1
   temp6 = _SD_FireB[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Plays channel 1.
   ;
   AUDV1 = temp4
   AUDC1 = temp5
   AUDF1 = temp6

   ;```````````````````````````````````````````````````````````````
   ;  Sets duration.
   ;
   _Ch1_Duration = _SD_FireB[_Ch1_Counter] : _Ch1_Counter = _Ch1_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to end of channel 1 area.
   ;
   goto __Skip_Ch_1

__Skip_Chan1_Sound_001



   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Other channel 1 sound effects go here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



   ;***************************************************************
   ;
   ;  Jumps to end of channel 1 area. (This catches any mistakes.)
   ;
   goto __Skip_Ch_1



   ;***************************************************************
   ;
   ;  Clears channel 1.
   ;
__Clear_Ch_1
   
   _Ch1_Sound = 0 : AUDV1 = 0



   ;***************************************************************
   ;
   ;  End of channel 1 area.
   ;
__Skip_Ch_1



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





   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  END OF MAIN LOOP
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````




   
   ;***************************************************************
   ;***************************************************************
   ;
   ;
   ;  Sound effect data starts here.
   ;
   ;
   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for up sound effect.
   ;
   data _SD_Up
   9,12,23
   1
   8,12,23
   2
   6,12,23
   2
   5,12,23
   2
   4,12,23
   1
   2,12,23
   8

   9,12,20
   1
   8,12,20
   2
   6,12,20
   2
   5,12,20
   2
   4,12,20
   2
   2,12,20
   8

   9,12,17
   1
   8,12,17
   1
   6,12,17
   6
   5,12,17
   6
   4,12,17
   1
   2,12,17
   8

   9,12,20
   1
   8,12,20
   1
   6,12,20
   1
   5,12,20
   1
   4,12,20
   1
   2,12,20
   8

   9,12,23
   1
   8,12,23
   1
   6,12,23
   1
   5,12,23
   1
   4,12,23
   1
   2,12,23
   8

   9,12,20
   1
   8,12,20
   1
   6,12,20
   1
   5,12,20
   1
   4,12,20
   1
   2,12,20
   8

   9,12,26
   1
   8,12,26
   1
   6,12,26
   1
   5,12,26
   1
   4,12,26
   1
   2,12,26
   8
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for down sound effect.
   ;
   data _SD_Down
   8,4,25
   1
   8,4,24
   1
   8,4,27
   1
   8,4,23
   1
   8,4,26
   1
   8,4,28
   1
   8,4,25
   1
   8,4,23
   1
   8,4,28
   1
   8,4,24
   1
   8,4,28
   1
   8,4,25
   1
   8,4,26
   1
   8,4,25
   1
   8,4,23
   1
   8,4,27
   1
   8,4,24
   1
   8,4,26
   1
   8,4,28
   1
   8,4,27
   1
   8,4,25
   1
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for left sound effect.
   ;
   data _SD_Left
   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   1

   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   18


   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   1

   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   18


   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   2

   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   2

   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   2

   5,8,2
   1
   4,8,2
   1
   3,8,2
   1
   2,8,2
   1
   1,8,2
   1
   0,8,2
   18

   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for right sound effect.
   ;
   data _SD_Right
   15,8,2
   1
   8,8,2
   1
   4,8,2
   1
   0,8,2
   4

   15,8,2
   1
   8,8,2
   1
   4,8,2
   1
   0,8,2
   4

   15,8,2
   1
   8,8,2
   1
   4,8,2
   1
   0,8,2
   11

   15,8,2
   1
   8,8,2
   1
   4,8,2
   1
   0,8,2
   4
   0,0,0
   8
   255
end



   ;***************************************************************
   ;***************************************************************
   ;
   ;  Sound data for fire button sound effect.
   ;
   data _SD_FireB
   2,12,17
   1
   4,12,17
   1
   8,12,17
   7
   4,12,17
   1
   2,12,17
   8


   2,12,26
   1
   4,12,26
   1
   8,12,26
   12
   4,12,26
   1
   2,12,26
   8

   2,12,17
   1
   4,12,17
   1
   8,12,17
   7
   4,12,17
   1
   2,12,17
   8

   2,12,29
   1
   4,12,29
   1
   8,12,29
   12
   4,12,29
   1
   2,12,29
   8


   2,12,29
   1
   4,12,29
   1
   8,12,29
   3
   4,12,29
   1
   2,12,29
   8


   2,12,23
   1
   4,12,23
   1
   8,12,23
   3
   4,12,23
   1
   2,12,23
   8

   2,12,26
   1
   4,12,26
   1
   8,12,26
   3
   4,12,26
   1
   2,12,26
   8


   2,12,19
   1
   4,12,19
   1
   8,12,19
   12
   4,12,19
   1
   2,12,19
   8

   2,12,17
   1
   4,12,17
   1
   8,12,17
   7
   4,12,17
   1
   2,12,17
   8

   2,12,26
   1
   4,12,26
   1
   8,12,26
   12
   4,12,26
   1
   2,12,26
   8

   2,12,19
   1
   4,12,19
   1
   8,12,19
   7
   4,12,19
   1
   2,12,19
   8

   2,12,29
   1
   4,12,29
   1
   8,12,29
   12
   4,12,29
   1
   2,12,29
   8
   255
end