//ACTUAL KEYBOARD MODULE
module keyboard(CLOCK_50,resetn,PS2_CLK,PS2_DAT,UP,DOWN,LEFT,RIGHT,CTRL,END,HOME);
input CLOCK_50,resetn;
inout PS2_CLK,PS2_DAT;
output reg UP,DOWN,LEFT,RIGHT,CTRL,END,HOME;
wire ps2_key_pressed;
wire [7:0] ps2_key_data;

PS2_Controller PS2 (
	// Inputs
	.CLOCK_50 (CLOCK_50),
	.reset (~resetn),
	// Bidirectionals
	.PS2_CLK (PS2_CLK),
 	.PS2_DAT (PS2_DAT),
	// Outputs
	.received_data (ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);

reg [4:0] kCurrentState,kNextState;
localparam 	S_IDLE_K      		= 5'd0,
				S_INITIAL_P			= 5'd1,
				S_UP					= 5'd2,
				S_DOWN				= 5'd3,
				S_LEFT				= 5'd4,
				S_RIGHT				= 5'd5,
				S_CTRL				= 5'd6,
				S_END					= 5'd8,
				S_HOME				= 5'd9,
				S_RELEASE			= 5'd7;
				
always@(*)
begin: k_state_table
	case(kCurrentState)
		S_IDLE_K				: kNextState = (ps2_key_data == 'hE0) ? S_INITIAL_P : S_IDLE_K;
		S_INITIAL_P			: begin
			if(ps2_key_data== 'h75)
			kNextState = S_UP;
			else if(ps2_key_data== 'h72) 
			kNextState = S_DOWN;
			else if(ps2_key_data== 'h6B) 
			kNextState = S_LEFT;
			else if(ps2_key_data== 'h74) 
			kNextState = S_RIGHT;
			else if(ps2_key_data== 'h14) 
			kNextState = S_CTRL;
			else if(ps2_key_data== 'h69) 
			kNextState = S_END;
			else if(ps2_key_data== 'h6C) 
			kNextState = S_HOME;
			else
			kNextState = S_INITIAL_P;
		end
		S_UP					: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_UP;
		S_DOWN				: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_DOWN;
		S_LEFT				: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_LEFT;
		S_RIGHT				: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_RIGHT;
		S_CTRL				: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_CTRL;
		S_END					: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_END;
		S_HOME				: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE : S_HOME;
		S_RELEASE			: kNextState = (ps2_key_data == 'hF0) ? S_RELEASE: S_IDLE_K;
		default: kNextState = S_IDLE_K;
	endcase
end //k_state_table

always @(*)
begin: keyboard_signals
UP 		= 0;
DOWN 		= 0;
LEFT		= 0;
RIGHT 	= 0;
CTRL		= 0;
END		= 0;
HOME		= 0;
case (kCurrentState)
		S_UP			: UP 		= 1;
		S_DOWN		: DOWN 	= 1;
		S_LEFT		: LEFT	= 1;
		S_RIGHT		: RIGHT 	= 1;
		S_CTRL		: CTRL	= 1;
		S_END			: END		= 1;
		S_HOME		: HOME	= 1;
endcase
end // keyboard_signals

always@(posedge CLOCK_50)
begin: k_state_FFs
  if(!resetn)
		kCurrentState <= S_IDLE_K;
  else
		kCurrentState <= kNextState;
end // state_FFS

endmodule//keyboard