module i2c_controller#(
	parameter DIVIDE_BY = 2
)(
input  			clk,
input 			rst,
input  [7:0] 	addr,
input  [7:0] 	data_in,
input  			enable,
input  			restart,

inout i2c_sda,
inout i2c_scl
);

localparam 	IDLE = 0,
			START = 1,
			ADDR = 2,
			RACK = 3,
			WDATA = 4,
			WACK = 5,
			ADDRACK = 6,
			RDATA = 7,
			STOP = 8;


reg [3:0]   state;
reg [7:0]   addr_write;
reg [7:0]   data_write;
reg	[7:0]   data_read;
reg [2:0]   counter;
reg [7:0]   scl_counter;
reg         wen;
/*
	en(enable) if 1, start transmit
	re(restart) if 1, regnerate start signal
*/
reg			en;
reg			re;

reg	[7:0]	out_vec;
reg        	sda_out;
reg         i2c_scl_enable;
reg         i2c_clk;

//I2c bidirectional bus control
assign i2c_scl = i2c_scl_enable & (!i2c_clk )?  0 : 1'bz;
assign i2c_sda = wen & (!sda_out) ? 0 : 1'bz;

//SDA value control
always@(*) begin
	if(state == ADDR) sda_out = addr_write[counter];
	else if(state == WDATA)sda_out = data_write[counter];
	else sda_out = 0;
end

//FSM, write enable control
always @(negedge i2c_clk or negedge rst) begin
	if(!rst) begin
		wen <= 0;
		state <= IDLE;
		counter <= 0;
		addr_write <= 0;
		data_write <= 0;
	end else begin
		addr_write <= addr;
		data_write <= data_in;	
		case(state)
			IDLE: begin
				if (en) begin
					wen <= 1;	
					state <= START;	
				end
				else begin
					state <= IDLE;
					wen <= 0;
				end
				counter <= 0;
			end
			START: begin
				state <= ADDR;
				counter <= 7;
			end
			ADDR: begin
				if (counter == 0) begin
					wen <= 0;
					state <= ADDRACK;
				end
				else begin
					wen <= 1;
				end
				counter <= counter - 1;
			end
			RACK: begin
				if (re) begin
					state <= START;
					wen <= 1;
				end
				else if(en) begin
					state <= RDATA;
					wen <= 0;
				end
				else begin
					state <= STOP;
					wen <= 1;
				end
			end
			WDATA: begin 
				if(i2c_scl) begin
					if(counter == 0) begin
						state <= WACK;
						wen <= 0;
					end
					else begin
						wen <= 1;
					end   
					counter <= counter - 1;
				end
			end
			WACK: begin
				/*
					possible next state:
					RESTART: 
					KEEP TRANSFER: next = WDATA
					STOP : next = STOP
				*/
				if (re) begin
					state <= IDLE;
					wen <= 0;
				end
				else if(i2c_sda == 0 && en) begin
					state <= WDATA;
					wen <= 1;
				end
				else begin
					state <= STOP;
					wen <= 1;
				end
			end
			ADDRACK: begin
				if(i2c_sda) begin
					state <= STOP;
					wen <= 1;
				end
				else if(addr_write[0]) begin
					state <= RDATA;
					wen <= 0;
				end
				else begin
					state <= WDATA;
					wen <= 1;
				end
			end
			RDATA: begin
				if(i2c_scl) begin
					if(counter == 0) begin
						state <= RACK;
						if(re || !en) wen <= 0;
						else wen <= 1;
					end
					else wen <= 0;
					counter <= counter - 1;
				end
			end
			STOP: begin
				wen <= 0;
				state <= IDLE; 
			end
		endcase
	end
end


// for SCL enable control and read from SDA bus
always @(posedge i2c_clk or negedge rst) begin		
	if(!rst) begin
		i2c_scl_enable <= 0;
		data_read <= 0;
	end else begin
		case(state)
			IDLE: i2c_scl_enable	<=	0;
			RACK: 
				if(re) i2c_scl_enable	<=	0;
			STOP: i2c_scl_enable	<=	0;
			default: i2c_scl_enable	<=	1;
		endcase
		if(state == RDATA) data_read[counter] <=i2c_sda;
		else data_read <= data_read;
	end
end

//scl clock generator
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		scl_counter 	<= 0;
		i2c_clk 		<= 0;
		en 				<= 0;
		re				<= 0;
	end
	else begin
		if (scl_counter == DIVIDE_BY - 1) begin
			i2c_clk <= ~i2c_clk;
			scl_counter <= 0;
		end
		else scl_counter <= scl_counter + 1;
		en			<= enable;
		re			<= restart;
	end
end 
endmodule