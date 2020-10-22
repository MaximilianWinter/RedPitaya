-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.2 (lin64) Build 1909853 Thu Jun 15 18:39:10 MDT 2017
-- Date        : Thu Oct 15 13:59:34 2020
-- Host        : maximilian-laptop running 64-bit Ubuntu 18.04.5 LTS
-- Command     : write_vhdl -force -mode funcsim
--               {/home/maximilian/LRZ_Sync+Share/Studium/WS2021/HiWi_MPQ/Lukas_Projekt/Pulse Stabilization Red
--               Pitaya/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.srcs/sources_1/bd/system/ip/system_xlconstant_0/system_xlconstant_0_sim_netlist.vhdl}
-- Design      : system_xlconstant_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7z010clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_xlconstant_0 is
  port (
    dout : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of system_xlconstant_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of system_xlconstant_0 : entity is "system_xlconstant_0,xlconstant_v1_1_3_xlconstant,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of system_xlconstant_0 : entity is "yes";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of system_xlconstant_0 : entity is "xlconstant_v1_1_3_xlconstant,Vivado 2017.2";
end system_xlconstant_0;

architecture STRUCTURE of system_xlconstant_0 is
  signal \<const1>\ : STD_LOGIC;
begin
  dout(0) <= \<const1>\;
VCC: unisim.vcomponents.VCC
     port map (
      P => \<const1>\
    );
end STRUCTURE;
