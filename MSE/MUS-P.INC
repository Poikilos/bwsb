;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Music Processing Routines Begin Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

IFDEF GUS ;********
SetVolumeCL         Macro
    Mov     al, cl
    Mov     ds:SndChans.MixVolume, cl          ;Save new music volume
    Shr     cl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, cl            ;Save new vumeter

    Mul     MusicVol                           ;Multiply by master volume
    Shr     ax, 6                              ;Divide by 64
    Movzx   ebx, al                            ;Save new relative volume
    Mov     ds:SndChans.MixMonoVol, bl

    Mov     dx, GUSRegAddr
    Mov     al, 89h                            ;89h - GF1 Current Volume
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port
    In      ax, dx
    Cmp     ax, [GUSVolTable+ebx*2]
    Je      Short @F

    Mov     ax, [GUSVolTable+ebx*2]
    Call    UltraSlideRamp

@@:
    Mov     cl, ds:SndChans.MixMonoVol
    Movzx   bx, ds:SndChans.MixPanning
    Movzx   ax, Byte PTR [xPanTableRight+bx]
RightCalc:
    Mul     cl                         ;Mixing volume(CL)*Panning(AL)
    Shr     ax, 4                      ;Mixing volume\16=New Right Volume
    Mov     ds:SndChans.MixRgtVol, al
LeftCalc:
    Movzx   ax, Byte PTR [PanTableLeft+bx]
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Left Volume
    Mov     ds:SndChans.MixLftVol, al

EndM

ELSE      ;********

SetVolumeCL         Macro
    Mov     al, cl
    Mov     ds:SndChans.MixVolume, cl          ;Save new music volume
    Shr     cl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, cl            ;Save new vumeter

    Mul     MusicVol                           ;Multiply by master volume
    Shr     ax, 6                              ;Divide by 64
    Mov     cl, al                             ;Save new relative volume
    Mov     ds:SndChans.MixMonoVol, cl

IFDef Stereo
      Movzx   bx, ds:SndChans.MixPanning
      Movzx   ax, Byte PTR [xPanTableRight+bx]
  RightCalc:
      Mul     cl                         ;Mixing volume(CL)*Panning(AL)
      Shr     ax, 4                      ;Mixing volume\16=New Right Volume
      Mov     ds:SndChans.MixRgtVol, al
  LeftCalc:
      Movzx   ax, Byte PTR [PanTableLeft+bx]
      Mul     cl                         ;Mixing volume*Panning
      Shr     ax, 4                      ;Mixing volume\16=New Left Volume
      Mov     ds:SndChans.MixLftVol, al
EndIF
EndM

ENDIF     ;********

PattJump        db      0              ;0- Can pattern jump, 1- Jumps disabled
NoteEvent       db      0              ;0- Has no change, 1- Has note change
NoNoteFlag      db      0

LoopCounter     db      0              ;0- No loop, >0- number of loops left
PattLoop        db      0              ;Pattern row to loop to
PattLoopOff     dw      0              ;Pattern offset to loop to

CurrentOff      dw      0              ;Current Offset of row

MusicUpdateFX       Proc    Near
    push    ds
    push    eax

    Movzx   bx, NumChannels
    Add     bx, 2
    Shl     bx, 1
    Cmp     al, Tempo
    Jb      Short UpLoop

DownLoop:
    Mov     ds, cs:[SCSegTable+bx-2]      ;Get music channel segment
    Mov     ds:SndChans.MusEffect1, 0
    Mov     ds:SndChans.MusEffect2, 0
    Mov     ds:SndChans.MusEffect3, 0
    Mov     ds:SndChans.MusEffect4, 0
    Sub     bx, 2
    Jnz     DownLoop

    pop     eax
    pop     ds
    ret

UpLoop:
    Push    ebx
    Xor     di, di

IFDEF GUS ;*******
    Mov     dx, GUSAddr
    Add     dx, 102h                        ;GF1 Channel Select Port
    Mov     ax, bx                          ;Get current channel number
    Sub     ax, 2
    Shr     ax, 1                           ;Divide by 2
    Out     dx, al
ENDIF     ;*******

    Mov     ds, cs:[SCSegTable+bx-2]        ;Get music channel segment
NextEffect:
    Movzx   bx, ds:[SndChans.MusEffect1+di]
    Shl     bx, 1
    Jz      Short FXUpdateEnd
    Jmp     word ptr cs:[FXUpdate+bx-2]     ;Continue the effect
FXUpdateEnd Label Near
    Add     di, 3
    Cmp     di, 9
    Jb      Short NextEffect
    Pop     ebx
    Sub     bx, 2
    Jnz     UpLoop

    pop     eax
    pop     ds
    Ret
MusicUpdateFX       EndP

MusicUpdateRow      Proc    Near
    push    ds

    Mov     es, PlaySeg
    Mov     si, PlayOff
    Mov     CurrentOff, si             ;Save row beginning offset

    Mov     PattJump, 0

ChannelLoop:
    Mov     ch, es:[si]                ;Get the event specification byte
    Inc     si                         ;Update pointer
    Or      ch, ch                     ;Is it 0?
    Jz      RowComplete                ;If so, we're done, exit channel loop
    movzx   bx, ch
    and     bx, 1Fh

IFDEF GUS ;*******
    Mov     dx, GUSAddr
    Add     dx, 102h                   ;GF1 Channel Select Port
    Mov     al, bl
    Out     dx, al                     ;Send GUS the channel we're workin' on!
ENDIF     ;*******

    shl     bx, 1
    Mov     ds, cs:[SCSegTable+bx]     ;Get music channel segment

; Note/Sample Event Ü ;
;  ฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿ ;
BeginNSEvent:
    Test    ch, 32                     ;Is there a note event?
    Jz      BeginEffectEvent           ;No, check for effects
    Mov     NoteEvent, 0
    Mov     NoNoteFlag, 0

    Mov     bl, es:[si]                ;Get the note and instrument
    Inc     si                         ;Update pointer
    Or      bl, bl                     ;Is there a note?
    Jz      Short BeginSampleEvent     ;Nope, go do a sample change

BeginNoteEvent:                        ;|*|*|*[ NOTE EVENT ]*|*|*|
    Mov     NoteEvent, 1
    Dec     bl                         ;Decrement for real note
    Mov     cl, bl                     ;Make two copies
    And     bl, 0Fh                    ;LSN=Note.. Mask off MSN..
    Mov     ds:SndChans.MusNote, bl    ;Save the note number
    Shr     cl, 4                      ;MSN=Octave.. Pull MSN into LSN
    Mov     ds:SndChans.MusOctave, cl  ;Save the octave number

BeginSampleEvent:                      ;|*|*|*[ SAMPLE CHANGE EVENT ]*|*|*|
    Movzx   bx, Byte PTR es:[si]       ;Get the sample number
    Inc     si                         ;Update pointer
    Or      bl, bl                     ;Is there no sample change?
    Jz      EndNSEvent                 ;Yep, finish off the note/sample event.

    Dec     bl                         ;1 based decrement
    Mov     ds:SndChans.MusSample, bl  ;Save the sample number
    Shl     bx, 6                      ;Multiply sample number by 64

    Mov     ax, Samples.SamSeg[bx]
    Mov     ds:SndChans.MixSeg, ax
    Mov     word ptr ds:SndChans.GUSAddress, ax
    Mov     ah, Samples.SamHandle[bx]
    Mov     ds:SndChans.MixHandle, ah
    Mov     Byte PTR ds:SndChans.GUSAddress+2, ah

    Mov     cl, Samples.SamFlags[bx]
    Mov     ds:SndChans.MixFlags, cl
    Test    cl, 1
    Mov     eax, Samples.SamLen[bx]
    Jz      Short NoLoop
    Mov     eax, Samples.SamBegin[bx]
    Mov     ds:SndChans.MixLBeg, ax
    Mov     ds:SndChans.MusWaveStart, ax

IFDEF GUS ;*******
    Add     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr
    Mov     al, 3                      ;03h - Starting Location LSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc
    Out     dx, ax

    Dec     dx
    Mov     al, 2                      ;02h - Starting Location MSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc+2
    Out     dx, ax
ENDIF     ;*******

    Mov     eax, Samples.SamEnd[bx]
    Or      eax, eax
    Jz      Short NoLoop
    Dec     eax
NoLoop:
    Mov     ds:SndChans.MixLEnd, ax

IFDEF GUS ;*******
    Add     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr
    Mov     al, 05h                    ;05h - End Location LSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 4                      ;04h - End Location MSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc+2
    Out     dx, ax
ENDIF     ;*******

    Mov     ax, Samples.SamTune[bx]
    Mov     ds:SndChans.MixFinetune, ax
    Test    cl, 4
    Jz      Short EndNSEvent
    Mov     cl, Samples.SamVol[bx]
    SetVolumeCL

EndNSEvent:
    Cmp     NoteEvent, 0
    Jz      WasOnlySample

    Movzx   ebx, ds:SndChans.MusNote
    Mov     ax, cs:[PeriodTable+ebx*2]         ;Period value
    Mov     cl, ds:SndChans.MusOctave
    And     cl, 7                              ;Mask off upper bit
    Shr     ax, cl                             ;Divide by octave

    mov     bx, 8363                           ;Multiply by 8363 (C4 Hertz)
    mul     bx

    Mov     bx, ds:SndChans.MixFinetune        ;Divide calculate by finetune
    Or      bx, bx
    Jnz     Short @F
    Mov     NoNoteFlag, 1
    Mov     bx, 8363
@@: Div     bx
    Mov     bx, ax                             ;Save period in bx

    Mov     cl, ds:SndChans.MusOctave
    Test    cl, 8                              ;Do we retrigger the sample?
    Jz      Short Retrig

    And     cl, 7                              ;Mask off upper bit
    Mov     word ptr ds:SndChans.MixRate+2, bx
    Jmp     BeginEffectEvent

Retrig:
    Cmp     NoNoteFlag, 0                      ;Allowed to play this note?
    Jnz     Short SetOnlyOffset

    Mov     word ptr ds:SndChans.MixRate, bx
    Mov     ax, word ptr cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, word ptr cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx

    Mov     ds:SndChans.MixInc, ax
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift
    Out     dx, ax
ENDIF     ;*******

SetOnlyOffset:
    Mov     ds:SndChans.MixIncRemain, 0
    Mov     ds:SndChans.MixOff, 0
IFDEF GUS ;********
    Mov     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax
ENDIF     ;********

IFDEF GUS ;*******
    Mov     dx, GUSRegAddr             ;3x3h - GF1 Register Select
    Xor     al, al                     ;00h - Write Voice Control Register
    Out     dx, al
    Add     dx, 2                      ;3x5h - GF1 Data MSB
    Mov     al, ds:SndChans.MixFlags
    And     al, 1                      ;Loop flag
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al
ENDIF     ;*******

WasOnlySample:

; Effect Events Ü ;
;  ฿฿฿฿฿฿฿฿฿฿฿฿฿฿ ;
BeginEffectEvent:
    Test    ch, 64                     ;Is there an Effect event?
    Jz      Short BeginEndRowEvent     ;No, check for end of row
MoreEffecT:
    Mov     cl, es:[si]                ;Yes, get the effect number
    Inc     si                         ;Update pointer

    Mov     al, cl
    And     al, 63
    Movzx   edi, cl                    ;Make a effect channel pointer
    Shr     edi, 6                     ;Pull off all other bits
    Lea     edi, [edi*2+edi]           ;Multiply by 3

    Movzx   bx, cl
    And     bx, 31                     ;Have only effect number
    Mov     ds:SndChans.MusEffect1[di], bl;Save the effect number
BeginEffect:
    Mov     ah, es:[si]                ;Get the effect data
    Inc     si                         ;Update pointer
    Shl     bx, 1                      ;Multiply by two
    Push    eax
    Jmp     word ptr cs:[FXTable+bx-2] ;Setup the effect
FXStartEnd Label Near
    Pop     eax
    Test    al, 32                     ;Is there another effect?
    Jnz     MoreEffecT

BeginEndRowEvent:

EndChannelLoop:
    Jmp     ChannelLoop

RowComplete:
    Inc     PlayRow
    Jnz     Short @F
    pop     ds
    ret
@@: Cmp     PattJump, 0                ;Are we allowed to jump to patterns?
    Jnz     Short NoNewPatOff
    Cmp     si, PlayLen                ;Is this pattern complete?
    Jne     Short NoNewPattern         ;Nope, go continue

    Mov     PattLoopOff, 0             ;Reset pattern loop location
    Movzx   bx, PlayOrder              ;Increment the play order
    Inc     bl
    Cmp     bl, NOOrders               ;Are we past the last order?
    Jbe     Short @F
    Xor     bx, bx                     ;Yeah, loop back to first order
    Inc     MusicLpCount               ;Increment loop count
    Cmp     MusicLpStatus, 0           ;Are we allowed to loop?
    Jnz     Short @F                   ;If non zero, yeah
    Mov     MusicStatus, 0             ;If zero, no, so disable music
@@:
    Mov     PlayOrder, bl              ;Save new order number
    Movzx   bx, cs:[OrderTable+bx]     ;Look up the pattern number in order table
    Mov     PlayPattern, bl            ;Save new pattern number
    Shl     bx, 1                      ;Multiply by two for tables
    Mov     ax, cs:[PatSegTable+bx]    ;Get segment of new pattern
    Mov     PlaySeg, ax                ;Save new pattern segment
    Mov     es, ax
    Mov     ax, es:[0]                 ;Get length of new pattern
    Mov     PlayLen, ax                ;Save length of new pattern
    Mov     PlayRow, 0                 ;Back to row 0
    Mov     si, 2

NoNewPattern:
    Mov     PlayOff, si                ;Save play offset
NoNewPatOff:

    pop     ds
    ret
MusicUpdateRow      EndP
