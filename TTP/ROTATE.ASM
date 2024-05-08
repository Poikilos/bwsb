.Model Large,Pascal
.386p
.Data

INCLUDE sincos.dd     ; 512 degree, 12 point Sin and Cos tables

.Code

Public RotatePoints
Public ScalePoints
Public Project
Public MakeNormalList

RotateAxis MACRO
  ; Rotates around a certain axis based on EAX,ECX, and BX
  ; in  EAX = First Coord, ECX = Second Coord,  BX = Angle
  ; out EAX = New First Coord, ECX = New Second Coord
  PUSH ESI
  PUSH EDI
  MOV  ESI,EAX
  MOV  EDI,ECX

  SHL  BX,2
  MOV  EDX,DWord Ptr [Cosine + BX]
  IMUL EDX       ; EAX = Y*Cosine(XAn)
  MOV  EDX,DWord Ptr [Sine + BX]
  XCHG ECX,EAX   ; EAX = Z, ECX = Y*Cosine[Xan]
  IMUL EDX       ; EAX = Z*Sine[Xan]
  SUB  ECX,EAX
  SAR  ECX,12    ; 12 place fixed point number
  PUSH ECX       ; ECX = NewY = Sar(Y*Cosine[Xan] - Z*Sin[Xan])

  MOV  EAX,ESI   ; Restore origional coords
  MOV  ECX,EDI

  MOV  EDX,DWord Ptr [Sine + BX]
  IMUL EDX    ; EAX = Y*Sin[Xan]
  MOV  EDX,DWord Ptr [Cosine + BX]
  XCHG ECX,EAX  ; EAX = Z, ECX = Y*Sin[Xan]
  IMUL EDX      ; EAX = Z*Cosine[Xan]
  ADD  EAX,ECX
  SAR  EAX,12   ; EAX = NewZ = Sar(Y*Sin[Xan] + Z*Cosine[Xan])
  MOV  ECX,EAX
  POP  EAX
  POP  EDI
  POP  ESI
ENDM

RotatePoints Proc Uses es ds si di,LocalP:DWord,WorldP:DWord,Num:Word,Xan:Word,Yan:Word,Zan:Word
; Rotates points around the x,y, and z axis.
; in: LocalP - Pointer to local coordinate list
;     WorldP - Pointer to world coordinate list
;     Num    - number of verticies to transform
;     Xan,Yan,Zan - angle to rotate coords
; out: nothing

  LDS  SI,LocalP
  LES  DI,WorldP
  MOV  CX,Num
 @RotateCounter:
  PUSH CX
 ; XAxis rotation
  MOV  EAX,DWord Ptr DS:[SI+4]   ; EAX = Y Coord
  MOV  ECX,DWord Ptr DS:[SI+8]   ; ECX = Z Coord
  MOV  BX,Xan
 ROTATEAXIS ; Rotate around X axis
  MOV  DWord Ptr ES:[DI+4],EAX  ; Store Y Coord
  MOV  EAX,DWord Ptr DS:[SI]    ; EAX = X Coord
  MOV  BX,Yan                   ; ECX = Z Coord
 ROTATEAXIS ; Rotate around Y axis
  MOV  DWord Ptr ES:[DI+8],ECX   ; Store Z Coord
  MOV  ECX,DWord Ptr ES:[DI+4]   ; ECX = YCoord
  MOV  BX,Zan
 ROTATEAXIS ; Rotate around Z axis
  MOV  DWord Ptr ES:[DI],EAX    ; Store X Coord
  MOV  DWord Ptr ES:[DI+4],ECX  ; Store Y Coord
  ADD  SI,12  ; Increment to next vertex in LocalP list
  ADD  DI,12  ; Increment to next vertex in WordlP list
  POP  CX
  DEC  CX
  JNZ @RotateCounter
  RET
RotatePoints Endp


ScalePoints Proc Uses ds si,WorldP:DWord,Num:Word,ScaleFactor:DWord
; Scales all the points in World list by a fixed-point scale factor
  MOV  AX,NUM
  MOV  BX,3
  IMUL BX        ; Multiply number of verticies by 3 because each vertex
                 ; has three components
  MOV  CX,AX
  LDS  SI,WorldP
 @ScaleLooper:
  MOV  EAX,ScaleFactor
  MOV  EDX,DWord Ptr DS:[SI]   ; Get vertex point
  IMUL EDX                     ; multiply by scale factor
  SAR  EAX,12                  ; acount for fixed-point
  MOV  DWord Ptr DS:[SI],EAX   ; store back in list
  ADD  SI,4
  DEC  CX
  JNZ  @ScaleLooper
  RET
ScalePoints Endp

Project Proc Uses es ds di si,WorldP:DWord,ScreenP:DWord,Num:Word
; Projects the 3D coords found in WordlP to the screen coords
; in ScreenP.
; The Distance factor is 512, the Origin at (160,100)
; in: WorldP - List of transformed coordinates
;     ScreenP - List of screen coordinates
;     Num - number of coordinates to transfore
; out: screen coordinats of object

  MOV   CX,Num
  LDS   SI,WorldP
  LES   DI,ScreenP
 @ProjectLooper:
  MOV   EBX,512
  MOV   EDX,DWord Ptr DS:[SI+8] ; Get ZCoord
  SUB   EBX,EDX     ; EBX = 256 - ZCoord
  MOV   EAX,DWord Ptr DS:[SI]  ; EAX = X coord
  SHL   EAX,9
  CDQ
  iDIV  EBX
  ADD   EAX,160                ; AX = (XCoord*512)/(512-ZCoord)+160
  MOV   Word Ptr ES:[DI],AX
  MOV   EAX,DWord Ptr DS:[SI+4]  ; EAX = Y coord
  CDQ
  SHL   EAX,9
  iDIV  EBX
  ADD   EAX,100                ; AX = (XCoord*512)/(512-ZCoord)+160
  MOV   Word Ptr ES:[DI+2],AX
  ADD   SI,12   ; Move to next Coord triplet
  ADD   DI,4
  DEC   CX
  JNZ  @ProjectLooper
  RET
Project EndP



MakeNormalList proc Uses ds es di si,PointerList:DWord,NumberList:DWord,Num:Word
; Takes an array of pointers an places the data into an array of data
  LFS  BX,PointerList
  LES  DI,NumberList
  MOV  CX,Num
 @ChangeCounter:
  LDS  SI,DWord Ptr FS:[BX]  ; Load pointer to coord
  MOVSD                      ; store 4 bytes of coord data
  ADD  BX,4                  ; step to next coord
  DEC  CX
  JNZ @ChangeCounter
  RET
MakeNormalList EndP

End
