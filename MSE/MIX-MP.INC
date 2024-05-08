;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Mono Parallel Mixing Routine Begins Here
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     Ä-ZLÄ-
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
BufferLen           dw      ?          ;Length of DMA (mixing) buffer

Align   4                              ;Speed up for 386+

;Calling: dx - number of bytes to mix
;Returns: none
MixInterrupt        Proc    Near
    Mov     Word PTR cs:DXSave, dx     ;Use self modifying instead of PUSH/POP

    Movzx   dx, EmsHandle              ;DX - Ems Handle
    Or      dx, dx                     ;DX will be zero if no Ems is in use
    Jz      @F                         ;If Ems disabled, skip page map saving
    Mov     ah, 47h                    ;Save Ems page map so IRQ doesn't
    Int     67h                        ;interfere with forground Ems apps.

@@:
DXSave EQU $+1
    Mov     dx, 2324h
    Mov     es, BufferSegment          ;Put mixer buffer segment in es
    Mov     di, Word PTR cs:MixOffset
    Mov     cx, dx
    Mov     eax, 7F7F7F7Fh
    Shr     cx, 2
    Cld
    Rep     Stosd                      ;Store silence (7Fh) in the mixing buffer

MixHotLoop:
    Cmp     dx, FrameCounter           ;Will there be a music update this IRQ?
    Jb      NoFrame
    Sub     dx, FrameCounter           ;Yeah, only mix up to the music update
    Mov     Word ptr cs:MixLeft, dx    ;Save number of bytes left to mix
    Mov     dx, FrameCounter           ;Mix up to the music update
    Mov     Word ptr cs:MixSlimLength, dx
    Mov     Byte ptr cs:FrameFlag, 0F8h   ;Flag that music will need updating
    Jmp     MixBytes

NoFrame:
    Mov     Word PTR cs:MixLeft, 0
    Sub     FrameCounter, dx
    Mov     Byte PTR cs:FrameFlag, 0F9h  ;Flag that music will not need updating
    Mov     Word PTR cs:MixSlimLength, dx

MixBytes:

MixChanOffset EQU $+1
    Mov     di, 0FFFFh                  ;Modified to equal: # channels * 128

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mix Channel Setup
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixSetup    Label Near
    Mov     al, SndChans.MixHandle-128[di]       ;Is the sample in EMS memory?
    Or      al, al
    Jz      NoEMS                               ;No

    Mov     Word PTR cs:DXSave2, dx
    Movzx   dx, al
    Mov     bx, SndChans.MixSeg-128[di]
    Mov     ax, 4400h                           ;Map the EMS pages into memory
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

    Mov     gs, EmsPageSeg                      ;Put sound segment into AX
DXSave2 EQU $+1
    Mov     dx, 02324h
    Jmp     Short YesEMS

NoEMS:
    Mov     gs, SndChans.MixSeg-128[di]       ;Put sound segment into GS
YesEMS:
MixOffset   EQU $+1
    Mov     bp, 02233h                        ;Put mixer buffer offset into bp
    dec     bp

    Mov     bh, SndChans.MixMonoVol-128[di]   ;Put sound volume into BH
    Mov     si, SndChans.MixOff-128[di]       ;Put sound offset into SI
    Test    SndChans.MixFlags-128[di], 1      ;Is there loop end or sample end?
    Jz      MixSamStop                        ;Jump if non-looped sample

    Mov     ah, SndChans.MixIncRemain-128[di]
    Mov     cx, SndChans.MixInc-128[di]
    Or      cx, cx                            ;Is the sample even running?
    Jz      NoMix                             ;No, don't do slow ADDs, etc.

    Mov     al, cl
    Movzx   cx, ch

    Or      bh, bh                            ;Is this VOL=0?
    Jz      StartSPMix                        ;Yeah, don't modify memory (faster)

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Beginning of Mixing Loop [Sample Loops]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(       Mono Mixing Routine       )
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
StartMonoMix:
    Mov     Word PTR cs:AddWholeL, cx

    Mov     cx, SndChans.MixLBeg-128[di]
    Mov     Word PTR cs:ZLMixLBegin, cx

    Mov     cx, SndChans.MixLEnd-128[di]
    Or      cx, cx
    Jz      OkLocMix
    Dec     cx
    Jmp     Short OkLocMix

    Align   4
LoopEnd:
ZLMixLBegin EQU $+1
    Mov     si, 02324h

OkLocMix:
    inc     bp                         ;Increment offset to mixing buffer

    mov     bl, gs:[si]                ;Get one byte of sound
    mov     bl, cs:[VolumeTable+bx]    ;Look up volume
    sub     byte ptr es:[bp], bl       ;Add it to mixing buffer

    add     ah, al                     ;Add Remainders
AddWholeL   EQU $+2
    adc     si, 02324h                 ;Add whole numbers

    cmp     cx, si                     ;Have we reached the loop end?
    dec     dx                         ;Decrement the buffer count
    Ja      short OkLocMix
    Jnz     LoopEnd

    Jmp     EndMixLoop

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(Simple Mixing Routine [no volume])
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
StartSPMix:
    Mov     bx, SndChans.MixLBeg-128[di]
    Mov     Word PTR cs:SPMixLBegin, bx

    Mov     bx, SndChans.MixLEnd-128[di]
    Or      bx, bx
    Jz      OkLocSP
    Dec     bx
    Jmp     Short OkLocSP

    Align   4
LoopEndSP:
SPMixLBegin EQU $+1
    Mov     si, 02324h
OkLocSP:
    inc     bp                         ;Increment offset to mixing buffer

    add     ah, al                     ;Add Remainders
    adc     si, cx                     ;Add whole numbers

    cmp     bx, si                     ;Have we reached the loop end?
    dec     dx                         ;above CF=0 - non zero ZF=0
    Ja      OkLocSP
    Jnz     LoopEndSP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Ending of Mixing Loop
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EndMixLoop  Label Near
    Mov     SndChans.MixIncRemain-128[di], ah
MixSaveOff:
    Mov     SndChans.MixOff-128[di], si

MixNoSave:
MixSlimLength   EQU $+1
    Mov     dx, 0FFFFh
    Sub     di, 128
    Jnz     MixSetup                   ;Cycle through channels

MixDone     Label Near
    inc     bp
    cmp     bp, BufferLen
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
    Mov     dx, 0FFFFh
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
    Sub     di, 128
    Jnz     MixSetup                   ;Cycle through channels
    Jmp     MixDone
MixInterrupt        EndP

MixSamStop          Proc    Near
    Mov     ah, SndChans.MixIncRemain-128[di]
    Mov     cx, SndChans.MixInc-128[di]
    Or      cx, cx
    Jz      NoMix

    Mov     al, cl
    Movzx   cx, ch
    Mov     Word PTR cs:AddWholeE, cx
    Mov     Word PTR cs:AddWholeSPE, cx

    Mov     cx, SndChans.MixLEnd-128[di]
    Or      cx, cx
    Jz      @F
    Dec     cx
@@: Or      bh, bh
    Jz      SimpleMix

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Beginning of Mixing Loop [Sample Ends]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    Align   4
MixLoop:
    inc     bp                         ;2;1 Increment offset to mixing buffer
                                       ;
    mov     bl, gs:[si]                ;4;1 Get one byte of sound
    mov     bl, cs:[VolumeTable+bx]    ;4;1 Look up volume
    sub     byte ptr es:[bp], bl       ;6;3
                                       ;---6
    add     ah, al                     ;2;1 Add Remainders
AddWholeE   EQU $+2                    ;---7
    adc     si, 2324h                  ;2;1 Add whole numbers
                                       ;---8
    cmp     cx, si                     ;2;1 Have we reached the sample end?
    dec     dx                         ;2;1 above CF=0 - non zero ZF=0
    ja      MixLoop                    ;7+1m;3
    Jz      EndMixLoop

SampleEnd:
    Mov     ax, dx
    Mov     SndChans.MixInc-128[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, 128
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Jmp     MixDone

;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
;(Simple Mixing Routine [no volume])
;(ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ)
    Align   4
SimpleMix:
    Inc     bp                         ;Increment offset to mixing buffer

    Add     ah, al                     ;Add Remainders
AddWholeSPE EQU $+2
    Adc     si, 3224h                  ;Add whole numbers

    Cmp     cx, si                     ;Have we reached the sample end?
    Dec     dx                         ;above CF=0 - non zero ZF=0
    Ja      SimpleMix
    Jz      EndMixLoop

SampleEndSP:
    Mov     ax, dx
    Mov     SndChans.MixInc-128[di], 0
    Mov     dx, Word PTR cs:[MixSlimLength]
    Sub     di, 128
    Jnz     MixSetup                   ;Cycle through channels

    Add     bp, ax
    Jmp     MixDone
MixSamStop          EndP
