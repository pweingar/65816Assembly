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

.include "interrupts_def.asm"           ; Interrupt register and bit definitions
.include "macros.asm"                   ; Include macro definitions
.include "vicky_ii_inc.asm"             ; Include the definitions for VICKY II registers
.include "VKYII_CFP9553_SPRITE_def.asm" ; Include Vicky's sprite registers

;
; Defines
;

; Memory areas

IRQV = $00FFEE                          ; Native mode IRQ vector
JOYSTICK0 = $AFE800                     ; Joystick 0 (next to SD Card)
SP0_VRAM = $B00000                      ; This is where we will save the sprite bitmap... beginning of VRAM

OLDIRQ = $002000                        ; Bank 0 variable: old IRQ vector (so we could restore later)
SP0_X = $002002                         ; Bank 0 variable: Sprite #0 x position (16-bits)
SP0_Y = $002004                         ; Bank 0 variable: Sprite #0 y position (16-bits)

; Kernel routines...

FK_CLRSCREEN = $0010A8                  ; Kernel routine: Clear the screen

; Useful constant values

VELOCITY = 4

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

START           CLC                     ; Make sure we're in native mode
                XCE

                setaxl                  ; Make accumulator and index registers 16-bits
                LDA #<>SP0_X            ; Set DPR to point to our sprite variables
                TCD
                .dpage SP0_X            ; Tell assembler where it is

                JSL FK_CLRSCREEN        ; Clear the text screen

                ; Initialize interrupt handler

                SEI                     ; Turn off IRQs for the moment

                setal
                LDA @l IRQV             ; Get the current IRQ vector
                STA @l OLDIRQ           ; And save it so we could restore it later

                LDA #<>SOFHANDLE        ; Get the address of our handler in bank 0
                STA @l IRQV             ; Store it in the IRQ vector

                ; Enable SOF interrupts

                setas
                LDA @l INT_MASK_REG0    ; Get the interrupt controller mask register for SOF
                AND #~FNX0_INT00_SOF    ; Drop the mask bit for the SOF interrupt
                STA @l INT_MASK_REG0    ; Store the mask back to the interrupt controller

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
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En
                STA @l MASTER_CTRL_REG_L

                LDA #$01                ; Enable Sprite #0
                STA @l SP00_CONTROL_REG

                LDA #0                  ; Tell Vicky that the sprite is at the start of VRAM
                STA @l SP00_ADDY_PTR_L
                STA @l SP00_ADDY_PTR_M
                STA @l SP00_ADDY_PTR_H

                setal
                LDA #100                ; Set the initial position to (100, 100)       
                STA @b SP0_X
                STA @b SP0_Y

;
; Wait for the user to press a key and move the sprite accordingly
;

get_input       CLI                     ; Enable IRQ
                WAI                     ; Wait for an interrupt
                
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
                SEI                     ; Avoid interrupts while we mess with SP0_Y
                LDA @b SP0_Y            ; Decrement the row #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from Y
                CMP #MIN_Y              ; Y < MIN_Y?
                BGE set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

do_down         setal
                SEI                     ; Avoid interrupts while we mess with SP0_Y
                LDA @b SP0_Y            ; Increment the row #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to Y
                CMP #MAX_Y              ; Y >= MAX_Y?
                BLT set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

set_y           STA @b SP0_Y            ; Save the updated Y value
                BRA chk_lr              ; Check for left right motion

                ; Handle horizontal movements, lock X to range (MIN_X, MAX_X]

do_left         setal
                SEI                     ; Avoid interrupts while we mess with SP0_X
                LDA @b SP0_X            ; Decrement the column #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from X
                CMP #MIN_X              ; X < MIN_X?
                BGE set_x               ; No: update the column #
                BRA get_input           ; Otherwise: ignore the keypress

do_right        setal
                SEI                     ; Avoid interrupts while we mess with SP0_X
                LDA @b SP0_X            ; Increment the column #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to X
                CMP #MAX_X              ; X >= MAX_X?
                BLT set_x               ; No: update the column #
                BRA get_input           ; Otherwise: ignore the keypress

set_x           STA @b SP0_X            ; Save the updated X value
                BRA get_input           ; Wait for another keypress

.include "bitmap.asm"                   ; Include the data for the sprite's bitmap
.include "colors.asm"                   ; Include the data for the sprite's colors

;
; Interrupt handler... stored in bank 0
;

* = $002100

;
; Handle a SOF IRQ... this is our interrupt handler
;
SOFHANDLE       setal                   ; Save registers we're going to change
                PHA                     ; Note: this is a simple handler, not touching DP, DBR, X, or Y

                setas
                LDA @l INT_PENDING_REG0 ; Check to see if we've gotten a SOF interrupt
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE SOFCLEAR            ; No: just clear the pending interrupt

                ; Yes: update our sprite position

                setal
                LDA @b SP0_X            ; Get the x position
                STA @l SP00_X_POS_L     ; Set the x position

                LDA @b SP0_Y            ; Get the y position
                STA @l SP00_Y_POS_L     ; Set the y position

SOFCLEAR        setas
                LDA @l INT_PENDING_REG0 ; Clear all pending interrupts
                STA @l INT_PENDING_REG0

                setal                   ; Restore registers and return to main program
                PLA
                RTI

COLDSTART       JML START

;
; Reset Vector
;

* = $00FFFC
                .word <>COLDSTART