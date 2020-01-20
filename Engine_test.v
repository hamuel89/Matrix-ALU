module Engine_Test;

parameter SCALER = 42;
parameter 	OP_ADD = 3'b001, 
			OP_SUB = 3'b010,
			OP_MULTI = 3'b011,
			OP_SCALE = 3'b100,
			OP_TRANS = 3'b101,
			OP_STOP = 3'b111;

parameter 	OP_FROM_MEMORY  = 2'b01, 
			OP_FROM_REGISTER = 2'b10,
			OP_FROM_MEM_RESULT = 2'b11;

parameter 	OP_TO_MEM_RESULT = 2'b00,
			OP_TO_MEMORY   = 2'b01, 
			OP_TO_REGISTER = 2'b10,
			OP_TO_REG_AND_MEM_RESULT = 2'b11;
//OpCODE sizing/type)
// [OPCODE_COMMAND_SIZE:OPCODE_TO:COUNTER:OPCODE_TO:COUNTER:OP_FROM]
//		3				 2          8          2       8      2
// Will fix Counter size later
parameter ADDRESS_PG_OPCODE = 2'b01,
		  ADDRESS_PG_MATRIX = 2'b10,
		  ADDRESS_PG_RESULTS = 2'b11;			
			
parameter ADDRESS_SIZE = 6,
		  MEMORY_SIZE = 256, 
		  COUNTER_SIZE = 8,
		  POINTER_SIZE = 4,
		  OPCODE_SIZE = 24,
		  OPCODE_FROM_SIZE = 2,
		  OPCODE_TO_SIZE = 2,
		  OPCODE_COMMAND_SIZE = 3;
		  
// MATRIX1 1 rolling and 2 for assigment
reg [MEMORY_SIZE-1:0]MATRIX1 = ((((((((((((((((0+16'd4<<16) + 16'd12<<16) + 16'd4<<16) + 16'd34 <<16) +
								  16'd7 <<16) + 16'd6<<16) + 16'd11<<16) + 16'd9 <<16) +
		                          16'd9 <<16) + 16'd2<<16) + 16'd8 <<16) + 16'd13 <<16) +
		                          16'd2 <<16) + 16'd15<<16) + 16'd16 <<16) + 16'd3),
					 MATRIX2=((((((((((((((((0+16'd23<<16) + 45<<16) + 67 <<16) + 22 <<16) +
								  7 <<16) + 6<<16) + 4 <<16) + 1 <<16) +
		                          18 <<16) + 56<<16) + 13 <<16) + 12 <<16) +
		                          3 <<16) + 5<<16) + 7 <<16) + 9);

reg [COUNTER_SIZE-1:0]count_for_loading;



//memory fluffy
wire mem_select,mem_readwrite,mem_done,mult_reset_l;
//register fluffy
wire reg_select,reg_readwrite,reg_done;

//multiplier fluffy
wire mult_done,mult_select,mult_readwrite;
wire add_done,add_select,add_readwrite,addsub,add_reset_l;
//transpose
wire trans_done,trans_select,trans_readwrite,trans_reset_l;
//counters
wire [COUNTER_SIZE-1:0]cnt_result_offset,result_pointer,cnt_opcode_offset,opcode_pointer;
wire cnt_reset_l;

//shared wires/regs
wire [MEMORY_SIZE-1:0]databus;
reg  [MEMORY_SIZE-1:0]DataOut;

wire [ADDRESS_SIZE-1:0]address;
wire ab_select;
reg clk, 
	enable,
	enable_engine,
	readwrite; // 1 turns on engine 0 turns it off
//for loading matrix and opcodes into memory
reg  [ADDRESS_SIZE-1:0]addressout;
reg load,mem_load_rw,mult_load_rw,
	mem_load_sel,reg_load_sel,mult_load_sel;
			  
Engine engine(mult_done,mult_select,mult_readwrite,ab_select,mult_reset_l,
			   add_done,add_select,add_readwrite,ab_select,addsub,add_reset_l,
			   trans_done,trans_select,trans_readwrite,trans_reset_l,
			       mem_select, mem_readwrite, address,mem_done,
			       reg_select,reg_readwrite,reg_done,
				   cnt_result_offset,result_pointer,
				   cnt_opcode_offset,opcode_pointer,
			       databus,cnt_reset_l,
				   clk,enable_engine);
SystemMemory mem(databus, mem_done, address,mem_select, mem_readwrite,enable, clk);
SystemReg       Reg(databus, reg_done, reg_select, reg_readwrite,enable, clk);
multiplier      mult(databus,mult_done,mult_select,mult_readwrite,ab_select, mult_reset_l,enable,clk);
Adder           add(databus,add_done,add_select,add_readwrite,ab_select,addsub,add_reset_l,enable,clk);
Transpose       trans(databus,trans_done,trans_select,trans_readwrite,trans_reset_l,enable,clk);
counter         result(result_pointer, cnt_result_offset,cnt_reset_l,enable, clk);   
counter         opcode(opcode_pointer, cnt_opcode_offset,cnt_reset_l,enable, clk);   
// For tristating
assign databus = readwrite ? DataOut : 'bz;
assign address = load ? addressout : 'bz;
assign mem_readwrite = load ? mem_load_rw : 'bz;
assign mult_readwrite = load ? mult_load_rw : 'bz;
assign mem_select = load ? mem_load_sel : 'bz;
assign reg_select = load ? reg_load_sel : 'bz;
assign mult_select = load ? mult_load_sel : 'bz;


initial
	begin
		enable_engine =0;
		enable = 0;
		DataOut = 'bz;
		count_for_loading=0;
		clk = 1;
		forever #2 clk = !clk;
	end
	

initial
	begin
	    #1 enable = 1;
		load_opcodes();
		load_matrix();
		#2 enable_engine = 1;
	end
	

//TASK TO LOAD MATRIX 1 and 2 for multi assigment
task load_matrix();
	begin
		  
		load = 1;
		reg_load_sel = 0;
		mult_load_sel = 0;
		mem_load_rw = 1;
		readwrite =1;
		count_for_loading=0;
		
		addressout = (ADDRESS_PG_MATRIX<<4) + count_for_loading;
		DataOut = MATRIX1;
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		
		addressout = (ADDRESS_PG_MATRIX<<4) + count_for_loading;
		DataOut = MATRIX2;
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		readwrite = 0;
		load = 0;
	end
endtask
// Reads just Matrix back.
task read_matrix();
	begin
		load = 1;
		readwrite <= 0;
		reg_load_sel <= 0;
		#2 mem_load_rw = 0;
		for(count_for_loading = 0; count_for_loading <2; count_for_loading = count_for_loading +1)
		begin
			addressout = (ADDRESS_PG_MATRIX<<4) + count_for_loading;
			#1 mem_load_sel = 1;
			wait(mem_done);
			mem_load_sel = 0;
			wait(!mem_done);
		end
		load = 0;
		mem_load_rw = 0;
		readwrite = 0;
		addressout = 'bz;
	end
endtask
//read OPCODES BACK
task read_opcodes();
	begin
		load = 1;
		readwrite = 0;
		reg_load_sel = 0;
		#2 mem_load_rw = 0;
		for(count_for_loading = 0; count_for_loading <6; count_for_loading = count_for_loading +1)
		begin
			addressout = (ADDRESS_PG_OPCODE<<4) + count_for_loading;
			mem_load_sel = 1;
			wait(mem_done);
			mem_load_sel = 0;
			wait(!mem_done);
		end
		load = 0;
		addressout = 'bz;
	end
endtask
//Task to load OPCODE for MULTI Project
task load_opcodes();
	begin
		load = 1;
		reg_load_sel = 0;
		mult_load_sel = 0;
		mult_load_rw = 0;
		mem_load_rw = 1;
		readwrite =1;
		
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = ((((((((((0+OP_ADD)<< OPCODE_FROM_SIZE)+OP_FROM_MEMORY)<<COUNTER_SIZE)+ 8'b0<<OPCODE_FROM_SIZE)+OP_FROM_MEMORY)<<COUNTER_SIZE)+ 8'b1)<<OPCODE_TO_SIZE)+OP_TO_MEM_RESULT);
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		
		mem_load_rw = 1;
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = ((((((((((0+OP_SUB)<< OPCODE_FROM_SIZE)+OP_FROM_MEM_RESULT)<<COUNTER_SIZE)+ 8'b0<<OPCODE_FROM_SIZE)+OP_FROM_MEMORY)<<COUNTER_SIZE)+ 8'b0)<<OPCODE_TO_SIZE)+OP_TO_MEM_RESULT);
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		
		
		mem_load_rw = 1;
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = ((((((((((0+OP_TRANS)<< OPCODE_FROM_SIZE)+OP_FROM_MEM_RESULT)<<COUNTER_SIZE)+ 8'b1<<OPCODE_FROM_SIZE)+2'b00)<<COUNTER_SIZE)+ 8'b0)<<OPCODE_TO_SIZE)+OP_TO_MEM_RESULT);
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		
		mem_load_rw = 1;
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = ((((((((0+OP_SCALE)<< OPCODE_FROM_SIZE)+OP_FROM_MEM_RESULT)<<COUNTER_SIZE)+ 8'b10<<OPCODE_FROM_SIZE+COUNTER_SIZE)+ SCALER)<<OPCODE_TO_SIZE)+OP_TO_REGISTER);
		$display("%b",((((((((0+OP_SCALE)<< OPCODE_FROM_SIZE)+OP_FROM_MEM_RESULT)<<COUNTER_SIZE)+ 8'b10<<OPCODE_FROM_SIZE+COUNTER_SIZE)+ SCALER)<<OPCODE_TO_SIZE)+OP_TO_REGISTER));
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		mem_load_rw = 1;
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = ((((((((((0+OP_MULTI)<< OPCODE_FROM_SIZE)+OP_FROM_REGISTER)<<COUNTER_SIZE)+ 8'b11<<OPCODE_FROM_SIZE)+OP_FROM_MEM_RESULT)<<COUNTER_SIZE)+ 8'b10)<<OPCODE_TO_SIZE)+OP_TO_MEM_RESULT);
		#1 mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		
		mem_load_rw = 1;
		addressout = (ADDRESS_PG_OPCODE<<POINTER_SIZE) + count_for_loading;
		DataOut = (OP_STOP)<< OPCODE_SIZE-OPCODE_COMMAND_SIZE+1;
		mem_load_sel = 1;
		wait(mem_done);
		mem_load_sel = 0;
		count_for_loading = count_for_loading +1;
		wait(!mem_done);
		mem_load_rw = 0;
		
		load = 0;
		readwrite = 0;
	end
endtask

endmodule