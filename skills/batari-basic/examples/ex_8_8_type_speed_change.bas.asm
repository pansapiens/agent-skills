; Provided under the CC0 license. See the included LICENSE.txt for details.

 processor 6502
 include "vcs.h"
 include "macro.h"
 include "2600basic.h"
 include "2600basic_variable_redefs.h"
 ifconst bankswitch
  if bankswitch == 8
     ORG $1000
     RORG $D000
  endif
  if bankswitch == 16
     ORG $1000
     RORG $9000
  endif
  if bankswitch == 32
     ORG $1000
     RORG $1000
  endif
  if bankswitch == 64
     ORG $1000
     RORG $1000
  endif
 else
   ORG $F000
 endif

 ifconst bankswitch_hotspot
 if bankswitch_hotspot = $083F ; 0840 bankswitching hotspot
   .byte 0 ; stop unexpected bankswitches
 endif
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

start
 sei
 cld
 ldy #0
 lda $D0
 cmp #$2C               ;check RAM location #1
 bne MachineIs2600
 lda $D1
 cmp #$A9               ;check RAM location #2
 bne MachineIs2600
 dey
MachineIs2600
 ldx #0
 txa
clearmem
 inx
 txs
 pha
 bne clearmem
 sty temp1
 ifnconst multisprite
 ifconst pfrowheight
 lda #pfrowheight
 else
 ifconst pfres
 lda #(96/pfres)
 else
 lda #8
 endif
 endif
 sta playfieldpos
 endif
 ldx #5
initscore
 lda #<scoretable
 sta scorepointers,x 
 dex
 bpl initscore
 lda #1
 sta CTRLPF
 ora INTIM
 sta rand

 ifconst multisprite
   jsr multisprite_setup
 endif

 ifnconst bankswitch
   jmp game
 else
   lda #>(game-1)
   pha
   lda #<(game-1)
   pha
   pha
   pha
   ldx #1
   jmp BS_jsr
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

     ; This is a 2-line kernel!
     ifnconst vertical_reflect
kernel
     endif
     sta WSYNC
     lda #255
     sta TIM64T

     lda #1
     sta VDELBL
     sta VDELP0
     ldx ballheight
     inx
     inx
     stx temp4
     lda player1y
     sta temp3

     ifconst shakescreen
         jsr doshakescreen
     else
         ldx missile0height
         inx
     endif

     inx
     stx stack1

     lda bally
     sta stack2

     lda player0y
     ldx #0
     sta WSYNC
     stx GRP0
     stx GRP1
     stx PF1L
     stx PF2
     stx CXCLR
     ifconst readpaddle
         stx paddle
     else
         sleep 3
     endif

     sta temp2,x

     ;store these so they can be retrieved later
     ifnconst pfres
         ldx #128-44+(4-pfwidth)*12
     else
         ldx #132-pfres*pfwidth
     endif

     dec player0y

     lda missile0y
     sta temp5
     lda missile1y
     sta temp6

     lda playfieldpos
     sta temp1
     
     ifconst pfrowheight
         lda #pfrowheight+2
     else
         ifnconst pfres
             lda #10
         else
             lda #(96/pfres)+2 ; try to come close to the real size
         endif
     endif
     clc
     sbc playfieldpos
     sta playfieldpos
     jmp .startkernel

.skipDrawP0
     lda #0
     tay
     jmp .continueP0

.skipDrawP1
     lda #0
     tay
     jmp .continueP1

.kerloop     ; enter at cycle 59??

continuekernel
     sleep 2
continuekernel2
     lda ballheight
     
     ifconst pfres
         ldy playfield+pfres*pfwidth-132,x
         sty PF1L ;3
         ldy playfield+pfres*pfwidth-131-pfadjust,x
         sty PF2L ;3
         ldy playfield+pfres*pfwidth-129,x
         sty PF1R ; 3 too early?
         ldy playfield+pfres*pfwidth-130-pfadjust,x
         sty PF2R ;3
     else
         ldy playfield-48+pfwidth*12+44-128,x
         sty PF1L ;3
         ldy playfield-48+pfwidth*12+45-128-pfadjust,x ;4
         sty PF2L ;3
         ldy playfield-48+pfwidth*12+47-128,x ;4
         sty PF1R ; 3 too early?
         ldy playfield-48+pfwidth*12+46-128-pfadjust,x;4
         sty PF2R ;3
     endif

     ; should be playfield+$38 for width=2

     dcp bally
     rol
     rol
     ; rol
     ; rol
goback
     sta ENABL 
.startkernel
     lda player1height ;3
     dcp player1y ;5
     bcc .skipDrawP1 ;2
     ldy player1y ;3
     lda (player1pointer),y ;5; player0pointer must be selected carefully by the compiler
     ; so it doesn't cross a page boundary!

.continueP1
     sta GRP1 ;3

     ifnconst player1colors
         lda missile1height ;3
         dcp missile1y ;5
         rol;2
         rol;2
         sta ENAM1 ;3
     else
         lda (player1color),y
         sta COLUP1
         ifnconst playercolors
             sleep 7
         else
             lda.w player0colorstore
             sta COLUP0
         endif
     endif

     ifconst pfres
         lda playfield+pfres*pfwidth-132,x 
         sta PF1L ;3
         lda playfield+pfres*pfwidth-131-pfadjust,x 
         sta PF2L ;3
         lda playfield+pfres*pfwidth-129,x 
         sta PF1R ; 3 too early?
         lda playfield+pfres*pfwidth-130-pfadjust,x 
         sta PF2R ;3
     else
         lda playfield-48+pfwidth*12+44-128,x ;4
         sta PF1L ;3
         lda playfield-48+pfwidth*12+45-128-pfadjust,x ;4
         sta PF2L ;3
         lda playfield-48+pfwidth*12+47-128,x ;4
         sta PF1R ; 3 too early?
         lda playfield-48+pfwidth*12+46-128-pfadjust,x;4
         sta PF2R ;3
     endif 
     ; sleep 3

     lda player0height
     dcp player0y
     bcc .skipDrawP0
     ldy player0y
     lda (player0pointer),y
.continueP0
     sta GRP0

     ifnconst no_blank_lines
         ifnconst playercolors
             lda missile0height ;3
             dcp missile0y ;5
             sbc stack1
             sta ENAM0 ;3
         else
             lda (player0color),y
             sta player0colorstore
             sleep 6
         endif
         dec temp1
         bne continuekernel
     else
         dec temp1
         beq altkernel2
         ifconst readpaddle
             ldy currentpaddle
             lda INPT0,y
             bpl noreadpaddle
             inc paddle
             jmp continuekernel2
noreadpaddle
             sleep 2
             jmp continuekernel
         else
             ifnconst playercolors 
                 ifconst PFcolors
                     txa
                     tay
                     lda (pfcolortable),y
                     ifnconst backgroundchange
                         sta COLUPF
                     else
                         sta COLUBK
                     endif
                     jmp continuekernel
                 else
                     ifconst kernelmacrodef
                         kernelmacro
                     else
                         sleep 12
                     endif
                 endif
             else
                 lda (player0color),y
                 sta player0colorstore
                 sleep 4
             endif
             jmp continuekernel
         endif
altkernel2
         txa
         ifnconst vertical_reflect
             sbx #256-pfwidth
         else
             sbx #256-pfwidth/2
         endif
         bmi lastkernelline
         ifconst pfrowheight
             lda #pfrowheight
         else
             ifnconst pfres
                 lda #8
             else
                 lda #(96/pfres) ; try to come close to the real size
             endif
         endif
         sta temp1
         jmp continuekernel
     endif

altkernel

     ifconst PFmaskvalue
         lda #PFmaskvalue
     else
         lda #0
     endif
     sta PF1L
     sta PF2


     ;sleep 3

     ;28 cycles to fix things
     ;minus 11=17

     ; lax temp4
     ; clc
     txa
     ifnconst vertical_reflect
         sbx #256-pfwidth
     else
         sbx #256-pfwidth/2
     endif

     bmi lastkernelline

     ifconst PFcolorandheight
         ifconst pfres
             ldy playfieldcolorandheight-131+pfres*pfwidth,x
         else
             ldy playfieldcolorandheight-87,x
         endif
         ifnconst backgroundchange
             sty COLUPF
         else
             sty COLUBK
         endif
         ifconst pfres
             lda playfieldcolorandheight-132+pfres*pfwidth,x
         else
             lda playfieldcolorandheight-88,x
         endif
         sta.w temp1
     endif
     ifconst PFheights
         lsr
         lsr
         tay
         lda (pfheighttable),y
         sta.w temp1
     endif
     ifconst PFcolors
         tay
         lda (pfcolortable),y
         ifnconst backgroundchange
             sta COLUPF
         else
             sta COLUBK
         endif
         ifconst pfrowheight
             lda #pfrowheight
         else
             ifnconst pfres
                 lda #8
             else
                 lda #(96/pfres) ; try to come close to the real size
             endif
         endif
         sta temp1
     endif
     ifnconst PFcolorandheight
         ifnconst PFcolors
             ifnconst PFheights
                 ifnconst no_blank_lines
                     ; read paddle 0
                     ; lo-res paddle read
                     ; bit INPT0
                     ; bmi paddleskipread
                     ; inc paddle0
                     ;donepaddleskip
                     sleep 10
                     ifconst pfrowheight
                         lda #pfrowheight
                     else
                         ifnconst pfres
                             lda #8
                         else
                             lda #(96/pfres) ; try to come close to the real size
                         endif
                     endif
                     sta temp1
                 endif
             endif
         endif
     endif
     

     lda ballheight
     dcp bally
     sbc temp4


     jmp goback


     ifnconst no_blank_lines
lastkernelline
         ifnconst PFcolors
             sleep 10
         else
             ldy #124
             lda (pfcolortable),y
             sta COLUPF
         endif

         ifconst PFheights
             ldx #1
             ;sleep 4
             sleep 3 ; this was over 1 cycle
         else
             ldx playfieldpos
             ;sleep 3
             sleep 2 ; this was over 1 cycle
         endif

         jmp enterlastkernel

     else
lastkernelline
         
         ifconst PFheights
             ldx #1
             ;sleep 5
             sleep 4 ; this was over 1 cycle
         else
             ldx playfieldpos
             ;sleep 4
             sleep 3 ; this was over 1 cycle
         endif

         cpx #0
         bne .enterfromNBL
         jmp no_blank_lines_bailout
     endif

     if ((<*)>$d5)
         align 256
     endif
     ; this is a kludge to prevent page wrapping - fix!!!

.skipDrawlastP1
     lda #0
     tay ; added so we don't cross a page
     jmp .continuelastP1

.endkerloop     ; enter at cycle 59??
     
     nop

.enterfromNBL
     ifconst pfres
         ldy.w playfield+pfres*pfwidth-4
         sty PF1L ;3
         ldy.w playfield+pfres*pfwidth-3-pfadjust
         sty PF2L ;3
         ldy.w playfield+pfres*pfwidth-1
         sty PF1R ; possibly too early?
         ldy.w playfield+pfres*pfwidth-2-pfadjust
         sty PF2R ;3
     else
         ldy.w playfield-48+pfwidth*12+44
         sty PF1L ;3
         ldy.w playfield-48+pfwidth*12+45-pfadjust
         sty PF2L ;3
         ldy.w playfield-48+pfwidth*12+47
         sty PF1R ; possibly too early?
         ldy.w playfield-48+pfwidth*12+46-pfadjust
         sty PF2R ;3
     endif

enterlastkernel
     lda ballheight

     ; tya
     dcp bally
     ; sleep 4

     ; sbc stack3
     rol
     rol
     sta ENABL 

     lda player1height ;3
     dcp player1y ;5
     bcc .skipDrawlastP1
     ldy player1y ;3
     lda (player1pointer),y ;5; player0pointer must be selected carefully by the compiler
     ; so it doesn't cross a page boundary!

.continuelastP1
     sta GRP1 ;3

     ifnconst player1colors
         lda missile1height ;3
         dcp missile1y ;5
     else
         lda (player1color),y
         sta COLUP1
     endif

     dex
     ;dec temp4 ; might try putting this above PF writes
     beq endkernel


     ifconst pfres
         ldy.w playfield+pfres*pfwidth-4
         sty PF1L ;3
         ldy.w playfield+pfres*pfwidth-3-pfadjust
         sty PF2L ;3
         ldy.w playfield+pfres*pfwidth-1
         sty PF1R ; possibly too early?
         ldy.w playfield+pfres*pfwidth-2-pfadjust
         sty PF2R ;3
     else
         ldy.w playfield-48+pfwidth*12+44
         sty PF1L ;3
         ldy.w playfield-48+pfwidth*12+45-pfadjust
         sty PF2L ;3
         ldy.w playfield-48+pfwidth*12+47
         sty PF1R ; possibly too early?
         ldy.w playfield-48+pfwidth*12+46-pfadjust
         sty PF2R ;3
     endif

     ifnconst player1colors
         rol;2
         rol;2
         sta ENAM1 ;3
     else
         ifnconst playercolors
             sleep 7
         else
             lda.w player0colorstore
             sta COLUP0
         endif
     endif
     
     lda.w player0height
     dcp player0y
     bcc .skipDrawlastP0
     ldy player0y
     lda (player0pointer),y
.continuelastP0
     sta GRP0



     ifnconst no_blank_lines
         lda missile0height ;3
         dcp missile0y ;5
         sbc stack1
         sta ENAM0 ;3
         jmp .endkerloop
     else
         ifconst readpaddle
             ldy currentpaddle
             lda INPT0,y
             bpl noreadpaddle2
             inc paddle
             jmp .endkerloop
noreadpaddle2
             sleep 4
             jmp .endkerloop
         else ; no_blank_lines and no paddle reading
             pla
             pha ; 14 cycles in 4 bytes
             pla
             pha
             ; sleep 14
             jmp .endkerloop
         endif
     endif


     ; ifconst donepaddleskip
         ;paddleskipread
         ; this is kind of lame, since it requires 4 cycles from a page boundary crossing
         ; plus we get a lo-res paddle read
         ; bmi donepaddleskip
     ; endif

.skipDrawlastP0
     lda #0
     tay
     jmp .continuelastP0

     ifconst no_blank_lines
no_blank_lines_bailout
         ldx #0
     endif

endkernel
     ; 6 digit score routine
     stx PF1
     stx PF2
     stx PF0
     clc

     ifconst pfrowheight
         lda #pfrowheight+2
     else
         ifnconst pfres
             lda #10
         else
             lda #(96/pfres)+2 ; try to come close to the real size
         endif
     endif

     sbc playfieldpos
     sta playfieldpos
     txa

     ifconst shakescreen
         bit shakescreen
         bmi noshakescreen2
         ldx #$3D
noshakescreen2
     endif

     sta WSYNC,x

     ; STA WSYNC ;first one, need one more
     sta REFP0
     sta REFP1
     STA GRP0
     STA GRP1
     ; STA PF1
     ; STA PF2
     sta HMCLR
     sta ENAM0
     sta ENAM1
     sta ENABL

     lda temp2 ;restore variables that were obliterated by kernel
     sta player0y
     lda temp3
     sta player1y
     ifnconst player1colors
         lda temp6
         sta missile1y
     endif
     ifnconst playercolors
         ifnconst readpaddle
             lda temp5
             sta missile0y
         endif
     endif
     lda stack2
     sta bally

     ; strangely, this isn't required any more. might have
     ; resulted from the no_blank_lines score bounce fix
     ;ifconst no_blank_lines
         ;sta WSYNC
     ;endif

     lda INTIM
     clc
     ifnconst vblank_time
         adc #43+12+87
     else
         adc #vblank_time+12+87

     endif
     ; sta WSYNC
     sta TIM64T

     ifconst minikernel
         jsr minikernel
     endif

     ; now reassign temp vars for score pointers

     ; score pointers contain:
     ; score1-5: lo1,lo2,lo3,lo4,lo5,lo6
     ; swap lo2->temp1
     ; swap lo4->temp3
     ; swap lo6->temp5
     ifnconst noscore
         lda scorepointers+1
         ; ldy temp1
         sta temp1
         ; sty scorepointers+1

         lda scorepointers+3
         ; ldy temp3
         sta temp3
         ; sty scorepointers+3


         sta HMCLR
         tsx
         stx stack1 
         ldx #$E0
         stx HMP0

         LDA scorecolor 
         STA COLUP0
         STA COLUP1
         ifconst scorefade
             STA stack2
         endif
         ifconst pfscore
             lda pfscorecolor
             sta COLUPF
         endif
         sta WSYNC
         ldx #0
         STx GRP0
         STx GRP1 ; seems to be needed because of vdel

         lda scorepointers+5
         ; ldy temp5
         sta temp5,x
         ; sty scorepointers+5
         lda #>scoretable
         sta scorepointers+1
         sta scorepointers+3
         sta scorepointers+5
         sta temp2
         sta temp4
         sta temp6
         LDY #7
         STY VDELP0
         STA RESP0
         STA RESP1


         LDA #$03
         STA NUSIZ0
         STA NUSIZ1
         STA VDELP1
         LDA #$F0
         STA HMP1
         lda (scorepointers),y
         sta GRP0
         STA HMOVE ; cycle 73 ?
         jmp beginscore


         if ((<*)>$d4)
             align 256 ; kludge that potentially wastes space! should be fixed!
         endif

loop2
         lda (scorepointers),y ;+5 68 204
         sta GRP0 ;+3 71 213 D1 -- -- --
         ifconst pfscore
             lda.w pfscore1
             sta PF1
         else
             ifconst scorefade
                 sleep 2
                 dec stack2 ; decrement the temporary scorecolor
             else
                 sleep 7
             endif
         endif
         ; cycle 0
beginscore
         lda (scorepointers+$8),y ;+5 5 15
         sta GRP1 ;+3 8 24 D1 D1 D2 --
         lda (scorepointers+$6),y ;+5 13 39
         sta GRP0 ;+3 16 48 D3 D1 D2 D2
         lax (scorepointers+$2),y ;+5 29 87
         txs
         lax (scorepointers+$4),y ;+5 36 108
         ifconst scorefade
             lda stack2
         else
             sleep 3
         endif

         ifconst pfscore
             lda pfscore2
             sta PF1
         else
             ifconst scorefade
                 sta COLUP0
                 sta COLUP1
             else
                 sleep 6
             endif
         endif

         lda (scorepointers+$A),y ;+5 21 63
         stx GRP1 ;+3 44 132 D3 D3 D4 D2!
         tsx
         stx GRP0 ;+3 47 141 D5 D3! D4 D4
         sta GRP1 ;+3 50 150 D5 D5 D6 D4!
         sty GRP0 ;+3 53 159 D4* D5! D6 D6
         dey
         bpl loop2 ;+2 60 180

         ldx stack1 
         txs
         ; lda scorepointers+1
         ldy temp1
         ; sta temp1
         sty scorepointers+1

         LDA #0 
         sta PF1
         STA GRP0
         STA GRP1
         STA VDELP0
         STA VDELP1;do we need these
         STA NUSIZ0
         STA NUSIZ1

         ; lda scorepointers+3
         ldy temp3
         ; sta temp3
         sty scorepointers+3

         ; lda scorepointers+5
         ldy temp5
         ; sta temp5
         sty scorepointers+5
     endif ;noscore
    ifconst readpaddle
        lda #%11000010
    else
        ifconst qtcontroller
            lda qtcontroller
            lsr    ; bit 0 in carry
            lda #4
            ror    ; carry into top of A
        else
            lda #2
        endif ; qtcontroller
    endif ; readpaddle
 sta WSYNC
 sta VBLANK
 RETURN
     ifconst shakescreen
doshakescreen
         bit shakescreen
         bmi noshakescreen
         sta WSYNC
noshakescreen
         ldx missile0height
         inx
         rts
     endif

; Provided under the CC0 license. See the included LICENSE.txt for details.

; playfield drawing routines
; you get a 32x12 bitmapped display in a single color :)
; 0-31 and 0-11

pfclear ; clears playfield - or fill with pattern
 ifconst pfres
 ldx #pfres*pfwidth-1
 else
 ldx #47-(4-pfwidth)*12 ; will this work?
 endif
pfclear_loop
 ifnconst superchip
 sta playfield,x
 else
 sta playfield-128,x
 endif
 dex
 bpl pfclear_loop
 RETURN
 
setuppointers
 stx temp2 ; store on.off.flip value
 tax ; put x-value in x 
 lsr
 lsr
 lsr ; divide x pos by 8 
 sta temp1
 tya
 asl
 if pfwidth=4
  asl ; multiply y pos by 4
 endif ; else multiply by 2
 clc
 adc temp1 ; add them together to get actual memory location offset
 tay ; put the value in y
 lda temp2 ; restore on.off.flip value
 rts

pfread
;x=xvalue, y=yvalue
 jsr setuppointers
 lda setbyte,x
 and playfield,y
 eor setbyte,x
; beq readzero
; lda #1
; readzero
 RETURN

pfpixel
;x=xvalue, y=yvalue, a=0,1,2
 jsr setuppointers

 ifconst bankswitch
 lda temp2 ; load on.off.flip value (0,1, or 2)
 beq pixelon_r  ; if "on" go to on
 lsr
 bcs pixeloff_r ; value is 1 if true
 lda playfield,y ; if here, it's "flip"
 eor setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN
pixelon_r
 lda playfield,y
 ora setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN
pixeloff_r
 lda setbyte,x
 eor #$ff
 and playfield,y
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 RETURN

 else
 jmp plotpoint
 endif

pfhline
;x=xvalue, y=yvalue, a=0,1,2, temp3=endx
 jsr setuppointers
 jmp noinc
keepgoing
 inx
 txa
 and #7
 bne noinc
 iny
noinc
 jsr plotpoint
 cpx temp3
 bmi keepgoing
 RETURN

pfvline
;x=xvalue, y=yvalue, a=0,1,2, temp3=endx
 jsr setuppointers
 sty temp1 ; store memory location offset
 inc temp3 ; increase final x by 1 
 lda temp3
 asl
 if pfwidth=4
   asl ; multiply by 4
 endif ; else multiply by 2
 sta temp3 ; store it
 ; Thanks to Michael Rideout for fixing a bug in this code
 ; right now, temp1=y=starting memory location, temp3=final
 ; x should equal original x value
keepgoingy
 jsr plotpoint
 iny
 iny
 if pfwidth=4
   iny
   iny
 endif
 cpy temp3
 bmi keepgoingy
 RETURN

plotpoint
 lda temp2 ; load on.off.flip value (0,1, or 2)
 beq pixelon  ; if "on" go to on
 lsr
 bcs pixeloff ; value is 1 if true
 lda playfield,y ; if here, it's "flip"
 eor setbyte,x
  ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts
pixelon
 lda playfield,y
 ora setbyte,x
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts
pixeloff
 lda setbyte,x
 eor #$ff
 and playfield,y
 ifconst superchip
 sta playfield-128,y
 else
 sta playfield,y
 endif
 rts

setbyte
 ifnconst pfcenter
 .byte $80
 .byte $40
 .byte $20
 .byte $10
 .byte $08
 .byte $04
 .byte $02
 .byte $01
 endif
 .byte $01
 .byte $02
 .byte $04
 .byte $08
 .byte $10
 .byte $20
 .byte $40
 .byte $80
 .byte $80
 .byte $40
 .byte $20
 .byte $10
 .byte $08
 .byte $04
 .byte $02
 .byte $01
 .byte $01
 .byte $02
 .byte $04
 .byte $08
 .byte $10
 .byte $20
 .byte $40
 .byte $80
; Provided under the CC0 license. See the included LICENSE.txt for details.

pfscroll ;(a=0 left, 1 right, 2 up, 4 down, 6=upup, 12=downdown)
 bne notleft
;left
 ifconst pfres
 ldx #pfres*4
 else
 ldx #48
 endif
leftloop
 lda playfield-1,x
 lsr

 ifconst superchip
 lda playfield-2,x
 rol
 sta playfield-130,x
 lda playfield-3,x
 ror
 sta playfield-131,x
 lda playfield-4,x
 rol
 sta playfield-132,x
 lda playfield-1,x
 ror
 sta playfield-129,x
 else
 rol playfield-2,x
 ror playfield-3,x
 rol playfield-4,x
 ror playfield-1,x
 endif

 txa
 sbx #4
 bne leftloop
 RETURN

notleft
 lsr
 bcc notright
;right

 ifconst pfres
 ldx #pfres*4
 else
 ldx #48
 endif
rightloop
 lda playfield-4,x
 lsr
 ifconst superchip
 lda playfield-3,x
 rol
 sta playfield-131,x
 lda playfield-2,x
 ror
 sta playfield-130,x
 lda playfield-1,x
 rol
 sta playfield-129,x
 lda playfield-4,x
 ror
 sta playfield-132,x
 else
 rol playfield-3,x
 ror playfield-2,x
 rol playfield-1,x
 ror playfield-4,x
 endif
 txa
 sbx #4
 bne rightloop
  RETURN

notright
 lsr
 bcc notup
;up
 lsr
 bcc onedecup
 dec playfieldpos
onedecup
 dec playfieldpos
 beq shiftdown 
 bpl noshiftdown2 
shiftdown
  ifconst pfrowheight
 lda #pfrowheight
 else
 ifnconst pfres
   lda #8
 else
   lda #(96/pfres) ; try to come close to the real size
 endif
 endif

 sta playfieldpos
 lda playfield+3
 sta temp4
 lda playfield+2
 sta temp3
 lda playfield+1
 sta temp2
 lda playfield
 sta temp1
 ldx #0
up2
 lda playfield+4,x
 ifconst superchip
 sta playfield-128,x
 lda playfield+5,x
 sta playfield-127,x
 lda playfield+6,x
 sta playfield-126,x
 lda playfield+7,x
 sta playfield-125,x
 else
 sta playfield,x
 lda playfield+5,x
 sta playfield+1,x
 lda playfield+6,x
 sta playfield+2,x
 lda playfield+7,x
 sta playfield+3,x
 endif
 txa
 sbx #252
 ifconst pfres
 cpx #(pfres-1)*4
 else
 cpx #44
 endif
 bne up2

 lda temp4
 
 ifconst superchip
 ifconst pfres
 sta playfield+pfres*4-129
 lda temp3
 sta playfield+pfres*4-130
 lda temp2
 sta playfield+pfres*4-131
 lda temp1
 sta playfield+pfres*4-132
 else
 sta playfield+47-128
 lda temp3
 sta playfield+46-128
 lda temp2
 sta playfield+45-128
 lda temp1
 sta playfield+44-128
 endif
 else
 ifconst pfres
 sta playfield+pfres*4-1
 lda temp3
 sta playfield+pfres*4-2
 lda temp2
 sta playfield+pfres*4-3
 lda temp1
 sta playfield+pfres*4-4
 else
 sta playfield+47
 lda temp3
 sta playfield+46
 lda temp2
 sta playfield+45
 lda temp1
 sta playfield+44
 endif
 endif
noshiftdown2
 RETURN


notup
;down
 lsr
 bcs oneincup
 inc playfieldpos
oneincup
 inc playfieldpos
 lda playfieldpos

  ifconst pfrowheight
 cmp #pfrowheight+1
 else
 ifnconst pfres
   cmp #9
 else
   cmp #(96/pfres)+1 ; try to come close to the real size
 endif
 endif

 bcc noshiftdown 
 lda #1
 sta playfieldpos

 ifconst pfres
 lda playfield+pfres*4-1
 sta temp4
 lda playfield+pfres*4-2
 sta temp3
 lda playfield+pfres*4-3
 sta temp2
 lda playfield+pfres*4-4
 else
 lda playfield+47
 sta temp4
 lda playfield+46
 sta temp3
 lda playfield+45
 sta temp2
 lda playfield+44
 endif

 sta temp1

 ifconst pfres
 ldx #(pfres-1)*4
 else
 ldx #44
 endif
down2
 lda playfield-1,x
 ifconst superchip
 sta playfield-125,x
 lda playfield-2,x
 sta playfield-126,x
 lda playfield-3,x
 sta playfield-127,x
 lda playfield-4,x
 sta playfield-128,x
 else
 sta playfield+3,x
 lda playfield-2,x
 sta playfield+2,x
 lda playfield-3,x
 sta playfield+1,x
 lda playfield-4,x
 sta playfield,x
 endif
 txa
 sbx #4
 bne down2

 lda temp4
 ifconst superchip
 sta playfield-125
 lda temp3
 sta playfield-126
 lda temp2
 sta playfield-127
 lda temp1
 sta playfield-128
 else
 sta playfield+3
 lda temp3
 sta playfield+2
 lda temp2
 sta playfield+1
 lda temp1
 sta playfield
 endif
noshiftdown
 RETURN
; Provided under the CC0 license. See the included LICENSE.txt for details.

;standard routines needed for pretty much all games
; just the random number generator is left - maybe we should remove this asm file altogether?
; repositioning code and score pointer setup moved to overscan
; read switches, joysticks now compiler generated (more efficient)

randomize
	lda rand
	lsr
 ifconst rand16
	rol rand16
 endif
	bcc noeor
	eor #$B4
noeor
	sta rand
 ifconst rand16
	eor rand16
 endif
	RETURN
; Provided under the CC0 license. See the included LICENSE.txt for details.

drawscreen
     ifconst debugscore
         ldx #14
         lda INTIM ; display # cycles left in the score

         ifconst mincycles
             lda mincycles 
             cmp INTIM
             lda mincycles
             bcc nochange
             lda INTIM
             sta mincycles
nochange
         endif

         ; cmp #$2B
         ; bcs no_cycles_left
         bmi cycles_left
         ldx #64
         eor #$ff ;make negative
cycles_left
         stx scorecolor
         and #$7f ; clear sign bit
         tax
         lda scorebcd,x
         sta score+2
         lda scorebcd1,x
         sta score+1
         jmp done_debugscore 
scorebcd
         .byte $00, $64, $28, $92, $56, $20, $84, $48, $12, $76, $40
         .byte $04, $68, $32, $96, $60, $24, $88, $52, $16, $80, $44
         .byte $08, $72, $36, $00, $64, $28, $92, $56, $20, $84, $48
         .byte $12, $76, $40, $04, $68, $32, $96, $60, $24, $88
scorebcd1
         .byte 0, 0, 1, 1, 2, 3, 3, 4, 5, 5, 6
         .byte 7, 7, 8, 8, 9, $10, $10, $11, $12, $12, $13
         .byte $14, $14, $15, $16, $16, $17, $17, $18, $19, $19, $20
         .byte $21, $21, $22, $23, $23, $24, $24, $25, $26, $26
done_debugscore
     endif

     ifconst debugcycles
         lda INTIM ; if we go over, it mucks up the background color
         ; cmp #$2B
         ; BCC overscan
         bmi overscan
         sta COLUBK
         bcs doneoverscan
     endif

overscan
     ifconst interlaced
         PHP
         PLA 
         EOR #4 ; flip interrupt bit
         PHA
         PLP
         AND #4 ; isolate the interrupt bit
         TAX ; save it for later
     endif

overscanloop
     lda INTIM ;wait for sync
     bmi overscanloop
doneoverscan

     ;do VSYNC

     ifconst interlaced
         CPX #4
         BNE oddframevsync
     endif

     lda #2
     sta WSYNC
     sta VSYNC
     STA WSYNC
     STA WSYNC
     lsr
     STA WSYNC
     STA VSYNC
     sta VBLANK
     ifnconst overscan_time
         lda #37+128
     else
         lda #overscan_time+128
     endif
     sta TIM64T

     ifconst interlaced
         jmp postsync 

oddframevsync
         sta WSYNC

         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste

         lda #2
         sta VSYNC
         sta WSYNC
         sta WSYNC
         sta WSYNC

         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste
         LDA ($80,X) ; 11 waste

         lda #0
         sta VSYNC
         sta VBLANK
         ifnconst overscan_time
             lda #37+128
         else
             lda #overscan_time+128
         endif
         sta TIM64T

postsync
     endif

     ifconst legacy
         if legacy < 100
             ldx #4
adjustloop
             lda player0x,x
             sec
             sbc #14 ;?
             sta player0x,x
             dex
             bpl adjustloop
         endif
     endif
     if ((<*)>$e9)&&((<*)<$fa)
         repeat ($fa-(<*))
         nop
         repend
     endif
     sta WSYNC
     ldx #4
     SLEEP 3
HorPosLoop     ; 5
     lda player0x,X ;+4 9
     sec ;+2 11
DivideLoop
     sbc #15
     bcs DivideLoop;+4 15
     sta temp1,X ;+4 19
     sta RESP0,X ;+4 23
     sta WSYNC
     dex
     bpl HorPosLoop;+5 5
     ; 4

     ldx #4
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 18

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 32

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 46

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 60

     dex
     ldy temp1,X
     lda repostable-256,Y
     sta HMP0,X ;+14 74

     sta WSYNC
     
     sta HMOVE ;+3 3


     ifconst legacy
         if legacy < 100
             ldx #4
adjustloop2
             lda player0x,x
             clc
             adc #14 ;?
             sta player0x,x
             dex
             bpl adjustloop2
         endif
     endif




     ;set score pointers
     lax score+2
     jsr scorepointerset
     sty scorepointers+5
     stx scorepointers+2
     lax score+1
     jsr scorepointerset
     sty scorepointers+4
     stx scorepointers+1
     lax score
     jsr scorepointerset
     sty scorepointers+3
     stx scorepointers

vblk
     ; run possible vblank bB code
     ifconst vblank_bB_code
         jsr vblank_bB_code
     endif
vblk2
     LDA INTIM
     bmi vblk2
     jmp kernel
     

     .byte $80,$70,$60,$50,$40,$30,$20,$10,$00
     .byte $F0,$E0,$D0,$C0,$B0,$A0,$90
repostable

scorepointerset
     and #$0F
     asl
     asl
     asl
     adc #<scoretable
     tay 
     txa
     ; and #$F0
     ; lsr
     asr #$F0
     adc #<scoretable
     tax
     rts
game
.
 ;;line 1;; 

.
 ;;line 2;; 

.
 ;;line 3;; 

.
 ;;line 4;; 

.
 ;;line 5;; 

.
 ;;line 6;; 

.
 ;;line 7;; 

.
 ;;line 8;; 

.
 ;;line 9;; 

.
 ;;line 10;; 

.
 ;;line 11;; 

.
 ;;line 12;; 

.
 ;;line 13;; 

.
 ;;line 14;; 

.
 ;;line 15;; 

.
 ;;line 16;; 

.
 ;;line 17;; 

.
 ;;line 18;; 

.
 ;;line 19;; 

.
 ;;line 20;; 

.
 ;;line 21;; 

.
 ;;line 22;; 

.
 ;;line 23;; 

.
 ;;line 24;; 

.
 ;;line 25;; 

.
 ;;line 26;; 

.
 ;;line 27;; 

.
 ;;line 28;; 

.
 ;;line 29;; 

.
 ;;line 30;; 

.
 ;;line 31;; 

.
 ;;line 32;; 

.
 ;;line 33;; 

.
 ;;line 34;; 

.
 ;;line 35;; 

.
 ;;line 36;; 

.
 ;;line 37;; 

.
 ;;line 38;; 

.
 ;;line 39;; 

.
 ;;line 40;; 

.
 ;;line 41;; 

.
 ;;line 42;; 

.
 ;;line 43;; 

.
 ;;line 44;; 

.
 ;;line 45;; 

.
 ;;line 46;; 

.
 ;;line 47;; 

.
 ;;line 48;; 

.
 ;;line 49;; 

.L00 ;;line 50;;  dim _Current_Object = a

.
 ;;line 51;; 

.
 ;;line 52;; 

.
 ;;line 53;; 

.
 ;;line 54;; 

.L01 ;;line 55;;  dim _Jiggle_Counter = b

.
 ;;line 56;; 

.
 ;;line 57;; 

.
 ;;line 58;; 

.
 ;;line 59;; 

.L02 ;;line 60;;  dim _Memx = c

.L03 ;;line 61;;  dim _Memy = d

.
 ;;line 62;; 

.
 ;;line 63;; 

.
 ;;line 64;; 

.
 ;;line 65;; 

.L04 ;;line 66;;  dim _P0_LR = player0x.e

.
 ;;line 67;; 

.
 ;;line 68;; 

.
 ;;line 69;; 

.
 ;;line 70;; 

.L05 ;;line 71;;  dim _P1_LR = player1x.f

.
 ;;line 72;; 

.
 ;;line 73;; 

.
 ;;line 74;; 

.
 ;;line 75;; 

.L06 ;;line 76;;  dim _B_LR = ballx.g

.
 ;;line 77;; 

.
 ;;line 78;; 

.
 ;;line 79;; 

.
 ;;line 80;; 

.L07 ;;line 81;;  dim _P0_Speed = h.i

.
 ;;line 82;; 

.
 ;;line 83;; 

.
 ;;line 84;; 

.
 ;;line 85;; 

.L08 ;;line 86;;  dim _P0_Left_Number = h

.
 ;;line 87;; 

.
 ;;line 88;; 

.
 ;;line 89;; 

.
 ;;line 90;; 

.L09 ;;line 91;;  dim _P0_Right_Number = i

.
 ;;line 92;; 

.
 ;;line 93;; 

.
 ;;line 94;; 

.
 ;;line 95;; 

.L010 ;;line 96;;  dim _P1_Speed = j.k

.
 ;;line 97;; 

.
 ;;line 98;; 

.
 ;;line 99;; 

.
 ;;line 100;; 

.L011 ;;line 101;;  dim _P1_Left_Number = j

.
 ;;line 102;; 

.
 ;;line 103;; 

.
 ;;line 104;; 

.
 ;;line 105;; 

.L012 ;;line 106;;  dim _P1_Right_Number = k

.
 ;;line 107;; 

.
 ;;line 108;; 

.
 ;;line 109;; 

.
 ;;line 110;; 

.L013 ;;line 111;;  dim _B_Speed = l.m

.
 ;;line 112;; 

.
 ;;line 113;; 

.
 ;;line 114;; 

.
 ;;line 115;; 

.L014 ;;line 116;;  dim _B_Left_Number = l

.
 ;;line 117;; 

.
 ;;line 118;; 

.
 ;;line 119;; 

.
 ;;line 120;; 

.L015 ;;line 121;;  dim _B_Right_Number = m

.
 ;;line 122;; 

.
 ;;line 123;; 

.
 ;;line 124;; 

.
 ;;line 125;; 

.L016 ;;line 126;;  dim _Score_Counter = n

.
 ;;line 127;; 

.
 ;;line 128;; 

.
 ;;line 129;; 

.
 ;;line 130;; 

.L017 ;;line 131;;  dim _Score_Slowdown = o

.
 ;;line 132;; 

.
 ;;line 133;; 

.
 ;;line 134;; 

.
 ;;line 135;; 

.L018 ;;line 136;;  dim _Score_Right_Number = p

.
 ;;line 137;; 

.
 ;;line 138;; 

.
 ;;line 139;; 

.
 ;;line 140;; 

.L019 ;;line 141;;  dim _P0Left_Mem = q

.L020 ;;line 142;;  dim _P0Right_Mem = r

.
 ;;line 143;; 

.L021 ;;line 144;;  dim _P1Left_Mem = s

.L022 ;;line 145;;  dim _P1Right_Mem = t

.
 ;;line 146;; 

.L023 ;;line 147;;  dim _BLeft_Mem = u

.L024 ;;line 148;;  dim _BRight_Mem = v

.
 ;;line 149;; 

.
 ;;line 150;; 

.
 ;;line 151;; 

.
 ;;line 152;; 

.L025 ;;line 153;;  dim _Left_Number = w

.
 ;;line 154;; 

.
 ;;line 155;; 

.
 ;;line 156;; 

.
 ;;line 157;; 

.L026 ;;line 158;;  dim _BitOp_01 = y

.L027 ;;line 159;;  dim _Bit0_Reset_Restrainer = y

.L028 ;;line 160;;  dim _Bit1_P0_Direction = y

.L029 ;;line 161;;  dim _Bit2_P1_Direction = y

.L030 ;;line 162;;  dim _Bit5_Ball_Direction = y

.L031 ;;line 163;;  dim _Bit6_Joy0_Restrainer = y

.L032 ;;line 164;;  dim _Bit7_Activate_Jiggle = y

.
 ;;line 165;; 

.
 ;;line 166;; 

.
 ;;line 167;; 

.
 ;;line 168;; 

.
 ;;line 169;; 

.
 ;;line 170;; 

.
 ;;line 171;; 

.
 ;;line 172;; 

.L033 ;;line 173;;  dim _sc1 = score

.L034 ;;line 174;;  dim _sc2 = score + 1

.L035 ;;line 175;;  dim _sc3 = score + 2

.
 ;;line 176;; 

.
 ;;line 177;; 

.
 ;;line 178;; 

.
 ;;line 179;; 

.
 ;;line 180;; 

.
 ;;line 181;; 

.
 ;;line 182;; 

.
 ;;line 183;; 

.L036 ;;line 184;;  const _c_Player0 = 0

.L037 ;;line 185;;  const _c_Ball = 1

.L038 ;;line 186;;  const _c_Player1 = 2

.
 ;;line 187;; 

.
 ;;line 188;; 

.
 ;;line 189;; 

.
 ;;line 190;; 

.
 ;;line 191;; 

.
 ;;line 192;; 

.
 ;;line 193;; 

.
 ;;line 194;; 

.L039 ;;line 195;;  const _c_PlayerMissile0_Color = $9C

.L040 ;;line 196;;  const _c_Ball_Color = $FC

.L041 ;;line 197;;  const _c_PlayerMissile1_Color = $CA

.
 ;;line 198;; 

.
 ;;line 199;; 

.
 ;;line 200;; 

.
 ;;line 201;; 

.
 ;;line 202;; 

.
 ;;line 203;; 

.
 ;;line 204;; 

.
 ;;line 205;; 

.
 ;;line 206;; 

.
 ;;line 207;; 

.__Start_Restart
 ;;line 208;; __Start_Restart

.
 ;;line 209;; 

.
 ;;line 210;; 

.
 ;;line 211;; 

.
 ;;line 212;; 

.
 ;;line 213;; 

.
 ;;line 214;; 

.L042 ;;line 215;;  AUDV0 = 0  :  AUDV1 = 0

	LDA #0
	STA AUDV0
	STA AUDV1
.
 ;;line 216;; 

.
 ;;line 217;; 

.
 ;;line 218;; 

.
 ;;line 219;; 

.
 ;;line 220;; 

.
 ;;line 221;; 

.L043 ;;line 222;;  a = 0  :  b = 0  :  c = 0  :  d = 0  :  e = 0  :  f = 0  :  g = 0  :  h = 0  :  i = 0

	LDA #0
	STA a
	STA b
	STA c
	STA d
	STA e
	STA f
	STA g
	STA h
	STA i
.L044 ;;line 223;;  j = 0  :  k = 0  :  l = 0  :  m = 0  :  n = 0  :  o = 0  :  p = 0  :  q = 0  :  r = 0

	LDA #0
	STA j
	STA k
	STA l
	STA m
	STA n
	STA o
	STA p
	STA q
	STA r
.L045 ;;line 224;;  s = 0  :  t = 0  :  u = 0  :  v = 0  :  w = 0  :  x = 0  :  y = 0  :  z = 0

	LDA #0
	STA s
	STA t
	STA u
	STA v
	STA w
	STA x
	STA y
	STA z
.
 ;;line 225;; 

.
 ;;line 226;; 

.
 ;;line 227;; 

.
 ;;line 228;; 

.
 ;;line 229;; 

.
 ;;line 230;; 

.L046 ;;line 231;;  player0x = 79  :  player0y = 64

	LDA #79
	STA player0x
	LDA #64
	STA player0y
.
 ;;line 232;; 

.
 ;;line 233;; 

.
 ;;line 234;; 

.
 ;;line 235;; 

.
 ;;line 236;; 

.
 ;;line 237;; 

.L047 ;;line 238;;  ballx = 83  :  bally = player0y  -  16

	LDA #83
	STA ballx
	LDA player0y
	SEC
	SBC #16
	STA bally
.
 ;;line 239;; 

.
 ;;line 240;; 

.
 ;;line 241;; 

.
 ;;line 242;; 

.
 ;;line 243;; 

.
 ;;line 244;; 

.L048 ;;line 245;;  player1x = 79  :  player1y = bally  -  8

	LDA #79
	STA player1x
	LDA bally
	SEC
	SBC #8
	STA player1y
.
 ;;line 246;; 

.
 ;;line 247;; 

.
 ;;line 248;; 

.
 ;;line 249;; 

.
 ;;line 250;; 

.
 ;;line 251;; 

.L049 ;;line 252;;  CTRLPF = $01  :  ballheight = 0

	LDA #$01
	STA CTRLPF
	LDA #0
	STA ballheight
.
 ;;line 253;; 

.
 ;;line 254;; 

.
 ;;line 255;; 

.
 ;;line 256;; 

.
 ;;line 257;; 

.
 ;;line 258;; 

.L050 ;;line 259;;  _P0_Speed = 0.72  :  _B_Speed = 1.00  :  _P1_Speed = 1.50

	LDX #184
	STX i
	LDA #0
	STA _P0_Speed
	LDX #0
	STX m
	LDA #1
	STA _B_Speed
	LDX #128
	STX k
	LDA #1
	STA _P1_Speed
.
 ;;line 260;; 

.
 ;;line 261;; 

.
 ;;line 262;; 

.
 ;;line 263;; 

.
 ;;line 264;; 

.
 ;;line 265;; 

.L051 ;;line 266;;  _P0_Left_Number = 0  :  _B_Left_Number = 1  :  _P1_Left_Number = 1

	LDA #0
	STA _P0_Left_Number
	LDA #1
	STA _B_Left_Number
	STA _P1_Left_Number
.
 ;;line 267;; 

.
 ;;line 268;; 

.
 ;;line 269;; 

.
 ;;line 270;; 

.
 ;;line 271;; 

.
 ;;line 272;; 

.L052 ;;line 273;;  _Score_Right_Number = 72

	LDA #72
	STA _Score_Right_Number
.
 ;;line 274;; 

.
 ;;line 275;; 

.
 ;;line 276;; 

.
 ;;line 277;; 

.
 ;;line 278;; 

.
 ;;line 279;; 

.L053 ;;line 280;;  _P0Left_Mem = $00  :  _P0Right_Mem = $72

	LDA #$00
	STA _P0Left_Mem
	LDA #$72
	STA _P0Right_Mem
.L054 ;;line 281;;  _BLeft_Mem = $10  :  _BRight_Mem = $00

	LDA #$10
	STA _BLeft_Mem
	LDA #$00
	STA _BRight_Mem
.L055 ;;line 282;;  _P1Left_Mem = $10  :  _P1Right_Mem = $50

	LDA #$10
	STA _P1Left_Mem
	LDA #$50
	STA _P1Right_Mem
.
 ;;line 283;; 

.
 ;;line 284;; 

.
 ;;line 285;; 

.
 ;;line 286;; 

.
 ;;line 287;; 

.
 ;;line 288;; 

.L056 ;;line 289;;  COLUBK = 0

	LDA #0
	STA COLUBK
.
 ;;line 290;; 

.
 ;;line 291;; 

.
 ;;line 292;; 

.
 ;;line 293;; 

.
 ;;line 294;; 

.
 ;;line 295;; 

.
 ;;line 296;; 

.
 ;;line 297;; 

.
 ;;line 298;; 

.L057 ;;line 299;;  _Bit0_Reset_Restrainer{0} = 1

	LDA _Bit0_Reset_Restrainer
	ORA #1
	STA _Bit0_Reset_Restrainer
.
 ;;line 300;; 

.
 ;;line 301;; 

.
 ;;line 302;; 

.
 ;;line 303;; 

.
 ;;line 304;; 

.
 ;;line 305;; 

.L058 ;;line 306;;  player0:

	LDX #<playerL058_0
	STX player0pointerlo
	LDA #>playerL058_0
	STA player0pointerhi
	LDA #7
	STA player0height
.
 ;;line 316;; 

.
 ;;line 317;; 

.
 ;;line 318;; 

.
 ;;line 319;; 

.
 ;;line 320;; 

.
 ;;line 321;; 

.L059 ;;line 322;;  player1:

	LDX #<playerL059_1
	STX player1pointerlo
	LDA #>playerL059_1
	STA player1pointerhi
	LDA #7
	STA player1height
.
 ;;line 332;; 

.
 ;;line 333;; 

.L060 ;;line 334;;  goto __Score_Color_Start

 jmp .__Score_Color_Start
.
 ;;line 335;; 

.
 ;;line 336;; 

.
 ;;line 337;; 

.
 ;;line 338;; 

.
 ;;line 339;; 

.
 ;;line 340;; 

.
 ;;line 341;; 

.
 ;;line 342;; 

.
 ;;line 343;; 

.
 ;;line 344;; 

.__Main_Loop
 ;;line 345;; __Main_Loop

.
 ;;line 346;; 

.
 ;;line 347;; 

.
 ;;line 348;; 

.
 ;;line 349;; 

.
 ;;line 350;; 

.
 ;;line 351;; 

.
 ;;line 352;; 

.
 ;;line 353;; 

.
 ;;line 354;; 

.
 ;;line 355;; 

.
 ;;line 356;; 

.L061 ;;line 357;;  if !joy0fire then _Bit6_Joy0_Restrainer{6} = 0  :  goto __Skip_Fire_Button

 bit INPT4
	BPL .skipL061
.condpart0
	LDA _Bit6_Joy0_Restrainer
	AND #191
	STA _Bit6_Joy0_Restrainer
 jmp .__Skip_Fire_Button
.skipL061
.
 ;;line 358;; 

.
 ;;line 359;; 

.
 ;;line 360;; 

.
 ;;line 361;; 

.L062 ;;line 362;;  if !joy0up  &&  !joy0down then _Bit6_Joy0_Restrainer{6} = 0  :  goto __Skip_Fire_Button

 lda #$10
 bit SWCHA
	BEQ .skipL062
.condpart1
 lda #$20
 bit SWCHA
	BEQ .skip1then
.condpart2
	LDA _Bit6_Joy0_Restrainer
	AND #191
	STA _Bit6_Joy0_Restrainer
 jmp .__Skip_Fire_Button
.skip1then
.skipL062
.
 ;;line 363;; 

.
 ;;line 364;; 

.
 ;;line 365;; 

.
 ;;line 366;; 

.L063 ;;line 367;;  if _Bit6_Joy0_Restrainer{6} then goto __Skip_Score_Change

	BIT _Bit6_Joy0_Restrainer
	BVC .skipL063
.condpart3
 jmp .__Skip_Score_Change
.skipL063
.
 ;;line 368;; 

.
 ;;line 369;; 

.
 ;;line 370;; 

.
 ;;line 371;; 

.L064 ;;line 372;;  if joy0up then _Bit6_Joy0_Restrainer{6} = 1  :  _Bit7_Activate_Jiggle{7} = 1  :  _Jiggle_Counter = 0  :  _Current_Object = _Current_Object  +  1  :  if _Current_Object  >  2 then _Current_Object = 0

 lda #$10
 bit SWCHA
	BNE .skipL064
.condpart4
	LDA _Bit6_Joy0_Restrainer
	ORA #64
	STA _Bit6_Joy0_Restrainer
	LDA _Bit7_Activate_Jiggle
	ORA #128
	STA _Bit7_Activate_Jiggle
	LDA #0
	STA _Jiggle_Counter
	INC _Current_Object
	LDA #2
	CMP _Current_Object
     BCS .skip4then
.condpart5
	LDA #0
	STA _Current_Object
.skip4then
.skipL064
.
 ;;line 373;; 

.L065 ;;line 374;;  if joy0down then _Bit6_Joy0_Restrainer{6} = 1  :  _Bit7_Activate_Jiggle{7} = 1  :  _Jiggle_Counter = 0  :  _Current_Object = _Current_Object  -  1  :  if _Current_Object  >  200 then _Current_Object = 2

 lda #$20
 bit SWCHA
	BNE .skipL065
.condpart6
	LDA _Bit6_Joy0_Restrainer
	ORA #64
	STA _Bit6_Joy0_Restrainer
	LDA _Bit7_Activate_Jiggle
	ORA #128
	STA _Bit7_Activate_Jiggle
	LDA #0
	STA _Jiggle_Counter
	DEC _Current_Object
	LDA #200
	CMP _Current_Object
     BCS .skip6then
.condpart7
	LDA #2
	STA _Current_Object
.skip6then
.skipL065
.
 ;;line 375;; 

.__Score_Color_Start
 ;;line 376;; __Score_Color_Start

.
 ;;line 377;; 

.
 ;;line 378;; 

.
 ;;line 379;; 

.
 ;;line 380;; 

.L066 ;;line 381;;  if _Current_Object = _c_Player0 then scorecolor = _c_PlayerMissile0_Color  :  _sc2 = _P0Left_Mem  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A  :  _sc3 = _P0Right_Mem  :  _Left_Number = _P0_Left_Number

	LDA _Current_Object
	CMP #_c_Player0
     BNE .skipL066
.condpart8
	LDA #_c_PlayerMissile0_Color
	STA scorecolor
	LDA _P0Left_Mem
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
	LDA _P0Right_Mem
	STA _sc3
	LDA _P0_Left_Number
	STA _Left_Number
.skipL066
.L067 ;;line 382;;  if _Current_Object = _c_Ball then scorecolor = _c_Ball_Color  :  _sc2 = _BLeft_Mem  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A  :  _sc3 = _BRight_Mem  :  _Left_Number = _B_Left_Number

	LDA _Current_Object
	CMP #_c_Ball
     BNE .skipL067
.condpart9
	LDA #_c_Ball_Color
	STA scorecolor
	LDA _BLeft_Mem
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
	LDA _BRight_Mem
	STA _sc3
	LDA _B_Left_Number
	STA _Left_Number
.skipL067
.L068 ;;line 383;;  if _Current_Object = _c_Player1 then scorecolor = _c_PlayerMissile1_Color  :  _sc2 = _P1Left_Mem  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A  :  _sc3 = _P1Right_Mem  :  _Left_Number = _P1_Left_Number

	LDA _Current_Object
	CMP #_c_Player1
     BNE .skipL068
.condpart10
	LDA #_c_PlayerMissile1_Color
	STA scorecolor
	LDA _P1Left_Mem
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
	LDA _P1Right_Mem
	STA _sc3
	LDA _P1_Left_Number
	STA _Left_Number
.skipL068
.
 ;;line 384;; 

.
 ;;line 385;; 

.
 ;;line 386;; 

.
 ;;line 387;; 

.L069 ;;line 388;;  _Bit6_Joy0_Restrainer{6} = 1

	LDA _Bit6_Joy0_Restrainer
	ORA #64
	STA _Bit6_Joy0_Restrainer
.
 ;;line 389;; 

.
 ;;line 390;; 

.
 ;;line 391;; 

.
 ;;line 392;; 

.L070 ;;line 393;;  goto __Skip_Score_Change

 jmp .__Skip_Score_Change
.
 ;;line 394;; 

.__Skip_Fire_Button
 ;;line 395;; __Skip_Fire_Button

.
 ;;line 396;; 

.
 ;;line 397;; 

.
 ;;line 398;; 

.
 ;;line 399;; 

.
 ;;line 400;; 

.
 ;;line 401;; 

.
 ;;line 402;; 

.
 ;;line 403;; 

.
 ;;line 404;; 

.
 ;;line 405;; 

.L071 ;;line 406;;  _Score_Counter = _Score_Counter  +  1

	INC _Score_Counter
.
 ;;line 407;; 

.
 ;;line 408;; 

.
 ;;line 409;; 

.
 ;;line 410;; 

.L072 ;;line 411;;  if _Score_Counter  <  _Score_Slowdown then goto __Skip_Score_Change

	LDA _Score_Counter
	CMP _Score_Slowdown
     BCS .skipL072
.condpart11
 jmp .__Skip_Score_Change
.skipL072
.
 ;;line 412;; 

.
 ;;line 413;; 

.
 ;;line 414;; 

.
 ;;line 415;; 

.
 ;;line 416;; 

.L073 ;;line 417;;  if !joy0left then goto __Skip_Score_Joy0_Left

 bit SWCHA
	BVC .skipL073
.condpart12
 jmp .__Skip_Score_Joy0_Left
.skipL073
.
 ;;line 418;; 

.
 ;;line 419;; 

.
 ;;line 420;; 

.
 ;;line 421;; 

.L074 ;;line 422;;  _Score_Right_Number = _Score_Right_Number  -  1  :  _Score_Slowdown = 10

	DEC _Score_Right_Number
	LDA #10
	STA _Score_Slowdown
.
 ;;line 423;; 

.
 ;;line 424;; 

.
 ;;line 425;; 

.
 ;;line 426;; 

.L075 ;;line 427;;  if _Score_Right_Number  <  200 then goto __Skip_Left_Decrement

	LDA _Score_Right_Number
	CMP #200
     BCS .skipL075
.condpart13
 jmp .__Skip_Left_Decrement
.skipL075
.
 ;;line 428;; 

.
 ;;line 429;; 

.
 ;;line 430;; 

.
 ;;line 431;; 

.L076 ;;line 432;;  if !_Left_Number then _Score_Right_Number = 0  :  goto __Skip_Score_Joy0_Left

	LDA _Left_Number
	BNE .skipL076
.condpart14
	LDA #0
	STA _Score_Right_Number
 jmp .__Skip_Score_Joy0_Left
.skipL076
.
 ;;line 433;; 

.
 ;;line 434;; 

.
 ;;line 435;; 

.
 ;;line 436;; 

.L077 ;;line 437;;  _Score_Right_Number = 99  :  _sc3 = $99

	LDA #99
	STA _Score_Right_Number
	LDA #$99
	STA _sc3
.
 ;;line 438;; 

.
 ;;line 439;; 

.
 ;;line 440;; 

.
 ;;line 441;; 

.L078 ;;line 442;;  if _Left_Number then _Left_Number = _Left_Number  -  1  :  _sc2 = _sc2  -  $10  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A

	LDA _Left_Number
	BEQ .skipL078
.condpart15
	DEC _Left_Number
	LDA _sc2
	SEC
	SBC #$10
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
.skipL078
.
 ;;line 443;; 

.L079 ;;line 444;;  goto __Skip_Score_Joy0_Left

 jmp .__Skip_Score_Joy0_Left
.
 ;;line 445;; 

.__Skip_Left_Decrement
 ;;line 446;; __Skip_Left_Decrement

.
 ;;line 447;; 

.
 ;;line 448;; 

.
 ;;line 449;; 

.
 ;;line 450;; 

.L080 ;;line 451;;  dec _sc3 = _sc3  -  $01

	SED
	LDA _sc3
	SEC
	SBC #$01
	STA _sc3
	CLD
.
 ;;line 452;; 

.__Skip_Score_Joy0_Left
 ;;line 453;; __Skip_Score_Joy0_Left

.
 ;;line 454;; 

.
 ;;line 455;; 

.
 ;;line 456;; 

.
 ;;line 457;; 

.
 ;;line 458;; 

.L081 ;;line 459;;  if !joy0right then goto __Skip_Score_Joy0_Right

 bit SWCHA
	BPL .skipL081
.condpart16
 jmp .__Skip_Score_Joy0_Right
.skipL081
.
 ;;line 460;; 

.
 ;;line 461;; 

.
 ;;line 462;; 

.
 ;;line 463;; 

.L082 ;;line 464;;  _Score_Right_Number = _Score_Right_Number  +  1  :  _Score_Slowdown = 10

	INC _Score_Right_Number
	LDA #10
	STA _Score_Slowdown
.
 ;;line 465;; 

.
 ;;line 466;; 

.
 ;;line 467;; 

.
 ;;line 468;; 

.L083 ;;line 469;;  if _Score_Right_Number  <  100 then goto __Skip_Right_Increment

	LDA _Score_Right_Number
	CMP #100
     BCS .skipL083
.condpart17
 jmp .__Skip_Right_Increment
.skipL083
.
 ;;line 470;; 

.L084 ;;line 471;;  if _Left_Number  >  8 then _Score_Right_Number = 99  :  _sc3 = $99  :  goto __Skip_Score_Joy0_Right

	LDA #8
	CMP _Left_Number
     BCS .skipL084
.condpart18
	LDA #99
	STA _Score_Right_Number
	LDA #$99
	STA _sc3
 jmp .__Skip_Score_Joy0_Right
.skipL084
.
 ;;line 472;; 

.L085 ;;line 473;;  _Score_Right_Number = 0  :  _sc3 = $00  :  _Left_Number = _Left_Number  +  1  :  _sc2 = _sc2  +  $10  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A  :  goto __Skip_Score_Joy0_Right

	LDA #0
	STA _Score_Right_Number
	LDA #$00
	STA _sc3
	INC _Left_Number
	LDA _sc2
	CLC
	ADC #$10
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
 jmp .__Skip_Score_Joy0_Right
.
 ;;line 474;; 

.__Skip_Right_Increment
 ;;line 475;; __Skip_Right_Increment

.
 ;;line 476;; 

.
 ;;line 477;; 

.
 ;;line 478;; 

.
 ;;line 479;; 

.L086 ;;line 480;;  dec _sc3 = _sc3  +  $01

	SED
	LDA _sc3
	CLC
	ADC #$01
	STA _sc3
	CLD
.
 ;;line 481;; 

.__Skip_Score_Joy0_Right
 ;;line 482;; __Skip_Score_Joy0_Right

.
 ;;line 483;; 

.
 ;;line 484;; 

.
 ;;line 485;; 

.
 ;;line 486;; 

.
 ;;line 487;; 

.L087 ;;line 488;;  if !joy0up then goto __Skip_Score_Joy0_Up

 lda #$10
 bit SWCHA
	BEQ .skipL087
.condpart19
 jmp .__Skip_Score_Joy0_Up
.skipL087
.
 ;;line 489;; 

.
 ;;line 490;; 

.
 ;;line 491;; 

.
 ;;line 492;; 

.L088 ;;line 493;;  _Score_Right_Number = _Score_Right_Number  +  1  :  _Score_Slowdown = 1

	INC _Score_Right_Number
	LDA #1
	STA _Score_Slowdown
.
 ;;line 494;; 

.
 ;;line 495;; 

.
 ;;line 496;; 

.
 ;;line 497;; 

.L089 ;;line 498;;  if _Score_Right_Number  <  100 then goto __Skip_Up_Increment

	LDA _Score_Right_Number
	CMP #100
     BCS .skipL089
.condpart20
 jmp .__Skip_Up_Increment
.skipL089
.
 ;;line 499;; 

.L090 ;;line 500;;  if _Left_Number  >  8 then _Score_Right_Number = 99  :  _sc3 = $99  :  goto __Skip_Score_Joy0_Up

	LDA #8
	CMP _Left_Number
     BCS .skipL090
.condpart21
	LDA #99
	STA _Score_Right_Number
	LDA #$99
	STA _sc3
 jmp .__Skip_Score_Joy0_Up
.skipL090
.
 ;;line 501;; 

.L091 ;;line 502;;  _Score_Right_Number = 0  :  _sc3 = $00  :  _Left_Number = _Left_Number  +  1  :  _sc2 = _sc2  +  $10  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A  :  goto __Skip_Score_Joy0_Up

	LDA #0
	STA _Score_Right_Number
	LDA #$00
	STA _sc3
	INC _Left_Number
	LDA _sc2
	CLC
	ADC #$10
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
 jmp .__Skip_Score_Joy0_Up
.
 ;;line 503;; 

.__Skip_Up_Increment
 ;;line 504;; __Skip_Up_Increment

.
 ;;line 505;; 

.
 ;;line 506;; 

.
 ;;line 507;; 

.
 ;;line 508;; 

.L092 ;;line 509;;  dec _sc3 = _sc3  +  $01

	SED
	LDA _sc3
	CLC
	ADC #$01
	STA _sc3
	CLD
.
 ;;line 510;; 

.__Skip_Score_Joy0_Up
 ;;line 511;; __Skip_Score_Joy0_Up

.
 ;;line 512;; 

.
 ;;line 513;; 

.
 ;;line 514;; 

.
 ;;line 515;; 

.
 ;;line 516;; 

.L093 ;;line 517;;  if !joy0down then goto __Skip_Score_Joy0_Down

 lda #$20
 bit SWCHA
	BEQ .skipL093
.condpart22
 jmp .__Skip_Score_Joy0_Down
.skipL093
.
 ;;line 518;; 

.
 ;;line 519;; 

.
 ;;line 520;; 

.
 ;;line 521;; 

.L094 ;;line 522;;  _Score_Right_Number = _Score_Right_Number  -  1  :  _Score_Slowdown = 1

	DEC _Score_Right_Number
	LDA #1
	STA _Score_Slowdown
.
 ;;line 523;; 

.
 ;;line 524;; 

.
 ;;line 525;; 

.
 ;;line 526;; 

.L095 ;;line 527;;  if _Score_Right_Number  <  200 then goto __Skip_Down_Decrement

	LDA _Score_Right_Number
	CMP #200
     BCS .skipL095
.condpart23
 jmp .__Skip_Down_Decrement
.skipL095
.
 ;;line 528;; 

.
 ;;line 529;; 

.
 ;;line 530;; 

.
 ;;line 531;; 

.L096 ;;line 532;;  if !_Left_Number then _Score_Right_Number = 0  :  goto __Skip_Score_Joy0_Down

	LDA _Left_Number
	BNE .skipL096
.condpart24
	LDA #0
	STA _Score_Right_Number
 jmp .__Skip_Score_Joy0_Down
.skipL096
.
 ;;line 533;; 

.
 ;;line 534;; 

.
 ;;line 535;; 

.
 ;;line 536;; 

.L097 ;;line 537;;  _Score_Right_Number = 99  :  _sc3 = $99

	LDA #99
	STA _Score_Right_Number
	LDA #$99
	STA _sc3
.
 ;;line 538;; 

.
 ;;line 539;; 

.
 ;;line 540;; 

.
 ;;line 541;; 

.L098 ;;line 542;;  if _Left_Number then _Left_Number = _Left_Number  -  1  :  _sc2 = _sc2  -  $10  :  _sc2 = _sc2  &  %11110000  :  _sc2 = _sc2  |  $0A

	LDA _Left_Number
	BEQ .skipL098
.condpart25
	DEC _Left_Number
	LDA _sc2
	SEC
	SBC #$10
	STA _sc2
	LDA _sc2
	AND #%11110000
	STA _sc2
	LDA _sc2
	ORA #$0A
	STA _sc2
.skipL098
.
 ;;line 543;; 

.L099 ;;line 544;;  goto __Skip_Score_Joy0_Down

 jmp .__Skip_Score_Joy0_Down
.
 ;;line 545;; 

.__Skip_Down_Decrement
 ;;line 546;; __Skip_Down_Decrement

.
 ;;line 547;; 

.
 ;;line 548;; 

.
 ;;line 549;; 

.
 ;;line 550;; 

.L0100 ;;line 551;;  dec _sc3 = _sc3  -  $01

	SED
	LDA _sc3
	SEC
	SBC #$01
	STA _sc3
	CLD
.
 ;;line 552;; 

.__Skip_Score_Joy0_Down
 ;;line 553;; __Skip_Score_Joy0_Down

.
 ;;line 554;; 

.
 ;;line 555;; 

.
 ;;line 556;; 

.
 ;;line 557;; 

.L0101 ;;line 558;;  temp5 = _sc3  &  $0F

	LDA _sc3
	AND #$0F
	STA temp5
.L0102 ;;line 559;;  temp6 = _sc3  /  16

	LDA _sc3
	lsr
	lsr
	lsr
	lsr
	STA temp6
.
 ;;line 560;; 

.L0103 ;;line 561;;  if _Current_Object = _c_Player0 then _P0Left_Mem = _sc2  &  %11110000  :  _P0Right_Mem = _sc3  :  _P0_Left_Number = _Left_Number  :  _P0_Right_Number = _DATA_Lo_Table[temp5]  +  _DATA_Hi_Table[temp6]

	LDA _Current_Object
	CMP #_c_Player0
     BNE .skipL0103
.condpart26
	LDA _sc2
	AND #%11110000
	STA _P0Left_Mem
	LDA _sc3
	STA _P0Right_Mem
	LDA _Left_Number
	STA _P0_Left_Number
	LDX temp5
	LDA _DATA_Lo_Table,x
	LDX temp6
	CLC
	ADC _DATA_Hi_Table,x
	STA _P0_Right_Number
.skipL0103
.
 ;;line 562;; 

.L0104 ;;line 563;;  if _Current_Object = _c_Ball then _BLeft_Mem = _sc2  &  %11110000  :  _BRight_Mem = _sc3  :  _B_Left_Number = _Left_Number  :  _B_Right_Number = _DATA_Lo_Table[temp5]  +  _DATA_Hi_Table[temp6]

	LDA _Current_Object
	CMP #_c_Ball
     BNE .skipL0104
.condpart27
	LDA _sc2
	AND #%11110000
	STA _BLeft_Mem
	LDA _sc3
	STA _BRight_Mem
	LDA _Left_Number
	STA _B_Left_Number
	LDX temp5
	LDA _DATA_Lo_Table,x
	LDX temp6
	CLC
	ADC _DATA_Hi_Table,x
	STA _B_Right_Number
.skipL0104
.
 ;;line 564;; 

.L0105 ;;line 565;;  if _Current_Object = _c_Player1 then _P1Left_Mem = _sc2  &  %11110000  :  _P1Right_Mem = _sc3  :  _P1_Left_Number = _Left_Number  :  _P1_Right_Number = _DATA_Lo_Table[temp5]  +  _DATA_Hi_Table[temp6]

	LDA _Current_Object
	CMP #_c_Player1
     BNE .skipL0105
.condpart28
	LDA _sc2
	AND #%11110000
	STA _P1Left_Mem
	LDA _sc3
	STA _P1Right_Mem
	LDA _Left_Number
	STA _P1_Left_Number
	LDX temp5
	LDA _DATA_Lo_Table,x
	LDX temp6
	CLC
	ADC _DATA_Hi_Table,x
	STA _P1_Right_Number
.skipL0105
.
 ;;line 566;; 

.
 ;;line 567;; 

.
 ;;line 568;; 

.
 ;;line 569;; 

.
 ;;line 570;; 

.L0106 ;;line 571;;  _Score_Counter = 0

	LDA #0
	STA _Score_Counter
.
 ;;line 572;; 

.__Skip_Score_Change
 ;;line 573;; __Skip_Score_Change

.
 ;;line 574;; 

.
 ;;line 575;; 

.
 ;;line 576;; 

.
 ;;line 577;; 

.
 ;;line 578;; 

.
 ;;line 579;; 

.
 ;;line 580;; 

.
 ;;line 581;; 

.
 ;;line 582;; 

.
 ;;line 583;; 

.
 ;;line 584;; 

.
 ;;line 585;; 

.L0107 ;;line 586;;  if !_Bit7_Activate_Jiggle{7} then goto __Skip_Object_Jiggle

	BIT _Bit7_Activate_Jiggle
	BMI .skipL0107
.condpart29
 jmp .__Skip_Object_Jiggle
.skipL0107
.
 ;;line 587;; 

.
 ;;line 588;; 

.
 ;;line 589;; 

.
 ;;line 590;; 

.L0108 ;;line 591;;  if _Jiggle_Counter  >=  1 then goto __Skip_Memory

	LDA _Jiggle_Counter
	CMP #1
     BCC .skipL0108
.condpart30
 jmp .__Skip_Memory
.skipL0108
.
 ;;line 592;; 

.L0109 ;;line 593;;  if _Current_Object = _c_Player0 then _Memx = player0x  :  _Memy = player0y

	LDA _Current_Object
	CMP #_c_Player0
     BNE .skipL0109
.condpart31
	LDA player0x
	STA _Memx
	LDA player0y
	STA _Memy
.skipL0109
.
 ;;line 594;; 

.L0110 ;;line 595;;  if _Current_Object = _c_Ball then _Memx = ballx  :  _Memy = bally

	LDA _Current_Object
	CMP #_c_Ball
     BNE .skipL0110
.condpart32
	LDA ballx
	STA _Memx
	LDA bally
	STA _Memy
.skipL0110
.
 ;;line 596;; 

.L0111 ;;line 597;;  if _Current_Object = _c_Player1 then _Memx = player1x  :  _Memy = player1y

	LDA _Current_Object
	CMP #_c_Player1
     BNE .skipL0111
.condpart33
	LDA player1x
	STA _Memx
	LDA player1y
	STA _Memy
.skipL0111
.
 ;;line 598;; 

.__Skip_Memory
 ;;line 599;; __Skip_Memory

.
 ;;line 600;; 

.
 ;;line 601;; 

.
 ;;line 602;; 

.
 ;;line 603;; 

.L0112 ;;line 604;;  _Jiggle_Counter = _Jiggle_Counter  +  1

	INC _Jiggle_Counter
.
 ;;line 605;; 

.
 ;;line 606;; 

.
 ;;line 607;; 

.
 ;;line 608;; 

.L0113 ;;line 609;;  if _Current_Object = _c_Player0 then temp5 = 255  +   ( rand & 3 )   :  player0x = player0x  +  temp5 :  temp5 = 255  +   ( rand & 3 )   :  player0y = player0y  +  temp5

	LDA _Current_Object
	CMP #_c_Player0
     BNE .skipL0113
.condpart34
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA player0x
	CLC
	ADC temp5
	STA player0x
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA player0y
	CLC
	ADC temp5
	STA player0y
.skipL0113
.
 ;;line 610;; 

.L0114 ;;line 611;;  if _Current_Object = _c_Ball then temp5 = 255  +   ( rand & 3 )   :  ballx = ballx  +  temp5 :  temp5 = 255  +   ( rand & 3 )   :  bally = bally  +  temp5

	LDA _Current_Object
	CMP #_c_Ball
     BNE .skipL0114
.condpart35
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA ballx
	CLC
	ADC temp5
	STA ballx
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA bally
	CLC
	ADC temp5
	STA bally
.skipL0114
.
 ;;line 612;; 

.L0115 ;;line 613;;  if _Current_Object = _c_Player1 then temp5 = 255  +   ( rand & 3 )   :  player1x = player1x  +  temp5 :  temp5 = 255  +   ( rand & 3 )   :  player1y = player1y  +  temp5

	LDA _Current_Object
	CMP #_c_Player1
     BNE .skipL0115
.condpart36
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA player1x
	CLC
	ADC temp5
	STA player1x
; complex statement detected
	LDA #255
	PHA
 jsr randomize
	AND #3
	TSX
	INX
	TXS
	CLC
	ADC $0,x
	STA temp5
	LDA player1y
	CLC
	ADC temp5
	STA player1y
.skipL0115
.
 ;;line 614;; 

.
 ;;line 615;; 

.
 ;;line 616;; 

.
 ;;line 617;; 

.
 ;;line 618;; 

.L0116 ;;line 619;;  if _Jiggle_Counter  <=  4 then goto __Skip_Object_Jiggle

	LDA #4
	CMP _Jiggle_Counter
     BCC .skipL0116
.condpart37
 jmp .__Skip_Object_Jiggle
.skipL0116
.
 ;;line 620;; 

.L0117 ;;line 621;;  _Bit7_Activate_Jiggle{7} = 0  :  _Jiggle_Counter = 0

	LDA _Bit7_Activate_Jiggle
	AND #127
	STA _Bit7_Activate_Jiggle
	LDA #0
	STA _Jiggle_Counter
.
 ;;line 622;; 

.L0118 ;;line 623;;  if _Current_Object = _c_Player0 then player0x = _Memx  :  player0y = _Memy

	LDA _Current_Object
	CMP #_c_Player0
     BNE .skipL0118
.condpart38
	LDA _Memx
	STA player0x
	LDA _Memy
	STA player0y
.skipL0118
.
 ;;line 624;; 

.L0119 ;;line 625;;  if _Current_Object = _c_Ball then ballx = _Memx  :  bally = _Memy

	LDA _Current_Object
	CMP #_c_Ball
     BNE .skipL0119
.condpart39
	LDA _Memx
	STA ballx
	LDA _Memy
	STA bally
.skipL0119
.
 ;;line 626;; 

.L0120 ;;line 627;;  if _Current_Object = _c_Player1 then player1x = _Memx  :  player1y = _Memy

	LDA _Current_Object
	CMP #_c_Player1
     BNE .skipL0120
.condpart40
	LDA _Memx
	STA player1x
	LDA _Memy
	STA player1y
.skipL0120
.
 ;;line 628;; 

.__Skip_Object_Jiggle
 ;;line 629;; __Skip_Object_Jiggle

.
 ;;line 630;; 

.
 ;;line 631;; 

.
 ;;line 632;; 

.
 ;;line 633;; 

.
 ;;line 634;; 

.
 ;;line 635;; 

.
 ;;line 636;; 

.L0121 ;;line 637;;  COLUP0 = _c_PlayerMissile0_Color

	LDA #_c_PlayerMissile0_Color
	STA COLUP0
.
 ;;line 638;; 

.
 ;;line 639;; 

.
 ;;line 640;; 

.
 ;;line 641;; 

.
 ;;line 642;; 

.
 ;;line 643;; 

.
 ;;line 644;; 

.L0122 ;;line 645;;  COLUP1 = _c_PlayerMissile1_Color

	LDA #_c_PlayerMissile1_Color
	STA COLUP1
.
 ;;line 646;; 

.
 ;;line 647;; 

.
 ;;line 648;; 

.
 ;;line 649;; 

.
 ;;line 650;; 

.
 ;;line 651;; 

.
 ;;line 652;; 

.L0123 ;;line 653;;  COLUPF = _c_Ball_Color

	LDA #_c_Ball_Color
	STA COLUPF
.
 ;;line 654;; 

.
 ;;line 655;; 

.
 ;;line 656;; 

.
 ;;line 657;; 

.
 ;;line 658;; 

.
 ;;line 659;; 

.
 ;;line 660;; 

.L0124 ;;line 661;;  if !_Bit1_P0_Direction{1} then _P0_LR = _P0_LR  -  _P0_Speed  :  temp6 = 2  +  _P0_Left_Number  :  if player0x  <  temp6 then _Bit1_P0_Direction{1} = 1

	LDA _Bit1_P0_Direction
	AND #2
	BNE .skipL0124
.condpart41
	LDA e
	SEC 
	SBC i
	STA e
	LDA _P0_LR
	SBC _P0_Speed
	STA _P0_LR
	LDA #2
	CLC
	ADC _P0_Left_Number
	STA temp6
	LDA player0x
	CMP temp6
     BCS .skip41then
.condpart42
	LDA _Bit1_P0_Direction
	ORA #2
	STA _Bit1_P0_Direction
.skip41then
.skipL0124
.
 ;;line 662;; 

.L0125 ;;line 663;;  if _Bit1_P0_Direction{1} then _P0_LR = _P0_LR  +  _P0_Speed  :  temp6 = 152  -  _P0_Left_Number  :  if player0x  >  temp6 then _Bit1_P0_Direction{1} = 0

	LDA _Bit1_P0_Direction
	AND #2
	BEQ .skipL0125
.condpart43
	LDA e
	CLC 
	ADC i
	STA e
	LDA _P0_LR
	ADC _P0_Speed
	STA _P0_LR
	LDA #152
	SEC
	SBC _P0_Left_Number
	STA temp6
	LDA temp6
	CMP player0x
     BCS .skip43then
.condpart44
	LDA _Bit1_P0_Direction
	AND #253
	STA _Bit1_P0_Direction
.skip43then
.skipL0125
.
 ;;line 664;; 

.
 ;;line 665;; 

.
 ;;line 666;; 

.
 ;;line 667;; 

.
 ;;line 668;; 

.
 ;;line 669;; 

.
 ;;line 670;; 

.L0126 ;;line 671;;  if !_Bit5_Ball_Direction{5} then _B_LR = _B_LR  -  _B_Speed  :  temp6 = 3  +  _B_Left_Number  :  if ballx  <  temp6 then _Bit5_Ball_Direction{5} = 1

	LDA _Bit5_Ball_Direction
	AND #32
	BNE .skipL0126
.condpart45
	LDA g
	SEC 
	SBC m
	STA g
	LDA _B_LR
	SBC _B_Speed
	STA _B_LR
	LDA #3
	CLC
	ADC _B_Left_Number
	STA temp6
	LDA ballx
	CMP temp6
     BCS .skip45then
.condpart46
	LDA _Bit5_Ball_Direction
	ORA #32
	STA _Bit5_Ball_Direction
.skip45then
.skipL0126
.
 ;;line 672;; 

.L0127 ;;line 673;;  if _Bit5_Ball_Direction{5} then _B_LR = _B_LR  +  _B_Speed  :  temp6 = 160  -  _B_Left_Number  :  if ballx  >  temp6 then _Bit5_Ball_Direction{5} = 0

	LDA _Bit5_Ball_Direction
	AND #32
	BEQ .skipL0127
.condpart47
	LDA g
	CLC 
	ADC m
	STA g
	LDA _B_LR
	ADC _B_Speed
	STA _B_LR
	LDA #160
	SEC
	SBC _B_Left_Number
	STA temp6
	LDA temp6
	CMP ballx
     BCS .skip47then
.condpart48
	LDA _Bit5_Ball_Direction
	AND #223
	STA _Bit5_Ball_Direction
.skip47then
.skipL0127
.
 ;;line 674;; 

.
 ;;line 675;; 

.
 ;;line 676;; 

.
 ;;line 677;; 

.
 ;;line 678;; 

.
 ;;line 679;; 

.
 ;;line 680;; 

.L0128 ;;line 681;;  if !_Bit2_P1_Direction{2} then _P1_LR = _P1_LR  -  _P1_Speed  :  temp6 = 2  +  _P1_Left_Number  :  if player1x  <  temp6 then _Bit2_P1_Direction{2} = 1

	LDA _Bit2_P1_Direction
	AND #4
	BNE .skipL0128
.condpart49
	LDA f
	SEC 
	SBC k
	STA f
	LDA _P1_LR
	SBC _P1_Speed
	STA _P1_LR
	LDA #2
	CLC
	ADC _P1_Left_Number
	STA temp6
	LDA player1x
	CMP temp6
     BCS .skip49then
.condpart50
	LDA _Bit2_P1_Direction
	ORA #4
	STA _Bit2_P1_Direction
.skip49then
.skipL0128
.
 ;;line 682;; 

.L0129 ;;line 683;;  if _Bit2_P1_Direction{2} then _P1_LR = _P1_LR  +  _P1_Speed  :  temp6 = 152  -  _P1_Left_Number  :  if player1x  >  temp6 then _Bit2_P1_Direction{2} = 0

	LDA _Bit2_P1_Direction
	AND #4
	BEQ .skipL0129
.condpart51
	LDA f
	CLC 
	ADC k
	STA f
	LDA _P1_LR
	ADC _P1_Speed
	STA _P1_LR
	LDA #152
	SEC
	SBC _P1_Left_Number
	STA temp6
	LDA temp6
	CMP player1x
     BCS .skip51then
.condpart52
	LDA _Bit2_P1_Direction
	AND #251
	STA _Bit2_P1_Direction
.skip51then
.skipL0129
.
 ;;line 684;; 

.
 ;;line 685;; 

.
 ;;line 686;; 

.
 ;;line 687;; 

.
 ;;line 688;; 

.
 ;;line 689;; 

.
 ;;line 690;; 

.L0130 ;;line 691;;  drawscreen

 jsr drawscreen
.
 ;;line 692;; 

.
 ;;line 693;; 

.
 ;;line 694;; 

.
 ;;line 695;; 

.
 ;;line 696;; 

.
 ;;line 697;; 

.
 ;;line 698;; 

.
 ;;line 699;; 

.
 ;;line 700;; 

.
 ;;line 701;; 

.
 ;;line 702;; 

.
 ;;line 703;; 

.
 ;;line 704;; 

.
 ;;line 705;; 

.
 ;;line 706;; 

.L0131 ;;line 707;;  if !switchreset then _Bit0_Reset_Restrainer{0} = 0  :  goto __Main_Loop

 lda #1
 bit SWCHB
	BEQ .skipL0131
.condpart53
	LDA _Bit0_Reset_Restrainer
	AND #254
	STA _Bit0_Reset_Restrainer
 jmp .__Main_Loop
.skipL0131
.
 ;;line 708;; 

.
 ;;line 709;; 

.
 ;;line 710;; 

.
 ;;line 711;; 

.
 ;;line 712;; 

.L0132 ;;line 713;;  if _Bit0_Reset_Restrainer{0} then goto __Main_Loop

	LDA _Bit0_Reset_Restrainer
	LSR
	BCC .skipL0132
.condpart54
 jmp .__Main_Loop
.skipL0132
.
 ;;line 714;; 

.
 ;;line 715;; 

.
 ;;line 716;; 

.
 ;;line 717;; 

.L0133 ;;line 718;;  goto __Start_Restart

 jmp .__Start_Restart
.
 ;;line 719;; 

.
 ;;line 720;; 

.
 ;;line 721;; 

.
 ;;line 722;; 

.
 ;;line 723;; 

.
 ;;line 724;; 

.
 ;;line 725;; 

.
 ;;line 726;; 

.
 ;;line 727;; 

.
 ;;line 728;; 

.
 ;;line 729;; 

.
 ;;line 730;; 

.
 ;;line 731;; 

.
 ;;line 732;; 

.
 ;;line 733;; 

.
 ;;line 734;; 

.
 ;;line 735;; 

.
 ;;line 736;; 

.
 ;;line 737;; 

.
 ;;line 738;; 

.
 ;;line 739;; 

.L0134 ;;line 740;;  data _DATA_Lo_Table

	JMP .skipL0134
_DATA_Lo_Table
	.byte     0,   5,   3,   8,  10,  13,  15,  18,  20,  23

.skipL0134
.
 ;;line 743;; 

.L0135 ;;line 744;;  data _DATA_Hi_Table

	JMP .skipL0135
_DATA_Hi_Table
	.byte     0,  26,  51,  77, 102, 128, 154, 179, 205, 230

.skipL0135
 if (<*) > (<(*+7))
	repeat ($100-<*)
	.byte 0
	repend
	endif
playerL058_0
	.byte    %00111100
	.byte    %01111110
	.byte    %11000011
	.byte    %10111101
	.byte    %11111111
	.byte    %11011011
	.byte    %01111110
	.byte    %00111100
 if (<*) > (<(*+7))
	repeat ($100-<*)
	.byte 0
	repend
	endif
playerL059_1
	.byte    %00111100
	.byte    %01111110
	.byte    %11000011
	.byte    %10111101
	.byte    %11111111
	.byte    %11011011
	.byte    %01111110
	.byte    %00111100
 if ECHOFIRST
       echo "    ",[(scoretable - *)]d , "bytes of ROM space left")
 endif 
ECHOFIRST = 1
 
 
 
; Provided under the CC0 license. See the included LICENSE.txt for details.
; font equates
.21stcentury = 1
alarmclock = 2     
handwritten = 3    
interrupted = 4    
retroputer = 5    
whimsey = 6
tiny = 7
hex = 8

; feel free to modify the score graphics - just keep each digit 8 high
; and keep the conditional compilation stuff intact
 ifnconst PXE
 ifconst ROM2k
   ORG $F7AC-8
 else
   ifconst bankswitch
     if bankswitch == 8
       ORG $2F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 16
       ORG $4F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 32
       ORG $8F94-bscode_length
       RORG $FF94-bscode_length
     endif
     if bankswitch == 64
       ORG  $10F80-bscode_length
       RORG $1FF80-bscode_length
     endif
   else
     ORG $FF9C
   endif
 endif


 ifconst font
   if font == hex
     ORG . - 48
   endif
 endif
 endif

scoretable

 ifconst font
  if font == .21stcentury
    include "score_graphics.asm.21stcentury"
  endif
  if font == alarmclock
    include "score_graphics.asm.alarmclock"
  endif
  if font == handwritten
    include "score_graphics.asm.handwritten"
  endif
  if font == interrupted
    include "score_graphics.asm.interrupted"
  endif
  if font == retroputer
    include "score_graphics.asm.retroputer"
  endif
  if font == whimsey
    include "score_graphics.asm.whimsey"
  endif
  if font == tiny
    include "score_graphics.asm.tiny"
  endif
  if font == hex
    include "score_graphics.asm.hex"
  endif
 else ; default font

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100

       .byte %01111110
       .byte %00011000
       .byte %00011000
       .byte %00011000
       .byte %00011000
       .byte %00111000
       .byte %00011000
       .byte %00001000

       .byte %01111110
       .byte %01100000
       .byte %01100000
       .byte %00111100
       .byte %00000110
       .byte %00000110
       .byte %01000110
       .byte %00111100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00000110
       .byte %00011100
       .byte %00000110
       .byte %01000110
       .byte %00111100

       .byte %00001100
       .byte %00001100
       .byte %01111110
       .byte %01001100
       .byte %01001100
       .byte %00101100
       .byte %00011100
       .byte %00001100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00000110
       .byte %00111100
       .byte %01100000
       .byte %01100000
       .byte %01111110

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %01111100
       .byte %01100000
       .byte %01100010
       .byte %00111100

       .byte %00110000
       .byte %00110000
       .byte %00110000
       .byte %00011000
       .byte %00001100
       .byte %00000110
       .byte %01000010
       .byte %00111110

       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100
       .byte %01100110
       .byte %01100110
       .byte %00111100

       .byte %00111100
       .byte %01000110
       .byte %00000110
       .byte %00111110
       .byte %01100110
       .byte %01100110
       .byte %01100110
       .byte %00111100 

       ifnconst DPC_kernel_options
 
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000
         .byte %00000000 

       endif

 endif

 ifnconst PXE
 ifconst ROM2k
   ORG $F7FC
 else
   ifconst bankswitch
     if bankswitch == 8
       ORG $2FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 16
       ORG $4FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 32
       ORG $8FF4-bscode_length
       RORG $FFF4-bscode_length
     endif
     if bankswitch == 64
       ORG  $10FE0-bscode_length
       RORG $1FFE0-bscode_length
     endif
   else
     ORG $FFFC
   endif
 endif
 endif
; Provided under the CC0 license. See the included LICENSE.txt for details.

 ifconst bankswitch
   if bankswitch == 8
     ORG $2FFC
     RORG $FFFC
   endif
   if bankswitch == 16
     ORG $4FFC
     RORG $FFFC
   endif
   if bankswitch == 32
     ORG $8FFC
     RORG $FFFC
   endif
   if bankswitch == 64
     ORG  $10FF0
     RORG $1FFF0
     lda $ffe0 ; we use wasted space to assist stella with EF format auto-detection
     ORG  $10FF8
     RORG $1FFF8
     ifconst superchip 
       .byte "E","F","S","C"
     else
       .byte "E","F","E","F"
     endif
     ORG  $10FFC
     RORG $1FFFC
   endif
 else
   ifconst ROM2k
     ORG $F7FC
   else
     ORG $FFFC
   endif
 endif
 .word (start & $ffff)
 .word (start & $ffff)
