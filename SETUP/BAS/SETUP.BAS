'
'SETUP.BAS - MSE setup program for BWSB
'            Written by Edward Schlunder (1994)
'
' You may freely include this program along with your programs so long as
' the original copyrights remain intact.
'
'Note - This program can not be run from the QBX environment and it does
'       not properly compile with QB4.5. It is only compilable using PDS 7.

DEFINT A-Z                                      'Integers for speed

'Declare all the BWSB subs and functions:
'$INCLUDE: 'BWSB.BI'
'$INCLUDE: 'GDMTYPE.BI'

DECLARE FUNCTION OverLoad (FileName$, FileHandle%)
DECLARE FUNCTION ExePath$ ()
DECLARE FUNCTION ExeName$ ()

DECLARE SUB TestSound ()
DECLARE SUB SelectSoundQuality ()
DECLARE SUB SelectSoundCard ()
DECLARE SUB SelectSoundSettings ()

DECLARE SUB MPrint (Txt$)
DECLARE FUNCTION PopUpMenu% (Row%, Col%, Items%, CharsWide%, MenuHelp() AS STRING)

'ƒƒƒ  Setup screens  ƒƒ>
DECLARE SUB MainMenu (Row%, Col%)
DECLARE SUB SoundcardMenu (Row%, Col%)
DECLARE SUB IRQMenu (Row%, Col%)
DECLARE SUB BaseioMenu (Row%, Col%)
DECLARE SUB DMAMenu (Row%, Col%)
DECLARE SUB QualityMenu (Row%, Col%)

DECLARE SUB TestScreen (Row%, Col%)
DECLARE SUB ErrorScreen (Row%, Col%)

'ƒƒƒ  Direct screen read/write functions  ƒƒ>
DECLARE SUB XLocate (Row%, Col%)
DECLARE SUB BLocate (Row%, Col%)
DECLARE SUB XColor (Forg%, Back%)
DECLARE SUB XPrint (TxtSeg%, TxtOff%, TxtLen%)
DECLARE SUB PrintChar (TxtSeg%, TxtOff%, TxtLen%)
DECLARE SUB LineFeed ()
DECLARE SUB XColorFill (Length%)

TYPE MSEConfigFile
  SoundCard     AS INTEGER
  BaseIO        AS INTEGER
  IRQ           AS INTEGER
  DMA           AS INTEGER
  SoundQuality  AS INTEGER
END TYPE

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

DIM SHARED MenuHelp(10) AS STRING
DIM SHARED MSEConfig AS MSEConfigFile

'CONST RunLine$ = "Type MMP [enter] to run thing"
CONST Copyright$ = " BWSB Music and Sound Engine Setup      Copyright (c) 1993-95, Edward Schlunder"

DIM SoundCards(6)  AS STRING, SndQuality(4) AS STRING
SoundCards(0) = "NONE (Silence)"
SoundCards(1) = "Gravis UltraSound"
SoundCards(2) = "Sound Blaster 1.x"
SoundCards(3) = "Sound Blaster 2.x"
SoundCards(4) = "Sound Blaster Pro"
SoundCards(5) = "Sound Blaster 16"
SoundCards(6) = "Pro AudioSpectrum"

SndQuality(0) = "Medium Sound Quality"
SndQuality(1) = "High Sound Quality"
SndQuality(2) = "Super-High Sound Quality"
SndQuality(3) = "Low Sound Quality"

SCREEN 0: WIDTH 80, 25                 'Initialize right video mode
MSEConfig.SoundCard = 0                          'None
MSEConfig.SoundQuality = 0                       'Medium sound quality
MSEConfig.BaseIO = &HFFFF: MSEConfig.IRQ = &HFF: MSEConfig.DMA = &HFF'Autodetect

OPEN "MSE.CFG" FOR BINARY AS 1
  IF LOF(1) THEN GET 1, 1, MSEConfig
CLOSE 1

BLocate 80, 80                         'Now you see cursor, now you don't

DO
  MainMenu 0, 0                          'Put up the main screen
  XColor 1, 7: XLocate 1, 1: MPrint Copyright$
  XColor 8, 7
  XLocate 6, 51: MPrint SoundCards(MSEConfig.SoundCard)
  XLocate 7, 53: MPrint RIGHT$(HEX$(MSEConfig.BaseIO), 3)
  XLocate 0, 59
  IF MSEConfig.IRQ > 15 THEN MPrint HEX$(MSEConfig.IRQ) ELSE MPrint LTRIM$(RTRIM$(STR$(MSEConfig.IRQ)))
  XLocate 0, 64
  IF MSEConfig.DMA > 15 THEN MPrint HEX$(MSEConfig.DMA) ELSE MPrint LTRIM$(RTRIM$(STR$(MSEConfig.DMA)))
  XLocate 8, 51: MPrint SndQuality(MSEConfig.SoundQuality)


  MenuHelp(0) = "Select Sound Card for digital music and sound effects"
  MenuHelp(1) = "Select Sound Card configuration settings (Address, IRQ number, DMA channel)"
  MenuHelp(2) = "Select sound quality level"
  MenuHelp(3) = "Load MSE and try playing music"
  MenuHelp(4) = "Exit and save new setup"
  Result = PopUpMenu(6, 3, 5, 27, MenuHelp())

  SELECT CASE Result
  CASE 0: SelectSoundCard              'Select sound card
  CASE 1: SelectSoundSettings          'Select sound settings
  CASE 2: SelectSoundQuality           'Select sound quality
  CASE 3: TestSound                    'Test out the sound engine
  CASE 4                               'Save configuration
    FileHandle = FREEFILE
    OPEN "MSE.CFG" FOR BINARY AS FileHandle
      PUT FileHandle, 1, MSEConfig
    CLOSE FileHandle
    CLS
    PRINT "New configuration saved."
    PRINT RunLine$
    END

  CASE -1
    CLS
    PRINT "Setup aborted by user, new configuration not saved."
    END
  END SELECT
LOOP

FUNCTION ExeName$
DIM Regs AS RegTypeX

Regs.ax = &H6200
CALL InterruptX(&H21, Regs, Regs)

DEF SEG = Regs.bx
DEF SEG = PEEK(44) + PEEK(45) * 256

DO
   IF PEEK(Byte) = 0 THEN
     IF PEEK(Byte + 1) = 0 THEN
       Byte = Byte + 2
       EXIT DO
     END IF
   END IF
   Byte = Byte + 1
LOOP

IF PEEK(Byte) = 1 THEN
  Byte = Byte + 2
  DO WHILE PEEK(Byte)
    Temp$ = Temp$ + CHR$(PEEK(Byte))
    Byte = Byte + 1
  LOOP
END IF
IF INSTR(Temp$, "QBX.EXE") THEN Temp$ = "D:\BWSB\MAKE\CODE\SETUP\SETUP.EXE"
ExeName$ = Temp$

DEF SEG
END FUNCTION

FUNCTION ExePath$
DIM Regs AS RegTypeX

Regs.ax = &H6200
CALL InterruptX(&H21, Regs, Regs)

DEF SEG = Regs.bx
DEF SEG = PEEK(44) + PEEK(45) * 256

DO
   IF PEEK(Byte) = 0 THEN
   IF PEEK(Byte + 1) = 0 THEN
   Byte = Byte + 2
   EXIT DO
   END IF
   END IF
   Byte = Byte + 1
LOOP

IF PEEK(Byte) = 1 THEN
Byte = Byte + 2
DO WHILE PEEK(Byte)
Temp$ = Temp$ + CHR$(PEEK(Byte))
Byte = Byte + 1
LOOP
MYNAME$ = Temp$
END IF
DEF SEG

FOR X = LEN(MYNAME$) TO 1 STEP -1
 Char = ASC(MID$(MYNAME$, X, 1))
  IF Char = 58 OR Char = 92 THEN
    ExePath$ = LEFT$(MYNAME$, X)
    EXIT FOR
  END IF
NEXT
END FUNCTION

SUB MPrint (Txt$)
XPrint SSEG(Txt$), SADD(Txt$), LEN(Txt$)
END SUB

FUNCTION OverLoad (FileName$, FileHandle)
DIM OverEnd AS OVREND, OverEntry AS OVRLOAD
GET FileHandle, LOF(FileHandle) - 14, OverEnd
IF OverEnd.ID <> "OverLoader" THEN
  XLocate 25, 1: XColor 12, 7
  MPrint "OverLoader: Couldn't find OverLoader ID."
  DO: LOOP UNTIL LEN(INKEY$)
  EXIT FUNCTION
END IF
SEEK FileHandle, OverEnd.Location
FOR J = 1 TO ASC(OverEnd.Entries)
GET FileHandle, , OverEntry
IF UCASE$(RTRIM$(OverEntry.FileName)) = UCASE$(LEFT$(FileName$, INSTR(FileName$, CHR$(0)))) THEN GOTO Done
NEXT

Done:
SEEK FileHandle, OverEntry.Location
OverLoad = OverEntry.Length MOD &H80FF
END FUNCTION

FUNCTION PopUpMenu (Row%, Col%, Items%, CharsWide%, MenuHelp() AS STRING)
CurrItem = 0
XColor 8, 7: XLocate 25, 1
MPrint MenuHelp(CurrItem) + SPACE$(80 - LEN(MenuHelp(CurrItem)))

XLocate Row + CurrItem, Col
XColor 0, 7: XColorFill CharsWide

DO
  DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
  IF LEN(Key$) = 1 THEN
    SELECT CASE ASC(Key$)
    CASE 13                            'Enter key
      XLocate Row + CurrItem, Col
      XColor 15, 1: XColorFill CharsWide
      PopUpMenu% = CurrItem%
      EXIT FUNCTION
    CASE 27                            'Escape key
      XLocate Row + CurrItem, Col
      XColor 15, 1: XColorFill CharsWide
      PopUpMenu% = -1
      EXIT FUNCTION
    END SELECT
  ELSE
    SELECT CASE ASC(RIGHT$(Key$, 1))
    CASE 72                            'Up key
      IF CurrItem > 0 THEN
        XLocate Row + CurrItem, Col
        XColor 15, 1: XColorFill CharsWide
        CurrItem = CurrItem - 1
        XLocate Row + CurrItem, Col
        XColor 0, 7: XColorFill CharsWide

        XColor 8, 7
        XLocate 25, 1
        MPrint MenuHelp(CurrItem) + SPACE$(80 - LEN(MenuHelp(CurrItem)))
      END IF
    CASE 80                            'Down key
      IF CurrItem < Items - 1 THEN
        XLocate Row + CurrItem, Col
        XColor 15, 1: XColorFill CharsWide
        CurrItem = CurrItem + 1
        XLocate Row + CurrItem, Col
        XColor 0, 7: XColorFill CharsWide

        XColor 8, 7
        XLocate 25, 1
        MPrint MenuHelp(CurrItem) + SPACE$(80 - LEN(MenuHelp(CurrItem)))
      END IF
    END SELECT
  END IF
LOOP
END FUNCTION

SUB SelectSoundCard
    MenuHelp(0) = "Select this if you don't have a sound card or don't want any sound"
    MenuHelp(1) = "Gravis UltraSound from Advanced Gravis                                 -Stereo-"
    MenuHelp(2) = "Sound Blaster 1.xx and other close compatibles                         - Mono -"
    MenuHelp(3) = "Sound Blaster 2.xx by Creative Labs                                    - Mono -"
    MenuHelp(4) = "Sound Blaster Pro by Creative Labs                                     -Stereo-"
    MenuHelp(5) = "Sound Blaster 16 by Creative Labs                                      -Stereo-"
    MenuHelp(6) = "Pro AudioSpectrum and other compatibles (SoundMan 16)                  -Stereo-"

    SoundcardMenu 8, 24
    Result = PopUpMenu(12, 27, 7, 25, MenuHelp())
    IF Result <> -1 THEN MSEConfig.SoundCard = Result
END SUB

SUB SelectSoundQuality
    MenuHelp(0) = "Medium Sound Quality, for slow 386s                                 (16000 Hz)"
    MenuHelp(1) = "High Sound Quality, for fast 386s/slow 486s                         (22000 Hz)"
    MenuHelp(2) = "Super-High Sound Quality, for fast 486s                             (45000 Hz)"
    MenuHelp(3) = "Low Sound Quality, use this if none of the above work on your system (8000 Hz)"
    MenuHelp(4) = ""
    MenuHelp(5) = ""
    MenuHelp(6) = ""

    QualityMenu 10, 25
    Result = PopUpMenu(14, 28, 4, 25, MenuHelp())
    IF Result <> -1 THEN MSEConfig.SoundQuality = Result
END SUB

SUB SelectSoundSettings
    MenuHelp(0) = "Select this if you are unsure what your setting is or your setting isn't listed"
    MenuHelp(1) = ""
    MenuHelp(2) = ""
    MenuHelp(3) = ""
    MenuHelp(4) = ""
    MenuHelp(5) = ""
    MenuHelp(6) = ""

    BaseioMenu 8, 24
    Result = PopUpMenu(12, 27, 7, 25, MenuHelp())
    IF Result = -1 THEN EXIT SUB
    IF Result = 0 THEN
      MSEConfig.BaseIO = &HFFFF
    ELSE
      MSEConfig.BaseIO = &H200 + Result * &H10
    END IF

    IRQMenu 8, 24               'Display the IRQ menu
    Result = PopUpMenu(12, 27, 8, 25, MenuHelp())
    IF Result = -1 THEN EXIT SUB
    SELECT CASE Result
    CASE 0: MSEConfig.IRQ = &HFF
    CASE 1: MSEConfig.IRQ = 2
    CASE 2: MSEConfig.IRQ = 5
    CASE 3: MSEConfig.IRQ = 7
    CASE 4: MSEConfig.IRQ = 10
    CASE 5: MSEConfig.IRQ = 11
    CASE 6: MSEConfig.IRQ = 12
    CASE 7: MSEConfig.IRQ = 15
    END SELECT

    DMAMenu 8, 24               'Display the DMA menu
    XLocate 22, 25
    XColor 8, 0: MPrint "≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤"
    Result = PopUpMenu(12, 27, 7, 25, MenuHelp())
    IF Result = -1 THEN EXIT SUB
    SELECT CASE Result
    CASE 0: MSEConfig.DMA = &HFF
    CASE 1: MSEConfig.DMA = 0
    CASE 2: MSEConfig.DMA = 1
    CASE 3: MSEConfig.DMA = 3
    CASE 4: MSEConfig.DMA = 5
    CASE 5: MSEConfig.DMA = 6
    CASE 6: MSEConfig.DMA = 7
    END SELECT
END SUB

SUB TestSound
DIM ModHead         AS GDMHeader       'Module Header
DIM SndDevMSE(6)    AS STRING          'Array of MSE file names
DIM ErrTxt(12)      AS STRING          'Array of MSE errors
DIM ErrTxtLoad(12)  AS STRING          'Array of GDM load errors
ErrTxt$(1) = "Base I/O address autodetection failure"
ErrTxt$(2) = "IRQ level autodetection failure"
ErrTxt$(3) = "DMA channel autodetection failure"
ErrTxt$(4) = "DMA channel not supported"
ErrTxt$(5) = ""
ErrTxt$(6) = "Sound device does not respond"
ErrTxt$(7) = "Memory control blocks destroyed"
ErrTxt$(8) = "Insufficient memory for mixing buffers"
ErrTxt$(9) = "Insufficient memory for MSE file"
ErrTxt$(10) = "MSE has invalid identification string (corrupt/non-existant)"
ErrTxt$(11) = "MSE disk read failure"
ErrTxt$(12) = "MVSOUND.SYS not loaded (required for PAS use)"

IF MSEConfig.SoundCard = 0 THEN EXIT SUB 'If no sound, don't test it

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

MSE$ = SndDevMSE(MSEConfig.SoundCard) + ".MSE"

'Set up our sound system:
Ov = 44
SELECT CASE MSEConfig.SoundQuality
CASE 0: Ov = 16
CASE 1: Ov = 22
CASE 2: Ov = 45
CASE 3: Ov = 8
END SELECT
ErFl = LoadMSE(MSE$, 0, Ov, 4096, MSEConfig.BaseIO, MSEConfig.IRQ, MSEConfig.DMA)

IF ErFl THEN
  ErrorScreen 14, 4
  XColor 4, 7: XLocate 16, 19: MPrint STR$(ErFl)
  XColor 15, 1: XLocate 18, 16
  IF ErFl <= 12 THEN
    MPrint ErrTxt$(ErFl)
  ELSE
    MPrint "Unknown error"
  END IF
  DO: LOOP UNTIL LEN(INKEY$)
  EXIT SUB
END IF

File = FREEFILE
OPEN ExeName$ FOR BINARY AS File
A = OverLoad("SLIMJIMS.GDM", File)
'Load our module
LoadGDM FILEATTR(File, 2), SEEK(File) - 1, ErFl, VARSEG(ModHead), VARPTR(ModHead)
CLOSE File
IF ErFl THEN
  EXIT SUB
END IF


MusicChannels = 0                      'Start out at zero..
FOR J = 1 TO 32                        'Scan for used music channels
  IF ASC(MID$(ModHead.PanMap, J, 1)) <> &HFF THEN
    MusicChannels = MusicChannels + 1
  END IF
NEXT

A& = StartOutput(MusicChannels, 0) 'Start your (sound) engines
StartMusic                                'Revv up the music playing

TestScreen 10, 9
XColor 15, 1
XLocate 14, 19: MPrint ModHead.SongTitle
XLocate 15, 22: MPrint ModHead.SongMusician
OldOrd = 2
DO
  FOR J = 1 TO 4
    VU = ChannelVU(J, ChannelVU(J, &HFF) - 1) \ 2
    IF VU THEN XLocate 15 + J, 12: XColor 10, 1: XColorFill VU
    IF 16 - VU THEN XLocate 15 + J, 12 + VU: XColor 0, 1: XColorFill 16 - VU
  NEXT
  Ord = MusicOrder(&HFF)
  IF Ord <> OldOrd THEN
    XColor 10, 1
    XLocate 17, 29 + Ord * 6: MPrint "€€€€€€"
    XLocate 18, 29 + Ord * 6: MPrint "€€€€€€"
    XColor 15, 1
    XLocate 17, 29 + OldOrd * 6: MPrint "±±±±±±"
    XLocate 18, 29 + OldOrd * 6: MPrint "±±±±±±"
  END IF
  OldOrd = Ord
  XColor 15, 1
  XLocate 14, 64: MPrint "Row:" + STR$(MusicRow) + " "
  FOR X = 0 TO 10
    OldTimer& = TIMER
    DO: LOOP UNTIL TIMER <> OldTimer&
  NEXT
LOOP UNTIL LEN(INKEY$)
FreeMSE
END SUB

