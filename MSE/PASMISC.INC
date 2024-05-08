;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Miscelleous Pro AudioSpectrum Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: GetPASVersion
 Calling: none
 Returns: al        Pro AudioSpectrum's hardware version (FFh - not found)
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
GetPASVersion       Proc    Near    Uses ebx ecx edx
    Mov     dx, 0B8Bh                  ;B8Bh - Interrupt Control
    Xor     dx, PASAddr                ;Translate using base i/o addr
    In      al, dx

    Cmp     al, 0FFh                   ;PAS not present?
    Je      Exit                       ;Yeah, exit with AL=FFh

    Mov     ah, al                     ;Save a copy here
    Xor     al, 11100000b              ;Invert the version number
    Out     dx, al                     ;Send the invertion
    Jmp     $+2                        ;Give PAS a rest
    Jmp     $+2
    In      al, dx                     ;AL=AH if PAS is good

    Cmp     al, ah                     ;Are they equal (good PAS?)?
    Xchg    al, ah
    Out     dx, al
    Mov     al, 0FFh                   ;Default is error
    Jne     Exit

    Mov     al, ah
    And     ax, 11100000b              ;Mask off AH and non-version bits
    Shr     al, 5                      ;Pull version down to 0 based

Exit:
    Ret
GetPASVersion       EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: InitPAS
 Calling: none
 Returns: CFlag     Set if error on initialization.
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
InitPAS             Proc    Near    Uses es di
    Mov     ax, 0BC02h                 ;MVSOUND.SYS - Get State Table Pointer
    Int     2Fh                        ;Call MVSOUND.SYS
    Cmp     ax, 'MV'                   ;Did the call go through?
    Je      @F
    Stc                                ;No, set error and exit
    Ret

@@: Mov     Word PTR PASShadow[0], bx
    Mov     Word PTR PASShadow[2], dx

    Les     di, PASShadow              ;Get pointer to PAS state table

    Mov     dx, 0B8Ah                  ;B8Ah - Audio Filter Control Register
    Xor     dx, PASAddr

    Cli
    Mov     al, es:[di.audiofilt]      ;Get current Audio Filter state
    And     al, 00111111b              ;Disable the Sample Rate & Buffer Timers
    Mov     es:[di.audiofilt], al      ;Save new Audio Filter state
    Out     dx, al                     ;Send new Audio Filter to PAS card

    Mov     al, PASDMA                 ;Mask off PAS's DMA channel
    Or      al, 0100b
    Movzx   dx, DMASingleMask          ;0Ah for DMA 0-3, D4h for DMA 4-7
    Out     dx, al

    Mov     dx, 0F8Ah                  ;F8Ah - Cross Channel Register
    Xor     dx, PASAddr
    Mov     al, es:[di.crosschannel]   ;Get current Cross Channel state
    And     al, 00111111b              ;Disable PCM state machine & DRQ control
    Or      al, 00010000b              ;Setup PAS for DAC output.
    Mov     es:[di.crosschannel], al   ;Save new Cross Channel state
    Out     dx, al                     ;Write new Cross Channel state to PAS

    Mov     dx, 8389h                  ;8389h - System Config 2
    Xor     dx, PASAddr
    In      al, dx                     ;Get current state
    And     al, 11110011b              ;Mask off 16bit and 12bit flags
    Out     dx, al                     ;Send new state to PAS card.

    Mov     dx, 0B8Bh                  ;B8Bh - Interrupt Control Register
    Xor     dx, PASAddr
    In      al, dx
    And     al, 11110011b              ;Disable sample rate/buffer timers
    Out     dx, al                     ;Send new Interrupt Control to PAS
    Mov     es:[di.intrctlr], al       ;Save above in state table

    Test    al, 00010011b              ;Are there Ints other than PCM?
    Jnz     Exit                       ;Yeah, don't mask off PIC then.

    Mov     cl, PASIRQ
    Cmp     cl, 2                      ;IRQ 2 (Chained?)
    Je      Exit

    Mov     dx, 021h                   ;21h - PIC1 Mask Register
    Cmp     PASIRQ, 8                  ;Are we using an IRQ off PIC2?
    Jb      @F
    Mov     dx, 0A1h                   ;A1h - PIC2 Mask Register
    Sub     cl, 8

@@: Mov     ah, 1                      ;Set appropriate bit
    Shl     ah, cl

    In      al, dx                     ;Get current mask
    Or      al, ah                     ;Mask off our IRQ
    Out     dx, al                     ;Send new IRQ mask

Exit:
    Sti

    Mov     dx, 0B89h                  ;B89h - Interrupt Control Status
    Xor     dx, PASAddr
    Out     dx, al                     ;Flush any pending IRQs

    Clc                                ;No error, return
    Ret
InitPAS             EndP
