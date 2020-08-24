module mycpu_top(
input wire      aclk,
	input wire     aresetn,
	
    input wire[5:0] ext_int,
    
    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       ,
	output wire                    timer_int_o,
	
	//debug
	output wire[`InstAddrBus]           debug_wb_pc0,
	output wire                         debug_wb_rf_wen0,
	output wire[4:0]                    debug_wb_rf_wnum0,
	output wire[`RegBus]                debug_wb_rf_wdata0,
	
	output wire[`InstAddrBus]           debug_wb_pc1,
	output wire                         debug_wb_rf_wen1,
	output wire[4:0]                    debug_wb_rf_wnum1,
	output wire[`RegBus]                debug_wb_rf_wdata1,
	
	output wire[`InstAddrBus]           debug_wb_pc,
	output wire[3:0]                    debug_wb_rf_wen,
	output wire[4:0]                    debug_wb_rf_wnum,
	output wire[`RegBus]                debug_wb_rf_wdata
	);
	
	////////////////////////////////////////////////////////////
	//ATTENTION: TIMER_INT_O AND DEBUG SIGNALS ARE EMPTY////////
	////////////////////////////////////////////////////////////
	
	//signal "int" is not connetcted
	
	//Inst
	wire 				inst_req_i;
	wire[`RegBus]		inst_vaddr_i;
	wire 				inst_hit_o;
	wire 				inst_valid_o;
	wire[`InstBus] 		inst1_o;
	wire[`InstBus] 		inst2_o;
	wire[`InstAddrBus] inst1_addr_o;
	wire[`InstAddrBus] inst2_addr_o;
    wire[`SIZE_OF_CORR_PACK] corr_pack0_from_cache_o;
    wire[`SIZE_OF_CORR_PACK] corr_pack1_from_cache_o;
	wire 				inst1_valid_o;
	wire 				inst2_valid_o;
	wire 				pc_stall_o;
	// wire 				single_shot;
	wire               flush;//CPU is running flush, which forces ICache to stop
    wire [`SIZE_OF_CORR_PACK] corr_pack0_to_cache_o;
    wire [`SIZE_OF_CORR_PACK] corr_pack1_to_cache_o;
	wire 				is_pc_branch_i;
	wire 				is_pcPlus4_branch_i;
	wire [`InstAddrBus]	pc_branch_dest_i;
	wire [`InstAddrBus]	pcPlus4_branch_dest_i;
	
	//pc control
	wire [`InstAddrBus] npc_from_cache_o;
	
	wire 				data_stall_o;
    wire 				data_ren_i;
    wire[`DataAddrBus]	data_vaddr_i;
    wire 				data_rvalid_o;
    wire[`RegBus]		data_rdata_o;
    wire 				data_wen_i;
    wire[`RegBus]		data_wdata_i;
    wire[`DataAddrBus]	data_awaddr_i;
    wire[3:0] 			data_wsel;
    wire 				data_bvalid_o;
	
	//AXI Communicate
	wire             axi_ce_o;
	//AXI read
	wire[`RegBus]    axi_rdata_i;
	wire             axi_rvalid_i;
	wire             axi_ren_o;
	wire             axi_rready_o;
	wire[`RegBus]    axi_raddr_o;
	wire [3:0]       axi_rlen_o;		//read burst length
	//AXI write
	wire             axi_bvalid_i;
    wire [3:0]       axi_wsel_o;
    wire [3:0]       axi_rsel_o;
	wire             axi_wen_o;
	wire[`RegBus]    axi_waddr_o;
	wire[`RegBus]    axi_wdata_o;    //cache
	wire             axi_wvalid_o;   //cache
	wire             axi_wlast_o;    //cache
	wire [3:0]       axi_wlen_o;		//write burst length
	
	mycpu mycpu0(
		aclk,
		aresetn,
		{timer_int_o,ext_int[4:0]},//ext_int,
		flush,//CPU is running flush, which forces ICache to stop
		timer_int_o,
		
		
		pc_stall_o,
		inst1_o,
		inst2_o,
		inst1_addr_o,
		inst2_addr_o,
        corr_pack0_from_cache_o,
        corr_pack1_from_cache_o,
		inst1_valid_o,
		inst2_valid_o,
		inst_req_i,
		inst_vaddr_i,
		
		npc_from_cache_o,
		
        corr_pack0_to_cache_o,
        corr_pack1_to_cache_o,
	    is_pc_branch_i,
	    is_pcPlus4_branch_i,
	    pc_branch_dest_i,
	    pcPlus4_branch_dest_i,
		
		
		data_rdata_o,
		data_stall_o,
		data_ren_i,
		data_vaddr_i,
		data_wen_i,
		data_awaddr_i,
		data_wdata_i,
		data_wsel,

        debug_wb_pc0,
    	debug_wb_rf_wen0,
        debug_wb_rf_wnum0,
        debug_wb_rf_wdata0,
	
	    debug_wb_pc1,
	    debug_wb_rf_wen1,
	    debug_wb_rf_wnum1,
	    debug_wb_rf_wdata1
		
    );
	
	Cache_pipeline cache0(

    aclk,
    ~aresetn,
    //bpu
	is_pc_branch_i,
	is_pcPlus4_branch_i,
	pc_branch_dest_i,
	pcPlus4_branch_dest_i,
    corr_pack0_to_cache_o,
    corr_pack1_to_cache_o,
    corr_pack0_from_cache_o,
    corr_pack1_from_cache_o,
	
	//pc control
	npc_from_cache_o,
	
	//Inst
	inst_req_i,
	inst_vaddr_i,
	inst_hit_o,
	inst_valid_o,
	inst1_o,
	inst2_o,
	inst1_addr_o,
	inst2_addr_o,
	inst1_valid_o,
	inst2_valid_o,
	pc_stall_o,
	// single_shot,
	flush,//CPU is running flush, which requires ICache to stop
    
	data_stall_o,
    data_ren_i,
    data_vaddr_i,
    data_rvalid_o,
    data_rdata_o,
    data_wen_i,
    data_wdata_i,
    data_awaddr_i,
    data_wsel,
    // data_bvalid_o,
	
	//AXI Communicate
	axi_ce_o,
    axi_wsel_o,
    axi_rsel_o,
	//AXI read
	axi_rdata_i,   
	axi_rvalid_i,  
	axi_ren_o,
	axi_rready_o,  
	axi_raddr_o,
	axi_rlen_o,		//read burst length
	
	axi_bvalid_i,
	axi_wen_o,
	axi_waddr_o,
	axi_wdata_o,    
	axi_wvalid_o,   
	axi_wlast_o,    
	axi_wlen_o		//write burst length
    );
	
	wire       stallreq;
	// wire       ax_flush;
	// wire [4:0] ax_stall;
	wire [`AXBURST]   burst_type;
	wire [`AXSIZE]    burst_size;
	assign ax_flush = 1'b0;
	assign ax_stall = 5'b0;
	assign burst_type = 2'h1;
	assign burst_size = 3'h2;
	
	my_axi_interface axi_interface0(
        aclk,
        aresetn, 
        
        1'b0,
        6'h0,
        stallreq,//?????
                
        //Cache////////
        axi_ce_o,
        axi_wen_o,
        axi_ren_o,
        axi_wsel_o,
        axi_rsel_o,
        axi_raddr_o,
        axi_waddr_o,  
        axi_wdata_o,   
        axi_rready_o,  
        axi_wvalid_o,  
        axi_wlast_o,   
        axi_rdata_i,
        axi_rvalid_i,
        axi_bvalid_i,  
        //burst
        burst_type, 
        burst_size,
        axi_rlen_o,
        axi_wlen_o,
       
        //axi///////
        //ar
        arid         ,
        araddr       ,
        arlen        ,
        arsize       ,
        arburst      ,
        arlock       ,
        arcache      ,
        arprot       ,
        arvalid      ,
        arready      ,
        
        //r           
        rid          ,
        rdata        ,
        rresp        ,
        rlast        ,
        rvalid       ,
        rready       ,
        
        //aw          
        awid         ,
        awaddr       ,
        awlen        ,
        awsize       ,
        awburst      ,
        awlock       ,
        awcache      ,
        awprot       ,
        awvalid      ,
        awready      ,
        
        //w          
        wid          ,
        wdata        ,
        wstrb        ,
        wlast        ,
        wvalid       ,
        wready       ,
        
        //b           
        bid          ,
        bresp        ,
        bvalid       ,
        bready       
    );
endmodule