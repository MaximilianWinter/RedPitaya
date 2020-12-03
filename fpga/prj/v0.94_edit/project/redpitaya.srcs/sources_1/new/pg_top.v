`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 13.11.2020 15:45:04
// Design Name: 
// Module Name: pg_top
// Project Name: PulseGenerator
// Target Devices: RedPitaya
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: only implemented for one channel
// 
//////////////////////////////////////////////////////////////////////////////////
/*
module_mode set via RAM

calibrator module writes U_PD as function of U_out to RAM
*/

module pg_top(
	input			clk_i,
	input			rstn_i,
	
	// Channel A Signals
	input	[14-1:0]	pd_i,
	output	[14-1:0]	ctrl_sig_o,
	output  [14-1:0]    test_sig_o,
	
	input			    trigger_i,
	
	//System Bus
	input      [ 32-1: 0] sys_addr  ,  // bus address
	input      [ 32-1: 0] sys_wdata ,  // bus write data
	input                 sys_wen   ,  // bus write enable
	input                 sys_ren   ,  // bus read enable
	output reg [ 32-1: 0] sys_rdata ,  // bus read data
	output reg            sys_err   ,  // bus error indicator
	output reg            sys_ack
	);
	
reg module_mode = 1'b0; // 0 corresponds to Calibration Mode


////////////////////////
///CALIBRATION MODULE///
////////////////////////
reg cal_trigger = 1'b0;
reg [14-1:0] cal_buf_addr;
wire [14-1:0] cal_buf_rdata;


wire [14-1:0] cal_ctrl_sig;		// if in calibration mode, this should drive ctrl_sig_o
wire [14-1:0] cal_pd_i;		// if in calibration mode, this should be driven by pd_i

calibrator cal(
	.clk_i(clk_i),
	.rstn_i(rstn_i),
	
	.trigger_i(cal_trigger),	// only do something at rising edge of trigger
	
	.ctrl_sig_o(cal_ctrl_sig),	// controller output of the calibrator module
	.pd_i(pd_i),			// input from photodiode if in calibrator mode
	
	
	.buf_rdata_o(cal_buf_rdata),	// we want to write the response curve to the memory want to read it via Python
	.buf_addr_i(cal_buf_addr)
);


////////////////////////////
///MOVING AVERAGER MODULE///
////////////////////////////

wire [14-1:0] avg_pd;

reg [3-1:0] avg_state;
reg avg_rstn;

moving_averager_64 avg(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(pd_i),
    .dat_o(avg_pd)
);

///////////////////////
///CONTROLLER MODULE///
///////////////////////

reg [14-1:0] k_p;
reg [14-1:0] delta_pd;

reg pctrl_buf_we;
reg pctrl_ref_buf_we;

reg do_init = 1'b0;
reg trigger = 1'b0;

reg [14-1:0] pctrl_buf_addr;
wire [14-1:0] pctrl_buf_rdata;
wire [14-1:0] pctrl_ref_buf_rdata;
wire [14-1:0] pctrl_general_buf_rdata;

reg [3-1:0] general_buf_state;

wire [14-1:0] pctrl_ctrl_sig;
wire [14-1:0] pctrl_pd_i;

reg [14-1:0] offset;
reg [14-1:0] rpnt_init_offset;
reg [3-1:0] avg_state_ctrl;
reg avg_rstn_ctrl;
controller pctrl(
	.clk_i(clk_i),
	.rstn_i(rstn_i),
	
	//.trigger_i(trigger_i),		// note: this is the trigger for the pulse generation
	.trigger_i(trigger),
	.do_init_i(do_init), // bug
	
	.ctrl_sig_o(pctrl_ctrl_sig),
	.pd_i(avg_pd),
	.test_sig_o(test_sig_o),
	
	.k_p_i(k_p),
	.delta_pd_i(delta_pd),
	
	.ctrl_buf_we_i(pctrl_buf_we),			// note: we want to write the ref_wf from memory into an array
	.ref_buf_we_i(pctrl_ref_buf_we),
	.buf_addr_i(pctrl_buf_addr),
	.buf_wdata_i(sys_wdata[14-1:0]),
	.ctrl_buf_rdata_o(pctrl_buf_rdata),			// and we might want to read it/or other signals for test purposes
	.ref_buf_rdata_o(pctrl_ref_buf_rdata),
	.general_buf_rdata_o(pctrl_general_buf_rdata),
	.general_buf_state_i(general_buf_state),
	.offset_i(offset),
	.rpnt_init_offset_i(rpnt_init_offset),
	.avg_state_i(avg_state_ctrl),
	.avg_rstn_i(avg_rstn_ctrl)
	
);


///////////////////
///MODE SELECTOR///
///////////////////
reg [14-1:0] ctrl_out;

always @(posedge clk_i)
begin
	case(module_mode)
		1'b0: begin ctrl_out <= $signed(cal_ctrl_sig); end
		//1'b0: begin ctrl_out <= $signed(avg_pd); end
		1'b1: begin ctrl_out <= $signed(pctrl_ctrl_sig); end
		//1'b2: begin ctrl_out <= $signed(avg_pd); end
	endcase
end

assign ctrl_sig_o = $signed(ctrl_out);




///////////////
///BUS LOGIC///
///////////////
always @(posedge clk_i)
begin
	pctrl_buf_we <= sys_wen && (sys_addr[19:16] == 'h1);
	pctrl_buf_addr <= sys_addr[15:2];
	
	pctrl_ref_buf_we <= sys_wen && (sys_addr[19:16] == 'h3);
	
	cal_buf_addr <= sys_addr[15:2];
end


reg [3-1: 0] ren_dly;
reg          ack_dly;


always @(posedge clk_i)
begin
	if (rstn_i == 1'b0) begin
		ren_dly <= 3'h0;
		ack_dly <= 1'b0;
	end
	else begin
		ren_dly <= {ren_dly[1:0], sys_ren};
		ack_dly <= ren_dly[2] || sys_wen;
		
		if (sys_wen) begin
			case(sys_addr[19:0])
				20'h0: begin module_mode	<= sys_wdata[0]; end // this writes data from memory to the internal module_mode register
				20'h4: begin k_p		<= sys_wdata[14-1:0]; end
				20'h8: begin delta_pd		<= sys_wdata[14-1:0]; end
				20'hC: begin general_buf_state <= sys_wdata[3-1:0]; end
				20'h10: begin do_init		<= sys_wdata[0]; end
				20'h14: begin trigger		<= sys_wdata[0]; end
				20'h18: begin cal_trigger		<= sys_wdata[0]; end
				20'h1C: begin offset        <= sys_wdata[14-1:0]; end
				20'h20: begin avg_state <= sys_wdata[3-1:0]; end
				20'h24: begin avg_rstn		<= sys_wdata[0]; end
				20'h28: begin rpnt_init_offset        <= sys_wdata[14-1:0]; end
				20'h2C: begin avg_state_ctrl <= sys_wdata[3-1:0]; end
				20'h30: begin avg_rstn_ctrl		<= sys_wdata[0]; end
			endcase
		end
	end
end


wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i)
begin
	if (rstn_i == 1'b0) begin
		sys_err <= 1'b0;
		sys_ack <= 1'b0;
	end
	else begin
		sys_err <= 1'b0;
		
		casez (sys_addr[19:0])
			20'h0: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, module_mode}; end
			20'h4: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, k_p}; end
			20'h8: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, delta_pd}; end
			20'hC: begin sys_ack <= sys_en;	sys_rdata <= {{32-3{1'b0}}, general_buf_state}; end
			20'h10: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, do_init}; end
			20'h14: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, trigger}; end
			20'h18: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, cal_trigger}; end
			20'h1C: begin sys_ack <= sys_en; sys_rdata <= {{32-14{1'b0}}, offset}; end
			20'h20: begin sys_ack <= sys_en;	sys_rdata <= {{32-3{1'b0}}, avg_state}; end
			20'h24: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, avg_rstn}; end
			20'h28: begin sys_ack <= sys_en; sys_rdata <= {{32-14{1'b0}}, rpnt_init_offset}; end
			20'h2C: begin sys_ack <= sys_en;	sys_rdata <= {{32-3{1'b0}}, avg_state_ctrl}; end
			20'h30: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, avg_rstn_ctrl}; end
			
			
			20'h1zzzz: begin sys_ack <= ack_dly; 	sys_rdata <= {{18{1'b0}}, pctrl_buf_rdata}; end // this writes data from the controller module to memory
			20'h2zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, cal_buf_rdata}; end // this writes data from the calibrator module to memory
			20'h3zzzz: begin sys_ack <= ack_dly; 	sys_rdata <= {{18{1'b0}}, pctrl_ref_buf_rdata}; end
			20'h4zzzz: begin sys_ack <= ack_dly; 	sys_rdata <= {{18{1'b0}}, pctrl_general_buf_rdata}; end
			
			default: begin sys_ack <= sys_en; sys_rdata <= 32'h0; end
		endcase
	end

end

    
endmodule
