@Echo Off
rem --------------
rem  FOR PDS ONLY
rem --------------
:Compile
Echo Compiling 2GDM.BAS to 2GDM.OBJ
BC /G2/S/O/Fs 2GDM.BAS;

Echo Linking 2GDM.OBJ to make 2GDM.EXE
LINK /NOE 2GDM.OBJ AMIGAPC.OBJ NOEDIT.OBJ NOCOM.OBJ NOLPT.OBJ,2GDM.EXE,nul /W;
lzexe 2gdm.exe

del 2gdm.old
del 2gdm.obj
:End
