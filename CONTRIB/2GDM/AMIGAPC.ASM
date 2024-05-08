;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; AMIGAPC.ASM - Fast Amiga to PC conversion routines
;               Written by Edward Schlunder (1994-95)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Model Medium, C
.286
.Data
.Code

public AmigaWord
public AmigaLong
public AmigaSam

;Converts an Amiga integer (word) to a PC integer (word)
AmigaWord       Proc        AmWord:Word
	 Mov     ax, AmWord
	 xchg al,ah
	 Ret
AmigaWord       EndP

;Converts an Amiga long integer to a PC long integer
AmigaLong       Proc        AmLong:dword
	 Mov     ax, [WORD PTR AmLong]
	 Mov	   dx, [WORD PTR AmLong+2]
	 xchg al,dh
	 xchg ah,dl
	 Ret
AmigaLong       EndP

;Converts an Amiga signed sample to PC unsigned sample
AmigaSam       Proc        Uses es di, Mem:DWord, Leng:Word
	 Les di,[Mem]
	 Mov     cx, Leng

	 Or      cx, cx
	 Jnz     @@
	 Ret

@@: Xor     Byte PTR es:[di], 128      ;Flip the sign bit
	 Inc     di                         ;Increment the sample pointer
	 Dec     cx                         ;Decrement bytes left to convert
	 Jnz     @@                         ;Loop for next byte

	 Ret
AmigaSam       EndP

End
