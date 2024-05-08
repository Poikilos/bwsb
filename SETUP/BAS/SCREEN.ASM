;
;Screen Routines for MSE Configuration Program
;Copyright (c) 1994, Edward Schlunder
;All rights reserved
;

.Model Medium, Basic
.286
.Data

Include main.inc                       ;Main Menu             (MAIN   )
Include sndcard.inc                    ;Sound Card Menu       (SNDCARD)
Include baseio.inc                     ;Base I/O Address Menu (BASEIO )
Include irq.inc                        ;IRQ Level             (IRQ    )
Include dma.inc                        ;DMA Channel           (DMA    )
Include quality.inc                    ;Sound Quality Menu    (QUALITY)

Include error.inc                      ;MSE Sound Card Error  (ERRROR )
Include test.inc                       ;Test Playing Screen   (TEST   )

.Code

;Calling:
;di - (Row * 80) + Col
Display     Macro   SCR,SCR_DEPTH,SCR_WIDTH
    Mov     bx, Row
    Mov     al, [bx]
    Mov     bl, 160
    Mul     bl
    Mov     di, ax

    Mov     bx, Col
    Mov     ax, [bx]
    Shl     ax, 1
    Add     di, ax



    Cld
    Mov     si, Offset SCR
    Mov     ax, 0B800h
    Mov     es, ax
    Mov     dl, SCR_DEPTH
@@:
    Mov     cx, SCR_WIDTH*2
    Rep     Movsb
    Sub     di, SCR_WIDTH*2
    Add     di, 160
    Dec     dl
    Jnz     @B
EndM

MainMenu        Proc    Uses es di si, Row:Word, Col:Word
    Display Main, Main_Depth, Main_Width
    Ret
MainMenu        EndP

SoundcardMenu   Proc    Uses es di si, Row:Word, Col:Word
    Display SndCard, SndCard_Depth, SndCard_Width
    Ret
SoundcardMenu   EndP

BaseioMenu      Proc    Uses es di si, Row:Word, Col:Word
    Display BaseIO, BaseIO_Depth, BaseIO_Width
    Ret
BaseioMenu      EndP

IRQMenu         Proc    Uses es di si, Row:Word, Col:Word
    Display IRQ, IRQ_Depth, IRQ_Width
    Ret
IRQMenu         EndP

DMAMenu         Proc    Uses es di si, Row:Word, Col:Word
    Display DMA, DMA_Depth, DMA_Width
    Ret
DMAMenu         EndP

QualityMenu     Proc    Uses es di si, Row:Word, Col:Word
    Display Quality, Quality_Depth, Quality_Width
    Ret
QualityMenu     EndP

TestScreen      Proc    Uses es di si, Row:Word, Col:Word
    Display Test, Test_Depth, Test_Width
    Ret
TestScreen      EndP

ErrorScreen     Proc    Uses es di si, Row:Word, Col:Word
    Display Error, Error_Depth, Error_Width
    Ret
ErrorScreen     EndP

End
