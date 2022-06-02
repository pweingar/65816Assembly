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

JOYSTICK0 = $AFE800                     ; Joystick 0 (next to SD Card)
SP0_VRAM = $B00000                      ; This is where we will save the sprite bitmap... beginning of VRAM
SP0_X = $002000                         ; Bank 0 variable: Sprite #0 x position (16-bits)
SP0_Y = $002002                         ; Bank 0 variable: Sprite #0 y position (16-bits)

; Kernel routines...

FK_CLRSCREEN = $0010A8                  ; Kernel routine: Clear the screen

; Useful constant values

VELOCITY = 2

MIN_Y = 64                              ; Minimum Y value (VICKY specific... leaves room for border and sprite margin)
MIN_X = 64                              ; Minimum X value (VICKY specific... leaves room for border and sprite margin)
MAX_Y = 480 - 32                        ; Maximum Y value (VICKY specific... leaves room for border and sprite margin)
MAX_X = 640 - 32                        ; Maximum X value (VICKY specific... leaves room for border and sprite margin)

JOY_UP = $01                            ; Joystick up position
JOY_DOWN = $02                          ; Joystick down position
JOY_LEFT = $04                          ; Joystick left position
JOY_RIGHT = $08                         ; Joystick right position

;
; Start of our code
;

START           setaxl                  ; Make accumulator and index registers 16-bits
                LDA #<>SP0_X            ; Set DPR to point to our sprite variables
                TCD
                .dpage SP0_X            ; Tell assembler where it is

                setas                   ; Make accumulator 8-bits
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
                STA @b SP0_X
                STA @b SP0_Y
                JSR SP0AT               ; Set position to (100, 100)

;
; Wait for the user to press a key and move the sprite accordingly
;

get_input       LDX #250                ; Introduce a bit of a delay...
                JSR ILOOP_MS            ; Later we'll do more precise timing here
                
                setas
                LDA @l JOYSTICK0        ; Get the joystick
                AND #JOY_UP             ; look at just the UP bit
                BEQ do_up               ; If 0: joystick is in the up position

                LDA @l JOYSTICK0        ; Get the joystick
                AND #JOY_DOWN           ; look at just the DOWN bit
                BEQ do_down             ; If 0: joystick is in the down position

chk_lr          setas
                LDA @l JOYSTICK0        ; Get the joystick
                AND #JOY_LEFT           ; look at just the LEFT bit
                BEQ do_left             ; If 0: joystick is in the left position

                LDA @l JOYSTICK0        ; Get the joystick
                AND #JOY_RIGHT          ; look at just the RIGHT bit
                BEQ do_right            ; If 0: joystick is in the right position

                BRA get_input           ; Otherwise: go back to waiting

                ; Handle vertical movements, lock Y to range (MIN_Y, MAX_Y]

do_up           setal
                LDA @b SP0_Y            ; Decrement the row #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from Y
                CMP #MIN_Y              ; Y < MIN_Y?
                BGE set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

do_down         setal
                LDA @b SP0_Y            ; Increment the row #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to Y
                CMP #MAX_Y              ; Y >= MAX_Y?
                BLT set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

set_y           STA @b SP0_Y            ; Save the updated Y value
                JSR SP0AT               ; And move the sprite
                BRA chk_lr              ; Check for left right motion

                ; Handle horizontal movements, lock X to range (MIN_X, MAX_X]

do_left         setal
                LDA @b SP0_X            ; Decrement the column #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from X
                CMP #MIN_X              ; X < MIN_X?
                BGE set_x               ; No: update the column #
                BRA get_input           ; Otherwise: ignore the keypress

do_right        setal
                LDA @b SP0_X            ; Increment the column #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to X
                CMP #MAX_X              ; X >= MAX_X?
                BLT set_x               ; No: update the column #
                BRA get_input           ; Otherwise: ignore the keypress

set_x           STA @b SP0_X            ; Save the updated X value
                JSR SP0AT               ; And move the sprite
                BRA get_input           ; Wait for another keypress

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

                LDA @b SP0_X            ; Get the x position
                STA @l SP00_X_POS_L     ; Set the x position

                LDA @b SP0_Y            ; Get the y position
                STA @l SP00_Y_POS_L     ; Set the y position

                PLP                     ; Restore the register sizes
                RTS                     ; Return to the caller 
                .pend                   ; Mark the end of a procedure

ILOOP           NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                RTS

ILOOP_1         JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                JSR ILOOP
                RTS

ILOOP_1MS       JSR ILOOP_1
                RTS

; A delay loop
ILOOP_MS        CPX #0
                BEQ LOOP_MS_END
                JSR ILOOP_1MS
                DEX
                BRA ILOOP_MS
LOOP_MS_END     RTS



.include "bitmap.asm"                   ; Include the data for the sprite's bitmap
.include "colors.asm"                   ; Include the data for the sprite's colors
