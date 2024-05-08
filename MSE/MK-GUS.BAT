@echo off
if exist gus.obj goto LinkIt
tasm.exe gus /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link gus;
execom gus.exe ..\demo\gus.mse
touch ..\demo\gus
del gus.obj
