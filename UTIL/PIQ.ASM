;Prefetch Instruction Queue (PIQ) Size Detection Routine
;Written by Zilym Limms/OTM. Copyright (c) 1995, Edward Schlunder
;
;Feel free to use this in anything you want (I have no idea what you
;*could* use it for, but oh well).. Just leave me credits if you do.
;
;While I've got your attention, check out some of my other programs:
;OmniPlayer - Multichannel digital music player for GUS, SB, SBPro, SB16, PAS
;BWSB       - Digital music and sound library for QB/PDS/TP/C/C++
;
;theory: this thing works on the fact that self modifying code
;        only modifies stuff in memory, and does not modify stuff already
;        loaded into the PIQ.

_codeseg segment
assume cs:_codeseg
org 100h

start:
    mov     ax, ds                     ;get es pointing to this segment
    mov     es, ax                     ;for the movsb

    mov     dx, offset header          ;display out little noise
    mov     ah, 9h
    int     21h

    cld                                ;make sure movsb goes the right direction
    mov     dx, 1                      ;number of bytes in PIQ counter
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
PIQLoop:
    mov     si, offset STCIns          ;si=STC instruction table
    mov     di, offset start1          ;offset into code
    add     di, dx                     ;add byte number to test
    mov     cx, 1                      ;make movsb only move one byte
    clc                                ;clear the carry (our flag of PIQ end)
    cli                                ;make sure IRQs don't reload the PIQ
    jmp     start1                     ;clear PIQ clean
align 16                               ;PIQ only works on paragraph aligned
start1:                                ;Byte Number:
    movsb                              ;1  (overwrite a NOP with STC)
PIQ:db  63 dup (90h)                   ;tons of NOPs
    sti                                ;reenable IRQs
    jc      FoundSize

    mov     di, offset PIQ             ;Refill the NOP table with NOPs again
    mov     al, 90h
    mov     cx, 63
    rep     stosb

    inc     dx                         ;Test the next size up
    cmp     dx, 64                     ;are we at the limit?
    jb      PIQLoop                    ;keep goin' if not..

NoFoundSize:
    mov     dx, offset NoSize          ;display our error
    mov     ah, 9h
    int     21h
    mov     ax, 4C01h                  ;exit to DOS, errorlevel=1
    int     21h

FoundSize:
    mov     cx, dx
    mov     ah, 9
    mov     dx, offset sizeis
    int     21h

    mov     bx, cx
    dec     bx
    shl     bx, 1
    add     bx, offset ascii
    mov     byte ptr [bx+2], '$'
    mov     dx, bx
    mov     ah, 9
    int     21h

    mov     ah, 9
    mov     dx, offset bytes
    int     21h

    mov     ax, 4C00h
    int     21h

header      db      'Prefetch Instruction Queue Size Detection Routine',10,13
            db      'Copyright (c) 1995, Edward Schlunder (zilym@hndymn.stat.com)',10,13
            db      10, 13, '$'
nosize      db      "PIQ size equal to or larger than 64 bytes$"
sizeis      db      'PIQ size: $'
bytes       db      ' byte(s)', 10, 13, '$'


STCIns      db      32 dup (0F9h) ;this table is full of STC instructions

ascii       db      ' 1'        ; 1 or 0 byte PIQ (doesn't detect if 0 byte or not)
            db      ' 2',' 3',' 4',' 5',' 6',' 7',' 8',' 9','10'
            db      '11','12','13','14','15','16','17','18','19'
            db      '20','21','22','23','24','25','26','27','28'
            db      '29','30','31','32','33','34','35','36','37'
            db      '38','39','40','41','42','43','44','45','46'
            db      '47','48','49','50','51','52','53','54','55'
            db      '56','57','58','59','60','61','62','63','64'

_codeseg ends
end start
