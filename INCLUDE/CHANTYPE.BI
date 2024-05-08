'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
'              Bells, Whistles, and Sound Boards. Version 1.00
'                  Copyright (c) 1993-97, Edward Schlunder.
'                 See COPYING.ES for redistribution details.
'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
' CHANTYPE.BI - Channel information type declaration for BWSB.
'
'               Written by Edward Schlunder (1994)
'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TYPE ChannelType
  MixFlags              AS STRING * 1  'Mixing flags
  MixLBeg               AS INTEGER     'Offset of loop beginning
  MixLEnd               AS INTEGER     'Offset of loop ending
  MixFinetune           AS INTEGER     'Finetune (C-4 Hertz)
  MixRate               AS LONG        'Sample rate/period of sound
  MixSeg                AS INTEGER     'Segment of sound
  MixOff                AS INTEGER     'Offset of next byte to mix
  MixVolume             AS STRING * 1  'Volume of channel
  MixInc                AS INTEGER     'Incrementation for each sample. MSB.LSB
  MixIncRemain          AS STRING * 1  'Remainder from last increment.
  MusSample             AS STRING * 1  'Currently played sample number
  MusNote               AS STRING * 1  'Currently played note
  MusOctave             AS STRING * 1  'Currently played octave
  MusEffect1            AS STRING * 1  'Music Effect Number (1)**
  MusEffDat1            AS INTEGER     'Music Effect Data   (1)**
  MusEffect2            AS STRING * 1  'Music Effect Number (2)*
  MusEffDat2            AS INTEGER     'Music Effect Data   (2)*
  MusEffect3            AS STRING * 1  'Music Effect Number (3)
  MusEffDat3            AS INTEGER     'Music Effect Data   (3)
  MusEffect4            AS STRING * 1  'Music Effect Number (4)
  MusEffDat4            AS INTEGER     'Music Effect Data   (4)
  VUMeter               AS STRING * 1  'Volume Meter value
  MusVolRate            AS INTEGER     'Old Vol Slide Speed
  MusPortaRate          AS INTEGER     'Old Porta to Note Speed
  MusVibWave            AS STRING * 1  'Vibrato Waveform Select
  MusVibPosition        AS STRING * 1  'Vibrato Table Position
  MusVibSpeed           AS STRING * 1  'Vibrato Speed (x0h)
  MusVibDepth           AS STRING * 1  'Vibrato Depth (0yh)
  MusTrmWave            AS STRING * 1  'Tremolo Waveform Select
  MusTrmPosition        AS STRING * 1  'Tremolo Table Position
  MusTrmSpeed           AS STRING * 1  'Tremolo Speed
  MusTrmDepth           AS STRING * 1  'Tremolo Depth
  MusRetrigSpeed        AS STRING * 1  'Retrigger speed
  MusRetrigSlide        AS STRING * 1  'Retrigger volume slide
  MusGlissFunk          AS STRING * 1  'Funk It (Invert Loop) Speed
  MusFunkOffset         AS STRING * 1  'Funk It position
  MusWaveStart          AS INTEGER     'Funk It funk pointer (offset into sample)
  MixPanning            AS STRING * 1  'Pan position
  MixHandle             AS STRING * 1  'EMS Handle this sample resides on
  MixMonoVol            AS STRING * 1  'Mono volume value
  MixLftVol             AS STRING * 1  'Left speaker mixing volume
  MixRgtVol             AS STRING * 1  'Right speaker mixing volume
  GUSAddress            AS LONG        'Address of start position in GUS memory
  MusArpeggio           AS STRING * 1  'Old Arpeggio speed
  MusPortaUD            AS STRING * 1  'Old Porta Up/Down speed
  Reserved              AS STRING * 64 'For future expansion
END TYPE
