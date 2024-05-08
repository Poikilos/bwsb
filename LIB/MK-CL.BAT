@ECHO off
DEL      mse_cl.lib
TASM.EXE c_mse /jmasm51 /jquirks /m9 /i..\INCLUDE /ml /dLMM
TASM.EXE ems_c /jmasm51 /jquirks /m9 /i..\INCLUDE /ml /dLMM
LIB      mse_cl.lib c_mse.obj, nul;
DEL      c_mse.obj
DEL      ems_c.obj
