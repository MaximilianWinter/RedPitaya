-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.2 (lin64) Build 1909853 Thu Jun 15 18:39:10 MDT 2017
-- Date        : Thu Oct 15 13:59:34 2020
-- Host        : maximilian-laptop running 64-bit Ubuntu 18.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               {/home/maximilian/LRZ_Sync+Share/Studium/WS2021/HiWi_MPQ/Lukas_Projekt/Pulse Stabilization Red
--               Pitaya/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.srcs/sources_1/bd/system/ip/system_xlconstant_0/system_xlconstant_0_stub.vhdl}
-- Design      : system_xlconstant_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z010clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity system_xlconstant_0 is
  Port ( 
    dout : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end system_xlconstant_0;

architecture stub of system_xlconstant_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "dout[0:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "xlconstant_v1_1_3_xlconstant,Vivado 2017.2";
begin
end;
