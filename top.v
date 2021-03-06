module top(
	input clk24m,
	input resetkey,
	output[2:0] led,

	output txd,
	input rxd1,
	input rxd2,

	//lcd
	output wire [7:0] R,
	output wire [7:0] G,
	output wire [7:0] B,
	output wire LCD_CLK,
	output wire LCD_HSYNC,
	output wire LCD_VSYNC,
	output wire LCD_DEN,
	output wire LCD_PWM,	//backlight,set to high
	
	//i2c (TP)
	inout	sda,
	inout	scl,
	
	// SD CARD
	inout sd_d2,
	inout sd_d3_cs,
	inout sd_cmd_mosi,
	inout sd_clk,
	inout sd_d0_miso,
	inout sd_d1,

	// JTAG	
	input  io_jtag_tms,
	input  io_jtag_tdi,
	output io_jtag_tdo,
	input  io_jtag_tck,

	// DEBUG
	output debugc,
	output debugd
);

reg [23:0] counter;
reg reset;
wire clk;
reg [23:0]clktap;

wire clk96mp,clk48mp,clk24mp,clk12mp;
wire clk50mp;

assign led[2:0] = io_gpioA_write[2:0];

pll u_pll
(
.refclk(clk24m),
.clk0_out(),
.clk1_out(clk50mp),
.clk2_out(clk48mp),
.clk3_out(clk96mp));

assign clk    = clk50mp;
always @(posedge clk) begin
	clktap <= clktap + 1'b1 ;
end

assign clk25_0mp = clktap[0];
assign clk12_5mp = clktap[1];
assign lcdclk = clk12_5mp;

assign debugc = sclin;
assign debugd = sdain;

// Reset Logic
always @(posedge clk) begin
	if (!resetkey) begin
		counter <= 20'b0 ;
		reset <= 1'b0;
	end else begin
		if (counter[15:0] < 16'hF000) begin
			counter <= counter + 1'b1;
		end else begin
			reset <= 1'b1;
		end
	end
end

//
// Briey SoC Wires
//
wire[10:0]  io_sdram_ADDR;            // output[10:0]
wire[1:0]   io_sdram_BA;              // output[1:0]
wire[31:0]  io_sdram_DQ_read;         // input[31:0]
wire[31:0]  io_sdram_DQ_write;        // output[31:0]
wire[31:0]  io_sdram_DQ_writeEnable;  // output[31:0]
wire[3:0]   io_sdram_DQM;             // output[3:0]
wire        io_sdram_CASn;            // output
wire        io_sdram_CKE;             // output
wire        io_sdram_CSn;             // output
wire        io_sdram_RASn;            // output
wire        io_sdram_WEn;             // output
  
wire[31:0]  io_gpioA_read;            // input[31:0]
wire[31:0]  io_gpioA_write;           // output[31:0]
wire[31:0]  io_gpioA_writeEnable;     // output[31:0]
wire[31:0]  io_gpioB_read;            // input[31:0]
wire[31:0]  io_gpioB_write;           // output[31:0]
wire[31:0]  io_gpioB_writeEnable;     // output[31:0]
  
wire io_uart_txd;              // output
wire io_uart_rxd;              // input

wire [4:0]io_vga_color_r;
wire [5:0]io_vga_color_g;
wire [4:0]io_vga_color_b;


assign txd = io_uart_txd;
wire rxd ;
assign io_uart_rxd = rxd1 & rxd2 ;

wire LCD_START;
assign LCD_PWM = (reset == 1'b1) ? 1'b1 : 1'b0;
assign LCD_CLK = lcdclk;
reg LCD_DEN_LAST;
reg [15:0]px;
reg [15:0]py;

wire [15:0] npx;
//wire [15:0] lpx;
wire [15:0] npy;
wire [7:0] pixels;

// Hardware Cursor
reg [31:0] cursorx;
reg [31:0] cursory;
wire cxmatch,cymatch,cursorrev;
assign npx   = px + 15'd1;
assign npy   = py + 15'd1;
//assign lpx   = px - 15'd1;
assign cxmatch = (px[10:3] == cursorx[7:0]);
assign cymatch = (py[12:5] == cursory[7:0]);
assign cursorrev = (cxmatch & cymatch);
assign pixel = (pixels[3'b111 - px[2:0]]) ^ cursorrev;

always @(posedge lcdclk) begin
	if (LCD_START) begin
		px <= 16'b0;
		py <= 16'b0;
	end else begin
		if (LCD_DEN) begin
			// ?? STRANGE LOGIC ?? - DUE TO JTAG DEBUGGER CONNECT FAIL
			if (!LCD_DEN_LAST) begin 
				px <= 16'b1;
			end else begin
				px <= px + 16'b1;
			end 
		end else if (LCD_DEN_LAST) begin
			py <= py + 16'b1;
			px <= 16'b0;
		end
	end
	LCD_DEN_LAST <= LCD_DEN;
end

wire[7:0] chrout;

fontrom u_fontrom (
	.clka(clk),
	.addra({chrout[6:0],py[4:1]}),
	.doa(pixels),
	.rsta(1'b0)
);

textvram u_textvram(
	.doa(APB_PRDATA[7:0]),
	.dia(APB_PWDATA[7:0]),
	.addra(APB_PADDR[13:2]),
	.wea(APB_WR),
	.clka(clk),

	.dob(chrout),
	.dib(8'h00),
	.addrb({py[9:5],npx[9:3]}), //(HIGH LCD)
	.web(1'b0),
	.clkb(lcdclk)
);

wire[7:0] G8;

assign R = pixel ? 8'hFF : { io_vga_color_r[4:0],io_vga_color_r[2:0] } ;
assign G8 = { io_vga_color_g[5:0],io_vga_color_g[1:0] } ;
assign G = pixel ? 8'hFF :
                       (px[15:2] == tpx[15:2] ? (tpen == 1'b1 ? 8'hFF : G8) : 
                       (py[15:2] == tpy[15:2] ? (tpen == 1'b1 ? 8'hFF : G8) : 
                       G8 ));
//assign G = pixel ? 8'hFF : { io_vga_color_g[5:0],io_vga_color_g[1:0] } ;
assign B = pixel ? 8'hFF : { io_vga_color_b[4:0],io_vga_color_b[2:0] } ;


//
// APB
//
wire[15:0] APB_PADDR;      //output     
wire[0:0]  APB_PSEL;       //output     [0:0]
wire       APB_PENABLE;    //output
wire       APB_PREADY;     //input
wire       APB_PWRITE;     //output             
wire[31:0] APB_PWDATA;     //output   
wire[31:0] APB_PRDATA;     //input         
assign     APB_WR = APB_PSEL & APB_PENABLE & APB_PWRITE ;      
assign     APB_RD = APB_PSEL & APB_PENABLE & !APB_PWRITE ;                 
assign     APB_PREADY    = 1'b1; // NO WAIT


Briey u_briey (
  .io_asyncReset(!reset), // input
  .io_axiClk(clk50mp),     // input
  .io_vgaClk(lcdclk),     // input
  
  .io_jtag_tms(io_jtag_tms), // input
  .io_jtag_tdi(io_jtag_tdi), // input
  .io_jtag_tdo(io_jtag_tdo), // output
  .io_jtag_tck(io_jtag_tck), // input
  
  .io_sdram_ADDR(io_sdram_ADDR),            // output[10:0]
  .io_sdram_BA(io_sdram_BA),              // output[1:0]
  .io_sdram_DQ_read(io_sdram_DQ_read),         // input[31:0]
  .io_sdram_DQ_write(io_sdram_DQ_write),        // output[31:0]
  .io_sdram_DQ_writeEnable(io_sdram_DQ_writeEnable),  // output
  .io_sdram_DQM(io_sdram_DQM),             // output[3:0]
  .io_sdram_CASn(io_sdram_CASn),            // output
  .io_sdram_CKE(io_sdram_CKE),             // output
  .io_sdram_CSn(io_sdram_CSn),             // output
  .io_sdram_RASn(io_sdram_RASn),            // output
  .io_sdram_WEn(io_sdram_WEn),             // output
  
  .io_gpioA_read(io_gpioA_read),            // input[31:0]
  .io_gpioA_write(io_gpioA_write),           // output[31:0]
  .io_gpioA_writeEnable(io_gpioA_writeEnable),     // output[31:0]
  .io_gpioB_read(io_gpioB_read),            // input[31:0]
  .io_gpioB_write(io_gpioB_write),           // output[31:0]
  .io_gpioB_writeEnable(io_gpioB_writeEnable),     // output[31:0]
  
  .io_uart_txd(io_uart_txd),              // output
  .io_uart_rxd(io_uart_rxd),              // input
 
  .io_vga_vSync(LCD_VSYNC), // output
  .io_vga_hSync(LCD_HSYNC), // output
  .io_vga_colorEn(LCD_DEN), // output
  .io_vga_color_r(io_vga_color_r), // output[4:0] 5
  .io_vga_color_g(io_vga_color_g), // output[5:0] 6
  .io_vga_color_b(io_vga_color_b), // output[4:0] 5
  .io_vgaFrameStart(LCD_START),
  
  .io_timerExternal_clear(1'b0), // input
  .io_timerExternal_tick(1'b0), // input
  .io_coreInterrupt(1'b0), // input
  
  .io_extAPB_PADDR(APB_PADDR),         //output     [3:0]
  .io_extAPB_PSEL(APB_PSEL),          //output     [0:0]
  .io_extAPB_PENABLE(APB_PENABLE),       //output
  .io_extAPB_PREADY(APB_PREADY),     //input
  .io_extAPB_PWRITE(APB_PWRITE),        //output             
  .io_extAPB_PWDATA(APB_PWDATA),        //output     [31:0]   
  .io_extAPB_PRDATA(APB_PRDATA),        //input      [31:0]   
  
  .io_extAPB2_PADDR(APB2_PADDR),         //output     [3:0]
  .io_extAPB2_PSEL(APB2_PSEL),          //output     [0:0]
  .io_extAPB2_PENABLE(APB2_PENABLE),       //output
  .io_extAPB2_PREADY(APB2_PREADY),     //input
  .io_extAPB2_PWRITE(APB2_PWRITE),        //output             
  .io_extAPB2_PWDATA(APB2_PWDATA),        //output     [31:0]   
  .io_extAPB2_PRDATA(APB2_PRDATA)        //input      [31:0]   
);

wire [31:0] sdram_dq;
assign io_sdram_DQ_read = sdram_dq;
assign sdram_dq = io_sdram_DQ_writeEnable ? io_sdram_DQ_write : 'hz;

EG_PHY_SDRAM_2M_32 sdram(
    .clk(clk50mp),
    .ras_n(io_sdram_RASn),
    .cas_n(io_sdram_CASn),
    .we_n(io_sdram_WEn),
    .addr(io_sdram_ADDR),
    .ba(io_sdram_BA),
    .dq(sdram_dq),
    .cs_n(io_sdram_CSn),
    .dm0(io_sdram_DQM[0]),
    .dm1(io_sdram_DQM[1]),
    .dm2(io_sdram_DQM[2]),
    .dm3(io_sdram_DQM[3]),
    .cke(io_sdram_CKE)
);

//
// I2C (TP)
//
reg sdain ;
reg sclin ;
wire sdaout;
wire sclout;

assign sda = (sdaout != 1'b0) ? 1'bz : 1'b0;
assign scl = (sclout != 1'b0) ? 1'bz : 1'b0;

reg [15:0]tpx;
reg [15:0]tpy;
reg tpen;
reg tpwe;

wire[31:0] tp_dout;

tpi2c u_i2c
(
	.resetb(reset), 
	.clk(clk),
	.sda_in(sdain),
	.scl_in(sclin),
	.sda_out(sdaout),
	.scl_out(sclout),
	
	.we(tpwe),
	.addr(APB2_PADDR[3:2]),
	.din(APB2_PWDATA[31:0]),
	.dout(tp_dout)
);

//
// APB2
//
wire[15:0] APB2_PADDR;      //output     
wire[0:0]  APB2_PSEL;       //output     [0:0]
wire       APB2_PENABLE;    //output
wire       APB2_PREADY;     //input
wire       APB2_PWRITE;     //output             
wire[31:0] APB2_PWDATA;     //output   
wire[31:0] APB2_PRDATA;     //input         
assign     APB2_WR = APB2_PSEL & APB2_PENABLE & APB2_PWRITE ;      
assign     APB2_RD = APB2_PSEL & APB2_PENABLE & !APB2_PWRITE ;                 
assign     APB2_PREADY    = 1'b1; // NO WAIT

// SPI GPIO
reg gpioa_ready;
reg[7:0] gpioa_out; // +40
reg[7:0] gpioa_dir; // +44
reg[7:0] gpioa_pin; // +48

reg[31:0] gpioa_spiout; // +4C(WRITE)
reg[31:0] gpioa_spiin;  // +4C(READ)
reg[7:0] gpioa_spicnt; // +50
reg[7:0] gpioa_spista; // +54

// GPIOA OUTPUT DRIVERS (BIDIR)
assign sd_d0_miso  = gpioa_dir[0] ? gpioa_out[0] : 1'bz ;
assign sd_cmd_mosi = gpioa_dir[1] ? gpioa_out[1] : 1'bz ;
assign sd_clk      = gpioa_dir[2] ? gpioa_out[2] : 1'bz ;
assign sd_d3_cs    = gpioa_dir[3] ? gpioa_out[3] : 1'bz ;
assign sd_d2       = gpioa_dir[4] ? gpioa_out[4] : 1'bz ;
assign sd_d1       = gpioa_dir[5] ? gpioa_out[5] : 1'bz ;

assign adr00h = (APB2_PADDR[7:0] == 8'h00);
//
assign adr02h = (APB2_PADDR[7:0] == 8'h08); // SCL
assign adr03h = (APB2_PADDR[7:0] == 8'h0C); // SDA
assign adr04h = (APB2_PADDR[7:0] == 8'h10); // TPX
assign adr06h = (APB2_PADDR[7:0] == 8'h18); // TPY
assign adr08h = (APB2_PADDR[7:0] == 8'h20); // TPEN

assign adr10h = (APB2_PADDR[7:0] == 8'h40); // gpioa_out
assign adr11h = (APB2_PADDR[7:0] == 8'h44); // gpioa_dir
assign adr12h = (APB2_PADDR[7:0] == 8'h48); // gpioa_pin
assign adr13h = (APB2_PADDR[7:0] == 8'h4C); // gpioa_spi in/out
assign adr14h = (APB2_PADDR[7:0] == 8'h50); // gpioa_spicnt
assign adr15h = (APB2_PADDR[7:0] == 8'h54); // gpioa_spista

assign adrcsrx = (APB2_PADDR[7:0] == 8'h80); // gpioa_spista
assign adrcsry = (APB2_PADDR[7:0] == 8'h84); // gpioa_spista

assign adrtp   = (APB2_PADDR[7:4] == 4'hA); // tp sm

wire iowren,iorden;
reg  last_iowr,last_iord;
assign iord = APB2_RD;
assign iowr = APB2_WR;
assign iowren = (!last_iowr) && (iowr) ;
assign iorden = (!last_iord) && (iord) ;

reg[4:0] spi_nextbit;

always @(posedge clk) begin
	if (iowren) begin
		//if (adr02h) begin
		//	sclout <= APB2_PWDATA[0]; // SCL
		//end
		//if (adr03h) begin
		//	sdaout <= APB2_PWDATA[7]; // SDA (MSB FIRST)
		//end
		if (adr04h) begin
			tpx[15:0] <= APB2_PWDATA[15:0];
		end
		if (adr06h) begin
			tpy[15:0] <= APB2_PWDATA[15:0];
		end
		if (adr08h) begin
			tpen <= APB2_PWDATA[0];
		end
		if (adr10h) begin
			gpioa_out[7:0] <= APB2_PWDATA[7:0];
		end
		if (adr11h) begin
			gpioa_dir[7:0] <= APB2_PWDATA[7:0];
		end
		if (adr13h) begin
			gpioa_spiout[31:0] <= APB2_PWDATA[31:0];
		end
		if (adr14h) begin
			gpioa_spiin[31:0] <= 8'h0 ;
			gpioa_spista[7:0] <= 8'h0 ;
			gpioa_out[1]      <= gpioa_spiout[APB2_PWDATA[4:0] - 5'h1];	// FIRST BIT			
			spi_nextbit[4:0]  <= APB2_PWDATA[4:0] - 5'h1;               // NEXT BIT
			gpioa_out[2]      <= 1'b0;				// CK_L()
			gpioa_spicnt[7:0] <= APB2_PWDATA[7:0] ;
		end
		if (adrcsrx) begin
			cursorx <= APB2_PWDATA;
		end
		if (adrcsry) begin
			cursory <= APB2_PWDATA;
		end
		// TP
		tpwe <= adrtp ;
	end else begin		
		// HW SPI CONTROL
		if (gpioa_spicnt[7:0] > 8'h0) begin
			if (gpioa_spista[7:0] == 8'h0) begin
				gpioa_spiin[spi_nextbit] <= sd_d0_miso ;
				gpioa_out[2]      <= 1'b1;			// CK_H()
				spi_nextbit[4:0]  <= spi_nextbit[4:0]  - 5'h1; 
				gpioa_spista[7:0] <= 8'h3;
			end else begin
				gpioa_out[1]      <= gpioa_spiout[spi_nextbit]; // NEXT BIT
				gpioa_out[2]      <= 1'b0;			  // CK_L()	  			
				gpioa_spista[7:0] <= 8'h0;				
				gpioa_spicnt[7:0] <= gpioa_spicnt[7:0] - 8'h1;
			end
		end		
		// TP
		tpwe <= 1'b0 ;
	end

	// GPIOA SAMPLE EVERY CLOCK
	gpioa_pin[7:0] <= { 1'b0 , 1'b0 , sd_d1 , sd_d2 , sd_d3_cs , sd_clk , sd_cmd_mosi , sd_d0_miso };

	sdain     <= sda ; // sda data
	sclin     <= scl ; // scl data	
	last_iowr <= iowr ; // TXD WR
	last_iord <= iord ; // TXD WR
end

// I2C
assign iord02h = (iord && adr02h);
assign iord03h = (iord && adr03h);
assign iord04h = (iord && adr04h);
assign iord06h = (iord && adr06h);
// SPI
assign iord10h = (iord && adr10h);
assign iord11h = (iord && adr11h);
assign iord12h = (iord && adr12h);
assign iord13h = (iord && adr13h);
assign iord14h = (iord && adr14h);
assign iord15h = (iord && adr15h);

assign iordcsrx = (iord && adrcsrx);
assign iordcsry = (iord && adrcsry);

assign iordtp   = (iord && adrtp);

//reg[7:0] gpioa_out; // +10
//reg[7:0] gpioa_dir; // +11
//reg[7:0] gpioa_pin; // +12
//reg[7:0] gpioa_spiout; // +13(WRITE)
//reg[7:0] gpioa_spiin;  // +13(READ)
//reg[7:0] gpioa_spicnt; // +14
//reg[7:0] gpioa_spista; // +15

assign APB2_PRDATA = 
				(iord02h ? {31'b0 , sclin} :
				(iord03h ? {31'b0 , sdain} :
				(iord04h ? {16'b0 , tpx[15:0]} :
				(iord06h ? {16'b0 , tpy[15:0]} :
				(iord10h ? {24'b0 , gpioa_out} :
				(iord11h ? {24'b0 , gpioa_dir} :
				(iord12h ? {24'b0 , gpioa_pin} :
				(iord13h ? gpioa_spiin :
				(iord14h ? {24'b0 , gpioa_spicnt} :
				(iord15h ? {24'b0 , gpioa_spista} :
				(iordcsrx ? cursorx :
				(iordcsry ? cursory :
				(iordtp   ? tp_dout :
				32'hFFFFFFFF)))))))))))));
endmodule
