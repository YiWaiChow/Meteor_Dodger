module ship_control
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[1];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire ld_x, ld_y, draw;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    combined c1 (
		.clock(CLOCK_50),
		.resetn(resetn),
		.start(KEY[2]),
		.colour(SW[9:7]),
		.shift_left(~KEY[3]),
		.shift_right(~KEY[0]),
		.out_x(x),
		.out_y(y),
		.out_colour(colour),
		.plot(writeEn)
	);

    
endmodule

module combined (clock,start,resetn, data, colour, shift_left, shift_right, out_x, out_y, out_colour, plot);
	input clock, start, resetn, shift_left, shift_right;
	input [6:0] data;
	input [2:0] colour;
	output [7:0] out_x;
	output [6:0] out_y;
	output [2:0] out_colour;
	output plot;
	
	wire ld_c, load_location, reg_l, reg_r, draw, clear;
	
	// Instansiate datapath
	datapath d0(
		.resetn(resetn),
		.clock(clock),
		.colour(colour),
		
		.load_location(load_location),
		.shift_left(reg_l),
		.shift_right(reg_r),
		.ld_c(ld_c),
		.draw(draw),
		.clear(clear),
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour)
	);

    // Instansiate FSM control
   control c0(
		.clock(clock),
		.resetn(resetn),
		.start(start),
		.load_location(load_location),
		.shift_left(shift_left),
		.shift_right(shift_right),
		.reg_r(reg_r),
		.reg_l(reg_l),
		.clear(clear),
		.ld_c(ld_c),
		.draw(draw),
		.plot(plot)
		);
	
endmodule

module datapath(colour, resetn, clock, load_location, shift_left, shift_right, ld_c, clear,draw, out_x, out_y, out_colour);
	
	input [2:0] colour;
	input resetn, clock, clear;
	input load_location, shift_left, shift_right, ld_c, draw;
	
	output  [7:0] out_x;
	output  [6:0] out_y;
	output reg [2:0] out_colour;
	
	reg [7:0] x;
	reg [6:0] y;
	reg [3:0] q;
	
	always @(posedge clock)
	begin: load
		if (!resetn) begin
			x <= 0;
			y <= 0;
			out_colour = 3'b111;
			end
		else 
			begin
				if (load_location) begin
					x <= 8'b00111111;
					y <= 7'b0111111;
					end
				if (shift_left)
						if(x > 8'b00000000)
							x <=  x-10;
						else
							x <= x;
				if (shift_right)
						if(x < 8'b01111111)
							x <= x +10;
						else
							x <= x;
				if (ld_c)
					 out_colour <= colour;
				if (clear)
					out_colour <= 3'b000;
			end
	end

	always @(posedge clock)
	begin: counter
		if (!resetn)
			q <= 4'b0000;
		else if (draw)
			begin
				if (q == 4'b1111)
					q <= 0;
				else
					q <= q + 1'b1;
			end
	end
	
	assign out_x = x + q[1:0];
	assign out_y = y + q[3:2];
	
endmodule

module control(clock, resetn,  start, shift_left, shift_right, reg_r, reg_l, ld_c, draw, plot, load_location, clear);
	input resetn, clock, start, shift_left, shift_right;
	output reg load_location,draw, plot, reg_r, reg_l, ld_c, clear;

	reg [3:0] current_state, next_state;
	
	localparam   S_start    = 4'd0,
                S_centre   = 4'd1,
                S_left     = 4'd2,
                S_right    = 4'd3,
					 S_clear_left = 4'd4,
					 S_clear_right =4'd5,
					 S_clear    = 4'd6;

	always @(*)
	begin: state_table
		case (current_state)
			S_start: 
					 begin
					 if(!start)
						next_state =  S_centre; 
					 else
						next_state = S_start;
					 end
                S_centre: 
					 begin
						if(!shift_left)
						  next_state = S_clear_left;
						if(!shift_right)
							next_state = S_clear_right;
						else
							next_state = S_centre;
						end
					 S_clear_left: next_state = S_left;
					 S_clear_right: next_state = S_right;
                S_left: next_state = S_centre;
                S_right: next_state = S_centre; 
					 
            default:     next_state = S_start;
		endcase
	end
	
	always @(*)
	begin: signals
		reg_r = 1'b0;
		reg_l = 1'b0;
		load_location = 1'b0;
		ld_c = 1'b0;
		draw = 1'b0;
		plot = 1'b0;
		clear = 1'b0;
		
		case (current_state)
		
	   S_start: begin
			load_location =1'b1;
			end
		S_centre: begin
			draw =1'b1;
			plot =1'b1;
			ld_c = 1'b1;
			end
		S_left : begin
			reg_l = 1'b1;
			end
		S_clear_left:begin 
		   clear = 1'b1;
			ld_c = 1'b0;
			end
		S_clear_right:begin
			ld_c = 1'b0;
		   clear = 1'b1;
			end
		S_right: begin
			reg_r = 1'b1;
			end
		S_clear: begin
			clear = 1'b1;
			end
		endcase
	end
	
always@(posedge clock)
    begin: state_FFs
        if(!resetn)
            current_state <= S_start;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

