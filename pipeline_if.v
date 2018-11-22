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
   assign cur_inst = stalled?inst_pending:ram_data_i;
   //assign cur_pc = stalled?pc_pending:pc_i;
   localparam
	 IDLE=5'b00001,
	 WAITING=5'b00010,
	 READING=5'b00100,
	 FINISH=5'b01000,
	 BRANCH=5'b10000;
   assign ram_addr_o = pc_i;
   assign ram_re_o = (!stall_i[1]) && (!ram_busy_i) && (!ram_done_i || !branch_trig) && (!branch_waiting || ex_mem_op_i == `OpTypeBranch);
   assign stall_o = (ram_busy_i) || (ram_done_i && branch_trig) || (branch_waiting && ex_mem_op_i!=`OpTypeBranch);
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
		 if (ram_done_i && !branch_waiting) begin
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
   /* -----\/----- EXCLUDED -----\/-----
	always @(posedge clk) begin

	    if (rst) begin
      waiting_branch <= 1'b0;
    end else begin
      if (branch_stall_trig) 
        waiting_branch <= 1'b1;
      else if (ex_mem_op_i == `OpTypeBranch)
        waiting_branch <= 1'b0;
      else
        waiting_branch <= waiting_branch;
    end
  end

  always @(*) begin
    if (rst == `Enable) begin
      rom_addr_o = `ZeroWord;
      rom_re_o = `Disable;
      cur_inst = `ZeroWord;
      stall_rom = `Disable;
    end else begin
      rom_addr_o = pc;
      if (rom_done_i == `Enable && reading==1'b1) begin
        cur_inst = rom_data_i;
        stall_rom = `Disable;
        rom_re_o = `Disable;
      end else if (rom_busy_i == `Disable) begin
        cur_inst = `ZeroWord;
        stall_rom = `Enable;
        rom_re_o = ~stall_i[1];
      end else begin
        cur_inst = `ZeroWord;
        stall_rom = `Enable;
        rom_re_o = ~stall_i[1];
      end
    end
  end

  assign stall_o = (branch_stall_trig | waiting_branch) | stall_rom;
   reg stalled;
  always @(posedge clk) begin
    if (rst == `Enable || flush_i[0] == `Enable) begin
       inst_o <= `ZeroWord;
       pc_o <= `ZeroWord;
	   stalled <= 1'b0;
	   reading <= 1'b0;
    end else if (stall_i[1] == `Enable ) begin
       inst_o <= inst_o;
       pc_o <= pc_o;
	   pc_pending<=pc_pending;
	   
	   if (rom_done_i) begin
		  inst_buf <= cur_inst;
		  stalled <=1'b1;
	   end
    end else if (stall_i[0] == `Enable) begin
       if (branch_stall_trig)
         inst_o <= cur_inst;
       else 
         inst_o <= `ZeroWord;
	   reading <= 1'b1;
       pc_o <= pc_o;
    end else begin
       inst_o <= stalled ? inst_buf:cur_inst;
       pc_o <= pc;
	   stalled <= 1'b0;
	   reading <= 1'b0;
    end

  end
 -----/\----- EXCLUDED -----/\----- */
endmodule
