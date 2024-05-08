;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                      Bells, Whistles, and Sound Boards
;        Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;    (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; ASM_MSE.ASM - ASM <-> MSE Interface routines
;               Written by Edward Schlunder (1995)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
include id.inc
.model large, basic
.386
.code

IF Evaluation
UnregBanner     db      10, 13, BWSBCopy, 10, 13, BWSBCopy2, 10, 13
                db      10, 13, SignBanner, 10, 13, '$'
SignedOff       db      0
ELSE
                db      BWSBCopy
ENDIF
                db      BBVer


MSEID           db      'Copyright (c) ',', Edward Schlunder ',13,10
Identification  db      IDString
                db      MajorVersion, MinorVersion

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

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadMSE                                                       0
 Calling: ds:bx   Pointer to ASCIIZ file/path of MSE
          edi     File Offset to load from
          ah      Oversampling rate (xxKHz, Range 5..45)
          al      Mixing buffer size (xx00h, Range 1..7Fh)
          dx      Sound device base I/O address. FFFFh for autodetect.
          ch      Sound device IRQ level. FFh for autodetect.
          cl      Sound device DMA channel. FFh for autodetect.
 Returns: dx      Base I/O address used
          ch      IRQ level used
          cl      DMA channel used
          ax      Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public LoadMSE
LoadMSE             Proc    Uses es ds esi edi
Local   FileHandle:word, FileSize:word, FileOff:dword
Local   OverRate:byte, Buffer:byte
Local   BaseIO:word, IRQ:byte, DMA:byte

    mov     OverRate, ah
    mov     Buffer, al
    mov     BaseIO, dx
    mov     IRQ, ch
    mov     DMA, cl
    mov     FileOff, edi

    mov     ax, 3D00h                  ;open file
    mov     dx, bx                     ;offset of filename
    int     21h
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
    mov     ax, ss
    mov     ds, ax
    lea     dx, FileSize
    mov     cx, 2
    mov     ah, 3Fh
    int     21h
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

    mov     ax, 3F00h                  ;Load the music/sound engine
    mov     cx, FileSize
    xor     dx, dx
    mov     ds, MSESegment
    int     21h
    jc      Exit

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
    xor     ch, ch
    mov     cl, es:[DRVNOF]            ;Get number of functions
    inc     cl

WriteSeg:
    mov     es:[bx], es                ;Write all the segments in function table
    add     bx, 4                      ;Increment over the offsets
    loop    WriteSeg                   ;Go through all the functions

    mov     ah, OverRate
    mov     dx, BaseIO
    mov     ch, IRQ
    mov     cl, DMA
    mov     bh, Buffer

    call    dword ptr es:[DRVFunc+0*4]     ;Call the function

    xor     ah, ah
Exit:
    ret
LoadMSE             EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: DeviceName
 Calling: none
 Returns: dx:ax   pointer to sound device name
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public DeviceName
DeviceName          proc
    mov     dx, MSESegment
    mov     ax, DRVSndName
    ret
DeviceName          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeMSE                                                       1
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public FreeMSE
FreeMSE             Proc    uses eax ebx ecx edx es ds
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
 Calling: al      Number of output channels (Range 1..32)
 Returns: ax      Actual oversampling rate being used
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public StartOutput
StartOutput         Proc    Uses ebx ecx edx es
    xor     bh, bh
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
StopOutput          Proc    Uses eax ebx ecx edx es
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+3*4]
    ret
StopOutput          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixStatus                                                     4
 Calling: none
 Returns: ax      Mixing flag, 0- No mixing needed, 1- Mixing needed
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MixStatus
MixStatus           Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+4*4]
    Ret
MixStatus           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MixForground                                                  5
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MixForground
MixForground        Proc    Uses eax ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+5*4]   ;Call the function
    Ret
MixForground        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: SetAutoMix                                                    6
 Calling: al     New automix flag
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public SetAutoMix
SetAutoMix          Proc    Uses eax ebx ecx edx es
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
StartMusic          Proc    Uses eax ebx ecx edx es
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
StopMusic           Proc    Uses eax ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+21*4]   ;Call the function
    Ret
StopMusic           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AmigaHertz                                                   22
 Calling: eax     New Amiga period Hertz to use
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public AmigaHertz
AmigaHertz          Proc    Uses eax ebx ecx edx es
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
MusicStatus         Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+23*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicStatus         EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicBPM                                                     24
 Calling: ah      New music BPM 0=no set
 Returns: ax      Music BPM
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicBPM
MusicBPM            Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+24*4]   ;Call the function
    movzx   ax, ah
    Ret
MusicBPM            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicTempo                                                   25
 Calling: ah      New music tempo, FFh=no set
 Returns: ax      Music tempo
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicTempo
MusicTempo          Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+25*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicTempo          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicOrder                                                   26
 Calling: ah      New music order, FFh=no set
 Returns: ax      Current music order
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicOrder
MusicOrder          Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+26*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicOrder          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicPattern                                                 27
 Calling: ah      New music pattern, FFh=no set
 Returns: ax      Current music pattern
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicPattern
MusicPattern        Proc        Uses ebx ecx edx es
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
MusicRow            Proc        Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+28*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicRow            EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicLoop                                                    29
 Calling: ah       0 - Disable music looping
                   1 - Enable music looping
                  FF - no change
 Returns: ax      Number of times music has looped
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicLoop
MusicLoop           Proc        Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+29*4]   ;Call the function
    Movzx   ax, ah
    Ret
MusicLoop           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: MusicVolume                                                  30
 Calling: ah      New global music volume (0-64). 0FFh=no change
 Returns: ax      Current global music volume
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public MusicVolume
MusicVolume         Proc        Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+30*4]   ;Call the function
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
public PlaySample
PlaySample          Proc        Uses eax ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+41*4]   ;Call the function
    Ret
PlaySample          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetChannelTable                                              44
 Calling: Chan    Channel number (1..32)
          dx:di   Pointer to channel table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetChannelTable
GetChannelTable     Proc        Uses eax ebx ecx edx es di
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+44*4]   ;Call the function
    Ret
GetChannelTable     EndP
db      BWSBCopy
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan                                                   45
 Calling: bl      Channel number (1..32)
          al      New pan position (0..15). FFh=no set
 Returns: ax      Channel's pan position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelPan
ChannelPan          Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+45*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelPan          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVU                                                    46
 Calling: bl      Channel number (1..32)
          al      New VU setting, 0FFh=no set
 Returns: ax      Channel's VU setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelVU
ChannelVU           Proc        Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+46*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVU           EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol                                                   47
 Calling: bl      Channel number (1..32)
          al      New volume setting (0..64). FFh=no set
 Returns: ax      Channel's volume setting
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelVol
ChannelVol          Proc    Uses ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+47*4]   ;Call the function
    Movzx   ax, al
    Ret
ChannelVol          EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPos                                                   48
 Calling: bl      Channel number (1..32)
          ax      New play position (0..65534). FFFFh=no set
 Returns: ax      Channel's play position
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public ChannelPos
ChannelPos          proc    Uses ebx ecx edx es
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+48*4]   ;Call the function
    ret
ChannelPos          endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetSampleTable                                               49
 Calling: bl      Sample number (0..254)
          dx:di   Pointer to sample table buffer
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetSampleTable
GetSampleTable      Proc        Uses eax ebx ecx edx es di
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+49*4]   ;Call the function
    Ret
GetSampleTable      EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: GetMainScope                                                 50
 Calling: none
 Returns: ax     Left scope value (16bit)
          cx     Right scope value (16bit)
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public GetMainScope
GetMainScope        Proc        Uses ebx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+50*4]   ;Call the function
    Ret
GetMainScope        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UnloadModule                                                 64
 Calling: none
 Returns: none
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public UnloadModule
UnloadModule        Proc    Uses eax ebx ecx edx es
    mov     es, MSESegment
    Call    dword ptr es:[DRVFunc+64*4]
    Ret
UnloadModule        EndP

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: LoadGDM                                                      66
 Calling: ax      File handle to load from
          ecx     Offset into file to load from
          bl      Load flags
          dx:di   Pointer address of GDM header buffer
 Returns: bl      Error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public LoadGDM
LoadGDM             Proc uses eax ecx edx gs

    mov     gs, MSESegment
    Call    dword ptr gs:[DRVFunc+66*4]
    Ret
LoadGDM             EndP
db  IDString
Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: AllocSample                                                  67
 Calling: dx:si   Address of sample header buffer
          cl      Sample number to load into
 Returns: ax      error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public AllocSample
AllocSample         proc    uses ebx ecx edx si es
    mov     es, MSESegment
    call    dword ptr es:[DRVFunc+67*4]
    ret
AllocSample         endp

Comment *ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: FreeSample                                                   68
 Calling: cl      Sample number to free
 Returns: ax      error code
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*
public FreeSample
FreeSample          proc    uses ebx ecx edx es
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
EmsExist            proc    uses ebx ecx edx si es
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

end
