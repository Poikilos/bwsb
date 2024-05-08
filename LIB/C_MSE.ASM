;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                      Bells, Whistles, and Sound Boards
;        Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;    (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; C_MSE.ASM - C <-> MSE Interface routines
;             Written by Edward Schlunder (1995)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
include id.inc

IFDEF LMM
.model large, c                       ;Define large model/C calling syntax
ELSE
.model medium, c                      ;Define medium model/C calling syntax
ENDIF

.386P
.data

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

Public MSESegment
MSESegment      dw      0              ;Segment in memory where MSE resides

IFNDEF LMM
SndDevName      db      20 dup (0)
ENDIF
.code

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
 Routine: LoadMSE                                                       0
 Calling: File    ASCIIZ file/path of MSE
          OverRat Oversampling rate (xxKHz, Range 5..45)
          BufferS Mixing buffer size (Range 256..32767)
          Base    Sound device base I/O address. FFFFh for autodetect.
          IRQ     Sound device IRQ level. FFh for autodetect.
          DMA     Sound device DMA channel. FFh for autodetect.
 Returns: Base    Base I/O address used
          IRQ     IRQ level used
          DMA     DMA channel used
          ax      Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public LoadMSE
IF @DataSize
LoadMSE             Proc    Uses es ds si di, File:dword, FileOff:dword,  \
                            OverRate:byte, BufferSize:word, \
                            Base:dword, IRQ:dword, DMA:dword
ELSE
LoadMSE             Proc    Uses es ds si di, File:word, FileOff:dword, \
                            OverRate:byte, BufferSize:word, \
                            Base:word, IRQ:word, DMA:word
ENDIF
Local   FileHandle:word, FileSize:word

    push    ds
    mov     ax, 3D00h
IF @DataSize
    lds     dx, File
ELSE
    mov     dx, File
ENDIF
    int     21h
    pop     ds
    jc      Exit                       ;Exit if error
    mov     FileHandle, ax

    mov     bx, ax                     ;file handle
    mov     ax, 4200h                  ;find out MSE size
    mov     ecx, FileOff
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
    add     ax, 0Fh                    ;Saftey margin
    shr     ax, 4
    mov     bx, ax
    mov     ax, 4800h                  ;Allocate memory for MSE file
    int     21h
    Jc      Exit
    mov     MSESegment, ax

    mov     ax, 4200h                  ;Move back to beginning of file
    mov     bx, FileHandle
    mov     cx, word ptr FileOff+2
    mov     dx, word ptr FileOff
    int     21h
    jc      Exit

    push    ds
    mov     ax, 3F00h                  ;Load the music/sound engine
    mov     cx, FileSize
    Xor     dx, dx
    mov     ds, MSESegment
    Int     21h
    pop     ds
    Jc      Exit

    mov     ah, 3Eh                    ;Close file handle
    int     21h
    jc      Exit

    mov     ax, 0Ah                    ;Check for bad ID header
    mov     es, MSESegment
    mov     cx, 14
    mov     si, Offset MSEID
    mov     di, MSECopyright
    Rep     Cmpsb
    Jne     Exit
    Add     di, 7
    mov     cx, 21
    Rep     Cmpsb
    Jne     Exit

    mov     bx, DRVFunc+2              ;Get location of function table
    Xor     ch, ch
    mov     cl, es:[DRVNOF]            ;Get number of functions
    Inc     cl

WriteSeg:
    mov     es:[bx], es                ;Write all the segments in function table
    Add     bx, 4                      ;Increment over the offsets
    Loop    WriteSeg                   ;Go through all the functions

    mov     ah, OverRate
IF @DataSize
    push    es
    les     bx, Base
    mov     dx, es:[bx]
    les     bx, IRQ
    mov     ch, es:[bx]
    les     bx, DMA
    mov     cl, es:[bx]
    pop     es
ELSE
    mov     bx, Base
    mov     dx, [bx]
    mov     bx, IRQ
    mov     ch, [bx]
    mov     bx, DMA
    mov     cl, [bx]
ENDIF
    mov     bh, byte ptr BufferSize+1

    call    dword ptr es:[DRVFunc+0*4]     ;Call the function

IF @DataSize
    les     bx, DMA
    mov     es:[bx], cl
    les     bx, IRQ
    mov     es:[bx], ch
    les     bx, Base
    mov     es:[bx], dx
ELSE
    mov     bx, DMA
    mov     [bx], cl
    mov     bx, IRQ
    mov     [bx], ch
    mov     bx, Base
    mov     [bx], dx
ENDIF

    xor     ah, ah
Exit:
    ret
LoadMSE             EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DeviceName
 Calling: none
 Returns: dx:ax   pointer to sound device name
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
IFDEF LMM
DeviceName          proc
    mov     dx, MSESegment
    mov     ax, DRVSndName
ELSE
DeviceName          proc    uses es ds si di
    mov     ax, ds
    mov     es, ax
    mov     di, Offset SndDevName
    mov     ds, MSESegment
    mov     si, DRVSndName
    mov     cx, 20
    rep     movsb
    mov     ax, Offset SndDevName
ENDIF
    ret
DeviceName          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeMSE                                                       1
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public FreeMSE
FreeMSE             Proc    uses ds
    cmp     MSESegment, 0                ;Has the MSE already been freed?
    jz      Exit                         ;Exit if so

    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+1*4]
    mov     ah, 49h                      ;Release MSE memory
    int     21h
    mov     MSESegment, 0                ;Flag that MSE is no longer loaded

IF Evaluation
%OUT Evaluation Version!
    Cmp     SignedOff, 0
    Jnz     Exit
    mov     SignedOff, 1
    mov     ax, @data
    mov     ds, ax
    mov     ah, 9h
    mov     dx, Offset UnregBanner
    Int     21h
ENDIF
Exit:
    Ret
FreeMSE             EndP

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
 Routine: StartOutput                                                   2
 Calling: Chan    Number of output channels (Range 1..32)
          Amp     Amplification value (Range -9..9)
 Returns: ax      Actual oversampling rate being used
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public StartOutput
StartOutput         Proc    Uses es, Chan:byte, Amp:byte
    mov     al, Chan
    mov     bh, Amp
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+2*4]
    mov     ax, bx
    ret
StartOutput         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopOutput                                                    3
 Calling: None
 Returns: None
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public StopOutput
StopOutput          Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+3*4]
    Ret
StopOutput          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MixStatus
MixStatus           Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+4*4]
    Ret
MixStatus           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MixForground
MixForground        Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+5*4]   ;Call the function
    Ret
MixForground        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: Mix    New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public SetAutoMix
SetAutoMix          Proc    Uses es, Mix:byte
    mov     al, Mix
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+6*4]
    Ret
SetAutoMix          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartMusic                                                   20
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public StartMusic
StartMusic          Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+20*4]   ;Call the function
    Ret
StartMusic          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopMusic                                                    21
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public StopMusic
StopMusic           Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+21*4]   ;Call the function
    Ret
StopMusic           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: Hertz   New Amiga period Hertz to use
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public AmigaHertz
AmigaHertz          Proc    Uses es eax, Hertz:dword
    mov     eax, Hertz

    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+22*4]   ;Call the function
    Ret
AmigaHertz          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicStatus                                                  23
 Calling: none
 Returns: ax      Music processing status (0-disabled, 1-enabled)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicStatus
MusicStatus         Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+23*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicStatus         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: BPM     New music BPM 0=no set
 Returns: ax      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicBPM
MusicBPM            Proc    Uses es, BPM:byte
    mov     ah, BPM
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+24*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicBPM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: Tempo   New music tempo, FFh=no set
 Returns: ax      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicTempo
MusicTempo          Proc    Uses es, Tempo:byte
    mov     ah, Tempo
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+25*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicTempo          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: ah      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicOrder
MusicOrder          Proc    Uses es, Order:byte
    mov     ah, Order
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+26*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicOrder          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: Pat     New music pattern, FFh=no set
 Returns: ax      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicPattern
MusicPattern        Proc        Uses es, Pat:byte
    mov     ah, Pat
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+27*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicPattern        EndP
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicRow                                                     28
 Calling: none
 Returns: ax      Current music row
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicRow
MusicRow            Proc        Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+28*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicRow            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicLoop                                                    29
 Calling: LoopSt   0 - Disable music looping
                   1 - Enable music looping
                  FF - no change
 Returns: ax      Number of times music has looped
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicLoop
MusicLoop           Proc        Uses es, LoopStatus:byte
    mov     ah, LoopStatus
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+29*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicLoop           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: Vol     New global music volume (0-64). 0FFh=no change
 Returns: ax      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicVolume
MusicVolume         Proc        Uses es, Vol:byte
    mov     ah, Vol
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+30*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicVolume         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                   41
 Calling: Chan    Channel number (1..32)
          Sam     Sample number (0..255)
          Rate    Sampling rate (4000..65535)
          Vol     Volume for playback
          Pan     Pan position to start with
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public PlaySample
PlaySample          Proc        Uses es di, Chan:byte, Sam:byte, Rate:word, \
                                            Vol:byte, Pan:byte
    mov     bl, Chan
    mov     cl, Sam
    mov     ax, Rate
    mov     dl, Vol
    mov     dh, Pan
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+41*4]   ;Call the function
    Ret
PlaySample          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlayNote                                                     42
 Calling: bl      Channel number (1..32)
          cl      Sample number (0..255)
          ah      Note octave (0..7)
          al      Note number (0..11)
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlayNote            proc        Uses es di, Chan:byte, Sam:byte, Octave:byte, \
                                            Note:byte
    mov     bl, Chan
    mov     cl, Sam
    mov     ah, Octave
    mov     al, Note
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+42*4]   ;Call the function
    ret
PlayNote            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetChannelTable                                              44
 Calling: Chan    Channel number (1..32)
          TSeg    Segment of channel table buffer
          TOff    Offset of channel table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetChannelTable
GetChannelTable     Proc        Uses es di, Chan:byte, TSeg:Word, TOff:Word
    mov     bl, Chan
    mov     dx, TSeg
    mov     di, TOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+44*4]   ;Call the function
    Ret
GetChannelTable     EndP
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: Chan    Channel number (1..32)
          Pan     New pan position (0..15). FFh=no set
 Returns: ax      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelPan
ChannelPan          Proc    Uses es di, Chan:byte, Pan:byte
    mov     bl, Chan
    mov     al, Pan
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+45*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelPan          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: Chan    Channel number (1..32)
          VU      New VU setting, 0FFh=no set
 Returns: ax      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelVU
ChannelVU           Proc        Uses es di, Chan:byte, VU:byte
    mov     bl, Chan
    mov     al, VU
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+46*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVU           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                   47
 Calling: Chan    Channel number (1..32)
          Vol     New volume setting (0..64). FFh=no set
 Returns: ax      Channel's volume setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelVol
ChannelVol          Proc    Uses es di, Chan:byte, Vol:byte
    mov     bl, Chan
    mov     al, Vol
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+47*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVol          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: Chan    Channel number (1..32)
          Pos     New play position (0..65534). FFFFh=no set
 Returns: ax      Channel's play position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelPos
ChannelPos          proc    Uses es, Chan:byte, Pos:word
    mov     bl, Chan
    mov     ax, Pos
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+48*4]   ;Call the function
    ret
ChannelPos          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetSampleTable                                               49
 Calling: Samp    Sample number (0..254)
          TSeg    Segment of sample table buffer
          TOff    Offset of sample table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetSampleTable
GetSampleTable      Proc        Uses es di, Samp:byte, TSeg:word, TOff:word
    mov     bl, Samp
    mov     dx, TSeg
    mov     di, TOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+49*4]   ;Call the function
    Ret
GetSampleTable      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: Lft     Left scope value (16bit)
          Rgt     Right scope value (16bit)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetMainScope
IF @DataSize
GetMainScope        Proc        Uses es, Lft:dword, Rgt:dword
ELSE
GetMainScope        Proc        Uses es, Lft:word, Rgt:word
ENDIF
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+50*4]   ;Call the function
IF @DataSize
    les     bx, Lft
    mov     es:[bx], ax
    les     bx, Rgt
    mov     es:[bx], cx
ELSE
    mov     bx, Lft
    mov     [bx], ax
    mov     bx, Rgt
    mov     [bx], cx
ENDIF
    Ret
GetMainScope        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterSample                                               60
 Calling: SamNum  Sample number
          SamSeg  Segment of sample header
          SamOff  Offset of sample header
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public RegisterSample
RegisterSample      Proc    Uses es di si, SamNum:byte, SamSeg:word, SamOff:word
    mov     bl, SamNum
    mov     dx, SamSeg
    mov     si, SamOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+60*4]   ;Call the function
    Ret
RegisterSample      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegisterPatterns                                             61
 Calling: PatSeg  Segment of pattern segment table
          PatOff  Offset of pattern segment table
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public RegisterPatterns
RegisterPatterns    Proc    Uses es si, PatSeg:word, PatOff:word
    mov     dx, PatSeg
    mov     si, PatOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+61*4]   ;Call the function
    Ret
RegisterPatterns    EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: RegigterOrders                                               62
 Calling: OSeg    Segment of order table
          OOff    Offset of order table
          NOO     Number of orders
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public RegisterOrders
RegisterOrders      Proc    Uses es ds si, OSeg:word, OOff:word, NOO:byte
    mov     es, MSESegment
    mov     si, OOff
    mov     dx, OSeg
    mov     ch, NOO
    Call    dword ptr es:[DRVFunc+62*4]   ;Call the function
    Ret
RegisterOrders      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UnloadModule                                                 64
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public UnloadModule
UnloadModule        Proc    Uses es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+64*4]
    Ret
UnloadModule        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CopyDRAM                                                     65
 Calling: SSeg    Segment of memory to copy
          DRAM    DRAM memory location to copy to (32 bit)
          Bytes   Bytes of memory to copy
 Returns: Bytes   Zero if this MSE uses GUS DRAM, unchanged if no DRAM use
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public CopyDRAM
CopyDRAM            Proc    Uses gs es si di, SSeg:word, DRAM:dword, Bytes:word
    mov     es, SSeg

    mov     si, word ptr DRAM+2
    mov     di, word ptr DRAM

    mov     bx, Bytes
    mov     cx, [bx]
    mov     gs, MSESegment
    Call    dword ptr gs:[DRVFunc+65*4]

    mov     bx, Bytes
    mov     [bx], cx
    Ret
CopyDRAM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadGDM                                                      66
 Calling: Hand    File handle to load from
          FOff    Offset into file to load from
          Flags   Load flags
          GOff    Pointer address of GDM header buffer
 Returns: Flags   Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public LoadGDM
IF @DataSize
LoadGDM             Proc \
uses gs ecx di, Hand:word, FOff:dword, Flags:dword, GOff:dword
ELSE
LoadGDM             Proc \
uses gs ecx di, Hand:word, FOff:dword, Flags:word, GOff:word
ENDIF

    mov     ax, Hand
    mov     ecx, FOff
IF @DataSize
%OUT Large Memory Model
    mov     dx, word ptr GOff+2
    mov     di, word ptr GOff
    lgs     bx, Flags
    mov     bl, gs:[bx]
ELSE
    mov     dx, ds
    mov     di, GOff
    mov     bx, Flags
    mov     bl, [bx]
ENDIF

    mov     gs, MSESegment
    Call    dword ptr gs:[DRVFunc+66*4]
IF @DataSize
    lgs     di, Flags
    mov     gs:[di], bx
ELSE
    mov     di, Flags
    mov     [di], bx
ENDIF

    Ret
LoadGDM             EndP
db  IDString
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AllocSample                                                  67
 Calling: SamHead Address of sample header buffer
          SamNum  Sample number to load into
 Returns: ax      error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public AllocSample
IF @DataSize
AllocSample         proc    uses si, SamNum:byte, SamHead:dword
ELSE
AllocSample         proc    uses si, SamNum:byte, SamHead:word
ENDIF

    mov     si, word ptr SamHead
IF @DataSize
    mov     dx, word ptr SamHead+2
ELSE
    mov     dx, ds
ENDIF
    mov     cl, SamNum
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+67*4]
    ret
AllocSample         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeSample                                                   68
 Calling: SamNum  Sample number to load into
 Returns: ax      error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public FreeSample
FreeSample          proc    SamNum:byte
    mov     cl, SamNum                  ;setup CL for MSE call

    mov     es, MSESegment              ;get segment of MSE
    call    dword ptr es:[DRVFunc+68*4] ;call the MSE function 68

    ret                                 ;return to calller
FreeSample          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: EmsExist
 Calling: none
 Returns: ax      0 - ems services not detected,
                  1 - ems services detected
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
EmmIdCode           db      'EMMXXXX0'
public EmsExist
EmsExist            proc    uses si
    xor     ax, ax
    mov     es, ax                     ;set es: segment 0
    mov     bx, 19Eh                   ;get offset of interrupt 67h vector
    mov     ax, es:[bx]                ;find segment of ems driver
    mov     es, ax                     ;reload es with it

    mov     cl, 8                      ;eight byte long id string
    mov     si, 10                     ;starts in ems driver at offset 10
    xor     bx, bx
CmpLoop:
    mov     al, es:[si]
    cmp     al, cs:[EmmIdCode+bx]      ;compare to our id code in cs
    jne     EmsNoExist
    inc     si
    inc     bx
    dec     cl
    jnz     CmpLoop

EmsYesExist:
    mov     ax, 1
    ret

EmsNoExist:
    xor     ax, ax
    ret
EmsExist            endp

End

