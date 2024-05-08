//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//                              Sound Blaster
//                           OmniSound Source Code
//                   Copyright (c) 1993-97, Edward Schlunder
// 
//                Written by Edward Schlunder/OverThrowMachine
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
#include "bwsb32.h"
#include "gus.h"

#include <string.h>
#include <dos.h>
#include <pc.h>
#include <iostream.h>

#include <dpmi.h>
#include <sys/segments.h>

const char *Description = "BWSB Music and Sound Engine v1.22 (GUS)\n";
const char *Copyright = "Copyright (c) 1993-97, Edward T. Schlunder\n";
const char *Author = "Written by Edward Schlunder (zilym@aztec.asu.edu)\n";
const char *DeviceName = "Sound Blaster";

//Ä Ultrasound Tables ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
const int GUSVolTable[] = { 0x8800,0x9800,0xA200,0xA800,0xAE00,0xB200,0xB500,
                            0xB800,0xBB00,0xBE00,0xC080,0xC200,0xC380,0xC500,
                            0xC680,0xC800,0xC980,0xCB00,0xCC80,0xCE00,0xCF80,
                            0xD080,0xD140,0xD200,0xD2C0,0xD380,0xD440,0xD500,
                            0xD5C0,0xD680,0xD740,0xD800,0xD8C0,0xD980,0xDA40,
                            0xDB00,0xDBC0,0xDC80,0xDD40,0xDE00,0xDEC0,0xDF80,
                            0xE020,0xE080,0xE0E0,0xE140,0xE1A0,0xE200,0xE260,
                            0xE2C0,0xE320,0xE380,0xE3E0,0xE440,0xE4A0,0xE500,
                            0xE560,0xE5C0,0xE620,0xE680,0xE6E0,0xE740,0xE7A0,
                            0xE800,0xE860 };

//This table is used to figure out what oversampling rate is being used:
const int GUSOverTable[] = { 44100,41160,38587,36317,34300,32494,30870,29400,
                             28063,26843,25725,24696,23746,22866,22050,21289,
                             20580,19916,19293 };

int GUSAddr;                    //Ultrasound's Base I/O Address
char GUSTickerRate;             //GUS's timer rate (We use 80ms*2 Timer)
int MusicStatus;                //0-Music Disabled, 1-Music Enabled
int NeedsTick;
int TickTock;
int FrameFlag;

void endIRQHandler(void);
void IRQHandler(void);
void IRQHandler2(void);

//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
// Auxilary Functions Begin Here
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//             Copyright (c) 1993-97, Edward Schlunder/OverThrowMachine
//                                     Ä-ZLÄ-
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//This does a little delay for the GUS, let's us time things out better..
inline void seGUS::GF1_Delay(void) {
        inportb(GUSAddr+0x103);            
        inportb(GUSAddr+0x103);            
        inportb(GUSAddr+0x103);            
        inportb(GUSAddr+0x103);            
        inportb(GUSAddr+0x103);            
        inportb(GUSAddr+0x103);            
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: UltraSlideRamp
 Calling: Vol       New channel volume to slide to
 Returns: none
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
void seGUS::UltraSlideRamp(int Vol) {
    int CurVol;

    outportb(GUSAddr+0x103, 0xD);       //0Dh - Volume Ramp Control
    outportb(GUSAddr+0x105, 3);         //Manual stop ramp

    outportb(GUSAddr+0x103, 6);         //06h - Volume Ramp Speed
    outportb(GUSAddr+0x105, 0x3F);

    outportb(GUSAddr+0x103, 0x89);      //89h - Get Current Volume
    CurVol = inportw(GUSAddr+0x104) >> 8;
    Vol = Vol >> 8;

    if(CurVol > Vol) {
        outportb(GUSAddr+0x103, 7);     //07h - Volume Ramp Start
        outportb(GUSAddr+0x105, Vol);
        outportb(GUSAddr+0x103, 8);     //08h - Volume Ramp End
        outportb(GUSAddr+0x105, CurVol);

        outportb(GUSAddr+0x103, 0xD);   //0Dh - Volume Ramp Control
        outportb(GUSAddr+0x105, 0x40);  //decreasing ramp
    }
    else {
        outportb(GUSAddr+0x103, 7);     //07h - Volume Ramp Start
        outportb(GUSAddr+0x105, CurVol);
        outportb(GUSAddr+0x103, 8);     //08h - Volume Ramp End
        outportb(GUSAddr+0x105, Vol);

        outportb(GUSAddr+0x103, 0xD);   //0Dh - Volume Ramp Control
        outportb(GUSAddr+0x105, 0);     //increasing ramp
    }
}

void seGUS::SetTimerBPM(int BPM) {
    if(BPM == 0) {
        MusicStatus = 0;
        return;
    }
    else
        MusicStatus = 1;

    if(BPM < 125) {
        GUSTickerRate = -(7813 / BPM);
        NeedsTick = 4;                  //Use all IRQs for 80ms timer
        TickTock = 4;                   //Cut IRQs in half for 160ms timer
    }
    else {
        GUSTickerRate = -(15625 / BPM);
        NeedsTick = 2;                  //Cut IRQs in half for 160ms timer
        TickTock = 2;                   //Cut IRQs in half for 160ms timer
    }
   
    SetUltraTimer1();
}

void seGUS::IRQFree(void) {
    char    pic;

    disable();
    outportb(GUSAddr+0x103, 0x45);      //45h - Timer Control Register
    outportb(GUSAddr+0x105, inportb(GUSAddr+0x105) & 0xFB); //Disable Timer 1 IRQ

    InitGUS();

    outportb(GUSAddr, 8);               //Enable IRQ Latches, Line In/Out

    if(GUSIRQ < 8) {                    //Mask off the GUS IRQ
        pic = inportb(0x21);
        pic = pic | (1 << GUSIRQ);
        outportb(0x21, pic);
    }
    else {
        pic = inportb(0xA1);
        pic = pic | (1 << (GUSIRQ-8));
        outportb(0xA1, pic);
    }

    //Restore old IRQ handler
    _go32_dpmi_set_protected_mode_interrupt_vector(GUSInt, &OldIRQ); //GUSInt
    _go32_dpmi_free_iret_wrapper(&NewIRQ);

    enable();
}

void seGUS::IRQSetup(void) {
    char    pic;

    //First, lock interrupt handler code and data to avoid page faults
    _go32_dpmi_lock_code(&IRQHandler, (unsigned long)(endIRQHandler-IRQHandler));
    _go32_dpmi_lock_data(&FrameFlag, sizeof(FrameFlag));
    _go32_dpmi_lock_data(&TickTock, sizeof(TickTock));
    _go32_dpmi_lock_data(&NeedsTick, sizeof(NeedsTick));
    _go32_dpmi_lock_data(&GUSTickerRate, sizeof(GUSTickerRate));
    _go32_dpmi_lock_data(&GUSAddr, sizeof(GUSAddr));

    //Save old GUS IRQ handler address (if anything)
    _go32_dpmi_get_protected_mode_interrupt_vector(GUSInt, &OldIRQ); //GUSInt

    //Install our shiny new IRQ handler
    NewIRQ.pm_offset = (int)IRQHandler;
    NewIRQ.pm_selector = _my_cs();
    _go32_dpmi_allocate_iret_wrapper(&NewIRQ);
    _go32_dpmi_set_protected_mode_interrupt_vector(GUSInt, &NewIRQ); //GUSInt

    inportb(GUSAddr+6);                 //2x6h - IRQ Status Port
    outportb(GUSAddr, 9);               //Enable IRQ Latches, Disable Line In
    //ÄÄ Clear IRQ Source
    outportb(GUSAddr+0x103, 0x8F);      //8Fh - IRQ Source Register
    inportb(GUSAddr+0x105);

    SetUltraTimer1();                   //Program the GUS to do our stuff

    disable();                          //Unmask the GUS IRQ
    if(GUSIRQ < 8) {
        pic = inportb(0x21);
        pic = pic & ~(1 << GUSIRQ);
        outportb(0x21, pic);
    }
    else {
        pic = inportb(0xA1);
        pic = pic & ~(1 << (GUSIRQ-8));
        outportb(0xA1, pic);
    }
    enable();

    outportb(GUSAddr+8, 4);             //Select timer stuff - AdLib thang
    outportb(GUSAddr+9, 0x80);          //Reset Timer IRQs
}

void IRQHandler(void) {
    outportb(GUSAddr+0x103, 0x46);      //46h - Timer 1 Count
    outportb(GUSAddr+0x105, GUSTickerRate);
    outportb(GUSAddr+0x103, 0x45);      //45h - Timer Control
    outportb(GUSAddr+0x105, 4);         //Enable Timer 1 IRQ
    outportb(GUSAddr+8, 4);             //2x8h - Timer Control Reg (AdLib Control)
    outportb(GUSAddr+9, 1);             //1h - Timer 1 Start (80ms timer)

    outportb(GUSAddr+0x103, 0x45);      //45h - Timer Control
    outportb(GUSAddr+0x105, 0);         //Disable Timer IRQs
    outportb(GUSAddr+0x105, 4);         //Enable Timer 1 IRQ (80ms timer)

    if(--TickTock == 0) {
        TickTock = NeedsTick;

        if(MusicStatus)
            UpdateMusic();
        FrameFlag++;
    }

    outportb(0x20, 0x20);               //End of Interrupt
    outportb(0xA0, 0x20); 
}

void endIRQHandler(void) {       //Dummy routine for IRQHandler locking
    return;
}

void seGUS::SetUltraTimer1(void) {
    outportb(GUSAddr+0x103, 0x46);      //46h - Timer 1 Count
    outportb(GUSAddr+0x105, GUSTickerRate);
    outportb(GUSAddr+0x103, 0x45);      //45h - Timer Control
    outportb(GUSAddr+0x105, 4);         //Enable Timer 1 IRQ

    outportb(GUSAddr+8, 4);             //2x8h - Timer Control Reg (AdLib Control)
    outportb(GUSAddr+9, 1);             //1h - Timer 1 Start (80ms timer)
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_Poke
 Calling: Addr    - address to poke data to
          Sample  - data to poke into DRAM
 Returns: FCTVAL  - read back data
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
inline int seGUS::u_Poke(long Loc, unsigned char Sample) {
    outportb ( GUSAddr+0x103, 0x43 );   //DRAM I/O Address (LOW)
    outportw ( GUSAddr+0x104, (unsigned short)Loc & 0x0000FFFF);
    outportb ( GUSAddr+0x103, 0x44 );   //DRAM I/O Address (HIGH)
    outportb ( GUSAddr+0x105, (unsigned char)( (Loc & 0x00FF0000) >> 16 ) ); 
    outportb ( GUSAddr+0x107, Sample );
    return ( inportb(GUSAddr+0x107) );
}

void seGUS::u_Pokei(long Loc, unsigned int Sample) {
    for(int i = 0; i < 4; i++) {       
        u_Poke(Loc + i, (char)((Sample>>(i*8)) & 0xFF));
    }
}

unsigned int seGUS::u_Peeki(long Loc) {
    unsigned int Temp = 0;

    for(int i = 0; i < 4; i++) {
        Temp += (u_Peek(Loc + i) & 0xFF) << (i*8);
    }

    return(Temp);
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_Peek
 Calling: Addr   - address to peek data from
 Returns: FCTVAL - read back data
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
char seGUS::u_Peek(long Loc) {
    outportb(GUSAddr+0x103, 0x43);      //DRAM I/O Address (LOW)
    outportw(GUSAddr+0x104, Loc & 0x0000FFFF);
    outportb(GUSAddr+0x103, 0x44);      //DRAM I/O Address (HIGH)
    outportb(GUSAddr+0x105, (Loc & 0x00FF0000) >> 16); 

    return(inportb(GUSAddr+0x107));
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: u_MemSize
 Calling: none
 Returns: FCTVAL - UltraSound DRAM size:
                   256, 512, 768, 1024
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
int seGUS::u_MemSize(void) {
    int i;
    char t;

    for(i = 0; i < 1048576; i += 262144) {
        t = u_Peek(i);
        if(u_Poke(i, 0xAA) != 0xAA)
            break;
        else
            u_Poke(i, t);
    }

    return(i);
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PreInitGUS
 Calling: none
 Returns: none
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
void seGUS::PreInitGUS(void) {
    char GUSChangeIRQ[] = { 0,0,1,3,0,2,0,4,0,0,0,5,6,0,0,7 };
    char GUSChangeDMA[] = { 1,0,2,0,3,4,5 };
    char cl, bl;

    disable();

    if(GUSIRQ == GUSIRQMidi)            //Sharing IRQs?
        cl = GUSChangeIRQ[GUSIRQ] | 0x40;   //Use only GF1 IRQ (sharing IRQs)
    else
        cl = GUSChangeIRQ[GUSIRQ] + (GUSChangeIRQ[GUSIRQMidi] << 3);

    if(GUSDMA == GUSDMARecord)
        bl = GUSChangeDMA[GUSDMARecord] | 0x40; //Use only Record DMA (sharing DMAs)
     else
        bl = GUSChangeDMA[GUSDMARecord] + (GUSChangeDMA[GUSDMA] << 3);

    outportb(GUSAddr, 8);               //8h - Set DMA Control
    outportb(GUSAddr+0xB, bl | 0x80);   //Write new DMA channels
    outportb(GUSAddr, 0x48);            //48h - Set IRQ Control
    outportb(GUSAddr+0xB, cl);          //write new IRQ levels

    outportb(GUSAddr, 8);               //8h - Set DMA Control
    outportb(GUSAddr+0xB, bl);          //Write new DMA channels
    outportb(GUSAddr, 0x48);            //48h - Set IRQ Control
    outportb(GUSAddr+0xB, cl);          // write new IRQ levels

    outportb(GUSAddr+0x102, 0);
    outportb(GUSAddr+0x102, 0);

    enable();
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: InitGUS
 Calling: none
 Returns: none
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
void seGUS::InitGUS(void) {
        //ÄÄ Setup little helper registers
        int bx = GUSAddr+0x103;         //3x3h - Global/GF1 Register Select
        int cx = GUSAddr+0x105;         //3x5h - Data High Port

        //ÄÄ Do a GUS global reset
        outportb(bx, 0x4C);             //4Ch - Reset Register
        outportb(cx, 0);                //GF1 Master Reset, DAC Off, IRQs Off
        GF1_Delay();
        GF1_Delay();

        outportb(bx, 0x4C);             //4Ch - Reset Register
        outportb(cx, 1);                //GF1 Master Reset Run
        GF1_Delay();
        GF1_Delay();

        //ÄÄ GUS MIDI Reset (3x0h - MIDI Control Port)
        outportb(GUSAddr+0x100, 3);     //Toggle high......
        GF1_Delay();
        outportb(GUSAddr+0x100, 0);     //then toggle low
        GF1_Delay();

        //ÄÄ GUS DMA Reset
        outportb(bx, 0x41);             //41h - DMA Control Register
        outportb(cx, 0);                //DMA Off, Write, 8Bit, 650KHz, IRQ Off, 8Bit, Unsigned

        //ÄÄ GUS DRAM Heap Init
        GUSTotalMemory = u_MemSize();

        //-=-=-=-=-DO I REALLY NEED THIS??=-=-=-==-=-=
        u_Pokei(0, GUSTotalMemory - 4); //mark memory block as unused

        //ÄÄ GUS DRAM Address
        outportb(bx, 0x44);             //44h - Set DRAM Address MSB
        outportb(cx, 0);                //Start back at 0
        outportb(bx, 0x43);             //43h - Set DRAM Address LSB
        outportw(bx+1, 0);

        //ÄÄ GUS Timer
        outportb(GUSAddr+9, 0x80);      //Reset Timer IRQ
        outportb(GUSAddr+9, 0);

        outportb(bx, 0x46);             //46h - Timer 1 Count
        outportb(cx, 0);                //Set 0FFh count

        outportb(bx, 0x47);             //47h - Timer 2 Count
        outportb(cx, 0);                //Set 0FFh count

        outportb(bx, 0x45);             //45h - Timer Control Register
        outportb(cx, 0);                //Disable 80ms and 320ms timers

        //ÄÄ GUS Active Voices
        outportb(GUSAddr+0x103, 0xE);   //0Eh - Set Active Voices
        outportb(GUSAddr+0x105, NumChannels - 1 | 0xC0);

        OverRate = GUSOverTable[(NumChannels < 14) ? 0:NumChannels-14];

        //ÄÄ GUS Recording
        outportb(bx, 0x49);             //49h - Sampling Control Register
        outportb(cx, 0);                //Disable GUS sampling

        //ÄÄ Clear IRQs
        inportb(GUSAddr+6);             //2x6h - IRQ Status Port

        //ÄÄ Clear DMA Control
        outportb(bx, 0x41);             //41h - DMA Control Register
        inportb(cx);

        //ÄÄ Clear Sampling Control
        outportb(bx, 0x49);             //49h - Sampling Control Register
        inportb(cx);

        //ÄÄ Clear IRQ Source
        outportb(bx, 0x8F);             //8Fh - IRQ Source Register
        inportb(cx);

        //ÄÄ Initialize all channels
        for(int i = 0; i < 32; i++) {
                outportb(GUSAddr+0x102, i);     //3x2h - GUS Page Register
                outportb(bx, 0);        //00h - Channel control
                outportb(cx, 3);        //Turn this channel off!

                outportb(bx, 0xD);      //0Dh - Volume Ramp Control
                outportb(cx, 3);        //Turn off the volume ramp
        }

        //ÄÄ Clear DMA Control
        outportb(bx, 0x41);
        inportb(cx);        

        //ÄÄ Clear Sampling Control
        outportb(bx, 0x49);             //49h - Sampling Control Register
        inportb(cx);

        //ÄÄ Clear IRQ Source
        outportb(bx, 0x8F);             //8Fh - IRQ Source Register
        inportb(cx);

        //ÄÄ Global Reset
        outportb(bx, 0x4C);             //4Ch - GF1 Reset Register
        outportb(cx, 7);                //Enable GF1, DAC Output, and Master IRQ

        for(int i = 0; i < 32; i++) {
                outportb(GUSAddr+0x102, i);     //3x2h - Page Register

                //ÄÄ Set Volume Ramp Rate
                outportb(bx, 0x6);      //Volume Ramp Rate Register
                outportb(cx, 0x3F);     //Do a Fast Ramp(tm)!

                //ÄÄ Set Current Volume
                outportb(bx, 0x9);      //Current Volume Register
                outportw(bx+1, 0);
                GF1_Delay();
                outportw(bx+1, 0);
        }
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: CheckGUS
 Calling: GUSAddr   GUS base I/O address to check for GUS existance
 Returns: FCTVAL    Nonzero if GUS not found, zero if is working properly
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
int seGUS::CheckGUS(void) {
        char temp;

        //ÄÄ GUS DRAM Address
        outportb(GUSAddr+0x103, 0x44);          //44h - Set DRAM Address MSB
        outportb(GUSAddr+0x105, 0);             //Start back at 0
        outportb(GUSAddr+0x103, 0x43);          //43h - Set DRAM Address LSB
        outportw(GUSAddr+0x104, 0);

        temp = inportb(GUSAddr + 0x107);        //DRAM I/O Address
        outportb(GUSAddr+0x107, 0x40);          //write test value
        if(inportb(GUSAddr+0x107) != 0x40) {
                return(-1);
        }

        outportb(GUSAddr + 0x107, 0x80);        //write another test value
        if(inportb(GUSAddr + 0x107) != 0x80) {
                return(-1);
        }

        outportb(GUSAddr + 0x107, temp);        //restore old memory value
        return(0);
}

//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
// Class Member Functions Begin Here
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//             Copyright (c) 1993-97, Edward Schlunder/OverThrowMachine
//                                     Ä-ZLÄ-
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
int seGUS::Status(void) {
        return(ErrStatus);
}

const char *seGUS::DevName(void) {
        return(DeviceName);
}

int seGUS::DevAddr(void) {
        return(GUSAddr);
}

int seGUS::DevIRQ(void) {
        return(GUSIRQ);
}

int seGUS::DevDMA(void) {
        return(GUSDMA);
}

seGUS::seGUS(void) {
        seGUS(0x240, 5, 7, 5, 5);
}

seGUS::seGUS(short Addr, char IRQ, char IRQ2, char DMA, char DMA2) {
        GUSAddr = Addr;
        GUSIRQ = IRQ;
        GUSIRQMidi = IRQ2;
        GUSDMA = DMA;
        GUSDMARecord = DMA2;
        GUSInt = (GUSIRQ < 8) ? (GUSIRQ+8) : (GUSIRQ+0x68);
        NumChannels = 14;

        InitGUS();                      //Kick GUS into a known state
        if(CheckGUS()) {
                ErrStatus = seRESPOND;  //Sound card doesn't respond error.
                return;
        }

        PreInitGUS();                   //Set up IRQ/DMA Select Ports
        InitGUS();                      //Kick GUS into a known state
        PreInitGUS();                   //Set up IRQ/DMA Select Ports
        InitGUS();                      //Kick GUS into a known state

        outportb(GUSAddr, 9);           //Enable IRQ Latches, Disable Line In

        GUSMemoryUsed = 0;
        OutputStatus = 0;               //Disable output flag
        MusicStatus = 0;
        MasterVol = 64;
        FrameFlag = 0;

        for(int i = 0; i < 32; i++)
            VU[i] = 0;

        ErrStatus = seOKAY;
}

int seGUS::AllocSample(int SamNum, SampleInfo SamHead) {
    unsigned long i, l;

        strcpy(SAM[SamNum].SamName, SamHead.SamName);
        strcpy(SAM[SamNum].SamFileName, SamHead.FileName);
        SAM[SamNum].SamLen = SamHead.Length;
        SAM[SamNum].SamBegin = SamHead.LoopBegin;
        SAM[SamNum].SamEnd = SamHead.LoopEnd;
        SAM[SamNum].SamFlags = SamHead.Flags;
        SAM[SamNum].SamTune = SamHead.Rate;
        SAM[SamNum].SamVol = SamHead.Volume;
        SAM[SamNum].SamPan = SamHead.Pan;

        if(SAM[SamNum].SamLen == 0)
            return(0);

        unsigned int temp;
        for(long loc = 0; loc < GUSTotalMemory; loc += temp+4) {
            temp = u_Peeki(loc) % 0x80000000;
            if(!(u_Peeki(loc) >> 31) && (temp >= SamHead.Length)) {
                u_Pokei(loc+SamHead.Length+5, u_Peeki(loc) - SamHead.Length - 5);
                u_Pokei(loc, (SamHead.Length+1) | 0x80000000);
                SAM[SamNum].GUSAddress = loc+4;
                break;
            }
        }

        if((SAM[SamNum].GUSAddress + SamHead.Length) >> 16 == SAM[SamNum].GUSAddress >> 16) {
            outportb ( GUSAddr+0x103, 0x44 );   //DRAM I/O Address (HIGH)
            outportb ( GUSAddr+0x105, SAM[SamNum].GUSAddress >> 16); 
            outportb ( GUSAddr+0x103, 0x43 );   //DRAM I/O Address (LOW)
            for(i = 0; i < SamHead.Length; i++) {
                outportw ( GUSAddr+0x104, (SAM[SamNum].GUSAddress+i) & 0x0000FFFF);
                outportb ( GUSAddr+0x107, SamHead.Sample[i] ^ 128);
            }
        }
        else {
            for(i = 0; i < SamHead.Length; i++) {
                l = SAM[SamNum].GUSAddress + i;
                outportb ( GUSAddr+0x103, 0x43 );   //DRAM I/O Address (LOW)
                outportw ( GUSAddr+0x104, l & 0x0000FFFF);
                outportb ( GUSAddr+0x103, 0x44 );   //DRAM I/O Address (HIGH)
                outportb ( GUSAddr+0x105, l >> 16); 
                outportb ( GUSAddr+0x107, SamHead.Sample[i] ^ 128);
            }
        }
        
        u_Poke(SAM[SamNum].GUSAddress + i, SamHead.Sample[i-1] ^ 128);

        return(seOKAY);
}

void seGUS::CleanMemory(void) {
        int temp, temp2;

        for(long loc = 0; loc < GUSTotalMemory; loc += temp + 4) {
            temp = u_Peeki(loc) % 0x80000000;
            if(!(u_Peeki(loc) >> 31) && ((loc+temp+4) < GUSTotalMemory)) {
                temp2 = u_Peeki(loc+temp+4) % 0x80000000;
                if(!(u_Peeki(loc + temp + 4) >> 31)) {
                    u_Pokei(loc, temp + temp2 + 4);

                    CleanMemory();
                    break;
                }
            }
        }
}

void seGUS::FreeSample(int S) {
        u_Pokei(SAM[S].GUSAddress-4, SAM[S].SamLen);
        SAM[S].SamLen = 0;

        CleanMemory();
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: PlaySample                                                
 Calling: Ch      Channel number (1..32)
          Sam     Sample number (0..255)
          Rate    Sampling rate (4000..65535)
          Vol     Volume for playback
          Pan     Pan position to start with
 Returns: none
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
void seGUS::PlaySample(char Ch, int Sam, int Rate, char Vol, char Pan) {
    int TempLoc;

    if(Rate == 0xFFFF)
        Rate = SAM[Sam].SamTune;
    if(Vol == -1)
        Vol = SAM[Sam].SamVol;
    if(Pan == -1)
        Pan = SAM[Sam].SamPan;

    if(SAM[Sam].SamLen == 0)
        return;

        CHAN[Ch].MixInc = 0;
        CHAN[Ch].MixIncRemain = 0;
        CHAN[Ch].MixOff = 0;
        CHAN[Ch].Sample = Sam;

//        ChannelPan(Ch, 8); //Pan);
        ChannelVol(Ch, Vol);

        outportb(GUSAddr+0x102, Ch);  //Set current channel number
        outportb(GUSAddr+0x103, 1);   //01h - GF1 Sample Increment (Freq)
        outportw(GUSAddr+0x104, (Rate << 10) / OverRate);
        CHAN[Ch].MixInc = (Rate << 10) / OverRate;
        
        CHAN[Ch].GUSAddress = SAM[Sam].GUSAddress;
        CHAN[Ch].MixFlags = SAM[Sam].SamFlags;
        if(CHAN[Ch].MixFlags & 1) {
            CHAN[Ch].MixLBeg = SAM[Sam].SamBegin;
            CHAN[Ch].MixLEnd = SAM[Sam].SamEnd;
            TempLoc = (CHAN[Ch].MixLBeg + CHAN[Ch].GUSAddress) << 9;
            outportb(GUSAddr+0x103, 3);     //03h - Starting Location LSW
            outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
            outportb(GUSAddr+0x103, 2);     //02h - Starting Location MSW
            outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);
        }
        else
            CHAN[Ch].MixLEnd = SAM[Sam].SamLen;

        TempLoc = (CHAN[Ch].MixLEnd + CHAN[Ch].GUSAddress) << 9;
        outportb(GUSAddr+0x103, 5);     //05h - End Location LSW
        outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
        outportb(GUSAddr+0x103, 4);     //04h - End Location MSW
        outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);

        TempLoc = CHAN[Ch].GUSAddress << 9;
        outportb(GUSAddr+0x103, 0xB);   //0Bh - Current Location LSW
        outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
        GF1_Delay();
        outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
        outportb(GUSAddr+0x103, 0xA);   //0Ah - Current Location MSB
        outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);
        GF1_Delay();
        outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);

        outportb(GUSAddr+0x103, 0);     //00h - Write Voice Control Register
        outportb(GUSAddr+0x105, (CHAN[Ch].MixFlags & 1) << 3);
        GF1_Delay();
        outportb(GUSAddr+0x105, (CHAN[Ch].MixFlags & 1) << 3);

}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelVol
 Calling: Vol     New volume setting (0..64). FFh=no set
          Ch      Channel number (1..32)
 Returns: FCTVAL  Channel's volume setting (0..64)
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
int seGUS::ChannelVol(char Ch, char Vol) {
    if(Vol == -1) {
        return(CHAN[Ch].MixVolume);
    }

    CHAN[Ch].MixVolume = Vol;
    VU[Ch] = Vol >> 1;

    CHAN[Ch].MixMonoVol = (Vol * MasterVol) >> 6; //save relative volume

    outportb(GUSAddr+0x102, Ch);
    outportb(GUSAddr+0x103, 0x89);      //89h - GF1 Current Volume
    if(inportw(GUSAddr+0x104) != GUSVolTable[CHAN[Ch].MixMonoVol])
        UltraSlideRamp(GUSVolTable[CHAN[Ch].MixMonoVol]);

    return(CHAN[Ch].MixVolume);
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: ChannelPan
 Calling: Pan     New pan setting (0..15). FFh=no set
          Ch      Channel number (1..32)
 Returns: FCTVAL  Channel's volume setting (0..64)
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
char seGUS::ChannelPan(char Ch, char Pan) {
//    if(Pan == -1) {
//        return(CHAN[Ch].MixPanning);
//    }

    CHAN[Ch].MixPanning = Pan;

    outportb ( GUSAddr+0x102 , Ch );
    outportb ( GUSAddr+0x103 , 0x0C );
    outportb ( GUSAddr+0x105 , Pan );

    return(CHAN[Ch].MixPanning);
}

unsigned int seGUS::GUSLoc(char Ch) {
    unsigned int TempLoc;

        outportb ( GUSAddr+0x102 , Ch );

        outportb(GUSAddr+0x103, 0x8A);   //8Ah - Current Location MSW
        TempLoc = (inportw(GUSAddr+0x104) & 0x1FFF) << 16;
        outportb(GUSAddr+0x103, 0x8B);   //8Bh - Current Location LSW
        TempLoc += inportw(GUSAddr+0x104);
 
    return(TempLoc >> 9);
}

void seGUS::SetChannel(char Ch) {
    outportb(GUSAddr+0x102, Ch);
}

long seGUS::MixInc(char Ch) {
    outportb(GUSAddr+0x102, Ch);        //Set current channel number
    outportb(GUSAddr+0x103, 0x80);      //80h - GF1 Voice Control Register
    if(inportb(GUSAddr+0x105) & 1)
        return(0);

    outportb(GUSAddr+0x103, 0x81);      //81h - GF1 Sample Increment (Freq)
    return((inportw(GUSAddr+0x104) & 0xFFFE) << 6);
}

void seGUS::MixInc(char Ch, long NewInc) {
    outportb(GUSAddr+0x102, Ch);        //Set current channel number
    outportb(GUSAddr+0x103, 0x01);      //01h - GF1 Sample Increment (Freq)
    outportw(GUSAddr+0x104, NewInc >> 6);
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: Offset                                                
 Calling: Ch      Channel number (1..32)
          Offs    New Sample Offset
 Returns: none
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
void seGUS::Offset(char Ch, unsigned long Offs) {
    int TempLoc;

    if(SAM[CHAN[Ch].Sample].SamLen < Offs)
        Offs = SAM[CHAN[Ch].Sample].SamLen;

    CHAN[Ch].MixOff = Offs;

    outportb(GUSAddr+0x102, Ch);  //Set current channel number
        
    TempLoc = (CHAN[Ch].GUSAddress + Offs) << 9;
    outportb(GUSAddr+0x103, 0xB);   //0Bh - Current Location LSW
    outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
    GF1_Delay();
    outportw(GUSAddr+0x104, TempLoc & 0xFFFF);
    outportb(GUSAddr+0x103, 0xA);   //0Ah - Current Location MSB
    outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);
    GF1_Delay();
    outportw(GUSAddr+0x104, (TempLoc >> 16) & 0xFFFF);
}

/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Routine: Offset                                                
 Calling: Ch      Channel number (1..32)
 Returns: FCTVAL  offset
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
long seGUS::Offset(char Ch) {
    int TempLoc;

    outportb(GUSAddr+0x102, Ch);  //Set current channel number
    outportb(GUSAddr+0x103, 0x8B);   //0Bh - Current Location LSW
    TempLoc = inportw(GUSAddr+0x104);

    outportb(GUSAddr+0x103, 0x8A);   //0Ah - Current Location MSB
    TempLoc += inportw(GUSAddr+0x104) << 16;

    return((TempLoc >> 9) - CHAN[Ch].GUSAddress);
}

void seGUS::Channels(char Ch) {
    NumChannels = Ch;
    if(Ch < 14)
        Ch = 14;

    outportb(GUSAddr+0x103, 0xE);   //0Eh - Set Active Voices
    outportb(GUSAddr+0x105, Ch - 1 | 0xC0);

    OverRate = GUSOverTable[(Ch < 14) ? 0:Ch-14];
}

int seGUS::Channels(void) {
    return(NumChannels);
}

//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
// DMA Buffer Allocation Routine Begins Here
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//    Copyright (C) 1993-94, Edward Schlunder. Written by Edward Schlunder
//                                     Ä-ZLÄ-
//ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
//Calling:
//       pages   Number of pages long the buffer should be
//
//Returning:
//       Carry   Set if error
#include <dpmi.h>

int dmaSel;
int dmaSeg;

int AllocDMABuffers(int pages) {


    __dpmi_allocate_dos_memory(pages << 1, &dmaSel);

}
    Shl     bx, 1                      ;Multiple by 2 for DMA boundary free
    Mov     ax, 4800h                  ;Allocate memory
    Int     21h
    Jc      Short Exit                 ;Something went wrong on alloc, abort

    Mov     cx, Word PTR cs:BufferLen
FindBuffLoop:
    Mov     dx, ax
    Shl     dx, 4                      ;Lower 12 bits of segment are DMA address
    Neg     dx                         ;65536 - Off#1 = Maximum len of #1
    Cmp     dx, cx
    Ja      Short @F
    Inc     ax
    Jmp     FindBuffLoop

@@: Mov     BufferSegment, ax          ;Save the segment address of buffer
    Mov     bx, Word PTR cs:BufferLen
    Mov     ds, ax
FillBufLoop:
    Mov     Byte PTR ds:[bx-1], 7Fh
    Dec     bx
    Jnz     FillBufLoop
    Clc

Exit:
    Ret
AllocDMABuffers     EndP


