//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
//                               Music Engine
//                 BWSB/32 Music and Sound Engine Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
#include <stdio.h>
#include <string.h>
#include <dos.h>

#include "bwsb32.h"
#include "gus.h"
#include "music.h"

#include "gdm.h"
#include "s3m.h"

const int PeriodTable[] = { 1712*16, 1616*16, 1524*16, 1440*16, 1356*16,
                            1280*16, 1208*16, 1140*16, 1076*16, 1016*16,
                             960*16, 907*16 };

const int VibrateTable[] = {   0, 24, 49, 74, 97,120,141,161,180,197,212,
                             224,235,244,250,253,255,253,250,244,235,224,
                             212,197, 180,161,141,120, 97, 74, 49, 24 };
MusicEngine *UpdatePTR;

void UpdateMusic(void) {
    UpdatePTR->RealUpdate(*UpdatePTR);
}

int MusicEngine::DetectType(FILE *fpFile) {
    char ID[5];
    long lTemp;

    fseek(fpFile, 0, SEEK_SET);
    fread(ID, 1, 4, fpFile); ID[5] = 0;
    if(!strcmp(ID, "GDMþ\0"))
        return(fmtGDM);
    
    fseek(fpFile, 44, SEEK_SET);
    fread(&lTemp, 1, 4, fpFile);
    if(lTemp == 0x4D524353)
        return(fmtS3M);

    return(NULL);                       //Couldn't figure out module format
}

int MusicEngine::Load(char FileName[]) {
    FILE *fpFile;

    fpFile = fopen(FileName, "rb");
    if(fpFile == NULL) {
        return(musOPENFAIL);
    }

    Format = fmtGDM; //DetectType(fpFile);

    switch(Format) {
    case fmtGDM:
        RealLoad    = &_musLoadGDM;
        RealSave    = &_musSaveGDM;
        RealUpdate  = &_musUpdateGDM;
        break;
    case fmtS3M:
        RealLoad    = &_musLoadS3M;
        RealSave    = &_musSaveGDM;
        RealUpdate  = &_musUpdateGDM;
        break;
    }
    UpdatePTR = this;

    fseek(fpFile, 0, SEEK_SET);
    RealLoad(*this, fpFile);
    fclose(fpFile);

    return(0);                          //Everything okay
}

int MusicEngine::Load(char FileName[], int Offset) {
    FILE *fpFile;
    fpFile = fopen(FileName, "rb");
    fseek(fpFile, Offset, SEEK_SET);

    return(0);
}

MusicEngine::MusicEngine(seGUS& SoundEngine) {
    snd = &SoundEngine;
    Format = NULL;

    MaxChan = 0;
    for(int i = 0; i < 32; i++) {
        CHAN[i].MixInc = 0;
    }
}

void MusicEngine::Order(int newOrd) {
    if(newOrd < 0)
        newOrd = 0;
    if(newOrd > NOO)
        newOrd = NOO;

    disable();
    MusOff = 2;
    Ord = newOrd;
    Pat = OrdTable[Ord];
    Row = 0;
    enable();
}

void MusicEngine::Play(void) {
    snd->SetTimerBPM(head.BPM);

    for(int i = 0; i < MaxChan; i++) {
        snd->MixInc(i, CHAN[i].MixInc);
    }
}

void MusicEngine::Pause(void) {
    snd->SetTimerBPM(0);                 //Turn off music timer

    for(int i = 0; i < MaxChan; i++) {
        CHAN[i].MixInc = snd->MixInc(i);
        snd->MixInc(i, 0);
    }
}
