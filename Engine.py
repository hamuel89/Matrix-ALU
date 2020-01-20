module Engine(mult_done,mult_select,mult_readwrite,ab_select,mult_reset_l,
		      add_done,add_select,add_readwrite,ab_select,addsub,add_reset_l,
			  trans_done,trans_select,trans_readwrite,trans_reset_l,
			       mem_select, mem_readwrite,address,mem_done,
			       reg_select,reg_readwrite,reg_done,
				   cnt_result_offset,result_pointer,
				   cnt_opcode_offset,opcode_pointer,
			       databus,pointers_resetl,
				   clk,enable);
				   
parameter 	OP_ADD = 3'b001, 
			OP_SUB = 3'b010,
			OP_MULTI = 3'b011,
			OP_SCALE = 3'b100,
			OP_TRANS = 3'b101,
			OP_STOP = 3'b111;//bits 9-7

parameter 	OP_FROM_MEMORY  = 2'b01,  
			OP_FROM_REGISTER = 2'b10,
			OP_FROM_MEM_RESULT = 2'b11;//bits 6-2
			
parameter 	OP_TO_MEM_RESULT = 2'b00,
			OP_TO_MEMORY   = 2'b01, 
			OP_TO_REGISTER = 2'b10,
			OP_TO_REG_AND_MEM_RESULT = 2'b11;//bits 1-0;
		// [OPCODE_COMMAND_SIZE:OPCODE_FROM_SIZE:COUNTER:OPCODE_FROM_SIZE:COUNTER:OPCODE_TO_SIZE]
		//		3				 2         			 8          2      		 8       2
parameter ADDRESS_PG_OPCODE = 6'b010000,
		  ADDRESS_PG_MATRIX = 6'b100000,
		  ADDRESS_PG_RESULTS = 6'b110000;	

parameter ADDRESS_SIZE = 6,
		  MEMORY_LENGTH = 256,
		  MEMORY_SIZE = 256,
		  OPCODE_SIZE = 24,
		  OPCODE_FROM_SIZE = 2,
		  OPCODE_TO_SIZE = 2,
		  OPCODE_COMMAND_SIZE = 3,
		  COUNTER_SIZE = 8,
		  SCALER_SIZE = 8,
		  DATASIZE = 16,
		  MATRIX_SIZE = 4;
		  
		  
//multiplier
output reg mult_select,mult_readwrite,mult_reset_l;
input wire mult_done;

//adder fluffy
output reg add_select,add_readwrite,add_reset_l,addsub;
input wire add_done;

//transpose fluffy
output reg trans_select,trans_readwrite,trans_reset_l;
input wire trans_done;

//counter for results pointer
output reg [COUNTER_SIZE-1:0]cnt_result_offset,cnt_opcode_offset;
input wire [COUNTER_SIZE-1:0]result_pointer,opcode_pointer;
output reg pointers_resetl;

//Memory and reg fluffy
inout wire mem_select, mem_readwrite,
			reg_select, reg_readwrite;
inout wire [ADDRESS_SIZE-1:0]address;

reg 		mem_selecto, mem_readwriteo,
			reg_selecto, reg_readwriteo;
reg 	   [ADDRESS_SIZE-1:0]addresso;

input wire mem_done,reg_done;


//shared stuff
inout wire [MEMORY_SIZE-1:0] databus;
reg  [MEMORY_SIZE-1:0] dataout,OPCODE;
reg en_sel_pins,readwrite;
output reg ab_select;

input wire	clk,
			enable;// turns on the Enigne
			
assign databus = readwrite ? dataout : 'bz;
assign mem_select = en_sel_pins ? mem_selecto : 'bz;
assign reg_select = en_sel_pins ? reg_selecto : 'bz;
assign mem_readwrite = en_sel_pins ? mem_readwriteo : 'bz;
assign reg_readwrite = en_sel_pins ? reg_readwriteo : 'bz;
assign address = en_sel_pins ? addresso : 'bz;

initial
begin
	trans_select <= 0;
	mult_select <=0;
	mem_selecto <=0;
	mult_select <=0;
	reg_selecto <=0;
	add_select <= 0;
end
initial
	begin
		en_sel_pins <= 0;
		readwrite <= 0;
		cnt_opcode_offset <= 0;
		cnt_result_offset <= 0;
		mult_readwrite <=0;
		ab_select <=0; 
		mult_reset_l <=1;
		mem_readwriteo <=0;
		addresso <=0;
		reg_readwriteo <=0;
		pointers_resetl <=1;
		OPCODE <= 0;
		add_readwrite <= 0;
		add_reset_l <= 1;
		addsub <= 1;
		trans_readwrite <= 0;
		trans_reset_l <= 1;
		
	end

always @ opcode_pointer
	cnt_opcode_offset = 0;
always @ result_pointer
	cnt_result_offset = 0;
always @ enable
	en_sel_pins = enable;
always @ (posedge clk)
begin
	if(enable)
	begin
	
		if( OPCODE == 0 )
		begin
			Get_Next_Opcode(opcode_pointer);
				case(OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-OPCODE_SIZE):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE+1))])
				OP_MULTI :
				begin
					Multiplication(0);
				end
				OP_ADD:
				begin
					Addition(1);
				end
				OP_SUB:
				begin
					Addition(0);
				end
				OP_TRANS:
				begin
					Transpose();
				end
				OP_SCALE:
				begin
				Multiplication(1);
				end
				OP_STOP :
				begin
					$display("OpCode Stop");
					mult_reset_l = 0;
					addresso  = 'hz;
				end
			endcase
		end
		
	end
end
task Multiplication(input scaler);
	begin
		$display("Op code mult");
		ab_select = 0;
		addresso = From_Where(OPCODE,ab_select);
		#2 $display("Address %b",From_Where(OPCODE,ab_select));
		Select_MemReg(ab_select);
		mult_readwrite = 1;
		wait(mem_done || reg_done);
		mult_select = 1;
		wait(!mem_done || !reg_done);
		#2 mult_select = 0;
		mem_selecto = 0;
		reg_selecto = 0;
		reg_selecto = 0;
		
		ab_select = 1;
		if(scaler == 0)
		begin
			addresso = From_Where(OPCODE,ab_select);
			#2 Select_MemReg(ab_select);
			mult_readwrite = 1;
			wait(mem_done || reg_done);
			mult_select = 1;
			wait(!mem_done || !reg_done);
			#2 mult_select = 0;
			mem_selecto = 0;
			reg_selecto = 0;
		end
		else if( scaler == 1)
		begin
			readwrite=1;
			dataout = Scaler_Identity(OPCODE);
			mult_readwrite = 1;
			mult_select = 1;
			
			#2 mult_select = 0;
			readwrite = 0;
		end
		addresso = To_Where(OPCODE);
		readwrite =0;
		mult_readwrite=0;
		mult_select=1;
		wait(mult_done);
		Select_MemReg_Write();	
		wait(!mult_done);
		wait(mem_done || reg_done);
		wait(!mem_done || !reg_done);
		#2 mem_selecto = 0;
		reg_selecto = 0;
		mult_select=0;
		
		mult_reset_l = 0;
		mult_reset_l = 1;
	end
endtask
task Addition(input addsubtract);
	begin
		$display("Op code add/sub:  %b",addsubtract);
		ab_select = 0;
		add_reset_l = 1;
		addsub = addsubtract ? 1:0;
		addresso = From_Where(OPCODE,ab_select);
		#2 $display("Address %b",addresso);
		Select_MemReg(ab_select);
		add_readwrite = 1;
		wait(mem_done || reg_done);
		add_select = 1;
		wait(!mem_done || !reg_done);
		#2 add_select = 0;
		mem_selecto = 0;
		reg_selecto = 0;
		add_select = 0;
		
		ab_select = 1;
		addresso = From_Where(OPCODE,ab_select);
		$display("Address %b",addresso);
		
		Select_MemReg(ab_select);
		#4 add_readwrite = 1;
		wait(mem_done || reg_done);
		add_select = 1;
		wait(!mem_done || !reg_done);
		#2 add_select = 0;
		mem_selecto = 0;
		reg_selecto = 0;
		
		addresso = To_Where(OPCODE);
		add_readwrite=0;
		add_select=1;
		wait(add_done);
		
		Select_MemReg_Write();
		wait(!add_done);
		wait(mem_done || reg_done);
		wait(!mem_done || !reg_done);
		#2 mem_selecto = 0;
		reg_selecto = 0;
		add_select=0;
		trans_select=0;
		mult_select = 0;
		add_reset_l = 0;
		add_reset_l = 1;

	end
endtask

task Transpose;
	begin
		$display("Op code trans",);
		ab_select = 0;
		trans_reset_l = 1;
		addresso = From_Where(OPCODE,ab_select);
		#2 $display("Address %b",addresso);
		mem_readwriteo = 0;
		mem_selecto = 1;
		trans_readwrite = 1;
		wait(mem_done || reg_done);
		trans_select = 1;
		wait(!mem_done || !reg_done);
		#2 trans_select = 0;
		mem_selecto = 0;
		reg_selecto = 0;
		trans_select = 0;
	
		addresso = To_Where(OPCODE);
		#2 $display("Address %b",addresso);
		trans_readwrite=0;
		trans_select=1;
		wait(trans_done);
		
		Select_MemReg_Write();
		wait(!trans_done);
		wait(mem_done || reg_done);
		mem_selecto = 0;
		reg_selecto = 0;
		wait(!mem_done || !reg_done);
		trans_select=0;
		mult_select = 0;
		trans_reset_l = 0;
		trans_reset_l = 1;

	end
endtask

function [ADDRESS_SIZE-1:0]From_Where;
input [MEMORY_LENGTH-1:0] opcode;
input matrix_select;
reg [ADDRESS_SIZE-1:0] memloc;
    begin
		case(matrix_select == 0 ? OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE+1))]
								: OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE+1))])
			OP_FROM_MEMORY:
			begin
				memloc = ADDRESS_PG_MATRIX;
			end
			OP_FROM_REGISTER:
			begin
				memloc = 0;
			end
			
			OP_FROM_MEM_RESULT:
			begin
				memloc = ADDRESS_PG_RESULTS;
			end
			
			default:
			begin
					//register_select = 0;
					//memory_select = 1;
			end
		endcase
		From_Where = (matrix_select == 0 ? OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE+1))]			
												  : OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE+1))])
												  + memloc ;
	end
endfunction

task Select_MemReg(input matrix_select);
	begin

		case(matrix_select == 0 ? OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE+1))]
								: OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE+1))])
			OP_FROM_MEMORY:
			begin
			$display("from matrix pin");
				mem_readwriteo = 0 ;
				mem_selecto =  1 ;
			end
			OP_FROM_MEM_RESULT:
			begin
			$display("from results pin");
				mem_readwriteo = 0 ;
				mem_selecto =  1 ;
			end
			OP_FROM_REGISTER:
			begin
			$display("from reg pin");
				reg_readwriteo =  0 ;
				reg_selecto =  1 ;
			end
			default
				$display("Stuff2");
		endcase
	end
endtask


task Select_MemReg_Write;
	begin
	// [OPCODE_COMMAND_SIZE:OPCODE_FROM_SIZE:COUNTER:OPCODE_FROM_SIZE:COUNTER:OPCODE_TO_SIZE]
		//		3				 2         			 8          2      		 8       2
		case(OPCODE[1:0])
			OP_TO_MEMORY:
			begin
			$display("to mem wr");
				mem_readwriteo = 1 ;
				mem_selecto =  1 ;
			end
			OP_TO_MEM_RESULT:
			begin
			$display("to results wr");
				mem_readwriteo = 1 ;
				mem_selecto =  1 ;
			end
			OP_TO_REG_AND_MEM_RESULT:
			begin
				mem_readwriteo = 1 ;
				mem_selecto =  1 ;
				mem_readwriteo = 1 ;
				mem_selecto =  1 ;
			end
			OP_TO_REGISTER:
			begin
			$display("to reg wr");
				reg_readwriteo =  1 ;
				reg_selecto =  1 ;
			end

		endcase
		OPCODE = 0;
	end
endtask

function  [ADDRESS_SIZE-1:0]To_Where;
input [MEMORY_LENGTH-1:0] opcode;
 begin
 	case(opcode[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_FROM_SIZE-COUNTER_SIZE-OPCODE_TO_SIZE+1))])
		OP_TO_MEM_RESULT:
		begin
			$display("to Result");
			
			To_Where = ADDRESS_PG_RESULTS + result_pointer;	
			
		end
		OP_TO_REGISTER:
			begin
				$display("to register");
				To_Where = 0;
			end
		OP_TO_REG_AND_MEM_RESULT:
			begin
				$display("To both");
				To_Where = ADDRESS_PG_RESULTS + result_pointer;	
			end
		default:
			begin
					$display("default");
			end
	endcase
	cnt_result_offset = 1;

end
endfunction


function [MEMORY_LENGTH-1:0]Scaler_Identity;
input [MEMORY_LENGTH-1:0] opcode;
reg [SCALER_SIZE-1:0]scaler;
begin	// [OPCODE_COMMAND_SIZE:OPCODE_FROM_SIZE:COUNTER:OPCODE_FROM_SIZE:COUNTER:OPCODE_TO_SIZE]
		//		3				 2         			 8          2      		 8       2
	scaler = opcode[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-2*OPCODE_FROM_SIZE-COUNTER_SIZE)):MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE-OPCODE_COMMAND_SIZE-2*OPCODE_FROM_SIZE-2*COUNTER_SIZE+1))];
	
	Scaler_Identity = 0+(scaler<< (MEMORY_LENGTH-DATASIZE))+(scaler<< (MEMORY_LENGTH-2*DATASIZE-MATRIX_SIZE*DATASIZE))+(scaler<< (MEMORY_LENGTH-3*DATASIZE-2*MATRIX_SIZE*DATASIZE))+(scaler<< (MEMORY_LENGTH-4*DATASIZE-3*MATRIX_SIZE*DATASIZE));
	$display("scaler %h",Scaler_Identity);
end
endfunction
task Get_Next_Opcode(input [COUNTER_SIZE-1:0]count);
	begin
	    $display("get opcode");
		mult_select = 0;
		readwrite =0;
		addresso = ADDRESS_PG_OPCODE  + count;
		$display("Address : %b",addresso);
		mem_selecto = 1;
		mem_readwriteo = 0;
		wait(mem_done);
		OPCODE = databus;
		cnt_opcode_offset = 1;
		$display("OPCODE %b",OPCODE[MEMORY_LENGTH-(MEMORY_LENGTH-(OPCODE_SIZE)):0]);
		wait(!mem_done);
		mem_selecto = 0;
		
	end
endtask

endmodule
