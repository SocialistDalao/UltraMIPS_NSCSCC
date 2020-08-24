`timescale 1ns / 1ps
`include"defines.v"
`include"defines_cache.v"
module InstBuffer(
    input clk,
    input rst,
	input flush,
    //Issue
    input wire 					issue_mode_i,// Issue mode of issue stage
    input wire 					issue_i,// Whether issue stage has issued inst
    output wire [`InstBus]		issue_inst1_o,
    output wire [`InstBus]		issue_inst2_o,
    output wire [`InstAddrBus] issue_inst1_addr_o,
    output wire [`InstAddrBus]	issue_inst2_addr_o,
    output wire 				issue_ok_o,//when there are 3 or more inst in FIFO, we can issue
	//Fetch inst	
    input wire [`InstBus]		ICache_inst1_i,
    input wire [`InstBus]		ICache_inst2_i,
	input wire [`InstAddrBus] 	ICache_inst1_addr_i,
	input wire [`InstAddrBus] 	ICache_inst2_addr_i,
    input wire 					ICache_inst1_valid_o,
    input wire 					ICache_inst2_valid_o,
	output wire 				buffer_full_o
	
    );
	//????¡À???
    reg [`InstBus]FIFO_data[`InstBufferSize-1:0];
    reg [`InstAddrBus]FIFO_addr[`InstBufferSize-1:0];
	
    //?¡¤?????????¡è
    reg [`InstBufferSizeLog2-1:0]tail;//¡À¨ª?¡Â?¡À?¡ã??????????????????
    reg [`InstBufferSizeLog2-1:0]head;//¡À¨ª?¡Â¡Á??¨®?¨¨?????????????????¨®????
    reg [`InstBufferSize-1:0]FIFO_valid;//¡À¨ª?¡Âbuffer??????????¡¤????¡ì?¡§?????????¡ì??
    always@(posedge clk)begin
        if(rst|flush)begin
            head <= `InstBufferSizeLog2'h0;
			FIFO_valid <= `InstBufferSize'h0;
        end
		//pop
        else if( issue_i == `Valid && issue_mode_i == `SingleIssue)begin//Issue one inst
			FIFO_valid[head] <= `Invalid;
            head <= head + 1;
		end
        else if( issue_i == `Valid && issue_mode_i == `DualIssue)begin//Issue two inst
			FIFO_valid[head] <= `Invalid;
			FIFO_valid[head+`InstBufferSizeLog2'h1] <= `Invalid;
            head <= head + 2;
		end
		
        if(rst|flush)begin
            tail <= `InstBufferSizeLog2'h0;
        end
		//push
        else if( ICache_inst1_valid_o == `Valid && ICache_inst2_valid_o == `Invalid)begin//ICache return one inst
			FIFO_valid[tail] <= `Valid;
            tail <= tail + 1;
		end
        else if( ICache_inst1_valid_o == `Valid && ICache_inst2_valid_o == `Valid)begin//ICache return two inst
			FIFO_valid[tail] <= `Valid;
			FIFO_valid[tail+`InstBufferSizeLog2'h1] <= `Valid;
            tail <= tail + 2;
		end
    end
	
	
	//Write
    always@(posedge clk)begin
		FIFO_data[tail] <= ICache_inst1_i;
		FIFO_addr[tail] <= ICache_inst1_addr_i;
		FIFO_data[tail+`InstBufferSizeLog2'h1] <= ICache_inst2_i;
		FIFO_addr[tail+`InstBufferSizeLog2'h1] <= ICache_inst2_addr_i;
    end
	   
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
	assign issue_inst1_o = FIFO_data[head];
	assign issue_inst2_o = FIFO_data[head+`InstBufferSizeLog2'h1];
	assign issue_inst1_addr_o = FIFO_addr[head];
	assign issue_inst2_addr_o = FIFO_addr[head+`InstBufferSizeLog2'h1];
	assign issue_ok_o = FIFO_valid[head+`InstBufferSizeLog2'h2];
    //full
	assign buffer_full_o = FIFO_valid[tail+`InstBufferSizeLog2'h5];
endmodule
