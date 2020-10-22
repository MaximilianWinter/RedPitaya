`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2020 03:22:09 PM
// Design Name: 
// Module Name: longer_pulse_generator_01
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


module longer_pulse_generator_01 #(parameter RSZ = 14
)(
    input                 clk_i           ,
    input                 rstn_i          ,
    
        // Channel A
    //input                 trigger_a_i     ,
    input      [ 14-1: 0] dat_a_i         ,
    output     [ 14-1: 0] dat_a_o         ,
    
       // system bus
    input      [ 32-1: 0] sys_addr        ,  // bus address
    input      [ 32-1: 0] sys_wdata       ,  // bus write data
    input                 sys_wen         ,  // bus write enable
    input                 sys_ren         ,  // bus read enable
    output reg [ 32-1: 0] sys_rdata       ,  // bus read data
    output reg            sys_err         ,  // bus error indicator
    output reg            sys_ack            // bus acknowledge signal

    );
    
reg  [  14-1: 0] wave  [  0: 4096-1]; // array with 8192 entries, each 14 bit wide

integer i;
initial begin // initialize waveforms to 0
    for (i=0; i<4096; i = i + 1) begin
        wave[i]  = 14'h0;
    end
end

always @(posedge clk_i) begin
      if (sys_wen) begin
         casez (sys_addr[19:0])
		   20'h1zzzz : begin wave[sys_addr[14-1:2]]  <= sys_wdata[14-1:0]; end
		 endcase
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
	  20'h1zzzz : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave[sys_addr[14-1:2]]};  end

      default :   begin sys_ack <= sys_en;  sys_rdata <=  32'h0;                                  end
   endcase
end 

//------------------------------------------------------------------------------------------------
// waveform output
//
// simply outputs the waveform written to the register in ADC counts. This is done via a counter, meaning that a new sample is output each clock cycle (8ns). 
// can be used for testing / debugging 

reg  [  16-1: 0] counter_pgen = 16'h0;
reg  [  14-1: 0] pgen_out     = 14'h0;

always @(posedge clk_i) begin
    
              if (counter_pgen <= 16'hFFF) // count all entries in the wave vector
                begin
                  
                  if ($signed(wave[counter_pgen]) > 14'h1FFF) begin // positive saturation
                    pgen_out <= 14'h1FFF;
                  end
                  
                  else if ($signed(wave[counter_pgen]) < 14'sh2000) begin // negative saturation
                    pgen_out <= 14'h2000;
                  end
                  
                  else begin
                    pgen_out <= $signed(wave[counter_pgen]);
                  end
                  
                  
                counter_pgen <= counter_pgen + 16'h1 ;  
                end
              else begin
                  counter_pgen <= 16'h0;
              end
end


assign dat_a_o = pgen_out;



endmodule
