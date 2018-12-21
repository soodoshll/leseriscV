//`define DCACHE
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
	 WRITHR = 5'b10000,
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

   localparam
	 dindex_len = 5,
	 d_addr_len = 17;


   //********** ICACHE **********
   reg [`DataBus] 				icache[0:(2**index_len)-1];
   reg [inst_addr_len - index_len - 3 : 0] icache_tag[0:(2**index_len)-1];
   reg [(2**index_len)-1:0] 			   icache_val;	


   reg [4:0] 								state;				   
   
   reg [1:0] 								deal_cnt;
   
   reg [`MemAddrBus] 						addr_buf; 
   reg [`ByteWidth-1:0] 					inst_buf[0:3];

   wire [index_len-1:0] 					iaddr_index;
   assign iaddr_index = if_addr_i[index_len+1:2];
   wire [inst_addr_len - index_len - 3 : 0] iaddr_tag;
   assign iaddr_tag = if_addr_i[inst_addr_len - 1: index_len + 2];
   
   wire [index_len-1:0] 					iaddrb_index;
   assign iaddrb_index = addr_buf[index_len+1:2];
   wire [inst_addr_len - index_len - 3 : 0] iaddrb_tag;
   assign iaddrb_tag = addr_buf[inst_addr_len - 1: index_len + 2];

   reg 										re_from;
   
   wire 									icache_en;
   assign icache_en = (mem_re_i == m_none && mem_we_i == m_none && if_re_i == 1'b1 && if_re_i < 'h20000);
   reg 										icache_en_buf;
   wire [`MemAddrBus] 						addr_in = (mem_re_i!=m_none || mem_we_i!=m_none) ? mem_addr_i : if_addr_i;


`ifdef DCACHE
   //********** DCACHE **********
   reg [`ByteBus] 						  dcache[0:(2**dindex_len)-1];
   reg [d_addr_len - dindex_len - 1 : 0 ] dcache_tag[0:(2**dindex_len)-1];
   reg [(2**dindex_len)-1:0] 			  dcache_val;
   reg [(2**dindex_len)-1:0] 			  dcache_dirty; 			  

   wire 								  dcache_re;
   assign dcache_re = (mem_we_i == m_none && mem_re_i != m_none && mem_addr_i < 'h20000);
   reg 									  dcache_re_buf;
   wire 								  dcache_we;
   assign dcache_we = (mem_we_i != m_none && mem_addr_i < 'h20000);
   reg 									  dcache_we_buf;

   wire [`MemAddrBus] 					  dcache_a[0:3];
   assign dcache_a[0] = mem_addr_i;
   assign dcache_a[1] = mem_addr_i + 1;
   assign dcache_a[2] = mem_addr_i + 2;
   assign dcache_a[3] = mem_addr_i + 3;

   wire [dindex_len-1:0] 				  dcache_i[0:3];
   wire [d_addr_len - dindex_len - 1 : 0] dcache_t[0:3];
   wire [`ByteBus] 					  dcache_d[0:3];					  
   genvar 								  i;
   generate
	  for (i=0;i<4;i = i + 1) begin
		 assign dcache_i[i] = dcache_a[i][dindex_len-1:0];
		 assign dcache_t[i] = dcache_a[i][d_addr_len-1:dindex_len];
		 assign dcache_d[i] = dcache[dcache_i[i]];
	  end
   endgenerate
   
   reg 									  dcache_rhit;
   
   always @(*) begin
	  case (mem_re_i)
		default : dcache_rhit = 1'b0;
		m_byte: dcache_rhit = (dcache_val[dcache_i[0]] && dcache_tag[dcache_i[0]] == dcache_t[0]) ;
		m_half: dcache_rhit = (dcache_val[dcache_i[0]] && dcache_tag[dcache_i[0]] == dcache_t[0]) &&
							  (dcache_val[dcache_i[1]] && dcache_tag[dcache_i[1]] == dcache_t[1]);										  
		m_word: dcache_rhit = (dcache_val[dcache_i[0]] && dcache_tag[dcache_i[0]] == dcache_t[0])&&
							  (dcache_val[dcache_i[1]] && dcache_tag[dcache_i[1]] == dcache_t[1])&&
							  (dcache_val[dcache_i[2]] && dcache_tag[dcache_i[2]] == dcache_t[2])&&
							  (dcache_val[dcache_i[3]] && dcache_tag[dcache_i[3]] == dcache_t[3]) ;
	  endcase
   end

   
   reg								  dcache_whit;
   always @(*) begin
	  case (mem_we_i)
		default : dcache_whit = 1'b0;
		m_byte: dcache_whit =(!dcache_val[dcache_i[0]] || !dcache_dirty[dcache_i[0]] || dcache_tag[dcache_i[0]] == dcache_t[0]) ;
		m_half: dcache_whit =(!dcache_val[dcache_i[0]] || !dcache_dirty[dcache_i[0]] || dcache_tag[dcache_i[0]] == dcache_t[0]) &&
							 (!dcache_val[dcache_i[1]] || !dcache_dirty[dcache_i[1]] || dcache_tag[dcache_i[1]] == dcache_t[1]) ;
		m_word: dcache_whit =(!dcache_val[dcache_i[0]] || !dcache_dirty[dcache_i[0]] || dcache_tag[dcache_i[0]] == dcache_t[0]) &&
							 (!dcache_val[dcache_i[1]] || !dcache_dirty[dcache_i[1]] || dcache_tag[dcache_i[1]] == dcache_t[1]) &&
							 (!dcache_val[dcache_i[2]] || !dcache_dirty[dcache_i[2]] || dcache_tag[dcache_i[2]] == dcache_t[2]) &&
							 (!dcache_val[dcache_i[3]] || !dcache_dirty[dcache_i[3]] || dcache_tag[dcache_i[3]] == dcache_t[3]) ;
	  endcase
   end
`endif 

   


		
`ifdef DCACHE   
   assign ram_addr_o = (state != IDLE) ? addr_buf :
					   (dcache_we && !dcache_whit) ? {dcache_tag[dcache_i[0]],dcache_i[0]}:
					   addr_in;
`else
   assign ram_addr_o = (state != IDLE) ? addr_buf :
					   addr_in;
`endif
   
   reg [1:0] 				   re_buf;
   reg [1:0] 				   we_buf;
   wire [1:0] 				   re = (mem_we_i != m_none)?m_none:
							        (mem_re_i != m_none)?mem_re_i:
							        (if_re_i == `Enable)?m_word:m_none;
   
   wire 					   write_finish;
   assign write_finish = (deal_cnt == 0 && we_buf == m_byte) ||
						 (deal_cnt == 1 && we_buf == m_half) ||
						 (deal_cnt == 3 && we_buf == m_word) ;
   

   reg [3:0] 				   j;
   
   always @(*)begin
	  case (state)
		default: ram_wr_o = 1'b0;
`ifdef DCACHE
		IDLE:    ram_wr_o = (mem_we_i != m_none && (!dcache_we || !dcache_whit))? 1'b1:1'b0; 
`else
		IDLE:    ram_wr_o = (mem_we_i != m_none)? 1'b1:1'b0;
`endif 
		READING: ram_wr_o = 1'b0;
		WRITHR:  ram_wr_o = (write_finish)?1'b0:1'b1;
		WRITING: ram_wr_o = (write_finish)?1'b0:1'b1;
	  endcase
   end
   
   
   wire [`ByteWidth-1:0] 	   wdata[0:3];
   assign wdata[0] = mem_wdata_i[7:0];
   assign wdata[1] = mem_wdata_i[15:8];
   assign wdata[2] = mem_wdata_i[23:16];
   assign wdata[3] = mem_wdata_i[31:24];
`ifdef DCACHE
   assign ram_data_o = (state == WRITHR)?dcache_d[deal_cnt+1]:
					   (state == WRITING)?wdata[deal_cnt+1]:
					   (dcache_we && !dcache_whit)?dcache_d[0]: wdata[0];
`else
   assign ram_data_o = (state == WRITING)?wdata[deal_cnt+1]:wdata[0];
`endif
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
		   re_from <= 0;
`ifdef DCACHE
		   dcache_val <= 0;
		   dcache_dirty <= 0;
`endif
		end else if (rdy) begin
		   case (state)
			 IDLE:begin

				//write_finish <= 1'b0;
				if (mem_we_i != m_none) begin
`ifdef DCACHE				
				   dcache_we_buf <= dcache_we;
				   if (dcache_we) begin
					  if (dcache_whit) begin
						 state <= IDLE;
						 busy_o <= 1'b0;
						 done_o <= 1'b1;
						 case (mem_we_i)
						   default:;
						   m_byte: begin
							  dcache_val[dcache_i[0]] <= 1'b1;
							  dcache_tag[dcache_i[0]] <= dcache_t[0];
							  dcache_dirty[dcache_i[0]] <= 1'b1;
							  dcache[dcache_i[0]] <= wdata[0];
						   end
						   m_half: begin
							  for (j=0;j<2;j=j+1) begin
								 dcache_val[dcache_i[j]] <= 1'b1;
								 dcache_tag[dcache_i[j]] <= dcache_t[j];
								 dcache_dirty[dcache_i[j]] <= 1'b1;
								 dcache[dcache_i[j]] <= wdata[j];
							  end
						   end
						   m_word: begin
							  //$display("fuck");
							  for (j=0;j<4;j=j+1) begin
								 dcache_val[dcache_i[j]] <= 1'b1;
								 dcache_tag[dcache_i[j]] <= dcache_t[j];
								 dcache_dirty[dcache_i[j]] <= 1'b1;
								 dcache[dcache_i[j]] <= wdata[j];
							  end
						   end
						 endcase // case (mem_we_i)
					  end else begin // if (dcahce_whit)
						 state <= WRITHR;
						 busy_o <= 1'b1;
						 done_o <= 1'b0;
						 deal_cnt <= 0;
						 we_buf <= mem_we_i;
						 addr_buf <= {dcache_tag[dcache_i[1]],dcache_i[1]};
					  end
				   end else 
`endif
					 begin
						state <= WRITING;
						busy_o <= 1'b1;
						done_o <= 1'b0;
						deal_cnt <= 0;
						we_buf <= mem_we_i;
						addr_buf <= addr_in+1;
					 end
				end else if (re != m_none) begin
				   //dealing with cache
`ifdef DCACHE
				   dcache_re_buf <= dcache_re;
`endif
				   icache_en_buf <= icache_en;
`ifdef DCACHE
				   if (dcache_re && dcache_rhit) begin
					  state <= IDLE;
					  busy_o <= 1'b0;
					  done_o <= 1'b1;
					  case (mem_re_i)
						default:;
						m_byte: data_o <= mem_rsign_i ? {{24{dcache_d[0][7]}},dcache_d[0]} :
							              {24'b0,dcache_d[0]}; 
						m_half: data_o <= mem_rsign_i ? {{16{dcache_d[1][7]}},dcache_d[1],dcache_d[0]} :
										  {16'b0,dcache_d[1],dcache_d[0]} ;
						m_word: data_o <= {dcache_d[3],dcache_d[2],
										   dcache_d[1],dcache_d[0]};
					  endcase // case (mem_re)
				   end else
`endif	 
				   if (icache_en && icache_val[iaddr_index] && 
								icache_tag[iaddr_index] == iaddr_tag) begin
					  state <= IDLE;
					  data_o <= icache[iaddr_index];
					  busy_o <= 1'b0;
					  done_o <= 1'b1;
				   end else begin
					  state <= GET;
					  busy_o <= 1'b1;
					  done_o <= 1'b0;
					  deal_cnt <= 0;
					  re_buf <= re;
					  //addr_buf <= addr_in;
					  addr_buf <= (addr_in < 'h20000) ? addr_in + 1 : addr_in;
					  re_from <= (addr_in < 'h20000);
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


/* -----\/----- EXCLUDED -----\/-----
			 CACHE:begin
				data_o <= cache_buf;
				busy_o <= 1'b0;
				done_o <= 1'b1;
				state <= IDLE;
			 end
 -----/\----- EXCLUDED -----/\----- */
			 
			 
			 GET:begin
				addr_buf <= (deal_cnt == 2 && re_from) ? addr_buf : addr_buf + 1;
				deal_cnt <= deal_cnt + 1;
`ifdef DCACHE				
				if (dcache_re_buf && !dcache_dirty[dcache_i[deal_cnt]]) begin
				   dcache_val[dcache_i[deal_cnt]] <= 1'b1;
				   dcache_tag[dcache_i[deal_cnt]] <= dcache_t[deal_cnt];
				   dcache[dcache_i[deal_cnt]] <= ram_data_i;
				end // if (dcache_re_buf)
`endif
				
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
				   //state <= READING;
				   state <= (re_from) ?  GET : READING;
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
`ifdef DCACHE
			 WRITHR: begin
				addr_buf <= {dcache_tag[dcache_i[deal_cnt+2]],dcache_i[deal_cnt+2]};
				deal_cnt <= deal_cnt + 1;
				
				dcache_tag[dcache_i[deal_cnt]] <= dcache_t[deal_cnt];
				dcache[dcache_i[deal_cnt]] <= wdata[deal_cnt];
				dcache_val[dcache_i[deal_cnt]] <= 1'b1;
				dcache_dirty[dcache_i[deal_cnt]] <= 1'b1;
				
				if (write_finish) begin
				   busy_o <= 1'b0;
				   state <= IDLE;
				   done_o <= 1'b1;
				end
			 end
`endif
		   endcase
		end
	 end 
	 
	 
   
   

endmodule   
