//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/05 17:28:24
// Design Name: 
// Module Name: WriteBuffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines_cache.v"
`include "defines.v"

module CacheAXI_Interface(
    input clk,
    input rst,
    //input flush,
    input wire[3:0]            mem_sel_i,
	//ICahce: Read Channel
    input wire 					inst_ren_i,
    input wire [`InstAddrBus] 	inst_araddr_i,
//	input wire                  inst_uncached,
	output reg 				    inst_rvalid_o,
	output reg [`WayBus]		inst_rdata_o,//DCache: Read Channel
	//output wire                is_process_cached_inst_o,
	
	//I-uncached read channel
	input wire                 iucache_ren_i,
	input wire[`DataAddrBus]   iucache_addr_i,
	output reg                 iucache_rvalid_o,
	output reg[`RegBus]        iucache_rdata_o,     
    
	//DCache: Read Channel
    input wire 					data_ren_i,
    input wire [`DataAddrBus]	data_araddr_i,
	input wire 					data_uncached,
    output reg 					data_rvalid_o,
    output reg [`WayBus]		data_rdata_o,//一个块的大小
	
	//DCache: Write Channel
    input wire 					data_wen_i,
    input wire [`WayBus]		data_wdata_i,//一个块的大小
    input wire [`DataAddrBus]	data_awaddr_i,
    output reg 					data_bvalid_o,
    
    //D-uncache: Read Channel
    input wire                 ducache_ren_i,
    input wire [`DataAddrBus]  ducache_araddr_i,
    output reg                 ducache_rvalid_o,   
    output reg [`RegBus]       ducache_rdata_o,       //一个字的大小  
    
	//D-uncache: Write Channel
	input wire 					ducache_wen_i,
	input wire [`RegBus]		ducache_wdata_i,  //一个字的大小
    input wire [`DataAddrBus]	ducache_awaddr_i,  //!!!/////
    output reg 					ducache_bvalid_o,  //!!!/////

	//AXI Communicate
	output wire             	axi_ce_o,
	output wire[3:0]       axi_wsel_o,
	 output wire[3:0]       axi_rsel_o,
	//AXI read
	input wire[`RegBus]    		rdata_i,        //返回到cache的读取数据
	input wire             		rdata_valid_i,  //返回数据可获取
	output wire             	axi_ren_o,
	output wire             	axi_rready_o,   //cache端准备好读
	output wire	[`RegBus]    	axi_raddr_o,
	output wire [3:0]           axi_rlen_o,    
	//AXI write
	input wire             		wdata_resp_i,   //写响应,每个beat发一次，成功则可以传下一数据
	output wire             	axi_wen_o,
	output wire	[`RegBus]    	axi_waddr_o,
	output reg [`RegBus]    	axi_wdata_o,    //cache最好保证在每个时钟沿更新要写的内容
	output wire             	axi_wvalid_o,   //cache端准备好写的数据，最好是持续
	output wire             	axi_wlast_o,    //cache写最后一个数据
	output wire [3:0]           axi_wlen_o    
    );
	assign  axi_ce_o = rst? `ChipDisable: `ChipEnable;
	//assign  axi_sel_o = 4'b1111;//byte select

	//READ(DCache first,uncache first)
	//state
	 reg[`READ_STATE_WIDTH]read_state;
	reg[2:0]read_count;
	assign is_process_cached_inst_o = (read_state ==`STATE_READ_ICACHE);
	always@(posedge clk)begin
		if(rst) 
			read_state <= `STATE_READ_FREE;
		else if( read_state == `STATE_READ_FREE && ducache_ren_i == `ReadEnable )
			read_state <= `STATE_READ_DUNCACHED;  //data uncached
		else if( read_state == `STATE_READ_DUNCACHED && rdata_valid_i == `Valid)
			read_state <= `STATE_READ_FREE;       //data uncached finish
		else if( read_state == `STATE_READ_FREE && data_ren_i == `ReadEnable)//DCache
			read_state <= `STATE_READ_DCACHE;     //data cache
		else if( read_state == `STATE_READ_DCACHE && rdata_valid_i == `Valid && read_count == 3'h7 )//last read successful
			read_state <= `STATE_READ_FREE;		  //data cache finish 
		else if( read_state == `STATE_READ_FREE && iucache_ren_i /*inst_ren_i == `ReadEnable && inst_uncached == `Uncached*/)//ICache
			read_state <= `STATE_READ_IUNCACHED;  //inst uncached
		else if( read_state == `STATE_READ_IUNCACHED && rdata_valid_i == `Valid)//last read successful
			read_state <= `STATE_READ_FREE;       //inst uncached finish
		else if( read_state == `STATE_READ_FREE && inst_ren_i == `ReadEnable)//ICache
			read_state <= `STATE_READ_ICACHE;     //inst cache
		else if( read_state == `STATE_READ_ICACHE && rdata_valid_i == `Valid && read_count == 3'h7 )//last read successful
			read_state <= `STATE_READ_FREE;		  //inst cache finish 
		else
			read_state <= read_state;
	end
	always@(posedge clk)begin
		if(read_state == `STATE_READ_FREE)
			read_count <= 3'h0;
		else if(rdata_valid_i == `Valid)
			read_count <= read_count + 1;
		else	
			read_count <= read_count;
	end
	//AXI
	assign axi_ren_o = (read_state == `STATE_READ_FREE) ? `ReadDisable : `ReadEnable;
	assign axi_rready_o = axi_ren_o;//ready when starts reading
	assign axi_raddr_o = (read_state == `STATE_READ_DUNCACHED)? ducache_araddr_i:
	                    (read_state == `STATE_READ_DCACHE)? {data_araddr_i[31:5],read_count,2'b00}:
	                    (read_state == `STATE_READ_IUNCACHED)? inst_araddr_i:
						(read_state == `STATE_READ_ICACHE)? {inst_araddr_i[31:5],read_count,2'b00}:
						`ZeroWord;
    assign axi_rsel_o = (read_state == `STATE_READ_DUNCACHED) ? mem_sel_i:4'b1111;
	//ICache/I-uncached/DCache
	always@(posedge clk)begin
	   	if( read_state == `STATE_READ_ICACHE  && rdata_valid_i == `Valid && read_count == 3'h7 )
	       	inst_rvalid_o <= `Valid;
       	else if (read_state == `STATE_READ_IUNCACHED && rdata_valid_i == `Valid)
       	    iucache_rvalid_o <= `Valid;
       	else begin   
            inst_rvalid_o <= `Invalid;
            iucache_rvalid_o <= `Invalid;
        end
	end
	always@(posedge clk)begin
	   	if( read_state == `STATE_READ_DCACHE && rdata_valid_i == `Valid && read_count == 3'h7 )
	       	data_rvalid_o <= `Valid;
       	else    
        	data_rvalid_o <= `Invalid;
	end
	
	//d-uncached
    always@(posedge clk)begin
        if( read_state == `STATE_READ_DUNCACHED && rdata_valid_i == `Valid )
            ducache_rvalid_o <= `Valid;
        else    
            ducache_rvalid_o <= `Invalid;
    end
	
//	assign inst_rvalid_o = ( read_state == `STATE_READ_ICACHE && rdata_valid_i == `Valid && read_count == 3'h7 )?
//							`Valid: `Invalid;//can add key word optimization later
//	assign data_rvalid_o = ( read_state == `STATE_READ_DCACHE && rdata_valid_i == `Valid && read_count == 3'h7 )?
//							`Valid: `Invalid;//can add key word optimization later
	always@(posedge clk)begin
	   if(rst)begin
	       inst_rdata_o <= 256'h0;
	   end else if(rdata_valid_i)begin	       
           case(read_count)
               3'h0:	inst_rdata_o[32*1-1:32*0] <= rdata_i;
               3'h1:	inst_rdata_o[32*2-1:32*1] <= rdata_i;
               3'h2:	inst_rdata_o[32*3-1:32*2] <= rdata_i;
               3'h3:	inst_rdata_o[32*4-1:32*3] <= rdata_i;
               3'h4:	inst_rdata_o[32*5-1:32*4] <= rdata_i;
               3'h5:	inst_rdata_o[32*6-1:32*5] <= rdata_i;
               3'h6:	inst_rdata_o[32*7-1:32*6] <= rdata_i;
               3'h7:	inst_rdata_o[32*8-1:32*7] <= rdata_i;
               default:	inst_rdata_o <= inst_rdata_o;
           endcase
		end
	end
	always@(posedge clk)begin
	   if(rdata_valid_i)begin
            case(read_count)
                3'h0:	data_rdata_o[32*1-1:32*0] <= rdata_i;
                3'h1:	data_rdata_o[32*2-1:32*1] <= rdata_i;
                3'h2:	data_rdata_o[32*3-1:32*2] <= rdata_i;
                3'h3:	data_rdata_o[32*4-1:32*3] <= rdata_i;
                3'h4:	data_rdata_o[32*5-1:32*4] <= rdata_i;
                3'h5:	data_rdata_o[32*6-1:32*5] <= rdata_i;
                3'h6:	data_rdata_o[32*7-1:32*6] <= rdata_i;
                3'h7:	data_rdata_o[32*8-1:32*7] <= rdata_i;
                default:	data_rdata_o <= data_rdata_o;
            endcase
		end
	end
	//uncached rdata_o
	always@(posedge clk)begin
	    if(rst)begin
	        iucache_rdata_o <= 32'd0;
	        ducache_rdata_o <= 32'd0;
	    end else begin	    
	        if(rdata_valid_i && read_state == `STATE_READ_DUNCACHED)begin
	            ducache_rdata_o <= rdata_i; 
	        end
	        if(rdata_valid_i && read_state == `STATE_READ_IUNCACHED)begin
	            iucache_rdata_o <= rdata_i;
	        end
	    end
	end
		
	//WRITE
	//state
	 reg [`WRITE_STATE_WIDTH]write_state;
	reg [2:0]write_count;
	always@(posedge clk)begin
		if(rst) 
			write_state <= `STATE_WRITE_FREE;
		else if( write_state == `STATE_WRITE_FREE && ducache_wen_i == `WriteEnable)//write uncache
            write_state <= `STATE_WRITE_DUNCACHED;
        else if( write_state == `STATE_WRITE_DUNCACHED && wdata_resp_i == `Valid )//last write successful
            write_state <= `STATE_WRITE_FREE;
		else if( write_state == `STATE_WRITE_FREE && data_wen_i == `WriteEnable)//write 
			write_state <= `STATE_WRITE_BUSY;
		else if( write_state == `STATE_WRITE_BUSY && wdata_resp_i == `Valid && write_count == 3'h7 )//last write successful
			write_state <= `STATE_WRITE_FREE;
		else
			write_state <= write_state;
	end
	always@(posedge clk)begin
		if(write_state == `STATE_WRITE_FREE)
			write_count <= 3'h0;
		else if(write_state == `STATE_WRITE_BUSY && wdata_resp_i == `Valid)
			write_count <= write_count + 1;
		else	
			write_count <= write_count;
	end
	
	//AXI
	assign  axi_wlen_o   = (write_state == `STATE_WRITE_DUNCACHED ||(write_state == `STATE_WRITE_FREE && ducache_wen_i == 1'b1))?4'h0:4'h7;//byte select
	
	assign  axi_wen_o    = (write_state == `STATE_WRITE_FREE) ? `WriteDisable : `WriteEnable;
	assign  axi_wvalid_o = (write_state == `STATE_WRITE_FREE)? `Invalid: `Valid;
    
    assign  axi_rlen_o  = ((read_state == `STATE_READ_IUNCACHED || read_state == `STATE_READ_DUNCACHED ) || 
                           ((read_state == `STATE_READ_FREE)&&(ducache_ren_i)) || 
                           ((read_state == `STATE_READ_FREE)&&(iucache_ren_i)))?4'h0:4'h7;//byte select
                           
	assign  axi_waddr_o = (write_state == `STATE_WRITE_DUNCACHED)?
	                       ducache_awaddr_i:{data_awaddr_i[31:5],write_count,2'b00};
	assign  axi_wlast_o = (write_state == `STATE_WRITE_BUSY && write_count == 3'h7)? 
                           `Valid:(write_state == `STATE_WRITE_DUNCACHED)?`Valid:`Invalid;//write last word
	
    assign  axi_ce_o = rst? `ChipDisable: `ChipEnable;
    
	assign  axi_wsel_o =  (write_state == `STATE_WRITE_DUNCACHED)? mem_sel_i:4'b1111;
	                    
	
	                     
	//DCache
	always@(posedge clk)begin
	   if( write_state == `STATE_WRITE_BUSY && wdata_resp_i == `Valid && write_count == 3'h7 )
	       data_bvalid_o <= `Valid;
       else    
           data_bvalid_o <= `Invalid;
	end
	//D-uncached
	always@(posedge clk)begin
       if( write_state == `STATE_WRITE_DUNCACHED && wdata_resp_i == `Valid )
           ducache_bvalid_o <= `Valid;
       else    
           ducache_bvalid_o <= `Invalid;
    end
	
	
	always@(*)begin
		case(write_count)
			3'h0:	axi_wdata_o <= (write_state == `STATE_WRITE_DUNCACHED)?ducache_wdata_i:data_wdata_i[32*1-1:32*0];
			3'h1:	axi_wdata_o <= data_wdata_i[32*2-1:32*1];
			3'h2:	axi_wdata_o <= data_wdata_i[32*3-1:32*2];
			3'h3:	axi_wdata_o <= data_wdata_i[32*4-1:32*3];
			3'h4:	axi_wdata_o <= data_wdata_i[32*5-1:32*4];
			3'h5:	axi_wdata_o <= data_wdata_i[32*6-1:32*5];
			3'h6:	axi_wdata_o <= data_wdata_i[32*7-1:32*6];
			3'h7:	axi_wdata_o <= data_wdata_i[32*8-1:32*7];
			default:	axi_wdata_o <= `ZeroWord;
		endcase
	end
	
	
	
endmodule
