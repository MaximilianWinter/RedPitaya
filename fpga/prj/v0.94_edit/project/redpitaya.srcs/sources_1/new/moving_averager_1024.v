`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.01.2021 13:48:40
// Design Name: 
// Module Name: moving_averager_1024
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


module moving_averager_1024(
    input clk_i,
    input rstn_i,
    input [32-1:0] dat_i,
    output [32-1:0] dat_o,
    output          full_o,
    input           new_data_i
    );
    
reg [32-1:0] avg_buf [0:1024-1];
reg [32-1:0] avg;
reg [32-1:0] old_val;

reg [44-1:0] sum;

reg [10-1:0] w_pnt = 10'd0; // as we have up to 2^10=1024 elements in avg_buf,
reg [10-1:0] r_pnt = 10'd1;

reg full = 1'b0;

reg [2-1:0] state = 2'b00;
reg [2-1:0] wait_for_high = 2'b00;
reg [2-1:0] high = 2'b01;
reg [2-1:0] increase_counter = 2'b10;
reg [2-1:0] wait_for_low = 2'b11;

always @(posedge clk_i)
begin
    case(state)
        wait_for_high:
            begin
                if (new_data_i) begin
                    state <= high;
                end
            end
        high:
            begin
                avg_buf[w_pnt] <= $signed(dat_i);
                old_val <= $signed(avg_buf[r_pnt]);
                
                if (full)
                    sum <= $signed(sum) + $signed(dat_i) - $signed(old_val);
                else
                    sum <= $signed(sum) + $signed(dat_i);
                    
                avg <= $signed(sum[42-1:10]);
                state <= increase_counter;
            end
        increase_counter:
            begin
                w_pnt <= w_pnt + 10'd1;
                r_pnt <= r_pnt + 10'd1;
                state <= wait_for_low;
            end
        wait_for_low:
            begin
                if (!new_data_i) begin
                    state <= wait_for_high;
                end
            end
    endcase
    
end
assign dat_o = $signed(avg);

always @(posedge clk_i)
begin
    full <= (full) || (r_pnt==10'd0);
end

assign full_o = full;

endmodule
