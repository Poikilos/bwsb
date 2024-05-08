;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;              Bells, Whistles, and Sound Boards. Version 0.99
;       Copyright (C) 1993-94, Edward Schlunder. 
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; GDMSTRUC.INC - GDM module header/sample structure definitions for ASM
;                Written by Edward Schlunder (1994)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

GDMStruc       Struc
  ID            db      'GDMş'              ;Magic file ID
  SongTitle     db      32 dup (?)          ;Music's title
  SongMusician  db      32 dup (?)          ;Name of music's composer
  DOSEOF        db      10, 13, 26
  ID2           db      'GDMF'              ;ID: 'GDMF'
  FormMajorVer  db      ?                   ;Format major version
  FormMinorVer  db      ?                   ;Format minor version
  TrackID       dw      ?                   ;Composing Tracker ID code
  TrackMajorVer db      ?                   ;Tracker's major version
  TrackMinorVer db      ?                   ;Tracker's minor version
  PanMap        db      32 dup (?)          ;0-Left to 15-Right, 255-N/U
  MastVol       db      64                  ;Global music volume 0..64
  xTempo        db      6                   ;Initial music tempo (6)
  xBPM          db      125                 ;Initial music BPM (125)
  xFlags2       dw      ?                   ;Music flags
  OrdOffset     dd      ?
  NOO           db      ?                   ;Number of orders in module
  PatOffset     dd      ?
  xNOP          db      ?                   ;Number of patterns in module
  SamHeadOffset dd      ?
  SamOffset     dd      ?
  NOS           db      ?
  MTOffset      dd      ?
  MTLength      dd      ?
  SSOffset      dd      ?
  SSLength      dw      ?
  TGOffset      dd      ?
  TGLength      dw      ?
GDMStruc       EndS

SamHeader      Struc
  xSamName      db      32 dup (?)     ;32
  FileName      db      12 dup (?)     ;44
  xEmsHandle    db      ?              ;45
  xLength       dd      ?              ;49
  LoopBegin     dd      ?              ;53
  xLoopEnd      dd      ?              ;57
  xFlags        db      ?              ;58
  C4Hertz       dw      8363           ;60
  Volume        db      64             ;61
  Pan           db      0FFh           ;62
  xSegment      dw      ?
SamHeader      EndS

