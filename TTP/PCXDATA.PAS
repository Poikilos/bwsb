Unit PCXData;
{ The Linked PCX cockpit data file }

Interface

Var
  CockPitAddr : Pointer;
  TitleAddr : Pointer;

Procedure Cockpit;

Implementation

{$F+}
{$L Pit.OBJ}
Procedure CockPit; External;

{$L Title.OBJ}
Procedure TitlePCX; External;
{$F-}


Begin
  CockPitAddr := Addr(CockPit);
  TitleAddr := Addr(TitlePCX);
End.