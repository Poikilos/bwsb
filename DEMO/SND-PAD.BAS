'ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
'              Bells, Whistles, and Sound Boards. Version 1.02
'       Copyright (C) 1993-94, Edward Schlunder. 
'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
' SND-PAD.BAS - Example GDM sound effect player.
'               Written by Edward Schlunder (1994)
'
'ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
DEFINT A-Z

'Declare all the BWSB subs and functions:
'$INCLUDE: 'BWSB.BI'
'$INCLUDE: 'GDMTYPE.BI'

'$LINK "MSE_PB.OBJ"
'$INCLUDE "BWSB.PBI"
'$INCLUDE "GDMTYPE.BI"

DECLARE SUB SetScreen ()
DECLARE SUB UpScreen ()

TYPE MSEConfigFile
  SoundCard     AS INTEGER
  BaseIO        AS INTEGER
  IRQ           AS INTEGER
  DMA           AS INTEGER
  SoundQuality  AS INTEGER
END TYPE

TYPE RegTypeX
  ax AS INTEGER
  bx AS INTEGER
  cx AS INTEGER
  dx AS INTEGER
  bp AS INTEGER
  SI AS INTEGER
  DI AS INTEGER
  Flags AS INTEGER
  ds AS INTEGER
  es AS INTEGER
END TYPE

TYPE RegType
  ax AS INTEGER
  bx AS INTEGER
  cx AS INTEGER
  dx AS INTEGER
  bp AS INTEGER
  SI AS INTEGER
  DI AS INTEGER
  Flags AS INTEGER
END TYPE

DIM ModHead         AS GDMHeader       'Module Header
DIM SndDevMSE(6)    AS STRING          'Array of MSE file names
DIM MSEConfig       AS MSEConfigFile   'Structure of MSE configuration file

Freemem& = FRE(-1) - 80000             'Basic Heap - EXE Memory (80000)
A& = SETMEM(-Freemem&)                 'This is the memory freed for module
                                       'and MSE usage.
'Table of MSE file names
SndDevMSE(1) = "GUS"                   'Gravis Ultrasound
SndDevMSE(2) = "SB1X"                  'Sound Blaster 1.xx
SndDevMSE(3) = "SB2X"                  'Sound Blaster 2.xx
SndDevMSE(4) = "SBPRO"                 'Sound Blaster Pro
SndDevMSE(5) = "SB16"                  'Sound Blaster 16
SndDevMSE(6) = "PAS"                   'Pro AudioSpectrum 16

OPEN "MSE.CFG" FOR BINARY AS 1
  GET 1, , MSEConfig
CLOSE 1
IF MSEConfig.SoundCard = 0 THEN
  PRINT "No Sound Selected in SETUP. Please run SETUP."
  END
END IF
'============================================================================

MSE$ = SndDevMSE(MSEConfig.SoundCard) + ".MSE"

SELECT CASE MSEConfig.SoundQuality
CASE 0: Ov = 16
CASE 1: Ov = 22
CASE 2: Ov = 45
CASE 3: Ov = 8
END SELECT

'Set up our sound system:
ErrorFlag = LoadMSE(MSE$, 0, Ov, 4096, MSEConfig.BaseIO, MSEConfig.IRQ, MSEConfig.DMA)

SELECT CASE ErrorFlag
CASE 0
CASE 1: PRINT "Base I/O address autodetection failure": END
CASE 2: PRINT "IRQ level autodetection failure": END
CASE 3: PRINT "DMA channel autodetection failure": END
CASE 4: PRINT "DMA channel not supported": END
CASE 6: PRINT "Sound device does not respond": END
CASE 7: PRINT "Memory control blocks destroyed": END
CASE 8: PRINT "Insufficient memory for mixing buffers": END
CASE 9: PRINT "Insufficient memory for MSE file": END
CASE 10: PRINT "MSE has invalid identification string (corrupt/non-existant)": END
CASE 11: PRINT "MSE disk read failure": END
CASE 12: PRINT "MVSOUND.SYS not loaded (required for PAS use)": END
CASE ELSE: PRINT "Unknown error on MSE startup" + STR$(ErrorFlag): END
END SELECT

'Display the actual settings *used* in the MSE.
PRINT DeviceName$
PRINT "Addr: "; HEX$(MSEConfig.BaseIO); "h  IRQ:"; MSEConfig.IRQ; " DMA:"; MSEConfig.DMA

IF LEN(COMMAND$) = 0 THEN INPUT "Module file: ", ModFile$ ELSE ModFile$ = COMMAND$

TestMOD:
IF LEN(ModFile$) = 0 THEN END
IF INSTR(ModFile$, ".") = 0 THEN ModFile$ = ModFile$ + ".GDM"

PRINT "Loading Module: "; ModFile$

IF EmsExist THEN ErrorFlag = 1 ELSE ErrorFlag = 0   'Setup EMS use flag
File = FREEFILE
OPEN ModFile$ FOR BINARY AS File
'Load our module
LoadGDM FILEATTR(File, 2), 0, ErrorFlag, VARSEG(ModHead), VARPTR(ModHead)
CLOSE File

SELECT CASE ErrorFlag
CASE 0
CASE 1: PRINT "Module is corrupt": END
CASE 2: PRINT "Could not autodetect module type": END
CASE 3: PRINT "Bad format ID": END
CASE 4: PRINT "Out of memory": END
CASE 5: PRINT "Cannot unpack samples": END
CASE 6: PRINT "AdLib samples not supported": END
CASE ELSE: PRINT "Unknown Load Error:" + STR$(ErrorFlag): END
END SELECT

OverRate& = StartOutput(1, 0)             'Setup for 1 sound effect channel

CurSample = 0: CurFreq& = 22000: CurPan = 8
CLS
SetScreen
DO
  DO
    G$ = INKEY$                          'Poll the keyboard for keys
  LOOP UNTIL LEN(G$)
  SELECT CASE ASC(RIGHT$(G$, 1))
  CASE 72                                'Up key
    IF CurSample THEN CurSample = CurSample - 1
    UpScreen
  CASE 80                                'Down key
    CurSample = CurSample + 1
    UpScreen
  CASE 60, 44, 75                        '<
    IF CurFreq& > 4000 THEN CurFreq& = CurFreq& - 1000
    UpScreen
  CASE 62, 46, 77                        '>
    IF CurFreq& < 44000 THEN CurFreq& = CurFreq& + 1000
    UpScreen
  CASE 32                                'Space Bar
    PlaySample 1, CurSample, CurFreq&, 64, CurPan
  CASE 27                                'Esc
    EXIT DO
  END SELECT
LOOP

FreeMSE                                'Unload the module and free MSE
COLOR 7, 0
CLS
END

SUB SetScreen
DIM Regs AS RegTypeX, SamHead AS SamHeader

File = FREEFILE
OPEN "SND-PAD.BIN" FOR BINARY AS File
  'Load the screen
  Regs.ax = &H3F00
  Regs.bx = FILEATTR(File, 2)
  Regs.ds = &HB800: Regs.dx = 0
  Regs.cx = 8000
  CALL InterruptX(&H21, Regs, Regs)
CLOSE File

COLOR 15, 4
GetSampleTable 0, VARSEG(SamHead), VARPTR(SamHead)
LOCATE 7, 5: PRINT SamHead.SamName;

COLOR 15, 0
FOR J = 1 TO 17                        'Display all sample names
  GetSampleTable J, VARSEG(SamHead), VARPTR(SamHead)
  LOCATE J + 7, 5: PRINT SamHead.SamName;
NEXT
END SUB

SUB UpScreen
DIM SamHead AS SamHeader
SHARED CurSample, CurFreq&
COLOR 15, 4
GetSampleTable CurSample, VARSEG(SamHead), VARPTR(SamHead)
LOCATE 7, 5: PRINT SamHead.SamName;
COLOR 7, 1: LOCATE , 2: PRINT RIGHT$(RTRIM$(STR$(CurSample)), 2);

FOR J = 1 TO 17                        'Display all sample names
  GetSampleTable J + CurSample, VARSEG(SamHead), VARPTR(SamHead)
  COLOR 15, 0: LOCATE J + 7, 5: PRINT SamHead.SamName;
  COLOR 7, 1: LOCATE , 2: PRINT RIGHT$(RTRIM$(STR$(J + CurSample)), 2);
NEXT

F = CurFreq& \ 1000
COLOR 15, 0: LOCATE 15, 68: PRINT RIGHT$(RTRIM$(STR$(F)), 2);

COLOR 0, 7
LOCATE 16, 40: PRINT STRING$(F - 4, 196);
LOCATE 16, 36 + F: PRINT "þ";
PRINT STRING$(44 - F, 196);
END SUB

