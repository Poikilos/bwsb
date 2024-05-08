;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Miscelleous Sound Blaster Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: SBDACOn
 Calling: none
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
SBDACOn         Proc    Near    Uses eax edx
    Mov     dx, SBAddr
    Add     dl, 0Ch                    ;Base+0Ch=DSP Write Data or Command

@@: In      al, dx                     ;Get write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, the SB isn't ready for data

    Mov     al, 0D1h                   ;DSP command to turn on DAC output
    Out     dx, al                     ;Output the command to the Sound Blaster

    Ret
SBDACOn         EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: SBDACOff
 Calling: none
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
SBDACOff        Proc    Near    Uses eax edx
    Mov     dx, SBAddr
    Add     dl, 0Ch                    ;Base+0Ch=DSP Write Data or Command

@@: In      al, dx                     ;Get write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, the SB isn't ready for data

    Mov     al, 0D3h                   ;DSP command to turn off DAC output
    Out     dx, al                     ;Output the command to the Sound Blaster

    Ret                                ;Return to caller
SBDACOff        EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: ResetDSP
 Calling: none
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
ResetDSP            Proc    Near    Uses eax ecx edx
    Mov     dx, SBAddr                 ;Get the SB's base I/O address
    Add     dl, 6                      ;Base+6 = DSP Reset Port
    Mov     al, 1                      ;Send DSP Reset a 1 to let it know we're
    Out     dx, al                     ;resetting the DSP

    In      al, dx                     ;This section does the 3.3ms delay
    In      al, dx                     ;2
    In      al, dx                     ;3
    In      al, dx                     ;4
    In      al, dx                     ;5
    In      al, dx                     ;6

    Xor     al, al
    Out     dx, al                     ;Output 0 to the DSP Reset Port

    Mov     cx, 64                     ;Timeout for DSP return code

GetReturn:
    Push    ecx                        ;Save cx and dx, we're going to
    Push    edx                        ;mess 'em up.

    Add     dl, 8                      ;Base+Eh = Data Available Status
    Mov     cx, 1024                   ;Timeout for DSP data available

@@: In      al, dx                     ;Get data available status
    Or      al, al                     ;Check bit 7
    Js      Short @F                   ;If set, go get data and get out of loop
    Loop    @B                         ;Loop until CX=0.

@@:
    Sub     dl, 4                      ;Base+0Ah=DSP Read Data
    In      al, dx                     ;Get the data

GetDataExit:
    Pop     edx                        ;Okay, done playing with these registers
    Pop     ecx                        ;so we restore them..

    Cmp     al, 0AAh                   ;Did we get the return code?
    Je      Short GoodReset            ;If yes, go clear AX and exit

    Loop    GetReturn                  ;Loop until timeout or got a good
                                       ;return code
    Stc                                ;Set error code
    Ret

GoodReset:
    Clc                                ;Clear error flag

Exit:
    Ret
ResetDSP        EndP
