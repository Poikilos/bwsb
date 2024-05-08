 {ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
 {              Bells, Whistles, and Sound Boards. Version 1.04             }
 {       Copyright (C) 1993-94, Edward Schlunder. All Rights Reserved.      }
 {ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ}
 { TTP.BAS - Example game using BWSB sound effects                          }
 {           Written by Alex Chalfin (1994)                                 }
 {                                                                          }
 {ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{ NOTE: You cannot compile this. The units used in this game are not      }
{  included, as they do not contain code important to the playing of the  }
{  music/sound effects. All the source code is included in the registered }
{  version of BWSB. If you aren't registering BWSB, but interested in     }
{  the routines used here, feel free to contact me (Alex)                 }

{$M 16384,0,0}              { Always make some room for music and sounds! }
{$G+}
Program Bubble_Gunner;

Uses
   Crt, Stuff, MSE_TP, MCGA, Vector;

Var
  ShotsFired : Longint;
  TargetsHit : Longint;
  StartTime  : Longint;
  EndTime    : Longint;
  Time : Longint Absolute $0000:$046c;

Function GetSoundDevice : String;

Begin
  Writeln('Choose Sound Device: ');
  Writeln;
  Writeln(' 1. Gravis Ultrasound');
  Writeln(' 2. Sound Blaster 1.xx');
  Writeln(' 3. Sound Blaster 2.xx');
  Writeln(' 4. Sound Blaster Pro');
  Writeln(' 5. Sound Blaster 16');
  Writeln(' 6. Pro AudioSpectrum');
  Case ReadKey of
    '1' : GetSoundDevice := 'GUS.MSE';
    '2' : GetSoundDevice := 'SB1X.MSE';
    '3' : GetSoundDevice := 'SB2X.MSE';
    '4' : GetSoundDevice := 'SBPRO.MSE';
    '5' : GetSoundDevice := 'SB16.MSE';
    '6' : GetSoundDevice := 'PAS.MSE';
    Else EndProg('Invalid Sound Device');
  End;
End;

Function GetBaseIO : Word;

Begin
  Writeln;
  Writeln('Select Base I/O Address:');
  Writeln;
  Writeln(' 1. 210h');
  Writeln(' 2. 220h');
  Writeln(' 3. 230h');
  Writeln(' 4. 240h');
  Writeln(' 5. 250h');
  Writeln(' 6. 260h');
  Writeln(' Anything else - Autodetect.');
  Case ReadKey of
    '1' : GetBaseIO := $210;
    '2' : GetBaseIO := $220;
    '3' : GetBaseIO := $230;
    '4' : GetBaseIO := $240;
    '5' : GetBaseIO := $250;
    '6' : GetBaseIO := $260;
    Else GetBaseIO := $FFFF;
  End;
End;

Function GetIRQ : Byte;

Begin
  Writeln;
  Writeln('Select IRQ Level:');
  Writeln;
  Writeln(' 1. IRQ 2');
  Writeln(' 2. IRQ 5');
  Writeln(' 3. IRQ 7');
  Writeln(' 4. IRQ 11');
  Writeln(' 5. IRQ 12');
  Writeln(' Anything else - Autodetect.');
  Case ReadKey of
    '1' : GetIRQ := 2;
    '2' : GetIRQ := 5;
    '3' : GetIRQ := 7;
    '4' : GetIRQ := 11;
    '5' : GetIRQ := 12;
    Else GetIRQ := $FF;
  End;
End;

Function GetDMA : Byte;

Begin
  Writeln;
  Writeln('Select DMA Channel:');
  Writeln;
  Writeln(' 1. DMA 1');
  Writeln(' 2. DMA 2');
  Writeln(' 3. DMA 3');
  Writeln(' 4. DMA 5');
  Writeln(' Anything else - Autodetect.');
  Case ReadKey of
    '1' : GetDMA := 1;
    '2' : GetDMA := 2;
    '3' : GetDMA := 3;
    '4' : GetDMA := 5;
    Else GetDMA := $FF;
  End;
End;

Procedure InitSound;

Var
  BaseIO : Word;
  IRQ : Byte;
  DMA : Byte;
  Handle : File;
  Header : GDMHeader;
  ErrorCode : Word;
  Channels : Word;
  DriverName : String;

Begin
  DriverName := GetSoundDevice;
  BaseIO := GetBaseIO;
  IRQ := GetIRQ;
  DMA := GetDMA;
  ErrorCode := LoadMSE(DriverName, 0, 45, 4096, BaseIO, IRQ, DMA);
  If ErrorCode <> 0
    Then EndProg('Could not initialize sound device');
  ExitProc := @FreeMSE;

{$I-}
  Assign(Handle, 'TTP.GDM');        { Open the module for loading }
  Reset(Handle);
{$I+}
  If IOResult <> 0 Then
     EndProg('Could not open TTP.GDM');
  ErrorCode := 0;                               { Don't use EMS }
  Writeln('Loading GDM');
  ErrorCode := LoadGDM(Handle, 0, ErrorCode, Header);
  If ErrorCode <> 0
    Then EndProg('Could not load TTP.GDM');
  Close(Handle);

  Channels := 0;
  For ErrorCode := 1 to 32 do
    If Header.PanMap[ErrorCode] <> $FF
      Then Channels := Channels + 1;
  ErrorCode := StartOutput(Channels + 2, 0);
  StartMusic;
End;


Procedure DoPlayLoop;

Var
  LRAngle, UDAngle : Integer;
  TargetHit : Boolean;
  Fired, Quit : Boolean;
  Side : Integer;
  Time : Longint Absolute $0000:$046c;

Begin
  Frames := 0;
  ShotsFired := 0;
  TargetsHit := 0;
  Side := 1;
  LRAngle := 256;
  UDAngle := 256;
  Quit := False;
  Fired := False;
  TargetHit := False;
  InitCircle;
  Randomize;
  StartTime := Time;
  Repeat
    SpawnTarget(Random(511), -((Random(700) - 350) + 1000), Random(1500) + 800);
    Repeat
      Frames := Frames + 1;
      GetKeyStuff(LRAngle, UDAngle, Fired, Quit);
      If Quit
        Then Exit;
      If Fired
        Then Begin
          ShotsFired := ShotsFired + 1;

(* Play the laser sample (sample #8) on Channel 5 at 8000 Hz.               *)
(* Use higest volume (63), and switch pan position based on the side of the *)
(* laser blast (-1 And 15) = 15, (1 and 15) = 1                             *)

          Side := -Side;
          PlaySample(5, 7, 8000, 63, Side And 15);  { Laser blast sound }

          TargetHit := CheckHit;
        End;
      DisplayIt(Fired, Side, LRAngle, UDAngle);
    Until (TargetHit);
    TargetHit := False;
    TargetsHit := TargetsHit + 1;

(* Do the explosion sound effect.                      *)
(* Play sample 9 on channel 6 at 8000 Hz.              *)
(* Use maximum volume (63) and middle pan position (8) *)

    PlaySample(6, 8, 8000, 63, 8);    { Do explosion sound }
    DrawExplosion;
  Until False;
End;

Begin
  InitSound;
  InitGraphics;
  InitStars;
  SetPalette;
  TitleScreen;
  KickKBDaemon;
  StartTime := Time;
  DoPlayLoop;
  EndTime := Time;
  FreeKBDaemon;
  CleanUp;
  StopMusic;
  StopOutput;
  UnloadModule;
  FreeMSE;
  If ShotsFired = 0
    Then Writeln('No shots fired.')
    Else Writeln('Hit percentage: ',(TargetsHit/ShotsFired)*100:2:0, '%' );
  If (EndTime-StartTime) > 0
    Then Writeln(Frames*18.2/(EndTime-StartTime):5:2, ' fps');
End.