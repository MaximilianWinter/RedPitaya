`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MPQ
// Engineer: Maximilian Winter
// 
// Create Date: 08.01.2021 13:42:13
// Design Name: 
// Module Name: dual_bram
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


module big_dual_bram(
    input       clk_i,
    input [14-1:0] waddr_A_i,
    input [14-1:0] raddr_A_i, 
    input          write_enable_A_i,
    input [29-1:0] data_A_i,
    output reg [29-1:0] data_A_o,
    input [14-1:0] waddr_B_i,
    input [14-1:0] raddr_B_i, 
    input          write_enable_B_i,
    input [29-1:0] data_B_i,
    output reg [29-1:0] data_B_o 
    );

reg [29-1:0] memory_array [0:4096-1]; 

always @(posedge clk_i)
begin
    if (write_enable_A_i) begin
        memory_array[waddr_A_i] <= data_A_i;
    end
    data_A_o <= memory_array[raddr_A_i];
    
    //if (write_enable_B_i) begin
    //    memory_array[waddr_B_i] <= data_B_i;
    //end
    data_B_o <= memory_array[raddr_B_i];
end

endmodule
