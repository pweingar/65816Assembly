;
; Code to manage the ship game object
;

SHIP_TYPE = 1

;
; Initialize the ship game object
;
SHIP_INIT       .proc
                PHP
                PHX

                ; Load the bitmap

                setas
                LDX #0
bm_copy         LDA #SHIP_BM,B,X            ; Get a pixel of the ship
                STA SHIP_VRAM,X             ; Save it to VRAM
                INX                         ; Go to the next pixel
                CPX #32*32                  ; Until we've done all the pixels
                BNE bm_copy

                ; Set up the game object

                setaxl
                LDX #<>GO_SHIP              ; X := offset to game object for ship

                LDA #SHIP_TYPE              ; Set the game object type to SHIP
                STA #GAMEOBJ.TYPE,B,X

                LDA #`SHIP_VRAM             ; Set the address of the ship's bitmap
                SEC
                SBC #`VRAM                  ; Make it an offset into VRAM
                STA GAMEOBJ.BITMAP+2,X
                LDA #<>SHIP_VRAM
                STA #GAMEOBJ.BITMAP,B,X

                LDA #100                    ; Set the starting coordinates to (100, 100)
                STA #GAMEOBJ.X,B,X
                STA #GAMEOBJ.Y,B,X

                LDA #0                      ; Set velocity to (0, 0)
                STA #GAMEOBJ.DX,B,X
                STA #GAMEOBJ.DY,B,X

                LDA #<>SHIP_COMPUTE         ; Set the COMPUTE routine for this object
                STA #GAMEOBJ.COMPUTER,B,X

                PLX
                PLP
                RTS
                .pend

;
; Compute the next action of the ship
;
; Inputs:
; X = offset in bank 0 to the ship game object
;
SHIP_COMPUTE    .proc
                PHP
               
                setas
                LDA @l JOYSTICK0        ; Get the joystick
                AND #JOY_BUTTON         ; look at just the BUTTON bit
                BEQ do_fire             ; If 0: fire button is pressed
                
chk_ud          setas
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

                BRA exit                ; Otherwise: go back to waiting

                ; Handle the fire button: launch a torpedo

do_fire         setaxl
                LDA #GAMEOBJ.X,B,X      ; Get the X coordinate
                STA TOR_INIT_X          ; Store it in the launch coordinate
                LDA #GAMEOBJ.Y,B,X      ; Get the Y coordinate
                STA TOR_INIT_Y          ; Store it in the launch coordinate

                JSR TOR_LAUNCH          ; Launch the torpedo

                BRA chk_ud              ; And check for movement

                ; Handle vertical movements, lock Y to range (MIN_Y, MAX_Y]

do_up           setaxl
                SEI                     ; Avoid interrupts while we mess with SP0_Y
                LDA #GAMEOBJ.Y,B,X      ; Decrement the row #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from Y
                CMP #MIN_Y              ; Y < MIN_Y?
                BGE set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

do_down         setaxl
                SEI                     ; Avoid interrupts while we mess with SP0_Y
                LDA #GAMEOBJ.Y,B,X      ; Increment the row #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to Y
                CMP #MAX_Y              ; Y >= MAX_Y?
                BLT set_y               ; No: update the row #
                BRA chk_lr              ; Otherwise: check for left right motion

set_y           STA #GAMEOBJ.Y,B,X      ; Save the updated Y value
                BRA chk_lr              ; Check for left right motion

                ; Handle horizontal movements, lock X to range (MIN_X, MAX_X]

do_left         setaxl
                SEI                     ; Avoid interrupts while we mess with SP0_X
                LDA #GAMEOBJ.X,B,X      ; Decrement the column #
                SEC                     ; Set the carry bit (no borrow)
                SBC #VELOCITY           ; Subtract "velocity" pixels from X
                CMP #MIN_X              ; X < MIN_X?
                BGE set_x               ; No: update the column #
                BRA exit                ; Otherwise: ignore the keypress

do_right        setaxl
                SEI                     ; Avoid interrupts while we mess with SP0_X
                LDA #GAMEOBJ.X,B,X      ; Increment the column #
                CLC                     ; Clear the carry (no carry)
                ADC #VELOCITY           ; Add "velocity" pixels to X
                CMP #MAX_X              ; X >= MAX_X?
                BLT set_x               ; No: update the column #
                BRA exit                ; Otherwise: ignore the keypress

set_x           STA #GAMEOBJ.X,B,X      ; Save the updated X value

exit            PLP
                RTS
                .pend
