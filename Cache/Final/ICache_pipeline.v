`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Structure of ICache
//----Initialization
//--------BANK_RAM
//--------TAG+VALID_RAM
//--------DIRTY
//--------LRU
//----RAM Collision Operation
//----Main Operation
//----Output
//////////////////////////////////////////////////////////////////////////////////


module ICache_pipeline(

	//Control Signal
    input wire 					clk,
    input wire 					rst,
    output wire 			    is_working_o,
    output wire 			    is_pipeline2_empty_o,
//	output wire 				is_mem_request,//ICache Flush Control Related Signal
    
    //read inst request
    input wire 					cpu_req_i,
    input wire [`InstAddrBus]	virtual_addr_i,//inst read virtual addr
    input wire [`InstAddrBus]	physical_addr_1,//inst read virtual addr
    
    //read inst result
    output wire 				hit_o,
    //output wire 				cpu_inst_valid_o,
    output wire [`InstBus] 		cpu_inst1_o,
    output wire [`InstBus] 		cpu_inst2_o,
    output reg [`InstAddrBus] 	cpu_inst1_addr_o,
    output reg [`InstAddrBus] 	cpu_inst2_addr_o,
    output reg 			   	inst1_valid_o,
    output reg 				inst2_valid_o,
	output wire 				stall_o,
    
    //read from mem
    input wire 					mem_inst_rvalid_i,
    input wire [`WayBus]		mem_inst_rdata_i,//һ����Ĵ�С
    output wire 				mem_inst_ren_o,
    output wire[`InstAddrBus]	mem_inst_araddr_o,
    
    input wire [`SIZE_OF_CORR_PACK] corr_pack0_i      ,//
    input wire [`SIZE_OF_CORR_PACK] corr_pack1_i      ,
    output reg [`SIZE_OF_CORR_PACK] corr_pack0_o      ,//
    output reg [`SIZE_OF_CORR_PACK] corr_pack1_o
    
    );
	//remaining signal: In this vision, these signals are not useful, but we keep them here
	wire 				stall_o;
	wire 				cpu_inst_valid_o = inst1_valid_o;
		
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Initialization//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
	//pipeline name rule:
	//"i","o" means input, output signal
	//"1" means state 1: LOOK UP
	//"2" means state 2: SCAN CACHE
    //wire [`RegBus]physical_addr_1 = virtual_addr_i;
    reg [`RegBus]physical_addr_2;
    reg cpu_req_2;
	always@(posedge clk)begin
		if(rst)begin
			physical_addr_2 <= `ZeroWord;
			cpu_req_2 <= `Invalid;
			cpu_inst1_addr_o <= `ZeroWord;
			cpu_inst2_addr_o <= `ZeroWord;
		end
		else if( stall_o)begin
			physical_addr_2 <= physical_addr_2;
			cpu_req_2 <= cpu_req_2;
			cpu_inst1_addr_o <= cpu_inst1_addr_o;
			cpu_inst2_addr_o <= cpu_inst2_addr_o;
			corr_pack0_o <= corr_pack0_o;
			corr_pack1_o <= corr_pack1_o;
		end
		else begin
			physical_addr_2 <= physical_addr_1;
			cpu_req_2 <= cpu_req_i;
			cpu_inst1_addr_o <= virtual_addr_i;
			cpu_inst2_addr_o <= virtual_addr_i + 32'h4;
			corr_pack0_o <= corr_pack0_i;
			corr_pack1_o <= corr_pack1_i;
		end
	end
    //TLB
    //TLB tlb0(
    //.virtual_addr_i(virtual_addr_i),
    //.physical_addr_o(physical_addr_1)
    //);
   
    
    //BANK 0~7 WAY 0~1
    //biwj indicates bank_i way_j
    wire [3:0]wea_way0;
    wire [3:0]wea_way1;
    
    //port a:write  port b:read
	wire [`InstBus]way0_cache[`BlockNum-1:0];
	wire [6:0] ram_addr = (stall_o)? physical_addr_2[`IndexBus] : virtual_addr_i[`IndexBus];//When stall, maintain the addr of ram 
    simple_dual_ram Bank0_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way0_cache[7]));
   
	wire [`InstBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[0]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[1]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[2]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[3]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[4]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[5]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[6]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina(read_from_mem[7]),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(way1_cache[7]));                        

    //Tag+Valid
    wire [`TagVBus]tagv_cache_w0;
    wire [`TagVBus]tagv_cache_w1;
    simple_dual_ram TagV0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(physical_addr_2[`IndexBus]), .dina({1'b1,physical_addr_2[`TagBus]}),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(tagv_cache_w0));
    simple_dual_ram TagV1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(physical_addr_2[`IndexBus]), .dina({1'b1,physical_addr_2[`TagBus]}),.clkb(clk),.enb(`Enable),.addrb(ram_addr),.doutb(tagv_cache_w1));  
    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[virtual_addr_i[`IndexBus]];
    always@(posedge clk)begin
        if(rst)
            LRU <= 0;
        else if(cpu_inst_valid_o == `Valid && hit_success == `HitSuccess)
            LRU[virtual_addr_i[`IndexBus]] <= hit_way0;
        else if(cpu_inst_valid_o == `Valid && hit_success == `HitFail)
            LRU[virtual_addr_i[`IndexBus]] <= wea_way0;
        else
            LRU <= LRU;
    end
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////RAM Collision Operation//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
	
	//RAM Coliision 
	reg ram_collision_way0;
	reg ram_collision_way1;
	//collision keep
    reg [`InstBus]inst1_from_mem_2;
    reg [`InstBus]inst2_from_mem_2;
    reg [`InstBus]tagv_way0_2;
    reg [`InstBus]tagv_way1_2;
	always@(posedge clk)begin
		ram_collision_way0 <= physical_addr_2[`IndexBus] == virtual_addr_i[`IndexBus] && |wea_way0;
		ram_collision_way1 <= physical_addr_2[`IndexBus] == virtual_addr_i[`IndexBus] && |wea_way1;
		inst1_from_mem_2 <= read_from_mem[virtual_addr_i[4:2]];
		inst2_from_mem_2 <= read_from_mem[virtual_addr_i[4:2]+3'h1];
		tagv_way0_2 <= {1'b1,physical_addr_2[`TagBus]};
		tagv_way1_2 <= {1'b1,physical_addr_2[`TagBus]};
	end
	//Collistion data select
    wire [`InstBus]inst1_way0 = ram_collision_way0 ? //write/read collision
								inst1_from_mem_2: way0_cache[physical_addr_2[4:2]];
    wire [`InstBus]inst2_way0 = ram_collision_way0? //write/read collision
								inst2_from_mem_2: way0_cache[physical_addr_2[4:2]+3'h1];
    wire [`InstBus]inst1_way1 = ram_collision_way1? //write/read collision
								inst1_from_mem_2: way1_cache[physical_addr_2[4:2]];
    wire [`InstBus]inst2_way1 = ram_collision_way1? //write/read collision
								inst2_from_mem_2: way1_cache[physical_addr_2[4:2]+3'h1];
    
    wire [`TagVBus]tagv_way0 = ram_collision_way0? //write/read collision
								tagv_way0_2: tagv_cache_w0;
    wire [`TagVBus]tagv_way1 = ram_collision_way1? //write/read collision
								tagv_way1_2: tagv_cache_w1;
                                
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Main Operation//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

    //Tag Hit
    wire hit_way0 = (tagv_way0[19:0]==physical_addr_2[`TagBus] && tagv_way0[20]==`Valid)? `HitSuccess : `HitFail;
    wire hit_way1 = (tagv_way1[19:0]==physical_addr_2[`TagBus] && tagv_way1[20]==`Valid)? `HitSuccess : `HitFail;
    wire hit_success = (hit_way0 | hit_way1) & cpu_req_2;//hit & req valid
	wire hit_fail = ~(hit_success) & cpu_req_2;
    
    
   //Mem communication
   wire read_success = mem_inst_rvalid_i;
   assign mem_inst_ren_o = ~read_success & hit_fail;//read axi when not hit(when read success, stop)
   assign mem_inst_araddr_o = physical_addr_2;
   //mem read data
   wire [`InstBus]read_from_mem[`BlockNum-1:0];
   for(genvar i =0 ;i<`BlockNum; i=i+1)begin
		assign read_from_mem[i] = mem_inst_rdata_i[32*(i+1)-1:32*i];
   end
   //write back mem data
	assign wea_way0 = (cpu_req_2 && read_success && LRU_pick == 1'b0)? 4'b1111 : 4'h0;
	assign wea_way1 = (cpu_req_2 && read_success && LRU_pick == 1'b1)? 4'b1111 : 4'h0;
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
   
    assign cpu_inst1_o = 	(hit_way0 == `HitSuccess)? inst1_way0:
							(hit_way1 == `HitSuccess)? inst1_way1:
							(hit_fail == `Valid && read_success == `Success)? read_from_mem[physical_addr_2[4:2]]:
							`ZeroWord;
           
    assign cpu_inst2_o = 	(hit_way0 == `HitSuccess)? inst2_way0:
							(hit_way1 == `HitSuccess)? inst2_way1:
							(hit_fail == `Valid && read_success == `Success)? read_from_mem[physical_addr_2[4:2]+3'h1]:
							`ZeroWord;
    wire debug1 = hit_success == `HitSuccess;
    wire debug2 = read_success == `Success;
    wire debug3 = (read_success == `Success)? cpu_req_2 &!rst :
                              `Invalid ;
    wire debug4 = (hit_success == `HitSuccess)? cpu_req_2 &!rst :
                              (read_success == `Success)? cpu_req_2 &!rst :
                              `Invalid ;
    
    always @ (*) begin
        if (hit_success == `HitSuccess || read_success == `Success) inst1_valid_o <= cpu_req_2 & ~rst;
        else inst1_valid_o <= `Invalid;
    end
    
    always @ (*) begin
        if (physical_addr_2[4:2] == 3'b111) inst2_valid_o <= `Invalid;
        else inst2_valid_o <= inst1_valid_o;
    end
			  
	assign stall_o = (hit_fail == `Valid)? ~cpu_inst_valid_o: //not valid == stall_o
					rst;//if ICache is reset, then pc should not move 
	assign is_pipeline2_empty_o = !cpu_req_2;
	
	assign hit_o = hit_success;
	assign is_working_o = cpu_req_i | (hit_fail & !read_success);
//	assign is_mem_request = hit_fail;
endmodule
