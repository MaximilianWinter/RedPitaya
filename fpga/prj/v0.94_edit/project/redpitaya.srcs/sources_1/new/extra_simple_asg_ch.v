`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MPQ
// Engineer: Maximilian Winter
// 
// Create Date: 10/19/2020 12:57:28 PM
// Design Name: 
// Module Name: extra_simple_asg_ch
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


module extra_simple_asg_ch(
    output reg  [14-1:0]    dac_o       ,
    input                   clk_i       ,
    input                   rstn_i      ,
    
    input                   buf_we_i    ,
    input       [14-1: 0]   buf_addr_i  ,
    input       [14-1: 0]   buf_wdata_i ,
    output reg  [14-1: 0]   buf_rdata_o ,
    output reg  [14-1: 0]   buf_rpnt_o
    );
    

reg [14-1: 0]   dac_buf [0:16384]   ;
reg [14-1: 0]   dac_rd      ;
reg [14-1: 0]   dac_rdat    ;

/*reg*/ wire [14-1: 0]   dac_rp      ;
reg [30-1: 0]   dac_pnt     ;

wire [31-1: 0]  dac_npnt    ;

always @(posedge clk_i)
begin
    //buf_rpnt_o <= dac_pnt[29:16];
    //dac_rp <= dac_pnt[29:16];
    //dac_rd <= dac_buf[dac_rp];
    //dac_rdat <= dac_rd;
    //dac_o <= dac_rdat;
    dac_o <= dac_buf[dac_rp];
end    

always @(posedge clk_i)
begin
    if (buf_we_i) dac_buf[buf_addr_i] <= buf_wdata_i[14-1:0];
end

always @(posedge clk_i)
begin
    buf_rdata_o <= dac_buf[buf_addr_i];
end

always @(posedge clk_i)
begin
    if (rstn_i == 1'b0) begin
        dac_pnt <= {30{1'b0}};
    end
    else begin
        dac_pnt <= dac_npnt[29:0];
    end
end

assign dac_npnt = dac_pnt + {14'd1,{16{1'b0}}};


assign dac_rp = dac_pnt[29:16];
    
    
    
    
    
    
    
    
endmodule
