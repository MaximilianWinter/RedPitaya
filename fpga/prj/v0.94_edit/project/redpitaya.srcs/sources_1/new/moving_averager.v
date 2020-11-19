`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
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
// Additional Comments: should work, needs to get tested
// 
//////////////////////////////////////////////////////////////////////////////////


module moving_averager(
    input [14-1:0]  dat_i,
    input [14-1:0]  dat_o,
    input           clk_i,
    input           rstn_i,
    input [3-1:0]   buf_state_i,
    input	     buf_rstn_i		
    );
    
/////////////////////////////
///CREATING MOVING AVERAGE///
/////////////////////////////
reg [14-1:0] avg_buf [0:64-1];
reg [14-1:0] avg;
reg [14-1:0] old_val;

reg [20-1:0] sum;

reg [7-1:0] w_pnt = 7'd0; // as we have up to 64 elements in avg_buf,
reg [7-1:0] r_pnt = 7'd1; // the pointers can be in the range 0-64 (always one extra element needed)

always @(posedge clk_i)
begin
    if (buf_rstn_i) begin
        sum <= 20'd0;
    end
    else begin
        avg_buf[w_pnt] <= dat_i;
        old_val <= avg_buf[r_pnt];
        
        sum <= sum + dat_i - old_val;
        
        case(buf_state_i)
            3'b000: begin avg <= dat_i; end
            3'b001: begin avg <= sum[15-1:1]; end // division by 2
            3'b010: begin avg <= sum[16-1:2]; end // division by 4
            3'b011: begin avg <= sum[17-1:3]; end // division by 8
            3'b100: begin avg <= sum[18-1:4]; end // division by 16
            3'b101: begin avg <= sum[19-1:5]; end // division by 32
            3'b110: begin avg <= sum[20-1:6]; end // division by 64
        endcase
    end
   
end
assign dat_o = avg;

reg [7-1:0] max_val = 7'd64;

always @(posedge clk_i)
begin
    if (buf_rstn_i) begin
        w_pnt = 7'd0;
        r_pnt = 7'd1;
    end
	
    
    case(buf_state_i)
    	3'b001: begin max_val <= 7'd2; end // division by 2
    	3'b010: begin max_val <= 7'd4; end // division by 4
    	3'b011: begin max_val <= 7'd8; end // division by 8
    	3'b100: begin max_val <= 7'd16; end // division by 16
    	3'b101: begin max_val <= 7'd32; end // division by 32
    	3'b110: begin max_val <= 7'd64; end // division by 64
    endcase
    
    // note that both pointers move 1 step
    // per clk cycle; however, r_pnt is 1 step ahead
    if (w_pnt == max_val) begin
    	w_pnt <= 7'd0;
    end
    else begin
    	w_pnt <= w_pnt + 7'd1;
    end
    
    if (r_pnt == max_val) begin
    	r_pnt <= 7'd0;
    end
    else begin
    	r_pnt <= r_pnt + 7'd1;
    end
end


    
endmodule
