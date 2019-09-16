module project
	(LEDR,
		CLOCK_50,						//	On Board 50 MHz
		SW,
		KEY,							// On Board Keys
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,
		PS2_CLK,
		PS2_DAT,
		HEX0,
		HEX1,
		HEX2,
		AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,FPGA_I2C_SDAT,AUD_XCK,AUD_DACDAT,FPGA_I2C_SCLK
	//	VGA Blue[9:0]
	);
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;					
	input [9:0] SW;
		output [9:0] LEDR;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	inout PS2_CLK, PS2_DAT;
	
	wire resetn,up,down,left,right,en_game_playing;
	assign resetn = SW[0];
		
	assign en_game_playing = SW[1];
	wire [5:0] color;
	
	wire keyUP,keyDOWN,keyLEFT,keyRIGHT, keyCTRL,keyEND,keyHOME;
	assign up = ~KEY[3]||keyUP;
	assign down = ~KEY[2]||keyDOWN;
	assign left = ~KEY[1]||keyLEFT;
	assign right = ~KEY[0]||keyRIGHT;
	keyboard kb(.CLOCK_50(CLOCK_50),
				.resetn(resetn),
				.PS2_CLK(PS2_CLK),
				.PS2_DAT(PS2_DAT),
				.UP(keyUP),
				.DOWN(keyDOWN),
				.LEFT(keyLEFT),
				.RIGHT(keyRIGHT),
				.CTRL(keyCTRL),
				.END(keyEND),
				.HOME(keyHOME));
	
	wire ld_xyc,plotEn,m_plotEn,m1_plotEn,m2_plotEn,m3_plotEn,m4_plotEn,m5_plotEn,clean;
	
	wire writeEn,finish,m_finish,m1_finish,m2_finish,m3_finish,m4_finish,m5_finish, cleanDone, collision, lose, check, restart;
	wire [9:0] plotx;
	wire [9:0] ploty;
	
	wire frameC;
	wire en_Ship_gamestart,en_moveShipUp,en_moveShipDown,en_moveShipLeft,en_moveShipRight;//enable signals
	wire [9:0] ShipInitX;
	wire [8:0] ShipInitY;
	wire [9:0] meteorx;
	wire [8:0] meteory;
	wire [9:0] meteorx1;
	wire [8:0] meteory1;
	wire [9:0] meteorx2;
	wire [8:0] meteory2;
	
	wire m_dir_x;
	wire m_dir_y;
	wire m1_dir_x;
	wire m1_dir_y;
	wire m2_dir_x;
	wire m2_dir_y;
	
//	wire [5:0] m1_color;
//	wire [5:0] m2_color;
	wire [31:0]meteorspeed;
	wire frame;
	frameCounter c6(.clkin(CLOCK_50),.clkout(frame),.speed(1));
	meteorspeed s2(.i_clk(CLOCK_50),.speed(meteorspeed), .reset(resetn), .restart(restart) ,.frame(frame));
	frameCounter c4(.clkin(CLOCK_50),.clkout(frameC),.speed(meteorspeed));
	
	//AUDIO
input	AUD_ADCDAT;
inout AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,FPGA_I2C_SDAT;
output AUD_XCK,AUD_DACDAT,FPGA_I2C_SCLK;
wire soundOn,audio_out_allowed,write_audio_out;
wire [31:0] left_channel_audio_out;
wire [31:0]	right_channel_audio_out;
assign left_channel_audio_out	= soundOn? {BGMq,{24'b0}} : 0;
assign right_channel_audio_out	= soundOn? {BGMq,{24'b0}} : 0;
assign write_audio_out = audio_out_allowed;
assign soundOn = SW[9];//SW[9] controls sound on/off
//ACTUAL Audio Module
Audio_Controller Audio_Controller (
	.CLOCK_50						(CLOCK_50),
	.reset						(~resetn),
	.clear_audio_in_memory		(~resetn),
	.read_audio_in				(),
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),
	.AUD_ADCDAT					(AUD_ADCDAT),
	// 
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),
	// Outputs
	.audio_in_available			(),
	.left_channel_audio_in		(),
	.right_channel_audio_in		(),
	.audio_out_allowed			(audio_out_allowed),
	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)
);
avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~resetn)
);

	wire sixKC;
	sixK six6(.clkin(CLOCK_50),.clkout(sixKC));
	
reg	[15:0]  BGMAddress=16'b0;
wire	[7:0]  BGMq;
///////////////////////
///
//
//			check below!!!
//
/////////
bgm_ram bgm52556(.address(BGMAddress),.clock(CLOCK_50),.data(0),.wren(0),.q(BGMq));
always @(posedge sixKC) begin
	if(BGMAddress<52556)
	BGMAddress<=BGMAddress+16'b1;
	else
	BGMAddress<=16'b0;
end






	vga_controlPath controlP(.LEDR(LEDR),
								.restart(restart),
								.resetn(resetn),
								.CLOCK_50(CLOCK_50),
								.plotEn(plotEn),
								.m_plotEn(m_plotEn),
								.m1_plotEn(m1_plotEn),
								.m2_plotEn(m2_plotEn),
								.m3_plotEn(m3_plotEn),
								.m4_plotEn(m4_plotEn),
								.m5_plotEn(m5_plotEn),
								.ld_xyc(ld_xyc),
								.finish(finish),
								.m_finish(m_finish),
								.m1_finish(m1_finish),
								.m2_finish(m2_finish),
								.m3_finish(m3_finish),
								.m4_finish(m4_finish),
								.m5_finish(m5_finish),
								.clean(clean),
								.collision(collision),
								.frameCounter(frameC),
								.cleanDone(cleanDone),
								.lose(lose),
								.check(check)
								);

	vga_dataPath dataP(.game_restart(restart),
				.lose(lose),
				.check(check),
				.collision(collision),
				.resetn(resetn),
				.CLOCK_50(CLOCK_50),
				.ld_xyc(ld_xyc),
				.plotEn(plotEn),
				.m_plotEn(m_plotEn),
				.m1_plotEn(m1_plotEn),
				.m2_plotEn(m2_plotEn),
				.m3_plotEn(m3_plotEn),
				.m4_plotEn(m4_plotEn),
				.m5_plotEn(m5_plotEn),
				.writeEn(writeEn),
				.x(plotx),
				.y(ploty),
				.initialX(ShipInitX),
				.initialY(ShipInitY),
				.m_initialx(meteorx),
				.m_initialy(meteory),
				.m_initialx1(meteorx1),
				.m_initialy1(meteory1),
				.m_initialx2(meteorx2),
				.m_initialy2(meteory2),
				.m_initialx3(meteorx3),
				.m_initialy3(meteory3),
				.m_initialx4(meteorx4),
				.m_initialy4(meteory4),
				.m_initialx5(meteorx5),
				.m_initialy5(meteory5),
				.enable_m1(frame0),
				.enable_m2(frame1),
				.enable_m3(frame2),
				.enable_m4(frame3),
				.enable_m5(frame4),
				.enable_m6(frame5),
				.finish(finish),
				.m_finish(m_finish),
				.m1_finish(m1_finish),
				.m2_finish(m2_finish),
				.m3_finish(m3_finish),
				.m4_finish(m4_finish),
				.m5_finish(m5_finish),
				.clean(clean),
				.frameCounter(frameC),
				.colorOut(color),
				.cleanDone(cleanDone),
				.up(up),
				.down(down),
				.left(left),
				.right(right));
						
	
		vga_adapter VGA(
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(color),
		.x(plotx),
		.y(ploty),
		.plot(writeEn),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	

	
	
	

	
	
	

	
	shipMove_controlpath sc0(.CLOCK_50(CLOCK_50),
									.resetn(resetn),
									.UP(up),
									.DOWN(down),
									.LEFT(left),
									.RIGHT(right),
									.en_Ship_gamestart(en_Ship_gamestart),
									.en_moveShipUp(en_moveShipUp),
									.en_moveShipDown(en_moveShipDown),
									.en_moveShipLeft(en_moveShipLeft),
									.en_moveShipRight(en_moveShipRight),
									.en_game_playing(en_game_playing));
	
	ShipenMove_datapath SMD0(.CLOCK_50(CLOCK_50),
									.resetn(resetn),
									.en_new_game(restart),
									.en_Ship_gamestart(en_Ship_gamestart),
									.en_moveShipUp(en_moveShipUp),
									.en_moveShipDown(en_moveShipDown),
									.en_moveShipLeft(en_moveShipLeft),
									.en_moveShipRight(en_moveShipRight),
									.ShipInitX(ShipInitX),
									.ShipInitY(ShipInitY));
	
	meteor_movement m1(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(120),
							 .m_y(140),
							 .set_dir_x(1),
							 .set_dir_y(0),
							 .m_dir_x(m_dir_x),
							 .m_dir_y(m_dir_y),
							 .enable(frame0),
							 .o_x(meteorx),
							 .restart(restart),
							 .o_y(meteory));
							 
	meteor_movement m2(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(20),
						    .m_y(20),
							 .set_dir_x(1),
							 .set_dir_y(0),
							 .m_dir_x(m1_dir_x),
							 .m_dir_y(m1_dir_y),
							 .restart(restart),
							 .enable(frame1),
							 .o_x(meteorx1),
							 .o_y(meteory1));
							 
	meteor_movement m3(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(100),
							 .m_y(200),
							 .set_dir_x(1),
							 .set_dir_y(1),
							 .m_dir_x(m2_dir_x),
							 .m_dir_y(m2_dir_y),
							 .restart(restart),
							 .enable(frame2),
							 .o_x(meteorx2),
							 .o_y(meteory2));
	wire [9:0] meteorx3,meteorx4,meteorx5;
	wire [8:0] meteory3, meteory4, meteory5;
	wire m3_dir_x,m4_dir_x,m5_dir_x;
	wire m3_dir_y, m4_dir_y, m5_dir_y;
							
	meteor_movement m4(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(50),
							 .m_y(170),
							 .set_dir_x(0),
							 .set_dir_y(1),
							 .m_dir_x(m3_dir_x),
							 .m_dir_y(m3_dir_y),
							 .restart(restart),
							 .enable(frame3),
							 .o_x(meteorx3),
							 .o_y(meteory3));
							 
	meteor_movement m5(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(100),
							 .m_y(70),
							 .set_dir_x(1),
							 .set_dir_y(0),
							 .m_dir_x(m4_dir_x),
							 .m_dir_y(m4_dir_y),
							 .restart(restart),
							 .enable(frame4),
							 .o_x(meteorx4),
							 .o_y(meteory4));
							 
							 
	meteor_movement m6(.i_clk(CLOCK_50),
							 .m_frame(frameC),
							 .m_reset(resetn),
							 .m_x(77),
							 .m_y(88),
							 .set_dir_x(1),
							 .set_dir_y(1),
							 .m_dir_x(m5_dir_x),
							 .m_dir_y(m5_dir_y),
							 .restart(restart),
							 .enable(frame5),
							 .o_x(meteorx5),
							 .o_y(meteory5));
							 
	wire frame0,frame1, frame2, frame3,frame4, frame5;
	TimeCounter t0 (.clkin(CLOCK_50),.clkout(frame0) ,.period(1) ,.restart(restart),.reset(resetn));
	TimeCounter t1 (.clkin(CLOCK_50),.clkout(frame1) ,.period(5),.restart(restart),.reset(resetn));
	TimeCounter t2 (.clkin(CLOCK_50),.clkout(frame2), .period(10),.restart(restart),.reset(resetn));
	TimeCounter t3 (.clkin(CLOCK_50),.clkout(frame3) ,.period(15) ,.restart(restart),.reset(resetn));
	TimeCounter t4 (.clkin(CLOCK_50),.clkout(frame4) ,.period(20),.restart(restart),.reset(resetn));
	TimeCounter t5 (.clkin(CLOCK_50),.clkout(frame5), .period(25),.restart(restart),.reset(resetn));
	
	wire data;
	wire [6:0]h1, h2,h3;
	score score1(.clk(CLOCK_50),
				 .frame(frame),
				 .resetn(resetn),
				 .data(data),
				 .restart(restart),
				 .h1(h1),
				 .h2(h2),
				 .h3(h3));
	assign HEX0 = h1;
	assign HEX1 = h2;
	assign HEX2 = h3;
	
	
							 
							 

endmodule
		
module vga_controlPath (m2_finish,LEDR,
								restart,resetn,CLOCK_50,
								m_plotEn,m1_plotEn,m2_plotEn,plotEn,m3_plotEn, m4_plotEn, m5_plotEn,
								collision,
								ld_xyc,
								finish,m_finish,m1_finish,m3_finish, m4_finish, m5_finish,
								cleanDone,frameCounter,clean, lose, check);

   input restart,resetn,CLOCK_50,finish,cleanDone,frameCounter, m_finish, m1_finish, m2_finish,m3_finish, m4_finish, m5_finish,collision;
	
	reg [5:0] current_state, next_state;

	output reg ld_xyc, plotEn,clean,m_plotEn, m1_plotEn, m2_plotEn,m3_plotEn, m4_plotEn, m5_plotEn, lose, check;
	output  [9:0] LEDR;
	assign LEDR = current_state;
	localparam  S_LOAD_XYC        = 5'd9,
					S_CLEAN			 = 5'd1,
					S_PLOT          = 5'd2,
					S_PLOT_M        = 5'd3,
					S_PLOT_M1       = 5'd4,
					S_PLOT_M2       = 5'd8,
					S_PLOT_M3       = 5'd10,
					S_PLOT_M4       = 5'd11,
					S_PLOT_M5       = 5'd12,
					S_check_collide = 5'd5, 
					S_lose          = 5'd6;
	
	
    always@(*)
    begin: state_table 
		case (current_state)
			 S_LOAD_XYC: next_state =frameCounter ? S_CLEAN : S_LOAD_XYC;
			 S_CLEAN: next_state = cleanDone ? S_PLOT_M: S_CLEAN;
			 S_PLOT_M: next_state = (m_finish) ? S_PLOT_M1 : S_PLOT_M;
			 S_PLOT_M1: next_state = (m1_finish) ? S_PLOT_M2 : S_PLOT_M1;
			 S_PLOT_M2: next_state = (m2_finish) ? S_PLOT_M3 : S_PLOT_M2;
			 S_PLOT_M3: next_state = (m3_finish) ? S_PLOT_M4 : S_PLOT_M3;
			 S_PLOT_M4: next_state = (m4_finish) ? S_PLOT_M5 : S_PLOT_M4;
			 S_PLOT_M5: next_state = (m5_finish) ? S_PLOT : S_PLOT_M5;
			 S_PLOT: next_state = (finish) ? S_check_collide  : S_PLOT;
			 S_check_collide: next_state = (collision) ? S_lose : S_LOAD_XYC;
			 //S_LOSE: next_state = (collide)? S_reset: S_LOAD_XYC; check if collide
			 
//		default: next_state = S_LOAD_XYC;
		endcase
    end // state_table
   
    always @(*)
    begin: enable_signals
        ld_xyc = 0;
		  plotEn = 0;
		  clean = 0;
		  m_plotEn = 0;
		  m1_plotEn = 0;
		  m2_plotEn = 0;
		  m3_plotEn = 0;
		  m4_plotEn = 0;
		  m5_plotEn = 0;
//		  check = 0;
		  lose = 0;
        case (current_state)
            S_LOAD_XYC:begin
				ld_xyc= 1;
				
				end
				S_CLEAN: clean =1;
				S_PLOT: plotEn = 1;
				S_PLOT_M: m_plotEn =1;
				S_PLOT_M1: m1_plotEn =1;
				S_PLOT_M2: m2_plotEn =1;
				S_PLOT_M3: m3_plotEn =1;
				S_PLOT_M4: m4_plotEn =1;
				S_PLOT_M5: m5_plotEn =1;
				S_check_collide: begin
				check  =1;
				end
				S_lose: begin
				lose = 1;
				end
				//S_LOSE: check_collide = 1;
        endcase
    end // enable_signals
 
    always@(posedge CLOCK_50)
    begin: state_FFs
        if((!resetn || restart ))
            current_state <= S_LOAD_XYC;
        else
            current_state <= next_state;
    end // state_FFS
	 
endmodule

module vga_dataPath(m_initialx2,
							m_initialy2,
							m2_finish,
							m2_plotEn,
							game_restart,
							lose,
							check,
							collision,
							resetn,
							CLOCK_50,
							ld_xyc,
							m_plotEn,
							plotEn,
							m1_plotEn,
							m3_plotEn,m4_plotEn,m5_plotEn,
							writeEn,
							x,y,
							enable_m1,
							enable_m2,
							enable_m3,
							enable_m4,
							enable_m5,
							enable_m6,
							initialX,
							initialY,
							finish,m_finish,
							m1_finish,m5_finish,m4_finish,m3_finish,
							m_initialx,m_initialy,
							m_initialx1,m_initialy1,
							m_initialx3,m_initialy3,
							m_initialx4,m_initialy4,
							m_initialx5,m_initialy5,
							clean,
							cleanDone,frameCounter,
							colorOut,up,down,left,right);	 
//	input [5:0] colorIn;
//	input [5:0] m_colorIn;
//	input [5:0] m1_colorIn;
//	input [5:0] m2_colorIn;
	input up, down, right, left;
	input resetn,CLOCK_50,ld_xyc,plotEn, m_plotEn,m1_plotEn,m2_plotEn,m3_plotEn,m4_plotEn,m5_plotEn,clean,frameCounter, lose , check;
	output reg writeEn = 1'b0;
	output reg [9:0] x = 8'b10011110;
	output reg [9:0] y = 7'b0;
	input [9:0] initialX;
	input [9:0] initialY;
	input [9:0] m_initialx;
	input [9:0] m_initialy;
	input [9:0] m_initialx1;
	input [9:0] m_initialy1;
	input [9:0] m_initialx2;
	input [9:0] m_initialy2;
	input [9:0] m_initialx3;
	input [9:0] m_initialy3;
	input [9:0] m_initialx4;
	input [9:0] m_initialy4;
	input [9:0] m_initialx5;
	input [9:0] m_initialy5;
	input enable_m1,enable_m2,enable_m3,enable_m4,enable_m5,enable_m6;
	reg [9:0]current_x;
	reg [9:0]temp_x;
	reg [9:0]temp_x1;
	reg [9:0]temp_x2;
	reg [9:0]temp_x3;
	reg [9:0]temp_y3;
	reg [9:0]temp_x4;
	reg [9:0]temp_y4;
	reg [9:0]temp_x5;
	reg [9:0]temp_y5;
	reg [9:0]current_y;
	reg [9:0]temp_y;
	reg [9:0]temp_y1;
	reg [9:0]temp_y2;
	output reg finish = 1'b0; 
	output reg m_finish = 1'b0;
	output reg m1_finish = 1'b0;
	output reg m2_finish = 1'b0;
	output reg m3_finish = 1'b0;
	output reg m4_finish = 1'b0;
	output reg m5_finish = 1'b0;
	output reg collision = 1'b0;
	output reg game_restart = 1'b0;

	reg [8:0] HCount = 9'b0;
	reg [7:0] VCount = 8'b0;

	output reg cleanDone = 1'b0;
	reg [7:0] XIn =8'b10011110;
	reg [6:0] YIn =7'b0;
	reg [2:0] plotting = 3'b0;
	reg [2:0] plotting1 = 3'b0;
	reg [2:0] plotting2 = 3'b0;
	reg [2:0] plotting3 = 3'b0;
	reg [2:0] plotting4 = 3'b0;
	reg [2:0] plotting5 = 3'b0;
	reg [2:0] plotting6 = 3'b0;
	output reg [5:0] colorOut ;
	
	wire [5:0] spaceColor;
	wire [5:0] shipColor;
	wire [5:0] m_color;

	reg [16:0] space_address=0;
	space_ROM space_background(
	.address(space_address),
	.clock(CLOCK_50),
	.q(spaceColor));
	
	reg [16:0] ship_address=0;
	shipROM shipcolor(
	.address(ship_address),
	.clock(CLOCK_50),
	.q(shipColor));
	
	reg [16:0] star_address=0;
	starRom starcolor(
	.address(star_address),
	.clock(CLOCK_50),
	.q(m_color));
	
	localparam Background = 0, Ship = 1, Meteor = 2;
	reg [2:0] imageSelector;
	
	always@(*)begin
	case(imageSelector)
	0: colorOut=spaceColor;
	1: colorOut=shipColor;
	2: colorOut=m_color;
	3: colorOut=6'b000000;
	endcase
	end
	
	reg [4:0] xcount = 5'b0;
	reg [4:0] ycount = 5'b0;
	
	
	always@(posedge CLOCK_50) begin
			if((!resetn || game_restart)) begin
            x <= 8'b10011110; 
            y <= 7'b0;
				plotting <= 3'b0;
				writeEn  <= 1'b0;
				finish <= 1'b0;
				m_finish <= 1'b0;
				m1_finish <= 1'b0;
				m2_finish <= 1'b0;
				m3_finish <= 1'b0;
				m4_finish <= 1'b0;
				m5_finish <= 1'b0;
				plotting1 <= 3'b0;
				plotting2 <= 3'b0;
				plotting3 <= 3'b0;
				plotting4 <= 3'b0;
				plotting5 <= 3'b0;
				collision <= 1'b0;
				finish <=0;
            writeEn <= 0;
				cleanDone <= 0;
				game_restart <= 0;
				current_x <= 0;
				current_y <= 0;
				temp_x <= 0;
				temp_y <= 0;
				temp_x1 <= 0;
				temp_y1 <= 0;
				temp_x2 <= 0;
				temp_y2 <= 0;
				temp_x3 <= 0;
				temp_y3 <= 0;
				temp_x4 <= 0;
				temp_y4 <= 0;
				temp_x5<= 0;
				temp_y5<= 0;
        end
        else begin
				finish <=0;
				m_finish <=0;
				m1_finish <=0;
				m2_finish <= 1'b0;
				m3_finish <=0;
				m4_finish <=0;
				m5_finish <=0;
				collision <=1'b0;
            writeEn <= 0;
				cleanDone <= 0;
				collision <= 0;
				game_restart<= 0;
				
				if(ld_xyc) begin
					finish <= 0;
					x <= XIn;
					y <= YIn;
				end
				
				if (clean) begin
					x <= HCount;
					y <= VCount;
					imageSelector = 0;
					writeEn <= 1;					
					if(HCount<10'd319)begin
						HCount <= HCount+1'b1;
						space_address <= space_address +1;
						end
					else begin
						if(VCount<10'd239) begin
						VCount <= VCount+1'b1;
						HCount <= 9'b0;
						space_address <= space_address +1;
						end
						else begin
						HCount <= 9'b0;
						VCount <= 8'b0;
						cleanDone <= 1;
						space_address <= 0;
						end
					end
				end
							
			if(plotEn) begin
			ship_address <= ship_address +1;
				x <= initialX + xcount;
				y <= initialY + ycount;
				current_x <= initialX;
				current_y <= initialY;
				imageSelector = 1;
				writeEn <= 1'b1;
				if(colorOut == 6'b110011)begin
				writeEn <= 1'b0; 
				end
				if(xcount<12)begin
					xcount <= xcount+1'b1;

					end
				else if(ycount<14) begin
					xcount <= 5'b0;
					ycount <= ycount+1'b1;
					
				end
				else begin
					finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					ship_address <= 0;
				end	
			end
			if(m_plotEn) begin
				if(enable_m1)
					begin
					star_address <= star_address +1;
						x <= m_initialx + xcount;
						y <= m_initialy + ycount;
						temp_x <=m_initialx;
						temp_y <=m_initialy;
						
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
						end
					end
				 else
					begin
					x <= m_initialx; 
					y <= m_initialy ;
					temp_x <=m_initialx;
					temp_y <=m_initialy;
					imageSelector = 3;
					writeEn <= 1'b0;
					end
				if(xcount<12)begin
					xcount <= xcount+1'b1;
					
				end
				else if(ycount<14) begin
					ycount <= ycount+1'b1;
					xcount <= 5'b0;

				end else begin
					m_finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					star_address <= 0;
				end
			end
			
			if(m1_plotEn) begin
				if(enable_m2)
					begin
						x <= m_initialx1 + xcount;
						y <= m_initialy1 + ycount;
						temp_x1 <=m_initialx1;
						temp_y1 <=m_initialy1;
						star_address <= star_address +1;
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
						end
					end
				else
					begin
						x <= m_initialx1 ;
						y <= m_initialy1;
						temp_x1 <=m_initialx1;
						temp_y1 <=m_initialy1;
						imageSelector =3;
						writeEn <= 1'b0;
					end
				if(xcount<12)begin
					xcount <= xcount+1'b1;
					end
				else if (ycount<14)begin
					 
					ycount <= ycount+1'b1;
					xcount <= 5'b0;
				end 
				else 
					begin
					m1_finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					star_address <= 0;
					end
				end

			if(m2_plotEn) begin
			if(enable_m3)
				begin
						x <= m_initialx2 + xcount;
						y <= m_initialy2 + ycount;
						temp_x2 <=m_initialx2;
						temp_y2 <=m_initialy2;
						star_address <= star_address +1;
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
					end
				end
			else
				begin
					x <= m_initialx2; 
					y <= m_initialy2;
					temp_x2 <=m_initialx2;
					temp_y2 <=m_initialy2;
					imageSelector = 3;
					writeEn <= 1'b0;
				end
			
				if(xcount<12)
					begin
						xcount <= xcount+1'b1;
						
						end
				else if (ycount<14)
						begin
							ycount <= ycount+1'b1;
							xcount <= 5'b0;
						end 
				else 
					begin
						m2_finish <= 1;
						xcount <= 8'b0;
						ycount <= 7'b0;
						star_address <= 0;
					end
			end
			if(m3_plotEn) begin
				if(enable_m4)
					begin
					star_address <= star_address +1;
						x <= m_initialx3 + xcount;
						y <= m_initialy3 + ycount;
						temp_x3 <=m_initialx3;
						temp_y3 <=m_initialy3;
						
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
						end
					end
				 else
					begin
					x <= m_initialx3; 
					y <= m_initialy3 ;
					temp_x3 <=m_initialx3;
					temp_y3 <=m_initialy3;
					imageSelector = 3;
					writeEn <= 1'b0;
					end
				if(xcount<12)begin
					xcount <= xcount+1'b1;
					
				end
				else if(ycount<14) begin
					ycount <= ycount+1'b1;
					xcount <= 5'b0;

				end else begin
					m3_finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					star_address <= 0;
				end
			end
			if(m4_plotEn) begin
				if(enable_m5)
					begin
					star_address <= star_address +1;
						x <= m_initialx4 + xcount;
						y <= m_initialy4 + ycount;
						temp_x4 <=m_initialx4;
						temp_y4 <=m_initialy4;
						
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
						end
					end
				 else
					begin
					x <= m_initialx4; 
					y <= m_initialy4 ;
					temp_x4 <=m_initialx4;
					temp_y4 <=m_initialy4;
					imageSelector = 3;
					writeEn <= 1'b0;
					end
				if(xcount<12)begin
					xcount <= xcount+1'b1;
					
				end
				else if(ycount<14) begin
					ycount <= ycount+1'b1;
					xcount <= 5'b0;

				end else begin
					m4_finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					star_address <= 0;
				end
			end
			if(m5_plotEn) begin
				if(enable_m6)
					begin
					star_address <= star_address +1;
						x <= m_initialx5 + xcount;
						y <= m_initialy5 + ycount;
						temp_x5 <=m_initialx5;
						temp_y5 <=m_initialy5;
						
						imageSelector = 2;
						writeEn <= 1'b1;
						if(colorOut == 6'b110011)begin
						writeEn <= 1'b0; 
						end
					end
				 else
					begin
					x <= m_initialx5; 
					y <= m_initialy5 ;
					temp_x5 <=m_initialx5;
					temp_y5 <=m_initialy5;
					imageSelector = 3;
					writeEn <= 1'b0;
					end
				if(xcount<12)begin
					xcount <= xcount+1'b1;
					
				end
				else if(ycount<14) begin
					ycount <= ycount+1'b1;
					xcount <= 5'b0;

				end else begin
					m5_finish <= 1;
					xcount <= 8'b0;
					ycount <= 7'b0;
					star_address <= 0;
				end
			end
			
			
			if(check) begin 
				integer i;
				integer j;
				//check straight row
				for(i = 0; i<14 ;i = i+1) begin
					 if((((current_x +6) == (temp_x +6))&& ((current_y +i)== (temp_y +7)) ) ) begin
						collision <= 1;
						end
					 if ((((current_x+6) == (temp_x1 +6)) && ((current_y+i) == (temp_y1 +7)))) begin
						collision <= 1;
						end
					if ((((current_x +6) == (temp_x2+6)) && ((current_y+i) == (temp_y2+7)))) begin
					  collision <= 1;
						end
						if ((((current_x +6) == (temp_x3+6)) && ((current_y+i) == (temp_y3+7)))) begin
					  collision <= 1;
						end
						if ((((current_x +6) == (temp_x4+6)) && ((current_y+i) == (temp_y4+7)))) begin
					  collision <= 1;
						end
						if ((((current_x +6) == (temp_x5+6)) && ((current_y+i) == (temp_y5+7)))) begin
					  collision <= 1;
						end
					end
				for(j = 0; j<12; j = j+1)begin
					if((((current_x +j) == (temp_x+6))&& ((current_y +8)== (temp_y+7) ))) begin
						collision <= 1;
						end
					 if ((((current_x+j) == (temp_x1+6)) && ((current_y+8) == (temp_y1+7)))) begin
						collision <= 1;
						end
					if ((((current_x +j) == (temp_x2+7)) && ((current_y+8) == (temp_y2+7)))) begin
					  collision <= 1;
						end
					if ((((current_x +j) == (temp_x3+7)) && ((current_y+8) == (temp_y3+7)))) begin
					  collision <= 1;
						end
					if ((((current_x +j) == (temp_x4+7)) && ((current_y+8) == (temp_y4+7)))) begin
					  collision <= 1;
						end
					if ((((current_x +j) == (temp_x5+7)) && ((current_y+8) == (temp_y5+7)))) begin
					  collision <= 1;
						end
					end
			end	
			if(lose) begin
				game_restart <= 1;
				end
			end
		end
	 

	 
endmodule

module TimeCounter(clkin,clkout,period, restart, reset);
	input clkin;
	input [7:0]period;
	input restart;
	input reset;
	reg [7:0]cycle = 1;
	output reg clkout = 0;
	reg [31:0] counter = 0;
	always @(posedge clkin)
	begin
		if(restart || !reset)
		begin
		cycle <= 1;
		clkout = 0;
		end

		if ((counter == 0 && (cycle <period)))
		begin
			counter <= (50000000-1);
			cycle <= cycle + 1;
		end
		else 
		begin
			counter <= counter - 1;
			clkout <= 0;
		end
		if(cycle >= period)
			begin
			clkout<= 1;
			end
	end
endmodule

module frameCounter(clkin,clkout, speed);
	input clkin;
	input [31:0]speed;
	output reg clkout = 0;
	reg [26:0] counter = 0;
	always @(posedge clkin)
	begin
		if (counter == 0)
		begin
			counter <= (50000000/speed-1);
			clkout <= 1;
		end
		else 
		begin
			counter <= counter -1;
			clkout <= 0;
		end
	end
endmodule 