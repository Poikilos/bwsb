;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Sound Blaster Oversampling Rate Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Include sbtick.inc

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: SetOverRate
 Calling: ah      Oversampling KHz
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
SetOverRate         Proc    Near    Uses eax ebx ecx edx esi
    Movzx   bx, ah                     ;Get oversample rate for table
IfDef SBPRO
    Shl     bx, 1
Else
    Dec     bx
EndIf
    Mov     al, SBTickTable[bx]        ;Look up in SB Tick table
    Cmp     al, 21                     ;Are we trying to play above 45KHz?
    Jae     @F
    Mov     al, 21                     ;Yeah, set back to maximum
@@: Push    ax
    Neg     al                         ;256-AL = SB Ticks
    Mov     SBTickerRate, al
    Pop     cx
IfDef SBPRO
    Shl     cx, 1
EndIf
    Xor     ch, ch
    Mov     dx, 0Fh                    ;Get 1,000,000\SBTicks=Real OverRate
    Mov     ax, 4240h
    Div     cx

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
    Mov     cl, SBTickerRate
    Mov     dx, SBAddr                 ;Get the SB's Base I/O Address
    Add     dl, 0Ch                    ;Base+0Ch=DSP Write Command or Data

@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, 040h                   ;DSP Set Sample Rate command
    Out     dx, al                     ;Write the command

@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, cl
    Out     dx, al                     ;Send play rate to DSP
    Ret
SBOverRate          EndP
