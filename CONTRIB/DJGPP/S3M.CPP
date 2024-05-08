#include <stdio.h>
#include <iostream.h>

#include "bwsb32.h"
#include "gus.h"
#include "music.h"
int _musLoadS3M(MusicEngine& mus, FILE *fpFile) {
//    int OldPorta[16];
    int NC = 0;
    unsigned char Byte, Stereo, ZeroPattern;
    unsigned short CWTV, usTemp, Flags;

    //컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Header Conversion
    fseek(fpFile, 0x1D, SEEK_SET);
    fread(&Byte, 1, 1, fpFile);
    if(Byte != 16) {
        cout << "Not a ST3 module" << endl;
        return(musCORRUPT);
    }

    fseek(fpFile, 0, SEEK_SET);
    fread(mus.Title, 1, 28, fpFile);
    fseek(fpFile, 0x20, SEEK_SET);
    fread(&usTemp, 1, 2, fpFile); mus.NOO = usTemp - 1;
    fread(&usTemp, 1, 2, fpFile); mus.NOS = usTemp - 1;
    fread(&usTemp, 1, 2, fpFile); mus.NOP = usTemp - 1;
    fread(&Flags, 1, 2, fpFile);
    fread(&CWTV, 1, 2, fpFile);
    fread(&usTemp, 1, 2, fpFile);
    if(usTemp > 2) {
        cout << "Incorrect format version" << endl;
        return(musCORRUPT);
    }
    fseek(fpFile, 0x30, SEEK_SET);
    fread(&Byte, 1, 1, fpFile); mus.Volume = Byte;
    fread(&Byte, 1, 1, fpFile); mus.Tempo = Byte;
    fread(&Byte, 1, 1, fpFile); mus.BPM = Byte;
    fread(&Byte, 1, 1, fpFile); Stereo = Byte >> 7;

    fseek(fpFile, 0x40, SEEK_SET);
    for(int i = 0; i < 32; i++) {
        fread(&Byte, 1, 1, fpFile);

        mus.Pan[i] = 0xFF;
        if(Byte <= 7) {
            mus.Pan[i] = (Stereo) ? 0:8;
            NC++;
        }
        if(Byte >= 8 && Byte <= 15) {
            mus.Pan[i] = (Stereo) ? 15:8;
            NC++;
        }
    }
    //컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Order Conversion
    fseek(fpFile, 0x60, SEEK_SET);

    mus.OrdTable = new int[mus.NOO+1];
    usTemp = mus.NOO;
    for(int i = 0; i <= usTemp; i++) {
        fread(&Byte, 1, 1, fpFile);
        if(Byte < 254) {
            if(Byte > mus.NOP) {
                ZeroPattern = 0xFF;
                Byte = mus.NOP + 1;
            }
            mus.OrdTable[i] = Byte;
        }
        else {
            mus.NOO--;
        }
    }

    long SampleLoc[256];                //Load Sample Location Table
    for(int i = 0; i <= mus.NOS; i++) {
        fread(&usTemp, 1, 2, fpFile);
        SampleLoc[i] = usTemp << 4;        
    }

    long PatternLoc[256];               //Load Pattern Location Table
    for(int i = 0; i <= mus.NOP; i++) {
        fread(&usTemp, 1, 2, fpFile);
        PatternLoc[i] = usTemp << 4;
    }

    if(CWTV >= 0x1320) {
        for(int i = 0; i < NC; i++) {
            fread(&Byte, 1, 1, fpFile);
            if(Byte & 32)
                mus.Pan[i] = Byte & 0xF;
        }
    }

    //컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Sample Header Conversion
    char HT, SamType, SamFlag;
    mus.Sample = new SampleInfo[mus.NOS+1];
    for(int i = 0; i <= mus.NOS; i++) {
        HT = 4;                         //HAs default volume
        fseek(fpFile, SampleLoc[i], SEEK_SET);
        fread(&SamType, 1, 1, fpFile);
        fread(mus.Sample[i].FileName, 1, 12, fpFile);
        fseek(fpFile, +1, SEEK_CUR);
        fread(&usTemp, 1, 2, fpFile); SampleLoc[i] = usTemp << 4;
        fread(&mus.Sample[i].Length, 1, 4, fpFile);
        fread(&mus.Sample[i].LoopBegin, 1, 4, fpFile);
        fread(&mus.Sample[i].LoopEnd, 1, 4, fpFile); mus.Sample[i].LoopEnd++;
        fread(&mus.Sample[i].Volume, 1, 4, fpFile);
        if(mus.Sample[i].Volume > 64) mus.Sample[i].Volume = 64;
        fseek(fpFile, +2, SEEK_CUR);
        fread(&SamFlag, 1, 1, fpFile);
        if(SamFlag & 1) HT |= 1;        //Looped sample
        if(SamFlag & 2) HT |= 32;       //Stereo sample
        if(SamFlag & 4) HT |= 2;        //16 bit sample
        fread(&usTemp, 1, 2, fpFile); mus.Sample[i].Rate = usTemp;
        fseek(fpFile, +14, SEEK_CUR);
        fread(mus.Sample[i].SamName, 1, 28, fpFile);
        mus.Sample[i].Flags = HT;
    }

    for(int i = mus.NOS; i >= 0; i--) {
        if(mus.Sample[i].SamName[0] != 0 || mus.Sample[i].Length != 0) {
            mus.NOS = i;
            break;
        }
    }



    mus.Row = 0;
    mus.Ord = 0;
    mus.Pat = mus.OrdTable[mus.Ord];
    mus.MusOff = 2;
    mus.TempoCounter = mus.head.Tempo;

    mus.snd->SetTimerBPM(mus.head.BPM);

    return(0);
}
/*
'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Pattern Conversion
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

'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Sample Conversion
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

*/
