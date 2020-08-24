`timescale 1ns / 1ps
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

`include "defines.v"
`include "defines_cache.v"

module ICacheAXI_Interface(
    input clk,
    input rst,
	//ICahce: Read Channel
    input wire inst_ren_i,
    input wire[`InstAddrBus]inst_araddr_i,
	output reg inst_rvalid_o,
	output reg [`WayBus]inst_rdata_o,//DCache: Read Channel
	
	//Data : Read Channel
    input wire data_ren_i,
    input wire[`DataAddrBus]data_araddr_i,
    output wire data_rvalid_o,
    output wire [`RegBus]data_rdata_o,//Word
	output wire data_stall_o,
	
	//Data: Write Channel
    input wire data_wen_i,
    input wire[`RegBus]data_wdata_i,//Way
    input wire [`DataAddrBus]data_awaddr_i,
    output wire data_bvalid_o,
	
	//AXI Communicate
	output wire             axi_ce_o,
//	output wire[3:0]        axi_sel_o,
	//AXI read
	input wire[`RegBus]    axi_rdata_i,        //返回到cache的读取数据
	input wire             axi_rvalid_i,  //返回数据可获取
	output wire             axi_ren_o,
	output wire             axi_rready_o,   //cache端准备好读
	output wire[`RegBus]    axi_raddr_o,
	output wire [3:0]       axi_rlen_o,		//read burst length
	//AXI write
	input wire             axi_bvalid_i,   //写响应,每个beat发一次，成功则可以传下一数据
	output wire             axi_wen_o,
	output wire[`RegBus]    axi_waddr_o,
	output wire[`RegBus]    axi_wdata_o,    //cache最好保证在每个时钟沿更新要写的内容
	output wire             axi_wvalid_o,   //cache端准备好写的数据，最好是持续
	output wire             axi_wlast_o,    //cache写最后一个数据
	output wire [3:0]       axi_wlen_o		//read burst length
    );
	assign  axi_ce_o = rst? `ChipDisable: `ChipEnable;
	assign axi_rlen_o = (read_state == `STATE_READ_DCACHE)? 4'h0:
	                       (read_state == `STATE_READ_ICACHE) ? 4'h7:
	                       4'h0;
//	assign  axi_sel_o = 4'b1111;//byte select
	
	
	//READ(DCache first)
	//state
	assign axi_rlen = (read_state == `STATE_READ_DCACHE)? 4'h0:4'h7;
	assign data_stall_o = data_stall | stall_write;
	wire data_stall = (read_state == `STATE_READ_FREE &&  !data_ren_i )? `Invalid: //free
							(read_state == `STATE_READ_ICACHE && !data_ren_i)? `Invalid: //Read inst but no data request
							(read_state == `STATE_READ_DCACHE && axi_rvalid_i)? `Invalid: //Read data but no data request
							`Valid;
    
	reg[1:0]read_state;
	reg[2:0]read_count;
	always@(posedge clk)begin
		if(rst) 
			read_state <= `STATE_READ_FREE;
		//data
		else if( read_state == `STATE_READ_FREE && data_ren_i == `ReadEnable)//DCache
			read_state <= `STATE_READ_DCACHE;
		else if( read_state == `STATE_READ_DCACHE && axi_rvalid_i == `Valid )//last read successful
			read_state <= `STATE_READ_FREE;
		//inst
		else if( read_state == `STATE_READ_FREE && inst_ren_i == `ReadEnable)//ICache
			read_state <= `STATE_READ_ICACHE;
		else if( read_state == `STATE_READ_ICACHE && axi_rvalid_i == `Valid && read_count == 3'h7 )//last read successful
			read_state <= `STATE_READ_FREE;
		else
			read_state <= read_state;
	end
	always@(posedge clk)begin
		if(read_state == `STATE_READ_FREE)
			read_count <= 3'h0;
		else if(axi_rvalid_i == `Valid)
			read_count <= read_count + 1;
		else	
			read_count <= read_count;
	end
	//AXI
	assign axi_ren_o = (read_state == `STATE_READ_FREE) ? `ReadDisable : `ReadEnable;
	assign axi_rready_o = axi_ren_o;//ready when starts reading
	assign axi_raddr_o = (read_state == `STATE_READ_DCACHE)? {data_araddr_i[31:2],2'b00}:
						(read_state == `STATE_READ_ICACHE)? {inst_araddr_i[31:5],read_count,2'b00}:
						`ZeroWord;
	//ICache/DCache
	always@(posedge clk)begin
	   if( read_state == `STATE_READ_ICACHE && axi_rvalid_i == `Valid && read_count == 3'h7 )
	       inst_rvalid_o <= `Valid;
       else    
            inst_rvalid_o <= `Invalid;
	end
	assign data_rvalid_o = axi_rvalid_i;
//	assign inst_rvalid_o = ( read_state == `STATE_READ_ICACHE && axi_rvalid_i == `Valid && read_count == 3'h7 )?
//							`Valid: `Invalid;//can add key word optimization later
//	assign data_rvalid_o = ( read_state == `STATE_READ_DCACHE && axi_rvalid_i == `Valid && read_count == 3'h7 )?
//							`Valid: `Invalid;//can add key word optimization later
	always@(posedge clk)begin
	   if(axi_rvalid_i)begin
            case(read_count)
                3'h0:	inst_rdata_o[32*1-1:32*0] <= axi_rdata_i;
                3'h1:	inst_rdata_o[32*2-1:32*1] <= axi_rdata_i;
                3'h2:	inst_rdata_o[32*3-1:32*2] <= axi_rdata_i;
                3'h3:	inst_rdata_o[32*4-1:32*3] <= axi_rdata_i;
                3'h4:	inst_rdata_o[32*5-1:32*4] <= axi_rdata_i;
                3'h5:	inst_rdata_o[32*6-1:32*5] <= axi_rdata_i;
                3'h6:	inst_rdata_o[32*7-1:32*6] <= axi_rdata_i;
                3'h7:	inst_rdata_o[32*8-1:32*7] <= axi_rdata_i;
                default:	inst_rdata_o <= inst_rdata_o;
            endcase
		end
	end
	assign data_rdata_o = axi_rdata_i;
	
	
	//WRITE
	//state
	wire stall_write = (write_state == `STATE_WRITE_FREE && data_wen_i)? `Valid://begin to write
	                   ( write_state == `STATE_WRITE_BUSY && axi_bvalid_i == `Invalid )? `Valid://write not finished
	                   `Invalid;
	assign axi_wlen_o = 4'h0;//one word 
	reg write_state;
	reg [2:0]write_count;
	always@(posedge clk)begin
		if(rst) 
			write_state <= `STATE_WRITE_FREE;
		else if( write_state == `STATE_WRITE_FREE && data_wen_i == `WriteEnable)//write 
			write_state <= `STATE_WRITE_BUSY;
		else if( write_state == `STATE_WRITE_BUSY && axi_bvalid_i == `Valid )//write successful
			write_state <= `STATE_WRITE_FREE;
		else
			write_state <= write_state;
	end
	//AXI
	assign axi_wen_o = (write_state == `STATE_WRITE_FREE && data_wen_i == `WriteEnable) ? `WriteEnable :
	                   (write_state == `STATE_WRITE_BUSY) ? `WriteEnable : `WriteDisable;
	assign axi_waddr_o = {data_awaddr_i[31:2],2'b00};
	assign axi_wdata_o = data_wdata_i;
	assign axi_wlast_o = `Valid;//write last word
	assign axi_wvalid_o = (write_state == `STATE_WRITE_BUSY )? `Valid: `Invalid;
	//DCache
	assign data_bvalid_o = ( write_state == `STATE_WRITE_BUSY && axi_bvalid_i == `Valid );//write successful
	
	
	
endmodule
