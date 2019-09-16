//6K Hz
module sixK(clkin,clkout);
	input clkin;
	output reg clkout = 0;
	reg [13:0] counter = 0;
	always @(posedge clkin) begin
		if (counter == 0) begin
			counter <= (8333);
			clkout <= 1;
		end
		else begin
			counter <= counter -14'b1;
			clkout <= 0;
		end
	end
endmodule 