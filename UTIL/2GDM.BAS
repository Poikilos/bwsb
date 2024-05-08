DECLARE SUB AbortProg ()
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
'                      Bells, Whistles, and Sound Boards
'       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
' 2GDM.BAS - 8MED MED STM ULT S3M MOD MTM FAR 669 to GDM conversion program
'            Written by Edward Schlunder (1993-95)
'
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DEFINT A-Z

'$INCLUDE: 'BWSB.BI'
'$INCLUDE: 'GDMTYPE.BI'

DECLARE FUNCTION AmigaWord% (AmiWord%)              'Swaps MSB and LSB
DECLARE FUNCTION AmigaLong& (AmiLong&)              'Swaps MSW and LSW
DECLARE SUB AmigaSam8 (SamSeg%, SamOff%, SamLen%)   'Convert Signed<->Unsigned

DECLARE SUB ConvertMED ()
DECLARE SUB ConvertSTM ()
DECLARE SUB ConvertULT (Kin%)
DECLARE SUB ConvertS3M ()
DECLARE SUB ConvertMOD (NC%, NS%)
DECLARE SUB ConvertMTM ()
DECLARE SUB ConvertFAR ()
DECLARE SUB Convert669 ()
DECLARE SUB ConvertXM ()
DECLARE SUB DetermineFile ()

'$DYNAMIC
DIM SHARED GDMHead  AS GDMHeader, GDMText$
DIM SHARED OrderTable(255) AS STRING * 1
DIM SHARED FileType, File$
DIM SHARED SamHead(255) AS SamHeader2
DIM SHARED PT(4, 11), PanTable(31)

PT(0, 0) = 1712: PT(0, 1) = 1616: PT(0, 2) = 1525: PT(0, 3) = 1440
PT(0, 4) = 1357: PT(0, 5) = 1281: PT(0, 6) = 1209: PT(0, 7) = 1141
PT(0, 8) = 1077: PT(0, 9) = 1017: PT(0, 10) = 961: PT(0, 11) = 907

PT(1, 0) = 856: PT(1, 1) = 808: PT(1, 2) = 762: PT(1, 3) = 720
PT(1, 4) = 678: PT(1, 5) = 640: PT(1, 6) = 604: PT(1, 7) = 570
PT(1, 8) = 538: PT(1, 9) = 508: PT(1, 10) = 480: PT(1, 11) = 453

PT(2, 0) = 428: PT(2, 1) = 404: PT(2, 2) = 381: PT(2, 3) = 360
PT(2, 4) = 339: PT(2, 5) = 320: PT(2, 6) = 302: PT(2, 7) = 285
PT(2, 8) = 269: PT(2, 9) = 254: PT(2, 10) = 240: PT(2, 11) = 226

PT(3, 0) = 214: PT(3, 1) = 202: PT(3, 2) = 190: PT(3, 3) = 180
PT(3, 4) = 170: PT(3, 5) = 160: PT(3, 6) = 151: PT(3, 7) = 143
PT(3, 8) = 135: PT(3, 9) = 127: PT(3, 10) = 120: PT(3, 11) = 113

PT(4, 0) = 107: PT(4, 1) = 101: PT(4, 2) = 95: PT(4, 3) = 90
PT(4, 4) = 85: PT(4, 5) = 80: PT(4, 6) = 76: PT(4, 7) = 71
PT(4, 8) = 67: PT(4, 9) = 64: PT(4, 10) = 60: PT(4, 11) = 57

'FileTypes:
'0-MTM   1-669   2-S3M   3-STM   4-STX   5-FAR    6-PSM
'7-MED0  8-15MOD 9-4MOD  10-6MOD 11-8MOD 12-16MOD 13-32MOD
'14-ULT1 15-ULT2 16-ULT3 17-     18-     19-XM    20-DMF

CONST major = 1, minor = 20, NumModTypes = 13

GDMHead.ID = "GDMþ": GDMHead.ID2 = "GMFS"
GDMHead.DOSEOF = CHR$(13) + CHR$(10) + CHR$(26)
GDMHead.TrackID = 0
GDMHead.TrackMajorVer = CHR$(major): GDMHead.TrackMinorVer = CHR$(minor)
GDMHead.FormMajorVer = CHR$(1): GDMHead.FormMinorVer = CHR$(0)

PRINT "Module->GDM Format Converter.  Version"; RTRIM$(STR$(major)); "."; LTRIM$(STR$(minor))
PRINT "By Edward Schlunder              (c)1994-95"
PRINT

FileType$ = "MODNSTWOWOCTFARULTMMDMEDMTM669STMS3M8MEXM "

IF LEN(COMMAND$) THEN
  Sp = INSTR(COMMAND$, " ")
  IF Sp THEN
    File$ = MID$(COMMAND$, 1, Sp - 1)
    GDMFile$ = MID$(COMMAND$, Sp + 1)
    IF INSTR(GDMFile$, ".GDM") = 0 THEN GDMFile$ = GDMFile$ + ".GDM"
  ELSEIF INSTR(COMMAND$, "*") THEN
NextModule:
    IF ModTypeSelect >= NumModTypes THEN GOTO EndProg
    IF INSTR(COMMAND$, ".") THEN
      File$ = DIR$(COMMAND$)
    ELSE
      File$ = DIR$(COMMAND$ + "." + MID$(FileType$, ModTypeSelect * 3 + 1, 3))
    END IF
    IF LEN(File$) = 0 THEN ModTypeSelect = ModTypeSelect + 1: GOTO NextModule
    GDMFile$ = LEFT$(File$, LEN(File$) - 4) + ".GDM"
    GOTO StartConvert
  ELSE
    File$ = COMMAND$
    Temp = INSTR(File$, ".")
    IF Temp THEN
      GDMFile$ = LEFT$(File$, Temp - 1) + ".GDM"
    ELSE
      GDMFile$ = File$ + ".GDM"
    END IF

  END IF
ELSE
  PRINT "No filename specified"
  END
END IF

NewFileTry:
IF LEN(DIR$(File$)) = 0 THEN
  IF INSTR(File$, ".") <> 0 THEN
    PRINT "File not found!"
    END
  ELSE
    FOR J = 0 TO NumModTypes
      'PRINT File$ + "." + MID$(FileType$, j * 3 + 1, 3);
      t$ = DIR$(File$ + "." + MID$(FileType$, J * 3 + 1, 3))
      'PRINT T$
      IF LEN(t$) THEN EXIT FOR
    NEXT
    File$ = File$ + "."
    IF LEN(t$) THEN File$ = File$ + MID$(FileType$, J * 3 + 1, 3)
    GOTO NewFileTry
  END IF
END IF

StartConvert:
OPEN File$ FOR BINARY AS #1
PRINT File$;
LOCATE , 36
DetermineFile
IF FileType <> 255 THEN OPEN GDMFile$ FOR BINARY AS #2
SELECT CASE FileType
CASE 0: PRINT "MTM->GDM": ConvertMTM
CASE 1: PRINT "669->GDM": Convert669
CASE 2: PRINT "S3M->GDM": ConvertS3M
CASE 3: PRINT "STM->GDM": ConvertSTM
CASE 4: PRINT "STX->GDM"
CASE 5: PRINT "FAR->GDM": ConvertFAR
CASE 6: PRINT "PSM->GDM"
CASE 7: PRINT "MED->GDM": ConvertMED
CASE 8: PRINT "MOD->GDM": ConvertMOD 4, 15
CASE 9: PRINT "MOD->GDM": ConvertMOD 4, 31
CASE 10: PRINT "MOD->GDM": ConvertMOD 6, 31
CASE 11: PRINT "MOD->GDM": ConvertMOD 99, 31
CASE 12: PRINT "MOD->GDM": ConvertMOD 16, 31
CASE 13: PRINT "MOD->GDM": ConvertMOD 32, 31
CASE 14: PRINT "ULT->GDM": ConvertULT 1 '1.0 -> 1.3
CASE 15: PRINT "ULT->GDM": ConvertULT 2 '1.4
CASE 16: PRINT "ULT->GDM": ConvertULT 3 '1.5
CASE 17: PRINT "ULT->GDM": ConvertULT 4 '1.6
CASE 18: PRINT ""
CASE 19: PRINT " XM->GDM": ConvertXM
CASE 20: PRINT "DMF->GDM"
CASE 255: PRINT : PRINT "Unrecognized file format!"
END SELECT

IF INSTR(COMMAND$, "*") THEN
  IF ModTypeSelect > NumModTypes THEN GOTO EndProg
  File$ = DIR$
  IF LEN(File$) = 0 AND INSTR(COMMAND$, ".") = 0 THEN ModTypeSelect = ModTypeSelect + 1: GOTO NextModule
  IF LEN(File$) = 0 THEN GOTO EndProg
  GDMFile$ = LEFT$(File$, LEN(File$) - 4) + ".GDM"
  GOTO StartConvert
END IF

EndProg:
IF FileType <> 255 THEN PRINT "Conversion complete!"

REM $STATIC
SUB AbortProg
PRINT
PRINT "Program aborted by user!"
END
END SUB

SUB Convert669
DIM OldFX(7)  AS INTEGER, OldData(7) AS INTEGER
GDMHead.FormOrigin = 4                 'Composer 669

SEEK 2, LEN(GDMHead) + 1
Byte$ = " "
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
GDMHead.BPM = CHR$(78)                 'BPM of 78 for 669s
GET #1, 3, GDMHead.SongTitle           'Get song title
GDMHead.SongTitle = RTRIM$(GDMHead.SongTitle) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GDMHead.MastVol = CHR$(64)

GET #1, &HF2, GDMHead.Tempo            'Get default Tempo
GET #1, 111, GDMHead.NOS: GDMHead.NOS = CHR$(ASC(GDMHead.NOS) - 1)
GET #1, 112, GDMHead.NOP: GDMHead.NOP = CHR$(ASC(GDMHead.NOP) - 1)
FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 7 STEP 2
PanTable(J) = 0: PanTable(J + 1) = 15
NEXT
NOC = 8

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Message Text Conversion
Temp$ = SPACE$(36)
GET #1, 3, Temp$: GDMText$ = RTRIM$(Temp$) + CHR$(13) + CHR$(10)
GET #1, , Temp$: GDMText$ = GDMText$ + RTRIM$(Temp$) + CHR$(13) + CHR$(10)
GET #1, , Temp$: GDMText$ = GDMText$ + RTRIM$(Temp$) + CHR$(26)
GDMHead.MTLength = LEN(GDMText$): GDMHead.MTOffset = SEEK(2) - 1
PUT #2, , GDMText$: GDMText$ = ""

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
OrderList$ = SPACE$(128)
GET #1, 114, OrderList$
GDMHead.OrdOffset = SEEK(2) - 1
DEF SEG = SSEG(OrderList$)
FOR J = 0 TO 127
  Ord$ = MID$(OrderList$, J + 1, 1)
  IF ASC(Ord$) = &HFF THEN EXIT FOR
  PUT #2, , Ord$
NEXT
GDMHead.NOO = CHR$(J - 1)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
SEEK 1, &H1F2
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 0
  GET #1, , SamHead(Sample).FileName
  SamHead(Sample).SamName = SamHead(Sample).FileName + STRING$(32, 0)
  GET #1, , Byte$
  GET #1, , SamHead(Sample).Length
  GET #1, , SamHead(Sample).LoopBegin
  GET #1, , SamHead(Sample).LoopEnd

  SamHead(Sample).Pan = CHR$(&HFF)
  SamHead(Sample).Volume = CHR$(&HFF)
  SamHead(Sample).C4Hertz = 8363

  IF SamHead(Sample).LoopEnd <> &HFFFFF THEN HT = HT + 1
  IF SamHead(Sample).LoopEnd = &HFFFFF THEN SamHead(Sample).LoopEnd = 0
  SamHead(Sample).Flags = CHR$(HT)
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
PRINT
MaxChannels = 0
GDMHead.PatOffset = SEEK(2) - 1
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  LOCATE , 1
  PRINT "Converting Pattern:"; Pattern;
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  Lc& = (ASC(GDMHead.NOS) + 1) * 25
  Lk& = Pattern
  Lk& = Lk& * 1536
  Lc& = Lc& + Lk&
  Lc& = Lc& + &H1F2
  SEEK 1, Lc&
  Music$ = SPACE$(1536)
  GET 1, , Music$
  J& = 0
  K& = SEEK(1)
  Temp$ = " "
  GET 1, 370 + Pattern, Temp$: Break = ASC(Temp$)
  GET 1, 242 + Pattern, Temp$
  Tempo = ASC(Temp$)
  GTE = 0
  SEEK 1, K&
  FX2 = 0: FX1 = 0
  FOR Row = 0 TO Break
    FOR Channel = 0 TO 7
      FX2 = 0
      FX1 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + J&)
      Byte2 = PEEK(SADD(Music$) + J& + 1)
      Byte3 = PEEK(SADD(Music$) + J& + 2)

      GDMNote = 0: GDMIns = 0
      IF Row = 0 AND GTE = 0 THEN FX2 = &HF: FX2Data = Tempo
      IF Byte1 < &HFE THEN
        Octave = Byte1 \ 48
        Note = Byte1 \ 4 MOD 12
        GDMNote = (((Octave + 2) * 16) + Note) + 1
        GDMIns = Byte2 \ 16 + ((Byte1 AND 3) * 16) + 1
        OldData(Channel) = 0
      END IF
      IF Byte1 < &HFF THEN
        FX1 = &HC
        FX1Data = INT((Byte2 AND &HF) * 4.26666666666667#)
        IF FX1Data > 64 THEN FX1Data = 64
      END IF
      IF Byte3 < &HFF THEN
        EFX = Byte3 \ 16
        Dat = Byte3 AND &HF
        SELECT CASE EFX
        CASE 0: FX2 = 1: FX2Data = Dat  'Ax- Porta up, x=speed
          OldFX(Channel) = FX2: OldData(Channel) = FX2Data
          IF FX2Data = 0 THEN FX2 = 0
        CASE 1: FX2 = 2: FX2Data = Dat 'Bx- Porta down, x=speed
          OldFX(Channel) = FX2: OldData(Channel) = FX2Data
          IF FX2Data = 0 THEN FX2 = 0
        CASE 2                         'Cx- Porta to note, x=speed
          FX2 = 3: FX2Data = Dat
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
          OldFX(Channel) = FX2: OldData(Channel) = FX2Data
          IF FX2Data = 0 THEN FX2 = 0
        CASE 3                         'Dx- Frequency adjust, x=freq
          FX2 = &HE: FX2Data = &H50 + Dat
          IF FX2Data = 0 THEN FX2Data = &H50
        CASE 4: FX2 = 4: FX2Data = Dat 'Ex- Vibrato, x=depth
          OldFX(Channel) = FX2: OldData(Channel) = FX2Data
          IF FX2Data = 0 THEN FX2 = 0
        CASE 5: FX2 = &HF: FX2Data = Dat 'Fx- Set tempo, x=tempo
        CASE 6                         'Gx- Extended commands
          SELECT CASE Dat
          CASE 0': FX2 = &HE: FX2Data = &H61  'G0- Fine pan left
          CASE 1': FX2 = &HE: FX2Data = &H71  'G1- Fine pan right
          END SELECT
        CASE 7: FX2 = &H12: FX2Data = Dat     'Hx- Slot retrig
        END SELECT
      ELSE
        SELECT CASE OldFX(Channel)
        CASE 1, 2, 3, 4
          IF OldData(Channel) <> 0 THEN
            FX2 = OldFX(Channel): FX2Data = OldData(Channel)
          END IF
        END SELECT
      END IF
      IF Row = 0 THEN IF FX2 = &HF THEN GTE = -1
      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 AND FX2 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
          Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
        ELSE
          IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
          IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      J& = J& + 3
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Copy Samples
PRINT
GDMHead.SamOffset = SEEK(2) - 1
NOP& = ASC(GDMHead.NOP) + 1
NOS& = ASC(GDMHead.NOS) + 1
FOR J = 0 TO ASC(GDMHead.NOS)
  LOCATE , 1
  PRINT "Copying Sample:"; J;
  IF INKEY$ = CHR$(27) THEN AbortProg

  SEEK 1, &H1F2 + NOS& * 25 + NOP& * 1536 + SamLoc&
  SamLoc& = SamLoc& + SamHead(J).Length
  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$
    PUT #2, , Buffer$
  LOOP UNTIL FF
NEXT
PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertFAR
DIM VibraDep(16)
GDMHead.FormOrigin = 5                 'Farandole Composer

Byte$ = " "
SEEK 2, LEN(GDMHead) + 1

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
GET #1, 5, GDMHead.SongTitle
GDMHead.SongTitle = RTRIM$(GDMHead.SongTitle) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GET #1, 48, HDLen
GET #1, 50, Byte$: IF Byte$ <> CHR$(&H10) THEN PRINT "Incorrect Format Version!": END
GET #1, 76, Byte$: GDMHead.Tempo = Byte$
GDMHead.BPM = CHR$(80)
GDMHead.MastVol = CHR$(64)
FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 15
GET #1, , Byte$: PanTable(J) = ASC(Byte$)
NEXT

GET #1, 97, MTLen: GDMHead.MTLength = MTLen
GDMText$ = SPACE$(GDMHead.MTLength)
GET #1, 99, GDMText$
Heder& = SEEK(1)
GET #1, Heder& + 257, GDMHead.NOO
GDMHead.NOO = CHR$(ASC(GDMHead.NOO) - 1)
SEEK 1, Heder&
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
Temp$ = SPACE$(ASC(GDMHead.NOO) + 1)
GET #1, , Temp$
PUT #2, , Temp$
DEF SEG = SSEG(Temp$)
NOP = 0

SEEK 1, Heder& + 259
DIM PatLen(255) AS LONG
FOR J = 0 TO 255
  GET #1, , Byte$: PatLen(J) = ASC(Byte$)
  GET #1, , Byte$: PatLen(J) = PatLen(J) + ASC(Byte$) * 256
  IF PatLen(J) <> 0 THEN NOP = J
NEXT
GDMHead.NOP = CHR$(NOP)

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
SEEK 1, HDLen + 1
GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  IF PatLen(Pattern) = 0 THEN GOTO NextPattern
  GET #1, , Byte$: Break = ASC(Byte$) + 1
  GET #1, , Byte$
  Music$ = SPACE$(PatLen(Pattern) - 2)
  J& = 0
  GET #1, , Music$
  FOR Row = 0 TO Break
    FOR Channel = 0 TO 15
      FX1 = 0: FX2 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + J&)
      Byte2 = PEEK(SADD(Music$) + J& + 1)
      Byte3 = PEEK(SADD(Music$) + J& + 2)
      Byte4 = PEEK(SADD(Music$) + J& + 3)
      GDMNote = 0: GDMIns = 0
      IF Byte1 <> 0 THEN
        Byte1 = Byte1 - 1
        Octave = Byte1 \ 12
        Note = Byte1 MOD 12
        GDMNote = ((Octave + 3) * 16 + Note) + 1
        GDMIns = (Byte2 AND &H3F) + 1
      END IF
      IF Byte3 <> 0 THEN
        FX2 = &HC: FX2Data = INT(((Byte3 - 1) MOD 16) * 4.26666666666667#)
        IF FX2Data > 64 THEN FX2Data = 64
      END IF
      IF Byte4 <> 0 THEN
        EFX = Byte4 \ 16
        Dat = Byte4 AND &HF
        SELECT CASE EFX
        CASE &H1: FX1 = 1: FX1Data = Dat               '1x Porta Up
        CASE &H2: FX1 = 2: FX1Data = Dat               '2x Porta Down
        CASE &H3: FX1 = 3: FX1Data = Dat               '3x Porta to Note
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        CASE &H4: FX1 = &H12: FX1Data = Dat            '4x Retrigger
        CASE &H5: FX1 = &H4: FX1Data = Dat             '5x Vibrato Depth
        CASE &H6: FX1 = &H4: FX1Data = Dat * 16        '6x Vibrato
        CASE &H7: FX1 = &HE: FX1Data = &HA0 + Dat      '7x Fine Volume Up
        CASE &H8: FX1 = &HE: FX1Data = &HB0 + Dat      '8x Fine Volume Down
        CASE &HB: FX1 = &H1E: FX1Data = &H80 + Dat     'Bx Set Pan
        CASE &HF: FX1 = &HF: FX1Data = Dat             'Fx Set Tempo
        END SELECT
      END IF
      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
        IF GDMNote = 0 AND GDMIns = 0 AND FX1 = &HF AND Channel + 1 > MaxChannels THEN
          Chan = MaxChannels + 1
          FXChan = 1
        ELSE
          IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
          Chan = Channel
        END IF
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          IF GDMIns > 25 THEN H = 1
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 AND FX2 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
          Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
        ELSE
          IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
          IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      J& = J& + 4
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
NextPattern:
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
MaxChannels = MaxChannels + FXChan
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

DIM SamSaved(64)
Temp$ = SPACE$(8)
GET #1, , Temp$
FOR J = 1 TO 8
  Byte = ASC(MID$(Temp$, J, 1))
  FOR Bit = 0 TO 7
    IF Byte AND 2 ^ Bit THEN SamSaved(N) = 1: NOS = N
    N = N + 1
  NEXT
NEXT
GDMHead.NOS = CHR$(NOS)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion

GDMHead.SamHeadOffset = SEEK(2) - 1
DIM SamOffset(NOS) AS LONG
PRINT
FOR Sample = 0 TO NOS
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4
  IF SamSaved(Sample) <> 0 THEN
    GET #1, , SamHead(Sample).SamName
    Zero = INSTR(SamHead(Sample).SamName, CHR$(0))
    IF Zero THEN SamHead(Sample).SamName = LEFT$(SamHead(Sample).SamName, Zero) + STRING$(32, 0)
    GET #1, , SamHead(Sample).Length
    SamHead(Sample).Pan = CHR$(17)
    GET #1, , Byte$
    SELECT CASE ASC(Byte$)
    CASE 0: SamHead(Sample).C4Hertz = 8363
    CASE 1: SamHead(Sample).C4Hertz = 8424
    CASE 2: SamHead(Sample).C4Hertz = 8485
    CASE 3: SamHead(Sample).C4Hertz = 8547
    CASE 4: SamHead(Sample).C4Hertz = 8608
    CASE 5: SamHead(Sample).C4Hertz = 8671
    CASE 6: SamHead(Sample).C4Hertz = 8734
    CASE 7: SamHead(Sample).C4Hertz = 8797
    CASE 8: SamHead(Sample).C4Hertz = 7894
    CASE 9: SamHead(Sample).C4Hertz = 7951
    CASE 10: SamHead(Sample).C4Hertz = 8009
    CASE 11: SamHead(Sample).C4Hertz = 8067
    CASE 12: SamHead(Sample).C4Hertz = 8125
    CASE 13: SamHead(Sample).C4Hertz = 8184
    CASE 14: SamHead(Sample).C4Hertz = 8244
    CASE 15: SamHead(Sample).C4Hertz = 8303
    CASE ELSE: PRINT ASC(Byte$)
    END SELECT
    GET #1, , SamHead(Sample).Volume
    SamHead(Sample).Volume = CHR$(INT((ASC(SamHead(Sample).Volume) MOD 16) * 4.26666666666667#))
    GET #1, , SamHead(Sample).LoopBegin
    GET #1, , SamHead(Sample).LoopEnd
    GET #1, , Byte$: IF Byte$ = CHR$(1) THEN HT = HT + 2
    GET #1, , Byte$: IF Byte$ = CHR$(8) THEN HT = HT + 1
    SamHead(Sample).FileName = LEFT$(SamHead(Sample).SamName, 13)
    SamOffset(Sample) = SEEK(1)
    SEEK 1, SEEK(1) + SamHead(Sample).Length
    SamHead(Sample).Flags = CHR$(HT)
  ELSE
    SamHead(Sample).Length = 0
  END IF
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
PRINT
GDMHead.SamOffset = SEEK(2) - 1
FOR J = 0 TO NOS
  PRINT "Converting Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  IF SamHead(J).Length = 0 THEN GOTO SkipSample
  SEEK 1, SamOffset(J)
  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$: AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    PUT #2, , Buffer$
  LOOP UNTIL FF
SkipSample:
NEXT
PUT #2, 1, GDMHead
CLOSE 1, 2
PRINT : PRINT
END SUB

SUB ConvertMED
GDMHead.FormOrigin = 8                 'MED module

Byte$ = " "
SEEK 2, LEN(GDMHead) + 1
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
Temp$ = "MMD ": GET #1, 1, Temp$
SELECT CASE Temp$
  CASE "MMD0": MEDType = 0
  CASE "MMD1": MEDType = 1
  CASE ELSE: PRINT "Unknown MED module type!": END
END SELECT
GET #1, 5, ModLen&: ModLen& = AmigaLong(ModLen&)
GET #1, 9, SongOffset&: SongOffset& = AmigaLong(SongOffset&)
GET #1, 17, PatPoint&: PatPoint& = AmigaLong(PatPoint&)
GET #1, 25, SamHeadOff&: SamHeadOff& = AmigaLong(SamHeadOff&)
GET #1, 33, ExpOffset&: ExpOffset& = AmigaLong(ExpOffset&)

'Expansion Data Structure:
IF ExpOffset& > 0 THEN
  GET #1, ExpOffset& + 1 + 4, SamExt&: SamExt& = AmigaLong(SamExt&)
  GET #1, , NSE: NSE = AmigaWord(NSE)
  GET #1, , SESize: SESize = AmigaWord(SESize)

  GET #1, , TxtOff&: TxtOff& = AmigaLong(TxtOff&)
  GET #1, , TxtLen&: TxtLen& = AmigaLong(TxtLen&)

  GET #1, , SamOff&: SamOff& = AmigaLong(SamOff&)
  GET #1, , SamNum: SamNum = AmigaWord(SamNum)
  GET #1, , SamSize: SamSize = AmigaWord(SamSize)

  IF TxtOff& > 0 THEN
    GDMText$ = SPACE$(TxtLen&)
    GET #1, TxtOff& + 1, GDMText$
  END IF

  GDMHead.SongTitle = RTRIM$(LEFT$(GDMText$, 32)) + STRING$(32, 0)
  GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
END IF

GET #1, SongOffset& + 1 + 787, Byte$: GDMHead.NOS = CHR$(ASC(Byte$) - 1)

SEEK 1, SongOffset& + 1 + 504
GET #1, , Temp: GDMHead.NOP = CHR$(AmigaWord(Temp) - 1)
GET #1, , Temp: GDMHead.NOO = CHR$(AmigaWord(Temp) - 1)

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Message Text Conversion
GDMHead.MTLength = LEN(GDMText$): GDMHead.MTOffset = SEEK(2) - 1
PUT #2, , GDMText$: GDMText$ = ""

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
DIM SamLoc(62) AS LONG
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  IF INKEY$ = CHR$(27) THEN AbortProg
  LOCATE , 1
  HT = 4                                     'Default Volume

  GET #1, SongOffset& + 1 + Sample * 8, Temp 'Loop Begin
  SamHead(Sample).LoopBegin = AmigaWord(Temp) * 2

  GET #1, , Temp                             'Loop End
  SamHead(Sample).LoopEnd = SamHead(Sample).LoopBegin + (AmigaWord(Temp) * 2) + 1
  IF SamHead(Sample).LoopEnd - SamHead(Sample).LoopBegin > 8 THEN HT = HT + 1

  GET #1, SEEK(1) + 2, SamHead(Sample).Volume
  SamHead(Sample).Flags = CHR$(HT)

  IF SamOff& THEN
    Temp$ = SPACE$(32): GET #1, SamOff& + 1 + Sample * SamSize, Temp$
    Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = 32
    IF Zero > 32 THEN Zero = 32
    IF Zero THEN SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
    SamHead(Sample).FileName = LEFT$(SamHead(Sample).SamName, 12)
  ELSE
    SamHead(Sample).SamName = STRING$(32, 0)
  END IF

  IF SamExt& > 0 THEN
    GET #1, SamExt& + 1 + Sample * SESize + 3, Byte$
    SELECT CASE ASC(Byte$)
    CASE 0: SamHead(Sample).C4Hertz = 8363
    CASE 1: SamHead(Sample).C4Hertz = 8424
    CASE 2: SamHead(Sample).C4Hertz = 8485
    CASE 3: SamHead(Sample).C4Hertz = 8547
    CASE 4: SamHead(Sample).C4Hertz = 8608
    CASE 5: SamHead(Sample).C4Hertz = 8671
    CASE 6: SamHead(Sample).C4Hertz = 8734
    CASE 7: SamHead(Sample).C4Hertz = 8797
    CASE 8: SamHead(Sample).C4Hertz = 7894
    CASE 9: SamHead(Sample).C4Hertz = 7951
    CASE 10: SamHead(Sample).C4Hertz = 8009
    CASE 11: SamHead(Sample).C4Hertz = 8067
    CASE 12: SamHead(Sample).C4Hertz = 8125
    CASE 13: SamHead(Sample).C4Hertz = 8184
    CASE 14: SamHead(Sample).C4Hertz = 8244
    CASE 15: SamHead(Sample).C4Hertz = 8303
    END SELECT
  ELSE
    SamHead(Sample).C4Hertz = 8363
  END IF
  SamHead(Sample).Pan = CHR$(&HFF)

  GET #1, SamHeadOff& + 1 + Sample * 4, SamLoc(Sample)
  SamLoc(Sample) = AmigaLong(SamLoc(Sample))

  IF SamLoc(Sample) > 0 THEN
    GET #1, SamLoc(Sample) + 1, SL&: SamHead(Sample).Length = AmigaLong(SL&)
    GET #1, , SamType
    IF SamType <> 0 THEN PRINT "Warning: Non-digital Sample!"
    SamLoc(Sample) = SEEK(1)
  ELSE
    SamLoc(Sample) = SEEK(1)
  END IF
NEXT

FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
IF J < 0 THEN J = ASC(GDMHead.NOS)
GDMHead.SamHeadOffset = SEEK(2) - 1
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
OrderList$ = SPACE$(256)
GDMHead.OrdOffset = SEEK(2) - 1
GET #1, SongOffset& + 1 + 508, OrderList$
OrderList$ = LEFT$(OrderList$, ASC(GDMHead.NOO) + 1)
PUT #2, , OrderList$
GET #1, , DefaultBPM: DefaultBPM = AmigaWord(DefaultBPM)
GET #1, , Byte$ 'Play transpose
GET #1, , Byte$ '############### Add OctaMED Channel Spitting Here
GET #1, , Byte$: Flags2 = ASC(Byte$)
GET #1, , Byte$: GDMHead.Tempo = Byte$
GET #1, SEEK(1) + 16, Byte$: GDMHead.MastVol = Byte$

IF Flags2 AND &H20 THEN
  GDMHead.BPM = CHR$(DefaultBPM)
ELSE
  SELECT CASE DefaultBPM
  CASE 0 TO 10: GDMHead.Tempo = CHR$(DefaultBPM)
  CASE 11 TO 67: GDMHead.BPM = CHR$(DefaultBPM * 3.78787878787878#)
  CASE 68 TO &HFFFF
    PRINT "Warning: BPM is too big ="; DefaultBPM * 3.78787878787878#
    GDMHead.BPM = CHR$(&HFF)
  END SELECT
END IF

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
SEEK #1, PatPoint& + 1
DIM PatLoc(ASC(GDMHead.NOP)) AS LONG
FOR J = 0 TO ASC(GDMHead.NOP)
  GET #1, , PatLoc(J): PatLoc(J) = AmigaLong(PatLoc(J))
NEXT

GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
PRINT
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  IF MEDType >= 1 THEN
    GET #1, PatLoc(Pattern) + 1, Temp: NC = AmigaWord(Temp) - 1
    GET #1, , MusicRows: MusicRows = AmigaWord(MusicRows)
    Temp$ = SPACE$(4): GET #1, , Temp$
    Music$ = SPACE$(4 * (NC + 1) * (MusicRows + 1))
  ELSE
    GET #1, PatLoc(Pattern) + 1, Byte$: NC = ASC(Byte$) - 1
    GET #1, , Byte$: MusicRows = ASC(Byte$)
    Music$ = SPACE$(3 * (NC + 1) * (MusicRows + 1))
  END IF
  GET #1, , Music$

  Pat$ = ""
  J& = 0
  FOR Row = 0 TO MusicRows
    FOR Channel = 0 TO NC
      FX1 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + J&)          'xx Ins, xxxxxx Note
      IF MEDType >= 1 THEN Byte1 = Byte1 AND &H7F
      Byte2 = PEEK(SADD(Music$) + J& + 1)      'MSN(Ins), LSN(EFX)
      IF MEDType >= 1 THEN Byte2 = Byte2 AND &H3F
      Byte3 = PEEK(SADD(Music$) + J& + 2)      'Effx Data
      IF MEDType >= 1 THEN Byte4 = PEEK(SADD(Music$) + J& + 3) 'Effx Data

      GDMNote = 0: GDMIns = 0
      IF MEDType = 0 THEN
         Note = ((Byte1 AND &H3F) - 1) MOD 12
        Oct = (((Byte1 AND &H3F) - 1) \ 12) + 3
        GDMIns = Byte2 \ 16' + ((Byte1 \ 64) * 16)
      ELSE
        Note = (Byte1 - 1) MOD 12
        Oct = (Byte1 - 1) \ 12 + 3
        GDMIns = Byte2
      END IF
      IF MEDType = 0 AND Byte1 MOD 64 <> 0 THEN
        GDMNote = (Oct * 16 + Note) + 1
      END IF
      IF MEDType >= 1 AND Byte1 <> 0 THEN GDMNote = (Oct * 16 + Note) + 1

      IF MEDType >= 1 THEN
        EFX = Byte3
        Dat = Byte4
      ELSE
        EFX = Byte2 MOD 16
        Dat = Byte3
      END IF
      SELECT CASE EFX
      CASE 0: IF Dat <> 0 THEN FX1 = &H10: FX1Data = Dat 'No Effect/Arpeggio
      CASE 1: FX1 = 1: FX1Data = Dat    '1xx- Porta up, x=speed
      CASE 2: FX1 = 2: FX1Data = Dat    '2xx- Porta down, x=speed
      CASE 3: FX1 = 3: FX1Data = Dat    '3xx- Porta to note, x=speed
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 4: FX1 = 4: FX1Data = Dat    '4xy- Vibrato, x=speed, y=depth
      CASE 9                     '9xx- Set Tempo
        IF Dat > 0 THEN FX1 = &HF: FX1Data = Dat
      CASE &HA, &HD               'Axx- Volume Slide
        FX1 = &HA: FX1Data = Dat
        IF FX1Data = 0 THEN FX1 = 0
      CASE &HB                   'Bxx- Jump to Order, x=order
        FX1 = &HB: FX1Data = Dat
      CASE &HC                   'Cxx- Set Volume, x=volume (0..40)
        IF Dat > 64 THEN Dat = 64
        FX1 = &HC: FX1Data = Dat
      CASE &HF
        SELECT CASE Dat
        CASE &H0: FX1 = &HD: FX1Data = Dat     'Pattern Break
        CASE &H1 TO &HF0                       'Set BPM-like Tempo
          IF Flags2 AND &H20 THEN
            FX1 = &H1F: FX1Data = Dat
          ELSE
            SELECT CASE Dat
            CASE 0 TO 10: FX1 = &HF: FX1Data = Dat
            CASE 11 TO 67: FX1 = &H1F: FX1Data = Dat * 3.78787878787878#
            CASE 68 TO &HFFFF
               PRINT "Warning: BPM is too big ="; Dat * 3.78787878787878#
               FX1 = &H1F: FX1Data = &HFF
            END SELECT
          END IF
        CASE &HFE: FX1 = &HF: FX1Data = 0      'Play Stop
        CASE &HFF: FX1 = &HC: FX1Data = 0      'Note cut
        END SELECT
      END SELECT
      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data)
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      IF MEDType >= 1 THEN J& = J& + 4 ELSE J& = J& + 3
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""

FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO NC STEP 4
PanTable(J) = 0: PanTable(J + 1) = 15
PanTable(J + 2) = 15: PanTable(J + 3) = 0
NEXT

FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
GDMHead.SamOffset = SEEK(2) - 1
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  LOCATE , 1
  PRINT "Converting Sample:"; J;
  IF INKEY$ = CHR$(27) THEN AbortProg
  SL& = SamHead(J).Length
  FF = 0
  SEEK #1, SamLoc(J)
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$: AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    PUT #2, , Buffer$
  LOOP UNTIL FF
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertMOD (NC, NS)
GDMHead.FormOrigin = 1                 'Protracker module

IF NC = 99 THEN
  NC = 7: NS = NS - 1
ELSE
  Temp$ = "1234": GET #1, 1081, Temp$
  SELECT CASE Temp$
  CASE "M.K.", "M!K!", "FLT4": NC = 3: NS = 30
  CASE "4CHN" TO "9CHN": NS = 30: NC = VAL(LEFT$(Temp$, 1)) - 1
  CASE "OCTA": NS = 30: NC = 7
  CASE "10CH" TO "32CH":  NS = 30: NC = VAL(LEFT$(Temp$, 2)) - 1
  CASE ELSE: NC = 3: NS = 14
  END SELECT
END IF
Byte$ = " "
SEEK 2, LEN(GDMHead) + 1
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
Temp$ = SPACE$(20): GET #1, 1, Temp$
Zero = INSTR(Temp$, CHR$(0)): IF Zero THEN Temp$ = LEFT$(Temp$, Zero)
GDMHead.SongTitle = RTRIM$(Temp$) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GDMHead.Tempo = CHR$(6)                'Default Tempo of 6 for MODs
GDMHead.BPM = CHR$(125)                'Default BPM of 125 for MODs
GDMHead.MastVol = CHR$(64)
FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO NC STEP 4
PanTable(J) = 0: PanTable(J + 1) = 15
PanTable(J + 2) = 15: PanTable(J + 3) = 0
NEXT

GDMHead.NOS = CHR$(NS)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
SEEK 1, 21
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4                               'Default Volume enable
  Temp$ = SPACE$(22): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = LEN(Temp$)
  SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
  GET #1, , Byte$: HI& = ASC(Byte$)
  GET #1, , Byte$: LO& = ASC(Byte$)
  SamHead(Sample).Length = (HI& * 256 + LO&) * 2
  GET #1, , Byte$
  SELECT CASE ASC(Byte$) AND &HF
  CASE 0: SamHead(Sample).C4Hertz = 8363
  CASE 1: SamHead(Sample).C4Hertz = 8424
  CASE 2: SamHead(Sample).C4Hertz = 8485
  CASE 3: SamHead(Sample).C4Hertz = 8547
  CASE 4: SamHead(Sample).C4Hertz = 8608
  CASE 5: SamHead(Sample).C4Hertz = 8671
  CASE 6: SamHead(Sample).C4Hertz = 8734
  CASE 7: SamHead(Sample).C4Hertz = 8797
  CASE 8: SamHead(Sample).C4Hertz = 7894
  CASE 9: SamHead(Sample).C4Hertz = 7951
  CASE 10: SamHead(Sample).C4Hertz = 8009
  CASE 11: SamHead(Sample).C4Hertz = 8067
  CASE 12: SamHead(Sample).C4Hertz = 8125
  CASE 13: SamHead(Sample).C4Hertz = 8184
  CASE 14: SamHead(Sample).C4Hertz = 8244
  CASE 15: SamHead(Sample).C4Hertz = 8303
  END SELECT
  GET #1, , SamHead(Sample).Volume
  IF ASC(SamHead(Sample).Volume) > 64 THEN SamHead(Sample).Volume = CHR$(64)
  GET #1, , Byte$: HI& = ASC(Byte$)
  GET #1, , Byte$: LO& = ASC(Byte$)
  SamHead(Sample).LoopBegin = (HI& * 256 + LO&) * 2
  GET #1, , Byte$: HI& = ASC(Byte$)
  GET #1, , Byte$: LO& = ASC(Byte$)
  SamHead(Sample).LoopEnd = SamHead(Sample).LoopBegin + ((HI& * 256 + LO&) * 2) + 1
  SamHead(Sample).Pan = CHR$(&HFF)
  IF SamHead(Sample).LoopEnd - SamHead(Sample).LoopBegin > 8 THEN HT = HT + 1
  IF SamHead(Sample).LoopEnd > SamHead(Sample).Length THEN SamHead(Sample).LoopEnd = SamHead(Sample).Length + 1
  SamHead(Sample).Flags = CHR$(HT)
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

GET #1, , Byte$: GDMHead.NOO = CHR$(ASC(Byte$) - 1)
GET #1, , Byte$
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
NOP = 0
FOR J = 0 TO ASC(GDMHead.NOO)
  GET #1, , Byte$
  IF ASC(Byte$) > NOP THEN NOP = ASC(Byte$)
  PUT #2, , Byte$
NEXT
FOR J = ASC(GDMHead.NOO) TO 126
  GET #1, , Byte$
  IF ASC(Byte$) > NOP THEN NOP = ASC(Byte$)
NEXT
GDMHead.NOP = CHR$(NOP)

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
IF NS = 14 THEN SEEK 1, 601 ELSE SEEK 1, 155 + ((NS + 1) * 30)
GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
PRINT
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Music$ = SPACE$(4 * (NC + 1) * 64)
  Pat$ = ""
  GET #1, , Music$
  J& = 0
  FOR Row = 0 TO 63
    FOR Channel = 0 TO NC
      FX1 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + J&)
      Byte2 = PEEK(SADD(Music$) + J& + 1)
      Byte3 = PEEK(SADD(Music$) + J& + 2)
      Byte4 = PEEK(SADD(Music$) + J& + 3)
      GDMNote = 0: GDMIns = 0
      Note = (Byte1 MOD 16) * 256 + Byte2
      Ins = (Byte3 \ 16) + (Byte1 AND &HF0)
      IF Note <> 0 OR Ins <> 0 THEN
        IF Note = 0 THEN
          GDMIns = Ins
        ELSE
          LastFit = 32767
          FOR Ot = 0 TO 4
            FOR Nt = 0 TO 11
              IF ABS(PT(Ot, Nt) - Note) < LastFit THEN
                GDMNote = ((Ot + 2) * 16 + Nt) + 1
                LastFit = ABS(PT(Ot, Nt) - Note)
              END IF
            NEXT
          NEXT
          GDMIns = Ins
        END IF
      END IF
      EFX = Byte3 MOD 16
      Dat = Byte4
      SELECT CASE EFX
      CASE 0: IF Dat <> 0 THEN FX1 = &H10: FX1Data = Dat 'Arpeggio
      CASE 1: FX1 = 1: FX1Data = Dat    '1xx- Porta up, x=speed
      CASE 2: FX1 = 2: FX1Data = Dat    '2xx- Porta down, x=speed
      CASE 3: FX1 = 3: FX1Data = Dat    '3xx- Porta to note, x=speed
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 4: FX1 = 4: FX1Data = Dat    '4xy- Vibrato, x=speed, y=depth
      CASE 5: FX1 = 5: FX1Data = Dat    '5xy- Porta to note+Vol Slide
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        IF FX1Data = 0 THEN FX1 = 3
      CASE 6: FX1 = 6: FX1Data = Dat    '6xy- Vibrato + Vol Slide
        IF FX1Data = 0 THEN FX1 = 4
      CASE 7: FX1 = 7: FX1Data = Dat    '7xy- Tremolo
      CASE 8                            '8xx- Pan
        IF Dat = &HA4 THEN
          FX1 = &H1E: FX1Data = 1       'Surround
        ELSE
        IF Dat < &H80 THEN
          IF Dat < &H80 THEN
            DDat = Dat \ 8: IF DDat > 15 THEN DDat = 15
            FX1 = &H1E: FX1Data = &H80 + DDat
          END IF
        END IF
        END IF
      CASE 9: FX1 = 9: FX1Data = Dat        '9xx- Sample Offset, xx00h=offset
      CASE &HA: FX1 = &HA: FX1Data = Dat    'Axx- Volume Slide
        IF FX1Data = 0 THEN FX1 = 0
      CASE &HB: FX1 = &HB: FX1Data = Dat    'Bxx- Jump to Order, x=order
      CASE &HC                              'Cxx- Set Volume, x=volume (0..40)
        IF Dat > 64 THEN Dat = 64
        FX1 = &HC: FX1Data = Dat
      CASE &HD: FX1 = &HD: FX1Data = Dat    'Dxx- Pattern Break, break to row x
      CASE &HE                   'Exx- Extended effects
        FF = Dat \ 16
        Dat = Dat MOD 16
        SELECT CASE FF
        CASE 0: FX1 = &HE: FX1Data = Dat          'Set filter
        CASE 1: FX1 = &HE: FX1Data = &H10 + Dat   'Fineslide Up
        CASE 2: FX1 = &HE: FX1Data = &H20 + Dat   'Fineslide Down
        CASE 3: FX1 = &HE: FX1Data = &H30 + Dat   'Glissando Control
        CASE 4: FX1 = &HE: FX1Data = &H40 + Dat   'Vibrato Waveform
        CASE 5: FX1 = &HE: FX1Data = &H50 + Dat   'Set C-4 finetune
        CASE 6: FX1 = &HE: FX1Data = &H60 + Dat   'Patttern Loop
        CASE 7: FX1 = &HE: FX1Data = &H70 + Dat   'Tremolo Waveform
        CASE 8: FX1 = &H1E: FX1Data = &H80 + Dat  'Pan Position
        CASE 9: FX1 = &H12: FX1Data = Dat         'Retrigger
          IF FX1Data = 0 THEN FX1 = 0
        CASE &HA: FX1 = &HE: FX1Data = &HA0 + Dat 'Fine Vol up
        CASE &HB: FX1 = &HE: FX1Data = &HB0 + Dat 'Fine Vol down
        CASE &HC: FX1 = &HE: FX1Data = &HC0 + Dat 'Note Cut
        CASE &HD: FX1 = &HE: FX1Data = &HD0 + Dat 'Note Delay
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1 ELSE FX1 = 0
        CASE &HE: FX1 = &HE: FX1Data = &HE0 + Dat 'Pattern Delay
        CASE &HF: FX1 = &HE: FX1Data = &HF0 + Dat 'Invert Loop
        END SELECT
      CASE &HF                   'Fxx- Set Tempo/BPM, x=tempo/BPM
        IF Dat > 31 THEN FX1 = &H1F ELSE FX1 = &HF
        FX1Data = Dat
      END SELECT

      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data)
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      J& = J& + 4
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
GDMHead.SamOffset = SEEK(2) - 1
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)': HW& = HW& + BL
    GET #1, , Buffer$: AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    PUT #2, , Buffer$
  LOOP UNTIL FF
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertMTM
GDMHead.FormOrigin = 2                 'MultiTracker module

SEEK 2, LEN(GDMHead) + 1
Byte$ = " "
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
GET #1, 4, Byte$: IF Byte$ <> CHR$(&H10) THEN PRINT "Wrong format version": END
Temp$ = SPACE$(20): GET #1, 5, Temp$
Zero = INSTR(Temp$, CHR$(0)): IF Zero THEN Temp$ = LEFT$(Temp$, Zero) + STRING$(32, 0)
GDMHead.SongTitle = Temp$
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GDMHead.MastVol = CHR$(64)
GET #1, 25, NumOTracks: NumOTracks& = NumOTracks
GET #1, 27, GDMHead.NOP
GET #1, 28, GDMHead.NOO
GET #1, 31, Byte$: NOS = ASC(Byte$) - 1: GDMHead.NOS = CHR$(NOS)
GET #1, 29, MTLen: GDMHead.MTLength = MTLen
GET #1, 34, Byte$: NOC = ASC(Byte$)
FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO NOC - 1
GET #1, , Byte$: PanTable(J) = ASC(Byte$)
NEXT
GDMHead.BPM = CHR$(125): GDMHead.Tempo = CHR$(6)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
SEEK 1, 67
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4

  Temp$ = SPACE$(22): GET #1, , Temp$:
  Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = LEN(Temp$)
  SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
  SamHead(Sample).FileName = RTRIM$(LEFT$(Temp$, 13)) + STRING$(13, 0)
  GET #1, , SamHead(Sample).Length
  GET #1, , SamHead(Sample).LoopBegin
  GET #1, , SamHead(Sample).LoopEnd
  IF SamHead(Sample).LoopEnd - SamHead(Sample).LoopBegin > 8 THEN HT = HT + 1
  GET #1, , Byte$
  SELECT CASE ASC(Byte$)
  CASE 0: SamHead(Sample).C4Hertz = 8363
  CASE 1: SamHead(Sample).C4Hertz = 8424
  CASE 2: SamHead(Sample).C4Hertz = 8485
  CASE 3: SamHead(Sample).C4Hertz = 8547
  CASE 4: SamHead(Sample).C4Hertz = 8608
  CASE 5: SamHead(Sample).C4Hertz = 8671
  CASE 6: SamHead(Sample).C4Hertz = 8734
  CASE 7: SamHead(Sample).C4Hertz = 8797
  CASE 8: SamHead(Sample).C4Hertz = 7894
  CASE 9: SamHead(Sample).C4Hertz = 7951
  CASE 10: SamHead(Sample).C4Hertz = 8009
  CASE 11: SamHead(Sample).C4Hertz = 8067
  CASE 12: SamHead(Sample).C4Hertz = 8125
  CASE 13: SamHead(Sample).C4Hertz = 8184
  CASE 14: SamHead(Sample).C4Hertz = 8244
  CASE 15: SamHead(Sample).C4Hertz = 8303
  END SELECT
  GET #1, , SamHead(Sample).Volume
  SamHead(Sample).Pan = CHR$(&HFF)
  GET #1, , Byte$: AT = ASC(Byte$)
  IF AT AND 1 THEN HT = HT + 2         '16/8Bit samples
  SamHead(Sample).Flags = CHR$(HT)
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
SEEK 1, 67 + (NOS + 1) * 37
FOR J = 0 TO ASC(GDMHead.NOO)
  GET #1, , Byte$
  PUT #2, , Byte$
NEXT
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
Lik& = 195 + (NOS + 1) * 37
SEEK 1, Lik& + NumOTracks& * 192
DIM TrakSeq(ASC(GDMHead.NOP), 31)  AS LONG
FOR J = 0 TO ASC(GDMHead.NOP)
  FOR Chan = 0 TO 31
    GET #1, , TS
    TrakSeq(J, Chan) = TS
  NEXT
NEXT
PRINT
MaxChannels = 0
GDMHead.PatOffset = SEEK(2) - 1
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  Trak$ = SPACE$(192)
  Music$ = ""
  FOR J = 0 TO NOC - 1
    Trk& = (TrakSeq(Pattern, J) - 1) * 192
    IF TrakSeq(Pattern, J) = 0 THEN
      Trak$ = STRING$(192, 0)
    ELSE
      SEEK 1, Trk& + Lik&
      GET #1, , Trak$
    END IF
    Music$ = Music$ + Trak$
  NEXT

  J& = 0
  FOR Row = 0 TO 63
    FOR Channel = 0 TO NOC - 1
      FX1 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + (Channel * 192) + (Row * 3))
      Byte2 = PEEK(SADD(Music$) + (Channel * 192) + (Row * 3) + 1)
      Byte3 = PEEK(SADD(Music$) + (Channel * 192) + (Row * 3) + 2)
      GDMNote = 0: GDMIns = 0
      Note = ((Byte1 \ 48 + 2) * 16) + ((Byte1 \ 4) MOD 12)
      Ins = Byte2 \ 16 + ((Byte1 MOD 4) * 16)
      IF Byte1 \ 4 <> 0 THEN GDMNote = Note + 1
      IF Ins <> 0 THEN GDMIns = Ins
      EFX = Byte2 MOD 16
      Dat = Byte3
      SELECT CASE EFX
      CASE 0: IF Dat <> 0 THEN FX1 = &H10: FX1Data = Dat 'Arpeggio
      CASE 1: FX1 = 1: FX1Data = Dat    '1xx- Porta up, x=speed
      CASE 2: FX1 = 2: FX1Data = Dat    '2xx- Porta down, x=speed
      CASE 3: FX1 = 3: FX1Data = Dat    '3xx- Porta to note, x=speed
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 4: FX1 = 4: FX1Data = Dat    '4xy- Vibrato, x=speed, y=depth
      CASE 5: FX1 = 5: FX1Data = Dat    '5xy- Porta to note+Vol Slide
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        IF FX1Data = 0 THEN FX1 = 3
      CASE 6: FX1 = 6: FX1Data = Dat    '6xy- Vibrato + Vol Slide
        IF FX1Data = 0 THEN FX1 = 4
      CASE 7: FX1 = 7: FX1Data = Dat    '7xy- Tremolo
      CASE 8                            '8xx- Pan
        IF Dat = &HA4 THEN
          FX1 = &H1E: FX1Data = 1       'Surround
        ELSE
          IF Dat < &H80 THEN
            DDat = Dat \ 8: IF DDat > 15 THEN DDat = 15
            FX1 = &H1E: FX1Data = &H80 + DDat
          END IF
        END IF
      CASE 9: FX1 = 9: FX1Data = Dat        '9xx- Sample Offset, xx00h=offset
      CASE &HA: FX1 = &HA: FX1Data = Dat    'Axx- Volume Slide
        IF FX1Data = 0 THEN FX1 = 0
      CASE &HB: FX1 = &HB: FX1Data = Dat    'Bxx- Jump to Order, x=order
      CASE &HC                              'Cxx- Set Volume, x=volume (0..40)
        IF Dat > 64 THEN Dat = 64
        FX1 = &HC: FX1Data = Dat
      CASE &HD: FX1 = &HD: FX1Data = Dat    'Dxx- Pattern Break, break to row x
      CASE &HE                   'Exx- Extended effects
        FF = Dat \ 16
        Dat = Dat MOD 16
        SELECT CASE FF
        CASE 0: FX1 = &HE: FX1Data = Dat          'Set filter
        CASE 1: FX1 = &HE: FX1Data = &H10 + Dat   'Fineslide Up
        CASE 2: FX1 = &HE: FX1Data = &H20 + Dat   'Fineslide Down
        CASE 3: FX1 = &HE: FX1Data = &H30 + Dat   'Glissando Control
        CASE 4: FX1 = &HE: FX1Data = &H40 + Dat   'Vibrato Waveform
        CASE 5: FX1 = &HE: FX1Data = &H50 + Dat   'Set C-4 finetune
        CASE 6: FX1 = &H4: FX1Data = &H60 + Dat   'Patttern Loop
        CASE 7: FX1 = &HE: FX1Data = &H70 + Dat   'Tremolo Waveform
        CASE 8: FX1 = &H1E: FX1Data = &H80 + Dat   'Pan Position
        CASE 9: FX1 = &H12: FX1Data = Dat          'Retrigger
          IF FX1Data = 0 THEN FX1 = 0
        CASE &HA: FX1 = &HE: FX1Data = &HA0 + Dat 'Fine Vol up
        CASE &HB: FX1 = &HE: FX1Data = &HB0 + Dat 'Fine Vol down
        CASE &HC: FX1 = &HE: FX1Data = &HC0 + Dat 'Note Cut
        CASE &HD: FX1 = &HE: FX1Data = &HD0 + Dat 'Note Delay
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1 ELSE FX1 = 0
        CASE &HE: FX1 = &HE: FX1Data = &HE0 + Dat 'Pattern Delay
        CASE &HF: FX1 = &HE: FX1Data = &HF0 + Dat 'Invert Loop
        END SELECT
      CASE &HF                   'Fxx- Set Tempo/BPM, x=tempo/BPM
        IF Dat > 31 THEN FX1 = &H1F ELSE FX1 = &HF
        FX1Data = Dat
      END SELECT

      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data)
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      J& = J& + 3
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Write Message Text
SEEK 1, Lik& + NumOTracks& * 192 + ((ASC(GDMHead.NOP) + 1) * 64)
GDMText$ = SPACE$(GDMHead.MTLength)
GET 1, , GDMText$
GDMHead.MTOffset = SEEK(2) - 1
PUT 2, , GDMText$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Copy
GDMHead.SamOffset = SEEK(2) - 1
Music$ = ""
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  PRINT "Copying Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$
    PUT #2, , Buffer$
  LOOP UNTIL FF
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertS3M
DIM OldPorta(16)  AS INTEGER
GDMHead.FormOrigin = 3                 'Scream Tracker 3

SEEK 2, LEN(GDMHead) + 1
Byte$ = " "
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
GET #1, &H1E, Byte$: IF Byte$ <> CHR$(16) THEN PRINT "Not a ST3 module": END
Temp$ = SPACE$(28)
GET #1, 1, Temp$: Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = 28
GDMHead.SongTitle = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
GET #1, &H29, CWTV
GET #1, &H2B, FFV: IF FFV > 2 THEN PRINT "Incorrect format version": END
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GET #1, &H31, GDMHead.MastVol
GET #1, &H34, Byte$: Stereo = ASC(Byte$) \ 128
GET #1, &H27, Flags

GET #1, &H32, GDMHead.Tempo
GET #1, &H33, GDMHead.BPM
GET #1, &H21, GDMHead.NOO: GDMHead.NOO = CHR$(ASC(GDMHead.NOO) - 1)
GET #1, &H23, GDMHead.NOS: GDMHead.NOS = CHR$(ASC(GDMHead.NOS) - 1)
GET #1, &H25, GDMHead.NOP: GDMHead.NOP = CHR$(ASC(GDMHead.NOP) - 1)

Temp$ = SPACE$(32): GET #1, &H41, Temp$
FOR J = 0 TO 31
Byte = ASC(MID$(Temp$, J + 1, 1))
PanTable(J) = &HFF
IF Stereo THEN Lft = 0: Rgt = 15 ELSE Lft = 8: Rgt = 8
SELECT CASE Byte
CASE 0 TO 7: PanTable(J) = Lft: NC = NC + 1
CASE 8 TO 15: PanTable(J) = Rgt: NC = NC + 1
CASE 16 TO 31   'AdLib Channels
END SELECT
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
SEEK 1, &H61
FOR J = 0 TO ASC(GDMHead.NOO)
  GET #1, , Byte$
  IF ASC(Byte$) <> 254 AND ASC(Byte$) <> 255 THEN
    IF ASC(Byte$) > ASC(GDMHead.NOP) THEN
      ZeroPattern = -1
      Byte$ = CHR$(ASC(GDMHead.NOP) + 1)
    END IF
    PUT #2, , Byte$
  ELSE
    GDMHead.NOO = CHR$(ASC(GDMHead.NOO) - 1)
  END IF
NEXT
DIM SampleLoc(255) AS LONG
FOR J = 0 TO ASC(GDMHead.NOS)          'Load Sample Location Table
  GET #1, , Byte$: SampleLoc(J) = ASC(Byte$)
  GET #1, , Byte$: Temp& = ASC(Byte$): SampleLoc(J) = SampleLoc(J) + Temp& * 256
  SampleLoc(J) = SampleLoc(J) * 16 + 1
NEXT
DIM PatternLoc(255) AS LONG
FOR J = 0 TO ASC(GDMHead.NOP)          'Load Pattern Location Table
  GET #1, , Byte$: PatternLoc(J) = ASC(Byte$)
  GET #1, , Byte$: Temp& = ASC(Byte$): PatternLoc(J) = PatternLoc(J) + Temp& * 256
  PatternLoc(J) = PatternLoc(J) * 16 + 1
NEXT
IF CWTV >= &H1320 THEN
  FOR J = 0 TO NC - 1
    GET 1, , Byte$: Temp = ASC(Byte$)
    IF Temp AND 32 THEN PanTable(J) = Temp AND &HF
  NEXT
END IF

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4                               'Has default volume
  SEEK 1, SampleLoc(Sample)
  GET #1, , Byte$: SamType = ASC(Byte$)
  Temp$ = SPACE$(12): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)) - 1: IF Zero <= 0 THEN Zero = 12
  SamHead(Sample).FileName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(12, 0)
  GET #1, , Byte$
  GET #1, , Byte$: SampleLoc(Sample) = ASC(Byte$)
  GET #1, , Byte$: Temp& = ASC(Byte$): SampleLoc(Sample) = SampleLoc(Sample) + Temp& * 256
  SampleLoc(Sample) = SampleLoc(Sample) * 16
  GET #1, , SamHead(Sample).Length
  GET #1, , SamHead(Sample).LoopBegin
  GET #1, , SamHead(Sample).LoopEnd
  SamHead(Sample).LoopEnd = SamHead(Sample).LoopEnd + 1
  GET #1, , SamHead(Sample).Volume
  IF ASC(SamHead(Sample).Volume) > 64 THEN SamHead(Sample).Volume = CHR$(64)
  GET #1, , Byte$
  GET #1, , Byte$
  IF ASC(Byte$) THEN PRINT "Warning: GDM format does not support packed instruments"
  GET #1, , Byte$: SamFlag = ASC(Byte$)
  IF SamFlag AND 1 THEN HT = HT + 1    'Looped sample
  IF SamFlag AND 2 THEN HT = HT + 32   'Stereo sample
  IF SamFlag AND 4 THEN HT = HT + 2    '16 Bit sample
  GET #1, , SamHead(Sample).C4Hertz
  Temp$ = SPACE$(14): GET #1, , Temp$  'Filler
  Temp$ = SPACE$(28): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = 28
  SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
  SamHead(Sample).Flags = CHR$(HT)
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
PRINT
GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  SEEK 1, PatternLoc(Pattern)
  GET #1, , PatLen: PatLen = PatLen - 2
  IF PatLen = -2 THEN GOTO DonePattern
   
  Music$ = SPACE$(PatLen): GET #1, , Music$
  J& = 0
  Channel = 0
  ChanType = 0
  GDMNote = 0: GDMIns = 0
  Row = 0
  DO
    FX1 = 0: FX2 = 0
    DEF SEG = SSEG(Music$)
    ChanType = PEEK(SADD(Music$) + J&): J& = J& + 1
    IF ChanType = 0 THEN
      Pat$ = Pat$ + CHR$(0)
      Row = Row + 1
      IF BrkFlg THEN Row = 64
      GOTO ChanDone
    END IF
    Channel = ChanType MOD 32
    IF Channel > NC THEN
      IF ChanType AND 32 THEN J& = J& + 2
      IF ChanType AND 64 THEN J& = J& + 1
      IF ChanType AND 128 THEN J& = J& + 2
      ChanType = 0
    END IF
    GDMNote = 0: GDMIns = 0
    IF ChanType AND 32 THEN             'Note Event
      GDMNote = PEEK(SADD(Music$) + J&) + 1: J& = J& + 1
      IF GDMNote = 256 THEN GDMNote = 0
      IF GDMNote = 255 THEN GDMNote = 0: FX1 = &HC: FX1Data = 0
      GDMIns = PEEK(SADD(Music$) + J&): J& = J& + 1
    END IF
    IF ChanType AND 64 THEN            'Volume Event
      FX1 = &HC: FX1Data = PEEK(SADD(Music$) + J&): J& = J& + 1
      IF FX1Data > 64 THEN FX1Data = 64
    END IF
    IF ChanType AND 128 THEN           'Effect Event
      EFX = PEEK(SADD(Music$) + J&): J& = J& + 1
      Dat = PEEK(SADD(Music$) + J&): J& = J& + 1
      SELECT CASE EFX
      CASE 1: FX2 = &HF: FX2Data = Dat    'Axx- Set Tempo, x=tempo
        IF Dat = 0 THEN FX2 = 0
      CASE 2: FX2 = &HB: FX2Data = Dat    'Bxx- Jump to Order, x=order
        BrkFlg = -1
      CASE 3: FX2 = &HD: FX2Data = Dat    'Cxx- Pattern Break, x=row
        BrkFlg = -1
      CASE 4                              'Dxy- Volume Slide
        HiNib = Dat \ 16: LoNib = Dat MOD 16
        IF HiNib = 0 OR LoNib = 0 THEN            'Volume Slide
          FX2 = &HA: FX2Data = Dat
        ELSE
          IF HiNib = &HF THEN FX2 = &HE: FX2Data = &HB0 + LoNib 'FDown
          IF LoNib = &HF THEN FX2 = &HE: FX2Data = &HA0 + HiNib 'FUp
          IF HiNib <> &HF AND LoNib <> &HF THEN FX2 = &HA: FX2Data = LoNib
        END IF
      CASE 5                            'Exx- Porta Downs
        IF Dat = 0 THEN Dat = OldPorta(Channel)
        OldPorta(Channel) = Dat
        IF Dat \ 16 = &HF THEN FX2 = &HE: FX2Data = &H20 + Dat MOD 16'Fine
        IF Dat \ 16 = &HE THEN FX2 = &HE: FX2Data = &H90 + Dat MOD 16'Xtra
        IF Dat \ 16 < &HE THEN FX2 = 2: FX2Data = Dat
      CASE 6                            'Fxx- Porta Ups
        IF Dat = 0 THEN Dat = OldPorta(Channel)
        OldPorta(Channel) = Dat
        IF Dat \ 16 = &HF THEN FX2 = &HE: FX2Data = &H10 + Dat MOD 16'Fine
        IF Dat \ 16 = &HE THEN FX2 = &HE: FX2Data = &H80 + Dat MOD 16'Xtra
        IF Dat \ 16 < &HE THEN FX2 = 1: FX2Data = Dat
      CASE 7: FX2 = 3: FX2Data = Dat    'Gxx- Porta to Note
        IF Dat <> 0 THEN OldPorta(Channel) = Dat
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 8: FX2 = 4: FX2Data = Dat    'Hxx- Vibrato
      CASE 9: FX2 = 8: FX2Data = Dat    'Ixx- Tremor
      CASE 10: FX2 = &H10: FX2Data = Dat'Jxx- Arpeggio
      CASE 11                           'Kxy- Vibrato+Volume Slide
        FX2 = 6: FX2Data = Dat
      CASE 12                           'Lxy- Porta Note+Vol slide
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        FX2 = 5: FX2Data = Dat
      CASE 15: FX2 = 9: FX2Data = Dat   'Oxx- Set Sample Offset
      CASE 17: FX2 = &H12: FX2Data = Dat'Qxx- Retrigger+Vol Slide
      CASE 18: FX2 = 7: FX2Data = Dat   'Rxx- Tremolo
      CASE 19                           'Sxx- Special Commands
        FF = Dat \ 16
        Dat = Dat MOD 16
        SELECT CASE FF
        CASE 0: FX2 = &HE: FX2Data = Dat          'Set filter
        CASE 1: FX2 = &HE: FX2Data = &H30 + Dat   'Glissando Control
        CASE 2: FX2 = &HE: FX2Data = &H50 + Dat   'Set C-4 finetune
        CASE 3: FX2 = &HE: FX2Data = &H40 + Dat   'Vibrato Waveform
        CASE 4: FX2 = &HE: FX2Data = &H70 + Dat   'Tremolo Waveform
        CASE 8: FX2 = &H1E: FX2Data = &H80 + Dat  'Pan Position
        CASE &HB: FX2 = &HE: FX2Data = &H60 + Dat 'Patttern Loop
        CASE &HC: FX2 = &HE: FX2Data = &HC0 + Dat 'Note Cut
        CASE &HD: FX2 = &HE: FX2Data = &HD0 + Dat 'Note Delay
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1 ELSE FX2 = 0
        CASE &HE: FX2 = &HE: FX2Data = &HE0 + Dat 'Pattern Delay
        CASE &HF: FX2 = &HE: FX2Data = &HF0 + Dat 'Invert Loop
        END SELECT
      CASE &H14: FX2 = &H1F: FX2Data = Dat 'Txx- Set BPM, x=BPM
        IF FX2Data < 32 THEN FX2 = 0
      CASE &H15: FX2 = &H14: FX2Data = Dat 'Uxy- Fine Vibrato
      CASE &H16: FX2 = &H13: FX2Data = Dat 'Set Global Volume
      CASE &H18                            'Xxx- Panning
        IF Dat = &HA4 THEN
          FX2 = &H1E: FX2Data = 1       'Surround
        ELSE
          IF Dat < &H80 THEN
            DDat = Dat \ 8: IF DDat > 15 THEN DDat = 15
            FX2 = &H1E: FX2Data = &H80 + DDat
          END IF
        END IF
      END SELECT
    END IF
    IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
      Chan = Channel
      IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
      Events$ = ""
      IF GDMNote <> 0 OR GDMIns <> 0 THEN
        Chan = Chan + 32
        Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
      END IF
      IF FX1 <> 0 AND FX2 <> 0 THEN
        Chan = Chan + 64
        Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
        Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
      ELSE
        IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
        IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
      END IF
      Pat$ = Pat$ + CHR$(Chan) + Events$
    END IF
ChanDone:
  OldBrkFlg = BrkFlg
  BrkFlg = 0
  LOOP UNTIL J& >= PatLen OR Row = 64
DonePattern:
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
IF ZeroPattern THEN
  PRINT "Converting Pattern:"; Pattern + 1;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  GDMHead.NOP = CHR$(ASC(GDMHead.NOP) + 1)
  Temp$ = CHR$(64) + CHR$(0) + STRING$(64, 0)
  PUT 2, , Temp$
END IF

FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
GDMHead.SamOffset = SEEK(2) - 1
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  IF FFV = 2 THEN PRINT "Copying Sample:"; J;  ELSE PRINT "Converting Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  IF SampleLoc(J) = 0 THEN GOTO NoSample
  SEEK 1, SampleLoc(J)
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$
    IF FFV = 1 THEN
      AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    END IF
    PUT #2, , Buffer$
  LOOP UNTIL FF
NoSample:
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertSTM
GDMHead.FormOrigin = 7                      'Enable Amiga Porta Limits

Byte$ = " "
SEEK 2, LEN(GDMHead) + 1
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
Temp$ = SPACE$(20): GET #1, 1, Temp$
Zero = INSTR(Temp$, CHR$(0)): IF Zero THEN Temp$ = LEFT$(Temp$, Zero)
GDMHead.SongTitle = RTRIM$(Temp$) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
Temp$ = SPACE$(9): GET #1, , Temp$     '"!Scream!"
GET #1, , Byte$: IF Byte$ <> CHR$(2) THEN PRINT "Error: Not a module!": END
GET #1, , Temp                         'Tracker version
GET #1, , GDMHead.Tempo: GDMHead.Tempo = CHR$(ASC(GDMHead.Tempo) \ 16)
GDMHead.BPM = CHR$(125)                'Default BPM of 125 for STMs
GET #1, , GDMHead.NOP: GDMHead.NOP = CHR$(ASC(GDMHead.NOP) - 1)
GET #1, , GDMHead.MastVol
FOR J = 0 TO 31: PanTable(J) = &HFF: NEXT
PanTable(0) = 0: PanTable(1) = 15
PanTable(2) = 15: PanTable(3) = 0

GDMHead.NOS = CHR$(30)
Temp$ = SPACE$(13): GET #1, , Temp$
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4                                'Sample has default volume
  Temp$ = SPACE$(12): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = LEN(Temp$)
  SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
  Temp$ = SPACE$(4): GET #1, , Temp$

  GET #1, , Byte$: LO& = ASC(Byte$): GET #1, , Byte$: HI& = ASC(Byte$)
  SamHead(Sample).Length = HI& * 256 + LO&
  GET #1, , Byte$: LO& = ASC(Byte$): GET #1, , Byte$: HI& = ASC(Byte$)
  SamHead(Sample).LoopBegin = HI& * 256 + LO&

  GET #1, , Byte$: LO& = ASC(Byte$): GET #1, , Byte$: HI& = ASC(Byte$)
  SamHead(Sample).LoopEnd = HI& * 256 + LO&

  GET #1, , SamHead(Sample).Volume: GET #1, , Byte$

  GET #1, , Byte$: LO& = ASC(Byte$): GET #1, , Byte$: HI& = ASC(Byte$)
  SamHead(Sample).C4Hertz = HI& * 256 + LO&
  SamHead(Sample).Pan = CHR$(17)
  IF SamHead(Sample).LoopEnd > SamHead(Sample).Length THEN SamHead(Sample).LoopEnd = 0
  IF SamHead(Sample).LoopEnd - SamHead(Sample).LoopBegin > 8 THEN HT = HT + 1
  Temp$ = SPACE$(6): GET #1, , Temp$
  SamHead(Sample).Flags = CHR$(HT)
NEXT

FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
OrderList$ = SPACE$(128): GET #1, , OrderList$
FOR J = 0 TO 127
  Byte$ = MID$(OrderList$, J + 1, 1)
  IF Byte$ = CHR$(99) THEN EXIT FOR
  PUT #2, , Byte$
NEXT
GDMHead.NOO = CHR$(J - 1)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
PRINT
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  Music$ = ""
  FOR Row = 0 TO 63
    FOR Channel = 0 TO 3
      GET #1, , Byte$
      SELECT CASE ASC(Byte$)
      CASE 251: Music$ = Music$ + STRING$(4, 0): PRINT "ASD1"
      CASE 252: Music$ = Music$ + STRING$(4, 0): PRINT "ASD2"
      CASE 253: Music$ = Music$ + CHR$(&HFF) + STRING$(3, 0)
      CASE ELSE
        Temp$ = SPACE$(3): GET #1, , Temp$
        Music$ = Music$ + Byte$ + Temp$
      END SELECT
    NEXT
  NEXT

  J& = 0
  FOR Row = 0 TO 63
    FOR Channel = 0 TO 3
      FX1 = 0: FX2 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + J&)
      Byte2 = PEEK(SADD(Music$) + J& + 1)
      Byte3 = PEEK(SADD(Music$) + J& + 2)
      Byte4 = PEEK(SADD(Music$) + J& + 3)
      GDMNote = 0: GDMIns = 0
      Ins = Byte2 \ 8
      IF Byte1 < &HFE THEN
        Note = Byte1 MOD 16
        Oct = (Byte1 \ 16) + 2
        GDMNote = (Oct * 16 + Note) + 1
        GDMIns = Ins
      END IF
      IF Byte1 < &HFF THEN
        FX2 = &HC: FX2Data = (Byte2 MOD 8) + ((Byte3 \ 16) * 8) - 1
        IF FX2Data = -1 THEN FX2 = 0
      END IF
      EFX = Byte3 MOD 16: Dat = Byte4
      SELECT CASE EFX
      CASE 1: FX1 = &HF: FX1Data = Dat \ &H10'Axx- Set Tempo, x=tempo
        IF Dat = 0 THEN FX1 = 0
      CASE 2: FX1 = &HB: FX1Data = Dat    'Bxx- Jump to Order, x=order
      CASE 3: FX1 = &HD: FX1Data = Dat    'Cxx- Pattern Break, x=row
      CASE 4: FX1 = &HA: FX1Data = Dat    'Dxy- Volume Slide
        IF FX1Data = 0 THEN FX1 = 0
      CASE 5: FX1 = 2: FX1Data = Dat      'Exx- Porta Down
      CASE 6: FX1 = 1: FX1Data = Dat      'Fxx- Porta Up
      CASE 7: FX1 = 3: FX1Data = Dat      'Gxx- Porta to Note
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 8: FX1 = 4: FX1Data = Dat      'Hxx- Vibrato
      CASE 9: FX1 = 8: FX1Data = Dat      'Ixx- Tremor
      CASE 10: FX1 = &H10: FX1Data = Dat  'Jxx- Arpeggio
      CASE 11: FX1 = 6: FX1Data = Dat     'Kxy- Vibrato+Volume Slide
        IF FX1Data = 0 THEN FX1 = 4
      CASE 12: FX1 = 5: FX1Data = Dat     'Lxy- Porta Note+Vol slide
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        IF FX1Data = 0 THEN FX1 = 3
      END SELECT

      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 AND FX2 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
          Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
        ELSE
          IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
          IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
      J& = J& + 4
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
PRINT
GDMHead.SamOffset = SEEK(2) - 1
FOR J = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$
    DEF SEG = SSEG(Buffer$): AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    PUT #2, , Buffer$
  LOOP UNTIL FF
  Temp$ = SPACE$(15 - (SamHead(J).Length MOD 16))
  GET #1, , Temp$
NEXT
PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertULT (Kin)
DIM OldPorta(31)
GDMHead.FormOrigin = 6                 'UltraTracker module

SEEK 2, LEN(GDMHead) + 1
Byte$ = " "
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
Temp$ = SPACE$(15)
GET #1, 1, Temp$:
SELECT CASE Temp$
CASE "MAS_UTrack_V001"
CASE "MAS_UTrack_V002"
CASE "MAS_UTrack_V003"
CASE "MAS_UTrack_V004"
CASE ELSE: PRINT "Error: Invalid ID": END
END SELECT
Temp$ = SPACE$(32): GET #1, 16, Temp$
Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = LEN(Temp$)
GDMHead.SongTitle = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GDMHead.MastVol = CHR$(64)
GET #1, , Byte$: RES = ASC(Byte$) * 32

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Convert Message Text
IF Kin > 1 THEN
  GDMText$ = SPACE$(RES)
  GET #1, , GDMText$
  GDMHead.MTLength = LEN(GDMText$)
  GDMHead.MTOffset = SEEK(2) - 1
  PUT #2, , GDMText$
END IF

GET #1, 49 + RES, GDMHead.NOS: GDMHead.NOS = CHR$(ASC(GDMHead.NOS) - 1)
GDMHead.BPM = CHR$(125): GDMHead.Tempo = CHR$(6)

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
SEEK 1, 50 + RES
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4                                'Sample has default volume
  Temp$ = SPACE$(32): GET #1, , Temp$: SamHead(Sample).SamName = Temp$
  Zero = INSTR(SamHead(Sample).SamName, CHR$(0))
  IF Zero THEN SamHead(Sample).SamName = LEFT$(SamHead(Sample).SamName, Zero) + STRING$(32, 0)
  Temp$ = SPACE$(12): GET #1, , Temp$
  SamHead(Sample).FileName = LEFT$(Temp$, 8) + "." + RIGHT$(Temp$, 3)
  GET #1, , SamHead(Sample).LoopBegin
  GET #1, , SamHead(Sample).LoopEnd
  GET #1, , SizeFirst&: GET #1, , SizeLast&
  SamHead(Sample).Length = SizeLast& - SizeFirst&
  GET #1, , Byte$: SamHead(Sample).Volume = CHR$(ASC(Byte$) \ 4)
  GET #1, , Byte$: AT = ASC(Byte$)
  IF AT AND 8 THEN HT = HT + 1         'Loop sample
  IF AT AND 4 THEN HT = HT + 2         '16/8Bit samples
  IF Kin > 3 THEN
    GET #1, , SamHead(Sample).C4Hertz
  ELSE
    SamHead(Sample).C4Hertz = 8363
  END IF
  GET #1, , FineTune
  SamHead(Sample).Flags = CHR$(HT)
NEXT

GDMHead.SamHeadOffset = SEEK(2) - 1
FOR J = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(J)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
OrderList$ = SPACE$(256)
GDMHead.OrdOffset = SEEK(2) - 1
GET #1, , OrderList$
DEF SEG = SSEG(OrderList$)
FOR J = 0 TO 255
  Byte = PEEK(SADD(OrderList$) + J)
  IF Byte = &HFF THEN EXIT FOR
NEXT
GDMHead.NOO = CHR$(J - 1)
OrderList$ = LEFT$(OrderList$, J)
PUT #2, , OrderList$

GET #1, , Byte$: NOC = ASC(Byte$) + 1
GET #1, , Byte$: GDMHead.NOP = Byte$
IF Kin > 2 THEN
  FOR J = 0 TO NOC - 1
    GET #1, , Byte$
    PanTable(J) = ASC(Byte$)
  NEXT
ELSE
  FOR J = 0 TO NOC - 1 STEP 2
    PanTable(J) = 0: PanTable(J + 1) = 15
  NEXT
END IF

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
PatOff& = SEEK(1)
DIM ChanLoc(NOC - 1) AS LONG

FOR Channel = 0 TO NOC - 1
  ChanLoc(Channel) = SEEK(1)
  Events = 0
  DO
      GET #1, , Byte$
      IF ASC(Byte$) = &HFC THEN
        GET #1, , Byte$: RepCount = ASC(Byte$)
        Temp$ = SPACE$(5): GET #1, , Temp$: Events = Events + RepCount
      ELSE
        Temp$ = SPACE$(4): GET #1, , Temp$: Events = Events + 1
      END IF
  LOOP UNTIL Events >= 64 * (ASC(GDMHead.NOP) + 1)
NEXT

GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
PRINT
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  Music$ = ""

  FOR Channel = 0 TO NOC - 1
    SEEK #1, ChanLoc(Channel)
    Events = 0
    TMusic$ = ""
    DO
        GET #1, , Byte$
        IF ASC(Byte$) = &HFC THEN
          GET #1, , Byte$: RepCount = ASC(Byte$)
          Temp$ = SPACE$(5): GET #1, , Temp$
          FOR J = 1 TO RepCount
            TMusic$ = TMusic$ + Temp$: Events = Events + 1
          NEXT
        ELSE
          Temp$ = SPACE$(4): GET #1, , Temp$: Temp$ = Byte$ + Temp$
          TMusic$ = TMusic$ + Temp$: Events = Events + 1
        END IF
    LOOP UNTIL Events >= 64
    Music$ = Music$ + TMusic$
    ChanLoc(Channel) = SEEK(1)
  NEXT

  FOR Row = 0 TO 63
    FOR Channel = 0 TO NOC - 1
      FX1 = 0: FX2 = 0
      DEF SEG = SSEG(Music$)
      Byte1 = PEEK(SADD(Music$) + (Channel * 320) + Row * 5)     'Note
      Byte2 = PEEK(SADD(Music$) + (Channel * 320) + Row * 5 + 1) 'Sample
      Byte3 = PEEK(SADD(Music$) + (Channel * 320) + Row * 5 + 2) 'Effect Numbers
      Byte4 = PEEK(SADD(Music$) + (Channel * 320) + Row * 5 + 3) 'Effect 2 Data
      Byte5 = PEEK(SADD(Music$) + (Channel * 320) + Row * 5 + 4) 'Effect 1 Data
      GDMNote = 0: GDMIns = 0
      IF Byte1 <> 0 THEN
        Oct = (Byte1 - 1) \ 12
        Note = (Byte1 - 1) MOD 12
        GDMNote = (Oct + 2) * 16 + Note + 1
        OldPorta(Channel) = 0
      END IF
      GDMIns = Byte2
      EFX = Byte3 \ 16                  'Do effect #1
      Dat = Byte5
      FXChan = 0
FXLoop:
      FX = 0
      SELECT CASE EFX
      CASE 1: FX = 1: FXData = Dat      '1xx- Porta up, x=speed
        SELECT CASE FX1
        CASE 1, 2, 3: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE 1, 2: FX = 0
          END SELECT
        END SELECT
      CASE 2: FX = 2: FXData = Dat      '2xx- Porta down, x=speed
        SELECT CASE FX1
        CASE 1, 2, 3: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE 1, 2: FX = 0
          END SELECT
        END SELECT
      CASE 3: FX = 3: FXData = Dat      '3xx- Porta to note, x=speed
        SELECT CASE FX1
        CASE 1, 2, 3: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE 1, 2: FX = 0
          END SELECT
        END SELECT
        IF FX THEN OldPorta(Channel) = FXData
        GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 4: FX = 4: FXData = Dat      '4xy- Vibrato, x=speed, y=depth
        IF FX1 = 4 THEN FX = 0
      CASE 5                            '5xy- Specail
        SELECT CASE Dat
        CASE 0                          'None
        CASE 1                          'Play with no loop
        CASE 2                          'Play backwards with no loop
        END SELECT
      CASE &HA                           'Axx- Volume Slide
        DatHi = ((Dat \ 16)): IF DatHi > &HF THEN DatHi = &HF
        DatLo = ((Dat MOD 16)): IF DatLo > &HF THEN DatLo = &HF
        Dat = DatHi * 16 + DatLo
        FX = &HA: FXData = Dat
        SELECT CASE FX1
        CASE &HA: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE &HA, &HB: FX = 0
          END SELECT
        END SELECT
        IF FXData = 0 THEN FX = 0
      CASE &HB: FX = &H1E: FXData = &H80 + (Dat MOD 16) 'Pan Position
      CASE &HC                   'Cxx- Set Volume, x=volume (0..40)
        Dat = Dat \ 4
        IF Dat > 64 THEN Dat = 64
        FX = &HC: FXData = Dat
      CASE &HD: FX = &HD: FXData = Dat  'Dxx- Pattern Break, break to row x
      CASE &HE                   'Exx- Extended effects
        FF = Dat \ 16
        Dat = Dat MOD 16
        SELECT CASE FF
        CASE 0: FX = &H4: FXData = Dat            'Vibrato Depth
        CASE 1: FX = &HE: FXData = &H10 + Dat     'Fineslide Up
        SELECT CASE FX1
        CASE 1, 2, 3: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE 1, 2: FX = 0
          END SELECT
        END SELECT
        CASE 2: FX = &HE: FXData = &H20 + Dat     'Fineslide Down
        SELECT CASE FX1
        CASE 1, 2, 3: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE 1, 2: FX = 0
          END SELECT
        END SELECT
        CASE 9: FX = &H12: FXData = Dat           'Retrigger
          IF FXData = 0 THEN FX = 0
        CASE &HA: FX = &HE: FXData = &HA0 + Dat   'Fine Vol up
        SELECT CASE FX1
        CASE &HA: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE &HA, &HB: FX = 0
          END SELECT
        END SELECT
        CASE &HB: FX = &HE: FXData = &HB0 + Dat   'Fine Vol down
        SELECT CASE FX1
        CASE &HA: FX = 0
        CASE &HE
          SELECT CASE FX1Data \ 16
          CASE &HA, &HB: FX = 0
          END SELECT
        END SELECT
        CASE &HC: FX = &HE: FXData = &HC0 + Dat   'Note Cut
        CASE &HD: FX = &HE: FXData = &HD0 + Dat   'Note Delay
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1 ELSE FX = 0
        END SELECT
      CASE &HF                   'Fxx- Set Tempo/BPM, x=tempo/BPM
        IF Dat > 31 THEN FX = &H1F ELSE FX = &HF
        FXData = Dat
      CASE ELSE
        IF OldPorta(Channel) THEN
          FX = 3: FXData = 0
          SELECT CASE FX1
          CASE 1, 2, 3: FX = 0
          CASE &HE
            SELECT CASE FX1Data \ 16
            CASE 1, 2: FX = 0
            END SELECT
          END SELECT
        END IF
      END SELECT
      IF FXChan = 0 THEN
        FX1 = FX: FX1Data = FXData
        FXChan = 1
        EFX = Byte3 MOD 16
        Dat = Byte4
        GOTO FXLoop
      ELSE
        FX2 = FX: FX2Data = FXData
      END IF

      IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
        Chan = Channel
        IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
        Events$ = ""
        IF GDMNote <> 0 OR GDMIns <> 0 THEN
          Chan = Chan + 32
          Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
        END IF
        IF FX1 <> 0 AND FX2 <> 0 THEN
          Chan = Chan + 64
          Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
          Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
        ELSE
          IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
          IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
        END IF
        Pat$ = Pat$ + CHR$(Chan) + Events$
      END IF
    NEXT
    Pat$ = Pat$ + CHR$(0)
  NEXT
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
GDMHead.SamOffset = SEEK(2) - 1
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample:"; J;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$: AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    PUT #2, , Buffer$
  LOOP UNTIL FF
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB ConvertXM
GDMHead.FormOrigin = 19                'Fast Tracker 2

SEEK 2, LEN(GDMHead) + 1
Byte$ = " "
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Header Conversion
GET #1, 59, Version
IF Version <> &H104 THEN PRINT "Incorrect format version": END

Temp$ = SPACE$(20)
GET #1, 18, Temp$: Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = 20
GDMHead.SongTitle = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
GDMHead.SongMusician = "Unknown" + STRING$(32, 0)
GDMHead.MastVol = CHR$(64)

GET #1, 61, HeadSize&
GET #1, 65, GDMHead.NOO: GDMHead.NOO = CHR$(ASC(GDMHead.NOO) - 1)
GET #1, 69, NC
GET #1, 71, GDMHead.NOP: GDMHead.NOP = CHR$(ASC(GDMHead.NOP) - 1)
GET #1, 73, GDMHead.NOS: GDMHead.NOS = CHR$(ASC(GDMHead.NOS) - 1)
GET #1, 77, GDMHead.Tempo
GET #1, 79, GDMHead.BPM

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Order Conversion
GDMHead.OrdOffset = SEEK(2) - 1
SEEK 1, 81
FOR J = 0 TO ASC(GDMHead.NOO)
  GET #1, , Byte$
  IF ASC(Byte$) > ASC(GDMHead.NOP) THEN
    ZeroPattern = -1
    Byte$ = CHR$(ASC(GDMHead.NOP) + 1)
  END IF
  PUT #2, , Byte$
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Pattern Conversion
PRINT
SEEK 1, HeadSize&
GDMHead.PatOffset = SEEK(2) - 1
MaxChannels = 0
FOR Pattern = 0 TO ASC(GDMHead.NOP)
  PRINT "Converting Pattern:"; Pattern;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  Pat$ = ""
  'SEEK 1, PatternLoc(Pattern)
  GET #1, , PatLen: PatLen = PatLen - 2
  Music$ = SPACE$(PatLen): GET #1, , Music$
  J& = 0
  Channel = 0
  ChanType = 0
  GDMNote = 0: GDMIns = 0
  Row = 0
  DO
    FX1 = 0: FX2 = 0
    DEF SEG = SSEG(Music$)
    ChanType = PEEK(SADD(Music$) + J&): J& = J& + 1
    IF ChanType = 0 THEN
      Pat$ = Pat$ + CHR$(0)
      Row = Row + 1
      IF BrkFlg THEN Row = 64
      'GOTO ChanDone
    END IF
    Channel = ChanType MOD 32
    IF Channel > NC THEN
      IF ChanType AND 32 THEN J& = J& + 2
      IF ChanType AND 64 THEN J& = J& + 1
      IF ChanType AND 128 THEN J& = J& + 2
      ChanType = 0
    END IF
    GDMNote = 0: GDMIns = 0
    IF ChanType AND 32 THEN             'Note Event
      GDMNote = PEEK(SADD(Music$) + J&) + 1: J& = J& + 1
      IF GDMNote = 256 THEN GDMNote = 0
      IF GDMNote = 255 THEN GDMNote = 0: FX1 = &HC: FX1Data = 0
      GDMIns = PEEK(SADD(Music$) + J&): J& = J& + 1
    END IF
    IF ChanType AND 64 THEN            'Volume Event
      FX1 = &HC: FX1Data = PEEK(SADD(Music$) + J&): J& = J& + 1
      IF FX1Data > 64 THEN FX1Data = 64
    END IF
    IF ChanType AND 128 THEN           'Effect Event
      EFX = PEEK(SADD(Music$) + J&): J& = J& + 1
      Dat = PEEK(SADD(Music$) + J&): J& = J& + 1
      SELECT CASE EFX
      CASE 1: FX2 = &HF: FX2Data = Dat    'Axx- Set Tempo, x=tempo
        IF Dat = 0 THEN FX2 = 0
      CASE 2: FX2 = &HB: FX2Data = Dat    'Bxx- Jump to Order, x=order
        BrkFlg = -1
      CASE 3: FX2 = &HD: FX2Data = Dat    'Cxx- Pattern Break, x=row
        BrkFlg = -1
      CASE 4                              'Dxy- Volume Slide
        HiNib = Dat \ 16: LoNib = Dat MOD 16
        IF HiNib = 0 OR LoNib = 0 THEN            'Volume Slide
          FX2 = &HA: FX2Data = Dat
        ELSE
          IF HiNib = &HF THEN FX2 = &HE: FX2Data = &HB0 + LoNib 'FDown
          IF LoNib = &HF THEN FX2 = &HE: FX2Data = &HA0 + HiNib 'FUp
          IF HiNib <> &HF AND LoNib <> &HF THEN FX2 = &HA: FX2Data = LoNib
        END IF
      CASE 5                            'Exx- Porta Downs
        'IF Dat = 0 THEN Dat = OldPorta(Channel)
        'OldPorta(Channel) = Dat
        IF Dat \ 16 = &HF THEN FX2 = &HE: FX2Data = &H20 + Dat MOD 16'Fine
        IF Dat \ 16 = &HE THEN FX2 = &HE: FX2Data = &H90 + Dat MOD 16'Xtra
        IF Dat \ 16 < &HE THEN FX2 = 2: FX2Data = Dat
      CASE 6                            'Fxx- Porta Ups
        'IF Dat = 0 THEN Dat = OldPorta(Channel)
        'OldPorta(Channel) = Dat
        IF Dat \ 16 = &HF THEN FX2 = &HE: FX2Data = &H10 + Dat MOD 16'Fine
        IF Dat \ 16 = &HE THEN FX2 = &HE: FX2Data = &H80 + Dat MOD 16'Xtra
        IF Dat \ 16 < &HE THEN FX2 = 1: FX2Data = Dat
      CASE 7: FX2 = 3: FX2Data = Dat    'Gxx- Porta to Note
        'IF Dat <> 0 THEN OldPorta(Channel) = Dat
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
      CASE 8: FX2 = 4: FX2Data = Dat    'Hxx- Vibrato
      CASE 9: FX2 = 8: FX2Data = Dat    'Ixx- Tremor
      CASE 10: FX2 = &H10: FX2Data = Dat'Jxx- Arpeggio
      CASE 11                           'Kxy- Vibrato+Volume Slide
        FX2 = 6: FX2Data = Dat
      CASE 12                           'Lxy- Porta Note+Vol slide
        IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1
        FX2 = 5: FX2Data = Dat
      CASE 15: FX2 = 9: FX2Data = Dat   'Oxx- Set Sample Offset
      CASE 17: FX2 = &H12: FX2Data = Dat'Qxx- Retrigger+Vol Slide
      CASE 18: FX2 = 7: FX2Data = Dat   'Rxx- Tremolo
      CASE 19                           'Sxx- Special Commands
        FF = Dat \ 16
        Dat = Dat MOD 16
        SELECT CASE FF
        CASE 0: FX2 = &HE: FX2Data = Dat          'Set filter
        CASE 1: FX2 = &HE: FX2Data = &H30 + Dat   'Glissando Control
        CASE 2: FX2 = &HE: FX2Data = &H50 + Dat   'Set C-4 finetune
        CASE 3: FX2 = &HE: FX2Data = &H40 + Dat   'Vibrato Waveform
        CASE 4: FX2 = &HE: FX2Data = &H70 + Dat   'Tremolo Waveform
        CASE 8: FX2 = &H1E: FX2Data = &H80 + Dat  'Pan Position
        CASE &HB: FX2 = &HE: FX2Data = &H60 + Dat 'Patttern Loop
        CASE &HC: FX2 = &HE: FX2Data = &HC0 + Dat 'Note Cut
        CASE &HD: FX2 = &HE: FX2Data = &HD0 + Dat 'Note Delay
          IF GDMNote <> 0 THEN GDMNote = ((GDMNote - 1) OR 128) + 1 ELSE FX2 = 0
        CASE &HE: FX2 = &HE: FX2Data = &HE0 + Dat 'Pattern Delay
        CASE &HF: FX2 = &HE: FX2Data = &HF0 + Dat 'Invert Loop
        END SELECT
      CASE &H14: FX2 = &H1F: FX2Data = Dat 'Txx- Set BPM, x=BPM
        IF FX2Data < 32 THEN FX2Data = 32
      CASE &H15: FX2 = &H14: FX2Data = Dat 'Uxy- Fine Vibrato
      CASE &H16: FX2 = &H13: FX2Data = Dat 'Set Global Volume
      CASE &H18                            'Xxx- Panning
        IF Dat = &HA4 THEN
          FX2 = &H1E: FX2Data = 1       'Surround
        ELSE
          IF Dat < &H80 THEN
            DDat = Dat \ 8: IF DDat > 15 THEN DDat = 15
            FX2 = &H1E: FX2Data = &H80 + DDat
          END IF
        END IF
      END SELECT
    END IF
    IF GDMNote <> 0 OR GDMIns <> 0 OR FX1 <> 0 OR FX2 <> 0 THEN
      Chan = Channel
      IF Channel + 1 > MaxChannels THEN MaxChannels = Channel + 1
      Events$ = ""
      IF GDMNote <> 0 OR GDMIns <> 0 THEN
        Chan = Chan + 32
        Events$ = Events$ + CHR$(GDMNote) + CHR$(GDMIns)
      END IF
      IF FX1 <> 0 AND FX2 <> 0 THEN
        Chan = Chan + 64
        Events$ = Events$ + CHR$(FX1 + 32) + CHR$(FX1Data)
        Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data)
      ELSE
        IF FX1 <> 0 THEN Events$ = Events$ + CHR$(FX1) + CHR$(FX1Data): Chan = Chan + 64
        IF FX2 <> 0 THEN Events$ = Events$ + CHR$(FX2 + 64) + CHR$(FX2Data): Chan = Chan + 64
      END IF
      Pat$ = Pat$ + CHR$(Chan) + Events$
    END IF
'ChanDone:
  OldBrkFlg = BrkFlg
  BrkFlg = 0
  LOOP UNTIL J& >= PatLen OR Row = 64
  PatLen = LEN(Pat$) + 2
  Pat$ = CHR$(PatLen MOD 256) + CHR$(PatLen \ 256) + Pat$
  PUT 2, , Pat$
NEXT
Music$ = "": Pat$ = ""
IF ZeroPattern THEN
  PRINT "Converting Pattern:"; Pattern + 1;
  LOCATE , 1
  GDMHead.NOP = CHR$(ASC(GDMHead.NOP) + 1)
  Temp$ = CHR$(64) + CHR$(0) + STRING$(64, 0)
  PUT 2, , Temp$
END IF

FOR J = MaxChannels TO 31: PanTable(J) = &HFF: NEXT
FOR J = 0 TO 31
  Pan$ = Pan$ + CHR$(PanTable(J))
NEXT: GDMHead.PanMap = Pan$

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Header Conversion
GDMHead.SamHeadOffset = SEEK(2) - 1
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PRINT "Converting Sample Header:"; Sample;
  LOCATE , 1
  IF INKEY$ = CHR$(27) THEN AbortProg

  HT = 4                               'Has default volume
  'SEEK 1, SampleLoc(Sample)
  GET #1, , Byte$: SamType = ASC(Byte$)
  Temp$ = SPACE$(12): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)) - 1: IF Zero <= 0 THEN Zero = 12
  SamHead(Sample).FileName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(12, 0)
  GET #1, , Byte$
  'GET #1, , Byte$: SampleLoc(Sample) = ASC(Byte$)
  'GET #1, , Byte$: Temp& = ASC(Byte$): SampleLoc(Sample) = SampleLoc(Sample) + Temp& * 256
  'SampleLoc(Sample) = SampleLoc(Sample) * 16
  GET #1, , SamHead(Sample).Length
  GET #1, , SamHead(Sample).LoopBegin
  GET #1, , SamHead(Sample).LoopEnd
  GET #1, , SamHead(Sample).Volume
  IF ASC(SamHead(Sample).Volume) > 64 THEN SamHead(Sample).Volume = CHR$(64)
  GET #1, , Byte$
  GET #1, , Byte$
  IF ASC(Byte$) THEN PRINT "Warning: GDM format does not support packed instruments"
  GET #1, , Byte$: SamFlag = ASC(Byte$)
  IF SamFlag AND 1 THEN HT = HT + 1    'Looped sample
  IF SamFlag AND 2 THEN HT = HT + 32   'Stereo sample
  IF SamFlag AND 4 THEN HT = HT + 2    '16 Bit sample
  GET #1, , SamHead(Sample).C4Hertz
  Temp$ = SPACE$(14): GET #1, , Temp$  'Filler
  Temp$ = SPACE$(28): GET #1, , Temp$
  Zero = INSTR(Temp$, CHR$(0)): IF Zero = 0 THEN Zero = 28
  SamHead(Sample).SamName = RTRIM$(LEFT$(Temp$, Zero)) + STRING$(32, 0)
  SamHead(Sample).Flags = CHR$(HT)
NEXT
FOR J = ASC(GDMHead.NOS) TO 0 STEP -1
  IF SamHead(J).SamName <> STRING$(32, 0) OR SamHead(J).Length <> 0 THEN EXIT FOR
NEXT
GDMHead.NOS = CHR$(J)
FOR Sample = 0 TO ASC(GDMHead.NOS)
  PUT #2, , SamHead(Sample)
NEXT

'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Conversion
GDMHead.SamOffset = SEEK(2) - 1
PRINT
FOR J = 0 TO ASC(GDMHead.NOS)
  LOCATE , 1
  IF FFV = 2 THEN PRINT "Copying Sample:"; J;  ELSE PRINT "Converting Sample:"; J;
  IF INKEY$ = CHR$(27) THEN AbortProg

  SL& = SamHead(J).Length
  'IF SampleLoc(J) = 0 THEN GOTO NoSample
  'SEEK 1, SampleLoc(J)
  FF = 0
  DO
    IF SL& > 16000 THEN BL = 16000: SL& = SL& - 16000 ELSE BL = SL&: FF = 1
    Buffer$ = SPACE$(BL)
    GET #1, , Buffer$
    IF FFV = 1 THEN
      AmigaSam8 SSEG(Buffer$), SADD(Buffer$), LEN(Buffer$)
    END IF
    PUT #2, , Buffer$
  LOOP UNTIL FF
'NoSample:
NEXT

PUT #2, 1, GDMHead
CLOSE 2, 1
PRINT : PRINT
END SUB

SUB DetermineFile
ID$ = SPACE$(17)
GET #1, 1, ID$
IF ID$ = "Extended Module: " THEN FileType = 19: EXIT SUB

ID$ = SPACE$(8)
GET #1, 45, ID&
GET #1, 21, ID$
GET #1, 61, IDD&
IF IDD& = &H4D524353 AND ID$ = "!Scream!" THEN FileType = 4: EXIT SUB
IF ID& = &H4D524353 THEN FileType = 2: EXIT SUB
IF ID$ = "!Scream!" THEN FileType = 3: EXIT SUB
IF ID$ = "BMOD2STM" THEN FileType = 3: EXIT SUB

ID$ = SPACE$(4)
GET #1, 1, ID$
IF ID$ = "FARþ" THEN FileType = 5: EXIT SUB
IF LEFT$(ID$, 3) = "MTM" THEN FileType = 0: EXIT SUB
IF LEFT$(ID$, 3) = "MAS" THEN
  G$ = " "
  GET #1, 15, G$
  IF G$ = "1" THEN FileType = 14: EXIT SUB
  IF G$ = "2" THEN FileType = 15: EXIT SUB
  IF G$ = "3" THEN FileType = 16: EXIT SUB
  IF G$ = "4" THEN FileType = 17: EXIT SUB
END IF
IF ID$ = "PSMþ" THEN FileType = 6: EXIT SUB
IF LEFT$(ID$, 3) = "MMD" THEN FileType = 7: EXIT SUB
IF ID$ = "DDMF" THEN FileType = 20: EXIT SUB

ID$ = "1234": GET #1, 1081, ID$
SELECT CASE ID$
CASE "M.K."
  IF RIGHT$(File$, 4) = ".WOW" THEN FileType = 11 ELSE FileType = 9
  EXIT SUB
CASE "M!K!", "FLT4", "4CHN": FileType = 9: EXIT SUB
CASE "6CHN": FileType = 10: EXIT SUB
CASE "8CHN", "FLT8", "OCTA": FileType = 11: EXIT SUB
END SELECT
IF RIGHT$(ID$, 2) = "CH" OR RIGHT$(ID$, 3) = "CHN" THEN FileType = 9: EXIT SUB

GET #1, 1, ID
IF ID = &H6669 THEN FileType = 1: EXIT SUB
IF ID = &H4E4A THEN FileType = 1: EXIT SUB
IF RIGHT$(File$, 4) = ".MOD" THEN FileType = 8: EXIT SUB
FileType = 255
'FileTypes:
'0-MTM   1-669   2-S3M   3-STM   4-STX   5-FAR    6-PSM
'7-MED   8-15MOD 9-4MOD  10-6MOD 11-8MOD 12-16MOD 13-32MOD
'14-ULT1 15-ULT2 16-ULT3 17-ULT4 18-     19-      20-DMF

'If unknown, just close it up..
CLOSE 1
END SUB

