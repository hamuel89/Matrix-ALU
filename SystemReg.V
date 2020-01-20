
module SystemReg(databus,done, select, ReadWrite,enable, clk);
parameter DATASIZE = 256;

inout wire [DATASIZE-1:0]databus;
input ReadWrite, // 1= read 0= write
	  select,
	  clk,
	  enable;
	  

reg [DATASIZE-1:0] memory;
reg [DATASIZE-1:0] DataOut;
output reg done;

assign databus = (!ReadWrite && select && enable) ? DataOut : 'bz;

initial
		done = 'bz;


always @ (posedge clk)
		if(enable && select && ReadWrite)
			begin
			$display("write reg");
				memory = databus;
				done = 1;
				#2 done = 0;
				#1 done = 'bz;
			end
always @ (negedge clk)
		if(enable && select && !ReadWrite)
			begin
			$display("read reg");
				DataOut = memory;
				done = 1;
				#2 done = 0;
				#1 done = 'bz;
			end
endmodule
