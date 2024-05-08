; KBDEAMON.ASM - Keyboard schtuff for gAMeS... ugh, GAMES; durn caps
;                lock key..
; Written by Edward Schlunder aka Zilym Limms/OverThrowMachine

.Model Large, Pascal
.386P
.Code

OldInt9         dd      ?              ;Old Int 9h handler address

EE              db      0

KUp             db      0              ;1-Up is down, 0-Up is up
KDown           db      0              ;1-Down is down, 0-Down is up
KLeft           db      0              ;1-Left is down, 0-Left is up
KRight          db      0              ;1-Right is down, 0-Right is up

;Kicks the KB daemon into action..
KickKBDaemon        Proc    Uses ds es
    Mov     ax, 3509h                  ;Get original Int 9h handler
    Int     21h
    Mov     Word PTR cs:OldInt9, bx       ;Save old IRQ vector
    Mov     Word PTR cs:OldInt9+2, es

    Mov     dx, Offset Int9Handler     ;Load DX with our KB handler offset
    Mov     ax, 2509h                  ;DOS function to change int vectors
    Mov     bx, cs                     ;Put segment of our DMA IRQ handler in
    Mov     ds, bx                     ;DX for DOS's use.
    Int     21h                        ;Go call DOS and have the interrupt

    Ret
KickKBDaemon        EndP

;Returns the current key krap..
KBDaemon            Proc        Uses es, Up:dword,Down:dword,Lft:dword,Rgt:dword
    Mov     al, cs:KUp
    Les     bx, Up
    Mov     es:[bx], al

    Mov     al, cs:KDown
    Les     bx, Down
    Mov     es:[bx], al

    Mov     al, cs:KRight
    Les     bx, Rgt
    Mov     es:[bx], al

    Mov     al, cs:KLeft
    Les     bx, Lft
    Mov     es:[bx], al

    Ret
KBDaemon            EndP

FreeKBDaemon        Proc        Uses ds
    Mov     ax, 2509h                  ;DOS function to change int vectors
    Mov     dx, word ptr cs:OldInt9
    Mov     ds, word ptr cs:OldInt9+2
    Int     21h                        ;Go call DOS and have the interrupt

    Ret
FreeKBDaemon        EndP

Int9Handler         Proc
    Push    ax

    In      al, 60h                    ;Get current scan code
    Cmp     al, 0E0h                   ;Is it a good one?
    Je      EEXiT

    Cmp     cs:EE, 1
    Jne     BIOSJump
    Mov     cs:EE, 0

    Cmp     al, 48h                    ;UP?
    Jne     @F
    Mov     byte ptr cs:KUp, 1
    Jmp     Exit

@@: Cmp     al, 48h OR 80h             ;Is it an UP is up code?
    Jne     @F
    Mov     byte ptr cs:KUp, 0         ;Yep
    Jmp     Exit

@@: Cmp     al, 50h                    ;DOWN?
    Jne     @F
    Mov     byte ptr cs:KDown, 1
    Jmp     Exit

@@: Cmp     al, 50h OR 80h
    Jne     @F
    Mov     byte ptr cs:KDown, 0
    Jmp     Exit

@@: Cmp     al, 4Dh                    ;RIGHT?
    Jne     @F
    Mov     byte ptr cs:KRight, 1
    Jmp     Exit

@@: Cmp     al, 4Dh OR 80h
    Jne     @F
    Mov     byte ptr cs:KRight, 0
    Jmp     Exit

@@: Cmp     al, 4Bh                    ;LEFT?
    Jne     @F
    Mov     byte ptr cs:KLeft, 1
    Jmp     Exit

@@: Cmp     al, 4Bh or 80h             ;LEFT?
    Jne     Exit
    Mov     byte ptr cs:KLeft, 0
    Jmp     Exit

EEXiT:
    Mov     cs:EE, 1

Exit:
    In      al, 61h                    ;Get value of keyboard control lines
    Mov     ah, al                     ;Save it
    Or      al, 80h                    ;Set the "enable kbd" bit
    Out     61h, al                    ; And write it out the control port
    Xchg    ah, al                     ;Fetch the original control port value
    Out     61h, al                    ; And write it back

    Mov     al, 20h
    Out     20h, al

    Pop     ax
    Iret

BIOSJump:
    Pop     ax
    Jmp     cs:OldInt9
Int9Handler             EndP

End
