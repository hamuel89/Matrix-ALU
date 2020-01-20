/*
Matrix multiplcation 4x4 matrix takes in 256 bit string and rolls and unrolls,
tristated databus;
string is 3->0 row and 3->0 coloum
*/
module multiplier(databus,done,select,readwrite,ab_select,reset_l,enable,clk);
		
parameter MEMORY_SIZE = 256,
		  DATASIZE = 16,
		  REGISTER_SIZE = 4;

inout wire [MEMORY_SIZE-1:0] databus;
reg [MEMORY_SIZE-1:0] dataout;

output reg done;
		   
input wire enable,
	       reset_l,
		   readwrite,
		   ab_select,
		   select,
	       clk;

integer row,
		coloum,
		k;

reg [DATASIZE-1:0]Matrix_Row_A[0:REGISTER_SIZE-1][0:REGISTER_SIZE-1];
reg [DATASIZE-1:0]Matrix_Row_B[0:REGISTER_SIZE-1][0:REGISTER_SIZE-1];
reg [DATASIZE-1:0]MatrixResult[0:REGISTER_SIZE-1][0:REGISTER_SIZE-1];
assign databus = (!readwrite && select && enable) ? dataout : 'bz;

reg [2:0]matcount;
initial
	begin
		done = 0;
		matcount = 0;
	end
always @ (posedge clk or negedge reset_l)
begin
	if(enable && select && readwrite)
	begin
		dataout = 0;
		$display("ab_select :",ab_select);
		for( row = 0;row < REGISTER_SIZE;row = row +1)
			for(coloum = 0;coloum <REGISTER_SIZE;coloum = coloum +1)
			begin
				if(ab_select == 0)
				begin
					Matrix_Row_A[3-row][3-coloum] = databus >> (row*REGISTER_SIZE*DATASIZE+coloum*DATASIZE);

				end
				else
				begin
					Matrix_Row_B[3-row][3-coloum] = databus >> (row*REGISTER_SIZE*DATASIZE+coloum*DATASIZE);
				
				end
			end
	end
		
	if(!reset_l)
	begin
		dataout <= 0;
		done <= 0;
		matcount = 0;
	
		for( row = 0;row < REGISTER_SIZE;row = row +1)
			for(coloum = 0;coloum < REGISTER_SIZE;coloum = coloum +1)
			begin
				Matrix_Row_A[row][coloum] = 0;
				Matrix_Row_B[row][coloum] = 0;
				MatrixResult[row][coloum] = 0;
			end

	end	
end
always @ (negedge clk)
if(enable && !readwrite && select)
	begin
		dataout = 0;
		 $display("A[%d] [%d] [%d] [%d]", Matrix_Row_A[0][0], Matrix_Row_A[0][1], Matrix_Row_A[0][2], Matrix_Row_A[0][3]);
				$display("A[%d] [%d] [%d] [%d]", Matrix_Row_A[1][0], Matrix_Row_A[1][1], Matrix_Row_A[1][2], Matrix_Row_A[1][3]);
				$display("A[%d] [%d] [%d] [%d]", Matrix_Row_A[2][0], Matrix_Row_A[2][1], Matrix_Row_A[2][2], Matrix_Row_A[2][3]);
				$display("A[%d] [%d] [%d] [%d]", Matrix_Row_A[3][0], Matrix_Row_A[3][1], Matrix_Row_A[3][2], Matrix_Row_A[3][3]);
				$display("B[%d] [%d] [%d] [%d]", Matrix_Row_B[0][0], Matrix_Row_B[0][1], Matrix_Row_B[0][2], Matrix_Row_B[0][3]);
				$display("B[%d] [%d] [%d] [%d]", Matrix_Row_B[1][0], Matrix_Row_B[1][1], Matrix_Row_B[1][2], Matrix_Row_B[1][3]);
				$display("B[%d] [%d] [%d] [%d]", Matrix_Row_B[2][0], Matrix_Row_B[2][1], Matrix_Row_B[2][2], Matrix_Row_B[2][3]);
				$display("B[%d] [%d] [%d] [%d]", Matrix_Row_B[3][0], Matrix_Row_B[3][1], Matrix_Row_B[3][2], Matrix_Row_B[3][3]);
		for( row = 0;row < REGISTER_SIZE;row = row +1)
			for(coloum = 0;coloum < REGISTER_SIZE;coloum = coloum +1)
				begin
					MatrixResult[row][coloum] = 0; 
					for (k = 0; k < REGISTER_SIZE; k = k+1)
						MatrixResult[row][coloum] = MatrixResult[row][coloum] + Matrix_Row_A[row][k] * Matrix_Row_B[k][coloum]; 
					
				end
			for( row = 0;row < REGISTER_SIZE;row = row +1)
			for(coloum = 0;coloum < REGISTER_SIZE;coloum = coloum +1)
				begin
					dataout = (dataout<<DATASIZE) + MatrixResult[row][coloum];
				end
$display("R[%d] [%d] [%d] [%d]", MatrixResult[0][0], MatrixResult[0][1], MatrixResult[0][2], MatrixResult[0][3]);
				$display("R[%d] [%d] [%d] [%d]", MatrixResult[1][0], MatrixResult[1][1], MatrixResult[1][2], MatrixResult[1][3]);
				$display("R[%d] [%d] [%d] [%d]", MatrixResult[2][0], MatrixResult[2][1], MatrixResult[2][2], MatrixResult[2][3]);
				$display("R[%d] [%d] [%d] [%d]", MatrixResult[3][0], MatrixResult[3][1], MatrixResult[3][2], MatrixResult[3][3]);
			done =1;	
			#2 done = 0;
			#1 done = 'bz;
				
	end

endmodule
