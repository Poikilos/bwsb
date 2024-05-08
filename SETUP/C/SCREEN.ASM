;
;Screen Routines for MSE Configuration Program
;Copyright (c) 1994-95, Edward Schlunder
;All rights reserved
;

.model medium, c
.386
.data

include main.inc                       ;Main Menu             (MAIN   )
include sndcard.inc                    ;Sound Card Menu       (SNDCARD)
include baseio.inc                     ;Base I/O Address Menu (BASEIO )
include irq.inc                        ;IRQ Level             (IRQ    )
include dma.inc                        ;DMA Channel           (DMA    )
include quality.inc                    ;Sound Quality Menu    (QUALITY)

include error.inc                      ;MSE Sound Card Error  (ERRROR )
include test.inc                       ;Test Playing Screen   (TEST   )

.code

;Calling:
;di - (Row * 80) + Col
Display     Macro   SCR,SCR_DEPTH,SCR_WIDTH
    mov     al, Row
    mov     bl, 160
    mul     bl
    mov     di, ax

    movzx   ax, Col
    shl     ax, 1
    add     di, ax

    cld
    mov     si, Offset SCR
    mov     ax, 0B800h
    mov     es, ax
    mov     dl, SCR_DEPTH
@@:
    mov     cx, SCR_WIDTH*2
    rep     Movsb
    sub     di, SCR_WIDTH*2
    add     di, 160
    dec     dl
    jnz     @B
EndM

MainMenu        proc    Uses di si, Row:byte, Col:byte
    Display MAIN, MAIN_DEPTH, MAIN_WIDTH
    ret
MainMenu        endp

SoundCardMenu   proc    Uses di si, Row:byte, Col:byte
    Display SNDCARD, SNDCARD_DEPTH, SNDCARD_WIDTH
    ret
SoundCardMenu   endp

BaseioMenu      proc    Uses di si, Row:byte, Col:byte
    Display BASEIO, BASEIO_DEPTH, BASEIO_WIDTH
    ret
BaseioMenu      endp

IRQMenu         proc    Uses di si, Row:byte, Col:byte
    Display IRQ, IRQ_DEPTH, IRQ_WIDTH
    ret
IRQMenu         endp

DMAMenu         proc    Uses di si, Row:byte, Col:byte
    Display DMA, DMA_DEPTH, DMA_WIDTH
    ret
DMAMenu         endp

QualityMenu     proc    Uses di si, Row:byte, Col:byte
    Display QUALITY, QUALITY_DEPTH, QUALITY_WIDTH
    ret
QualityMenu     endp

TestScreen      proc    Uses di si, Row:byte, Col:byte
    Display TEST, TEST_DEPTH, TEST_WIDTH
    ret
TestScreen      endp

ErrorScreen     proc    Uses di si, Row:byte, Col:byte
    Display ERROR, ERROR_DEPTH, ERROR_WIDTH
    ret
ErrorScreen     endp

End
