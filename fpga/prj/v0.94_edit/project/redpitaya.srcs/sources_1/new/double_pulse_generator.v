`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MPQ
// Engineer: Maximilian Winter
// 
// Create Date: 10/15/2020 11:40:54 AM
// Design Name: 
// Module Name: double_pulse_generator
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


module double_pulse_generator(
    input                 clk_i           ,
    input                 rstn_i          ,
    
        // Channel A
    input                 trigger_a_i     ,
    input      [ 14-1: 0] dat_a_i         ,
    output     [ 14-1: 0] dat_a_o         ,
    
        // Channel B
    input                 trigger_b_i     ,
    input      [ 14-1: 0] dat_b_i         ,
    output     [ 14-1: 0] dat_b_o         ,
    
       // system bus
    input      [ 32-1: 0] sys_addr        ,  //!< bus address
    input      [ 32-1: 0] sys_wdata       ,  //!< bus write data
    input                 sys_wen         ,  //!< bus write enable
    input                 sys_ren         ,  //!< bus read enable
    output reg [ 32-1: 0] sys_rdata       ,  //!< bus read data
    output reg            sys_err         ,  //!< bus error indicator
    output reg            sys_ack            //!< bus acknowledge signal
    );

    
//////////////////////////////
/// REGISTERS FOR WAVEFORMS///
//////////////////////////////
reg  [  14-1: 0] wave_a  [  0: 4096-1];
reg  [  14-1: 0] wave2_a [  0: 4096-1]; // array with 4096 entries, each 14 bit wide
reg  [  14-1: 0] wave_b  [  0: 4096-1];
reg  [  14-1: 0] wave2_b [  0: 4096-1];
integer i;
initial begin // initialize waveforms to 0
    for (i=0; i<4096; i = i + 1) begin
        wave_a[i]  = 14'h0;
		wave_b[i] = 14'h0;
    end
end

/*assign sp_delay_a_1_i = parameters_a[0];
assign set_ki_a_i = parameters_a[1];
assign int_rst_a_i = parameters_a[2];
*/

////////////////////////////////////////
///ERROR SIGNAL CALCULATION CHANNEL A///
////////////////////////////////////////

reg  [  15-1: 0] error_a        = 15'h0;
reg  [  14-1: 0] sp_delay_a_1_i = 14'h0; // set via RAM 
reg  [  14-1: 0] sp_delay_a_2_i = 14'h0; // set via RAM
reg  [  16-1: 0] counter_err_a  = 16'h0;
reg  [  14-1: 0] offset_a       = 14'h0; 

always @(posedge clk_i) begin
    if (trigger_a_i == 1'b1) begin
        if ((sp_delay_a_1_i < counter_err_a) && (counter_err_a < (16'hFFF + sp_delay_a_2_i))) begin
            error_a <= $signed(wave_a[($signed(counter_err_a) - $signed(sp_delay_a_1_i))]) - $signed(dat_a_i) + $signed(offset_a);
        end
        else if (counter_err_a == 16'hFFFE) begin
            counter_err_a = 16'hFFFD;
            error_a <= 15'h0;
        end
        else begin
            error_a <= 15'h0;
        end
        counter_err_a <= counter_err_a + 16'h1;
    end
    else begin
        counter_err_a <= 16'h0;
        error_a <= 15'h0;
    end
end
            
///////////////////////////////////
/// OFFSET CALCULATION CHANNEL A///
///////////////////////////////////
reg  [   8-1: 0] counter_off_a = 8'h1; 
reg  [  21-1: 0] offset_reg_a  = 21'h0; // Bit 21 (MSB) reserved for potential overflow during signed addition/subtraction
reg  [  14-1: 0] offset_meas_a = 14'h0;
    
always @(posedge clk_i) begin  
if (trigger_a_i == 1'b0) //TTL signal low (<3V)
  begin
    if ($signed(counter_off_a) <= 8'sh40) begin // 64 clock cycles to determine offset
      if (offset_reg_a[21-1:21-2] == 2'b01) //max positive
        offset_reg_a <= 21'h7FFFF;
      else if (offset_reg_a == 2'b10) //max negative
        offset_reg_a <= 21'h80000;
      else
        offset_reg_a <= $signed(offset_reg_a[20:0]) + $signed(dat_a_i);  
    end
    else begin
      counter_off_a = 8'h0;
      offset_meas_a = offset_reg_a[20-1:6]; //divide by 64 -> bit shift by 6          
      offset_reg_a = 21'h0;
    end
      counter_off_a <= counter_off_a + 8'h1 ;
  end  
end 



////////////////////////////////
///OFFSET SELECTION CHANNEL A///
////////////////////////////////
reg              off_mode_a_i   = 1'b0;  // set via RAM
reg  [  14-1: 0] offset_err_a_i = 14'h0; // set via RAM

always@(posedge clk_i) begin
  if(off_mode_a_i)
    offset_a <= offset_meas_a;
  else
    offset_a <= offset_err_a_i;
end





//////////////////////////
///INTEGRATOR CHANNEL A///
//////////////////////////

reg  [    29-1: 0] ki_mult_a;
wire [    33-1: 0] int_sum_a;
reg  [    32-1: 0] int_reg_a;
wire [    14-1: 0] int_out_a;
reg  [    14-1: 0] set_ki_a_i; // set via RAM
reg                int_rst_a_i = 1'b0; // set via RAM

always @(posedge clk_i) begin
      ki_mult_a <= $signed(error_a) * $signed(set_ki_a_i) ;

      if (int_rst_a_i) begin
         int_reg_a <= 32'h0; // integrator reset
         int_reg_a <= 32'h0; // integrator reset
	  end
      else if (int_sum_a[33-1:33-2] == 2'b01) begin// positive saturation
         int_reg_a <= 32'h7FFFFFFF; // max positive
	  end
      else if (int_sum_a[33-1:33-2] == 2'b10) begin// negative saturation
         int_reg_a <= 32'h80000000; // max negative
	  end
      else begin
         int_reg_a <= int_sum_a[32-1:0]; // use sum as it is
	  end
end

assign int_sum_a = $signed(ki_mult_a) + $signed(int_reg_a) ;
assign int_out_a = int_reg_a[32-1:18] ;

////////////////////////////////////
///INTEGRATOR AVERAGING CHANNEL A///
////////////////////////////////////
reg  [   8-1: 0] counter_int_a  = 8'h1; 
reg  [  21-1: 0] int_avg_reg_a  = 21'h0; // Bit 21 (MSB) reserved for potential overflow during signed addition/subtraction
reg  [  14-1: 0] int_avg_a      = 14'h0;
    
always @(posedge clk_i) begin  
  if ($signed(counter_int_a) <= 8'sh40) begin // 64 clock cycles to determine average
    if (int_avg_reg_a[21-1:21-2] == 2'b01) //max positive
      int_avg_reg_a <= 21'h7FFFF;
    else if (int_avg_reg_a == 2'b10) //max negative
      int_avg_reg_a <= 21'h80000;
    else
      int_avg_reg_a <= $signed(int_avg_reg_a[20:0]) + $signed(int_out_a);  
  end
  else begin
    counter_int_a = 8'h0;
    int_avg_a = int_avg_reg_a[20-1:6]; //divide by 64 -> bit shift by 6          
    int_avg_reg_a = 21'h0;
  end
  counter_int_a <= counter_int_a + 8'h1 ;  
end 

/////////////////////////////////
///CONTROLLER OUTPUT CHANNEL A///
/////////////////////////////////
reg  [  14-1: 0] pid_out_a     = 14'h0;
reg  [  16-1: 0] counter_pid_a = 16'h0;
reg  [  29-1: 0] pid_reg_a     = 29'h0; 

always @(posedge clk_i) begin
  if (trigger_a_i == 1'b1) // TTL signal high (>3V)
    begin
	  if (counter_pid_a < 16'hFFF) begin // count all entries in the wave vector
	        pid_reg_a <= $signed(wave2_a[counter_pid_a]) * $signed(int_out_a);
	  end
	  else if (counter_pid_a == 16'hFFFE) begin
		  counter_pid_a = 16'hFFFD;  // keep counter at maximum value
	      pid_reg_a <= 29'h0;
      end
	  else begin
	      pid_reg_a <= 29'h0;
	  end
	  counter_pid_a <= counter_pid_a + 16'h1 ;
    end  
  else 
    begin 
      counter_pid_a <= 16'h0;
      pid_reg_a <= 29'h0;
    end  
end 
	



////////////////////////////////////////
///ERROR SIGNAL CALCULATION CHANNEL B///
////////////////////////////////////////

reg  [  15-1: 0] error_b        = 15'h0;
reg  [  14-1: 0] sp_delay_b_1_i = 14'h0; // set via RAM 
reg  [  14-1: 0] sp_delay_b_2_i = 14'h0; // set via RAM
reg  [  16-1: 0] counter_err_b  = 16'h0;
reg  [  14-1: 0] offset_b       = 14'h0; 

always @(posedge clk_i) begin
    if (trigger_b_i == 1'b1) begin
        if ((sp_delay_b_1_i < counter_err_b) && (counter_err_b < (16'hFFF + sp_delay_b_2_i))) begin
            error_b <= $signed(wave_b[($signed(counter_err_b) - $signed(sp_delay_b_1_i))]) - $signed(dat_b_i) + $signed(offset_b);
        end
        else if (counter_err_b == 16'hFFFE) begin
            counter_err_b = 16'hFFFD;
            error_b <= 15'h0;
        end
        else begin
            error_b <= 15'h0;
        end
        counter_err_b <= counter_err_b + 16'h1;
    end
    else begin
        counter_err_b <= 16'h0;
        error_b <= 15'h0;
    end
end

///////////////////////////////////
/// OFFSET CALCULATION CHANNEL B///
///////////////////////////////////
reg  [   8-1: 0] counter_off_b = 8'h1; 
reg  [  21-1: 0] offset_reg_b  = 21'h0; // Bit 21 (MSB) reserved for potential overflow during signed addition/subtraction
reg  [  14-1: 0] offset_meas_b = 14'h0;
    
always @(posedge clk_i) begin  
if (trigger_b_i == 1'b0) //TTL signal low (<3V)
  begin
    if ($signed(counter_off_b) <= 8'sh40) begin // 64 clock cycles to determine offset
      if (offset_reg_b[21-1:21-2] == 2'b01) //max positive
        offset_reg_b <= 21'h7FFFF;
      else if (offset_reg_b == 2'b10) //max negative
        offset_reg_b <= 21'h80000;
      else
        offset_reg_b <= $signed(offset_reg_b[20:0]) + $signed(dat_b_i);  
    end
    else begin
      counter_off_b = 8'h0;
      offset_meas_b = offset_reg_b[20-1:6]; //divide by 64 -> bit shift by 6          
      offset_reg_b = 21'h0;
    end
      counter_off_b <= counter_off_b + 8'h1 ;
  end  
end 

////////////////////////////////
///OFFSET SELECTION CHANNEL B///
////////////////////////////////
reg              off_mode_b_i   = 1'b0;  // set via RAM
reg  [  14-1: 0] offset_err_b_i = 14'h0; // set via RAM

always@(posedge clk_i) begin
  if(off_mode_b_i)
    offset_b <= offset_meas_b;
  else
    offset_b <= offset_err_b_i;
end


//////////////////////////
///INTEGRATOR CHANNEL B///
//////////////////////////

reg  [    29-1: 0] ki_mult_b;
wire [    33-1: 0] int_sum_b;
reg  [    32-1: 0] int_reg_b;
wire [    14-1: 0] int_out_b;
reg  [    14-1: 0] set_ki_b_i; // set via RAM
reg                int_rst_b_i = 1'b0; // set via RAM

always @(posedge clk_i) begin
      ki_mult_b <= $signed(error_b) * $signed(set_ki_b_i) ;

      if (int_rst_b_i) begin
         int_reg_b <= 32'h0; // integrator reset
         int_reg_b <= 32'h0; // integrator reset
	  end
      else if (int_sum_b[33-1:33-2] == 2'b01) begin// positive saturation
         int_reg_b <= 32'h7FFFFFFF; // max positive
	  end
      else if (int_sum_b[33-1:33-2] == 2'b10) begin// negative saturation
         int_reg_b <= 32'h80000000; // max negative
	  end
      else begin
         int_reg_b <= int_sum_b[32-1:0]; // use sum as it is
	  end
end

assign int_sum_b = $signed(ki_mult_b) + $signed(int_reg_b) ;
assign int_out_b = int_reg_b[32-1:18] ;

////////////////////////////////////
///INTEGRATOR AVERAGING CHANNEL A///
////////////////////////////////////
reg  [   8-1: 0] counter_int_b  = 8'h1; 
reg  [  21-1: 0] int_avg_reg_b  = 21'h0; // Bit 21 (MSB) reserved for potential overflow during signed addition/subtraction
reg  [  14-1: 0] int_avg_b      = 14'h0;
    
always @(posedge clk_i) begin  
  if ($signed(counter_int_b) <= 8'sh40) begin // 64 clock cycles to determine average
    if (int_avg_reg_b[21-1:21-2] == 2'b01) //max positive
      int_avg_reg_b <= 21'h7FFFF;
    else if (int_avg_reg_b == 2'b10) //max negative
      int_avg_reg_b <= 21'h80000;
    else
      int_avg_reg_b <= $signed(int_avg_reg_b[20:0]) + $signed(int_out_b);  
  end
  else begin
    counter_int_b = 8'h0;
    int_avg_b = int_avg_reg_b[20-1:6]; //divide by 64 -> bit shift by 6          
    int_avg_reg_b = 21'h0;
  end
  counter_int_b <= counter_int_b + 8'h1 ;  
end 

/////////////////////////////////
///CONTROLLER OUTPUT CHANNEL A///
/////////////////////////////////
reg  [  14-1: 0] pid_out_b     = 14'h0;
reg  [  16-1: 0] counter_pid_b = 16'h0;
reg  [  29-1: 0] pid_reg_b     = 29'h0; 

always @(posedge clk_i) begin
  if (trigger_b_i == 1'b1) // TTL signal high (>3V)
    begin
	  if (counter_pid_b < 16'hFFF) begin // count all entries in the wave vector
	        pid_reg_b <= $signed(wave2_b[counter_pid_b]) * $signed(int_out_b);
	  end
	  else if (counter_pid_b == 16'hFFFE) begin
		  counter_pid_b = 16'hFFFD;  // keep counter at maximum value
	      pid_reg_b <= 29'h0;
      end
	  else begin
	      pid_reg_b <= 29'h0;
	  end
	  counter_pid_b <= counter_pid_b + 16'h1 ;
    end  
  else 
    begin 
      counter_pid_b <= 16'h0;
      pid_reg_b <= 29'h0;
    end  
end 






///////////////////////////////////
///FOR TESTING - WAVEFORM OUTPUT///
///////////////////////////////////
reg  [  16-1: 0] counter_pgen = 16'h0;
reg  [  14-1: 0] pgen_a_out     = 14'h0;
reg  [  14-1: 0] pgen_b_out     = 14'h0;

always @(posedge clk_i) begin
    
              if (counter_pgen <= 16'hFFF) // count all entries in the wave vector
                begin
                  
                  if ($signed(wave_a[counter_pgen]) > 14'h1FFF) begin // positive saturation
                    pgen_a_out <= 14'h1FFF;
                  end
                  
                  else if ($signed(wave_a[counter_pgen]) < 14'sh2000) begin // negative saturation
                    pgen_a_out <= 14'h2000;
                  end
                  
                  else begin
                    pgen_a_out <= $signed(wave_a[counter_pgen]);
                  end
                  
                  
                  
                  if ($signed(wave_b[counter_pgen]) > 14'h1FFF) begin // positive saturation
                    pgen_b_out <= 14'h1FFF;
                  end
                                    
                  else if ($signed(wave_b[counter_pgen]) < 14'sh2000) begin // negative saturation
                    pgen_b_out <= 14'h2000;
                  end
                                    
                  else begin
                    pgen_b_out <= $signed(wave_b[counter_pgen]);
                  end                  
                  
                  
                                                      
                counter_pgen <= counter_pgen + 16'h1 ;  
                end
              else begin
                  counter_pgen <= 16'h0;
              end
end

////////////////////
///CHANNEL A MODE///
////////////////////

reg ch_a_mode_i = 1'b1;
reg [   14-1: 0] gen_out_a;

always @(posedge clk_i) begin
    casez (ch_a_mode_i) // used to be ch_a_mode_i
        1'b0: begin gen_out_a <= $signed(pid_reg_a[29-1:15]); end
        1'b1: begin gen_out_a <= $signed(pgen_a_out); end
    endcase
end

assign dat_a_o = gen_out_a;

////////////////////
///CHANNEL B MODE///
////////////////////

reg ch_b_mode_i = 1'b1;
reg [   14-1: 0] gen_out_b;

always @(posedge clk_i) begin
    casez (ch_b_mode_i)
        1'b0: begin gen_out_b <= $signed(pid_reg_b[29-1:15]); end
        1'b1: begin gen_out_b <= $signed(pgen_b_out); end
    endcase
end

assign dat_b_o = gen_out_b;    
    
    
//////////////////////////
///SYSTEM BUS WAVEFORMS///
//////////////////////////

always @(posedge clk_i) begin
      if (sys_wen) begin
         casez (sys_addr[19:0])
         
           20'h00000 : begin sp_delay_a_1_i            <= sys_wdata[14-1:0]; end
           20'h00004 : begin set_ki_a_i                <= sys_wdata[14-1:0]; end
           20'h00008 : begin int_rst_a_i               <= sys_wdata[0]; end 
           20'h0000C : begin ch_a_mode_i              <= sys_wdata[0];    end
           
           20'h00010 : begin sp_delay_a_2_i            <= sys_wdata[14-1:0]; end
           20'h00014 : begin offset_err_a_i            <= sys_wdata[14-1:0]; end
           20'h0001C : begin off_mode_a_i              <= sys_wdata[0];      end

           
           20'h00030 : begin sp_delay_b_1_i            <= sys_wdata[14-1:0]; end
           20'h00034 : begin set_ki_b_i                <= sys_wdata[14-1:0]; end
           20'h00038 : begin int_rst_b_i               <= sys_wdata[0]; end 
           20'h0003C : begin ch_b_mode_i              <= sys_wdata[0];    end
           
           20'h00040 : begin sp_delay_b_2_i            <= sys_wdata[14-1:0]; end
           /*
           20'h00044 : begin offset_err_b_i            <= sys_wdata[14-1:0]; end
           20'h0004C : begin off_mode_b_i              <= sys_wdata[0];      end
           */
           
		   20'h2zzzz : begin wave_a[sys_addr[14-1:2]]  <= sys_wdata[14-1:0]; end
		   //20'h2zzzz : begin wave2_a[sys_addr[14-1:2]]  <= sys_wdata[15-1:0]; end
		   
		   
		   20'h3zzzz : begin wave_b[sys_addr[14-1:2]]  <= sys_wdata[14-1:0]; end
		   //20'h4zzzz : begin wave2_b[sys_addr[14-1:2]]  <= sys_wdata[15-1:0]; end
		   
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
      
      20'h00000 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},sp_delay_a_1_i};            end
      20'h00004 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},set_ki_a_i};                end
      20'h00008 : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},int_rst_a_i};                end
      20'h0000C : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},ch_a_mode_i};               end
      
      20'h00010 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},sp_delay_a_2_i};            end
      20'h00014 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},offset_err_a_i};            end
      20'h00018 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},offset_meas_a};             end // keep read-only 
      20'h0001C : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},off_mode_a_i};               end
      
      20'h00020 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},int_avg_a};                 end
      
      
      20'h00030 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},sp_delay_b_1_i};            end
      20'h00034 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},set_ki_b_i};                end
      20'h00038 : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},int_rst_b_i};                end
      20'h0003C : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},ch_b_mode_i};               end
      
      20'h00040 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},sp_delay_b_2_i};            end
      /*
      20'h00044 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},offset_err_b_i};            end
      20'h00048 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},offset_meas_b};             end // keep read-only 
      20'h0004C : begin sys_ack <= sys_en;  sys_rdata <= {{32-1{1'b0}},off_mode_b_i};               end
      
      20'h00050 : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},int_avg_b};                 end       
      */
   
	  20'h2zzzz : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave_a[sys_addr[14-1:2]]};  end
      //20'h2zzzz : begin sys_ack <= sys_en;  sys_rdata <= {{32-15{1'b0}},wave2_a[sys_addr[14-1:2]]};  end
      
      20'h3zzzz : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}},wave_b[sys_addr[14-1:2]]};  end
      //20'h4zzzz : begin sys_ack <= sys_en;  sys_rdata <= {{32-15{1'b0}},wave2_b[sys_addr[14-1:2]]};  end
      
      default :   begin sys_ack <= sys_en;  sys_rdata <=  32'h0;                                  end
   endcase
end 

    
endmodule
