`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 08.01.2021
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
// Additional Comments: only implemented for one channel; controller_4.v does smoothing automatically after
//                      smoothing_cycles_i ctrl cycles; and sets output to zero after zero_output_del_i clk cycles;
//                      included min/max delta range
// 
//////////////////////////////////////////////////////////////////////////////////
/*
module_mode set via RAM

calibrator module writes U_PD as function of U_out to RAM
*/

module pg_top_dual_ram_delta_finder(
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


moving_averager_4 avg( //4 bit averager
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(pd_i),
    .dat_o(avg_pd)
);

///////////////////////
///CONTROLLER MODULE///
///////////////////////

reg [14-1:0] k_p;

reg pctrl_buf_we;
reg pctrl_ref_buf_we;

reg do_init = 1'b0;
reg software_trigger = 1'b0;
reg trigger_select = 1'b0;

reg trigger;

always @(posedge clk_i)
begin
    if (trigger_select == 1'b0) begin
        trigger <= trigger_i;
    end
    else begin
        trigger <= software_trigger;
    end
end


reg [14-1:0] pctrl_buf_addr;

wire [14-1:0] pctrl_general_buf_rdata;
wire [14-1:0] init_ctrl_sig_rdata;
wire [14-1:0] pd_rdata;
wire [14-1:0] ref_rdata;
wire [14-1:0] ctrl_sig_rdata;

reg [3-1:0] general_buf_state;

wire [14-1:0] pctrl_ctrl_sig;
wire [14-1:0] pctrl_pd_i;

reg [14-1:0] offset;
reg [14-1:0] wpnt_init_offset;

reg smoothing_rstn;
reg [14-1:0] smoothing_cycles;
reg [14-1:0] upper_zero_output_cnt = 14'd4095; //set to maxval initially
reg [14-1:0] lower_zero_output_cnt = 14'd0;
reg [14-1:0] max_arr_pnt = 14'd4095;

reg [14-1:0] delta_center;
reg [14-1:0] deltashift_upper = 14'd5;
reg [14-1:0] deltashift_lower = 14'd5;
reg [14_1:0] patience = 14'd100;
reg [14-1:0] center_patience = 14'd100;
reg [14-1:0] deltajump_upper = 14'd1;
reg [14-1:0] deltajump_lower = 14'd1;
reg [14-1:0] min_delta_range = 14'd0;
reg [14-1:0] max_delta_range = 14'd4095;
reg          start_delta_finder = 1'd0;

wire [14-1:0] ctrl_sig_rpnt_shift;

wire [32-1:0] err_0;
wire [32-1:0] err_1;
wire [32-1:0] err_2;

wire [3-1:0] delta_finder_state;

wire [32-1:0] too_low_center_patience_cnt;
wire [32-1:0] center_patience_cnt;

controller_dual_ram_delta_finder pctrl(
	.clk_i(clk_i),
	.rstn_i(rstn_i),
	
	.trigger_i(trigger),
	.do_init_i(do_init), 
	
	// signals
	.ctrl_sig_o(pctrl_ctrl_sig),
	.pd_i(avg_pd),
	.test_sig_o(test_sig_o),
	
	// main control parameters
	.k_p_i(k_p),
	.offset_i(offset),
	.smoothing_rstn_i(smoothing_rstn),
    .smoothing_cycles_i(smoothing_cycles),
    .delta_center_i(delta_center),
    .deltashift_upper_i(deltashift_upper),
    .deltashift_lower_i(deltashift_lower),
    .patience_i(patience),
    .center_patience_i(center_patience),
    .deltajump_upper_i(deltajump_upper),
    .deltajump_lower_i(deltajump_lower),
    .min_delta_range_i(min_delta_range),
    .max_delta_range_i(max_delta_range),
    .start_delta_finder_i(start_delta_finder),
    .ctrl_sig_rpnt_shift_o(ctrl_sig_rpnt_shift),
    .err0_o(err_0),
    .err1_o(err_1),
    .err2_o(err_2),
    .delta_finder_state_o(delta_finder_state),
    .too_low_center_patience_cnt_o(too_low_center_patience_cnt),
	.center_patience_cnt_o(center_patience_cnt),
	// additional control parameters
	.lower_zero_output_cnt_i(lower_zero_output_cnt),
    .upper_zero_output_cnt_i(upper_zero_output_cnt),
    .max_arr_pnt_i(max_arr_pnt),
    .wpnt_init_offset_i(wpnt_init_offset),
        
    // for visualizing and debugging
    .general_buf_state_i(general_buf_state),
    
    // bus logic
	.ctrl_buf_we_i(pctrl_buf_we),			// note: we want to write the ref_wf from memory into an array
	.ref_buf_we_i(pctrl_ref_buf_we),
	.buf_addr_i(pctrl_buf_addr),
	.buf_wdata_i(sys_wdata[14-1:0]),
	.general_buf_rdata_o(pctrl_general_buf_rdata),
	.init_ctrl_sig_rdata_o(init_ctrl_sig_rdata),
	.pd_rdata_o(pd_rdata),
	.ref_rdata_o(ref_rdata),
	.ctrl_sig_rdata_o(ctrl_sig_rdata)
	
);


///////////////////
///MODE SELECTOR///
///////////////////
reg [14-1:0] ctrl_out;

always @(posedge clk_i)
begin
	case(module_mode)
		1'b0: begin ctrl_out <= $signed(cal_ctrl_sig); end
		1'b1: begin ctrl_out <= $signed(pctrl_ctrl_sig); end
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
			    // module parameters
				20'h0: begin module_mode                <= sys_wdata[0]; end // 0: calib mode, 1: ctrl mode
				20'h4: begin cal_trigger                <= sys_wdata[0]; end
				20'h8: begin do_init		            <= sys_wdata[0]; end
				20'hC: begin software_trigger		    <= sys_wdata[0]; end
				20'h10: begin trigger_select		    <= sys_wdata[0]; end
				
				
				// main control parameters
				20'h14: begin k_p                       <= sys_wdata[14-1:0]; end
				//20'h18: begin delta_pd		            <= sys_wdata[14-1:0]; end
				20'h2C: begin offset                    <= sys_wdata[14-1:0]; end				
				20'h30: begin smoothing_rstn            <= sys_wdata[0]; end
				20'h34: begin smoothing_cycles		    <= sys_wdata[14-1:0]; end
				
				// additional control parameters
				20'h38: begin lower_zero_output_cnt     <= sys_wdata[14-1:0]; end
				20'h3C: begin upper_zero_output_cnt     <= sys_wdata[14-1:0]; end
				20'h40: begin max_arr_pnt               <= sys_wdata[14-1:0]; end
				20'h44: begin wpnt_init_offset          <= sys_wdata[14-1:0]; end
				
				// for visualizing and debugging
				20'h48: begin general_buf_state         <= sys_wdata[3-1:0]; end
				
				// new params:
				20'h4C: begin delta_center		            <= sys_wdata[14-1:0]; end
				20'h50: begin deltashift_upper		            <= sys_wdata[14-1:0]; end
				20'h54: begin deltashift_lower		            <= sys_wdata[14-1:0]; end
				20'h58: begin patience		            <= sys_wdata[14-1:0]; end
				20'h5C: begin deltajump_upper		            <= sys_wdata[14-1:0]; end
				20'h60: begin deltajump_lower		            <= sys_wdata[14-1:0]; end
				
				20'h78: begin min_delta_range		            <= sys_wdata[14-1:0]; end
				20'h7C: begin max_delta_range		            <= sys_wdata[14-1:0]; end
				
				20'h80: begin center_patience		            <= sys_wdata[14-1:0]; end
				20'h84: begin start_delta_finder            <= sys_wdata[0]; end
				
			
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
		    // module parameters
			20'h0: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, module_mode}; end
			20'h4: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, cal_trigger}; end
			20'h8: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, do_init}; end
			20'hC: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, software_trigger}; end
			20'h10: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, trigger_select}; end
			
			// main control parameters
			20'h14: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, k_p}; end
			//20'h18: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, delta_pd}; end
			20'h2C: begin sys_ack <= sys_en; sys_rdata <= {{32-14{1'b0}}, offset}; end
			20'h30: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, smoothing_rstn}; end
            20'h34: begin sys_ack <= sys_en;    sys_rdata <= {{32-14{1'b0}}, smoothing_cycles}; end
                        
            // additional control parameters
			20'h38: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, lower_zero_output_cnt}; end
			20'h3C: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, upper_zero_output_cnt}; end
			20'h40: begin sys_ack <= sys_en;    sys_rdata <= {{32-14{1'b0}}, max_arr_pnt}; end
			20'h44: begin sys_ack <= sys_en; sys_rdata <= {{32-14{1'b0}}, wpnt_init_offset}; end
			
			// for visualizing and debugging		
			20'h48: begin sys_ack <= sys_en;	sys_rdata <= {{32-3{1'b0}}, general_buf_state}; end
			
			// new params:
			20'h4C: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, delta_center}; end
			20'h50: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, deltashift_upper}; end
			20'h54: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, deltashift_lower}; end
			20'h58: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, patience}; end
			20'h5C: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, deltajump_upper}; end
			20'h60: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, deltajump_lower}; end
			20'h64: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, ctrl_sig_rpnt_shift}; end
			
			20'h68: begin sys_ack <= sys_en;	sys_rdata <= {err_0}; end
			20'h6C: begin sys_ack <= sys_en;	sys_rdata <= {err_1}; end
			20'h70: begin sys_ack <= sys_en;	sys_rdata <= {err_2}; end
			
			20'h74: begin sys_ack <= sys_en;	sys_rdata <= {{32-3{1'b0}}, delta_finder_state}; end
			
			20'h78: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, min_delta_range}; end
			20'h7C: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, max_delta_range}; end
			
			20'h80: begin sys_ack <= sys_en;	sys_rdata <= {{32-14{1'b0}}, center_patience}; end
			20'h84: begin sys_ack <= sys_en;	sys_rdata <= {{32-1{1'b0}}, start_delta_finder}; end
			
			
			20'h88: begin sys_ack <= sys_en;	sys_rdata <= {too_low_center_patience_cnt}; end
			20'h8C: begin sys_ack <= sys_en;	sys_rdata <= {center_patience_cnt}; end
			
			// waveforms
			20'h1zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, init_ctrl_sig_rdata}; end
			20'h2zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, cal_buf_rdata}; end // this writes data from the calibrator module to memory
			20'h3zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, ref_rdata}; end
			20'h4zzzz: begin sys_ack <= ack_dly; 	    sys_rdata <= {{18{1'b0}}, pctrl_general_buf_rdata}; end
			20'h5zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, pd_rdata}; end
			20'h6zzzz: begin sys_ack <= ack_dly;	    sys_rdata <= {{18{1'b0}}, ctrl_sig_rdata}; end
			
			default: begin sys_ack <= sys_en; sys_rdata <= 32'h0; end
		endcase
	end

end

    
endmodule
