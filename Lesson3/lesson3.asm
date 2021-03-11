;;;
;;; Assembly code to display a sprite
;;;

;
; Preamble
;

.cpu "65816"                            ; Tell the assembler we're using a 65816 processor
* = $010000                             ; Set the starting address for our code

;
; Includes
;

.include "macros.asm"                   ; Include macro definitions
.include "vicky_ii_inc.asm"             ; Include the definitions for VICKY II registers
.include "VKYII_CFP9553_SPRITE_def.asm" ; Include Vicky's sprite registers

;
; Defines
;

; Memory areas

SP0_VRAM = $B00000                      ; This is where we will save the sprite bitmap... beginning of VRAM
SP0_X = $002000                         ; Bank 0 variable: Sprite #0 x position (16-bits)
SP0_Y = $002002                         ; Bank 0 variable: Sprite #0 y position (16-bits)

; Kernel routines...

FK_GETCHW = $00104c                     ; Kernel routine: Get a character from the input channel.
                                        ; Waits until data received. A=0 and Carry=1 if no data is wating
FK_CLRSCREEN = $0010A8                  ; Kernel routine: Clear the screen

; Useful constant values

MIN_Y = 64                              ; Minimum Y value (VICKY specific... leaves room for border and sprite margin)
MIN_X = 64                              ; Minimum X value (VICKY specific... leaves room for border and sprite margin)
MAX_Y = 480 - 32                        ; Maximum Y value (VICKY specific... leaves room for border and sprite margin)
MAX_X = 640 - 32                        ; Maximum X value (VICKY specific... leaves room for border and sprite margin)

;
; Start of our code
;

START           setas                   ; Make accumulator 8-bits
                setxl                   ; Make index registers 16-bits

                JSL FK_CLRSCREEN        ; Clear the text screen

INITLUT         ; Initialize the color lookup table

                LDX #0                  ; Set X to point to the first byte
LUTLOOP         LDA @l LUT_START,X      ; Get a byte of the color table
                STA @l GRPH_LUT0_PTR,X  ; Save it to Vicky's Graphics LUT#0
                INX                     ; Move to the next byte
                CPX #256*4              ; Check to see if we've reached the limit
                BNE LUTLOOP             ; No: copy this next byte too

INITBITMAP      ; Initialize the sprite bitmap

                LDX #0                  ; Set X to point to the first byte
BITMAPLOOP      LDA @l IMG_START,X      ; Get a byte of bitmap data
                STA @l SP0_VRAM,X       ; Save it to Video RAM
                INX                     ; Move to the next byte
                CPX #32*32              ; Check to see if we've reached the limit
                BNE BITMAPLOOP          ; No: copy this next byte too

SHOWSPRITE      ; Set Vicky registers to display sprite

                ; Turn on the sprite graphics engine with text overlay
                LDA #Mstr_Ctrl_Text_Mode_En | Mstr_Ctrl_Text_Overlay | Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En
                STA @l MASTER_CTRL_REG_L

                LDA #$01                ; Enable Sprite #0
                STA @l SP00_CONTROL_REG

                LDA #0                  ; Tell Vicky that the sprite is at the start of VRAM
                STA @l SP00_ADDY_PTR_L
                STA @l SP00_ADDY_PTR_M
                STA @l SP00_ADDY_PTR_H

                LDA #100                
                STA @l SP0_X
                STA @l SP0_Y
                JSR SP0AT               ; Set position to (100, 100)

;
; Wait for the user to press a key and move the sprite accordingly
;

get_key         setas
                JSL FK_GETCHW           ; Wait for a keypress. It will be returned in A
                CMP #'W'
                BEQ do_up               
                CMP #'w'
                BEQ do_up               ; W -> move sprite up

                CMP #'S'
                BEQ do_down
                CMP #'s'
                BEQ do_down             ; S -> move sprite down

                CMP #'A'
                BEQ do_left
                CMP #'a'
                BEQ do_left             ; A -> move sprite left

                CMP #'D'
                BEQ do_right
                CMP #'d'
                BEQ do_right            ; D -> move sprite right

                BRA get_key             ; Otherwise: go back to waiting

                ; Handle vertical movements, lock Y to range (MIN_Y, MAX_Y]

do_up           setal
                LDA @l SP0_Y            ; Decrement the row #
                DEC A
                CMP #MIN_Y              ; Y < MIN_Y?
                BGE set_y               ; No: update the row #
                BRA get_key             ; Otherwise: ignore the keypress

do_down         setal
                LDA @l SP0_Y            ; Increment the row #
                INC A
                CMP #MAX_Y              ; Y >= MAX_Y?
                BLT set_y               ; No: update the row #
                BRA get_key             ; Otherwise: ignore the keypress

set_y           STA SP0_Y               ; Save the updated Y value
                JSR SP0AT               ; And move the sprite
                BRA get_key             ; Wait for another keypress

                ; Handle horizontal movements, lock X to range (MIN_X, MAX_X]

do_left         setal
                LDA @l SP0_X            ; Decrement the column #
                DEC A
                CMP #MIN_X              ; X < MIN_X?
                BGE set_x               ; No: update the column #
                BRA get_key             ; Otherwise: ignore the keypress

do_right        setal
                LDA @l SP0_X            ; Increment the column #
                INC A
                CMP #MAX_X              ; X >= MAX_X?
                BLT set_x               ; No: update the column #
                BRA get_key             ; Otherwise: ignore the keypress

set_x           STA SP0_X               ; Save the updated X value
                JSR SP0AT               ; And move the sprite
                BRA get_key             ; Wait for another keypress

;
; Set the position of sprite #0
;
; Inputs:
;   SP0_X = row # of the sprite's position (16-bits)
;   SP0_Y = column # of the sprite's position (16-bits)
;
; Affects: A
;
SP0AT           .proc                   ; Mark the beginning of a procedure (not necessary)
                PHP                     ; Save status (including register sizes)

                setal

                LDA @l SP0_X            ; Get the x position
                STA @l SP00_X_POS_L     ; Set the x position

                LDA @l SP0_Y            ; Get the y position
                STA @l SP00_Y_POS_L     ; Set the y position

                PLP                     ; Restore the register sizes
                RTS                     ; Return to the caller 
                .pend                   ; Mark the end of a procedure


.include "bitmap.asm"                   ; Include the data for the sprite's bitmap
.include "colors.asm"                   ; Include the data for the sprite's colors
