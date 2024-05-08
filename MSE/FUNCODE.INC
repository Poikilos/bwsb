;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Function Code Area Begins Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
FreqShift = 1

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixStatus           Proc
    Movzx   ax, PlayNeedsMix
    Ret
MixStatus           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixForground        Proc
IFNDEF GUS
    Push    esi                        ;Preserve all those registers
    Push    edi                        ;that the mixing routines might
    Push    ebp                        ;possibly use.
    Push    es
    Push    ds
    Push    gs
    Push    eax
    Push    ebx
    Push    ecx
    Push    edx

    Mov     dx, Word PTR cs:[BufLenDMA]
    Inc     dx
    Call    MixInterrupt               ;Go mix DX number of samples

    Pop     edx                        ;Restore all our old register values
    Pop     ecx
    Pop     ebx
    Pop     eax
    Pop     gs
    Pop     ds
    Pop     es
    Pop     ebp
    Pop     edi
    Pop     esi
ENDIF

    Ret
MixForground        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: al     New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SetAutoMix          Proc
    Mov     AutoMixFlag, al
    Ret
SetAutoMix          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartMusic                                                   20
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartMusic          Proc
    Mov     MusicStatus, 1             ;Enable the music
    Mov     MusicLpCount, 0            ;Reset number of music loops
    Ret
StartMusic          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopMusic                                                    21
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopMusic           Proc
    Mov     MusicStatus, 0             ;Disable the music processing
    Ret
StopMusic           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: ax      New Amiga period Hertz to use (default 3579545.25)
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
AmigaHertz          Proc        Uses ebx edx
    Shl     eax, 10                    ;Multiply by 4 * 256
    Xor     edx, edx
    Mov     AmigaClockHz, eax

    Movzx   ebx, OverRate
    Or      bx, bx
    Jz      Short Exit

    Div     ebx
IFDEF GUS ;********
    Shl     eax, 1
ENDIF     ;********
    Mov     ClockHertz, eax

Exit:
    Ret
AmigaHertz          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicEnable                                                  23
 Calling: none
 Returns: ah      Music playing status (1-enabled, 0-disabled)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicEnable         Proc
    Mov     ah, MusicStatus            ;Get current music enable status
    Ret
MusicEnable         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: ah      New music BPM 0=no set
 Returns: ah      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicBPM            Proc
    Or      ah, ah                     ;Are we setting the BPM?
    Jz      Short GetBPM
    Mov     BPM, ah                    ;Save new BPM speed
IFDEF GUS ;********
    Call    CalcBPMTimer
ELSE      ;********
    Movzx   bx, ah                     ;Lookup BPM in our table
    Shl     bx, 1
    Mov     bx, cs:[bx+BPMTickTable-64];Get number of ticks for this BPM
    Mov     FrameTicks, bx             ;Save new ticks in both frame variables
    Mov     FrameCounter, bx
ENDIF     ;********

GetBPM:
    Mov     ah, BPM                    ;Get the current BPM
    Ret
MusicBPM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: ah      New music tempo, FFh=no set
 Returns: ah      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicTempo          Proc
    Cmp     ah, 0FFh                   ;Are we setting the current tempo?
    Je      Short GetTempo
    Mov     Tempo, ah                  ;Save the new tempo
    Mov     TempoCounter, 0            ;Reset tempo counter
GetTempo:
    Mov     ah, Tempo                  ;Get current tempo
    Ret
MusicTempo          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: ah      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicOrder          Proc        Uses es ebx
    Cmp     ah, 0FFh                   ;Are we just getting the current order?
    Je      Short GetOrder
    Movzx   bx, ah                     ;Get ready to look up pattern number
    Cmp     ah, NOOrders               ;Trying to set a nonexistant order?
    Jbe     Short @F
    Xor     bx, bx                     ;Yeah, loop back to first order
@@: Mov     PlayOrder, bl              ;Save new order number
    Movzx   ebx, cs:[OrderTable+bx]    ;Look up the pattern number in order table
    Mov     PlayPattern, bl            ;Save new pattern number
    Mov     ax, cs:[PatSegTable+ebx*2] ;Get segment of new pattern
    Mov     PlaySeg, ax                ;Save new pattern segment
    Mov     es, ax
    Mov     ax, es:[0]                 ;Get length of new pattern
    Mov     PlayLen, ax                ;Save length of new pattern
    Mov     PlayOff, 2                 ;Save play offset
    Mov     PlayRow, 0                 ;Back to row 0
GetOrder:
    Mov     ah, PlayOrder              ;Get the new order number
    Ret
MusicOrder          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: ah      New music pattern, FFh=no set
 Returns: ah      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicPattern        Proc        Uses es ebx
    Cmp     ah, 0FFh                   ;Are we just getting the current?
    Je      Short GetPattern
    Mov     PlayPattern, ah            ;Save new pattern number
    Movzx   ebx, ah                    ;Get ready to look up in tables
    Mov     ax, cs:[PatSegTable+ebx*2] ;Get segment of new pattern
    Mov     PlaySeg, ax                ;Save new pattern segment
    Mov     es, ax
    Mov     ax, es:[0]                 ;Get length of new pattern
    Mov     PlayLen, ax                ;Save length of new pattern
    Mov     PlayOff, 2                 ;Save play offset
    Mov     PlayRow, 0                 ;Back to row 0
GetPattern:
    Mov     ah, PlayPattern
    Ret
MusicPattern        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicRow                                                     28
 Calling: none
 Returns: ah      Current music row
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicRow            Proc
    Mov     ah, PlayRow                ;Get the current music row number
    Ret
MusicRow            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicLoop                                                    29
 Calling: ah       0 - Disable music looping
                   1 - Enable music looping
                  FF - no change
 Returns: ah      Number of times music has looped
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicLoop           Proc
    Cmp     ah, 0FFh                   ;Are we setting loop enable?
    Je      Short GetCount
    Mov     MusicLpStatus, ah          ;Set the new music looping status
GetCount:
    Mov     ah, MusicLpCount           ;Get number of times music has looped
    Ret
MusicLoop           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: ah      New global music volume (0-64). 0FFh=no change
 Returns: ah      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicVolume         Proc
    Cmp     ah, 0FFh                   ;Are we setting global music volume?
    Je      Short GetVol

    Cmp     ah, 64                     ;Above maximum?
    Jb      Short @F
    Mov     ah, 64                     ;Yeah, set back to maximum
@@: Mov     MusicVol, ah               ;Set the new music volume
    Call    GlobalMusicSet
GetVol:
    Mov     ah, MusicVol               ;Get number of times music has looped
    Ret
MusicVolume         EndP

GlobalMusicSet      Proc    Near    Uses ax ebx ecx dx ds di
    Xor     ebx, ebx

MusicGVolLoop:
    Mov     ds, [SCSegTable+ebx*2]
    Mov     al, ds:SndChans.MixVolume          ;Get channel's volume
    Mul     MusicVol                           ;Multiply by master volume
    Shr     ax, 6                              ;Divide by 64
    Movzx   ecx, al                            ;Save new relative volume
    Mov     ds:SndChans.MixMonoVol, cl

IFDEF GUS ;********
    Mov     dx, GUSAddr
    Add     dx, 102h                        ;GF1 Channel Select Port
    Mov     al, bl                          ;Get current channel number
    Out     dx, al

    Mov     dx, GUSRegAddr
    Mov     al, 89h                            ;89h - GF1 Current Volume
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port
    In      ax, dx
    Cmp     ax, [GUSVolTable+ecx*2]
    Je      Short @F

    Mov     ax, [GUSVolTable+ecx*2]
    Call    UltraSlideRamp
@@:
ENDIF     ;********

    Movzx   di, ds:SndChans.MixPanning
    Movzx   ax, Byte PTR [xPanTableRight+di]
RightCalc:
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Right Volume
    Mov     ds:SndChans.MixRgtVol, al
LeftCalc:
    Movzx   ax, Byte PTR [PanTableLeft+di]
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Left Volume
    Mov     ds:SndChans.MixLftVol, al

    Inc     ebx                        ;Update channel number
    Cmp     bl, NumChannels            ;Have we fixed up all channels?
    Jb      MusicGVolLoop

    Ret
GlobalMusicSet      EndP

IFDEF GUS ;********
SetSoundVolDL       Macro
    Mov     al, dl
    Mov     ds:SndChans.MixVolume, dl          ;Save new music volume
    Shr     dl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, dl            ;Save new vumeter

    Mul     SoundVol                           ;Multiply by master volume
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
    Push    cx
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
    Pop     cx
EndM

ELSE      ;********

SetSoundVolDL       Macro
    Push    cx
    Mov     al, dl
    Mov     ds:SndChans.MixVolume, dl          ;Save new music volume
    Shr     dl, 1                              ;Divide by 2 for vumeters
    Mov     ds:SndChans.VUMeter, dl            ;Save new vumeter

    Mul     SoundVol                           ;Multiply by master volume
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
    Pop     cx
EndM
ENDIF

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                   41
 Calling: bl      Channel number (1..32)
          cl      Sample number (0..255)
          ax      Sampling rate (4000..65535)
          dl      Volume for playback
          dh      Pan position to start with
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlaySample          Proc        Uses ebx eax ecx edx ds
Local   TempInc:word, ChanNum:byte

    Push    dx
    Dec     bl
    Mov     ChanNum, bl
IFDEF GUS ;*******
    Push    ax
    Mov     dx, GUSAddr
    Add     dx, 102h                        ;GF1 Channel Select Port
    Mov     al, bl                          ;Get current channel number
    Out     dx, al
    Pop     ax
ENDIF     ;*******
    Xor     bh, bh
    Shl     bx, 1
    Mov     ds, SCSegTable[bx]
    Mov     ds:SndChans.MixInc, 0
    Mov     ds:SndChans.MusSample, cl  ;Save the sample number
    Movzx   ecx, cl                    ;Setup sample number
    Shl     ecx, 6                     ;Multiply sample number by 64

    Mov     bx, OverRate
    Movzx   dx, ah
    Mov     ah, al
    Xor     al, al
    Div     bx
    Mov     TempInc, ax
    Mov     ds:SndChans.MixIncRemain, 0
    Mov     ds:SndChans.MixOff, 0

IFDEF GUS ;*******
    Mov     dx, GUSRegAddr
    Mov     bl, al                             ;Save Mixing Increment LSB

    Mov     al, 1                              ;01h - GF1 Frequency Control
    Out     dx, al
    Inc     dx                                 ;GF1 Data LSB Port

    Mov     al, bl                             ;Restore Mixing Increment LSB
    Shl     ax, 2
    Out     dx, ax
ENDIF     ;*******

    Pop     ax
    Mov     dl, al
    Mov     al, ah
    Mov     bl, ChanNum
    Inc     bl
    Push    dx
    Push    cx
    Push    cs
    Call    Near PTR ChannelPan
    Pop     cx
    Pop     dx
    SetSoundVolDL

    Mov     ax, Samples.SamSeg[ecx]
    Mov     ds:SndChans.MixSeg, ax
    Mov     Word PTR ds:SndChans.GUSAddress, ax
    Mov     ah, Samples.SamHandle[ecx]
    Mov     ds:SndChans.MixHandle, ah
    Mov     Byte PTR ds:SndChans.GUSAddress+2, ah

    Mov     al, Samples.SamFlags[ecx]
    Mov     ds:SndChans.MixFlags, al
    Test    al, 1
    Movzx   eax, Word PTR Samples.SamLen[ecx]
    Jz      Short NoLoop
    Movzx   eax, Word PTR Samples.SamBegin[ecx]
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
    Mov     ax, Word PTR TempLoc
    Out     dx, ax

    Dec     dx
    Mov     al, 2                      ;02h - Starting Location MSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
ENDIF     ;*******

    Movzx   eax, Word PTR Samples.SamEnd[ecx]
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
    Mov     ax, Word PTR TempLoc
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 4                      ;04h - End Location MSW
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, Word PTR TempLoc+2
    Out     dx, ax
ENDIF     ;*******
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
    Mov     ax, TempInc
    Mov     ds:SndChans.MixInc, ax
    Ret
PlaySample          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetChannelTable                                              44
 Calling: bl      Channel number (1..32)
          dx      Segment of channel table buffer
          di      Offset of channel table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetChannelTable     Proc        Uses si ds es
    Xor     bh, bh
    Dec     bx
    Shl     bx, 1
    Mov     ds, SCSegTable[bx]
    Mov     si, Offset SndChans
    Mov     es, dx
    Mov     cx, 64 ;128
    Rep     Movsb
    Ret
GetChannelTable     EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: al      New pan position (0..15). FFh=no set
          bl      Channel number (1..32)
 Returns: al      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPan          Proc        Uses di
    Mov     cl, bl
    Dec     cl
    Movzx   bx, bl
    Dec     bx
    Shl     bx, MCShift                ;Multiply by MCSize
    Cmp     al,  0FFh                  ;Are we setting the pan position?
    Je      Short GetPan

    Mov     SndChans.MixPanning[bx], al ;Save new pan position

IFDEF GUS ;********
    Push    ax
    Push    dx

    Mov     ah, al

    Mov     dx, GUSAddr
    Add     dx, 102h                        ;GF1 Channel Select Port
    Mov     al, cl                          ;Get current channel number
    Out     dx, al

    Mov     dx, GUSRegAddr
    Mov     al, 0Ch                    ;0Ch - Pan Position
    Out     dx, al
    Add     dx, 2
    Mov     al, ah
    Out     dx, al

    Pop     dx
    Pop     ax
ENDIF     ;********

    Mov     al, SndChans.MixVolume[bx]         ;Get channel's volume
    Mul     MusicVol                           ;Multiply by master volume
    Shr     ax, 6                              ;Divide by 64
    Mov     cl, al                             ;Save new relative volume
    Mov     SndChans.MixMonoVol[bx], cl

    Movzx   di, SndChans.MixPanning[bx]        ;Get current panning position
    Movzx   ax, Byte PTR [xPanTableRight+di]
RightCalc:
    Mul     cl                         ;Mixing volume(CL)*Panning(AL)
    Shr     ax, 4                      ;Mixing volume\16=New Right Volume
    Mov     SndChans.MixRgtVol[bx], al
LeftCalc:
    Movzx   ax, Byte PTR [PanTableLeft+di]
    Mul     cl                         ;Mixing volume*Panning
    Shr     ax, 4                      ;Mixing volume\16=New Left Volume
    Mov     SndChans.MixLftVol[bx], al

GetPan:
    Mov     al, cs:SndChans.MixPanning[bx]
    Ret
ChannelPan          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: al      New VU setting, 0FFh=no set
          bl      Channel number (1..32)
 Returns: al      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVU           Proc        Uses ds
    Movzx   bx, bl
    Dec     bx
    Shl     bx, MCShift                ;Multiply by MCSize

    Cmp     al, 0FFh                   ;Are we setting the VU value?
    Je      Short GetVU
    Mov     SndChans.VUMeter[bx], al   ;Save new VU value

GetVU:
    Mov     al, SndChans.VUMeter[bx]   ;Get VU value for caller
    Ret
ChannelVU           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                   47
 Calling: al      New volume setting (0..64). FFh=no set
          bl      Channel number (1..32)
 Returns: al      Channel's volume setting (0..64)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVol          Proc        Uses ds ebx
    Dec     bl
    Movzx   ebx, bl
    Mov     ds, SCSegTable[ebx*2]
IFDEF GUS ;*******
    Push    ax
    Mov     dx, GUSAddr
    Add     dx, 102h                        ;GF1 Channel Select Port
    Mov     al, bl                          ;Get current channel number
    Out     dx, al
    Pop     ax
ENDIF     ;*******

    Cmp     al,  0FFh                  ;Are we setting the pan position?
    Je      Short GetVol

    Mov     dl, al
    SetSoundVolDL

GetVol:
    Mov     al, ds:SndChans.MixVolume
    Ret
ChannelVol          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: ax      New channel play position (0..65534). FFFFh=no set
          bl      Channel number (1..32)
 Returns: ax      Channel's play position (0..65535)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPos          Proc        Uses ds ebx
    Dec     bl
    Movzx   ebx, bl
    Mov     ds, word ptr cs:SCSegTable[ebx*2]
IFDEF GUS ;*******
    Push    ax
    mov     dx, word ptr cs:GUSAddr
    add     dx, 102h                        ;GF1 Channel Select Port
    mov     al, bl                          ;Get current channel number
    out     dx, al
    Pop     ax
ENDIF     ;*******

    Cmp     ax,  0FFFFh                ;Are we setting the play position?
    Je      Short GetPos

    Mov     word ptr ds:SndChans.MixOff, ax             ;Save new sample offset
IFDEF GUS ;********
    Movzx   eax, word ptr ds:SndChans.MixOff
    Add     eax, dword ptr ds:SndChans.GUSAddress
    Shl     eax, 9
    Mov     dword ptr cs:TempLoc, eax
    Mov     dx, word ptr cs:GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 0Bh                    ;0Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr cs:TempLoc
    Out     dx, ax                     ;Send Lower 7 bits of location
    GF1_Delay
    Out     dx, ax

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 0Ah                    ;0Bh - Current Location MSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    Mov     ax, word ptr cs:TempLoc+2
    Out     dx, ax
    GF1_Delay
    Out     dx, ax
ENDIF     ;********

GetPos:
    Mov     ax, word ptr ds:SndChans.MixOff     ;Get current offset
IFDEF GUS ;********
    Mov     dx, word ptr cs:GUSRegAddr             ;GF1 Register Select Port
    Mov     al, 8Ah                    ;8Bh - Current Location MSB
    Out     dx, al
    inc     dx                         ;GF1 Data LSB Port
    in      ax, dx                     ;Read Lower 7 bits of location
    shl     eax, 16

    Dec     dx                         ;GF1 Register Select Port
    Mov     al, 8Bh                    ;8Ah - Current Location LSB
    Out     dx, al
    Inc     dx                         ;GF1 Data LSB Port
    in      ax, dx

    shr     eax, 9
    sub     eax, dword ptr ds:SndChans.GUSAddress
ENDIF     ;********

    Ret
ChannelPos          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetSampleTable                                               49
 Calling: bl      Sample number (0..254)
          dx      Segment of sample table buffer
          di      Offset of sample table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetSampleTable      Proc        Uses si ds es
    Xor     bh, bh
    Shl     bx, 6
    Mov     si, bx
    Mov     ax, cs
    Mov     ds, ax
    Add     si, Offset Samples
    Mov     es, dx
    Mov     cx, 64
    Rep     Movsb
    Ret
GetSampleTable      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterSample                                               60
 Calling: bl      Sample number
          dx      Segment of sample header
          si      Offset of sample header
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegisterSample      Proc    Uses es ds si di
    Movzx   di, bl
    Shl     di, 6                      ;Multiply DI by 64
    Add     di, Offset Samples
    Mov     ax, cs
    Mov     es, ax
    Mov     cx, 64
    Mov     ds, dx
    Rep     Movsb

    Mov     al, cs:[SamHeader.SamHandle+di-64]
    Cmp     al, 0
    Je      Short Exit
IFNDEF GUS
    Mov     EmsHandle, al
    Mov     ah, 41h
    Int     67h
    Mov     EmsPageSeg, bx
ENDIF

Exit:
    Ret
RegisterSample      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterPatterns                                             61
 Calling: dx      Segment of pattern segment table
          si      Offset of pattern segment table
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegisterPatterns    Proc    Uses ds es di
    Mov     ax, cs
    Mov     es, ax
    Mov     di, Offset PatSegTable
    Mov     ds, dx
    Mov     cx, 256                    ;256 patterns possible
    Rep     Movsw                      ;Copy pattern segment table
    Ret
RegisterPatterns    EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterOrders                                               62
 Calling: dx      Segment of order table
          si      Offset of order table
          ch      Number of orders
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegOrderPostProcess     Macro
    Push    es
    Mov     PlayOrder, 0               ;Reset music playing locations
    Movzx   bx, cs:[OrderTable]
    Mov     PlayPattern, bl
    Shl     bx, 1
    Mov     ax, cs:[PatSegTable+bx]
    Mov     PlaySeg, ax
    Mov     es, ax
    Mov     ax, es:[0]
    Mov     PlayLen, ax                ;Save length of this pattern
    Mov     PlayRow, 0                 ;Start on row 0
    Mov     PlayOff, 2                 ;Start at beginning
    Pop     es
EndM

RegisterOrders      Proc    Uses es ds si di
    Mov     NOOrders, ch
    Mov     ax, cs
    Mov     es, ax
    Mov     di, Offset OrderTable
    Mov     ds, dx
    Mov     cx, 256                    ;256 orders possible
    Rep     Movsb                      ;Copy order table

    RegOrderPostProcess

    Ret
RegisterOrders      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UnloadModule                                                 64
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
UnloadModule        Proc
    call    near ptr DeallocModule
    ret
UnloadModule        EndP

IFNDEF GUS
EMSDeallocLimit     dw      ?
ENDIF
DeallocModule       Proc    Near Uses es ds si di   ;Internal routine
    Xor     bx, bx
IFNDEF GUS
    Mov     EMSDeallocLimit, 0
ENDIF

PatternLoop:
    mov     cx, cs:[PatSegTable+bx]    ;Get segment of this pattern
    or      cx, cx                     ;Is this segment zero (last pattern)?
    jz      short DonePatterns         ;Yeah, don't deallocate any more
    mov     es, cx
    mov     ah, 49h                    ;Release memory of this pattern
    int     21h
    mov     cs:[PatSegTable+bx], 0     ;Flag that this pattern is GONE!
    add     bx, 2                      ;Increment pattern number
    cmp     bx, 512                    ;Is this last pattern in table?
    jb      PatternLoop                ;Loop if not
DonePatterns:
    xor     bx, bx

SampleLoop:
    test    cs:[Samples.SamFlags+bx], 128   ;Is this a module sample?
    Jz      Short NextSample2               ;Jump if not
    And     cs:[Samples.SamFlags+bx], 127   ;Clear module bit
IFNDEF GUS ;*******
    Movzx   dx, cs:[Samples.SamHandle+bx]   ;Get EMS handle number
    Or      dx, dx                          ;Is this sample in EMS memory?
    Jz      Short BaseSample
    Cmp     dx, EMSDeallocLimit             ;Have we already deallocated it?
    Jbe     Short NextSample
    Mov     EMSDeallocLimit, dx             ;Set new limit

    Mov     ah, 45h                         ;EMS deallocation handle memory
    Int     67h                             ;Call EMS driver
    Jmp     Short NextSample

BaseSample:
    Mov     es, cs:[Samples.SamSeg+bx] ;Get segment of sample
    Mov     ah, 49h                    ;Release memory of this sample
    Int     21h
ENDIF ;*******

NextSample:
    Mov     cx, 64
 EraseSmpLoop:
    Mov     Byte PTR cs:[Samples+bx], 0
    Inc     bx
    Dec     cx
    Jnz     EraseSmpLoop

    Cmp     bx, 255*SIZE SamHeader     ;Is this the last sample?
    Jb      SampleLoop
    Ret

NextSample2:
    add     bx, 64                     ;Go to next sample

    Cmp     bx, 255*SIZE SamHeader     ;Is this the last sample?
    Jb      SampleLoop
    Ret
DeallocModule       EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CopyDRAM                                                     65
 Calling: es      Segment of memory to copy
          si:di   DRAM memory location to copy to
          cx      Bytes of memory to copy
 Returns: cx      Zero if this MSE uses GUS DRAM, unchanged if no DRAM use
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
CopyDRAM            Proc
    Or      cx, cx
    Jnz     Short @F
    Ret
@@:
IFDEF GUS
    Xor     bx, bx
    Mov     dx, GUSAddr
    Add     dx, 103h                   ;Global Register Select
    Mov     al, 44h                    ;Set DRAM Address MSB
    Out     dx, al

    Add     dx, 2                      ;Data High Byte Port
    Mov     ax, si                     ;Output upper 4 bits of DRAM address
    Out     dx, al

    Sub     dx, 2                      ;Global Register Port
MainLoop:
    Mov     al, 43h                    ;Set DRAM Address LSB
    Out     dx, al
    Inc     dx                         ;Data Low Byte Port
    Mov     ax, di                     ;Send DRAM Address LSB
    Out     dx, ax

;ÄÄ Dump a Byte
    Add     dx, 3                      ;DRAM I/O Port
    Mov     al, es:[bx]                ;Get a byte of sample
    Xor     al, 80h                    ;unsigned->signed
    Inc     bx
    Out     dx, al                     ;Write the byte to DRAM

    Sub     dx, 4                      ;Global Register Port

    Add     di, 1
    Jnc     Short DoLoop
    Inc     si
    Mov     al, 44h                    ;Set DRAM Address MSB
    Out     dx, al
    Add     dx, 2                      ;Data High Byte Port
    Mov     ax, si
    Out     dx, al
    Sub     dx, 2

DoLoop:
    Dec     cx
    Jnz     MainLoop

    Mov     al, 43h                    ;Set DRAM Address LSB
    Out     dx, al
    Inc     dx                         ;Data Low Byte Port
    Mov     ax, di                     ;Send DRAM Address LSB
    Out     dx, ax

;ÄÄ Dump a Silence Byte
    Add     dx, 3                      ;DRAM I/O Port
    Mov     al, es:[bx-1]
    Xor     al, 80h
    Out     dx, al                     ;Write the byte to DRAM
ENDIF

    Ret
CopyDRAM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadGDM                                                      66
 Calling: ax      File handle to load from
          ecx     Offset into file to load from
          bl      Load flags
          dx:di   Address of GDM header buffer
 Returns: bx      Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
INCLUDE GDMSTRUC.INC                   ;GDM Format Structure Definition

LoadGDM             Proc    Uses es ds gs esi di edx
Local Temp:word, Temp2:word, EmsFile:word, DramLoc:dword
Local Handle:word, FileOff:dword, Flags:byte, GDMSeg:word, GDMOff:word
;ÄÄÄÄÄ> Initialize
    Mov     Handle, ax
    Mov     FileOff, ecx
    Mov     Flags, bl
    Mov     GDMSeg, dx
    Mov     GDMOff, di

    Mov     bx, ax                     ;BX - File Handle
    Mov     ds, dx                     ;DS - GDM Header Segment Address
    Mov     gs, dx

;ÄÄÄÄÄ> Load Header
    Mov     dx, cx
    Shr     ecx, 16                    ;CX:DX - Offset into File
    Mov     ax, 4200h                  ;Seek to beginning of module
    Int     21h
    Jnc     Short @F
;**
    Jmp     Exit

@@: Mov     ah, 3Fh                    ;Load GDM Header
    Movzx   edx, GDMOff                ;DS:DX - Address of GDM Header
    Mov     cx, size GDMStruc
    Int     21h
    Jnc     Short @F
;**
    Jmp     Exit

@@: Mov     ax, 3                      ;Error Code - Invalid ID

    Cmp     Word PTR gs:[GDMStruc.ID+edx], 04447h
    Jne     Exit
    Cmp     word PTR gs:[GDMStruc.ID+2+edx], 0FE4Dh
    Jne     Exit
    Cmp     word PTR gs:[GDMStruc.ID2+edx], 'MG'
    Jne     Exit
    Cmp     word PTR gs:[GDMStruc.ID2+2+edx], 'SF'
    Jne     Exit

;ÄÄ> Default Global Music Volume
    Mov     al, gs:[GDMStruc.MastVol+edx]
    Cmp     al, 64                     ;Above maximum?
    Jb      Short @F
    Mov     al, 64                     ;Yeah, set back to maximum
@@: Mov     MusicVol, al               ;Set the new music volume
    Call    GlobalMusicSet

;ÄÄ> Default Music BPM
    Mov     ah, gs:[GDMStruc.xBPM+edx]
    Push    dx
    Push    cs                         ;Fix up for FAR call in actuality
    Call    Near PTR MusicBPM
    Pop     dx

;ÄÄ> Default Music Tempo
    Mov     ah, gs:[GDMStruc.xTempo+edx]
    Push    dx
    Push    cs                         ;Fix up for FAR call in actuality
    Call    Near PTR MusicTempo
    Pop     dx

;ÄÄ> Default Panning Map
    Xor     cx, cx
PanLoop:
    Inc     cx                         ;Channel number increment
    Mov     al, Byte PTR gs:[GDMStruc.PanMap+edx]
    Cmp     al, 0FFh                   ;Is this channel used in the GDM?
    Je      Short EndLoop              ;Don't mess with it if not in module

    Mov     bl, cl                     ;BL - Channel to set pan for
    Push    cx
    Push    dx

    Push    cs                         ;Fix up for FAR call in actuality
    Call    Near PTR ChannelPan        ;Set default panning for this channel

    Pop     dx
    Pop     cx

EndLoop:
    Inc     dx
    Cmp     cx, 32
    Jne     PanLoop

;ÄÄÄÄÄ> Load Patterns
    Mov     ax, 4200h                  ;Move file pointer to pattern data
    Mov     bx, GDMOff
    Mov     ecx, gs:[GDMStruc.PatOffset+bx]
    Add     ecx, FileOff
    Mov     dx, cx
    Shr     ecx, 16
    Mov     bx, Handle
    Int     21h
    Jc      Exit

    Mov     Temp2, 0                   ;Start with pattern number 0
PatLoop:
    Mov     ax, ss
    Mov     ds, ax

    Mov     ah, 3Fh                    ;Load pattern length
    Mov     bx, Handle
    Mov     cx, 2                      ;Load only 2 bytes (word)
    Mov     dx, bp
    Sub     dx, 0Ah                    ;Offset of Temp
    Int     21h
    Jc      Exit

    Mov     bx, Temp
    Test    bx, 00001111b              ;Does the length fall flat on one page?
    Jz      Short @F
    Add     bx, 00010000b              ;No, add one more page to it
@@: Shr     bx, 4                      ;Divide by 16 -> Number of Pages
    Mov     ah, 48h                    ;Allocate memory for pattern
    Int     21h
    Mov     ds, ax
    Mov     ax, 4                      ;Error Code - Insufficient Memory
    Jc      Exit

    Mov     di, Temp2                  ;Save segment of this pattern in MSE's
    Shl     di, 1                      ;segment table..
    Mov     PatSegTable[di], ds

    Mov     ah, 3Fh                    ;Finnish loading rest of pattern
    Mov     bx, Handle
    Mov     cx, Temp
    Mov     ds:[0], cx
    Sub     cx, 2                      ;Don't load pattern size again
    Mov     dx, 2                      ;Don't overwrite pattern size
    Int     21h
    Jc      Exit                       ;Exit if error

    Mov     ax, Temp2                  ;What pattern number are we on?
    Inc     Temp2                      ;Move to next one
    Mov     bx, GDMOff
    Cmp     al, gs:[GDMStruc.xNOP+bx]  ;Did we just load the last pattern?
    Jne     PatLoop                    ;Loop if not

;ÄÄÄÄÄ> Load Order Table
    Mov     ax, 4200h                  ;Move file pointer to order table
    Mov     bx, GDMOff
    Mov     ecx, gs:[GDMStruc.OrdOffset+bx]
    Add     ecx, FileOff
    Mov     dx, cx
    Shr     ecx, 16
    Mov     bx, Handle
    Int     21h
    Jc      Exit

    Mov     bx, GDMOff
    Movzx   cx, gs:[GDMStruc.NOO+bx]
    Mov     NOOrders, cl
    Inc     cx
    Mov     ax, cs
    Mov     ds, ax
    Mov     ah, 3Fh                    ;Load Order table
    Mov     bx, Handle
    Mov     dx, Offset OrderTable
    Int     21h
    Jc      Exit                       ;Exit if error

    RegOrderPostProcess

;ÄÄÄÄÄ> Load Sample Headers
    Mov     ax, 4200h                  ;Move file pointer to sample headers
    Mov     bx, GDMOff
    Mov     ecx, gs:[GDMStruc.SamHeadOffset+bx]
    Add     ecx, FileOff
    Mov     dx, cx
    Shr     ecx, 16
    Mov     bx, Handle
    Int     21h
    Jc      Exit

    Mov     Temp2, 0
    Mov     EmsFile, 0
SamHeadLoop:
    Mov     ax, cs
    Mov     ds, ax
    Mov     ah, 3Fh                    ;Load Sample Header
    Mov     bx, Handle
    Movzx   edx, Temp2
    Shl     edx, 6
    Add     edx, Offset Samples
    Mov     cx, 62
    Int     21h
    Jc      Exit                       ;Exit if error

    Or      cs:[SamHeader.SamFlags+edx],128  ;Flag that this is a module sample
    Mov     cs:[SamHeader.SamHandle+edx], 0

IFNDEF GUS
    Test    Flags, 1                   ;Is loading into EMS enabled?
    Jz      NotInEms                   ;No, skip this part..

    Mov     ecx, cs:[SamHeader.SamLen+edx]
    Or      ecx, ecx                   ;Is this an empty sample?
    Jz      NotInEms                   ;Yeah, forget this, chap...
    Cmp     ecx, 65535                 ;Is this sample greater than 64K?
    Ja      NotInEms                   ;Yeah, can't stick it in EMS

    Test    cx, 03FFFh                ;Is this sample one flat EMS page?
    Jz      @F
    Add     ecx,  4000h               ;No, allocate one more page
@@: Shr     ecx, 14                   ;Divide by 16384 (size of one page)

    Mov     ah, 42h                    ;EMS Pages Free Function
    Push    dx
    Int     67h
    Pop     dx
    Sub     bx, EmsFile
    Cmp     bx, cx                     ;Is there enough EMS memory free?
    Jb      NotInEms                   ;No, don't put it in EMS

    Mov     cs:[SamHeader.SamHandle+edx], 1
    Mov     ax, EmsFile
    Mov     cs:[SamHeader.SamSeg+edx], ax
    Add     EmsFile, cx

NotInEms:
ENDIF
    Inc     Temp2
    Mov     bx, GDMOff
    Movzx   ax, gs:[GDMStruc.NOS+bx]
    Cmp     Temp2, ax
    Jbe     SamHeadLoop

;ÄÄÄÄÄ> Load Samples
IFDEF GUS   ;*******
    Mov     ah, 48h                    ;GUS requires temporary DRAM buffer
    Mov     bx, 4096                   ;in base memory
    Int     21h
    Mov     Temp2, ax                  ;Save segment of buffer in Temp2
    Mov     ax, 4
    Jc      Exit
ELSE
    Test    Flags, 1                   ;Is EMS memory enabled?
    Jz      NoEmsAlloc
    Mov     ah, 43h                    ;Allocate EMS memory
    Mov     bx, EmsFile
    Int     67h
    Mov     Temp2, dx                  ;Save EMS handle
    Mov     EmsHandle, dl              ;And again
    Mov     ah, 41h
    Int     67h
    Mov     EmsPageSeg, bx
NoEmsAlloc:
ENDIF
    Mov     DramLoc, 0                 ;DRAM location pointer = 0

    Mov     ax, 4200h                  ;Move file pointer to sample data
    Mov     bx, GDMOff
    Mov     ecx, gs:[GDMStruc.SamOffset+bx]
    Add     ecx, FileOff
    Mov     dx, cx
    Shr     ecx, 16
    Mov     bx, Handle
    Int     21h
    Jc      Exit

    Xor     si, si
    Mov     Temp, 0
LoadSampleLoop:
IFDEF GUS   ;*******
    Mov     ecx, DramLoc
    Mov     Samples.SamSeg[si], cx
    Shr     ecx, 16
    Mov     Samples.SamHandle[si], cl
    Mov     ds, Temp2                  ;DRAM buffer segment
ELSE
    Cmp     Samples.SamHandle[si], 0   ;Is this sample for EMS memory?
    Jz      BaseSample

    Mov     bx, Samples.SamSeg[si]
    Mov     dx, Temp2                  ;Get EMS handle
    Mov     Samples.SamHandle[si], dl

    Mov     ax, 4400h                  ;Map in the sample's page numbers
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

    Mov     ds, EmsPageSeg             ;Get Ems page frame segment
    Jmp     LoadSamp

BaseSample:
    Mov     ah, 48h                    ;Allocate memory for this sample
    Mov     bx, Word PTR Samples.SamLen[si]
    Test    bx, 0Fh
    Jz      @F
    Add     bx, 10h
@@: Shr     bx, 4
    Int     21h
    Mov     Samples.SamSeg[si], ax
    Mov     ds, ax
    Mov     ax, 4
    Jc      Exit
ENDIF
LoadSamp:
    Mov     bx, Handle
    Mov     ax, 4201h                  ;Find file pointer
    Xor     cx, cx
    Xor     dx, dx
    Int     21h
    Jc      Short Exit

    Push    ax
    Push    dx

    Mov     ah, 3Fh                    ;Load Sample
    Xor     dx, dx
    Mov     cx, Word PTR Samples.SamLen[si]
    Int     21h
    Jc      Short Exit                 ;Exit if error

    Mov     ax, 4200h                  ;Set file pointer
    Pop     cx
    Shl     ecx, 16
    Pop     cx
    Add     ecx, Samples.SamLen[si]
    Mov     dx, cx
    Shr     ecx, 16
    Int     21h
    Jc      Short Exit

IFDEF GUS
    Push    si
    Mov     cx, Word PTR Samples.SamLen[si]
    Mov     ax, ds
    Mov     es, ax
    Mov     esi, DramLoc
    Mov     di, si
    Shr     esi, 16
    Push    cs
    Call    Near PTR CopyDRAM
    Pop     si

    Mov     ecx, Samples.SamLen[si]
    Inc     ecx
    Add     DramLoc, ecx
ENDIF
    Add     si, 64
    Inc     Temp
    Mov     ax, Temp
    Mov     bx, GDMOff
    Cmp     al, gs:[GDMStruc.NOS+bx]
    Jbe     LoadSampleLoop


;ÄÄÄ> Clean Up
IFDEF GUS   ;********
    Mov     ah, 49h                    ;Deallocate DRAM temporary buffer
    Mov     es, Temp2
    Int     21h
ENDIF

    Xor     ax, ax                     ;Error Code - No Load Errors

Exit:
    Mov     bx, ax                     ;Save error code in BX
    Ret
LoadGDM             EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AddSample                                                    67
 Calling: dx:si   Address of sample header buffer
          cl      Sample number to allocate to
 Returns: ax      Error code/Memory Free Flag
                  2 - sample slot already used
                  3 - insufficeint memory for sample
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
IFNDEF GUS
EmsEnabled      db      0              ;0 - Ems Disabled, 1 - Ems Enabled
ENDIF

AddSample           proc    uses ds es
local SamData:word, SamHead:dword

    mov     word ptr SamHead, si
    mov     word ptr SamHead+2, dx

    mov     ds, dx                      ;get source segment revved

    movzx   ebx, cl
    shl     bx, 6                       ;multiply by 64
    add     bx, offset Samples
    cmp     cs:[ebx.SamSeg], 0
    jz      @F
    mov     ax, 2
    jmp     Exit

@@: mov     di, bx                      ;get destination offset revved
    mov     ax, cs
    mov     es, ax                      ;get destination segment revved

    mov     cx, SIZE SamHeader          ;get number of bytes to move revved
    rep     movsb                       ;copy the caller's header into ours

    mov     ax, cs:[ebx.SamSeg]
    mov     SamData, ax

    mov     cs:[ebx.SamSeg], 0          ;make sure to flag sample unused

    xor     ax, ax                      ;no error
    cmp     cs:[ebx.SamLen], 0          ;is this an empty sample?
    jz      Exit                        ;yep, we're done!
    cmp     cs:[ebx.SamLen], 0FFFFh     ;is sample length larger than 64K?
    jbe     @F
    mov     cs:[ebx.SamLen], 0FFFFh     ;yeah, truncate it!
@@:
IFNDEF GUS
    cmp     EmsEnabled, 0               ;are we going to use Ems memory for sam?
    jnz     LoadEms

;© Base Memory Load ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚ
LoadBase:
    mov     ax, SamData                 ;save segment of this sample in header
    mov     cs:[ebx.SamSeg], ax
    xor     ax, ax                      ;clear error flag
    jmp     Exit

;© Ems Memory Load ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙ
LoadEms:
    mov     ecx, cs:[ebx.SamLen]
    add     ecx, 3FFFh                  ;safety margin for allocation
    shr     ecx, 14                     ;Divide by 16384 (size of one page)

;ems alloc routine (calling: cx-pages  return: dx-handle)
    push    bx
    mov     bx, cx                      ;put number of pages in bx for int
    mov     ah, 43h                     ;function 43h - Allocate Pages
    int     67h                         ;int 67h - Ems Functions
    pop     bx
;end ems alloc routine

    mov     cs:[ebx.SamHandle], bl      ;save handle of ems sample
    mov     EmsHandle, bl               ;and again for IRQ routines

    mov     ax, EmsPageSeg
    or      ax, ax                      ;do we need to load this variable?
    jnz     CopyToEms

    push    bx
    mov     ah, 41h                     ;function 41h - Return Page Frame Segment
    int     67h
    mov     ax, bx
    mov     EmsPageSeg, ax
    pop     bx

CopyToEms:
    movzx   dx, cs:[ebx.SamHandle]
    mov     ah, 47h                     ;function 47h - save page frame
    int     67h

;ems map pages routine
    push    bx
    xor     bx, bx
    mov     ax, 4400h                   ;function 44h - map page into frame 0
    int     67h
    inc     bx
    mov     ax, 4401h                   ;function 44h - map page into frame 1
    int     67h
    inc     bx
    mov     ax, 4402h                   ;function 44h - map page into frame 2
    int     67h
    inc     bx
    mov     ax, 4403h                   ;function 44h - map page into frame 3
    int     67h
    pop     bx
;end of ems map pages routine

    xor     di, di
    mov     es, EmsPageSeg              ;ES:DI - Address to copy to
    xor     si, si
    mov     ds, SamData                 ;DS:SI - Sample data to copy from
    mov     cx, word ptr cs:[ebx.SamLen]
    rep     movsb

    mov     ah, 48h                     ;function 48h - restore page frame
    int     67h

EmsDone:
    mov     ax, 1                       ;flag that you *should* free sample data
ELSE

;© Gus Dram Memory Load ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚ
LoadDram:
    mov     ecx, 4                      ;start searching from memory block 0
SearchLoop:
    call    u_Peek                      ;High Order bytes are last
    mov     ah, bl
    dec     ecx
    call    u_Peek
    mov     al, bl
    shl     eax, 16

    dec     ecx
    call    u_Peek
    mov     ah, bl
    dec     ecx
    call    u_Peek
    mov     al, bl

    dec     ecx
    call    u_Peek                      ;Read 'Block Used' status
    add     ecx, 4                      ;Go back to beginning of block

    or      bl, bl                      ;is this block available?
    jz      CheckSize                   ;exit loop if so..

    add     ecx, eax                    ;move to next block in memory
    cmp     ecx, GUSTotalMemory
    jb      SearchLoop
    mov     ax, 3                       ;insufficeint memory
    jmp     Exit

CheckSize:
    cmp     eax, cs:[ebx.SamLen]        ;is this memory block large enough?
    jbe     FoundBlock
    add     ecx, eax                    ;move to next block in memory
    cmp     ecx, GUSTotalMemory
    jb      SearchLoop
    mov     ax, 3
    jmp     Exit

FoundBlock:
    mov     cs:[ebx.SamSeg], cx
    ror     ecx, 16
    mov     cs:[ebx.SamHandle], cl
    ror     ecx, 16

    sub     ecx, 4                      ;go back to header
    mov     bl, 1                       ;mark this memory block as used now
    call    u_Poke
    inc     ecx

    mov     edx, cs:[ebx.SamLen]
    add     edx, 4
    cmp     eax, edx                    ;is there enough free memory to create
                                        ;another memory block after this one?
;    jb
ENDIF

Exit:
    ret
AddSample           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SubSample                                                    68
 Calling: cl      Sample number to free
 Returns: ax      Error code
                  1 - sample slot isn't used..
                  2 - module sample, can't dealloc
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SubSample           proc
    movzx   ebx, cl
    shl     bx, 6                       ;multiply by 64
    add     bx, offset Samples

    mov     ax, 1
    cmp     cs:[ebx.SamLen], 0          ;is this sample slot even used?
    jz      Exit

    mov     ax, 2
    test    cs:[ebx.SamFlags], 128      ;is this a module sample?
    jnz     Exit                        ;return if so..


IFNDEF GUS
    cmp     cs:[ebx.SamHandle], 0       ;is this sample in Ems or Base memory?
    jnz     EmsFree                     ;jump if Ems memory

;© Base Memory Free ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚ
BaseFree:
    mov     es, cs:[ebx.SamSeg]         ;get segment of sample
    mov     ah, 49h                     ;release memory of this sample
    int     21h
    jmp     ExitOk                      ;return to caller

;© Ems Memory Load ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙ
EmsFree:
    movzx   dx, cs:[ebx.SamHandle]      ;get Ems handle number
    mov     ah, 45h                     ;45h - Ems dealloc handle memory
    int     67h
ELSE

;© Gus Dram Memory Free ÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚÙÚ
DramFree:

ENDIF

ExitOk:
    mov     cx, SIZE SamHeader
    mov     ax, cs
    mov     es, ax
    mov     di, bx
    mov     al, 0
    cld
    rep     stosb

Exit:
    ret
SubSample           endp
