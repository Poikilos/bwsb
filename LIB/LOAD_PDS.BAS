DECLARE FUNCTION DeviceName$ ()
'��������������������������������������������������������������������������
'                      Bells, Whistles, and Sound Boards
'       Copyright (c) 1993-95, Edward Schlunder. All Rights Reserved.
'��������������������������������������������������������������������������
' LOADMSE - Music/sound engine loading routines for BWSB.
'           Written by Edward Schlunder (1993-95)
'
'��������������������������������������������������������������������������
DEFINT A-Z

DECLARE FUNCTION xLoadMSE% (FSeg%, FOff%, FileOff&, OvrRate%, BufSize%, Addr%, IRQ%, DMA%)
DECLARE SUB SoundDeviceName (NameSeg%, NameOff%)
DECLARE FUNCTION LoadMSE% (MSE$, FileOff&, OverRate%, BufferSize%, BaseIO%, IRQ%, DMA%)

FUNCTION DeviceName$
Temp$ = SPACE$(20)
SoundDeviceName SSEG(Temp$), SADD(Temp$)
DeviceName$ = LEFT$(Temp$, INSTR(Temp$, CHR$(0)))
END FUNCTION

FUNCTION LoadMSE (MSE$, FileOff&, OverRate, BufferSize, BaseIO, IRQ, DMA)
FileName$ = MSE$ + CHR$(0)

LoadMSE = xLoadMSE(SSEG(FileName$), SADD(FileName$), FileOff&, OverRate, BufferSize, BaseIO, IRQ, DMA)
END FUNCTION

