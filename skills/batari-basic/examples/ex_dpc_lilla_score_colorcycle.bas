   ;***************************************************************
   ;
   ;  Change Score Color (DPC+)
   ;
   ;  Example program by Lillapojkenpaon and adapted by Duane Alan
   ;  Hahn (Random Terrain) using hints, tips, code snippets, and
   ;  more from AtariAge members such as batari, SeaGtGruff,
   ;  RevEng, Robert M, Nukey Shay, Atarius Maximus, jrok,
   ;  supercat, GroovyBee, and bogax.
   ;  
   ;```````````````````````````````````````````````````````````````
   ;
   ;  If this program will not compile for you, get the latest
   ;  version of batari Basic:
   ;  
   ;  http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
   ;  
   ;***************************************************************



   ;****************************************************************
   ;
   ;  This program uses the DPC+ kernel.
   ;
   set kernel DPC+



   ;****************************************************************
   ;
   ;  Standard used in North America and most of South America.
   ;
   set tv ntsc



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
   ;  Slows color change.
   ;
   dim _Speed_Counter = g

   ;```````````````````````````````````````````````````````````````
   ;  Score color.
   ;
   dim _Score_Color = h

   ;```````````````````````````````````````````````````````````````
   ;  All-purpose bits for various jobs.
   ;
   dim _Bit0_Reset_Restrainer = y ; Reset switch becomes inactive if it hasn't been released.




   ;***************************************************************
   ;
   ;  Score color constants.
   ;  [The c stands for constant.]
   ;
   const _c_SCOREDATA_Lo = #<scoredata
   const _c_SCOREDATA_Hi = #((>scoredata) & $0f)



   goto __Bank_2 bank2



   bank 2
   temp1=temp1



__Bank_2





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
   ;  Clears all normal variables and the extra 9.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0
   var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
   var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0


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
   ;  Score color change section.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Adds one to the speed counter.
   ;
   _Speed_Counter = _Speed_Counter + 1

   ;```````````````````````````````````````````````````````````````
   ;  Skips section if counter isn't at the limit.
   ;
   if _Speed_Counter < 6 then goto __Skip_Color_Change

   ;```````````````````````````````````````````````````````````````
   ;  Clears the speed counter.
   ;
   _Speed_Counter = 0

   ;```````````````````````````````````````````````````````````````
   ;  Adds two to the score color variable.
   ;
   _Score_Color = _Score_Color + 2

   ;```````````````````````````````````````````````````````````````
   ;  Color change important code.
   ;
   DF0LOW = _c_SCOREDATA_Lo
   DF0HI = _c_SCOREDATA_Hi

   ;```````````````````````````````````````````````````````````````
   ;  More color change important code.
   ;
   DF0WRITE = _Score_Color
   DF0WRITE = _Score_Color
   DF0WRITE = _Score_Color - 2
   DF0WRITE = _Score_Color - 2
   DF0WRITE = _Score_Color - 4
   DF0WRITE = _Score_Color - 4
   DF0WRITE = _Score_Color - 6
   DF0WRITE = _Score_Color - 6

__Skip_Color_Change



   ;***************************************************************
   ;
   ;  88 rows that are 2 scanlines high.
   ;
   DF6FRACINC = 255 : DF4FRACINC = 255

   DF0FRACINC = 128 : DF1FRACINC = 128 : DF2FRACINC = 128 : DF3FRACINC = 128



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





   bank 3
   temp1=temp1





   bank 4
   temp1=temp1





   bank 5
   temp1=temp1





   bank 6
   temp1=temp1