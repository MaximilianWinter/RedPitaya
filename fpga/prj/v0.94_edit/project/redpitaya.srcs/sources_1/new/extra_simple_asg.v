`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MPQ
// Engineer: Maximilian Winter
// 
// Create Date: 10/19/2020 12:33:04 PM
// Design Name: 
// Module Name: extra_simple_asg
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


module extra_simple_asg(
    output  [14-1:0]    dac_a_o ,
    
    input               clk_i   ,
    input               rstn_i  ,
    
      // System bus
    input      [ 32-1: 0] sys_addr  ,  // bus address
    input      [ 32-1: 0] sys_wdata ,  // bus write data
    input                 sys_wen   ,  // bus write enable
    input                 sys_ren   ,  // bus read enable
    output reg [ 32-1: 0] sys_rdata ,  // bus read data
    output reg            sys_err   ,  // bus error indicator
    output reg            sys_ack      // bus acknowledge signal

    );
    
    
reg               buf_a_we     ; //Buffer A, write enable Bool - Max
reg   [  14-1: 0] buf_a_addr   ; //Buffer A, Address, 14 bits - Max
wire  [  14-1: 0] buf_a_rdata  ; //Buffer A, read data, 14 bits - Max
wire  [  14-1: 0] buf_a_rpnt   ; //Buffer A, current read pointer, 14 bits - Max
reg   [  32-1: 0] buf_a_rpnt_rd; //Buffer A, ???, 32 bits; NOT given to asg_ch; need to understand its role better -Max
    

always @(posedge clk_i)
begin
    buf_a_we <= sys_wen && (sys_addr[19:16] == 'h1);
    buf_a_addr <= sys_addr[15:2];
end
    

reg [3-1: 0] ren_dly;
reg          ack_dly;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        ren_dly <= 3'h0;
        ack_dly <= 1'b0;
    end
    else begin
        ren_dly <= {ren_dly[1:0], sys_ren};
        ack_dly <= ren_dly[2] || sys_wen;
        
        if (sys_ren) begin
            buf_a_rpnt_rd <= {{16{1'b0}}, buf_a_rpnt, 2'h0};
        end
    end
end
    
wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        sys_err <= 1'b0;
        sys_ack <= 1'b0;
    end
    else begin
        sys_err <= 1'b0;
        
        casez (sys_addr[19:0])
            20'h1zzzz : begin sys_ack <= ack_dly;   sys_rdata <= {{18{1'b0}}, buf_a_rdata}; end
            default : begin sys_ack <= sys_en;  sys_rdata <= 32'h0; end
        endcase
        
    end
end

extra_simple_asg_ch (
    .dac_o  (dac_a_o),
    .clk_i  (clk_i),
    .rstn_i  (rstn_i),
    
    .buf_we_i       (buf_a_we),
    .buf_addr_i     (buf_a_addr),
    .buf_wdata_i    (sys_wdata[14-1:0]),
    .buf_rdata_o    (buf_a_rdata),
    .buf_rpnt_o     (buf_a_rpnt)
);
    
    
endmodule
