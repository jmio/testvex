module tpi2c
#(
	parameter NS2009_DELAY = 8'h10,
	parameter NS2009_POLLP = 8'h40,
	parameter NS2009_WADDR = 8'h90,
	parameter NS2009_RADDR = 8'h91,
	parameter NS2009_LOW_POWER_READ_X  = 8'hC0,
	parameter NS2009_LOW_POWER_READ_Y  = 8'hD0,
	parameter NS2009_LOW_POWER_READ_Z1 = 8'hE0
)
(
	input resetb, 
	input clk,
	input sda_in,
	input scl_in,
	output reg sda_out,
	output reg scl_out,
	
	input  we,
	input[1:0] addr,
	input[31:0] din,
	output[31:0] dout
);

reg[7:0] smstate;

reg wtrg;
reg rtrg;
reg[7:0] iaddr;
reg[7:0] wdata;
reg[15:0] xdata,ydata,zdata;

reg[7:0] i2ccnt;
reg[7:0] i2cmode;
reg[7:0] i2cbit;
reg[7:0] i2cstep;
reg[7:0] i2csend[3:0];
reg[7:0] i2crecv[3:0];
reg      i2cack;
reg[7:0] i2cwait;

assign dout[31:0] = (addr[1:0] == 2'b00 ? {24'h0 ,smstate[7:0]} :
                    (addr[1:0] == 2'b01 ? {16'h0 ,xdata} :
                    (addr[1:0] == 2'b10 ? {16'h0 ,ydata} :
                    (addr[1:0] == 2'b11 ? {16'h0 ,zdata} : 32'b0))));


always@(posedge clk) begin
	if (resetb == 1'b0) begin
		smstate <= 8'h0 ;
	end
	else
	begin
		// INIT
		if (smstate == 8'h0) begin
			if (i2cstep == 0) begin		
				if ((we) && (addr[1:0] == 2'b00)) begin
					smstate <= 8'h1;
					xdata   <= 16'h0;
					ydata   <= 16'h0;
					zdata   <= 16'h0;										
				end
			end
		end
		else
		// Z1
		if (smstate == 8'h1) begin
			// WAIT READ END
			if (i2cstep == 0) begin
				// WRITE CMD
				wtrg    <= 1'b1 ;
				iaddr   <= NS2009_WADDR ;
				wdata   <= NS2009_LOW_POWER_READ_Z1 ;
				smstate <= 8'h2 ;
			end
		end
		else
		if (smstate == 8'h2) begin
			// WAIT WRITE START
			if (i2cstep != 0) begin
				wtrg    <= 1'b0 ;
				smstate <= 8'h3 ;
			end
		end
		else
		if (smstate == 8'h3) begin
			// WAIT WRITE END and READ CMD
			if (i2cstep == 0) begin
				rtrg    <= 1'b1 ;
				iaddr   <= NS2009_RADDR ;
				smstate <= 8'h4 ;
			end
		end
		else
		if (smstate == 8'h4) begin
			// WAIT READ START
			if (i2cstep != 0) begin
				rtrg    <= 1'b0 ;
				smstate <= 8'h5 ;
			end
		end
		else
		// X
		if (smstate == 8'h5) begin
			// WAIT READ END
			if (i2cstep == 0) begin
				zdata   <= {4'b0,i2crecv[1][7:4],i2crecv[1][3:0],i2crecv[0][7:4]};
				// WRITE CMD
				wtrg    <= 1'b1 ;
				iaddr   <= NS2009_WADDR ;
				wdata   <= NS2009_LOW_POWER_READ_X ;
				smstate <= 8'h6 ;
			end
		end
		else
		if (smstate == 8'h6) begin
			// WAIT WRITE START
			if (i2cstep != 0) begin
				wtrg    <= 1'b0 ;
				smstate <= 8'h7 ;
			end
		end
		else
		if (smstate == 8'h7) begin
			// WAIT WRITE END and READ CMD
			if (i2cstep == 0) begin
				rtrg    <= 1'b1 ;
				iaddr   <= NS2009_RADDR ;
				smstate <= 8'h8 ;
			end
		end
		else
		if (smstate == 8'h8) begin
			// WAIT READ START
			if (i2cstep != 0) begin
				rtrg    <= 1'b0 ;
				smstate <= 8'h9 ;
			end
		end
		else
		// Y
		if (smstate == 8'h9) begin
			// WAIT READ END
			if (i2cstep == 0) begin
				xdata   <= {4'b0,i2crecv[1][7:4],i2crecv[1][3:0],i2crecv[0][7:4]};
				// WRITE CMD
				wtrg    <= 1'b1 ;
				iaddr   <= NS2009_WADDR ;
				wdata   <= NS2009_LOW_POWER_READ_Y ;
				smstate <= 8'hA ;
			end
		end
		else
		if (smstate == 8'hA) begin
			// WAIT WRITE START
			if (i2cstep != 0) begin
				wtrg    <= 1'b0 ;
				smstate <= 8'hB ;
			end
		end
		else
		if (smstate == 8'hB) begin
			// WAIT WRITE END and READ CMD
			if (i2cstep == 0) begin
				rtrg    <= 1'b1 ;
				iaddr   <= NS2009_RADDR ;
				smstate <= 8'hC ;
			end
		end
		else
		if (smstate == 8'hC) begin
			// WAIT READ START
			if (i2cstep != 0) begin
				rtrg    <= 1'b0 ;
				smstate <= 8'hD ;
			end
		end
		else
		// Z1
		if (smstate == 8'hD) begin
			// WAIT READ END
			if (i2cstep == 0) begin
				ydata   <= {4'b0,i2crecv[1][7:4],i2crecv[1][3:0],i2crecv[0][7:4]};
				smstate <= 8'h0 ; // GOtO IDLE
			end
		end
	end
end

always@(posedge clk) begin
	if (resetb == 1'b0) begin
		i2ccnt  <= 8'b0;
		i2cmode <= 8'b0;
		i2cbit  <= 8'b0;
		i2cstep <= 8'b0;
		sda_out <= 1'b1;
		scl_out <= 1'b1;
		i2cwait <= 8'h0;
	end else begin
		if (i2cstep == 8'h0) begin
			if (wtrg) begin
				// I2C WRITE
		        // _func   I2C_SEND(90H,NS2009_LOW_POWER_READ_Z1)   ; NS2009 Z1 Axis
				i2csend[0] <= iaddr; // ADDR
				i2csend[1] <= wdata; // DATA
				i2cmode    <= 8'h2;	     // TX MODE
				i2ccnt     <= 8'h0;
				i2cbit     <= 8'h0;
				// START CONDITION
				scl_out    <= 1'b1;
				sda_out    <= 1'b0;
				// START MACHINE
				i2cstep   <= 8'h1;
				i2cwait   <= 8'h0;
			end else
			if (rtrg) begin
				// I2C READ
				// _func   I2C_READ(91H)
				i2crecv[0] <= 8'b0;
				i2crecv[1] <= 8'b0;
				i2crecv[2] <= 8'b0;
				i2crecv[3] <= 8'b0;
				i2csend[0] <= iaddr; // ADDR
				i2csend[1] <= 8'h0; // DATA
				i2cmode    <= 8'h1;	// RX MODE
				i2ccnt     <= 8'h0;
				i2cbit     <= 8'h0;
				// CLEAR REGS
				i2crecv[0] <= 8'b0;
				i2crecv[1] <= 8'b0;
				i2crecv[2] <= 8'b0;
				i2crecv[3] <= 8'b0;
				// START CONDITION
				scl_out    <= 1'b1;
				sda_out    <= 1'b0;
				// START MACHINE
				i2cstep    <= 8'h1;
				i2cwait    <= 8'h0;
			end
		end
		else  
		if (i2cstep == 8'h1) begin
			scl_out <= 1'b0; // DRIVE L
			i2cstep <= 4'h2;		
		end
		else  
		if (i2cstep == 8'h2) begin
			if (scl_in == 1'b0) begin // WAIT SCL==0
				if (i2ccnt == 8'h0) begin
					i2cstep <= 8'h3;  // TX OPERATION
				end else begin
					if (i2cmode == 8'h1) begin // RX MODE						
						i2cstep <= 8'h4;  // RX OPERATION
					end else begin // TX MODE
						i2cstep <= 8'h3;  // TX OPERATION
					end
				end 				
			end
		end
		else  
		if (i2cstep == 8'h3) begin
			// TX BIT
			//scl_out <= 1'b1 ; // DRV H
			sda_out <= i2csend[i2ccnt[1:0]][8'h7-i2cbit]; // OUT MSB
			i2cwait <= NS2009_DELAY;
			i2cstep <= 8'h35;
		end
		else  
		if (i2cstep == 8'h35) begin
			if (i2cwait > 8'h0) begin
				i2cwait <= i2cwait - 8'h1;
			end else begin
				scl_out <= 1'b1 ; // DRV H
				i2cstep <= 8'h5;
			end
		end
		else  
		if (i2cstep == 8'h4) begin
			// RX BIT
			//i2crecv[i2ccnt[1:0]-2'b1][8'h7-i2cbit] <= sda_in ;
			//scl_out <= 1'b1 ; // DRV H
			i2cwait <= NS2009_DELAY;
			i2cstep <= 8'h45;
		end
		else  
		if (i2cstep == 8'h45) begin
			if (i2cwait > 8'h0) begin
				i2cwait <= i2cwait - 8'h1;
			end else begin
				// RX BIT
				i2crecv[2'b10-i2ccnt[1:0]][8'h7-i2cbit] <= sda_in ;
				scl_out <= 1'b1 ; // DRV H
				i2cstep <= 8'h5;
			end
		end
		else  
		if (i2cstep == 8'h5) begin
			// WAIT H
			if (scl_in == 1'b1) begin
				if (i2cbit == 8'h7) begin
					i2cwait <= NS2009_DELAY;
					i2cstep <= 8'h56;
				end else begin
					i2cbit  <= i2cbit + 8'h1;
					i2cwait <= NS2009_DELAY;
					i2cstep <= 8'h51;
				end
			end
		end
		else
		if (i2cstep == 8'h51) begin
			if (i2cwait > 8'h0) begin
				// DUMMY DELAY STATE
				i2cwait <= i2cwait - 8'h1;
			end else begin
				i2cstep <= 8'h1;
			end
		end
		else
		if (i2cstep == 8'h56) begin
			if (i2cwait > 8'h0) begin
				// DUMMY DELAY STATE
				i2cwait <= i2cwait - 8'h1;
			end else begin
				i2cstep <= 8'h6;
			end
		end
		else
		if (i2cstep == 8'h6) begin
			// BIT 8 READ ACK
			scl_out <= 1'b0; // DRIVE L
			i2cstep <= 8'h7;
		end			
		else
		if (i2cstep == 8'h7) begin
			if (scl_in == 1'b0) begin
				if ((i2cmode == 8'h1) && (i2ccnt == 8'h1)) begin // RX MODE AND BYTE 1
					sda_out <= 1'b0; // Master ACK
				end else begin
					sda_out <= 1'b1; // Hi-Z
				end
				i2cstep <= 8'h8;
			end
		end			
		else
		if (i2cstep == 8'h8) begin
			scl_out <= 1'b1; // DRIVE H
			i2cack  <= sda_in;
			i2cstep <= 8'h9;
		end
		else
		if (i2cstep == 8'h9) begin
			if (scl_in == 1'b1) begin // WAIT H
				i2cwait <= NS2009_DELAY;
				i2cstep <= 8'h9A;
			end
		end
		else
		if (i2cstep == 8'h9A) begin
			if (i2cwait > 8'h0) begin
				// DUMMY DELAY STATE
				i2cwait <= i2cwait - 8'h1;
			end else begin
				i2cstep <= 8'hA;
			end
		end
		else
		if (i2cstep == 8'hA) begin
			scl_out <= 1'b0; // DRIVE L
			sda_out <= 1'b1; // Hi-Z
			if (i2cmode == 8'h2) begin // TX MODE
				if (i2ccnt == 8'h1) begin // BYTE 1
					i2cstep <= 8'hF; // END TX
				end else begin
					i2ccnt <= i2ccnt + 1;
					i2cbit <= 8'h0;  // START NEXT BYTE
					i2cstep <= 8'h1;
				end 				
			end else begin
				if (i2ccnt == 8'h2) begin // BYTE 2
					i2cstep <= 8'hF; // END RX
				end else begin
					i2ccnt <= i2ccnt + 1;
					i2cbit <= 8'h0;  // START NEXT BYTE
					i2cstep <= 8'h1;
				end 								
			end
		end
		else
		if (i2cstep == 8'hF) begin
			// STOP CONDITION
			scl_out <= 1'b1; // DRIVE H
			i2cwait <= NS2009_POLLP;
			i2cstep <= 8'hFF; // STOP I2C STATE MACHINE and WAIT
		end
		else
		if (i2cstep == 8'hFF) begin
			// STOP CONDITION		
			if (scl_in == 1'b1) begin // WAIT H
				sda_out <= 1'b1; // Hi-Z			
				if (i2cwait > 8'h0) begin
					// DUMMY DELAY STATE
					i2cwait <= i2cwait - 8'h1;
				end else begin
					i2cstep <= 8'h0; // GOTO IDLE
				end				
			end
		end
	end
end

endmodule