DEFINT A-Z
DIM SBTick(-1 TO 45)
SBTick(-1) = 250
FOR J& = 0 TO 45
  FOR H& = 1 TO 255
    IF (1000000 / (H& + 1)) \ 1000 = J& THEN EXIT FOR
  NEXT
  IF H& = 256 THEN SBTick(J&) = SBTick(J& - 1) ELSE SBTick(J&) = H&
NEXT

OPEN "SBTICK.INC" FOR OUTPUT AS #1
PRINT #1, "SBTickTable    db      ";

PRINT #1, RTRIM$(STR$(SBTick(0)));
FOR J = 1 TO 45
  IF J MOD 14 = 0 THEN
    PRINT #1, ""
    PRINT #1, "               db       "; RIGHT$("  " + RTRIM$(STR$(SBTick(J))), 3);
  ELSE
    PRINT #1, ","; RIGHT$(RTRIM$(STR$(SBTick(J))), 3);
  END IF
NEXT

CLOSE #1

