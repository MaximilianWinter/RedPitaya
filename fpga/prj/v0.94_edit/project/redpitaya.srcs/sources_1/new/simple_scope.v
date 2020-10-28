`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2020 10:35:09
// Design Name: 
// Module Name: simple_scope
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


module simple_scope(
    input   [14-1:0]    adc_a_i ,
    
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
    
reg   [  14-1: 0] adc_a_buf [0:16383] ;
reg   [  14-1: 0] adc_a_rd      ;
reg   [ 14-1: 0] adc_wp        ;
reg   [ 14-1: 0] adc_wp_cur    ;
reg   [ 14-1: 0] adc_raddr     ;
reg   [ 14-1: 0] adc_a_raddr   ;

reg   [   4-1: 0] adc_rval      ;
wire              adc_rd_dv     ;
// WRITE

reg trigger = 1'b0;

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0 || trigger == 1'b0) begin
        adc_wp      <= {14{1'b0}};
    end
    else begin
        adc_wp <= adc_wp + 1;
    end

end

always @(posedge clk_i)
begin
    adc_a_buf[adc_wp] <= $signed(adc_a_i);
end

// READ

always @(posedge clk_i) begin
   if (rstn_i == 1'b0)
      adc_rval <= 4'h0 ;
   else
      adc_rval <= {adc_rval[2:0], (sys_ren || sys_wen)};
end
assign adc_rd_dv = adc_rval[3];

always @(posedge clk_i) begin
   adc_raddr   <= sys_addr[15:2] ; // address synchronous to clock
   adc_a_raddr <= adc_raddr     ; // double register 
   adc_a_rd    <= $signed(adc_a_buf[adc_a_raddr]) ;
   //adc_a_rd    <= $signed(adc_a_buf[sys_addr[15:2]]) ;
end

// System Bus
always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        trigger <= 1'b0;
    end
    else begin
        if (sys_wen) begin
            if (sys_addr[19:0]==20'h00)   trigger   <= sys_wdata[     0] ;
        end
    end
end



wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
   sys_err <= 1'b0 ;
   sys_ack <= 1'b0 ;
end else begin
   sys_err <= 1'b0 ;

   casez (sys_addr[19:0])
     20'h00000 : begin sys_ack <= sys_en;          sys_rdata <= {{32-1{1'b0}}, trigger}; end



     20'h1???? : begin sys_ack <= adc_rd_dv;       sys_rdata <= {16'h0, 2'h0,adc_a_rd}              ; end

       default : begin sys_ack <= sys_en;          sys_rdata <=  32'h0                              ; end
   endcase
end

endmodule
