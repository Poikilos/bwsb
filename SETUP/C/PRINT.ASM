;Some little direct screen write routines...
;Copyright (c) 1994-95, Edward Schlunder

.model medium, c
.386
.Data

    Color   db      07h
    Row     db      0
    Col     db      0

.Code

Locate          proc        NewRow:byte, NewCol:byte
    mov     al, NewRow
    or      al, al
    jz      @F
    dec     al
    mov     Row, al

@@: mov     al, NewCol
    or      al, al
    jz      @F
    dec     al
    mov     Col, al

@@: ret
Locate          endp

XColor          Proc        Forg:byte, Back:byte
    mov     ah, Forg
    mov     al, Back
    shl     al, 4
    and     ah, 0Fh
    or      al, ah
    mov     Color, al
    ret
XColor          endp

XColorFill      Proc        Uses si, TxtLen:word
    mov     cx, TxtLen

    mov     ax, 0B800h
    mov     es, ax

    mov     bl, Row
    mov     al, 80
    mul     bl
    add     al, Col
    adc     ah, 0
    shl     ax, 1
    mov     bx, ax
    inc     bx

    cld
    add     Col, cl
    mov     ah, Color
ColorLoop:
    lodsb
    mov     es:[bx], ah
    add     bx, 2
    dec     cx
    jnz     ColorLoop

    ret
XColorFill      endp

End

PrintChar       Proc        Uses si, TxtOff:word
    mov     si, TxtOff

    mov     ax, 0B800h
    mov     es, ax

    mov     bl, Row
    mov     al, 80
    mul     bl
    add     al, Col
    adc     ah, 0
    shl     ax, 1
    mov     bx, ax

    cld
    jmp     GetChar
PrintLoop:
    mov     es:[bx], al
    add     bx, 2
GetChar:
    lodsb
    or      al, al
    jnz     PrintLoop

    ret
PrintChar       endp

LineFeed        proc
    mov     Col, 0
    inc     Row
    ret
LineFeed        endp

BLocate         proc        NewRow:byte, NewCol:byte
    mov     al, NewRow
    or      al, al
    jz      @F
    dec     al
    mov     Row, al

@@: mov     al, NewCol
    or      al, al
    jz      @F
    dec     al
    mov     Col, al

    mov     ah, 0Fh
    int     10h

    mov     ah, 02h                    ;Set cursor location via BIOS
    mov     dh, Row
    mov     dl, Col
    int     10h

@@: ret
BLocate         endp

ClearEOL        proc
    mov     ax, 0B800h
    mov     es, ax

    mov     bl, Row
    mov     al, 80
    mul     bl
    add     al, Col
    adc     ah, 0
    shl     ax, 1
    mov     bx, ax

    cld
    xor     al, al
    mov     ah, Color
    mov     cl, 80
    sub     cl, Col
    jz      Exit
PrintLoop:
    mov     es:[bx], ax
    add     bx, 2
    dec     cl
    jnz     PrintLoop
Exit:
    ret
ClearEOL        endp

XPrint          proc        Uses si, TxtOff:word
    mov     si, TxtOff

    mov     ax, 0B800h
    mov     es, ax

    mov     bl, Row
    mov     al, 80
    mul     bl
    add     al, Col
    adc     ah, 0
    shl     ax, 1
    mov     bx, ax

    cld
    add     Col, cl
    mov     ah, Color

    jmp     GetChar
PrintLoop:
    mov     es:[bx], ax
    add     bx, 2
    inc     Col
GetChar:
    lodsb
    or      al, al
    jnz     PrintLoop

    cmp     Col, 80
    jb      Exit
    mov     Col, 79
Exit:
    ret
XPrint          endp
