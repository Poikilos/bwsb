//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//                    Bells, Whistles, and Sound Boards
//                 Copyright (c) 1993-97, Edward Schlunder
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

typedef struct {
    unsigned char   *Sample;
    char            SamName[32];
    char            FileName[13];
    unsigned long   Length;
    unsigned long   LoopBegin;
    unsigned long   LoopEnd;
    unsigned char   Flags;
    unsigned int    Rate;
    unsigned char   Volume;
    unsigned char   Pan;
} SampleInfo;

typedef struct {
  char ID[4];                          // ID: 'GDMş'
  char SongTitle[32];                  // Music's title
  char SongMusician[32];               // Name of music's composer
  char ID2[4];                         // ID: 'GDMF'
  unsigned char FormMajorVer;          // Format major version
  unsigned char FormMinorVer;          // Format minor version
  unsigned short TrackID;            // Composing Tracker ID code
  unsigned char TrackMajorVer;         // Tracker's major version
  unsigned char TrackMinorVer;         // Tracker's minor version
  unsigned char PanMap[32];            // 0-Left to 15-Right, 255-N/U
  unsigned char MastVol;               // Range: 0..64
  unsigned char Tempo;                 // Initial music tempo (6)
  unsigned char BPM;                   // Initial music BPM (125)
  unsigned short FormOrigin;         // Original format ID:
   // 1-MOD, 2-MTM, 3-S3M, 4-669, 5-FAR, 6-ULT, 7-STM, 8-MED
   // (versions of 2GDM prior to v1.15 won't set this correctly)

  unsigned long OrdOffset;
  unsigned char NOO;                   // Number of orders in module
  unsigned long PatOffset;
  unsigned char NOP;                   // Number of patterns in module
  unsigned long SamHeadOffset;
  unsigned long SamOffset;
  unsigned char NOS;                   // Number of samples in module
  unsigned long MTOffset;
  unsigned long MTLength;
  unsigned long SSOffset;
  unsigned short SSLength;
  unsigned long TGOffset;
  unsigned short TGLength;
} GDMHeader;

typedef struct {
    int     MixInc;                     //for pausing the music

    int     MusNote;
    int     MusOctave;
    int     MusSample;
    int     MusRate;
    int     MusEffect[4];
    int     MusEfxDat[4];
    int     MusPeriod;

    // Effect Save Data
    int     MusVolRate;                 //volume slide speed

    int     MusVibPosition;
    int     MusVibWave;
    int     MusVibDepth;
    int     MusVibSpeed;
} ChannelInfo;

//Ä Mixer Structures ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
typedef struct {
        char SamName[32];               //Instrument's full name
        char SamFileName[13];           //Sample's file name
        unsigned int GUSAddress;        //GUS DRAM memory location
        unsigned int SamLen;            //Sample length
        unsigned int SamBegin;          //Sample loop begin
        unsigned int SamEnd;            //Sample loop end
        unsigned char SamFlags;         //Sample flags
        unsigned int SamTune;           //C-4Hz. 8363 normal
        unsigned char SamVol;           //Sample's default volume
        unsigned char SamPan;           //Pan Position
} SamHeader;        

typedef struct {
        unsigned char MixFlags;                  //Mixing flags
        unsigned int MixLBeg;                    //Offset of loop beginning
        unsigned int MixLEnd;                    //Offset of loop ending
        unsigned int MixFinetune;                //Finetune
        unsigned int MixRate;                    //Sample rate/period of sound
        unsigned int MixOff;                     //Offset of next byte to mix
        unsigned char MixVolume;                 //Volume of channel
        unsigned char MixMonoVol;
        unsigned int MixInc;                     //Incrementation for each sample. MSB.LSB
        unsigned char MixIncRemain;              //Remainder from last increment.
        unsigned int Sample;                     //Sample number
        unsigned char VUMeter;                   //Volume Meter value
        unsigned char MixPanning;                //Pan position
        unsigned int GUSAddress;                 //Address of start position in GUS memory
} SoundChan;

extern void UpdateMusic(void);
