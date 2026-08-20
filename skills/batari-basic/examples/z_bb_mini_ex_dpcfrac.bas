   ;***************************************************************
   ;
   ;  Example Program by RevEng
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  Date created: 2013y_08m_7d
   ;
   ;  Date Updated: 2025y_01m_21d_1853t
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



   goto __Start_Restart bank2




   bank 2




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
   ;  Frame counter.
   ;
   dim _Frame = a

   ;```````````````````````````````````````````````````````````````
   ;  Bits for various jobs.
   ;
   dim _Bit3_Joy0_UpDown = t




   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  Score colors.
   ;
   scorecolors:
   $3E
   $3C
   $3A
   $3A
   $38
   $38
   $36
   $36
end


   ;***************************************************************
   ;
   ;  Playfield data.
   ;
   playfield:
   ..XXXX....XXXX....XXXX....XXXX..
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
   ................................
   ....X.......X.......X.......X...
   ...XX......XX......XX......XX...
   ..XXX.....XXX.....XXX.....XXX...
   ...XX......XX......XX......XX...
   ...XX......XX......XX......XX...
   ...XX......XX......XX......XX...
   ...XX......XX......XX......XX...
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   ................................
   ................................
   ..XXXX....XXXX....XXXX....XXXX..
   .X...XX..X...XX..X...XX..X...XX.
   .....XX......XX......XX......XX.
   .....XX......XX......XX......XX.
   ..XXXX....XXXX....XXXX....XXXX..
   .XX......XX......XX......XX.....
   .XX......XX......XX......XX.....
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   ................................
   ................................
   ..XXXX....XXXX....XXXX....XXXX..
   .X...XX..X...XX..X...XX..X...XX.
   .....XX......XX......XX......XX.
   ...XXX.....XXX.....XXX.....XXX..
   .....XX......XX......XX......XX.
   .....XX......XX......XX......XX.
   .X...XX..X...XX..X...XX..X...XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
   ................................
   ....XX......XX......XX......XX..
   ...XXX.....XXX.....XXX.....XXX..
   ..X.XX....X.XX....X.XX....X.XX..
   .X..XX...X..XX...X..XX...X..XX..
   .X..XX...X..XX...X..XX...X..XX..
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   ....XX......XX......XX......XX..
   ....XX......XX......XX......XX..
   ................................
   ................................
   .XXXXXX..XXXXXX..XXXXXX..XXXXXX.
   .XX......XX......XX......XX.....
   .XX......XX......XX......XX.....
   ..XXXX....XXXX....XXXX....XXXX..
   .....XX......XX......XX......XX.
   .....XX......XX......XX......XX.
   .X...XX..X...XX..X...XX..X...XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
   ................................
   ..XXXX....XXXX....XXXX....XXXX..
   .XX...X..XX...X..XX...X..XX...X.
   .XX......XX......XX......XX.....
   .XXXXX...XXXXX...XXXXX...XXXXX..
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
   ................................
   ..XXXXX...XXXXX...XXXXX...XXXXX.
   .X....X..X....X..X....X..X....X.
   .....XX......XX......XX......XX.
   ....XX......XX......XX......XX..
   ...XX......XX......XX......XX...
   ..XX......XX......XX......XX....
   ..XX......XX......XX......XX....
   ..XX......XX......XX......XX....
   ................................
   ................................
   ..XXXX....XXXX....XXXX....XXXX..
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   ..XXXX....XXXX....XXXX....XXXX..
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
   ................................
   ..XXXX....XXXX....XXXX....XXXX.. 
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   .XX..XX..XX..XX..XX..XX..XX..XX.
   ..XXXXX...XXXXX...XXXXX...XXXXX.
   .....XX......XX......XX......XX.
   .X...XX..X...XX..X...XX..X...XX.
   ..XXXX....XXXX....XXXX....XXXX..
   ................................
end


   ;***************************************************************
   ;
   ;  Playfield color.
   ;
   pfcolors:
   $86
end


   ;***************************************************************
   ;
   ;  Sets effect direction.
   ;
   _Bit3_Joy0_UpDown{3} = 0




   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_loop



   ;***************************************************************
   ;
   ;  Fracle rock.
   ;
   DF0FRACINC = _Frame + 128 ; Column 0.
   DF1FRACINC = _Frame + 64 ;  Column 1.
   DF2FRACINC = _Frame + 32 ;  Column 2.
   DF3FRACINC = _Frame ;       Column 3.



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Changes effect based on up or down joystick movement.
   ;
   if joy0up then _Bit3_Joy0_UpDown{3} = 0

   if joy0down then _Bit3_Joy0_UpDown{3} = 1



   ;***************************************************************
   ;
   ;  Adds to or subtracts from the frame counter.
   ;
   if !_Bit3_Joy0_UpDown{3} then _Frame = _Frame + 1

   if _Bit3_Joy0_UpDown{3} then _Frame = _Frame - 1



   goto __Main_loop