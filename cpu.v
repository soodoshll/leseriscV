// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "define.v"
module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

   wire 			 clk = clk_in;
   wire 			 rst = rst_in;
   wire 			 rdy = rdy_in;			 
   wire 			 memctrl_busy;
   wire [`DataBus] 	 memctrl_data;
   wire 			 memctrl_done;
   
   wire 			 if_mem_re;
   wire [`InstWidth-1:0] if_mem_addr;

   wire [1:0] 			 memctrl_re;
   wire 				 memctrl_rsign;
   wire [`MemAddrBus] 	 memctrl_addr;
   wire [1:0] 			 memctrl_we;
   wire [`DataBus] 		 memctrl_wdata;
   
   memctrl memctrl0
	 (.clk(clk_in),
	  .rst(rst_in),
	  .rdy(rdy_in),

	  .if_re_i(if_mem_re),
	  .if_addr_i(if_mem_addr),

	  .mem_re_i(memctrl_re),
	  .mem_rsign_i(memctrl_rsign),
	  .mem_addr_i(memctrl_addr),
	  .mem_we_i(memctrl_we),
	  .mem_wdata_i(memctrl_wdata),
	  
	  .busy_o(memctrl_busy),
	  .data_o(memctrl_data),
	  .done_o(memctrl_done),
	  .ram_data_i(mem_din),
	  .ram_data_o(mem_dout),
	  .ram_addr_o(mem_a),
	  .ram_wr_o(mem_wr)
	  
	  
	  );
//CPU core

   reg [`MemAddrWidth-1:0] pc;
   wire [`MemAddrBus] 	   ex_set_pc;
   wire 				   ex_set_pc_e;
   wire [4:0] 			   flush;
   wire [4:0] 			   stall;
   wire [`MemAddrBus] 	   set_pc;
   wire 				   set_pc_e;
   wire 				   if_stall;
   wire 				   id_stall;
   wire 				   mem_stall;	
			   
   ctrl ctrl0
	 (
	  .rdy(rdy),
	  .set_pc_i(ex_set_pc),
	  .set_pc_e_i(ex_set_pc_e),

	  .set_pc_o(set_pc),
	  .set_pc_e_o(set_pc_e),

	  .flush_o(flush),

	  .if_stall_i(if_stall),
	  .id_stall_i(id_stall),
	  .mem_stall_i(mem_stall),
	  .stall_o(stall)
	  );

   wire [`InstWidth-1:0]   inst;
   always @(posedge clk) begin
      if (!rst) begin
		 if (set_pc_e) 
           pc <= set_pc;
		 else if (stall[0]) 
           pc <= pc;
		 else
           pc <= pc+4;
      end
      else 
		pc <= 0;
   end
   assign dbgreg_dout  = pc;
   wire [`MemAddrBus] if_id_pc;
   wire [1:0] 		  ex_if_op;
   pipeline_if if0
	 (.rst(rst),
	  .clk(clk),
	  .pc_i(pc),
	  .pc_o(if_id_pc),
	  .inst_o(inst),
	  .flush_i(flush),
	  .stall_o(if_stall),
	  .stall_i(stall),

	  .ram_data_i(memctrl_data),
	  .ram_addr_o(if_mem_addr),
	  .ram_re_o(if_mem_re),
	  .ram_busy_i(memctrl_busy),
	  .ram_done_i(memctrl_done),
	  .ex_mem_op_i(ex_if_op)
	  );
   
   wire 			  id_reg_re1;
   wire [`RegAddrBus] id_reg_ra1;
   wire 			  id_reg_re2;
   wire [`RegAddrBus] id_reg_ra2;
   wire [`DataBus] 	  id_reg_val1;
   wire [`DataBus] 	  id_reg_val2;

   wire [`RegAddrBus] wb_reg_rd;
   wire               wb_reg_we;
   wire [`DataBus] 	  wb_reg_wdata;

   regfile reg0(
				.clk(clk),
				.rst(rst),

				.we(wb_reg_we),
				.waddr(wb_reg_rd),
				.wdata(wb_reg_wdata),

				.re1(id_reg_re1),
				.raddr1(id_reg_ra1),
				.rdata1(id_reg_val1),
				.re2(id_reg_re2),
				.raddr2(id_reg_ra2),
				.rdata2(id_reg_val2)
				);

   wire [`DataBus] 	  id_ex_val1;
   wire [`DataBus] 	  id_ex_val2;
   wire [`DataBus] 	  id_ex_imm;
   wire [`RegAddrBus] id_ex_rd;
   wire 			  id_ex_we;
   wire [1:0] 		  id_ex_optype;
   wire [`OpSelWidth-1:0] id_ex_opsel;
   wire [4:0] 			  id_ex_shamt;
   
   wire [`RegAddrBus] 	  id_ex_rs1;
   wire 				  id_ex_rs1_e;
   wire [`RegAddrBus] 	  id_ex_rs2;
   wire 				  id_ex_rs2_e;  

   wire [`MemAddrBus] 	  id_ex_pc;

   pipeline_id id0
	 (.clk(clk),
	  .rst(rst),
	  .inst_i(inst),
	  .stall_i(stall),

	  .val1_i(id_reg_val1),
	  .val2_i(id_reg_val2),
	  .reg_re1_o(id_reg_re1),
	  .reg_ra1_o(id_reg_ra1),
	  .reg_re2_o(id_reg_re2),
	  .reg_ra2_o(id_reg_ra2),

	  .val1_o(id_ex_val1),
	  .val2_o(id_ex_val2),
	  .imm_o(id_ex_imm),
	  .rd_o(id_ex_rd),
	  .we_o(id_ex_we),
	  .optype_o(id_ex_optype),
	  .opsel_o(id_ex_opsel),
	  .shamt_o(id_ex_shamt),
	  
	  .rs1_o(id_ex_rs1),
	  .rs1_e_o(id_ex_rs1_e),
	  .rs2_o(id_ex_rs2),
	  .rs2_e_o(id_ex_rs2_e),

	  
	  .pc_i(if_id_pc),
	  .pc_o(id_ex_pc),
	  .stall_o(id_stall),
	  .flush_i(flush)
	  );

   wire [`RegAddrBus] 	  ex_mem_rd;
   wire 				  ex_mem_we;
   wire [`DataBus] 		  ex_mem_wdata;

   wire [1:0] 			  ex_mem_mre;
   wire 				  ex_mem_mrsign;
   wire [1:0] 			  ex_mem_mwe;
   wire [`DataBus] 		  ex_mem_mwdata;
   wire [`MemAddrBus] 	  ex_mem_ma;
   
   pipeline_ex ex0
	 (.clk(clk),
	  .rst(rst),
	  .stall_i(stall),

	  .val1_i(id_ex_val1),
	  .val2_i(id_ex_val2),
	  .imm_i(id_ex_imm),
	  .rd_i(id_ex_rd),
	  .we_i(id_ex_we),
	  .optype_i(id_ex_optype),
	  .opsel_i(id_ex_opsel),
	  .shamt_i(id_ex_shamt),
	  
	  .rs1_i(id_ex_rs1),
	  .rs1_e_i(id_ex_rs1_e),
	  .rs2_i(id_ex_rs2),
	  .rs2_e_i(id_ex_rs2_e),

	  .mem_rd_i(wb_reg_rd),
	  .mem_we_i(wb_reg_we),
	  .mem_wdata_i(wb_reg_wdata),
	  
	  .rd_o(ex_mem_rd),
	  .we_o(ex_mem_we),
	  .wdata_o(ex_mem_wdata),

	  .mre_o(ex_mem_mre),
	  .mrsign_o(ex_mem_mrsign),
	  .mwe_o(ex_mem_mwe),
	  .mwdata_o(ex_mem_mwdata),
	  .ma_o(ex_mem_ma),
	  
	  .pc_i(id_ex_pc),
	  .set_pc_o(ex_set_pc),
	  .set_pc_e_o(ex_set_pc_e),

	  //.stall_o(ex_stall),
	  .ex_mem_op_o(ex_if_op)
	  );

   //wire [1:0] 			 memctrl_re;
   //wire 				 memctrl_rsign;
   //wire [`MemAddrBus] 	 memctrl_addr;
   //wire [1:0] 			 memctrl_we;
   //wire [`DataBus] 		 memctrl_wdata;
   
   pipeline_mem mem0
	 (.clk(clk),
	  .rst(rst),
	  .stall_i(stall),
	  .rd_i(ex_mem_rd),
	  .we_i(ex_mem_we),
	  .wdata_i(ex_mem_wdata),

	  .rd_o(wb_reg_rd),
	  .we_o(wb_reg_we),
	  .wdata_o(wb_reg_wdata),

	  .mre_i(ex_mem_mre),
	  .mrsign_i(ex_mem_mrsign),
	  .mwe_i(ex_mem_mwe),
	  .mwdata_i(ex_mem_mwdata),
	  .ma_i(ex_mem_ma),
	  
	  .mre_o(memctrl_re),
	  .mrsign_o(memctrl_rsign),
	  .mwe_o(memctrl_we),
	  .mwdata_o(memctrl_wdata),
	  .ma_o(memctrl_addr),

	  .mem_busy_i(memctrl_busy),
	  .mem_data_i(memctrl_data),
	  .mem_done_i(memctrl_done),
	  
	  .mem_stall_o(mem_stall)
	  );

endmodule
