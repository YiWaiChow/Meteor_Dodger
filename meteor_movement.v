module meteor_movement
    (
    input  i_clk,         // base clock
    input  m_frame,   // animation clock: pixel clock is 1 pix/frame
    input  m_reset, 	 // reset: returns animation to starting position
	 input enable,
	 input restart,
	 input  [9:0]m_x,
	 input   [8:0]m_y,
	 input set_dir_x, // meteor x direction
	 input set_dir_y,
	 output reg m_dir_x, // meteor x direction
	 output  reg m_dir_y, // meteor y direction
//	 input  [2:0]meteor_colour, // meteor colour
//	 output  reg [2:0]meteor_colour_out,
    output reg  [9:0]o_x,  // the meteor output x position
    output reg  [8:0]o_y // the meteor outpur y position
    );

    reg [9:0] x ;   // horizontal position of square centre
    reg [8:0] y ;   // vertical position of square centre
//    reg x_dir ;  // horizontal animation direction
//    reg y_dir ;  // vertical animation direction

//initial
//begin
//o_x  = 160; //'b0010100000;
//o_y  = 195;//'b010100000;

//end
    always @ (posedge i_clk)
    begin
        if (!m_reset || restart)  // on reset return to starting position
        begin
           x <= m_x;
            y <= m_y;
            m_dir_x<= set_dir_x;
            m_dir_y<= set_dir_y;
        end
		  else 
		  begin
			if (x == 1)  // edge of square is at left of screen
                m_dir_x <= 1;  // change direction to right
            if (x == 310)  // edge of square at right
                m_dir_x <= 0;  // change direction to left          
            if (y == 230)  // edge of square at top of screen
                m_dir_y <= 0;  // change direction to down
            if (y == 1)  // edge of square at bottom
                m_dir_y <= 1;  // change direction to up  
			end
		  begin 
		if(m_frame)
        begin
            x <= (m_dir_x) ? x + 1 : x - 1;  // move left if positive x_dir
            y <= (m_dir_y) ? y + 1 : y - 1;  // move down if positive y_dir
        
        end 
	if(enable)begin
		o_x <= x;
	  o_y <= y;
	 end
	 else begin
	  o_x <= 0;
	  o_y <= 0;
		end
	end
end
endmodule 