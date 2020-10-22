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
    
    input       [ 14-1: 0]  amp_i           ,
    input       [ 14-1: 0]  offset_i        ,
    input                   offset_mode_i   ,
    input       [ 14-1: 0]  delay_i         ,
    input       [ 14-1: 0]  set_ki_i        ,
    input                   int_rst_i       ,
    input       [ 3-1: 0]   ch_mode_i       ,
    input       [ 30-1: 0]  step_i
    );
    
////////////////////////
///WAVEFORM BUFFERING///
////////////////////////

reg [14-1: 0]   wf_buf [0:16384]   ;

reg [28-1: 0]   scaled_wf_p_val;
//reg [14-1: 0]   scaled_wf_prev_val;
reg [14-1: 0]   scaled_wf_current_val;
reg [14-1: 0]   wf_current_val;
reg [14-1: 0]   wf_pppp_val;
reg [14-1: 0]   wf_ppp_val;
reg [14-1: 0]   wf_pp_val;
reg [14-1: 0]   wf_p_val;
    
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

// TODO: check delays induced by that! should be 3 clk cycles = 24ns
always @(posedge clk_i)
begin
    scaled_wf_p_val <= $signed(wf_pp_val) * $signed({1'b0,amp_i});
    scaled_wf_current_val <= scaled_wf_p_val[28-1:13];
end

always @(posedge clk_i)
begin
    if (buf_we_i) wf_buf[buf_addr_i] <= buf_wdata_i[14-1:0];
end
    
always @(posedge clk_i)
begin
    buf_rdata_o <= wf_buf[buf_addr_i];
end

reg  iteration_done = 1'b0;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0)
    begin
        wf_pnt <= {30{1'b0}};
    end
  
    if (trigger_i == 1'b1) begin
        if (iteration_done == 1'b1) begin
            wf_pnt <= {30{1'b0}};
        end
        else begin
            if (wf_npnt[29:16] < 14'd16383) begin
                wf_pnt <= wf_npnt[29:0];
            end
            else if (wf_npnt[29:16] == 14'd16383) begin
                iteration_done <= 1'b1;
                wf_pnt <= {30{1'b0}};
            end
        end
    end
    else begin
        wf_pnt <= {30{1'b0}};
        iteration_done <= 1'b0;
    end
end

assign wf_npnt = wf_pnt + {14'd1,{16{1'b0}}}; //step_i; TODO: can change to step_i
assign wf_rp = wf_pnt[29:16];

//////////////////////////////
///ERROR SIGNAL CALCULATION/// ///TODO: Implement other type of delay
//////////////////////////////

reg [15-1:0]    error = 15'h0;
reg             error_calc_done = 1'b0;

reg [14-1:0]    offset = 14'h0;

always @(posedge clk_i)
begin
    if (trigger_i == 1'b1) begin
        if (error_calc_done) begin
            error <= 15'h0;
        end
        else begin
            if (wf_rp > delay_i && wf_rp < 14'd16383) begin
                error <= $signed(scaled_wf_current_val) - $signed(dat_i) + $signed(offset);
            end
            else if (wf_rp == 14'd16383) begin
                error_calc_done <= 1'b1;
                error <= 15'h0;
            end
        end    
    end
    else begin
        error <= 15'h0;
        error_calc_done <= 1'b0;    
    end
end 

////////////////////////
///OFFSET CALCULATION///
////////////////////////
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
            counter_off <= 8'h0;
            offset_meas <= offset_reg[20-1:6];
            offset_reg <= 21'h0;
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

////////////////
///INTEGRATOR///
////////////////

reg  [29-1:0]   ki_mult;
wire [33-1:0]   int_sum;
reg  [32-1:0]   int_reg;
wire [14-1:0]   int_out;

always @(posedge clk_i)
begin
    ki_mult <= $signed(error) * $signed(set_ki_i);
    
    if (int_rst_i) begin
        int_reg <= 32'h0;
    end
    else if (int_sum[33-1:33-2] == 2'b01) begin
        int_reg <= 32'h7FFFFFFF;
    end
    else if (int_sum[33-1:33-2] == 2'b10) begin
        int_reg <= 32'h80000000;
    end
    else begin
        int_reg <= int_sum[32-1:0];
    end
end

assign int_sum = $signed(ki_mult) + $signed(int_reg);
assign int_out = int_reg[32-1:18]; 

//////////////////////////
///INTEGRATOR AVERAGING///
//////////////////////////


reg [8-1:0]     counter_int = 8'h1;
reg [21-1:0]    int_avg_reg = 21'h0;
reg [14-1:0]    int_avg = 14'h0;

always @(posedge clk_i)
begin
    if ($signed(counter_int) <= 8'sh40) begin
        if (int_avg_reg[21-1:21-2] == 2'b01) begin
            int_avg <= 21'h7FFFF;
        end
        else if (int_avg_reg[21-1:21-2] == 2'b10) begin
            int_avg_reg <= 21'h80000;
        end
        else begin
            int_avg_reg <= $signed(int_avg_reg[20:0]) + $signed(int_out);
        end
    end
    else begin //NOTE: in original file, equal signs used instead of arrows
        counter_int <= 8'h0;
        int_avg <= int_avg_reg[20-1:6];
        int_avg_reg <= 21'h0;
    end
    counter_int <= counter_int + 8'h1;
end 

///////////////////////
///CONTROLLER OUTPUT/// TODO; in original file: WAVE 2
///////////////////////


reg [29-1:0]    pid_reg = 29'h0;
reg             controller_out_done = 1'b0;

always @(posedge clk_i)
begin
    if (trigger_i == 1'b1) begin
        if (controller_out_done) begin
            pid_reg <= 29'h0;
        end
        else begin            
            if (wf_rp < 14'd16383) begin
                pid_reg <= $signed(wf_current_val) * $signed(int_out); //NOTE: actually WAVE 2
            end
            else if (wf_rp == 14'd16383) begin
                controller_out_done <= 1'b1;
                pid_reg <= 29'h0;
            end
        end
    end
    else begin
        pid_reg <= 29'h0;
        controller_out_done <= 1'b0;
    end
end 

/////////////////
///OUTPUT MODE///
/////////////////

reg [14-1:0] gen_out;

always @(posedge clk_i)
begin
    case(ch_mode_i)
        3'b000: begin gen_out <= $signed(pid_reg[29-1:15]); end
        3'b001: begin gen_out <= $signed(wf_current_val); end
        3'b010: begin gen_out <= $signed(scaled_wf_current_val); end
        3'b011: begin gen_out <= $signed(error); end
        3'b100: begin gen_out <= $signed(int_out); end
    endcase
end

assign dat_o = gen_out;


    
endmodule
