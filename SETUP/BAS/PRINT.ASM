;Some little direct screen write routines...
;Copyright (c) 1994, Edward Schlunder

.Model Medium, Basic
.386
.Data

    Color   db      07h
    Row     db      0
    Col     db      0

.Code

PrintChar       Proc        Uses ds si es, TxtSeg:word, TxtOff:word, TxtLen:word

    Mov     bx, TxtOff
    Mov     si, [bx]
    Mov     bx, TxtLen
    Mov     cx, [bx]
    Mov     bx, TxtSeg
    Mov     dx, [bx]

    Mov     ax, 0B800h
    Mov     es, ax

    Mov     bl, Row
    Mov     al, 80
    Mul     bl
    Add     al, Col
    Adc     ah, 0
    Shl     ax, 1
    Mov     bx, ax

    Cld
    Mov     ds, dx
PrintLoop:
    Lodsb
    Mov     es:[bx], al
    Add     bx, 2
    Dec     cx
    Jnz     PrintLoop

    Ret
PrintChar       EndP

XLocate         Proc        NewRow:word, NewCol:word
    Mov     bx, NewRow
    Mov     al, [bx]
    Or      al, al
    Jz      @F
    Dec     al
    Mov     Row, al

@@: Mov     bx, NewCol
    Mov     al, [bx]
    Or      al, al
    Jz      @F
    Dec     al
    Mov     Col, al

@@: Ret
XLocate         EndP

BLocate         Proc        NewRow:word, NewCol:word
    Mov     bx, NewRow
    Mov     al, [bx]
    Or      al, al
    Jz      @F
    Dec     al
    Mov     Row, al

@@: Mov     bx, NewCol
    Mov     al, [bx]
    Or      al, al
    Jz      @F
    Dec     al
    Mov     Col, al

    Mov     ah, 0Fh
    Int     10h

    Mov     ah, 02h                    ;Set cursor location via BIOS
    Mov     dh, Row
    Mov     dl, Col
    Int     10h

@@: Ret
BLocate         EndP

XPrint          Proc        Uses ds si es, TxtSeg:word, TxtOff:word, TxtLen:word
    Mov     bx, TxtOff
    Mov     si, [bx]
    Mov     bx, TxtLen
    Mov     cx, [bx]
    Mov     bx, TxtSeg
    Mov     dx, [bx]

    Mov     ax, 0B800h
    Mov     es, ax

    Mov     bl, Row
    Mov     al, 80
    Mul     bl
    Add     al, Col
    Adc     ah, 0
    Shl     ax, 1
    Mov     bx, ax

    Cld
    Add     Col, cl
    Mov     ah, Color
    Mov     ds, dx
PrintLoop:
    Lodsb
    Mov     es:[bx], al
    Mov     es:[bx+1], ah
    Add     bx, 2
    Dec     cx
    Jnz     PrintLoop

    Ret
XPrint          EndP

XColor          Proc        Forg:word, Back:word
    Mov     bx, Forg
    Mov     ah, [bx]
    Mov     bx, Back
    Mov     al, [bx]
    Shl     al, 4
    And     ah, 0Fh
    Or      al, ah
    Mov     Color, al
    Ret
XColor          EndP

LineFeed        Proc
    Mov     Col, 0
    Inc     Row
    Ret
LineFeed        EndP

XColorFill      Proc        Uses ds si es, TxtLen:word
    Mov     bx, TxtLen
    Mov     cx, [bx]

    Mov     ax, 0B800h
    Mov     es, ax

    Mov     bl, Row
    Mov     al, 80
    Mul     bl
    Add     al, Col
    Adc     ah, 0
    Shl     ax, 1
    Mov     bx, ax

    Cld
    Add     Col, cl
    Mov     ah, Color
    Mov     ds, dx
ColorLoop:
    Lodsb
    Mov     es:[bx+1], ah
    Add     bx, 2
    Dec     cx
    Jnz     ColorLoop

    Ret
XColorFill      EndP

End
