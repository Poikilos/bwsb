/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*                     Bells, Whistles, and Sound Boards                    */
/*       Copyright (c) 1993-95, Edward Schlunder.                           */
/*ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ*/
/* CHPLAY.C - Example GDM module player with channel vu bars.               */
/*            Written by Edward Schlunder (1995)                            */
/*                                                                          */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

#include <bwsb.h>
#include <chantype.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <process.h>
#include <ctype.h>
#include <conio.h>
#include <dos.h>
#include <io.h>
#include <fcntl.h>

typedef struct
{ int SoundCard;
  int BaseIO;
  int IRQ;
  int DMA;
  int SoundQuality;
} MSEConfigFile;


void textblink(char intensity);

void PrintHeader(char Dark);
void DoPlayer(void);

void DiChan(int Channel);
void DiPan(int Channel);
void DiNote(int Channel);
void DiPos(int Channel);
void DiVol(int Channel);
void DiVu(int Channel);

unsigned long OverLoad(char *FileName, int FileHandle);

int Channels = { 0 };

int j, ErrorFlag, Handle;
ChannelType MusicChan;

char ShowChan, ShowPan, ShowNote, ShowVol, ShowPos, ShowVU;
char *Note[] = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" };

char *PanPos[] = { "L               ",
                   " l              ",
                   "  l             ",
                   "   l            ",
                   "    l           ",
                   "     l          ",
                   "      m         ",
                   "       m        ",
                   "        M       ",
                   "         m      ",
                   "          m     ",
                   "           r    ",
                   "            r   ",
                   "             r  ",
                   "              r ",
                   "               R"};
GDMHeader ModHead;
char modfile[80];         /* ASCIIZ filename of file to load */
char *comspec;            /* Command processor name and path */

void main(int argc, char *argv[])
{  long FileOff;
   unsigned int BaseIO = { 0xFFFF },
                IRQ = { 0xFF },
                DMA = { 0xFF };
   char Ov, *msefile[] = { "GUS.MSE", "SB1X.MSE", "SB2X.MSE",
                           "SBPRO.MSE", "SB16.MSE", "PAS.MSE" },
        OverTable[]    = { 16, 22, 45, 8, 11 },
        *ErrorMSE[]    = { "Base I/O address autodetection failure\n",        
        /* 2 */            "IRQ level autodetection failure\n",              
        /* 3 */            "DMA channel autodetection failure\n",            
        /* 4 */            "DMA channel not supported\n",                    
        /* 5 */            "\n",                                             
        /* 6 */            "Sound device does not respond\n",                
        /* 7 */            "Memory control blocks destroyed\n",              
        /* 8 */            "Insufficient memory for mixing buffers\n",       
        /* 9 */            "Insufficient memory for MSE file\n",             
        /* 10 */           "MSE has invalid identification string\n",       
        /* 11 */           "MSE disk read failure\n",                        
        /* 12 */           "MVSOUND.SYS not loaded (required for PAS use)\n",
        /* 13 */           "Insufficient memory for volume table\n" };
   MSEConfigFile MSEConfig;             /* Configuration for MSE */
   char *ErrorLoad[] = {
     "Module is corrupt\n",                             /* 1 */
     "Could not autodetect module type\n",              /* 2 */
     "Bad file format ID string\n",                     /* 3 */
     "Insufficient memory to load module\n",            /* 4 */
     "Can not unpack samples\n",                        /* 5 */
     "AdLib instruments not supported\n" };

   union REGS regs; struct SREGS sregs;

   PrintHeader(1);

   if ((Handle = open("MSE.CFG", O_RDONLY | O_BINARY)) == -1) {
   MSEError:
      printf("No Sound selected in SETUP. Please run SETUP.\n");
      return;
   }

   read(Handle, &MSEConfig, 10); close(Handle);
   if (MSEConfig.SoundCard == 0) goto MSEError;

   MSEConfig.SoundCard--;
   BaseIO = MSEConfig.BaseIO;
   IRQ = MSEConfig.IRQ;
   DMA = MSEConfig.DMA;

   Handle = open(argv[0], O_RDONLY | O_BINARY);
   OverLoad(msefile[MSEConfig.SoundCard], Handle);
   FileOff = lseek(Handle, 0, SEEK_CUR);
   close(Handle);

   Ov = OverTable[MSEConfig.SoundQuality];
   ErrorFlag = LoadMSE(argv[0], FileOff, Ov, 4096, &BaseIO, &IRQ, &DMA);

   if (ErrorFlag >= 1 && ErrorFlag <= 13) {
      printf(ErrorMSE[ErrorFlag-1]);
      return;
   }
   atexit(FreeMSE);                     /* make sure that things get put back
                                           before an abort or exit */

   /* Display name of sound device */
   printf("Sound Device: %s\n", DeviceName());
   printf("A:%Xh I:%d D:%d\n", BaseIO, IRQ, DMA);
   ErrorFlag = EmsExist() & 1;            /* Enable EMS use if available */
   if (ErrorFlag) printf("EMS Enabled\n");

   /* Ask for a module to load */
   if (argc - 1) stpcpy(modfile, argv[1]);
   else {   
     printf("File: ");
     gets(modfile);
     if (strlen(modfile) == 0) return;
   }

   /* Append a .GDM if no extension specified */
   if (strstr(modfile, ".") == NULL) strncat(modfile, ".GDM", 80);

   printf("Loading Module: %s\n", modfile);
   if ((Handle = open(modfile, O_RDONLY | O_BINARY)) == -1) {
      printf("Can't find file %s\n", modfile);
      return;
   }

   LoadGDM(Handle, 0, &ErrorFlag, &ModHead);
   close(Handle);

   if (ErrorFlag) {                /* Was there an error loading? */
      printf(ErrorLoad[ErrorFlag-1]);
      return;                                                          
   }

   /* Scan and count number of used music channels */
   /* 0xFF is an unused channel, so only inc when not = 0xFF */
   for (j = 0;j < 32;j++) if (ModHead.PanMap[j] != 0xFF) Channels++;

   StartOutput(Channels, 0);       /* Enable sound output, no amplification */
   StartMusic();                   /* Start playing the music */

   PrintHeader(0);
   DoPlayer();

   PrintHeader(1);
   _setcursortype(_NORMALCURSOR);

   StopMusic();
   StopOutput();
   UnloadModule();
   FreeMSE();
}

void PrintHeader(char Dark)
{
   if (Dark)
   {  textattr(0x7);
      clrscr();
      textattr(0x1F);
      textblink(1);
   }
   else
   {  textattr(0x17);
      clrscr();
      textattr(0x9F);
      textblink(0);
   }
   cprintf(" OmniPlayer/C v1.21                     Copyright (c) 1993-95, Edward Schlunder ");
}

typedef struct
{ char FileName[12];
  unsigned long FileLoc;
  unsigned long FileSize;
} OLHeader;

typedef struct
{ char ID[10];
  unsigned char Entries;
  unsigned long Location;
} OLEnd;

unsigned long OverLoad(char *FileName, int FileHandle)
{ OLHeader Header;
  OLEnd EndHeader;
  int j;

  lseek(FileHandle, -15, SEEK_END);

  read(FileHandle, &EndHeader, sizeof(EndHeader));
  if (strnicmp(EndHeader.ID, "OverLoader", 10) != 0)
  {  printf("Couldn't find OverLoader ID header\n");
     getch();
     return(0);
  }

  lseek(FileHandle, EndHeader.Location - 1, SEEK_SET);
  for (j = 1; j <= EndHeader.Entries; j++)
  {  read(FileHandle, &Header, sizeof(OLHeader));
     if (strnicmp(Header.FileName, FileName, 12) == 0) goto FoundFile;
  }

  return(0);

  FoundFile:
  lseek(FileHandle, Header.FileLoc - 1, SEEK_SET);
  return(Header.FileSize);
}


void DiChan(int Channel)
{  textattr(0x7F);  cprintf("İ");
   textattr(0x71);  cprintf("%2u", Channel);
   textattr(0x78);  cprintf("Ş");
}

void DiPan(int Channel)
{  textattr(0x7F);  cprintf("İ");
   textattr(0x70);  cprintf("%s", PanPos[ChannelPan(Channel, 0xFF)]);
   textattr(0x78);  cprintf("Ş");
}

void DiNote(Channel)
{  textattr(0x7F);  cprintf("İ");

   textattr(0x70);
   if (ChannelVol(Channel, 0xFF) == 0) cprintf("   ");
   else cprintf("%s%u", Note[MusicChan.MusNote], MusicChan.MusOctave & 7);

   textattr(0x78);  cprintf("Ş");
}

void DiPos(Channel)
{  textattr(0x7F);  cprintf("İ");

   textattr(0x70);
   if (ChannelPos(Channel, 0xFFFF) == 0) cprintf("     ");
   else cprintf("%5u", ChannelPos(Channel, 0xFFFF));

   textattr(0x78);  cprintf("Ş");
}

void DiVol(Channel)
{  textattr(0x7F);  cprintf("İ");

   textattr(0x70);
   if (ChannelVol(Channel, 0xFF) == 0) cprintf("  ");
   else cprintf("%2u", ChannelVol(Channel, 0xFF));

   textattr(0x78);  cprintf("Ş");
}

void DiVu(Channel)
{  textattr(0x7F);  cprintf("İ");
   ErrorFlag = ChannelVU(Channel, ChannelVU(Channel, 0xFF)-1);

   for (Handle = 0; Handle <= 20; Handle++)
   { if (Handle < ErrorFlag) textcolor(10); else textcolor(0);
     cprintf("ş");                                                      }
   for (Handle = 21; Handle <= 30; Handle++)
   { if (Handle < ErrorFlag) textcolor(12); else textcolor(0);
     cprintf("ş");                                                      }

   textattr(0x78);  cprintf("Ş");
}

void DoPlayer(void)
{
   directvideo = 1;
   _setcursortype(_NOCURSOR);

   ShowChan = -1;
   ShowPan  = -1;
   ShowNote = -1;
   ShowPos  = 0;
   ShowVol  = -1;
   ShowVU   = -1;
   for (;;) {
      textcolor(7); gotoxy(2, 2);
      cprintf("Row: %-2u  Order:%3u/%-3u Pattern:%3u/%-3u Tempo: %2u/%-2u",
               MusicRow(),
               MusicOrder(0xFF), ModHead.NOO,
               MusicPattern(0xFF), ModHead.NOP,
               MusicTempo(0xFF), MusicBPM(0));

      for (j = 1;j <= Channels;j++) {
        if (j + 2 > 25) break;
        gotoxy(1, j + 2);
        GetChannelTable(j, FP_SEG(&MusicChan), FP_OFF(&MusicChan));

        if (ShowChan) DiChan(j);
        if (ShowPan)  DiPan (j);
        if (ShowNote) DiNote(j);
        if (ShowPos)  DiPos (j);
        if (ShowVol)  DiVol (j);
        if (ShowVU)   DiVu  (j);
        textbackground(1);
        clreol();
      }

      if (kbhit()) {
        j = toupper(getch());
        switch (j) {
          case 'F':  /* Ask for a module to load */
                     PrintHeader(1);
                     printf("\nModule file: ");
                     if (gets(modfile)==NULL) return;  /* abort if nothing entered */

                     /* Append a .GDM if no extension specified */
                     if (strstr(modfile, ".")==NULL) strncat(modfile, ".GDM", 80);

                  printf("Loading Module: %s\n", modfile);
                  if ((Handle = open(modfile, O_RDONLY | O_BINARY)) == -1) {
                     printf("Can't find file %s\n", modfile);
                     return;                                                         
                  }
                  
                  ErrorFlag = EmsExist() & 1;     /* Enable EMS use if available */
                  StopMusic();
                  StopOutput();
                  UnloadModule();
                  LoadGDM(Handle, 0, &ErrorFlag, &ModHead);  /* Load the GDM file */
                  close(Handle);

                  if (ErrorFlag) {                /* Was there an error loading? */
                     printf("Error while loading GDM: %u\n", ErrorFlag);
                     return;                                                        
                  }

                  /* Scan and count number of used music channels */
                  /* 0xFF is an unused channel, so only inc when not = 0xFF */
                  Channels = 0;
                  for (j = 0;j < 32;j++) if (ModHead.PanMap[j] != 0xFF) Channels++;

                  StartOutput(Channels, 0);       /* Enable sound output with */
                                                  /* no amplification. */
                  StartMusic();                   /* Start playing the music */
                  PrintHeader(0);
                  break;
       case 'D':  PrintHeader(1);
                  _setcursortype(_NORMALCURSOR);
                  printf("\nType EXIT [enter] to return..");
                  if (spawnl(P_WAIT, getenv("COMSPEC"), NULL))
                  {  printf("Shell Error: %u\n", errno);
                     getch();
                  }
                  PrintHeader(0);
                  _setcursortype(_NOCURSOR);
                  break;
       case '+':  MusicVolume(MusicVolume(0xFF) + 1);
                  break;
       case '-':  MusicVolume(MusicVolume(0xFF) - 1);
                  break;
       case '1':  ShowChan =! ShowChan;
                  break;
       case '2':  ShowPan  =! ShowPan;
                  break;
       case '3':  ShowNote =! ShowNote;
                  break;
       case '4':  ShowPos  =! ShowPos;
                  break;
       case '5':  ShowVol  =! ShowVol;
                  break;
       case '6':  ShowVU   =! ShowVU;
                  break;
       case 75:   MusicOrder(MusicOrder(0xFF) - 1);
                  break;
       case 77:   MusicOrder(MusicOrder(0xFF) + 1);
                  break;
       case 27:   return;                                              }
     }
   }
}

void textblink(char intensity) {
   if (intensity) {
     asm  mov  ax, 0x1003;
     asm  mov  bl, 1;
     asm  int  0x10;
   }
   else {
     asm  mov  ax, 0x1003;
     asm  xor  bl, bl;
     asm  int  0x10;
   };
}
