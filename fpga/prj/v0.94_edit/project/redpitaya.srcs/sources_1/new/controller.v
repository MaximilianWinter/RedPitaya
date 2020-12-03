`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 13.11.2020 18:42:41
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: without delta-t determination; bitfile generation works - 19.11. 18:51
// 
//////////////////////////////////////////////////////////////////////////////////


module controller(
	input			clk_i,
	input			rstn_i,
	
	input			trigger_i,
	input			do_init_i,
	
	output	[14-1:0]	ctrl_sig_o,
	input	[14-1:0]	pd_i,
	
	output  [14-1:0]    test_sig_o,
	
	input	[14-1:0]	k_p_i,
	input   [14-1:0]    delta_pd_i,
	
	input			ctrl_buf_we_i,
	input			ref_buf_we_i,
	input	[14-1:0]	buf_addr_i,
	input	[14-1:0]	buf_wdata_i,
	output	reg [14-1:0]	ctrl_buf_rdata_o,
	output	reg [14-1:0]	ref_buf_rdata_o,
	output reg [14-1:0]    general_buf_rdata_o,
	input [3-1:0]      general_buf_state_i,
	input  [14-1:0]    offset_i,
	input  [14-1:0]    rpnt_init_offset_i,
	input [3-1:0]      avg_state_i,
	input              avg_rstn_i

);
//////////////////////////////
///RAM/ARRAY INITIALIZATION///
//////////////////////////////

///INIT CTRL SIGNAL///
reg [14-1:0]    init_ctrl_sig_waddr;
reg [14-1:0]    init_ctrl_sig_raddr;
reg             init_ctrl_sig_we;
reg [14-1:0]    init_ctrl_sig_wdata;
wire [14-1:0]   init_ctrl_sig_rdata;

sram init_ctrl_sig_ram(
    .clk_i(clk_i),
    .waddr_i(init_ctrl_sig_waddr),
    .raddr_i(init_ctrl_sig_raddr),
    .write_enable_i(init_ctrl_sig_we),
    .data_i(init_ctrl_sig_wdata),
    .data_o(init_ctrl_sig_rdata)
);


///CTRL SIGNAL///
reg [14-1:0]    ctrl_sig_waddr;
reg [14-1:0]    ctrl_sig_raddr;
reg             ctrl_sig_we;
reg [14-1:0]    ctrl_sig_wdata;
wire [14-1:0]    ctrl_sig_rdata;

sram ctrl_sig_ram(
    .clk_i(clk_i),
    .waddr_i(ctrl_sig_waddr),
    .raddr_i(ctrl_sig_raddr),
    .write_enable_i(ctrl_sig_we),
    .data_i(ctrl_sig_wdata),
    .data_o(ctrl_sig_rdata)
);

///PD ARRAY///
reg [14-1:0]    pd_waddr;
reg [14-1:0]    pd_raddr;
reg             pd_we;
reg [14-1:0]    pd_wdata;
wire [14-1:0]   pd_rdata;

sram pd_sram(
    .clk_i(clk_i),
    .waddr_i(pd_waddr),
    .raddr_i(pd_raddr),
    .write_enable_i(pd_we),
    .data_i(pd_wdata),
    .data_o(pd_rdata)
);


///REF WF ARRAY///
reg [14-1:0]    ref_waddr;
reg [14-1:0]    ref_raddr;
reg             ref_we;
reg [14-1:0]    ref_wdata;
wire [14-1:0]   ref_rdata;

sram ref_sram(
    .clk_i(clk_i),
    .waddr_i(ref_waddr),
    .raddr_i(ref_raddr),
    .write_enable_i(ref_we),
    .data_i(ref_wdata),
    .data_o(ref_rdata)
);

///INIT CTRL SIG///
wire [14-1:0] init_ctrl_sig_rpnt;
always @(posedge clk_i)
begin
    init_ctrl_sig_wdata <= buf_wdata_i;
    init_ctrl_sig_we <= (ctrl_buf_we_i && do_init_i);
    init_ctrl_sig_waddr <= buf_addr_i;
    init_ctrl_sig_raddr <= init_ctrl_sig_rpnt;
end


///CTRL SIG///
reg [14-1:0] ctrl_sig_wf_val;

reg [14-1:0] ctrl_sig_wpnt;
reg [14-1:0] ctrl_sig_rpnt;
always @(posedge clk_i)
begin
    ctrl_sig_wdata <= ctrl_sig_wf_val;
    //ctrl_sig_we <= !trigger_i;                      // we want to write to the array when trigger is low
    ctrl_sig_waddr <= ctrl_sig_wpnt;
    ctrl_sig_raddr <= ctrl_sig_rpnt;
end


///PD ARRAY///
wire [14-1:0] pd_wpnt;
wire [14-1:0] pd_rpnt;
always @(posedge clk_i)
begin
    pd_wdata <= pd_i;
    pd_we <= trigger_i;
    pd_waddr <= pd_wpnt;
    pd_raddr <= pd_rpnt;
end

///REF ARRAY///
reg [14-1:0] ref_rpnt;
always @(posedge clk_i)
begin
    ref_wdata <= buf_wdata_i;
    ref_we <= (ref_buf_we_i && do_init_i);
    ref_waddr <= buf_addr_i;
    ref_raddr <= ref_rpnt;
end




///CONTROLLER VALUE CALCULATION///
reg [14-1:0] output_val;
reg [15-1:0] error;
reg [29-1:0] scaled_error;

reg first = 1'b1;
reg trig_it_done = 1'b0;

reg [14-1:0] raw_ctrl_sig_wf_val;

always @(posedge clk_i)
begin
    if (!do_init_i) begin
        if (!trigger_i) begin
            ctrl_sig_we <= 1'b1;
            
            output_val <= 14'd0;
            
            error <= $signed(ref_rdata) - $signed(pd_rdata) + $signed(offset_i);
            scaled_error <= $signed(error) * $signed({1'b0,k_p_i});
            ctrl_sig_wf_val <= $signed(ctrl_sig_rdata) + $signed(scaled_error[29-1:15]); //need to include averager
            
        end
        else begin
            ctrl_sig_we <= 1'b0;
            output_val <= ctrl_sig_rdata;
        end

    end
    else begin
        ctrl_sig_we <= 1'b1;
        ctrl_sig_wf_val <= $signed(init_ctrl_sig_rdata);
    end
end

assign ctrl_sig_o = output_val;


///MOVING AVERAGER///
wire [14-1:0] avg_output_val;

moving_averager_64 avg(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(output_val),
    .dat_o(avg_output_val)
);

///////////////////
///POINTER LOGIC///
///////////////////

///DURING TRIGGER

reg ntrig_it_done = 1'b0;

wire [14-1:0] ctrl_sig_nrpnt;
wire [14-1:0] ctrl_sig_nwpnt;
wire [14-1:0] ref_nrpnt;
always @(posedge clk_i)
begin
    if (trigger_i) begin
        ntrig_it_done <= 1'b0;
        if (trig_it_done) begin
            ctrl_sig_rpnt <= 14'd1 + rpnt_init_offset_i;
        end
        else begin
            if (do_init_i) begin
                if (ctrl_sig_nwpnt < 14'd16383) begin
                    ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                    ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                end
                else begin
                    trig_it_done <= 1'b1;
                    ctrl_sig_wpnt <= 14'd0;
                    ctrl_sig_rpnt <= 14'd1 + rpnt_init_offset_i;
                end
            end
            else begin
                if (ctrl_sig_nrpnt < 14'd16383) begin
                     ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                end
                else begin
                    trig_it_done <= 1'b1;
                    ctrl_sig_rpnt <= 14'd1 + rpnt_init_offset_i;
                end
            end
        end
    end
    else begin
        trig_it_done <= 1'b0;
        
        if (ntrig_it_done) begin
            ref_rpnt <= 14'd3;
            
            ctrl_sig_rpnt <= 14'd1;
            ctrl_sig_wpnt <= 14'd0;
        end
        else begin
            if (ref_nrpnt < 14'd16383) begin
                ref_rpnt <= ref_nrpnt;
                ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                ctrl_sig_wpnt <= ctrl_sig_nwpnt;
            end
            else begin
                ntrig_it_done <= 1'b1;
                ref_rpnt <= 14'd3;
                ctrl_sig_rpnt <= 14'd1;
                ctrl_sig_wpnt <= 14'd0;
            end
        end
    end
end

assign ctrl_sig_nrpnt = ctrl_sig_rpnt + 14'd1; // for top and bottom

assign ctrl_sig_nwpnt = ctrl_sig_wpnt + 14'd1; // for top and bottom
assign ref_nrpnt = ref_rpnt + 14'd1;            // for bottom

assign init_ctrl_sig_rpnt = ctrl_sig_rpnt; // for top
assign pd_wpnt = ctrl_sig_rpnt; // for top

assign pd_rpnt = ref_rpnt + delta_pd_i; // for bottom









reg [14-1:0]    general_buf_waddr;
reg [14-1:0]    general_buf_raddr;
reg             general_buf_we;
reg [14-1:0]    general_buf_wdata;
wire [14-1:0]   general_buf_rdata;

sram general_buf_ram(
    .clk_i(clk_i),
    .waddr_i(general_buf_waddr),
    .raddr_i(general_buf_raddr),
    .write_enable_i(general_buf_we),
    .data_i(general_buf_wdata),
    .data_o(general_buf_rdata)
);

reg [14-1:0] general_out;

always @(posedge clk_i)
begin
    case (general_buf_state_i)
        // to be read out when trigger is low
        3'b000: begin general_out <= $signed(ref_rdata); end
        3'b001: begin general_out <= $signed(pd_rdata); end
        3'b010: begin general_out <= $signed(error); end
        3'b011: begin general_out <= $signed(scaled_error[29-1:15]); end
        
        // to be read out when trigger is high
        3'b100: begin general_out <= $signed(output_val); end // controller output
        3'b101: begin general_out <= $signed(init_ctrl_sig_rdata); end
    endcase
end

assign test_sig_o = general_out;

wire [14-1:0] general_buf_wpnt;

assign general_buf_wpnt = ctrl_sig_rpnt;

always @(posedge clk_i)
begin
    general_buf_wdata <= $signed(general_out);
    general_buf_we <= (!trigger_i && !general_buf_state_i[2]) || (trigger_i && general_buf_state_i[2]); // only if both are high or both are low set WE to high
    general_buf_waddr <= general_buf_wpnt;
    general_buf_raddr <= buf_addr_i;
    
    general_buf_rdata_o <= general_buf_rdata;
end









/*





reg [14-1:0] ctrl_wpnt;
wire [14-1:0] ctrl_nwpnt;

reg iteration_done = 1'b0;


always @(posedge clk_i)
begin
    if (do_ctrl_i == 1'b0) begin
        if (ctrl_buf_we_i) begin
            ctrl_sig_addr <= buf_addr_i;
            ctrl_sig_wdata <= buf_wdata_i[14-1:0];
            ctrl_sig_we <= 1'b1;
        end
        else begin
            ctrl_sig_we <= 1'b0;
        end
    end
    else begin
        if (trigger_i == 1'b0) begin
            ctrl_sig_addr <= ctrl_wpnt;
            ctrl_sig_wdata <= pd_i;
            ctrl_sig_we <= 1'b1;
        end
        else begin
            ctrl_sig_we <= 1'b0;
        end
    end
end


///////////////////
///POINTER LOGIC FOR ///
///////////////////

always @(posedge clk_i)
begin
	if (rstn_i == 1'b0) begin
		ctrl_wpnt <= 14'h1;
		iteration_done <= 1'b0;
	end
	
	if (trigger_i == 1'b0) begin
		if (iteration_done) begin
			ctrl_wpnt <= 14'h1;
		end
		else begin
			if (ctrl_nwpnt < 14'd16383) begin
				ctrl_wpnt <= ctrl_nwpnt;
			end
			else begin
				iteration_done <= 1'b1;
				ctrl_wpnt <= 14'h1;
			end
		end
	end
	else begin
		iteration_done <= 1'b1;
		ctrl_wpnt <= 14'h1;
	end
end
assign ctrl_nwpnt = ctrl_wpnt + 14'd1;


reg [14-1:0] ctrl_sig_arr [0:16384-1];

reg [14-1:0] pd_arr [0:16384-1];

reg [14-1:0] ref_wf_arr [0:16384-1];


// NOTE: this writes WF from RAM to array; should only be enabled if not controlling
always @(posedge clk_i)
begin
	if (do_ctrl_i == 1'b0) begin
		if (ctrl_buf_we_i) ctrl_sig_arr[buf_addr_i] <= buf_wdata_i[14-1:0];
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
		pd_iteration_done <= 1'b1;
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
always @(posedge clk_i)
begin
	if (do_ctrl_i == 1'b0) begin
		if (ctrl_buf_we_i) ctrl_sig_arr[buf_addr_i] <= buf_wdata_i[14-1:0];
		if (ref_buf_we_i) ref_wf_arr[buf_addr_i] <= buf_wdata_i[14-1:0];
	end
end

reg [14-1:0] ctrl_sig_new_current_val;
reg [14-1:0] ctrl_sig_old_current_val;
reg [14-1:0] pd_shifted_val;
reg [14-1:0] ref_val;

always @(posedge clk_i)
begin
	if (trigger_i == 1'b0) begin
		ctrl_sig_arr[ctrl_wpnt] <= ctrl_sig_new_current_val;
		
		ctrl_sig_old_current_val <= ctrl_sig_arr[ctrl_wpnt-1];
		pd_shifted_val <= pd_arr[pd_rpnt-3]; // NOTE: need to ensure that index stays positive!
		ref_val <= ref_wf_arr[ref_rpnt-3];
	end
end

reg [14-1:0] ctrl_sig_addr;
reg [14-1:0] ctrl_sig_wdata;


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
end

always @(posedge clk_i)
begin
    if (ctrl_buf_we_i || (trigger_i == 1'b0)) begin
        ctrl_sig_arr[ctrl_sig_addr] <= ctrl_sig_wdata;
    end
end




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
