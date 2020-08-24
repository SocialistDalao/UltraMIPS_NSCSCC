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
module DCache_pipeline(

    input wire                  clk,
    input wire rst,
    
    //cpu data request
    input wire                  cpu_rreq_i,
    input wire                  cpu_wreq_i,
    input wire [`DataAddrBus]   virtual_addr_i,
    input wire [`DataAddrBus]   physical_addr_i,
    input wire [`DataBus]       cpu_wdata_i,
    input wire [3:0]            cpu_wsel_i,
//    output wire hit_o,
    output wire                 cpu_data_valid_o,
    output wire [`DataBus]      cpu_data_final_o,
	
	//cache state
	output reg                  cpu_stall_o,
//	output wire [`StateBus] DCache_state_o,
    
    //mem read
    input wire                  mem_rvalid_i,
    input wire [`WayBus]        mem_rdata_i,
    output wire                 mem_ren_o,
    output wire[`DataAddrBus]   mem_araddr_o,
	//mem write
    input wire                  mem_bvalid_i,
    output wire                 mem_wen_o,
    output wire[`WayBus]        mem_wdata_o,//?????¨¦???¨®??
    output wire [`DataAddrBus]  mem_awaddr_o
    
    //test
    //output [`DirtyBus] dirty
    );
	
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////Hit Rate Calculation//////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	reg [127:0]total_dcache_hit;
	reg [127:0]total_dcache_req;
	always@(posedge clk)begin
		if(rst)
			total_dcache_hit <= 0;
		else if(hit_success)
			total_dcache_hit <= total_dcache_hit + 1;
		if(rst)
			total_dcache_req <= 0;
		else if((cpu_rreq_2|cpu_wreq_2)&& !cpu_stall_o)
			total_dcache_req <= total_dcache_req + 1;
	end
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
	
	//mem_data_i in 2-dimen array
	wire [`DataBus]mem_rdata[`BlockNum-1:0];
   for(genvar i =0 ;i<`BlockNum; i=i+1)begin
		assign mem_rdata[i] = mem_rdata_i[32*(i+1)-1:32*i];
   end
	
	//keep input data
//    (* mark_debug = "true" *)
    reg [`DataAddrBus]	virtual_addr_2;
    reg [`DataAddrBus]	physical_addr_2;
    reg [`RegBus]		cpu_wdata;
	reg 				cpu_rreq_2;
	reg 				cpu_wreq_2;
    reg [3:0]			cpu_wsel_2;
    wire [`DataBus]		wsel_expand = {{8{cpu_wsel_2[3]}} , {8{cpu_wsel_2[2]}} , {8{cpu_wsel_2[1]}} , {8{cpu_wsel_2[0]}}};
    always@(posedge clk)begin
        if(rst)begin
            virtual_addr_2	<= `ZeroWord;
            physical_addr_2	<= `ZeroWord;
            cpu_wdata		<= `ZeroWord;
            cpu_rreq_2 		<= `Invalid;
            cpu_wreq_2 		<= `Invalid;
            cpu_wsel_2 		<= 4'h0;
        end
        else if(cpu_stall_o)begin
            virtual_addr_2 	<= virtual_addr_2;
            physical_addr_2	<= physical_addr_2;
            cpu_wdata 		<= cpu_wdata;
            cpu_rreq_2 		<= cpu_rreq_2;
            cpu_wreq_2 		<= cpu_wreq_2;
            cpu_wsel_2 		<= cpu_wsel_2;
        end
        else begin
            virtual_addr_2 	<= virtual_addr_i;
            physical_addr_2	<= physical_addr_i;
            cpu_wdata 		<= cpu_wdata_i;
            cpu_rreq_2 		<= cpu_rreq_i;
            cpu_wreq_2 		<= cpu_wreq_i;
            cpu_wsel_2 		<= cpu_wsel_i;
        end
    end
	
	//WriteBuffer
	wire [`DataAddrBus]FIFO_waddr;
	reg [`DataBus]FIFO_wdata[`BlockNum-1:0];
//	wire [`DataAddrBus]FIFO_raddr = (cpu_stall_o)? physical_addr_2:physical_addr_i;
	wire [`DataBus]FIFO_rdata[`BlockNum-1:0];
	wire FIFO_hit = `Invalid;
	wire FIFO_wreq;
	wire [`FIFOStateNumLog2-1:0]FIFO_state;
    WriteBuffer WB0(
        .clk(clk),
        .rst(rst),
        //CPU write request
        .cpu_wreq_i(FIFO_wreq),
        .cpu_awaddr_i(FIFO_waddr),
        .cpu_wdata_i({FIFO_wdata[7],
					  FIFO_wdata[6],
					  FIFO_wdata[5],
					  FIFO_wdata[4],
					  FIFO_wdata[3],
					  FIFO_wdata[2],
					  FIFO_wdata[1],
					  FIFO_wdata[0]}
					),//WaySize
        //CPU read request and response
//        .cpu_rreq_i(cpu_rreq_2|cpu_wreq_2),
//        .cpu_araddr_i(FIFO_raddr),
//        .read_hit_o(FIFO_hit),
//        .cpu_rdata_o({FIFO_rdata[7],
//					  FIFO_rdata[6],
//					  FIFO_rdata[5],
//					  FIFO_rdata[4],
//					  FIFO_rdata[3],
//					  FIFO_rdata[2],
//					  FIFO_rdata[1],
//					  FIFO_rdata[0]}
					
//		),//WaySize
        //state
        .state_o(FIFO_state),
        //MEM 
        .mem_bvalid_i(mem_bvalid_i),
        .mem_wen_o(mem_wen_o),
        .mem_wdata_o(mem_wdata_o),
        .mem_awaddr_o(mem_awaddr_o)
    );
   
    
    //BANK 0~7 WAY 0~1
    //biwj indicates bank_i way_j
//    reg [`WayBus] data_cache;
    wire [`DataAddrBus]ram_addr = (cpu_stall_o == `Invalid)? virtual_addr_i : physical_addr_2; 
	reg [`DataBus]cache_wdata[`BlockNum-1:0];
	
    wire [3:0]wea_way0;
    wire [3:0]wea_way1;
    
	wire [`DataBus]way0_cache[`BlockNum-1:0];
//	wire [6:0] ram_addr = (cpu_stall_o)? physical_addr_2[`IndexBus] : virtual_addr_i[`IndexBus];//When stall, maintain the addr of ram 
    simple_dual_ram Bank0_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way0_cache[7]));
   
	wire [`DataBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(cache_wdata[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(way1_cache[7]));                        

    //Tag+Valid
    wire [`TagVBus]tagv_cache_w0;
    wire [`TagVBus]tagv_cache_w1;
    simple_dual_ram TagV0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina({1'b1,physical_addr_2[`TagBus]}),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(tagv_cache_w0));
    simple_dual_ram TagV1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina({1'b1,physical_addr_2[`TagBus]}),.clkb(clk),.enb(`Enable),.addrb(ram_addr[`IndexBus]),.doutb(tagv_cache_w1));  
    
    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[virtual_addr_2[`IndexBus]];
    always@(posedge clk)begin
        if(rst)
            LRU <= 0;
        else if(hit_success == `HitSuccess)//hit: set LRU to bit that is not hit
            LRU[virtual_addr_2[`IndexBus]] <= hit_way0;
        else if(bus_read_success == `Success && hit_fail == `Valid)//not hit: set opposite LRU
            LRU[virtual_addr_2[`IndexBus]] <= ~LRU_pick;
        else
            LRU <= LRU;
    end
    
    //Dirty 
    reg [`DirtyBus] dirty;
	wire write_dirty = dirty[{virtual_addr_2[`IndexBus],LRU_pick}]; 
    always@(posedge clk)begin
        if(rst)
            dirty<=0;
		else if(bus_read_success == `Valid && cpu_rreq_2 == `Valid)//Read not hit
            dirty[{virtual_addr_2[`IndexBus],LRU_pick}] <= `NotDirty;
		else if(bus_read_success == `Success && cpu_wreq_2 == `Valid)//write not hit
            dirty[{virtual_addr_2[`IndexBus],LRU_pick}] <= `Dirty;
		else if((hit_way0|hit_way1) == `HitSuccess && cpu_wreq_2 == `Valid)//write hit but not FIFO
            dirty[{virtual_addr_2[`IndexBus],hit_way1}] <= `Dirty;
        else
            dirty <= dirty;
    end
	
	//Stall
	always@(*)begin 
		if(hit_fail == `Valid)
			cpu_stall_o <= ~bus_read_success;
		//else if (bus_read_success == `Success && FIFO_state == `STATE_FULL && write_dirty == `Valid)//Write buffer FIFO full
		//	cpu_stall_o <= `Valid;
		else 
			cpu_stall_o <= `Invalid;
	end
    
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////State Operation//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
	wire bus_read_success = mem_rvalid_i;
    ////////////////STATE_LOOK_UP ////////////////
	////////////////RAM Coliision ////////////////
	reg ram_collision_way0;
	reg ram_collision_way1;
	//collision keep
    reg [`DataBus]cache_wdata_selected_2;//data collision
    reg [`DataBus]cache_wdata_2[`BlockNum-1:0];//way size data collision
    reg [`DataBus]tagv_way0;//tag collision
    reg [`DataBus]tagv_way1;
	always@(posedge clk)begin
		ram_collision_way0 		<= cpu_stall_o == `Invalid && physical_addr_2[`IndexBus] == virtual_addr_i[`IndexBus] && |wea_way0;
		ram_collision_way1 		<= cpu_stall_o == `Invalid && physical_addr_2[`IndexBus] == virtual_addr_i[`IndexBus] && |wea_way1;
		cache_wdata_selected_2 	<= cache_wdata[virtual_addr_i[4:2]];
		tagv_way0 				<= {1'b1,physical_addr_2[`TagBus]};
		tagv_way1 				<= {1'b1,physical_addr_2[`TagBus]};
		cache_wdata_2[0] 	    <= cache_wdata[0];
		cache_wdata_2[1] 	    <= cache_wdata[1];
		cache_wdata_2[2] 	    <= cache_wdata[2];
		cache_wdata_2[3] 	    <= cache_wdata[3];
		cache_wdata_2[4] 	    <= cache_wdata[4];
		cache_wdata_2[5] 	    <= cache_wdata[5];
		cache_wdata_2[6] 	    <= cache_wdata[6];
		cache_wdata_2[7] 	    <= cache_wdata[7];
	end
	//Collistion data select
    wire [`DataBus]data_way0 = ram_collision_way0 ? //write/read collision
								cache_wdata_selected_2: way0_cache[physical_addr_2[4:2]];
    wire [`DataBus]data_way1 = ram_collision_way1? //write/read collision
								cache_wdata_selected_2: way1_cache[physical_addr_2[4:2]];
								
    wire [`DataBus]way0_2[`BlockNum-1:0];
    wire [`DataBus]way1_2[`BlockNum-1:0];
    for(genvar i = 0; i<`BlockNum; i = i+1)begin
        assign way0_2[i] = ram_collision_way0 ? cache_wdata_2[i] : way0_cache[i];
        assign way1_2[i] = ram_collision_way1 ? cache_wdata_2[i] : way1_cache[i];
    end
    
    wire [`TagVBus]tagv_way0_2 = ram_collision_way0? //write/read collision
								tagv_way0: tagv_cache_w0;
    wire [`TagVBus]tagv_way1_2 = ram_collision_way1? //write/read collision
								tagv_way1: tagv_cache_w1;
	
    ////////////////STATE_FETCH_DATA//////////////////
	//hit judgement
    wire hit_way0 = (tagv_way0_2[19:0]==physical_addr_2[`TagBus] && tagv_way0_2[20]==`Valid)? `HitSuccess : `HitFail;
    wire hit_way1 = (tagv_way1_2[19:0]==physical_addr_2[`TagBus] && tagv_way1_2[20]==`Valid)? `HitSuccess : `HitFail;
	wire hit_success = (hit_way0 | hit_way1 | FIFO_hit) & (cpu_rreq_2 | cpu_wreq_2);//hit & req valid
	wire hit_fail = ~(hit_success) & (cpu_rreq_2 | cpu_wreq_2);
	//tag hit
    wire [`DataBus]data_FIFO = FIFO_rdata[virtual_addr_2[4:2]];
    
    
   //Tag not hit
   //write to ram
    assign wea_way0 =(hit_fail==`Valid && bus_read_success == `Success && LRU_pick == 1'b0)? 4'b1111 : // Not Hit
                     (hit_way0 == `HitSuccess && cpu_wreq_2 == `WriteEnable )? cpu_wsel_2: 4'h0;//Write Hit
    
    assign wea_way1 = (hit_fail==`Valid && bus_read_success == `Success && LRU_pick == 1'b1)? 4'b1111 ://not hit
                     (hit_way1 == `HitSuccess  && cpu_wreq_2 == `WriteEnable )? cpu_wsel_2 : 4'h0;//write hit
                     
                 
	assign FIFO_wreq = (FIFO_hit == `HitSuccess && cpu_wreq_2 == `WriteEnable)? `WriteEnable:
	                   (bus_read_success == `Success && FIFO_state != `STATE_FULL && write_dirty == `Dirty)? `WriteEnable:
	                    `WriteDisable;
	assign FIFO_waddr = (LRU_pick == 1'b1)?  
	                   {tagv_way1_2[19:0],physical_addr_2[11:0]}:
                        {tagv_way0_2[19:0],physical_addr_2[11:0]};
   //AXI read requirements
	assign mem_ren_o = (hit_fail == `Valid) ?  ~bus_read_success: `ReadDisable;
	assign mem_araddr_o = physical_addr_2;
	//ram write data
	always@(*) begin 
        cache_wdata[0] <= `ZeroWord;
        cache_wdata[1] <= `ZeroWord;
        cache_wdata[2] <= `ZeroWord;
        cache_wdata[3] <= `ZeroWord;
        cache_wdata[4] <= `ZeroWord;
        cache_wdata[5] <= `ZeroWord;
        cache_wdata[6] <= `ZeroWord;
        cache_wdata[7] <= `ZeroWord;
		if(hit_fail == `Valid)begin//hit fail
			cache_wdata[0] <= mem_rdata[0];
			cache_wdata[1] <= mem_rdata[1];
			cache_wdata[2] <= mem_rdata[2];
			cache_wdata[3] <= mem_rdata[3];
			cache_wdata[4] <= mem_rdata[4];
			cache_wdata[5] <= mem_rdata[5];
			cache_wdata[6] <= mem_rdata[6];
			cache_wdata[7] <= mem_rdata[7];
			if(cpu_wreq_2 == `WriteEnable)//write
				cache_wdata[virtual_addr_2[4:2]] <= (cpu_wdata & wsel_expand)|(mem_rdata_i[virtual_addr_2[4:2]] & ~wsel_expand);
		end
		if(hit_success == `HitSuccess)begin//hit success
			if(hit_way0 == `HitSuccess)begin
				cache_wdata[0] <= way0_2[0];
				cache_wdata[1] <= way0_2[1];
				cache_wdata[2] <= way0_2[2];
				cache_wdata[3] <= way0_2[3];
				cache_wdata[4] <= way0_2[4];
				cache_wdata[5] <= way0_2[5];
				cache_wdata[6] <= way0_2[6];
				cache_wdata[7] <= way0_2[7];
				cache_wdata[virtual_addr_2[4:2]] <= (cpu_wdata & wsel_expand)|(way0_2[virtual_addr_2[4:2]] & ~wsel_expand);
			end
			if(hit_way1 == `HitSuccess)begin
				cache_wdata[0] <= way1_2[0];
				cache_wdata[1] <= way1_2[1];
				cache_wdata[2] <= way1_2[2];
				cache_wdata[3] <= way1_2[3];
				cache_wdata[4] <= way1_2[4];
				cache_wdata[5] <= way1_2[5];
				cache_wdata[6] <= way1_2[6];
				cache_wdata[7] <= way1_2[7];
				cache_wdata[virtual_addr_2[4:2]] <= (cpu_wdata & wsel_expand)|(way1_2[virtual_addr_2[4:2]] & ~wsel_expand);
			end
			if(FIFO_hit == `HitSuccess)begin
				cache_wdata[0] <= FIFO_rdata[0];
				cache_wdata[1] <= FIFO_rdata[1];
				cache_wdata[2] <= FIFO_rdata[2];
				cache_wdata[3] <= FIFO_rdata[3];
				cache_wdata[4] <= FIFO_rdata[4];
				cache_wdata[5] <= FIFO_rdata[5];
				cache_wdata[6] <= FIFO_rdata[6];
				cache_wdata[7] <= FIFO_rdata[7];
				cache_wdata[virtual_addr_2[4:2]] <= (cpu_wdata & wsel_expand)|(FIFO_rdata[virtual_addr_2[4:2]] & ~wsel_expand);
			end
		end
	end
	
	//STATE_WRITE_DATA
	//write to FIFO 
	always@(*)begin
        FIFO_wdata[0] <= `ZeroWay;
        FIFO_wdata[1] <= `ZeroWay;
        FIFO_wdata[2] <= `ZeroWay;
        FIFO_wdata[3] <= `ZeroWay;
        FIFO_wdata[4] <= `ZeroWay;
        FIFO_wdata[5] <= `ZeroWay;
        FIFO_wdata[6] <= `ZeroWay;
        FIFO_wdata[7] <= `ZeroWay;
	   if((cpu_wreq_2) && FIFO_hit == `HitSuccess)begin
				FIFO_wdata[0] <= FIFO_rdata[0];
				FIFO_wdata[1] <= FIFO_rdata[1];
				FIFO_wdata[2] <= FIFO_rdata[2];
				FIFO_wdata[3] <= FIFO_rdata[3];
				FIFO_wdata[4] <= FIFO_rdata[4];
				FIFO_wdata[5] <= FIFO_rdata[5];
				FIFO_wdata[6] <= FIFO_rdata[6];
				FIFO_wdata[7] <= FIFO_rdata[7];
				FIFO_wdata[virtual_addr_2[4:2]] <= cpu_wdata;
	   end
	   if(bus_read_success == `Success)begin
            if(LRU_pick == 1'b0)begin//0?¡è????I
				FIFO_wdata[0] <= way0_cache[0];
				FIFO_wdata[1] <= way0_cache[1];
				FIFO_wdata[2] <= way0_cache[2];
				FIFO_wdata[3] <= way0_cache[3];
				FIFO_wdata[4] <= way0_cache[4];
				FIFO_wdata[5] <= way0_cache[5];
				FIFO_wdata[6] <= way0_cache[6];
				FIFO_wdata[7] <= way0_cache[7];
            end
            else begin//1?¡è????I
				FIFO_wdata[0] <= way1_cache[0];
				FIFO_wdata[1] <= way1_cache[1];
				FIFO_wdata[2] <= way1_cache[2];
				FIFO_wdata[3] <= way1_cache[3];
				FIFO_wdata[4] <= way1_cache[4];
				FIFO_wdata[5] <= way1_cache[5];
				FIFO_wdata[6] <= way1_cache[6];
				FIFO_wdata[7] <= way1_cache[7];
            end
       end
	end
   
   
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    reg [`DataBus] cpu_data_o;
    always@(*)begin
        cpu_data_o <= `ZeroWord;
        if(hit_way0 == `HitSuccess)
            cpu_data_o <= data_way0;
        if(hit_way1 == `HitSuccess)
            cpu_data_o <= data_way1;
        if(FIFO_hit == `HitSuccess)
            cpu_data_o <= data_FIFO;
        if(bus_read_success ==`Success)
			cpu_data_o <= mem_rdata[virtual_addr_2[4:2]];
    end

    assign cpu_data_valid_o = (hit_success == `HitSuccess && cpu_rreq_2 == `Valid)? `Valid :
                              (bus_read_success == `Success && cpu_rreq_2 == `Valid)? `Valid :
//                              (current_state==`STATE_WRITE_DATA)                        ? `Valid :
                              `Invalid ;
							  
//	assign DCache_state_o = current_state;
	
	//continuous read collison
	reg [`DataBus] cpu_data_o_2;
	always@(posedge clk)begin
		cpu_data_o_2 <= cpu_data_o;
	end
	
	//assign cpu_data_final_o = (current_state == `STATE_LOOK_UP)?	cpu_data_o_2: cpu_data_o;
	assign cpu_data_final_o = cpu_data_o;
	
	//debug signals
	wire [6:0]index = physical_addr_2[`IndexBus];
	wire [2:0]offset = physical_addr_2[4:2];
	wire [19:0]tag = physical_addr_2[`TagBus];
	wire [19:0]debug_tag_way0 = tagv_way0_2[19:0];
	wire [19:0]debug_tag_way1 = tagv_way1_2[19:0];
endmodule
