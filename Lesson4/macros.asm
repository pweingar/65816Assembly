;
; Macros
;

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
