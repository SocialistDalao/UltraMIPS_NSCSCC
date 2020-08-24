`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////
//Notice:
///////1.DCache recieves only one port for addr, but cpu gives two,
/////////so we actually combine them here.
///////////////////////////////////////////////////////////////////////


`include"defines.v"
`include"defines_cache.v"
module Cache_pipeline(
    input wire clk,
    input wire rst,
    
	//Inst
	input wire 					inst_req_i,//???????cpu????????
	input wire [`RegBus]		inst_vaddr_i,
	output wire 				inst_hit_o,//????????ICache????
	output wire 				inst_valid_o,//?????????????inst??§¹
	output reg [`InstBus] 		inst1_o,
	output wire [`InstBus] 		inst2_o,
	output wire [`InstAddrBus] 	inst1_addr_o,
	output wire [`InstAddrBus] 	inst2_addr_o,
    output reg 					inst1_valid_o,
    output reg 					inst2_valid_o,
	output wire					pc_stall_o,
	//output reg 				    inst_stall_o,//????????????????????
	//output reg 				    single_issue_o,//???????ICache??????????
	input wire 					flush,
    
	//Data stall
	output wire 				data_stall_o,//?????????????????????
	//Data : Read Channel
    input wire 					data_rreq_i,//???????cpu?????????
    input wire[`DataAddrBus]	data_raddr_i,
    output wire 				data_rvalid_o,//?????????????data??§¹
    output reg [`RegBus]		data_rdata_o,
	//Data: Write Channel
    input wire 					data_wreq_i,//???????cpu????§Õ????
    input wire[`RegBus]			data_wdata_i,
    input wire [`DataAddrBus]	data_waddr_i,
    input wire [3:0] 			data_wsel_i,//??????§Õ???¦Ë?????
//    output wire data_bvalid_o,
	
	//AXI Communicate
	output wire             axi_ce_o,
	output wire [3:0]        axi_sel_o,
	//AXI read
	input wire[`RegBus]    	axi_rdata_i,        //?????cache????????
	input wire             	axi_rvalid_i,  //???????????
	output wire             axi_ren_o,
	output wire             axi_rready_o,   //cache????????
	output wire[`RegBus]    axi_raddr_o,
	output wire [3:0]       axi_rlen_o,		//read burst length
	//AXI write
	input wire             	axi_bvalid_i,   //§Õ???,???beat????¦²?????????????????
	output wire             axi_wen_o,
	output wire[`RegBus]    axi_waddr_o,
	output wire[`RegBus]    axi_wdata_o,    //cache???????????????????§Õ??????
	output wire             axi_wvalid_o,   //cache???????§Õ???????????????
	output wire             axi_wlast_o,    //cache§Õ??????????
	output wire [3:0]       axi_wlen_o		//write burst length
    );

	
//Notice:
///////1.DCache recieves only one port for addr, but cpu gives two,
///////  so we actually combine them here.

	
	wire [`DataAddrBus] virtual_addr_i = (data_rreq_i)? data_raddr_i:
										(data_wreq_i)? data_waddr_i:
										`ZeroWord;
	//Cache hit count
	wire DCache_hit;
	wire ICache_hit;
	reg [127:0]total_icache_hit;
	reg [127:0]total_icache_req;
	always@(posedge clk)begin
		if(rst)
			total_icache_req <= 0;
		else if(inst1_valid_o)
			total_icache_req <= total_icache_req + 1;
		if(rst)
			total_icache_req <= 0;
		else if(ICache_hit)
			total_icache_req <= total_icache_req + 1;
	end
	
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Mapping Operation/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
	//In this section, we deal with cached and uncached operation
	//and give related control signals to Cache and AXI.
	
	//inst read
	wire 				mem_inst_rvalid_i;
	wire [`WayBus]		mem_inst_rdata_i;//???????§á
	wire 				mem_inst_ren_o;
	wire [`InstAddrBus]	mem_inst_araddr_o;
    //data read
    wire 				mem_data_rvalid_i;
    wire [`WayBus]		mem_data_rdata_i;
    wire 				mem_data_ren_o;
    wire [`DataAddrBus]	mem_data_araddr_o;
	//data write
    wire 				mem_data_bvalid_i;
    wire 				mem_data_wen_o;
    wire [`WayBus] 		mem_data_wdata_o;//???????§á
    wire [`DataAddrBus]	mem_data_awaddr_o;
	
	//TLB
	wire inst_uncached = `Invalid;
	wire [`InstAddrBus]inst_paddr_i;
	TLB tlb_inst(
    .virtual_addr_i(inst_vaddr_i),
    .physical_addr_o(inst_paddr_i)
//    .uncached(inst_uncached)
    );
	wire data_uncached;
	wire [`InstAddrBus]data_paddr_i;
	TLB tlb_data(
    .virtual_addr_i(virtual_addr_i),
    .physical_addr_o(data_paddr_i),
    .uncached(data_uncached)
    );
	
	//**Inst Uncached Operation**
	//ICache enable
	reg ICache_req;
	//*CacheAXI interface channel*
	reg 				interface_inst_req;
	reg [`InstAddrBus]	interface_inst_araddr;
	wire 				interface_inst_rvalid_i;
	wire [`WayBus]		interface_inst_rdata_i;
	//*Cpu output operation*
	
	//wire 				ICache_stall;
	wire [`InstBus]		ICache_inst1;
	wire 				ICache_inst1_valid_o;
	wire 				ICache_inst2_valid_o;
	//wire 				ICache_single_issue;
	always@(*)begin
		if(rst|flush)begin
			ICache_req 				<= `Invalid;
			interface_inst_req 		<= `Invalid;
			interface_inst_araddr 	<= `ZeroWord;
//			inst_stall_o 			<= `Valid;
			inst1_o 				<= `ZeroWord;
			inst1_valid_o			<= `Invalid;
			inst2_valid_o			<= `Invalid;
		end
		else if(inst_uncached)begin
			ICache_req 				<= `Invalid;
			interface_inst_req 		<= 	inst_req_i & ~interface_inst_rvalid_i;
			interface_inst_araddr 	<= 	inst_paddr_i;
			//inst_stall_o 			<= ~interface_inst_rvalid_i & inst_req_i;
			inst1_o 				<= 	interface_inst_rdata_i[`InstBus];
			inst1_valid_o			<= 	interface_inst_rvalid_i;
			inst2_valid_o			<= `Invalid;
		end
		else begin
			ICache_req 				<= 	inst_req_i;
			interface_inst_req 		<= 	mem_inst_ren_o;
			interface_inst_araddr 	<= 	mem_inst_araddr_o;
			//inst_stall_o 			<= 	ICache_stall;
			inst1_o 				<= 	ICache_inst1;
			inst1_valid_o			<= 	ICache_inst1_valid_o;
			inst2_valid_o			<= 	ICache_inst2_valid_o;
		end
	end
	
	
	
	//**Data READ Uncached Operation**
	//*Uncached: CacheAXI_Interface*
	reg 				interface_uncached_data_rreq;
	reg [`InstAddrBus]	interface_uncached_data_araddr;
	wire 				interface_uncached_data_rvalid_i;
	wire [`DataBus]		interface_uncached_data_rdata_i;
	//*Control operation*
	reg 				DCache_rreq;
	wire 				dcache_stall;
	wire [`StateBus]	dcache_state;
	reg 				data_uncached_rstall;
	wire[`DataBus] 		DCache_rdata_o;
	
	//**Data WRITE Uncached Operation**
	//*Uncached: CacheAXI_Interface*
	reg 				interface_uncached_data_wreq;
	reg [`DataAddrBus]	interface_uncached_data_awaddr;
	reg [`DataBus]		interface_uncached_data_wdata;
	wire 				interface_uncached_data_bvalid_i;
	//*Control operation*
	reg 				DCache_wreq;
	reg 				data_uncached_wstall;
	reg 				uncached_state;
	reg 				uncached_next_state;
	
	//Read Channel
	//data keeper
	reg [`DataAddrBus] data_paddr_2;
	always@(posedge clk)begin
        // keep reading uncached addr to communicate with AXI
        if(uncached_state == `DATA_CACHED)
            data_paddr_2 <= data_paddr_i;
        //next operation: update addr( ready to operate another uncached signal)
        else if(interface_uncached_data_rvalid_i)begin
            data_paddr_2 <= data_paddr_i;
        end
	end
	always@(posedge clk)begin
		if(rst)
			uncached_state <= `DATA_CACHED;
		else 
			uncached_state <= uncached_next_state;
	end
	always@(*)begin
         uncached_next_state <= uncached_state;
		case(uncached_state)
			`DATA_CACHED:begin//When dcache is not working and current request is uncached
				if(data_rreq_i & data_uncached & (dcache_state == `STATE_LOOK_UP))
					uncached_next_state <= `DATA_UNCACHED;
			end
			`DATA_UNCACHED:begin//When uncached operation is finished and next one is not uncached operation
				if(interface_uncached_data_rvalid_i & !(data_rreq_i & data_uncached))
					uncached_next_state <= `DATA_CACHED;
			end
			default:;
		endcase
	end
	always@(*)begin
		if(rst)begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= `Invalid;
				interface_uncached_data_araddr 	<= `ZeroWord;
				data_uncached_rstall			<= `Invalid;
				data_rdata_o					<= `ZeroWord;
		end
		else if(uncached_state == `DATA_CACHED)begin
			if(uncached_next_state == `DATA_UNCACHED)begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= `Valid;
				interface_uncached_data_araddr 	<= 	data_paddr_i;
				data_rdata_o					<= 	interface_uncached_data_rdata_i;
				data_uncached_rstall			<= `Invalid;
			end
			else begin
				DCache_rreq 					<=  data_rreq_i;
				interface_uncached_data_rreq 	<= `Invalid;
				interface_uncached_data_araddr 	<=  data_paddr_i;
				data_uncached_rstall			<= `Invalid;
				data_rdata_o					<=  DCache_rdata_o;
			end
		end
		else if(uncached_state == `DATA_UNCACHED)begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= 	~interface_uncached_data_rvalid_i;
				interface_uncached_data_araddr 	<= 	data_paddr_2;
				data_uncached_rstall			<= ~interface_uncached_data_rvalid_i;
				data_rdata_o					<= 	interface_uncached_data_rdata_i;
		end
		else begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= `Invalid;
				interface_uncached_data_araddr 	<= `ZeroWord;
				data_uncached_rstall			<= `Invalid;
				data_rdata_o					<= `ZeroWord;
		end
	end
	
	//Write Channel
	always@(*)begin
		if(rst)begin
			//write
			DCache_wreq						<= `Invalid;
			interface_uncached_data_wreq	<= `Invalid;
			interface_uncached_data_awaddr  <= `ZeroWord;
			interface_uncached_data_wdata   <= `ZeroWord;
			data_uncached_wstall    		<= `ZeroWord;
		end
		else if(data_uncached)begin
			//write
			DCache_wreq						<= `Invalid;
			interface_uncached_data_wreq	<=  data_wreq_i & ~interface_uncached_data_bvalid_i;
			interface_uncached_data_awaddr  <=  data_paddr_i;
			interface_uncached_data_wdata   <=  data_wdata_i;
			data_uncached_wstall    		<= ~interface_uncached_data_bvalid_i & data_wreq_i;
		end
		else begin
			//write
			DCache_wreq						<=  data_wreq_i;
			interface_uncached_data_wreq	<= `Invalid;
			interface_uncached_data_awaddr  <=  data_waddr_i;
			interface_uncached_data_wdata   <=  data_wdata_i;
			data_uncached_wstall    		<= `Invalid;
		end
	end
	assign data_stall_o = data_uncached_rstall | data_uncached_wstall | dcache_stall;
	
//////////////////////////////////////////////////////////////////////////////////
///////////////////////////ICache Flush Control///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	wire is_process_cached_inst;//VALID: ICache request for loading inst from mem
	reg ICache_flush;
	assign pc_stall_o = ICache_flush | ICache_stall;//When ICache stops, pc should not move.
	always@(posedge clk)begin
		if(rst)
			ICache_flush <= `Invalid;
		else if(is_process_cached_inst & flush & !mem_inst_rvalid_i)begin//read mem but not end
			ICache_flush <= `Valid;
		end
		else if(mem_inst_rvalid_i == `Valid)begin
			ICache_flush <= `Invalid;
		end
	end


//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Body Of Cache ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
	
	ICache_pipeline ICache0(

		clk,
		rst|ICache_flush|flush,
//		is_mem_request,
		
		//read inst request
		ICache_req,
//		flush,
		inst_vaddr_i,
		inst_paddr_i,
		
		//read inst result
		ICache_hit,
		ICache_inst1,
		inst2_o,
		inst1_addr_o,
		inst2_addr_o,
		ICache_inst1_valid_o,
		ICache_inst2_valid_o,
		ICache_stall,
		//ICache_single_issue,
		
		mem_inst_rvalid_i,
		mem_inst_rdata_i,
		mem_inst_ren_o,
		mem_inst_araddr_o
		
		);	
	DCache_pipeline DCache0(

		clk,
		rst,
		
		DCache_rreq,
		DCache_wreq,
		data_paddr_i,
		data_wdata_i,
		data_wsel_i,
		DCache_hit,
		data_rvalid_o,
		DCache_rdata_o,
		
		dcache_stall,
		dcache_state,
		
		mem_data_rvalid_i,
		mem_data_rdata_i,
		mem_data_ren_o,
		mem_data_araddr_o,
		
		mem_data_bvalid_i,
		mem_data_wen_o,
		mem_data_wdata_o,
		mem_data_awaddr_o
    
    );
    assign mem_inst_rvalid_i = interface_inst_rvalid_i;
    assign mem_inst_rdata_i = interface_inst_rdata_i;
    
    //wire [3:0] sel_from_stbuff;
    
	CacheAXI_Interface CacheAXI_Interface0(
		clk,
		rst,
		data_wsel_i,
		//ICahce: Read Channel
		interface_inst_req,
		interface_inst_araddr,
		inst_uncached,
		interface_inst_rvalid_i,
		interface_inst_rdata_i,
		is_process_cached_inst,
		
		//Data: Read Channel
		mem_data_ren_o,
		mem_data_araddr_o,
		data_uncached,
		mem_data_rvalid_i,
		mem_data_rdata_i,
		
		//Data: Write Channel
		mem_data_wen_o,
		mem_data_wdata_o,
		mem_data_awaddr_o,
		mem_data_bvalid_i,
		
		//Data Uncached: Read Channel
		interface_uncached_data_rreq,
		interface_uncached_data_araddr,
		interface_uncached_data_rvalid_i,
		interface_uncached_data_rdata_i,
		
		//Data Uncached: Write Channel
		interface_uncached_data_wreq,
		interface_uncached_data_wdata,
		interface_uncached_data_awaddr,
		interface_uncached_data_bvalid_i,
		
		//AXI Communicate
		axi_ce_o,
		axi_sel_o,
		//AXI read
		axi_rdata_i,        //?????cache????????
		axi_rvalid_i,  //???????????
		axi_ren_o,
		axi_rready_o,   //cache????????
		axi_raddr_o,
		axi_rlen_o,		//read burst length
		//AXI write
		axi_bvalid_i,   //§Õ???,???beat????¦²?????????????????
		axi_wen_o,
		axi_waddr_o,
		axi_wdata_o,    //cache???????????????????§Õ??????
		axi_wvalid_o,   //cache???????§Õ???????????????
		axi_wlast_o,    //cache§Õ??????????
		axi_wlen_o		//read burst length
	);

endmodule
