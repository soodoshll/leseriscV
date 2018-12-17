`timescale 1ns / 1ps
`include "define.v"
module ctrl(
  input wire 				rst,
  input wire 				rdy,
  // input wire[`MemAddrBus] pc_i,

  input wire 				set_pc_e_i,
  input wire [`MemAddrBus] 	set_pc_i,

  output wire [`MemAddrBus] set_pc_o,
  output wire 				set_pc_e_o,
  output wire [4:0] 		flush_o,

  input wire 				if_stall_i,
  input wire 				mem_stall_i,
  input wire 				id_stall_i,
  output reg [4:0] 			stall_o
  );
  
  //assign flush_o = (set_pc_e_i == `Enable? 5'b00011: 5'b00000);
  assign flush_o = `Disable;
  assign set_pc_o = set_pc_i;
  assign set_pc_e_o = set_pc_e_i;
  always @(*) begin
	 if (rdy == 1'b0) stall_o = 5'b11111;
	 else if (mem_stall_i) stall_o = 5'b01111;
	 else if (id_stall_i) stall_o = 5'b00011;
     else if (if_stall_i) stall_o = 5'b00001;
     else stall_o = 5'b00000;
  end
endmodule
