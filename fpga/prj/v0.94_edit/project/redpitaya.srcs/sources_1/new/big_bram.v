`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MPQ
// Engineer: Maximilian Winter
// 
// Create Date: 10/18/2020 01:57:42 PM
// Design Name: 
// Module Name: big_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: based on simple RAM module, sram.v; but with larger elements (29 bit)
// 
//////////////////////////////////////////////////////////////////////////////////


module big_bram(
    input       clk_i,
    input [14-1:0] waddr_i,
    input [14-1:0] raddr_i, 
    input          write_enable_i,
    input [29-1:0] data_i,
    output reg [29-1:0] data_o 
    );

reg [29-1:0] memory_array [0:16384-1]; 

always @(posedge clk_i)
begin
    if (write_enable_i) begin
        memory_array[waddr_i] <= data_i;
    end
    data_o <= memory_array[raddr_i];
end

endmodule