;
; Code for the torpedo game object
;

TORPEDO_TYPE = 2                            ; The type code for a torpedo

;
; Initialize the torpedo game object
;
TOR_INIT        .proc
                PHP
                PHX

                ; Load the bitmap

                setas
                LDX #0
bm_copy         LDA #TORPEDO_BM,B,X         ; Get a pixel of the torpedo
                STA TORPEDO_VRAM,X          ; Save it to VRAM
                INX                         ; Go to the next pixel
                CPX #32*32                  ; Until we've done all the pixels
                BNE bm_copy

                STZ TOR_COUNT               ; Set count to zero

                PLX
                PLP
                RTS
                .pend

;
; Code to launch the torpedo
;
; Inputs:
; TOR_INIT_X = Launch position X
; TOR_INIT_Y = Launch position Y
;
TOR_LAUNCH      .proc
                PHP
                setaxl
                PHX

                LDA TOR_COUNT               ; Check how many torpedos are flying
                BNE done                    ; For now: if any, we don't fire another

                JSR GOBJ_NEW                ; Try to get a new game object slot
                LDX GO_TARGET
                BEQ done                    ; If 0, just skip everything... we can't allocate

                ; Set up the game object              

                LDA #TORPEDO_TYPE           ; Set the game object type to TORPEDO
                STA #GAMEOBJ.TYPE,B,X

                SEC
                LDA #`TORPEDO_VRAM          ; Set the address of the torpedo's bitmap
                SBC #`VRAM                  ; Make it an offset into VRAM
                STA #GAMEOBJ.BITMAP+2,B,X
                LDA #<>TORPEDO_VRAM
                STA #GAMEOBJ.BITMAP,B,X

                LDA #<>TOR_COMPUTE          ; Set the COMPUTE routine for this object
                STA #GAMEOBJ.COMPUTER,B,X

                LDA TOR_INIT_X              ; Set initial X position
                STA #GAMEOBJ.X,B,X

                LDA TOR_INIT_Y              ; Set initial Y position
                STA #GAMEOBJ.Y,B,X

                LDA #0                      ; Do not move horixontally
                STA #GAMEOBJ.DX,B,X

                LDA #$FFFC
                STA #GAMEOBJ.DY,B,X

                INC TOR_COUNT               ; Add to the count

done            PLX
                PLP
                RTS
                .pend

;
; Code to update position of the torpedo
;
; Inputs:
; 0,X = offset in bank 0 to the ship game object
;
TOR_COMPUTE     .proc
                PHP
                PHY

                setaxl
                CLC
                LDA #GAMEOBJ.Y,B,X              ; Get the Y coordinate
                ADC #GAMEOBJ.DY,B,X             ; Add the speed
                STA #GAMEOBJ.Y,B,X

                CMP #0
                BEQ disable                     ; If the result is 0, disable the torpedo

                LDA #<>GAMEOBJS                 ; Set target to the first game object
                STA GO_TARGET

loop            LDA (GO_TARGET)                 ; Get the target's type
                BMI done                        ; It's the sentinel... there's no collision
                CMP #FLIER_TYPE                 ; Is it a flier type?
                BEQ is_flier                    ; Yes: check it for a collision

next            CLC
                LDA GO_TARGET                   ; No: Go to the next target
                ADC #size(GAMEOBJ)
                STA GO_TARGET
                BRA loop                        ; And check it

is_flier        SEC
                LDA #GAMEOBJ.X,B,X              ; Get the torpedo's X
                LDY #GAMEOBJ.X  
                SBC (GO_TARGET),Y               ; Subtract's the target's X
                BPL chk_x                       ; Take the absolute value of the difference
                EOR #$FFFF
                INC A
chk_x           CMP #16                         ; Is it >=16?
                BGE next                        ; Yes: no collision here... check the next

                SEC
                LDA #GAMEOBJ.Y,B,X              ; Get the torpedo's Y
                LDY #GAMEOBJ.Y
                SBC (GO_TARGET),Y               ; Subtract's the target's Y
                BPL chk_y                       ; Take the absolute value of the difference
                EOR #$FFFF
                INC A
chk_y           CMP #16                          ; Is it >=16?
                BGE next                        ; Yes: no collision here... check the next

                ; We have a collision

is_collision    PHX
                LDX GO_TARGET
                JSR FLI_KILL
                PLX
                
disable         LDA #0
                STA #GAMEOBJ.TYPE,B,X           ; Set type on torpedo to 0 too
                DEC TOR_COUNT                   ; Remove a torpedo from the list

done            PLY
                PLP
                RTS
                .pend
