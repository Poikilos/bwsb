@ECHO off
if exist ems.obj goto MasmIt
MASM  ems;

:MasmIt
if exist qbx_mse.obj goto BcIt
MASM  qbx_mse;

:BcIt
BC    load_qb /O/S;
DEL   mse_qb.lib
LIB   mse_qb.lib +ems.obj+qbx_mse.obj+load_qb.obj+qb.lib, nul;
LINK  /Q mse_qb.lib, mse_qb.qlb, nul, BQLB45.LIB;
