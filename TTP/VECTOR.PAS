Unit Vector;

Interface

Uses MCGA;

Const
  NumStars = 200;

Type
  LCoord = Record
    x, y, z : Longint;
  End;
  LList = Array[0..7] of LCoord;
  LNormal = Array[0..5] of LCoord;
  PolyDesc = Array[0..5,0..3] of Byte;
  SCoord = Record
    x, y : Integer;
  End;
  SList = Array[0..7] of SCoord;
  SField = Array[0..NumStars] of SCoord;

Const
  NumColors = 12;
  ColorStart = 65;
  EndPosition : LCoord = (x:0; y:0; z:-10000);
  Viewer : LCoord = (x:0;y:0;z:4096);
  Local : LList = ((x:50; y:50;  z:50),
                   (x:50; y:-50; z:50),
                   (x:-50; y:-50; z:50),
                   (x:-50; y:50; z:50),
                   (x:50; y:50; z:-50),
                   (x:50; y:-50; z:-50),
                   (x:-50; y:-50; z:-50),
                   (x:-50; y:50; z:-50));
  Polygons:PolyDesc=((0,3,2,1),(5,6,7,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(0,1,5,4));
  Normals:LNormal=((x:0;y:0;z:4096),(x:0;y:0;z:-4096),(x:0;y:-4096;z:0),
                   (x:-4096;y:0;z:0),(x:0;y:4096;z:0),(x:4096;y:0;z:0));

Var
  LStars, WStars : SField;
  Circle : Array[0..511] of SCoord;

Procedure InitStars;
Procedure LocalRotate(X, Y, Z : Word);
Procedure GlobalTranslate;
Procedure GlobalRotate(X, Y, Z : Word);
Procedure DisplayVec;
Procedure Scale;
Procedure UpDatePos;
Procedure SpawnTarget(CirPos, Z, Sca : Longint);
Procedure PutStars;
Procedure DrawLaser(Side : Integer);
Procedure InitCircle;

Implementation

Var
  ScaleSize : Longint;
  World : LList;
  WNormals : LNormal;
  Screen : SList;
  XPos, YPos, ZPos : Integer;
  CirclePos : Word;

{$F+}
{$L Rotate.Obj}
Procedure RotatePoints(Var Local, World; Num, X, Y, Z : Word); External;
Procedure ScalePoints(Var Word; Num : Word; Sf : Longint); External;
Procedure Project(Var World, Screen; Num : Word); External;

{$L Poly.Obj}
Procedure DrawPoly(Var Sc; Num : Word; Color : Byte; PG : Word); External;
{$F-}

Procedure InitStars;

Var
  x : Integer;

Begin
  RandSeed := 1001;
  For x := 0 to NumStars do
    Begin
      LStars[x].x := Random(900) - 450;
      LStars[x].y := Random(900) - 450;
    End;
End;

Procedure LocalRotate(X, Y, Z : Word);

Begin
  RotatePoints(Local, World, 8, X, Y, Z);
  RotatePoints(Normals, WNormals, 6, X, Y, Z);
End;

Procedure Scale;

Begin
  ScalePoints(World, 8, ScaleSize);
End;

Procedure GlobalTranslate;

Var
  Count : Integer;

Begin
  For Count := 0 to 7 do
    Begin
      World[Count].x := World[Count].x + Circle[CirclePos].x;
      World[Count].y := World[Count].y + Circle[CirclePos].y;
      World[Count].z := World[Count].z + ZPos;
    End;
End;

Procedure GlobalRotate(X, Y, Z : Word);

Var
  xc : Integer;

Begin
  RotatePoints(World, World, 8, X, Y, Z);
  RotatePoints(WNormals, WNormals, 6, X, Y, Z);
  For xc := 0 to NumStars do
    Begin
      WStars[xc].x := LStars[xc].x + (y - 256) Shl 2;
      WStars[xc].y := LStars[xc].y - (x - 256) Shl 2;
    End;
End;

Function Visible(W : LNormal; Num : Word) : Word;

Var
  Dot : Longint;

Begin
  Dot := (Viewer.x * W[Num].x) + (Viewer.y * W[Num].y) + (Viewer.z * W[Num].z);
  If Dot >= 0
    Then Visible := ((Dot Shr 12) * NumColors) Shr 12
    Else Visible := $ff00;
End;

Procedure PutStars;

Var
  Count : Integer;

Begin
  For Count := 0 to NumStars do
    With WStars[Count] do
      Begin
        If ((X >= 0) and (X <= 319)) And
           ((Y >= 0) and (Y <= 199))
            Then Mem[Page1:y*320+x] := 15;
      End;
End;

Procedure DisplayVec;

Var
  SmallList : Array[0..3] of SCoord;
  Count : Integer;
  Intensity : Word;
  Convert : Integer;

Begin
  Project(World, Screen, 8);
  For Count := 0 to 6 do
    Begin
      Intensity := Visible(WNormals, Count);
      If (Intensity And $ff00) = 0
        Then Begin
          For Convert := 0 to 3 do
            Begin
              SmallList[Convert].x := Screen[Polygons[Count,Convert]].x;
              SmallList[Convert].y := Screen[Polygons[Count,Convert]].y;
            End;
          DrawPoly(SmallList, 4, ColorStart + (NumColors - Lo(Intensity) + 1), Page1);
        End;
    End;
End;

Procedure SpawnTarget(CirPos, Z, Sca : Longint);

Begin
  CirclePos := CirPos;
  ZPos := Z;
  ScaleSize := Sca;
End;

Procedure UpdatePos;

Begin
  CirclePos := (CirclePos + 1) And 511;
End;


Procedure DrawLaser(Side : Integer);

Var
  LaserList : Array[0..2] of SCoord;

Begin
  If Side = 1
    Then Begin
      LaserList[0].x := 0;
      LaserList[0].y := 110;
      LaserList[1].x := 160;
      LaserList[1].y := 100;
      LaserList[2].x := 0;
      LaserList[2].y := 130;
    End
    Else Begin
      LaserList[0].x := 160;
      LaserList[0].y := 100;
      LaserList[1].x := 319;
      LaserList[1].y := 110;
      LaserList[2].x := 319;
      LaserList[2].y := 130;
    End;
  DrawPoly(LaserList, 3, 249, Page1);
End;

Procedure InitCircle;

Var
  x : Longint;

Begin
  For x := 0 to 511 do
    Begin
      Circle[x].x := Round(Cos(x*(Pi*2)/512)*300);
      Circle[x].y := Round(Sin(x*(Pi*2)/512)*300);
    End;
End;

End.