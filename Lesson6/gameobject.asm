;
; Code for Game Objects
;

;
; Initialize all the game objects...
; Sets everything to 0 except for the hardware register pointers
;
GOBJ_INIT       .proc
                PHP
                setaxl
                PHX
                PHY

                LDX #<>GAMEOBJS
                LDY #<>SP00_CONTROL_REG             ; Y = the sprite registers

loop            LDA #0                              ; Zero out most of the fields
                STA #GAMEOBJ.TYPE,B,X
                STA #GAMEOBJ.X,B,X
                STA #GAMEOBJ.Y,B,X
                STA #GAMEOBJ.DX,B,X
                STA #GAMEOBJ.DY,B,X
                STA #GAMEOBJ.COMPUTER,B,X
                STA #GAMEOBJ.BITMAP+2,B,X
                STA #GAMEOBJ.BITMAP,B,X

                LDA #`SP00_CONTROL_REG              ; Set the hardware registers for this game object
                STA #GAMEOBJ.HWREG+2,B,X
                TYA
                STA #GAMEOBJ.HWREG,B,X

                CLC                          
                ADC #size(HWSPRITE)                 ; Set Y to the next set of hardware registers
                TAY

                CLC
                TXA                                 ; Move to the next game object slot
                ADC #size(GAMEOBJ)
                TAX
                CPX #<>SENTINEL                     ; Is it the sentinel (end of list)?
                BNE loop                            ; No: initialize this new slot...

                PLY
                PLX
                PLP
                RTS
                .pend

;
; Find an unusued game object
;
; Returns:
; GO_TARGET = the address of the new game object, 0 if none are free
;
GOBJ_NEW        .proc
                PHP

                setaxl
                LDA #<>GAMEOBJS                     ; Start at the beginning of the list
                STA GO_TARGET

loop            LDA (GO_TARGET)                     ; Get the target's type
                BEQ done                            ; If 0, we've found an unused slot... return it
                BMI not_found                       ; If negative, we've reached the end of the list

                CLC
                LDA GO_TARGET                       ; Otherwise, skip to the next game object
                ADC #size(GAMEOBJ)
                STA GO_TARGET
                BRA loop

not_found       STZ GO_TARGET                       ; Not found: set GO_TARGET to zero

done            PLP
                RTS
                .pend

;
; Compute the actions of all active game objects
;
GOBJ_COMPUTE    .proc
                PHP
                setxl
                PHX
                PHY

                setaxl
                LDX #<>GAMEOBJS
loop            LDA #GAMEOBJ.TYPE,B,X               ; Get the type of the object
                BEQ next                            ; If it's 0, it's inactive... skip it
                BMI done                            ; If it's the sentinel, we're done

                LDA #GAMEOBJ.COMPUTER,B,X           ; Call the COMPUTE function for this game object
                STA PROCEDURE
                JSR do_jump

next            TXA                                 ; Go to the next game object
                CLC
                ADC #size(GAMEOBJ)
                TAX

                BRA loop

done            PLY
                PLX
                PLP
                RTS

do_jump         JMP (PROCEDURE)
                .pend

;
; Set the VICKY sprite registers based on the values in the game object record
; 
; Inputs: 0,X points to the current game object
;
GOBJ_UPDATE     .proc
                PHP
                setaxl
                PHY

                LDA #GAMEOBJ.HWREG+2,B,X    ; Set the pointer to the hardware registers
                STA CURRSP+2
                LDA GAMEOBJ.HWREG,B,X
                STA CURRSP
   
                LDA #GAMEOBJ.TYPE,B,X       ; A := the type of the sprite
                BNE is_active               ; If <> 0, then we need to update the sprite

                setas
                LDA #0                      ; Otherwise, disable the sprite
                LDY #HWSPRITE.CONTROL
                STA [CURRSP],Y   

                PLY
                PLP
                RTS

is_active       setas
                LDA #1                      ; Enable the sprite
                LDY #HWSPRITE.CONTROL
                STA [CURRSP],Y

                LDA #GAMEOBJ.BITMAP+2,B,X   ; Set the address of the bitmap
                LDY #HWSPRITE.ADDRESS+2
                STA [CURRSP],Y
                setal
                LDA #GAMEOBJ.BITMAP,B,X
                LDY #HWSPRITE.ADDRESS
                STA [CURRSP],Y
        
                SEC
                LDA #GAMEOBJ.X,B,X          ; Set X coordinate
                SBC #16
                LDY #HWSPRITE.X
                STA [CURRSP],Y
        
                SEC
                LDA #GAMEOBJ.Y,B,X          ; Set Y coordinate
                SBC #16
                LDY #HWSPRITE.Y
                STA [CURRSP],Y

                PLY
                PLP
                RTS                         ; Return to our caller
                .pend
