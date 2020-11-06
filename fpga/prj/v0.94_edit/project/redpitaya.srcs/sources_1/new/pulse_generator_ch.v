`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Max-Planck-Institute of Quantum Optics, Quantum Dynamics Division
// Engineer: Maximilian Winter
// 
// Create Date: 10/19/2020 02:26:17 PM
// Design Name: 
// Module Name: pulse_generator_ch
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pulse_generator_ch(
    input               clk_i           ,
    input               rstn_i          ,
    
    // Channel
    input                   trigger_i       ,
    input       [ 14-1: 0]  dat_i           ,
    output      [ 14-1: 0]  dat_o           ,
    
    // Buffer organisation
    input                   buf_we_i        ,
    input       [ 14-1: 0]  buf_addr_i      ,
    input       [ 14-1: 0]  buf_wdata_i     ,
    output reg  [ 14-1: 0]  buf_rdata_o     ,
    output reg  [ 14-1: 0]  buf_rpnt_o      ,
    
    output reg  [ 14-1: 0]  sig_buf_rdata_o ,
    
    input       [ 14-1: 0]  amp_i           ,
    input       [ 14-1: 0]  offset_i        ,
    input                   offset_mode_i   ,
    input       [ 14-1: 0]  wf_delay_i      ,
    input       [ 14-1: 0]  swf_delay_i     ,
    input       [ 14-1: 0]  set_ki_i        ,
    input                   int_rst_i       ,
    input       [ 3-1: 0]   ch_mode_i       ,
    input       [ 30-1: 0]  step_i          ,
    input                   delta_state_i   
    );
    

////////////////////////
///WAVEFORM BUFFERING///
////////////////////////

reg [15-1: 0]   wf_buf [0:16383]   ;

always @(posedge clk_i)
begin
    if (buf_we_i) wf_buf[buf_addr_i] <= buf_wdata_i[14-1:0];
end
    
always @(posedge clk_i)
begin
    buf_rdata_o <= wf_buf[buf_addr_i];
end

reg [15-1: 0]   wf_current_val;
reg [15-1: 0]   wf_pppp_val;
reg [15-1: 0]   wf_ppp_val;
reg [15-1: 0]   wf_pp_val;
reg [15-1: 0]   wf_p_val;
    
wire [14-1: 0]   wf_rp      ;
reg [30-1: 0]   wf_pnt     ;
wire [31-1: 0]  wf_npnt    ;

always @(posedge clk_i)
begin
    wf_pppp_val <= wf_buf[wf_rp];
    wf_ppp_val <= wf_pppp_val;
    wf_pp_val <= wf_ppp_val;
    
    wf_p_val <= wf_pp_val;
    wf_current_val <= wf_p_val;
   
end

reg  wf_iteration_done = 1'b0;
reg [14-1:0] wf_delay_counter = 14'h0;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0)
    begin
        wf_pnt <= {30{1'b0}};
	wf_iteration_done <= 1'b0;
	wf_delay_counter <= 14'h0;
    end
  
    if (trigger_i == 1'b1) begin
        if (wf_iteration_done == 1'b1) begin
            wf_pnt <= {30{1'b0}};
        end
        else begin
	    if (wf_delay_counter < wf_delay_i) begin
	        wf_delay_counter <= wf_delay_counter + 14'd1;
	    end
	    else begin		
		    if (wf_npnt[29:16] < 14'd16383) begin
		        wf_pnt <= wf_npnt[29:0];
		    end
		    else if (wf_npnt[29:16] == 14'd16383) begin
		        wf_iteration_done <= 1'b1;
		        wf_pnt <= {30{1'b0}};
		    end
	    end	
        end
    end
    else begin
        wf_pnt <= {30{1'b0}};
        wf_iteration_done <= 1'b0;
	wf_delay_counter <= 14'h0;
    end
end

assign wf_npnt = wf_pnt + {14'd1,{16{1'b0}}}; //step_i; TODO: can change to step_i
assign wf_rp = wf_pnt[29:16];

///////////////////////////////
///SCALED WAVEFORM BUFFERING///
///////////////////////////////

reg [14-1: 0]   swf_current_val;
reg [15-1: 0]   swf_pppp_val;
reg [15-1: 0]   swf_ppp_val;
reg [15-1: 0]   swf_pp_val;
reg [29-1: 0]   swf_p_val;

wire [14-1: 0]   swf_rp      ;
reg [30-1: 0]   swf_pnt     ;
wire [31-1: 0]  swf_npnt    ;

always @(posedge clk_i)
begin
    swf_pppp_val <= wf_buf[swf_rp];
    swf_ppp_val <= swf_pppp_val;
    swf_pp_val <= swf_ppp_val;
    
    swf_p_val <= $signed(swf_pp_val) * $signed(amp_i);
    swf_current_val <= swf_p_val[29-1:15];
end

reg  swf_iteration_done = 1'b0;
reg [14-1:0] swf_delay_counter = 14'h0;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0)
    begin
        swf_pnt <= {30{1'b0}};
	swf_iteration_done <= 1'b0;
	swf_delay_counter <= 14'h0;
    end
  
    if (trigger_i == 1'b1) begin
        if (swf_iteration_done == 1'b1) begin
            swf_pnt <= {30{1'b0}};
        end
        else begin
	    if (swf_delay_counter < swf_delay_i) begin
	        swf_delay_counter <= swf_delay_counter + 14'd1;
	    end
	    else begin		
		    if (swf_npnt[29:16] < 14'd16383) begin
		        swf_pnt <= swf_npnt[29:0];
		    end
		    else if (swf_npnt[29:16] == 14'd16383) begin
		        swf_iteration_done <= 1'b1;
		        swf_pnt <= {30{1'b0}};
		    end
	    end	
        end
    end
    else begin
        swf_pnt <= {30{1'b0}};
        swf_iteration_done <= 1'b0;
	swf_delay_counter <= 14'h0;
    end
end

assign swf_npnt = swf_pnt + {14'd1,{16{1'b0}}}; //step_i; TODO: can change to step_i
assign swf_rp = swf_pnt[29:16];

////////////////////////
///OFFSET CALCULATION///
////////////////////////
reg [14-1:0]    offset = 14'h0;
reg  [   8-1: 0] counter_off = 8'h1; 
reg  [  21-1: 0] offset_reg  = 21'h0; // Bit 21 (MSB) reserved for potential overflow during signed addition/subtraction
reg  [  14-1: 0] offset_meas = 14'h0;

always @(posedge clk_i)
begin
    if (trigger_i == 1'b0) begin
        if ($signed(counter_off) <= 8'sh40) begin
            if (offset_reg[21-1:21-2] == 2'b01) begin
                offset_reg <= 21'h7FFFF;
            end
            else if (offset_reg[21-1:21-2] == 2'b10) begin
                offset_reg <= 21'h80000;
            end
            else begin
                offset_reg <= $signed(offset_reg[20:0]) + $signed(dat_i);
            end
        end
        else begin //NOTE: in original file: '=' instead of '<='
            counter_off = 8'h0;
            offset_meas = offset_reg[20-1:6];
            offset_reg = 21'h0;
        end
        counter_off <= counter_off + 8'h1;
    end
end

//////////////////////
///OFFSET SELECTION///
//////////////////////
always @(posedge clk_i)
begin
    case (offset_mode_i)
        1'b0: begin offset <= offset_i; end
        1'b1: begin offset <= offset_meas; end
    endcase
end

////////////////////////////
///INIT INTEGRATOR MODULE///
////////////////////////////
wire [ 14-1: 0] error;
wire [ 14-1: 0] int_out;
wire [ 14-1: 0] i_cont;

pulse_generator_init init(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .trigger_i(trigger_i),
    
    .wf_current_val_i(wf_current_val),
    .swf_current_val_i(swf_current_val),
    .dat_i(dat_i),
    
    .offset_i(offset),
    .wf_rp_i(wf_rp),
    .swf_rp_i(swf_rp),
    
    .set_ki_i(set_ki_i),
    .int_rst_i(int_rst_i),
    
    .error_o(error),
    .int_o(int_out),
    .i_cont_o(i_cont)
);

/////////////////////////
///DELTA FINDER MODULE///
/////////////////////////
/*
pulse_generator_delta_finder delta_finder(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .trigger_i(trigger_i),
    
    .swf_current_val_i(swf_current_val),
    .dat_i(dat_i),
    .state_i(delta_state_i)
);
*/






















/////////////////
///OUTPUT MODE///
/////////////////

reg [14-1:0] gen_out;

always @(posedge clk_i)
begin
    case(ch_mode_i)
        3'b000: begin gen_out <= $signed(i_cont); end
        3'b001: begin gen_out <= $signed(wf_current_val); end
        3'b010: begin gen_out <= $signed(swf_current_val); end
        3'b011: begin gen_out <= $signed(error); end
        3'b100: begin gen_out <= $signed(int_out); end
        3'b101: begin gen_out <= $signed(dat_i); end
    endcase
end

assign dat_o = $signed(i_cont);


///////////////////////////////
///WRITING SIGNALS TO MEMORY///
///////////////////////////////
reg [14-1:0] sig_buf [0:16383];

reg [14-1:0] buf_pnt;
wire [14-1:0] buf_npnt;

reg buf_iteration_done = 1'b0;
// signal buffer logic
always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        buf_pnt <= {14{1'b0}};        
        buf_iteration_done <= 1'b0;
    end
    
    if (trigger_i == 1'b1) begin
        if (buf_iteration_done == 1'b1) begin
            buf_pnt <= {14{1'b0}}; 
        end
        else begin
            if (buf_npnt < 14'd16383) begin
                buf_pnt <= buf_npnt;
            end
            else if (buf_npnt == 14'd16383) begin
                buf_iteration_done <= 1'b1;
                buf_pnt <= {14{1'b0}};
            end
        end
    end
    else begin
        buf_pnt <= {14{1'b0}};
        buf_iteration_done <= 1'b0;
    end
end
assign buf_npnt = buf_pnt + 14'd1;

always @(posedge clk_i) begin
    sig_buf[buf_pnt] <= $signed(gen_out);
end

always @(posedge clk_i)
begin
    sig_buf_rdata_o <= sig_buf[buf_addr_i];
end
    
endmodule
