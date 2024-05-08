;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;                   Copyright (c) 1993-97, Edward Schlunder
;                 See COPYING.ES for redistribution details.
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; BWSB.INC - BWSB library routine declarations for ASM/Large Model only.
;            Written by Edward Schlunder (1995)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
extrn   LoadMSE:far
extrn   DeviceName:far
extrn   FreeMSE:far
extrn   StartOutput:far
extrn   StopOutput:far
extrn   StopBanner:far

extrn   MixForground:far
extrn   MixStatus:far
extrn   SetAutoMix:far

extrn   StartMusic:far
extrn   StopMusic:far
extrn   AmigaHertz:far
extrn   MusicStatus:far
extrn   MusicBPM:far
extrn   MusicTempo:far
extrn   MusicOrder:far
extrn   MusicPattern:far
extrn   MusicRow:far
extrn   MusicLoop:far
extrn   MusicVolume:far

extrn   ChannelPan:far
extrn   ChannelVU:far
extrn   ChannelVol:far
extrn   ChannelPos:far

extrn   AllocSample:far
extrn   FreeSample:far
extrn   PlaySample:far

extrn   GetChannelTable:far
extrn   GetSampleTable:far
extrn   GetMainScope:far

extrn   LoadGDM:far
extrn   UnloadModule:far
extrn   EmsExist:far
