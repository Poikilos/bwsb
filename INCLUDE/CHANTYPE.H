//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//                    Bells, Whistles, and Sound Boards
//                  Copyright (c) 1993-95, Edward Schlunder.
//                 See COPYING.ES for redistribution details.
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
// CHANTYPE.BI - Channel information structure definition.
//               Written by Edward Schlunder (1995)
//
//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
typedef struct
{
  unsigned char MixFlags;              // Mixing flags
  unsigned int MixLBeg;                // Offset of loop beginning
  unsigned int MixLEnd;                // Offset of loop ending
  unsigned int MixFinetune;            // Finetune (C-4 Hertz)
  unsigned long MixRate;               // Sample rate/period of sound
  unsigned int MixSeg;                 // Segment of sound
  unsigned int MixOff;                 // Offset of next byte to mix
  unsigned char MixVolume;             // Volume of channel
  unsigned int MixInc;                 // Incrementation for each sample. MSB.LSB
  unsigned char MixIncRemain;          // Remainder from last increment.
  unsigned char MusSample;             // Currently played sample number
  unsigned char MusNote;               // Currently played note
  unsigned char MusOctave;             // Currently played octave
  unsigned char MusEffect1;            // Music Effect Number (1)**
  unsigned int MusEffDat1;             // Music Effect Data   (1)**
  unsigned char MusEffect2;            // Music Effect Number (2)*
  unsigned int MusEffDat2;             // Music Effect Data   (2)*
  unsigned char MusEffect3;            // Music Effect Number (3)
  unsigned int MusEffDat3;             // Music Effect Data   (3)
  unsigned char MusEffect4;            // Music Effect Number (4)
  unsigned int MusEffDat4;             // Music Effect Data   (4)
  unsigned char VUMeter;               // Volume Meter value
  unsigned int MusVolRate;             // Old Vol Slide Speed
  unsigned int MusPortaRate;           // Old Porta to Note Speed
  unsigned char MusVibWave;            // Vibrato Waveform Select
  unsigned char MusVibPosition;        // Vibrato Table Position
  unsigned char MusVibSpeed;           // Vibrato Speed (x0h)
  unsigned char MusVibDepth;           // Vibrato Depth (0yh)
  unsigned char MusTrmWave;            // Tremolo Waveform Select
  unsigned char MusTrmPosition;        // Tremolo Table Position
  unsigned char MusTrmSpeed;           // Tremolo Speed
  unsigned char MusTrmDepth;           // Tremolo Depth
  unsigned char MusRetrigSpeed;        // Retrigger speed
  unsigned char MusRetrigSlide;        // Retrigger volume slide
  unsigned char MusGlissFunk;          // Funk It (Invert Loop) Speed
  unsigned char MusFunkOffset;         // Funk It position
  unsigned int MusWaveStart;           // Funk It funk pointer (offset into sample)
  unsigned char MixPanning;            // Pan position
  unsigned char MixHandle;             // EMS Handle this sample resides on
  unsigned char MixMonoVol;            // Mono volume value
  unsigned char MixLftVol;             // Left speaker mixing volume
  unsigned char MixRgtVol;             // Right speaker mixing volume
  unsigned long GUSAddress;            // Address of start position in GUS memory
  unsigned char MusArpeggio;           // Old Arpeggio speed
  unsigned char MusPortaUD;            // Old Porta Up/Down speed
  char Reserved[64];                   // For future expansion
} ChannelType;
