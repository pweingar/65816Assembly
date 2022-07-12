;;;
;;; Assembly code to display a sprite
;;;

;
; Preamble
;

.cpu "65816"                            ; Tell the assembler we're using a 65816 processor

;
; Define our segments
;

;
; Includes
;

.include "interrupts_def.asm"           ; Interrupt register and bit definitions
.include "macros.asm"                   ; Include macro definitions
.include "vicky_ii_inc.asm"             ; Include the definitions for VICKY II registers
.include "VKYII_CFP9553_SPRITE_def.asm" ; Include Vicky's sprite registers
.include "vicky_bitmap.asm"             ; Include definitions for bitmap graphics
.include "variables.asm"                ; Include the definitions of our variables

;
; Defines
;

IRQV = $00FFEE                          ; Native mode IRQ vector
JOYSTICK0 = $AFE800                     ; Joystick 0 (next to SD Card)
VRAM = $B00000                          ; Start of video RAM

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
JOY_BUTTON = $10                        ; Joystick fire button

; Where images go in VRAM...

SHIP_VRAM = VRAM                        ; The address of the ship bitmap in VRAM
TORPEDO_VRAM = VRAM + 32*32             ; The address of the torpedo bitmap in VRAM
FLIER_VRAM = VRAM + 32*32*2             ; The address of the flier bitmap in VRAM
BACKGROUND_VRAM = $B10000               ; Where will the bitmap go in VRAM?

BACKGROUND_SIZE = 640*480               ; How big is the bitmap (in bytes)?

;
; Start of our code
;

* = $3000                               ; Our program starts at $003000

START           CLC                     ; Make sure we're in native mode
                XCE

                setaxl                  ; Make accumulator and index registers 16-bits
                setdp <>OLDIRQ          ; Point the direct page to our BSS
                setdbr 0                ; Set our data bank to 0

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

;
; Initialize the game objects
;

                JSR BACKGROUND_INIT     ; Initialize the background image
                JSR GOBJ_INIT           ; Initialize the game objects as a whole
                JSR SHIP_INIT           ; Initialize the ship game object
                JSR TOR_INIT            ; Initialize the torpedo game object
                JSR FLI_INIT            ; Initialize the purple flier game object

SHOWSPRITE      ; Set Vicky registers to display sprite

                ; Turn on the sprite graphics engine with bitmaps, 640x480
                setas
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En | Mstr_Ctrl_Bitmap_En
                STA @l MASTER_CTRL_REG_L
                LDA #0
                STA @l MASTER_CTRL_REG_H

                ; Turn off the border and mouse pointer
                LDA #0
                STA @l BORDER_CTRL_REG
                STA @l MOUSE_PTR_CTRL_REG_L
                setaxl

                JSR FLI_LAUNCH          ; Launch the first purple flier
;
; Wait for the user to press a key and move the sprite accordingly
;

game_loop       CLI                     ; Enable IRQ
                WAI                     ; Wait for an interrupt
                
                JSR GOBJ_COMPUTE        ; Compute the actions of all the game objects
                JSR FLI_TICK            ; Check respawn timer for the flier... and create a new one if needed

                BRA game_loop           ; And wait for the next interrupt

;
; Handle a SOF IRQ... this is our interrupt handler
;
SOFHANDLE       setal                   ; Save registers we're going to change
                PHA
                PHX
                PHY

                setas
                LDA @l INT_PENDING_REG0 ; Check to see if we've gotten a SOF interrupt
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE SOFCLEAR            ; No: just clear the pending interrupt

                ; Yes: iterate through our sprites and update them

                LDX #<>GAMEOBJS         ; Point to the first game object                
SOFLOOP         JSR GOBJ_UPDATE         ; Update the current game object
                setal
                CLC                     ; Point to the next game object
                TXA
                ADC #size(GAMEOBJ)
                TAX

                LDA #GAMEOBJ.TYPE,B,X   ; Get the type of the object
                BPL SOFLOOP             ; Keep looping until the object is the sentinel

SOFCLEAR        setas
                LDA @l INT_PENDING_REG0 ; Clear all pending interrupts
                STA @l INT_PENDING_REG0

                setal                   ; Restore registers and return to main program
                PLY
                PLX
                PLA
                RTI

;
; Initialize the background image
;
BACKGROUND_INIT .proc
                PHP
                
                setxl
                setas
                LDX #0
loop_cm         LDA BACKGROUND_CM,X
                STA GRPH_LUT1_PTR,X
                INX
                CPX #4*256
                BNE loop_cm

                setaxl
                STZ COUNT+2
                STZ COUNT

                LDA #`BACKGROUND_BM         ; Set the source pointer
                STA SOURCE+2
                LDA #<>BACKGROUND_BM
                STA SOURCE

                LDA #`BACKGROUND_VRAM       ; Set the dest pointer
                STA DEST+2
                LDA #<>BACKGROUND_VRAM
                STA DEST

loop_bm         setas
                LDA [SOURCE]                ; Copy a byte of the bitmap
                STA [DEST]

                setal
                INC SOURCE                  ; Move to the next source byte
                BNE inc_dest
                INC SOURCE+2

inc_dest        INC DEST                    ; Move to the next destination address
                BNE inc_count
                INC DEST+2

inc_count       INC COUNT
                BNE chk_count
                INC COUNT+2

chk_count       LDA COUNT                   ; Have we copied all the bytes?
                CMP #<>BACKGROUND_SIZE
                BNE loop_bm                 ; No: keep looping
                LDA COUNT+2
                CMP #`BACKGROUND_SIZE
                BNE loop_bm

                LDA #<>BACKGROUND_VRAM      ; Tell VICKY where the image is
                STA BM0_START_ADDY_L
                setas
                SEC
                LDA #`BACKGROUND_VRAM
                SBC #`VRAM
                STA BM0_START_ADDY_H

                LDA #BM_LUT1 | BM_Enable
                STA BM0_CONTROL_REG

                LDA #0                      ; Disable
                STA BM1_CONTROL_REG

                PLP
                RTS
                .pend


.include "gameobject.asm"               ; Include the definitions for game objects
.include "ship.asm"                     ; Include the definitions for the ship game object
.include "torpedo.asm"                  ; Include the definitions for the torpedo game object
.include "flier.asm"                    ; Include the definitions for the purple flier game object
.include "rsrc/ship_bm.asm"             ; Include the data for the ship's bitmap
.include "rsrc/torpedo_bm.asm"          ; Include the data for the torpedo's bitmap
.include "rsrc/flier_bm.asm"            ; Include the data for the purple flier's bitmap
.include "rsrc/colors.asm"              ; Include the data for the sprite's colors
.include "rsrc/praesepe_cm.asm"         ; The colors for the background image
.include "rsrc/praesepe_bm.asm"         ; The bitmap for the background image

;
; Reset Vector (just here so I can download and start the program on the C256)
;

* = $00FFFC
                .word <>START