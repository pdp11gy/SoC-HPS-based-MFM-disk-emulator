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
        
    German:
    Smart MFM-DEcoder. Es gibt mehrere Möglichkeiten um einen MFM Decoder zu realisieren.
    Das Messen der Abstände von den MFM-Signalen und eine Ableitung davon bilden ist kaum
    synchron zu realisieren, so dass ich mich für folgende Möglichkeit entschieden habe:
    Die Übertragungsrate bei den MFM, ST506/ST412 Disk ist 5 Mhz. somit ist die  Basis ein
    16:1 Teiler , also 80Mhz -> 5Mhz Counter, welcher synchron mit den positiven MFM
    Flanken synchronisiert wird. Da bei den MFM disks keine clock zur Verfügung steht,
    muss hier auch Clock-Recovery implementiert werden und das ist tricki. Der Teiler wird
    bei jedem MFM Signal synchronisiert, was aber bei einem Long cycle zu Problemen führt,
    weil hier das clock signal vorversetzt synchronisiert wird und somit kein Unterschied
    bei der posiven Clock Flanke zwischen einen Long und short Cycle besteht. Den einzigen
    Unterschied  kann man nur beim Zeitpunkt der negativen Clock Flanke finden und dann
    dementsprechen bei der darauffolgenden positiven Clock-Flanke verknüpfen. Das gesamte
    Design läuft voll synchron. Die Masterclock sollte ca. 16mal, in diesem Fall 80Mhz sein.
    
   English:
    Smart MFM decoder. There are several ways to realize an MFM decoder.Measuring the 
    distances from the MFM signals and forming a derivative thereof is hardly synchronously,
    so I decided to do the following: The transfer rate for the MFM, ST506 / ST412 Disk is 
    5Mhz. so the base is one 16: 1 divider, ie 80Mhz -> 5Mhz Counter, which synchronizes 
    with the positive MFM Flanks is synchronized. Since no clock is available for the MFM 
    disks, clock-recovery has to be implemented here, too, and that's tricky. The divider will
    synchronized with every MFM signal, but this causes problems in a long cycle,
    because here the clock signal is synchronized in advance and thus no difference
    in the positive clock flank exists between a long and a short cycle. The only one
    Difference can only be found at the time of negative clock flank and then
    connect accordingly in the subsequent positive clock edge. The entire
    Design is in full sync. The masterclock should be about 16 times, in this case 80Mhz.


                                 Clone-Mode                                 
                                
              by: Reinhard Heuberger , www.PDP11GY.com, MAR, 2019

    
                          Change to  Byte  Mode JAN, 2019 
    
    
        Clocks + MFM : 80Mhz = 0.0125uS  x 16 = 0.2uS
    
        ....__--------________......   = 2.5MHz / 0.4 uS
        ....__----____----____......   = 5.0Mhz / 0.2 uS
             |<---->|                 = Short Cycle   = 0.2uS  = 16mal 80Mhz Clock
                |<-------->|             = Long Cycle    = 0.3uS  = 24mal 80Mhz Clock
                |<------------->|        = VeryLong Cyle = 0.4uS  = 32mal 80Mhz Clock
                
                
 Problem: Same symtom as in the MFM_gap_DECODER_V1_0.v 
             In a configuration like PDP-11,RQDX-1 and RD51, I found MFM gaps outside(!) the user
             data which were either too short or too long. These cycles mess up the data timing
             which results in obsolete data. Too short sometimes 80ns , toolong sometimes 0,52 us.
             I could not find this symptom with a standard PC but I have not an up and running 
             MFM-disk based PC available yet to continue working. Also, my RQDX-3 has a problem
             and thus I can not working continue in the PDP-11 area.    

    Toolong: query of  Bit 0 - 24. if 0 than toolong   

                    check_toolong_MFM[24]..................check_toolong_MFM[0]
    MFM_shift[39].............[24]..................MFM_shift[0]  << MFM - Signal :shift right to left
                   |                                              |
                   |                                              +-- MFM_IN;
                   +-- MFM_Sy = MFM_shift[38];

    Tooshort:  query of  Bit 31 - 28  if not 0  , than tooshort
   MFM_shift[31]........[28]
                
*/
module CL_my_MFM_DEcoder_V1_0(
        CLK_80,                // System Clock  80.0 MHz
        MFM_IN,                // Input MFM
        MSB_first,             // BIG/LITTLE Edian mode,
        Index,                 // Index-Puls from disk
        Enable,                // Ready+Seek-complete Signal from disk
        //
        MFM_Sy,                // MFM synced to system clock
        CLK_5,                 // synced 5 Mhz clock
        data_serial,           // Serial Data out
        CLK_8bit,              // synced 8 Bit/byte clock.
        data_byte_out,         // Data, 8 Bit parallel out
        Index_puls,            // INDEX pulse
        watchdog,              // Watch dog puls if MFM too long
        test);
//
//      
input CLK_80, MFM_IN, MSB_first, Index, Enable;
output MFM_Sy, CLK_5, CLK_8bit, data_serial;
output [7:0] data_byte_out;
output Index_puls, watchdog, test;
//
reg [31:0]  divider0;          // counter,= clock generator.
reg [31:0]  divider1;          // counter,= clock generator.
reg [7:0]   shifter0;          // shifter, serial->parallel
reg [7:0]   latch_byte;        // Parallel out
reg [38:0]  MFM_shift;         // shift and sync MFM to 80MHz clk.
reg [38:0]  INDEX_shift;       // shift and sync Index puls
reg [24:0]  check_toolong_MFM;
reg [2:0]   check_tooshort_MFM;
reg MFM_S, CLK_5_S, CLK_10_S, CLK_8bit_P;
reg INDEX_S, rec_5, rec_5_S;
reg FlipFlop, long_cycle_flag, alt_MFM;
reg toolong;
reg tooshort;
wire MFM_pulse, CLK_10;
wire load_byte, data_strobe;
wire INDEX_Sy;
//
initial
begin
   divider0         <= 0;
   divider1         <= 0;
   shifter0         <= 0;
   FlipFlop         <= 0; 
   long_cycle_flag  <= 0;
    toolong         <= 0;
    tooshort        <= 0;
end
//
//
//========= shift + Synchronize MFM signal, = MFM_IN  to FPGA clock ==========
//============================================================================
always @ (posedge CLK_80)
begin
   //MFM_shift <= { MFM_shift[3:0] , MFM_IN };   // shift
    MFM_shift <= MFM_shift << 1;
    MFM_shift[0] <= MFM_IN;
    //
    //check_toolong_MFM <= MFM_shift;
end
assign MFM_Sy = MFM_shift[38];
//
always @(posedge CLK_80)
begin
    check_toolong_MFM <= MFM_shift;
end
//
always @(posedge CLK_80)
begin
    check_tooshort_MFM <= MFM_shift[31:28];
end
//
//==================== Generate a 80Mhz load pulse ===========================
//============================================================================
always @(posedge CLK_80)
begin
 MFM_S  <= MFM_Sy;
end
assign MFM_pulse = ((MFM_S ^ MFM_Sy) & MFM_Sy);
//
//
//
//
//==================== Synchronize Index pulse signal ========================
//============================================================================
always @ (posedge CLK_80)
begin
    //INDEX_shift <= { INDEX_shift[38:0] , Index };   // shift
    INDEX_shift <= INDEX_shift << 1;
    INDEX_shift[0] <= Index;
end
assign INDEX_Sy=INDEX_shift[38];
//
//
//==================== Generate a 80Mhz index pulse ==========================
//============================================================================
always @(posedge CLK_80)
begin
    INDEX_S  <= INDEX_Sy;
end
assign Index_puls = ((INDEX_S ^ INDEX_Sy) & INDEX_Sy);
//
//
//
//*****************************************************************************
// Watch dog timer : Wenn die MFM signale läger als ein very long cycle 
// auseinander sind, gemessen vom synced MFM signal, positiv edge.
//*****************************************************************************
always @(posedge CLK_80)
begin
    if(MFM_pulse) begin                       // IF synced MFM signal
      //
        if(check_tooshort_MFM != 0) begin     // Too short MFM signal
            tooshort <= 1;
        end else begin
            tooshort <= 0;
        end
       //
    end else begin
       tooshort <= tooshort;
    end
end
assign test     = tooshort;
//
always @(posedge CLK_80)
begin
    if(MFM_pulse) begin                       // IF synced MFM signal
      //
        if (check_toolong_MFM == 0 ) begin    // Too long MFM signal
            toolong  <= 1;
        end else begin
            toolong  <= 0;
        end
      //        
    end else begin
        toolong <= toolong;
    end
end
assign watchdog = toolong;
//
//
//
//===================== Synchronized Counter/Divider =========================
//============================================================================
// Note: Counting up is done at negative edges.
//       Counting down is done at positive edges.
always @ (posedge CLK_80)
begin
    if(Enable & !Index_puls & !watchdog) begin
        if(!watchdog) begin                         //  watchdog 
            if (MFM_pulse)                          //  IF load
                begin
                divider0 <= 1;                      //   than reysnc to MFM puls
            end else if (!MFM_pulse) begin          //  ELSE
                divider0 <= divider0 - 1;           //   count
            end
        end else begin                              // watch dog zeitraum
            divider0 <= divider0;
        end
    end
end
assign CLK_5   =    divider0[3];                // Output: synced   5MHz clock
assign CLK_10  =    divider0[2];                // Output: synced  10MHz clock
//
//
//===================== Modify 5Mhz + 10Mclock ===============================
//============================================================================
always @ (posedge CLK_80)
begin
  CLK_5_S  <= CLK_5;
  CLK_10_S <= CLK_10;
end
//
//
//===============================  DEcode MFM  ===============================
//=================================**********=================================
always @ (posedge CLK_80)
begin
    if(!Enable) begin
        long_cycle_flag <= 0;
        FlipFlop <= 0;
    end else begin
        if(!watchdog) begin 
            if(Index_puls) begin 
                FlipFlop <= 0; 
             end else begin
                // 
                if ( !CLK_5 & CLK_5_S ) begin                   // neg edge
                    if( MFM_Sy)
                        long_cycle_flag <= 1;                   // long cycle
                    else if ( !MFM_Sy) 
                        long_cycle_flag <= 0;                   // short or very long
                    end
                if ( CLK_5 & !CLK_5_S ) begin                   // pos edge
                    alt_MFM <= MFM_Sy;
                    if ( long_cycle_flag )                      // = Long cycle
                        FlipFlop <= FlipFlop;
                    else begin 
                        if ( MFM_Sy !== alt_MFM )               // = Very Long cycle
                            FlipFlop <= ~FlipFlop;
                        else begin 
                            FlipFlop <= FlipFlop;               // = Short cycle
                        end
                    end
                end else begin
                   alt_MFM <= alt_MFM;
                end    
            end
        end else begin                                              // watch dog match 
            FlipFlop <= FlipFlop;   
          //FlipFlop <= ~FlipFlop;      
        end
    end
end
assign data_serial = FlipFlop;
//
//
//======================= Revover 8 bit clock  ==============================
//============================================================================
always @ (posedge CLK_80)
begin
    if (Enable) begin 
        if (Index_puls) begin                   // Index ?
            divider1 <= 0;
        end else begin
            divider1 <= divider1;
        end
        if ( CLK_10 & !CLK_10_S ) begin
            divider1 <= divider1 +1 ;               // count +1
        end  
    end else begin
        divider1 <= 0;                              // Sync @ index
    end 
end
assign CLK_8bit =  ~divider1[3];                    // Output: synced 8bit clock
//
//
//===================== Modify recovered  5Mhz ===============================
//============================================================================
always @ (posedge CLK_80)
begin
    rec_5 <= ~divider1[0];
    rec_5_S  <= rec_5;
end
assign data_strobe = !rec_5 & rec_5_S;
//
//
//=============== Generate load pulse for parallel out =======================
//============================================================================
always @ (posedge CLK_80)
begin
 CLK_8bit_P <= CLK_8bit;
end
assign load_byte = CLK_8bit & !CLK_8bit_P;
//
//
//===============  serial to 16 bit parallel converter =======================
//============================================================================
always @ (posedge CLK_80)
begin
    if ( !rec_5 & rec_5_S ) begin                   //  shift @ pos edge
        shifter0 <= shifter0 << 1;
        shifter0[0] <= FlipFlop;
      /*
        if (MSB_first) begin
            shifter0 <= shifter0 << 1;                // MSB first
            shifter0[0] <= FlipFlop;
        end else if (!MSB_first) begin
            shifter0 <= shifter0 >> 1;                // LSB first
            shifter0[7] <= FlipFlop;
        end
        */
    end
end
//
//
//=========================== latch 16 bit output ============================
//============================================================================
always @ (posedge CLK_80)
begin
  if (load_byte) begin
    latch_byte <= shifter0;                   // latch output
  end
end
assign data_byte_out = latch_byte;           // 8bit / byte  out
//
endmodule

