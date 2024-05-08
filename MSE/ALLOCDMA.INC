;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; DMA Buffer Allocation Routine Begins Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (C) 1993-94, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;Calling:
;       bx      Number of pages long the buffer should be

;Returning:
;       Carry   Set if error

AllocDMABuffers     Proc    Near    Uses ds bx cx dx
    Shl     bx, 1                      ;Multiple by 2 for DMA boundary free
    Mov     ax, 4800h                  ;Allocate memory
    Int     21h
    Jc      Short Exit                 ;Something went wrong on alloc, abort

    Mov     cx, Word PTR cs:BufferLen
FindBuffLoop:
    Mov     dx, ax
    Shl     dx, 4                      ;Lower 12 bits of segment are DMA address
    Neg     dx                         ;65536 - Off#1 = Maximum len of #1
    Cmp     dx, cx
    Ja      Short @F
    Inc     ax
    Jmp     FindBuffLoop

@@: Mov     BufferSegment, ax          ;Save the segment address of buffer
    Mov     bx, Word PTR cs:BufferLen
    Mov     ds, ax
FillBufLoop:
    Mov     Byte PTR ds:[bx-1], 7Fh
    Dec     bx
    Jnz     FillBufLoop
    Clc

Exit:
    Ret
AllocDMABuffers     EndP

