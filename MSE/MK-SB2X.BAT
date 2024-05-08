@echo off
if exist sb2x.obj goto LinkIt
tasm.exe sb2x /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link sb2x;
execom sb2x.exe ..\demo\sb2x.mse
touch ..\demo\sb2x
del sb2x.obj
