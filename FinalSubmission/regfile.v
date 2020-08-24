`include "defines.v"

module regfile(

	input clk,
	input rst,
	
	//写端口1
	input                 we1,
	input[`RegAddrBus]    waddr1,
	input[`RegBus]        wdata1,
	
	//写端口2
	input                 we2,
	input[`RegAddrBus]    waddr2,
	input[`RegBus]        wdata2,
	
	//读端口1
	input[`RegAddrBus]     raddr1,
	output reg[`RegBus]    rdata1,
	
	//读端口2
	input[`RegAddrBus]     raddr2,
	output reg[`RegBus]    rdata2,
	
	//读端口3
	input wire[`RegAddrBus]    raddr3,
	output reg[`RegBus]        rdata3,
	
	//读端口4
	input wire[`RegAddrBus]    raddr4,
	output reg[`RegBus]        rdata4,
	
	output wire[`RegBus] reg31
	
);

    reg[`RegBus]  regs[0:`RegNum-1];
    assign reg31 = regs[31];
    /*
     wire[`RegBus] reg_t5;
     wire[`RegBus] reg_s2;
    
    assign reg_t5 = regs[13];
    assign reg_s2 = regs[18];
    */
    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            case ({we2, we1})
			 {`WriteDisable, `WriteEnable}: if (waddr1 != `NOPRegAddr) regs[waddr1] <= wdata1;
			 {`WriteEnable, `WriteDisable}: if (waddr2 != `NOPRegAddr) regs[waddr2] <= wdata2;
			 {`WriteEnable, `WriteEnable}: begin
			     if (waddr2 != `NOPRegAddr) regs[waddr2] <= wdata2;
			     if (waddr1 != waddr2 && waddr1 != `NOPRegAddr) begin // 没有发生“写后写”（WAW）相关
			         regs[waddr1] <= wdata1;
			     end
			 end
			 default: ;
            endcase
        end
    end
	
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata1 = `ZeroWord;
        end else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 = `ZeroWord;
        end else begin
            case ({we2, we1})
			 2'b01: rdata1 = (raddr1 == waddr1) ? wdata1 : regs[raddr1];
			 2'b10: rdata1 = (raddr1 == waddr2) ? wdata2 : regs[raddr1];
			 2'b11: begin
			     if (raddr1 == waddr2) rdata1 = wdata2;
			     else if (raddr1 == waddr1) rdata1 = wdata1;
			     else rdata1 = regs[raddr1];
			 end
			 default: rdata1 = regs[raddr1];
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata2 = `ZeroWord;
        end else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 = `ZeroWord;
        end else begin
            case ({we2, we1})
			 2'b01: rdata2 = (raddr2 == waddr1) ? wdata1 : regs[raddr2];
			 2'b10: rdata2 = (raddr2 == waddr2) ? wdata2 : regs[raddr2];
			 2'b11: begin
			     if (raddr2 == waddr2) rdata2 = wdata2;
			     else if (raddr2 == waddr1) rdata2 = wdata1;
			     else rdata2 = regs[raddr2];
			 end
			 default: rdata2 = regs[raddr2];
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata3 = `ZeroWord;
        end else if (raddr3 == `RegNumLog2'h0) begin
            rdata3 = `ZeroWord;
        end else begin
            case ({we2, we1})
			 2'b01: rdata3 = (raddr3 == waddr1) ? wdata1 : regs[raddr3];
			 2'b10: rdata3 = (raddr3 == waddr2) ? wdata2 : regs[raddr3];
			 2'b11: begin
			     if (raddr3 == waddr2) rdata3 = wdata2;
			     else if (raddr3 == waddr1) rdata3 = wdata1;
			     else rdata3 = regs[raddr3];
			 end
			 default: rdata3 = regs[raddr3];
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata4 = `ZeroWord;
        end else if (raddr4 == `RegNumLog2'h0) begin
            rdata4 = `ZeroWord;
        end else begin
            case ({we2, we1})
			 2'b01: rdata4 = (raddr4 == waddr1) ? wdata1 : regs[raddr4];
			 2'b10: rdata4 = (raddr4 == waddr2) ? wdata2 : regs[raddr4];
			 2'b11: begin
			     if (raddr4 == waddr2) rdata4 = wdata2;
			     else if (raddr4 == waddr1) rdata4 = wdata1;
			     else rdata4 = regs[raddr4];
			 end
			 default: rdata4 = regs[raddr4];
            endcase
        end
    end

endmodule