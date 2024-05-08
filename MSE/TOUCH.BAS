DEFINT A-Z

File$ = COMMAND$
NAME File$ + ".MSE" AS File$ + ".OLD"

OPEN File$ + ".OLD" FOR BINARY AS 1
OPEN File$ + ".MSE" FOR BINARY AS 2
Temp$ = SPACE$(131)
GET #1, , Temp$
PUT #2, , Temp$
GET #1, , A%
A% = LOF(1)
AA& = LOF(1)
PUT #2, , A%

Temp$ = SPACE$(16000)
DO
  GET #1, , Temp$
  EndStop = INSTR(Temp$, "STOP")
  IF EndStop THEN
    Temp$ = LEFT$(Temp$, EndStop - 1)
    PUT #2, , Temp$
    EXIT DO
  END IF
  PUT #2, , Temp$
LOOP UNTIL EOF(1)
PRINT "Bytes Removed:"; AA& - SEEK(2)
CLOSE 1, 2
KILL File$ + ".OLD"

