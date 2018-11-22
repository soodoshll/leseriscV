`timescale 1ns / 1ps
`include "define.v"
// module decoder(
//   //input wire clk,
//   // input wire rst,

//   input wire[`InstWidth-1:0] inst_i,

//   output wire[1:0] optype_o,
//   output wire[`OpSelWidth-1:0] opsel_o,

//   output wire[`RegAddrWidth-1:0] rd_o,
//   output wire                    we_o,

//   output wire[`RegAddrWidth-1:0] rs1_addr_o,
//   output wire[`RegAddrWidth-1:0] re1_o,
//   output wire[`RegAddrWidth-1:0] rs2_addr_o,
//   output wire[`RegAddrWidth-1:0] re2_o,

//   output wire[`DataWidth-1:0] imm_o,
//   output wire[4:0] shamt_o
//   );


//   wire [6:0]opcode = inst_i[6:0];
//   wire opcode_0110111 = (opcode == 7'b0110111);
//   wire opcode_0010111 = (opcode == 7'b0010111);
//   wire opcode_1101111 = (opcode == 7'b1101111);
//   wire opcode_1100111 = (opcode == 7'b1100111);
//   wire opcode_1100011 = (opcode == 7'b1100011);
//   wire opcode_0000011 = (opcode == 7'b0000011);
//   wire opcode_0100011 = (opcode == 7'b0100011);
//   wire opcode_0010011 = (opcode == 7'b0010011);
//   wire opcode_0110011 = (opcode == 7'b0110011);

//   wire [2:0]fun3 = inst_i[14:12];
//   wire fun3_000 = (fun3 == 3'b000);
//   wire fun3_001 = (fun3 == 3'b001);
//   wire fun3_010 = (fun3 == 3'b010);
//   wire fun3_011 = (fun3 == 3'b011);
//   wire fun3_100 = (fun3 == 3'b100);
//   wire fun3_101 = (fun3 == 3'b101);
//   wire fun3_110 = (fun3 == 3'b110);
//   wire fun3_111 = (fun3 == 3'b111);

//   wire [6:0]fun7 = inst_i[31:25];
//   wire fun7_0000000 = (fun7 == 7'b0000000);
//   wire fun7_0100000 = (fun7 == 7'b0100000);


//   assign optype_o=({2{opcode_0110111 | opcode_0010111 | opcode_0010011 | 
//                     opcode_0110011}} & 2'b01) |
//                   ({2{opcode_1101111 | opcode_1100111 | opcode_1100011}}
//                     & 2'b10) |
//                   ({2{opcode_0000011 | opcode_0100011}} & 2'b11);

//   wire OpLUI   = (opcode_0110111);
//   wire OpAUIPC = (opcode_0010111);
//   wire OpADD   = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_000;
//   wire OpXOR   = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_100;
//   wire OpOR    = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_110;
//   wire OpAND   = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_111;  
//   wire OpSLL   = (opcode_0010011 || opcode_0110011) && fun7_0000000 && fun3_001;
//   wire OpSRL   = (opcode_0010011 || opcode_0110011) && fun7_0000000 && fun3_101;
//   wire OpSRA   = (opcode_0010011 || opcode_0110011) && fun7_0100000 && fun3_101;
//   wire OpSLT   = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_010;
//   wire OpSLTU  = (opcode_0010011 || (opcode_0110011 && fun7_0000000)) && fun3_011;
//   wire OpSUB   = (opcode_0110011 && fun7_0100000 && fun3_000);  

//   wire OpLB    = opcode_0000011 && fun3_000;
//   wire OpLH    = opcode_0000011 && fun3_001;
//   wire OpLW    = opcode_0000011 && fun3_010;
//   wire OpLBU   = opcode_0000011 && fun3_100;
//   wire OpLHU   = opcode_0000011 && fun3_101;
//   wire OpSB    = opcode_0100011 && fun3_000;
//   wire OpSH    = opcode_0100011 && fun3_001;
//   wire OpSW    = opcode_0100011 && fun3_010;

//   wire OpJAL   = opcode_1101111 ;
//   wire OpBEQ   = opcode_1100011 && fun3_000;
//   wire OpBNE   = opcode_1100011 && fun3_001;
//   wire OpBLT   = opcode_1100011 && fun3_100;
//   wire OpBGE   = opcode_1100011 && fun3_101;
//   wire OpBLTU  = opcode_1100011 && fun3_110;
//   wire OpBGEU  = opcode_1100011 && fun3_111;
//   wire OpJALR  = opcode_1100111;

//   assign opsel_o = ({32{OpLUI}} & `OpLUI)|
//                 ({32{OpAUIPC}} & `OpAUIPC)|
//                 ({32{OpADD}} & `OpADD)|
//                 ({32{OpXOR}} & `OpXOR)|
//                 ({32{OpOR}} & `OpOR)|
//                 ({32{OpAND}} & `OpAND)|
//                 ({32{OpSLL}} & `OpSLL)|
//                 ({32{OpSRL}} & `OpSRL)|
//                 ({32{OpSRA}} & `OpSRA)|
//                 ({32{OpSLT}} & `OpSLT)|
//                 ({32{OpSLTU}} & `OpSLTU)|
//                 ({32{OpSUB}} & `OpSUB)|
//                 ({32{OpLB}} & `OpLB)|
//                 ({32{OpLH}} & `OpLH)|
//                 ({32{OpLW}} & `OpLW)|
//                 ({32{OpSB}} & `OpSB)|
//                 ({32{OpSH}} & `OpSH)|
//                 ({32{OpSW}} & `OpSW)|
//                 ({32{OpLBU}} & `OpLBU)|
//                 ({32{OpLHU}} & `OpLHU)|
//                 ({32{OpJAL}} & `OpJAL)|
//                 ({32{OpBEQ}} & `OpBEQ)|
//                 ({32{OpBNE}} & `OpBNE)|
//                 ({32{OpBLT}} & `OpBLT)|
//                 ({32{OpBGE}} & `OpBGE)|
//                 ({32{OpBLTU}} & `OpBLTU)|
//                 ({32{OpBGEU}} & `OpBGEU)|
//                 ({32{OpJALR}} & `OpJALR);


//   assign  shamt_o = inst_i[24:20];;
//   wire [`DataBus] imm_I = {{21{inst_i[31]}},inst_i[30:20]};
//   wire [`DataBus] imm_S = {{21{inst_i[31]}},inst_i[30:25],inst_i[11:7]};
//   wire [`DataBus] imm_B = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
//   wire [`DataBus] imm_U = {inst_i[31:12],12'b0};
//   wire [`DataBus] imm_J = {{12{inst_i[31]}},inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};


//   wire immsel_I = opcode_0000011 | opcode_0010011 | opcode_1100111;
//   wire immsel_S = opcode_0100011;
//   wire immsel_B = opcode_1100011;
//   wire immsel_U = opcode_0110111 | opcode_0010111;
//   wire immsel_J = opcode_1101111;
//   assign imm_o = ({32{immsel_I}} & imm_I)|
//                ({32{immsel_S}} & imm_S)|
//                ({32{immsel_B}} & imm_B)|
//                ({32{immsel_U}} & imm_U)|
//                ({32{immsel_J}} & imm_J);

//   assign rd_o = inst_i[11:7];
//   assign we_o = opcode_0110111 | opcode_0010111 | opcode_1101111 | 
//                 opcode_1101111 | opcode_1100111 | opcode_0000011 |
//                 opcode_0010011 | opcode_0110011 ;

//   assign rs1_addr_o = inst_i[19:15];
//   assign re1_o = opcode_1100111 | opcode_1100011 | opcode_0000011 |
//                  opcode_0100011 | opcode_0010011 | opcode_0110011;

//   assign rs2_addr_o = inst_i[24:20];
//   assign re2_o = opcode_1100011 | opcode_0100011 | opcode_0110011;

// endmodule


module decoder
  (
   //input wire clk,
   // input wire rst,

   input wire [`InstWidth-1:0] 	   inst_i,

   output reg [1:0] 			   optype_o,
   output reg [`OpSelWidth-1:0]    opsel_o,

   output wire [`RegAddrWidth-1:0] rd_o,
   output reg 					   we_o,

   output wire [`RegAddrWidth-1:0] rs1_addr_o,
   output reg [`RegAddrWidth-1:0]  re1_o,
   output wire [`RegAddrWidth-1:0] rs2_addr_o,
   output reg [`RegAddrWidth-1:0]  re2_o,

   output reg [`DataWidth-1:0] 	   imm_o,
   output wire [4:0] 			   shamt_o
   );


   wire [6:0] 					   opcode = inst_i[6:0];

   wire [2:0] 					   fun3 = inst_i[14:12];

   wire [6:0] 					   fun7 = inst_i[31:25];

   assign  shamt_o = inst_i[24:20];
   wire [`DataBus] 				   imm_I = {{21{inst_i[31]}},inst_i[30:20]};
   wire [`DataBus] 				   imm_S = {{21{inst_i[31]}},inst_i[30:25],inst_i[11:7]};
   wire [`DataBus] 				   imm_B = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
   wire [`DataBus] 				   imm_U = {inst_i[31:12],12'b0};
   wire [`DataBus] 				   imm_J = {{12{inst_i[31]}},inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};


   always @(*) begin
      case (opcode)
		7'b0110111:begin
           imm_o = imm_U;
           opsel_o = `OpLUI;
           optype_o = `OpTypeALU;
           we_o = `Enable;
           re1_o = `Disable;
           re2_o = `Disable;
		end
		7'b0010111:begin
           imm_o = imm_U;
           opsel_o = `OpAUIPC;
           optype_o = `OpTypeALU;
           we_o = `Enable;
           re1_o = `Disable;
           re2_o = `Disable;
		end
		7'b1101111:begin
           //$display("jump");
           imm_o = imm_J;
           opsel_o = `OpJAL;
           optype_o = `OpTypeBranch;
           we_o = `Enable;
           re1_o = `Disable;
           re2_o = `Disable;
		end
		7'b1100111:begin
           imm_o = imm_I;
           opsel_o = `OpJALR;
           optype_o = `OpTypeBranch;
           we_o = `Enable;
           re1_o = `Enable;
           re2_o = `Disable;
		end    
		7'b1100011:begin
           imm_o = imm_B;
           case(fun3)
			 3'b000:opsel_o = `OpBEQ;
			 3'b001:opsel_o = `OpBNE;
			 3'b100:opsel_o = `OpBLT;
			 3'b101:opsel_o = `OpBGE;
			 3'b110:opsel_o = `OpBLTU;
			 3'b111:opsel_o = `OpBGEU;
			 default:opsel_o = 6'b0;
           endcase
           optype_o = `OpTypeBranch;
           we_o = `Disable;
           re1_o = `Enable;
           re2_o = `Enable;
		end  
		7'b0000011:begin
           imm_o = imm_I;
           case(fun3)
			 3'b000:opsel_o = `OpLB;
			 3'b001:opsel_o = `OpLH;
			 3'b010:opsel_o = `OpLW;
			 3'b100:opsel_o = `OpLBU;
			 3'b100:opsel_o = `OpLHU;
			 default:opsel_o = 6'b0;
           endcase
           optype_o = `OpTypeLS;
           we_o = `Enable;
           re1_o = `Enable;
           re2_o = `Disable;
		end 
		7'b0100011:begin
           imm_o = imm_S;
           case(fun3)
			 3'b000:opsel_o = `OpSB;
			 3'b001:opsel_o = `OpSH;
			 3'b010:opsel_o = `OpSW;
			 default:opsel_o = 6'b0;
           endcase
           optype_o = `OpTypeLS;
           we_o = `Disable;
           re1_o = `Enable;
           re2_o = `Enable;
		end 
		7'b0010011:begin
           imm_o = imm_I;
           case (fun3)
			 3'b000:opsel_o = `OpADD;
			 3'b010:opsel_o = `OpSLT;
			 3'b011:opsel_o = `OpSLTU;
			 3'b100:opsel_o = `OpXOR;
			 3'b110:opsel_o = `OpOR;
			 3'b111:opsel_o = `OpAND;
			 3'b001:opsel_o = `OpSLL;
			 3'b101:begin
				case(fun7)
				  7'b0000000: opsel_o = `OpSRL;
				  7'b0100000: opsel_o = `OpSRA;
				  default:    opsel_o = 6'b0;
				endcase
			 end
			 default:opsel_o = 6'b0;
           endcase
           optype_o = `OpTypeALU;
           we_o = `Enable;
           re1_o = `Enable;
           re2_o = `Disable;
		end 
		7'b0110011:begin
           imm_o = imm_I;
           case (fun3)
			 3'b000:begin
				case(fun7)
				  7'b0000000: opsel_o = `OpADD;
				  7'b0100000: opsel_o = `OpSUB;
				  default:    opsel_o = 6'b0;
				endcase
			 end
			 3'b010:opsel_o = `OpSLT;
			 3'b011:opsel_o = `OpSLTU;
			 3'b100:opsel_o = `OpXOR;
			 3'b110:opsel_o = `OpOR;
			 3'b111:opsel_o = `OpAND;
			 3'b001:opsel_o = `OpSLL;
			 3'b101:begin
				case(fun7)
				  7'b0000000: opsel_o = `OpSRL;
				  7'b0100000: opsel_o = `OpSRA;
				  default:    opsel_o = 6'b0;
				endcase
			 end
			 default:opsel_o = 6'b0;
           endcase
           optype_o = `OpTypeALU;
           we_o = `Enable;
           re1_o = `Enable;
           re2_o = `Enable;
		end 
		default: begin
           imm_o = imm_J;
           opsel_o = `OpNOP;
           optype_o = 2'b00;
           we_o = `Disable;
           re1_o = `Disable;
           re2_o = `Disable;
		end
      endcase
   end



   assign rd_o = inst_i[11:7];

   assign rs1_addr_o = inst_i[19:15];


   assign rs2_addr_o = inst_i[24:20];

endmodule

module pipeline_id
  (
   input wire 					clk,
   input wire 					rst,

   //From If
   input wire [`InstWidth-1:0] 	inst_i,

   //To Reg
   input wire [`DataBus] 		val1_i,
   input wire [`DataBus] 		val2_i,
   output reg 					reg_re1_o,
   output reg [`RegAddrBus] 	reg_ra1_o,
   output reg 					reg_re2_o,
   output reg [`RegAddrBus] 	reg_ra2_o,

   //To Ex
   output reg [`DataBus] 		val1_o,
   output reg [`DataBus] 		val2_o,
   output reg [`DataBus] 		imm_o,
   output reg [`RegAddrBus] 	rd_o,
   output reg 					we_o,
   output reg [1:0] 			optype_o,
   output reg [`OpSelWidth-1:0] opsel_o,

   //To Ex for forwarding
   output reg [`RegAddrBus] 	rs1_o,
   output reg 					rs1_e_o,
   output reg [`RegAddrBus] 	rs2_o,
   output reg 					rs2_e_o,

   //PC Reg
   input wire [`MemAddrBus] 	pc_i,
   output reg [`MemAddrBus] 	pc_o,

   //Flush
   input wire [4:0] 			flush_i,
   input wire [4:0] 			stall_i,
   
   output wire 					stall_o
   );
   
   //wire[`InstWidth-1:0] inst_i,
   wire [1:0] 					optype;
   wire [`OpSelWidth-1:0] 		opsel;

   wire [`RegAddrWidth-1:0] 	rd;
   wire 						we;

   wire [`RegAddrWidth-1:0] 	rs1_addr;
   wire [`RegAddrWidth-1:0] 	re1;
   wire [`RegAddrWidth-1:0] 	rs2_addr;
   wire [`RegAddrWidth-1:0] 	re2;

   wire [`DataWidth-1:0] 		imm;
   wire [4:0] 					shamt;

   decoder decoder0
	 (
	  .inst_i(inst_i),
	  .optype_o(optype),
	  .opsel_o(opsel),
	  .rd_o(rd),
	  .we_o(we),
	  .rs1_addr_o(rs1_addr),
	  .re1_o(re1),
	  .rs2_addr_o(rs2_addr),
	  .re2_o(re2),
	  .imm_o(imm),
	  .shamt_o(shamt)
	  );

   wire 						last_load;
   wire 						v1_s;
   wire 						v2_s;
   assign last_load = (opsel_o == `OpLB) || (opsel_o == `OpLH) || (opsel_o == `OpLW) ||
					  (opsel_o == `OpLBU) || (opsel_o == `OpLHU);
   assign v1_s = (re1 && we_o && (rs1_addr == rd_o) && (rd_o != 5'b0));
   assign v2_s = (re2 && we_o && (rs2_addr == rd_o) && (rd_o != 5'b0));
   assign stall_o = last_load && (v1_s || v2_s);

   
   //To Reg
   always @(*) begin
      if (rst == `Enable) begin
		 reg_re1_o = `Disable;
		 reg_ra1_o = `ZeroWord;
		 reg_re2_o = `Disable;
		 reg_ra2_o = `ZeroWord;
      end else begin
		 reg_re1_o = re1;
		 reg_ra1_o = rs1_addr;
		 reg_re2_o = re2;
		 reg_ra2_o = rs2_addr;
      end
   end

   //
   always @(posedge clk) begin
      if (rst == `Enable || (stall_i[1] == `Enable && stall_i[2]==`Disable)) begin
		 val1_o <= `ZeroWord;
		 val2_o <= `ZeroWord;
		 imm_o <= `ZeroWord;
		 rd_o <= `ZeroWord;
		 we_o <= `Disable;
		 opsel_o <= 6'b0;
		 optype_o <= 2'b00;
		 pc_o <= pc_i;
		 rs1_o <= 5'b0;
		 rs1_e_o <= `Disable;
		 rs2_o <= 5'b0;
		 rs2_e_o <= `Disable;
      
	  end else if (stall_i[2] ==`Enable) begin
		 val1_o <= val1_o;
		 val2_o <= val2_o;
		 imm_o <= imm_o;
		 rd_o <= rd_o;
		 we_o <= we_o;
		 opsel_o <= opsel_o;
		 optype_o <= optype_o;
		 pc_o <= pc_o;
		 rs1_o <= rs1_o;
		 rs1_e_o <= rs1_e_o;
		 rs2_o <= rs2_o;
		 rs2_e_o <= rs2_e_o;
      end else begin
		 val1_o <= (opsel == `OpAUIPC)? pc_i : val1_i;
		 val2_o <= val2_i;
		 imm_o <= imm;
		 rd_o <= rd;
		 we_o <= we;
		 opsel_o <= opsel; 
		 optype_o <= optype;     
		 pc_o <= pc_i;
		 rs1_o <= rs1_addr;
		 rs1_e_o <= re1;
		 rs2_o <= rs2_addr;
		 rs2_e_o <= re2;
      end
   end
 
endmodule
