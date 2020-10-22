`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2020 01:04:28 PM
// Design Name: 
// Module Name: double_pulse_generator_ch
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


module double_pulse_generator_ch(

    input                   clk_i           ,
    input                   rstn_i          ,
    input       [ 14-1: 0]  dat_i           ,
    output      [ 14-1: 0]  dat_o           ,
    
    input                   trigger_i       ,
    
    input       [ 20-1: 0] wave_addr        ,
    input       [ 14-1: 0]  sp_delay_1_i    ,
    input       [ 14-1: 0]  sp_delay_2_i    ,

       // system bus
    input      [ 32-1: 0] sys_addr        ,  //!< bus address
    input      [ 32-1: 0] sys_wdata       ,  //!< bus write data
    input                 sys_wen         ,  //!< bus write enable
    input                 sys_ren         ,  //!< bus read enable
    output reg [ 32-1: 0] sys_rdata       ,  //!< bus read data
    output reg            sys_err         ,  //!< bus error indicator
    output reg            sys_ack            //!< bus acknowledge signal  
    );
    
reg  [  14-1: 0] wave   [ 0: 4096-1];
    
reg  [  15-1: 0] error        = 15'h0;
reg  [  16-1: 0] counter_err  = 16'h0;
reg  [  14-1: 0] offset       = 14'h0; 
    
//////////////////////////////
///ERROR SIGNAL CALCULATION///
//////////////////////////////

always @(posedge clk_i) begin
    if (trigger_i == 1'b1) begin
        if ((sp_delay_1_i < counter_err) && (counter_err < (16'hFFF + sp_delay_2_i))) begin
            error <= $signed(wave[($signed(counter_err) - $signed(sp_delay_1_i))]) - $signed(dat_i) + $signed(offset);
        end
        else if (counter_err == 16'hFFFE) begin
            counter_err = 16'hFFFD;
            error <= 15'h0;
        end
        else begin
            error <= 15'h0;
        end
        counter_err <= counter_err + 16'h1;
    end
    else begin
        counter_err <= 16'h0;
        error <= 15'h0;
    end
end

///////////////////////////////////
///FOR TESTING - WAVEFORM OUTPUT///
///////////////////////////////////
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
    
assign dat_o = pgen_out;
    
    
    
    
/////////////////    
/// SYSTEM BUS///
/////////////////

always @(posedge clk_i) begin
      if (sys_wen) begin
         casez (sys_addr[19:0])
		   wave_addr : begin wave[sys_addr[14-1:2]]  <= sys_wdata[14-1:0]; end
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
	  wave_addr : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave[sys_addr[14-1:2]]};  end
      default :   begin sys_ack <= sys_en;  sys_rdata <=  32'h0;                                  end
   endcase
end 
    
endmodule

