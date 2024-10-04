`timescale 1ns / 1ns
`define CLK 10.0
`define CLK_1 11.0
`define MAX_CYCLE 10000
module i2c_controller_tb;

	// Inputs
	reg clk;
	reg clk_1;
	reg rst;
	reg [7:0] addr;
	reg [7:0] data_in;
	reg [7:0] o_data;
	reg enable;
	reg re;
	reg stretching;
	// Outputs
	wire [7:0] data_out;
	wire ready;

	// Bidirs
	wire i2c_sda;
	wire i2c_scl;

	//assign 
	pullup(i2c_sda);
	pullup(i2c_scl);
	i2c_controller #(.DIVIDE_BY(2)) master (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.data_in(data_in), 
		.enable(enable), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl),
		.restart(re)
	);
	
		
	i2c_slave_controller #(.DIVIDE_BY(2)) slave (
		.clk(clk_1),
		.rst(rst),
		.sda(i2c_sda), 
		.scl(i2c_scl),
		.data(o_data),
		.scl_stretch(stretching)
    );
	
	initial begin
		clk = 0;
		clk_1 = 0;
		forever begin
			clk = #(`CLK) ~clk;
			clk_1 = #(`CLK_1) ~clk_1;
		end		
	end
	
	`ifdef ADDRNACK
		initial begin
			clk = 0;
			rst = 1;
			
			enable = 0;
			stretching = 0;
			#15;
			re = 1;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 8'b00011100;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end 
	`elsif WDATA_NO_STOP
		initial begin
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011000;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			// enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif WDATA_STOP
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011000;
			data_in = 8'b01000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif WDATA_RESTART
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 1;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011000;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			// enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif RDATA_STOP
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011001;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif RDATA_NO_STOP
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011001;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			// enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif RDATA_RESTART
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 1;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011001;
			data_in = 8'b10000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			// enable = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif WDATA_STRETCH
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011000;
			data_in = 8'b01000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			enable = 0;
			stretching = 1;
			#(`CLK*200);
			stretching = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`elsif RDATA_STRETCH
		initial begin
			// Initialize Inputs
			clk = 0;
			rst = 1;
			enable = 0;
			stretching = 0;
			#15;
			re = 0;
			rst = 0;	
			#20;
			rst = 1;	
			addr = 	  8'b10011001;
			data_in = 8'b01000011;
			o_data =  8'b10000001;
			
			#(`CLK*5);
			enable = 1;
			#(`CLK*15);
			enable = 0;
			stretching = 1;
			#(`CLK*200);
			stretching = 0;
					
			#(`MAX_CYCLE)
			$finish;
		end
	`endif

	
    	initial $dumpfile("vcdbasic.vcd");
    	initial $dumpvars();
	
endmodule