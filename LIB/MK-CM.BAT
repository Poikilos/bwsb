@ECHO off
DEL      mse_cm.lib
TASM.EXE c_mse /jmasm51 /jquirks /m9 /i..\INCLUDE /ml
TASM.EXE ems_c /jmasm51 /jquirks /m9 /i..\INCLUDE /ml
LIB      mse_cm.lib c_mse.obj, nul;
DEL      c_mse.obj
DEL      ems_c.obj
