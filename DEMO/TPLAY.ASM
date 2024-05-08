.model large, basic

include bwsb.inc                        ;external declarations
include gdmtype.inc                     ;GDM module file format structures

.386
.stack 512
.data

ModHead         GDMHeader   <?>

MSEConfigFile  struc
  SoundCard     dw      ?
  BaseIO        dw      ?
  IRQ           dw      ?
  DMA           dw      ?
  SoundQuality  dw      ?
MSEConfigFile   ends

MSEConfig       MSEConfigFile   <?>
MSECFGFileName  db      'MSE.CFG',0         ;Name of MSE.CFG file
ConfigError     db      'No Sound selected in SETUP. Please run SETUP',13,10,'$'

MSEOversample   db      16, 22, 45, 8

Temp            dw      ?
Temp2           dw      ?

ErrorUnknown    db      'Unknown error',13,10,'$'

MSEErrorTable   dw      offset MSE1, offset MSE2, offset MSE3, offset MSE4
                dw      offset ErrorUnknown, offset MSE6, offset MSE7
                dw      offset MSE8, offset MSE9, offset MSE10, offset MSE11
                dw      offset MSE12

MSE1    db      'Base I/O address autodetection failure',13,10,'$'
MSE2    db      'IRQ level autodetection failure',13,10,'$'
MSE3    db      'DMA channel autodetection failure',13,10,'$'
MSE4    db      'DMA channel not supported',13,10,'$'

MSE6    db      'Sound device does not respond',13,10,'$'
MSE7    db      'Memory control blocks destroyed',13,10,'$'
MSE8    db      'Insufficient memory for mixing buffers',13,10,'$'
MSE9    db      'Insufficient memory for MSE file',13,10,'$'
MSE10   db      'MSE has invalid ID string (corrupt/non-existant)',13,10,'$'
MSE11   db      'MSE disk read failure',13,10,'$'
MSE12   db      'MVSOUND.SYS not loaded (required for PAS use)',13,10,'$'

GDMErrorTable   dw      offset GDM1, offset GDM2, offset GDM3, offset GDM4
                dw      offset GDM5, offset GDM6

GDM1    db      'Module is corrupt',13,10,'$'
GDM2    db      'Could not autodetect module type',13,10,'$'
GDM3    db      'Bad format ID',13,10,'$'
GDM4    db      'Out of memory',13,10,'$'
GDM5    db      'Cannot unpack samples',13,10,'$'
GDM6    db      'AdLib samples not supported',13,10,'$'

MSEFile         db      'GUS.MSE',0,"  "
                db      'SB1X.MSE',0," "
                db      'SB2X.MSE',0," "
                db      'SBPRO.MSE',0,""
                db      'SB16.MSE',0," "
                db      'PAS.MSE',0,"  "

HexTable        db      '0123456789ABCDEF'


Banner          db      13, 10
                db      'BWSB Example Module Player', 13, 10
                db      'Copyright (c) 1995, Edward Schlunder',13,10,13,10,'$'

SoundDevice     db      'Sound Device: $'

Address         db      'Addr: $'
Address2        db      'h  IRQ: $'
Address3        db      '  DMA: $'
Address4        db      'x',13,10,'$'

InputFile       db      'Module file: $'
ModFileInput    db      74, ?
ModFile         db      75 dup ('$')

CantFindFile    db      "Can't find file: $"
SayLoadModule   db      'Loading Module: $'

SayChannels     db      'Channels: $'
SayOversample   db      'Oversampling: $'
SayOversample2  db      ' Hz$'
CRLF            db      13,10,'$'

.code

Start:
;-------
    mov     ah, 4Ah                     ;Shrink program memory for more free
    mov     bx, 01830h                   ;Keep 64K of memory
    int     21h

    mov     ax, @data                   ;Initialize segment registers
    mov     ds, ax
;-------
    mov     ah, 9                       ;Display program banner
    mov     dx, offset Banner
    int     21h
;-------
    mov     ax, 3D00h                   ;Open config file for read only
    mov     dx, offset MSECFGFileName
    int     21h
    jnc     @F                          ;Continue program if no errors

MSEError:
    mov     dx, offset ConfigError      ;Couldn't open file, display error
    mov     ah, 9h
    int     21h
    jmp     Exit                        ;Return to DOS
;-------
@@: mov     bx, ax                      ;Put file handle in correct register
    mov     dx, offset MSEConfig        ;Load config file into our structure
    mov     cx, size MSEConfigFile      ;Read in only the right number of bytes
    mov     ah, 3Fh                     ;3Fh - Read from Handle
    int     21h
    jc      MSEError                    ;Quit if error while loading

    cmp     ax, size MSEConfigFile      ;Did we read the right number of bytes?
    jb      MSEError                    ;Display error if MSE.CFG is too small

    mov     ah, 3Eh                     ;Close file handle
    int     21h
;-------
    mov     bx, MSEConfig.SoundCard     ;Get sound card to load MSE for
    dec     bx
    mov     ax, 10                      ;multiply sound card # by 10 for table
    mul     bl
    mov     bx, ax
    add     bx, offset MSEFile          ;ds:bx - ASCIIZ filename of MSE to load

    xor     edi, edi                    ;load from offset 0
    movzx   eax, MSEConfig.SoundQuality
    mov     ah, [MSEOversample+eax]     ;45KHz oversampling (or whatever is max)
    mov     al, 10h                     ;4096 byte mixing buffer
    mov     dx, MSEConfig.BaseIO        ;Base I/O Address of sound card
    mov     ch, byte ptr MSEConfig.IRQ  ;IRQ level of sound card
    mov     cl, byte ptr MSEConfig.DMA  ;DMA channel of sound card

    call    LoadMSE                     ;Load the MSE file
    or      ax, ax                      ;Was there an error loading the MSE?
    jz      @F                          ;Skip over error if none
;-------
    mov     bx, ax
    dec     bx
    shl     bx, 1                       ;Multiply by two for table
    mov     dx, [MSEErrorTable+bx]      ;Get offset of correct error message
    mov     ah, 9                       ;Display error message
    int     21h
    jmp     Exit                        ;Return to DOS
;-------
@@: mov     MSEConfig.BaseIO, dx        ; save autodetected information
    mov     byte ptr MSEConfig.IRQ, ch  ; ...
    mov     byte ptr MSEConfig.DMA, cl  ; ...

    mov     ah, 9h                      ;Print sound device's name
    mov     dx, offset SoundDevice
    int     21h

    call    DeviceName                  ;returns: dx:ax - pointer to dev name
    push    ds
    mov     ds, dx
    movzx   edx, ax
    mov     bl, ds:[edx+20]
    mov     byte ptr ds:[edx+20], '$'
    mov     ah, 9h                      ;Display device name
    int     21h
    mov     ds:[edx+20], bl
    pop     ds

    mov     dx, offset CRLF             ;Jump to next line
    int     21h

    mov     dx, offset Address          ;Print Base I/O Address used
    int     21h
    mov     ax, MSEConfig.BaseIO
    call    PrintHex

    mov     ah, 9h
    mov     dx, offset Address2         ;Print Base I/O Address used
    int     21h
    mov     ax, MSEConfig.IRQ
    call    PrintDecimal

    mov     ah, 9h
    mov     dx, offset Address3         ;Print Base I/O Address used
    int     21h
    mov     ax, MSEConfig.DMA
    call    PrintDecimal

    mov     ah, 9h
    mov     dx, offset CRLF             ;Jump to next line
    int     21h
    int     21h
;-------
    mov     dx, offset InputFile        ;Print prompt string
    int     21h

    mov     ah, 0Ah                     ;Input the name of the file to load
    mov     dx, offset ModFileInput
    int     21h

    mov     ah, 9h
    mov     dx, offset CRLF
    int     21h

    cmp     byte ptr [ModFileInput+1], 0
    je      Exit                        ;Abort if user just pressed enter

    movzx   ecx, byte ptr [ModFileInput+1]
    mov     byte ptr [ModFile+ecx], 0

    mov     ax, @data
    mov     es, ax
    mov     di, offset Modfile
    cld
    mov     al, '.'
    repne   scasb
    jz      LoadModule

    movzx   bx, byte ptr [ModFileInput+1]
    mov     byte ptr [ModFile+bx], '.'
    mov     byte ptr [ModFile+bx+1], 'G'
    mov     byte ptr [ModFile+bx+2], 'D'
    mov     byte ptr [ModFile+bx+3], 'M'
    mov     byte ptr [ModFile+bx+4], 0

;-------
LoadModule:
    mov     ax, 3D00h                   ;Open module for read only
    mov     dx, offset ModFile
    int     21h
    jnc     @F

    mov     ah, 9                       ;Display error message
    mov     dx, offset CantFindFile
    int     21h

    mov     dx, offset ModFile
    int     21h
    mov     dx, offset CRLF
    int     21h

    jmp     Exit                        ;Return to dos
;-------
@@: mov     Temp, ax                    ;save file handle

    mov     ah, 9h
    mov     dx, Offset SayLoadModule    ;Display message that we're loading
    int     21h

    mov     dx, Offset ModFile
    int     21h
    mov     dx, offset CRLF
    int     21h
;-------
    call    EmsExist                    ;Find out if EMS memory exists
    and     al, 1                       ;Only keep bit 0
    mov     bl, al                      ;Set load flags

    mov     ax, Temp                    ;File Handle to load from
    xor     ecx, ecx                    ;File offest to load from: 0
    mov     dx, ds
    mov     di, offset ModHead
    call    LoadGDM

    push    bx
    mov     ah, 3Eh                     ;Close module file handle
    mov     bx, Temp
    int     21h
    pop     bx

    or      bl, bl
    jz      @F

    movzx   bx, bl
    dec     bx
    shl     bx, 1                       ;Multiply by two for table
    mov     dx, [GDMErrorTable+bx]      ;Get offset of correct error message
    mov     ah, 9                       ;Display error message
    int     21h
    jmp     Exit                        ;Return to DOS
;-------
@@: mov     cx, 32
    mov     bx, offset ModHead.PanMap
    xor     al, al                      ;channel counter set to zero
ChanScanLoop:
    cmp     byte ptr ds:[bx], 0FFh
    je      @F
    inc     al                          ;increment channel counter
@@: inc     bx
    dec     cx
    jnz     ChanScanLoop

    mov     byte ptr Temp, al
    call    StartOutput
    mov     Temp2, ax

    mov     ah, 9h                      ;Print number of channels in module
    mov     dx, offset SayChannels
    int     21h
    movzx   ax, byte ptr Temp
    call    PrintDecimal

    mov     ah, 9h
    mov     dx, offset CRLF
    int     21h

    mov     ah, 9h                      ;Print number oversampling rate
    mov     dx, offset SayOversample
    int     21h
    mov     ax, Temp2
    call    PrintDecimal
    mov     ah, 9h                      ;Print number oversampling rate
    mov     dx, offset SayOversample2
    int     21h

    mov     ah, 9h
    mov     dx, offset CRLF
    int     21h

    call    StartMusic

;-------
    xor     ah, ah                      ;wait for a key press
    int     16h
;-------
    call    StopMusic
    call    StopOutput
    call    UnloadModule
    call    FreeMSE

;------- Exit Program
Exit:
    mov     ax, 4C00h
    int     21h
;-------

;Purpose: Print a decimal number to STDOUT.
;Calling: ax - number to print
;Returns: none
PrintDecimal        proc        uses ax bx cx dx
local   Number:word, PrintFlag:byte

    mov     Number, ax                  ;save the number to print
    mov     PrintFlag, 0

    mov     ax, 10000
PrintLoop:
    mov     dl, '0'

IncLoop:
    cmp     Number, ax
    jb      PrintIt
    sub     Number, ax
    inc     dl
    jmp     IncLoop

PrintIt:
    cmp     dl, 48
    je      @F
    mov     PrintFlag, 1
@@: cmp     PrintFlag, 0
    jz      SkipPrint

    push    ax
    mov     ah, 02h
    int     21h
    pop     ax

SkipPrint:
    xor     dx, dx
    mov     bx, 10
    div     bx
    or      ax, ax
    jnz     PrintLoop

    ret
PrintDecimal        endp

;Purpose: Print a hexidecimal number to STDOUT.
;Calling: ax - number to print
;Returns: none
PrintHex            proc        uses ax bx cx dx ds
local   Number:word, PrintFlag:byte

    mov     Number, ax                  ;save the number to print
    mov     PrintFlag, 0
    mov     ax, @data
    mov     ds, ax

    mov     cl, 12
PrintLoop:
    mov     bx, Number
    shr     bx, cl
    and     bx, 0Fh
    jnz     @F
    cmp     PrintFlag, 0
    jz      SkipPrint

@@: mov     dl, [HexTable+bx]
    mov     ah, 02h
    int     21h
    mov     PrintFlag, 1

SkipPrint:
    sub     cl, 4
    cmp     cl, 0
    jnl     PrintLoop

    ret
PrintHex            endp
end Start
