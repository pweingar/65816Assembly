;;;
;;; Definitions of all the variables we're going to use
;;;

NUM_GAMEOBJ = 5                         ; How many game objects should we support

;
; Types
;

; Structure to represent the hardware registers for VICKY sprites
HWSPRITE        .struct
CONTROL         .byte ?                 ; Control register (enable, LUT, layer)
ADDRESS         .long ?                 ; Address of the sprite's bitmap (relative to start of VRAM)
X               .word ?                 ; X coordinate
Y               .word ?                 ; Y coordinate
                .ends


; Structure to represent a game object
GAMEOBJ         .struct type
TYPE            .word \type             ; The type of the sprite: 0 = Unused, 1 = Player, 2 = Missile, 3 = Enemy Ship
X               .word ?                 ; X-coordinate of the sprite
Y               .word ?                 ; Y-coordinate of the sprite
DX              .word ?                 ; Horizontal velocity
DY              .word ?                 ; Vertical velocity
HWREG           .dword ?                ; Pointer to the hardware registers for this sprite
BITMAP          .dword ?                ; Pointer to the bitmap for this sprite
COMPUTER        .word ?                 ; Pointer to procedure that does the COMPUTE step
                .ends

;
; Variables
;

* = $2000                                           ; Variables start at $002000

OLDIRQ          .word ?                             ; Location to save the old IRQ vector address
SOURCE          .dword ?                            ; Address of source data for bitmap copying
DEST            .dword ?                            ; Address of destination for bitmap copying
COUNT           .dword ?                            ; Number of bytes to copy
CURRSP          .dword ?                            ; Pointer to the hardware sprite registers for the current sprite
PROCEDURE       .word ?                             ; Pointer to the COMPUTE function of the current game object
GO_TARGET       .word ?                             ; Pointer to the target game object
GAMEOBJS        .fill size(GAMEOBJ)*NUM_GAMEOBJ     ; Reserve space for the game objects
SENTINEL        .dstruct GAMEOBJ, $FFFF             ; A placeholder game object that marks the end of the list
FLI_ACTIVE      .word 0                             ; Is a flier on the screen?
FLI_TIMER       .word 0                             ; Number of ticks to wait before spawning
TOR_INIT_X      .word 0                             ; Launch position X
TOR_INIT_Y      .word 0                             ; Launch position Y
TOR_COUNT       .word 0                             ; How many torpedos are flying?

;
; Shortcut definitions
;

GO_SHIP = GAMEOBJS                                  ; Address of ship's game object
