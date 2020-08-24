`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 代码架构：
//----初始定义：
//--------TLB：虚实地址转换
//--------BANK_RAM
//--------TAG+VALID_RAM
//--------DIRTY
//--------LRU
//----状态机描述：
//--------状态转移动作
//--------状态转移表
//----组合逻辑具体操作：
//--------STATE_SCAN_CACHE
//--------STATE_HIT_FAIL
//--------STATE_WRITE_BACK
//----输出控制：
//--------STATE_SCAN_CACHE
//////////////////////////////////////////////////////////////////////////////////


module ICache(

    input wire 					clk,
    input wire 					rst,
    
    //read inst request
    input wire 					cpu_req_i,
    input wire [`RegBus]		virtual_addr_i,//inst read virtual addr
    
    //read inst result
    output wire 				hit_o,
    output wire 				cpu_inst_valid_o,
    output wire [`InstBus] 		cpu_inst1_o,
    output wire [`InstBus] 		cpu_inst2_o,
	output wire 				stall_o,
	output wire 				single_issue_o,
    
    //read from mem
    input wire 					mem_inst_rvalid_i,
    input wire [`WayBus]		mem_inst_rdata_i,//一个块的大小
    output wire 				mem_inst_ren_o,
    output wire[`InstAddrBus]	mem_inst_araddr_o
    
    );
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////初始定义//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    wire [`RegBus]physical_addr=virtual_addr_i;
    wire index = physical_addr[`IndexBus];
    wire offset = physical_addr[`OffsetBus];
    //TLB
//    TLB tlb0(
//    .virtual_addr_i(virtual_addr_i),
//    .physical_addr_o(physical_addr)
//    );
   
    
    //BANK 0~7 WAY 0~1
    //biwj indicates bank_i way_j
    wire [3:0]wea_way0;
    wire [3:0]wea_way1;
    
	wire [`InstBus]way0_cache[`BlockNum-1:0];
    //porta:write  portb:read
    simple_dual_ram Bank0_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[0]));
    simple_dual_ram Bank1_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[1]));
    simple_dual_ram Bank2_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[2]));
    simple_dual_ram Bank3_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[3]));
    simple_dual_ram Bank4_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[4]));
    simple_dual_ram Bank5_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[5]));
    simple_dual_ram Bank6_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[6]));
    simple_dual_ram Bank7_way0 (.clka(clk),.ena(|wea_way0),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way0_cache[7]));
//    bank_ram Bank0_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.douta(way0_cache[0]));
//    bank_ram Bank1_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.douta(way0_cache[1]));
//    bank_ram Bank2_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.douta(way0_cache[2]));
//    bank_ram Bank3_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.douta(way0_cache[3]));
//    bank_ram Bank4_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.douta(way0_cache[4]));
//    bank_ram Bank5_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.douta(way0_cache[5]));
//    bank_ram Bank6_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.douta(way0_cache[6]));
//    bank_ram Bank7_way0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.douta(way0_cache[7]));
    
	wire [`InstBus]way1_cache[`BlockNum-1:0]; 
    simple_dual_ram Bank0_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[0]));
    simple_dual_ram Bank1_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[1]));
    simple_dual_ram Bank2_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[2]));
    simple_dual_ram Bank3_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[3]));
    simple_dual_ram Bank4_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[4]));
    simple_dual_ram Bank5_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[5]));
    simple_dual_ram Bank6_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[6]));
    simple_dual_ram Bank7_way1 (.clka(clk),.ena(|wea_way1),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.clkb(clk),.enb(`Enable),.addrb(virtual_addr_i[`IndexBus]),.doutb(way1_cache[7]));                        
//    bank_ram Bank0_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*1-1:32*0]),.douta(way1_cache[0]));
//    bank_ram Bank1_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*2-1:32*1]),.douta(way1_cache[1]));
//    bank_ram Bank2_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*3-1:32*2]),.douta(way1_cache[2]));
//    bank_ram Bank3_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*4-1:32*3]),.douta(way1_cache[3]));
//    bank_ram Bank4_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*5-1:32*4]),.douta(way1_cache[4]));
//    bank_ram Bank5_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*6-1:32*5]),.douta(way1_cache[5]));
//    bank_ram Bank6_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*7-1:32*6]),.douta(way1_cache[6]));
//    bank_ram Bank7_way1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]), .dina(read_from_mem[32*8-1:32*7]),.douta(way1_cache[7]));

    //Tag+Valid
    wire [`TagVBus]tagv_cache_w0;
    wire [`TagVBus]tagv_cache_w1;
    tag_ram TagV0 (.clka(clk),.ena(`Enable),.wea(wea_way0),.addra(virtual_addr_i[`IndexBus]),.dina({1'b1,physical_addr[`TagBus]}),.douta(tagv_cache_w0));
    tag_ram TagV1 (.clka(clk),.ena(`Enable),.wea(wea_way1),.addra(virtual_addr_i[`IndexBus]),.dina({1'b1,physical_addr[`TagBus]}),.douta(tagv_cache_w1));
    
    //LRU
    reg [`SetBus]LRU;
    wire LRU_pick = LRU[virtual_addr_i[`IndexBus]];
    always@(posedge clk)begin
        if(rst)
            LRU <= 0;
        else if(cpu_inst_valid_o == `Valid && hit_o == `HitSuccess)
            LRU[virtual_addr_i[`IndexBus]] <= hit_way0;
        else if(cpu_inst_valid_o == `Valid && hit_o == `HitFail)
            LRU[virtual_addr_i[`IndexBus]] <= wea_way0;
        else
            LRU <= LRU;
    end
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////状态机描述////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

    reg [`StateBus]current_state;
    reg [`StateBus]next_state;
//    状态转移动作  
    always@(posedge clk)begin
        if(rst)
            current_state <= `STATE_LOOK_UP;
        else
            current_state <= next_state;
    end
    
//    状态转移表 
    always@(*)begin
        next_state <= `STATE_LOOK_UP;
        case(current_state)
            `STATE_LOOK_UP:begin
                if(cpu_req_i)begin
                    next_state <= `STATE_SCAN_CACHE;
                end
                else
                    next_state <= `STATE_LOOK_UP;
            end
            `STATE_SCAN_CACHE:begin
                if(hit_o)
                    next_state <= `STATE_LOOK_UP;
                else
                    next_state <= `STATE_HIT_FAIL;
            end
            `STATE_HIT_FAIL:begin
                if(read_success)
                    next_state <= `STATE_WRITE_BACK;
                else
                    next_state <= `STATE_HIT_FAIL;
            end
            `STATE_WRITE_BACK:
                    next_state <= `STATE_LOOK_UP;
            default:;
        endcase
    end//always
    
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////组合逻辑//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
    
    //STATE_SCAN_CACHE：选择ram中对应的bank
    wire [`InstBus]inst1_way0 = way0_cache[virtual_addr_i[4:2]   ];
    wire [`InstBus]inst2_way0 = way0_cache[virtual_addr_i[4:2]+3'h1 ];
    wire [`InstBus]inst1_way1 = way1_cache[virtual_addr_i[4:2]   ];
    wire [`InstBus]inst2_way1 = way1_cache[virtual_addr_i[4:2]+3'h1 ];
    
    //Tag Hit
    wire hit_way0 = (tagv_cache_w0[19:0]==physical_addr[`TagBus] && tagv_cache_w0[20]==`Valid)? `HitSuccess : `HitFail;
    wire hit_way1 = (tagv_cache_w1[19:0]==physical_addr[`TagBus] && tagv_cache_w1[20]==`Valid)? `HitSuccess : `HitFail;
    assign hit_o = (current_state==`STATE_SCAN_CACHE)? (hit_way0 | hit_way1) :`HitFail;
    
    
   //STATE_HIT_FAIL
   assign mem_inst_ren_o = (current_state==`STATE_HIT_FAIL && !read_success)?`ReadEnable : `ReadDisable;
   assign mem_inst_araddr_o = physical_addr;
   wire read_success = mem_inst_rvalid_i;
   reg [`WayBus]read_from_mem;
   always@(posedge clk) begin 
        if(current_state==`STATE_HIT_FAIL )
            read_from_mem<= mem_inst_rdata_i;
        else
            read_from_mem<= read_from_mem;
   end
   
   
   //STATE_WRITE_BACK
    assign wea_way0 = (current_state==`STATE_WRITE_BACK && LRU_pick == 1'b0)? 4'b1111 : 4'h0;
    assign wea_way1 = (current_state==`STATE_WRITE_BACK && LRU_pick == 1'b1)? 4'b1111 : 4'h0;
    
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////输出控制//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
   
    assign cpu_inst1_o = (current_state==`STATE_SCAN_CACHE && hit_way0 == `HitSuccess)? inst1_way0:
                        (current_state==`STATE_SCAN_CACHE && hit_way1 == `HitSuccess)? inst1_way1:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h0)? read_from_mem[32*1-1:32*0]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h1)? read_from_mem[32*2-1:32*1]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h2)? read_from_mem[32*3-1:32*2]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h3)? read_from_mem[32*4-1:32*3]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h4)? read_from_mem[32*5-1:32*4]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h5)? read_from_mem[32*6-1:32*5]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h6)? read_from_mem[32*7-1:32*6]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h7)? read_from_mem[32*8-1:32*7]:
                        `ZeroWord;
           
    assign cpu_inst2_o = (current_state==`STATE_SCAN_CACHE && hit_way0 == `HitSuccess)? inst2_way0:
                        (current_state==`STATE_SCAN_CACHE && hit_way1 == `HitSuccess)? inst2_way1:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h0)? read_from_mem[32*2-1:32*1]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h1)? read_from_mem[32*3-1:32*2]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h2)? read_from_mem[32*4-1:32*3]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h3)? read_from_mem[32*5-1:32*4]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h4)? read_from_mem[32*6-1:32*5]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h5)? read_from_mem[32*7-1:32*6]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h6)? read_from_mem[32*8-1:32*7]:
                        (current_state==`STATE_WRITE_BACK &&virtual_addr_i[4:2] == 3'h7)? read_from_mem[32*1-1:32*0]:
                        `ZeroWord;
						
    assign cpu_inst_valid_o = (current_state==`STATE_SCAN_CACHE && hit_o == `HitSuccess)? `Valid :
                              (current_state==`STATE_WRITE_BACK)                        ? `Valid :
                              `Invalid ;
							  
			  
	assign stall_o = (current_state == `STATE_SCAN_CACHE)? ~cpu_inst_valid_o: //not valid == stall_o
					(current_state == `STATE_LOOK_UP ) ? cpu_req_i:
					(current_state == `STATE_HIT_FAIL ) ? `Valid:
					(current_state == `STATE_WRITE_BACK ) ? `Invalid:
					`Invalid; 
	
	assign single_issue_o = (virtual_addr_i[4:2] == 3'b111)? `Valid:`Invalid;//in the edge
endmodule
