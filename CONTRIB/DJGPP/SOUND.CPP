//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
//                               Sound Engine
//                          OmniSound Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
#include <string.h>

#include "bwsb32.h"
#include "sound.h"

int SoundEngine::Status(void) {
    return(errStatus);
}

const char *SoundEngine::Device(void) {
    return(devName);
}

int SoundEngine::Address(void) {
    return(addr);
}

int SoundEngine::IRQ(void) {
    return(irq);
}

int SoundEngine::DMA(void) {
    return(dma);
}

SoundEngine::SoundEngine(void) {
    SoundEngine("GUS", 0x240, 15, 15, 5, 5);
}

SoundEngine::SoundEngine(char Dev[], int Addr, char IRQ, char DMA) {
    if(strcmp(Dev, "SB1X") == 0) {
        _snd_SetSB1X(*this, Addr, IRQ, DMA);
        return;
    }

    _snd_SetGUS(*this, Addr, IRQ, IRQ, DMA, DMA);
}

SoundEngine::SoundEngine(char Dev[], int Addr, char IRQ, char IRQ2, char DMA, char DMA2) {
    if(strcmp(Dev, "SB1X") == 0) {
        _snd_SetSB1X(*this, Addr, IRQ, DMA);
        return;
    }

    _snd_SetGUS(*this, Addr, IRQ, IRQ2, DMA, DMA2);
}



