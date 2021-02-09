`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 29.01.2021 14:53:34
// Design Name: 
// Module Name: controller_lock_monitoring
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: instead of shifting pd, shift ctrl signa
//////////////////////////////////////////////////////////////////////////////////


module controller_ctrl_shift(
	input			clk_i,
	input			rstn_i,
	
	input			trigger_i,
	input			do_init_i,
	
	// signals
	output	[14-1:0]	ctrl_sig_o,
	input	[14-1:0]	pd_i,
	output  [14-1:0]    test_sig_o,
	
	// main control parameters
	input	[14-1:0]	k_p_i,
	input  [14-1:0]    offset_i,
    input              smoothing_rstn_i,
    input [14-1:0]     smoothing_cycles_i,
    
    input [14-1:0]      delta_center_i,
    input               monitoring_rstn_i,
    
    output [32-1:0]     error_avg_o,
    input [32-1:0]     error_threshold_i,
    output             need_to_relock_o,
    output [32-1:0]    avg_spread_o,
    input [14-1:0]     min_err_range_i,
    input [14-1:0]     max_err_range_i,
	
	// additional control parameters
    input [14-1:0]     lower_zero_output_cnt_i,
    input [14-1:0]     upper_zero_output_cnt_i,
    input [14-1:0]     max_arr_pnt_i,
    input  [14-1:0]    wpnt_init_offset_i,
    
    // for visualizing and debugging
    input [3-1:0]      general_buf_state_i,
	
	// bus logic
	input			ctrl_buf_we_i,
	input			ref_buf_we_i,
	input	[14-1:0]	buf_addr_i,
	input	[14-1:0]	buf_wdata_i,
	output reg [14-1:0]    general_buf_rdata_o,
	output reg [14-1:0]    init_ctrl_sig_rdata_o,
	output reg [14-1:0]    pd_rdata_o,
	output reg [14-1:0]    ref_rdata_o,
	output reg [14-1:0]    ctrl_sig_rdata_o

);

//////////////////////////////////////////////////////////////////////////////////
///RAM INITIALIZATIONS////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

///INIT CTRL SIGNAL///////////////////////////////////////////////////////////////
reg [14-1:0]    init_ctrl_sig_waddr_A;
reg [14-1:0]    init_ctrl_sig_raddr_A;
reg             init_ctrl_sig_we_A;
reg [14-1:0]    init_ctrl_sig_wdata_A;
wire [14-1:0]   init_ctrl_sig_rdata_A;

reg [14-1:0]    init_ctrl_sig_waddr_B;
reg [14-1:0]    init_ctrl_sig_raddr_B;
reg             init_ctrl_sig_we_B;
reg [14-1:0]    init_ctrl_sig_wdata_B;
wire [14-1:0]   init_ctrl_sig_rdata_B;

dual_bram init_ctrl_sig_ram(
    .clk_i(clk_i),
    .waddr_A_i(init_ctrl_sig_waddr_A),
    .raddr_A_i(init_ctrl_sig_raddr_A),
    .write_enable_A_i(init_ctrl_sig_we_A),
    .data_A_i(init_ctrl_sig_wdata_A),
    .data_A_o(init_ctrl_sig_rdata_A),
    
    .waddr_B_i(init_ctrl_sig_waddr_B),
    .raddr_B_i(init_ctrl_sig_raddr_B),
    .write_enable_B_i(init_ctrl_sig_we_B),
    .data_B_i(init_ctrl_sig_wdata_B),
    .data_B_o(init_ctrl_sig_rdata_B)
);


///CTRL SIGNAL////////////////////////////////////////////////////////////////////
reg [14-1:0]    ctrl_sig_waddr_A;
reg [14-1:0]    ctrl_sig_raddr_A;
reg             ctrl_sig_we_A;
reg [29-1:0]    ctrl_sig_wdata_A;
wire [29-1:0]    ctrl_sig_rdata_A;

reg [14-1:0]    ctrl_sig_waddr_B;
reg [14-1:0]    ctrl_sig_raddr_B;
reg             ctrl_sig_we_B;
reg [29-1:0]    ctrl_sig_wdata_B;
wire [29-1:0]    ctrl_sig_rdata_B;

big_dual_bram ctrl_sig_ram(
    .clk_i(clk_i),
    .waddr_A_i(ctrl_sig_waddr_A),
    .raddr_A_i(ctrl_sig_raddr_A),
    .write_enable_A_i(ctrl_sig_we_A),
    .data_A_i(ctrl_sig_wdata_A),
    .data_A_o(ctrl_sig_rdata_A),
    .waddr_B_i(ctrl_sig_waddr_B),
    .raddr_B_i(ctrl_sig_raddr_B),
    .write_enable_B_i(ctrl_sig_we_B),
    .data_B_i(ctrl_sig_wdata_B),
    .data_B_o(ctrl_sig_rdata_B)
);


///PD ARRAY///////////////////////////////////////////////////////////////////////
reg [14-1:0]    pd_waddr_A;
reg [14-1:0]    pd_raddr_A;
reg             pd_we_A;
reg [14-1:0]    pd_wdata_A;
wire [14-1:0]   pd_rdata_A;

reg [14-1:0]    pd_waddr_B;
reg [14-1:0]    pd_raddr_B;
reg             pd_we_B;
reg [14-1:0]    pd_wdata_B;
wire [14-1:0]   pd_rdata_B;

dual_bram pd_sram(
    .clk_i(clk_i),
    .waddr_A_i(pd_waddr_A),
    .raddr_A_i(pd_raddr_A),
    .write_enable_A_i(pd_we_A),
    .data_A_i(pd_wdata_A),
    .data_A_o(pd_rdata_A),
    .waddr_B_i(pd_waddr_B),
    .raddr_B_i(pd_raddr_B),
    .write_enable_B_i(pd_we_B),
    .data_B_i(pd_wdata_B),
    .data_B_o(pd_rdata_B)
);


///REF WF ARRAY///////////////////////////////////////////////////////////////////
reg [14-1:0]    ref_waddr_A;
reg [14-1:0]    ref_raddr_A;
reg             ref_we_A;
reg [14-1:0]    ref_wdata_A;
wire [14-1:0]   ref_rdata_A;

reg [14-1:0]    ref_waddr_B;
reg [14-1:0]    ref_raddr_B;
reg             ref_we_B;
reg [14-1:0]    ref_wdata_B;
wire [14-1:0]   ref_rdata_B;

dual_bram ref_sram(
    .clk_i(clk_i),
    .waddr_A_i(ref_waddr_A),
    .raddr_A_i(ref_raddr_A),
    .write_enable_A_i(ref_we_A),
    .data_A_i(ref_wdata_A),
    .data_A_o(ref_rdata_A),
    .waddr_B_i(ref_waddr_B),
    .raddr_B_i(ref_raddr_B),
    .write_enable_B_i(ref_we_B),
    .data_B_i(ref_wdata_B),
    .data_B_o(ref_rdata_B)
);


//////////////////////////////////////////////////////////////////////////////////
///RAM WIRING/////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


///INIT CTRL SIG//////////////////////////////////////////////////////////////////
reg [14-1:0] init_ctrl_sig_rpnt;
always @(posedge clk_i)
begin
    init_ctrl_sig_wdata_A <= buf_wdata_i;
    init_ctrl_sig_we_A <= (ctrl_buf_we_i && do_init_i);
    init_ctrl_sig_waddr_A <= buf_addr_i;
    init_ctrl_sig_raddr_A <= init_ctrl_sig_rpnt;
    
    init_ctrl_sig_wdata_B <= 14'd0;
    init_ctrl_sig_we_B <= 1'b0;
    init_ctrl_sig_waddr_B <= 14'd0;
    init_ctrl_sig_raddr_B <= buf_addr_i;
    init_ctrl_sig_rdata_o <= init_ctrl_sig_rdata_B;
end


///CTRL SIG///////////////////////////////////////////////////////////////////////
reg [29-1:0] ctrl_sig_wf_val;

reg [14-1:0] ctrl_sig_wpnt;
reg [14-1:0] ctrl_sig_rpnt;
always @(posedge clk_i)
begin
    ctrl_sig_wdata_A <= ctrl_sig_wf_val;
    //ctrl_sig_we_A <= !trigger_i;                      // we want to write to the array when trigger is low
    ctrl_sig_waddr_A <= ctrl_sig_wpnt;
    ctrl_sig_raddr_A <= ctrl_sig_rpnt;
    
    ctrl_sig_wdata_B <= 14'd0;
    ctrl_sig_we_B <= 1'b0;                      
    ctrl_sig_waddr_B <= 14'd0;
    ctrl_sig_raddr_B <= buf_addr_i;
    
    ctrl_sig_rdata_o <= ctrl_sig_rdata_B[29-1:15];
end

///CONTROLLER STATES//////////////////////////////////////////////////////////////
reg [3-1:0] ctrl_state = 3'b000;
reg [3-1:0] wait_for_high = 3'b000;
reg [3-1:0] high = 3'b001;
reg [3-1:0] wait_for_low = 3'b011;
reg [3-1:0] low = 3'b100;
reg [3-1:0] initialize = 3'b101;

///PD ARRAY///////////////////////////////////////////////////////////////////////
reg [14-1:0] pd_wpnt;
reg [14-1:0] pd_rpnt;
reg [14-1:0] pd_rpnt_B;
always @(posedge clk_i)
begin
    pd_wdata_A <= pd_i;
    pd_we_A <= (ctrl_state == high);//trigger_i;
    pd_waddr_A <= pd_wpnt;
    pd_raddr_A <= pd_rpnt;
    
    pd_wdata_B <= 14'd0;
    pd_we_B <= 1'b0;
    pd_waddr_B <= 14'd0;
    pd_raddr_B <= buf_addr_i;
    //pd_raddr_B <= pd_rpnt_B;
    
    pd_rdata_o <= pd_rdata_B;
end

///REF WF ARRAY///////////////////////////////////////////////////////////////////
reg [14-1:0] ref_rpnt;
reg [14-1:0] ref_rpnt_B;
always @(posedge clk_i)
begin
    ref_wdata_A <= buf_wdata_i;
    ref_we_A <= (ref_buf_we_i && do_init_i);
    ref_waddr_A <= buf_addr_i;
    ref_raddr_A <= ref_rpnt;
    
    ref_wdata_B <= 14'd0;
    ref_we_B <= 1'b0;
    ref_waddr_B <= 14'd0;
    ref_raddr_B <= buf_addr_i;
    //ref_raddr_B <= ref_rpnt_B;
    
    ref_rdata_o <= ref_rdata_B;
end


//////////////////////////////////////////////////////////////////////////////////
///CONTROLLER LOGIC///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


///CONTROLLER SIGNALS/////////////////////////////////////////////////////////////
reg [14-1:0] output_val;
reg [15-1:0] error;
reg [29-1:0] scaled_error;
reg [29-1:0] ctrl_sig_wf_preval;
wire [14-1:0] avg_output_val;


///CONTROLLER PARAMETERS//////////////////////////////////////////////////////////
reg do_smoothing = 1'b0;
reg zero_output = 1'b0;

reg [14-1:0] k_p = 14'd0;

reg zero_out = 1'b0;
reg zero_out_del = 1'b0;

always @(posedge clk_i)
begin
    if (ctrl_state != initialize) begin
        if (ctrl_state == low) begin
            ctrl_sig_we_A <= 1'b1;
            
            output_val <= 14'd0;
            
            if ($signed(ref_rdata_A) == 14'd0) begin // leave output unchanged where target is zero
                error <= 15'd0;
                zero_out <= 1'd1;
            end
            else begin
                zero_out <= 1'd0;
                error <= $signed(ref_rdata_A) - $signed(pd_rdata_A) + $signed(offset_i);
            end
            
            
            zero_out_del <= zero_out;
            scaled_error <= $signed(error) * $signed({1'b0,k_p});
            
            
            if (zero_out_del == 1'b1) begin
                ctrl_sig_wf_preval <= 29'd0;
            end
            else begin
                ctrl_sig_wf_preval <= $signed(ctrl_sig_rdata_A) + $signed(scaled_error); //need to include averager
            end
            
            if ($signed(ctrl_sig_wf_preval) < 0)
                ctrl_sig_wf_val <= 29'd0;
            else
                ctrl_sig_wf_val <= ctrl_sig_wf_preval;           
        end
        else if (ctrl_state == high) begin
            if (!zero_output) begin
                output_val <= ctrl_sig_rdata_A[29-1:15];
            end
            else begin
                output_val <= 14'd0;
            end    
            
            if (do_smoothing) begin
                ctrl_sig_we_A <= 1'b1;
                ctrl_sig_wf_val <= $signed({avg_output_val,{15{1'b0}}});
            end
            else begin
                ctrl_sig_we_A <= 1'b0;
            end
        end
        else begin
            ctrl_sig_we_A <= 1'b0;
            output_val <= 14'd0;
        end

    end
    else begin
        ctrl_sig_we_A <= 1'b1;
        ctrl_sig_wf_val <= $signed({init_ctrl_sig_rdata_A,{15{1'b0}}});
    end
end

assign ctrl_sig_o = avg_output_val;

///MOVING AVERAGER////////////////////////////////////////////////////////////////
moving_averager_4 avg( // 4 bit averager
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(output_val),
    .dat_o(avg_output_val)
);



//////////////////////////////////////////////////////////////////////////////////
///POINTER AND STATE LOGIC////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


///NEXT POINTER SIGNALS///////////////////////////////////////////////////////////
wire [14-1:0] ctrl_sig_nrpnt;
wire [14-1:0] pd_nwpnt;
wire [14-1:0] ctrl_sig_nwpnt;
wire [14-1:0] init_ctrl_sig_nrpnt;
wire [14-1:0] ref_nrpnt;
wire [14-1:0] pd_nrpnt;

///POINTER SIGNALS PARAMETERS/////////////////////////////////////////////////////
reg smoothing_even_odd_cnt = 1'b0;
reg [14-1:0] ctrl_sig_rpnt_shift = 14'd0;

always @(posedge clk_i)
begin
    case (ctrl_state)
        wait_for_high:
            begin
                if (trigger_i)
                    ctrl_state <= high;
                // initialize pointers:
                
                pd_wpnt <= 14'd0;
                init_ctrl_sig_rpnt <= 14'd0;
                
                if (do_init_i) begin
                    ctrl_sig_wpnt <= 14'd0;
                    ctrl_sig_rpnt <= 14'd0;
                    ctrl_state <= initialize;
                end
                else if (do_smoothing) begin
                    smoothing_even_odd_cnt <= !(smoothing_even_odd_cnt);
                    ctrl_sig_wpnt <= wpnt_init_offset_i + {{13{1'b0}},smoothing_even_odd_cnt} + delta_center_i;// + $signed(ctrl_sig_rpnt_shift);
                    ctrl_sig_rpnt <= 14'd0 + delta_center_i;// + $signed(ctrl_sig_rpnt_shift); // Is this problematic?
                end
                else begin
                    ctrl_sig_rpnt <= 14'd0 + delta_center_i;// + $signed(ctrl_sig_rpnt_shift);
                end
            end
        high:
            begin
                if (pd_nwpnt < max_arr_pnt_i) begin
                    ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                    pd_wpnt <= pd_nwpnt;
                    init_ctrl_sig_rpnt <= init_ctrl_sig_nrpnt;
                    if (do_smoothing) begin
                        ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                    end
                    if ((pd_wpnt < lower_zero_output_cnt_i) || (pd_wpnt > upper_zero_output_cnt_i)) begin
                        zero_output <= 1'b1;
                    end
                    else begin
                        zero_output <= 1'b0;
                    end
                end
                else begin
                    ctrl_state <= wait_for_low;
                    zero_output <= 1'b0;
                end
            end
        wait_for_low:
            begin
                if (!trigger_i)
                    ctrl_state <= low;
                    
                pd_rpnt <= 14'd6;
                ref_rpnt <= 14'd6;
                ctrl_sig_rpnt <= 14'd4;
                ctrl_sig_wpnt <= 14'd0;
                
                if (do_init_i) begin
                    init_ctrl_sig_rpnt <= 14'd0;
                    ctrl_state <= initialize;
                end
                
            end
        low:
            begin
                if (ref_nrpnt < max_arr_pnt_i) begin
                    pd_rpnt <= pd_nrpnt;
                    ref_rpnt <= ref_nrpnt;
                    ctrl_sig_rpnt <= ctrl_sig_nrpnt;
                    ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                end
                else begin
                    ctrl_state <= wait_for_high;
                end  
            end
        initialize:
            begin
                if (ctrl_sig_nwpnt < max_arr_pnt_i) begin
                    ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                    init_ctrl_sig_rpnt <= init_ctrl_sig_nrpnt;
                end
                else if (!do_init_i) begin
                    ctrl_state <= wait_for_high;
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


//////////////////////////////////////////////////////////////////////////////////
///SMOOTHING LOGIC////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

reg [14-1:0] trigger_cnt = 14'd0;
reg          wait_for_high_trigger = 1'b1;

always @(posedge clk_i)
begin 
    if (smoothing_rstn_i) begin
        trigger_cnt <= 14'd0;
        wait_for_high_trigger = 1'b1;
        do_smoothing <= 1'b0;
    end
    else begin
        if (wait_for_high_trigger) begin
            if (ctrl_state == high) begin
                if (k_p != 14'd0) begin
                    trigger_cnt <= trigger_cnt + 14'd1;
                end
                wait_for_high_trigger <= 1'b0;
            end
        end
        else begin
            if (ctrl_state == low) begin
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



//////////////////////////////////////////////////////////////////////////////////
///MONITORING///////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


///MONITORING STATES////////////////////////////////////////////////////////////
reg need_to_relock = 1'b0;

reg [32-1:0] error_sum;

wire [32-1:0] error_avg;

reg [32-1:0] old_error_avg;

wire error_full;

reg err_avg_rstn = 1'b0;
reg new_data = 1'd0;
reg [32-1:0] err_raw = 32'd0;

moving_averager_128 avg_err0(
    .clk_i(clk_i),
    .rstn_i(err_avg_rstn),
    .dat_i(err_raw),
    .dat_o(error_avg),
    .full_o(error_full),
    .new_data_i(new_data)
);



wire [32-1:0] current_spread;
assign current_spread = $signed(error_sum) - $signed(error_avg);

wire [32-1:0] abs_current_spread;
assign abs_current_spread = ($signed(current_spread) > 0)? $signed(current_spread):-$signed(current_spread);

wire [32-1:0] avg_spread;

wire spread_full;

moving_averager_128 spread(
    .clk_i(clk_i),
    .rstn_i(err_avg_rstn),
    .dat_i(abs_current_spread),
    .dat_o(avg_spread),
    .full_o(spread_full),
    .new_data_i(new_data)
);

reg [15-1:0] abs_error = 15'd0;

always @(posedge clk_i)
begin
    if (!monitoring_rstn_i) begin
        case (ctrl_state)
            wait_for_high:
                begin
                    err_raw <= error_sum;
                    new_data <= 1'b1;
                    err_avg_rstn <= 1'b0;
                    //if (error_full) begin
                    //    if (error_avg > old_error_avg + error_threshold_i) begin // relock criterion
                    //        need_to_relock <= 1'b1;
                    //    end
                    //end
                    old_error_avg <= error_avg;
                end
            high:
                begin
                    if (need_to_relock) begin
                        k_p <= 14'd0;
                    end
                    else begin
                        k_p <= k_p_i;
                    end
                end
            wait_for_low:
                begin
                    new_data <= 1'b0;
                    error_sum <= 32'b0;
                end
            low:
                begin
                    if ((ref_rpnt > min_err_range_i) && (ref_rpnt < max_err_range_i)) begin
                        if($signed(error) > 0) begin
                            abs_error <= $signed(error);
                        end
                        else begin
                            abs_error <= -$signed(error);
                        end
                        error_sum <= error_sum + $signed(abs_error);
                    end
                end
            initialize:
                begin
                    err_avg_rstn <= 1'b1;
                    need_to_relock <= 1'b0;
                end
        endcase
    end
    else begin
        need_to_relock <= 1'b0;
        err_avg_rstn <= 1'b1;
        k_p <= k_p_i;
    end

end

assign error_avg_o = err_raw; //for works better than with averager
assign need_to_relock_o = need_to_relock;
assign avg_spread_o = avg_spread;

//////////////////////////////////////////////////////////////////////////////////
///GENERAL BUF LOGIC//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


///GENERAL BUF RAM INITIALIZATION/////////////////////////////////////////////////
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

///GENERAL BUF WIRING/////////////////////////////////////////////////////////////
reg [14-1:0] general_out;
wire [14-1:0] general_buf_wpnt;

assign general_buf_wpnt = ctrl_sig_rpnt;

always @(posedge clk_i)
begin
    general_buf_wdata <= $signed(general_out);
    general_buf_we <= ((ctrl_state == low) && !general_buf_state_i[2]) || ((ctrl_state == high) && general_buf_state_i[2]); // only if both are high or both are low set WE to high
    general_buf_waddr <= general_buf_wpnt;
    general_buf_raddr <= buf_addr_i;
    
    general_buf_rdata_o <= general_buf_rdata;
end


///GENERAL BUF MUX////////////////////////////////////////////////////////////////
always @(posedge clk_i)
begin
    case (general_buf_state_i)
        // to be read out when trigger is low
        3'b000: begin general_out <= $signed(ref_rdata_A); end
        3'b001: begin general_out <= $signed(pd_rdata_A); end
        3'b010: begin general_out <= $signed(error); end
        3'b011: begin general_out <= $signed(scaled_error[29-1:15]); end
        
        // to be read out when trigger is high
        3'b100: begin general_out <= $signed(output_val); end // controller output
        3'b101: begin general_out <= $signed(init_ctrl_sig_rdata_A); end
        3'b111: begin general_out <= $signed(avg_output_val); end
    endcase
end

assign test_sig_o = general_out;

endmodule
