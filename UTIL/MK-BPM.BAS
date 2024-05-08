DEFINT A-Z

OPEN "BPMTABLE.INC" FOR OUTPUT AS 1

PRINT #1, "BPMTable        dw      ";
FOR BPM = 32 TO 255
  Numb = (BPM / 2.5) * 256
  IF (BPM - 31) MOD 9 = 0 THEN
    PRINT #1, RIGHT$(RTRIM$("   " + STR$(Numb)), 5)
    PRINT #1, "                dw      ";
    Numb = 0
  ELSE
  IF BPM < 255 THEN
    PRINT #1, RIGHT$(RTRIM$("   " + STR$(Numb)), 5); ",";
  ELSE
    PRINT #1, RIGHT$(RTRIM$("   " + STR$(Numb)), 5);
  END IF
    Numb = 0
  END IF
NEXT
CLOSE 1

