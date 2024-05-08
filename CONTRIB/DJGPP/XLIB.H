/*
 * xlib.h - main header for mode-x graphics library
 *
 * DESCRIPTION
 *
 * USAGE
 * #include "xlib.h"
 *
 * NOTES
 * Based on xlib60 for BC by Themie Goumas
 *
 * REVISION HISTORY
 * Date         Reason
 * 27 Jun 95    Initial Release
 * 13 Jul 95    Added split screen stuff
 * 31 Aug 95    Added bitmap clipping functions, improved color text routines,
 *              Added clipped text support
 *  1 Sep 95    Added x_tile32_clipy
 *  7 Sep 95    Patched kb handler and pulled vr handler
 *
 */

#ifndef _XLIB_H_
#define _XLIB_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "defines.h"

/*************************************************************************
** defined resolutions (256 color)
** NOTE: 360x resolutions have trouble with some multisync monitors/cards 
*************************************************************************/
#define X_320X200       1
#define X_320X240       2
#define X_320X400       3
#define X_320X480       4
#define X_360X240       5
#define X_360X480       6

/************************************** 
** Global Variables
**************************************/
extern BOOLEAN InGraphics;
extern int ScrnPhysicalByteWidth;
extern int ScrnLogicalByteWidth;
extern int ScrnPhysicalPixelWidth;
extern int ScrnPhysicalHeight;
extern int ScrnLogicalHeight;
extern int VisibleOffset;   /* Offset in bytes to address of 0,0 on Page0 */
extern int Page0_Offs;
extern int Page1_Offs;
extern int Page0_Disp_Offs;
extern int Page1_Disp_Offs;
extern int VisiblePageOffs;
extern int HiddenPageOffs;
extern int NonVisibleOffs;
extern int XClipMin;
extern int XClipMax;
extern int YClipMin;
extern int YClipMax;
extern int OldVideoMode;
extern int XPaletteLevel;
extern int XPaletteStep;
extern int SplitLines;
extern int SplitStartOffset;
extern int SplitStartLine;
extern int NonSplitLines;

/* selector for DOS memory */
extern WORD core_select;

/* Mouse module variables */
extern int MouseX;
extern int MouseY;
extern int MouseButtonStatus;
extern BOOLEAN MouseDriverActive;
extern BOOLEAN MouseHidden;
extern BYTE * pMouseCursor;
extern int XMouseClipMin;
extern int XMouseClipMax;
extern int YMouseClipMin;
extern int YMouseClipMax;


/* Joystick module variables */
extern int Joystick1X;
extern int Joystick1Y;
extern int Joystick2X;
extern int Joystick2Y;
extern int JoystickSense;
extern int JoystickRange;
extern int JoystickCenterX;
extern int JoystickCenterY;


/****************************************
** Exported functions
****************************************/

/* General screen control functions */
int  x_set_mode(int resolution);
void x_set_text_mode();
void x_clear_buffer();
void x_show_page(WORD PageBase);
void x_set_logical_size(int x, int y);
void x_set_split_screen(int startline);
BOOLEAN x_detect_VGA();


/* Vertical Retrace detection */
void x_wait_vertical_retrace_start(void);
void x_wait_vertical_retrace_end(void);
void x_wait_display_mode(void);
void x_wait_retrace_mode(void);
BOOLEAN x_vertical_retrace_occuring(void);


/* Primitive drawing functions */
void x_put_pixel(int x, int y, int PageBase, BYTE Color);
BYTE x_get_pixel(int x, int y, int PageBase);
void x_line(int X1, int Y1, int X2, int Y2, int PageBase, BYTE Color);
void x_rect_fill(int StartX, int StartY, int EndX, int EndY,
                 int PageBase, BYTE Color);


/* Screen-to-screen update & copy functions */
void x_cp_vid_rect(int SrcStartX, int SrcStartY, int SrcEndX, int SrcEndY,
                   int DestStartX, int DestStartY, int SrcPageBase,
                   int DestPageBase, int SrcBitmapWidth, int DestBitmapWidth);


/* Palette control functions */
void x_set_palette(BYTE * pal_to_set);
void x_set_part_palette(int first_color, int num_colors, BYTE * pal_to_set);
void x_black_palette();
void x_fade_in( BYTE * palette );
void x_fade_out( BYTE * palette );
void x_part_fade_in( int first, int num, BYTE * palette );
void x_part_fade_out( int first, int num, BYTE * palette );
void x_part_cycleL( int first, int num, BYTE * palette );
void x_part_cycleR( int first, int num, BYTE * palette );

/* Stepped palette fades (for use with timer synchronization) */
void x_set_palette_noVR(BYTE * pal_to_set);
void x_set_part_palette_noVR(int first_color, int num_colors, BYTE * pal_to_set);
void x_fade_in_step( BYTE * palette );
void x_fade_out_step( BYTE * palette );
void x_part_fade_in_step( int first, int num, BYTE * palette );
void x_part_fade_out_step( int first, int num, BYTE * palette );

/* Palette effects with no vertical retrace checking */
void x_fade_in_noVR( BYTE * palette );
void x_fade_out_noVR( BYTE * palette );
void x_part_fade_in_noVR( int first, int num, BYTE * palette );
void x_partfade_out_noVR( int first, int num, BYTE * palette );
void x_part_cycleL_noVR( int first, int num, BYTE * palette );
void x_part_cycleR_noVR( int first, int num, BYTE * palette );

/* Bitmap conversion & utility functions */
void x_BM_to_PBM(BYTE * linear, BYTE * planar);


/* Bitmap drawing functions */
void x_put_PBM(int X, int Y, int PageBase, BYTE * bitmap);
void x_put_PBM_masked(int X, int Y, int PageBase, BYTE * bitmap);
void x_tile16(int X, int Y, int PageBase, BYTE * bitmap);
void x_tile32(int X, int Y, int PageBase, BYTE * bitmap);

/* clipped drawing functions */
void x_put_PBM_masked_clipx(int X, int Y, int PageBase, BYTE * bitmap);
void x_put_PBM_masked_clipxy(int X, int Y, int PageBase, BYTE * bitmap);
void x_put_PBM_masked_clipy(int X, int Y, int PageBase, BYTE * bitmap);
void x_set_cliprect(int left, int top, int right, int bottom);
void x_put_PBM_clipx(int X, int Y, int PageBase, BYTE * bitmap);
void x_put_PBM_clipxy(int X, int Y, int PageBase, BYTE * bitmap);
void x_put_PBM_clipy(int X, int Y, int PageBase, BYTE * bitmap);
void x_tile32_clipy(int x, int y, int PageBase, BYTE * bitmap);


/* RLE bitmap functions */
int x_PBM_to_RLE(BYTE * pbm, BYTE * rle, int ScreenByteWidth);
int x_sizeof_RLE(BYTE * pbm, BYTE ScreenByteWidth);
void x_put_RLE(int X, int Y, int PageBase, BYTE * rlebitmap);


/* compiled bitmap functions */
int x_compile_bitmap (int logical_screen_width, BYTE * bitmap, BYTE * output);
int x_sizeof_cbitmap (int logical_screen_width, BYTE * bitmap);
void x_put_cbitmap(int XPos, int YPos, int PageOffset, BYTE * Sprite);


/* Text functions */
int x_char_put(int X,int Y,int PageBase,int Color,BYTE * font, char Char);
int x_color_char_put(int x,int y,int ScrnOffs, BYTE * font, char Character);
void x_printf(int x, int y, int ScrnOffs, int color, BYTE * font, 
              char * line, ...);
void x_cprintf(int x, int y, int ScrnOffs, BYTE * font, char * line, ...);

/* Clipping text functions */
int x_char_put_clipxy(int X,int Y,int PageBase,int Color,BYTE * font, 
                      char Char);
int x_color_char_put_clipxy(int x,int y,int ScrnOffs, BYTE * font, 
                            char Character);
void x_printf_clipxy(int x, int y, int ScrnOffs, int color, BYTE * font, 
                     char * line, ...);
void x_cprintf_clipxy(int x, int y, int ScrnOffs, BYTE * font, 
                      char * line, ...);


/* Joystick control functions */
int read_joystick();
BOOLEAN detect_joystick();
BOOLEAN calibrate_joystick();


/* Mouse control functions (polled) */
void x_mouse_get_event();
void x_show_mouse();
void x_hide_mouse();
int  x_init_mouse();
void x_mouse_window();
void x_set_mouse_cursor(BYTE * bitmap);
void x_remove_mouse();

/* important function to lock memory for interrupt handlers */
int x_lock_memory(const void * ptr, unsigned long bytes);

#ifdef __cplusplus
}
#endif

#endif    /* _XLIB_H_ */
