Unit Explosions;

Interface

Var
  Exp1, Exp2, Exp3 : Pointer;

Implementation

{$F+}
{$L Exp1.obj}
Procedure Explosion1; External;

{$L Exp2.obj}
Procedure Explosion2; External;

{$L Exp3.obj}
Procedure Explosion3; External;
{$F-}

Begin
  Exp1 := Addr(Explosion1);
  Exp2 := Addr(Explosion2);
  Exp3 := Addr(Explosion3);
End.