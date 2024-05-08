Unit Stuff;

Interface

Uses
  Crt,
  MCGA,       { Some graphics routines    }
  Vector,     { Vector graphics stuff     }
  PCXData,    { CockPit data              }
  Explosions; { Explosion bitmap data     }

Procedure EndProg(S : String);
Procedure InitGraphics;
Procedure CleanUp;
Procedure DrawExplosion;
Procedure GetKeyStuff(Var LRAngle, UDAngle : Integer; Var Fired, Quit : Boolean);
Procedure DisplayIt(Var Fired : Boolean; Side : Integer; LR,UD : Word);
Procedure TitleScreen;
Procedure KickKBDaemon;
Procedure FreeKBDaemon;


Implementation

{$F+}
{$L KBDAEMON.OBJ}
Procedure KBDaemon (Var Up, Down, Left, Right : Boolean); External;
Procedure KickKBDaemon; External;
Procedure FreeKBDaemon; External;
{$F-}

Var
  ShowCage : Boolean;
  KeyUp, KeyDwn, KeyLft, KeyRgt : Boolean;
  LocalX, LocalY, LocalZ : Word;

Procedure EndProg(S : String);

Begin
  Writeln(S);
  Halt(0);
End;

Procedure InitGraphics;

Begin
  SetMode($13);
  If Page1 = $FFFF
    Then Begin
      SetMode($03);
      EndProg('Could not allocate virtual screen.');
    End;
End;

Procedure CleanUp;

Begin
  FreeAlloc(Page1);
  SetMode($03);
End;

Procedure DrawExplosion;

Var
  Target : Integer;

Begin
  For Target := 1 to 32 do
      Begin
        ClearPage(Page1);
        PutStars;
        PutScaledSprite(160-(Target Shr 1), 100-(Target Shr 1), Target, Exp1^, Page1);
        If ShowCage
          Then DeCompPCX(CockPitAddr^, Page1, 199*320)
          Else ShowCross(Page1);
        CopyPage(Page1, Page0);
      End;
    For Target := 32 to 48 do
      Begin
        ClearPage(Page1);
        PutStars;
        PutScaledSprite(158-(Target Shr 1), 98-(Target Shr 1), Target, Exp2^, Page1);
        If ShowCage
          Then DeCompPCX(CockPitAddr^, Page1, 199*320)
          Else ShowCross(Page1);
        CopyPage(Page1, Page0);
      End;
    For Target := 1 to 15 do
      Begin
        ClearPage(Page1);
        PutStars;
        PutScaledSprite(160-20, 100-20, 48, Exp3^, Page1);
        If ShowCage
          Then DeCompPCX(CockPitAddr^, Page1, 199*320)
          Else ShowCross(Page1);
        CopyPage(Page1, Page0);
      End;
      Delay(1000);
End;

Procedure GetKeyStuff(Var LRAngle, UDAngle : Integer; Var Fired, Quit : Boolean);

Begin
  KBDaemon(KeyUp, KeyDwn, KeyLft, KeyRgt);

  If KeyRgt Then Begin                     { Right Arrow }
    LRAngle := LRAngle + 1;
    If LRAngle > 384 Then LRAngle := 384;
  End;

  If KeyUp Then Begin                      { Up Arrow }
    UDAngle := UDAngle + 1;
    If UDAngle > 384 Then UDAngle := 384;
  End;

  If KeyDwn Then Begin                     { Down Arrow }
    UDAngle := UDAngle - 1;
    If UDAngle < 128 Then UDAngle := 128;
  End;

  If KeyLft Then Begin                     { Left Arrow }
    LRAngle := LRAngle - 1;
    If LRAngle < 128 Then LRAngle := 128;
  End;

  If KeyPressed
    Then Begin
      Case ReadKey of
        #27 : Quit := True;
        #32 : Fired := True;
        #13 : ShowCage := Not(ShowCage);
      End;
    End;
End;

Procedure DoVector(LRAngle, UDAngle : Word);

Begin
  LocalX := (LocalX + 2) And 511;
  LocalY := (LocalY + 2) And 511;
  LocalZ := (LocalZ + 2) And 511;
  LocalRotate(LocalX, LocalY, LocalZ);
  Scale;
  GlobalTransLate;
  UpDatePos;
  GlobalRotate(-UDAngle And 511, -LRAngle And 511, 0);
  PutStars;
  DisplayVec;
  If ShowCage
    Then DeCompPCX(CockPitAddr^, Page1, 199*320)
    Else ShowCross(Page1);
  CopyPage(Page1, Page0);
  ClearPage(Page1);
End;

Procedure DisplayIt(Var Fired : Boolean; Side : Integer; LR,UD : Word);

Var
  Count : Integer;

Begin
  If Fired
    Then Begin
      For Count := 1 to 10 do
        Begin
          DrawLaser(Side);
          DoVector(LR, UD);
        End;
      Fired := False;
    End
    Else DoVector(LR, UD);
End;

Procedure TitleScreen;

Var
  Ch : Char;

Begin
  DeCompPCX(TitleAddr^, Page0, 200*320);
  ch := ReadKey;
End;

Begin
  ShowCage := True;
End.