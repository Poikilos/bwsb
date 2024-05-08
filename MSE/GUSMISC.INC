;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Miscellaneous Gravis Ultrasound Routines Begin Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
GUSChangeIRQ    db      0,0,1,3,0,2,0,4,0,0,0,5,6,0,0,7
GUSChangeDMA    db      1,0,2,0,3,4,5
GUSTotalMemory  dd      ?               ;256k, 512k, 768k, or 1024k

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_Poke
 Calling: ecx - address to poke data to
          bl  - data to poke into DRAM
 Returns: bl  - read back data
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
u_Poke        proc      near
    push    dx
    push    ax

    mov     dx, GUSRegAddr              ;3x3h - Global/GF1 Register Select
    mov     al, 43h                     ;43h - Set DRAM LSW Address
    out     dx, al

    inc     dx                          ;3x4h - 16bit Data I/O
    mov     ax, cx
    out     dx, ax

    dec     dx                          ;3x3h - Global/GF1 Register Select
    mov     al, 44h                     ;44h - Set DRAM MSW Address
    out     dx, al

    add     dx, 2                       ;3x5h - 8bit Data I/O
    mov     eax, ecx
    shr     eax, 16                     ;get upper word of ECX
    out     dx, al

    add     dx, 2                       ;3x7h - DRAM Direct I/O
    mov     al, bl
    out     dx, al
    in      al, dx

    mov     bl, al
    pop     ax
    pop     dx
    ret
u_Poke          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_Peek
 Calling: ecx - address to peek data from
 Returns: bl  - read back data
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
u_Peek        proc      near
    push    dx
    push    ax

    mov     dx, GUSRegAddr              ;3x3h - Global/GF1 Register Select
    mov     al, 43h                     ;43h - Set DRAM LSW Address
    out     dx, al

    inc     dx                          ;3x4h - 16bit Data I/O
    mov     ax, cx
    out     dx, ax

    dec     dx                          ;3x3h - Global/GF1 Register Select
    mov     al, 44h                     ;44h - Set DRAM MSW Address
    out     dx, al

    add     dx, 2                       ;3x5h - 8bit Data I/O
    mov     eax, ecx
    shr     eax, 16                     ;get upper word of ECX
    out     dx, al

    add     dx, 2                       ;3x7h - DRAM Direct I/O
    in      al, dx

    mov     bl, al
    pop     ax
    pop     dx
    ret
u_Peek          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_MemSize
 Calling:
 Returns: ax  - UltraSound DRAM size:
                256, 512, 768, 1024
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
u_MemSize       proc    near
    xor     ecx, ecx

SizeLoop:
    add     ecx, 262144                 ;move to next bank
    cmp     ecx, 1048576
    jae     FoundSize

    mov     bl, 0AAh
    call    u_Poke

    cmp     bl, 0AAh
    je      SizeLoop

FoundSize:
    mov     eax, ecx
    ret
u_MemSize       endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PreInitGUS
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PreInitGUS      Proc        Near    Uses eax ebx ecx edx
    Cmp     GUSIRQ, 0FFh               ;If any values are unitialized, don't
    Je      Exit                       ;pre-init GUS!
    Cmp     GUSIRQMidi, 0FFh
    Je      Exit
    Cmp     GUSDMA, 0FFh
    Je      Exit
    Cmp     GUSDMARecord, 0FFh
    Je      Exit

    Cli
    Movzx   bx, GUSIRQMidi
    Mov     cl, Byte PTR cs:[GUSChangeIRQ+bx]
    Shl     cl, 3
    Movzx   bx, GUSIRQ
    Or      cl, Byte PTR cs:[GUSChangeIRQ+bx]
    Cmp     bl, GUSIRQMidi             ;Sharing IRQs?
    Jne     Short @F
    And     cl, 00000111b              ;Only use GF1 IRQ
    Or      cl, 01000000b              ;Flag that we're sharing IRQs
@@: Movzx   bx, GUSDMA
    Mov     dl, Byte PTR cs:[GUSChangeDMA+bx-1]
    Shl     dl, 3
    Movzx   bx, GUSDMARecord
    Or      dl, Byte PTR cs:[GUSChangeDMA+bx-1]
    Cmp     bl, GUSDMA
    Jne     Short @F
    And     dl, 00000111b              ;Only use Record DMA
    Or      dl, 01000000b              ;Flag that we're sharing DMAs
@@: Mov     bl, dl

    Mov     dx, GUSAddr
    Mov     al, 8                      ;Set DMA Control
    Out     dx, al
    Add     dx, 0Bh                    ;DMA/IRQ Control Port
    Mov     al, bl
    Or      al, 80h
    Out     dx, al                     ;Write new DMA channels

    Mov     dx, GUSAddr
    Mov     al, 48h                    ;Set IRQ Control
    Out     dx, al
    Add     dx, 0Bh                    ;IRQ/DMA Control Port
    Mov     al, cl
    Out     dx, al

    Mov     dx, GUSAddr                ;2x0h -
    Mov     al, 8
    Out     dx, al
    Add     dx, 0Bh                    ;2xBh
    Mov     al, bl
    Out     dx, al

    Mov     dx, GUSAddr                ;2x0h -
    Mov     al, 48h
    Out     dx, al
    Add     dx, 0Bh                    ;2xBh -
    Mov     al, cl
    Out     dx, al

    Mov     dx, GUSAddr
    Add     dx, 102h                   ;3x2h -
    Xor     al, al
    Out     dx, al
    Xor     al, al
    Out     dx, al
    Sti
Exit:
    Ret
PreInitGUS      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: InitGUS
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
InitGUS         Proc        Near    Uses eax ebx ecx edx
    cli
;ÄÄ Setup little helper registers
    Mov     bx, GUSRegAddr             ;3x3h - Global/GF1 Register Select
    Mov     cx, bx
    Add     cx, 2                      ;3x5h - Data High Port

;ÄÄ Do a GUS global reset
    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 4Ch                    ;4Ch - Reset Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Xor     al, al                     ;GF1 Master Reset, DAC Off, IRQs Off
    Out     dx, al                     ;Clear all bits (Reset GUS, DAC, IRQ)
    GF1_Delay
    GF1_Delay

    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 4Ch                    ;4Ch - Reset Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Mov     al, 1                      ;GF1 Master Reset Run
    Out     dx, al
    GF1_Delay
    GF1_Delay

;ÄÄ GUS MIDI Reset
    Mov     dx, GUSAddr
    Add     dx, 100h                   ;3x0h - MIDI Control Port
    Mov     al, 11b                    ;Toggle high......
    Out     dx, al
    GF1_Delay
    Mov     al, 00b                    ;then toggle low
    Out     dx, al
    GF1_Delay

;ÄÄ GUS DMA Reset
    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 41h                    ;41h - DMA Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Xor     al, al                     ;DMA Off, Write, 8Bit, 650KHz, IRQ Off, 8Bit, Unsigned
    Out     dx, al

;ÄÄ GUS DRAM Heap Init
    push    cx
    push    bx

    call    u_MemSize
    mov     GUSTotalMemory, eax

    xor     ecx, ecx                    ;mark memory block as unused
    mov     bl, 0
    call    u_Poke
    inc     ecx
    mov     eax, GUSTotalMemory

    mov     bl, al
    call    u_Poke
    inc     ecx
    mov     bl, ah
    call    u_Poke
    inc     ecx

    shr     eax, 16                     ;High order bytes are last
    mov     bl, al
    call    u_Poke
    inc     ecx
    mov     bl, ah
    call    u_Poke
    inc     ecx

    pop     bx
    pop     cx
;ÄÄ GUS DRAM Address
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 44h                    ;44h - Set DRAM Address MSB
    Out     dx, al

    Mov     dx, cx                     ;3x5h - Data High Byte Port
    Xor     al, al                     ;Start back at 0
    Out     dx, al
    Sub     dx, 2                      ;3x3h - Global Register Port
    Mov     al, 43h                    ;43h - Set DRAM Address LSB
    Out     dx, al
    Inc     dx                         ;3x4h - Data Low Byte Port
    Xor     ax, ax                     ;Start back at 0
    Out     dx, ax

;ÄÄ GUS Timer
    Mov     dx, GUSAddr
    Add     dx, 9                      ;2x9h - Timer Data Register
    Mov     al, 80h                    ;Reset Timer IRQ
    Out     dx, al
    Xor     al, al
    Out     dx, al

    Mov     dx, bx                     ;3x3h - Global Register Port
    Mov     al, 46h                    ;46h - Timer 1 Count
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Xor     al, al                     ;Set 0FFh count
    Out     dx, al

    Mov     dx, bx                     ;3x3h - Global Register Port
    Mov     al, 47h                    ;47h - Timer 2 Count
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data high port
    Xor     al, al                     ;Set 0FFh count
    Out     dx, al

    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 45h                    ;Timer Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Xor     al, al                     ;Disable 80ms and 320ms timers
    Out     dx, al

;ÄÄ GUS Active Voices
    Mov     dx, bx                     ;3x3h - GF1 Register Select
    Mov     al, 0Eh                    ;0Eh - Set Active Voices
    Out     dx, al

    Mov     dx, cx                     ;3x5h - Data High Byte Port
    Mov     al, 0DFh                   ;Enable all 32 channels
    Out     dx, al

;ÄÄ GUS Recording
    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 49h                    ;49h - Sampling Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    Xor     al, al                     ;Disable GUS sampling
    Out     dx, al

;ÄÄ Clear IRQs
    Mov     dx, GUSAddr
    Add     dx, 06h                    ;2x6h - IRQ Status Port
    In      al, dx

;ÄÄ Clear DMA
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 41h                    ;41h - DMA Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    In      al, dx

;ÄÄ Clear Sampling Control
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 49h                    ;49h - Sampling Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    In      al, dx

;ÄÄ Clear IRQ Source
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 8Fh                    ;8Fh - IRQ Source Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Port
    In      al, dx

;ÄÄ Initialize all channels
    Push    cx                         ;Save Data High Register
    Mov     cx, 32                     ;GUS has 32 channels

ChanLoop:
    Mov     dx, GUSAddr
    Add     dx, 102h                   ;3x2h - GUS Page Register
    Mov     al, cl                     ;Select channel we're gonna fix up
    Dec     al
    Out     dx, al

    Inc     dx                         ;3x3h - GF1 Register Select
    Xor     al, al                     ;00h - Channel control
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data High Port
    Mov     al, 3                      ;Turn this channel off!
    Out     dx, al

    Sub     dx, 2                      ;3x3h - GF1 Register Select Port
    Mov     al, 0Dh                    ;0Dh - Volume Ramp Control
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data High Port
    Mov     al, 3                      ;Turn off the volume ramp
    Out     dx, al

    Loop    ChanLoop                   ;Go through all the channels
    Pop     cx                         ;Restore Data High Register

;ÄÄ Clear DMA Control
    Mov     dx, bx                     ;3x3h - Global Reg Port
    Mov     al, 41h                    ;41h - DMA Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Reg
    In      al, dx

;ÄÄ Clear Sampling Control
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 49h                    ;49h - Sampling Control Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Reg
    In      al, dx

;ÄÄ Clear IRQ Source
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 8Fh                    ;IRQ Source Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Reg
    In      al, dx

;ÄÄ Global Reset
    Mov     dx, bx                     ;3x3h - Global Register Select
    Mov     al, 4Ch                    ;4Ch - GF1 Reset Register
    Out     dx, al
    Mov     dx, cx                     ;3x5h - Data High Reg
    Mov     al, 7                      ;Enable GF1, DAC Output, and Master IRQ
    Out     dx, al

    Mov     cx, 32
SetRampRateLoop:
    Mov     dx, GUSAddr
    Add     dx, 102h                   ;3x2h - Page Register
    Mov     al, NumChannels
    Sub     al, cl
    Out     dx, al                     ;Set the channel we're working on here

;ÄÄ Set Volume Ramp Rate
    Mov     dx, GUSRegAddr             ;GF1 Register Select
    Mov     al, 06h                    ;Volume Ramp Rate Register
    Out     dx, al
    Mov     al, 00111111b              ;Do a Fast Ramp(tm)!
    Mov     dx, GUSAddr
    Add     dx, 105h                   ;Data High Port
    Out     dx, al

;ÄÄ Set Current Volume
    mov     dx, GUSRegAddr             ;GF1 Register Select
    mov     al, 09h                    ;Current Volume Register
    out     dx, al
    inc     dx                         ;Data Low Port
    xor     ax, ax
    out     dx, ax
    GF1_Delay
    out     dx, ax

    loop    SetRampRateLoop

    sti
    Ret
InitGUS         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CheckGUS
 Calling: dx        GUS base I/O address to check for GUS existance
 Returns: CFlag     Set if GUS not found, clear if is working properly
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
CheckGUS        Proc        Near
    Mov     dx, GUSAddr
    Add     dx, 107h                   ;DRAM I/O Address
    In      al, dx                     ;Get the current byte
    Mov     ah, al                     ;Save it for later

    Mov     al, 40h                    ;Our little test value
    Out     dx, al                     ;Write it to DRAM
    In      al, dx                     ;Read the test value back
    Cmp     al, 40h                    ;Did it change?
    Jne     Short ExitError            ;Yeah, no GUS on this port

    Xor     al, 81h                    ;Try a different test value
    Out     dx, al                     ;Write it to DRAM
    In      al, dx                     ;Read back!
    Cmp     al, 0C1h                   ;Is it what we expected?
    Jne     Short ExitError            ;No, exit with carry

    Mov     al, ah                     ;Get back the original value here
    Out     dx, al                     ;Rewrite it into GUS memory

    Clc                                ;No errors, this is the GUS port
    Ret                                ;Return to the caller

ExitError:
    Stc                                ;This port isn't the GUS's, set the error
    Ret
CheckGUS        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CalcBPMTimer
 Calling: BPM       BPM speed to calculate for
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
CalcBPMTimer    Proc        Near    Uses bx ax
    Mov     bl, BPM
    Cmp     bl, 125
    Jb      Short CalcLow
CalcHigh:
    Mov     ax, 15625
    Div     bl
    Neg     al
    Mov     GUSTickerRate, al
    Mov     NeedsTick, 2               ;Cut IRQs in half for 160ms timer
    Mov     TickTock, 2                ;Cut IRQs in half for 160ms timer

    Ret

CalcLow:
    Mov     ax, 7813
    Div     bl
    Neg     al
    Mov     GUSTickerRate, al
    Mov     NeedsTick, 4               ;Use all IRQs for 80ms timer
    Mov     TickTock, 4                ;Cut IRQs in half for 160ms timer

    Ret
CalcBPMTimer    EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetUltraTimer1
 Calling: ah        New Ultrasound Timer 1 speed to start up
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SetUltraTimer1  Proc        Near
    Cli
    Mov     dx, GUSRegAddr             ;3x3h - Register Select
    Mov     al, 46h                    ; 46h - Timer 1 Count
    Out     dx, al
    Add     dx, 2                      ;3x5h - MSB
    Mov     al, GUSTickerRate
    Out     dx, al

    Sub     dx, 2                      ;3x3h - Register Select
    Mov     al, 45h                    ; 45h - Timer Control
    Out     dx, al
    Add     dx, 2                      ;3x5h - MSB
    Mov     al, 0100b                  ;Enable Timer 1 IRQ
    Out     dx, al

    Mov     dx, GUSAddr
    Add     dx, 08h                    ;2x8h - Timer Control Reg (AdLib Control)
    Mov     al, 4
    Out     dx, al

    Inc     dx                         ;2x9h - Timer Data (AdLib Data)
    Mov     al, 1                      ;21h - Timer 1 Start (80ms timer)
    Out     dx, al

    Sti
    Ret
SetUltraTimer1  EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UltraSlideRamp
 Calling: ax        New channel volume to slide to
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
UltraSlideRamp  Proc        Near    Uses bx si
    Mov     si, ax
    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select
    Mov     al, 0Dh                    ;0Dh - Volume Ramp Control
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data MSB
    Mov     al, 3                      ;Manual stop ramp
    Out     dx, al

    Sub     dx, 2                      ;3x3h - GF1 Register Select
    Mov     al, 89h                    ;89h - Current Volume
    Out     dx, al
    Inc     dx                         ;3x4h - GF1 Data LSB
    In      ax, dx
    Push    si
    Push    ax
    Shr     ax, 8
    Shr     si, 8
    Cmp     ax, si
    Jb      Short @F
    Xchg    si, ax

@@: Push    ax
    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select
    Mov     al, 7                      ;07h - Volume Ramp Start
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data MSB
    Pop     ax
    Out     dx, al

    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select
    Mov     al, 8                      ;08h - Volume Ramp End
    Out     dx, al
    Add     dx, 2
    Mov     ax, si
    Out     dx, al

    Mov     dx, GUSRegAddr
    Mov     al, 6                      ;06h - Volume Ramp Speed
    Out     dx, al
    Add     dx, 2
    Mov     al, 00111111b
    Out     dx, al
    Xor     bl, bl
    Pop     ax
    Pop     si
    Cmp     ax, si
    Jb      Short @F
    Or      bl, 01000000b
@@: Mov     dx, GUSRegAddr
    Mov     al, 0Dh                    ;0Dh - Volume Ramp Control
    Out     dx, al
    Add     dx, 2
    Mov     al, bl
    Out     dx, al

    Ret
UltraSlideRamp  EndP
