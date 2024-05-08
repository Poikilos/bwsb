;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Effect Processing Routines Begin Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; [OR] - On Row         [S] - Effect Setup
; [OF] - On Frame       [D] - Effect Do
;
;[On Rows] Entry: ah=effect data on entry
;                 al and 31=effect number
;                 di=Effect Channel offset
;          Exit:  Must JMP to FXStartEnd
;          Note:  es si ch ss sp needs preservation
;
;[Between] Entry: di=Effect Channel offset
;          Exit:  Must JMP to FXUpdateEnd
;          Note:  ss sp needs preservation

FXTable         dw      Offset PortaUpDownStart ;01xx- Portamento Up
                dw      Offset PortaUpDownStart ;02xx- Portamento Down
                dw      Offset PortaNoteStart   ;03xx- Porta to Note
                dw      Offset VibratoStart     ;04xy- Vibrato
                dw      Offset Porta_VolStart   ;05xy- Porta to Note+Vol Slide
                dw      Offset Vibrato_VolStart ;06xy- Vibrato+Vol Slide
                dw      Offset TremoloStart     ;07xy- Tremolo
                dw      Offset FXStartEnd       ;08xy- Tremor
                dw      Offset SampleOffset     ;09xx- Sample Offset
                dw      Offset VolSlideStart    ;0Axy- Volume Slide
                dw      Offset OrderJump        ;0Bxx- Order Jump
                dw      Offset SetVolume        ;0Cxx- Set Volume
                dw      Offset PatternBreak     ;0Dxx- Pattern Break
                dw      Offset ExtendedStart1   ;0Exx- Extended Effects
                dw      Offset SetTempo         ;0Fxx- Set Tempo/End Module
                dw      Offset ArpeggioStart    ;10xx- Arpeggio
                dw      Offset FXStartEnd       ;11xy- Set Internal Flag
                dw      Offset RetrigNoteStart  ;12xy- Retrig Note+Vol Slide
                dw      Offset SetGlobalVolume  ;13xx- Global Volume
                dw      Offset VibratoStart     ;14xy- Fine Vibrato
                dw      Offset FXStartEnd       ;15xx- Undefined
                dw      Offset FXStartEnd       ;16xx- Undefined
                dw      Offset FXStartEnd       ;17xx- Undefined
                dw      Offset FXStartEnd       ;18xx- Undefined
                dw      Offset FXStartEnd       ;19xx- Undefined
                dw      Offset FXStartEnd       ;1Axx- Undefined
                dw      Offset FXStartEnd       ;1Bxx- Undefined
                dw      Offset FXStartEnd       ;1Cxx- Undefined
                dw      Offset FXStartEnd       ;1Dxx- Undefined
                dw      Offset ExtendedStart2   ;1Exx- Extended Effects #2
                dw      Offset SetBPM           ;1Fxx- Set BPM

FXExtended      dw      Offset FXStartEnd       ;0E0x- Set Low Pass Filter
                dw      Offset FinePortaUp      ;0E1x- Fine Porta Up
                dw      Offset FinePortaDown    ;0E2x- Fine Porta Down
                dw      Offset FXStartEnd       ;0E3x- Glissando Control
                dw      Offset SetVibraWave     ;0E4x- Set Vibrato Waveform
                dw      Offset SetFinetune      ;0E5x- Set C-4 Finetune
                dw      Offset StartPatternLoop ;0E6x- Pattern Loop
                dw      Offset SetTremoWave     ;0E7x- Set Tremolo Waveform
                dw      Offset ExtraFinePortaUp ;0E8x- Extra Fine Porta Up
                dw      Offset ExtraFinePortaDwn;0E9x- Extra Fine Porta Down
                dw      Offset FineVolumeUp     ;0EAx- Fine Vol Slide Up
                dw      Offset FineVolumeDown   ;0EBx- Fine Vol Slide Down
                dw      Offset NoteCutStart     ;0ECx- Note Cut
                dw      Offset NoteDelayStart   ;0EDx- Note Delay
                dw      Offset PatternDelay     ;0EEx- Pattern Delay
                dw      Offset StartFunkIt      ;0EFx- Invert Loop

FXExtended2     dw      Offset FXStartEnd       ;1E0x- Set Surround
                dw      Offset FXStartEnd       ;1E1x- Set Sample Direction
                dw      Offset FXStartEnd       ;1E2x- Set Sample Loop
                dw      Offset FXStartEnd       ;1E3x- Undefined
                dw      Offset FXStartEnd       ;1E4x- Undefined
                dw      Offset FXStartEnd       ;1E5x- Undefined
                dw      Offset FXStartEnd       ;1E6x- Undefined
                dw      Offset FXStartEnd       ;1E7x- Undefined
                dw      Offset SetPan           ;1E8x- Set Pan Position
                dw      Offset FXStartEnd       ;1E9x- Undefined
                dw      Offset FXStartEnd       ;1EAx- Undefined
                dw      Offset FXStartEnd       ;1EBx- Undefined
                dw      Offset FXStartEnd       ;1ECx- Undefined
                dw      Offset FXStartEnd       ;1EDx- Frequency Adjust
                dw      Offset FXStartEnd       ;1EEx- Undefined
                dw      Offset FXStartEnd       ;1EFx- Undefined

FXUpdate        dw      Offset PortaUpUpdate    ;01xx- Porta Up
                dw      Offset PortaDownUpdate  ;02xx- Portamento Down
                dw      Offset PortaNoteDnUpdate;03xx- Porta to Note Down
                dw      Offset VibratoUpdate    ;04xy- Vibrato
                dw      Offset Porta_VolUpdate  ;05xy- Porta to Note+Vol Slide
                dw      Offset Vibrato_VolUpdate;06xy- Vibrato+Vol Slide
                dw      Offset TremoloUpdate    ;07xy- Tremolo
                dw      Offset FXUpdateEnd      ;08xy- Tremor
                dw      Offset FXUpdateEnd      ;09xx- Sample Offset
                dw      Offset VolSlideUpdate   ;0Axy- Volume Slide
                dw      Offset FXUpdateEnd      ;0Bxx- Order Jump
                dw      Offset FXUpdateEnd      ;0Cxx- Set Volume
                dw      Offset FXUpdateEnd      ;0Dxx- Pattern Break
                dw      Offset FXUpdateEnd      ;0Exx- Extended Effects
                dw      Offset FXUpdateEnd      ;0Fxx- Set Tempo/End Module
                dw      Offset ArpeggioUpdate   ;10xx- Arpeggio
                dw      Offset FXUpdateEnd      ;11xy- Set Internal Flag
                dw      Offset RetrigNoteUpdate ;12xy- Retrig Note+Vol Slide
                dw      Offset FXUpdateEnd      ;13xx- Global Volume
                dw      Offset FineVibratoUpdate;14xy- Fine Vibrato
                dw      Offset FXUpdateEnd      ;15xx- Undefined
                dw      Offset FXUpdateEnd      ;16xx- Undefined
                dw      Offset FXUpdateEnd      ;17xx- Undefined
                dw      Offset FXUpdateEnd      ;18xx- Undefined
                dw      Offset FXUpdateEnd      ;19xx- Undefined
                dw      Offset FXUpdateEnd      ;1Axx- Undefined
                dw      Offset FXUpdateEnd      ;1Bxx- Undefined
                dw      Offset FXUpdateEnd      ;1Cxx- Undefined
                dw      Offset FXUpdateEnd      ;1Dxx- Undefined
                dw      Offset FXUpdateEnd      ;1Exx- Extended Effects #2
                dw      Offset FXUpdateEnd      ;1Fxx- Set BPM
                dw      Offset PortaNoteUpUpdate;20xx- Porta to Note Up
                dw      Offset NoteCutUpdate    ;21xx- Note Cut
                dw      Offset NoteDelayUpdate  ;22xx- Note Delay
                dw      Offset UpdateFunkIt     ;23y - Funk It (Invert Loop)

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 1xx/2xx - Porta Up/Down Start                          [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaUpDownStart    Proc    Near
    Movzx   eax, ah                            ;Move periods into AX
    Lea     eax, [eax*4]                       ;Periods x 4 = ST3 Periods
    Jnz     Short @F                           ;Is the new porta speed zero?
    Movzx   eax, ds:SndChans.MusPortaUD[di]    ;Yes, check for an old porta to
    Lea     eax, [eax*4]                       ;repeat
    Jnz     Short @F
    Mov     ds:SndChans.MusEffect1[di], 0      ;Clear the porta command
@@: Mov     ds:SndChans.MusEffDat1[di], ax     ;Save the new porta speed
    Shr     ax, 2
    Mov     ds:SndChans.MusPortaUD[di], al     ;Save for speed for later use
    Jmp     FXStartEnd                         ;Return to music processing
PortaUpDownStart    EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 1xx - Porta Up Update                                  [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaUpUpdate       Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Mov     ax, ds:SndChans.MusEffDat1[di]     ;Save porta speed in ax
    Sub     bx, ax                             ;Subtract number of periods
    Cmp     bx, 113 ;452                       ;Are we at B-5 (low limit)?
    Ja      Short PortaDo                      ;No, go do the porta
PortaStop:                                     ;We're at B-5, end the porta
    Mov     ds:SndChans.MusEffect1[di], 0      ;Clear effect number
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaDo:
    Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period value
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx                                 ;Calculate new sample increment

    Cmp     ds:SndChans.MixInc, 0              ;Is the sound ended?
    Jz      FXUpdateEnd                        ;Yeah, don't start it!

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
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
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaUpUpdate       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 2xx - Porta Down Update                                [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaDownUpdate     Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Mov     ax, ds:SndChans.MusEffDat1[di]     ;Save porta speed in ax
    Add     bx, ax                             ;Add number of periods
    Cmp     bx, 27392 ;3424                    ;Are we at C-3 (high limit)?
    Jb      Short PortaDo                      ;No, go do the porta
PortaStop:                                     ;We're at C-3, end the porta
    Mov     ds:SndChans.MusEffect1[di], 0      ;Clear effect number
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaDo:
    Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period value
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx                                 ;Calculate new sample increment

    Cmp     ds:SndChans.MixInc, 0              ;Is the sound ended?
    Jz      FXUpdateEnd                        ;Yeah, don't start it!

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
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
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaDownUpdate     EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 3xx - Porta to Note Start                              [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaNoteStart      Proc    Near
    Mov     bx, word ptr ds:SndChans.MixRate+2 ;Porta Note Destination
    Or      bx, bx                             ;Is there a porta destination?
    Jz      Short NoPorta                      ;No, so don't do porta
    Mov     dx, word ptr ds:SndChans.MixRate   ;Current Note Period
    Or      dx, dx
    Jz      Short NoPorta
    Movzx   ax, ah                             ;AX=porta speed
    Shl     ax, 2                              ;Multiply by 4, Amiga Periods!
    Jz      Short @F                           ;If speed=0, use old speed
    Mov     ds:SndChans.MusPortaRate, ax       ;If speed<>0, save new speed
@@: Cmp     dx, bx
    Je      Short NoPorta                      ;If dest=curr then no porta
    Jl      FXStartEnd                         ;If current below dest, then down
    Mov     ds:SndChans.MusEffect1[di], 20h    ;Do a Porta to Note Up
    Jmp     FXStartEnd
NoPorta:
    Mov     ds:SndChans.MusEffect1[di], 0      ;Don't do any porta at all
    Jmp     FXStartEnd
PortaNoteStart      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 3xx - Porta to Note Down Update                        [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaNoteDnUpdate   Proc    Near
    Mov     bx, word ptr ds:SndChans.MixRate   ;BX=Current Period
    Mov     ax, ds:SndChans.MusPortaRate       ;AX=Porta Speed

PortaNoteDnUpdate2  Label   Near               ;Porta+Vol Slide entry point
    Add     bx, ax                             ;Add periods
    Cmp     bx, word ptr ds:SndChans.MixRate+2 ;Are we at the destination?
    Jl      Short @F                           ;No
PortaStop:
    Mov     bx, word ptr ds:SndChans.MixRate+2 ;Slide only to destination
    Mov     ds:SndChans.MusEffect1[di], 0      ;No more portaing
    Mov     Word PTR ds:SndChans.MixRate+2, 0  ;Don't use this destination again
@@:
    Mov     word ptr ds:SndChans.MixRate, bx   ;Save new period
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
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
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaNoteDnUpdate   EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 20xx - Porta to Note Up Update                         [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PortaNoteUpUpdate   Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;BX=Current Period
    Mov     ax, ds:SndChans.MusPortaRate       ;AX=Porta Speed

PortaNoteUpUpdate2  Label   Near               ;Porta+Vol Slide entry point
    Sub     bx, ax                             ;Subtract periods
    Jb      Short PortaStop                    ;Don't go below 0
    Cmp     bx, Word PTR ds:SndChans.MixRate+2 ;Are we at the destination?
    Jg      Short @F                           ;No
PortaStop:
    Mov     bx, Word PTR ds:SndChans.MixRate+2 ;Slide only to destination
    Mov     ds:SndChans.MusEffect1[di], 0      ;No more portaing
    Mov     Word PTR ds:SndChans.MixRate+2, 0  ;Don't use this destination again
@@:
    Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx

    Cmp     ds:SndChans.MixInc, 0              ;Is the sound ended?
    Jz      FXUpdateEnd                        ;Yeah, don't start it!

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXUpdateEnd                        ;Return to music processing
PortaNoteUpUpdate   EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 4xx - Vibrato Start                                    [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VibratoStart        Proc    Near
    Test    ah, 0Fh                            ;Is there a new depth?
    Jz      Short NewSpeed                     ;No, go look for new speed
    mov     ds:SndChans.MusVibDepth, ah        ;Save new vibrato depth
    and     ds:SndChans.MusVibDepth, 0Fh       ;Mask off speed

NewSpeed:
    Test    ah, 0F0h                           ;Is there a new speed?
    Jz      Short Exit                         ;No, go start the vibrato
    and     ah, 0F0h
    shr     ah, 2
    Mov     ds:SndChans.MusVibSpeed, ah        ;Save new speed
Exit:
    Cmp     word ptr ds:SndChans.MixRate, 0
    Jz      NoVibrato

    Jmp     FXStartEnd
NoVibrato:
    Mov     ds:SndChans.MusEffect1[di], 0      ;Don't do a vibrato if speed=0
    Jmp     FXStartEnd                         ;Return to music processing
VibratoStart        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 4xx - Vibrato Update                                   [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VibratoUpdate       Proc    Near
    mov     bl, ds:SndChans.MusVibPosition   ;Old position in vibrato
    shr     bx, 2
    and     bx, 001Fh
    movzx   cx, ds:SndChans.MusVibWave

    and     cl, 03h                     ;Only allow 0 - 3
    jz      short vib_sine              ;Is it waveform 0 (sinus)?

    shl     bl, 3                  
    cmp     cl, 1                       ;Is it waveform 1 (ramp down)?
    je      short vib_rampdown

    mov     ax, 255                     ;Assume waveform 2 (square wave).
    jmp     short vib_set

vib_rampdown:                           ;Rampdown ( |\|\|\ )
    cmp     ds:SndChans.MusVibPosition, 0
    jns     short vib_rampdown2         ;Less than zero?
    mov     ax, 255
    sub     al, bl
    jmp     short vib_set
vib_rampdown2:
    movzx   ax, bl
    jmp     short vib_set

vib_sine:                               ;Sinus ( /\/\/\/ )
    movzx   ax, [VibrateTable+bx]
;------------------
vib_set:
    mul     ds:SndChans.MusVibDepth
    shr     ax, 7
    shl     ax, 2

    mov     bx, word ptr ds:SndChans.MixRate
    cmp     ds:SndChans.MusVibPosition, 0
    js      short VibratoNeg
    add     bx, ax
    jmp     short Vibrato3
VibratoNeg:
    sub     bx, ax
Vibrato3:
    mov     al, ds:SndChans.MusVibSpeed      ;MOVE.B  n_vibratocmd(A6),D0
    sub     ds:SndChans.MusVibPosition, al   ;ADD.B   D0,n_vibratopos(A6)

    or      bx, bx                             ;Is new period zero?
    jz      FXUpdateEnd                        ;Yeah, don't apply vibrato

    mov     ax, word ptr cs:[ClockHertz]       ;Get period clock low byte hertz
    mov     dx, word ptr cs:[ClockHertz+2]     ;Get period clock high byte hertz
    div     bx

IFNDEF GUS ;******
    cmp     ds:SndChans.MixInc, 0              ;Is the sound turned off?
    jz      FXUpdateEnd                        ;yeah, we have no right to start
ENDIF
    mov     ds:SndChans.MixInc, ax             ;Save new increment speed

IFDEF GUS ;*******
    mov     dx, GUSRegAddr
    mov     bl, al                             ;Save Mixing Increment LSB

    mov     al, 1                              ;01h - GF1 Frequency Control
    out     dx, al
    inc     dx                                 ;GF1 Data LSB Port

    mov     al, bl                             ;Restore Mixing Increment LSB
    shl     ax, FreqShift
    out     dx, ax
ENDIF     ;*******
    Jmp     FXUpdateEnd                      ;RTS
VibratoUpdate       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 14xx - Fine Vibrato Update                             [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FineVibratoUpdate   Proc    Near
    mov     bl, ds:SndChans.MusVibPosition   ;MOVE.B  n_vibratopos(A6),D0
    shr     bx, 2                            ;LSR     #2,D0
    and     bx, 001Fh
    movzx   cx, ds:SndChans.MusVibWave       ;MOVE.B  n_wavecontrol(A6),D2
    and     cl, 03h                          ;AND.B   #$03,D2
    jz      short vib_sine                   ;BEQ     vib_sine
    shl     bl, 3                            ;LSL.B   #3,D0
    cmp     cl, 1                            ;CMP.B   #1,D2
    je      short vib_rampdown               ;BEQ     vib_rampdown
    mov     cl, 255                          ;MOVE.B  #255,D2
    jmp     short vib_set                    ;BRA     vib_set
vib_rampdown:
    cmp     ds:SndChans.MusVibPosition, 0    ;TST.B   n_vibratopos(A6)
    jns     short vib_rampdown2              ;BPL     vib_rampdown2
    mov     cl, 255                          ;MOVE.B  #255,D2
    sub     cl, bl                           ;SUB.B   D0,D2
    jmp     short vib_set                    ;BRA     vib_set
vib_rampdown2:
    Mov     cl, bl                           ;MOVE.B  D0,D2
    Jmp     Short vib_set                    ;BRA     vib_set
vib_sine:
    mov     cl, [VibrateTable+bx]            ;MOVE.B  (A4,D0.W),D2
vib_set:
    movzx   ax, ds:SndChans.MusVibDepth      ;MOVE.B  n_vibratocmd(A6),D0
    mul     cl                               ;MULU    D0,D2
    shr     ax, 7                            ;LSR     #7,D2

    mov     bx, word ptr ds:SndChans.MixRate ;MOVE    n_period(A6),D0
    cmp     ds:SndChans.MusVibPosition, 0    ;TST.B   n_vibratopos(A6)
    js      short VibratoNeg                 ;BMI     VibratoNeg
    add     bx, ax                           ;ADD     D2,D0
    jmp     short Vibrato3                   ;BRA     Vibrato3
VibratoNeg:
    sub     bx, ax                           ;SUB     D2,D0
Vibrato3:
    mov     al, ds:SndChans.MusVibSpeed      ;MOVE.B  n_vibratocmd(A6),D0
    add     ds:SndChans.MusVibPosition, al   ;ADD.B   D0,n_vibratopos(A6)

    Mov     ax, word ptr cs:[ClockHertz]       ;Get period clock low byte hertz
    Mov     dx, word ptr cs:[ClockHertz+2]     ;Get period clock high byte hertz
IFDEF GUS
    shr     bx, 1
ENDIF
    Or      bx, bx                             ;Is new period zero?
    Jz      FXUpdateEnd                        ;Yeah, don't apply vibrato
    Div     bx

    Cmp     ds:SndChans.MixInc, 0              ;Is the sound turned off?
    Jz      FXUpdateEnd                        ;yeah, we have no right to start

    Mov     ds:SndChans.MixInc, ax             ;Save new increment speed

IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXUpdateEnd                      ;RTS
FineVibratoUpdate   EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 5xy - Porta to Note + Volume Slide Start               [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Porta_VolStart      Proc    Near
    Or      ah, ah                             ;Is there a new slide speed?
    Jz      FXStartEnd                         ;No, make sure its not a fine slide

    Movzx   ax, ah
    Mov     ds:SndChans.MusVolRate, ax         ;Save new volume slide speed
    Jmp     FXStartEnd                         ;Return to music processing
Porta_VolStart      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 5xy - Porta to Note + Volume Slide Update              [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Porta_VolUpdate     Proc    Near

;----- First do the Volume Slide
    Mov     ax, ds:SndChans.MusVolRate         ;Get slide speeds
    Or      ah, ah                             ;Is there a slide speed?
    Jnz     Short SkipSlide                    ;No, don't do any

    Mov     ah, al                             ;Make two copies of speed
    And     ah, 0Fh                            ;AH=Down speed
    Shr     al, 4                              ;AL=Up speed
    Mov     cl, ds:SndChans.MixVolume          ;CL=Current volume

    Add     cl, al                             ;Add upspeed (x)
    Cmp     cl, 64                             ;Did we slide above 64?
    Jbe     Short @F                           ;No, go down slide down
    Mov     cl, 64                             ;Yes, set back to max
@@: Sub     cl, ah                             ;Subtract downspeed (y)
    Jnb     Short @F                           ;Did we slide below 0?
    Xor     cl, cl                             ;Yes, set back to min
@@: SetVolumeCL

;----- Now do the Porta to Note
SkipSlide:
    Mov     bx, Word PTR ds:SndChans.MixRate+2 ;Porta Note Destination
    Or      bx, bx                             ;Is there a porta destination?
    Jz      FXUpdateEnd                        ;No, so don't do porta
    Mov     dx, Word PTR ds:SndChans.MixRate   ;Current Note Period
    Or      dx, dx                             ;Is there a current period?
    Jz      FXUpdateEnd                        ;No, so don't do porta
    Cmp     dx, bx
    Je      FXUpdateEnd                        ;If dest=curr then no porta
    Jl      PortaNoteDnUpdate2                 ;If current below dest, then down
    Jmp     PortaNoteUpUpdate2                 ;If current above dest, then up
Porta_VolUpdate     EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 6xy - Vibrato + Volume Slide Start                     [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Vibrato_VolStart    Proc    Near
    Or      ah, ah                             ;Is there a new slide speed?
    Jz      Short CheckForFine                 ;No, make sure its not a fine slide

    Movzx   ax, ah
SetNewVolRate:
    Mov     ds:SndChans.MusVolRate, ax         ;Save new volume slide speed
    Xor     ax, ax
    Jmp     VibratoStart                       ;Return to music processing

CheckForFine:
    Mov     ax, ds:SndChans.MusVolRate         ;Get volume slide speed/type
    Or      ax, ax                             ;Any slide at all?
    Jnz     Short @F
    Movzx   ax, ds:SndChans.MusVibSpeed
    Shl     al, 4
    Or      al, ds:SndChans.MusVibDepth
    Test    al, 0Fh
    Jz      SetNewVolRate
    Test    al, 0F0h
    Jz      SetNewVolRate
    And     al, 0Fh
    Jmp     SetNewVolRate

@@: Or      ah, ah                             ;Type is Zero (smooth slide)?
    Jz      VibratoStart                       ;Yeah, nothing to worry about..
    Mov     ds:SndChans.MusEffect1[di], 04h    ;Don't do a volume slide if fine
    Jmp     VibratoStart
Vibrato_VolStart    EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 6xy - Vibrato + Volume Slide Update                    [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Vibrato_VolUpdate   Proc    Near
;----- First do the Volume Slide
    Mov     al, Byte PTR ds:SndChans.MusVolRate;Get slide speeds
    Mov     cl, ds:SndChans.MixVolume          ;Get current volume
    Mov     ah, al                             ;Save for down slide
    And     ah, 0Fh                            ;Down slide speed mask
    Shr     al, 4                              ;Up slide speed mask
    Or      al, al                             ;Are we sliding up?
    Jz      Short VolSlideDown                 ;If zero then slide down

VolSlideUp:
    Add     cl, al                             ;Add upspeed (x)
    Cmp     cl, 64
    Js      Short vsskip                       ;Did we slide above 64?
    Mov     cl, 64                             ;Yes, set back to max
    Jmp     Short vsskip

VolSlideDown:
    Sub     cl, ah                             ;Subtract downspeed (y)
    Jns     Short vsskip                       ;Did we slide below 0?
    Xor     cl, cl                             ;Yes, set back to min

vsskip:
    SetVolumeCL

;----- Next do the Vibrato
SkipSlide:
    Cmp     ds:SndChans.MusVibSpeed, 0         ;Is the speed zero?
    Jz      FXUpdateEnd                        ;Skip Vibrato if zero
    Jmp     VibratoUpdate                      ;Go do the Vibrato
Vibrato_VolUpdate   EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 7xx - Tremolo Start                                    [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TremoloStart        Proc    Near
    Test    ah, 0Fh                            ;Is there a new depth?
    Jz      Short NewSpeed                     ;No, go look for new speed
    Mov     bl, ah                             ;Yes, save it
    And     bl, 0Fh                            ;Mask off speed
    Mov     ds:SndChans.MusTrmDepth, bl        ;Save new vibrato depth
NewSpeed:
    Test    ah, 0F0h                           ;Is there a new speed?
    Jz      Short Exit                         ;No, go start the vibrato
    Mov     bl, ah                             ;Yes, save it
    And     bl, 0F0h                           ;Mask off depth
    Shr     bl, 2                              ;Multiply speed by 4
    Mov     ds:SndChans.MusTrmSpeed, bl        ;Save new speed
Exit:
    Cmp     ds:SndChans.MusTrmSpeed, 0         ;Is the speed zero?
    Jnz     FXStartEnd                         ;Do music processing if nonzero
    Mov     ds:SndChans.MusEffect1[di], 0      ;Don't do a vibrato if speed=0
    Jmp     FXStartEnd                         ;Return to music processing
TremoloStart        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 7xx - Tremolo Update                                   [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TremoloUpdate       Proc    Near
    Mov     al, ds:SndChans.MusTrmPosition   ;MOVE.B  n_tremolopos(A6),D0
    Mov     bx, Offset VibrateTable          ;LEA     VibratoTable(PC),A4
    Shr     al, 2
    And     ax, 001Fh                        ;AND     #$001F,D0
    Xor     cx, cx                           ;MOVEQ   #0,D2
    Mov     cl, ds:SndChans.MusTrmWave       ;MOVE.B  n_wavecontrol(A6),D2
    And     cl, 03h                          ;AND.B   #$03,D2
    Jz      Short tre_sine                   ;BEQ     tre_sine
    Shl     al, 3                            ;LSL.B   #3,D0
    Cmp     cl, 1                            ;CMP.B   #1,D2
    Je      Short tre_rampdown               ;BEQ     tre_rampdown
    Mov     cl, 255                          ;MOVE.B  #255,D2
    Jmp     Short tre_set                    ;BRA     tre_set
tre_rampdown:
    Cmp     ds:SndChans.MusTrmPosition, 0    ;TST.B   n_vibratopos(A6)
    Jns     Short tre_rampdown2              ;BPL     tre_rampdown2
    Mov     cl, 255                          ;MOVE.B  #255,D2
    Sub     cl, al                           ;SUB.B   D0,D2
    Jmp     Short tre_set                    ;BRA     tre_set
tre_rampdown2:
    Mov     cl, al                           ;MOVE.B  D0,D2
    Jmp     Short tre_set                    ;BRA     tre_set
tre_sine:
    Add     bx, ax                           ;;;(a4,d0.w)
    Mov     cl, cs:[bx]                      ;MOVE.B  0(A4,D0.W),D2
tre_set:
    Mov     al, ds:SndChans.MusTrmDepth      ;MOVE.B  n_tremolocmd(A6),D0
    Mul     cl                               ;MULU    D0,D2
    Shr     ax, 6                            ;LSR     #6,D2
    Mov     cx, ax
    ;Xor     ax, ax                          ;MOVEQ   #0,D0
    Movzx   ax, ds:SndChans.MixVolume        ;MOVE.B  n_volume(A6),D0
    Cmp     ds:SndChans.MusTrmPosition, 0    ;TST.B   n_tremolopos(A6)
    Js      Short TremoloNeg                 ;BMI     TremoloNeg
    Add     ax, cx                           ;ADD     D2,D0
    Jmp     Short Tremolo3                   ;BRA     Tremolo3
TremoloNeg:
    Sub     ax, cx                           ;SUB     D2,D0
Tremolo3:
    Jns     Short TremoloSkip                ;BPL     TremoloSkip
    Xor     ax, ax                           ;CLR     D0
TremoloSkip:
    Cmp     ax, 40h                          ;CMP     #$40,D0
    Jl      Short TremoloOk                  ;BLS     TremoloOk
    Mov     ax, 40h                          ;MOVE    #$40,D0

TremoloOk:
    Mov     cl, al
    Shr     cl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, cl            ;Save new vumeter

    Mul     MusicVol                           ;Multiply by master volume
    Shr     ax, 6                              ;Divide by 64
    Mov     cl, al                             ;Save new relative volume
    Mov     ds:SndChans.MixMonoVol, cl

    Movzx   bx, ds:SndChans.MixPanning
    Movzx   ax, Byte PTR [xPanTableRight+bx]
RightCalc:
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Right Volume
    Mov     ds:SndChans.MixRgtVol, al
LeftCalc:
    Movzx   ax, Byte PTR [PanTableLeft+bx]
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Left Volume
    Mov     ds:SndChans.MixLftVol, al

    Mov     al, ds:SndChans.MusTrmSpeed      ;MOVE.B  n_vibratocmd(A6),D0
    And     ax, 003Ch                        ;AND     #$003C,D0
    Add     ds:SndChans.MusTrmPosition, al   ;ADD.B   D0,n_tremolopos(A6)

    Jmp     FXUpdateEnd                      ;RTS
TremoloUpdate       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 9xx - Sample Offset                                    [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SampleOffset        Proc    Near
    Xor     al, al                             ;Clear AL, AX=xx00h
    Mov     ds:SndChans.MixOff, ax             ;Save new sample offset
IFDEF GUS ;********
    Movzx   eax, ds:SndChans.MixOff
    Add     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax
ENDIF     ;********

    Jmp     FXStartEnd                         ;Return to music processing
SampleOffset        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Axy - Volume Slide Start                               [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VolSlideStart       Proc    Near
    Or      ah, ah                             ;Is there a new slide speed?
    Jz      Short CheckForFine                 ;No, make sure its not a fine slide

    Movzx   ax, ah
    Mov     ds:SndChans.MusVolRate, ax         ;Save new volume slide speed
    Jmp     FXStartEnd                         ;Return to music processing

CheckForFine:
    Mov     ax, ds:SndChans.MusVolRate         ;Get volume slide speed/type
    Or      ah, ah                             ;Type is Zero (smooth slide)?
    Jz      FXStartEnd                         ;Yeah, nothing to worry about..
    Mov     ds:SndChans.MusEffect1[di], 0Eh    ;Don't do a smooth slide if fine
    Movzx   ebx, ah
    Mov     ah, al                             ;Fine slide, go fix up..
    Shl     bl, 4                              ;Move over fine type
    Add     bl, al
    Mov     Byte PTR ds:SndChans.MusEffDat1[di], bl
    Shr     bx, 4
    And     ah, 0Fh                            ;Mask off effect number
    Jmp     cs:[FXExtended+ebx*2]
VolSlideStart       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Axy - Volume Slide Update                              [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VolSlideUpdate      Proc    Near
    Mov     al, Byte PTR ds:SndChans.MusVolRate;Get slide speeds
    Mov     cl, ds:SndChans.MixVolume          ;Get current volume
    Mov     ah, al                             ;Save for down slide
    And     ah, 0Fh                            ;Down slide speed mask
    Shr     al, 4                              ;Up slide speed mask
    Or      al, al                             ;Are we sliding up?
    Jz      Short VolSlideDown                 ;If zero then slide down

VolSlideUp:
    Add     cl, al                             ;Add upspeed (x)
    Cmp     cl, 64
    Js      Short vsskip                       ;Did we slide above 64?
    Mov     cl, 64                             ;Yes, set back to max
    Jmp     Short vsskip

VolSlideDown:
    Sub     cl, ah                             ;Subtract downspeed (y)
    Jns     Short vsskip                       ;Did we slide below 0?
    Xor     cl, cl                             ;Yes, set back to min

vsskip:
    SetVolumeCL
    Jmp     FXUpdateEnd                        ;Return to music processing
VolSlideUpdate      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Bxx - Order Jump                                       [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
OrderJump           Proc    Near
    Cmp     PattJump, 0                        ;Are we allowed to jump?
    Jnz     FXStartEnd                         ;Nope, exit

    Push    es                                 ;Preserve ES
    Movzx   bx, ah                             ;Make pointer for our table
    Cmp     ah, NOOrders                       ;Attempt to jump beyond limit?
    Jbe     Short @F                           ;No, do the jump
    Xor     bx, bx                             ;Yeah, loop back to first order

@@: Cmp     bl, PlayOrder                      ;Are we going backward in table?
    Ja      Short @F
    Inc     MusicLpCount                       ;Increment loop count
    Cmp     MusicLpStatus, 0                   ;Are we allowed to loop?
    Jnz     Short @F                           ;If non zero, yeah
    Mov     MusicStatus, 0                     ;If zero, no, so disable music
@@: Mov     PlayOrder, bl                      ;Save new order number
    Movzx   ebx, cs:[OrderTable+bx]            ;Look up pattern in order table
    Mov     PlayPattern, bl                    ;Save new pattern number
    Lea     ebx, [ebx*2]                       ;Multiply by two for tables
    Mov     ax, cs:[PatSegTable+bx]            ;Get segment of new pattern
    Mov     PlaySeg, ax                        ;Save new pattern segment
    Mov     es, ax                             ;Get ready to access new pattern
    Mov     ax, es:[0]                         ;Get length of new pattern
    Mov     PlayLen, ax                        ;Save length of new pattern
    Mov     PlayRow, 0FFh                      ;Back to row 0
    Mov     PlayOff, 2                         ;Save play offset
    Pop     es                                 ;Restore ES
    Mov     PattJump, 1
    Mov     PattLoopOff, 0                     ;Reset pattern loop location
    Jmp     FXStartEnd                         ;Return to music processing
OrderJump           EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Cxx - Set Volume                                       [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetVolume           Proc    Near
    Mov     cl, ah
    Cmp     cl, 64                             ;Setting above 64?
    Jbe     Short @F                           ;Jump if not
    Mov     cl, 64                             ;Yes, set back to max.
@@: SetVolumeCL
    Jmp     FXStartEnd                         ;Return to music processing
SetVolume           EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Dxx - Pattern Break                                    [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TempRow     db      0
PatternBreak        Proc    Near
    Cmp     PattJump, 0                ;Are we allowed to do any jumps?
    Jnz     FXStartEnd                 ;Exit if not.

    Mov     cl, ah                     ;Convert HEX->DEC
    Movzx   ax, ah
    Shr     ax, 4
    Mov     bl, 10
    Mul     bl
    And     cl, 0Fh
    Add     al, cl

    Push    es                         ;Preserve ES
    Push    esi
    Push    ecx

    Movzx   bx, PlayOrder              ;Increment the playing Order
    Inc     bl
    Cmp     bl, NOOrders               ;Are we past the last order?
    Jbe     Short @F                   ;No, go do it

    Xor     bx, bx                     ;Yeah, loop back to first order
    Inc     MusicLpCount               ;Increment loop count
    Cmp     MusicLpStatus, 0           ;Are we allowed to loop?
    Jnz     Short @F                   ;If non zero, yeah
    Mov     MusicStatus, 0             ;If zero, no, so disable music

@@: Mov     PlayOrder, bl              ;Save new order number
    Movzx   ebx, cs:[OrderTable+bx]    ;Look up pattern in order table
    Mov     PlayPattern, bl            ;Save new pattern number
    Lea     ebx, [ebx*2]               ;Multiply by two for tables
    Mov     bx, cs:[PatSegTable+bx]    ;Get segment of new pattern
    Mov     PlaySeg, bx                ;Save new pattern segment
    Mov     es, bx                     ;Get ready to access new pattern
    Mov     bx, es:[0]                 ;Get length of new pattern
    Mov     PlayLen, bx                ;Save length of new pattern

    Mov     PlayRow, al                ;Back to row right
    Mov     si, 2                      ;First row offset
    Or      al, al
    Jz      Short SaveNewOff
    Mov     TempRow, 0

ChannelLoop:
    Mov     ch, es:[si]                ;Get the event specification byte
    Inc     si                         ;Update pointer
    Or      ch, ch                     ;Is it 0?
    Jz      Short RowComplete          ;If so, we're done, exit channel loop

; Note/Sample Event Ü ;
;  ßßßßßßßßßßßßßßßßßß ;
BeginNSEvent:
    Test    ch, 32                     ;Is there a note event?
    Jz      Short BeginEffectEvent     ;No, check for effects
    Add     si, 2                      ;Skip past note and instrument

; Effect Events Ü ;
;  ßßßßßßßßßßßßßß ;
BeginEffectEvent:
    Test    ch, 64                     ;Is there an Effect event?
    Jz      ChannelLoop                ;No, check for end of row
MoreEffecT:
    Mov     al, es:[si]                ;Yes, get the effect number
    Add     si, 2                      ;Update pointer and skip effect data
    Test    al, 32                     ;Is there another effect?
    Jnz     MoreEffecT

EndChannelLoop:
    Jmp     ChannelLoop

RowComplete:
    Inc     TempRow
    Mov     al, TempRow
    Cmp     al, PlayRow
    Jb      ChannelLoop

SaveNewOff:
    Mov     PlayOff, si                ;Save play offset
    Dec     PlayRow

    Pop     ecx
    Pop     esi
    Pop     es                         ;Restore ES
    Mov     PattJump, 1
    Mov     PattLoopOff, 0             ;Reset pattern loop location

    Jmp     FXStartEnd                 ;Return to music processing
PatternBreak        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Exx - Extended Effects                                 [S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ExtendedStart1      Proc    Near
    Mov     Byte PTR ds:SndChans.MusEffDat1[di], ah ;Save effect data+number
    Movzx   ebx, ah                             ;Setup bx for jump pointer
    Shr     bx, 4
    And     ah, 0Fh                            ;Mask off effect number
    Jmp     cs:[FXExtended+ebx*2]
ExtendedStart1      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E1x - Fine Porta Up                                    [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FinePortaUp         Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Movzx   eax, ah                            ;Get ready for quarter period mul
    Lea     eax, [eax*4]                       ;Quarter period multiply
    Sub     bx, ax                             ;Subtract number of periods
    Cmp     bx, 452                            ;Did we slide above B-5?
    Ja      Short @F
    Mov     bx, 452                            ;Yes, set back to min
@@: Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period
    Mov     Word PTR ds:SndChans.MixRate+2, 0
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx
    Cmp     ds:SndChans.MixInc, 0              ;Is the sound ended?
    Jz      FXStartEnd                         ;Yeah, don't start it!

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXStartEnd                         ;Return to music processing
FinePortaUp         EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E2x - Fine Porta Down                                  [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FinePortaDown       Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Movzx   eax, ah                            ;Get ready for quarter period mul
    Lea     eax, [eax*4]                       ;Quarter period multiply
    Add     bx, ax                             ;Add number of periods
    Cmp     bx, 3424                           ;Did we slide below C-3?
    Jb      Short @F
    Mov     bx, 3424                           ;Yes, set back to max
@@: Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period
    Mov     Word PTR ds:SndChans.MixRate+2, 0
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx
    Cmp     ds:SndChans.MixInc, 0              ;Is the sound ended?
    Jz      FXStartEnd                         ;Yeah, don't start it!

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXStartEnd                         ;Return to music processing
FinePortaDown       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E4x - Set Vibrato Waveform                             [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetVibraWave        Proc    Near
    Mov     ds:SndChans.MusVibWave, ah
    Jmp     FXStartEnd                         ;Return to music processing
SetVibraWave        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E5x - Set Finetune                                     [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetFinetune         Proc    Near
    Push    ecx                                ;Preserve CH
    Movzx   ebx, ah                            ;Set up BX for look up table
    Mov     cx, [FineTune+ebx*2]               ;Loop up C-4 Hz in table
    Mov     ds:SndChans.MixFinetune, cx        ;Divide calculate by finetune

    Movzx   ebx, ds:SndChans.MusNote
    Mov     ax, [PeriodTable+ebx*2]            ;Lookup period value
    Mov     cl, ds:SndChans.MusOctave
    And     cl, 7                              ;Mask off upper bit
    Shr     ax, cl                             ;Divide by octave

    mov     bx, 8363                           ;C4 Hertz
    mul     bx

    Mov     bx, ds:SndChans.MixFinetune        ;Divide calculate by finetune
    Div     bx
    Mov     bx, ax                             ;Save period in bx
    Mov     Word PTR ds:SndChans.MixRate, bx
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx
    Pop     ecx

    Cmp     ds:SndChans.MixInc, 0
    Jz      FXStartEnd

    Mov     ds:SndChans.MixInc, ax
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Mov     ds:SndChans.MixIncRemain, 0
    Jmp     FXStartEnd
SetFinetune         EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E6x - Pattern Loop                                     [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StartPatternLoop    Proc    Near
    Or      ah, ah                     ;Are we setting loop start?
    Jz      Short SetLoopStart

    Cmp     LoopCounter, 0             ;Is this first time loop?
    Jz      Short SetLoopCount

    Cmp     PattJump, 0                ;Are we allowed to do jumps?
    Jnz     FXStartEnd

    Dec     LoopCounter                ;Decrement loop counter
    Jz      FXStartEnd                 ;If zero then no loop now..

SetNewPosition:
    Mov     ax, PattLoopOff
    Or      ax, ax                     ;Is there a loop start location?
    Jz      FXStartEnd                 ;No, skip pattern loop if no where to go

    Mov     PlayOff, ax                ;Save play offset
    Mov     al, PattLoop               ;Set new pattern row location variables
    Dec     al
    Mov     PlayRow, al                ;Set row counter

    Mov     PattJump, 1                ;No more jumps for us
    Jmp     FXStartEnd

SetLoopStart:
    Mov     ax, CurrentOff
    Mov     PattLoopOff, ax
    Mov     al, PlayRow
    Mov     PattLoop, al
    Jmp     FXStartEnd

SetLoopCount:
    Mov     LoopCounter, ah
    Jmp     SetNewPosition
StartPatternLoop    EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E7x - Set Tremolo Waveform                             [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetTremoWave        Proc    Near
    Mov     ds:SndChans.MusTrmWave, ah
    Jmp     FXStartEnd                         ;Return to music processing
SetTremoWave        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E8x - Extra Fine Porta Up                              [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ExtraFinePortaUp    Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Movzx   ax, ah
    Sub     bx, ax                             ;Subtract number of periods
    Cmp     bx, 113                            ;Did we slide too high?
    Ja      Short @F
    Mov     bx, 113                            ;Yes, set back to min
@@: Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx
    Cmp     ds:SndChans.MixInc, 0
    Jz      FXStartEnd

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXStartEnd                         ;Return to music processing
ExtraFinePortaUp    EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect E9x - Extra Fine Porta Down                            [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ExtraFinePortaDwn   Proc    Near
    Mov     bx, Word PTR ds:SndChans.MixRate   ;Save period in bx
    Movzx   ax, ah                             ;Save porta speed in ax
    Add     bx, ax                             ;Add number of periods
    Cmp     bx, 27392                          ;Did we slide too low?
    Jb      Short @F                           ;No, go do the porta
    Mov     bx, 27392
@@: Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period value
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx                                 ;Calculate new sample increment
    Cmp     ds:SndChans.MixInc, 0
    Jz      FXStartEnd

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXStartEnd                         ;Return to music processing
ExtraFinePortaDwn   EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EAx - Fine Volume Slide Up                      (PT ST)[D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FineVolumeUp        Proc    Near
    Or      ah, ah
    Jnz     Short SaveSlideRate

    Mov     ah, Byte PTR ds:SndChans.MusVolRate    ;Get old speed

SaveSlideRate:
    Mov     Byte PTR ds:SndChans.MusVolRate, ah    ;Save speed
    Mov     Byte PTR ds:SndChans.MusVolRate+1, 0Ah ;Save type: Fine Vol Up

    Mov     al, ds:SndChans.MixVolume          ;Get current channel volume
    Add     al, ah                             ;Slide the volume up
    Cmp     al, 64                             ;Did we slide past 64 (max)?
    Jbe     Short @F
    Mov     al, 64                             ;Yes, set back to max
@@: Mov     cl, al
    SetVolumeCL
    Jmp     FXStartEnd                         ;Return to music processing
FineVolumeUp        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EBx - Fine Volume Slide Down                    (PT ST)[D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FineVolumeDown      Proc    Near
    Or      ah, ah
    Jnz     Short SaveSlideRate

    Mov     ah, Byte PTR ds:SndChans.MusVolRate    ;Get old speed

SaveSlideRate:
    Mov     Byte PTR ds:SndChans.MusVolRate, ah    ;Save speed
    Mov     Byte PTR ds:SndChans.MusVolRate+1, 0Bh ;Save type: Fine Vol Up

    Mov     al, ds:SndChans.MixVolume          ;Get current channel volume
    Sub     al, ah                             ;Slide the volume down
    Jnb     Short @F                           ;Did we slide past 0 (min)?
    Xor     al, al                             ;Yes, set back to min
@@: Mov     cl, al
    SetVolumeCL
    Jmp     FXStartEnd                         ;Return to music processing
FineVolumeDown      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect ECxx - Note Cut Start                     (PT HT MT ST)[S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NoteCutStart        Proc    Near
    Mov     Byte PTR ds:SndChans.MusEffDat1[di], ah
    Mov     ds:SndChans.MusEffect1[di], 21h
    Jmp     FXStartEnd
NoteCutStart        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 21xx - Note Cut Update                    (PT HT MT ST)[D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NoteCutUpdate       Proc    Near
    Mov     al, TempoCounter
    Inc     al
    Cmp     Byte PTR ds:SndChans.MusEffDat1[di], al
    Jne     FXUpdateEnd
IFDEF GUS ;********
    Mov     dx, GUSRegAddr
    Mov     al, 9                              ;09h - GF1 Current Volume
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port
    Mov     ax, [GUSVolTable]
    Out     dx, ax
    GF1_Delay
    Out     dx, ax
ELSE      ;********
    Mov     ds:SndChans.MixVolume, 0
    Mov     ds:SndChans.MixMonoVol, 0
    Mov     ds:SndChans.MixRgtVol, 0
    Mov     ds:SndChans.MixLftVol, 0
ENDIF     ;********
    Jmp     FXUpdateEnd
NoteCutUpdate       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EDxx - Note Delay Start                   (PT HT MT ST)[S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NoteDelayStart      Proc    Near
    Mov     Byte PTR ds:SndChans.MusEffDat1[di], ah
    Mov     ds:SndChans.MusEffect1[di], 22h
    Jmp     FXStartEnd
NoteDelayStart      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EDxx - Note Delay Update                  (PT HT MT ST)[D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NoteDelayUpdate     Proc    Near
    Mov     al, TempoCounter                   ;Are we on the right
    Inc     al
    Cmp     Byte PTR ds:SndChans.MusEffDat1[di], al     ;frame?
    Ja      FXUpdateEnd

    Mov     bx, Word PTR ds:SndChans.MixRate+2 ;Get new period
    Or      bx, bx                             ;Is there actually a new period?
    Jz      FXUpdateEnd                        ;No, don't do retrig

    Mov     Word PTR ds:SndChans.MixRate+2, 0  ;Don't use period for Porta Note
    Mov     Word PTR ds:SndChans.MixRate, bx   ;Save new period

    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock LSB hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock MSB hertz
    Div     bx

    Mov     ds:SndChans.MixInc, ax             ;Save new sample increment
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax

;ÄÄ Set Current Channel Location
    Mov     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax

;ÄÄ Tell GF1 to Turn up the Voice
    Mov     dx, GUSRegAddr
    Xor     al, al                     ;00h - Voice Control Register
    Out     dx, al
    Add     dx, 2
    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al

    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al
ENDIF     ;*******

    Mov     ds:SndChans.MixIncRemain, 0
    Mov     ds:SndChans.MixOff, 0
    Mov     al, ds:SndChans.MixVolume          ;Save new music volume
    Shr     al, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, al            ;Save new vumeter

    Jmp     FXUpdateEnd
NoteDelayUpdate     EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EExx - Pattern Delay                                   [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PatternDelay        Proc    Near
    Mov     bl, Tempo
    Movzx   ax, ah
    Mul     bl
    Sub     bl, al
    Mov     TempoCounter, bl
    Jmp     FXStartEnd
PatternDelay        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect EFx - Invert Loop (Funk It)                           [SD OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                    0 1 2 3 4 5  6  7  8  9  A  B  C  D  E   F  ; Spd->RealSpd
FunkTable       db   0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128 ; Lookup Table

StartFunkIt         Proc    Near
IFDEF GUS
    Jmp     FXStartEnd                      ;No, don't do it...
ELSE
    Mov     ds:SndChans.MusGlissFunk, ah
    Mov     ds:SndChans.MusEffect1[di], 0   ;Default no funk

    Or      ah, ah                          ;Is there a funk?
    Jz      FXStartEnd                      ;No, don't do it...
    Mov     ds:SndChans.MusEffect1[di], 23h ;Set up update Funk It

    Movzx   bx, ds:SndChans.MusGlissFunk    ;Get the funk speed
    Or      bl, bl
    Jz      FXStartEnd                      ;If funk speed=0, don't do a funk

    Mov     al, cs:[FunkTable+bx]           ;Look up real funk speed in table
    Add     ds:SndChans.MusFunkOffset, al   ;Update funk position
    Cmp     ds:SndChans.MusFunkOffset, 128  ;Ready to funk a byte?
    Jb      FXStartEnd                      ;Nope, don't do anything

    Mov     ds:SndChans.MusFunkOffset, 0    ;Reset

    Mov     bx, ds:SndChans.MusWaveStart
    Inc     bx                              ;Update funk pointer
    Cmp     bx, ds:SndChans.MixLEnd         ;Updated beyond end?
    Jb      funkok
    Mov     bx, ds:SndChans.MixLBeg         ;Yeah, loop to loop beginning
funkok:
    Mov     ds:SndChans.MusWaveStart, bx    ;Save new funk pointer

    Push    es
    Mov     al, ds:SndChans.MixHandle           ;Is the sample in EMS memory?
    Or      al, al
    Jz      NoEMS                               ;No

    Push    edx
    Movzx   dx, al
    Mov     bx, ds:SndChans.MixSeg
    Mov     ax, 4400h
    Int     67h
    Inc     bx
    Mov     ax, 4401h
    Int     67h
    Inc     bx
    Mov     ax, 4402h
    Int     67h
    Inc     bx
    Mov     ax, 4403h
    Int     67h

    Mov     es, EmsPageSeg
    Pop     edx
    Jmp     Short YesEMS

NoEMS:
    Mov     es, ds:SndChans.MixSeg          ;Put sound segment into AX
YesEMS:
    Mov     bx, ds:SndChans.MusWaveStart    ;Get new funk pointer

    Xor     al, al
    Sub     al, Byte PTR es:[bx]
    Mov     Byte PTR es:[bx], al
    Pop     es
    Jmp     FXStartEnd
ENDIF
StartFunkIt         EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 23x - Invert Loop (Funk It)                            [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
UpdateFunkIt        Proc    Near
IFDEF GUS
ELSE
    Movzx   bx, ds:SndChans.MusGlissFunk    ;Get the funk speed
    Or      bl, bl
    Jz      FXUpdateEnd                     ;If funk speed=0, don't do a funk

    Mov     al, cs:[FunkTable+bx]           ;Look up real funk speed in table
    Add     ds:SndChans.MusFunkOffset, al   ;Update funk counter
    Cmp     ds:SndChans.MusFunkOffset, 128  ;Ready to funk a byte?
    Jb      FXUpdateEnd                     ;Nope, don't do anything

    Mov     ds:SndChans.MusFunkOffset, 0    ;Reset

    Mov     bx, ds:SndChans.MusWaveStart
    Inc     bx                              ;Update funk pointer
    Cmp     bx, ds:SndChans.MixLEnd         ;Updated beyond end?
    Jb      funkok
    Mov     bx, ds:SndChans.MixLBeg         ;Yeah, loop to loop beginning
funkok:
    Mov     ds:SndChans.MusWaveStart, bx    ;Save new funk pointer

    Push    es
    Mov     al, ds:SndChans.MixHandle           ;Is the sample in EMS memory?
    Or      al, al
    Jz      NoEMS                               ;No

    Movzx   dx, al
    Mov     bx, ds:SndChans.MixSeg
    Mov     ax, 4400h
    Int     67h
    Inc     bx
    Mov     ax, 4401h
    Int     67h
    Inc     bx
    Mov     ax, 4402h
    Int     67h
    Inc     bx
    Mov     ax, 4403h
    Int     67h

    Mov     es, EmsPageSeg
    Jmp     Short YesEMS

NoEMS:
    Mov     es, ds:SndChans.MixSeg          ;Put sound segment into AX
YesEMS:
    Mov     bx, ds:SndChans.MusWaveStart    ;Get new funk pointer

    Xor     al, al
    Sub     al, Byte PTR es:[bx]
    Mov     Byte PTR es:[bx], al
    Pop     es
ENDIF
    Jmp     FXUpdateEnd
UpdateFunkIt        EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect Fxx - Set Tempo                           (PT HT MT ST)[D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetTempo            Proc    Near
    Or      ah, ah                             ;Is Tempo 0 (end sound)?
    Jnz     Short @F                           ;No, go set it
    Mov     MusicStatus, 0                     ;Yes, stop song playback
    Jmp     FXStartEnd                         ;Return to music processing
@@: Mov     Tempo, ah                          ;Save new Tempo
    Jmp     FXStartEnd                         ;Return to music processing
SetTempo            EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 10xy - Arpeggio                           (PT HT MT ST)[S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ArpeggioStart       Proc    Near
    Or      ah, ah
    Jnz     Short @F
    Mov     ah, ds:SndChans.MusArpeggio[di]
@@: Mov     Byte PTR ds:SndChans.MusEffDat1[di], ah
    Mov     ds:SndChans.MusArpeggio[di], ah
    Jmp     FXStartEnd
ArpeggioStart       EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 10xy - Arpeggio                           (PT HT MT ST)[D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ArpeggioUpdate      Proc    Near
    Xor     esi, esi
    Xor     cl, cl
    Cmp     Word PTR ds:SndChans.MixRate, 0
    Jz      FXUpdateEnd
FindNoteLoop:
    Mov     ax, [PeriodTable+esi*2]               ;Lookup period value
    Shr     ax, cl                                ;Divide by octave

    mov     bx, 8363                              ;C4 Hertz
    mul     bx

    Mov     bx, ds:SndChans.MixFinetune
    Div     bx                                    ;Divide by finetune
    Cmp     ax, word ptr ds:SndChans.MixRate
    Jbe     Short FoundOurNote
    Inc     si
    Cmp     si, 11
    Jbe     FindNoteLoop
    Xor     esi, esi
    Inc     cl
    Cmp     cl, 7
    Ja      FXUpdateEnd
    Jmp     FindNoteLoop

FoundOurNote:
    Movzx   ax, TempoCounter           ;Get frame number
    Inc     ax
    Mov     bl, 3
    Div     bl                         ;Divide by 3 - Get tick number

    Movzx   ebx, si
    Mov     al, Byte PTR ds:SndChans.MusEffDat1[di]

    Cmp     ah, 2                      ;Tick 2?
    Je      Short Arpeggio2
    Cmp     ah, 1                      ;Tick 1?
    Jz      Short Arpeggio1
Arpeggio0:
    Jmp     Short ArpeggioSet
Arpeggio1:
    Shr     al, 4
    Add     bl, al
    Cmp     bl, 11
    Jbe     Short ArpeggioSet
    Sub     bl, 12
    Inc     cl
    Jmp     Short ArpeggioSet
Arpeggio2:
    And     al, 0Fh
    Add     bl, al
    Cmp     bl, 11
    Jbe     Short ArpeggioSet
    Sub     bl, 12
    Inc     cl
ArpeggioSet:
    Cmp     cl, 7
    Jbe     Short @F
    Mov     cl, 7
@@: Cmp     bl, 11
    Jbe     Short @F
    Mov     bl, 11
@@: Mov     ax, [PeriodTable+ebx*2]            ;Get period value
    Shr     ax, cl                             ;Divide by octave

    mov     bx, 8363                           ;C4 Hertz Finetune
    mul     bx

    Mov     bx, ds:SndChans.MixFinetune        ;Divide calculate by finetune
    Div     bx
    Mov     bx, ax                             ;Save period in bx
    Mov     ax, Word PTR cs:[ClockHertz]       ;Get the period clock low byte hertz
    Mov     dx, Word PTR cs:[ClockHertz+2]     ;Get the period clock high byte hertz
    Div     bx

    Cmp     ds:SndChans.MixInc, 0      ;Is this channel on?
    Jz      FXUpdateEnd                ;Don't start if it's off

    Mov     ds:SndChans.MixInc, ax
IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, FreqShift ;2
    Out     dx, ax
ENDIF     ;*******
    Jmp     FXUpdateEnd
ArpeggioUpdate      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 12xx - Retrigger Note+Volume Slide Start  (PT HT MT ST)[S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RetrigNoteStart     Proc    Near
    Or      ah, ah
    Jz      Short NoNewRetrig
    Mov     al, ah
    Shr     al, 4                              ;Get volume slide
    And     ah, 0Fh                            ;Is the retrigger speed 0?
    Mov     ds:SndChans.MusRetrigSpeed, ah     ;Save new retrigger speed
    Mov     ds:SndChans.MusRetrigSlide, al     ;Save new retrigger slide rate

NoNewRetrig:
    Test    ch, 32                             ;Was there a note/sample event?
    Jnz     FXStartEnd                         ;Yeah, not continuing a retrig..

    Mov     cl, ds:SndChans.MixVolume          ;Get music volume
    Shr     cl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, cl            ;Save new vumeter

    Mov     ds:SndChans.MixIncRemain, 0        ;Reset increment remainder
    Mov     ds:SndChans.MixOff, 0              ;Reset sample offset
IFDEF GUS ;********
    Mov     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax

;ÄÄ Tell GF1 to Start Channel!
    Mov     dx, GUSRegAddr
    Xor     al, al                     ;00h - Voice Control Register
    Out     dx, al
    Add     dx, 2
    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al

    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al
ENDIF     ;********

    Movzx   bx, ds:SndChans.MusRetrigSlide     ;Get slide speeds
    Or      bl, bl
    Jz      FXStartEnd
    Mov     cl, ds:SndChans.MixVolume          ;Get current volume

    Cmp     bl, 5
    Jbe     Short VolSlideDown
    Cmp     bl, 6
    Jbe     Short VolSlideTwoThird
    Cmp     bl, 7
    Jbe     Short VolSlideHalf
    Cmp     bl, 0Dh
    Jbe     Short VolSlideUp
    Cmp     bl, 0Eh
    Jbe     Short VolSlideThreeHalf

VolSlideTwice:
    Shl     cl, 1                      ;Multiply vol*2
    Cmp     cl, 64
    Jbe     Short vsskip               ;Slide above 64?
    Mov     cl, 64                     ;Set back down
    Jmp     Short vsskip

VolSlideThreeHalf:
    Movzx   eax, cl
    Lea     eax, [eax*2+eax]           ;Multiply vol*3
    Shr     ax, 1                      ;Divide vol\2
    Mov     cl, al
    Cmp     cl, 64
    Jbe     Short vsskip
    Mov     cl, 64
    Jmp     Short vsskip

VolSlideUp:
    Mov     al, cs:[bx+RetrigSlideTable-8] ;Get slide speed
    Add     cl, al                     ;Add upspeed (x)
    Cmp     cl, 64
    Js      Short vsskip               ;Did we slide above 64?
    Mov     cl, 64                     ;Yes, set back to max
    Jmp     Short vsskip

VolSlideHalf:
    Shr     cl, 1                      ;Divide vol\2
    Jmp     Short vsskip

VolSlideTwoThird:
    Movzx   eax, cl
    Lea     eax, [eax*2]               ;Multiply vol*2
    Mov     bl, 3
    Div     bl                         ;Divide vol(ax)\3
    Mov     cl, al
    Jmp     Short vsskip

VolSlideDown:
    Mov     al, Byte PTR cs:[RetrigSlideTable+bx]
    Sub     cl, al                     ;Subtract downspeed (y)
    Jns     Short vsskip               ;Did we slide below 0?
    Xor     cl, cl                     ;Yes, set back to min
    Jmp     Short vsskip

vsskip:
    SetVolumeCL
    Jmp     FXStartEnd
RetrigNoteStart     EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 12xx - Retrigger Note+Volume Slide Update              [D OF]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RetrigSlideTable    db      0,1,2,4,8,16       ;Table for Retrig volume slides

RetrigNoteUpdate    Proc    Near
    Movzx   ax, TempoCounter
    Inc     ax
    Mov     cl, ds:SndChans.MusRetrigSpeed     ;Is retrigger speed 0?
    Or      cl, cl
    Jz      FXUpdateEnd
    Div     cl                                 ;Are we at the right tick?
    Or      ah, ah                             ;If remainder, then wrong tick
    Jnz     FXUpdateEnd

    Mov     cl, ds:SndChans.MixVolume          ;Get music volume
    Shr     cl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, cl            ;Save new vumeter

    Mov     ds:SndChans.MixIncRemain, 0        ;Reset increment remainder
    Mov     ds:SndChans.MixOff, 0              ;Reset sample offset
IFDEF GUS ;********
    Mov     eax, ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     TempLoc, eax
    Mov     dx, GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax

;ÄÄ Tell GF1 to Start Channel!
    Mov     dx, GUSRegAddr
    Xor     al, al                     ;00h - Voice Control Register
    Out     dx, al
    Add     dx, 2
    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al

    Mov     al, ds:SndChans.MixFlags
    And     al, 1
    Shl     al, 3
    Out     dx, al
    GF1_Delay
    Out     dx, al
ENDIF     ;********

    Movzx   bx, ds:SndChans.MusRetrigSlide     ;Get slide speeds
    Or      bl, bl
    Jz      FXUpdateEnd
    Mov     cl, ds:SndChans.MixVolume          ;Get current volume

    Cmp     bl, 5
    Jbe     Short VolSlideDown
    Cmp     bl, 6
    Jbe     Short VolSlideTwoThird
    Cmp     bl, 7
    Jbe     Short VolSlideHalf
    Cmp     bl, 0Dh
    Jbe     Short VolSlideUp
    Cmp     bl, 0Eh
    Jbe     Short VolSlideThreeHalf

VolSlideTwice:
    Shl     cl, 1                      ;Multiply vol*2
    Cmp     cl, 64
    Jbe     Short vsskip               ;Slide above 64?
    Mov     cl, 64                     ;Set back down
    Jmp     Short vsskip

VolSlideThreeHalf:
    Movzx   ecx, cl
    Lea     ecx, [ecx*2+ecx]           ;Multiply vol*3
    Shr     cx, 1                      ;Divide vol\2
    Cmp     cl, 64
    Jbe     Short vsskip
    Mov     cl, 64
    Jmp     Short vsskip

VolSlideUp:
    Mov     al, RetrigSlideTable[bx-8] ;Get slide speed
    Add     cl, al                     ;Add upspeed (x)
    Cmp     cl, 64
    Js      Short vsskip               ;Did we slide above 64?
    Mov     cl, 64                     ;Yes, set back to max
    Jmp     Short vsskip

VolSlideHalf:
    Shr     cl, 1                      ;Divide vol\2
    Jmp     Short vsskip

VolSlideTwoThird:
    Movzx   eax, cl
    Lea     eax, [eax*2]               ;Multiply vol*2
    Mov     bl, 3
    Div     bl                         ;Divide vol(ax)\3
    Mov     cl, al
    Jmp     Short vsskip

VolSlideDown:
    Mov     al, [RetrigSlideTable+bx]
    Sub     cl, al                     ;Subtract downspeed (y)
    Jns     Short vsskip               ;Did we slide below 0?
    Xor     cl, cl                     ;Yes, set back to min
    Jmp     Short vsskip

vsskip:
    SetVolumeCL
    Jmp     FXUpdateEnd                ;Return to music processing
RetrigNoteUpdate    EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 13xx - Set Global Music Volume                         [D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetGlobalVolume     Proc    Near
    Cmp     ah, 64
    Jb      Short @F
    Mov     ah, 64
@@: Mov     MusicVol, ah               ;Save new global music volume
    Call    GlobalMusicSet             ;Go fix up all music channels
    Jmp     FXStartEnd
SetGlobalVolume     EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 1Exx - Extended Effects #2                (PT HT MT ST)[S OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ExtendedStart2      Proc    Near
    Mov     Byte PTR ds:SndChans.MusEffDat1[di], ah
    Movzx   ebx, ah
    Shr     bx, 4
    And     ah, 0Fh                            ;Mask off effect number
    Jmp     cs:[FXExtended2+ebx*2]
ExtendedStart2      EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 1E8x - Set Pan Position                   (PT HT MT ST)[D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPan              Proc    Near
    Mov     ds:SndChans.MixPanning, ah
IFDEF GUS ;********
    Push    edx
    Push    eax
    Mov     dx, GUSRegAddr
    Mov     al, 0Ch                    ;0Ch - Pan Position
    Out     dx, al
    Add     dx, 2
    Mov     al, ah
    Out     dx, al
    Pop     eax
    Pop     edx
ENDIF     ;********

    Mov     cl, ds:SndChans.MixMonoVol
    Movzx   bx, ah
    Movzx   ax, Byte PTR [xPanTableRight+bx]
RightCalc:
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Right Volume
    Mov     ds:SndChans.MixRgtVol, al
LeftCalc:
    Movzx   ax, Byte PTR [PanTableLeft+bx]
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Left Volume
    Mov     ds:SndChans.MixLftVol, al

    Jmp     FXStartEnd
SetPan              EndP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Effect 1Fxx - Set BPM                            (PT HT MT ST)[D OR]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetBPM              Proc    Near
    Mov     BPM, ah                            ;Save new BPM
IFDEF GUS ;*******
    Call    CalcBPMTimer
    Call    SetUltraTimer1
ELSE      ;*******
    Movzx   ebx, ah                            ;Set BX=BPM
    Mov     bx, cs:[ebx*2+BPMTickTable-64]     ;Get new counter from table
    Mov     FrameTicks, bx                     ;Save new counter
    Mov     FrameCounter, bx
ENDIF     ;*******
    Jmp     FXStartEnd                         ;Return to music processing
SetBPM              EndP
