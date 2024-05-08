@echo off
if exist sbpro.obj goto LinkIt
tasm.exe sbpro /jmasm51 /jquirks /m9 /i..\INCLUDE

:LinkIt
link sbpro;
execom sbpro.exe ..\demo\sbpro.mse
touch ..\demo\sbpro
del sbpro.obj
