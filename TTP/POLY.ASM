; A Polygon fill routine.
; Alex Chalfin   10/25/94
; Internet: achalfin@uceng.uc.edu
;
; Pascal Declaration:
;
; Procedure DrawPoly(Var VertexList;NumVert:Word;Color:Byte;PageAddr:Word);
;

.Model Large,Pascal
.Data

MinY       dw ?   ; Starting Y value (Minimum)
Edges      dw ?   ; Number of edges in the polygon
StartVert1 dw ?   ; Start vertex index for line1
StartVert2 dw ?   ; Start vertex index for line2
EndVert1   dw ?   ; End vertex index for line 1
EndVert2   dw ?   ; End vertex index for line 2
Delta1     dd ?   ; Change in X location for line 1
Delta2     dd ?   ; Change in X location for line 2
Count1     dw ?   ; Y Counter for line 1
Count2     dw ?   ; Y Counter for line 2
XVal1      dd ?   ; X place holder for line 1
XVal2      dd ?   ; X place holder for line 2
YCount     dw ?   ; Store current Y location
PolyColor  db ?   ; Color to draw polygon

.Code
.386

Public DrawPoly


FINDMINMAX Macro
  Lfs  di,Vert     ;; Make fs:di point to screen vertex list
;*** Find the minimum and maximum values of polyogn
  Mov  ax,06fffh   ; use ax for minimum value
  Mov  MinY,ax
  Mov  cx,0
 @MinMaxLooper:
  Mov  bx,cx
  Shl  bx,2
  Mov  ax,Word Ptr fs:[di+bx+2]   ; Get Y value for vertex list
  Cmp  ax,MinY                    ; Check for minimum value
  Jge @SkipMinStore
  Mov  StartVert1,cx              ; Store the starting (top) vertex
  Mov  MinY,ax
 @SkipMinStore:
  Inc  cx
  Cmp  cx,Num
  Jnz @MinMaxLooper
  Mov  ax,MinY
  Mov  YCount,ax
EndM ;FINDMINMAX

Proc ZeroCheck Near
  Cmp bx,0
  Jne @Skip
  Inc bx
 @Skip:
  Ret
EndP ZeroCheck

CALCDELTA1 Macro
  Mov   bx,StartVert1
  Shl   bx,2
  Movsx eax,Word Ptr fs:[di+bx]   ;  Get first X value, X1
  Mov   XVal1,eax
  Push  eax                       ; Store X value on stack
  Movsx eax,Word Ptr fs:[di+bx+2] ; Get Y Value, Y1
  Mov   bx,EndVert1
  Shl   bx,2
  Movsx ecx,Word Ptr fs:[di+bx]   ; Get Second X Value, X2
  Push  ecx
  Movsx ecx,Word Ptr fs:[di+bx+2] ; Get Y value, Y2
  Sub   ecx,eax
  Inc   ecx        ; cx := Y2-Y1+1
  Mov   edx,ecx    ; store in dx for later use
  Pop   ecx        ; Restore X2
  Pop   eax        ; Restore X1
  Sub   ecx,eax
  Shl   ecx,8      ; cx := (X2-X1) Shl 8
  Mov   eax,ecx
  Mov   ebx,edx    ; bx := Y2-Y1+1
  Mov   Count1,bx  ; Store Count1
  Cdq              ; Convert DWord in EAX to QWord in EDX:EAX
  Call  ZeroCheck  ; Make sure divisor isn't 0
  Idiv  ebx
  Mov   Delta1,eax ; Store the first delta
EndM

CALCDELTA2 Macro
  Mov  bx,StartVert2
  Shl  bx,2
  Movsx eax,Word Ptr fs:[di+bx]  ;  Get first X value, X1
  Mov  XVal2,eax
  Push eax                       ; Store X value on stack
  Movsx eax,Word Ptr fs:[di+bx+2]  ; Get Y Value, Y1
  Mov  bx,EndVert2
  Shl  bx,2
  Movsx ecx,Word Ptr fs:[di+bx]  ; Get Second X Value, X2
  Push ecx
  Movsx ecx,Word Ptr fs:[di+bx+2]  ; Get Y value, Y2
  Sub  ecx,eax
  Inc  ecx        ; cx := Y2-Y1+1
  Mov  edx,ecx    ; store in dx for later use
  Pop  ecx        ; Restore X2
  Pop  eax        ; Restore X1
  Sub  ecx,eax
  Shl  ecx,8      ; cx := (X2-X1) Shl 8
  Mov  eax,ecx
  Mov  ebx,edx    ; bx := Y2-Y1+1
  Mov  Count2,bx  ; Store Count2
  Cdq             ; Convert DWord in EAX to QWord in EDX:EAX
  Call ZeroCheck  ; Make sure divisor isn't 0
  Idiv ebx
  Mov  Delta2,eax    ; Store the first delta
EndM

HLINE Macro
;;  eax = X1, ebx = x2, dx = y
  Push eax
  Push ebx
  Push dx
  Cmp  dx,0     ; Check lower Y bound
  Jl  @Nothing
  Cmp  dx,199   ; Check upper Y bound
  Jg  @Nothing
  Shr  eax,8
  Shr  ebx,8
;;; Do clipping
  Cmp  bx,ax
  Jl @Nothing
  Cmp  ax,319
  Jg  @Nothing
  Cmp  bx,0
  Jl  @Nothing
  Cmp  ax,0      ; Left Clip
  Jg  @CheckBX
  Mov  ax,0
 @CheckBX:
  Cmp  bx,319    ; Right Clip
  Jle @DrawIt
  Mov  bx,319
 @DrawIt:
  Sub bx,ax
  Inc bx
  Mov cx,bx  ; Put Count in CX
  Mov di,ax
  Mov ax,320
  Mov bx,dx
  Mul bx
  Add di,ax
  Mov al,PolyColor
  Mov ah,al
  Shr cx,1
  Jnc @SkipSingle
  Stosb
 @SkipSingle:
  Jcxz @Nothing
  Rep Stosw
 @Nothing:
  Pop dx
  Pop ebx
  Pop eax
EndM


Proc DrawPoly Uses es si di,Vert:DWord,Num:Word,Col:Byte,PgSg:Word
;; VERT is a list of screen points
;; NUM is the number of points
;; COL is the color to draw the polygon
;; PGSG is the segment pointer to the screen
  Mov  al,Col
  Mov  PolyColor,al
  Mov  es,PgSg
  Mov  ax,Num
  Mov  Edges,ax
;;; Find minimum and maximum values
  FINDMINMAX
;;; Set up initial start an end vertex indicies
  Mov  ax,StartVert1
  Mov  StartVert2,ax
  Dec  ax
  Jns  @SkipV1Reset
  Mov  ax,Num
  Dec  ax
 @SkipV1Reset:
  Mov  EndVert1,ax   ; EVert1 := StartVert1 - 1;
  Mov  ax,StartVert2
  Inc  ax
  Cmp  ax,Num
  Jnz  @SkipV2Reset
  Mov  ax,0
 @SkipV2Reset:       ; EVert2 := StartVert2 + 1;
  Mov EndVert2,ax
;;;;  Calculate the delta values
  CALCDELTA1
  CALCDELTA2
;;;;  Begin Main loop
  ; While Edge > 1 do
 @EdgeLooper:
  Mov  ax,Edges
  Cmp  ax,1
  Jle @ExitTraceLoop
  Push di
  Mov  eax,XVal1
  Mov  ebx,XVal2
  Shl  eax,8        ; Make XVals .8 fixed point
  Shl  ebx,8
  Mov  cx,Count1
  Shl  ecx,16
  Mov  cx,Count2
  Mov  dx,YCount
  Push ebp
  Mov  ebp,Delta1
  Mov  esi,Delta2
 @TraceLoop:     ; This is it! This loop draws everything
  Push ecx
  Cmp  cx,0      ; Check if count2 is zero yet
  Jle  @ExitInnerTraceLoop
  Shr  ecx,16
  Cmp  cx,0      ; Check if count1 is zero
  Jle  @ExitInnerTraceLoop
  HLINE
  Add  eax,ebp   ; Increment XVal1 by Delta1
  Add  ebx,esi   ; Increment XVal2 by Delta2
  Pop  ecx
  Sub  ecx,00010001h  ; Subtract 1 from Count1 and Count2
  Inc  dx
  Jmp  @TraceLoop
 @ExitInnerTraceLoop:
  Shr  eax,8
  Mov  XVal1,eax   ; Store updated XVals
  Shr  ebx,8
  Mov  XVal2,ebx
  Pop  ecx
  Pop  ebp
  Pop  di
  Mov  Count2,cx
  Shr  ecx,16
  Mov  Count1,cx
  Mov  YCount,dx
;;;;;;  Up date left side vertex
  Mov  ax,Count1
  Cmp  ax,0      ; Check Count1
  Jg  @CheckNext
  Mov  ax,EndVert1
  Mov  StartVert1,ax
  Dec  ax
  Jns @SkipV1Reset2
  Mov  ax,Num
  Dec  ax
 @SkipV1Reset2:
  Mov  EndVert1,ax
  CALCDELTA1
  Dec  Edges
 @CheckNext:
;;;;;; Update right side vertex
  Mov  ax,Count2
  Cmp  ax,0
  Jg  @SkipCount2
  Mov  ax,EndVert2
  Mov  StartVert2,ax
  Inc  ax
  Cmp  ax,Num
  Jnz  @SkipV2Reset2
  Mov  ax,0
 @SkipV2Reset2:
  Mov  EndVert2,ax
  CALCDELTA2
  Dec  Edges
 @SkipCount2:
  Jmp @EdgeLooper
 @ExitTraceLoop:
  Ret
Endp DrawPoly

End