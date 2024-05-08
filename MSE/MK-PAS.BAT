@echo off
if exist pas.obj goto LinkIt
tasm.exe pas /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link pas;
execom pas.exe ..\demo\pas.mse
touch ..\demo\pas
del pas.obj
