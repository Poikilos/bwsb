//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//                                   GDM
//                 BWSB/32 Music and Sound Engine Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
#include <stdio.h>

#include "bwsb32.h"
#include "gus.h"
#include "music.h"

int _musSaveGDM(MusicEngine& mus, FILE *fpFile) {
    fwrite(&mus.Title, 1, 32, fpFile);
    return(0);
}

int _musLoadGDM(MusicEngine& mus, FILE *fpFile) {
    unsigned char c;
    unsigned short temp;

    fseek(fpFile, 0, SEEK_SET);
    fread(mus.head.ID, 1, 4, fpFile);
    fread(mus.Title, 1, 32, fpFile);
    mus.Title[33] = 0;
    fread(mus.head.SongMusician, 1, 32, fpFile);
    fseek(fpFile, 3, SEEK_CUR);
    fread(mus.head.ID2, 1, 4, fpFile);
    fread(&mus.head.FormMajorVer, 1, 2, fpFile);
    fread(&mus.head.TrackID, 1, 2, fpFile);
    fread(&mus.head.TrackMajorVer, 1, 37, fpFile);
    fread(&mus.head.FormOrigin, 1, 2, fpFile);
    fread(&mus.head.OrdOffset, 1, 4, fpFile);
    fread(&c, 1, 1, fpFile); mus.NOO = c;
    fread(&mus.head.PatOffset, 1, 4, fpFile);
    fread(&c, 1, 1, fpFile); mus.NOP = c;
    fread(&mus.head.SamHeadOffset, 1, 4, fpFile);
    fread(&mus.head.SamOffset, 1, 4, fpFile);
    fread(&c, 1, 1, fpFile); mus.NOS = c;
    fread(&mus.head.MTOffset, 1, 12, fpFile);
    fread(&mus.head.SSLength, 1, 2, fpFile);
    fread(&mus.head.TGOffset, 1, 4, fpFile);
    fread(&mus.head.TGLength, 1, 2, fpFile);

    mus.head.SongTitle[31] = 0;

    mus.MaxChan = 0;
    for(int i = 0; i < 32; i++) {
        mus.MaxChan++;
        if(mus.head.PanMap[i] == 0xFF)
            break;

        mus.snd->ChannelPan(i, mus.head.PanMap[i]);
    }
    mus.snd->Channels(mus.MaxChan);

    fseek(fpFile, mus.head.SamHeadOffset, SEEK_SET);
    for(int i = 0; i <= mus.NOS; i++) {
        fread(mus.sam[i].SamName, 1, 45, fpFile);
        fread(&mus.sam[i].Length, 1, 12, fpFile);
        fread(&mus.sam[i].Flags, 1, 1, fpFile);
        fread(&temp, 1, 2, fpFile);
        mus.sam[i].Rate = temp;
        fread(&mus.sam[i].Volume, 1, 2, fpFile);

        mus.sam[i].SamName[31] = 0;
        mus.sam[i].Pan = 8;
    }

    fseek(fpFile, mus.head.SamOffset, SEEK_SET);
    for(int i = 0; i <= mus.NOS; i++) {
        mus.sam[i].Sample = new unsigned char[mus.sam[i].Length];
        fread(mus.sam[i].Sample, 1, mus.sam[i].Length, fpFile);

        mus.snd->AllocSample(i, mus.sam[i]);

        delete mus.sam[i].Sample;
    }

    fseek(fpFile, mus.head.OrdOffset, SEEK_SET);
    mus.OrdTable = new int[mus.NOO+1];
    for(int i = 0; i <= mus.NOO; i++) {
        fread(&c, 1, 1, fpFile);
        mus.OrdTable[i] = c;
    }

    fseek(fpFile, mus.head.PatOffset, SEEK_SET);
    for(int i = 0; i <= mus.NOP; i++) {
        fread(&temp, 1, 2, fpFile);     //read size of pattern data
        mus.musLen[i] = temp;
        fseek(fpFile, -2, SEEK_CUR);
        mus.music[i] = new char[mus.musLen[i]];
        fread(mus.music[i], 1, mus.musLen[i], fpFile);
    }

    mus.Row = 0;
    mus.Ord = 0;
    mus.Pat = mus.OrdTable[mus.Ord];
    mus.MusOff = 2;
    mus.TempoCounter = mus.head.Tempo;

    for(int i = 0; i < mus.MaxChan; i++) {
        mus.CHAN[i].MusVolRate = 0;
        mus.CHAN[i].MusEffect[0] = 0;
        mus.CHAN[i].MusEffect[1] = 0;
        mus.CHAN[i].MusEffect[2] = 0;
        mus.CHAN[i].MusEffect[3] = 0;

        mus.CHAN[i].MusVibPosition = 0;
        mus.CHAN[i].MusVibWave = 0;
        mus.CHAN[i].MusVibDepth = 0;
        mus.CHAN[i].MusVibSpeed = 0;        
    }

    mus.snd->SetTimerBPM(mus.head.BPM);
    return(0);
}

void _musUpdateFX(MusicEngine& mus, char ch, char fxch) {
    int i;

    switch(mus.CHAN[ch].MusEffect[fxch]) {
    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    //Effect Axy - Volume Slide Update                             
    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    case 0xA:
        if((mus.CHAN[ch].MusVolRate & 0xF0)) {   //slide up
            i = mus.snd->ChannelVol(ch, -1) + (mus.CHAN[ch].MusVolRate >> 4);
            mus.snd->ChannelVol(ch, (i > 64) ? 64:i);
        }
        else {                                 //slide down
            i = mus.snd->ChannelVol(ch, -1) - (mus.CHAN[ch].MusVolRate & 0x0F);
            mus.snd->ChannelVol(ch, (i < 0) ? 0:i);                        
        }
        break;

    }
}

void _musStartFX(MusicEngine& mus, char ch, char fxch) {
    int i;

    switch(mus.CHAN[ch].MusEffect[fxch]) {
    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    //Effect 9xx - Sample Offset                                    [D OR]
    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    case 0x9:
        mus.snd->Offset(ch, mus.CHAN[ch].MusEfxDat[fxch] << 8);
        break;

    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    //Effect Axy - Volume Slide Start
    //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    case 0xA:
        if(mus.CHAN[ch].MusEfxDat[fxch]) {  //Is there a new slide speed?
            mus.CHAN[ch].MusVolRate = mus.CHAN[ch].MusEfxDat[fxch];
            break;
        }

        // No new slide speed, use old volume slide (fine or smooth)
        if((mus.CHAN[ch].MusVolRate & 0xFF00) == 0)
            break;            

        // Old slide was a fine slide, set up a fine slide...
        mus.CHAN[ch].MusEffect[fxch] = 0;
        if((mus.CHAN[ch].MusVolRate & 0xFF00) == 0xA00) { //slide up
            i = mus.snd->ChannelVol(ch, -1) + (mus.CHAN[ch].MusVolRate & 0xF);
            mus.snd->ChannelVol(ch, (i > 64) ? 64:i);
        }
        else {        //slide down
            i = mus.snd->ChannelVol(ch, -1) - (mus.CHAN[ch].MusVolRate & 0xF);
            mus.snd->ChannelVol(ch, (i < 0) ? 0:i);
        }

        break;

    case 0xC:           //Set Volume
        mus.snd->ChannelVol(ch, mus.CHAN[ch].MusEfxDat[fxch]);
        break;

    case 0xD:           //Pattern Break
        mus.MusOff = 2;
        if(mus.Ord < mus.NOO)
            mus.Ord++;
        else
            mus.Ord = 0;

        mus.Pat = mus.OrdTable[mus.Ord];
        mus.Row = 0;
        break;

    case 0xF:           //Set Tempo
        mus.head.Tempo = mus.CHAN[ch].MusEfxDat[fxch];
        mus.TempoCounter = mus.head.Tempo;
        break;

    case 0xE:           //Extended Effects
        switch(mus.CHAN[ch].MusEfxDat[fxch] >> 4) {
        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        //Effect EAx - Fine Volume Slide Up                      (PT ST)[D OR]
        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        case 0xA:
            if(mus.CHAN[ch].MusEfxDat[fxch] & 0x0F)
                mus.CHAN[ch].MusVolRate = (mus.CHAN[ch].MusEfxDat[fxch] & 0x0F) + 0xA00;

            i = mus.snd->ChannelVol(ch, -1) + (mus.CHAN[ch].MusVolRate & 0xF);
            mus.snd->ChannelVol(ch, (i > 64) ? 64:i);

            break;

        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        //Effect EBx - Fine Volume Slide Down                    (PT ST)[D OR]
        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        case 0xB:
            if(mus.CHAN[ch].MusEfxDat[fxch] & 0x0F)
                mus.CHAN[ch].MusVolRate = (mus.CHAN[ch].MusEfxDat[fxch] & 0x0F) + 0xB00;

            i = mus.snd->ChannelVol(ch, -1) - (mus.CHAN[ch].MusVolRate & 0xF);
            mus.snd->ChannelVol(ch, (i < 0) ? 0:i);

            break;
        }
        break;

    case 0x1E:          //Extended Effects 2
        switch(mus.CHAN[ch].MusEfxDat[fxch] >> 4) {
        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        //Effect 1E8x - Set Pan Position                   (PT HT MT ST)[D OR]
        //ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        case 0x8:
            mus.snd->ChannelPan(ch, mus.CHAN[ch].MusEfxDat[fxch] & 0xF);
            break;
        }

        break;
    case 0x1F:          //set BPM
        mus.head.BPM = mus.CHAN[ch].MusEfxDat[fxch];
        mus.snd->SetTimerBPM(mus.head.BPM);
        break;
    }
}

void _musUpdateGDM(MusicEngine& mus) {
    char Event, ch, fxch, temp;
//    char PattJump = 0;                  //0- Can pattern jump, 1- disabled
    char NoteEvent = 0;                 //0- Has no change, 1- Has note change
    char NoNoteFlag = 0;

//    char LoopCounter = 0;               //0- No loop, >0- number of loops left
//    char PattLoop = 0;                  //Pattern row to loop to
//    char PattLoopOff = 0;               //Pattern offset to loop to
//    char CurrentOff = 0;                //Current Offset of row

    if(--mus.TempoCounter) {
        for(ch = 0; ch < mus.MaxChan; ch++)
            for(fxch = 0; fxch < 2; fxch++)
                _musUpdateFX(mus, ch, fxch);
        return;
    }

    for(ch = 0; ch < mus.MaxChan; ch++) {
        mus.CHAN[ch].MusEffect[0] = 0;
        mus.CHAN[ch].MusEffect[1] = 0;
        mus.CHAN[ch].MusEffect[2] = 0;
        mus.CHAN[ch].MusEffect[3] = 0;
    }
    mus.TempoCounter = mus.head.Tempo;

    Event = mus.music[mus.Pat][mus.MusOff++];
    while(Event) {
        ch = Event & 0x1F;
        mus.snd->SetChannel(ch);             //Select channel we're working on

        // Note/Sample Event Ü
        // ßßßßßßßßßßßßßßßßßßß 
        if(Event & 32) {                //Is there a note event?
            NoteEvent = 0;
            NoNoteFlag = 0;
            temp = mus.music[mus.Pat][mus.MusOff++];
            if(temp) {                  //|*|*|*[ NOTE EVENT ]*|*|*|
                NoteEvent = 1;
                temp--;
                mus.CHAN[ch].MusNote = temp & 0xF;
                mus.CHAN[ch].MusOctave = ((temp >> 4) & 0xF);
            }
            temp = mus.music[mus.Pat][mus.MusOff++];
            if(temp) {                  //|*|*|*[ SAMPLE CHANGE EVENT ]*|*|*|
                temp--;
                mus.CHAN[ch].MusSample = temp;
                // update play offs, play end, play loop, if def vol
                
            } //EndNSEvent

            if(NoteEvent) {

                if(mus.sam[mus.CHAN[ch].MusSample].Rate == 0) {
                    NoNoteFlag = 1;
                    mus.CHAN[ch].MusRate = ((PeriodTable[mus.CHAN[ch].MusNote] >> (mus.CHAN[ch].MusOctave & 7)) * 16);
                }
                else {
                    mus.CHAN[ch].MusRate = (((PeriodTable[mus.CHAN[ch].MusNote] >> (mus.CHAN[ch].MusOctave & 7)) * 16 * 8363) / mus.sam[mus.CHAN[ch].MusSample].Rate);
                }
                if(mus.CHAN[ch].MusRate) {
                    mus.CHAN[ch].MusRate = (14317056 / mus.CHAN[ch].MusRate) << 4;
                    mus.snd->PlaySample(ch, mus.CHAN[ch].MusSample, mus.CHAN[ch].MusRate, 0xFF, 0xFF);
                }
            } //WasOnlySample
        }

        // Effect Events Ü
        //  ßßßßßßßßßßßßßß
        if(Event & 64) {            //Is there an Effect event?
            do {
                temp = mus.music[mus.Pat][mus.MusOff++];
                fxch = temp >> 6;
                mus.CHAN[ch].MusEffect[fxch] = temp & 31;
                mus.CHAN[ch].MusEfxDat[fxch] = mus.music[mus.Pat][mus.MusOff++];
                _musStartFX(mus, ch, fxch);
            } while(temp & 32);
        } //BeginEndRowEvent

        Event = mus.music[mus.Pat][mus.MusOff++];
    }

    mus.Row++;

    if(mus.MusOff >= mus.musLen[mus.Pat]) {
        mus.MusOff = 2;
        if(mus.Ord < mus.NOO)
            mus.Ord++;
        else
            mus.Ord = 0;

        mus.Pat = mus.OrdTable[mus.Ord];
        mus.Row = 0;
    }
}
