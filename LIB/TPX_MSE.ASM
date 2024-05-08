;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;   (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; TPX_MSE.ASM - Turbo Pascal <-> MSE Interface routines
;               Written by Alex Chalfin and Edward Schlunder (1994-95)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
include id.inc

.model large, pascal           ;Define memory model/Pascal call syntax
.386
.data

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
snddevname      db      21 dup (?)

.code
MSESegment      dw      0

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
LoadMSE             Proc    Uses es ds si di, File:dword, FileOff:dword, \
                            OverRate:byte, BufferSize:word, Base:dword, \
                            IRQ:dword, DMA:dword
Local   FileHandle:word, FileSize:word

    push    ds
    mov     ax, 3D00h
    lds     di, File
    movzx   bx, byte ptr ds:[di]       ;Get size of filename
    inc     di
    mov     ch, byte ptr ds:[di+bx]    ;temporary save
    mov     byte ptr ds:[di+bx], 0     ;make filename ASCIIZ
    mov     dx, di
    int     21h
    mov     byte ptr ds:[di+bx], ch
    pop     ds
    jc      Exit                       ;Exit if error
    mov     FileHandle, ax

    mov     bx, ax
    mov     ax, 4200h                  ;Find file size
    mov     ecx, FileOff
    add     ecx, DRVSize+1
    mov     dx, cx
    shr     ecx, 16
    int     21h
    Jc      Exit

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
    Int     21h
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
    xor     dx, dx
    mov     ds, MSESegment
    int     21h
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
    push    es
    les     bx, Base
    mov     dx, es:[bx]
    les     bx, IRQ
    mov     ch, es:[bx]
    les     bx, DMA
    mov     cl, es:[bx]
    pop     es
    mov     bh, byte ptr BufferSize+1

    call    dword ptr es:[DRVFunc+0*4]     ;Call the function

    les     bx, DMA
    mov     es:[bx], cl
    les     bx, IRQ
    mov     es:[bx], ch
    les     bx, Base
    mov     es:[bx], dx

    xor     ah, ah
Exit:
    ret
LoadMSE             EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DeviceName
 Calling: none
 Returns: dx:ax   pointer to sound device name
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DeviceName          proc
    push    bp

    mov     bp, sp

    push    es
    push    si
    push    ds
    push    di

    mov     ax, @data
    mov     es, ax
    mov     di, offset snddevname
    mov     byte ptr es:[di], 20
    inc     di
    mov     ds, MSESegment
    mov     si, DRVSndName
    mov     cx, 20
    rep     movsb

    mov     word ptr [bp+6], offset snddevname
    mov     word ptr [bp+8], @data

    pop     di
    pop     ds
    pop     si
    pop     es

    pop     bp
    ret
DeviceName          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeMSE
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
FreeMSE   Proc    Uses es ds
    cmp     cs:MSESegment, 0             ;Has the MSE already been freed?
    jz      Exit                         ;Exit if so

    mov     es, cs:MSESegment
    call    DWord PTR es:[DRVFunc+1*4]
    mov     ah, 49h                      ;Release MSE memory
    int     21h
    mov     cs:MSESegment, 0             ;Flag that MSE is no longer loaded

IF Evaluation
%OUT Evaluation Version!
    Cmp     SignedOff, 0
    Jnz     Exit
    Mov     SignedOff, 1
    Mov     ax, @data
    Mov     ds, ax
    Mov     ah, 9h
    Mov     dx, Offset UnregBanner
    Int     21h
ENDIF
Exit:
    Ret
FreeMSE  EndP

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
StartOutput         Proc    Uses es, Chan:Word, Amp:Word
    Mov     ax, Chan
    Mov     bh, byte ptr Amp
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+2*4]
    Mov     ax, bx
    Xor     dx, dx
    Ret
StartOutput         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopOutput                                                    3
 Calling: None
 Returns: None
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopOutput          Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+3*4]
    Ret
StopOutput          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixStatus           Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+4*4]
    Ret
MixStatus           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixForground        Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+5*4]   ;Call the function
    Ret
MixForground        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: Mix    New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SetAutoMix          Proc    Uses es, Mix:Byte
    Mov     al, Mix
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+6*4]
    Ret
SetAutoMix          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartMusic                                                   20
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartMusic          Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+20*4]   ;Call the function
    Ret
StartMusic          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopMusic                                                    21
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopMusic           Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+21*4]   ;Call the function
    Ret
StopMusic           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
AmigaHertz          Proc    Uses es eax, Hertz:dword
    Mov     eax, Hertz

    Mov     es, cs:MSESegment
    Call    dword ptr es:[DRVFunc+22*4]     ;Call the function
    Ret
AmigaHertz          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicStatus                                                  23
 Calling: none
 Returns: ax      Music processing status (0-disabled, 1-enabled)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicStatus         Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+23*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicStatus         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: BPM     New music BPM 0=no set
 Returns: ax      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicBPM            Proc    Uses es, BPM:Byte
    Mov     ah, BPM
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+24*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicBPM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: Tempo   New music tempo, FFh=no set
 Returns: ax      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicTempo          Proc    Uses es, Tempo:Byte
    Mov     ah, Tempo
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+25*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicTempo          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: al      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicOrder          Proc    Uses es, Order:Byte
    Mov     ah, Order
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+26*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicOrder          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: Pat     New music pattern, FFh=no set
 Returns: ax      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicPattern        Proc        Uses es, Pat:Byte
    Mov     ah, Pat
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+27*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicPattern        EndP
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicRow                                                     28
 Calling: none
 Returns: ax      Current music row
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicRow            Proc        Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+28*4]   ;Call the function
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
MusicLoop           Proc        Uses es, LoopStatus:Byte
    Mov     ah, LoopStatus
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+29*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicLoop           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: Vol     New global music volume (0-64). 0FFh=no change
 Returns: ax      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicVolume         Proc        Uses es, Vol:Byte
    Mov     ah, Vol
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+30*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicVolume         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                   41
 Calling: bl      Channel number (1..32)
          cl      Sample number (0..255)
          ax      Sampling rate (4000..65535)
          dl      Volume for playback
          dh      Pan position to start with
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlaySample          Proc        Uses es, Chan:Byte, Sam:Byte, Rate:Word, \
                                         Vol:Byte, Pan:Byte
    Mov     bl, Chan
    Mov     cl, Sam
    Mov     ax, Rate
    Mov     dl, Vol
    Mov     dh, Pan
    Mov     es, cs:MSESegment
    Call    dword ptr es:[DRVFunc+41*4]
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
GetChannelTable     Proc        Uses es di, Chan:Byte, TSeg:Word, TOff:Word
    Mov     bl, Chan
    Mov     dx, TSeg
    Mov     di, TOff
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+44*4]   ;Call the function
    Ret
GetChannelTable     EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: Chan    Channel number (1..32)
          Pan     New pan position (0..15). FFh=no set
 Returns: ax      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPan          Proc    Uses es, Chan:Byte, Pan:Byte
    Mov     bl, Chan
    Mov     al, Pan
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+45*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelPan          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: Chan    Channel number (1..32)
          VU      New VU setting, 0FFh=no set
 Returns: ax      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVU           Proc        Uses es, Chan:Byte, VU:Byte
    Mov     bl, Chan
    Mov     al, VU
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+46*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVU           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                    47
 Calling: Chan    Channel number (1..32)
          Vol     New Volume setting, 0FFh=no set
 Returns: ax      Channel's Volume setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVol           Proc        Uses es, Chan:Byte, Vol:Byte
    Mov     bl, Chan
    Mov     al, Vol
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+47*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVol           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: Chan    Channel number (1..32)
          Pos     New play position (0..65534). FFFFh=no set
 Returns: ax      Channel's play position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
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
GetSampleTable      Proc        Uses es di, Samp:Byte, TSeg:Word, TOff:Word
    Mov     bl, Samp
    Mov     dx, TSeg
    Mov     di, TOff
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+49*4]   ;Call the function
    Ret
GetSampleTable      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: Lft     Left scope value (16bit)
          Rgt     Right scope value (16bit)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetMainScope        Proc        Uses es, Lft:DWord, Rgt:DWord
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+50*4]   ;Call the function
    Les     bx, Lft
    Mov     es:[bx], ax
    Les     bx, Rgt
    Mov     es:[bx], cx
    Ret
GetMainScope        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UnloadModule                                                 64
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
UnloadModule        Proc    Uses es
    Mov     es, cs:MSESegment
    Call    DWord PTR es:[DRVFunc+64*4]
    Ret
UnloadModule        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadGDM                                                      66
 Calling: Hand    File handle to load from
          FOff    Offset into file to load from
          Flags   Load flags
          GSeg    Segment address of GDM header buffer
          GOff    Offset address of GDM header buffer
 Returns: Flags   Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
LoadGDM             proc \
uses gs ecx di, Hand:dword, FOff:dword, Flags:dword, GSeg:word, GOff:word

    lgs     di, Flags
    mov     bx, word ptr gs:[di]
    lgs     di, Hand
    mov     ax, word ptr gs:[di]
    mov     ecx, FOff
    mov     dx, GSeg
    mov     di, GOff

    mov     gs, cs:MSESegment
    call    dword ptr gs:[DRVFunc+66*4]

    lgs     di, Flags
    mov     Word Ptr gs:[di], bx
    ret
LoadGDM             endp
db  IDString
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AllocSample                                                  67
 Calling: SamHead Address of sample header buffer
          SamNum  Sample number to load into
 Returns: ax      error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public AllocSample
AllocSample         proc    uses si, SamNum:byte, SamHead:dword
    int     3
    mov     si, word ptr SamHead
    mov     dx, word ptr SamHead+2
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
    int     3
    mov     cl, SamNum                  ;setup CL for MSE call

    mov     es, MSESegment              ;get segment of MSE
    call    dword ptr es:[DRVFunc+68*4] ;call the MSE function 68

    ret                                 ;return to calller
FreeSample          endp

End
