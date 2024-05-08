;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Stereo Parallel Mixing Routine Begins Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (C) 1993-94, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

BufferLen           dw      ?

    Align   4                          ;Double word alignment for 386+
MixInterrupt        Proc    Near
    Mov     Word PTR cs:DXSave, dx

    Movzx   dx, EmsHandle
    Or      dx, dx
    Jz      @F
    Mov     ah, 47h
    Int     67h

@@:
DXSave EQU $+1
    Mov     dx, 2324h
    Mov     es, BufferSegment          ;Put mixer buffer segment in es
    Mov     di, Word PTR cs:MixOffset  ;Get current offset into mixing buffer
    Mov     cx, dx                     ;Set buffer length
    Mov     eax, 7F7F7F7Fh             ;Clear buffer to silence (7Fh)
    Shr     cx, 1
    Cld
    Rep     Stosd

MixHotLoop:
    Cmp     dx, FrameCounter
    Jb      NoFrame
    Sub     dx, FrameCounter
    Mov     Word PTR cs:MixLeft, dx
    Mov     dx, FrameCounter
    Mov     Word PTR cs:MixSlimLength, dx
    Mov     Byte PTR cs:FrameFlag, 0F8h
    Jmp     MixBytes

NoFrame:
    Mov     Word PTR cs:MixLeft, 0
    Sub     FrameCounter, dx
    Mov     Byte PTR cs:FrameFlag, 0F9h
    Mov     Word PTR cs:MixSlimLength, dx

MixBytes:

MixChanOffset EQU $+1
    Mov     di, 02233h                  ;Modified to equal: # channels * MCSize

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mix Channel Setup
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixSetup    Label Near
MixOffset   EQU $+1
    Mov     bp, 02233h                          ;Put mixer buffer offset into bp

    Mov     Word PTR cs:DXSave2, dx
    Movzx   dx, SndChans.MixHandle-MCSize[di]       ;Is the sample in EMS memory?
    Or      dx, dx
    Jz      NoEMS                               ;No

    Mov     bx, SndChans.MixSeg-MCSize[di]
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

    Mov     gs, EmsPageSeg
    Jmp     Short YesEMS

NoEMS:
    Mov     gs, SndChans.MixSeg-MCSize[di]          ;Put sound segment into AX

YesEMS:
DXSave2 EQU $+1
    Mov     dx, 02324h
    Mov     si, SndChans.MixOff-MCSize[di]          ;Put sound offset into SI
    Test    SndChans.MixFlags-MCSize[di], 1         ;Is it loop end or sample end?
    Jz      MixSamStop                          ;Jump if non-looped sample

    Mov     ah, SndChans.MixIncRemain-MCSize[di]
    Mov     cx, SndChans.MixInc-MCSize[di]
    Or      cx, cx                              ;Is the sample even running?
    Jz      NoMix
    Mov     al, cl
    Movzx   cx, ch
    Cmp     Word PTR SndChans.MixLftVol-MCSize[di], 0
    Jz      SimpleMix

    Movzx   ebx, SndChans.MixPanning-MCSize[di]
    Jmp     Word PTR cs:[MixJumpTable+ebx*2]

MixJumpTable        dw      Offset LeftOnlyMix              ;0 Left
                    dw      Offset PannedMix                ;1
                    dw      Offset PannedMix                ;2
                    dw      Offset PannedMix                ;3
                    dw      Offset PannedMix                ;4
                    dw      Offset PannedMix                ;5
                    dw      Offset PannedMix                ;6
                    dw      Offset PannedMix                ;7
                    dw      Offset MidOnlyMix               ;8 Middle
                    dw      Offset PannedMix                ;9
                    dw      Offset PannedMix                ;A
                    dw      Offset PannedMix                ;B
                    dw      Offset PannedMix                ;C
                    dw      Offset PannedMix                ;D
                    dw      Offset PannedMix                ;E
                    dw      Offset RightOnlyMix             ;F Right


;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(      Panned Mixing Routine      )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
PannedMix:
    Mov     Word PTR cs:AddWholeLPan, cx
    Mov     cx, SndChans.MixLBeg-MCSize[di]
    Mov     Word PTR cs:PanMixLBegin, cx

    Mov     bh, SndChans.MixRgtVol-MCSize[di]       ;Get right side volume
    Xor     ecx, ecx
    Mov     ch, SndChans.MixLftVol-MCSize[di]       ;Get left side volume

    Mov     Word PTR cs:DISave, di
    Mov     di, SndChans.MixLEnd-MCSize[di]
    Or      di, di
    Jz      OkLoc
    Dec     di
    Jmp     OkLoc                              ;For some reason this is
    Align   4

LoopEnd:
PanMixLBegin EQU $+1
    Mov     si, 02324h

OkLoc:
    Mov     cl, gs:[si]                ;Get one byte of sound
    Mov     cl, Byte PTR cs:[VolumeTable+ecx] ;Look up volume
    Sub     Byte PTR es:[bp], cl

    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
AddWholeLPan EQU $+2
    Adc     si, 02324h                 ;Add whole numbers

    Cmp     di, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLoc                ;Jump if not
    Jnz     LoopEnd                    ;If we haven't done all channels,

DISave      EQU $+1
    Mov     di, 02324h
    Jmp     EndMixLoop                 ;continue loop

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(      Middle Mixing Routine      )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
MidOnlyMix:
    Mov     Word PTR cs:AddWholeLMID, cx
    Mov     cx, SndChans.MixLBeg-MCSize[di]
    Mov     Word PTR cs:MIDMixLBegin, cx

    Mov     bh, SndChans.MixLftVol-MCSize[di]     ;Get volume
    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocMID
    Dec     cx
    Jmp     OkLocMID                           ;For some reason this is

    Align   4
LoopEndMID:
MIDMixLBegin    EQU $+1
    Mov     si, 02324h

OkLocMID:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp], bl
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer

    Add     ah, al                     ;Add Remainders
AddWholeLMID EQU $+2
    Adc     si, 02324h                 ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocMID             ;Jump if not
    Jnz     LoopEndMID                 ;If we haven't done all channels,

    Jmp     EndMixLoop                 ;continue loop

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(       Left Mixing Routine       )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
LeftOnlyMix:
    Mov     Word PTR cs:AddWholeLLFT, cx
    Mov     cx, SndChans.MixLBeg-MCSize[di]
    Mov     Word PTR cs:LFTMixLBegin, cx

    Mov     bh, SndChans.MixLftVol-MCSize[di]     ;Get volume
    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocLFT
    Dec     cx
    Jmp     OkLocLFT

    Align   4
LoopEndLFT:
LFTMixLBegin    EQU $+1
    Mov     si, 02324h ;SndChans.MixLBeg-MCSize[di]

OkLocLFT:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp], bl

    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
AddWholeLLFT    EQU $+2
    Adc     si, 2324h ;cx                     ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocLFT             ;Jump if not
    Jnz     LoopEndLFT                 ;If we haven't done all channels,

    Jmp     EndMixLoop                 ;continue loop

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(      Right Mixing Routine       )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
RightOnlyMix:
    Mov     Word PTR cs:AddWholeLRGT, cx
    Mov     cx, SndChans.MixLBeg-MCSize[di]
    Mov     Word PTR cs:RGTMixLBegin, cx

    Mov     bh, SndChans.MixRgtVol-MCSize[di]       ;Get right side volume
    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocRGT
    Dec     cx
    Jmp     OkLocRGT

    Align   4
LoopEndRGT:
RGTMixLBegin    EQU $+1
    Mov     si, 2324h

OkLocRGT:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
AddWholeLRGT    EQU $+2
    Adc     si, 2324h                  ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocRGT
    Jnz     LoopEndRGT                 ;If we haven't done all channels,

    Jmp     EndMixLoop                 ;continue loop

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(Simple Mixing Routine [no volume])
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
SimpleMix:
    mov     bx, SndChans.MixLBeg-MCSize[di]
    mov     word ptr cs:SPMixLBegin, bx

    mov     bx, SndChans.MixLEnd-MCSize[di]
    or      bx, bx
    jz      OkLocSP
    dec     bx
    jmp     OkLocSP

    Align   4
LoopEndSP:
SPMixLBegin EQU $+1
    Mov     si, 02324h

OkLocSP:
    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
    Adc     si, cx                     ;Add whole numbers

    Cmp     bx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocSP
    Jnz     LoopEndSP                  ;If we haven't done all channels,

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Ending of Mixing Loop
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EndMixLoop  Label Near
    Mov     SndChans.MixIncRemain-MCSize[di], ah
MixSaveOff:
    Mov     SndChans.MixOff-MCSize[di], si

MixNoSave:
MixSlimLength   EQU $+1
    Mov     dx, 02233h
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels
MixDone     Label Near
    Cmp     bp, BufferLen
    Jb      Short @F
    Xor     bp, bp
@@: Mov     Word PTR cs:[MixOffset], bp

FrameFlag   EQU $
    Stc
    Jc      Short Exit
    Mov     ax, FrameTicks             ;Reset music tick timer
    Mov     FrameCounter, ax

    Cmp     MusicStatus, 0             ;Is the music enabled?
    Jz      Short Exit                 ;Exit if it's disabled

    Mov     al, TempoCounter
    Inc     al
    Call    MusicUpdateFX
    Cmp     al, Tempo
    Jne     Short TempoExit

    Mov     TempoCounter, 0
    Call    MusicUpdateRow
    Mov     es, BufferSegment          ;Put mixer buffer segment in fs
    Jmp     Short Exit

TempoExit:
    Mov     TempoCounter, al

Exit:
MixLeft     EQU $+1
    Mov     dx, 02233h
    Or      dx, dx
    Jnz     MixHotLoop

MixHotDone:
    Mov     PlayNeedsMix, 0

    Movzx   dx, EmsHandle
    Or      dx, dx
    Jz      @F
    Mov     ah, 48h
    Int     67h

@@: Ret

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(       NUL Mixing Routine        )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
    Align   4
NoMix               Label   Near
    Add     bp, dx
    Add     bp, dx
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels
    Jmp     MixDone
MixInterrupt        EndP

MixSamStop          Proc    Near
    Mov     ah, SndChans.MixIncRemain-MCSize[di]
    Mov     cx, SndChans.MixInc-MCSize[di]
    Or      cx, cx
    Jz      NoMix
    Mov     al, cl
    Movzx   cx, ch

    Cmp     Word PTR SndChans.MixLftVol-MCSize[di], 0
    Jz      SimpleMix

    Movzx   ebx, SndChans.MixPanning-MCSize[di]
    Jmp     Word PTR cs:[MixJumpTable2+ebx*2]

MixJumpTable2       dw      Offset LeftOnlyMix2             ;0 Left
                    dw      Offset PannedMix                ;1
                    dw      Offset PannedMix                ;2
                    dw      Offset PannedMix                ;3
                    dw      Offset PannedMix                ;4
                    dw      Offset PannedMix                ;5
                    dw      Offset PannedMix                ;6
                    dw      Offset PannedMix                ;7
                    dw      Offset MidOnlyMix2              ;8 Middle
                    dw      Offset PannedMix                ;9
                    dw      Offset PannedMix                ;A
                    dw      Offset PannedMix                ;B
                    dw      Offset PannedMix                ;C
                    dw      Offset PannedMix                ;D
                    dw      Offset PannedMix                ;E
                    dw      Offset RightOnlyMix2            ;F Right

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(      Panned Mixing Routine      )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
PannedMix:
    Mov     Word PTR cs:AddWholePan, cx
    Mov     bh, SndChans.MixRgtVol-MCSize[di]       ;Get right side volume
    Xor     ecx, ecx
    Mov     ch, SndChans.MixLftVol-MCSize[di]       ;Get left side volume

    Mov     Word PTR cs:DISave2, di
    Mov     Word PTR cs:DISave3, di

    Mov     di, SndChans.MixLEnd-MCSize[di]
    Or      di, di
    Jz      OkLoc
    Dec     di

    Align   4
OkLoc:
    Mov     cl, gs:[si]                ;Get one byte of sound
    Mov     cl, Byte PTR cs:[VolumeTable+ecx] ;Look up volume
    Sub     Byte PTR es:[bp], cl

    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer

    Add     ah, al                     ;Add Remainders
AddWholePan EQU $+2
    Adc     si, 02324h                 ;Add whole numbers

    Cmp     di, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLoc                ;Jump if not
    Jnz     SampEnd                    ;If we haven't done all channels,

DISave2     EQU $+1
    Mov     di, 02324h
    Jmp     EndMixLoop                 ;continue loop

SampEnd:
    Mov     ax, dx
DISave3     EQU $+1
    Mov     di, 02324h
    Mov     SndChans.MixInc-MCSize[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Add     bp, ax
    Jmp     MixDone

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(    Left Side Mixing Routine     )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
LeftOnlyMix2:
    Mov     Word PTR cs:AddWholeLLFT2, cx

    Mov     bh, SndChans.MixLftVol-MCSize[di]       ;Put sound volume into BH
    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocLFT
    Dec     cx

    Align   4
OkLocLFT:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp], bl

    Add     bp, 2                      ;Increment offset to mixing buffer

    Add     ah, al                     ;Add Remainders
AddWholeLLFT2    EQU $+2
    Adc     si, 2324h                  ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocLFT
    Jz      EndMixLoop                 ;If we haven't done all channels,

LeftNoLoopEnd:
    Mov     ax, dx
    Mov     SndChans.MixInc-MCSize[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Add     bp, ax
    Jmp     MixDone

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(      Middle Mixing Routine      )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
MidOnlyMix2:
    Mov     Word PTR cs:AddWholeMID, cx
    Mov     bh, SndChans.MixLftVol-MCSize[di]       ;Get right side volume

    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocMID
    Dec     cx

    Align   4
OkLocMID:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp], bl
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer

    Add     ah, al                     ;Add Remainders
AddWholeMID EQU $+2
    Adc     si, 02324h                 ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocMID             ;Jump if not
    Jz      EndMixLoop                 ;If we haven't done all channels,

SampEndMID:
    Mov     ax, dx
    Mov     SndChans.MixInc-MCSize[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Add     bp, ax
    Jmp     MixDone

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(    Right Side Mixing Routine    )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
RightOnlyMix2:
    Mov     Word PTR cs:AddWholeRGT2, cx

    Mov     bh, SndChans.MixRgtVol-MCSize[di]       ;Get right side volume
    Mov     cx, SndChans.MixLEnd-MCSize[di]
    Or      cx, cx
    Jz      OkLocRGT
    Dec     cx

    Align   4
OkLocRGT:
    Mov     bl, gs:[si]                ;Get one byte of sound
    Mov     bl, Byte PTR cs:[VolumeTable+bx] ;Look up volume
    Sub     Byte PTR es:[bp+1], bl

    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
AddWholeRGT2    EQU $+2
    Adc     si, 2324h                  ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocRGT
    Jz      EndMixLoop                 ;If we haven't done all channels,

RightNoLoopEnd:
    Mov     ax, dx
    Mov     SndChans.MixInc-MCSize[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Add     bp, ax
    Jmp     MixDone

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(Simple Mixing Routine [no volume])
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
SimpleMix:
    Mov     bx, SndChans.MixLEnd-MCSize[di]
    Or      bx, bx
    Jz      OkLocSP
    Dec     bx

    Align   4
OkLocSP:
    Add     bp, 2                      ;Increment offset to mixing buffer
    Add     ah, al                     ;Add Remainders
    Adc     si, cx                     ;Add whole numbers

    Cmp     bx, si                     ;Have we reached the loop or sample end?
    Dec     dx
    Ja      Short OkLocSP
    Jz      EndMixLoop                 ;If we haven't done all channels,

NoLoopEndSP:
    Mov     ax, dx
    Mov     SndChans.MixInc-MCSize[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, MCSize
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Add     bp, ax
    Jmp     MixDone
MixSamStop          EndP
