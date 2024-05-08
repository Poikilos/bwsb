	.286p
	ifndef	??version
?debug	macro
	endm
publicdll macro	name
	public	name
	endm
$comm	macro	name,dist,size,count
	comm	dist name:BYTE:count*size
	endm
	else
$comm	macro	name,dist,size,count
	comm	dist name[size]:BYTE:count
	endm
	endif
	?debug	V 300h
	?debug	S "setup.c"
	?debug	C E9D6B4B21E0773657475702E63
	?debug	C E91DB2B21E21443A5C425753425C494E434C5544455C2E2E5C696E+
	?debug	C 636C7564655C627773622E68
	?debug	C E966B1711E19443A5C425753425C494E434C5544455C67646D7479+
	?debug	C 70652E68
	?debug	C E94019CA1817453A5C424350505C494E434C5544455C737464696F+
	?debug	C 2E68
	?debug	C E94019CA1817453A5C424350505C494E434C5544455C5F64656673+
	?debug	C 2E68
	?debug	C E94019CA1818453A5C424350505C494E434C5544455C5F6E66696C+
	?debug	C 652E68
	?debug	C E94019CA1817453A5C424350505C494E434C5544455C5F6E756C6C+
	?debug	C 2E68
	?debug	C E94019CA1818453A5C424350505C494E434C5544455C7374646C69+
	?debug	C 622E68
	?debug	C E94019CA1818453A5C424350505C494E434C5544455C737472696E+
	?debug	C 672E68
	?debug	C E94019CA1817453A5C424350505C494E434C5544455C636F6E696F+
	?debug	C 2E68
	?debug	C E94019CA1815453A5C424350505C494E434C5544455C646F732E68
	?debug	C E94019CA1814453A5C424350505C494E434C5544455C696F2E68
	?debug	C E94019CA1817453A5C424350505C494E434C5544455C66636E746C+
	?debug	C 2E68
	?debug	C E9EF4E6E1E0873637265656E2E68
	?debug	C E948726E1E077072696E742E68
SETUP_TEXT	segment byte public 'CODE'
SETUP_TEXT	ends
DGROUP	group	_DATA,_BSS
	assume	cs:SETUP_TEXT,ds:DGROUP
_DATA	segment word public 'DATA'
d@	label	byte
d@w	label	word
_DATA	ends
_BSS	segment word public 'BSS'
b@	label	byte
b@w	label	word
_BSS	ends
_DATA	segment word public 'DATA'
_Copyright	label	dword
	dd	DGROUP:s@
	dd	DGROUP:s@+80
	dd	DGROUP:s@+134
	dd	DGROUP:s@+210
	dd	DGROUP:s@+237
	dd	DGROUP:s@+268
	db	20 dup (0)
	dd	DGROUP:s@+292
	dd	DGROUP:s@+310
	dd	DGROUP:s@+328
	dd	DGROUP:s@+346
	dd	DGROUP:s@+364
	dd	DGROUP:s@+382
	dd	DGROUP:s@+400
	dd	DGROUP:s@+418
	dd	DGROUP:s@+443
	dd	DGROUP:s@+468
	dd	DGROUP:s@+493
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
   ;	
   ;	void main(int argc, char *argv[])
   ;	
	assume	cs:SETUP_TEXT
_main	proc	far
	enter	84,0
	push	si
	push	di
   ;	
   ;	{  char *MainHelp[10] =
   ;	 { "Select Sound Card for digital music and sound effects",
   ;	
   ;	
   ;	   "Select Sound Card configuration settings (Address, IRQ number, DMA channel)",
   ;	   "Select sound quality level",
   ;	   "Load MSE and try playing music",
   ;	   "Exit and save new setup" };
   ;	
	lea	ax,word ptr [bp-40]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+4
	mov	cx,40
	call	far ptr F_SCOPY@
   ;	
   ;	
   ;	   char *SoundCards[] = { "NONE (Silence)   ",
   ;	
   ;	
   ;	                          "Gravis UltraSound",
   ;	                          "Sound Blaster 1.x",
   ;	                          "Sound Blaster 2.x",
   ;	                          "Sound Blaster Pro",
   ;	                          "Sound Blaster 16 ",
   ;	                          "Pro AudioSpectrum" };
   ;	
	lea	ax,word ptr [bp-68]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+44
	mov	cx,28
	call	far ptr F_SCOPY@
   ;	
   ;	   char *SndQuality[] = { "Medium Sound Quality    ",
   ;	
   ;	
   ;	                          "High Sound Quality      ",
   ;	                          "Super-High Sound Quality",
   ;	                          "Low Sound Quality       " };
   ;	
	lea	ax,word ptr [bp-84]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+72
	mov	cx,16
	call	far ptr F_SCOPY@
   ;	
   ;	  int temp, temp2;
   ;	
   ;	  MSEConfig.SoundCard = 0;              // Sound Card: None
   ;	
	mov	word ptr DGROUP:_MSEConfig,0
   ;	
   ;	  MSEConfig.SoundQuality = 0;           // Medium sound quality
   ;	
	mov	word ptr DGROUP:_MSEConfig+8,0
   ;	
   ;	  MSEConfig.BaseIO = 0xFFFF;
   ;	
	mov	word ptr DGROUP:_MSEConfig+2,-1
   ;	
   ;	  MSEConfig.IRQ = 0xFF;
   ;	
	mov	word ptr DGROUP:_MSEConfig+4,255
   ;	
   ;	  MSEConfig.DMA = 0xFF;                 // Autodetect sound card setup
   ;	
	mov	word ptr DGROUP:_MSEConfig+6,255
   ;	
   ;	
   ;	  temp = open("MSE.CFG", O_RDONLY | O_BINARY);
   ;	
	push	-32767
	push	ds
	push	offset DGROUP:s@+518
	call	far ptr _open
	add	sp,6
	mov	si,ax
   ;	
   ;	  if (temp != -1) read(temp, &MSEConfig, sizeof (MSEConfig));
   ;	
	cmp	si,-1
	je	short @1@86
	push	10
	push	ds
	push	offset DGROUP:_MSEConfig
	push	si
	call	far ptr _read
	add	sp,8
@1@86:
   ;	
   ;	  close(temp);
   ;	
	push	si
	call	far ptr _close
	pop	cx
   ;	
   ;	
   ;	  _setcursortype(_NOCURSOR);            // Now you see cursor, now you don't
   ;	
	push	0
	call	far ptr __setcursortype
	pop	cx
@1@114:
   ;	
   ;	
   ;	  for(;;) {
   ;	     MainMenu(0, 0);                    // Put up the main screen
   ;	
	push	0
	push	0
	call	far ptr _MainMenu
	add	sp,4
   ;	
   ;	     textattr(0x71); gotoxy(1, 1); cprintf("%s", Copyright);
   ;	
	push	113
	call	far ptr _textattr
	pop	cx
	push	1
	push	1
	call	far ptr _gotoxy
	add	sp,4
	push	word ptr DGROUP:_Copyright+2
	push	word ptr DGROUP:_Copyright
	push	ds
	push	offset DGROUP:s@+526
	call	far ptr _cprintf
	add	sp,8
   ;	
   ;	
   ;	     textattr(0x78);
   ;	
	push	120
	call	far ptr _textattr
	pop	cx
   ;	
   ;	     gotoxy(51, 6); cprintf("%s", SoundCards[MSEConfig.SoundCard]);
   ;	
	push	6
	push	51
	call	far ptr _gotoxy
	add	sp,4
	mov	bx,word ptr DGROUP:_MSEConfig
	shl	bx,2
	lea	ax,word ptr [bp-68]
	add	bx,ax
	push	word ptr ss:[bx+2]
	push	word ptr ss:[bx]
	push	ds
	push	offset DGROUP:s@+529
	call	far ptr _cprintf
	add	sp,8
   ;	
   ;	     gotoxy(53, 7); if (MSEConfig.BaseIO == 0xFFFF) cprintf("FFF");
   ;	
	push	7
	push	53
	call	far ptr _gotoxy
	add	sp,4
	cmp	word ptr DGROUP:_MSEConfig+2,-1
	jne	short @1@170
	push	ds
	push	offset DGROUP:s@+532
	call	far ptr _cprintf
	add	sp,4
	jmp	short @1@198
@1@170:
   ;	
   ;	                       else cprintf("%X", MSEConfig.BaseIO);
   ;	
	push	word ptr DGROUP:_MSEConfig+2
	push	ds
	push	offset DGROUP:s@+536
	call	far ptr _cprintf
	add	sp,6
@1@198:
   ;	
   ;	     gotoxy(59, 7); if (MSEConfig.IRQ < 16) cprintf("%u", MSEConfig.IRQ);
   ;	
	push	7
	push	59
	call	far ptr _gotoxy
	add	sp,4
	cmp	word ptr DGROUP:_MSEConfig+4,16
	jae	short @1@254
	push	word ptr DGROUP:_MSEConfig+4
	push	ds
	push	offset DGROUP:s@+539
	call	far ptr _cprintf
	add	sp,6
	jmp	short @1@282
@1@254:
   ;	
   ;	                       else cprintf("FF");
   ;	
	push	ds
	push	offset DGROUP:s@+542
	call	far ptr _cprintf
	add	sp,4
@1@282:
   ;	
   ;	     gotoxy(64, 7); cprintf("%X", MSEConfig.DMA);
   ;	
	push	7
	push	64
	call	far ptr _gotoxy
	add	sp,4
	push	word ptr DGROUP:_MSEConfig+6
	push	ds
	push	offset DGROUP:s@+545
	call	far ptr _cprintf
	add	sp,6
   ;	
   ;	     gotoxy(51, 8); cprintf("%s", SndQuality[MSEConfig.SoundQuality]);
   ;	
	push	8
	push	51
	call	far ptr _gotoxy
	add	sp,4
	mov	bx,word ptr DGROUP:_MSEConfig+8
	shl	bx,2
	lea	ax,word ptr [bp-84]
	add	bx,ax
	push	word ptr ss:[bx+2]
	push	word ptr ss:[bx]
	push	ds
	push	offset DGROUP:s@+548
	call	far ptr _cprintf
	add	sp,8
   ;	
   ;	
   ;	     temp = PopUpMenu(6, 3, 5, 27, MainHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-40]
	push	ax
	push	27
	push	5
	push	3
	push	6
	call	far ptr _PopUpMenu
	add	sp,12
	mov	si,ax
   ;	
   ;	
   ;	     switch (temp) {
   ;	
	mov	bx,si
	inc	bx
	cmp	bx,5
	jbe	@@0
	jmp	@1@562
@@0:
	shl	bx,1
	jmp	word ptr cs:@1@C642[bx]
@1@394:
   ;	
   ;	       case 0: SelectSoundCard();       // Select sound card
   ;	
	call	far ptr _SelectSoundCard
   ;	
   ;	               break;
   ;	
	jmp	@1@562
@1@422:
   ;	
   ;	       case 1: SelectSoundSettings();   // Select sound settings
   ;	
	call	far ptr _SelectSoundSettings
   ;	
   ;	               break;
   ;	
	jmp	@1@562
@1@450:
   ;	
   ;	       case 2: SelectSoundQuality();    // Select sound quality
   ;	
	call	far ptr _SelectSoundQuality
   ;	
   ;	               break;
   ;	
	jmp	@1@562
@1@478:
   ;	
   ;	       case 3: TestSound(argv[0]);      // Test out the sound engine
   ;	
	les	bx,dword ptr [bp+8]
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	call	far ptr _TestSound
	add	sp,4
   ;	
   ;	               break;
   ;	
	jmp	@1@562
@1@506:
   ;	
   ;	       case 4:                          // Save configuration
   ;	               temp2 = open("MSE.CFG", O_CREAT | O_BINARY | O_TRUNC);
   ;	
	push	-32000
	push	ds
	push	offset DGROUP:s@+551
	call	far ptr _open
	add	sp,6
	mov	di,ax
   ;	
   ;	               write(temp2, &MSEConfig, sizeof(MSEConfig));
   ;	
	push	10
	push	ds
	push	offset DGROUP:_MSEConfig
	push	di
	call	far ptr _write
	add	sp,8
   ;	
   ;	               close(temp2);
   ;	
	push	di
	call	far ptr _close
	pop	cx
   ;	
   ;	               textattr(0x07);
   ;	
	push	7
	call	far ptr _textattr
	pop	cx
   ;	
   ;	               clrscr();
   ;	
	call	far ptr _clrscr
   ;	
   ;	               printf("New configuration saved.\n\n");
   ;	
	push	ds
	push	offset DGROUP:s@+559
	call	far ptr _printf
	add	sp,4
   ;	
   ;	               _setcursortype(_NORMALCURSOR);
   ;	
	push	2
	call	far ptr __setcursortype
	pop	cx
   ;	
   ;	               exit(1);
   ;	
	push	1
	call	far ptr _exit
	pop	cx
@1@534:
   ;	
   ;	       case -1:
   ;	               textattr(0x07);
   ;	
	push	7
	call	far ptr _textattr
	pop	cx
   ;	
   ;	               clrscr();
   ;	
	call	far ptr _clrscr
   ;	
   ;	               printf("Setup aborted by user, new configuration not saved.\n");
   ;	
	push	ds
	push	offset DGROUP:s@+586
	call	far ptr _printf
	add	sp,4
   ;	
   ;	               _setcursortype(_NORMALCURSOR);
   ;	
	push	2
	call	far ptr __setcursortype
	pop	cx
   ;	
   ;	               exit(1);
   ;	
	push	1
	call	far ptr _exit
	pop	cx
@1@562:
	jmp	@1@114
   ;	
   ;	     }
   ;	  }
   ;	}
   ;	
	pop	di
	pop	si
	leave	
	ret	
_main	endp
@1@C642	label	word
	dw	@1@534
	dw	@1@394
	dw	@1@422
	dw	@1@450
	dw	@1@478
	dw	@1@506
   ;	
   ;	int PopUpMenu(char Row, char Col, char Items, char CharsWide, char *MenuHelp[]) {
   ;	
	assume	cs:SETUP_TEXT
_PopUpMenu	proc	far
	enter	2,0
   ;	
   ;	  char CurrItem = 0;
   ;	
	mov	byte ptr [bp-1],0
   ;	
   ;	  char Key;
   ;	
   ;	  textattr(0x78); gotoxy(1, 25);
   ;	
	push	120
	call	far ptr _textattr
	pop	cx
	push	25
	push	1
	call	far ptr _gotoxy
	add	sp,4
   ;	
   ;	  cprintf("%s", MenuHelp[CurrItem]); clreol();
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	shl	ax,2
	les	bx,dword ptr [bp+14]
	add	bx,ax
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	ds
	push	offset DGROUP:s@+639
	call	far ptr _cprintf
	add	sp,8
	call	far ptr _clreol
   ;	
   ;	
   ;	  Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	  XColor(0, 7); XColorFill(CharsWide);
   ;	
	push	7
	push	0
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
@2@58:
   ;	
   ;	
   ;	  for(;;) {
   ;	    Key = getch();
   ;	
	call	far ptr _getch
	mov	byte ptr [bp-2],al
   ;	
   ;	    if (Key != 0)
   ;	
	cmp	byte ptr [bp-2],0
	je	short @2@310
   ;	
   ;	     switch(Key) {
   ;	
	mov	al,byte ptr [bp-2]
	cbw	
	cmp	ax,13
	je	short @2@198
	cmp	ax,27
	je	short @2@254
	jmp	short @2@282
@2@198:
   ;	
   ;	       case 13:                           /* Enter key */
   ;	        Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	        XColor(15, 1); XColorFill(CharsWide);
   ;	
	push	1
	push	15
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	        return(CurrItem);
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
@2@226:
	jmp	@2@590
@2@254:
   ;	
   ;	       case 27:                           /* Escape key */
   ;	        Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	        XColor(15, 1); XColorFill(CharsWide);
   ;	
	push	1
	push	15
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	        return(-1);
   ;	
	mov	ax,-1
	jmp	short @2@226
@2@282:
   ;	
   ;	     }
   ;	
	jmp	@2@562
@2@310:
   ;	
   ;	    else
   ;	     switch(getch()) {
   ;	
	call	far ptr _getch
	cmp	ax,72
	je	short @2@422
	cmp	ax,80
	jne	@@1
	jmp	@2@506
@@1:
	jmp	@2@562
@2@422:
   ;	
   ;	        case 72:                            /* Up key */
   ;	         if (CurrItem > 0) {
   ;	
	cmp	byte ptr [bp-1],0
	jg	@@2
	jmp	@2@478
@@2:
   ;	
   ;	            Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	            XColor(15, 1); XColorFill(CharsWide);
   ;	
	push	1
	push	15
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	            CurrItem--;
   ;	
	dec	byte ptr [bp-1]
   ;	
   ;	            Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	            XColor(0, 7); XColorFill(CharsWide);
   ;	
	push	7
	push	0
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	
   ;	            textattr(0x78); gotoxy(1, 25);
   ;	
	push	120
	call	far ptr _textattr
	pop	cx
	push	25
	push	1
	call	far ptr _gotoxy
	add	sp,4
   ;	
   ;	            cprintf("%s", MenuHelp[CurrItem]); clreol();
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	shl	ax,2
	les	bx,dword ptr [bp+14]
	add	bx,ax
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	ds
	push	offset DGROUP:s@+642
	call	far ptr _cprintf
	add	sp,8
	call	far ptr _clreol
@2@478:
   ;	
   ;	         }
   ;	         break;
   ;	
	jmp	@2@562
@2@506:
   ;	
   ;	        case 80:                          /* Down key */
   ;	         if (CurrItem < Items - 1) {
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	push	ax
	mov	al,byte ptr [bp+10]
	cbw	
	dec	ax
	pop	dx
	cmp	dx,ax
	jl	@@3
	jmp	@2@562
@@3:
   ;	
   ;	            Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	            XColor(15, 1); XColorFill(CharsWide);
   ;	
	push	1
	push	15
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	            CurrItem++;
   ;	
	inc	byte ptr [bp-1]
   ;	
   ;	            Locate(Row + CurrItem, Col);
   ;	
	mov	al,byte ptr [bp+8]
	push	ax
	mov	al,byte ptr [bp+6]
	add	al,byte ptr [bp-1]
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	            XColor(0, 7); XColorFill(CharsWide);
   ;	
	push	7
	push	0
	call	far ptr _XColor
	add	sp,4
	mov	al,byte ptr [bp+12]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
   ;	
   ;	
   ;	            textattr(0x78); gotoxy(1, 25);
   ;	
	push	120
	call	far ptr _textattr
	pop	cx
	push	25
	push	1
	call	far ptr _gotoxy
	add	sp,4
   ;	
   ;	            cprintf("%s", MenuHelp[CurrItem]); clreol();
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	shl	ax,2
	les	bx,dword ptr [bp+14]
	add	bx,ax
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	ds
	push	offset DGROUP:s@+645
	call	far ptr _cprintf
	add	sp,8
	call	far ptr _clreol
@2@562:
	jmp	@2@58
@2@590:
   ;	
   ;	         }
   ;	     }
   ;	  }
   ;	}
   ;	
	leave	
	ret	
_PopUpMenu	endp
SETUP_TEXT	ends
_DATA	segment word public 'DATA'
	dd	DGROUP:s@+648
	dd	DGROUP:s@+715
	dd	DGROUP:s@+795
	dd	DGROUP:s@+875
	dd	DGROUP:s@+955
	dd	DGROUP:s@+1035
	dd	DGROUP:s@+1115
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
   ;	
   ;	void SelectSoundCard(void)
   ;	
	assume	cs:SETUP_TEXT
_SelectSoundCard	proc	far
	enter	30,0
   ;	
   ;	{  char *MenuHelp[] = {
   ;	
   ;	
   ;	   "Select this if you don't have a sound card or don't want any sound",
   ;	   "Gravis UltraSound from Advanced Gravis                                 -Stereo-",
   ;	   "Sound Blaster 1.xx or 100% compatibles                                 - Mono -",
   ;	   "Sound Blaster 2.xx or 100% compatibles                                 - Mono -",
   ;	   "Sound Blaster Pro or 100% compatibles                                  -Stereo-",
   ;	   "Sound Blaster 16 from Creative Labs                                    -Stereo-",
   ;	   "Pro AudioSpectrum or 100% compatibles (SoundMan 16)                    -Stereo-" };
   ;	
	lea	ax,word ptr [bp-30]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+88
	mov	cx,28
	call	far ptr F_SCOPY@
   ;	
   ;	   char temp;
   ;	
   ;	    SoundCardMenu(8, 24);
   ;	
	push	24
	push	8
	call	far ptr _SoundCardMenu
	add	sp,4
   ;	
   ;	    temp = PopUpMenu(12, 27, 7, 25, MenuHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-30]
	push	ax
	push	25
	push	7
	push	27
	push	12
	push	cs
	call	near ptr _PopUpMenu
	add	sp,12
	mov	byte ptr [bp-1],al
   ;	
   ;	    if (temp != -1) MSEConfig.SoundCard = temp;
   ;	
	cmp	byte ptr [bp-1],255
	je	short @3@86
	mov	al,byte ptr [bp-1]
	cbw	
	mov	word ptr DGROUP:_MSEConfig,ax
@3@86:
   ;	
   ;	}
   ;	
	leave	
	ret	
_SelectSoundCard	endp
SETUP_TEXT	ends
_DATA	segment word public 'DATA'
	dd	DGROUP:s@+1195
	dd	DGROUP:s@+1275
	dd	DGROUP:s@+1277
	dd	DGROUP:s@+1279
	dd	DGROUP:s@+1281
	dd	DGROUP:s@+1283
	dd	DGROUP:s@+1285
	dd	DGROUP:s@+1287
	db	255
	db	2
	db	5
	db	7
	db	10
	db	11
	db	12
	db	15
	db	255
	db	0
	db	1
	db	3
	db	5
	db	6
	db	7
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
   ;	
   ;	void SelectSoundSettings(void)
   ;	
	assume	cs:SETUP_TEXT
_SelectSoundSettings	proc	far
	enter	50,0
   ;	
   ;	{  char *MenuHelp[8] = {
   ;	
   ;	
   ;	   "Select this if you are unsure what your setting is or your setting isn't listed",
   ;	   " ", " ", " ", " ", " ", " ", " " };
   ;	
	lea	ax,word ptr [bp-50]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+116
	mov	cx,32
	call	far ptr F_SCOPY@
   ;	
   ;	   char IRQTable[] = { 0xFF, 2, 5, 7, 10, 11, 12, 15 };
   ;	
	lea	ax,word ptr [bp-8]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+148
	mov	cx,8
	call	far ptr F_SCOPY@
   ;	
   ;	   char DMATable[] = { 0xFF, 0, 1, 3, 5, 6, 7 };
   ;	
	lea	ax,word ptr [bp-16]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+156
	mov	cx,7
	call	far ptr F_SCOPY@
   ;	
   ;	   char temp;
   ;	
   ;	   BaseioMenu(8, 24);
   ;	
	push	24
	push	8
	call	far ptr _BaseioMenu
	add	sp,4
   ;	
   ;	   temp = PopUpMenu(12, 27, 7, 25, MenuHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-50]
	push	ax
	push	25
	push	7
	push	27
	push	12
	push	cs
	call	near ptr _PopUpMenu
	add	sp,12
	mov	byte ptr [bp-17],al
   ;	
   ;	   if (temp == -1) return;
   ;	
	cmp	byte ptr [bp-17],255
	jne	short @4@86
	jmp	@4@310
@4@86:
   ;	
   ;	   if (temp == 0) MSEConfig.BaseIO = 0xFFFF;
   ;	
	cmp	byte ptr [bp-17],0
	jne	short @4@142
	mov	word ptr DGROUP:_MSEConfig+2,-1
	jmp	short @4@170
@4@142:
   ;	
   ;	     else MSEConfig.BaseIO = 0x200 + temp * 0x10;
   ;	
	mov	al,byte ptr [bp-17]
	cbw	
	shl	ax,4
	add	ax,512
	mov	word ptr DGROUP:_MSEConfig+2,ax
@4@170:
   ;	
   ;	
   ;	   IRQMenu(8, 24);               // Display the IRQ menu
   ;	
	push	24
	push	8
	call	far ptr _IRQMenu
	add	sp,4
   ;	
   ;	   temp = PopUpMenu(12, 27, 8, 25, MenuHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-50]
	push	ax
	push	25
	push	8
	push	27
	push	12
	push	cs
	call	near ptr _PopUpMenu
	add	sp,12
	mov	byte ptr [bp-17],al
   ;	
   ;	   if (temp == -1) return;
   ;	
	cmp	byte ptr [bp-17],255
	jne	short @4@226
	jmp	short @4@310
@4@226:
   ;	
   ;	   MSEConfig.IRQ = IRQTable[temp];
   ;	
	mov	al,byte ptr [bp-17]
	cbw	
	lea	dx,word ptr [bp-8]
	add	ax,dx
	mov	bx,ax
	mov	al,byte ptr ss:[bx]
	cbw	
	mov	word ptr DGROUP:_MSEConfig+4,ax
   ;	
   ;	
   ;	   DMAMenu(8, 24);               // Display the DMA menu
   ;	
	push	24
	push	8
	call	far ptr _DMAMenu
	add	sp,4
   ;	
   ;	   gotoxy(25, 22); textattr(0x08); cprintf("²²²²²²²²²²²²²²²²²²²²²²²²²²²²²");
   ;	
	push	22
	push	25
	call	far ptr _gotoxy
	add	sp,4
	push	8
	call	far ptr _textattr
	pop	cx
	push	ds
	push	offset DGROUP:s@+1289
	call	far ptr _cprintf
	add	sp,4
   ;	
   ;	   temp = PopUpMenu(12, 27, 7, 25, MenuHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-50]
	push	ax
	push	25
	push	7
	push	27
	push	12
	push	cs
	call	near ptr _PopUpMenu
	add	sp,12
	mov	byte ptr [bp-17],al
   ;	
   ;	   if (temp == -1) return;
   ;	
	cmp	byte ptr [bp-17],255
	jne	short @4@282
	jmp	short @4@310
@4@282:
   ;	
   ;	   MSEConfig.DMA = DMATable[temp];
   ;	
	mov	al,byte ptr [bp-17]
	cbw	
	lea	dx,word ptr [bp-16]
	add	ax,dx
	mov	bx,ax
	mov	al,byte ptr ss:[bx]
	cbw	
	mov	word ptr DGROUP:_MSEConfig+6,ax
@4@310:
   ;	
   ;	}
   ;	
	leave	
	ret	
_SelectSoundSettings	endp
SETUP_TEXT	ends
_DATA	segment word public 'DATA'
	dd	DGROUP:s@+1319
	dd	DGROUP:s@+1398
	dd	DGROUP:s@+1477
	dd	DGROUP:s@+1556
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
   ;	
   ;	void SelectSoundQuality(void)
   ;	
	assume	cs:SETUP_TEXT
_SelectSoundQuality	proc	far
	enter	18,0
   ;	
   ;	{  char *MenuHelp[] = {
   ;	
   ;	
   ;	   "Medium Sound Quality, for slow 386s                                 (16000 Hz)",
   ;	   "High Sound Quality, for fast 386s/slow 486s                         (22000 Hz)",
   ;	   "Super-High Sound Quality, for fast 486s                             (45000 Hz)",
   ;	   "Low Sound Quality, use this if none of the above work on your system (8000 Hz)" };
   ;	
	lea	ax,word ptr [bp-18]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+163
	mov	cx,16
	call	far ptr F_SCOPY@
   ;	
   ;	   char temp;
   ;	
   ;	   QualityMenu(10, 25);                 // Pop up our Super High Quality Menu!
   ;	
	push	25
	push	10
	call	far ptr _QualityMenu
	add	sp,4
   ;	
   ;	   temp = PopUpMenu(14, 28, 4, 25, MenuHelp);
   ;	
	push	ss
	lea	ax,word ptr [bp-18]
	push	ax
	push	25
	push	4
	push	28
	push	14
	push	cs
	call	near ptr _PopUpMenu
	add	sp,12
	mov	byte ptr [bp-1],al
   ;	
   ;	   if (temp != -1) MSEConfig.SoundQuality = temp;
   ;	
	cmp	byte ptr [bp-1],255
	je	short @5@86
	mov	al,byte ptr [bp-1]
	cbw	
	mov	word ptr DGROUP:_MSEConfig+8,ax
@5@86:
   ;	
   ;	}
   ;	
	leave	
	ret	
_SelectSoundQuality	endp
   ;	
   ;	unsigned long OverLoad(char *FileName, int FileHandle) {
   ;	
	assume	cs:SETUP_TEXT
_OverLoad	proc	far
	enter	36,0
	push	si
	push	di
	mov	si,word ptr [bp+10]
   ;	
   ;	  OLHeader Header;
   ;	  OLEnd EndHeader;
   ;	  int j;
   ;	
   ;	  lseek(FileHandle, -15, SEEK_END);
   ;	
	push	2
	push	-1
	push	-15
	push	si
	call	far ptr _lseek
	add	sp,8
   ;	
   ;	
   ;	  read(FileHandle, &EndHeader, sizeof(OLEnd));
   ;	
	push	15
	push	ss
	lea	ax,word ptr [bp-36]
	push	ax
	push	si
	call	far ptr _read
	add	sp,8
   ;	
   ;	  if (strnicmp(EndHeader.ID, "OverLoader", 10) != 0)
   ;	
	push	10
	push	ds
	push	offset DGROUP:s@+1635
	push	ss
	lea	ax,word ptr [bp-36]
	push	ax
	call	far ptr _strnicmp
	add	sp,10
	or	ax,ax
	je	short @6@142
   ;	
   ;	  {  printf("Couldn't find OverLoader ID header\n");
   ;	
	push	ds
	push	offset DGROUP:s@+1646
	call	far ptr _printf
	add	sp,4
   ;	
   ;	     getch();
   ;	
	call	far ptr _getch
   ;	
   ;	     return(0);
   ;	
@6@86:
	xor	dx,dx
	xor	ax,ax
@6@114:
	jmp	short @6@338
@6@142:
   ;	
   ;	  }
   ;	
   ;	  lseek(FileHandle, EndHeader.Location - 1, SEEK_SET);
   ;	
	push	0
	mov	ax,word ptr [bp-23]
	mov	dx,word ptr [bp-25]
	sub	dx,1
	sbb	ax,0
	push	ax
	push	dx
	push	si
	call	far ptr _lseek
	add	sp,8
   ;	
   ;	
   ;	  for (j = 1; j <= EndHeader.Entries; j++)
   ;	
	mov	di,1
	jmp	short @6@254
@6@170:
   ;	
   ;	  {  read(FileHandle, &Header, sizeof(OLHeader));
   ;	
	push	20
	push	ss
	lea	ax,word ptr [bp-20]
	push	ax
	push	si
	call	far ptr _read
	add	sp,8
   ;	
   ;	     if (strnicmp(Header.FileName, FileName, 12) == 0) goto FoundFile;
   ;	
	push	12
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	ss
	lea	ax,word ptr [bp-20]
	push	ax
	call	far ptr _strnicmp
	add	sp,10
	or	ax,ax
	jne	short @6@226
	jmp	short @6@310
@6@226:
	inc	di
@6@254:
	mov	al,byte ptr [bp-26]
	mov	ah,0
	cmp	ax,di
	jge	short @6@170
	jmp	short @6@86
@6@310:
   ;	
   ;	  }
   ;	  return(0);
   ;	
   ;	  FoundFile:
   ;	  lseek(FileHandle, Header.FileLoc - 1, SEEK_SET);
   ;	
	push	0
	mov	ax,word ptr [bp-6]
	mov	dx,word ptr [bp-8]
	sub	dx,1
	sbb	ax,0
	push	ax
	push	dx
	push	si
	call	far ptr _lseek
	add	sp,8
   ;	
   ;	  return(Header.FileSize);
   ;	
	mov	dx,word ptr [bp-2]
	mov	ax,word ptr [bp-4]
	jmp	short @6@114
@6@338:
   ;	
   ;	}
   ;	
	pop	di
	pop	si
	leave	
	ret	
_OverLoad	endp
SETUP_TEXT	ends
_DATA	segment word public 'DATA'
	dd	DGROUP:s@+1682
	dd	DGROUP:s@+1690
	dd	DGROUP:s@+1699
	dd	DGROUP:s@+1708
	dd	DGROUP:s@+1718
	dd	DGROUP:s@+1727
	dd	DGROUP:s@+1735
	dd	DGROUP:s@+1774
	dd	DGROUP:s@+1806
	dd	DGROUP:s@+1840
	dd	DGROUP:s@+1866
	dd	DGROUP:s@+1867
	dd	DGROUP:s@+1897
	dd	DGROUP:s@+1929
	dd	DGROUP:s@+1968
	dd	DGROUP:s@+2001
	dd	DGROUP:s@+2062
	dd	DGROUP:s@+2084
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
   ;	
   ;	void TestSound(char *ExeName)
   ;	
	assume	cs:SETUP_TEXT
_TestSound	proc	far
	enter	236,0
	push	si
   ;	
   ;	{  GDMHeader ModHead;                // Module Header
   ;	   char *SndDevMSE[6] = { "GUS.MSE", "SB1X.MSE", "SB2X.MSE",
   ;	
   ;	
   ;	                          "SBPRO.MSE", "SB16.MSE", "PAS.MSE" };
   ;	
	lea	ax,word ptr [bp-188]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+179
	mov	cx,24
	call	far ptr F_SCOPY@
   ;	
   ;	   char *ErrorMSE[12] = {
   ;	
   ;	
   ;	   "Base I/O address autodetection failure",  //1
   ;	   "IRQ level autodetection failure",         //2
   ;	   "DMA channel autodetection failure",
   ;	   "DMA channel not supported",
   ;	   "",
   ;	   "Sound device does not respond",
   ;	   "Memory control blocks destroyed",
   ;	   "Insufficient memory for mixing buffers",
   ;	   "Insufficient memory for MSE file",
   ;	   "MSE has invalid identification string (corrupt/non-existant)",
   ;	   "MSE disk read failure",
   ;	   "MVSOUND.SYS not loaded (required for PAS use)"               };
   ;	
	lea	ax,word ptr [bp-236]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:d@w+203
	mov	cx,48
	call	far ptr F_SCOPY@
   ;	
   ;	  char temp, OverRate, j, OldOrd;
   ;	  int Handle, ErrorFlag;
   ;	
   ;	  if (MSEConfig.SoundCard == 0) return; /* If no sound, don't test it */
   ;	
	cmp	word ptr DGROUP:_MSEConfig,0
	jne	short @7@86
	jmp	@7@1010
@7@86:
   ;	
   ;	
   ;	  /* Set up our sound system: */
   ;	  OverRate = 44;
   ;	
	mov	byte ptr [bp-2],44
   ;	
   ;	  switch (MSEConfig.SoundQuality) {
   ;	
	mov	bx,word ptr DGROUP:_MSEConfig+8
	cmp	bx,3
	ja	short @7@310
	shl	bx,1
	jmp	word ptr cs:@7@C1042[bx]
@7@198:
   ;	
   ;	     case 0: OverRate = 16; break;
   ;	
	mov	byte ptr [bp-2],16
	jmp	short @7@310
@7@226:
   ;	
   ;	     case 1: OverRate = 22; break;
   ;	
	mov	byte ptr [bp-2],22
	jmp	short @7@310
@7@254:
   ;	
   ;	     case 2: OverRate = 45; break;
   ;	
	mov	byte ptr [bp-2],45
	jmp	short @7@310
@7@282:
   ;	
   ;	     case 3: OverRate = 8; break;
   ;	
	mov	byte ptr [bp-2],8
	jmp	short @7@310
@7@310:
   ;	
   ;	  }
   ;	  temp = LoadMSE(SndDevMSE[MSEConfig.SoundCard-1],
   ;	
   ;	
   ;	                 0,
   ;	                 OverRate,
   ;	                 4096,
   ;	                 &MSEConfig.BaseIO,
   ;	                 &MSEConfig.IRQ,
   ;	                 &MSEConfig.DMA);
   ;	
	push	ds
	push	offset DGROUP:_MSEConfig+6
	push	ds
	push	offset DGROUP:_MSEConfig+4
	push	ds
	push	offset DGROUP:_MSEConfig+2
	push	4096
	mov	al,byte ptr [bp-2]
	push	ax
	push	0
	push	0
	mov	bx,word ptr DGROUP:_MSEConfig
	dec	bx
	shl	bx,2
	lea	ax,word ptr [bp-188]
	add	bx,ax
	push	word ptr ss:[bx+2]
	push	word ptr ss:[bx]
	call	far ptr _LoadMSE
	add	sp,24
	mov	byte ptr [bp-1],al
   ;	
   ;	
   ;	  if (temp)
   ;	
	cmp	byte ptr [bp-1],0
	jne	@@4
	jmp	@7@450
@@4:
   ;	
   ;	  {  ErrorScreen(14, 4);
   ;	
	push	4
	push	14
	call	far ptr _ErrorScreen
	add	sp,4
   ;	
   ;	     textattr(0x74); gotoxy(19, 16); cprintf("%u", temp);
   ;	
	push	116
	call	far ptr _textattr
	pop	cx
	push	16
	push	19
	call	far ptr _gotoxy
	add	sp,4
	mov	al,byte ptr [bp-1]
	cbw	
	push	ax
	push	ds
	push	offset DGROUP:s@+2130
	call	far ptr _cprintf
	add	sp,6
   ;	
   ;	     textattr(0x1F); gotoxy(16, 18);
   ;	
	push	31
	call	far ptr _textattr
	pop	cx
	push	18
	push	16
	call	far ptr _gotoxy
	add	sp,4
   ;	
   ;	     if (temp <= 12) cprintf("%s", ErrorMSE[temp-1]);
   ;	
	cmp	byte ptr [bp-1],12
	jg	short @7@394
	mov	al,byte ptr [bp-1]
	cbw	
	shl	ax,2
	lea	dx,word ptr [bp-240]
	add	ax,dx
	mov	bx,ax
	push	word ptr ss:[bx+2]
	push	word ptr ss:[bx]
	push	ds
	push	offset DGROUP:s@+2133
	call	far ptr _cprintf
	add	sp,8
	jmp	short @7@422
@7@394:
   ;	
   ;	     else cprintf("Unknown error");
   ;	
	push	ds
	push	offset DGROUP:s@+2136
	call	far ptr _cprintf
	add	sp,4
@7@422:
   ;	
   ;	     getch();
   ;	
	call	far ptr _getch
@7@450:
   ;	
   ;	  }
   ;	
   ;	  Handle = open(ExeName, O_RDONLY | O_BINARY);
   ;	
	push	-32767
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	call	far ptr _open
	add	sp,6
	mov	si,ax
   ;	
   ;	  OverLoad("SLIMJIMS.GDM", Handle);
   ;	
	push	si
	push	ds
	push	offset DGROUP:s@+2150
	push	cs
	call	near ptr _OverLoad
	add	sp,6
   ;	
   ;	  /* Load our module */
   ;	  LoadGDM(Handle, lseek(Handle, 0, SEEK_CUR), &ErrorFlag, &ModHead);
   ;	
	push	ss
	lea	ax,word ptr [bp-164]
	push	ax
	push	ss
	lea	ax,word ptr [bp-6]
	push	ax
	push	1
	push	0
	push	0
	push	si
	call	far ptr _lseek
	add	sp,8
	push	dx
	push	ax
	push	si
	call	far ptr _LoadGDM
	add	sp,14
   ;	
   ;	  close(Handle);
   ;	
	push	si
	call	far ptr _close
	pop	cx
   ;	
   ;	  if (ErrorFlag) {
   ;	
	cmp	word ptr [bp-6],0
	je	short @7@506
   ;	
   ;	     ErrorScreen(14, 4);
   ;	
	push	4
	push	14
	call	far ptr _ErrorScreen
	add	sp,4
   ;	
   ;	     textattr(0x74); gotoxy(19, 16); cprintf("%u", ErrorFlag);
   ;	
	push	116
	call	far ptr _textattr
	pop	cx
	push	16
	push	19
	call	far ptr _gotoxy
	add	sp,4
	push	word ptr [bp-6]
	push	ds
	push	offset DGROUP:s@+2163
	call	far ptr _cprintf
	add	sp,6
   ;	
   ;	     textattr(0x1F); gotoxy(16, 18);
   ;	
	push	31
	call	far ptr _textattr
	pop	cx
	push	18
	push	16
	call	far ptr _gotoxy
	add	sp,4
   ;	
   ;	     cprintf("Error loading GDM music file\n");
   ;	
	push	ds
	push	offset DGROUP:s@+2166
	call	far ptr _cprintf
	add	sp,4
   ;	
   ;	     getch();
   ;	
	call	far ptr _getch
   ;	
   ;	     return;
   ;	
	jmp	@7@1010
@7@506:
   ;	
   ;	  }
   ;	
   ;	  temp = 0;                          /* Start out at zero.. */
   ;	
	mov	byte ptr [bp-1],0
   ;	
   ;	  for (j = 1; j <= 32; j++) if (ModHead.PanMap[j] != 0xFF) temp++;
   ;	
	mov	byte ptr [bp-3],1
	jmp	short @7@618
@7@534:
	mov	al,byte ptr [bp-3]
	cbw	
	lea	dx,word ptr [bp-83]
	add	ax,dx
	mov	bx,ax
	cmp	byte ptr ss:[bx],255
	je	short @7@590
	inc	byte ptr [bp-1]
@7@590:
	inc	byte ptr [bp-3]
@7@618:
	cmp	byte ptr [bp-3],32
	jle	short @7@534
   ;	
   ;	
   ;	  StartOutput(temp, 0);              // Start your (sound) engines
   ;	
	push	0
	mov	al,byte ptr [bp-1]
	push	ax
	call	far ptr _StartOutput
	add	sp,4
   ;	
   ;	  StartMusic();                      // Revv up the music playing
   ;	
	call	far ptr _StartMusic
   ;	
   ;	
   ;	  TestScreen(10, 9);
   ;	
	push	9
	push	10
	call	far ptr _TestScreen
	add	sp,4
   ;	
   ;	  textattr(0x1F);
   ;	
	push	31
	call	far ptr _textattr
	pop	cx
   ;	
   ;	  gotoxy(19, 14); cprintf("%s", ModHead.SongTitle);
   ;	
	push	14
	push	19
	call	far ptr _gotoxy
	add	sp,4
	push	ss
	lea	ax,word ptr [bp-160]
	push	ax
	push	ds
	push	offset DGROUP:s@+2196
	call	far ptr _cprintf
	add	sp,8
   ;	
   ;	  gotoxy(22, 15); cprintf("%s", ModHead.SongMusician);
   ;	
	push	15
	push	22
	call	far ptr _gotoxy
	add	sp,4
	push	ss
	lea	ax,word ptr [bp-128]
	push	ax
	push	ds
	push	offset DGROUP:s@+2199
	call	far ptr _cprintf
	add	sp,8
   ;	
   ;	
   ;	  OldOrd = 2;
   ;	
	mov	byte ptr [bp-4],2
@7@674:
   ;	
   ;	  do
   ;	  {  for (j = 1; j <= 4; j++)
   ;	
	mov	byte ptr [bp-3],1
	jmp	@7@842
@7@702:
   ;	
   ;	     {  temp = ChannelVU(j, ChannelVU(j, 0xFF) - 1) / 2;
   ;	
	push	255
	mov	al,byte ptr [bp-3]
	push	ax
	call	far ptr _ChannelVU
	add	sp,4
	add	al,255
	push	ax
	mov	al,byte ptr [bp-3]
	push	ax
	call	far ptr _ChannelVU
	add	sp,4
	cwd	
	sub	ax,dx
	sar	ax,1
	mov	byte ptr [bp-1],al
   ;	
   ;	        if (temp)
   ;	
	cmp	byte ptr [bp-1],0
	je	short @7@758
   ;	
   ;	        {  Locate(15 + j, 12);
   ;	
	push	12
	mov	al,byte ptr [bp-3]
	add	al,15
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	           XColor(10, 1);
   ;	
	push	1
	push	10
	call	far ptr _XColor
	add	sp,4
   ;	
   ;	           XColorFill(temp);
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	push	ax
	call	far ptr _XColorFill
	pop	cx
@7@758:
   ;	
   ;	        }
   ;	        if (16 - temp)
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	mov	dx,16
	sub	dx,ax
	je	short @7@814
   ;	
   ;	        { Locate(15 + j, 12 + temp);
   ;	
	mov	al,byte ptr [bp-1]
	add	al,12
	push	ax
	mov	al,byte ptr [bp-3]
	add	al,15
	push	ax
	call	far ptr _Locate
	add	sp,4
   ;	
   ;	          XColor(0, 1);
   ;	
	push	1
	push	0
	call	far ptr _XColor
	add	sp,4
   ;	
   ;	          XColorFill(16 - temp);
   ;	
	mov	al,byte ptr [bp-1]
	cbw	
	mov	dx,16
	sub	dx,ax
	push	dx
	call	far ptr _XColorFill
	pop	cx
@7@814:
	inc	byte ptr [bp-3]
@7@842:
	cmp	byte ptr [bp-3],4
	jg	@@5
	jmp	@7@702
@@5:
   ;	
   ;	        }
   ;	     }
   ;	     temp = MusicOrder(0xFF);
   ;	
	push	255
	call	far ptr _MusicOrder
	pop	cx
	mov	byte ptr [bp-1],al
   ;	
   ;	     if (temp != OldOrd)
   ;	
	mov	al,byte ptr [bp-1]
	cmp	al,byte ptr [bp-4]
	jne	@@6
	jmp	@7@926
@@6:
   ;	
   ;	     {  textattr(0x1A);
   ;	
	push	26
	call	far ptr _textattr
	pop	cx
   ;	
   ;	        gotoxy(29 + temp * 6, 17); cprintf("ÛÛÛÛÛÛ");
   ;	
	push	17
	mov	al,byte ptr [bp-1]
	cbw	
	imul	ax,ax,6
	add	ax,29
	push	ax
	call	far ptr _gotoxy
	add	sp,4
	push	ds
	push	offset DGROUP:s@+2202
	call	far ptr _cprintf
	add	sp,4
   ;	
   ;	        gotoxy(29 + temp * 6, 18); cprintf("ÛÛÛÛÛÛ");
   ;	
	push	18
	mov	al,byte ptr [bp-1]
	cbw	
	imul	ax,ax,6
	add	ax,29
	push	ax
	call	far ptr _gotoxy
	add	sp,4
	push	ds
	push	offset DGROUP:s@+2209
	call	far ptr _cprintf
	add	sp,4
   ;	
   ;	        textattr(0x1F);
   ;	
	push	31
	call	far ptr _textattr
	pop	cx
   ;	
   ;	        gotoxy(29 + OldOrd * 6, 17); cprintf("±±±±±±");
   ;	
	push	17
	mov	al,byte ptr [bp-4]
	cbw	
	imul	ax,ax,6
	add	ax,29
	push	ax
	call	far ptr _gotoxy
	add	sp,4
	push	ds
	push	offset DGROUP:s@+2216
	call	far ptr _cprintf
	add	sp,4
   ;	
   ;	        gotoxy(29 + OldOrd * 6, 18); cprintf("±±±±±±");
   ;	
	push	18
	mov	al,byte ptr [bp-4]
	cbw	
	imul	ax,ax,6
	add	ax,29
	push	ax
	call	far ptr _gotoxy
	add	sp,4
	push	ds
	push	offset DGROUP:s@+2223
	call	far ptr _cprintf
	add	sp,4
@7@926:
   ;	
   ;	     }
   ;	     OldOrd = temp;
   ;	
	mov	al,byte ptr [bp-1]
	mov	byte ptr [bp-4],al
   ;	
   ;	     textattr(0x1F);
   ;	
	push	31
	call	far ptr _textattr
	pop	cx
   ;	
   ;	     gotoxy(64, 14); cprintf("Row: %u ", MusicRow());
   ;	
	push	14
	push	64
	call	far ptr _gotoxy
	add	sp,4
	call	far ptr _MusicRow
	mov	ah,0
	push	ax
	push	ds
	push	offset DGROUP:s@+2230
	call	far ptr _cprintf
	add	sp,6
   ;	
   ;	  } while (!kbhit());
   ;	
	call	far ptr _kbhit
	or	ax,ax
	jne	@@7
	jmp	@7@674
@@7:
   ;	
   ;	  getch();
   ;	
	call	far ptr _getch
   ;	
   ;	  FreeMSE();
   ;	
	call	far ptr _FreeMSE
@7@1010:
   ;	
   ;	}
   ;	
	pop	si
	leave	
	ret	
_TestSound	endp
@7@C1042	label	word
	dw	@7@198
	dw	@7@226
	dw	@7@254
	dw	@7@282
SETUP_TEXT	ends
_BSS	segment word public 'BSS'
_MSEConfig	label	word
	db	10 dup (?)
	?debug	C E9
	?debug	C FA00000000
_BSS	ends
_DATA	segment word public 'DATA'
s@	label	byte
	db	' BWSB Music and Sound Engine Setup      Copyright (c) 1993-95'
	db	', Edward Schlunder'
	db	0
	db	'Select Sound Card for digital music and sound effects'
	db	0
	db	'Select Sound Card configuration settings (Address, IRQ number'
	db	', DMA channel)'
	db	0
	db	'Select sound quality level'
	db	0
	db	'Load MSE and try playing music'
	db	0
	db	'Exit and save new setup'
	db	0
	db	'NONE (Silence)   '
	db	0
	db	'Gravis UltraSound'
	db	0
	db	'Sound Blaster 1.x'
	db	0
	db	'Sound Blaster 2.x'
	db	0
	db	'Sound Blaster Pro'
	db	0
	db	'Sound Blaster 16 '
	db	0
	db	'Pro AudioSpectrum'
	db	0
	db	'Medium Sound Quality    '
	db	0
	db	'High Sound Quality      '
	db	0
	db	'Super-High Sound Quality'
	db	0
	db	'Low Sound Quality       '
	db	0
	db	'MSE.CFG'
	db	0
	db	'%s'
	db	0
	db	'%s'
	db	0
	db	'FFF'
	db	0
	db	'%X'
	db	0
	db	'%u'
	db	0
	db	'FF'
	db	0
	db	'%X'
	db	0
	db	'%s'
	db	0
	db	'MSE.CFG'
	db	0
	db	'New configuration saved.'
	db	10
	db	10
	db	0
	db	'Setup aborted by user, new configuration not saved.'
	db	10
	db	0
	db	'%s'
	db	0
	db	'%s'
	db	0
	db	'%s'
	db	0
	db	'Select this if you don'
	db	39
	db	't have a sound card or don'
	db	39
	db	't want any sound'
	db	0
	db	'Gravis UltraSound from Advanced Gravis                       '
	db	'          -Stereo-'
	db	0
	db	'Sound Blaster 1.xx or 100% compatibles                       '
	db	'          - Mono -'
	db	0
	db	'Sound Blaster 2.xx or 100% compatibles                       '
	db	'          - Mono -'
	db	0
	db	'Sound Blaster Pro or 100% compatibles                        '
	db	'          -Stereo-'
	db	0
	db	'Sound Blaster 16 from Creative Labs                          '
	db	'          -Stereo-'
	db	0
	db	'Pro AudioSpectrum or 100% compatibles (SoundMan 16)          '
	db	'          -Stereo-'
	db	0
	db	'Select this if you are unsure what your setting is or your se'
	db	'tting isn'
	db	39
	db	't listed'
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	' '
	db	0
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	-78
	db	0
	db	'Medium Sound Quality, for slow 386s                          '
	db	'       (16000 Hz)'
	db	0
	db	'High Sound Quality, for fast 386s/slow 486s                  '
	db	'       (22000 Hz)'
	db	0
	db	'Super-High Sound Quality, for fast 486s                      '
	db	'       (45000 Hz)'
	db	0
	db	'Low Sound Quality, use this if none of the above work on your'
	db	' system (8000 Hz)'
	db	0
	db	'OverLoader'
	db	0
	db	'Couldn'
	db	39
	db	't find OverLoader ID header'
	db	10
	db	0
	db	'GUS.MSE'
	db	0
	db	'SB1X.MSE'
	db	0
	db	'SB2X.MSE'
	db	0
	db	'SBPRO.MSE'
	db	0
	db	'SB16.MSE'
	db	0
	db	'PAS.MSE'
	db	0
	db	'Base I/O address autodetection failure'
	db	0
	db	'IRQ level autodetection failure'
	db	0
	db	'DMA channel autodetection failure'
	db	0
	db	'DMA channel not supported'
	db	0
	db	0
	db	'Sound device does not respond'
	db	0
	db	'Memory control blocks destroyed'
	db	0
	db	'Insufficient memory for mixing buffers'
	db	0
	db	'Insufficient memory for MSE file'
	db	0
	db	'MSE has invalid identification string (corrupt/non-existant)'
	db	0
	db	'MSE disk read failure'
	db	0
	db	'MVSOUND.SYS not loaded (required for PAS use)'
	db	0
	db	'%u'
	db	0
	db	'%s'
	db	0
	db	'Unknown error'
	db	0
	db	'SLIMJIMS.GDM'
	db	0
	db	'%u'
	db	0
	db	'Error loading GDM music file'
	db	10
	db	0
	db	'%s'
	db	0
	db	'%s'
	db	0
	db	-37
	db	-37
	db	-37
	db	-37
	db	-37
	db	-37
	db	0
	db	-37
	db	-37
	db	-37
	db	-37
	db	-37
	db	-37
	db	0
	db	-79
	db	-79
	db	-79
	db	-79
	db	-79
	db	-79
	db	0
	db	-79
	db	-79
	db	-79
	db	-79
	db	-79
	db	-79
	db	0
	db	'Row: %u '
	db	0
_DATA	ends
SETUP_TEXT	segment byte public 'CODE'
SETUP_TEXT	ends
	extrn	F_SCOPY@:far
	extrn	__setargv__:far
	public	_main
	public	_Copyright
	public	_MSEConfig
	extrn	_Locate:far
	extrn	_XColorFill:far
	extrn	_XColor:far
	extrn	_ErrorScreen:far
	extrn	_TestScreen:far
	extrn	_QualityMenu:far
	extrn	_DMAMenu:far
	extrn	_IRQMenu:far
	extrn	_BaseioMenu:far
	extrn	_SoundCardMenu:far
	extrn	_MainMenu:far
	public	_PopUpMenu
	public	_SelectSoundSettings
	public	_SelectSoundCard
	public	_SelectSoundQuality
	public	_TestSound
	public	_OverLoad
	extrn	_write:far
	extrn	_read:far
	extrn	_open:far
	extrn	_lseek:far
	extrn	_close:far
	extrn	_cprintf:far
	extrn	__setcursortype:far
	extrn	_textattr:far
	extrn	_kbhit:far
	extrn	_getch:far
	extrn	_gotoxy:far
	extrn	_clrscr:far
	extrn	_clreol:far
	extrn	_strnicmp:far
	extrn	_exit:far
	extrn	_printf:far
	extrn	_LoadGDM:far
	extrn	_ChannelVU:far
	extrn	_MusicRow:far
	extrn	_MusicOrder:far
	extrn	_StartMusic:far
	extrn	_StartOutput:far
	extrn	_FreeMSE:far
	extrn	_LoadMSE:far
_s@	equ	s@
	end
