module memctrl
  (
   input wire 				   clk,
   input wire 				   rst,
   input wire 				   rdy, 

   //********** With IF **********
   input wire 				   if_re_i,
   input wire [`MemAddrBus]    if_addr_i,

   //********** With MEM **********
   input wire [1:0] 		   mem_re_i,
   input 					   mem_rsign_i,
   // 00 - disable  01-LB 10-LH 11-LW
   input wire [`MemAddrBus]    mem_addr_i, 

   input wire [1:0] 		   mem_we_i,
   input wire [`DataBus] 	   mem_wdata_i,
   
   output reg 				   busy_o,
   output reg [`InstWidth-1:0] data_o,
   output reg 				   done_o, 
   //********** With RAM **********
   output reg 				   ram_wr_o,
   output wire [`MemAddrBus]   ram_addr_o,
   input wire [`ByteWidth-1:0] ram_data_i,
   output wire [`ByteWidth-1:0] ram_data_o
);
   localparam 
	 IDLE = 5'b00001,
	 READING = 5'b00010,
	 GET = 5'b00100,
	 WRITING = 5'b01000,
	 CACHE = 5'b10000,
	 BLOWDRY = 5'b00000;

   localparam
	 m_none = 2'b00,
	 m_byte = 2'b01,
	 m_half = 2'b10,
	 m_word = 2'b11;

   localparam
	 index_len = 7,
	 inst_addr_len = 17
	 ;
   
   reg [`DataBus] 				icache[0:(2**index_len)-1];
   reg [inst_addr_len - index_len - 3 : 0] icache_tag[0:(2**index_len)-1];
   reg [(2**index_len)-1:0] 			   icache_val;	

   wire [index_len-1:0] 					iaddr_index;
   assign iaddr_index = if_addr_i[index_len+1:2];
   wire [inst_addr_len - index_len - 3 : 0] iaddr_tag;
   assign iaddr_tag = if_addr_i[inst_addr_len - 1: index_len + 2];

   wire 									icache_en;
   assign icache_en = (mem_re_i == m_none && mem_we_i == m_none && if_re_i == 1'b1 && if_re_i < 'h20000);
   reg 										icache_en_buf;
   wire [`MemAddrBus] 		   addr_in = (mem_re_i!=m_none || mem_we_i!=m_none) ? mem_addr_i : if_addr_i;
   
   reg [4:0] 				   state;				   

   reg [1:0] 				   deal_cnt;
   
   reg [`MemAddrBus] 		   addr_buf; 
   reg [`ByteWidth-1:0] 	   inst_buf[0:3];

   wire [index_len-1:0] 					iaddrb_index;
   assign iaddrb_index = addr_buf[index_len+1:2];
   wire [inst_addr_len - index_len - 3 : 0] iaddrb_tag;
   assign iaddrb_tag = addr_buf[inst_addr_len - 1: index_len + 2];

   //reg 						   write_finish;
		
   
   assign ram_addr_o = (state == IDLE) ? addr_in : addr_buf;
   reg [1:0] 				   re_buf;
   reg [1:0] 				   we_buf;
   wire [1:0] 				   re = (mem_we_i != m_none)?m_none:
							        (mem_re_i != m_none)?mem_re_i:
							        (if_re_i == `Enable)?m_word:m_none;
   
   wire 					   write_finish;
   assign write_finish = (deal_cnt == 0 && we_buf == m_byte) ||
						 (deal_cnt == 1 && we_buf == m_half) ||
						 (deal_cnt == 3 && we_buf == m_word) ;
   //wire 					   read_finish;
   //assign read_finish = (deal_cnt == 0 && re_buf == m_byte) ||
   //					 (deal_cnt == 1 && re_buf == m_half) ||
   //					 (deal_cnt == 3 && re_buf == m_word) ;

   //wire [`DataBus] 			   read_data[0:3];
   //assign read_data[0] = 
   
   always @(*)begin
	  case (state)
		default: ram_wr_o = 1'b0;
		IDLE:    ram_wr_o = (mem_we_i != m_none)? 1'b1:1'b0; 
		READING: ram_wr_o = 1'b0;
		GET:     ram_wr_o = 1'b0;
		WRITING: ram_wr_o = (write_finish)?1'b0:1'b1;
	  endcase
   end
   
   
   wire [`ByteWidth-1:0] 	   wdata[0:3];
   assign wdata[0] = mem_wdata_i[7:0];
   assign wdata[1] = mem_wdata_i[15:8];
   assign wdata[2] = mem_wdata_i[23:16];
   assign wdata[3] = mem_wdata_i[31:24];
   assign ram_data_o = (state == WRITING)?wdata[deal_cnt+1]:wdata[0];

   //reg [2**(index_len):0] 				   i;
   reg [`DataBus] 						   cache_buf;
   always @(posedge clk or negedge rst) 
	 begin
		if (rst) begin
		   state <= IDLE;
		   busy_o <= 1'b0;
		   done_o <= 1'b0;
		   re_buf <= m_none;
		   //write_finish <= 1'b0;
		   //for (i=0;i!=;i=i+1) begin
		//	  icache_val[i] = 1'b0;
		   icache_val <= 0;
		end else if (!rdy) begin
		   state <= state;
		end else begin
		   case (state)
			 IDLE:begin
				
				//write_finish <= 1'b0;
				if (mem_we_i != m_none) begin
				   state <= WRITING;
				   busy_o <= 1'b1;
				   done_o <= 1'b0;
				   deal_cnt <= 0;
				   we_buf <= mem_we_i;
				   addr_buf <= addr_in+1;
				end else if (re != m_none) begin
				   //dealing with cache
				   icache_en_buf <= icache_en;
				   if (icache_en && icache_val[iaddr_index] && 
					   icache_tag[iaddr_index] == iaddr_tag) begin
					  state <= IDLE;
					  data_o <= icache[iaddr_index];
					  //cache_buf <= icache[iaddr_index];
					  busy_o <= 1'b0;
					  done_o <= 1'b1;
				   end else begin
					  state <= GET;
					  busy_o <= 1'b1;
					  done_o <= 1'b0;
					  deal_cnt <= 0;
					  re_buf <= re;
					  addr_buf <= addr_in;
					end
				end else begin
				   state <= IDLE;
				   done_o <= 1'b0;
				   busy_o <= 1'b0;
				end
			 end // case: IDLE

			 READING:begin
				state <= GET;
			 end

			 CACHE:begin
				data_o <= cache_buf;
				busy_o <= 1'b0;
				done_o <= 1'b1;
				state <= IDLE;
			 end
			 
			 GET:begin
				addr_buf <= addr_buf + 1;
				deal_cnt <= deal_cnt + 1;
				if (deal_cnt == 0 && re_buf == m_byte) begin
				   //$display("load byte");
				   busy_o <= 1'b0;
				   state <= IDLE;
				   data_o <= mem_rsign_i ? {{24{ram_data_i[7]}},ram_data_i} :
							               {24'b0,ram_data_i};
				   done_o <= 1'b1;
				end else if (deal_cnt == 1 && re_buf == m_half) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   data_o <= mem_rsign_i ? {{16{ram_data_i[7]}},ram_data_i,inst_buf[0]} :
                                           {16'b0,ram_data_i,inst_buf[0]};
				   done_o <= 1'b1;
				end else if (deal_cnt == 3 && re_buf == m_word) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   data_o <= {ram_data_i,inst_buf[2],inst_buf[1],inst_buf[0]};
				   done_o <= 1'b1;

				   //dealing with cache
				   if (icache_en_buf) begin
					  icache_val[iaddrb_index] <= 1'b1;
					  icache_tag[iaddrb_index] <= iaddrb_tag;
					  icache[iaddrb_index] <= {ram_data_i,inst_buf[2],inst_buf[1],inst_buf[0]};
					  icache_en_buf <= 1'b0;
				   end
				   
				end else begin
				   busy_o <= 1'b1;
				   state <= READING;
//				   state <= GET;
				   inst_buf[deal_cnt] <= ram_data_i;
				end
			 end // case: READING
			 
			 WRITING:begin
				addr_buf <= addr_buf + 1;
				deal_cnt <= deal_cnt + 1;
				if (deal_cnt == 0 && we_buf == m_byte) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   done_o <= 1'b1;
				   //write_finish <= 1'b1;
				end else if (deal_cnt == 1 && we_buf == m_half) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   done_o <= 1'b1;
				   //write_finish <= 1'b1;
				end else if (deal_cnt == 3 && we_buf == m_word) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   done_o <= 1'b1;
				   //write_finish <= 1'b1;
				end else begin
				   busy_o <= 1'b1;
				   state <= WRITING;				   
				end	
			 end
 
		   endcase
		end
	 end 
	 
	 
   
   

endmodule   
