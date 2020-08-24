`include "defines.v"

module commit(

	input clk,
	input rst,
	input flush,
	input flush_cause,
	input[4:0] stall,

	// 来自访存阶段	
	input[`InstAddrBus]pc_i,
	input[`RegAddrBus] waddr1_i,
	input[`RegAddrBus] waddr2_i,
    input              we1_i,
    input              we2_i,
    input[`RegBus]     wdata1_i,
    input[`RegBus]     wdata2_i,
    input[`RegBus]     hi_i,
	input[`RegBus]     lo_i,
	input              whilo_i,
	input              LLbit_i,
	input              LLbit_we_i,
	input[2:0]         cp0_wsel_i,
	input              cp0_we_i,
	input[`RegAddrBus] cp0_waddr_i,
	input[`RegBus]     cp0_wdata_i,
	input              exception_first_inst_i,
	
	// 提交更改给寄存器堆
	output reg[`InstAddrBus]pc_o,
	output reg[`RegAddrBus] waddr1_o,
	output reg[`RegAddrBus] waddr2_o,
    output reg              we1_o,
    output reg              we2_o,
    output reg[`RegBus]     wdata1_o,
    output reg[`RegBus]     wdata2_o,
    output reg[`RegBus]     hi_o,
	output reg[`RegBus]     lo_o,
	output reg              whilo_o,
	output reg              LLbit_o,
	output reg              LLbit_we_o,
	output reg[2:0]         cp0_wsel_o,
	output reg              cp0_we_o,
	output reg[`RegAddrBus] cp0_waddr_o,
	output reg[`RegBus]     cp0_wdata_o
	
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            pc_o <= `ZeroWord;
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= `NOPRegAddr;
            cp0_wdata_o <= `ZeroWord;
        end else if (flush == `Flush && flush_cause == `Exception && exception_first_inst_i == 1'b1) begin
            pc_o <= `ZeroWord;
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= `NOPRegAddr;
            cp0_wdata_o <= `ZeroWord;
        end else if (flush == `Flush && flush_cause == `Exception && exception_first_inst_i == 1'b0) begin
            pc_o <= pc_i;
            waddr1_o <= waddr1_i;
            waddr2_o <= `NOPRegAddr;
            we1_o <= we1_i;
            we2_o <= `WriteDisable;
            wdata1_o <= wdata1_i;
            wdata2_o <= `ZeroWord;
            hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= `NOPRegAddr;
            cp0_wdata_o <= `ZeroWord;
        end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            pc_o <= `ZeroWord;
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= `NOPRegAddr;
            cp0_wdata_o <= `ZeroWord;
        end else if (stall[2] == `NoStop) begin
            pc_o <= pc_i;
            waddr1_o <= waddr1_i;
            waddr2_o <= waddr2_i;
            we1_o <= we1_i;
            we2_o <= we2_i;
            wdata1_o <= wdata1_i;
            wdata2_o <= wdata2_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;	
            LLbit_o <= LLbit_i;
            LLbit_we_o <= LLbit_we_i;
            cp0_wsel_o <= cp0_wsel_i;
            cp0_we_o <= cp0_we_i;
            cp0_waddr_o <= cp0_waddr_i;
            cp0_wdata_o <= cp0_wdata_i;		
        end
    end

endmodule