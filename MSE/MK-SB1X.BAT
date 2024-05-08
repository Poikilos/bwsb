@echo off
if exist sb1x.obj goto LinkIt
tasm.exe sb1x /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link sb1x;
execom sb1x.exe ..\demo\sb1x.mse
touch ..\demo\sb1x
del sb1x.obj
