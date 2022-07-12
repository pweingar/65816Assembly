;
; Macros
;

; Set the direct page. 
; Note: This uses the accumulator and leaves A set to 16 bits. 
setdp           .macro        
                PHA             ; begin setdp macro 
                PHP
                setal
                LDA #\1         ; set DP
                TCD             
                .dpage \1
                PLP
                PLA             ; end setdp macro 
                .endm 

setdbr          .macro          ; Set the B (Data bank) register 
                PHA             ; begin setdbr macro 
                PHP
                setas
                LDA #\1
                PHA
                PLB
                .databank \1
                PLP
                PLA             ; end setdbr macro 
                .endm 

setas           .macro                  ; Make accumulator 8-bits
                SEP #$20
                .as
                .endm

setal           .macro                  ; Make accumulator 16-bit
                REP #$20
                .al
                .endm

setxs           .macro                  ; Make index registers 8-bits
                SEP #$10
                .xs
                .endm

setxl           .macro                  ; Make index registers 16-bits
                REP #$10
                .xl
                .endm

setaxs          .macro                  ; Make accumulator and index registers 8-bits
                SEP #$30
                .as
                .xs
                .endm

setaxl          .macro                  ; Make accumulator and index registers 16-bits
                REP #$30
                .al
                .xl
                .endm
