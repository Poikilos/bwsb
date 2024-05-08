@Echo Off
Rem
Rem MAKE.BAT   - Multiple make file for BWSB
Rem              Written by Edward Schlunder (1995)
Rem
cls

IF PBMMP==%1 goto PbMakeMmp
IF pbmmp==%1 goto PbMakeMmp

IF PDSMMP==%1 goto PdsMakeMmp
IF pdsmmp==%1 goto PdsMakeMmp

IF QBMMP==%1 goto QbMakeMmp
IF qbmmp==%1 goto QbMakeMmp

IF PDSSND==%1 goto PdsMakeSndPad
IF pdssnd==%1 goto PdsMakeSndPad

IF QBSND==%1 goto QbMakeSndPad
IF qbsnd==%1 goto QbMakeSndPad

IF PLAY==%1 goto TpMakePlay
IF play==%1 goto TpMakePlay

IF SCOPE==%1 goto TpMakeScope
IF scope==%1 goto TpMakeScope

IF TTP==%1 goto TpMakeTTP
IF ttp==%1 goto TpMakeTTP

IF CL==%1 goto CMakeLarge
IF cl==%1 goto CMakeLarge

IF CM==%1 goto CMakeMedium
IF cm==%1 goto CMakeMedium

IF CHL==%1 goto CHMakeLarge
IF chl==%1 goto CHMakeLarge

IF CHM==%1 goto CHMakeMedium
IF chm==%1 goto CHMakeMedium

IF TPLAY==%1 goto MakeTPlay
IF tplay==%1 goto MakeTPlay

echo MAKE.BAT - Multiple make file for example BWSB programs
echo            Written by Edward Schlunder (1995)
echo ÿ
echo Usage: MAKE prog [ENTER]
echo ÿ
echo where prog can be:
echo [PB]    PBMMP    - Make Minature Module Player
echo [PDS]   PDSMMP   - Make Minature Module Player
echo [QB]    QBMMP    - Make Minature Module Player
echo [PDS]   PDSSND   - Make Sound Pad
echo [QB]    QBSND    - Make Sound Pad
echo [TP]    PLAY     - Make GDMPLAY module player
echo [TP]    SCOPE    - Make GDMSCOPE module player
echo [TP]    TTP      - Make Tailgunner's Target Practice game
echo [C/C++] CL       - Make PLAYC using Large memory model (Borland C)
echo [C/C++] CM       - Make PLAYC using Medium memory model (Borland C)
echo [C/C++] CHL      - Make CHPLAY using Large memory model (Borland C)
echo [C/C++] CHM      - Make CHPLAY using Medium memory model (Borland C)
echo [ASM]   TPLAY    - Make TPLAY using large memory model (TASM)
goto End

:MakeTPlay
  echo Making TPLAY.EXE using TASM.
  echo ÿ
  echo ÿ

  tasm.exe tplay /um510 /m9 /i..\INCLUDE
  tlink -3 tplay ..\lib\mse_asm
  lzexe tplay.exe
  del tplay.old
  del tplay.map
  del tplay.obj
  goto End

:CMakeMedium
  echo Making PLAYC.EXE (Medium Model) for Borland C/C++
  echo ÿ
  echo ÿ

  BCC -l3 -mm -2 playc.c ..\lib\mse_cm.lib
  lzexe playc.exe
  del playc.old
  del playc.map
  del playc.obj

  goto End

:CMakeLarge
  echo Making PLAYC.EXE (Large Model) for Borland C/C++
  echo ÿ
  echo ÿ

  BCC -l3 -ml -2 playc.c ..\lib\mse_cl.lib
  lzexe playc.exe
  del playc.old
  del playc.map
  del playc.obj

  goto End

:CHMakeLarge
  echo Making CHPLAY.EXE (Large Model) for Borland C/C++
  echo ÿ
  echo ÿ

  BCC -l3 -ml -2 chplay.c ..\lib\mse_cl.lib
  lzexe chplay.exe

  echo Adding data files
  ol chplay.exe gus.mse >nul
  ol chplay.exe sb1x.mse >nul
  ol chplay.exe sb2x.mse >nul
  ol chplay.exe sbpro.mse >nul
  ol chplay.exe sb16.mse >nul
  ol chplay.exe pas.mse >nul

  del chplay.old
  del chplay.map
  del chplay.obj

  goto End

:CHMakeMedium
  echo Making CHPLAY.EXE (Medium Model) for Borland C/C++
  echo ÿ
  echo ÿ

  BCC -l3 -mm -2 chplay.c ..\lib\mse_cm.lib
  lzexe chplay.exe

  echo Adding data files
  ol chplay.exe gus.mse >nul
  ol chplay.exe sb1x.mse >nul
  ol chplay.exe sb2x.mse >nul
  ol chplay.exe sbpro.mse >nul
  ol chplay.exe sb16.mse >nul
  ol chplay.exe pas.mse >nul

  del chplay.old
  del chplay.map
  del chplay.obj

  goto End

:TpMakeScope
  echo Make GDMSCOPE.EXE for Turbo Pascal
  echo ÿ
  if exist ..\lib\mse_tp.tpu goto skiptpu
  echo Making MSE_TP.TPU..
  tpc ..\lib\mse_tp /O..\LIB
  :skiptpu
  Echo Make GDMSCOPE.EXE using ..\LIB\MSE_TP.TPU
  tpc gdmscope /U..\LIB

  lzexe gdmscope.exe
  del gdmscope.old

  goto End

:TpMakeTTP
  echo Make TTP.EXE for Turbo Pascal
  echo ÿ
  if exist ..\lib\mse_tp.tpu goto skiptpu3
  echo Making MSE_TP.TPU..
  tpc ..\lib\mse_tp /O..\LIB
  :skiptpu3
  cd ..\ttp
  if exist ..\ttp\mcga.tpu goto skipttptpu
  echo Making the TPUs required by TTP.EXE
  call mk-tpu.bat

  :skipttptpu
  Echo Make TTP.EXE using ..\LIB\MSE_TP.TPU
  tpc ttp /U..\LIB
  copy ttp.exe ..\demo
  del ttp.exe
  cd ..\demo
  
  lzexe ttp.exe
  del ttp.old

  goto End

:TpMakePlay
  echo Make GDMPLAY.EXE for Turbo Pascal
  echo ÿ
  if exist ..\lib\mse_tp.tpu goto skiptpu2

  echo Making MSE_TP.TPU..
  tpc ..\lib\mse_tp /O..\LIB

  :skiptpu2
  Echo Make GDMPLAY.EXE using ..\LIB\MSE_TP.TPU
  tpc gdmplay /U..\LIB

  lzexe gdmplay.exe
  del gdmplay.old
  goto End

:PbMakeMmp
  echo Making PBMMP.EXE for PB 3.x
  echo ÿ
  echo Compiling PBMMP.BAS..

  PBC pbmmp.bas

  lzexe PBMMP.EXE

  del pbmmp.obj
  del pbmmp.map
  del pbmmp.old
  goto End

:PdsMakeMmp
  echo Making MMP.EXE for PDS 7.x
  echo ÿ
  echo Compiling MMP.BAS to MMP.OBJ

  BC mmp.bas /O/G2/S/Fs/FPi/T;

  echo Linking MMP.OBJ and MSE_PDS.LIB to make MMP.EXE
  LINK /CO /NOE /F mmp nofltin noevent smallerr noems nograph noedit nocom nolpt,,,..\lib\mse_pds.lib;

  lzexe MMP.EXE

  del mmp.obj
  del mmp.map
  del mmp.old
  goto End

:QbMakeMmp
  echo Making MMP.EXE for QB 4.5
  echo ÿ
  echo Compiling MMP.BAS to MMP.OBJ

  BC mmp.bas /O/S/FPi/T;

  echo Linking MMP.OBJ and MSE_QB.LIB to make MMP.EXE
  LINK /CO /NOE /F mmp,,,..\lib\mse_qb.lib;

  lzexe MMP.EXE

  del mmp.obj
  del mmp.map
  del mmp.old
  goto End

:PdsMakeSndPad
  echo Making SND-PAD.EXE for PDS 7.x
  echo ÿ
  echo Compiling SND-PAD.BAS to SND-PAD.OBJ

  BC SND-PAD.bas /O/G2/S/Fs/FPi/T;

  echo Linking SND-PAD.OBJ and MSE_PDS.LIB to make SND-PAD.EXE
  LINK /CO /NOE /F snd-pad nofltin noevent smallerr noems nograph noedit nocom nolpt,,,..\lib\mse_pds.lib;

  lzexe snd-pad.EXE

  del snd-pad.obj
  del snd-pad.map
  del snd-pad.old
  goto End

:QbMakeSndPad
  echo Making SND-PAD.EXE for QB 4.5
  echo ÿ
  echo Compiling SND-PAD.BAS to SND-PAD.OBJ

  BC snd-pad.bas /O/S/FPi/T;

  echo Linking SND-PAD.OBJ and MSE_QB.LIB to make SND-PAD.EXE
  LINK /CO /NOE /F snd-pad,,,..\lib\mse_qb.lib;

  lzexe SND-PAD.EXE

  del snd-pad.obj
  del snd-pad.map
  del snd-pad.old
  goto End

:End