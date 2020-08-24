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

    input wire clk,
    input wire rst,
    
    //cpu data request
    input wire cpu_rreq_i,
    input wire cpu_wreq_i,
    input wire [`DataAddrBus]virtual_addr_i,
    input wire [`DataBus]cpu_wdata_i,
    input wire [3:0]cpu_wsel_i,
    output wire hit_o,
    output wire cpu_data_valid_o,
    output wire [`DataBus] cpu_data_final_o,
	
	//cache state
	output reg cpu_stall_o,
	output wire [`StateBus] DCache_state_o,
    
    //mem read
    input wire mem_rvalid_i,
    input wire [`WayBus]mem_rdata_i,
    output wire mem_ren_o,
    output wire[`DataAddrBus]mem_araddr_o,
	//mem write
    input wire mem_bvalid_i,
    output wire mem_wen_o,
    output wire[`WayBus] mem_wdata_o,//?????¨¦???¨®??
    output wire [`DataAddrBus]mem_awaddr_o
    
    //test
    //output [`DirtyBus] dirty
    );
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
	reg [127:0]total_dcache_hit;
	reg [127:0]total_dcache_req;
	always@(posedge clk)begin
		if(rst)
			total_dcache_hit <= 0;
		else if(hit_o)
			total_dcache_hit <= total_dcache_hit + 1;
		if(rst)
			total_dcache_req <= 0;
		else if(current_state == `STATE_LOOK_UP && (cpu_rreq_i|cpu_wreq_i))
			total_dcache_req <= total_dcache_req + 1;
	end
	
    wire [31:0]wsel_expand;
    assign wsel_expand={{8{cpu_wsel_2[3]}} , {8{cpu_wsel_2[2]}} , {8{cpu_wsel_2[1]}} , {8{cpu_wsel_2[0]}}};
    //keep the data of STATE_LOOK_UP
    reg [`InstAddrBus]virtual_addr;
    reg [`RegBus]cpu_wdata;
    reg func;//?????¡ì??????????
    reg [3:0]cpu_wsel_2;
    
	
    always@(posedge clk)begin
        if(rst)begin
            virtual_addr<= `ZeroWord;
            cpu_wdata<= `ZeroWord;
            func <= `Invalid;
            cpu_wsel_2 <= 4'h0;
        end
        else if(current_state == `STATE_LOOK_UP)begin
            virtual_addr <= virtual_addr_i;
            cpu_wdata <= cpu_wdata_i;
            func <= cpu_wreq_i;
            cpu_wsel_2 <= cpu_wsel_i;
        end
        else begin
            virtual_addr <= virtual_addr;
            cpu_wdata <= cpu_wdata;
            func <= func;
            cpu_wsel_2 <= cpu_wsel_2;
        end
    end
    //TLB
    wire [`InstAddrBus]physical_addr = virtual_addr;
//    wire index = physical_addr[`IndexBus];
//    wire offset = physical_addr[`OffsetBus];
//    TLB tlb0(
//    .virtual_addr_i(virtual_addr),
//    .physical_addr_o(physical_addr)
//    );
	//WriteBuffer
	wire [`WayBus]FIFO_rdata;
	wire [`DataAddrBus]FIFO_waddr;
	reg [`WayBus]FIFO_wdata;
	wire FIFO_hit;
	wire FIFO_wreq;
	wire [`FIFOStateNumLog2-1:0]FIFO_state;
    WriteBuffer WB0(
        .clk(clk),
        .rst(rst),
        //CPU write request
        .cpu_wreq_i(FIFO_wreq),
        .cpu_awaddr_i(FIFO_waddr),
        .cpu_wdata_i(FIFO_wdata),//WaySize
        //CPU read request and response
        .cpu_rreq_i(cpu_rreq_i),
        .cpu_araddr_i(physical_addr),
        .read_hit_o(FIFO_hit),
        .cpu_rdata_o(FIFO_rdata),//WaySize
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
    wire [`InstAddrBus]ram_addr = (current_state == `STATE_LOOK_UP)? virtual_addr_i : physical_addr; 
	reg [`WayBus]read_from_mem;
	
    wire [3:0]wea_way0;
    wire [3:0]wea_way1;
    
    wire [`RegBus]inst_cache_b0w0;
    wire [`RegBus]inst_cache_b1w0;
    wire [`RegBus]inst_cache_b2w0;
    wire [`RegBus]inst_cache_b3w0;
    wire [`RegBus]inst_cache_b4w0;
    wire [`RegBus]inst_cache_b5w0;
    wire [`RegBus]inst_cache_b6w0;
    wire [`RegBus]inst_cache_b7w0;
    bank_ram Bank0_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.douta(inst_cache_b0w0));
    bank_ram Bank1_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.douta(inst_cache_b1w0));
    bank_ram Bank2_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.douta(inst_cache_b2w0));
    bank_ram Bank3_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.douta(inst_cache_b3w0));
    bank_ram Bank4_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.douta(inst_cache_b4w0));
    bank_ram Bank5_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.douta(inst_cache_b5w0));
    bank_ram Bank6_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.douta(inst_cache_b6w0));
    bank_ram Bank7_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.douta(inst_cache_b7w0));
    
    wire [`RegBus]inst_cache_b0w1;
    wire [`RegBus]inst_cache_b1w1;
    wire [`RegBus]inst_cache_b2w1;
    wire [`RegBus]inst_cache_b3w1;
    wire [`RegBus]inst_cache_b4w1;
    wire [`RegBus]inst_cache_b5w1;
    wire [`RegBus]inst_cache_b6w1;
    wire [`RegBus]inst_cache_b7w1;                              
    bank_ram Bank0_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.douta(inst_cache_b0w1));
    bank_ram Bank1_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.douta(inst_cache_b1w1));
    bank_ram Bank2_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.douta(inst_cache_b2w1));
    bank_ram Bank3_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.douta(inst_cache_b3w1));
    bank_ram Bank4_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.douta(inst_cache_b4w1));
    bank_ram Bank5_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.douta(inst_cache_b5w1));
    bank_ram Bank6_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.douta(inst_cache_b6w1));
    bank_ram Bank7_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.douta(inst_cache_b7w1));

    //Tag+Valid
    wire [`TagVBus]tagv_cache_w0;
    wire [`TagVBus]tagv_cache_w1;
    tag_ram TagV0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(ram_addr[`IndexBus]),.dina({1'b1,physical_addr[`TagBus]}),.douta(tagv_cache_w0));
    tag_ram TagV1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(ram_addr[`IndexBus]),.dina({1'b1,physical_addr[`TagBus]}),.douta(tagv_cache_w1));
    
    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[virtual_addr[`IndexBus]];
    always@(posedge clk)begin
        if(rst)
            LRU <= 0;
        else if(hit_o == `HitSuccess)//hit: set LRU to bit that is not hit
            LRU[virtual_addr[`IndexBus]] <= hit_way0;
        else if(cpu_data_valid_o == `Valid && hit_o == `HitFail)//not hit: set opposite LRU
            LRU[virtual_addr[`IndexBus]] <= ~LRU[virtual_addr[`IndexBus]];
        else
            LRU <= LRU;
    end
    
    //Dirty 
    reg [`DirtyBus] dirty;
	wire write_dirty = dirty[{virtual_addr[`IndexBus],LRU_pick}]; 
    always@(posedge clk)begin
        if(rst)
            dirty<=0;
		else if(current_state == `STATE_FETCH_DATA && bus_read_success == `Valid && func == `WriteDisable)//Read not hit
            dirty[{virtual_addr[`IndexBus],LRU_pick}] <= `NotDirty;
		else if(current_state == `STATE_FETCH_DATA && mem_rvalid_i == `Valid && func == `WriteEnable)//write not hit
            dirty[{virtual_addr[`IndexBus],LRU_pick}] <= `Dirty;
		else if(current_state == `STATE_FETCH_DATA && (hit_way0|hit_way1) == `HitSuccess && func == `WriteEnable)//write hit but not FIFO
            dirty[{virtual_addr[`IndexBus],hit_way1}] <= `Dirty;
        else
            dirty <= dirty;
    end
	
	//Stall
	always@(*)begin 
	
		if(current_state != `STATE_LOOK_UP && (cpu_rreq_i | cpu_wreq_i))//req when Cache is busy
			cpu_stall_o <= `Valid;
		else if(current_state == `STATE_FETCH_DATA && hit_o == `HitFail && func == `WriteDisable)//read not hit
			cpu_stall_o <= ~bus_read_success;//not successful( if request when successful, still stall)
		
		//else if (bus_read_success == `Success && FIFO_state == `STATE_FULL && write_dirty == `Valid)//Write buffer FIFO full
		//	cpu_stall_o <= `Valid;
		else
			cpu_stall_o <= `Invalid;
	end
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////State Transmission/////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	wire bus_read_success = mem_rvalid_i;//Better understatnding 
	//state
    reg [`StateBus]current_state;
    reg [`StateBus]next_state;
    always@(posedge clk)begin
        if(rst)
            current_state <= `STATE_LOOK_UP;
        else
            current_state <= next_state;
    end
    
    always@(*)begin
        next_state <= current_state;
        case(current_state)
            `STATE_LOOK_UP:begin
                if(cpu_rreq_i | cpu_wreq_i)begin
                    next_state <= `STATE_FETCH_DATA;
                end
                else
                    next_state <= `STATE_LOOK_UP;
            end
            `STATE_FETCH_DATA:begin
                if(hit_o == `HitSuccess)//hit 
                    next_state <= `STATE_LOOK_UP;
                else if(bus_read_success == `Success)//hit fail and no dirty bank to write
                    next_state <= `STATE_LOOK_UP;
//                else if(bus_read_success == `Success && write_dirty == `WriteEnable)//hit fail and dirty bank to write
//                    next_state <= `STATE_WRITE_DATA;
            end
//            `STATE_WRITE_DATA:begin
//				if(FIFO_state == `STATE_FULL)
//					next_state <= `STATE_WRITE_DATA;
//				else
//                    next_state <= `STATE_LOOK_UP;
//            end
            default:;
        endcase
    end//always
    
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////State Operation//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
    //STATE_LOOK_UP?? Detail operation is at the first of this file.
	
	
    //STATE_FETCH_DATA
	//hit judgement
    wire hit_way0 = (tagv_cache_w0[19:0]==physical_addr[`TagBus] && tagv_cache_w0[20]==`Valid)? `HitSuccess : `HitFail;
    wire hit_way1 = (tagv_cache_w1[19:0]==physical_addr[`TagBus] && tagv_cache_w1[20]==`Valid)? `HitSuccess : `HitFail;
    assign hit_o = (current_state==`STATE_FETCH_DATA)? (hit_way0 | hit_way1 | FIFO_hit) :`HitFail;
	
	//tag hit
    reg [`InstBus]data_way0;
    reg [`InstBus]data_way1;
    reg [`InstBus]data_FIFO;
    //way0
    always@(*)begin
        case(virtual_addr[4:2])
            3'h0:data_way0 <= inst_cache_b0w0;
            3'h1:data_way0 <= inst_cache_b1w0;
            3'h2:data_way0 <= inst_cache_b2w0;
            3'h3:data_way0 <= inst_cache_b3w0;
            3'h4:data_way0 <= inst_cache_b4w0;
            3'h5:data_way0 <= inst_cache_b5w0;
            3'h6:data_way0 <= inst_cache_b6w0;
            3'h7:data_way0 <= inst_cache_b7w0;
            default: data_way0 <= `ZeroWord;
        endcase
    end
    //way1
    always@(*)begin
        case(virtual_addr[4:2])
            3'h0:data_way1 <= inst_cache_b0w1;
            3'h1:data_way1 <= inst_cache_b1w1;
            3'h2:data_way1 <= inst_cache_b2w1;
            3'h3:data_way1 <= inst_cache_b3w1;
            3'h4:data_way1 <= inst_cache_b4w1;
            3'h5:data_way1 <= inst_cache_b5w1;
            3'h6:data_way1 <= inst_cache_b6w1;
            3'h7:data_way1 <= inst_cache_b7w1;
            default: data_way1 <= `ZeroWord;
        endcase
    end
    //FIFO
    always@(*)begin
        case(virtual_addr[4:2])
            3'h0:data_FIFO <= FIFO_rdata[32*1-1:32*0];
            3'h1:data_FIFO <= FIFO_rdata[32*2-1:32*1];
            3'h2:data_FIFO <= FIFO_rdata[32*3-1:32*2];
            3'h3:data_FIFO <= FIFO_rdata[32*4-1:32*3];
            3'h4:data_FIFO <= FIFO_rdata[32*5-1:32*4];
            3'h5:data_FIFO <= FIFO_rdata[32*6-1:32*5];
            3'h6:data_FIFO <= FIFO_rdata[32*7-1:32*6];
            3'h7:data_FIFO <= FIFO_rdata[32*8-1:32*7];
            default: data_FIFO <= `ZeroWord;
        endcase
    end
    
    
   //Tag not hit
   //write to ram
    assign wea_way0 =(bus_read_success==`Valid && bus_read_success == `Success && LRU_pick == 1'b0)? 4'b1111 : // Not Hit
                     (current_state==`STATE_FETCH_DATA && hit_way0 == `HitSuccess && func == `WriteEnable )? cpu_wsel_2: 4'h0;//Write Hit
    
    assign wea_way1 = (bus_read_success==`Valid && bus_read_success == `Success && LRU_pick == 1'b1)? 4'b1111 ://not hit
                     (current_state==`STATE_FETCH_DATA && hit_way1 == `HitSuccess  && func == `WriteEnable )? cpu_wsel_2 : 4'h0;//write hit
                     
                 
	assign FIFO_wreq = (current_state == `STATE_FETCH_DATA && FIFO_hit == `HitSuccess && func == `WriteEnable)? `WriteEnable:
	                   (bus_read_success == `Success && FIFO_state != `STATE_FULL && write_dirty == `Dirty)? `WriteEnable: `WriteDisable;
   assign FIFO_waddr = (LRU_pick == 1'b1)?  {tagv_cache_w1[19:0],physical_addr[11:0]}:
                        {tagv_cache_w0[19:0],physical_addr[11:0]};
   //AXI read requirements
   assign mem_ren_o = (current_state==`STATE_FETCH_DATA && hit_o == `HitFail) ?  ~bus_read_success:`ReadDisable;
   assign mem_araddr_o = physical_addr;
   //ram write data
   always@(*) begin 
        read_from_mem<={`ZeroWord,`ZeroWord,`ZeroWord,`ZeroWord,`ZeroWord,`ZeroWord,`ZeroWord,`ZeroWord};
		if(current_state == `STATE_FETCH_DATA && hit_o == `HitFail && func == `WriteDisable)begin//read hit fail
			read_from_mem <= mem_rdata_i;
		end
		if(current_state == `STATE_FETCH_DATA && hit_o == `HitFail && func == `WriteEnable)begin//write hit fail
			case(virtual_addr[4:2])
				3'h0:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*1-1:32*0] & ~wsel_expand)};
				3'h1:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*2-1:32*1] & ~wsel_expand),mem_rdata_i[32*2-1:32*1]};
				3'h2:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*3-1:32*2] & ~wsel_expand),mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				3'h3:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*4-1:32*3] & ~wsel_expand),mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				3'h4:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*5-1:32*4] & ~wsel_expand),mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				3'h5:read_from_mem <= {mem_rdata_i[32*8-1:32*7],mem_rdata_i[32*7-1:32*6],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*6-1:32*5] & ~wsel_expand),mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				3'h6:read_from_mem <= {mem_rdata_i[32*8-1:32*7],(cpu_wdata & wsel_expand)|(mem_rdata_i[32*7-1:32*6] & ~wsel_expand),mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				3'h7:read_from_mem <= {(cpu_wdata & wsel_expand)|(mem_rdata_i[32*8-1:32*7] & ~wsel_expand),mem_rdata_i[32*7-1:32*6],mem_rdata_i[32*6-1:32*5],mem_rdata_i[32*5-1:32*4],mem_rdata_i[32*4-1:32*3],mem_rdata_i[32*3-1:32*2],mem_rdata_i[32*2-1:32*1],mem_rdata_i[32*1-1:32*0]};
				default: read_from_mem <= mem_rdata_i;
			endcase
		end
		if(current_state == `STATE_FETCH_DATA && hit_o == `HitSuccess)begin//hit success
            if(hit_way0 == `HitSuccess)begin
                case(virtual_addr[4:2])
                    3'h0:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,cpu_wdata};
                    3'h1:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,cpu_wdata,inst_cache_b0w0};
                    3'h2:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,cpu_wdata,inst_cache_b1w0,inst_cache_b0w0};
                    3'h3:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,cpu_wdata,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                    3'h4:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,cpu_wdata,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                    3'h5:read_from_mem <= {inst_cache_b7w0,inst_cache_b6w0,cpu_wdata,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                    3'h6:read_from_mem <= {inst_cache_b7w0,cpu_wdata,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                    3'h7:read_from_mem <= {cpu_wdata,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                    default:read_from_mem<={inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
                endcase
            end
            if(hit_way1 == `HitSuccess)begin
                case(virtual_addr[4:2])
                    3'h0:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,cpu_wdata};
                    3'h1:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,cpu_wdata,inst_cache_b0w1};
                    3'h2:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,cpu_wdata,inst_cache_b1w1,inst_cache_b0w1};
                    3'h3:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,cpu_wdata,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h4:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,cpu_wdata,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h5:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,cpu_wdata,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h6:read_from_mem <= {inst_cache_b7w1,cpu_wdata,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h7:read_from_mem <= {cpu_wdata,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    default:read_from_mem<={inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                endcase
            end
            if(FIFO_hit == `HitSuccess)begin
                case(virtual_addr[4:2])
                    3'h0:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,cpu_wdata};
                    3'h1:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,cpu_wdata,inst_cache_b0w1};
                    3'h2:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,cpu_wdata,inst_cache_b1w1,inst_cache_b0w1};
                    3'h3:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,cpu_wdata,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h4:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,cpu_wdata,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h5:read_from_mem <= {inst_cache_b7w1,inst_cache_b6w1,cpu_wdata,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h6:read_from_mem <= {inst_cache_b7w1,cpu_wdata,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    3'h7:read_from_mem <= {cpu_wdata,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                    default:read_from_mem<={inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
                endcase
            end//if if
        end//if
   end
  
   //STATE_WRITE_DATA
   //write to FIFO 
	always@(*)begin
	   FIFO_wdata <= `ZeroWay;
	   if(current_state == `STATE_FETCH_DATA && FIFO_hit == `HitSuccess)begin
            case(virtual_addr[4:2])
                3'h0:FIFO_wdata <= {FIFO_rdata[8*32-1:1*32],cpu_wdata};
                3'h1:FIFO_wdata <= {FIFO_rdata[8*32-1:2*32],cpu_wdata,FIFO_rdata[1*32-1:0*32]};
                3'h2:FIFO_wdata <= {FIFO_rdata[8*32-1:3*32],cpu_wdata,FIFO_rdata[2*32-1:0*32]};
                3'h3:FIFO_wdata <= {FIFO_rdata[8*32-1:4*32],cpu_wdata,FIFO_rdata[3*32-1:0*32]};
                3'h4:FIFO_wdata <= {FIFO_rdata[8*32-1:5*32],cpu_wdata,FIFO_rdata[4*32-1:0*32]};
                3'h5:FIFO_wdata <= {FIFO_rdata[8*32-1:6*32],cpu_wdata,FIFO_rdata[5*32-1:0*32]};
                3'h6:FIFO_wdata <= {FIFO_rdata[8*32-1:7*32],cpu_wdata,FIFO_rdata[6*32-1:0*32]};
                3'h7:FIFO_wdata <= {cpu_wdata,FIFO_rdata[7*32-1:0*32]};
                default:;                                         
            endcase
	   end
	   if(bus_read_success == `Success)begin
            if(LRU_pick == 1'b0)begin//0?¡è????I
                FIFO_wdata <= {inst_cache_b7w0,inst_cache_b6w0,inst_cache_b5w0,inst_cache_b4w0,inst_cache_b3w0,inst_cache_b2w0,inst_cache_b1w0,inst_cache_b0w0};
            end
            else begin//1?¡è????I
                FIFO_wdata <= {inst_cache_b7w1,inst_cache_b6w1,inst_cache_b5w1,inst_cache_b4w1,inst_cache_b3w1,inst_cache_b2w1,inst_cache_b1w1,inst_cache_b0w1};
            end
       end
	end
   
   
//    assign mem_ren_o
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
reg [`DataBus] cpu_data_o;
    always@(*)begin
        cpu_data_o <= `ZeroWord;
        if(current_state==`STATE_FETCH_DATA && hit_way0 == `HitSuccess)
            cpu_data_o <= data_way0;
        if(current_state==`STATE_FETCH_DATA && hit_way1 == `HitSuccess)
            cpu_data_o <= data_way1;
        if(current_state==`STATE_FETCH_DATA && FIFO_hit == `HitSuccess)
            cpu_data_o <= data_FIFO;
        if(current_state==`STATE_FETCH_DATA && bus_read_success ==`Success)begin
        case(virtual_addr[4:2])
            3'h0:cpu_data_o <= read_from_mem[32*1-1:32*0];
            3'h1:cpu_data_o <= read_from_mem[32*2-1:32*1];
            3'h2:cpu_data_o <= read_from_mem[32*3-1:32*2];
            3'h3:cpu_data_o <= read_from_mem[32*4-1:32*3];
            3'h4:cpu_data_o <= read_from_mem[32*5-1:32*4];
            3'h5:cpu_data_o <= read_from_mem[32*6-1:32*5];
            3'h6:cpu_data_o <= read_from_mem[32*7-1:32*6];
            3'h7:cpu_data_o <= read_from_mem[32*8-1:32*7];
            default:;
        endcase
        end
    end

    assign cpu_data_valid_o = (current_state==`STATE_FETCH_DATA && hit_o == `HitSuccess && func == `WriteDisable)? `Valid :
                              (current_state==`STATE_FETCH_DATA && bus_read_success == `Success && func == `WriteDisable)? `Valid :
//                              (current_state==`STATE_WRITE_DATA)                        ? `Valid :
                              `Invalid ;
							  
	assign DCache_state_o = current_state;
	
	//continuous read collison
	reg [`DataBus] cpu_data_o_2;
	always@(posedge clk)begin
		cpu_data_o_2 <= cpu_data_o;
	end
	
	assign cpu_data_final_o = (current_state == `STATE_LOOK_UP)?	cpu_data_o_2: cpu_data_o;
	
endmodule
