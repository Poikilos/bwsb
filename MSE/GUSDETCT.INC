;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Gravis Ultrasound Detection Routines Begin Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Note:  ULTRASND environment variable autodetection routines originally
;        by Patch (hamell@cs.pdx.edu)..
;
;        ULTRASND=220,5,5,11,5
; Base I/O Address Ù  ³ ³  ³ À MIDI IRQ
;        Playback DMA Ù ³  À GF1 IRQ
;            Record DMA Ù
; ---------------------------------------------------------------------------
GUSAddrTable    dw      220h, 240h, 210h, 230h, 250h, 260h
UltraSndString  db      'ULTRASND='
UltraStringLen  EQU     $-UltraSndString

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ReadULTRASND
 Calling: none
 Returns: GUSAddr   Gravis Ultrasound's base I/O address
          GUSIRQ    Gravis Ultrasound's GF1 IRQ level
         GUSIRQMidi Gravis Ultrasound's MIDI IRQ level
          GUSDMA    Gravis Ultrasound's playback DMA channel
       GUSDMARecord Gravis Ultrasound's recording DMA channel
          CFlag     Set if couldn't find ULTRASND environment variable
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ReadULTRASND    Proc        Near    Uses eax ebx ecx edx ds di
    Mov     ah, 62h                    ;Get PSP address
    Int     21h
    Mov     ds, bx                     ;DS - Segment of PSP
    Mov     ds, ds:[2Ch]               ;Get Environment address
    Xor     di, di                     ;DS:DI - Pointer to Environment Area
    Mov     dx, Offset UltraSndString

CheckVar:
    Mov     bx, dx                     ;Offset into 'ULTRASND=' string
    Mov     cl, UltraStringLen         ;Counter for 'ULTRASND=' string
GoodVarLoop:
    Mov     al, Byte PTR ds:[di]       ;Get a byte in the environment
    Cmp     al, Byte PTR cs:[bx]       ;Does it match the 'ULTRASND=' string?
    Jne     Short SkipVar              ;Nope, move to next environment variable
    Inc     di                         ;Update pointers, try next byte
    Inc     bx
    Dec     cl                         ;Decrement 'ULTRASND=' length counter
    Jz      Short GoodVarFound
    Jmp     Short GoodVarLoop

SkipVar:
    Inc     di
    Mov     al, ds:[di]
    Or      al, al                     ;Loop until hit Z in ASCIIZ
    Jnz     SkipVar
    Inc     di
    Mov     al, ds:[di]
    Or      al, al                     ;Is this last variable in environment?
    Jnz     CheckVar                   ;Loop if not
    Stc                                ;ULTRASND variable not found, set error
    Jmp     Short Exit                 ;Return with error

GoodVarFound:
    Mov     cl, 3                      ;Counter for address string length
    Xor     bx, bx                     ;Start at Address 0
GetAddrLoop:
    Shl     bx, 4                      ;Move bits for next digit
    Mov     dl, Byte PTR ds:[di]       ;Get one more digit in environment string
    Inc     di
    Sub     dl, '0'                    ;Convert ASCII to number
    Or      bl, dl                     ;Copy digit into BX
    Dec     cl                         ;Decrement digit counter
    Jnz     GetAddrLoop                ;If not all read, loop

    Cmp     GUSAddr, 0FFFFh
    Jne     Short @F
    Mov     GUSAddr, bx                ;Save our new GUS address
@@: Inc     di                         ;Skip over comma

GetPlayDma:
    Mov     dl, Byte PTR ds:[di]       ;Get one more digit in environment string
    Sub     dl, '0'                    ;Convert ASCII to number

    Cmp     GUSDMA, 0FFh
    Jne     Short @F
    Mov     GUSDMA, dl                 ;Save our new GUS playback DMA
@@: Add     di, 2                      ;Increment pointer/skip over comma

GetRecordDma:
    Mov     dl, Byte PTR ds:[di]       ;Get one more digit in environment string
    Sub     dl, '0'                    ;Convert ASCII to number

    Mov     GUSDMARecord, dl           ;Save our new GUS recording DMA
    Add     di, 2                      ;Increment pointer/skip over comma

GetGF1IRQ:
    Xor     bl, bl
    Cmp     Byte PTR ds:[di+2], ","    ;Is this a two character IRQ number?
    Jne     Short @F
    Inc     di                         ;Skip past the 1 in variable
    Mov     bl, 10                     ;Add 10 to the IRQ value
@@:
    Mov     dl, Byte PTR ds:[di]       ;Get IRQ number
    Sub     dl, '0'                    ;Convert ASCII to number
    Add     bl, dl

    Cmp     GUSIRQ, 0FFh
    Jne     Short @F
    Mov     GUSIRQ, bl                 ;Save new GF1 IRQ level
@@: Add     di, 2                      ;Skip over digit and comma

GetMidiIRQ:
    Xor     bl, bl
    Cmp     Byte PTR ds:[di+2], ","    ;Is this a two character IRQ number?
    Jne     Short @F
    Inc     di                         ;Skip past the 1 in variable
    Mov     bl, 10                     ;Add 10 to the IRQ value
@@:
    Mov     dl, Byte PTR ds:[di]       ;Get IRQ number
    Sub     dl, '0'                    ;Convert ASCII to number
    Add     bl, dl

    Mov     GUSIRQMidi, bl             ;Save new MIDI IRQ level

    Clc                                ;All stuff was read, no errors
Exit:
    Ret
ReadULTRASND    EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DetectGUSAddr (using hardware)
 Calling: none
 Returns: GUSAddr   Gravis Ultrasound's I/O address
          CFlag     Set if couldn't detect, clear if everything okay.
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DetectGUSAddr   Proc        Near    Uses eax ebx ecx edx ds di
    Xor     ebx, ebx                   ;Table of Addresses pointer

CheckLoop:
    Mov     dx, [GUSAddrTable+ebx*2]   ;Get next GUS address to test from table
    Mov     GUSAddr, dx                ;Save this addresss

    Call    CheckGUS                   ;Does the GUS respond here?
    Jnc     Short Exit                 ;Exit if it does

    Inc     ebx                        ;Try next GUS address
    Cmp     ebx, 6                     ;Was this the last of them?
    Jne     CheckLoop                  ;Loop if not...

    Mov     GUSAddr, 0FFFFh            ;Flag that GUSAddr still needs detecting
    Stc                                ;Set error, we failed here..

Exit:
    Ret
DetectGUSAddr   EndP

SetupVect       Macro       INTR, IRQNUM, IRQName
    Mov     ax, 3500h+INTR              ;INTR - Interrupt Number
    Int     21h
    Mov     Word PTR OldIRQVector+IRQNUM*4, bx   ;Save interrupt's offset address
    Mov     Word PTR OldIRQVector+IRQNUM*4+2, es ;Save interrupt's segment address

    Mov     ax, 2500h+INTR              ;INTR - Interrupt Number
    Mov     dx, Offset IRQName
    Int     21h
EndM

RestoreVect     Macro       INTR, IRQNUM
    Mov     ax, 2500h+INTR              ;INTR - Interrupt Number
    Mov     dx, Word PTR OldIRQVector+IRQNUM*4 ;Save interrupt's offset address
    Mov     ds, Word PTR OldIRQVector+IRQNUM*4+2 ;Save interrupt's segment address
    Int     21h
EndM

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DetectGUSIRQ  [0][1] 2 #3#[4] 5 [6] 7 [8] [9] [10] 11  12 [13] [14] 15
 Calling: none           8  9  A  B  C  D  E  F 70h 71h 72h  73h 74h 75h 76h 77h
 Returns: GUSIRQ    Gravis Ultrasound's I/O address XOR 388h
          CFlag     Set if couldn't detect, clear if everything okay.
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
OldIRQVector    dd      6 dup (?)      ;Old IRQ vectors
DetectGUSIRQ    Proc        Near    Uses eax ebx ecx edx
    Mov     GUSIRQ, 0FFh
    Mov     GUSTickerRate, 0FFh

    Cli
    In      al, 0A1h                   ;Get current IRQ masks
    Mov     ah, al
    In      al, 021h
    Mov     Word PTR TempLoc, ax       ;Save current mask for later

    And     ax, 0110011101011011b      ;Enable IRQs 2,5,7,11,12,15
    Out     021h, al                   ;Reprogram PITs with new masks
    Mov     al, ah
    Out     0A1h, al

    Push    es
    Push    ds
    Mov     ax, cs
    Mov     ds, ax
    SetupVect   0Ah, 0, DummyIRQ2
    SetupVect   0Dh, 1, DummyIRQ5
    SetupVect   0Fh, 2, DummyIRQ7
    SetupVect   73h, 3, DummyIRQ11
    SetupVect   74h, 4, DummyIRQ12
    SetupVect   77h, 5, DummyIRQ15
    Pop     ds
    Pop     es

    Mov     dx, GUSAddr                ;2x0h - Mixer Control Port
    Xor     al, al                     ;Enable Line In/Out, IRQ Latches
    Out     dx, al
    Sti                                ;Allow interrupts again

    Call    SetUltraTimer1             ;Program the GUS to do our stuff

    Cli
    Mov     dx, GUSAddr                ;Mix Control Port
    Mov     al, 8                      ;Enable Line In/Out, IRQ Latches
    Out     dx, al

    Call    InitGUS
    GF1_Delay
    Call    SetUltraTimer1             ;Program the GUS to do our stuff

    Cli
    Mov     dx, GUSAddr
    Add     dx, 8                      ;2x8h - Timer Control Register (AdLib)
    Mov     al, 4                      ;Select 4, Adlib thang..
    Out     dx, al
    Inc     dx                         ;2x9h - Timer Data Register (AdLib)
    Mov     al, 128                    ;Reset IRQs
    Out     dx, al
    Sti

    Mov     ecx, 01FFFFh               ;Time out value

@@: Cmp     GUSIRQ, 0FFh
    Jne     Short GotOurIRQ

    Dec     ecx
    Jnz     @B

    Mov     GUSIRQ, 0FFh

GotOurIRQ:
    Cli
    Mov     dx, GUSRegAddr             ;3x3h - Global Register Select
    Mov     al, 45h                    ;45h - Timer Control Register
    Out     dx, al
    Add     dx, 2                      ;3x5h - Data High Port
    In      al, dx
    And     al, 0FBh                   ;Disable Timer 1 IRQ
    Out     dx, al

    Mov     ax, word ptr TempLoc       ;Restore old IRQ masks
    Out     021h, al
    Mov     al, ah
    Out     0A1h, al
    Sti

    Push    ds
    RestoreVect 0Ah, 0
    RestoreVect 0Dh, 1
    RestoreVect 0Fh, 2
    RestoreVect 73h, 3
    RestoreVect 74h, 4
    RestoreVect 77h, 5
    Pop     ds
    Cmp     GUSIRQ, 0FFh
    Jne     Short @F
    Stc
    Ret

@@: Clc
    Ret

DummyIRQ2:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      DummyIRQEnd
    Mov     GUSIRQ, 2
    Jmp     Short DummyIRQEnd
DummyIRQ5:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      Short DummyIRQEnd
    Mov     GUSIRQ, 5
    Jmp     Short DummyIRQEnd
DummyIRQ7:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      Short DummyIRQEnd
    Mov     GUSIRQ, 7
    Jmp     Short DummyIRQEnd
DummyIRQ11:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      Short DummyIRQEnd
    Mov     GUSIRQ, 11
    Jmp     Short DummyIRQEnd
DummyIRQ12:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      Short DummyIRQEnd
    Mov     GUSIRQ, 12
    Jmp     Short DummyIRQEnd
DummyIRQ15:
    Push    eax
    Push    edx
    Mov     dx, GUSAddr
    Add     dx, 6
    In      al, dx
    Or      al, al
    Jz      Short DummyIRQEnd
    Mov     GUSIRQ, 15

DummyIRQEnd:
    Mov     al, 20h                    ;Send EOI code
    Out     0A0h, al                   ;PIC 2
    Out     020h, al                   ;PIC 1
    Pop     edx
    Pop     eax
    Iret
DetectGUSIRQ    EndP
