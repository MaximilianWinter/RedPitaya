// GENERATED by Maximilian Winter
// edited from red_pitaya_asg.v

module simplified_asg (
  // DAC
  output     [ 14-1: 0] dac_a_o   ,  // DAC data CHA
  output     [ 14-1: 0] dac_b_o   ,  // DAC data CHB
  input                 dac_clk_i ,  // DAC clock
  input                 dac_rstn_i,  // DAC reset - active low
  input                 trig_a_i  ,  // starting trigger CHA
  input                 trig_b_i  ,  // starting trigger CHB
  output                trig_out_o,  // notification trigger
  // System bus
  input      [ 32-1: 0] sys_addr  ,  // bus address
  input      [ 32-1: 0] sys_wdata ,  // bus write data
  input                 sys_wen   ,  // bus write enable
  input                 sys_ren   ,  // bus read enable
  output reg [ 32-1: 0] sys_rdata ,  // bus read data
  output reg            sys_err   ,  // bus error indicator
  output reg            sys_ack      // bus acknowledge signal
);

//---------------------------------------------------------------------------------
//
// generating signal from DAC table 

localparam RSZ = 14 ;  // RAM size 2^RSZ; 2^14=16384

reg   [RSZ+15: 0] set_a_size   ;
reg   [RSZ+15: 0] set_a_step   ;
reg   [RSZ+15: 0] set_a_ofs    ;
reg               set_a_rst    ;
reg               set_a_once   ;
reg               set_a_wrap   ;
reg   [  14-1: 0] set_a_amp    ;
reg   [  14-1: 0] set_a_dc     ;
reg               set_a_zero   ;
reg   [  16-1: 0] set_a_ncyc   ;
reg   [  16-1: 0] set_a_rnum   ;
reg   [  32-1: 0] set_a_rdly   ;
reg               set_a_rgate  ;
reg               buf_a_we     ; //Buffer A, write enable Bool - Max
reg   [ RSZ-1: 0] buf_a_addr   ; //Buffer A, Address, 14 bits - Max
wire  [  14-1: 0] buf_a_rdata  ; //Buffer A, read data, 14 bits - Max
wire  [ RSZ-1: 0] buf_a_rpnt   ; //Buffer A, current read pointer, 14 bits - Max
reg   [  32-1: 0] buf_a_rpnt_rd; //Buffer A, ???, 32 bits; NOT given to asg_ch; need to understand its role better -Max
reg               trig_a_sw    ;
reg   [   3-1: 0] trig_a_src   ;
wire              trig_a_done  ;

simplified_asg_ch  #(.RSZ (RSZ)) (
  // DAC
  .dac_o           (dac_a_o),  // dac data output
  .dac_clk_i       (dac_clk_i),  // dac clock
  .dac_rstn_i      (dac_rstn_i),  // dac reset - active low
  // trigger
  .trig_sw_i       (trig_a_sw),  // software trigger
  .trig_ext_i      (trig_a_i         ),  // external trigger
  .trig_src_i      (trig_a_src       ),  // trigger source selector
  .trig_done_o     (trig_a_done      ),  // trigger event
  // buffer ctrl
  .buf_we_i        (buf_a_we         ),  // buffer buffer write
  .buf_addr_i      (buf_a_addr       ),  // buffer address
  .buf_wdata_i     (sys_wdata[14-1:0]),  // buffer write data
  .buf_rdata_o     (buf_a_rdata      ),  // buffer read data
  .buf_rpnt_o      (buf_a_rpnt       ),  // buffer current read pointer
  // configuration
  .set_size_i      (set_a_size       ),  // set table data size
  .set_step_i      (set_a_step       ),  // set pointer step
  .set_ofs_i       (set_a_ofs        ),  // set reset offset
  .set_rst_i       (set_a_rst        ),  // set FMS to reset
  .set_once_i      (set_a_once       ),  // set only once
  .set_wrap_i      (set_a_wrap       ),  // set wrap pointer
  .set_amp_i       (set_a_amp        ),  // set amplitude scale
  .set_dc_i        (set_a_dc         ),  // set output offset
  .set_zero_i      (set_a_zero       ),  // set output to zero
  .set_ncyc_i      (set_a_ncyc       ),  // set number of cycle
  .set_rnum_i      (set_a_rnum       ),  // set number of repetitions
  .set_rdly_i      (set_a_rdly       ),  // set delay between repetitions
  .set_rgate_i     (set_a_rgate      )   // set external gated repetition
);

always @(posedge dac_clk_i)
begin
   buf_a_we   <= sys_wen && (sys_addr[19:RSZ+2] == 'h1); //make write enable True if sys_wen is true and sys_addr[18:16] == 111 -Max
   buf_a_addr <= sys_addr[RSZ+1:2] ;  // address timing violation
  // can change only synchronous to write clock
end

assign trig_out_o = trig_a_done ;

//---------------------------------------------------------------------------------
//
//  System bus connection

reg  [3-1: 0] ren_dly ; //read enable, 3 bits
reg           ack_dly ; //acknowledge, 1 bit

always @(posedge dac_clk_i)
if (dac_rstn_i == 1'b0) begin // RESET is active low
   trig_a_sw   <=  1'b0    ;
   trig_a_src  <=  3'h0    ;
   set_a_amp   <= 14'h2000 ;
   set_a_dc    <= 14'h0    ;
   set_a_zero  <=  1'b0    ;
   set_a_rst   <=  1'b0    ;
   set_a_once  <=  1'b0    ;
   set_a_wrap  <=  1'b0    ;
   set_a_size  <= {RSZ+16{1'b1}} ; //Syntax: means Verilog concatenation operator; {3{1},0} = 1110; "+" has higher priority
   set_a_ofs   <= {RSZ+16{1'b0}} ;
   set_a_step  <={{RSZ+15{1'b0}},1'b0} ;
   set_a_ncyc  <= 16'h0    ;
   set_a_rnum  <= 16'h0    ;
   set_a_rdly  <= 32'h0    ;
   set_a_rgate <=  1'b0    ;
   
   ren_dly     <=  3'h0    ;
   ack_dly     <=  1'b0    ;
end else begin // if no Reset do the following
   //software trigger (1 bit) is true if, sys_wen is true, sys_wdata[0] is 1 and ... 
   trig_a_sw  <= sys_wen && (sys_addr[19:0]==20'h0) && sys_wdata[0]  ;
   
   
   
   if (sys_wen && (sys_addr[19:0]==20'h0))
      trig_a_src <= sys_wdata[2:0] ;
      // if sys_wen is true, and we are at the first address part
      // take the first 3 bits of sys_wdata and assign trig_a_src to it
      //corresponds to register map



   // if WRITE ENABLE IS TRUE 
   // MEANING: data from register to FPGA
   if (sys_wen) begin
      if (sys_addr[19:0]==20'h0)   {set_a_rgate, set_a_zero, set_a_rst, set_a_once, set_a_wrap} <= sys_wdata[ 8: 4] ;
      // assigning the bits 8 to 4 to the corresponding variables

      if (sys_addr[19:0]==20'h4)   set_a_amp  <= sys_wdata[  0+13: 0] ;
      // first 13 bits are for the amplitude scale; 14 bit
      
      if (sys_addr[19:0]==20'h4)   set_a_dc   <= sys_wdata[ 16+13:16] ;
      //this defines the amplitude offset; 14 bit
      
      if (sys_addr[19:0]==20'h8)   set_a_size <= sys_wdata[RSZ+15: 0] ;
      //"Counter Wrap", 30 bit
      
      if (sys_addr[19:0]==20'hC)   set_a_ofs  <= sys_wdata[RSZ+15: 0] ;
      //"Counter start offset"
      
      if (sys_addr[19:0]==20'h10)  set_a_step <= sys_wdata[RSZ+15: 0] ;
      //Counter step
      
      //missing here 20'h14 -> buffer current read pointer
      //probably because we only need to write values from FPGA to register
      // not vice versa
      
      if (sys_addr[19:0]==20'h18)  set_a_ncyc <= sys_wdata[  16-1: 0] ;
      //number of read cycles in one burst; 0: infinite
      
      if (sys_addr[19:0]==20'h1C)  set_a_rnum <= sys_wdata[  16-1: 0] ;
      //number of burst repitions; 0: disabled
      
      if (sys_addr[19:0]==20'h20)  set_a_rdly <= sys_wdata[  32-1: 0] ;
      //delay between burst repititions

   end

   // IF READ ENABLE IS TRUE 
   if (sys_ren) begin
      buf_a_rpnt_rd <= {{32-RSZ-2{1'b0}},buf_a_rpnt,2'h0};
      //assigning 16{1'b0},buf_a_rpnt,00 = 0000 0000 0000 0000 buf_a_rpnt(14 bit) 00
      // to buf_a_rpnt_rd (32 bit)
      // we do this because this is how it is stored in the Register 0x14
      
   end

   ren_dly <= {ren_dly[3-2:0], sys_ren};
   // assigning ren_dly[1:0] sys_ren (1 bit) to ren_dly
   // effectively shifting ren_dly's bits towards left; and adding new bit from sys_ren
   
   ack_dly <=  ren_dly[3-1] || sys_wen ;
   // acknowledge dly is assigned
   // MSB(leftest bit) of ren_dly OR sys_wen
   
end

wire [16-1: 0] r0_rd = {7'h0,set_a_rgate, set_a_zero,set_a_rst,set_a_once,set_a_wrap, 1'b0,trig_a_src };
// generally assigning r0_rd to 0000 000 set_a_rgate set_a_zero, set_a_rst, set_a_once, set_a_wrap, 0, trig_a_src (3bits)
// we do this because in the RG-map all these values are put together


wire sys_en;
assign sys_en = sys_wen | sys_ren;
// bit wise OR (but both are only 1 bit wide)


always @(posedge dac_clk_i)
//IF RESET do that
if (dac_rstn_i == 1'b0) begin
   sys_err <= 1'b0 ;
   sys_ack <= 1'b0 ;
   
//IF NO RESET do that 
end else begin
   sys_err <= 1'b0 ;

   casez (sys_addr[19:0])
     20'h00000 : begin sys_ack <= sys_en;          sys_rdata <= r0_rd                              ; end

     20'h00004 : begin sys_ack <= sys_en;          sys_rdata <= {2'h0, set_a_dc, 2'h0, set_a_amp}  ; end
     
     20'h00008 : begin sys_ack <= sys_en;          sys_rdata <= {{32-RSZ-16{1'b0}},set_a_size}     ; end
     
     20'h0000C : begin sys_ack <= sys_en;          sys_rdata <= {{32-RSZ-16{1'b0}},set_a_ofs}      ; end
     
     20'h00010 : begin sys_ack <= sys_en;          sys_rdata <= {{32-RSZ-16{1'b0}},set_a_step}     ; end
     
     
     20'h00014 : begin sys_ack <= sys_en;          sys_rdata <= buf_a_rpnt_rd                      ; end
     // writing the current read pointer to the register (or vice versa???)
     
     
     20'h00018 : begin sys_ack <= sys_en;          sys_rdata <= {{32-16{1'b0}},set_a_ncyc}         ; end
     20'h0001C : begin sys_ack <= sys_en;          sys_rdata <= {{32-16{1'b0}},set_a_rnum}         ; end
     20'h00020 : begin sys_ack <= sys_en;          sys_rdata <= set_a_rdly                         ; end


     20'h1zzzz : begin sys_ack <= ack_dly;         sys_rdata <= {{32-14{1'b0}},buf_a_rdata}        ; end
     //assigning 18{1'b0} buf_a_rdata(14 bits) to sys_rdata
     

       default : begin sys_ack <= sys_en;          sys_rdata <=  32'h0                             ; end
   endcase
end

endmodule