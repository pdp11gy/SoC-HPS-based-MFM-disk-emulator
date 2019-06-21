/*
          *****************************************************************************
          *    Copyright (C) by Reinhard Heuberger , www.PDP11GY.com, MAR, 2019       *
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
		
	                                    MFM Decoder 
                                        Clone-Mode									

	    This decoder measures the MFM distance time using the 80MHz clock.
			MFM decoder. The gap of the MFM signals are measured with an 80 MHz clock
			Two counters (A and B) alternately count the 80 MHZ pulses between the MFM 
			signals. The MFM tranfer rate is 5 MHz, that is 0.2 uS.
			This results in 80Mhz measurement, = 0.0125 �S:		  
			(  MFM decoder. Die Abst�nde der MFM Signale werden mit einer 80 MHz  Clock
			   gemessen. Zwei counter ( A und B ) z�hlen abwechselnd die 80 MHZ impulse 
			   zwischen den MFM Signalen. Die MFM tranfer Rate ist 5 MHz, also 0.2 uS.		  
			   Somit ergibt sich bei 80Mhz Messung, = 0.0125 uS :)
			short       : 0.2  us  = 16
			long        : 0.32 us  = 24
			verylong    : 0.4  us  = 32

		   Decoding:
			
			if counter > 17     				// long or verylong
		      if counter > 24					// verylong
			      // proceed verylong
			   else 							// long
			      // proceed long
			   endif
			else								// short
			   // proceed short
			endif
			
		This decoder provides "on the fly" realtime MFM-decoding and works perfectly with 
		Clock recovery, serial output and 8 bit parallel output. The decoder can also extended
		very easily if the MFM gaps schould stored. 
		
	Issues: Each manufacturer has guaranteed implemented his own track and data format which 
		was genarated with their own low-level format program. The following differences exist:
		CRC algorithm is different, such as different preset value.
		Track format: ID AM, DATA AM and SYNC character are differently. Even the same manufacturer,
		for example, DEC. There were different formats used . A disk , formatted with the RQDX-1 
		controller Disk could not be used in a RQDX-3 environment. 
		To handle this issue, a 16 bit input is provided to receive the DataAM pattern. 

	
    Problem: In a configuration like PDP-11,RQDX-1 and RD51, I found MFM gaps outside(!) the user
			 data which were either too short or too long. These cycles mess up the data timing
			 which results in obsolete data. Too short sometimes 80ns , toolong sometimes 0,52 us.
			 I could not find this symptom with a standard PC but I have not an up and running 
			 MFM-disk based PC available yet to continue working. Also, my RQDX-3 has a problem
			 and thus I can not working continue in the PDP-11 area.
			 
			
*/
module    MFM_gap_DECODER_V1_0(
		CLK_80,					// System Clock  80.0 MHz
		MFM_IN,					// Input MFM
		Index,					// Index-Puls from disk
		Enable,					// Ready+Seek-complete Signal from disk
		Pattern,					// DataAM pattern 
		//
		MFM_Sy1,					// MFM signal, synced to system clock
		data_serial,			// Serial Data out
		data_tmp,
		CLK_8bit,
		data_byte_out,			// Data, 8 Bit parallel out
		Index_puls,
		toolong,					// Debug/logic-analyser: FF
		tooshort,				// Debug/logic-analyser: FF
		match);					// Debug/logic-analyser: FF
//      
input CLK_80, MFM_IN, Index, Enable; 
input [15:0] Pattern;
output MFM_Sy1, data_serial, data_tmp, CLK_8bit;
output [7:0] data_byte_out;
output Index_puls, toolong, tooshort, match ;
//
reg [31:0]  divider1;          // counter,= clock generator.
reg [7:0]   counter_A;         // Counter A
reg [7:0]   counter_B;         // Counter B
reg [7:0]   counter_wert;      // latched counter value
reg [15:0]  shifter0;          // shifter, serial->parallel
reg [15:0]  triggerwert;       // 
reg [7:0]   latch_byte;        // Parallel out
reg [4:0]   byte_clock; 
reg [4:0]   MFM_shift;         // shift and sync MFM to 80MHz clk.
reg [4:0]   INDEX_shift;       // shift and sync Index puls
reg FlipFlop, FF, doshift, long, verylong, alt_MFM;
reg countAorB, CLK_8bit_P, TOOlong, TOOshort, pattern ; 
//wire MFM_pulse_pos1, MFM_pulse_pos2, MFM_pulse_pos3, MFM_pulse_neg;
wire MFM_pulse_pos2, MFM_pulse_pos3, MFM_pulse_neg;
wire usedcounter,load_byte;
wire [7:0]   count_A;
wire [7:0]   count_B;
wire [7:0]   counterwert;
wire [15:0]  DataAM;        
//
initial
begin
	divider1			<= 0;
	shifter0			<= 0;
	counter_A		<= 0;
	counter_B		<= 0;
	counter_wert	<= 0;
	byte_clock		<= 0;
	FlipFlop			<= 0;
	FF					<= 0;	
	doshift			<= 0;
	long				<= 0;
	verylong			<= 0;
	countAorB		<= 0;
end
//
//
//========= shift + Synchronize MFM signal, = MFM_IN  to FPGA clock ==========
//============================================================================
always @ (posedge CLK_80)
begin
	//
	MFM_shift <= { MFM_shift[3:0] , MFM_IN };					// synchron shift
	//
end
assign MFM_Sy1 =        MFM_shift[4];							// Synced MFM signal
assign MFM_pulse_pos2 = (!MFM_shift[3] &  MFM_shift[2]);	// 80Mhz MFM pulse #2
assign MFM_pulse_pos3 = (!MFM_shift[4] &  MFM_shift[3]);	// 80Mhz MFM pulse #3
assign MFM_pulse_neg =  ( MFM_shift[4] & !MFM_shift[3]);	// 80Mhz MFM pulse #4
//
//
//==================== Synchronize Index pulse signal ========================
//============================================================================
always @ (posedge CLK_80)
begin
	INDEX_shift <= { INDEX_shift[3:0] , Index };					// shift
end
assign Index_puls = (!INDEX_shift[3] & INDEX_shift[2]);		// 80Mhz index pulse
//
//
//============================================================================
always @ (posedge CLK_80)
begin
	triggerwert <= Pattern;
end
assign DataAM = triggerwert;
//
//
//===================   Measures MFM distance  ===============================
//                         with 80 MHZ clock
//
always @ (posedge CLK_80)
begin
	if(Enable & !Index_puls) begin
	   if(MFM_pulse_pos2) begin
			countAorB <= ~countAorB;						// Switch counter
	   end
		//		
	   if(!countAorB) begin
			counter_A <= counter_A + 1;					// increment counter A
			counter_B <= 0;
		end else begin
			counter_B <= counter_B + 1;					// incremant counter B
			counter_A <= 0;
		end
	end else begin
		counter_A <= 0;
		counter_B <= 0;
	end				
end
assign count_A = counter_A;
assign count_B = counter_B;
assign usedcounter = countAorB;
//
always @ (posedge CLK_80)
begin
	if(Enable & !Index_puls) begin
		//
		// Start @MFM positiv edge
		//
		if(MFM_pulse_pos2) begin
			if(!usedcounter) begin							// counter A  is in use
				counter_wert <= count_A;					// save Counter A 
			end else if(usedcounter) begin				// counter B  is in use
				counter_wert <= count_B;					// save Counter B 
			end
		end
	end
end
assign counterwert = counter_wert;
//
always @ (posedge CLK_80)
begin
	if(Enable & !Index_puls) begin
		//
		//----------------------------------------------------------------------
		//               calculate MFM gaps & decode to serial out 
		//----------------------------------------------------------------------
		//
		if ( MFM_pulse_pos3 ) begin										// pos edge
			//
			//
			if (counterwert  <= 9) begin									// TOO short !! (10)
				long          <= 0;											// !long     cycle 
				verylong      <= 0;											// !verylong cycle
				//byte_clock  <= 0;
				//byte_clock  <= byte_clock + 1;							// increment byte-counter
				doshift       <= 0;											// 1 = Enable shifting	
				FlipFlop      <= FlipFlop;
				FF            <= FF;											//Vergleich//
				TOOshort      <= ~TOOshort;								// Logic-analyser indicator 
			end else
				if (counterwert > 9 &  counterwert <= 20) begin		// short ( >10  & <=20)
					long       <= 0;											// !long     cycle 
					verylong   <= 0;											// !verylong cycle
					byte_clock <= byte_clock + 1;							// increment byte-counter
					doshift    <= 1;
					FlipFlop   <= FlipFlop;
					FF         <= FF;											//Vergleich//
			end else
				if (counterwert > 20 &  counterwert <= 28) begin	// long ( >20 & <=28 )
					//
					if(FlipFlop) begin										// Long cycle from 1 -> 0 
						long          <= 1;									// has to be handled different
					end															// comparing to 0 ->1 long cycle
					//
					verylong   <= 0;
					byte_clock <= byte_clock + 1;							// increment byte-counter
					doshift    <= 1;											// 1 = Enable shifting
					FlipFlop   <= ~FlipFlop;
					FF         <= ~FF;										//Vergleich//
			end else		
				if (counterwert > 28 &  counterwert <= 36) begin	// very long (>28  & <=36)
					long       <= 0;
					verylong   <= 1;
					byte_clock <= byte_clock + 1;							// increment byte-counter
					doshift    <= 1;											// 1 = Enable shifting
					FlipFlop   <= ~FlipFlop;								// FlipFlop   <= ~FlipFlop;
					FF         <= ~FF;										// Vergleich//
			end else 
				if (counterwert > 32) begin								// TOO long  !! (32)
					long       <= 0;											// !long     cycle 
					verylong   <= 0;											// !verylong cycle
					TOOlong    <= ~TOOlong;									// Logic-analyser indicator	
					//byte_clock <= 0;
					//byte_clock <= byte_clock + 1;						// increment byte-counter?
					doshift    <= 0;											// 1 = Enable shifting
					FlipFlop   <= 0;											// FlipFlop <= FlipFlop;
					FF         <= FF;											// Vergleich//
			end
			//
			if ( doshift ) begin
				shifter0 <= { shifter0[15:0] , FlipFlop};
			end
			//if (shifter0 == 16'hE4E4) begin							// Gap 1 Pattern , funktioniert
			if (shifter0 == DataAM) begin									// Find Pattern
				 pattern <= ~pattern;										// Logic-analyser indicator 
				 //byte_clock  <= 0;
		   end
			//
			//
		end else if ( MFM_pulse_neg ) begin								// pos edge
			if ( verylong | long ) begin									// VeryLong or 1->0 long cycle ?
				if (long ) begin
					FlipFlop  <= FlipFlop;									// long:     FlipFlop <= FlipFlop;	
					FF        <= FF;											// Vergleich//	
					long      <= 0;
				end else begin
					FlipFlop  <= ~FlipFlop;									// Verylong: FlipFlop <= ~FlipFlop;	
					FF        <= ~FF;											// Vergleich//
				end
				shifter0 <= { shifter0[15:0] , FlipFlop};
				byte_clock <= byte_clock + 1;								// increment byte-counter
				verylong   <= 0;												// Clear verylong Flag
			end else begin 
				FlipFlop <= FlipFlop;
				FF       <= FF;                           
			end
		end
		//
		//
	end else begin
	    long		<= 0;
		verylong	<= 0;
		FF			<= 0;
		FlipFlop	<= 0;
		byte_clock	<= 0;
	end
end
assign data_serial	= FlipFlop;
assign data_tmp		= FF;
assign toolong		= TOOlong;
assign tooshort		= TOOshort;
assign CLK_8bit		= byte_clock[2];
assign match		= pattern;
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
//=========================== latch 8 bit output =============================
//============================================================================
always @ (posedge CLK_80)
begin
  if (load_byte) begin
    //latch_byte <= shifter0;										// latch output
	 latch_byte[7:0] <= shifter0[7:0];							// latch output
  end
end
assign data_byte_out = latch_byte;								// 8bit / byte  out
//
//
//
endmodule

