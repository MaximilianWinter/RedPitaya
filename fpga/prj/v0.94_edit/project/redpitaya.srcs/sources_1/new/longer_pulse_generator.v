`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2020 03:22:09 PM
// Design Name: 
// Module Name: longer_pulse_generator
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


module longer_pulse_generator #(parameter RSZ = 14
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
    
reg  [  14-1: 0] wave  [  0: 4096-1]; // array with 4096 entries, each 14 bit wide
reg  [  14-1: 0] wave2 [  0: 4096-1];
integer i;
initial begin // initialize waveforms to 0
    for (i=0; i<4096; i = i + 1) begin
        wave[i]  = 14'h0;
        wave2[i] = 14'h0;
    end
end

always @(posedge clk_i) begin
      if (sys_wen) begin
         casez (sys_addr[19:0])
		   20'b100zzzzzzzzzzzz00 : begin wave[sys_addr[14-1:2]]  <= sys_wdata[14-1:0]; end
		   20'b1000zzzzzzzzzzzz00 : begin wave2[sys_addr[14-1:2]] <= sys_wdata[14-1:0]; end
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
	  20'b100zzzzzzzzzzzz00 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave[sys_addr[14-1:2]]};  end
	  20'b1000zzzzzzzzzzzz00 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave2[sys_addr[14-1:2]]}; end

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
reg              wave_counter = 1'b0;

always @(posedge clk_i) begin
        case(wave_counter)
            1'b0: begin
    
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
                  wave_counter <= 1'b1;
              end
            end
            
            1'b1: begin
                if (counter_pgen <= 16'hFFF) // count all entries in the wave vector
                    begin
                              
                    if ($signed(wave2[counter_pgen]) > 14'h1FFF) begin // positive saturation
                        pgen_out <= 14'h1FFF;
                    end
                              
                    else if ($signed(wave2[counter_pgen]) < 14'sh2000) begin // negative saturation
                        pgen_out <= 14'h2000;
                    end
                              
                    else begin
                        pgen_out <= $signed(wave2[counter_pgen]);
                    end
                              
                              
                counter_pgen <= counter_pgen + 16'h1 ;  
                end
                else begin
                    counter_pgen <= 16'h0;
                    wave_counter <= 1'b0;
                end          
            end
            
            default: wave_counter <= 1'b0;
            
        endcase
end


assign dat_a_o = pgen_out;



endmodule
