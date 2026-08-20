   ;***************************************************************
   ;
   ;  Routine Size Comparison by RevEng
   ;
   ;  Adapted by Duane Alan Hahn (Random Terrain).
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Insert your routines, then compile the program. The bytes
   ;  used in each section will be displayed above how many bytes
   ;  of ROM space are left.
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  If this program will not compile for you, get the latest
   ;  version of batari Basic:
   ;  
   ;  http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
   ;  
   ;***************************************************************


   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Any Kernel options, optimizations, or variable aliases that
   ;  you might need go here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````



__Routine1_Start

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your first routine goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````

__Routine1_End



__Routine2_Start

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your second routine goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````

__Routine2_End



__Routine3_Start

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Your third routine goes here.
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````

__Routine3_End



   ;***************************************************************
   ;
   ;  This is where the magic happens.
   ;
   asm
   echo "Routine 1: ",(.__Routine1_End-.__Routine1_Start)d
   echo "Routine 2: ",(.__Routine2_End-.__Routine2_Start)d
   echo "Routine 3: ",(.__Routine3_End-.__Routine3_Start)d
end