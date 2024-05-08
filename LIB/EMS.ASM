;EMS.ASM- Expanded Memory Routines [ZL/OTM] 06-20-94
;---------------------------------------------------

.Model Medium, Basic
.386
.Data

EmmIdCode           db      'EMMXXXX0'

.Code

;Entry:  ds=Data segment
;Return: ax=0-EMS non existant, 1-EMS detected
EmsExist            Proc        Uses es si
    Xor     ax, ax
    Mov     es, ax
    Mov     bx, 19Eh
    Mov     ax, es:[bx]
    Mov     es, ax

    Mov     cl, 8
    Mov     si, 10
    Xor     bx, bx
CmpLoop:
    Mov     al, es:[si]
    Cmp     al, ds:[EmmIdCode+bx]
    Jne     EmsNoExist
    Inc     si
    Inc     bx
    Dec     cl
    Jnz     CmpLoop

EmsYesExist:
    Mov     ax, 1
    Ret

EmsNoExist:
    Xor     ax, ax
    Ret
EmsExist            EndP

;Entry:  ds=Data segment
;Return: ax=EMS status code
EmsStatus           Proc
    Mov     ah, 40h
    Int     67h
    Movzx   ax, ah
    Ret
EmsStatus           EndP

;Entry:  ds=Data segment
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
