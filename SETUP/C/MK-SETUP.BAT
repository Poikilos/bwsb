@echo off
echo Compiling SETUP.C
bcc -ml -2 setup.c print.obj screen.obj vgadetec.obj ..\..\lib\mse_cl.lib

echo Compressing SETUP.EXE
lzexe setup.exe

Echo Adding data files to EXE
..\..\util\ol SETUP.EXE SETUP.GDM
del setup.obj
del setup.old
