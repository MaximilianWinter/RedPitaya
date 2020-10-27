`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Max-Planck-Institute of Quantum Optics
// Engineer: Maximilian Winter
// 
// Create Date: 10/19/2020 06:03:31 PM
// Design Name: 
// Module Name: pulse_generator_top
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


module pulse_generator_top(
    
    // Channel A
    input   [14-1:0]    dac_a_i,
    output  [14-1:0]    dac_a_o ,
    input               trigger_a_i,
    // Channel B
    input   [14-1:0]    dac_b_i,
    output  [14-1:0]    dac_b_o, 
    input               trigger_b_i,  
    
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

reg               buf_b_we     ; //Buffer A, write enable Bool - Max
reg   [  14-1: 0] buf_b_addr   ; //Buffer A, Address, 14 bits - Max
wire  [  14-1: 0] buf_b_rdata  ; //Buffer A, read data, 14 bits - Max
wire  [  14-1: 0] buf_b_rpnt   ; //Buffer A, current read pointer, 14 bits - Max
reg   [  32-1: 0] buf_b_rpnt_rd; //Buffer A, ???, 32 bits; NOT given to asg_ch; need to understand its role better -Max  


reg [14-1:0] amp_a;
reg [14-1:0] offset_a;
reg          offset_mode_a;
reg [14-1:0] wf_delay_a;
reg [14-1:0] swf_delay_a;
reg [14-1:0] set_ki_a;
reg          int_rst_a = 1'b0;
reg [3-1:0]  ch_mode_a = 3'b000;
reg [30-1:0] step_a = {14'd1,{16{1'b0}}};

reg [14-1:0] amp_b;
reg [14-1:0] offset_b;
reg          offset_mode_b;
reg [14-1:0] wf_delay_b;
reg [14-1:0] swf_delay_b;
reg [14-1:0] set_ki_b;
reg          int_rst_b = 1'b0;
reg [3-1:0]  ch_mode_b = 3'b000;
reg [30-1:0] step_b = {14'd1,{16{1'b0}}};



always @(posedge clk_i)
begin
    buf_a_we <= sys_wen && (sys_addr[19:16] == 'h1);
    buf_a_addr <= sys_addr[15:2];
    
    buf_b_we <= sys_wen && (sys_addr[19:16] == 'h2);
    buf_b_addr <= sys_addr[15:2];
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
            buf_b_rpnt_rd <= {{16{1'b0}}, buf_b_rpnt, 2'h0};
        end
        
        if (sys_wen) begin
            case(sys_addr[19:0])
                20'h0 : begin amp_a         <= sys_wdata[14-1:0]; end
                20'h4 : begin offset_a      <= sys_wdata[14-1:0]; end
                20'h8 : begin offset_mode_a <= sys_wdata[0]; end
                20'hC : begin wf_delay_a       <= sys_wdata[14-1:0]; end
		        20'h10 : begin swf_delay_a       <= sys_wdata[14-1:0]; end
                20'h14 : begin set_ki_a      <= sys_wdata[14-1:0]; end
                20'h18 : begin int_rst_a     <= sys_wdata[0]; end
                20'h20 : begin ch_mode_a    <= sys_wdata[3-1:0]; end
                20'h24 : begin step_a       <= sys_wdata[30-1:0]; end
                
                20'h30 : begin amp_b         <= sys_wdata[14-1:0]; end
                20'h34 : begin offset_b      <= sys_wdata[14-1:0]; end
                20'h38 : begin offset_mode_b <= sys_wdata[0]; end
                20'h3C: begin wf_delay_b       <= sys_wdata[14-1:0]; end
		        20'h40: begin swf_delay_b       <= sys_wdata[14-1:0]; end
                20'h44 : begin set_ki_b      <= sys_wdata[14-1:0]; end
                20'h48 : begin int_rst_b     <= sys_wdata[0]; end
                20'h4C : begin ch_mode_b    <= sys_wdata[3-1:0]; end
                20'h50 : begin step_b       <= sys_wdata[30-1:0]; end
            endcase
        
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
            20'h0 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, amp_a}; end
            20'h4 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, offset_a}; end
            20'h8 : begin sys_ack <= sys_en;        sys_rdata <= {{32-1{1'b0}}, offset_mode_a}; end
            20'hC : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, wf_delay_a}; end
            20'h10 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, swf_delay_a}; end
            20'h14 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, set_ki_a}; end
            20'h18 : begin sys_ack <= sys_en;        sys_rdata <= {{32-1{1'b0}}, int_rst_a}; end
            20'h1C : begin sys_ack <= sys_en;        sys_rdata <= {{32-3{1'b0}}, ch_mode_a}; end
            20'h20 : begin sys_ack <= sys_en;        sys_rdata <= {{32-30{1'b0}}, step_a}; end
            
            20'h30 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, amp_b}; end
            20'h34 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, offset_b}; end
            20'h38 : begin sys_ack <= sys_en;        sys_rdata <= {{32-1{1'b0}}, offset_mode_b}; end
            20'h3C : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, wf_delay_b}; end
            20'h40 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, swf_delay_b}; end
            20'h44 : begin sys_ack <= sys_en;        sys_rdata <= {{32-14{1'b0}}, set_ki_b}; end
            20'h48 : begin sys_ack <= sys_en;        sys_rdata <= {{32-1{1'b0}}, int_rst_b}; end
            20'h4C : begin sys_ack <= sys_en;        sys_rdata <= {{32-3{1'b0}}, ch_mode_b}; end
            20'h50 : begin sys_ack <= sys_en;        sys_rdata <= {{32-30{1'b0}}, step_b}; end
        
            20'h1zzzz : begin sys_ack <= ack_dly;   sys_rdata <= {{18{1'b0}}, buf_a_rdata}; end
            
            20'h2zzzz : begin sys_ack <= ack_dly;   sys_rdata <= {{18{1'b0}}, buf_b_rdata}; end
            
            default : begin sys_ack <= sys_en;  sys_rdata <= 32'h0; end
        endcase
        
    end
end


pulse_generator_ch pg_ch_a(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .trigger_i(trigger_a_i),
    .dat_i(dac_a_i),
    .dat_o(dac_a_o),
    
    .buf_we_i       (buf_a_we),
    .buf_addr_i     (buf_a_addr),
    .buf_wdata_i    (sys_wdata[14-1:0]),
    .buf_rdata_o    (buf_a_rdata),
    .buf_rpnt_o     (buf_a_rpnt),
    
    //all set via RAM:
    .amp_i          (amp_a),
    .offset_i       (offset_a),
    .offset_mode_i  (offset_mode_a),
    .wf_delay_i     (wf_delay_a),
    .swf_delay_i    (swf_delay_a),
    .set_ki_i       (set_ki_a),
    .int_rst_i      (int_rst_a),
    .ch_mode_i      (ch_mode_a),
    .step_i         (step_a)
);

pulse_generator_ch pg_ch_b(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .trigger_i(trigger_b_i),
    .dat_i(dac_b_i),
    .dat_o(dac_b_o),
    
    .buf_we_i       (buf_b_we),
    .buf_addr_i     (buf_b_addr),
    .buf_wdata_i    (sys_wdata[14-1:0]),
    .buf_rdata_o    (buf_b_rdata),
    .buf_rpnt_o     (buf_b_rpnt),
    
    //all set via RAM:
    .amp_i          (amp_b),
    .offset_i       (offset_b),
    .offset_mode_i  (offset_mode_b),
    .wf_delay_i     (wf_delay_b),
    .swf_delay_i    (swf_delay_b),
    .set_ki_i       (set_ki_b),
    .int_rst_i      (int_rst_b),
    .ch_mode_i      (ch_mode_b),
    .step_i         (step_b)
);



endmodule
