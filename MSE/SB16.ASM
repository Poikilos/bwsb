;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;                                Sound Blaster 16
;                   BWSB Music and Sound Engine Source Code
;                   Copyright (c) 1993-97, Edward Schlunder.
;                  See COPYING.ES for redistribution details.
;
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
.Model Medium, Basic                   ;Let us use simplified calling conventions
.386P                                  ;Let us use 386 specific instructions
Stereo  EQU -1                         ;Yes, playing in stereo

sb16_mse Segment Use16                 ;Define our dynamic segment, 16bit RM
Assume  cs:sb16_mse                    ;Make sure MASM always uses CS and not DS
Org     0                              ;Dynamic Drivers originate at 0.

include ..\id.inc

;BWSB Music and Sound Engine format
MSEFormat      Struc
 Description    db      'BWSB Music and Sound Engine ',BBVer,' (SB 16) ',13,10
 Copyright      db      'Copyright (c) 1993-97, Edward Schlunder ',13,10
 MSESize        dw      ?
 Author         db      'Written by Ed Schlunder  zilym@aztec.asu.edu',26
 Identification db      IDString
 MSEVersion     db      MajorVersion, MinorVersion
 Functions      db      NumberFunc
 DeviceName     db      'Sound Blaster 16',0,0,0,0
MSEFormat      EndS

MSEHeader       MSEFormat <>           ;Setup MSE header

Include         func.inc               ;Include function vector table
include         bpmtable.inc

;ฤ Sound Blaster Configuration ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
SBAddr          dw      0FFFFh         ;Sound Blaster's Base I/O Address
SBDMA           db      0FFh           ;Sound Blaster's DMA channel
SBIRQ           db      0FFh           ;Sound Blaster IRQ Number
SBInt           db      15             ;Acutal Interrupt number for IRQ
SBTickerRate    db      0              ;DSP sample rate command

;ฤ Sound Blaster Autodetection ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
OldIRQ          dd      ?              ;Holder for old IRQ vector (and IRQ2)
;                        0    1    2    3    4    5    6    7
DMAPageTable    db      087h,083h,081h,082h,08Bh,08Bh,089h,08Ah
DMAAddrTable    db      000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh
DMAContTable    db      001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Code Area Begins Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Align           4                      ;Double word alignment for 386+
Include         funcode.inc            ;Include functions' code

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: LoadMSE                                                       0
 Calling: ah      Oversampling rate (xxKHz, Range 5..45)
          bh      Mixing buffer size
          ch      Sound device IRQ level. FFh for autodetect.
          cl      Sound device DMA channel. FFh for autodetect.
          dx      Sound device Base I/O address. FFFFh for autodetect.
 Returns: ax      Error code
          ch      IRQ level used
          cl      DMA channel used
          dx      Base I/O address used
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
LoadMSE             Proc    Uses ds
    Cmp     InstallStatus, 0           ;Are we already installed?
    Jnz     Exit

    push    eax
    push    ecx
    push    edi
    push    es

    Mov     ax, cs                     ;Reset all sound/music channels
    Mov     es, ax
    Mov     di, Offset ClockHertz      ;Load offset beginning null data
    Mov     cx, NullDataEnd-NullDataStart
    Xor     al, al                     ;Set all elements to zero!
    Cld                                ;Make sure we increment addresses
    Rep     Stosb

    pop     es
    pop     edi
    pop     ecx
    pop     eax

    Xor     bl, bl
    Mov     cs:BufferLen, bx           ;Save mixing buffer size
    Mov     byte ptr OverRate, ah      ;Save oversampling rate

;ฤฤฤ Sound Blaster Base I/O Address
    Mov     SBAddr, dx                 ;Save the Sound Blaster's Base I/O address
    Cmp     dx, 0FFFFh                 ;Do we need to autodetect the SB's Addr?
    Jne     Short @F                   ;Skip if autodetect not required
    Call    DetectSBAddr               ;Go detect the SB's base I/O address
    Mov     ax, 1                      ;Base I/O Address detection error
    Jc      Exit

@@: Call    ResetDSP                   ;Make sure SBAddr is correct
    Mov     ax, 6                      ;Sound Device doesn't respond error
    Jc      Exit                       ;Exit if DSP Reset failed

;ฤฤฤ Sound Blaster IRQ Level
    Mov     SBIRQ, ch                  ;Save the SB's IRQ level
    Cmp     ch, 0FFh                   ;Do we need to autodetect IRQ?
    Jne     Short @F                   ;Skip if autodetection isn't required
    Call    DetectSBIRQ                ;Go detect the SB's IRQ
    Mov     ax, 2                      ;Sound Device IRQ level detection failure
    Jc      Exit                       ;If IRQ detection failed, exit routine

@@: Mov     ch, SBIRQ                  ;Retrieve the SB's IRQ
    Cmp     ch, 10                     ;Is the IRQ 10?
    Jne     Short @F                   ;If not 10, just do the regular IRQ Int calc
    Mov     ch, 72h                    ;If IRQ=10 then Int=72h
    Jmp     Short SetSBInt             ;Go save the SB's IRQ Interrupt number

@@: Add     ch, 8                      ;SB IRQ+8= SB IRQ Interrupt Number
SetSBInt:
    Mov     SBInt, ch                  ;Save the SB's IRQ Interrupt Number

;ฤฤฤ Sound Blaster DMA Channel
    Mov     SBDMA, cl                  ;Save the Sound Blaster's DMA Channel
    Cmp     cl, 0FFh                   ;Do we need to autodetect the DMA Chan?
    Jne     Short @F                   ;Skip autodetect if not required
    Call    DetectSBDMA                ;Go detect the SB's DMA Channel
    Mov     ax, 3                      ;DMA Channel detect error
    Jc      Exit                       ;If autodetection error, exit routine

;ฤฤฤ Sound Device Checkup
@@: Call    ResetDSP                   ;Make sure SBAddr is correct
    Mov     ax, 6                      ;Sound Device doesn't respond error
    Jc      Exit                       ;Exit if DSP Reset failed

;ฤฤฤฤ Oversampling Rate
    Mov     ah, Byte PTR OverRate
    Cmp     ah, 45
    Jbe     @F
    Mov     ah, 45
@@: Cmp     ah, 5
    Jae     @F
    Mov     ah, 5
@@: Call    SetOverRate                ;Go set up timing variables

;ฤฤฤ Mixing Buffer
    Mov     bx, Word PTR cs:BufferLen
    Shr     bx, 4                      ;Divide by 16->Paragraphs
    Call    AllocDMABuffers            ;Go allocate mixing buffers
    Mov     ax, 9                      ;Set error- No memory for mixing buffer
    Jc      Short Exit

    Mov     Tempo, 6
    Mov     BPM, 125

    Mov     ax, BPMTable+125*2
    Mov     FrameTicks, ax
    Mov     FrameCounter, ax
    Mov     TempoCounter, 0

    Mov     ax, cs
    Mov     cl, 34
    Xor     bx, bx
CalcSegLoop:
    Mov     cs:[SCSegTable+bx], ax
    Add     ax, 8
    Add     bx, 2
    Dec     cl
    Jnz     CalcSegLoop

    Mov     InstallStatus, 1           ;Set flag that we are installed
    Xor     ax, ax                     ;Clear error flag
Exit:
    Mov     cl, SBDMA                  ;Return the SB DMA channel detected
    Mov     ch, SBIRQ                  ;Return the SB IRQ number detected
    Mov     dx, SBAddr                 ;Return the SB's Base I/O detected
    Ret
LoadMSE             EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: FreeMSE                                                       1
 Calling: none
 Returns: none
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
FreeMSE             Proc        Uses es
    Cmp     InstallStatus, 0           ;Are we already uninstalled?
    Jz      Short Exit                 ;Skip uninstallation if uninstalled

    Cmp     OutputStatus, 0            ;Is output enabled?
    Jz      @F                         ;Skip if not enabled
    Mov     OutputStatus, 0            ;Set flag that output is disabled
    Call    UnInstallSB                ;Deactivate the sound device

@@: Call    DeallocModule              ;Dealloc module memory
    Mov     es, BufferSegment          ;Get segment of mixing buffer
    Mov     ah, 49h                    ;Release memory of mixing buffer
    Int     21h

    Mov     InstallStatus, 0           ;Set flag that we are not installed
Exit:
    Ret                                ;Return to caller
FreeMSE             EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: StartOutput                                                   2
 Calling: al      Number of output channels (1..32)
          bh      Amplification value (-9..9)
 Returns: bx      Oversampling rate actually use
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
StartOutput         Proc        Uses es di
    Cmp     OutputStatus, 0            ;Is output already enabled?
    Jnz     Exit

    Push    bx                         ;Save amplification value
    Cmp     al, 32                     ;Make sure number of channels isn't >32
    Jbe     Short @F
    Mov     al, 32                     ;Put to max if above 32
@@: Mov     NumChannels, al

    Movzx   cx, NumChannels            ;Get Maximum number of channels
    Shl     cx, MCShift                ;Multiply by MCSize for data structure
    Mov     Word PTR cs:MixChanOffset, cx ;Save upper struc offset
    Shr     cx, MCShift

    Movzx   bx, cl
    Mov     cl, cs:[ChanDivTable+bx-1]
    Pop     dx                         ;Get amplification value in BH
    Sub     cl, dh                     ;Perform the amplification
    Ja      @F
    Mov     cl, 1
@@: Mov     bx, 16640

CalcVolLoop:
    Dec     bx
    Mov     al, bl
    Sub     al, 128
    Imul    bh
    Shr     ax, 6
    Cbw
    IDiv    cl                         ;Make volume table do division*channels
    Mov     cs:[VolumeTable+bx], al
    Cmp     bx, 0
    Jnz     CalcVolLoop

    Mov     ax, BufferSegment          ;Get segment address of mixing buffer
    Mov     es, ax                     ;Set it up...
    Xor     di, di                     ;Offset always starts at zero
    Mov     cx, Word PTR cs:BufferLen  ;Load mixing buffer length
    Mov     al, 7Fh                    ;Clear mixing buffer to silence
    Cld                                ;Make sure we increment addresses
    Rep     Stosb

    Call    SBOverRate                 ;Kick the SB into right playing speed
    Call    InstallSB                  ;Install Sound Blaster output routines
    Mov     OutputStatus, 1            ;Flag that output is enabled

Exit:
    Mov     bx, OverRate               ;Return actual oversampling rate used
    Ret
StartOutput         EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: StopOutput
 Calling: None
 Returns: None
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
StopOutput          Proc        Uses es di
    Cmp     OutputStatus, 0            ;Is output even enabled?
    Jz      Exit

    Call    UnInstallSB                ;Deactivate the sound device
    Mov     OutputStatus, 0            ;Set the output disabled flag

    Mov     ax, cs                     ;Reset all sound/music channels
    Mov     es, ax
    Mov     di, Offset SndChans        ;Load offset of channel status table
    Mov     cx, 32*MCSize              ;32 Channels * MCSize Bytes Per Channel
    Xor     al, al                     ;Set all elements to zero!
    Cld                                ;Make sure we increment addresses
    Rep     Stosb

Exit:
    Ret
StopOutput          EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: ax        Left scope value
          cx        Right scope value (equal to ax if mono output device)
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
GetMainScope        Proc        Uses esi ds es
    Out     0Ch, al                    ;Clear DMA word flip flop

    Movzx   bx, SBDMA
    Movzx   dx, DMAPageTable[bx]
    In      al, dx                     ;Get the DMA page number
    Movzx   cx, al                     ;CX=DMA Page

    Movzx   dx, DMAAddrTable[bx]
    In      al, dx
    Mov     bl, al
    In      al, dx
    Mov     bh, al                     ;BX=DMA Address

    Shl     cx, 12                     ;DMA Page * 4096
    Mov     ax, bx
    Shr     ax, 4
    Add     cx, ax

    And     bx, 0Fh

    Mov     es, cx
    Xor     al, al
    Xor     cl, cl

    And     bl, 11111110b              ;Start on even address for Left
    Mov     ah, Byte PTR es:[bx]
    Mov     ch, Byte PTR es:[bx+1]     ;Odd address for Right
    Ret
GetMainScope        EndP

Comment                                *
  ÛฐÛอออออออออออออออออออออออออออออออออ๚๙๚อออออออออออออออออออออออออออออออออÛฐÛ

  ๚þ๚                     Internal Routines Begin Here                    ๚þ๚

  ÛฐÛอออออออออออออออออออออออออออออออออ๚๙๚อออออออออออออออออออออออออออออออออÛฐÛ
                                       *
Include mix-sp.inc                     ;Stereo Parallel mixing routine
Include mus-p.inc                      ;Music processing routines
Include mus-efx.inc                    ;Music effect processing routines

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Various Sound System Installation Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Include allocdma.inc                   ;DMA buffer allocation routines
Include sb16rate.inc

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Sound Blaster DMA Output Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
InstallSB           Proc    Near    Uses eax ebx ecx edx
    Mov     al, 4
    Add     al, SBDMA
    Out     0Ah, al                    ;Mask off DMA channel

    Call    SetupDMA                   ;Setup all the DMA code

    Push    es                         ;Store old IRQ handler vector
    Mov     al, SBInt
    Mov     ah, 35h
    Int     21h
    Mov     Word PTR OldIRQ, bx
    Mov     Word PTR OldIRQ+2, es
    Pop     es

    Mov     bx, BufferSegment          ;Get the sound's segment address
    Mov     cx, BufferLen              ;Get the sound's length
    Mov     dl, bh
    Shr     dl, 4                      ;Isolate upper 4 bits of segment for page
    Shl     bx, 4                      ;Lower 12 bits of segment are DMA address
    Dec     cx                         ;One less because of DMA's address way

DMAMaskChan     EQU $+1
    Mov     al, 0FFh                   ;Mask off DMA channel so we can
    Out     0Ah, al                    ;program it.
    Xor     al, al
    Out     0Ch, al                    ;Clear Word select FlipFlop
TransMode   EQU $+1
    Mov     al, 0FFh
    Out     0Bh, al                    ;Set transfer mode (play/rec)

    Mov     al, bl                     ;Get LSB of address
DMAAddr1    EQU $+1
    Out     0FFh, al                   ;Send LSB of address to DMA controller
    Mov     al, bh                     ;Get MSB of address
DMAAddr2    EQU $+1
    Out     0FFh, al                   ;Send MSB of address to DMA controller
    Mov     al, cl                     ;Get LSB of transfer length
DMALeng1    EQU $+1
    Out     0FFh, al                   ;Send LSB of length to DMA controller
    Mov     al, ch                     ;Get MSB of transfer length
DMALeng2    EQU $+1
    Out     0FFh, al                   ;Send MSB of length to DMA controller

    Mov     al, dl                     ;Get the page number
DMAPage1    EQU $+1
    Out     0FFh, al                   ;Send the page number to th DMA controller

DMAUnMask   EQU $+1
    Mov     al, 0FFh
    Out     0Ah, al                    ;Unmask channel 1

    Inc     cx
    Shr     cx, 1
    Dec     cx

    Mov     Word PTR cs:[MixOffset], 0 ;Clear mixing buffer offset
    Push    ds                         ;Save DS, DOS requires us to mess it up
    Mov     dx, Offset DMAIRQHS
    Mov     ah, 25h                    ;DOS function to change int vectors
    Mov     al, SBInt
    Mov     bx, cs                     ;Put segment of our DMA IRQ handler in
    Mov     ds, bx                     ;DX for DOS's use.
    Int     21h                        ;Go call DOS and have the interrupt
                                       ;vectored to our handler
    Pop     ds                         ;Restore DS

    Mov     dx, SBAddr
    Add     dx, 0Ch

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Mov     al, 0C6h                   ;Send 'Set Transfer Length' command
    Out     dx, al

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Mov     al, 20h                    ;Set stereo mode
    Out     dx, al

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Mov     al, cl                     ;Send LSB of transfer length
    Out     dx, al

@@: In      al, dx                     ;Get DSP write status
    Or      al, al                     ;Check bit 7
    Js      @B                         ;If set, DSP not ready for data
    Mov     al, ch                     ;Send MSB of transfer length
    Out     dx, al

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h

    Mov     dx, 0FFFEh                 ;Set all but bit 0
    Mov     cl, SBIRQ
    Rol     dx, cl                     ;Rotate mask by SB's IRQ number
    And     ax, dx                     ;Unmask our IRQ

    Out     021h, al                   ;Write new IRQ masks
    Mov     al, ah
    Out     0A1h, al

Exit:
    Ret
InstallSB           EndP

UnInstallSB         Proc    Near    Uses eax ebx ecx edx
    Call    ResetDSP                   ;Reset the Sound Blaster

    Mov     al, 4
    Add     al, SBDMA
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

    Mov     al, SBInt                  ;Restore original IRQ handler

    Push    ds
    Lds     dx, OldIRQ
    Mov     ah, 25h
    Int     21h
    Pop     ds

    Ret
UnInstallSB         EndP

SetupDMA            Proc    Near
    Mov     ax, SBAddr
    Add     al, 0Eh
    Mov     Word PTR cs:DIAck, ax

    Mov     al, 4
    Add     al, SBDMA
    Mov     Byte PTR cs:DMAMaskChan, al

    Mov     al, 01011000b              ;Autoinit mode, Forward Buffer
    Add     al, SBDMA
    Mov     Byte PTR cs:TransMode, al

    Mov     al, SBDMA
    Shl     al, 1
    Mov     Byte PTR cs:DMAAddr1, al
    Mov     Byte PTR cs:DMAAddr2, al
    Inc     al
    Mov     Byte PTR cs:DMALeng1, al
    Mov     Byte PTR cs:DMALeng2, al

    Movzx   bx, SBDMA
    Mov     al, DMAPageTable[bx]
    Mov     Byte PTR cs:DMAPage1, al

    Mov     al, SBDMA
    Mov     Byte PTR cs:DMAUnMask, al

    Mov     ax, Word PTR BufferLen
    Inc     ax
    Shr     ax, 2                      ;Divide into two buffers, stereo mode
    Dec     ax
    Mov     Word PTR cs:BufLenDMA, ax

    Ret
SetupDMA            EndP

    Align   4                          ;Double word alignment for 386+
DMAIRQHS            Proc    Far        ;High Speed DMA IRQ Handler
    Push    eax                        ;Save all the registers we're gonna
    Push    edx                        ;use right now..

    Cmp     PlayNeedsMix, 0
    Jnz     Exit

DIAck   EQU $+1
    Mov     dx, 0FFFFh                 ;2-8 Bit IRQ Acknowledgment port
    In      al, dx                     ;Acknowledge IRQ

    Mov     PlayNeedsMix, 1            ;Set mixing flag
    Cmp     AutoMixFlag, 0             ;Do we do mixing right now?
    Jz      Exit                       ;Nah..

BufLenDMA EQU $+1
    Mov     dx, 0FFFFh                 ;Get length of DMA buffer
    Inc     dx

    Push    esi                        ;Gonna need to save some more
    Push    edi                        ;registers for the mixing routines
    Push    bp
    Push    es
    Push    ds
    Push    gs
    Push    ebx
    Push    ecx
    Call    MixInterrupt               ;Go mix the next buffer
    Pop     ecx                        ;Restore all those mixing registers
    Pop     ebx
    Pop     gs
    Pop     ds
    Pop     es
    Pop     bp
    Pop     edi
    Pop     esi

Exit:
    Mov     al, 20h                    ;Send EOI code
    Cmp     SBIRQ, 8
    Jb      @F
    Out     0A0h, al
@@: Out     020h, al

    Pop     edx                        ;Restore those nifty registers
    Pop     eax
    Iret                               ;Return to regularly scheduled program
DMAIRQHS            EndP

Include sbdetect.inc                   ;Sound Blaster autodetection routines
Include sbmisc.inc                     ;Other miscellaneous SB routines

Include         msedata.inc            ;Include MSE data area

;ฤฤฤฤฤฤฤฤฤฤฤฤฤ Null Data Should be Placed Here ฤฤฤฤฤฤฤฤฤฤฤฤฤ
;(all ending nulls are removed from the MSE and saves disk space)

NullDataEnd     EQU     $
sb16_mse EndS                          ;End of Dynamic segment
End
