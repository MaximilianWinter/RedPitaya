`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 08.01.2021 13:42:45
// Design Name: 
// Module Name: controller_dual_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: like controller_dual_ram; but with delta_finder
//////////////////////////////////////////////////////////////////////////////////


module controller_dual_ram_delta_finder(
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
	//input   [14-1:0]    delta_pd_i,
	input  [14-1:0]    offset_i,
    input              smoothing_rstn_i,
    input [14-1:0]     smoothing_cycles_i,
    
    input [14-1:0]      delta_center_i,
    input [14-1:0]      deltashift_upper_i,
    input [14-1:0]      deltashift_lower_i,
    input [14-1:0]      patience_i,
    input [14-1:0]      deltajump_upper_i,
    input [14-1:0]      deltajump_lower_i,
    input [14-1:0]      min_delta_range_i,
    input [14-1:0]      max_delta_range_i,
    output [14-1:0]     ctrl_sig_rpnt_shift_o,
    output [32-1:0]     err0_o,
    output [32-1:0]     err1_o,
    output [32-1:0]     err2_o,
    output [3-1:0]      delta_finder_state_o,
	
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
//////////////////////////////
///RAM/ARRAY INITIALIZATION///
//////////////////////////////

///INIT CTRL SIGNAL///
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


///CTRL SIGNAL///
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

///PD ARRAY///
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


///REF WF ARRAY///
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

///INIT CTRL SIG///
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


///CTRL SIG///
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


///PD ARRAY///
reg [14-1:0] pd_wpnt;
reg [14-1:0] pd_rpnt;
reg [14-1:0] pd_rpnt_B;
always @(posedge clk_i)
begin
    pd_wdata_A <= pd_i;
    pd_we_A <= trigger_i;
    pd_waddr_A <= pd_wpnt;
    pd_raddr_A <= pd_rpnt;
    
    pd_wdata_B <= 14'd0;
    pd_we_B <= 1'b0;
    pd_waddr_B <= 14'd0;
    //pd_raddr_B <= buf_addr_i;
    pd_raddr_B <= pd_rpnt_B;
    
    pd_rdata_o <= pd_rdata_B;
end

///REF ARRAY///
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
    //ref_raddr_B <= buf_addr_i;
    ref_raddr_B <= ref_rpnt_B;
    
    ref_rdata_o <= ref_rdata_B;
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
            ctrl_sig_we_A <= 1'b1;
            
            output_val <= 14'd0;
            
            error <= $signed(ref_rdata_A) - $signed(pd_rdata_A) + $signed(offset_i);
            scaled_error <= $signed(error) * $signed({1'b0,k_p_i});
            ctrl_sig_wf_preval <= $signed(ctrl_sig_rdata_A) + $signed(scaled_error); //need to include averager
            
            if ($signed(ctrl_sig_wf_preval) < 0)
                ctrl_sig_wf_val <= 29'd0;
            else
                ctrl_sig_wf_val <= ctrl_sig_wf_preval;           
        end
        else begin
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

    end
    else begin //if (trigger_i) begin
        ctrl_sig_we_A <= 1'b1;
        ctrl_sig_wf_val <= $signed({init_ctrl_sig_rdata_A,{15{1'b0}}});
    end
end

assign ctrl_sig_o = avg_output_val; //NOTE: should use averaged output!


///MOVING AVERAGER///


moving_averager_4 avg( // 4 bit averager
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .dat_i(output_val),
    .dat_o(avg_output_val)
);

///////////////////////
///NEW POINTER LOGIC///
///////////////////////


reg [3-1:0] pnt_logic_state = 3'b000;
reg [3-1:0] wait_for_high = 3'b000;
reg [3-1:0] high = 3'b001;
reg [3-1:0] wait_for_low = 3'b010;
reg [3-1:0] low = 3'b011;
reg [3-1:0] initialize = 3'b100;

wire [14-1:0] ctrl_sig_nrpnt;
wire [14-1:0] pd_nwpnt;
wire [14-1:0] ctrl_sig_nwpnt;
wire [14-1:0] init_ctrl_sig_nrpnt;
wire [14-1:0] ref_nrpnt;
wire [14-1:0] pd_nrpnt;

reg smoothing_even_odd_cnt = 1'b0;

reg [14-1:0] ctrl_sig_rpnt_shift = 14'd0;
always @(posedge clk_i)
begin
    case (pnt_logic_state)
        wait_for_high:
            begin
                if (trigger_i)
                    pnt_logic_state <= high;
                // initialize pointers:
                
                pd_wpnt <= 14'd0;
                init_ctrl_sig_rpnt <= 14'd0;
                
                if (do_init_i) begin
                    ctrl_sig_wpnt <= 14'd0;
                    ctrl_sig_rpnt <= 14'd0;
                    pnt_logic_state <= initialize;
                end
                else if (do_smoothing) begin
                    smoothing_even_odd_cnt <= !(smoothing_even_odd_cnt);
                    ctrl_sig_wpnt <= wpnt_init_offset_i + {{13{1'b0}},smoothing_even_odd_cnt};
                    ctrl_sig_rpnt <= 14'd0;
                end
                else begin
                    ctrl_sig_rpnt <= 14'd0 + $signed(ctrl_sig_rpnt_shift);
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
                    pnt_logic_state <= wait_for_low;
                    zero_output <= 1'b0;
                end
            end
        wait_for_low:
            begin
                if (!trigger_i)
                    pnt_logic_state <= low;
                    
                pd_rpnt <= 14'd6 + delta_center_i;
                ref_rpnt <= 14'd6;
                ctrl_sig_rpnt <= 14'd4;
                ctrl_sig_wpnt <= 14'd0;
                
                if (do_init_i) begin
                    init_ctrl_sig_rpnt <= 14'd0;
                    pnt_logic_state <= initialize;
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
                    pnt_logic_state <= wait_for_high;
                end  
            end
        initialize:
            begin
                if (ctrl_sig_nwpnt < max_arr_pnt_i) begin
                    ctrl_sig_wpnt <= ctrl_sig_nwpnt;
                    init_ctrl_sig_rpnt <= init_ctrl_sig_nrpnt;
                end
                else if (!do_init_i) begin
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


/////////////////////
///SMOOTHING LOGIC///
/////////////////////

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



//////////////////
///DELTA FINDER///
//////////////////

//error_sum[0] <= error_sum[0] + ($signed(ref_lutram[pd_wpnt-(delta_center-deltashift_lower_i)])>$signed(pd_wdata))?($signed(ref_lutram[pd_wpnt-(delta_center-deltashift_lower_i)]) - $signed(pd_wdata)):($signed(pd_wdata) - $signed(ref_lutram[pd_wpnt-(delta_center-deltashift_lower_i)]));

reg [3-1:0] delta_finder_state = 3'b000;
reg [3-1:0] delta_wait_for_low = 3'b000;
reg [3-1:0] delta_get_error_sums = 3'b001;
reg [3-1:0] delta_store_error_sums = 3'b010;
reg [3-1:0] delta_compare_error_sums = 3'b011;
reg [3-1:0] evaluate_patience_cnts = 3'b100;
reg [3-1:0] delta_wait_for_high = 3'b101;

reg [15-1:0] error_B;
reg [15-1:0] abs_error_B;

reg [32-1:0] error_sum [0:3-1];
reg [2-1:0] error_sum_index = 2'b00;

reg [32-1:0] err0 = 32'd0;
reg [32-1:0] err1 = 32'd0;
reg [32-1:0] err2 = 32'd0;

reg [14-1:0] upper_patience_cnt = 14'd0;
reg [14-1:0] lower_patience_cnt = 14'd0;

always @(posedge clk_i)
begin   
    if (!do_init_i) begin
        case (delta_finder_state)
            delta_wait_for_low:
                begin
                    if (!trigger_i) begin
                        delta_finder_state <= delta_get_error_sums;
                    end
                    ref_rpnt_B <= 14'd0 + min_delta_range_i;
                    pd_rpnt_B <= (delta_center_i-deltashift_lower_i) + min_delta_range_i; //peak will be later
                    
                    error_sum_index <= 2'd0;
                    error_sum[0] <= 32'd0;
                    error_sum[1] <= 32'd0;
                    error_sum[2] <= 32'd0;
                end
                
            delta_get_error_sums:
                begin
                    if (ref_rpnt_B < max_delta_range_i) begin
                        error_B <= $signed(ref_rdata_B) - $signed(pd_rdata_B) + $signed(offset_i);
                        
                        if ($signed(error_B) > 0) begin
                            abs_error_B <= $signed(error_B);
                        end
                        else begin
                            abs_error_B <= -$signed(error_B);
                        end
                        error_sum[error_sum_index] <= error_sum[error_sum_index] + $signed(abs_error_B);
                        ref_rpnt_B <= ref_rpnt_B + 14'd1;
                        pd_rpnt_B <= pd_rpnt_B + 14'd1;
                    end
                    else begin
                        ref_rpnt_B <= 14'd0 + min_delta_range_i;
                        if (error_sum_index == 2'b00) begin
                            pd_rpnt_B <= delta_center_i + min_delta_range_i;
                            
                            
                            error_sum_index <= 2'b01;
                        end
                        else if (error_sum_index == 2'b01) begin
                            pd_rpnt_B <= (delta_center_i + deltashift_upper_i)+ min_delta_range_i;
                    
                            error_sum_index <= 2'b10;
                        end
                        else if (error_sum_index == 2'b10) begin
                            error_sum_index <= 2'b00;
                            delta_finder_state <= delta_store_error_sums;
                        end
                    end
                end
                
            delta_store_error_sums:
                begin
                    err0 <= error_sum[0];
                    err1 <= error_sum[1];
                    err2 <= error_sum[2];
                    delta_finder_state <= delta_compare_error_sums;
                end
            
            delta_compare_error_sums:
                begin
                    if ((err0 < err1) || (err2 < err1)) begin
                        if (err0 < err2) begin
                            lower_patience_cnt <= lower_patience_cnt + 14'd1;
                            upper_patience_cnt <= 14'd0;
                        end
                        else begin
                            lower_patience_cnt <= 14'd0;
                            upper_patience_cnt <= upper_patience_cnt + 14'd1;
                        end
                    end
                    else begin
                        lower_patience_cnt <= 14'd0;
                        upper_patience_cnt <= 14'd0;
                    end
                    delta_finder_state <= evaluate_patience_cnts;
                end
                
            evaluate_patience_cnts:
                begin
                    if (lower_patience_cnt == patience_i) begin
                        ctrl_sig_rpnt_shift <= ctrl_sig_rpnt_shift - deltajump_lower_i; // PD peak should be later
                        lower_patience_cnt <= 14'd0;
                        upper_patience_cnt <= 14'd0;
                    end
                    else if (upper_patience_cnt == patience_i) begin
                        ctrl_sig_rpnt_shift <= ctrl_sig_rpnt_shift + deltajump_upper_i; // PD peak should be earlier
                        lower_patience_cnt <= 14'd0;
                        upper_patience_cnt <= 14'd0;
                    end
                    delta_finder_state <= delta_wait_for_high;
                end
                
            delta_wait_for_high:
                begin
                    if (trigger_i) begin
                        delta_finder_state <= delta_wait_for_low;
                    end
                end
        endcase        
    end
    else begin
        ctrl_sig_rpnt_shift <= 14'd0;
        delta_finder_state <= delta_wait_for_low;
        lower_patience_cnt <= 14'd0;
        upper_patience_cnt <= 14'd0;
    end
end

assign err0_o = err0;
assign err1_o = err1;
assign err2_o = err2;
assign  ctrl_sig_rpnt_shift_o =  ctrl_sig_rpnt_shift;

assign delta_finder_state_o = delta_finder_state;

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
