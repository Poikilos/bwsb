;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Data Area Begins Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (C) 1993-94, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;ÄÄ Period Table: [PT Octave 0] * 16 * 8363
;1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,907
PeriodTable     dw      1712*16        ;C
                dw      1616*16        ;C#
                dw      1524*16        ;D
                dw      1440*16        ;D#
                dw      1356*16        ;E
                dw      1280*16        ;F
                dw      1208*16        ;F#
                dw      1140*16        ;G
                dw      1076*16        ;G#
                dw      1016*16        ;A
                dw       960*16        ;A#
                dw       907*16        ;B

VibrateTable    db        0, 24, 49, 74, 97,120,141,161
                db      180,197,212,224,235,244,250,253
                db      255,253,250,244,235,224,212,197
                db      180,161,141,120, 97, 74, 49, 24

FineTune        dw      8363,8424,8485,8547,8608,8671,8734,8797
                dw      7894,7951,8009,8067,8125,8184,8244,8303

IfDef Stereo
ChanDivTable    db      1, 2, 2, 3, 3, 3, 3, 4 ;Channel output probability table
                db      4, 4, 5, 5, 5, 5, 5, 5 ;for doing correct divisions of
                db      5, 5, 5, 5, 5, 5, 5, 5 ;samples. (( STEREO ))
                db      5, 5, 5, 5, 8, 8, 8, 8
Else
ChanDivTable    db      1, 2, 3, 4, 5, 5, 6, 6 ;Channel output probability table
                db      6, 7, 7, 7, 7, 7, 7, 7 ;for doing correct divisions of
                db      7, 7, 7, 7, 7, 7, 7, 7 ;samples.   [MONO]
                db      7, 7, 7, 7, 8, 8, 8, 8
EndIf

PanTableLeft    db  16, 16, 16, 15, 14, 13, 12, 11
                db  10, 08, 06, 04, 03, 02, 01, 00

xPanTableRight   db  00, 01, 02, 03, 04, 05, 06, 08
                db  10, 11, 12, 13, 14, 15, 16, 16

AutoMixFlag     db      1              ;1-Mix on IRQ, 0-Mix done in forground
MusicLpStatus   db      1              ;0- Looping Disabled, 1- Looping Enabled
SoundVol        db      64             ;Sound Effects Volume (currently unused)
MasterVol       db      64             ;Master Volume (currently unused)
MusicVol        db      64             ;Music global volume
InstallStatus   db      0              ;0- MSE not installed 1- MSE installed


AmigaClockHz    dd      14317056*256 ;3665454336     ;Amiga * 4 * 256
NullDataStart   EQU     $
ClockHertz      dd      'POTS'
;ClockHertz      dd      0              ;AmigaClockHz \ OverRate

IFNDEF GUS ;********
;IFDEF Stereo
  VolumeTable     db      16640 dup (0)  ;Volume calculation table
;ELSE
;  VolTableSeg   dw      0              ;Segment of volume table
;ENDIF

BPMTickTable    dw      224 dup (0)    ;BPM->Ticks table

;Ä MSE Variables ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EmsHandle       db      0              ;Handle for EMS memory
EmsPageSeg      dw      0              ;EMS Frame segment
ENDIF      ;********


;Ä Sample Structure & Allocations ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

SamHeader      Struc    ;12345678901234567890123456789012
 SamName        db      32 dup (0)     ;Instrument's full name                 32 32
 SamFileName    db      12 dup (0)     ;Sample's file name                     12 44
 SamHandle      db      0              ;EMS Handle for this sample             1  45
 SamLen         dd      0              ;Sample length                          4  49
 SamBegin       dd      0              ;Sample loop begin                      4  53
 SamEnd         dd      0              ;Sample loop end                        4  57
 SamFlags       db      0              ;Sample flags                           1  58
 SamTune        dw      0              ;C-4Hz. 8363 normal                     2  60
 SamVol         db      0              ;Sample's default volume                1  61
 SamPan         db      0              ;Memory Location(MSN)/Pan Position(LSN) 1  62
 SamSeg         dw      0              ;Segment/Page/Address of sample         2  64
SamHeader      EndS

Samples  SamHeader      255 dup (<>)   ;255 Samples Maximum

;Ä Mixer and Music Channel Structure ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChan        Struc
 MixFlags       db      0              ;Mixing flags                             1 0
 MixLBeg        dw      0              ;Offset of loop beginning                 2 1
 MixLEnd        dw      0              ;Offset of loop ending                    2 3
 MixFinetune    dw      0              ;Finetune                                 2 5
 MixRate        dd      0              ;Sample rate/period of sound              4 7        4 7
 MixSeg         dw      0              ;Segment of sound                         2 11
 MixOff         dw      0              ;Offset of next byte to mix               2 13
 MixVolume      db      0              ;Volume of channel                        1 15
 MixInc         dw      0              ;Incrementation for each sample. MSB.LSB  2 16
 MixIncRemain   db      0              ;Remainder from last increment.           1 18
 MusSample      db      0              ;Currently played sample number           1 19
 MusNote        db      0              ;Currently played note                    1 20
 MusOctave      db      0              ;Currently played octave                  1 21
 MusEffect1     db      0              ;Music Effect Channel 1                   1 22
 MusEffDat1     dw      0              ;                                         2 23
 MusEffect2     db      0              ;Music Effect Channel 2                   1 25
 MusEffDat2     dw      0              ;                                         2 26
 MusEffect3     db      0              ;Music Effect Channel 3                   1 28
 MusEffDat3     dw      0              ;                                         2 29
 MusEffect4     db      0              ;Music Effect Channel 4                   1 31
 MusEffDat4     dw      0              ;                                         2 32
 VUMeter        db      0              ;Volume Meter value                       1 34
 MusVolRate     dw      0              ;Old Vol Slide Speed                      2 35
 MusPortaRate   dw      0              ;Old Porta to Note Speed                  2 37
 MusVibWave     db      0              ;Vibrato Waveform Select                  1 39
 MusVibPosition db      0              ;Vibrato Table Position                   1 40
 MusVibSpeed    db      0              ;Vibrato Speed (x0h)                      1 41
 MusVibDepth    db      0              ;Vibrato Depth (0yh)                      1 42
 MusTrmWave     db      0              ;Tremolo Waveform Select                  1 43
 MusTrmPosition db      0              ;Tremolo Table Position                   1 44
 MusTrmSpeed    db      0              ;Tremolo Speed                            1 45
 MusTrmDepth    db      0              ;Tremolo Depth                            1 46
 MusRetrigSpeed db      0              ;Retrigger speed
 MusRetrigSlide db      0              ;Retrigger volume slide
 MusGlissFunk   db      0              ;Funk It (Invert Loop) Speed
 MusFunkOffset  db      0              ;Funk It position
 MusWaveStart   dw      0              ;Funk It funk pointer (offset into sample)
 MixPanning     db      0              ;Pan position
 MixHandle      db      0
 MixMonoVol     db      0
 MixLftVol      db      0              ;Left speaker mixing volume
 MixRgtVol      db      0              ;Right speaker mixing volume
 GUSAddress     dd      0              ;Address of start position in GUS memory
 MusArpeggio    db      0              ;Old Arpeggio speed
 MusPortaUD     db      0              ;Old Porta Up/Down speed
 Reserved       db      64 dup (0)     ;                                        18 47
MixChan        EndS

MCSize  EQU SIZE MixChan
MCShift EQU 7

comment |
IF MCSize=128
  %OUT MixChan checksum OK
else
  %out MixChan checksum mismatch
endif
|

SndChans   MixChan      34 dup (<>)    ;Channel structures
SCSegTable      dw      34 dup (0)     ;Segment table for each channel structure

;Ä Mixing Variables ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

OutputStatus    db      0              ;0-Output Disabled, 1-Output Enabled
OverRate        dw      0              ;Oversampling Rate

BufferSegment   dw      0              ;Segment of mixing buffer
VolSegment      dw      0              ;Segment of volume tables


NumChannels     db      0              ;Number of total channels
;Ä Music Variables ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MusicStatus     db      0              ;0-Disabled music processing, 1-Enable
MusicLpCount    db      0              ;Number of times music has looped

NOOrders        db      0              ;Number of orders in GDM
OrderTable      db      256 dup (0)    ;Order table
PatSegTable     dw      256 dup (0)    ;Pattern segment table

PlayOrder       db      0              ;Currently playing order
PlayPattern     db      0              ;Currently playing pattern
PlayRow         db      0              ;Currently playing row
PlayLen         dw      0              ;Total number of rows in pattern
PlaySeg         dw      0              ;Segment of current pattern
PlayOff         dw      0              ;Offset of current play address
PlayNeedsMix    db      0              ;1=Next buffer needs mixing, 0=none

BPM             db      0              ;BPM (Beats Per Minute) speed of music
Tempo           db      0              ;Temp speed of music
TempoCounter    db      0              ;Number of frames left before row update
FrameTicks      dw      0              ;Number of bytes between each frame
FrameCounter    dw      0              ;Number of bytes left before next frame
