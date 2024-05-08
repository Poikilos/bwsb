;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;   (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; QBX_MSE.ASM - QB 4.5, PDS, and VB/DOS <-> MSE Interface routines
;               Written by Edward Schlunder (1993-95)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
include id.inc

.Model Medium, Basic                   ;Define memory model/Basic call syntax
.386P
.Data

DeviceName      db      20 dup (0)

Public MSEID
MSEID           db      'Copyright (c) ',', Edward Schlunder ',13,10
Identification  db      IDString
                db      MajorVersion, MinorVersion
IF Evaluation
%OUT Evaluation Version!
UnregBanner     db      10, 13, BWSBCopy, 10, 13, BWSBCopy2, 10, 13
                db      10, 13, SignBanner, 10, 13, '$'
SignedOff       db      0
ELSE
                db      BWSBCopy
ENDIF
                db      BBVer

MSESegment      dw      0              ;Segment in memory where MSE resides

.Code
Extrn           B_OnExit:Far           ;Basic's Exit registery routine

;MSE File Format:
DRVDesc         EQU     0              ;Driver description
MSECopyright    EQU     44             ;Copright notice
DRVAuth         EQU     88             ;Author of driver, 26
DRVSize         EQU     130            ;File size of MSE
DRVID           EQU     132            ;ID
DRVMinVer       EQU     145            ;Driver minor version number
DRVMajVer       EQU     146            ;Driver major version number
DRVNOF          EQU     147            ;Number of functions
DRVSndName      EQU     148            ;Sound Device name
DRVFunc         EQU     168            ;Function table

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: xLoadMSE                                                      0
 Calling: FSeg    Segment of MSE file/path name
          FOff    Offset of above
          OVR     Oversampling rate (xxKHz, Range 5..45)
          BfSz    Mixing buffer size (Range 256..32767)
          Base    Sound device base I/O address. FFFFh for autodetect.
          IRQ     Sound device IRQ level. FFh for autodetect.
          DMA     Sound device DMA channel. FFh for autodetect.
 Returns: Base    Base I/O address used
          IRQ     IRQ level used
          DMA     DMA channel used
          ax      Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
xLoadMSE            proc    uses es ds si di, FSeg:word, FOff:word, FileOff:word, \
                            OVR:word, BfSz:word, Base:word, IRQ:word, DMA:word
Local   FileHandle:word, FileSize:word
    push    ds
    mov     ax, 3D00h
    mov     bx, FOff
    mov     dx, [bx]
    mov     bx, FSeg
    mov     ds, [bx]
    int     21h
    pop     ds
    jnc     @F
    add     ax, 40
    jmp     Exit                       ;Exit if error
@@: mov     FileHandle, ax

;ÄÄÄ Find MSE Size (DRVSize)
    mov     bx, ax                     ;file handle
    mov     ax, 4200h                  ;find out MSE size
    movzx   ecx, FileOff
    mov     ecx, [ecx]
    add     ecx, DRVSize+1
    mov     dx, cx
    shr     ecx, 16
    int     21h
    jnc     @F
    add     ax, 40
    jmp     Exit
@@:
    push    ds
    mov     ax, ss
    mov     ds, ax
    lea     dx, FileSize
    mov     cx, 2
    mov     ah, 3Fh
    int     21h
    pop     ds
    jc      Exit

    mov     ax, FileSize
    Add     ax, 0Fh                    ;Saftey margin
    shr     ax, 4
    mov     bx, ax
    mov     ax, 4800h                  ;Allocate memory for MSE file
    Int     21h
    jc      Exit
    mov     MSESegment, ax

    mov     ax, 4200h                  ;move back to beginning of file
    mov     bx, FileOff
    mov     cx, word ptr [bx+2]
    mov     dx, word ptr [bx]
    mov     bx, FileHandle
    int     21h
    jc      Exit

    Push    ds
    mov     ax, 3F00h                  ;Load the music/sound engine
    mov     cx, FileSize
    Xor     dx, dx
    mov     ds, MSESegment
    Int     21h
    Pop     ds
    jc      Exit

    mov     ah, 3Eh                    ;Close file handle
    int     21h
    jc      Exit

    mov     ax, 0Ah                    ;Check for bad ID header
    mov     es, MSESegment
    mov     cx, 14
    mov     si, Offset MSEID
    mov     di, MSECopyright
    Rep     Cmpsb
    jne     Exit
    Add     di, 7
    mov     cx, 21
    Rep     Cmpsb
    jne     Exit

    mov     bx, DRVFunc+2              ;Get location of function table
    Xor     ch, ch
    mov     cl, es:[DRVNOF]            ;Get number of functions
    Inc     cl

WriteSeg:
    mov     es:[bx], es                ;Write all the segments in function table
    Add     bx, 4                      ;Increment over the offsets
    Loop    WriteSeg                   ;Go through all the functions

    mov     bx, OVR
    mov     ah, [bx]
    mov     bx, Base
    mov     dx, [bx]
    mov     bx, IRQ
    mov     ch, [bx]
    mov     bx, DMA
    mov     cl, [bx]
    mov     bx, BfSz
    mov     bh, [bx+1]

    Call    dword ptr es:[DRVFunc+0*4]     ;Call the function

    Xor     ah, ah
    Push    ax
    mov     bx, DMA
    mov     [bx], cl
    mov     bx, IRQ
    mov     [bx], ch
    mov     bx, Base
    mov     [bx], dx

    Push    cs                         ;Place code segment on stack for routine
    mov     ax, Offset FreeMSE         ;Place code offset on stack
    Push    ax
    Call    B_OnExit                   ;Go register an exit routine

    Pop     ax                         ;Restore error code
Exit:
    Ret
xLoadMSE            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SoundDeviceName
 Calling: NameSeg Segment to 20 byte buffer
          NameOff
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SoundDeviceName     proc    uses es ds di si, NameSeg:word, NameOff:word
    mov     bx, NameSeg
    mov     es, [bx]
    mov     bx, NameOff
    mov     di, [bx]
    mov     ds, MSESegment
    mov     si, DRVSndName
    mov     cx, 20
    rep     movsb

    ret
SoundDeviceName     endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeMSE                                                       1
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
FreeMSE             proc    Uses es ds
    cmp     MSESegment, 0
    jz      Exit

    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+1*4]
    mov     ah, 49h                      ;Release MSE memory
    int     21h
    mov     MSESegment, 0

IF Evaluation
%OUT Evaluation Version!
    Cmp     SignedOff, 0
    jnz     Exit
    mov     SignedOff, 1
    mov     ax, @data
    mov     ds, ax
    mov     ah, 9h
    mov     dx, Offset UnregBanner
    Int     21h
ENDIF
Exit:
    Ret
FreeMSE             endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopBanner
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
IF Evaluation
public StopBanner
StopBanner          proc
    mov     SignedOff, 1
    ret
StopBanner          EndP
ENDIF

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartOutput&                                                  2
 Calling: Chan%   Number of output channels (Range 1..32)
          Amp%    Amplification value (Range -9..9)
 Returns: ax      Actual oversampling rate being used
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartOutput         proc    Uses es di, Chan:Word, Amp:Word
    mov     di, Chan
    mov     al, [di]
    mov     di, Amp
    mov     bh, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+2*4]
    mov     ax, bx
    Xor     dx, dx
    Ret
StartOutput         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopOutput                                                    3
 Calling: None
 Returns: None
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopOutput          proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+3*4]
    Ret
StopOutput          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixStatus           proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+4*4]
    Ret
MixStatus           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixForground        proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+5*4]   ;Call the function
    Ret
MixForground        endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: Mix%   New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SetAutoMix          proc    Uses es, Mix:Word
    mov     bx, Mix
    mov     al, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+6*4]
    Ret
SetAutoMix          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartMusic                                                   20
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartMusic          proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+20*4]   ;Call the function
    Ret
StartMusic          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopMusic                                                    21
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopMusic           proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+21*4]   ;Call the function
    Ret
StopMusic           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: Hertz&  New Amiga period Hertz to use
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
AmigaHertz          proc    Uses es eax, Hertz:word
    mov     bx, Hertz
    mov     eax, [bx]

    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+22*4]   ;Call the function
    Ret
AmigaHertz          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicStatus                                                  23
 Calling: none
 Returns: ax      Music processing status (0-disabled, 1-enabled)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicStatus         proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+23*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicStatus         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: BPM%    New music BPM 0=no set
 Returns: ax      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicBPM            proc    Uses es, BPM:word
    mov     bx, BPM
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+24*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicBPM            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: Tempo%  New music tempo, FFh=no set
 Returns: ax      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicTempo          proc    Uses es, Tempo:word
    mov     bx, Tempo
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+25*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicTempo          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: ah      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicOrder          proc    Uses es, Order:Word
    mov     bx, Order
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+26*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicOrder          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: Pat%    New music pattern, FFh=no set
 Returns: ax      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicPattern        proc        Uses es, Pat:Word
    mov     bx, Pat
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+27*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicPattern        endp
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicRow                                                     28
 Calling: none
 Returns: ax      Current music row
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicRow            proc        Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+28*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicRow            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicLoop                                                    29
 Calling: LoopSt%  0 - Disable music looping
                   1 - Enable music looping
                  FF - no change
 Returns: ax      Number of times music has looped
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicLoop           proc        Uses es, LoopStatus:Word
    mov     bx, LoopStatus
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+29*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicLoop           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: Vol%    New global music volume (0-64). 0FFh=no change
 Returns: ax      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicVolume         proc        Uses es, Vol:Word
    mov     bx, Vol
    mov     ah, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+30*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicVolume         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                   41
 Calling: bl      Channel number (1..32)
          cl      Sample number (0..255)
          ax      Sampling rate (4000..65535)
          dl      Volume for playback
          dh      Pan position to start with
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlaySample          proc        Uses es di, Chan:word, Sam:word, Rate:word, \
                                            Vol:word, Pan:word
    mov     di, Chan
    mov     bl, [di]
    mov     di, Sam
    mov     cl, [di]
    mov     di, Rate
    mov     ax, [di]
    mov     di, Vol
    mov     dl, [di]
    mov     di, Pan
    mov     dh, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+41*4]   ;Call the function
    Ret
PlaySample          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlayNote                                                     42
 Calling: bl      Channel number (1..32)
          cl      Sample number (0..255)
          ah      Note octave (0..7)
          al      Note number (0..11)
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlayNote            proc        Uses es di, Chan:word, Sam:word, Octave:word, \
                                            Note:word
    mov     di, Chan
    mov     bl, [di]
    mov     di, Sam
    mov     cl, [di]
    mov     di, Octave
    mov     ah, [di]
    mov     di, Note
    mov     al, [di]
    mov     es, MSESegment
    call    DWord PTR es:[DRVFunc+42*4]   ;Call the function
    ret
PlayNote            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetChannelTable                                              44
 Calling: Chan%   Channel number (1..32)
          TSeg%   Segment of channel table buffer
          TOff%   Offset of channel table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetChannelTable     proc        Uses es di, Chan:Word, TSeg:Word, TOff:Word
    mov     di, Chan
    mov     bl, [di]
    mov     di, TSeg
    mov     dx, [di]
    mov     di, TOff
    mov     di, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+44*4]   ;Call the function
    Ret
GetChannelTable     endp
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: Chan%   Channel number (1..32)
          Pan%    New pan position (0..15). FFh=no set
 Returns: ax      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPan          proc    Uses es di, Chan:Word, Pan:Word
    mov     di, Chan
    mov     bl, [di]
    mov     di, Pan
    mov     al, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+45*4]   ;Call the function
    movzx   ax, al
    Ret
ChannelPan          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: Chan%   Channel number (1..32)
          VU%     New VU setting, 0FFh=no set
 Returns: ax      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVU           proc        Uses es di, Chan:Word, VU:Word
    mov     di, Chan
    mov     bl, [di]
    mov     di, VU
    mov     al, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+46*4]   ;Call the function
    movzx   ax, al
    Ret
ChannelVU           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                   47
 Calling: Chan%   Channel number (1..32)
          Vol%    New volume setting (0..64). FFh=no set
 Returns: ax      Channel's volume setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVol          proc    Uses es di, Chan:Word, Vol:Word
    mov     di, Chan
    mov     bl, [di]
    mov     di, Vol
    mov     al, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+47*4]   ;Call the function
    movzx   ax, al
    Ret
ChannelVol          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: Chan%   Channel number (1..32)
          Pos%    New play position (0..65534). FFFFh=no set
 Returns: ax      Channel's play position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPos          proc    Uses es di, Chan:Word, Pos:Word
    mov     di, Chan
    mov     bl, [di]
    mov     di, Pos
    mov     ax, [di]
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+48*4]   ;Call the function
    xor     dx, dx
    ret
ChannelPos          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetSampleTable                                               49
 Calling: Samp%   Sample number (0..254)
          TSeg%   Segment of sample table buffer
          TOff%   Offset of sample table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetSampleTable      proc        Uses es di, Samp:Word, TSeg:Word, TOff:Word
    mov     di, Samp
    mov     bl, [di]
    mov     di, TSeg
    mov     dx, [di]
    mov     di, TOff
    mov     di, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+49*4]   ;Call the function
    Ret
GetSampleTable      endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: Lft%    Left scope value (16bit)
          Rgt%    Right scope value (16bit)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetMainScope        proc        Uses es, Lft:Word, Rgt:Word
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+50*4]   ;Call the function
    mov     bx, Lft
    mov     [bx], ax
    mov     bx, Rgt
    mov     [bx], cx
    Ret
GetMainScope        endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterSample                                               60
 Calling: SamNum% Sample number
          SamSeg% Segment of sample header
          SamOff% Offset of sample header
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegisterSample      proc    Uses es di si, SamNum:Word, SamSeg:Word, SamOff:Word
    mov     di, SamNum
    mov     bl, [di]
    mov     di, SamSeg
    mov     dx, [di]
    mov     di, SamOff
    mov     si, [di]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+60*4]   ;Call the function
    Ret
RegisterSample      endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterPatterns                                             61
 Calling: PatSeg% Segment of pattern segment table
          PatOff% Offset of pattern segment table
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegisterPatterns    proc    Uses es si, PatSeg:Word, PatOff:Word
    mov     bx, PatSeg
    mov     dx, [bx]
    mov     bx, PatOff
    mov     si, [bx]
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+61*4]   ;Call the function
    Ret
RegisterPatterns    endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterOrders                                               62
 Calling: OSeg%   Segment of order table
          OOff%   Offset of order table
          NOO%    Number of orders
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
RegisterOrders      proc    Uses es ds si, OSeg:Word, OOff:Word, NOO:Word
    mov     es, MSESegment
    mov     bx, OOff
    mov     si, [bx]
    mov     bx, OSeg
    mov     dx, [bx]
    mov     bx, NOO
    mov     ch, [bx]
    Call    DWord PTR es:[DRVFunc+62*4]   ;Call the function
    Ret
RegisterOrders      endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UnloadModule                                                 64
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
UnloadModule        proc    Uses es
    mov     es, MSESegment
    Call    DWord PTR es:[DRVFunc+64*4]
    Ret
UnloadModule        endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CopyDRAM                                                     65
 Calling: es      Segment of memory to copy
          si:di   DRAM memory location to copy to
          cx      Bytes of memory to copy
 Returns: cx      Zero if this MSE uses GUS DRAM, unchanged if no DRAM use
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
CopyDRAM            proc    Uses gs es si di, SSeg:word, DRAM:word, Bytes:word
    mov     bx, SSeg
    mov     es, [bx]

    mov     bx, DRAM
    mov     si, [bx+2]
    mov     di, [bx]

    mov     bx, Bytes
    mov     cx, [bx]
    mov     gs, MSESegment
    Call    DWord PTR gs:[DRVFunc+65*4]

    mov     bx, Bytes
    mov     [bx], cx
    Ret
CopyDRAM            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadGDM                                                      66
 Calling: Hand%   File handle to load from
          FOff%   Offset into file to load from
          Flags%  Load flags
          GSeg%   Segment address of GDM header buffer
          GOff%   Offset address of GDM header buffer
 Returns: Flags%  Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
LoadGDM             proc \
Uses gs ecx di, Hand:word, FOff:word, Flags:word, GSeg:word, GOff:word

    mov     bx, Hand
    mov     ax, [bx]
    mov     bx, FOff
    mov     ecx, [bx]
    mov     bx, GSeg
    mov     dx, [bx]
    mov     bx, GOff
    mov     di, [bx]
    mov     bx, Flags
    mov     bl, [bx]

    mov     gs, MSESegment
    Call    DWord PTR gs:[DRVFunc+66*4]

    mov     di, Flags
    mov     [di], bx

    Ret
LoadGDM             endp
db  IDString
End
