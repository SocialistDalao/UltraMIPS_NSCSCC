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
    
	//bpu
	input wire 				is_pc_branch_i,
	input wire 				is_pcPlus4_branch_i,
	input wire [`InstAddrBus]	pc_branch_dest_i,
	input wire [`InstAddrBus]	pcPlus4_branch_dest_i,
    input wire [`SIZE_OF_CORR_PACK] corr_pack0_i,
    input wire [`SIZE_OF_CORR_PACK] corr_pack1_i,
    output wire [`SIZE_OF_CORR_PACK] corr_pack0_o,
    output wire [`SIZE_OF_CORR_PACK] corr_pack1_o,
	
	//pc control
	output reg [`InstAddrBus] npc_o,
	
	//Inst
	input wire 					inst_req_i,//�ߵ�ƽ��ʾcpu����ȡָ��
	input wire [`RegBus]		inst_vaddr_i,
	output wire 				inst_hit_o,//��ѡ����ʾICache����
	output wire 				inst_valid_o,//�ߵ�ƽ��ʾ��ǰ���inst��Ч
	output reg [`InstBus] 		inst1_o,
	output wire [`InstBus] 		inst2_o,
	output wire [`InstAddrBus] 	inst1_addr_o,
	output wire [`InstAddrBus] 	inst2_addr_o,
    output reg 					inst1_valid_o,
    output reg 					inst2_valid_o,
	output wire					pc_stall_o,
	//output reg 				    inst_stall_o,//�ߵ�ƽ��ʾ���ڴ���ȡָ����
	//output reg 				    single_issue_o,//�ߵ�ƽ��ʾICacheֻ�ܹ�֧�ֵ���
	input wire 					flush,
    
	//Data stall
	output wire 				data_stall_o,//�ߵ�ƽ��ʾ���ڴ����ô�����
	//Data : Read Channel
    input wire 					data_rreq_i,//�ߵ�ƽ��ʾcpu����ȡ����
    input wire[`DataAddrBus]	data_raddr_i,
    output wire 				data_rvalid_o,//�ߵ�ƽ��ʾ��ǰ���data��Ч
    output reg [`RegBus]		data_rdata_o,
	//Data: Write Channel
    input wire 					data_wreq_i,//�ߵ�ƽ��ʾcpu����д����
    input wire[`RegBus]			data_wdata_i,
    input wire [`DataAddrBus]	data_waddr_i,
    input wire [3:0] 			data_wsel_i,//ѡ����Ҫд���λ��ʹ��?
//    output wire data_bvalid_o,
	
	//AXI Communicate
	output wire             axi_ce_o,
	output wire [3:0]       axi_wsel_o,
	output wire [3:0]       axi_rsel_o,
	//AXI read
	input wire[`RegBus]    	axi_rdata_i,        //���ص�cache�Ķ�ȡ����
	input wire             	axi_rvalid_i,  //�������ݿɻ�ȡ
	output wire             axi_ren_o,
	output wire             axi_rready_o,   //cache��׼���ö�
	output wire[`RegBus]    axi_raddr_o,
	output wire [3:0]       axi_rlen_o,		//read burst length
	//AXI write
	input wire             	axi_bvalid_i,   //д��Ӧ,ÿ��beat��һ�Σ��ɹ�����Դ���һ����?
	output wire             axi_wen_o,
	output wire[`RegBus]    axi_waddr_o,
	output wire[`RegBus]    axi_wdata_o,    //cache��ñ�֤��ÿ��ʱ���ظ���ҿд������?
	output wire             axi_wvalid_o,   //cache��׼����д�����ݣ�����ǳ���?
	output wire             axi_wlast_o,    //cacheд���һ������?
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
	wire [`WayBus]		mem_inst_rdata_i;//???????§኉wire 				mem_inst_ren_o;
	wire [`InstAddrBus]	mem_inst_araddr_o;
    //data read
    wire 				mem_data_rvalid_i;
    wire [`WayBus]		mem_data_rdata_i;
    wire 				mem_data_ren_o;
    wire [`DataAddrBus]	mem_data_araddr_o;
	//data write
    wire 				mem_data_bvalid_i;
    wire 				mem_data_wen_o;
    wire [`WayBus] 		mem_data_wdata_o;//???????§�?  
    wire [`DataAddrBus]	mem_data_awaddr_o;
	
	//TLB
//	wire inst_uncached = `Invalid;
	wire inst_uncached;
	wire [`InstAddrBus]inst_paddr_i;
	TLB tlb_inst(
    .virtual_addr_i(inst_vaddr_i),
    .physical_addr_o(inst_paddr_i)
    ,.uncached(inst_uncached)
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
	wire [`RegBus]		interface_inst_rdata_i;
	//*Cpu output operation*
	
	//wire 				ICache_stall;
	wire [`InstBus]		ICache_inst1;
	wire 				ICache_inst1_valid_o;
	wire 				ICache_inst2_valid_o;
	//wire 				ICache_single_issue;
	
	//Uncached inst flush problem
	reg                 inst_uncached_flush;
	always@(posedge clk)begin
	   if(rst)
	       inst_uncached_flush <= `Invalid;
       else if(flush & !interface_inst_rvalid_i)
	       inst_uncached_flush <= `Valid;
       else if(interface_inst_rvalid_i)
	       inst_uncached_flush <= `Invalid;
	end
	
	always@(*)begin
		if(rst)begin
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
			inst1_o 				<= 	interface_inst_rdata_i;
			inst1_valid_o			<= 	interface_inst_rvalid_i & !inst_uncached_flush;
			inst2_valid_o			<= `Invalid;
		end
		else begin
			ICache_req 				<= 	inst_req_i;
			interface_inst_req 		<= 	`Invalid;
			interface_inst_araddr 	<= 	mem_inst_araddr_o;
			//inst_stall_o 			<= 	ICache_stall;
			inst1_o 				<= 	ICache_inst1;
			inst1_valid_o			<= 	ICache_inst1_valid_o & inst1_valid_en_2;
			inst2_valid_o			<= 	ICache_inst2_valid_o & inst2_valid_en_2;
		end
	end
	
	
	
	//**Data READ Uncached Operation**
	//*Uncached: CacheAXI_Interface*
	reg 				interface_uncached_data_rreq;
	reg [`InstAddrBus]	interface_uncached_data_araddr;
	wire 				interface_uncached_data_rvalid_i;
	wire [`DataBus]		interface_uncached_data_rdata_i;
	reg  [3:0]          interface_data_wsel;
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
	reg [`DataAddrBus] data_wsel_2;
	always@(posedge clk)begin
        // keep reading uncached addr to communicate with AXI
        if(uncached_state == `DATA_CACHED)begin
            data_paddr_2 <= data_paddr_i;
            data_wsel_2 <= data_wsel_i;
        end
        //next operation: update addr( ready to operate another uncached signal)
        else if(interface_uncached_data_rvalid_i)begin
            data_paddr_2 <= data_paddr_i;
            data_wsel_2 <= data_wsel_i;
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
				if(data_rreq_i & data_uncached & (dcache_stall == `Invalid))
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
				interface_data_wsel             <=  data_wsel_i;
		end
		else if(uncached_state == `DATA_CACHED)begin
			if(uncached_next_state == `DATA_UNCACHED)begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= `Valid;
				interface_uncached_data_araddr 	<= 	data_paddr_i;
				data_rdata_o					<= 	interface_uncached_data_rdata_i;
				data_uncached_rstall			<= `Invalid;
				interface_data_wsel             <=  data_wsel_i;
			end
			else begin
				DCache_rreq 					<=  data_rreq_i;
				interface_uncached_data_rreq 	<= `Invalid;
				interface_uncached_data_araddr 	<=  data_paddr_i;
				data_uncached_rstall			<= `Invalid;
				data_rdata_o					<=  DCache_rdata_o;
				interface_data_wsel             <=  data_wsel_i;
			end
		end
		else if(uncached_state == `DATA_UNCACHED)begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= 	~interface_uncached_data_rvalid_i;
				interface_uncached_data_araddr 	<= 	data_paddr_2;
				data_uncached_rstall			<= ~interface_uncached_data_rvalid_i;
				data_rdata_o					<= 	interface_uncached_data_rdata_i;
				interface_data_wsel             <=  data_wsel_2;
		end
		else begin
				DCache_rreq 					<= `Invalid;
				interface_uncached_data_rreq 	<= `Invalid;
				interface_uncached_data_araddr 	<= `ZeroWord;
				data_uncached_rstall			<= `Invalid;
				data_rdata_o					<= `ZeroWord;
				interface_data_wsel             <=  data_wsel_i;
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
			interface_uncached_data_awaddr  <=  data_paddr_i;
			interface_uncached_data_wdata   <=  data_wdata_i;
			data_uncached_wstall    		<= `Invalid;
		end
	end
	assign data_stall_o = data_uncached_rstall | data_uncached_wstall | dcache_stall;

//////////////////////////////////////////////////////////////////////////////////
///////////////////////////ICache Flush Control///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

//	wire is_process_cached_inst;//VALID: ICache request for loading inst from mem
	assign pc_stall_o = ICache_stall;//When ICache stops, pc should not move.
	//reg ICache_flush;
	//assign pc_stall_o = ICache_flush | ICache_stall;//When ICache stops, pc should not move.
	//always@(posedge clk)begin
	//	if(rst)
	//		ICache_flush <= `Invalid;
	//	else if(is_process_cached_inst & flush & !mem_inst_rvalid_i)begin//read mem but not end
	//		ICache_flush <= `Valid;
	//	end
	//	else if(mem_inst_rvalid_i == `Valid)begin
	//		ICache_flush <= `Invalid;
	//	end
	//end


	
//////////////////////////////////////////////////////////////////////////////////
///////////////////////////ICache Dynamic BPU Control/////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	//I/O
	wire [`InstAddrBus] pc_i = inst_vaddr_i;
	
	//Fetch inst control signals
	reg 				inst1_valid_en_1;
	reg 				inst1_valid_en_2;
	reg 				inst2_valid_en_1;
	reg 				inst2_valid_en_2;
//	reg [`InstAddrBus]	pc_branch_dest_2;
//	reg [`InstAddrBus]	pcPlus4_branch_dest_2;
	reg [`InstAddrBus]	branch_dest_2;
    reg [`SIZE_OF_CORR_PACK] corr_pack0_2;
    reg [`SIZE_OF_CORR_PACK] corr_pack1_2;
	//assign corr_pack0_o = corr_pack0_2;
	//assign corr_pack1_o = corr_pack1_2;
	
	//ICache state
    wire ICache_is_working;
    wire is_ICache_pipeline2_empty;
	
	//Signal in control
	wire sign_pc_edge = (pc_i[4:2] == 3'b111);
	wire [`InstAddrBus] pc_plus4 = pc_i + 4;
	wire [`InstAddrBus] pc_plus8 = pc_i + 8;
	
	
	reg [1:0]				BPU_inst_state;
	//keep data for one more operation
	always@(posedge clk)begin
		//keep data
		if(rst)begin
			inst1_valid_en_2         <= `Valid;
			inst2_valid_en_2         <= `Valid;
//            pc_branch_dest_2 	     <= `ZeroWord;
//			pcPlus4_branch_dest_2 	 <= `ZeroWord;
			corr_pack0_2 	         <= 0;
			corr_pack1_2 	         <= 0;
		end
		//Flush: if ICache is working on old request, the inst is wrong definitely,
		//       while ICache is not working the inst will process right.
		else if(flush)begin
			inst1_valid_en_2         <= ~ICache_is_working;
			inst2_valid_en_2         <= ~ICache_is_working;
			corr_pack0_2 	 		<= {corr_pack0_i[`CRR_PRED_DIR],87'd0};
			corr_pack1_2 	 		<= {corr_pack1_i[`CRR_PRED_DIR],87'd0};
		end
		else if(ICache_inst1_valid_o == `Valid)begin
			inst1_valid_en_2 		<= inst1_valid_en_1;
			inst2_valid_en_2 		<= inst2_valid_en_1;
//			pc_branch_dest_2 	 	<= pc_branch_dest_i;
//			pcPlus4_branch_dest_2 	 <= pcPlus4_branch_dest_i;
			corr_pack0_2 	 		<= corr_pack0_i;
			corr_pack1_2 	 		<= corr_pack1_i;
		end
	end
	
	//Cached Dynamic Inst Fetch
	always@(posedge clk)begin
		if(rst)
			BPU_inst_state <= `GetNormalInst;
		else if(flush)
			BPU_inst_state <= `GetNormalInst;
		else if ((ICache_inst1_valid_o & ICache_req)|(ICache_req & is_ICache_pipeline2_empty))begin
			case(BPU_inst_state)
				`GetNormalInst:begin
                    if(is_pc_branch_i & sign_pc_edge) begin
                        BPU_inst_state <= `OnlyGetOneInst;
                        branch_dest_2 <= pc_branch_dest_i;
                    end
                    else if(is_pcPlus4_branch_i & !sign_pc_edge) begin
                        BPU_inst_state <= `OnlyGetOneInst;
                        branch_dest_2 <= pcPlus4_branch_dest_i;
                    end
                    else if(is_pcPlus4_branch_i & sign_pc_edge) begin
                        BPU_inst_state <= `OnlyGetTwoInst;
                        branch_dest_2 <= pcPlus4_branch_dest_i;
                    end
				end
				`OnlyGetOneInst:	BPU_inst_state <= `GetNormalInst;
				`OnlyGetTwoInst:	begin
				    if(sign_pc_edge)
				        BPU_inst_state <= `OnlyGetOneInst;
                    else
				        BPU_inst_state <= `GetNormalInst;
				end
				default:			BPU_inst_state <= `GetNormalInst;
			endcase
		end
		else
			BPU_inst_state <= BPU_inst_state;
	
	end
	
	//Uncached Dynamic Inst Fetch
	reg    uncachedInst_ready_to_jump;
	reg [`InstAddrBus]   uncachedInst_jump_dest;
	always@(posedge clk)begin
       if(rst | flush)
           uncachedInst_ready_to_jump <= `Invalid;
        else if(uncachedInst_ready_to_jump & inst1_valid_o)
            uncachedInst_ready_to_jump <= `Invalid;
       else if(inst_uncached & is_pc_branch_i & inst1_valid_o)begin
            uncachedInst_jump_dest <= pc_branch_dest_i;
           uncachedInst_ready_to_jump <= `Valid;
       end
	end
	//Add More Operation of Inst Valid
	always@(*)begin
	    npc_o            <=  pc_i;
		inst1_valid_en_1 <= `Valid;
		inst2_valid_en_1 <= `Valid;
		case(BPU_inst_state)
			`GetNormalInst:begin
				if(ICache_stall)begin//ICache operation not finished, stall
					npc_o <= pc_i;
					inst1_valid_en_1 <= `Valid;
					inst2_valid_en_1 <= `Valid;
				end
				else if(is_pc_branch_i)begin
					if(sign_pc_edge)begin
						npc_o <= pc_plus4;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Invalid;
					end
					else begin
						npc_o <= pc_branch_dest_i;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Valid;
					end
				end
				else if(is_pcPlus4_branch_i)begin
					if(sign_pc_edge)begin
						npc_o <= pc_plus4;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Invalid;
					end
					else begin
						npc_o <= pc_plus8;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Valid;
					end
				end
				else begin// normal read
					if(sign_pc_edge)begin
						npc_o <= pc_plus4;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Invalid;
					end
					else begin
						npc_o <= pc_plus8;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Valid;
					end
				end
			end
			`OnlyGetOneInst: begin
				if(ICache_stall)begin//Cache operation not finished, stall
					npc_o <= pc_i;
					inst1_valid_en_1 <= `Valid;
					inst2_valid_en_1 <= `Invalid;
				end
				else begin
					npc_o <= branch_dest_2;
					inst1_valid_en_1 <= `Valid;
					inst2_valid_en_1 <= `Invalid;
				end
			end
			`OnlyGetTwoInst: begin
				if(ICache_stall)begin//Cache operation not finished, stall
					npc_o <= pc_i;
					inst1_valid_en_1 <= `Valid;
					inst2_valid_en_1 <= `Valid;
				end
				else begin
					if(sign_pc_edge)begin
						npc_o <= pc_plus4;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Invalid;
					end
					else begin
						npc_o <= branch_dest_2;
						inst1_valid_en_1 <= `Valid;
						inst2_valid_en_1 <= `Valid;
					end
				end
			end
			default:;
		endcase
		if(inst_uncached)begin
			if(!inst1_valid_o)begin
				npc_o <= pc_i;
			end
			else if(uncachedInst_ready_to_jump)begin
				npc_o <= uncachedInst_jump_dest;
			end
			else begin
				npc_o <= pc_i + 4;
			end
		end
	end
	
	//output of BPU related info
    wire [`SIZE_OF_CORR_PACK] ICache_corr_pack0 ;//= corr_pack0_i;
    wire [`SIZE_OF_CORR_PACK] ICache_corr_pack1 ;//= corr_pack1_i;
	
	assign corr_pack0_o = (inst_uncached)? corr_pack0_i:ICache_corr_pack0;
	assign corr_pack1_o = (inst_uncached)? corr_pack1_i:ICache_corr_pack1;

//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Body Of Cache ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
	
	ICache_pipeline ICache0(

		clk,
		rst,
		ICache_is_working,
		is_ICache_pipeline2_empty,
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
		mem_inst_araddr_o,
		
		corr_pack0_i,////////////////
		corr_pack1_i,////////////////
		ICache_corr_pack0,///////////////
		ICache_corr_pack1 ///////////////
		
		);	
	DCache_pipeline DCache0(

		.clk              (clk),
		.rst              (rst),
		
		.cpu_rreq_i       (DCache_rreq),
		.cpu_wreq_i       (DCache_wreq),
		.virtual_addr_i   (virtual_addr_i),
		.physical_addr_i  (data_paddr_i),
		.cpu_wdata_i      (data_wdata_i),
		.cpu_wsel_i       (data_wsel_i),
//		DCache_hit,
		.cpu_data_valid_o (data_rvalid_o),
		.cpu_data_final_o (DCache_rdata_o),
		
		.cpu_stall_o      (dcache_stall),
//		dcache_state,
		
		.mem_rvalid_i     (mem_data_rvalid_i),
		.mem_rdata_i      (mem_data_rdata_i),
		.mem_ren_o        (mem_data_ren_o),
		.mem_araddr_o     (mem_data_araddr_o),
		
		.mem_bvalid_i     (mem_data_bvalid_i),
		.mem_wen_o        (mem_data_wen_o),
		.mem_wdata_o      (mem_data_wdata_o),
		.mem_awaddr_o     (mem_data_awaddr_o)
    
    );
//    assign mem_inst_rvalid_i = interface_inst_rvalid_i;
//    assign mem_inst_rdata_i = interface_inst_rdata_i;

    //wire [3:0] sel_from_stbuff;
    
	CacheAXI_Interface CacheAXI_Interface0(
		clk,
		rst,
		interface_data_wsel,
		//Cached Inst: Read Channel
		mem_inst_ren_o,
		mem_inst_araddr_o,
//		inst_uncached,
		mem_inst_rvalid_i,
		mem_inst_rdata_i,
//		is_process_cached_inst,
		
		//Uncached Inst: Read Channel
		interface_inst_req,
		interface_inst_araddr,
		interface_inst_rvalid_i,
		interface_inst_rdata_i,
		
		//Cached Data: Read Channel
		mem_data_ren_o,
		mem_data_araddr_o,
		data_uncached,
		mem_data_rvalid_i,
		mem_data_rdata_i,
		
		//CachedData: Write Channel
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
		axi_wsel_o,
		axi_rsel_o,
		//AXI read
		axi_rdata_i,        //���ص�cache�Ķ�ȡ����
		axi_rvalid_i,  //�������ݿɻ�ȡ
		axi_ren_o,
		axi_rready_o,   //cache��׼���ö�
		axi_raddr_o,
		axi_rlen_o,		//read burst length
		//AXI write
		axi_bvalid_i,   //д��Ӧ,ÿ��beat��һ�Σ��ɹ�����Դ���һ����?
		axi_wen_o,
		axi_waddr_o,
		axi_wdata_o,    //cache��ñ�֤��ÿ��ʱ���ظ���ҿд������?
		axi_wvalid_o,   //cache��׼����д�����ݣ�����ǳ���?
		axi_wlast_o,    //cacheд���һ������?
		axi_wlen_o		//read burst length
	);

endmodule
