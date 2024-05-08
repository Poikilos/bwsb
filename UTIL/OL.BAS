DEFINT A-Z
TYPE OVRLOAD
  FileName      AS STRING * 12
  Location      AS LONG
  Length        AS LONG
END TYPE
TYPE OVREND
  ID            AS STRING * 10
  Entries       AS STRING * 1
  Location      AS LONG
END TYPE
DIM Over(255) AS OVRLOAD, OverEnd AS OVREND
PRINT "OverLoader v1.01 by Zilym Limms/OverThrowMachine"


Sp = INSTR(COMMAND$, " ")
IF Sp THEN
  ExeFile$ = MID$(COMMAND$, 1, Sp)
  BinFile$ = MID$(COMMAND$, Sp + 1)
ELSE
  PRINT "No filename specified"
  END
END IF
OPEN ExeFile$ FOR BINARY AS 1
OPEN BinFile$ FOR BINARY AS 2

GET 1, LOF(1) - 14, OverEnd
IF OverEnd.ID = "OverLoader" THEN
  SEEK 1, OverEnd.Location
  FOR J = 1 TO ASC(OverEnd.Entries)
  GET 1, , Over(J)
  NEXT
  OverEnd.Entries = CHR$(ASC(OverEnd.Entries) + 1)
  SEEK 1, OverEnd.Location
ELSE
  OverEnd.ID = "OverLoader"
  OverEnd.Entries = CHR$(1)
  SEEK 1, LOF(1) + 1
END IF
Over(ASC(OverEnd.Entries)).FileName = LTRIM$(RTRIM$(BinFile$)) + STRING$(12, 0)
Over(ASC(OverEnd.Entries)).Length = LOF(2)
Over(ASC(OverEnd.Entries)).Location = SEEK(1)

LOCATE , 1
PRINT "Copying File"
SamLoc& = LOF(2)
SL& = LOF(2)
FF = 0
DO
  IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
  Buffer$ = SPACE$(BL)
  GET 2, , Buffer$
  PUT 1, , Buffer$
LOOP UNTIL FF

PRINT "Done"
OverEnd.Location = SEEK(1)
FOR J = 1 TO ASC(OverEnd.Entries)
  PUT 1, , Over(J)
NEXT
PUT 1, , OverEnd

