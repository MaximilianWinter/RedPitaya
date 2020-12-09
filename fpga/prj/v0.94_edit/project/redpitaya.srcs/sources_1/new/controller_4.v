`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 13.11.2020 18:42:41
// Design Name: 
// Module Name: controller_4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: based on controller_3.v, includes automatic smoothing after (# of ctrl cycles can be chosen),
//                      also output can be automatically set to zero after a certain number of clk cycles (after trigger)
//////////////////////////////////////////////////////////////////////////////////


module controller_4(
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
	output reg [14-1:0]    general_buf_rdata_o,
	input [3-1:0]      general_buf_state_i,
	input  [14-1:0]    offset_i,
	input  [14-1:0]    ctrl_sig_wpnt_start_i,
	input              smoothing_rstn_i,
	input [14-1:0]     smoothing_cycles_i,
	input [14-1:0]     zero_output_del_i

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
reg [29-1:0]    ctrl_sig_wdata;
wire [29-1:0]    ctrl_sig_rdata;

big_bram ctrl_sig_ram(
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
reg [14-1:0] init_ctrl_sig_rpnt;
always @(posedge clk_i)
begin
    init_ctrl_sig_wdata <= buf_wdata_i;
    init_ctrl_sig_we <= (ctrl_buf_we_i && do_init_i);
    init_ctrl_sig_waddr <= buf_addr_i;
    init_ctrl_sig_raddr <= init_ctrl_sig_rpnt;
end


///CTRL SIG///
reg [29-1:0] ctrl_sig_wf_val;

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
reg [14-1:0] pd_wpnt;
reg [14-1:0] pd_rpnt;
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

reg [29-1:0] ctrl_sig_wf_preval;

wire [14-1:0] avg_output_val;

reg do_smoothing = 1'b0;

reg zero_output = 1'b0;

always @(posedge clk_i)
begin
    if (!do_init_i) begin
        if (!trigger_i) begin
            ctrl_sig_we <= 1'b1;
            
            output_val <= 14'd0;
            
            error <= $signed(ref_rdata) - $signed(pd_rdata) + $signed(offset_i);
            scaled_error <= $signed(error) * $signed({1'b0,k_p_i});
            ctrl_sig_wf_preval <= $signed(ctrl_sig_rdata) + $signed(scaled_error); //need to include averager
            
            if ($signed(ctrl_sig_wf_preval) < 0)
                ctrl_sig_wf_val <= 29'd0;
            else
                ctrl_sig_wf_val <= ctrl_sig_wf_preval;           
        end
        else begin
            if (!zero_output) begin
                output_val <= ctrl_sig_rdata[29-1:15];
            end
            else begin
                output_val <= 14'd0;
            end    
            
            if (do_smoothing) begin
                ctrl_sig_we <= 1'b1;
                ctrl_sig_wf_val <= $signed({avg_output_val,{15{1'b0}}});
            end
            else begin
                ctrl_sig_we <= 1'b0;
            end
        end

    end
    else begin //if (trigger_i) begin
        ctrl_sig_we <= 1'b1;
        ctrl_sig_wf_val <= $signed({init_ctrl_sig_rdata,{15{1'b0}}});
    end
end

assign ctrl_sig_o = avg_output_val; //NOTE: should use averaged output!


///MOVING AVERAGER///


moving_averager_64 avg(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(output_val),
    .dat_o(avg_output_val)
);

///////////////////////
///NEW POINTER LOGIC///
///////////////////////


reg [2-1:0] pnt_logic_state = 2'b00;
reg [2-1:0] wait_for_high = 2'b00;
reg [2-1:0] high = 2'b01;
reg [2-1:0] wait_for_low = 2'b10;
reg [2-1:0] low = 2'b11;

wire [14-1:0] ctrl_sig_nrpnt;
wire [14-1:0] pd_nwpnt;
wire [14-1:0] ctrl_sig_nwpnt;
wire [14-1:0] init_ctrl_sig_nrpnt;
wire [14-1:0] ref_nrpnt;
wire [14-1:0] pd_nrpnt;
always @(posedge clk_i)
begin
    case (pnt_logic_state)
        wait_for_high:
            begin
                if (trigger_i)
                    pnt_logic_state <= high;
                // initialize pointers:
                ctrl_sig_rpnt <= 14'd0;
                pd_wpnt <= 14'd0;
                init_ctrl_sig_rpnt <= 14'd0;
                
                if (do_init_i) begin
                    ctrl_sig_wpnt <= 14'd0;
                end
                else if (do_smoothing) begin
                    ctrl_sig_wpnt <= ctrl_sig_wpnt_start_i;
                end
            end
        high:
            begin
                if (ctrl_sig_nrpnt < 14'd16383) begin
                    ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                    pd_wpnt <= pd_nwpnt;
                    init_ctrl_sig_rpnt <= init_ctrl_sig_nrpnt;
                    if (do_init_i || do_smoothing) begin
                        ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                    end
                    if (ctrl_sig_rpnt > zero_output_del_i) begin
                        zero_output <= 1'b1;
                    end
                end
                else begin
                    pnt_logic_state <= wait_for_low;
                    zero_output <= 1'b0;
                end
            end
        wait_for_low:
            begin
                if (!trigger_i)
                    pnt_logic_state <= low;
                    
                pd_rpnt <= 14'd6 + delta_pd_i;
                ref_rpnt <= 14'd6;
                ctrl_sig_rpnt <= 14'd4;
                ctrl_sig_wpnt <= 14'd0;
            end
        low:
            begin
                if (ref_nrpnt < 14'd16383) begin
                    pd_rpnt <= pd_nrpnt;
                    ref_rpnt <= ref_nrpnt;
                    ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                    ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                end
                else begin
                    pnt_logic_state <= wait_for_high;
                end  
            end
    endcase

end

assign ctrl_sig_nrpnt = ctrl_sig_rpnt + 14'd1;
assign pd_nwpnt = pd_wpnt + 14'd1;
assign ctrl_sig_nwpnt = ctrl_sig_wpnt + 14'd1;
assign init_ctrl_sig_nrpnt = init_ctrl_sig_rpnt + 14'd1;
assign ref_nrpnt = ref_rpnt + 14'd1;
assign pd_nrpnt = pd_rpnt + 14'd1;




reg [14-1:0] trigger_cnt = 14'd0;
reg          wait_for_high_trigger = 1'b1;

always @(posedge clk_i)
begin
    if (smoothing_rstn_i) begin
        trigger_cnt <= 14'd0;
        wait_for_high_trigger = 1'b1;
    end
    else begin
        if (wait_for_high_trigger) begin
            if (trigger_i) begin
                trigger_cnt <= trigger_cnt + 14'd1;
                wait_for_high_trigger <= 1'b0;
            end
        end
        else begin
            if (!trigger_i) begin
                if (trigger_cnt == smoothing_cycles_i) begin
                    trigger_cnt <= 14'd0;
                    do_smoothing <= 1'b1;
                end
                else begin
                    do_smoothing <= 1'b0;
                end
                wait_for_high_trigger <= 1'b1;
            end
        end
    end
end










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
        
        3'b111: begin general_out <= $signed(avg_output_val); end
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

endmodule
