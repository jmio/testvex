// Verilog netlist created by TD v4.6.18154
// Wed Jun 16 21:07:35 2021

`timescale 1ns / 1ps
module textvram  // al_ip/textvram.v(14)
  (
  addra,
  addrb,
  clka,
  clkb,
  dia,
  dib,
  wea,
  web,
  doa,
  dob
  );

  input [11:0] addra;  // al_ip/textvram.v(25)
  input [11:0] addrb;  // al_ip/textvram.v(26)
  input clka;  // al_ip/textvram.v(29)
  input clkb;  // al_ip/textvram.v(30)
  input [7:0] dia;  // al_ip/textvram.v(23)
  input [7:0] dib;  // al_ip/textvram.v(24)
  input [0:0] wea;  // al_ip/textvram.v(27)
  input [0:0] web;  // al_ip/textvram.v(28)
  output [7:0] doa;  // al_ip/textvram.v(19)
  output [7:0] dob;  // al_ip/textvram.v(20)


  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  // address_offset=0;data_offset=0;depth=4096;width=8;num_section=1;width_per_section=8;section_size=8;working_depth=4096;working_width=8;address_step=1;bytes_in_per_section=1;
  EG_PHY_BRAM32K #(
    .CSAMUX("1"),
    .CSBMUX("1"),
    .DATA_WIDTH_A("8"),
    .DATA_WIDTH_B("8"),
    .MODE("DP16K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .SRMODE("SYNC"),
    .WRITEMODE_A("NORMAL"),
    .WRITEMODE_B("NORMAL"))
    inst_4096x8_sub_000000_000 (
    .addra(addra[11:1]),
    .addrb(addrb[11:1]),
    .bytea(addra[0]),
    .byteb(addrb[0]),
    .clka(clka),
    .clkb(clkb),
    .dia({open_n51,open_n52,open_n53,open_n54,open_n55,open_n56,open_n57,open_n58,dia}),
    .dib({open_n59,open_n60,open_n61,open_n62,open_n63,open_n64,open_n65,open_n66,dib}),
    .wea(wea),
    .web(web),
    .doa({open_n71,open_n72,open_n73,open_n74,open_n75,open_n76,open_n77,open_n78,doa}),
    .dob({open_n79,open_n80,open_n81,open_n82,open_n83,open_n84,open_n85,open_n86,dob}));

endmodule 

