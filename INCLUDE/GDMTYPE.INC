;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;                     Bells, Whistles, and Sound Boards
;       Copyright (c) 1993-97, Edward Schlunder
;                 See COPYING.ES for redistribution details.
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; GDMTYPE.INC - GDM module header/sample type definitions.
;               Written by Edward Schlunder (1995)
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GDMHeader      Struc
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
  Tempo         db      6                   ;Initial music tempo (6)
  BPM           db      125                 ;Initial music BPM (125)
  FormOrigin    dw      ?                   ;Original format ID
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
GDMHeader      EndS

SamHeader      Struc    ;12345678901234567890123456789012
 SamName        db      32 dup (0)     ;Instrument's full name                 32 32
 SamFileName    db      12 dup (0)     ;Sample's file name                     12 44
 SamHandle      db      0              ;EMS Handle for this sample             1  45
 SamLen         dd      0              ;Sample length                          4  49
 SamBegin       dd      0              ;Sample loop begin                      4  53
 SamEnd         dd      0              ;Sample loop end                        4  57
 SamFlags       db      0              ;Sample flags                           1  58
 SamTune        dw      0              ;C-4Hz. 8363 normal                     2  60
 SamVol         db      0              ;Sample's default volume                1  61
 SamPan         db      0              ;Memory Location(MSN)/Pan Position(LSN) 1  62
 SamSeg         dw      0              ;Segment/Page/Address of sample         2  64
SamHeader      EndS

SamHeader2     Struc    ;12345678901234567890123456789012
 SamName        db      32 dup (0)     ;Instrument's full name                 32 32
 SamFileName    db      12 dup (0)     ;Sample's file name                     12 44
 SamHandle      db      0              ;EMS Handle for this sample             1  45
 SamLen         dd      0              ;Sample length                          4  49
 SamBegin       dd      0              ;Sample loop begin                      4  53
 SamEnd         dd      0              ;Sample loop end                        4  57
 SamFlags       db      0              ;Sample flags                           1  58
 SamTune        dw      0              ;C-4Hz. 8363 normal                     2  60
 SamVol         db      0              ;Sample's default volume                1  61
 SamPan         db      0              ;Memory Location(MSN)/Pan Position(LSN) 1  62
SamHeader2     EndS
