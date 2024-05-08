OldIRQ5         dd      ?              ;Holder for old IRQ5 vector
OldIRQ7         dd      ?              ;Holder for old IRQ7 vector
OldIRQ10        dd      ?              ;Holder for old IRQ10 vector

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Sound Blaster Detection Routines Begin Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DetectSBAddr
 Calling: none
 Returns: CFlag   Set if couldn't detect I/O address, clear if found
          SBAddr  Base I/O address of SB
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DetectSBAddr        Proc    Near    Uses eax ebx ecx dx

    Mov     dx, 220h                   ;Test I/O Address 220h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, go check other address
    Ret

@@: Mov     dx, 240h                   ;Test I/O Address 240h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, no (usable) SB detected!
    Ret

@@: Mov     dx, 210h                   ;Test I/O Address 210h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, no (usable) SB detected!
    Ret

@@: Mov     dx, 230h                   ;Test I/O Address 230h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, no (usable) SB detected!
    Ret

@@: Mov     dx, 250h                   ;Test I/O Address 250h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, no (usable) SB detected!
    Ret

@@: Mov     dx, 260h                   ;Test I/O Address 260h
    Mov     SBAddr, dx                 ;Put this into SBAddr for ResetDSP
    Call    ResetDSP                   ;Reset the DSP and see if it worked
    Jc      Short @F                   ;If error, no (usable) SB detected!
    Ret

@@: Mov     SBAddr, 0FFFFh             ;Make sure we flag error in SBAddr
    Stc                                ;Set error and return
    Ret                                ;Return to caller
DetectSBAddr        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DetectSBIRQ
 Calling: none
 Returns: CFlag   Set if couldn't detect, clear on success
          SBIRQ   SB's IRQ number or 0FFh if couldn't detect
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DetectSBIRQ         Proc        Near    Uses eax ebx ecx edx es ds

    Mov     ax, 350Ah                  ;Get the old IRQ vectors and store them
    Int     21h
    Mov     Word PTR OldIRQ, bx        ;IRQ 2 Offset
    Mov     Word PTR OldIRQ+2, es      ;IRQ 2 Segment

    Mov     al, 0Dh
    Int     21h
    Mov     Word PTR OldIRQ5, bx       ;IRQ 5 Offset
    Mov     Word PTR OldIRQ5+2, es     ;IRQ 5 Segment

    Mov     al, 0Fh
    Int     21h
    Mov     Word PTR OldIRQ7, bx       ;IRQ 7 Offset
    Mov     Word PTR OldIRQ7+2, es     ;IRQ 7 Segment

    Mov     al, 72h
    Int     21h
    Mov     Word PTR OldIRQ10, bx      ;IRQ 10 Offset
    Mov     Word PTR OldIRQ10+2, es    ;IRQ 10 Segment

    Mov     ax, cs                     ;Put code segment in DS for DOS
    Mov     ds, ax

    Mov     ax, 250Ah                  ;Set up the vectors for our own handlers
    Mov     dx, Offset SBDIRQ2         ;IRQ 2 Dummy IRQ handler
    Int     21h

    Mov     al, 0Dh
    Mov     dx, Offset SBDIRQ5         ;IRQ 5 Dummy IRQ handler
    Int     21h

    Mov     al, 0Fh
    Mov     dx, Offset SBDIRQ7         ;IRQ 7 Dummy IRQ handler
    Int     21h

    Mov     al, 72h
    Mov     dx, Offset SBDIRQ10        ;IRQ 10 Dummy IRQ handler
    Int     21h

    Mov     SBIRQ, 0FFh                ;Flag that the IRQ hasn't been called
                                       ;yet.

    Mov     dx, SBAddr                 ;Base+0Ch=Write DSP Command/Data
    Add     dl, 0Ch
@@: In      al, dx                     ;Get the write status from the SB
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If bit7 is set, the DSP isn't ready
                                       ;for a command, so continue waiting
    Mov     al, 0F2h                   ;0F2h is the command for triggering
    Out     dx, al                     ;an IRQ.

    In      al, 21h                    ;Get IRQ0-7 mask
    Mov     bl, al                     ;Save them for later restoration
    Mov     al, 01011011b              ;Enable IRQ 2, 5, and 7
    Out     21h, al                    ;Write our new mask

    In      al, 0A1h                   ;Get IRQ8-15 mask
    Mov     bh, al                     ;Save them for later restoration
    Mov     al, 11111011b              ;Enable IRQ 10
    Out     0A1h, al                   ;Write our new mask

    Xor     cx, cx                     ;Time out value (65536)

IRQWait:
    Cmp     SBIRQ, 0FFh                ;Did the IRQ handlers get called yet?
    Loope   IRQWait                    ;Loop until timeout or IRQ tiggered

SBDEnd:
    Mov     al, bl                     ;Restore IRQ0-7 mask
    Out     21h, al

    Mov     al, bh                     ;Restore IRQ8-15 mask
    Out     0A1h, al

    Lds     dx, OldIRQ                 ;Load DS:DX of old IRQ2 handler
    Mov     ax, 250Ah                  ;Set vector
    Int     21h

    Lds     dx, OldIRQ5                ;Load DS:DX of old IRQ5 handler
    Mov     ax, 250Dh                  ;Set vector
    Int     21h

    Lds     dx, OldIRQ7                ;Load DS:DX of old IRQ7 handler
    Mov     ax, 250Fh                  ;Set vector
    Int     21h

    Lds     dx, OldIRQ10               ;Load DS:DX of old IRQ10 handler
    Mov     ax, 2572h                  ;Set vector
    Int     21h

    Cmp     SBIRQ, 0FFh                ;Did the IRQ get detected?
    Je      @F                         ;If it didn't, exit
    Clc                                ;If it did, clear error flag (CF)
    Jmp     Short Exit
@@: Stc

Exit:
    Ret                                ;Return to caller

Comment                                *
    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                 IRQ Handlers for detecting the SB IRQ number
    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                                       *
SBDIRQ2:
    Push    edx
    Mov     dx, 0A02h
    Jmp     Short SBDIRQEnd

SBDIRQ5:
    Push    edx
    Mov     dx, 0D05h
    Jmp     Short SBDIRQEnd

SBDIRQ7:
    Push    edx
    Mov     dx, 0F07h
    Jmp     Short SBDIRQEnd

SBDIRQ10:
    Push    edx
    Mov     dx, 720Ah

SBDIRQEnd:
    Push    eax

    Mov     SBIRQ, dl
    Mov     SBInt, dh
    Mov     dx, SBAddr                 ;Get the SB's base I/O Address
    Add     dl, 0Eh                    ;Base+0Eh=IRQ Acknowledge Port
    In      al, dx                     ;Let the SB know that we got the IRQ

    Mov     al, 20h                    ;Send End Of Interrupt
    Cmp     SBIRQ, 8
    Jb      @F
    Out     0A0h, al                   ;to PIC2 (IRQ 10) and
@@: Out     020h, al                   ;PIC (IRQs 2, 5, 7)

    Pop     eax                        ;Restore registers
    Pop     edx
    Iret                               ;Return from interrupt

DetectSBIRQ         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DetectSBDMA
 Calling: none
 Returns: CFlag   Set if couldn't detect, clear on success
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DetectSBDMA         Proc        Near    Uses eax ebx ecx edx
    Mov     al, 5                      ;Mask off DMA Channel 1
    Out     0Ah, al
    Mov     al, 7                      ;Mask off DMA Channel 3
    Out     0Ah, al

    Mov     dx, SBAddr                 ;Get Sound Blaster's base I/O address
    Add     dl, 0Ch                    ;Base+0Ch=DSP Command/Data port
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
    Mov     al, 166
    Out     dx, al                     ;Send play rate to DSP

    Cli

    Push    es
    Mov     ah, 35h                    ;Get address of old IRQ handler
    Mov     al, SBInt
    Int     21h
    Mov     Word PTR OldIRQ, bx        ;Store address for later
    Mov     Word PTR OldIRQ+2, es
    Pop     es

    Push    ds                         ;Save DS, DOS requires us to mess it up
    Mov     dx, Offset DMADetectIRQ
    Mov     ah, 25h                    ;DOS function to change int vectors
    Mov     cx, cs                     ;Put segment of our IRQ handler in
    Mov     ds, cx                     ;DX for DOS's use.
    Int     21h                        ;Go call DOS and have the interrupt
                                       ;vectored to our handler
    Pop     ds                         ;Restore DS

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h

    Mov     dx, 0FFFEh                 ;Set all but bit 0
    Mov     cl, SBIRQ
    Rol     dx, cl                     ;Rotate mask by PAS's IRQ number
    And     ax, dx                     ;Unmask our IRQ

    Out     021h, al                   ;Write new IRQ masks
    Mov     al, ah
    Out     0A1h, al
    Sti

    Mov     SBDMA, 0

DMALoop:
    Mov     Byte PTR OldIRQ5, 0

ProgramDMA:
    Mov     al, 4                      ;Mask off DMA Channel 1 so we can
    Add     al, SBDMA
    Out     0Ah, al                    ;program it.
    Xor     al, al
    Out     0Ch, al                    ;Clear Word select FlipFlop
    Mov     al, 72
    Add     al, SBDMA
    Out     0Bh, al                    ;Set transfer mode to output (play)

    Movzx   dx, SBDMA
    Shr     dl, 1
    Xor     al, al                     ;Get LSB of address
    Out     dx, al                     ;Send LSB of address to DMA controller
    Out     dx, al                     ;Send MSB of address to DMA controller

    Inc     dx
    Xor     al, al                     ;Get LSB of transfer length
    Out     dx, al                     ;Send LSB of length to DMA controller
    Out     dx, al                     ;Send MSB of length to DMA controller

    Movzx   bx, SBDMA
    Movzx   dx, DMAPageTable[bx]
    Mov     al, 4                      ;Get the page number
    Out     dx, al                     ;Send the page number to th DMA controller

    Mov     al, SBDMA
    Out     0Ah, al                    ;Unmask channel

ProgramSB:
    Mov     dx, SBAddr
    Add     dl, 0Ch

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Mov     al, 14h
    Out     dx, al

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Xor     al, al
    Out     dx, al

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Xor     al, al
    Out     dx, al

    Xor     cx, cx
WaitLoop:
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Cmp     Byte PTR OldIRQ5, 1
    Je      Short DMAFound
    Loop    WaitLoop

    Call    ResetDSP                   ;Reset the DSP, see if it worked
    Mov     al, SBDMA
    Inc     al
    Cmp     al, 2
    Jne     Short @F
    Inc     al

@@:
    Mov     SBDMA, al
    Cmp     al, 4
    Jne     DMALoop

@@:
    Mov     SBDMA, 0FFh
    Jmp     Short Exit

DMAFound:
    Mov     bl, SBDMA

Exit:

    Mov     al, 5                      ;Set bit 2 to mask off DMA channel
    Out     0Ah, al                    ;Mask off DMA channel

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h
    Mov     dx, 1                      ;Set bit 0
    Mov     cl, SBIRQ
    Shl     dx, cl                     ;Shift over till we've hit our IRQ
    Or      ax, dx                     ;Mask the SB IRQ
    Out     021h, al                   ;Reprogram PITs
    Mov     al, ah
    Out     0A1h, al

    Mov     al, SBInt
    Push    ds                         ;Save DS, DOS requires us to mess it up
    Lds     dx, OldIRQ
    Mov     ah, 25h                    ;DOS function to change int vectors
    Int     21h                        ;Go call DOS and have the interrupt
                                       ;vectored to our handler
    Pop     ds                         ;Restore DS

    Mov     dx, SBAddr                 ;Is this another ACK?
    Add     dl, 0Eh
    In      al, dx

    Cmp     SBDMA, 0FFh
    Je      Short @F
    Clc
    Jmp     Short DExit

@@: Stc
DExit:
    Ret
DetectSBDMA         EndP

DMADetectIRQ:
    Push    eax
    Push    edx

    Mov     dx, SBAddr
    Add     dl, 0Eh
    In      al, dx

    Mov     Byte PTR OldIRQ5, 1

    Mov     al, 20h
    Cmp     SBIRQ, 8
    Jb      @F
    Out     0A0h, al
@@: Out     020h, al

    Pop     edx
    Pop     eax
    Iret
