`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2020 16:15:16
// Design Name: 
// Module Name: moving_averager_64
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


module moving_averager_64(
    input clk_i,
    input rstn_i,
    input [14-1:0] dat_i,
    output [14-1:0] dat_o
    );
    
reg [14-1:0] avg_buf [0:64-1];
reg [14-1:0] avg;
reg [14-1:0] old_val;

reg [22-1:0] sum;

reg [6-1:0] w_pnt = 6'd0; // as we have up to 64 elements in avg_buf,
reg [6-1:0] r_pnt = 6'd1;

reg full = 1'b0;

always @(posedge clk_i)
begin
    avg_buf[w_pnt] <= $signed(dat_i);
    old_val <= $signed(avg_buf[r_pnt]);
    
    if (full)
        sum <= $signed(sum) + $signed(dat_i) - $signed(old_val);
    else
        sum <= $signed(sum) + $signed(dat_i);
        
    avg <= $signed(sum[20-1:6]);
end
assign dat_o = $signed(avg);

always @(posedge clk_i)
begin
    w_pnt <= w_pnt + 6'd1;
    r_pnt <= r_pnt + 6'd1;
end

always @(posedge clk_i)
begin
    full <= (full) || (r_pnt==0);
end

endmodule
