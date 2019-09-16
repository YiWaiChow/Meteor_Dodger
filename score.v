module score(clk,frame,resetn,data,restart, h1,h2,h3);

input  clk;
input restart;
input frame;
input  resetn;
output reg [11:0] data;
output [6:0]h1, h2, h3;

always@(posedge clk)begin
	if(!resetn || restart)begin
		data <= 12'b0;
	end
	else if(frame) begin
		data<=data+1;
	end
end

	hex_decoder hexd0(.hex_digit(data[3:0]), .HEX(h1));
	hex_decoder hexd1(.hex_digit(data[7:4]), .HEX(h2));
	hex_decoder hexd2(.hex_digit(data[11:7]), .HEX(h3));
							 
endmodule 

module hex_decoder(hex_digit,HEX);
    input [3:0] hex_digit;
    output reg [6:0] HEX;
   
    always @(*)
        case (hex_digit)
            4'h0: HEX = 7'b100_0000;
            4'h1: HEX = 7'b111_1001;
            4'h2: HEX = 7'b010_0100;
            4'h3: HEX = 7'b011_0000;
            4'h4: HEX = 7'b001_1001;
            4'h5: HEX = 7'b001_0010;
            4'h6: HEX = 7'b000_0010;
            4'h7: HEX = 7'b111_1000;
            4'h8: HEX = 7'b000_0000;
            4'h9: HEX = 7'b001_1000;
            4'hA: HEX = 7'b000_1000;
            4'hB: HEX = 7'b000_0011;
            4'hC: HEX = 7'b100_0110;
            4'hD: HEX = 7'b010_0001;
            4'hE: HEX = 7'b000_0110;
            4'hF: HEX = 7'b000_1110;   
            default: HEX = 7'h7f;
        endcase
endmodule

