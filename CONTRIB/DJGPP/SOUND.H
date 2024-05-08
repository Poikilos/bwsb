//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
//                               Sound Engine
//                          OmniSound Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

#define MAX_CHAN 32

class SoundEngine {
public:
    SoundEngine(void);        
    SoundEngine(char Dev[], int Addr, char IRQ, char DMA);
    SoundEngine(char Dev[], int Addr, char IRQ, char IRQ2, char DMA, char DMA2);

    int Status(void);
    const char *Device(void);
    int Address(void);
    int IRQ(void);
    int DMA(void);

    void Channels(char chan);
    int Channels(void);

    void OverRate(unsigned int overRate);
    unsigned int OverRate(void);

    void SetChannel(char chan);
        void Volume(char vol);
        int Volume(void);
        void Sample(int num);
        int Sample(void);
        void SamOffset(long offs);
        long SamOffset(void);
        void Freq(long freq);
        long Freq(void);
        void Pan(char pan);
        int Pan(void);
        void LoopStart(long offs);
        long LoopStart(void);
        void PlayEnd(long offs);
        long PlayEnd(void);
        void PlayFlags(int flags);
        int PlayFlags(void);

    void NewSample(int num, SampleInfo head);
    void DeleteSample(int num);
    long AvailSample(void);
    SampleInfo GetSample(int num);

    void MusTimer(int BPM);
    int MusTimer(void);

    void On(void);
    int On(void);
    void Off(void);

    int VU[MAX_CHAN];

//---------------------------------------------------------------------------
//Quasi-Private Data... Clients shouldn't access this stuff directly. It is
//only provided for use by the individual sound card drivers.
//---------------------------------------------------------------------------
    void (*RealAllocSample)(SoundEngine& snd, int num, SampleInfo head);
    void Channels(char chan);
    void OverRate(unsigned int overRate);

//---------------------------------------------------------------------------
    int errStatus;                      //Sound Engine Status
    int addr;
    char irq, irq2;
    char dma, dma2;
    int overRate;
    char numChan;

    char device;
    char *devName;

private:
};
