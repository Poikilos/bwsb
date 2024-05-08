@echo off
if exist sb16.obj goto LinkIt
tasm.exe sb16 /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link sb16;
execom sb16.exe ..\demo\sb16.mse
touch ..\demo\sb16
del sb16.obj
