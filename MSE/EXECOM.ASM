comment *
   EXECOM 1.2  (c) Copyright 1988  Thomas G. Hanlin III
*

Sseg           segment byte stack 'prog'    ; dummy stack segment
Sseg           ends

Cseg           segment byte public 'prog'
               assume         cs:Cseg, ds:Cseg, ss:Sseg


               org            100h

MAIN           proc           far
               cld
               mov            si,80h
               lodsb                             ; get parm length
               cbw
               mov            cx,ax
               jcxz           Inform             ;   inform 'em if no parms

ScanParms:     lodsb                             ; get a command-line char
               cmp            al," "             ; is it a space?
               jbe            ScanLoop2          ;   yes, ignore it
               mov            di,offset OUTFILE  ; assume output file name
               inc            ah                 ; increment parm number
               cmp            ah,2               ; check it
               ja             Inform             ;   too large, inform 'em
               je             SaveFileName       ;   default OUTFILE is ok
               mov            di,offset INFILE   ; input file name (string)
SaveFileName:  stosb                             ; store a char of the filename
               dec            cx                 ; are we done yet?
               jz             ScanDone           ;   yes, exit
               lodsb                             ; get another char
               cmp            al," "             ; is it blank?
               ja             SaveFileName       ;   no, must be a filename chr
ScanLoop2:     loop           ScanParms          ;   keep looking for parms

ScanDone:      or             ah,ah              ; any parms?
               jz             Inform             ;   no, inform 'em
               dec            ah                 ; only one parm?
               jnz            ChangeExts         ;   no, go change extensions
               mov            si,offset INFILE   ; input file name
               mov            di,offset OUTFILE  ; output file name
DupeFile:      lodsb                             ; get an input char
               or             al,al              ; is it null?
               jz             ChangeExts         ;   yes, done- change exts
               stosb                             ; store char in output name
               jmp            DupeFile           ;   keep on truckin'

Inform:        mov            dx,offset INFORMATION
               mov            ah,9
               int            21h
               dec            EXITCODE
               jmp            Abort

ChangeExts:    mov            si,offset INFILE   ; input file name
Change1:       lodsb                             ; get a char
               or             al,al              ; are we done?
               jz             AddExtIn1          ;   yes, needs extension
               cmp            al,"."             ; is it a period?
               jne            Change1            ;   no, keep looking

ChangeExt2:    mov            si,offset OUTFILE  ; output file name
Change2:       lodsb                             ; get a char
               or             al,al              ; are we done?
               jz             AddExtIn2          ;   yes, needs extension
               cmp            al,"."             ; is it a period?
               jne            Change2            ;   no, keep looking
               lodsw                             ; is the extension ".EXE"?
               cmp            ax,"XE"            ;
               jne            OpenFiles          ;   no, go open the files
               lodsb                             ;
               cmp            al,"E"             ;
               jne            OpenFiles          ;   no, go open the files
               sub            si,3               ; pretend there's no ext

AddExtIn2:     dec            si                 ; move back to the first null
               mov            di,si
               mov            ax,"C."            ; install a ".COM"...
               stosw                             ; ...file extension
               mov            ax,"MO"            ;
               stosw                             ;
               jmp            OpenFiles

AddExtIn1:     dec            si                 ; move back to the first null
               mov            di,si
               mov            ax,"E."            ; install an ".EXE"...
               stosw                             ; ...file extension
               mov            ax,"EX"            ;
               stosw                             ;
               jmp            ChangeExt2


;------------------- Everything's set up, let's open the files ----------------


OpenFiles:     mov            ax,3D00h           ; open file for read
               mov            dx,offset INFILE   ; input file name
               int            21h
               jnc            InputOpenOk
               mov            cl,1
               jmp            ErrVector

InputOpenOk:   mov            INHANDLE,ax        ; save input file handle
               mov            bx,ax
               mov            ah,3Fh             ; read from file
               mov            cx,24              ; 24 bytes
               mov            dx,offset LASTBYTE ; data buffer
               int            21h
               jnc            ReadOk
               mov            cl,9
               jmp            ErrVector

ReadOk:        mov            si,dx
               mov            di,offset EXE_SIG
               mov            cx,5       ; set EXE_SIG, EXE_EXCESS, EXE_PAGES,
               rep movsw                 ;     EXE_RELOCCOUNT, EXE_HDRSIZE
               add            si,4
               movsw                             ; set EXE_SS
               movsw                             ; set EXE_SP
               add            si,2
               movsw                             ; set EXE_IP
               movsw                             ; set EXE_CS

               mov            cl,3               ; default error code
               cmp            EXE_SIG,"ZM"       ; is the signature ok?
               jne            ErrVector          ;   nope, error
               inc            cx                 ; inc error code
               cmp            EXE_RELOCCOUNT,0   ; any relocations needed?
               jne            ErrVector          ;   yes, error
               inc            cx                 ; inc error code
               cmp            EXE_SS,0           ; is there a defined SS?
               jne            ErrVector          ;   yes, error
               cmp            EXE_SP,0           ; is there a defined SP?
               jne            ErrVector          ;   yes, error
               inc            cx                 ; inc error code
               cmp            EXE_CS,0           ; is there a defined CS?
               jne            ErrVector          ;   yes, error
               inc            cx                 ; inc error code
               cmp            EXE_IP,0           ; is the IP = 0?
               je             ChecksOk           ;   yes, it's ok
               cmp            EXE_IP,0100h       ; is the IP = 0100h?
               jne            ErrVector          ;   no, error

ChecksOk:      mov            bx,EXE_HDRSIZE
               mov            cl,4
               shl            bx,cl              ; CodeStart in BX ****
               mov            ax,EXE_PAGES
               dec            ax
               mov            cx,512
               mul            cx
               sub            ax,bx
               sbb            dx,0               ; CodeSize in DX:AX ***
               mov            cx,EXE_EXCESS
               jcxz           NoDribble
               add            ax,cx
               jmp            GotCodeSize
NoDribble:     add            ax,512
GotCodeSize:   adc            dx,0
               or             dx,dx              ; is it too large?
               jz             CheckIP            ;   no, keep on truckin'
               mov            cl,8
ErrVector:     jmp            ErrorExit

CheckIP:       push           ax
               cmp            EXE_IP,0100h       ; is IP right for .COM files?
               je             IPok               ;   yes...
               mov            dx,offset WARNING
               mov            ah,9               ; display warning message
               int            21h
IPok:          mov            dx,bx              ; CodeStart
               xor            cx,cx
               add            dx,EXE_IP
               adc            cx,cx
               mov            bx,INHANDLE
               mov            ax,4200h           ; move file ptr from start
               int            21h
               mov            ah,3Ch             ; create file for write
               mov            dx,offset OUTFILE  ; output file name
               xor            cx,cx              ; normal file attribute
               int            21h
               pop            si
               jnc            OutputOpenOk
               mov            cl,2
               jmp            ErrVector
OutputOpenOk:  mov            OUTHANDLE,ax       ; save output file handle
               sub            si,EXE_IP          ; ignore IP bytes
               mov            dx,offset LASTBYTE ; buffer location
               mov            cx,32 * 1024       ; buffer size: 32K


; ----------------- Just copy the code from the EXE to the COM file -----------


WriteLoop:     or             si,si
               jz             Done
               cmp            si,cx
               ja             ReadBlock
               mov            cx,si
ReadBlock:     mov            ah,3Fh             ; read from file
               mov            bx,INHANDLE
               int            21h
               jc             ReadError
               mov            ah,40h             ; write to file
               mov            bx,OUTHANDLE
               int            21h
               jc             WriteError
               sub            si,cx
               jmp            WriteLoop

ReadError:     mov            cl,9
               jmp            ErrorExit0
WriteError:    mov            cl,10


;---------------------------- Error exit handler ------------------------------


ErrorExit0:    mov            ah,3Eh             ; close a file
               mov            bx,OUTHANDLE       ; ...output file
               int            21h

ErrorExit:     mov            EXITCODE,cl
               mov            ah,9               ; display error message
               mov            dx,offset FATALERR ; "Fatal error: "
               int            21h
               mov            si,offset CANTOPEN ; first error message
               xor            ch,ch
               jmp            FindErr1
FindErr:       lodsb                             ; get a char
               cmp            al,"$"             ; end of message?
               jne            FindErr            ;   no, keep looking
FindErr1:      loop           FindErr            ;   get the message we want
               mov            dx,si              ; pointer to error message
ErrDone:       mov            ah,9
               int            21h
               cmp            EXITCODE,1         ; did we open the input file?
               je             Abort              ;   no, don't close or delete

Done:          mov            ah,3Eh             ; close a file
               mov            bx,INHANDLE        ; input file
               int            21h
               cmp            EXITCODE,0         ; successful conversion?
               jnz            Abort              ;   no, just exit
               mov            ah,41h             ; delete file
               mov            dx,offset INFILE   ; ...the original input file
               int            21h
Abort:         mov            ah,4Ch             ; terminate program
               mov            al,EXITCODE        ; error exit code
               int            21h
MAIN           endp


WARNING        db "WARNING: The default IP is not 0100h.",13,10
               db "The output file will not be executable.",13,10,"$"

FATALERR       db "Fatal error: $"
CANTOPEN       db "Unable to open input file",13,10,"$"
CANTMAKE       db "Unable to create output file",13,10,"$"
BADSIG         db "Input file is not a valid .EXE file",13,10,"$"
RELITEMS       db "There are items requiring relocation",13,10,"$"
BADSTACK       db "A stack is defined",13,10,"$"
BADCSEG        db "A code segment is defined",13,10,"$"
BADCOFS        db "The code offset is neither 0 nor 0100h",13,10,"$"
TOOBIG         db "File is too large (.COM would be over 64K)",13,10,"$"
CANTREAD       db "Unable to read input file",13,10,"$"
CANTWRITE      db "Unable to write to output file",13,10,"$"


INFORMATION    db "EXECOM 1.2  Copyright (c) 1989  Thomas G. Hanlin III",13,10
               db "  Purpose: converts an .EXE file to a .COM file.",13,10
               db "  Syntax : EXECOM inputfile[.EXE] [outputfile[.COM]]",13,10
               db "$"

INHANDLE       dw ?
OUTHANDLE      dw ?
EXE_SIG        dw ?       ; EXE signature
EXE_EXCESS     dw ?       ; bytes in excess of the 512b EXE_PAGES count
EXE_PAGES      dw ?       ; code size, in 512b pages
EXE_RELOCCOUNT dw ?       ; count of items in the relocation table
EXE_HDRSIZE    dw ?       ; header size, in 16b paragraphs
EXE_SS         dw ?       ; default SS
EXE_SP         dw ?       ; default SP
EXE_IP         dw ?       ; default IP
EXE_CS         dw ?       ; default CS

EXITCODE       db 0       ; program error exit code

INFILE         db 80 dup (0)   ; input file name
OUTFILE        db 80 dup (0)   ; output file name

LASTBYTE:                 ; start of file buffer area

Cseg           ends
               end            MAIN
