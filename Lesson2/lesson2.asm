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

.include "vicky_ii_inc.asm"             ; Include the definitions for VICKY II registers
.include "VKYII_CFP9553_SPRITE_def.asm" ; Include Vicky's sprite registers

;
; Defines
;
SP0_VRAM = $B00000                      ; This is where we will save the sprite bitmap... beginning of VRAM

;
; Start of our code
;

START           SEP #$20                ; Set the accumulator to 8-bit wide
                .as                     ; Tell the assembler the accumulator is 8-bits wide

                REP #$10                ; Set the index registers to 16-bits wide
                .xl                     ; Tell the assembler that the index registers are 16-bits wide

INITLUT         ; Initialize the color lookup table

                LDX #0                  ; Set X to point to the first byte
LUTLOOP         LDA LUT_START,X         ; Get a byte of the color table
                STA GRPH_LUT0_PTR,X     ; Save it to Vicky's Graphics LUT#0
                INX                     ; Move to the next byte
                CPX #256*4              ; Check to see if we've reached the limit
                BNE LUTLOOP             ; No: copy this next byte too

INITBITMAP      ; Initialize the sprite bitmap

                LDX #0                  ; Set X to point to the first byte
BITMAPLOOP      LDA IMG_START,X         ; Get a byte of bitmap data
                STA SP0_VRAM,X          ; Save it to Video RAM
                INX                     ; Move to the next byte
                CPX #32*32              ; Check to see if we've reached the limit
                BNE BITMAPLOOP          ; No: copy this next byte too

SHOWSPRITE      ; Set Vicky registers to display sprite

                ; Turn on the sprite graphics engine with text overlay
                LDA #Mstr_Ctrl_Text_Mode_En | Mstr_Ctrl_Text_Overlay | Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En
                STA MASTER_CTRL_REG_L

                LDA #$01                ; Enable Sprite #0
                STA SP00_CONTROL_REG

                LDA #0                  ; Tell Vicky that the sprite is at the start of VRAM
                STA SP00_ADDY_PTR_L
                STA SP00_ADDY_PTR_M
                STA SP00_ADDY_PTR_H

                REP #$20                ; Switch to wide accumulator
                .al

                LDA #100                ; Set position to (100, 100)
                STA SP00_X_POS_L
                STA SP00_Y_POS_L

                BRK                     ; Trigger the machine language monitor
                BRK                     ; Place holder "operand" byte

.include "bitmap.asm"                   ; Include the data for the sprite's bitmap
.include "colors.asm"                   ; Include the data for the sprite's colors
