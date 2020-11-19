`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 13.11.2020 18:42:41
// Design Name: 
// Module Name: prop_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: without delta-t determination
// 
//////////////////////////////////////////////////////////////////////////////////


module prop_ctrl(
	input			clk_i,
	input			rstn_i,
	
	input			trigger_i,
	input			do_ctrl_i,
	
	output	[14-1:0]	ctrl_sig_o,
	input	[14-1:0]	pd_i,
	
	input	[14-1:0]	k_p_i,
	
	input			ctrl_buf_we_i,
	input			ref_buf_we_i,
	input	[14-1:0]	buf_addr_i,
	input	[14-1:0]	buf_wdata_i,
	output	reg [14-1:0]	ctrl_buf_rdata_o,
	output	reg [14-1:0]	ref_buf_rdata_o

);

reg [14-1:0] ctrl_sig_arr [0:16384-1];

reg [14-1:0] pd_arr [0:16384-1];

reg [14-1:0] ref_wf_arr [0:16384-1];


// NOTE: this writes WF from RAM to array; should only be enabled if not controlling
always @(posedge clk_i)
begin
	if (do_ctrl_i == 1'b0) begin
		//if (ctrl_buf_we_i) ctrl_sig_arr[buf_addr_i] <= buf_wdata_i[14-1:0];
		if (ref_buf_we_i) ref_wf_arr[buf_addr_i] <= buf_wdata_i[14-1:0];
	end
end

// NOTE: do i need to include ref_wf_arr as well?
always @(posedge clk_i)
begin
    ctrl_buf_rdata_o <= ctrl_sig_arr[buf_addr_i];
    ref_buf_rdata_o <= ref_wf_arr[buf_addr_i];
end



///////////////////
///POINTER LOGIC///
///////////////////
reg [14-1:0] ctrl_rpnt;
wire [14-1:0] ctrl_nrpnt;

reg iteration_done = 1'b0;


always @(posedge clk_i)
begin
	if (rstn_i == 1'b0) begin
		ctrl_rpnt <= 14'h0;
		iteration_done <= 1'b0;
	end
	
	if (trigger_i == 1'b1) begin
		if (iteration_done) begin
			ctrl_rpnt <= 14'h0;
		end
		else begin
			if (ctrl_nrpnt < 14'd16383) begin
				ctrl_rpnt <= ctrl_nrpnt;
			end
			else begin
				iteration_done <= 1'b1;
				ctrl_rpnt <= 14'h0;
			end
		end
	end
	else begin
		iteration_done <= 1'b1;
		ctrl_rpnt <= 14'h0;
	end
end
assign ctrl_nrpnt = ctrl_rpnt + 14'd1;

///////////////////////////////////
///DEFINING CURRENT CTRL SIG VAL///
///////////////////////////////////

reg [14-1:0] ctrl_sig_current_val;
always @(posedge clk_i)
begin
	if (trigger_i) begin
		ctrl_sig_current_val <= ctrl_sig_arr[ctrl_rpnt];
	end
	else begin
		ctrl_sig_current_val <= 14'h0;
	end
end

assign ctrl_sig_o = ctrl_sig_current_val;

///////////////////////
///WRITING TO PD ARR///
///////////////////////

wire [14-1:0] pd_arr_wpnt;
assign pd_arr_wpnt = ctrl_rpnt; 

always @(posedge clk_i)
begin
	if (trigger_i) begin
		pd_arr[pd_arr_wpnt] <= pd_i;
	end
end

/////////////////////////////////
///PD/REF RPNT AND CTRL WPNT LOGIC///
/////////////////////////////////

reg [14-1:0] delta_rpnt;

reg [14-1:0] pd_rpnt;
wire [14-1:0] pd_nrpnt;

reg [14-1:0] ref_rpnt;
wire [14-1:0] ref_nrpnt;

reg [14-1:0] ctrl_wpnt;
wire [14-1:0] ctrl_nwpnt;

reg pd_iteration_done = 1'b0;
always @(posedge clk_i)
begin
	if (rstn_i == 1'b0) begin
		ctrl_wpnt <= 14'h1;
		ref_rpnt <= 14'h0;
		pd_rpnt <= 14'h0 + delta_rpnt;
		pd_iteration_done <= 1'b0;
	end
	
	if (trigger_i == 1'b0) begin
		if (pd_iteration_done) begin
			ctrl_wpnt <= 14'h1;
			ref_rpnt <= 14'h0;
			pd_rpnt <= 14'h0;
		end
		else begin
			if (ctrl_nwpnt < 14'd16383) begin
				ctrl_wpnt <= ctrl_nwpnt;
				ref_rpnt <= ref_nrpnt;
				pd_rpnt <= pd_nrpnt;
			end
			else begin
				pd_iteration_done <= 1'b1;
				ctrl_wpnt <= 14'h1;
				ref_rpnt <= 14'h0;
				pd_rpnt <= 14'h0;
			end
		end
	end
	else begin
		pd_iteration_done <= 1'b0;
		ctrl_wpnt <= 14'h1;
		ref_rpnt <= 14'h0;
		pd_rpnt <= 14'h0 + delta_rpnt;
	end
end
assign pd_nrpnt = pd_rpnt + 14'd1;
assign ctrl_nwpnt = ctrl_wpnt + 14'd1;
assign ref_nrpnt = ref_rpnt + 14'd1;

////////////////////////
///GET CURRENT VALUES///
////////////////////////

reg [14-1:0] ctrl_sig_new_current_val;
reg [14-1:0] ctrl_sig_old_current_val;
reg [14-1:0] pd_shifted_val;
reg [14-1:0] ref_val;

always @(posedge clk_i)
begin
	if (trigger_i == 1'b0) begin
		//ctrl_sig_arr[ctrl_wpnt] <= ctrl_sig_new_current_val;
		
		//ctrl_sig_old_current_val <= ctrl_sig_arr[ctrl_wpnt-1];
		pd_shifted_val <= pd_arr[pd_rpnt-3]; // NOTE: need to ensure that index stays positive!
		ref_val <= ref_wf_arr[ref_rpnt-3];
	end
end

// up to here: synthesis takes 03:27 min (elapsed)

reg [14-1:0] ctrl_sig_addr;
reg [14-1:0] ctrl_sig_wdata;

reg [14-1:0] ctrl_sig_wdata1;
reg [14-1:0] ctrl_sig_wdata2;
reg [14-1:0] ctrl_sig_wdata3;

always @(posedge clk_i)
begin
    if (do_ctrl_i == 1'b0) begin
        if (ctrl_buf_we_i) begin
            ctrl_sig_addr <= buf_addr_i;
            ctrl_sig_wdata <= buf_wdata_i[14-1:0];
        end
    end
    else begin
        if (trigger_i == 1'b0) begin
            ctrl_sig_addr <= ctrl_wpnt;
            ctrl_sig_wdata <= ctrl_sig_new_current_val;
        end
    end
    ctrl_sig_wdata1 <= ctrl_sig_wdata;
    ctrl_sig_wdata2 <= ctrl_sig_wdata1;
    ctrl_sig_wdata3 <= ctrl_sig_wdata2;
end

// up to here: synthesis again 03:27 min

always @(posedge clk_i)
begin
    if (ctrl_buf_we_i || !trigger_i) begin
        ctrl_sig_arr[ctrl_sig_addr] <= ctrl_sig_wdata3;
    end
end

// synthesis 01:12, but implements in LUTRAM

/*

reg [15-1:0] error;
reg [29-1:0] scaled_error;

always @(posedge clk_i)
begin
	if (trigger_i == 1'b0) begin
		error <= $signed(ref_val) - $signed(pd_shifted_val);
		scaled_error <= $signed(error) * $signed(k_p_i);
		ctrl_sig_new_current_val <= ctrl_sig_old_current_val + scaled_error[29-1:15];
	end
end

*/

endmodule
