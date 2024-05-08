;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                      Bells, Whistles, and Sound Boards
;        Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;    (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; PB_MSE.ASM - PowerBasic <-> MSE Interface routines
;              Written by Edward Schlunder (1995)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
include ..\include\id.inc

.model large, basic                   ;Define large model/Basic calling syntax
.386P
code segment use16
assume cs:code

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

extrn       get$loc:far
extrn       get$alloc:far

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
LoadMSE             proc    uses es ds si di, File:dword, FileOff:dword, \
                            OverRate:word, BufferSize:word, Base:dword, \
                            IRQ:dword, DMA:dword
Local   FileHandle:word, FileSize:word
    push    ds
    les     di, File
    push    word ptr es:[di]
    call    get$loc                    ;DX:AX - pointer to File$; CX - LEN
    mov     ds, dx
    mov     dx, ax

    mov     di, dx
    add     di, cx
    mov     bl, byte ptr ds:[di]
    mov     byte ptr ds:[di], 0

    mov     ax, 3D00h                  ;Open the file
    int     21h
    mov     byte ptr ds:[di], bl
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
    int     21h
    jc      Exit
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
    int     21h
    pop     ds
    Jc      Exit

    mov     ah, 3Eh                    ;Close file handle
    int     21h
    jc      Exit

    mov     ax, cs
    mov     ds, ax
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

    mov     ah, byte ptr OverRate
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
 Returns: ax      handle for string that hold device name
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
DeviceName          proc    uses ds di si
    push    20
    call    get$alloc
    or      ax, ax
    jz      Exit
    mov     bx, ax

    push    ax
    call    get$loc
    mov     es, dx
    mov     di, ax

    mov     ds, MSESegment
    mov     si, DRVSndName             ;DS:SI - Sound Device Name in MSE file

    mov     cx, 20
    cld
    rep     movsb

    mov     ax, bx
Exit:
    ret
DeviceName          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeMSE                                                       1
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
FreeMSE             proc    uses ds
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
    mov     ax, cs
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
 Routine: StartOutput                                                   2
 Calling: Chan    Number of output channels (Range 1..32)
          Amp     Amplification value (Range -9..9)
 Returns: ax      Actual oversampling rate being used
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartOutput         proc    Chan:word, Amp:word
    mov     al, byte ptr Chan
    mov     bh, byte ptr Amp
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+2*4]
    xor     dx, dx
    mov     ax, bx
    ret
StartOutput         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopOutput                                                    3
 Calling: None
 Returns: None
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopOutput          proc
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+3*4]
    ret
StopOutput          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixStatus           proc
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+4*4]
    ret
MixStatus           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MixForground        proc
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+5*4]   ;Call the function
    ret
MixForground        endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: Mix    New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
SetAutoMix          proc    Mix:word
    mov     al, byte ptr Mix
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+6*4]
    ret
SetAutoMix          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StartMusic                                                   20
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StartMusic          proc
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+20*4]   ;Call the function
    Ret
StartMusic          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: StopMusic                                                    21
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
StopMusic           proc
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+21*4]   ;Call the function
    Ret
StopMusic           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: Hertz   New Amiga period Hertz to use
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
AmigaHertz          proc    Hertz:dword
    mov     eax, Hertz

    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+22*4]   ;Call the function
    Ret
AmigaHertz          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicStatus                                                  23
 Calling: none
 Returns: ax      Music processing status (0-disabled, 1-enabled)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicStatus         proc
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+23*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicStatus         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: BPM     New music BPM 0=no set
 Returns: ax      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicBPM            proc    BPM:word
    mov     ah, byte ptr BPM
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+24*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicBPM            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: Tempo   New music tempo, FFh=no set
 Returns: ax      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicTempo          proc    Tempo:word
    mov     ah, byte ptr Tempo
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+25*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicTempo          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: ah      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicOrder          Proc    Order:word
    mov     ah, byte ptr Order
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+26*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicOrder          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: Pat     New music pattern, FFh=no set
 Returns: ax      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicPattern        proc        Pat:word
    mov     ah, byte ptr Pat
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+27*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicPattern        endp
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicRow                                                     28
 Calling: none
 Returns: ax      Current music row
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicRow            proc
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+28*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicRow            endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicLoop                                                    29
 Calling: LoopSt   0 - Disable music looping
                   1 - Enable music looping
                  FF - no change
 Returns: ax      Number of times music has looped
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicLoop           proc    LoopStatus:word
    mov     ah, byte ptr LoopStatus
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+29*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicLoop           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: Vol     New global music volume (0-64). 0FFh=no change
 Returns: ax      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
MusicVolume         proc    Vol:word
    mov     ah, byte ptr Vol
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+30*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicVolume         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                   41
 Calling: Chan    Channel number (1..32)
          Sam     Sample number (0..255)
          Rate    Sampling rate (4000..65535)
          Vol     Volume for playback
          Pan     Pan position to start with
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
PlaySample          proc        uses di, Chan:word, Sam:word, Rate:dword, \
                                            Vol:word, Pan:word
    mov     bl, byte ptr Chan
    mov     cl, byte ptr Sam
    mov     ax, word ptr Rate
    mov     dl, byte ptr Vol
    mov     dh, byte ptr Pan
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+41*4]   ;Call the function
    Ret
PlaySample          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetChannelTable                                              44
 Calling: Chan    Channel number (1..32)
          TSeg    Segment of channel table buffer
          TOff    Offset of channel table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetChannelTable     proc    uses di, Chan:word, TSeg:word, TOff:word
    mov     bl, byte ptr Chan
    mov     dx, TSeg
    mov     di, TOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+44*4]   ;Call the function
    Ret
GetChannelTable     endp
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: Chan    Channel number (1..32)
          Pan     New pan position (0..15). FFh=no set
 Returns: ax      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPan          proc    uses di, Chan:word, Pan:word
    mov     bl, byte ptr Chan
    mov     al, byte ptr Pan
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+45*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelPan          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: Chan    Channel number (1..32)
          VU      New VU setting, 0FFh=no set
 Returns: ax      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVU           proc    uses di, Chan:word, VU:word
    mov     bl, byte ptr Chan
    mov     al, byte ptr VU
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+46*4]   ;Call the function
    movzx   ax, al
    Ret
ChannelVU           endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                   47
 Calling: Chan    Channel number (1..32)
          Vol     New volume setting (0..64). FFh=no set
 Returns: ax      Channel's volume setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelVol          proc    uses di, Chan:word, Vol:word
    mov     bl, byte ptr Chan
    mov     al, byte ptr Vol
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+47*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVol          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: Chan    Channel number (1..32)
          Pos     New play position (0..65534). FFFFh=no set
 Returns: ax      Channel's play position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
ChannelPos          proc    Chan:word, Pos:word
    mov     bl, byte ptr Chan
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
GetSampleTable      proc    uses di, Samp:word, TSeg:word, TOff:word
    mov     bl, byte ptr Samp
    mov     dx, TSeg
    mov     di, TOff
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+49*4]   ;Call the function
    Ret
GetSampleTable      endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: Lft     Left scope value (16bit)
          Rgt     Right scope value (16bit)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
GetMainScope        proc    Lft:dword, Rgt:dword
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+50*4]   ;Call the function
    les     bx, Lft
    mov     es:[bx], ax
    les     bx, Rgt
    mov     es:[bx], cx
    ret
GetMainScope        endp

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
UnloadModule        proc
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+64*4]
    Ret
UnloadModule        endp

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
LoadGDM             proc \
uses di, Hand:word, FOff:dword, Flags:dword, GSeg:word, GOff:word
    mov     ax, Hand
    mov     ecx, FOff
    mov     dx, GSeg
    mov     di, GOff
    les     bx, Flags
    mov     bl, es:[bx]

    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+66*4]
    les     di, Flags
    mov     es:[di], bx

    ret
LoadGDM             EndP
db  IDString
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: EmsExist
 Calling: none
 Returns: ax      0 - ems services not detected,
                  1 - ems services detected
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
EmmIdCode           db      'EMMXXXX0'
EmsExist            proc    uses ds si
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

code ends
end
