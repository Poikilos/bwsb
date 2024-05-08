Unit MCGA;
{$G+,A+}

Interface

Var
  Page0, Page1 : Word;
  Frames : Longint;


Procedure SetMode(Mode : Word);
Function Alloc(Paras : Word) : Word;
Procedure FreeAlloc(Address : Word);
Procedure CopyPage(Source, Dest : Word);
Procedure ClearPage(Dest : Word);
Procedure SetPalette;
Procedure PutScaledSprite(X, Y, Size : Integer; Var Image; Page : Word);
Procedure DeCompPCX(Var PCX; Dest, BottomLine : Word);
Function CheckHit : Boolean;
Procedure ShowCross(P : Word);

Implementation

{$F+}
{$L Pal.Obj}
Procedure Palette; External;
{$F-}

Function Alloc(Paras : Word) : Word; Assembler;

Asm
  Mov ah,48h
  Mov bx,Paras
  Int 21h
  Jnc @Exit
  Mov ax,0ffffh
 @Exit:
End;

Procedure FreeAlloc(Address : Word); Assembler;

Asm
  Mov  es,Address
  Mov  ah,49h
  Int  10h
End;

Procedure SetMode(Mode : Word); Assembler;

Asm
  Mov  ax,Mode
  Int  10h
  Mov  ax,64000/16
  Push ax
  Call Alloc
  Mov  Page1,ax
  Mov  ax,$A000
  Mov  Page0,ax
  Mov  ax,Page1
  Push ax
  Call ClearPage
End;

Procedure CopyPage(Source, Dest : Word); Assembler;

Asm
  db 66h; Inc Word Ptr [Frames]        { Inc DWord Ptr [Frames] }
  Push  ds
  Mov   es,Dest
  Mov   ds,Source
  Mov   di,0
  Mov   si,di
  db 66h; Mov  cx,16000; db 00h,00h    { Mov  ecx,16000 }
  db 66h; Rep  Movsw;                  { Rep  Movsd     }
  Pop   ds
End;

Procedure ClearPage(Dest : Word); Assembler;

Asm
  Mov  es,Dest
  Mov  di,0
  db 66h; Xor ax,ax                 { Xor eax,eax }
  db 66h; Mov cx,16000; db 00h,00h  { Mov ecx,16000 }
  db 66h; Rep Stosw                 { Rep Stosd }
End;


Procedure SetPalette;

Var
  Count : Word;

Begin
  Port[$3c8] := 0;
  For Count := 0 to 767 do
    Port[$3c9] := Mem[Seg(Palette):Ofs(Palette)+Count];
End;

Procedure PutScaledSprite(X, Y, Size : Integer; Var Image; Page : Word);
{ in : X - X Location of Sprite           }
{      Y - Y Location of Sprite           }
{      Size - Size to make X and Y length }
{      Image - Sprite data                }
{      Page - Segment Pointer to gfx page }
{* No Clipping is performed  *}


Var
  PicX, PicY : Integer;
  Offset, Segment : Word;
  XPos, YPos : Word;
  XStart : Word;
  XStep, YStep : Integer;
  YCount, XCount : Integer;
  O1, O2 : Integer;

Begin
  Offset := Ofs(Image);
  Segment := Seg(Image);
  PicX := MemW[Segment:Offset];
  PicY := MemW[Segment:Offset+2];
  Offset := Offset + 4;
  XStep := (PicX Shl 8) Div (Size);
  YStep := (PicY Shl 8) Div (Size);
  YPos := 0;
  XPos := 0;
  O1 := Y * 320 + x;
  For YCount := Y to (Y + Size - 1) do
    Begin
      O2 := (YPos Shr 8) * PicX + Offset;
      Asm
        Push  ds
        Mov   es,Page
        Mov   di,O1
        Mov   ds,Segment
        Mov   si,O2
        Mov   dx,XPos
        Mov   bl,dh
        Xor   bh,bh
        Mov   cx,Size
        Push  bp
        Mov   bp,XStep

       @Looper:
        Mov  al,ds:[si+bx]
        Mov  es:[di],al
        Add  dx,bp
        Mov  bl,dh
        Inc  di
        Dec  cx
        Jnz  @Looper

        Pop  bp
        Mov  O1,di
        Pop  ds
      End;
      O1 := O1 + (320 - Size);
      YPos := YPos + YStep;
      XPos := 0;
    End;
End;

Procedure DeCompPCX(Var PCX; Dest, BottomLine : Word); Assembler;
{ Decompresses a PCX picture _fast_                           }
{ Can keep the PCX picture compressed in memory.              }
{ treates color 0 as transparent.                             }

{ in : PCX - Pointer to PCX file in memory                    }
{      Dest - Segment pointer to memory location to put image }
{      BottomLine - Offset to end decompression (YLine*320)   }

Asm
  Push ds
  Lds  si,PCX     { Make ds:si point to PCX picture }
  Mov  es,Dest    { Make es:di point to screen }
  Mov  di,0
  Add  si,128
  Xor  cx,cx
  Xor  ah,ah
 @OuterLoop:
  Mov  al,ds:[si]
  Mov  cl,al
  Mov  bl,al
  Inc  si
  And  bl,11000000b
  Cmp  bl,11000000b
  Jnz @RunLen1
  And  cl,00111111b   {  cl = Runlength }
  Mov  al,ds:[si]     {  al = color     }
  Inc  si
  Jmp @DoitLoop
 @RunLen1:
  Mov  cl,1
 @DoItLoop:
  Cmp  al,0
  Je  @Skip0Color
 @InnerLoop:
  Mov  es:[di],al
  Inc  di
  Dec  cl
  Jz  @GotoNext
  Cmp  di,BottomLine
  Jnz  @InnerLoop
  Jmp @AllDone
 @Skip0Color:
  Add  di,cx    { Increment screen offset by length of 0 color run }
 @GotoNext:
  Cmp  di,BottomLine
  Jnz  @OuterLoop
 @AllDone:
  Pop  ds
End;

Function CheckHit : Boolean;

Var
  Temp : Byte;

Begin
  Temp := Mem[Page0:32160];
  CheckHit := ((Temp >= 65) and (Temp <= 77));
End;

Procedure ShowCross(p : Word);

Var
  X : Integer;

Begin
  For x := -8 to -1 do
    Begin
      Mem[P:(100+x)*320+160] := 15;
      Mem[P:32000+(160+x)] := 15;
    End;
  For x := 1 to 8 do
    Begin
      Mem[P:(100+x)*320+160] := 15;
      Mem[P:32000+(160+x)] := 15;
    End;
End;

Begin
  Frames := 0;
End.