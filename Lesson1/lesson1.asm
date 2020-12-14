;;;
;;; Simple assembly code for the C256 Foenix to set the border to green
;;;

;
; Preamble
;

.cpu "65816"                    ; Tell the assembler we're using a 65816 processor
* = $010000                     ; Set the starting address for our code

;
; Start of our code
;

START           SEP #$20        ; Set the accumulator to 8-bit wide
                .as             ; Tell the assembler the accumulator is 8-bits wide

                LDA #0          ; Set the accumulator to 0
                STA $AF0005     ; Set blue component to 0
                STA $AF0007     ; Set red component to 0

                LDA #255        ; Set the accumulator to 255
                STA $AF0006     ; Set green component to 255

                BRK             ; Trigger the machine language monitor
                BRK             ; Place holder "operand" byte