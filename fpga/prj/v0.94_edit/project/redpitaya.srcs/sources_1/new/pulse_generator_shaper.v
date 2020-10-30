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
    input           clk_i       ,
    input           rstn_i      ,
    
    input           trigger_i   ,
    input [14-1:0]  swf_current_val_i,
    input [14-1:0]  offset_i,
    input [14-1:0]  pd_i        ,
    input [14-1:0]  shift_i     ,
    input [14-1:0]  k_1_i       ,
    input [14-1:0]  k_2_i

    );

reg [14-1:0] previous_pg_out [0:16383];
reg [14-1:0] previous_pd_in [0:16383];

///////////////////
///POINTER LOGIC///
///////////////////

reg [14-1:0]    pt;
wire [14-1:0]    npt;
reg             iteration_done = 1'b0;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        pt <= {14{1'b0}};
        iteration_done <= 1'b0;
    end
    
    if (trigger_i == 1'b1) begin
        if (iteration_done == 1'b1) begin
            pt <= {14{1'b0}};
        end
        else begin
            if (npt < 14'd16383) begin
                pt <= npt;
            end
            else if (npt == 14'd16383) begin
                iteration_done <= 1'b1;
                pt <= {14{1'b0}};
            end
        end 
    end
    else begin
        iteration_done <= 1'b0;
        pt <= {14{1'b0}};
    end
end
assign npt = pt + 14'd1;

////////////////////////////
///READ AND WRITE SIGNALS///
////////////////////////////

reg [14-1:0] current_pg_out_val;


reg [14-1:0] previous_pg_out_val;
reg [14-1:0] previous_pd_in_val;

always @(posedge clk_i)
begin
    previous_pg_out_val <= previous_pg_out[pt];
    previous_pd_in_val <= previous_pd_in[pt+shift_i];
end

always @(posedge clk_i)
begin
    previous_pg_out[pt] <= current_pg_out_val;
    previous_pd_in[pt] <= pd_i;
end

///////////////////////
///ERROR CALCULATION///
///////////////////////

reg [15-1:0] error;
reg error_calc_done = 1'b0;


always @(posedge clk_i)
begin
    if (trigger_i == 1'b1) begin
        if (error_calc_done) begin
            error <= 15'h0;
        end
        else begin
            if (pt < 14'd16383) begin
                error <= $signed(swf_current_val_i) - $signed(previous_pd_in_val) + $signed(offset_i);
            end
            else if (pt == 14'd16383) begin
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

//////////////////////
///P CONTROL OUTPUT///
//////////////////////
always @(posedge clk_i)
begin
    current_pg_out_val <= previous_pg_out_val + k_1_i*error + k_2_i*error*error;
end
assign pg_o = current_pg_out_val;

    
endmodule
