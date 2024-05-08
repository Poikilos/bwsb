.model medium, c
.386
.code
public InitVideo
InitVideo           proc
    mov     ax, 3                       ;set video mode 3
    int     10h

    mov     ax, 1003h
    mov     bx, 101h
    int     10h

    ret
InitVideo           endp

public VGAPresent
VGAPresent          proc
    mov     ax, 1A00h                   ;get video subsystem
    int     10h

    mov     al, 1
    cmp     bl, 7
    je      Exit
    cmp     bl, 8
    je      Exit
    cmp     bl, 11
    je      Exit
    cmp     bl, 12
    je      Exit

    xor     al, al
Exit:
    ret
VGAPresent          endp

public NewBlue
NewBlue             proc
    mov     dx, 3C8h
    mov     al, 1
    out     dx, al

    inc     dx
    out     dx, al
    mov     al, 5
    out     dx, al
    mov     al, 16
    out     dx, al

    ret
NewBlue             endp

public OldBlue
OldBlue             proc
    mov     dx, 3C8h
    mov     al, 1
    out     dx, al

    inc     dx
    xor     al, al
    out     dx, al
    out     dx, al
    mov     al, 42
    out     dx, al

    ret
OldBlue             endp

end
