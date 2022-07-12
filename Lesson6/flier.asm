;
; Code for the flier game object
;

FLIER_TYPE = 3                              ; The type code for a Purple Flier

;
; Initialize the flier game object
;
FLI_INIT        .proc
                PHP
                PHX

                ; Load the bitmap

                setas
                LDX #0
bm_copy         LDA #FLIER_IMG,B,X          ; Get a pixel of the flier
                STA FLIER_VRAM,X            ; Save it to VRAM
                INX                         ; Go to the next pixel
                CPX #32*32                  ; Until we've done all the pixels
                BNE bm_copy

                PLX
                PLP
                RTS
                .pend

;
; Code to launch the flier
;
FLI_LAUNCH      .proc
                PHP
                setaxl
                PHX

                JSR GOBJ_NEW                ; Try to get a new game object
                LDX GO_TARGET               ; Offset to game object for flier
                BEQ done                    ; If none available, just quit

                ; Set up the game object         

                LDA #FLIER_TYPE             ; Set the game object type to flier
                STA #GAMEOBJ.TYPE,B,X

                SEC
                LDA #`FLIER_VRAM            ; Set the address of the flier's bitmap
                SBC #`VRAM                  ; Make it an offset into VRAM
                STA #GAMEOBJ.BITMAP+2,B,X
                LDA #<>FLIER_VRAM
                STA #GAMEOBJ.BITMAP,B,X

                LDA #60                     ; Reset the flier respawn timer
                STA FLI_TIMER

                LDA #<>FLI_COMPUTE          ; Set the COMPUTE routine for this object
                STA #GAMEOBJ.COMPUTER,B,X 
                
                LDA #320                    ; Set initial X position
                STA #GAMEOBJ.X,B,X

                LDA #0                      ; Set initial Y position
                STA #GAMEOBJ.Y,B,X

                LDA #0                      ; Do not move horizontally
                STA #GAMEOBJ.DX,B,X

                LDA #2
                STA #GAMEOBJ.DY,B,X

                LDA #FLIER_TYPE             ; Set the type to enable it
                STA #GAMEOBJ.TYPE,B,X

                LDA #1                      ; Mark that the flier is active
                STA FLI_ACTIVE

done            PLX
                PLP
                RTS
                .pend

;
; Count down and wait to launch a new purple flier
;
FLI_TICK        .proc
                PHP

                setaxl
                LDA FLI_ACTIVE              ; Is there already a flier?
                BNE done                    ; Yes: don't launch a new one

                LDA FLI_TIMER               ; Count down the flier respawn timer
                DEC A
                STA FLI_TIMER
                CMP #0                      ; Have we reached 0?
                BNE done                    ; No: keep looping

                JSR FLI_LAUNCH              ; Yes: launch a new flier

done            PLP
                RTS
                .pend

;
; Kill the flier
;
; Inputs:
; X = offset in bank 0 to the flier game object
;
FLI_KILL        .proc
                PHP

                setaxl
                LDA #0                      ; Clear the type to remove the game object
                STA #GAMEOBJ.TYPE,B,X

                STA FLI_ACTIVE              ; Mark that there is no flier active

                LDA #60                     ; Reset the flier respawn timer
                STA FLI_TIMER

                PLP
                RTS
                .pend

;
; Code to update position of the flier
;
; Inputs:
; X = offset in bank 0 to the ship game object
;
FLI_COMPUTE     .proc
                PHP

                setaxl
                CLC
                LDA #GAMEOBJ.Y,B,X              ; Get the Y coordinate
                ADC #GAMEOBJ.DY,B,X             ; Add the speed
                STA #GAMEOBJ.Y,B,X

                CMP #480
                BNE done

                ; If =480, we need to remove the flier

                JSR FLI_KILL

done            PLP
                RTS
                .pend