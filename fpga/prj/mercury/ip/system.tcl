
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2017.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
set design_name system

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set GPIO [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO ]
  set M_AXI_GP0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_GP0 ]
  set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.CLK_DOMAIN {system_M_AXI_GP0_ACLK} \
CONFIG.DATA_WIDTH {32} \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_REGION {0} \
CONFIG.NUM_READ_OUTSTANDING {8} \
CONFIG.NUM_WRITE_OUTSTANDING {8} \
CONFIG.PROTOCOL {AXI3} \
 ] $M_AXI_GP0
  set S_AXI_LA [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXI_LA ]
  set_property -dict [ list \
CONFIG.CLK_DOMAIN {system_M_AXI_GP0_ACLK} \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.TDATA_NUM_BYTES {2} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $S_AXI_LA
  set S_AXI_OSC0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXI_OSC0 ]
  set_property -dict [ list \
CONFIG.CLK_DOMAIN {system_M_AXI_GP0_ACLK} \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.TDATA_NUM_BYTES {2} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $S_AXI_OSC0
  set S_AXI_OSC1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXI_OSC1 ]
  set_property -dict [ list \
CONFIG.CLK_DOMAIN {system_M_AXI_GP0_ACLK} \
CONFIG.FREQ_HZ {125000000} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TREADY {1} \
CONFIG.HAS_TSTRB {0} \
CONFIG.LAYERED_METADATA {undef} \
CONFIG.TDATA_NUM_BYTES {2} \
CONFIG.TDEST_WIDTH {0} \
CONFIG.TID_WIDTH {0} \
CONFIG.TUSER_WIDTH {0} \
 ] $S_AXI_OSC1
  set Vaux0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0 ]
  set Vaux1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1 ]
  set Vaux8 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8 ]
  set Vaux9 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9 ]
  set Vp_Vn [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn ]

  # Create ports
  set FCLK_CLK0 [ create_bd_port -dir O -type clk FCLK_CLK0 ]
  set FCLK_CLK1 [ create_bd_port -dir O -type clk FCLK_CLK1 ]
  set FCLK_CLK2 [ create_bd_port -dir O -type clk FCLK_CLK2 ]
  set FCLK_CLK3 [ create_bd_port -dir O -type clk FCLK_CLK3 ]
  set FCLK_RESET0_N [ create_bd_port -dir O -type rst FCLK_RESET0_N ]
  set FCLK_RESET1_N [ create_bd_port -dir O -type rst FCLK_RESET1_N ]
  set FCLK_RESET2_N [ create_bd_port -dir O -type rst FCLK_RESET2_N ]
  set FCLK_RESET3_N [ create_bd_port -dir O -type rst FCLK_RESET3_N ]
  set IRQ [ create_bd_port -dir I -from 5 -to 0 -type intr IRQ ]
  set_property -dict [ list \
CONFIG.PortWidth {6} \
CONFIG.SENSITIVITY {EDGE_RISING} \
 ] $IRQ
  set M_AXI_GP0_ACLK [ create_bd_port -dir I -type clk M_AXI_GP0_ACLK ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {M_AXI_GP0:S_AXI_LA:S_AXI_OSC0:S_AXI_OSC1} \
CONFIG.CLK_DOMAIN {system_M_AXI_GP0_ACLK} \
CONFIG.FREQ_HZ {125000000} \
 ] $M_AXI_GP0_ACLK
  set M_AXI_GP0_ARESETn [ create_bd_port -dir I -type rst M_AXI_GP0_ARESETn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $M_AXI_GP0_ARESETn

  # Create instance: axi_dma_la, and set properties
  set axi_dma_la [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_la ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_la

  # Create instance: axi_dma_osc0, and set properties
  set axi_dma_osc0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_osc0 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_s2mm_burst_size {16} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_osc0

  # Create instance: axi_dma_osc1, and set properties
  set axi_dma_osc1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_osc1 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_include_s2mm_dre {0} \
CONFIG.c_include_sg {1} \
CONFIG.c_s2mm_burst_size {16} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_osc1

  # Create instance: axi_intc_0, and set properties
  set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0 ]
  set_property -dict [ list \
CONFIG.C_HAS_FAST {0} \
CONFIG.C_IRQ_CONNECTION {1} \
CONFIG.C_NUM_SW_INTR {0} \
CONFIG.C_S_AXI_ACLK_FREQ_MHZ {125.0} \
 ] $axi_intc_0

  # Create instance: axi_interconnect_dma_sg, and set properties
  set axi_interconnect_dma_sg [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_dma_sg ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {3} \
 ] $axi_interconnect_dma_sg

  # Create instance: axi_interconnect_sys, and set properties
  set axi_interconnect_sys [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_sys ]
  set_property -dict [ list \
CONFIG.NUM_MI {5} \
 ] $axi_interconnect_sys

  # Create instance: axi_prot_conv_osc0, and set properties
  set axi_prot_conv_osc0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_prot_conv_osc0 ]

  # Create instance: axi_prot_conv_osc1, and set properties
  set axi_prot_conv_osc1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_prot_conv_osc1 ]

  # Create instance: axi_protocol_converter_la, and set properties
  set axi_protocol_converter_la [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_converter_la ]

  # Create instance: axis_clock_converter_la, and set properties
  set axis_clock_converter_la [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_la ]

  # Create instance: axis_clock_converter_osc0, and set properties
  set axis_clock_converter_osc0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_osc0 ]

  # Create instance: axis_clock_converter_osc1, and set properties
  set axis_clock_converter_osc1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_osc1 ]

  # Create instance: proc_sys_reset, and set properties
  set proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset ]
  set_property -dict [ list \
CONFIG.C_EXT_RST_WIDTH {1} \
 ] $proc_sys_reset

  # Create instance: processing_system7, and set properties
  set processing_system7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7 ]
  set_property -dict [ list \
CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {125.000000} \
CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {142.857132} \
CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {250.000000} \
CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_CLK0_FREQ {125000000} \
CONFIG.PCW_CLK1_FREQ {142857132} \
CONFIG.PCW_CLK2_FREQ {200000000} \
CONFIG.PCW_CLK3_FREQ {250000000} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_ENET_RESET_ENABLE {1} \
CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
CONFIG.PCW_EN_CLK1_PORT {1} \
CONFIG.PCW_EN_CLK2_PORT {1} \
CONFIG.PCW_EN_CLK3_PORT {1} \
CONFIG.PCW_EN_EMIO_GPIO {1} \
CONFIG.PCW_EN_EMIO_TTC0 {1} \
CONFIG.PCW_EN_ENET0 {1} \
CONFIG.PCW_EN_GPIO {1} \
CONFIG.PCW_EN_I2C0 {1} \
CONFIG.PCW_EN_QSPI {1} \
CONFIG.PCW_EN_RST1_PORT {1} \
CONFIG.PCW_EN_RST2_PORT {1} \
CONFIG.PCW_EN_RST3_PORT {1} \
CONFIG.PCW_EN_SDIO0 {1} \
CONFIG.PCW_EN_SPI1 {1} \
CONFIG.PCW_EN_TTC0 {1} \
CONFIG.PCW_EN_UART0 {1} \
CONFIG.PCW_EN_UART1 {1} \
CONFIG.PCW_EN_USB0 {1} \
CONFIG.PCW_FCLK_CLK1_BUF {TRUE} \
CONFIG.PCW_FCLK_CLK2_BUF {TRUE} \
CONFIG.PCW_FCLK_CLK3_BUF {TRUE} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} \
CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {250} \
CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK2_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK3_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_IO {24} \
CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {24} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
CONFIG.PCW_I2C0_I2C0_IO {MIO 50 .. 51} \
CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {111.111115} \
CONFIG.PCW_I2C_RESET_ENABLE {1} \
CONFIG.PCW_I2C_RESET_SELECT {Share reset pin} \
CONFIG.PCW_IRQ_F2P_INTR {1} \
CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_0_PULLUP {disabled} \
CONFIG.PCW_MIO_0_SLEW {slow} \
CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_10_PULLUP {enabled} \
CONFIG.PCW_MIO_10_SLEW {slow} \
CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_11_PULLUP {enabled} \
CONFIG.PCW_MIO_11_SLEW {slow} \
CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_12_PULLUP {enabled} \
CONFIG.PCW_MIO_12_SLEW {slow} \
CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_13_PULLUP {enabled} \
CONFIG.PCW_MIO_13_SLEW {slow} \
CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_14_PULLUP {enabled} \
CONFIG.PCW_MIO_14_SLEW {slow} \
CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_15_PULLUP {enabled} \
CONFIG.PCW_MIO_15_SLEW {slow} \
CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_16_PULLUP {disabled} \
CONFIG.PCW_MIO_16_SLEW {fast} \
CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_17_PULLUP {disabled} \
CONFIG.PCW_MIO_17_SLEW {fast} \
CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_18_PULLUP {disabled} \
CONFIG.PCW_MIO_18_SLEW {fast} \
CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_19_PULLUP {disabled} \
CONFIG.PCW_MIO_19_SLEW {fast} \
CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_1_PULLUP {enabled} \
CONFIG.PCW_MIO_1_SLEW {slow} \
CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_20_PULLUP {disabled} \
CONFIG.PCW_MIO_20_SLEW {fast} \
CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_21_PULLUP {disabled} \
CONFIG.PCW_MIO_21_SLEW {fast} \
CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_22_PULLUP {disabled} \
CONFIG.PCW_MIO_22_SLEW {fast} \
CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_23_PULLUP {disabled} \
CONFIG.PCW_MIO_23_SLEW {fast} \
CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_24_PULLUP {disabled} \
CONFIG.PCW_MIO_24_SLEW {fast} \
CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_25_PULLUP {disabled} \
CONFIG.PCW_MIO_25_SLEW {fast} \
CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_26_PULLUP {disabled} \
CONFIG.PCW_MIO_26_SLEW {fast} \
CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_27_PULLUP {disabled} \
CONFIG.PCW_MIO_27_SLEW {fast} \
CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_28_PULLUP {disabled} \
CONFIG.PCW_MIO_28_SLEW {fast} \
CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_29_PULLUP {disabled} \
CONFIG.PCW_MIO_29_SLEW {fast} \
CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_2_SLEW {slow} \
CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_30_PULLUP {disabled} \
CONFIG.PCW_MIO_30_SLEW {fast} \
CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_31_PULLUP {disabled} \
CONFIG.PCW_MIO_31_SLEW {fast} \
CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_32_PULLUP {disabled} \
CONFIG.PCW_MIO_32_SLEW {fast} \
CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_33_PULLUP {disabled} \
CONFIG.PCW_MIO_33_SLEW {fast} \
CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_34_PULLUP {disabled} \
CONFIG.PCW_MIO_34_SLEW {fast} \
CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_35_PULLUP {disabled} \
CONFIG.PCW_MIO_35_SLEW {fast} \
CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_36_PULLUP {disabled} \
CONFIG.PCW_MIO_36_SLEW {fast} \
CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_37_PULLUP {disabled} \
CONFIG.PCW_MIO_37_SLEW {fast} \
CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_38_PULLUP {disabled} \
CONFIG.PCW_MIO_38_SLEW {fast} \
CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_39_PULLUP {disabled} \
CONFIG.PCW_MIO_39_SLEW {fast} \
CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_3_SLEW {slow} \
CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_40_PULLUP {enabled} \
CONFIG.PCW_MIO_40_SLEW {slow} \
CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_41_PULLUP {enabled} \
CONFIG.PCW_MIO_41_SLEW {slow} \
CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_42_PULLUP {enabled} \
CONFIG.PCW_MIO_42_SLEW {slow} \
CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_43_PULLUP {enabled} \
CONFIG.PCW_MIO_43_SLEW {slow} \
CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_44_PULLUP {enabled} \
CONFIG.PCW_MIO_44_SLEW {slow} \
CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_45_PULLUP {enabled} \
CONFIG.PCW_MIO_45_SLEW {slow} \
CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_46_PULLUP {enabled} \
CONFIG.PCW_MIO_46_SLEW {slow} \
CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_47_PULLUP {enabled} \
CONFIG.PCW_MIO_47_SLEW {slow} \
CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_48_PULLUP {enabled} \
CONFIG.PCW_MIO_48_SLEW {slow} \
CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_49_PULLUP {enabled} \
CONFIG.PCW_MIO_49_SLEW {slow} \
CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_4_SLEW {slow} \
CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_50_PULLUP {enabled} \
CONFIG.PCW_MIO_50_SLEW {slow} \
CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_51_PULLUP {enabled} \
CONFIG.PCW_MIO_51_SLEW {slow} \
CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_52_PULLUP {enabled} \
CONFIG.PCW_MIO_52_SLEW {slow} \
CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 2.5V} \
CONFIG.PCW_MIO_53_PULLUP {enabled} \
CONFIG.PCW_MIO_53_SLEW {slow} \
CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_5_SLEW {slow} \
CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_6_SLEW {slow} \
CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_7_SLEW {slow} \
CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_8_SLEW {slow} \
CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_9_PULLUP {enabled} \
CONFIG.PCW_MIO_9_SLEW {slow} \
CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#UART 1#UART 1#SPI 1#SPI 1#SPI 1#SPI 1#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#USB Reset#GPIO#I2C 0#I2C 0#Enet 0#Enet 0} \
CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_sclk#gpio[7]#tx#rx#mosi#miso#sclk#ss[0]#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#cd#wp#reset#gpio[49]#scl#sda#mdc#mdio} \
CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 2.5V} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 46} \
CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
CONFIG.PCW_SD0_GRP_WP_IO {MIO 47} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SPI1_SPI1_IO {MIO 10 .. 15} \
CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_SPI_PERIPHERAL_VALID {1} \
CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} \
CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {32} \
CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {32} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_UART1_UART1_IO {MIO 8 .. 9} \
CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} \
CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_USB0_RESET_ENABLE {1} \
CONFIG.PCW_USB0_RESET_IO {MIO 48} \
CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
CONFIG.PCW_USB_RESET_ENABLE {1} \
CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_USE_M_AXI_GP1 {1} \
CONFIG.PCW_USE_S_AXI_GP0 {1} \
CONFIG.PCW_USE_S_AXI_HP0 {1} \
CONFIG.PCW_USE_S_AXI_HP1 {1} \
CONFIG.PCW_USE_S_AXI_HP2 {1} \
 ] $processing_system7

  # Create instance: xadc, and set properties
  set xadc [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc ]
  set_property -dict [ list \
CONFIG.CHANNEL_ENABLE_VAUXP0_VAUXN0 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP1_VAUXN1 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP8_VAUXN8 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP9_VAUXN9 {true} \
CONFIG.CHANNEL_ENABLE_VP_VN {true} \
CONFIG.ENABLE_AXI4STREAM {false} \
CONFIG.ENABLE_RESET {false} \
CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN} \
CONFIG.INTERFACE_SELECTION {Enable_AXI} \
CONFIG.SEQUENCER_MODE {Off} \
CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
CONFIG.XADC_STARUP_SELECTION {independent_adc} \
 ] $xadc

  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {1} \
CONFIG.NUM_WRITE_OUTSTANDING {1} \
 ] [get_bd_intf_pins /xadc/s_axi_lite]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {5} \
 ] $xlconcat_0

  # Create instance: xlconstant, and set properties
  set xlconstant [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant ]

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_dma_osc0/M_AXI_SG] [get_bd_intf_pins axi_interconnect_dma_sg/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_LA [get_bd_intf_ports S_AXI_LA] [get_bd_intf_pins axis_clock_converter_la/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_OSC0 [get_bd_intf_ports S_AXI_OSC0] [get_bd_intf_pins axis_clock_converter_osc0/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_OSC1 [get_bd_intf_ports S_AXI_OSC1] [get_bd_intf_pins axis_clock_converter_osc1/S_AXIS]
  connect_bd_intf_net -intf_net Vaux0_1 [get_bd_intf_ports Vaux0] [get_bd_intf_pins xadc/Vaux0]
  connect_bd_intf_net -intf_net Vaux1_1 [get_bd_intf_ports Vaux1] [get_bd_intf_pins xadc/Vaux1]
  connect_bd_intf_net -intf_net Vaux8_1 [get_bd_intf_ports Vaux8] [get_bd_intf_pins xadc/Vaux8]
  connect_bd_intf_net -intf_net Vaux9_1 [get_bd_intf_ports Vaux9] [get_bd_intf_pins xadc/Vaux9]
  connect_bd_intf_net -intf_net Vp_Vn_1 [get_bd_intf_ports Vp_Vn] [get_bd_intf_pins xadc/Vp_Vn]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_SG [get_bd_intf_pins axi_dma_osc1/M_AXI_SG] [get_bd_intf_pins axi_interconnect_dma_sg/S01_AXI]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXI_SG [get_bd_intf_pins axi_dma_la/M_AXI_SG] [get_bd_intf_pins axi_interconnect_dma_sg/S02_AXI]
  connect_bd_intf_net -intf_net axi_dma_la_M_AXI_S2MM [get_bd_intf_pins axi_dma_la/M_AXI_S2MM] [get_bd_intf_pins axi_protocol_converter_la/S_AXI]
  connect_bd_intf_net -intf_net axi_dma_osc0_M_AXI_S2MM [get_bd_intf_pins axi_dma_osc0/M_AXI_S2MM] [get_bd_intf_pins axi_prot_conv_osc0/S_AXI]
  connect_bd_intf_net -intf_net axi_dma_osc1_M_AXI_S2MM [get_bd_intf_pins axi_dma_osc1/M_AXI_S2MM] [get_bd_intf_pins axi_prot_conv_osc1/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_sys/M00_AXI] [get_bd_intf_pins xadc/s_axi_lite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_dma_osc0/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_sys/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_dma_osc1/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_sys/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_dma_la/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_sys/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_dma_sg/M00_AXI] [get_bd_intf_pins processing_system7/S_AXI_GP0]
  connect_bd_intf_net -intf_net axi_interconnect_sys_M04_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins axi_interconnect_sys/M04_AXI]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_pins axi_prot_conv_osc0/M_AXI] [get_bd_intf_pins processing_system7/S_AXI_HP0]
  connect_bd_intf_net -intf_net axi_protocol_converter_osc1_M_AXI [get_bd_intf_pins axi_protocol_converter_la/M_AXI] [get_bd_intf_pins processing_system7/S_AXI_HP2]
  connect_bd_intf_net -intf_net axi_protocol_converter_osc2_M_AXI [get_bd_intf_pins axi_prot_conv_osc1/M_AXI] [get_bd_intf_pins processing_system7/S_AXI_HP1]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axi_dma_osc0/S_AXIS_S2MM] [get_bd_intf_pins axis_clock_converter_osc0/M_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_1_M_AXIS [get_bd_intf_pins axi_dma_osc1/S_AXIS_S2MM] [get_bd_intf_pins axis_clock_converter_osc1/M_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_2_M_AXIS [get_bd_intf_pins axi_dma_la/S_AXIS_S2MM] [get_bd_intf_pins axis_clock_converter_la/M_AXIS]
  connect_bd_intf_net -intf_net processing_system7_0_ddr [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_fixed_io [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_GPIO_0 [get_bd_intf_ports GPIO] [get_bd_intf_pins processing_system7/GPIO_0]
  connect_bd_intf_net -intf_net processing_system7_M_AXI_GP0 [get_bd_intf_ports M_AXI_GP0] [get_bd_intf_pins processing_system7/M_AXI_GP0]
  connect_bd_intf_net -intf_net processing_system7_M_AXI_GP1 [get_bd_intf_pins axi_interconnect_sys/S00_AXI] [get_bd_intf_pins processing_system7/M_AXI_GP1]

  # Create port connections
  connect_bd_net -net M_AXI_GP0_ACLK [get_bd_ports M_AXI_GP0_ACLK] [get_bd_pins axis_clock_converter_la/s_axis_aclk] [get_bd_pins axis_clock_converter_osc0/s_axis_aclk] [get_bd_pins axis_clock_converter_osc1/s_axis_aclk] [get_bd_pins processing_system7/M_AXI_GP0_ACLK]
  connect_bd_net -net M_AXI_GP0_ARESETn_1 [get_bd_ports M_AXI_GP0_ARESETn] [get_bd_pins axis_clock_converter_la/s_axis_aresetn] [get_bd_pins axis_clock_converter_osc0/s_axis_aresetn] [get_bd_pins axis_clock_converter_osc1/s_axis_aresetn]
  connect_bd_net -net axi_dma_la_s2mm_introut [get_bd_pins axi_dma_la/s2mm_introut] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net axi_dma_osc0_s2mm_introut [get_bd_pins axi_dma_osc0/s2mm_introut] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_dma_osc1_s2mm_introut [get_bd_pins axi_dma_osc1/s2mm_introut] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net axi_intc_0_irq [get_bd_pins axi_intc_0/irq] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net intr_1 [get_bd_ports IRQ] [get_bd_pins axi_intc_0/intr]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_la/axi_resetn] [get_bd_pins axi_dma_osc0/axi_resetn] [get_bd_pins axi_dma_osc1/axi_resetn] [get_bd_pins axis_clock_converter_la/m_axis_aresetn] [get_bd_pins axis_clock_converter_osc0/m_axis_aresetn] [get_bd_pins axis_clock_converter_osc1/m_axis_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn] [get_bd_pins xadc/s_axi_aresetn]
  connect_bd_net -net proc_sys_reset_interconnect_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins axi_interconnect_dma_sg/ARESETN] [get_bd_pins axi_interconnect_dma_sg/M00_ARESETN] [get_bd_pins axi_interconnect_dma_sg/S00_ARESETN] [get_bd_pins axi_interconnect_dma_sg/S01_ARESETN] [get_bd_pins axi_interconnect_dma_sg/S02_ARESETN] [get_bd_pins axi_interconnect_sys/ARESETN] [get_bd_pins axi_interconnect_sys/M00_ARESETN] [get_bd_pins axi_interconnect_sys/M01_ARESETN] [get_bd_pins axi_interconnect_sys/M02_ARESETN] [get_bd_pins axi_interconnect_sys/M03_ARESETN] [get_bd_pins axi_interconnect_sys/M04_ARESETN] [get_bd_pins axi_interconnect_sys/S00_ARESETN] [get_bd_pins axi_prot_conv_osc0/aresetn] [get_bd_pins axi_prot_conv_osc1/aresetn] [get_bd_pins axi_protocol_converter_la/aresetn] [get_bd_pins proc_sys_reset/interconnect_aresetn]
  connect_bd_net -net processing_system7_0_fclk_clk0 [get_bd_ports FCLK_CLK0] [get_bd_pins processing_system7/FCLK_CLK0]
  connect_bd_net -net processing_system7_0_fclk_clk1 [get_bd_ports FCLK_CLK1] [get_bd_pins axi_dma_la/m_axi_s2mm_aclk] [get_bd_pins axi_dma_la/m_axi_sg_aclk] [get_bd_pins axi_dma_la/s_axi_lite_aclk] [get_bd_pins axi_dma_osc0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_osc0/m_axi_sg_aclk] [get_bd_pins axi_dma_osc0/s_axi_lite_aclk] [get_bd_pins axi_dma_osc1/m_axi_s2mm_aclk] [get_bd_pins axi_dma_osc1/m_axi_sg_aclk] [get_bd_pins axi_dma_osc1/s_axi_lite_aclk] [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins axi_interconnect_dma_sg/ACLK] [get_bd_pins axi_interconnect_dma_sg/M00_ACLK] [get_bd_pins axi_interconnect_dma_sg/S00_ACLK] [get_bd_pins axi_interconnect_dma_sg/S01_ACLK] [get_bd_pins axi_interconnect_dma_sg/S02_ACLK] [get_bd_pins axi_interconnect_sys/ACLK] [get_bd_pins axi_interconnect_sys/M00_ACLK] [get_bd_pins axi_interconnect_sys/M01_ACLK] [get_bd_pins axi_interconnect_sys/M02_ACLK] [get_bd_pins axi_interconnect_sys/M03_ACLK] [get_bd_pins axi_interconnect_sys/M04_ACLK] [get_bd_pins axi_interconnect_sys/S00_ACLK] [get_bd_pins axi_prot_conv_osc0/aclk] [get_bd_pins axi_prot_conv_osc1/aclk] [get_bd_pins axi_protocol_converter_la/aclk] [get_bd_pins axis_clock_converter_la/m_axis_aclk] [get_bd_pins axis_clock_converter_osc0/m_axis_aclk] [get_bd_pins axis_clock_converter_osc1/m_axis_aclk] [get_bd_pins proc_sys_reset/slowest_sync_clk] [get_bd_pins processing_system7/FCLK_CLK1] [get_bd_pins processing_system7/M_AXI_GP1_ACLK] [get_bd_pins processing_system7/S_AXI_GP0_ACLK] [get_bd_pins processing_system7/S_AXI_HP0_ACLK] [get_bd_pins processing_system7/S_AXI_HP1_ACLK] [get_bd_pins processing_system7/S_AXI_HP2_ACLK] [get_bd_pins xadc/s_axi_aclk]
  connect_bd_net -net processing_system7_0_fclk_clk2 [get_bd_ports FCLK_CLK2] [get_bd_pins processing_system7/FCLK_CLK2]
  connect_bd_net -net processing_system7_0_fclk_reset0_n [get_bd_ports FCLK_RESET0_N] [get_bd_pins processing_system7/FCLK_RESET0_N]
  connect_bd_net -net processing_system7_0_fclk_reset1_n [get_bd_ports FCLK_RESET1_N] [get_bd_pins processing_system7/FCLK_RESET1_N]
  connect_bd_net -net processing_system7_0_fclk_reset2_n [get_bd_ports FCLK_RESET2_N] [get_bd_pins processing_system7/FCLK_RESET2_N]
  connect_bd_net -net processing_system7_0_fclk_reset3_n [get_bd_ports FCLK_RESET3_N] [get_bd_pins proc_sys_reset/ext_reset_in] [get_bd_pins processing_system7/FCLK_RESET3_N]
  connect_bd_net -net processing_system7_FCLK_CLK3 [get_bd_ports FCLK_CLK3] [get_bd_pins processing_system7/FCLK_CLK3]
  connect_bd_net -net xadc_ip2intc_irpt [get_bd_pins xadc/ip2intc_irpt] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins processing_system7/IRQ_F2P] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_dout [get_bd_pins proc_sys_reset/aux_reset_in] [get_bd_pins xlconstant/dout]

  # Create address segments
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_la/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x01000000 -offset 0xFC000000 [get_bd_addr_spaces axi_dma_la/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_QSPI_LINEAR] SEG_processing_system7_GP0_QSPI_LINEAR
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_la/Data_S2MM] [get_bd_addr_segs processing_system7/S_AXI_HP2/HP2_DDR_LOWOCM] SEG_processing_system7_HP2_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_osc0/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x01000000 -offset 0xFC000000 [get_bd_addr_spaces axi_dma_osc0/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_QSPI_LINEAR] SEG_processing_system7_GP0_QSPI_LINEAR
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_osc0/Data_S2MM] [get_bd_addr_segs processing_system7/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_osc1/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x01000000 -offset 0xFC000000 [get_bd_addr_spaces axi_dma_osc1/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_QSPI_LINEAR] SEG_processing_system7_GP0_QSPI_LINEAR
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_osc1/Data_S2MM] [get_bd_addr_segs processing_system7/S_AXI_HP1/HP1_DDR_LOWOCM] SEG_processing_system7_HP1_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x40000000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs M_AXI_GP0/Reg] SEG_M_AXI_GP0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x80410000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs axi_dma_osc1/S_AXI_LITE/Reg] SEG_axi_dma_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x80420000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs axi_dma_la/S_AXI_LITE/Reg] SEG_axi_dma_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x80400000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs axi_dma_osc0/S_AXI_LITE/Reg] SEG_axi_dma_3_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x81800000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] SEG_axi_intc_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x83C00000 [get_bd_addr_spaces processing_system7/Data] [get_bd_addr_segs xadc/s_axi_lite/Reg] SEG_xadc_Reg

  # Exclude Address Segments
  create_bd_addr_seg -range 0x00400000 -offset 0xE0000000 [get_bd_addr_spaces axi_dma_la/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_IOP] SEG_processing_system7_GP0_IOP
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_la/Data_SG/SEG_processing_system7_GP0_IOP]

  create_bd_addr_seg -range 0x40000000 -offset 0x40000000 [get_bd_addr_spaces axi_dma_la/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP0] SEG_processing_system7_GP0_M_AXI_GP0
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_la/Data_SG/SEG_processing_system7_GP0_M_AXI_GP0]

  create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_la/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP1] SEG_processing_system7_GP0_M_AXI_GP1
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_la/Data_SG/SEG_processing_system7_GP0_M_AXI_GP1]

  create_bd_addr_seg -range 0x00400000 -offset 0xE0000000 [get_bd_addr_spaces axi_dma_osc0/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_IOP] SEG_processing_system7_GP0_IOP
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc0/Data_SG/SEG_processing_system7_GP0_IOP]

  create_bd_addr_seg -range 0x40000000 -offset 0x40000000 [get_bd_addr_spaces axi_dma_osc0/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP0] SEG_processing_system7_GP0_M_AXI_GP0
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc0/Data_SG/SEG_processing_system7_GP0_M_AXI_GP0]

  create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_osc0/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP1] SEG_processing_system7_GP0_M_AXI_GP1
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc0/Data_SG/SEG_processing_system7_GP0_M_AXI_GP1]

  create_bd_addr_seg -range 0x00400000 -offset 0xE0000000 [get_bd_addr_spaces axi_dma_osc1/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_IOP] SEG_processing_system7_GP0_IOP
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc1/Data_SG/SEG_processing_system7_GP0_IOP]

  create_bd_addr_seg -range 0x40000000 -offset 0x40000000 [get_bd_addr_spaces axi_dma_osc1/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP0] SEG_processing_system7_GP0_M_AXI_GP0
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc1/Data_SG/SEG_processing_system7_GP0_M_AXI_GP0]

  create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_osc1/Data_SG] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_M_AXI_GP1] SEG_processing_system7_GP0_M_AXI_GP1
  exclude_bd_addr_seg [get_bd_addr_segs axi_dma_osc1/Data_SG/SEG_processing_system7_GP0_M_AXI_GP1]



  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


