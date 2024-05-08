'ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
'                     Bells, Whistles, and Sound Boards
'       Copyright (c) 1993-95, Edward Schlunder. 
'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
' PBMMP.BAS - Example GDM module player.
'             Written by Edward Schlunder (1994-95)
'
'ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
DEFINT A-Z

'Comment/Uncomment the approriate code--------------------------
REM $INCLUDE: 'BWSB.BI'              '\ These lines for QB/PDS
REM $INCLUDE: 'GDMTYPE.BI'           '/

$LINK "..\LIB\MSE_PB.OBJ"        '\
$INCLUDE "..\INCLUDE\BWSB.PBI"   ' | Use these lines for PB3.x
$INCLUDE "..\INCLUDE\GDMTYPE.BI" '/
'---------------------------------------------------------------

TYPE MSEConfigFile
  SoundCard     AS INTEGER
  BaseIO        AS INTEGER
  IRQ           AS INTEGER
  DMA           AS INTEGER
  SoundQuality  AS INTEGER
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


'Print our little header thing:
PRINT
PRINT "BWSB v1.15 Example Module Player"
PRINT "Copyright (c) 1993-95, Edward Schlunder"
PRINT

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

'Display the actutal settings *used* in the MSE.
PRINT "Addr: "; HEX$(MSEConfig.BaseIO); "h  ";
PRINT "IRQ:"; MSEConfig.IRQ; " ";
PRINT "DMA:"; MSEConfig.DMA

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

MusicChannels = 0                      'Start out at zero..
FOR J = 1 TO 32                        'Scan for used music channels
  IF ASC(MID$(ModHead.PanMap, J, 1)) <> &HFF THEN
    MusicChannels = MusicChannels + 1
  END IF
NEXT

PRINT
PRINT "Channels:"; MusicChannels; " Song: "; ModHead.SongTitle
OverRate& = StartOutput(MusicChannels, 0) 'Start your (sound) engines
StartMusic                                'Revv up the music playing

PRINT "Oversampling:"; OverRate&; "Hz"
PRINT "D for DOS Shell or any other key to quit"
PRINT
DO
  G$ = INKEY$                          'Poll the keyboard for keys

  IF G$ = "D" OR G$ = "d" THEN         'Do a DOS Shell?
    SHELL
    G$ = ""
  END IF

  LOCATE , 1                           'Update the music information
  PRINT "Playing Music ฤ> Order:"; MusicOrder(&HFF); " Pattern:"; MusicPattern(&HFF); " Row:"; MusicRow; "           ";
LOOP UNTIL LEN(G$)

StopMusic
StopOutput
UnloadModule
FreeMSE                                'Free MSE from system and memory
END

