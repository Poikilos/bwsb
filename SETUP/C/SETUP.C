/*                                                                         */
/* SETUP.C - MSE setup program for BWSB                                    */
/*           Written by Edward Schlunder (1994-95)                         */
/*                                                                         */
/* You may freely include this program along with your programs so long as */
/* the original copyrights remain intact.                                  */
/*                                                                         */

extern void InitVideo(void);
extern char VGAPresent(void);
extern void NewBlue(void);
extern void OldBlue(void);

/* Declare all the BWSB subs and functions: */
#include <..\include\bwsb.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <dos.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>

unsigned long OverLoad(char *FileName, int FileHandle);

void TestSound(char *ExeName);
void SelectSoundQuality(void);
void SelectSoundCard(void);
void SelectSoundSettings(void);

int PopUpMenu(char CurItem, char Row, char Col, char Items, char CharsWide, char *MenuHelp[]);

/* ÄÄÄ  Setup screens  ÄÄ> */
#include "screen.h"

/* ÄÄÄ  Direct screen read/write functions  ÄÄ> */
#include "print.h"

typedef struct {
  unsigned int SoundCard;
  unsigned int BaseIO;
  unsigned int IRQ;
  unsigned int DMA;
  unsigned int SoundQuality;
} MSEConfigFile;

MSEConfigFile MSEConfig;

char *Copyright = { " BWSB Music and Sound Engine Setup      Copyright (c) 1993-95, Edward Schlunder" };

void main(int argc, char *argv[]) {
   char *MainHelp[10] = {
     "Select Sound Card for digital music and sound effects",
     "Select Sound Card configuration settings (Address, IRQ number, DMA channel)",
     "Select sound quality level",
     "Load MSE and try playing music",
     "Exit and save new setup" };

   char *SoundCards[] = { "NONE (Silence)   ",
                          "Gravis UltraSound",
                          "Sound Blaster 1.x",
                          "Sound Blaster 2.x",
                          "Sound Blaster Pro",
                          "Sound Blaster 16 ",
                          "Pro AudioSpectrum" };
   char *SndQuality[] = { "Medium Sound Quality    ",
                          "High Sound Quality      ",
                          "Super-High Sound Quality",
                          "Low Sound Quality       " };
  char CurMain = 0;
  int temp, temp2;

  InitVideo();
  if (VGAPresent()) NewBlue();
  MSEConfig.SoundCard = 0;              /* Sound Card: None */
  MSEConfig.SoundQuality = 0;           /* Medium sound quality */
  MSEConfig.BaseIO = 0xFFFF;
  MSEConfig.IRQ = 0xFF;
  MSEConfig.DMA = 0xFF;                 /* Autodetect sound card setup */

  temp = open("MSE.CFG", O_RDONLY | O_BINARY);
  if (temp != -1) read(temp, &MSEConfig, sizeof (MSEConfig));
  close(temp);

  _setcursortype(_NOCURSOR);            /* Now you see cursor, now you don't */

  for(;;) {
     MainMenu(0, 0);                    /* Put up the main screen */
     textattr(0x71); gotoxy(1, 1); cprintf("%s", Copyright);

     textattr(0x78);
     gotoxy(51, 6); cprintf("%s", SoundCards[MSEConfig.SoundCard]);
     gotoxy(53, 7); if (MSEConfig.BaseIO == 0xFFFF) cprintf("FFF");
                       else cprintf("%X", MSEConfig.BaseIO);
     gotoxy(59, 7); if (MSEConfig.IRQ < 16) cprintf("%-u", MSEConfig.IRQ);
                       else cprintf("FF");
     gotoxy(64, 7); cprintf("%X", MSEConfig.DMA);
     gotoxy(51, 8); cprintf("%s", SndQuality[MSEConfig.SoundQuality]);

     CurMain = temp = PopUpMenu(CurMain, 6, 3, 5, 27, MainHelp);

     switch (temp) {
       case 0: SelectSoundCard();       /* Select sound card */
               break;
       case 1: SelectSoundSettings();   /* Select sound settings */
               break;
       case 2: SelectSoundQuality();    /* Select sound quality */
               break;
       case 3: TestSound(argv[0]);      /* Test out the sound engine */
               break;
       case 4:                          /* Save configuration */
               temp2 = open("MSE.CFG", O_CREAT | O_WRONLY | O_BINARY, S_IREAD | S_IWRITE);
               write(temp2, &MSEConfig, sizeof(MSEConfig));
               close(temp2);
               textattr(0x07);
               clrscr();
               printf("New configuration saved.\n\n");
               _setcursortype(_NORMALCURSOR);
               if (VGAPresent()) OldBlue();
               exit(1);
       case -1:
               textattr(0x07);
               clrscr();
               printf("Setup aborted by user, new configuration not saved.\n");
               _setcursortype(_NORMALCURSOR);
               if (VGAPresent()) OldBlue();
               exit(1);
     }
  }
}

int PopUpMenu(char CurItem, char Row, char Col, char Items, char CharsWide, char *MenuHelp[]) {
  char Key;

  textattr(0x78); gotoxy(1, 25);
  cprintf("%s", MenuHelp[CurItem]); clreol();

  Locate(Row + CurItem, Col);
  XColor(0, 7); XColorFill(CharsWide);

  for(;;) {
    Key = getch();
    if (Key != 0)
     switch(Key) {
       case 13:                           /* Enter key */
        Locate(Row + CurItem, Col);
        XColor(15, 1); XColorFill(CharsWide);
        return(CurItem);
       case 27:                           /* Escape key */
        Locate(Row + CurItem, Col);
        XColor(15, 1); XColorFill(CharsWide);
        return(-1);
     }
    else
     switch(getch()) {
        case 72:                            /* Up key */
         if (CurItem > 0) {
            Locate(Row + CurItem, Col);
            XColor(15, 1); XColorFill(CharsWide);
            CurItem--;
            Locate(Row + CurItem, Col);
            XColor(0, 7); XColorFill(CharsWide);

            textattr(0x78); gotoxy(1, 25);
            cprintf("%s", MenuHelp[CurItem]); clreol();
         }
         break;
        case 80:                          /* Down key */
         if (CurItem < Items - 1) {
            Locate(Row + CurItem, Col);
            XColor(15, 1); XColorFill(CharsWide);
            CurItem++;
            Locate(Row + CurItem, Col);
            XColor(0, 7); XColorFill(CharsWide);

            textattr(0x78); gotoxy(1, 25);
            cprintf("%s", MenuHelp[CurItem]); clreol();
         }
     }
  }
}

void SelectSoundCard(void)
{  char *MenuHelp[] = {
   "Select this if you don't have a sound card or don't want any sound",
   "Gravis UltraSound, GUS MAX, or GUS ACE from Advanced Gravis, Ltd.      -Stereo-",
   "Sound Blaster 1.xx or 100% compatibles                                 - Mono -",
   "Sound Blaster 2.xx or 100% compatibles                                 - Mono -",
   "Sound Blaster Pro or 100% compatibles                                  -Stereo-",
   "Sound Blaster 16 from Creative Labs                                    -Stereo-",
   "Pro AudioSpectrum or 100% compatibles (SoundMan 16)                    -Stereo-" };
   char temp;

    SoundCardMenu(8, 24);
    temp = PopUpMenu(0, 12, 27, 7, 25, MenuHelp);
    if (temp != -1) MSEConfig.SoundCard = temp;
    if (MSEConfig.SoundCard == 6)        /* Is this a PAS? */
      MSEConfig.BaseIO = 0xFFFF;         /* don't force base i/o if PAS */
    if (MSEConfig.SoundCard == 1)        /* Is this a GUS? */
      MSEConfig.SoundQuality = 2;        /* use highest sound quality */
}

void SelectSoundSettings(void)
{  char *MenuHelp[9] = {
   "Select this if you are unsure what your setting is or your setting isn't listed",
   " ", " ", " ", " ", " ", " ", " ", " " };
   unsigned int IRQTable[] = { 0xFF, 2, 5, 7, 10, 11, 12, 15 };
   unsigned int DMATable[] = { 0xFF, 0, 1, 3, 5, 6, 7 };
   char temp;

   if (MSEConfig.SoundCard == 6)        /* Is this a PAS? */
     MSEConfig.BaseIO = 0xFFFF;         /* don't ask for base i/o if PAS */
   else {
     BaseioMenu(8, 24);
     temp = PopUpMenu(0, 12, 27, 9, 25, MenuHelp);
     if (temp == -1) return;
     if (temp == 0) MSEConfig.BaseIO = 0xFFFF;
       else MSEConfig.BaseIO = 0x200 + temp * 0x10;
   }

   IRQMenu(8, 24);               /* Display the IRQ menu */
   gotoxy(25, 23); textattr(0x08); cprintf("²²²²²²²²²²²²²²²²²²²²²²²²²²²²²");
   temp = PopUpMenu(0, 12, 27, 8, 25, MenuHelp);
   if (temp == -1) return;
   MSEConfig.IRQ = IRQTable[temp];

   DMAMenu(8, 24);               /* Display the DMA menu */
   gotoxy(25, 22); textattr(0x08); cprintf("²²²²²²²²²²²²²²²²²²²²²²²²²²²²²");
   temp = PopUpMenu(0, 12, 27, 7, 25, MenuHelp);
   if (temp == -1) return;
   MSEConfig.DMA = DMATable[temp];
}

void SelectSoundQuality(void)
{  char *MenuHelp[] = {
   "Medium Sound Quality, for slow 386s                                 (16000 Hz)",
   "High Sound Quality, for fast 386s/slow 486s                         (22000 Hz)",
   "Super-High Sound Quality, for fast 486s                             (45000 Hz)",
   "Low Sound Quality, use this if none of the above work on your system (8000 Hz)" };
   char temp;

   QualityMenu(10, 25);                 /* Pop up our Super High Quality Menu! */
   temp = PopUpMenu(0, 14, 28, 4, 25, MenuHelp);
   if (temp != -1) MSEConfig.SoundQuality = temp;
}

typedef struct {
  char FileName[12];
  unsigned long FileLoc;
  unsigned long FileSize;
} OLHeader;

typedef struct {
  char ID[10];
  unsigned char Entries;
  unsigned long Location;
} OLEnd;

unsigned long OverLoad(char *FileName, int FileHandle) {
  OLHeader Header;
  OLEnd EndHeader;
  int j;

  lseek(FileHandle, -15, SEEK_END);

  read(FileHandle, &EndHeader, sizeof(OLEnd));
  if (strnicmp(EndHeader.ID, "OverLoader", 10) != 0) {
     printf("Couldn't find OverLoader ID header\n");
     getch();
     return(0);
  }

  lseek(FileHandle, EndHeader.Location - 1, SEEK_SET);

  for (j = 1; j <= EndHeader.Entries; j++) {
     read(FileHandle, &Header, sizeof(OLHeader));
     if (strnicmp(Header.FileName, FileName, 12) == 0) goto FoundFile;
  }
  return(0);

  FoundFile:
  lseek(FileHandle, Header.FileLoc - 1, SEEK_SET);
  return(Header.FileSize);
}

void TestSound(char *ExeName)
{  GDMHeader ModHead;                // Module Header
   char *SndDevMSE[6] = { "GUS.MSE", "SB1X.MSE", "SB2X.MSE",
                          "SBPRO.MSE", "SB16.MSE", "PAS.MSE" };
   char *ErrorMSE[12] = {
   "Base I/O address autodetection failure",  /* 1 */
   "IRQ level autodetection failure",         /* 2 */
   "DMA channel autodetection failure",
   "DMA channel not supported",
   "",
   "Sound device does not respond",
   "Memory control blocks destroyed",
   "Insufficient memory for mixing buffers",
   "Insufficient memory for MSE file",
   "MSE has invalid identification string (corrupt/non-existant)",
   "MSE disk read failure",
   "MVSOUND.SYS not loaded (required for PAS use)"               };
  char temp, OverRate, j, OldOrd;
  int Handle, ErrorFlag;

  if (MSEConfig.SoundCard == 0) return; /* If no sound, don't test it */

  /* Set up our sound system: */
  OverRate = 44;
  switch (MSEConfig.SoundQuality) {
     case 0: OverRate = 16; break;
     case 1: OverRate = 22; break;
     case 2: OverRate = 45; break;
     case 3: OverRate = 8; break;
  }
  if ((Handle = open(SndDevMSE[MSEConfig.SoundCard-1], O_RDONLY | O_BINARY)) == -1) {
     ErrorScreen(14, 4);
     textattr(0x74); gotoxy(20, 16); cprintf("99");
     textattr(0x1F); gotoxy(16, 18);
     cprintf("Can not find MSE. Please put MSE file in current directory.\n");
     getch();
     return;
  }
  close(Handle);

  temp = LoadMSE(SndDevMSE[MSEConfig.SoundCard-1],
                 0,
                 OverRate,
                 4096,
                 &MSEConfig.BaseIO,
                 &MSEConfig.IRQ,
                 &MSEConfig.DMA);

  if (temp)
  {  ErrorScreen(14, 4);
     textattr(0x74); gotoxy(20, 16); cprintf("%.2u", temp);
     textattr(0x1F); gotoxy(16, 18);
     if (temp <= 12) cprintf("%s", ErrorMSE[temp-1]);
     else cprintf("Unknown error");
     getch();
     FreeMSE();
     return;
  }

  Handle = open(ExeName, O_RDONLY | O_BINARY);
  OverLoad("SETUP.GDM", Handle);
  /* Load our module */
  LoadGDM(Handle, lseek(Handle, 0, SEEK_CUR), &ErrorFlag, &ModHead);
  close(Handle);
  if (ErrorFlag) {
     ErrorScreen(14, 4);
     textattr(0x74); gotoxy(20, 16); cprintf("%.2u", ErrorFlag);
     textattr(0x1F); gotoxy(16, 18);
     cprintf("Error loading GDM music file\n");
     getch();
     FreeMSE();
     return;
  }

  temp = 0;                          /* Start out at zero.. */
  for (j = 1; j <= 32; j++) if (ModHead.PanMap[j] != 0xFF) temp++;

  StartOutput(temp, 0);              /* Start your (sound) engines */
  StartMusic();                      /* Revv up the music playing */

  TestScreen(10, 9);
  textattr(0x1F);
  gotoxy(19, 14); cprintf("%s", ModHead.SongTitle);
  gotoxy(22, 15); cprintf("%s", ModHead.SongMusician);

  OldOrd = 2;
  do
  {  for (j = 1; j <= 4; j++)
     {  temp = ChannelVU(j, ChannelVU(j, 0xFF) - 1) / 2;
        if (temp)
        {  Locate(15 + j, 12);
           XColor(10, 1);
           XColorFill(temp);
        }
        if (16 - temp)
        { Locate(15 + j, 12 + temp);
          XColor(0, 1);
          XColorFill(16 - temp);
        }
     }
     temp = MusicOrder(0xFF);
     if (temp != OldOrd)
     {  textattr(0x1A);
        gotoxy(29 + temp * 6, 17); cprintf("ÛÛÛÛÛÛ");
        gotoxy(29 + temp * 6, 18); cprintf("ÛÛÛÛÛÛ");
        textattr(0x1F);
        gotoxy(29 + OldOrd * 6, 17); cprintf("±±±±±±");
        gotoxy(29 + OldOrd * 6, 18); cprintf("±±±±±±");
     }
     OldOrd = temp;
     textattr(0x1F);
     gotoxy(64, 14); cprintf("Row: %u ", MusicRow());
     delay(5);
  } while (!kbhit());
  getch();
  FreeMSE();
}