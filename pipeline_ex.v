`timescale 1ns / 1ps
`include "define.v"

module pipeline_ex
(
  input wire 				   clk,
  input wire 				   rst,

  input wire [`DataBus] 	   val1_i,
  input wire [`DataBus] 	   val2_i,
  input wire [`DataBus] 	   imm_i,
  input wire [`RegAddrBus] 	   rd_i,
  input wire 				   we_i,
  input wire [1:0] 			   optype_i,
  input wire [`OpSelWidth-1:0] opsel_i,

  //For forwarding
  input wire [`RegAddrBus] 	   rs1_i,
  input wire 				   rs1_e_i,
  input wire [`RegAddrBus] 	   rs2_i,
  input wire 				   rs2_e_i,

  //For forwarding from mem step
  input wire [`RegAddrBus] 	   mem_rd_i,
  input wire 				   mem_we_i,
  input wire [`DataBus] 	   mem_wdata_i,

  output reg [`RegAddrBus] 	   rd_o,
  output reg 				   we_o,
  output reg [`DataBus] 	   wdata_o,
 
  output reg [1:0] 			   mre_o,
  output reg 				   mrsign_o, 
  output reg [1:0] 			   mwe_o,
  //output reg [`RegAddrBus] 	   mrs_o, 
  output reg [`DataBus] 	   mwdata_o,
  output reg [`MemAddrBus] 	   ma_o, 
				
  input wire [`MemAddrBus] 	   pc_i,
  output reg [`MemAddrBus] 	   set_pc_o,
  output reg 				   set_pc_e_o,

  input wire [4:0] 			   stall_i,
  output wire 				   stall_o, 
  output reg [1:0] 			   ex_mem_op_o

  );

 localparam
   m_none = 2'b00,
   m_byte = 2'b01,
   m_half = 2'b10,
   m_word = 2'b11;
   
  //Forwarding
  wire [`DataBus] val1;
  wire [`DataBus] val2;
  
  wire val1_f = (we_o & rs1_e_i & (rs1_i == rd_o) & (rs1_i != 5'b0));
  wire val2_f = (we_o & rs2_e_i & (rs2_i == rd_o) & (rs2_i != 5'b0));

  wire val1_f_m = (mem_we_i & rs1_e_i & (rs1_i == mem_rd_i) & (rs1_i != 5'b0));
  wire val2_f_m = (mem_we_i & rs2_e_i & (rs2_i == mem_rd_i) & (rs2_i != 5'b0));

  assign val1 = (val1_f   == 1'b1 ? wdata_o : 
                 val1_f_m == 1'b1 ? mem_wdata_i:val1_i); 
  assign val2 = ((optype_i == `OpTypeALU || opsel_i == `OpJALR)
                   && rs2_e_i == `Disable? imm_i:
                 val2_f   == 1'b1 ? wdata_o : 
                 val2_f_m == 1'b1 ? mem_wdata_i:val2_i); 

  wire [`DataBus] ALU_add = $signed(val1) +  $signed(val2);
  wire [`DataBus] ALU_xor = $signed(val1) ^  $signed(val2);
  wire [`DataBus] ALU_or  = $signed(val1) |  $signed(val2);
  wire [`DataBus] ALU_and = $signed(val1) &  $signed(val2);
  wire [`DataBus] ALU_sll =         val1  <<         val2;
  wire [`DataBus] ALU_srl =         val1  >>         val2;
  wire [`DataBus] ALU_sra = $signed(val1) >>>        val2;
  wire [`DataBus] ALU_slt = $signed(val1) <  $signed(val2);
  wire [`DataBus] ALU_sltu=         val1  <          val2;
  wire [`DataBus] ALU_sub = $signed(val1) -  $signed(val2);

  wire [`DataBus] pc_taken  = pc_i + imm_i;
  wire [`DataBus] pc_ntaken = pc_i + 4;
  wire            BEQ = $signed(val1) == $signed(val2);
  wire            BNE = $signed(val1) != $signed(val2);
  wire            BLT = $signed(val1) <  $signed(val2);
  wire            BGE = $signed(val1) >= $signed(val2);
  wire            BLTU= val1          <  val2;
  wire            BGEU= val1          >= val2;

   wire [`DataBus] mem_addr = val1 + imm_i;
   //wire [`RegAddrBus]
   reg 			   last_load;
   assign stall_o = last_load && (val1_f || val2_f);
   always @(*) begin
      if (rst == `Enable || optype_i != `OpTypeBranch) begin
		 set_pc_o = `ZeroWord;
		 set_pc_e_o = 1'b0;
    end else begin
    case (opsel_i)
      `OpJAL: begin
        set_pc_o = pc_taken;
        set_pc_e_o = `Enable;
      end
      `OpJALR: begin
        set_pc_o = ALU_add;
        set_pc_e_o = `Enable;
      end
      `OpBEQ: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BEQ;
      end
      `OpBNE: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BNE;
      end
      `OpBLT: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BLT;
      end
      `OpBGE: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BGE;
      end
      `OpBLTU: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BLTU;
      end
      `OpBGEU: begin
        set_pc_o = pc_taken; 
        set_pc_e_o = BGEU;
      end
      endcase      
    end
  end

  always @(posedge clk) begin
    if (rst == `Enable || (stall_i[2] == `Enable && stall_i[3]==`Disable)) begin
       rd_o <= 5'b0;
       we_o <= `Disable;
       wdata_o <= `ZeroWord;
       ex_mem_op_o <= 2'b00;
	   
	   mre_o <= m_none;
	   mwe_o <= m_none;
	   mrsign_o <= 1'b0;
	   //mrs_o <= 5'b0;
	   mwdata_o <= `ZeroWord;
	   ma_o <= `ZeroWord;
	   last_load <= 1'b0;
    end else if (stall_i[3]==`Enable) begin
       rd_o <= rd_o;
       we_o <= we_o;
       wdata_o <= wdata_o;    
       ex_mem_op_o <= ex_mem_op_o;
	   
	   mre_o <= mre_o;
	   mwe_o <= mwe_o;
	   mrsign_o <= mrsign_o;
	   //mrs_o <= mrs_o;
	   mwdata_o <= mwdata_o;
	   ma_o <= ma_o;
    end else begin
       ex_mem_op_o<= optype_i;
       case (optype_i)
		 `OpTypeALU: begin
			rd_o <= rd_i;
			we_o <= 1'b1;

			mre_o <= m_none;
			mwe_o <= m_none;
			mrsign_o <= 1'b0;
			//mrs_o <= 5'b0;
			mwdata_o <= `ZeroWord;
			ma_o <= `ZeroWord;
			last_load <= 1'b0;
			case (opsel_i)
			  `OpADD: wdata_o <= ALU_add;
			  `OpXOR: wdata_o <= ALU_xor;
			  `OpOR:  wdata_o <= ALU_or;
			  `OpAND: wdata_o <= ALU_and;
			  `OpSLL: wdata_o <= ALU_sll;
			  `OpSRL: wdata_o <= ALU_srl;
			  `OpSRA: wdata_o <= ALU_sra;
			  `OpSLT: wdata_o <= ALU_slt;
			  `OpSLTU:wdata_o <= ALU_sltu;
			  `OpSUB: wdata_o <= ALU_sub;
			  `OpLUI: wdata_o <= val2;
			  `OpAUIPC: wdata_o <= ALU_add;
			  default: wdata_o <= `ZeroWord;			  
			endcase
		 end
		 `OpTypeBranch: begin
			mre_o <= m_none;
			mwe_o <= m_none;
			mrsign_o <= 1'b0;
			//mrs_o <= 5'b0;
			mwdata_o <= `ZeroWord;
			ma_o <= `ZeroWord;
			last_load <= 1'b0;
			case (opsel_i)
			  `OpJAL: begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 wdata_o <= pc_ntaken;
			  end
			  `OpJALR: begin
				 rd_o <= rd_i;
				 we_o <= `Enable;
				 wdata_o <= pc_ntaken;
			  end
			  `OpBEQ: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			  `OpBNE: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			  `OpBLT: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			  `OpBGE: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			  `OpBLTU: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			  `OpBGEU: begin
				 rd_o <= 5'b0;
				 we_o <= `Disable;
				 wdata_o <= `ZeroWord;
			  end
			endcase
		 end // case: `OpTypeBranch
		 `OpTypeLS:begin
			case (opsel_i)
			  `OpLB:begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 mre_o <= m_byte;
				 mrsign_o <= 1'b1;
				 mwe_o <= m_none;
				 //mrs_o <= 5'b0;
				 mwdata_o <= `ZeroWord;
				 ma_o <= mem_addr;
				 last_load <= 1'b1;
			  end
			  `OpLH:begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 mre_o <= m_half;
				 mrsign_o <= 1'b1;
				 mwe_o <= m_none;
				 //mrs_o <= 5'b0;
				 mwdata_o <= `ZeroWord;
				 ma_o <= mem_addr;
				 last_load <= 1'b1;
			  end
			  `OpLW:begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 mre_o <= m_word;
				 mrsign_o <= 1'b1;
				 mwe_o <= m_none;
				 //mrs_o <= 5'b0;
				 mwdata_o <= `ZeroWord;
				 ma_o <= mem_addr;
				 last_load <= 1'b1;
			  end
			  `OpLBU:begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 mre_o <= m_byte;
				 mrsign_o <= 1'b0;
				 mwe_o <= m_none;
				 //mrs_o <= 5'b0;
				 mwdata_o <= `ZeroWord;
				 ma_o <= mem_addr;
				 last_load <= 1'b1;
			  end
			  `OpLHU:begin
				 rd_o <= rd_i;
				 we_o <= 1'b1;
				 mre_o <= m_half;
				 mrsign_o <= 1'b0;
				 mwe_o <= m_none;
				 //mrs_o <= 5'b0;
				 mwdata_o <= `ZeroWord;
				 ma_o <= mem_addr;
				 last_load <= 1'b1;
			  end
			  `OpSB:begin
				 rd_o <= 5'b0;
				 we_o <= 1'b0;
				 mre_o <= m_none;
				 mrsign_o <= 1'b0;
				 mwe_o <= m_byte;
				 //mrs_o <= rs2_i;
				 mwdata_o <= val2;
				 ma_o <= mem_addr;
				 last_load <= 1'b0;
			  end
			  `OpSH:begin
				 $display("save half");
				 rd_o <= 5'b0;
				 we_o <= 1'b0;
				 mre_o <= m_none;
				 mrsign_o <= 1'b0;
				 mwe_o <= m_half;
				 //mrs_o <= rs2_i;
				 mwdata_o <= val2;
				 ma_o <= mem_addr;
				 last_load <= 1'b0;
			  end
			  `OpSW:begin
				 rd_o <= 5'b0;
				 we_o <= 1'b0;
				 mre_o <= m_none;
				 mrsign_o <= 1'b0;
				 mwe_o <= m_word;
				 //mrs_o <= rs2_i;
				 mwdata_o <= val2;
				 ma_o <= mem_addr;
				 last_load <= 1'b0;
			  end
			endcase
		 end
		   
		 default:begin
			rd_o <= 5'b0;
			we_o <= `Disable;
			wdata_o <= `ZeroWord;     
			mre_o <= m_none;
			mwe_o <= m_none;
			mrsign_o <= 1'b0;
			last_load <= 1'b0;
			//mrs_o <= 5'b0;
			mwdata_o <= `ZeroWord;
			ma_o <= `ZeroWord;   
		 end
       endcase
    end
  end



endmodule
