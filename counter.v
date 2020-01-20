module counter(count, offset,reset_l,enable, clk);
parameter COUNTERSIZE = 8;
output reg [COUNTERSIZE-1:0]count;
input wire [COUNTERSIZE-1:0]offset;
input wire enable,
	  reset_l, // 0 is Reset, High is GO!
	  clk;

initial 
	begin
		count = 0;
	end
	
always @ (posedge clk or negedge reset_l )
		count <= !reset_l ? 0 : ( enable ? count + offset : count) ;
endmodule
