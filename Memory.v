				   
module SystemMemory(databus, done, address,select, ReadWrite,enable, clk);
parameter ADDRESS_SIZE = 6,
		  MEMORY_LENGTH = 15,
		  DATASIZE = 256;

inout wire [DATASIZE-1:0]databus;
input [ADDRESS_SIZE-1:0]address;// 2MSB are Pages,Page 01 opcode, Page 10 Matrix, Page 11 results.
input ReadWrite, // 1= read 0= write
	  clk,
	  select,
	  enable;
	  

reg [DATASIZE-1:0] memory[4:0][MEMORY_LENGTH-1:0];
reg [DATASIZE-1:0] DataOut;
output reg done;
assign databus = (!ReadWrite && select && enable) ? DataOut : 'bz;
initial
	done = 'bz;

always @ (posedge clk)
		if(enable && select && ReadWrite)
			begin
				memory[address[5:4]][address[3:0]] = databus;
				done = 1;
				#3 done = 0;
			end
always @ (negedge clk)
		if(enable && select && !ReadWrite)
			begin
				DataOut = memory[address[5:4]][address[3:0]];
				done = 1;
				#3 done = 0;
				#1 done = 'bz;
			end
endmodule
