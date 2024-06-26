;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
; Pro AudioSpectrum Detection Routines Begin Here
;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     �-ZL�-
;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�

Comment *陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
 Routine: DetectPASAddr
 Calling: none
 Returns: PASAddr   Pro AudioSpectrum's I/O address XOR 388h
          CFlag     Set if couldn't detect, clear if everything okay.
 陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳*
DetectPASAddr       Proc    Near    Uses ax bx cx dx
    Mov     PASAddr, 0                 ;Test I/O Address 388h
    Call    GetPASVersion              ;Go try getting a version number
    Cmp     al, 0FFh                   ;Did the version error out
    Je      @F                         ;Yeah, try next i/o address
    Clc
    Ret                                ;No, this is the right one baby!

@@: Mov     PASAddr, 0Ch               ;Test I/O Address 384h
    Call    GetPASVersion              ;Go try getting a version number
    Cmp     al, 0FFh                   ;Did the version error out
    Je      @F                         ;Yeah, try next i/o address
    Clc
    Ret                                ;No, this is the right one baby!

@@: Mov     PASAddr, 4                 ;Test I/O Address 38Ch
    Call    GetPASVersion              ;Go try getting a version number
    Cmp     al, 0FFh                   ;Did the version error out
    Je      @F                         ;Yeah, try next i/o address
    Clc
    Ret                                ;No, this is the right one baby!

@@: Mov     PASAddr, 100h              ;Test I/O Address 288h
    Call    GetPASVersion              ;Go try getting a version number
    Cmp     al, 0FFh                   ;Did the version error out
    Je      @F                         ;Yeah, try next i/o address
    Clc
    Ret                                ;No, this is the right one baby!

@@: Stc                                ;Couldn't detect, set error
    Ret                                ;Return to caller
DetectPASAddr       EndP

Comment *陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
 Routine: DetectPASIRQ
 Calling: none
 Returns: PASIRQ    Pro AudioSpectrum's IRQ level
          CFlag     Set if couldn't detect, clear if everything's okay.
 陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳*
DetectPASIRQ        Proc        Near    Uses ax bx cx dx es ds
    Mov     ax, 0BC04h                 ;MVSOUND.SYS - Get PAS DMA/IRQ
    Int     2Fh
    Cmp     ax, 'MV'                   ;Are we sure this is from MVSOUND.SYS?
    Je      Exit
    Stc
    Ret

Exit:
    Mov     PASIRQ, cl                 ;Save returned IRQ number
    Clc
    Ret                                ;Return to caller
DetectPASIRQ        EndP

Comment *陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
 Routine: DetectPASDMA
 Calling: none
 Returns: PASDMA    Pro AudioSpectrum's DMA channel
          CFlag     Set if couldn't detect, clear if everything's okay.
 陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳*
DetectPASDMA        Proc        Near    Uses ax bx cx dx
    Mov     ax, 0BC04h                 ;MVSOUND.SYS - Get PAS DMA/IRQ
    Int     2Fh
    Cmp     ax, 'MV'                   ;Are we sure this is from MVSOUND.SYS?
    Je      Exit
    Stc
    Ret

Exit:
    Mov     PASDMA, bl                 ;Save returned DMA channel
    Clc
    Ret                                ;Return to caller
DetectPASDMA        EndP
