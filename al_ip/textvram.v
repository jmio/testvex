/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/Users/mio/Desktop/testvex/al_ip/textvram.v
 ** Date	:	2021 06 16
 ** TD version	:	4.6.18154
\************************************************************/

`timescale 1ns / 1ps

module textvram ( 
	doa, dia, addra, clka, wea,
	dob, dib, addrb, clkb, web
);

	output [7:0] doa;
	output [7:0] dob;


	input  [7:0] dia;
	input  [7:0] dib;
	input  [11:0] addra;
	input  [11:0] addrb;
	input  [0:0] wea;
	input  [0:0] web;
	input  clka;
	input  clkb;




	EG_LOGIC_BRAM #( .DATA_WIDTH_A(8),
				.DATA_WIDTH_B(8),
				.ADDR_WIDTH_A(12),
				.ADDR_WIDTH_B(12),
				.DATA_DEPTH_A(4096),
				.DATA_DEPTH_B(4096),
				.BYTE_ENABLE(8),
				.BYTE_A(1),
				.BYTE_B(1),
				.MODE("DP"),
				.REGMODE_A("NOREG"),
				.REGMODE_B("NOREG"),
				.WRITEMODE_A("NORMAL"),
				.WRITEMODE_B("NORMAL"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("32K"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE"))
			inst(
				.dia(dia),
				.dib(dib),
				.addra(addra),
				.addrb(addrb),
				.cea(1'b1),
				.ceb(1'b1),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(clka),
				.clkb(clkb),
				.wea(1'b0),
				.bea(wea),
				.web(1'b0),
				.beb(web),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(doa),
				.dob(dob));


endmodule