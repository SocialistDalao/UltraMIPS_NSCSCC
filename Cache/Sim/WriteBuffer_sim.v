`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/06 19:46:25
// Design Name: 
// Module Name: WriteBuffer_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module WriteBuffer_sim(

    );
    reg clk=0;
    always #10 clk=~clk;
    reg rst=1;
    //CPU write request
    reg cpu_wreq_i=0;
    reg [`DataAddrBus]cpu_awaddr_i=0;
    reg [`WayBus]cpu_wdata_i=0;//一个块的大小
	wire write_hit_o;
	//CPU read request and response
    reg cpu_rreq_i=0;
    reg [`DataAddrBus]cpu_araddr_i=0;
	 wire read_hit_o;
	 wire [`WayBus]cpu_rdata_o;
	
    //state
    wire [`FIFOStateBus]state_o;
	
    //MEM 
	wire wen ;
     wire[`WayBus] mem_wdata_o;//一个块的大小
     wire [`DataAddrBus]mem_awaddr_o;
    reg mem_bvalid_i=0;
    WriteBuffer WB0(
        .clk(clk),
        .rst(rst),
        //CPU write request
        .cpu_wreq_i(cpu_wreq_i),
        .cpu_awaddr_i(cpu_awaddr_i),
        .cpu_wdata_i(cpu_wdata_i),//一个块的大小
        .write_hit_o(write_hit_o),
        //CPU read request and response
        .cpu_rreq_i(cpu_rreq_i),
        .cpu_araddr_i(cpu_araddr_i),
        .read_hit_o(read_hit_o),
        .cpu_rdata_o(cpu_rdata_o),
        
        //state
        .state_o(state_o),
        
        //MEM 
		.mem_wen_o(wen),
        .mem_wdata_o(mem_wdata_o),//一个块的大小
        .mem_awaddr_o(mem_awaddr_o),
        .mem_bvalid_i(mem_bvalid_i)
    );
    
    initial begin
        #500 rst =0;
		
		///////////////////////////////////////////////////
		//////////////////normal write/////////////////////
		///////////////////////////////////////////////////
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24687_571;
		cpu_wdata_i = 256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		wait(state_o == `STATE_WORKING && wen == `WriteEnable
		&& mem_awaddr_o == 32'h24687_560
		 && mem_wdata_o == 256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234)begin 
			#200 mem_bvalid_i = `Valid;
			#20 mem_bvalid_i = `Invalid;
		end
		#20
		if(state_o == `STATE_EMPTY)begin
			$display("Success: Normal Write");
		end
		else begin
			$display("Fail: Normal Write");
			$stop;
		end
		
		///////////////////////////////////////////////////
		/////////overflow write && normal read/////////////
		///////////////////////////////////////////////////
		if(state_o == `STATE_EMPTY)begin
			$display("Success: overflow write STATE_EMPTY");
		end
		else begin
			$display("Fail: overflow Write STATE_EMPTY");
			$stop;
		end
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24687_571;
		cpu_wdata_i = 256'h02345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		if(state_o == `STATE_WORKING)begin
			$display("Success: overflow Write STATE_WORKING");
		end
		else begin
			$display("Fail: overflow Write STATE_WORKING");
			$stop;
		end
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24697_571;
		cpu_wdata_i = 256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		
		//read
		cpu_rreq_i = 1;
		cpu_araddr_i = 32'h99617_560;
		#20 cpu_rreq_i = 0;
		if(read_hit_o == `HitFail )begin
			$display("Success: normal read not hit");
		end
		else begin
			$display("Fail: normal read not hit");
			$stop;
		end
		//read finish
		
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h25687_571;
		cpu_wdata_i = 256'h22345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24617_571;
		cpu_wdata_i = 256'h32345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		
		//read
		cpu_rreq_i = 1;
		cpu_araddr_i = 32'h24617_560;
		#20 cpu_rreq_i = 0;
		if(read_hit_o == `HitSuccess &&  cpu_rdata_o == 256'h32345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234)begin
			$display("Success: normal read hit");
		end
		else begin
			$display("Fail: normal read hit");
			$stop;
		end
		//read finish
		
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24387_571;
		cpu_wdata_i = 256'h42345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24307_571;
		cpu_wdata_i = 256'h52345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h14387_571;
		cpu_wdata_i = 256'h62345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h74387_571;
		cpu_wdata_i = 256'h72345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		if(state_o == `STATE_FULL)begin
			$display("Success: overflow Write STATE_FULL");
		end
		else begin
			$display("Fail: overflow Write STATE_FULL");
			$stop;
		end
		//write response
		#200 mem_bvalid_i = `Valid;
		#20 mem_bvalid_i = `Invalid;
		
		//read
		cpu_rreq_i = 1;
		cpu_araddr_i = 32'h24687_560;
		#20 cpu_rreq_i = 0;
		if(read_hit_o == `HitFail )begin
			$display("Success: normal read not hit(hit invalid)");
		end
		else begin
			$display("Fail: normal read not hit(hit invalid)");
			$stop;
		end
		//read finish
		
		///////////////////////////////////////////////////
		/////////////////////write hit/////////////////////
		///////////////////////////////////////////////////
		
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24617_573;
		cpu_wdata_i = 256'h0;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		if(write_hit_o == `HitSuccess && WB0.FIFO_data[4]==256'h0 )begin
			$display("Success: write hit");
		end
		else begin
			$display("Fail: write hit");
			$stop;
		end
		
		///////////////////////////////////////////////////
		///////////////////read hit head///////////////////
		///////////////////////////////////////////////////
		
		//read
		cpu_rreq_i = 1;
		cpu_araddr_i = 32'h24697_560;
		#20 cpu_rreq_i = 0;
		if(read_hit_o == `HitSuccess &&  cpu_rdata_o == 256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234)begin
			$display("Success: read hit head");
		end
		else begin
			$display("Fail: read hit head");
			$stop;
		end
		//read finish
		
		
		///////////////////////////////////////////////////
		///////////////////write hit head//////////////////
		///////////////////////////////////////////////////
		
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24697_56b;
		cpu_wdata_i = 256'h1111;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		#100
		mem_bvalid_i = 1;//rewrite test
		#20
		mem_bvalid_i = 0;
		if(state_o == `STATE_WORKING && wen == `WriteEnable
		&& mem_awaddr_o == 32'h24697_560
		 && mem_wdata_o == 256'h1111)begin 
			$display("Success: write hit head");
		end
		else begin
			$display("Fail: write hit head");
			$stop;
		end
		
		///////////////////////////////////////////////////
		//////////////read hit head(rewritten)////////////
		///////////////////////////////////////////////////	
		
		//read
		cpu_rreq_i = 1;
		cpu_araddr_i = 32'h24697_56b;
		#20 cpu_rreq_i = 0;
		if(read_hit_o == `HitSuccess &&  cpu_rdata_o == 256'h1111)begin
			$display("Success: write hit head(rewritten)");
		end
		else begin
			$display("Fail: write hit head(rewritten)");
			$stop;
		end
		//read finish
		
		///////////////////////////////////////////////////
		//////////////write hit head(when bvalid)////////////
		///////////////////////////////////////////////////	
		
		#200
		mem_bvalid_i=1;
		cpu_wreq_i = 1;
		cpu_awaddr_i = 32'h24697_571;
		cpu_wdata_i = 256'h2222;
		#20 cpu_wreq_i = 0;//Keep one cycle ONLY 
		
		mem_bvalid_i = 0;//rewrite test
		#20
		if(state_o == `STATE_WORKING && wen == `WriteEnable
		&& mem_awaddr_o == 32'h24697_560
		 && mem_wdata_o == 256'h2222)begin 
			$display("Success: write hit head(when bvalid)");
		end
		else begin
			$display("Fail: write hit head(when bvalid)");
			$stop;
		end
    end
endmodule
