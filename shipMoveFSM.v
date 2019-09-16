module shipMove_controlpath(CLOCK_50,resetn,
									UP,DOWN,LEFT,RIGHT,
									en_Ship_gamestart,
									en_moveShipUp,
									en_moveShipDown,
									en_moveShipLeft,
									en_moveShipRight,
									en_play_buck_sound,
									en_game_playing);

input CLOCK_50,resetn;
input UP,DOWN,LEFT,RIGHT,en_game_playing; //keyboard signals

output reg en_Ship_gamestart, en_moveShipUp,en_moveShipDown,en_moveShipLeft,en_moveShipRight; //ShipenMove signals

reg [4:0] ShipMove_current_state, ShipMove_next_state;


localparam 	S_SHIP_GAMESTART			= 5'd0,
				S_SHIP_IDLE				= 5'd1,
				S_SHIP_UP_IDLE_WAIT		= 5'd2,
				S_SHIP_DOWN_IDLE_WAIT	= 5'd3,
				S_SHIP_LEFT_IDLE_WAIT	= 5'd4,
				S_SHIP_RIGHT_IDLE_WAIT	= 5'd5,
				S_SHIP_UP					= 5'd6,
				S_SHIP_DOWN				= 5'd7,
				S_SHIP_LEFT				= 5'd8,
				S_SHIP_RIGHT				= 5'd9;
always@(*)
begin: Ship_move_state_table
	case (ShipMove_current_state)
		S_SHIP_GAMESTART				: ShipMove_next_state= S_SHIP_IDLE;
		S_SHIP_IDLE					:begin
		if(UP&&en_game_playing)
			ShipMove_next_state = S_SHIP_UP_IDLE_WAIT;
		else if (DOWN&&en_game_playing)
			ShipMove_next_state = S_SHIP_DOWN_IDLE_WAIT;
		else if (LEFT&&en_game_playing)
			ShipMove_next_state = S_SHIP_LEFT_IDLE_WAIT;
		else if (RIGHT&&en_game_playing)
			ShipMove_next_state = S_SHIP_RIGHT_IDLE_WAIT;
		else
			ShipMove_next_state = S_SHIP_IDLE;
		end
		S_SHIP_UP_IDLE_WAIT			: ShipMove_next_state= (UP)? S_SHIP_UP_IDLE_WAIT : S_SHIP_UP;
		S_SHIP_DOWN_IDLE_WAIT		: ShipMove_next_state= (DOWN)? S_SHIP_DOWN_IDLE_WAIT : S_SHIP_DOWN;
		S_SHIP_LEFT_IDLE_WAIT		: ShipMove_next_state= (LEFT)? S_SHIP_LEFT_IDLE_WAIT : S_SHIP_LEFT;
		S_SHIP_RIGHT_IDLE_WAIT		: ShipMove_next_state= (RIGHT)? S_SHIP_RIGHT_IDLE_WAIT : S_SHIP_RIGHT;
		S_SHIP_UP						: ShipMove_next_state= S_SHIP_IDLE;
		S_SHIP_DOWN					: ShipMove_next_state= S_SHIP_IDLE;
		S_SHIP_LEFT					: ShipMove_next_state= S_SHIP_IDLE;
		S_SHIP_RIGHT					: ShipMove_next_state= S_SHIP_IDLE;
	default: ShipMove_next_state = S_SHIP_GAMESTART;
	endcase
end // Ship_move_state_table

output reg en_play_buck_sound;

always @(*)
begin: ShipMove_enable_signals
	en_Ship_gamestart=0;
	en_moveShipUp=0;
	en_moveShipDown=0;
	en_moveShipLeft=0;
	en_moveShipRight=0;
	en_play_buck_sound = 0;
  case (ShipMove_current_state)
		S_SHIP_GAMESTART: en_Ship_gamestart=1;
		S_SHIP_UP					: en_moveShipUp=1;
		S_SHIP_DOWN				: en_moveShipDown=1;
		S_SHIP_LEFT				: en_moveShipLeft=1;
		S_SHIP_RIGHT				: en_moveShipRight=1;
		
//		S_SHIP_UP_IDLE_WAIT		: en_play_buck_sound=1;
//		S_SHIP_DOWN_IDLE_WAIT	: en_play_buck_sound=1;
//		S_SHIP_LEFT_IDLE_WAIT	: en_play_buck_sound=1;
//		S_SHIP_RIGHT_IDLE_WAIT	: en_play_buck_sound=1;
		
  endcase
end // ShipMove_enable_signals

always@(posedge CLOCK_50)
begin: ShipMove_FFs
  if(!resetn)
		ShipMove_current_state <= S_SHIP_GAMESTART;
  else
		ShipMove_current_state <= ShipMove_next_state;
end // ShipMove_FFS

endmodule

module ShipenMove_datapath(CLOCK_50,resetn,en_new_game,
									en_Ship_gamestart,
									en_moveShipUp,
									en_moveShipDown,
									en_moveShipLeft,
									en_moveShipRight,
									ShipInitX,ShipInitY);
									
input CLOCK_50,resetn;
input en_Ship_gamestart,en_moveShipUp,en_moveShipDown,en_moveShipLeft,en_moveShipRight;

input en_new_game;
output reg [9:0] ShipInitX;
output reg [8:0] ShipInitY;

initial
begin
ShipInitX  = 160; //'b0010100000;
ShipInitY  = 195;//'b010100000;

end



//Ship Origin Position
always@(posedge CLOCK_50) begin
	if((!resetn)||en_new_game) begin
		ShipInitX <= 160;//'b0010100000;
		ShipInitY <= 195;//'b010100000;
	end
else begin
		if (en_Ship_gamestart) begin
			ShipInitX  <= 160;//'b0010100000;
			ShipInitY  <= 195;//'b010100000;
		end
		if (en_moveShipUp&& ((ShipInitY-5)>0) ) begin
			ShipInitY<= (ShipInitY-5);
		end
		if(en_moveShipDown&&((ShipInitY+5)<230)) begin
			ShipInitY<= (ShipInitY+5);
		end
		if(en_moveShipLeft&& ((ShipInitX-5)>0)) begin
			ShipInitX<= (ShipInitX-5);
		end
		if(en_moveShipRight&& ((ShipInitX+5)<310)) begin
			ShipInitX<= (ShipInitX+5);
		end
	end
end
endmodule 