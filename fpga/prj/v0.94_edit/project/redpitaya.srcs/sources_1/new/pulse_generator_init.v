`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 29.10.2020 15:30:47
// Design Name: 
// Module Name: pulse_generator_init
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


module pulse_generator_init(
    input                   clk_i               ,
    input                   rstn_i              ,
    
    input                   trigger_i           ,
    
    input       [ 15-1:0]   wf_current_val_i    ,
    input       [ 14-1:0]   swf_current_val_i   ,
    input       [ 14-1:0]   dat_i               ,
    
    input       [ 14-1:0]   offset_i            ,
    input       [ 14-1:0]   wf_rp_i             ,
    input       [ 14-1:0]   swf_rp_i            ,
    input       [ 14-1:0]   set_ki_i            ,
    input                   int_rst_i           ,
    
    output      [ 15-1:0]   error_o             ,
    output      [ 14-1:0]   int_o               ,
    output      [ 14-1:0]   i_cont_o            

    );
    
//////////////////////////////
///ERROR SIGNAL CALCULATION///
//////////////////////////////

reg [15-1:0] error;
reg error_calc_done = 1'b0;


always @(posedge clk_i)
begin
    if (trigger_i == 1'b1) begin
        if (error_calc_done) begin
            error <= 15'h0;
        end
        else begin
            if (swf_rp_i < 14'd16383) begin
                error <= $signed(swf_current_val_i) - $signed(dat_i) + $signed(offset_i);
            end
            else if (swf_rp_i == 14'd16383) begin
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

assign error_o = error;

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
    
    
///////////////////////
///CONTROLLER OUTPUT///
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
            if (wf_rp_i < 14'd16383) begin
                pid_reg <= $signed(wf_current_val_i) * $signed(int_out);
            end
            else if (wf_rp_i == 14'd16383) begin
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

assign i_cont_o = $signed(pid_reg[29-1:15]);
assign int_o = $signed(int_out);
    
endmodule
