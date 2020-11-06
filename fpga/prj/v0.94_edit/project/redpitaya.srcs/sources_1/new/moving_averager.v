`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2020 17:28:09
// Design Name: 
// Module Name: moving_averager
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


module moving_averager(
    input [14-1:0]  dat_i,
    input [14-1:0]  dat_o,
    input           clk_i,
    input           rstn_i
    );
    
/////////////////////////////
///CREATING MOVING AVERAGE///
/////////////////////////////
reg [14-1:0] avg_buf [0:8-1];
reg [14-1:0] avg;
reg [14-1:0] old_val;

reg [17-1:0] sum;

always @(posedge clk_i)
begin
    avg_buf[w_pnt] <= dat_i;
    old_val <= avg_buf[r_pnt];
    
    sum <= sum + dat_i - old_val;
    
    avg <= sum[17-1:3];
   
end


    
endmodule
