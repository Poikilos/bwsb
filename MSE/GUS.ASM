;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;                                Gravis Ultrasound
;                   BWSB Music and Sound Engine Source Code
;                   Copyright (c) 1993-97, Edward Schlunder. 
;                  See COPYING.ES for redistribution details.
;
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
.model medium, basic                   ;Let us use simplified calling conventions
.386P                                  ;Let us use 386 specific instructions
GUS     EQU -1
Stereo  EQU -1                         ;Yes, playing in stereo

gus_mse Segment Use16                  ;Define our dynamic segment, 16bit RM
Assume  cs:gus_mse                     ;Make sure we always uses CS and not DS
Org     0                              ;Dynamic Drivers originate at 0.

include id.inc

;BWSB Music and Sound Engine format
MSEFormat      Struc
 Description    db      'BWSB Music and Sound Engine ',BBVer,' (GUS)   ',13,10
 Copyright      db      'Copyright (c) 1993-97, Edward Schlunder ',13,10
 Author         db      'Written by Ed Schlunder  zilym@aztec.asu.edu',26
 MSESize        dw      ?
 Identification db      IDString
 MSEVersion     db      MajorVersion, MinorVersion
 Functions      db      NumberFunc
 DeviceName     db      'Gravis Ultrasound', 0, 0, 0
MSEFormat      EndS     ;1234567890

MSEHeader       MSEFormat <>           ;Setup MSE header

Include         func.inc               ;Include function vector table

;ฤ Gravis Ultrasound Variables ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
TempLoc         dd      0              ;Scratch pad memory area

GUSAddr         dw      0FFFFh         ;Ultrasound's Base I/O Address
GUSRegAddr      dw      0FFFFh         ;GF1/Global Register Select Port

GUSDMA          db      0FFh           ;Ultrasound's Playback DMA channel
GUSDMARecord    db      0FFh           ;Ultrasound's Recording DMA channel

GUSIRQ          db      0FFh           ;Ultrasound's GF1 IRQ Level
GUSIRQMidi      db      0FFh           ;Ultrasound's MIDI IRQ Level
GUSInt          db      15             ;Actual Interrupt number for GF1 IRQ

GUSTickerRate   db      50             ;GUS's timer rate (We use 80ms*2 Timer)
GUSMemoryUsed   dd      0              ;Upper limit to Ultrasound memory

;ฤ Ultrasound Tables ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
GUSVolTable      dw      08800h,09800h
                 dw      0A200h,0A800h,0AE00h,0B200h,0B500h,0B800h,0BB00h
                 dw      0BE00h,0C080h,0C200h,0C380h,0C500h,0C680h,0C800h
                 dw      0C980h,0CB00h,0CC80h,0CE00h,0CF80h,0D080h,0D140h
                 dw      0D200h,0D2C0h,0D380h,0D440h,0D500h,0D5C0h,0D680h
                 dw      0D740h,0D800h,0D8C0h,0D980h,0DA40h,0DB00h,0DBC0h
                 dw      0DC80h,0DD40h,0DE00h,0DEC0h,0DF80h,0E020h,0E080h
                 dw      0E0E0h,0E140h,0E1A0h,0E200h,0E260h,0E2C0h,0E320h
                 dw      0E380h,0E3E0h,0E440h,0E4A0h,0E500h,0E560h,0E5C0h
                 dw      0E620h,0E680h,0E6E0h,0E740h,0E7A0h,0E800h,0E860h

;GUSVolTable     dw      01500h
;                dw      09300h,0A900h,0B400h,0BC00h,0C180h,0C580h,0C980h,0CD80h
;                dw      0CF40h,0D240h,0D440h,0D640h,0D840h,0DA40h,0DC40h,0DE40h
;                dw      0DEF0h,0DFA0h,0E1A0h,0E2A0h,0E3A0h,0E4A0h,0E5A0h,0E6A0h
;                dw      0E7A0h,0E8A0h,0E9A0h,0EAA0h,0EBA0h,0ECA0h,0EDA0h,0EEA0h
;                dw      0EEF0h,0EFE0h,0EF60h,0F1E0h,0F160h,0F1E0h,0F260h,0F2E0h
;                dw      0F360h,0F3E0h,0F460h,0F4E0h,0F560h,0F5E0h,0F660h,0F6E0h
;                dw      0F760h,0F7E0h,0F860h,0F8E0h,0F960h,0F9E0h,0FA60h,0FAF0h
;                dw      0FB70h,0FBF0h,0FC70h,0FCF0h,0FD70h,0FD90h,0FDB0h,0FDD0h

;GUSVolTable     dw      00800,20000,39120,41376,42656,43936,45072,45696
;                dw      46240,46848,47408,47952,48528,49072,49360,49632
;                dw      49920,50160,50432,50704,50928,51168,51424,51680
;                dw      51952,52160,52448,52672,52912,53152,53312,53440
;                dw      53584,53664,53808,53952,54048,54144,54288,54400
;                dw      54496,54608,54720,54832,54944,55072,55184,55312
;                dw      55440,55552,55696,55760,55888,56016,56096,56240
;                dw      56304,56448,56528,56672,56752,56896,56976,57136
;                dw      57216

;This table is used to figure out what oversampling rate is being used:
GUSOverTable    dw      44100,41160,38587,36317,34300,32494,30870,29400,28063
                dw      26843,25725,24696,23746,22866,22050,21289,20580,19916
                dw      19293

;ฤ IRQ/DMA Data Tables ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
OldIRQ          dd      ?              ;Holder for old IRQ vector
;                  DMA:  0    1    2    3    4    5    6    7
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

;This macro does a little delay for the GUS, let's us time things out better..
GF1_Delay       Macro
    push    ax                         ;Do not modify any registers
    push    dx
    mov     dx, GUSRegAddr
rept 6
    in      al, dx                     ;Input 7 times
endm
    pop     dx
    pop     ax
EndM

Include         funcode.inc            ;Include interface functions' code

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: LoadMSE                                                       0
 Calling: ch      Sound device IRQ level. FFh for autodetect.
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

    Mov     GUSAddr, dx                ;Save the GUS's Base I/O Address
    Mov     GUSIRQ, ch                 ;Save the GUS's IRQ level
    Mov     GUSDMA, cl                 ;Save DMA channel
    Call    ReadULTRASND               ;Read the ULTRASND environment variable

;ฤฤฤ Ultrasound Base I/O Address
    Cmp     GUSAddr, 0FFFFh            ;Do we need to autodetect the GUS's Addr?
    Jne     Short @F                   ;Skip if autodetect not required
    Call    DetectGUSAddr              ;Go detect the GUS's base I/O address
    Mov     ax, 1                      ;Base I/O Address detection error
    Jc      Exit

;ฤฤฤ Sound Device Checkup
    Mov     dx, GUSAddr                ;210h, 220h, 230h, 240h, 250h, or 260h
    Add     dx, 103h                   ;3x3h - Global Register Select Port
    Mov     GUSRegAddr, dx             ;Save fast access port number reading

    Call    CheckGUS                   ;Make sure GUS exists on this I/O Address
    Mov     ax, 6                      ;Sound Device doesn't respond error
    Jc      Exit                       ;Exit if GUS check failed
    Call    InitGUS                    ;Initialize the Ultrasound

@@: Mov     dx, GUSAddr
    Add     dx, 103h                   ;Global Register Select Port
    Mov     GUSRegAddr, dx

;ฤฤฤ Ultrasound IRQ Level
    Cmp     GUSIRQ, 0FFh               ;Do we need to autodetect IRQ?
    Jne     Short @F                   ;Skip if autodetection isn't required
    Call    DetectGUSIRQ               ;Go detect the GUS's IRQ
    Mov     ax, 2                      ;Sound Device IRQ level detection failure
    Jc      Exit                       ;If IRQ detection failed, exit routine

@@: Mov     ch, GUSIRQ                 ;Retrieve the GUS's IRQ
    Cmp     ch, 8                      ;Is IRQ using PIC2?
    Jb      Short @F                   ;PIC1 - Just do the regular IRQ Int calc
    Add     ch, 70h - 8                ;IRQ + 70h = PIC2 Interrupt Number
    Jmp     Short SetInt               ;Go save the IRQ Interrupt number

@@: Add     ch, 8                      ;IRQ + 8 = PIC1 Interrupt Number
SetInt:
    Mov     GUSInt, ch                 ;Save the GUS's IRQ Interrupt Number

;ฤฤฤ Ultrasound DMA Channel
    Cmp     GUSDMA, 0FFh               ;Do we need to autodetect DMA channel?
    Jne     Short @F
    Mov     ax, 3                      ;DMA Channel detect error
    Jc      Exit                       ;If autodetection error, exit routine

@@: And     GUSDMA, 00000111b
    Cmp     GUSDMA, 4                  ;Is channel on DMA Controller 1 or 2?
    Jb      Short DMAC1
DMAC2:
    Mov     al, DMAMaskTable[1]        ;Load up all DMA port stuff with DMAC2
    Mov     DMASingleMask, al          ;I/O addresses.
    Mov     al, DMAFlpFTable[1]
    Mov     DMAFlipFlop, al
    Mov     al, DMAModeTable[1]
    Mov     DMATransMode, al

    Jmp     Short SetupSndChans

DMAC1:
    Mov     al, DMAMaskTable[0]        ;Load up all port information with DMAC1
    Mov     DMASingleMask, al          ;I/O addresses.
    Mov     al, DMAFlpFTable[0]
    Mov     DMAFlipFlop, al
    Mov     al, DMAModeTable[0]
    Mov     DMATransMode, al

SetupSndChans:
    Call    PreInitGUS                 ;Set up IRQ/DMA Select Ports
    Call    InitGUS                    ;Kick GUS into a known state
    Call    PreInitGUS                 ;Set up IRQ/DMA Select Ports
    Call    InitGUS                    ;Kick GUS into a known state

    Mov     Tempo, 6                   ;Set up for normal music speeds
    Mov     BPM, 125
    Call    CalcBPMTimer               ;Get GUS timer working for us..
    Mov     TempoCounter, 0
    Mov     GUSMemoryUsed, 0

    Mov     ax, cs
    Mov     cl, 34
    Xor     bx, bx
CalcSegLoop:
    Mov     cs:[SCSegTable+bx], ax
    Add     ax, 8
    Add     bx, 2
    Dec     cl
    Jnz     CalcSegLoop

    Mov     OutputStatus, 0            ;Set the output disabled flag
    Mov     InstallStatus, 1           ;Set flag that we are installed
    Xor     ax, ax                     ;Clear error flag
Exit:
    Mov     cl, GUSDMA                 ;Return the GUS DMA channel detected
    Mov     ch, GUSIRQ                 ;Return the GUS IRQ number detected
    Mov     dx, GUSAddr                ;Return the GUS Base I/O detected
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
    Jz      Short @F                   ;Skip if not enabled
    Mov     OutputStatus, 0            ;Set flag that output is disabled
    Call    UnInstallGUS               ;Deactivate the sound device
    Call    DeallocModule              ;Dealloc module memory

@@: Mov     InstallStatus, 0           ;Set flag that we are not installed
    Mov     es, BufferSegment          ;Get segment of mixing buffer
    Mov     ah, 49h                    ;Release memory of mixing buffer
    Int     21h

Exit:
    Ret                                ;Return to caller
FreeMSE             EndP

Comment *ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
 Routine: StartOutput                                                   2
 Calling: al      Number of output channels (1..32)
          bh      Amplification value (-9..9) [Ignored with GUS]
 Returns: bx      Oversampling rate actually being used
 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ*
StartOutput         Proc        Uses es di eax edx
    Push    ebx
    Cmp     OutputStatus, 0            ;Is output already enabled?
    Jnz     Exit

    Cmp     al, 32                     ;Make sure number of channels isn't >32
    Jbe     Short @F
    Mov     al, 32                     ;Put to max if above 32
@@: Cmp     al, 14                     ;Make sure number of channel isn't <14
    Ja      @F
    Mov     al, 14                     ;Put to min if below 14 (GUS Requires)
@@: Mov     NumChannels, al            ;Save number of channels to use

    Call    InstallGUS                 ;Install GUS output routines

;ฤฤ Active Voices
    Mov     dx, GUSRegAddr             ;3x3h - Global Register Select
    Mov     al, 0Eh                    ;0Eh - Write Active Voices Register
    Out     dx, al
    Add     dx, 2                      ;3x5h - Data High Port
    Mov     al, NumChannels            ;Get number of channels
    Dec     al                         ;GUS Decrement
    Or      al, 0C0h                   ;Set upper two bits (GUS requires)
    Out     dx, al                     ;Tell GUS how many channels to use

    And     eax, 31                    ;Mask off all but lower 5 bits
    Mov     ax, [GUSOverTable-26+eax*2];Look up oversampling rate in table
    Mov     OverRate, ax               ;Save new oversampling rate

    Mov     eax, AmigaClockHz          ;Calculate new ClockHertz value (used
    Xor     edx, edx                   ;for amiga period calcuations).
    Movzx   ebx, OverRate
    Div     ebx
    Shl     eax, 1
    Mov     ClockHertz, eax            ;Save period clock calculation number

    Mov     dx, GUSAddr
    Add     dx, 8                      ;2x8h - Timer Control Register
    Mov     al, 4                      ;Select timer stuff - AdLib thang
    Out     dx, al
    Inc     dx                         ;2x9h - Timer Data Register
    Mov     al, 10000000b              ;Reset Timer IRQs
    Out     dx, al

    Mov     OutputStatus, 1            ;Flag that output is now enabled
Exit:
    Pop     ebx
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
    Jz      Short Exit

    Call    UnInstallGUS               ;Deactivate the sound device

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
GetMainScope        Proc        Uses esi ds es ebx
    Mov     cx, 8000h
    Mov     dx, 8000h
    Movzx   ebx, NumChannels
    Inc     bl

ChanLoop:
    Call    GetOneChan
    Mov     ds, SCSegTable[ebx*2-2]
    Mov     bh, al
    Mov     al, ds:SndChans.MixLftVol
    Or      al, al
    Jz      Short @F
    Imul    bh
    Add     dx, ax

@@: Mov     al, ds:SndChans.MixRgtVol
    Or      al, al
    Jz      Short @F
    Imul    bh
    Add     cx, ax

@@: Xor     bh, bh
    Dec     bl
    Jnz     ChanLoop

EndLoop:
    Mov     ax, dx
    Ret
GetMainScope        EndP

GetOneChan          Proc        Near    Uses bx ecx dx
    Mov     dx, GUSAddr
    Add     dx, 102h                   ;GF1 Channel Select Port
    Mov     al, bl                     ;Set current channel number
    Dec     al
    Out     dx, al

    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select Port
    Mov     al, 08Ah                   ;8Ah - Voice Current Address High
    Out     dx, al

    Inc     dx                         ;3x4h - Data Low Port
    In      ax, dx                     ;Get high address
    Movzx   ecx, ax
    Shl     ecx, 7

    Dec     dx                         ;3x3h - GF1 Register Select
    Mov     al, 08Bh                   ;8Bh - Voice Current Address Low
    Out     dx, al

    Inc     dx                         ;3x4h - Data Low Port
    In      ax, dx

    Shr     ax, 9
    And     ax, 07Fh
    Or      cx, ax

    Mov     dx, GUSRegAddr             ;3x3h - Global Register Select
    Mov     al, 43h                    ;43h - Low 16 line DRAM loc
    Out     dx, al
    Inc     dx                         ;3x4h - Data Low Port
    Mov     ax, cx
    Out     dx, ax
    Dec     dx                         ;3x3h - Global Register Select
    Mov     al, 44h                    ;44h - High 4 line DRAM loc
    Out     dx, al
    Add     dx, 2                      ;3x5h - Data High Port
    Shr     ecx, 16
    Mov     al, cl
    Out     dx, al
    Add     dx, 2                      ;3x7h - DRAM Peek Port
    In      al, dx

    Ret
GetOneChan          EndP

Comment                                *
  ÛฐÛอออออออออออออออออออออออออออออออออ๚๙๚อออออออออออออออออออออออออออออออออÛฐÛ

  ๚þ๚                     Internal Routines Begin Here                    ๚þ๚

  ÛฐÛอออออออออออออออออออออออออออออออออ๚๙๚อออออออออออออออออออออออออออออออออÛฐÛ
                                       *
Include mus-p.inc                      ;Music processing routines
Include mus-efx.inc                    ;Music effect processing routines

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Gravis Ultrasound IRQ Handling Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
InstallGUS          Proc    Near

    Push    es
    Mov     al, GUSInt                 ;Get the original IRQ vector
    Mov     ah, 35h                    ;Call DOS to get it
    Int     21h
    Mov     Word PTR OldIRQ, bx        ;Save old IRQ vector
    Mov     Word PTR OldIRQ+2, es
    Pop     es

    Push    ds                         ;Save DS, DOS requires us to mess it up
    Mov     dx, Offset TimerIRQ        ;Load DX with our Timer IRQ handler offset
    Mov     ah, 25h                    ;DOS function to change int vectors
    Mov     al, GUSInt
    Mov     bx, cs                     ;Put segment of our DMA IRQ handler in
    Mov     ds, bx                     ;DX for DOS's use.
    Int     21h                        ;Go call DOS and have the interrupt
    Pop     ds                         ;Restore DS

    Mov     dx, GUSAddr                ;Mix Control Port
    Mov     al, 9                      ;Enable IRQ Latches, Disable Line In
    Out     dx, al

    Call    SetUltraTimer1             ;Program the GUS to do our stuff

    Cli
    In      al, 0A1h                   ;Get current IRQ masks
    Mov     ah, al
    In      al, 021h

    Mov     dx, 0FFFEh                 ;Set all but bit 0 of DX
    Mov     cl, GUSIRQ
    Rol     dx, cl                     ;Shift bit over to correct IRQ
    And     ax, dx                     ;Unmask our IRQ number

    Out     021h, al                   ;Reprogram PICs
    Mov     al, ah
    Out     0A1h, al
    Sti

Exit:
    Ret
InstallGUS          EndP

UnInstallGUS        Proc    Near    Uses ax bx cx dx
    Cli
    Mov     dx, GUSRegAddr             ;3x3h - Global Register Select
    Mov     al, 45h                    ;45h - Timer Control Register
    Out     dx, al
    Add     dx, 2                      ;3x5h - Data High Port
    In      al, dx
    And     al, 0FBh                   ;Disable Timer 1 IRQ
    Out     dx, al

    Call    InitGUS                    ;Initialize Gravis Ultrasound

    Mov     dx, GUSAddr                ;Mix Control Port
    Mov     al, 8                      ;Enable IRQ Latches, Line In/Out
    Out     dx, al

    In      al, 0A1h                   ;Get current IRQ masks in AX
    Mov     ah, al
    In      al, 021h
    Mov     dx, 1                      ;Set bit 0
    Mov     cl, GUSIRQ
    Shl     dx, cl                     ;Shift over till we've hit our IRQ
    Or      ax, dx                     ;Mask the GUS IRQ
    Out     021h, al                   ;Reprogram PITs
    Mov     al, ah
    Out     0A1h, al

    Mov     al, GUSInt                 ;Restore original IRQ handler
    Push    ds
    Mov     dx, word ptr OldIRQ
    Mov     ds, word ptr OldIRQ+2
    Mov     ah, 25h
    Int     21h
    Pop     ds

    Sti
    Ret
UnInstallGUS        EndP

TickTock        db      0              ;IRQ halver
NeedsTick       db      1

    Align   4                          ;Double word alignment for 386+
TimerIRQ            Proc    Far        ;Music Timer IRQ Handler
    Mov     DWord PTR cs:EAXSave, eax  ;Save all the registers we're gonna
    Mov     DWord PTR cs:EDXSave, edx  ;use right now..
    Mov     Word PTR cs:esSave, es
    Mov     Word PTR cs:dsSave, ds
    Mov     Word PTR cs:gsSave, gs
    Mov     Dword PTR cs:esiSave, esi  ;Gonna need to save some more
    Mov     Dword PTR cs:ediSave, edi  ;registers for the mixing routines
    Mov     Dword PTR cs:ebpSave, ebp
    Mov     Dword PTR cs:ebxSave, ebx
    Mov     Dword PTR cs:ecxSave, ecx

    Call    SetUltraTimer1
    Cli
    Mov     dx, GUSRegAddr             ;3x3h - Register Select
    Mov     al, 45h                    ;45h - Timer Control
    Out     dx, al
    Add     dx, 2                      ;3x5h - MSB
    Xor     al, al                     ;Disable Timer IRQs
    Out     dx, al
    Mov     al, 0100b                  ;Enable Timer 1 IRQ (80ms timer)
    Out     dx, al
    Sti

    Dec     TickTock
    Jnz     Short GoodExit             ;If nonzero, exit
    Mov     al, NeedsTick
    Mov     TickTock, al

@@: Cmp     MusicStatus, 0             ;Is the music enabled?
    Jz      Short GoodExit             ;Exit if it's disabled

    Mov     al, TempoCounter
    Inc     al
    Call    MusicUpdateFX
    Cmp     al, Tempo
    Jb      Short TempoExit

    Mov     TempoCounter, 0
    Call    MusicUpdateRow
    Jmp     Short GoodExit

TempoExit:
    Mov     TempoCounter, al

GoodExit:
TestNext:

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

    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select
    Mov     al, 8Fh
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data High I/O
    In      al, dx

    Mov     al, 20h                    ;Send EOI code
    Cmp     GUSIRQ, 8
    Jb      Short @F
    Out     0A0h, al                   ;PIC 2
@@: Out     020h, al                   ;PIC 1

EDXSave EQU $+2
    Mov     edx, 23242526h             ;Restore those nifty registers
EAXSave EQU $+2
    Mov     eax, 23242526h
    Iret                               ;Return to regularly scheduled program
TimerIRQ            EndP

Include gusdetct.inc                   ;Ultrasound autodetection routines
Include gusmisc.inc                    ;Other miscellaneous GUS routines


include         msedata.inc            ;Include MSE data area

NullDataEnd     EQU     $
gus_mse EndS                           ;End of Dynamic segment

End
