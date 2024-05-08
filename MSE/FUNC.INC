;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Function Vector Table Begins Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-95, Edward Schlunder. Written by Edward Schlunder
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;ฤฤ MSE Functions ฤ
Function00      dd      Offset LoadMSE
Function01      dd      Offset FreeMSE
Function02      dd      Offset StartOutput
Function03      dd      Offset StopOutput
Function04      dd      Offset MixStatus
Function05      dd      Offset MixForground
Function06      dd      Offset SetAutoMix
Function07      dd      ?
Function08      dd      ?
Function09      dd      ?
Function10      dd      ?
Function11      dd      ?
Function12      dd      ?
Function13      dd      ?
Function14      dd      ?
Function15      dd      ?
Function16      dd      ?
Function17      dd      ?
Function18      dd      ?
Function19      dd      ?

;ฤฤ Music Functions ฤ
Function20      dd      Offset StartMusic
Function21      dd      Offset StopMusic
Function22      dd      Offset AmigaHertz
Function23      dd      Offset MusicEnable
Function24      dd      Offset MusicBPM
Function25      dd      Offset MusicTempo
Function26      dd      Offset MusicOrder
Function27      dd      Offset MusicPattern
Function28      dd      Offset MusicRow
Function29      dd      Offset MusicLoop
Function30      dd      Offset MusicVolume
Function31      dd      ?
Function32      dd      ?
Function33      dd      ?
Function34      dd      ?
Function35      dd      ?
Function36      dd      ?
Function37      dd      ?
Function38      dd      ?
Function39      dd      ?
Function40      dd      ?

;ฤฤ Sound Functions ฤ
Function41      dd      Offset PlaySample
Function42      dd      ?
Function43      dd      ?
Function44      dd      Offset GetChannelTable
Function45      dd      Offset ChannelPan
Function46      dd      Offset ChannelVU
Function47      dd      Offset ChannelVol
Function48      dd      Offset ChannelPos
Function49      dd      Offset GetSampleTable
Function50      dd      Offset GetMainScope
Function51      dd      ?
Function52      dd      ?
Function53      dd      ?
Function54      dd      ?
Function55      dd      ?
Function56      dd      ?
Function57      dd      ?
Function58      dd      ?
Function59      dd      ?

;ฤฤ Load Functions ฤ
Function60      dd      Offset RegisterSample
Function61      dd      Offset RegisterPatterns
Function62      dd      Offset RegisterOrders
Function63      dd      ?
Function64      dd      Offset UnloadModule
Function65      dd      Offset CopyDRAM
Function66      dd      Offset LoadGDM
Function67      dd      Offset AddSample
Function68      dd      Offset SubSample
