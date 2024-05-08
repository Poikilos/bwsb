;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                      Bells, Whistles, and Sound Boards
;        Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;    (you may only make copies of this file for personal backup purposes)
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; EMS_C.ASM - Expanded Memory Routines [ZL/OTM] 06-20-94 for C
;             Written by Edward Schlunder (1994-95)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

IFDEF LMM
.model large, c
ELSE
.model medium, c
ENDIF

.386p
.code

;Entry:  none
;Return: ax=EMS status code
EmsStatus           Proc
    Mov     ah, 40h
    Int     67h
    Movzx   ax, ah
    Ret
EmsStatus           EndP

;Entry:  none
;Return: ax=Page Frame Segment
EmsFrameSegment     Proc
    Mov     ah, 41h
    Int     67h
    Mov     ax, bx
    Ret
EmsFrameSegment     EndP

EmsPagesTotal       Proc
    Mov     ah, 42h
    Int     67h
    Mov     ax, dx
    Ret
EmsPagesTotal       EndP

EmsPagesFree        Proc
    Mov     ah, 42h
    Int     67h
    Mov     ax, bx
    Ret
EmsPagesFree        EndP

EmsAlloc            Proc    Pages:Word
    Mov     bx, Pages
    Mov     bx, [bx]
    Mov     ah, 43h
    Int     67h
    Mov     ax, dx
    Ret
EmsAlloc            EndP

EmsMapPage          Proc    PhyPage:Word, LogPage:Word, Handle:Word
    Mov     ah, 44h
    Mov     bx, PhyPage
    Mov     al, [bx]
    Mov     bx, Handle
    Mov     dx, [bx]
    Mov     bx, LogPage
    Mov     bx, [bx]
    Int     67h
    Movzx   ax, ah
    Ret
EmsMapPage          EndP

EmsDealloc          Proc    Handle:Word
    Mov     bx, Handle
    Mov     dx, [bx]
    Mov     ah, 45h
    Int     67h
    Movzx   ax, ah
    Ret
EmsDealloc          EndP

End