`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Maximilian Winter
// 
// Create Date: 29.10.2020 17:04:38
// Design Name: 
// Module Name: pulse_generator_delta_finder
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


module pulse_generator_delta_finder(
    input                   clk_i               ,
    input                   rstn_i              ,    
    input                   trigger_i           ,
    
    input       [ 14-1:0]   swf_current_val_i   ,
    input       [ 14-1:0]   dat_i               , //PD signal
    input                   state_i                       
    

    );
    

// TODO: create individual read and write pointers! 
    
/// BUFFER FOR PD SIGNAL
reg [14-1:0] pd_buf [0:16383];

reg [14-1:0] pd_pnt;
wire [14-1:0] pd_npnt;

reg pd_iteration_done = 1'b0;
reg [14-1:0] pd_delay_counter = 14'h0;
// signal buffer logic
always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        pd_pnt <= {14{1'b0}};        
        pd_iteration_done <= 1'b0;
        pd_delay_counter <= 14'h0;
    end
    
    if (trigger_i == 1'b1) begin
        if (pd_iteration_done == 1'b1) begin
            pd_pnt <= {14{1'b0}}; 
        end
        else begin
            if (pd_delay_counter < pd_delay) begin
                pd_delay_counter <= pd_delay_counter + 14'd1;
            end
            else begin
                if (pd_npnt < 14'd16383) begin
                    pd_pnt <= pd_npnt;
                end
                else if (pd_npnt == 14'd16383) begin
                    pd_iteration_done <= 1'b1;
                    pd_pnt <= {14{1'b0}};
                end
            end
        end
    end
    else begin
        pd_pnt <= {14{1'b0}};
        pd_iteration_done <= 1'b0;
        pd_delay_counter <= 14'h0;
    end
end
assign pd_npnt = pd_pnt + 14'd1;

reg [ 14-1:0] pd_val;

always @(posedge clk_i) begin
    if (state_i == 0) begin
        pd_buf[pd_pnt] <= $signed(dat_i);
    end
    else begin
        pd_val <= pd_buf[pd_pnt];
    end
end

endmodule
