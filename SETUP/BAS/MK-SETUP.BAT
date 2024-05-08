@Echo Off
Echo Compiling SETUP.BAS to SETUP.OBJ
BC SETUP.BAS /O/Ot/G2/S/Fs/FPi/T;

Echo Linking SETUP.OBJ and MSE_PDS.LIB to make SETUP.EXE
LINK /CO /NOE /F SETUP PRINT SCREEN NOEDIT NOCOM NOLPT NOEMS SMALLERR,,nul,..\..\LIB\MSE_PDS.LIB;
LZEXE setup.exe
del setup.obj
del setup.old

Echo Adding data files
..\..\util\ol setup.exe slimjims.gdm >nul
