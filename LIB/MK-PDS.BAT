@ECHO off
if exist ems.obj goto MasmIt
MASM  ems;

:MasmIt
if exist qbx_mse.obj goto BcIt
MASM  qbx_mse;

:BcIt
BC    load_pds /O/G2/S/Fs/FPi/T;
DEL   mse_pds.lib
LIB   mse_pds.lib ems.obj+qbx_mse.obj+load_pds.obj+qbx.lib, nul;
LINK  /Q mse_pds.lib, mse_pds.qlb, nul, QBXQLB.LIB;
