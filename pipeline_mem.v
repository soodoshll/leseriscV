`timescale 1ns / 1ps
`include "define.v"
module pipeline_mem
(
  input wire 				clk,
  input wire 				rst,
  input wire 				rdy,
  input wire [`RegAddrBus] 	rd_i,
  input wire 				we_i,
  input wire [`DataBus] 	wdata_i,
  //input wire [`MemAddrBus] maddr_i,
  input wire [1:0] 			mre_i,
  input wire 				mrsign_i,
  input wire [1:0] 			mwe_i,
  //input wire [`RegAddrBus] mrs_i,
  input wire [`DataBus] 	mwdata_i,
  input wire [`MemAddrBus] 	ma_i,
 
  output reg [`RegAddrBus] 	rd_o,
  output reg 				we_o,
  output reg [`DataBus] 	wdata_o,

 //********** with memctrl **********
  output wire [1:0] 		mre_o,
  output wire 				mrsign_o,
  output wire [1:0] 		mwe_o,
  output wire [`DataBus] 	mwdata_o,
  output wire [`MemAddrBus] ma_o,

  input wire 				mem_busy_i,
  input wire [`DataBus] 	mem_data_i,
  input wire 				mem_done_i,

 
  output wire 				mem_stall_o,
  input wire [4:0] 			stall_i
  );


   
   localparam
	 m_none = 2'b00,
	 m_byte = 2'b01,
	 m_half = 2'b10,
	 m_word = 2'b11;

   localparam
	 IDLE = 4'b0001,
	 WAITING = 4'b0010,
	 READING = 4'b0100,
	 WRITING = 4'b1000,
	 BLOWDRY = 4'b0000;
   
   reg [3:0] 				state;
   wire 					mem_work;
   
   assign mem_work  = (mwe_i != m_none || mre_i != m_none);
   assign mem_stall_o = mem_work && !(
						 (state == READING && mem_done_i) ||
						 (state == WRITING && mem_done_i));
   
   wire 					finish;
   assign finish = (state == READING && mem_done_i) || (state==WRITING && mem_done_i);

   assign mre_o = (!mem_busy_i && !finish) ? mre_i : m_none;
   assign mrsign_o = mrsign_i;
   assign mwe_o = (!mem_busy_i && !finish) ? mwe_i : m_none;
   assign mwdata_o = mwdata_i;
   assign ma_o = ma_i;
   
   
   always @(posedge clk) begin
      if (rst == `Enable) begin
		 rd_o <= 5'b0;
		 we_o <= 1'b0;
		 wdata_o <= `ZeroWord;
		 state <= IDLE;
	  end else if (!rdy || stall_i[4]==`Enable) begin
/* -----\/----- EXCLUDED -----\/-----
		 rd_o <= rd_o;
		 we_o <= we_o;
		 wdata_o <= wdata_o;
 -----/\----- EXCLUDED -----/\----- */
      end else begin
		 case (state)
		   IDLE:begin
			  if (mwe_i != m_none) begin
				 if (mem_busy_i)
				   state <= WAITING;
				 else 
				   state <= WRITING;
			  end else if (mre_i != m_none) begin
				 if (mem_busy_i)
				   state <= WAITING;
				 else
				   state <= READING;
			  end else begin
				 rd_o <= rd_i;
				 we_o <= we_i;
				 wdata_o <= wdata_i;
			  end
		   end // case: IDLE

		   WAITING: begin
			  if (mem_busy_i) begin
				 state <= WAITING;
			  end else begin
				 if (mwe_i != m_none)
				   state <= WRITING;
				 else
				   state <= READING;
			  end
		   end
		   
		   WRITING:begin
			  if (mem_busy_i) begin
				 state <= WRITING;
			  end else begin				 
				 state <= IDLE;
				 rd_o <= rd_i;
				 we_o <= we_i;
			  end 	 
		   end
		   
		   READING:begin
			  //$display("reading");
			  if (mem_busy_i) begin
				 state <= READING;
			  end else begin
				 //$display("data fetched");
				 state <= IDLE;
				 rd_o <= rd_i;
				 we_o <= we_i;
				 wdata_o <= mem_data_i;
			  end 	 
		   end

		 endcase
		 
	  end
   end
endmodule
