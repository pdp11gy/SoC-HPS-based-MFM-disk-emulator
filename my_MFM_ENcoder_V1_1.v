/*
              *****************************************************************************
              *  Copyright (C) by Reinhard Heuberger                                 *
              *                                                                           *
              *  All rights reserved.                                                     *
              *                                                                           *
              *  Redistribution and use in source and binary forms, with or without       *
              *  modification, are permitted provided that the following conditions       *
              *  are met:                                                                 *
              *                                                                           *
              *  1. Redistributions of source code must retain the above copyright        *
              *     notice, this list of conditions and the following disclaimer.         *
              *  2. Redistributions in binary form must reproduce the above copyright     *
              *     notice, this list of conditions and the following disclaimer in the   *
              *     documentation and/or other materials provided with the distribution.  *
              *  3. Neither the name of the author nor the names of its contributors may  *
              *     be used to endorse or promote products derived from this software     *
              *     without specific prior written permission.                            *
              *                                                                           *
              *****************************************************************************
*/
//
// Description:
// ************
// MFM ENcoder for MFM disk simmulator with 8 bit parallel input
// and serial output. In this case, the serial transfer clock runs
// at 5.0 Mhz. The clock input is 80.0 MHz, obtained from a PLL to
// get the double frequency of 10.0 MHz, necessary for MFM phase 
// shifting. The 16bit transfer rate runs at 312.5 KHz. 
//
// TIME-shifting:
// **************
//  |<------ shift <-------- shift <----------- shift <-----------|
//  |<-16Bit SR history[15:0]->|<-16Bit shift/load,shifter[15:0]->|
//  |15  -> |9|8|7|6| <-     00|00 ---------LSB_first-----------15|
//           | | |             |15 ---------MSB_first-----------00|
//           | | | 
//           | | |
//           | | +-----> jetzt  (current)  history[7] -> serial_OUT
//           | +-------> alt    (old)      history[8]
//           +---------> uralt  (very old) history[9] 
// 
// PHASE shifting:
// ***************
// 10.0 MHz: ..._|----____----____|----____----____.....
// 5.0 MHz:  ..._|--------________|--------________.....
// phase_0   ..._|________________|________________.....
// phase_1   ..._|----____________|----____________.....
// phase_2   ..._|____----________|____----________.....
// phase_3   ..._|________----____|________----____.....
// phase_4   ..._|____________----|____________----.....
//
//  by: Reinhard Heuberger , www.PDP11GY.com
//
//   Umstellung auf 8 Bit / Byte  Mode JAN, 2019 
//

module my_MFM_ENcoder_V1_1(
       CLK_80,               // Input Clock  80.0 MHz
       data_byte_in,         // Data, 8 Bit parallel in
       //
       CLK_10,               // Out-Clock 10.0MHz
       CLK_5,                // Out-Clock  5.0MHZ
       CLK_8bit,             // Out-clock, 8Bit 
       serial_OUT,           // Data, Serial out
       load_L,               // SR load pulse
       MFM);                 // MFM out
//      
input CLK_80; 
input [7:0] data_byte_in;
output CLK_10, CLK_5, CLK_8bit, serial_OUT, load_L, MFM;
//
reg [31:0]  divider;         // counter,= clock generator.
reg [7:0]   shifter;         // 16Bit parallel in SR
reg [15:0]   history;        // jetzt, alt, uralt SR.
reg [3:0]   load_SR;         // load-puls generator SR
reg [2:0] rclksync_16_4;     // like 2 D-FF register, 
reg CLK_5_p;                 // Synchronized 5.0 MHz Clock
reg MFM;                     // MFM out
reg temp;                    // 
reg ph0, ph1, ph3;
wire phase_0, phase_1, phase_3, shifter_out;
//
initial
begin
   divider <= 0;
   shifter <= 0;
   history <= 0;
end
//
//
//========================== Counter/Divider =================================
//============================================================================
// Note: Counting up is done at negative edges.
//       Counting down is done at positive edges.
always @ (posedge CLK_80)
begin
   divider <= divider - 1;
end
assign CLK_10    =  divider[2];  // Output: 10.0Mhz
assign CLK_5     =  divider[3];  // Output: 5.0MHz
assign CLK_8bit  =  divider[6];  // Output: 8Bit Clock
//
//============== MFM phase and pulse-width generator =========================
//============================================================================
always @ (posedge CLK_80)
begin
 ph0 <= 0;
 ph1 <= ( CLK_5 &&  CLK_10);
 //
 ph3 <= (!CLK_5 &&  CLK_10);
 //
end
assign phase_0 = ph0;
assign phase_1 = ph1;
//
assign phase_3 = ph3;
//
//
//
//===================== Generate a 20ns load pulse ===========================
//============================================================================
always @ (posedge CLK_80)
begin
 load_SR = {load_SR[2:0], CLK_8bit};   // shift
end
assign load_L = ~((load_SR[2] ^ CLK_8bit) & CLK_8bit);
//
//
//========================= Mofify 5.0MHz clock  =============================
//============================================================================
always @ (posedge CLK_80)
begin
 CLK_5_p <= CLK_5;
end
//
//
//=============== Shiftregister with synchronous parallel load ===============
//============================================================================
//
always @ (posedge CLK_80)                       // Full Synchron !
begin
  if ( !CLK_5_p & CLK_5 )
      if (!load_L )
        shifter <= data_byte_in;                 // LOAD SR
      else if (load_L) begin
        shifter <= shifter << 1;                // MSB first
		  temp <= shifter[7];
		end
  end
assign  shifter_out  = temp; 
//
//
//========================= History shiftregister  ===========================
//============================================================================
always @ (posedge CLK_80)
begin
 if ( !CLK_5_p & CLK_5 )
 begin
  //
  history = {history[14:0], shifter_out};   // shift
  //
 end
end
assign  serial_OUT  = history[7];         // Serial out @ byte boundary     
//
//
//============================ MFM - ENcoder =================================
//============================================================================
//
always @(posedge CLK_80)
begin
      case (history[9:7])               // Byte boundery
      //case (history[15:13])           // word boundary
      //   |
      3'b000: MFM <= phase_1;         // 00->0 
      3'b001: MFM <= phase_3;         // 00->1 
      3'b010: MFM <= phase_0;         // 01->0 
      3'b011: MFM <= phase_3;         // 01->1 
      3'b100: MFM <= phase_1;         // 10->0 
      3'b101: MFM <= phase_3;         // 10->1 !
      3'b110: MFM <= phase_0;         // 11->0 
      3'b111: MFM <= phase_3;         // 11->1  
      //
     default: MFM <= 0;    
    endcase
end
//
endmodule
