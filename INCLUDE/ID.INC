;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Version and ID Information Begins Here
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;    Copyright (c) 1993-97, Edward Schlunder. Written by Edward Schlunder
;                 See COPYING.ES for redistribution details.
;                                     ฤ-ZLฤ-
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
MajorVersion EQU     1
MinorVersion EQU     21
BBVer        EQU     'v1.21'           ;Must equal 5 bytes - EXACTLY!
NumberFunc   EQU     68                ;If you add/remove functions in FUNC.INC,
                                       ;you must update this value too!

Evaluation   EQU     0                 ;Compile for: 0-Registered, 1-Evaluation
IF Evaluation
 BWSBCopy     EQU    'BWSB Music and Sound Engine v1.21 þ See COPYING.ES for redist details.  '
 BWSBCopy2    EQU    'Copyright (c) 1993-97, Edward Schlunder (zilym@aztec.asu.edu)  '
 SignBanner   EQU    'BWSB is free software distributed under the GNU GPL. See COPYING.ES       '
 IDString     EQU    'BWSB 1.21GNU'    ;Do not change this!
ELSE
 BWSBCopy     EQU    'BWSB Music and Sound Engine is Copyright (c) 1993-97, Edward Schlunder. All Rights Reserved. [BWSB 1.21GNU]'
 IDString     EQU    'BWSB 1.21GNU'    ;Do not change this! hehehe
ENDIF
