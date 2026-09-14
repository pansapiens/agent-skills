; ex_computed_collision.bas — data-driven collision without pfread
; Pattern from an 8-level SMB demake: level geometry stored as rule
; tables, collision computed with a goto-free for-next walk.
;
; THE CRITICAL CONSTRAINT: never use goto labels inside for-next.
; The safe pattern is pairs of if-then statements — see below.
;
; Build: scripts/bb-build.sh ex_computed_collision.bas

   set smartbranching on
   set tv ntsc
   set romsize 8k

   dim _cam = b
   dim _frame = a

   ; Level rules: each row of the level is a set of "runs" (spans).
   ; _lvlrow[n] = which playfield row (0-11)
   ; _lvlstart[n] = first column of the run
   ; _lvllen[n] = length of the run
   ; The floor (rows 9,10) spans all columns.
   data _lvlrow
   5, 5, 9, 10
end
   data _lvlstart
   8, 20, 0, 0
end
   data _lvllen
   3, 4, 32, 32
end

   player0x = 50 : player0y = 60
   COLUP0 = $2E
   player0:
   %00111100
   %01111110
   %11111111
   %11111111
   %01111110
   %00111100
end

mainloop
   _frame = _frame + 1
   if joy0left then player0x = player0x - 1
   if joy0right then player0x = player0x + 1
   if joy0up then player0y = player0y - 1
   if joy0down then player0y = player0y + 1

   ; --- THE SAFE WALK (goto-free) ---
   ; Check if the sprite's position overlaps any solid run.
   ; temp4 = column (playfield x 0-31)
   ; temp5 = row (playfield y 0-11)
   ; temp3 = result (1 = solid)
   temp4 = (player0x - 17) / 4
   temp5 = player0y / 8
   gosub checksolid
   if temp3 then player0y = temp5 * 8 - 8

   ; Draw the level from the same rules
   gosub drawlevel

   drawscreen
   goto mainloop

checksolid
   ; Scan all rules, check row match, then column range
   temp3 = 0
   if temp4 > 31 then return
   for temp6 = 0 to 3
      ; THESE TWO LINES ARE THE PATTERN — no goto, no labels
      if _lvlrow[temp6] = temp5 then temp2 = temp4 - _lvlstart[temp6]
      if _lvlrow[temp6] = temp5 then if temp2 < _lvllen[temp6] then temp3 = 1
   next
   return

drawlevel
   ; Simple: draw each rule as pf pixels
   pfclear
   for temp6 = 0 to 3
      temp5 = _lvlrow[temp6]
      temp1 = _lvlstart[temp6]
      temp3 = _lvllen[temp6]
      for temp2 = 0 to temp3 - 1
         temp4 = temp1 + temp2
         if temp4 < 32 then pfpixel temp4 temp5 on
      next
   next
   return
