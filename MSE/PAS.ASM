;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;                              Pro AudioSpectrum
;                   BWSB Music and Sound Engine Source Code
;                   Copyright (c) 1993-95, Edward Schlunder. 
;                  See COPYING.ES for redistribution details.
;
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
.Model Medium, Basic                   ;Let us use simplified calling conventions
.386P                                  ;Let us use 386 specific instructions
Stereo  EQU -1                         ;Yes, playing in stereo

pas_mse Segment Use16                  ;Define our dynamic segment, 16bit RM
Assume  cs:pas_mse                     ;Make sure assembler uses CS and not DS
Org     0                              ;Dynamic Drivers originate at 0.

include ..\id.inc

;BWSB Music and Sound Engine format
MSEFormat      Struc
 Description    db      'BWSB Music and Sound Engine ',BBVer,' (PAS)   ',13,10
 Copyright      db      'Copyright (c) 1993-97, Edward Schlunder ',13,10
 Author         db      'Written by Ed Schlunder  zilym@aztec.asu.edu',26
 MSESize        dw      ?
 Identification db      IDString
 MSEVersion     db      MajorVersion, MinorVersion
 Functions      db      NumberFunc
 DeviceName     db      'Pro AudioSpectrum', 0, 0, 0
MSEFormat      EndS

MSEHeader       MSEFormat <>           ;Setup MSE header

Include         func.inc               ;Include function vector table
include         bpmtable.inc

;ฤ Pro AudioSpectrum State Table ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
PASState       Struc
  sysspkrtmr    db      0              ;( 42 ) System Speaker Timer Address
  systmrctlr    db      0              ;( 43 ) System Timer Control
  sysspkrreg    db      0              ;( 61 ) System Speaker Register
  joystick      db      0              ;( 201) Joystick Register
  lfmaddr       db      0              ;( 388) Left  FM Synth Address
  lfmdata       db      0              ;( 389) Left  FM Synth Data
  rfmaddr       db      0              ;( 38A) Right FM Synth Address
  rfmdata       db      0              ;( 38B) Right FM Synth Data
  dfmaddr       db      0              ;( 788) Dual  FM Synth Address Register
  dfmdata       db      0              ;( 789) Dual  FM Synth Data Register
                db      0              ;filler
  paudiomixr    db      0              ;( 78B) Paralllel Audio Mixer Control
  audiomixr     db      0              ;( B88) Audio Mixer Control
  intrctlrst    db      0              ;( B89) Interrupt Status
  audiofilt     db      0              ;( B8A) Audio Filter Control
  intrctlr      db      0              ;( B8B) Interrupt Control
  pcmdata       db      0              ;( F88) PCM Data I/O Register
                db      0              ;filler
  crosschannel  db      0              ;( F8A) Cross Channel
                db      0              ;filler
  samplerate    dw      0              ;(1388) Sample Rate Timer
  samplecnt     dw      0              ;(1389) Sample Count Register
  spkrtmr       dw      0              ;(138A) Shadow Speaker Timer Count
  tmrctlr       db      0              ;(138B) Shadow Speaker Timer Control
  mdirqvect     db      0              ;(1788) MIDI IRQ Vector Register
  mdsysctlr     db      0              ;(1789) MIDI System Control Register
  mdsysstat     db      0              ;(178A) MIDI IRQ Status Register
  mdirqclr      db      0              ;(178B) MIDI IRQ Clear Register
  mdgroup1      db      0              ;(1B88) MIDI Group #1 Register
  mdgroup2      db      0              ;(1B89) MIDI Group #2 Register
  mdgroup3      db      0              ;(1B8A) MIDI Group #3 Register
  mdgroup4      db      0              ;(1B8B) MIDI Group #4 Register
PASState       Ends

PASShadow       dd      0              ;Pointer to MVSOUND.SYS's PAS state table

;ฤ Pro AudioSpectrum Configuration ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
PASAddr         dw      0FFFFh         ;Pro AudioSpectrum's Base I/O Address XOR
PASDMA          db      0FFh           ;Pro AudioSpectrum's DMA channel
PASIRQ          db      0FFh           ;Pro AudioSpectrum's IRQ Number
PASInt          db      15             ;Actual Interrupt number for IRQ
PASTickerRate   dw      0              ;Timer sample rate (1193181.667\Overrate)

;ฤ IRQ/DMA Data Tables ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
OldIRQ          dd      ?              ;Holder for old IRQ vector

;DMA Channels:           0    1    2    3    4    5    6    7
DMAPageTable    db      087h,083h,081h,082h,08Bh,08Bh,089h,08Ah
DMAAddrTable    db      000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh
DMAContTable    db      001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh

DMAMaskTable    db      0Ah,0D4h
DMAModeTable    db      0Bh,0D6h
DMAFlpFTable    db      0Ch,0D8h

DMASingleMask   db      0D4h           ;0Ah for DMA 0-3, D4h for DMA 4-7
DMATransMode    db      0Bh            ;DMA Transfer Mode
DMAFlipFlop     db      0Ch            ;DMA Read/Write Flip Flop

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
          bh      Mixing buffer size (in multiples of 256)
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

;ฤฤฤ Pro AudioSpectrum Base I/O Address
    Mov     ax, dx                     ;Make an extra copy for translation
    Xor     ax, 388h                   ;Translate code
    Mov     PASAddr, ax                ;Save the Pro AudioSpectrum's Base I/O
    Cmp     dx, 0FFFFh                 ;Do we need to autodetect the PAS's Addr?
    Jne     Short @F                   ;Skip if autodetect not required
    Call    DetectPASAddr              ;Go detect the PAS's base I/O address
    Mov     ax, 1                      ;Base I/O Address detection error
    Jc      Exit

@@: Push    cx
    Mov     ax, 0BC00h                 ;MVSOUND.SYS - Installation Check
    Mov     bx, '??'                   ;Setup expected registers for MVSOUND
    Xor     cx, cx
    Xor     dx, dx
    Int     2Fh                        ;Go call the driver
    Xor     bx, cx                     ;Process return codes
    Xor     bx, dx
    Pop     cx
    Cmp     bx, 'MV'                   ;Did we get expected return code?
    Je      @F
    Mov     ax, 0Ch                    ;MVSOUND.SYS not loaded error
    Jmp     Exit                       ;Exit because of MVSOUND.SYS error

;ฤฤฤ Pro AudioSpectrum IRQ Level
@@: Mov     PASIRQ, ch                 ;Save the PAS's IRQ level
    Cmp     ch, 0FFh                   ;Do we need to autodetect IRQ?
    Jne     Short @F                   ;Skip if autodetection isn't required
    Call    DetectPASIRQ               ;Go detect the PAS's IRQ
    Mov     ax, 2                      ;Sound Device IRQ level detection failure
    Jc      Exit                       ;If IRQ detection failed, exit routine

@@: Mov     ch, PASIRQ                 ;Retrieve the PAS's IRQ
    Cmp     ch, 8                      ;Is IRQ using PIC2?
    Jb      Short @F                   ;If not 10, just do the regular IRQ Int calc
    Add     ch, 70h - 8                ;IRQ + 70h = PIC2 Interrupt Number
    Jmp     Short SetInt               ;Go save the IRQ Interrupt number

@@: Add     ch, 8                      ;IRQ + 8 = PIC1 Interrupt Number
SetInt:
    Mov     PASInt, ch                 ;Save the PAS's IRQ Interrupt Number

;ฤฤฤ Pro AudioSpectrum DMA Channel
    Mov     PASDMA, cl                 ;Save the Pro AudioSpectrum's DMA Channel
    Cmp     cl, 0FFh                   ;Do we need to autodetect the DMA Chan?
    Jne     Short @F                   ;Skip autodetect if not required
    Call    DetectPASDMA               ;Go detect the PAS's DMA Channel
    Mov     ax, 3                      ;DMA Channel detect error
    Jc      Exit                       ;If autodetection error, exit routine

@@: And     PASDMA, 00000111b
    Cmp     PASDMA, 4                  ;Is DMA using DMA Controller 1 or 2?
    Jb      DMAC1
DMAC2:
    Mov     al, DMAMaskTable[1]
    Mov     DMASingleMask, al
    Mov     al, DMAFlpFTable[1]
    Mov     DMAFlipFlop, al
    Mov     al, DMAModeTable[1]
    Mov     DMATransMode, al

    Jmp     Short SDCheck

DMAC1:
    Mov     al, DMAMaskTable[0]
    Mov     DMASingleMask, al
    Mov     al, DMAFlpFTable[0]
    Mov     DMAFlipFlop, al
    Mov     al, DMAModeTable[0]
    Mov     DMATransMode, al

;ฤฤฤ Sound Device Checkup
SDCheck:
    Call    GetPASVersion              ;Make sure PASAddr is correct
    Cmp     al, 0FFh                   ;Is there a working PAS installed?
    Jne     @F
    Mov     ax, 6                      ;Sound Device doesn't respond error
    Jmp     Exit                       ;Exit if get version failed

;ฤฤฤฤ Oversampling Rate
@@: Mov     ah, Byte PTR OverRate      ;Get the desired oversampling rate
    Cmp     ah, 45                     ;Is it too high?
    Jbe     @F
    Mov     ah, 45                     ;Set back to maximum
@@: Cmp     ah, 5                      ;Is it too low?
    Jae     @F
    Mov     ah, 5                      ;Set forward to minimum
@@: Call    SetOverRate                ;Go set up timing variables

;ฤฤฤ Mixing Buffer
    Mov     bx, Word PTR cs:BufferLen
    Shr     bx, 4                      ;Divide by 16->Paragraphs
    Call    AllocDMABuffers            ;Go allocate mixing buffers
    Mov     ax, 9                      ;Set error- No memory for mixing buffer
    Jc      Short Exit

    Call    InitPAS                    ;Initialize the Pro AudioSpectrum
    Mov     ax, 6                      ;Error - Sound card does not respond
    Jc      Exit                       ;Exit if error on PAS initialization

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
    Mov     cl, PASDMA                 ;Return the PAS DMA channel detected
    Mov     ch, PASIRQ                 ;Return the PAS IRQ number detected
    Mov     dx, 388h
    Xor     dx, PASAddr                ;Return the PAS Base I/O detected
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
    Call    UnInstallPAS               ;Deactivate the sound device

@@: Call    DeallocModule              ;Dealloc module memory (if any)
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
 Returns: bx      Oversampling rate actually being used
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
    Mov     word ptr cs:MixChanOffset, cx ;Save upper struc offset
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

    Call    PASOverRate                ;Kick the PAS into right playing speed
    Call    InstallPAS                 ;Install PAS output routines
    Mov     OutputStatus, 1            ;Flag that output is enabled

Exit:
    Mov     bx, OverRate               ;Return actual oversampling rate used
    Ret
StartOutput         EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: StopOutput                                                    3
 Calling: None
 Returns: None
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
StopOutput          Proc        Uses es di
    Cmp     OutputStatus, 0            ;Is output even enabled?
    Jz      Exit

    Call    UnInstallPAS               ;Deactivate the sound device

    Mov     ax, cs                     ;Reset all sound/music channels
    Mov     es, ax
    Mov     di, Offset SndChans        ;Load offset of channel status table
    Mov     cx, 32*MCSize              ;32 Channels * MCSize Bytes Per Channel
    Xor     al, al                     ;Set all elements to zero!
    Cld                                ;Make sure we increment addresses
    Rep     Stosb

    Mov     OutputStatus, 0            ;Set the output disabled flag
Exit:
    Ret
StopOutput          EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: ax        Left scope value
          cx        Right scope value (equal to ax if mono output device)
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
GetMainScope        Proc        Uses si ds es
    Movzx   dx, DMAFlipFlop
    Out     dx, al                     ;Clear DMA word flip flop

    Movzx   bx, PASDMA
    Movzx   dx, DMAPageTable[bx]
    In      al, dx                     ;Get the DMA page number
    Movzx   cx, al                     ;CX=DMA Page

    Movzx   dx, DMAAddrTable[bx]
    In      al, dx
    Mov     bl, al
    In      al, dx
    Mov     bh, al                     ;BX=DMA Address

    cmp     PASDMA, 4                  ;Are we using a 16bit DMA channel?
    jb      @F
    shl     bx, 1                      ;16bit DMA - multiply addresses by 2
    rcl     cx, 1
@@:
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
Include pasrate.inc                    ;Pro AudioSpectrum sampling calculation

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Pro AudioSpectrum DMA Output Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
InstallPAS          Proc    Near    Uses eax ebx ecx edx es di
    Call    SetupDMA                   ;Setup all the DMA code

    Mov     al, PASInt                 ;Get the original IRQ vector
    Mov     ah, 35h                    ;Call DOS to get it
    Int     21h
    Mov     Word PTR OldIRQ, bx        ;Save old IRQ vector
    Mov     Word PTR OldIRQ+2, es

    Les     di, PASShadow              ;ES:DI->MVSOUND.SYS state table pointer

    Mov     bx, BufferSegment          ;Get buffer segment address
    Mov     cx, BufferLen              ;Get buffer length
    Mov     ah, bh
    Shr     ah, 4                      ;Isolate upper 4 bits of segment for page
    Shl     bx, 4                      ;Lower 12 bits of segment are DMA address
    Dec     cx                         ;One less because of DMA's address way

DMAMaskChan     EQU $+1
    Mov     al, 0FFh                   ;Mask off this DMA channel
    Movzx   dx, DMASingleMask          ;Get address of DMA controller
    Out     dx, al

    Movzx   dx, DMAFlipFlop
    Out     dx, al                     ;Clear word select FlipFlop

TransMode   EQU $+1
    Mov     al, 0FFh
    Movzx   dx, DMATransMode
    Out     dx, al                     ;Set transfer mode (play/rec)

    Mov     al, ah                     ;Get the page number
DMAPage1    EQU $+1
    Out     0FFh, al                   ;Send the page number to th DMA controller

    Cmp     PASDMA, 4                  ;Are we using a 16bit DMA channel?
    Jb      @F
    Shr     al, 1                      ;16bit DMA - Divide addresses and
    Rcr     bx, 1                      ;transfer lengths by 2 (2*8=1*16)
    Shr     cx, 1

@@: Mov     al, bl                     ;Get LSB of address
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

    Inc     cx
    Shr     cx, 1                      ;Transfer length \ 2=Half buffer

    Mov     Word PTR cs:[MixOffset], 0 ;Clear mixing buffer offset
    Push    ds                         ;Save DS, DOS requires us to mess it up
    Mov     dx, Offset DMAIRQ
    Mov     ah, 25h                    ;DOS function to change int vectors
    Mov     al, PASInt
    Mov     bx, cs                     ;Put segment of our DMA IRQ handler in
    Mov     ds, bx                     ;DX for DOS's use.
    Int     21h                        ;Go call DOS and have the interrupt
                                       ;vectored to our handler
    Pop     ds                         ;Restore DS

    Mov     al, 01110100b              ;74h - Timer 1, Rate Generator
    Mov     dx, 138Bh                  ;138Bh - PAS Timer Control Register
    Xor     dx, PASAddr

    Cli

    Out     dx, al
    Mov     es:[di.tmrctlr], al        ;Save new Timer Control state

    Mov     dx, 1389h                  ;1389h - Sample Count
    Xor     dx, PASAddr
    Mov     es:[di.samplecnt], cx      ;Save new sample count in state table

    Mov     al, cl                     ;Send LSB of sample count to PAS
    Out     dx, al
    Jmp     $+2                        ;Let PAS have some rest
    Mov     al, ch                     ;Send MSB of sample count to PAS
    Out     dx, al

    Mov     dx, 0B89h                  ;B89h - Interrupt Control Status
    Xor     dx, PASAddr
    Out     dx, al                     ;Flush any PAS IRQs pending

    Mov     dx, 0B8Bh                  ;B8Bh - Interrupt Control Register
    Xor     dx, PASAddr
    In      al, dx                     ;Get current IRQ masks
    Or      al, 00001000b              ;IRQ on Sample Buffer end
    Out     dx, al                     ;Send new IRQ masks to PAS
    Mov     es:[di.intrctlr], al       ;Save it in MVSOUND.SYS state table

    Mov     dx, 0F8Ah                  ;F8Ah - Cross Channel Register
    Xor     dx, PASAddr

    Mov     al, 11010000b              ;PCM Enable, DRQ Enable, Stereo, DAC
    Mov     ah, 0Fh
    And     ah, es:[di.crosschannel]   ;Get all current except PCM DRQ MONO DAC
    Or      al, ah

    Xor     al, 01000000b              ;Disable PCM bit
    Out     dx, al
    Xor     al, 01000000b              ;Enable PCM bit
    Out     dx, al

    Mov     es:[di.crosschannel], al   ;Save new Cross Channel state

    Mov     al, PASDMA
    And     al, 00000011b
    Movzx   dx, DMASingleMask          ;Get address of DMA controller
    Out     dx, al                     ;Unmask PAS's DMA channel

    Mov     dx, 0B8Ah                  ;B8Ah - Audio Filter Control
    Xor     dx, PASAddr
    Mov     al, es:[di.audiofilt]      ;Get current Audio Filter
    Or      al, 11000000b              ;Enable Sample Rate and Count IRQs
    Out     dx, al
    Mov     es:[di.audiofilt], al

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h

    Mov     dx, 0FFFEh                 ;Set all but bit 0
    Mov     cl, PASIRQ
    Rol     dx, cl                     ;Rotate mask by PAS's IRQ number
    And     ax, dx                     ;Unmask our IRQ

    Out     021h, al                   ;Write new IRQ masks
    Mov     al, ah
    Out     0A1h, al
    Sti

Exit:
    Ret
InstallPAS          EndP

UnInstallPAS        Proc    Near    Uses eax ebx ecx edx
    Call    InitPAS                    ;Initialize PAS to Power on State
    Mov     dx, 0B89h                  ;B89h - Interrupt Control Status
    Xor     dx, PASAddr
    Out     dx, al                     ;Flush any left over IRQs

    Mov     al, PASDMA
    Or      al, 0100b
    Movzx   dx, DMASingleMask
    Out     dx, al                     ;Mask off DMA channel

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h
    Mov     dx, 1                      ;Set bit 0
    Mov     cl, PASIRQ
    Shl     dx, cl                     ;Shift over till we've hit our IRQ
    Or      ax, dx                     ;Mask the PAS IRQ
    Out     021h, al                   ;Reprogram PITs
    Mov     al, ah
    Out     0A1h, al

    Mov     al, PASInt                 ;Restore original IRQ handler
    Push    ds
    Lds     dx, OldIRQ
    Mov     ah, 25h
    Int     21h
    Pop     ds

    Ret
UnInstallPAS        EndP

SetupDMA            Proc    Near
    Mov     ax, 0B89h                  ;B89h - Interrupt Control Status
    Xor     ax, PASAddr
    Mov     Word PTR cs:DIAck, ax      ;Save acknowledgement address

    Mov     al, PASDMA
    Or      al, 0100b
    Mov     Byte PTR cs:DMAMaskChan, al

    Mov     al, PASDMA
    And     al, 00000011b
    Or      al, 01011000b              ;Autoinit mode, Forwards Buffer
    Mov     Byte PTR cs:TransMode, al

    Movzx   bx, PASDMA
    Mov     al, DMAAddrTable[bx]
    Mov     Byte PTR cs:DMAAddr1, al
    Mov     Byte PTR cs:DMAAddr2, al

    Mov     al, DMAContTable[bx]
    Mov     Byte PTR cs:DMALeng1, al
    Mov     Byte PTR cs:DMALeng2, al

    Mov     al, DMAPageTable[bx]
    Mov     Byte PTR cs:DMAPage1, al

    Mov     ax, Word PTR BufferLen
    Inc     ax
    Shr     ax, 2                      ;Divide into two buffers, stereo mode
    Dec     ax
    Mov     Word PTR cs:BufLenDMA, ax

    Ret
SetupDMA            EndP

    Align   4                          ;Double word alignment for 386+
DMAIRQ              Proc    Far        ;PAS DMA IRQ Handler
    Mov     DWord PTR cs:EAXSave, eax  ;Save all the registers we're gonna
    Mov     DWord PTR cs:EDXSave, edx  ;use right now..

    Cmp     PlayNeedsMix, 0
    Jnz     Exit

    Mov     PlayNeedsMix, 1            ;Set mixing flag

DIAck   EQU $+1
    Mov     dx, 0FFFFh                 ;Interrupt Control Status
    Out     dx, al                     ;Acknowledge PAS's IRQ

    Cmp     AutoMixFlag, 0             ;Do we do mixing right now?
    Jz      Exit                       ;Nah..

BufLenDMA EQU $+1
    Mov     dx, 0FFFFh                 ;Get length of DMA buffer
    Inc     dx

    Mov     Word PTR cs:esSave, es
    Mov     Word PTR cs:dsSave, ds
    Mov     Word PTR cs:gsSave, gs
    Mov     Dword PTR cs:esiSave, esi  ;Gonna need to save some more
    Mov     Dword PTR cs:ediSave, edi  ;registers for the mixing routines
    Mov     Dword PTR cs:ebpSave, ebp
    Mov     Dword PTR cs:ebxSave, ebx
    Mov     Dword PTR cs:ecxSave, ecx
    Call    MixInterrupt               ;Go mix the next buffer
ecxSave EQU $+2
    Mov     ecx, 23242526h             ;Restore all those mixing registers
ebxSave EQU $+2
    Mov     ebx, 23242526h
ebpSave EQU $+2
    Mov     ebp, 23242526h
ediSave EQU $+2
    Mov     edi, 23242526h
esiSave EQU $+2
    Mov     esi, 23242526h

gsSave EQU $+1
    Mov     ax, 2324h
    Mov     gs, ax
dsSave EQU $+1
    Mov     ax, 2324h
    Mov     ds, ax
esSave EQU $+1
    Mov     ax, 2324h
    Mov     es, ax

Exit:
    Mov     al, 20h                    ;Send EOI code
    Cmp     PASIRQ, 8
    Jb      @F
    Out     0A0h, al                   ;PIC 2
@@: Out     020h, al                   ;PIC 1

EDXSave EQU $+2
    Mov     edx, 23242526h             ;Restore those nifty registers
EAXSave EQU $+2
    Mov     eax, 23242526h
    Iret                               ;Return to regularly scheduled program
DMAIRQ              EndP

Include pasdetct.inc                   ;Pro AudioSpectrum autodetection routines
Include pasmisc.inc                    ;Other miscellaneous PAS routines

Include         msedata.inc            ;Include MSE data area

;ฤฤฤฤฤฤฤฤฤฤฤฤฤ Null Data Should be Placed Here ฤฤฤฤฤฤฤฤฤฤฤฤฤ
;(all ending nulls are removed from the MSE and saves disk space)

NullDataEnd     EQU     $
pas_mse EndS                           ;End of Dynamic segment
End
