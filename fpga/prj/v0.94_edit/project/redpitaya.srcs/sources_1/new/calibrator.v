`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 13.11.2020 17:11:34
// Design Name: 
// Module Name: calibrator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: should work, Nov 13, 18:08
// 
//////////////////////////////////////////////////////////////////////////////////


module calibrator(
	input 			clk_i,
	input			rstn_i,
	
	input			trigger_i,
	
	output	[14-1:0]	ctrl_sig_o,
	input	[14-1:0]	pd_i,
	
	output	reg [14-1:0]	buf_rdata_o,
	input	[14-1:0]	buf_addr_i	

);

reg [14-1:0] response_curve [0:8192-1];

reg [14-1:0] out = 14'h0;
reg response_curve_done = 1'b0;
reg [2-1:0] state = 2'b00;
reg [14-1:0] counter = 14'h0;

reg [24-1:0] sum = 24'h0;
reg [14-1:0] avg = 14'h0;


always @(posedge clk_i)
begin
	if (trigger_i == 1'b1) begin
		if (response_curve_done) begin
			out <= 14'h0;
			state <= 2'b00;
			sum <= 24'h0;
			avg <= 14'h0;
			counter <= 14'h0;
		end
		else begin
			case (state)
				2'b00:	begin
						if (counter == 250) begin
							state <= 2'b01;
							counter <= 14'h0;
						end
						else begin
							counter <= counter + 1;
						end
					end
				
				2'b01:	begin
						if (counter < 1024) begin
							sum <= sum + pd_i;
							counter <= counter + 1;
						end
						else begin
							state <= 2'b10;
							counter <= 14'h0;
							avg <= sum[24-1:10];
							sum <= 24'h0;
						end
					end
				
				2'b10:	begin
						response_curve[out] <= avg;
						state <= 2'b00;
						
						if (out == 14'd8191) begin
							response_curve_done <= 1'b1;
						end
						else begin
							out <= out + 1;
						end
					end
			
			endcase
			
		end
	end
	else begin
		out <= 14'h0;
		response_curve_done <= 1'b0;
		state <= 2'b00;
		counter <= 14'h0;
		sum <= 24'h0;
		avg <= 14'h0;
	end
end

assign ctrl_sig_o = out;


always @(posedge clk_i)
begin
	buf_rdata_o <= response_curve[buf_addr_i];
end

endmodule
