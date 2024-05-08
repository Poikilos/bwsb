//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
//                              Sound Blaster
//                           OmniSound Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
#include <dpmi.h>

#define MAX_SAMPLES 255

#define seOKAY 0                        //Status: - OK -
#define seRESPOND 6                     //Sound Device doesn't respond

class seSB1X {
public:
        seSB1X(void);                            
        seSB1X(short Addr, char IRQ, char IRQ2, char DMA, char DMA2);
        int Status(void);                       
        const char *DevName(void);
        int DevAddr(void);
        int DevIRQ(void);
        int DevDMA(void);
        int AllocSample(int SamNum, SampleInfo SamHead);
        void FreeSample(int SamNum);
        void PlaySample(char Chan, int Sam, int Rate, char Vol, char Pan);
        int ChannelVol(char Chan, char Vol);
        char ChannelPan(char Chan, char Pan);

    long seGUS::MixInc(char Ch);
    void seGUS::MixInc(char Ch, long NewInc);
    long seGUS::Offset(char Ch);
    void seGUS::Offset(char Ch, unsigned long Offs);
    void seGUS::Channels(char Ch);
    int seGUS::Channels(void);

        void SetTimerBPM(int BPM);
        void IRQFree(void);
        void IRQSetup(void);
        void SetUltraTimer1(void);

        int u_Poke(long Addr, unsigned char Sample);
        char u_Peek(long Addr);
        unsigned int GUSLoc(char Ch);
        void u_Pokei(long Addr, unsigned int Sample);
        unsigned int u_Peeki(long Loc);
        int u_MemSize(void);
        void CleanMemory(void);
        void SetChannel(char Ch);

        int VU[32];

private:

        void GF1_Delay(void);
        void InitGUS(void);
        void PreInitGUS(void);
        int CheckGUS(void);
        void UltraSlideRamp(int Vol);

        int ErrStatus;                  //Sound Engine Status

        char dma;                       //SB's Playback DMA channel
        char irq;                       //SB's IRQ Level
        char int;                       //Actual Interrupt number for IRQ

//ฤ IRQ/DMA Data Tables ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
        _go32_dpmi_seginfo OldIRQ;      //old interrupt handler
        _go32_dpmi_seginfo NewIRQ;      //our new interrupt handler

//ฤ Standard Snd Engine ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
        char OutputStatus;              //0-Output Disabled, 1-Output Enabled
        char MasterVol;                 //Master Volume
        int OverRate;                   //Oversampling Rate
        int NumChannels;                //Number of channels total 
    
        SoundChan CHAN[32];             //sound channels
        SamHeader SAM[MAX_SAMPLES];     //samples

};

