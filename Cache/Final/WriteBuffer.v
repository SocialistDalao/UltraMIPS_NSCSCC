`timescale 1ns / 1ps
`include"defines.v"
`include"defines_cache.v"
module WriteBuffer(
    input clk,
    input rst,
    //CPU write request
    input wire cpu_wreq_i,
    input wire [`DataAddrBus]cpu_awaddr_i,
    input wire [`WayBus]cpu_wdata_i,//一个块的大小
	output wire write_hit_o,
	//CPU read request and response
    input wire cpu_rreq_i,
    input wire [`DataAddrBus]cpu_araddr_i,
	output wire read_hit_o,
	output reg [`WayBus]cpu_rdata_o,
	
    //state
    output wire [`FIFOStateBus]state_o,
	
    //MEM 
    input wire mem_bvalid_i,
    output wire mem_wen_o,
    output wire[`WayBus] mem_wdata_o,//一个块的大小
    output wire [`DataAddrBus]mem_awaddr_o
    );
	//地址对齐处理
	wire [`DataAddrBus]cpu_awaddr = {cpu_awaddr_i[31:5],5'h0};
	wire [`DataAddrBus]cpu_araddr = {cpu_araddr_i[31:5],5'h0};
	
    //当前队列状态
    //STATE_EMPTY `FIFOStateNumLog2'h0                  
    //STATE_WORKING `FIFOStateNumLog2'h1                
    //STATE_FULL `FIFOStateNumLog2'h3
    wire state_full;
    wire state_working;
    assign state_full = (rst)? `Invalid:
                        (FIFO_valid[tail] == `Valid)? `Valid: `Invalid;
    assign state_working = (rst)? `Invalid:
                        (FIFO_valid[head] == `Invalid)? `Invalid: `Valid;
    assign state_o = {state_full,state_working};
    
	

	//队列本体
    reg [`WayBus]FIFO_data[`FIFONum-1:0];
    reg [`DataAddrBus]FIFO_addr[`FIFONum-1:0];
	
	//冲突检测
	//Write Collision
	reg sign_rewrite;
	always@(posedge clk) begin
		if(rst)
			sign_rewrite <= `Invalid;
		else if(mem_bvalid_i)//write success (prior to write collision)
			sign_rewrite <= `Invalid;
		else if(write_hit_head)//write collision
			sign_rewrite <= `Valid;
		else
			sign_rewrite <=  sign_rewrite;
	end
	
    //头尾指针维护
    reg [`FIFONumLog2-1:0]tail;//表征当前正在写入的数据位置
    reg [`FIFONumLog2-1:0]head;//表征最后需要写入数据位置的后一位
    reg [`FIFONum-1:0]FIFO_valid;//表征buffer中的数据是否有效（高电平有效）
    always@(posedge clk)begin
        if(rst)begin
            head <= `FIFONumLog2'h0;
            tail <= `FIFONumLog2'h0;
			FIFO_valid <= `FIFONum'h0;
        end
        if( mem_bvalid_i == `Valid && !sign_rewrite //写入完毕且没有出现write collision
			&& !write_hit_head)begin//如果写完队头没有恰好出现collision
			//不重写
			FIFO_valid[head] <= `Invalid;
            head <= head + 1;
		end
        if(cpu_wreq_i == `WriteEnable && write_hit_o == `HitFail)begin //增加写入，入队
            tail <= tail + 1;
			FIFO_valid[tail] <= `Valid;
		end
    end
	
	//Read Hit
	reg [`FIFONum-1:0]read_hit;
	assign read_hit_o = |read_hit;
	for(genvar i = 0;i < `FIFONum; i = i+1)begin
		always@(posedge clk) read_hit[i] = ((cpu_araddr == FIFO_addr[i]) && FIFO_valid[i])? `HitSuccess: `HitFail;
	end
	
	//Read hit
	always@(*)begin
        case(read_hit)
            `FIFONum'b00000001: cpu_rdata_o <= FIFO_data[0];
            `FIFONum'b00000010: cpu_rdata_o <= FIFO_data[1];
            `FIFONum'b00000100: cpu_rdata_o <= FIFO_data[2];
            `FIFONum'b00001000: cpu_rdata_o <= FIFO_data[3];
            `FIFONum'b00010000: cpu_rdata_o <= FIFO_data[4];
            `FIFONum'b00100000: cpu_rdata_o <= FIFO_data[5];
            `FIFONum'b01000000: cpu_rdata_o <= FIFO_data[6];
            `FIFONum'b10000000: cpu_rdata_o <= FIFO_data[7];
            default:  cpu_rdata_o <= `ZeroWay;
        endcase
	end
    
	
	//Write Hit
	wire [`FIFONum-1:0]write_hit;
	wire write_hit_head = write_hit[head] & cpu_wreq_i;
	assign write_hit_o = |write_hit;
	for(genvar i = 0;i < `FIFONum; i = i+1)begin
		assign write_hit[i] = ((cpu_awaddr == FIFO_addr[i]) && FIFO_valid[i])? `HitSuccess: `HitFail;
	end
	
	//Write hit写入（包括写冲突）
    always@(posedge clk)begin
        if(cpu_wreq_i)begin
			case(write_hit)
				`FIFONum'b00000001: FIFO_data[0] <= cpu_wdata_i;
				`FIFONum'b00000010: FIFO_data[1] <= cpu_wdata_i;
				`FIFONum'b00000100: FIFO_data[2] <= cpu_wdata_i;
				`FIFONum'b00001000: FIFO_data[3] <= cpu_wdata_i;
				`FIFONum'b00010000: FIFO_data[4] <= cpu_wdata_i;
				`FIFONum'b00100000: FIFO_data[5] <= cpu_wdata_i;
				`FIFONum'b01000000: FIFO_data[6] <= cpu_wdata_i;
				`FIFONum'b10000000: FIFO_data[7] <= cpu_wdata_i;
				default:begin//没有冲突的入队操作
					FIFO_data[tail] <= cpu_wdata_i;
					FIFO_addr[tail] <= cpu_awaddr;
				end
			endcase
        end//else keep same
    end//always
	
    
    //总线处理
    assign mem_wen_o = (state_o == `STATE_EMPTY)? `Invalid:
                        (mem_bvalid_i == `Valid)? `Invalid: `Valid;
    assign mem_awaddr_o = FIFO_addr[head];
    assign mem_wdata_o = FIFO_data[head];
endmodule
