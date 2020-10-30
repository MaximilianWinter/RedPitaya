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
    input       [ 14-1:0]   offset_i            ,
    input       [ 14-1:0]   dat_i               , //PD signal
    input                   state_i                       
    

    );
    

// TODO: create individual read and write pointers! 
    
/// BUFFER FOR PD SIGNAL
reg [14-1:0] pd_buf [0:16383];

reg [14-1:0] pd_pnt;
wire [14-1:0] pd_npnt;

reg pd_iteration_done = 1'b0;
// signal buffer logic
always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        pd_pnt <= {14{1'b0}};        
        pd_iteration_done <= 1'b0;
    end
    
    if (trigger_i == 1'b1) begin
        if (pd_iteration_done == 1'b1) begin
            pd_pnt <= {14{1'b0}}; 
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
    else begin
        pd_pnt <= {14{1'b0}};
        pd_iteration_done <= 1'b0;
    end
end
assign pd_npnt = pd_pnt + 14'd1;

////////////////////////
///READ POINTER LOGIC///
////////////////////////

reg [14-1:0] pd_rpnt;
wire [14-1:0] pd_nrpnt;

reg pd_reading_done = 1'b0;

reg [14-1:0] shift = 14'd0;
// signal buffer logic
always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        pd_rpnt <= {14{1'b0}};        
        pd_reading_done <= 1'b0;
    end
    
    if (trigger_i == 1'b1) begin
        if (pd_reading_done == 1'b1) begin
            pd_rpnt <= {14{1'b0}}; 
        end
        else begin
            if (pd_nrpnt < 14'd16383) begin
                pd_rpnt <= pd_nrpnt;
            end
            else if (pd_nrpnt == 14'd16383) begin
                pd_reading_done <= 1'b1;
                pd_rpnt <= {14{1'b0}};
            end
        end
    end
    else begin
        pd_rpnt <= {14{1'b0}};
        pd_reading_done <= 1'b0;
    end
end
assign pd_nrpnt = pd_rpnt + 14'd1;


reg [ 14-1:0] pd_val;

always @(posedge clk_i) begin
    if (state_i == 0) begin
        pd_buf[pd_pnt] <= $signed(dat_i);
    end
    else begin
        pd_val <= pd_buf[pd_rpnt+shift];
    end
end

///////////////////////
///ERROR CALCULATION/// TODO: need to improve...
///////////////////////
reg [15-1:0] error;
reg [32-1:0] error_sum;
reg [32-1:0] smallest_error_sum = {32{1'b1}};
reg [14-1:0] final_shift;

reg error_calc_done = 1'b0;


always @(posedge clk_i)
begin
    if (trigger_i == 1'b1) begin
        if (error_calc_done) begin
            error <= 15'h0;
        end
        else begin
            if (pd_rpnt < 14'd16383) begin
                error <= $signed(swf_current_val_i) - $signed(pd_val) + $signed(offset_i);
                error_sum <= error_sum + error;
            end
            else if (pd_rpnt == 14'd16383) begin
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
endmodule
