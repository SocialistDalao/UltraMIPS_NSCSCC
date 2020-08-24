`timescale 1ns / 1ps
`include"defines.v"
`include"defines_cache.v"
module WriteBuffer(
    input clk,
    input rst,
    //CPU write request
    input wire cpu_wreq_i,
    input wire [`DataAddrBus]cpu_awaddr_i,
    input wire [`WayBus]cpu_wdata_i,//һ����Ĵ�С
	output wire write_hit_o,
	//CPU read request and response
    input wire cpu_rreq_i,
    input wire [`DataAddrBus]cpu_araddr_i,
	output wire read_hit_o,
	output reg [`WayBus]cpu_rdata_o,
	
    //state
    output reg buffer_valid_o,
	
    //MEM 
    input wire mem_bvalid_i,
    output wire mem_wen_o,
    output wire[`WayBus] mem_wdata_o,//һ����Ĵ�С
    output wire [`DataAddrBus]mem_awaddr_o
    );
	//��ַ���봦��
	wire [`DataAddrBus]cpu_awaddr = {cpu_awaddr_i[31:5],5'h0};
	wire [`DataAddrBus]cpu_araddr = {cpu_araddr_i[31:5],5'h0};
    
    reg [`WayBus]buffer_data;
    reg [`DataAddrBus]buffer_addr;
	
	//��ͻ���
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
	
    always@(posedge clk)begin
        if(rst)begin
            buffer_valid_o <= `Invalid;
        end
        if( mem_bvalid_i == `Valid && !sign_rewrite //д�������û�г���write collision
			&& !write_hit_head)begin//���д���ͷû��ǡ�ó���collision
			//����д
			buffer_valid_o <= `Invalid;
		end
        if(cpu_wreq_i == `WriteEnable && write_hit_o == `HitFail)begin //����д�룬���
            buffer_valid_o <= `Valid;
		end
    end
	
	//Read Hit
	assign read_hit_o = ((cpu_araddr == buffer_addr) && buffer_valid_o)? `HitSuccess: `HitFail;
	//Write Hit
	wire write_hit = ((cpu_awaddr == buffer_addr) && buffer_valid_o)? `HitSuccess: `HitFail;
	wire write_hit_head = write_hit;
	
	//Write hitд�루����д��ͻ��
    always@(posedge clk)begin
        if(cpu_wreq_i)begin
			buffer_data <= cpu_wdata_i;
			buffer_addr <= cpu_awaddr;
        end//else keep same
    end//always
	
	//Read hit
	always@(posedge clk)begin
		if(cpu_rreq_i && read_hit_o)begin
			cpu_rdata_o <= buffer_data;
		end//else keep same
	end
    
    
    //���ߴ���
    assign mem_wen_o = (mem_bvalid_i == `Valid)? `Invalid: buffer_valid_o;
    assign mem_awaddr_o = buffer_addr;
    assign mem_wdata_o = buffer_data;
endmodule
