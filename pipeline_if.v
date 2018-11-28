`timescale 1ns / 1ps
`include "define.v"
//Fetch Instruction
//Simulation version
module pipeline_if(
  input wire clk,
  input wire rst,
  input wire [`MemAddrWidth-1:0] pc_i,
  output reg[`MemAddrWidth-1:0] pc_o,
  output reg[`InstWidth-1:0] inst_o,

  input wire[4:0] flush_i,
  output wire     stall_o,
  input wire[4:0] stall_i,

  
  //To RAM
  input wire[`DataBus]    ram_data_i,
  output wire[`MemAddrBus]  ram_addr_o,

  output wire          ram_re_o,
  input wire          ram_busy_i,
  input wire          ram_done_i,

  //From Ex_Mem
  input wire[1:0]     ex_mem_op_i

  );

   reg [4:0] 		  state;
   
   reg [`InstWidth-1:0] inst_pending;
   
   reg [`MemAddrBus] 	pc_pending;
   wire [`InstWidth-1:0] 	cur_inst;
   reg [`MemAddrBus] 		cur_pc; 		
   reg 					branch_sent;
   //assign cur_inst = branch_sent ? `ZeroWord : rom_data_i;
   wire [6:0] 			opcode = cur_inst[6:0];
   reg 					stall_rom;
   wire 				branch_trig = (opcode == 7'b1101111 || opcode == 7'b1100111 || opcode == 7'b1100011);
   reg 					waiting_branch;
   reg 					reading;
   
   reg [`InstWidth-1:0] inst_buf;
   reg 					stalled;		
   //reg 					reading;					
   reg 					branch_waiting;					
   //assign cur_pc = stalled?pc_pending:pc_i;
   localparam
	 IDLE=5'b00001,
	 READING=5'b00010,
	 FINISH=5'b0100,
	 BRANCH=5'b01000;
   assign cur_inst = (state == FINISH) ? inst_pending:ram_data_i;
   assign ram_addr_o = pc_i;
   assign ram_re_o = (!stall_i[1]) &&
					 (!ram_busy_i) &&
					 (!ram_done_i || !branch_trig) &&
					 (state != BRANCH || ex_mem_op_i == `OpTypeBranch);
   assign stall_o = (ram_busy_i) ||
					(ram_done_i && branch_trig) || 
					(state == BRANCH && ex_mem_op_i !=`OpTypeBranch);


   always @(posedge clk) begin
	  if (rst) begin
		 state <= READING;
		 pc_o <= `ZeroWord;
		 inst_o <= `ZeroWord;
		 reading <= 1'b0;
	  end else if (stall_i[1]) begin
		 pc_o <= pc_o;
		 inst_o <= inst_o;
		 if (state==READING && ram_done_i) begin
			state <= FINISH;
			inst_pending <= ram_data_i;
		 end
	  end else begin
		 case (state)
		   //IDLE:begin
		//	  pc_pending <= pc_i;
		//	  state <= READING;
		//	  pc_o <= `ZeroWord;
		//	  inst_o <= `ZeroWord;
		  // end
		   READING:begin
			  if (ram_done_i) begin
				 if (reading) begin
					if (branch_trig) begin
					   state <= BRANCH;
					end
					pc_pending <= pc_i;
					pc_o <= pc_pending;
					inst_o <= ram_data_i;
				 end else begin
					reading <= 1'b1;
					pc_pending <= pc_i;
					pc_o <= `ZeroWord;
					inst_o <= `ZeroWord;
				 end // else: !if(reading)
			  end else begin
				 pc_o <= pc_o;
				 inst_o <= `ZeroWord;
			  end
		   end // case: READING
		   FINISH:begin
			  if (branch_trig) begin
				 state <= BRANCH;
			  end else begin
				 state <= READING;
			  end
			  pc_pending <= pc_i;
			  pc_o <= pc_pending;
			  inst_o <= inst_pending;
		   end
		   BRANCH:begin
			  pc_o <= pc_o;
			  inst_o <= `ZeroWord;
			  if (ex_mem_op_i == `OpTypeBranch) begin
				 pc_pending <= pc_i;
				 state <= READING;
			  end
		   end
		 endcase
	  end
   end

   
/* -----\/----- EXCLUDED -----\/-----
   always @(posedge clk) begin
	  if (rst) begin
		 inst_o <= `ZeroWord;
		 pc_o <= `ZeroWord;
		 pc_pending <= `ZeroWord;
		 stalled <= 1'b0;
		 branch_waiting <= 1'b0;
		 reading <= 1'b0;
		 inst_pending <= `ZeroWord;
	  end else if (stall_i[1]) begin
		 inst_o <= inst_o;
		 pc_o <= pc_o;
		 if (ram_done_i) begin
			//pc_pending <= pc_i;
			inst_pending <= ram_data_i;
			stalled <= 1'b1;
		 end
	  end else begin
		 //reading <= 1'b1;
		 if (ram_done_i) begin
			reading <= 1'b1;
			if (branch_trig) begin
			   branch_waiting <= 1'b1;
			   stalled <= 1'b0;
			   inst_pending <= `ZeroWord;
			end else begin 
			   pc_pending <= pc_i;
			   stalled <= 1'b0;
			end 
			
			pc_o <= pc_pending;
			inst_o <= (reading)?cur_inst:`ZeroWord;
		 end else begin // if (ram_done_i)
			if (branch_waiting) begin
			   if (ex_mem_op_i == `OpTypeBranch) begin
				  pc_pending <= pc_i;
				  pc_o <= pc_pending;
				  inst_o <= `ZeroWord;
				  stalled <= 1'b0;
				  branch_waiting <= 1'b0;
			   end else begin
				  pc_o <= pc_pending;
				  inst_o <= `ZeroWord;
			   end
			end else begin // if (branch_waiting)
			   pc_o <= pc_pending;
			   inst_o <= `ZeroWord;
			end 
		 end
	  end
   end
 -----/\----- EXCLUDED -----/\----- */
  
endmodule
