#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream.h>
#include <pc.h>
#include <sys/exceptn.h>
#include <go32.h>

#include "defines.h"
#include "xlib.h"
#include "archive.h"
#include "colors.h"

#include "bwsb32.h"
#include "gus.h"
#include "music.h"
#include "overload.h"

void ExitOP(void);
void NextModule(int argc, char *argv[], seGUS& snd, MusicEngine& mus);
void BuildScreen(MusicEngine& mus);
void OSShell(MusicEngine& mus);
void UpdateVU(seGUS& snd);
void PrevModule(char *argv[], seGUS& snd, MusicEngine& mus);

unsigned char palette[768];
unsigned char *font[3];
BYTE *mouse, *gbar, *rbar, *gbar2, *rbar2;
char *PlayScreen, *ExitScreen;

unsigned char lin_gbar[] = { 8, 0, 3, 0,
                    14, 14, 14, 14, 14, 14, 12,  0,
                    14, 12, 12, 12, 12, 12,  8,  0,
                    12,  8,  8,  8,  8,  8,  8,  0 };

unsigned char lin_gbar2[] = { 8, 0, 3, 0,
                    5, 5, 5, 5, 5, 5, 5, 0,
                    5, 5, 5, 5, 5, 5, 2, 0,
                    2, 2, 2, 2, 2, 2, 2, 0 };

unsigned char lin_rbar[] = { 8, 0, 3, 0,
                   48,48,48,48,48,48,38, 0,
                   48,38,38,38,38,38,32, 0,
                   38,32,32,32,32,32,32, 0 };

unsigned char lin_rbar2[] = { 8, 0, 3, 0,
                   29,29,29,29,29,29,29, 0,
                   29,29,29,29,29,29,20, 0,
                   20,20,20,20,20,20,20, 0 };

BYTE lin_mouse[] = { 8, 0, 10, 0, 
                    0xFF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                    0xFF,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
                    0xFF,0xFE,0xFF,0x00,0x00,0x00,0x00,0x00,
                    0xFF,0xFE,0xFE,0xFF,0x00,0x00,0x00,0x00,
                    0xFF,0xFE,0xFE,0xFE,0xFF,0x00,0x00,0x00, 
                    0xFF,0xFE,0xFE,0xFE,0xFE,0xFF,0x00,0x00,
                    0xFF,0xFE,0xFE,0xFE,0xFE,0xFE,0xFF,0x00,
                    0xFF,0xFF,0xFF,0xFE,0xFE,0xFF,0xFF,0xFF,
                    0x00,0x00,0x00,0xFF,0xFE,0xFE,0xFF,0x00,
                    0x00,0x00,0x00,0x00,0xFF,0xFF,0x00,0x00 };

typedef struct {
    short SoundCard;
    short BaseIO;
    short IRQ;
    short DMA;
    short SoundQuality;
} MSEConfigFile;

int FileNum;

#define DIR_DELIM '/'
#define OP_VERSION "1.03"

int main(int argc, char *argv[]) {
        MSEConfigFile MSEConfig;  /* Configuration for MSE */
        FILE *fpFile;
        int err, PlayingMusic = 0, i;
        char s, Buffer[10][100], *FileName;

        cout << "OmniPlayer/32 Version " OP_VERSION "\n";
        cout << "Copyright (c) 1993-97, Edward T. Schlunder.\n";
        cout << "All Rights Reserved.\n" << endl;

        if(x_init_mouse() == 0) {
            cout << "No mouse detected." << endl;
            return(1);
        }

        if(argc < 2) {
            cout << "No music files specified." << endl;
            return(1);
        }

        fpFile = fopen(argv[0], "rb");
        i = OverLoad("OPLAY.RAW", fpFile);
        if(i == 0) {
            cout << "Can't load image data." << endl;
            return(1);
        }
        PlayScreen = new char[i];
        fread(PlayScreen, 1, i, fpFile);

        i = OverLoad("OPLAY.PAL", fpFile);
        if(i == 0) {
            cout << "Can't load image palette data." << endl;
            return(1);
        }
        fread(palette, 1, i, fpFile);

        i = OverLoad("MODERNB.FNT", fpFile);
        if(i == 0) {
            cout << "Can't load modernb font data." << endl;
            return(1);
        }
        font[0] = new unsigned char[i];
        fread(font[0], 1, i, fpFile);

        i = OverLoad("SMALTHIN.FNT", fpFile);
        if(i == 0) {
            cout << "Can't load smalthin font data." << endl;
            return(1);
        }
        font[1] = new unsigned char[i];
        fread(font[1], 1, i, fpFile);

        i = OverLoad("OPEXIT.BIN", fpFile);
        if(i == 0) {
            cout << "Can't load exit screen." << endl;
            return(1);
        }
        ExitScreen = new char[i];
        fread(ExitScreen, 1, i, fpFile);

        fclose(fpFile);

        for(i = strlen(argv[0]); i > 0; i--) {
            if(argv[0][i-1] == DIR_DELIM)
                break;
        }
        if(i == 0) {
            FileName = new char[10];
            strcpy(FileName, "sound.cfg");
        }
        else {
            FileName = new char[i+10];
            strncpy(FileName, argv[0], i);
            FileName[i] = 0;
            strcat(FileName, "sound.cfg");
        }

        fpFile = fopen(FileName, "rb");
        if(fpFile == NULL) {
            cout << "Base I/O Address: ";
            cin >> hex >> MSEConfig.BaseIO >> dec;
            cout << "IRQ Level: ";
            cin >> MSEConfig.IRQ;
            cout << "DMA Channel: ";
            cin >> MSEConfig.DMA;
            fpFile = fopen("sound.cfg", "wb");
            fwrite(&MSEConfig, 1, sizeof(MSEConfigFile), fpFile);
        }
        else {
            fread(&MSEConfig, 1, sizeof(MSEConfigFile), fpFile);
        }
        fclose(fpFile);

        __djgpp_set_ctrl_c(0);
        _go32_want_ctrl_break(1);
    
        seGUS snd(MSEConfig.BaseIO, MSEConfig.IRQ, MSEConfig.IRQ, MSEConfig.DMA, MSEConfig.DMA);
        MusicEngine mus(snd);

        mouse = (BYTE *)malloc(1028);
        x_BM_to_PBM(lin_mouse, mouse);
        x_set_mouse_cursor(mouse);

        gbar = (unsigned char *) malloc(1028); x_BM_to_PBM(lin_gbar, gbar);
        gbar2 = (unsigned char *) malloc(1028); x_BM_to_PBM(lin_gbar2, gbar2);
        rbar = (unsigned char *) malloc(1028); x_BM_to_PBM(lin_rbar, rbar);
        rbar2 = (unsigned char *) malloc(1028); x_BM_to_PBM(lin_rbar2, rbar2);

        cout << "Output Device: " << snd.DevName() << endl;
        cout << "Addr:" << hex << snd.DevAddr() << dec;
        cout << "h  IRQ:" << snd.DevIRQ();
        cout << "  DMA:" << snd.DevDMA() << "\n" << endl;

        if(snd.Status() == 6) {
                cout << "Sound card does not respond, bad configuration?" << endl;
                return(1);
        }

        FileNum = 1;
        cout << "Loading " << argv[FileNum] << "..." << endl;
        mus.Load(argv[FileNum]);
        snd.IRQSetup();
        PlayingMusic = 1;

        BuildScreen(mus);

        err = 0;
        for(;;) {
            while(!kbhit() && !(MouseButtonStatus & 1)) {
                sprintf(Buffer[0], "%d", mus.Pat);
                sprintf(Buffer[1], "X:%d Y:%d", MouseX, MouseY);
                sprintf(Buffer[2], "%d/%d", mus.Ord, mus.NOO);
                sprintf(Buffer[3], "%d", mus.Row);

                x_wait_vertical_retrace_start();
                x_hide_mouse();    

                x_rect_fill(341, 184, 355, 193, Page0_Offs, 0); //14
                x_printf(341, 186, Page0_Offs, 50, font[1], Buffer[0]);
                x_rect_fill(237, 164, 292, 170, Page0_Offs, 0);
                x_printf(237, 165, Page0_Offs, 50, font[1], Buffer[1]);
                x_rect_fill(276, 184, 302, 193, Page0_Offs, 0);
                x_printf(276, 186, Page0_Offs, 50, font[1], Buffer[2]);

                x_rect_fill(227, 184, 240, 193, Page0_Offs, 0);
                x_printf(227, 186, Page0_Offs, 50, font[1], Buffer[3]);
                x_show_mouse();

                UpdateVU(snd);

                x_mouse_get_event();
            }
            
            if(kbhit()) {
                s = getkey();
                switch(s) {
                case 67:
                case 'd':
                    OSShell(mus);
                    break;

                case 'n':
                    NextModule(argc, argv, snd, mus);
                    break;

                case 'p':
                    PrevModule(argv, snd, mus);
                    break;
                
                case 27:
                case 'q':
                    ExitOP();
                    snd.IRQFree();
                    return(0);

                }
            }

            if(MouseButtonStatus & 1) {
                while(MouseButtonStatus & 1)
                    x_mouse_get_event();                

                if(MouseX>=5  && MouseX<=15 && MouseY>=166 && MouseY<=172) {
                    ExitOP();
                    snd.IRQFree();
                    return(0);
                }

                if(MouseX>=88 && MouseX<=129 && MouseY>=181 && MouseY<=189) {
                    PlayingMusic ^= 1;
                    if(PlayingMusic)
                        mus.Play();
                    else
                        mus.Pause();
                }

                if(MouseX>=48 && MouseX<=81 && MouseY>=167 && MouseY<=175)
                    OSShell(mus);

                if(MouseX>=176 && MouseX<=198 && MouseY>=167 && MouseY<=175)
                    PrevModule(argv, snd, mus);

                if(MouseX>=176 && MouseX<=198 && MouseY>=181 && MouseY<=189)
                    NextModule(argc, argv, snd, mus);

                if(MouseX>=136 && MouseX<=169 && MouseY>=181 && MouseY<=189)
                    mus.Order(mus.Ord+1);

                if(MouseX>=48 && MouseX<=81 && MouseY>=181 && MouseY<=189)
                    mus.Order(mus.Ord-1);
            }

        }
}

void ExitOP(void) {
    x_fade_out(palette);
    x_set_text_mode();
    ScreenUpdate(ExitScreen);
    ScreenPutString(OP_VERSION, 9, 47, 0);
    ScreenSetCursor(9, 0);
}

void NextModule(int argc, char *argv[], seGUS& snd, MusicEngine& mus) {
    int i;
    char sTemp[33];

    if(FileNum >= argc-1)
        return;
    FileNum++;

    x_rect_fill(231, 174, 355, 181, Page0_Offs, 0);
    x_printf(231, 174, Page0_Offs, 50, font[1], "loading...");

    snd.IRQFree();
    mus.Load(argv[FileNum]);
    snd.IRQSetup();

    for(i = 0; i < 23 && mus.Title[i] != 0; i++) {
        if((mus.Title[i] > 31) && (mus.Title[i] < 123))
            sTemp[i] = mus.Title[i];
        else
            sTemp[i] = 32;
    }
    sTemp[i] = 0;
    x_rect_fill(231, 174, 355, 181, Page0_Offs, 0);
    x_printf(231, 174, Page0_Offs, 50, font[1], sTemp);
}

void PrevModule(char *argv[], seGUS& snd, MusicEngine& mus) {
    int i;
    char sTemp[33];

    if(FileNum <= 1)
        return;
    FileNum--;

    x_rect_fill(231, 174, 355, 181, Page0_Offs, 0);
    x_printf(231, 174, Page0_Offs, 50, font[1], "loading...");

    snd.IRQFree();
    mus.Load(argv[FileNum]);
    snd.IRQSetup();

    for(i = 0; i < 23 && mus.Title[i] != 0; i++) {
        if((mus.Title[i] > 31) && (mus.Title[i] < 123))
            sTemp[i] = mus.Title[i];
        else
            sTemp[i] = 32;
    }
    sTemp[i] = 0;
    x_rect_fill(231, 174, 355, 181, Page0_Offs, 0);
    x_printf(231, 174, Page0_Offs, 50, font[1], sTemp);
}


void BuildScreen(MusicEngine& mus) {
    char sTemp[33];
    int x, y;
    int i;

    x_set_mode(X_360X240);
    XMouseClipMin = 0; XMouseClipMax = 351;
    YMouseClipMin = 0; YMouseClipMax = 231;
    x_mouse_window();

    x_set_palette(palette);

    x_wait_vertical_retrace_start();
    for(y = 0; y < 240; y++) {
        for(x = 0; x < 360; x++) {
            x_put_pixel(x, y, Page0_Offs, PlayScreen[x+y*360]);
        }
    }

    x_printf(61, 229, Page0_Offs, 52, font[0], "Version " OP_VERSION "        (c)1993-97, Ed Schlunder");
    for(i = 0; i < 23 && mus.Title[i] != 0; i++) {
        if((mus.Title[i] > 31) && (mus.Title[i] < 123))
            sTemp[i] = mus.Title[i];
        else
            sTemp[i] = 32;
    }
    sTemp[i] = 0;
    x_printf(231, 174, Page0_Offs, 50, font[1], sTemp);
}

void OSShell(MusicEngine& mus) {
    x_hide_mouse();
    x_set_text_mode();
    cout << "\n\nType EXIT [enter] to return to OmniPlayer/32..." << flush;
    system(getenv("COMSPEC"));
    BuildScreen(mus);
    x_show_mouse();
}

void UpdateVU(seGUS& snd) {
    int VU, i;

    x_wait_vertical_retrace_start();
    x_hide_mouse();
    for(i = 0; i < 32; i++) {
        VU = snd.VU[i];
        if(VU) snd.VU[i]--;
        VU = VU >> 1;
        for(int h = 0; h < 12; h++) {
            x_put_PBM(80 + (i<<3), 71 - (h<<2), Page0_Offs, (h<VU)? gbar:gbar2);
        }
        for(int h = 12; h < 16; h++) {
            x_put_PBM(80 + (i<<3), 71 - (h<<2), Page0_Offs, (h<VU)? rbar:rbar2);
        }
    }
    x_show_mouse();    
}
