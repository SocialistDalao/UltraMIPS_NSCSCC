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
	
	//mem_data_i in 2-dimen arry
	wire [`DataBus]mem_rdata[`BlockNum-1:0];
   generate for(genvar i =0 ;i<`BlockNum; i=i+1)begin
		assign mem_rdata[i] = mem_rdata_i[32*(i+1)-1:32*i];
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
	wire [`DataBus]FIFO_rdata[`BlockNum-1:0];
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
        .cpu_rdata_o({FIFO_rdata[7],
					  FIFO_rdata[6],
					  FIFO_rdata[5],
					  FIFO_rdata[4],
					  FIFO_rdata[3],
					  FIFO_rdata[2],
					  FIFO_rdata[1],
					  FIFO_rdata[0]
					
		),//WaySize
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
	reg [`DataBus]cache_wdata[`BlockNum-1:0];
	
    wire [3:0]wea_way0;
    wire [3:0]wea_way1;
    
	wire [`DataBus]way0_cache[`BlockNum-1:0];
	wire [6:0] ram_addr = (stall_o)? physical_addr_2[`IndexBus] : virtual_addr_i[`IndexBus];//When stall, maintain the addr of ram 
    simple_dual_ram Bank0_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[7]));
   
	wire [`DataBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(ram_addr[`IndexBus]), .dina(cache_wdata[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[7]));                        

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
    wire [`InstBus]data_way0 = way0_cache[virtual_addr[4:2]];
    wire [`InstBus]data_way1 = way1_cache[virtual_addr[4:2]];
    wire [`InstBus]data_FIFO = FIFO_rdata[virtual_addr[4:2]];
    
    
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
        cache_wdata[0] <= `ZeroWord;
        cache_wdata[1] <= `ZeroWord;
        cache_wdata[2] <= `ZeroWord;
        cache_wdata[3] <= `ZeroWord;
        cache_wdata[4] <= `ZeroWord;
        cache_wdata[5] <= `ZeroWord;
        cache_wdata[6] <= `ZeroWord;
        cache_wdata[7] <= `ZeroWord;
		if(current_state == `STATE_FETCH_DATA && hit_o == `HitFail)begin//hit fail
			cache_wdata[0] <= mem_rdata[0];
			cache_wdata[1] <= mem_rdata[1];
			cache_wdata[2] <= mem_rdata[2];
			cache_wdata[3] <= mem_rdata[3];
			cache_wdata[4] <= mem_rdata[4];
			cache_wdata[5] <= mem_rdata[5];
			cache_wdata[6] <= mem_rdata[6];
			cache_wdata[7] <= mem_rdata[7];
			if(func == `WriteEnable)//write
				cache_wdata[virtual_addr[4:2]] <= (cpu_wdata & wsel_expand)|(mem_rdata_i[virtual_addr[4:2]] & ~wsel_expand);
		end
		if(current_state == `STATE_FETCH_DATA && hit_o == `HitSuccess)begin//hit success
			if(hit_way0 == `HitSuccess)begin
				cache_wdata[0] <= way0_cache[0];
				cache_wdata[1] <= way0_cache[1];
				cache_wdata[2] <= way0_cache[2];
				cache_wdata[3] <= way0_cache[3];
				cache_wdata[4] <= way0_cache[4];
				cache_wdata[5] <= way0_cache[5];
				cache_wdata[6] <= way0_cache[6];
				cache_wdata[7] <= way0_cache[7];
				cache_wdata[virtual_addr[4:2]] <= cpu_wdata;
			end
			if(hit_way1 == `HitSuccess)begin
				cache_wdata[0] <= way1_cache[0];
				cache_wdata[1] <= way1_cache[1];
				cache_wdata[2] <= way1_cache[2];
				cache_wdata[3] <= way1_cache[3];
				cache_wdata[4] <= way1_cache[4];
				cache_wdata[5] <= way1_cache[5];
				cache_wdata[6] <= way1_cache[6];
				cache_wdata[7] <= way1_cache[7];
				cache_wdata[virtual_addr[4:2]] <= cpu_wdata;
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
				cache_wdata[virtual_addr[4:2]] <= cpu_wdata;
			end
		end
   end
  
   //STATE_WRITE_DATA
   //write to FIFO 
	always@(*)begin
	   FIFO_wdata <= `ZeroWay;
	   if(current_state == `STATE_FETCH_DATA && FIFO_hit == `HitSuccess)begin
				cache_wdata[0] <= FIFO_rdata[0];
				cache_wdata[1] <= FIFO_rdata[1];
				cache_wdata[2] <= FIFO_rdata[2];
				cache_wdata[3] <= FIFO_rdata[3];
				cache_wdata[4] <= FIFO_rdata[4];
				cache_wdata[5] <= FIFO_rdata[5];
				cache_wdata[6] <= FIFO_rdata[6];
				cache_wdata[7] <= FIFO_rdata[7];
				cache_wdata[virtual_addr[4:2]] <= cpu_wdata;
	   end
	   if(bus_read_success == `Success)begin
            if(LRU_pick == 1'b0)begin//0?¡è????I
                FIFO_wdata <= {way0_cache[7],
							   way0_cache[6],
							   way0_cache[5],
							   way0_cache[4],
							   way0_cache[3],
							   way0_cache[2],
							   way0_cache[1],
							   way0_cache[0]};
            end
            else begin//1?¡è????I
                FIFO_wdata <= {way1_cache[7],
							   way1_cache[6],
							   way1_cache[5],
							   way1_cache[4],
							   way1_cache[3],
							   way1_cache[2],
							   way1_cache[1],
							   way1_cache[0]};
            end
       end
	end
   
   
    
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
			cpu_data_o <= mem_rdata[virtual_addr[4:2]];
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
