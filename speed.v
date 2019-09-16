module speed(i_clk,speed, normal, slow, fast);
input normal;
input i_clk;
input slow;
input fast;
output reg [7:0]speed;
always @ (posedge i_clk)
    begin
	if(slow && (!normal) && (!fast))begin
		speed <= 1;
		end
	else if((!slow) &&(normal) && (!fast))begin
		speed <= 3;
	end
	else if((!slow) && (!normal) && (fast))begin
		speed <= 7;
	end
	else begin
	  speed  <= 20;
	 end
end

	endmodule 
	
module meteorspeed(i_clk,speed, reset, restart, frame);
input i_clk, reset, restart, frame;
output reg [31:0]speed;
always@(posedge i_clk)
	begin
	if((!reset)|| restart)
		begin
			speed <= 1;
		end
	if(frame)
		begin
		if(speed < 200);
			begin
			speed <= speed + 1;
			end
		end
	end
endmodule 