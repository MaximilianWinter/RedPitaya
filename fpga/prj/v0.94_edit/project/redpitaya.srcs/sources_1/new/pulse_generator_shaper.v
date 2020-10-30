`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2020 09:39:29
// Design Name: 
// Module Name: pulse_generator_shaper
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


module pulse_generator_shaper(
    input           clk_i

    );

reg [14-1:0] previous_pg_out [0:16383];
reg [14-1:0] previous_pd_in [0:16383];

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        pg_pt <={
    end

end
    
endmodule
