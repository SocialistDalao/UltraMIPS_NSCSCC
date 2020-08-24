`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Stucture of DCache
//----Initialization
//--------keep input data 
//--------TLB
//--------WriteBuffer
//--------Bank RAM
//--------Tag+Valid RAM
//--------Dirty
//--------Stall
//----State Transmission
//----State Operation
//--------STATE_FETCH_DATA
//------------tag hit
//------------tag not hit
//--------STATE_WRITE_DATA
//----Output
//////////////////////////////////////////////////////////////////////////////////

`include"defines.v"
`include"defines_cache.v"
module CacheBeta1(

    input wire clk,
    input wire rst,
    
	//Inst
	input wire inst_req_i,//高电平表示cpu发起取指令
	input wire [`RegBus]inst_vaddr_i,
	output wire inst_hit_o,//可选，表示ICache命中
	output wire inst_valid_o,//高电平表示当前输出inst有效
	output wire [`InstBus] inst1_o,
	output wire [`InstBus] inst2_o,
	output wire inst_stall_o,//高电平表示正在处理取指命令
	output wire single_shot,//高电平表示ICache只能够支持单发
	input wire flush,//CPU is running flush, which requires ICache to stop
    
	//Data stall
	output wire data_stall_o,//高电平表示正在处理访存命令
	//Data : Read Channel
    input wire data_ren_i,//高电平表示cpu发起取数据
    input wire[`DataAddrBus]data_vaddr_i,
    output wire data_rvalid_o,//高电平表示当前输出data有效
    output wire [`RegBus]data_rdata_o,
	//Data: Write Channel
    input wire data_wen_i,//高电平表示cpu发起写数据
    input wire[`RegBus]data_wdata_i,
    input wire [`DataAddrBus]data_vawaddr_i,
    input wire [3:0] data_wsel,//选择需要写入的位数使能
    output wire data_bvalid_o,//可选，高电平表示已经写入成功
	
	//AXI Communicate
	output wire             axi_ce_o,
	//AXI read
	input wire[`RegBus]    axi_rdata_i,        //返回到cache的读取数据
	input wire             axi_rvalid_i,  //返回数据可获取
	output wire             axi_ren_o,
	output wire             axi_rready_o,   //cache端准备好读
	output wire[`RegBus]    axi_raddr_o,
	output wire [3:0]       axi_rlen_o,		//read burst length
	//AXI write
	input wire             axi_bvalid_i,   //写响应,每个beat发一次，成功则可以传下一数据
    output wire [3:0]      axi_sel_o,//选择需要写入的位数使能
	output wire             axi_wen_o,
	output wire[`RegBus]    axi_waddr_o,
	output wire[`RegBus]    axi_wdata_o,    //cache最好保证在每个时钟沿更新要写的内容
	output wire             axi_wvalid_o,   //cache端准备好写的数据，最好是持续
	output wire             axi_wlast_o,    //cache写最后一个数据
	output wire [3:0]       axi_wlen_o		//write burst length
    );

	wire[`DataAddrBus]inst_araddr_i = (inst_vaddr_i[31:28]==4'h8)||(inst_vaddr_i[31:28]==4'h9)
									||(inst_vaddr_i[31:28]==4'ha)||(inst_vaddr_i[31:28]==4'hb)? 
										inst_vaddr_i & {3'b0,29'h1fffffff}: inst_vaddr_i ;
										
    wire mem_ren_o;
    wire [`InstAddrBus] mem_araddr_o;
    wire  mem_rvalid_i;
    wire [`WayBus] mem_rdata_i;
	ICache icache0(

		clk,
		rst|flush,
		
		//read inst request
		inst_req_i,
		inst_araddr_i,
		
		//read inst result
		inst_hit_o,
		inst_valid_o,
		inst1_o,
		inst2_o,
		inst_stall_o,
		single_shot,
		
		//from_mem read result
		mem_rvalid_i,
		mem_rdata_i,//一个块的大小
		//to_mem ready to recieve request 
		mem_ren_o,
		mem_araddr_o
		
		);	
	
	wire[`RegBus] data_araddr_i;
	wire[`RegBus] data_awaddr_i;
	assign axi_sel_o = data_wsel;
	assign data_araddr_i = (data_vaddr_i[31:28]==4'h8)||(data_vaddr_i[31:28]==4'h9)
									||(data_vaddr_i[31:28]==4'ha)||(data_vaddr_i[31:28]==4'hb)?
							data_vaddr_i & {3'b0,29'h1fffffff}: data_vaddr_i;
    assign data_awaddr_i = (data_vawaddr_i[31:28]==4'h8)||(data_vawaddr_i[31:28]==4'h9)
									||(data_vawaddr_i[31:28]==4'ha)||(data_vawaddr_i[31:28]==4'hb)?
							data_vawaddr_i & {3'b0,29'h1fffffff}: data_vawaddr_i;
							
	CacheAXI_Interface cache2axi(
		clk,
		rst,
		//ICahce: Read Channel
		mem_ren_o,
		mem_araddr_o,
		mem_rvalid_i,
		mem_rdata_i,//DCache: Read Channel
		
		//Data : Read Channel
		data_ren_i,
		data_araddr_i,
		data_rvalid_o,
		data_rdata_o,
		data_stall_o,
		
		//Data: Write Channel
		data_wen_i,
		data_wdata_i,
		data_awaddr_i,
		data_bvalid_o,
		
		//AXI Communicate
		axi_ce_o,
//		axi_sel_o,
		//AXI read
		axi_rdata_i,        //返回到cache的读取数据
		axi_rvalid_i,  //返回数据可获取
		axi_ren_o,
		axi_rready_o,   //cache端准备好读
		axi_raddr_o,
		axi_rlen_o,		//read burst length
		//AXI write
		axi_bvalid_i,   //写响应,每个beat发一次，成功则可以传下一数据
		axi_wen_o,
		axi_waddr_o,
		axi_wdata_o,    //cache最好保证在每个时钟沿更新要写的内容
		axi_wvalid_o,   //cache端准备好写的数据，最好是持续
		axi_wlast_o,    //cache写最后一个数据
		axi_wlen_o		//read burst length
	);
endmodule
