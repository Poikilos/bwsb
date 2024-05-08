;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Pro AudioSpectrum Oversampling Rate Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: LoadSoundDevice
 Calling: ah      Oversampling rate (xxKHz)
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
SetOverRate         Proc    Near    Uses eax ebx ecx edx esi
    Xor     dx, dx
    Movzx   ax, ah
    Mov     bx, 1000
    Mul     bx
    Mov     bx, ax

    Mov     dx, 0012h                  ;1193182 \ OverRate = PAS Timer Tick
    Mov     ax, 34DEh
    Div     bx
    Shr     ax, 1
    Mov     bx, ax
    Shl     bx, 1
    Mov     PASTickerRate, ax          ;Save tick speed for later use

    Mov     dx, 0012h                  ;1193182 \ PAS Timer Tick = OverRate
    Mov     ax, 34DEh
    Div     bx
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

PASOverRate         Proc    Near
    Mov     dx, 138Bh                  ;138Bh - Timer Control Register
    Xor     dx, PASAddr

    Mov     al, 00110110b              ;36h - Timer 0 / Square Wave Generator
    Out     dx, al                     ;Set the timer/mode/etc.


    Mov     dx, 1388h                  ;1388h - Sample Rate Timer Register
    Xor     dx, PASAddr

    Mov     ax, PASTickerRate          ;Send the actual timer count
    Out     dx, al                     ;Send LSB of timer count
    Jmp     $+2                        ;Slow down for PAS to catch up.
    Mov     al, ah                     ;Get MSB primed
    Out     dx, al                     ;Send MSB of timer count

    Ret
PASOverRate         EndP
