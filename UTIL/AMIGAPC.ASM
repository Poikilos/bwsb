;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; AMIGAPC.ASM - Fast Amiga to PC conversion routines
;               Written by Edward Schlunder (1994-95)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Model Medium, Basic
.386
.Data
.Code

;Converts an Amiga integer (word) to a PC integer (word)
AmigaWord       Proc        AmWord:Word
    Mov     bx, AmWord
    Mov     al, [bx+1]                 ;Return LSB/MSB swapped
    Mov     ah, [bx]
    Xor     dx, dx
    Ret
AmigaWord       EndP

;Converts an Amiga long integer to a PC long integer
AmigaLong       Proc        AmLong:Word
    Mov     bx, AmLong
    Mov     al, [bx+3]
    Mov     ah, [bx+2]
    Mov     dl, [bx+1]
    Mov     dh, [bx]
    Ret
AmigaLong       EndP

;Converts an Amiga signed sample to PC unsigned sample
AmigaSam8       Proc        Uses es di, AmigaSeg:Word, AmigaOff:Word, Leng:Word
    Mov     bx, AmigaSeg
    Mov     es, [bx]

    Mov     bx, AmigaOff
    Mov     di, [bx]

    Mov     bx, Leng
    Mov     cx, [bx]

    Or      cx, cx
    Jnz     @F
    Ret

@@: Xor     Byte PTR es:[di], 128      ;Flip the sign bit
    Inc     di                         ;Increment the sample pointer
    Dec     cx                         ;Decrement bytes left to convert
    Jnz     @B                         ;Loop for next byte

    Ret
AmigaSam8       EndP

End
