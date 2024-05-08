;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Sound Blaster Oversampling Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;Calling:
;       ah      Oversampling KHz
;Returning:
;       None
SetOverRate         Proc    Near    Uses eax ebx ecx edx si
    Xor     dx, dx
    Movzx   ax, ah
    Mov     bx, 1000
    Mul     bx

    Mov     OverRate, ax               ;Save real over sampling rate

    Mov     cl, 32
    Xor     si, si
BPMCalculate:
    Mov     ah, Byte PTR OverRate
    Mov     dl, Byte PTR OverRate+1
    Xor     al, al
    Xor     dh, dh
    Mov     bx, cs:[BPMTable+si]       ;Look up BPM Hertz in table
    Div     bx
    Mov     cs:[BPMTickTable+si], ax
    Add     si, 2
    Inc     cl
    Jnz     BPMCalculate

    Mov     eax, AmigaClockHz
    Xor     edx, edx
    Movzx   ebx, OverRate
    Div     ebx
    Mov     ClockHertz, eax

    Ret                                ;Return to caller
SetOverRate         EndP

SBOverRate          Proc    Near
    Mov     cx, OverRate
    Mov     dx, SBAddr                 ;Get the SB's Base I/O Address
    Add     dl, 0Ch                    ;Base+0Ch=DSP Write Command or Data

@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, 041h                   ;DSP Set Sample Rate command
    Out     dx, al                     ;Write the command

@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, ch
    Out     dx, al                     ;Send play rate to DSP

@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, cl
    Out     dx, al                     ;Send play rate to DSP

    Ret
SBOverRate          EndP
