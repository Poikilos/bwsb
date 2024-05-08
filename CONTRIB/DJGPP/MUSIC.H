//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
//                           Music and Sound Engine
//                 BWSB/32 Music and Sound Engine Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
#include <stdio.h>

class MusicEngine {
public:
    int Load(char FileName[]);
    int Load(char FileName[], int Offset);

    MusicEngine(seGUS& SoundEngine);
    void Order(int newOrd);

    void Play(void);
    void Pause(void);

//Quasi-Private Data (shouldn't be used by clients, only by music engines)
    int (*RealLoad)(MusicEngine& mus, FILE *fpFile);
    int (*RealSave)(MusicEngine& mus, FILE *fpFile);
    void (*RealUpdate)(MusicEngine& mus);    

    seGUS *snd;

    GDMHeader   head;
    SampleInfo  sam[256];
    char        *music[256];
    int         musLen[256];

    char Title[33];                     //music's title
    int NOO;                            //number of orders
    int NOP;                            //number of patterns
    int NOS;                            //number of samples
    int *OrdTable;                      //pointer to order table
    char *Pattern[256];                 //pointers to pattern data
    int *PatLength;                     //pointer to pattern length table
    SampleInfo *Sample;

    ChannelInfo CHAN[32];
    int MaxChan;                        //number of music channels
    int Volume;                         //music volume (0..64)
    int Tempo;                          //music tempo
    int BPM;                            //music BPM
    int TempoCounter;                   //number of frames before row update
    int Row, Pat, Ord;                  //current music playing location
    int MusOff;                         //current offset into music data 
    int Pan[32];                        //Panning Table:
                                        //0-15 LFT/RGT, 16 SRD, 255-N/U
private:
    int DetectType(FILE *fpFile);

    int Format;                         //which music format/engine we use
    
};

extern const int PeriodTable[], VibrateTable[];

#define musOPENFAIL 1
#define musCORRUPT 2

#define fmtMOD 1
#define fmtS3M 2
#define fmtGDM 30
