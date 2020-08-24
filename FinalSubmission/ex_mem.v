`include "defines.v"

module ex_mem(

	input clk,
	input rst,
	input flush,
	input flush_cause,
	input[3:0] stall,
	
	//来自执行阶段的信息
	input[`InstAddrBus]inst1_addr_i,
	input[`InstAddrBus]inst2_addr_i,
	
    input[`SIZE_OF_CORR_PACK] inst1_bpu_corr_i,
    input[`SIZE_OF_CORR_PACK] inst2_bpu_corr_i,
    
    input[`SIZE_OF_BRANCH_INFO] branch_info_i,
    
	input[`RegAddrBus] waddr1_i,
	input[`RegAddrBus] waddr2_i,
    input              we1_i,
    input              we2_i,
    input[`RegBus]     wdata1_i,
    input[`RegBus]     wdata2_i,
    input[`RegBus]     hi_i,
	input[`RegBus]     lo_i,
	input              whilo_i,
	input[`AluOpBus]   aluop1_i,
	input[`RegBus]     mem_addr_i,
	input[`RegBus]     reg2_i,
	input              LLbit_i,
	input              LLbit_we_i,
	input[2:0]         cp0_wsel_i,
	input              cp0_we_i,
	input[`RegAddrBus] cp0_waddr_i,
	input[`RegBus]     cp0_wdata_i,
	input              is_in_delayslot1_i,
	input              is_in_delayslot2_i,
	input[31:0]        exception_type1_i,
	input[31:0]        exception_type2_i,
	
	//送到访存阶段的信息
	output reg[`InstAddrBus]inst1_addr_o,
	output reg[`InstAddrBus]inst2_addr_o,
	
    output[`SIZE_OF_CORR_PACK] inst1_bpu_corr_o,
    output[`SIZE_OF_CORR_PACK] inst2_bpu_corr_o,
	
    output reg[`SIZE_OF_BRANCH_INFO] branch_info_o,
    
	output reg[`RegAddrBus] waddr1_o,
	output reg[`RegAddrBus] waddr2_o,
    output reg              we1_o,
    output reg              we2_o,
    output reg[`RegBus]     wdata1_o,
    output reg[`RegBus]     wdata2_o,
    output reg[`RegBus]     hi_o,
	output reg[`RegBus]     lo_o,
	output reg              whilo_o,
	output reg[`AluOpBus]   aluop1_o,
	output reg[`RegBus]     mem_addr_o,
	output reg[`RegBus]     reg2_o,
	output reg              LLbit_o,
	output reg              LLbit_we_o,
	output reg[2:0]         cp0_wsel_o,
	output reg              cp0_we_o,
	output reg[`RegAddrBus] cp0_waddr_o,
	output reg[`RegBus]     cp0_wdata_o,
	output reg              is_in_delayslot1_o,
	output reg              is_in_delayslot2_o,
	output reg[31:0]        exception_type1_o,
	output reg[31:0]        exception_type2_o
	
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            inst1_addr_o <= `ZeroWord;
            inst2_addr_o <= `ZeroWord;
            branch_info_o = {`ZeroWord,`NotBranch, `ZeroWord, `BTYPE_NUL};
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            aluop1_o <= `EXE_NOP_OP;
            mem_addr_o <= `ZeroWord;
            reg2_o <= `ZeroWord;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= 5'b00000;
            cp0_wdata_o <= `ZeroWord;
            is_in_delayslot1_o <= `NotInDelaySlot;
            is_in_delayslot2_o <= `NotInDelaySlot;
            exception_type1_o <= `ZeroWord;
            exception_type2_o <= `ZeroWord;
        end else if (flush == `Flush && flush_cause == `Exception) begin
            inst1_addr_o <= `ZeroWord;
            inst2_addr_o <= `ZeroWord;
            branch_info_o = {`ZeroWord,`NotBranch, `ZeroWord, `BTYPE_NUL};
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            aluop1_o <= `EXE_NOP_OP;
            mem_addr_o <= `ZeroWord;
            reg2_o <= `ZeroWord;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= 5'b00000;
            cp0_wdata_o <= `ZeroWord;
            is_in_delayslot1_o <= `NotInDelaySlot;
            is_in_delayslot2_o <= `NotInDelaySlot;
            exception_type1_o <= `ZeroWord;
            exception_type2_o <= `ZeroWord;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
            inst1_addr_o <= `ZeroWord;
            inst2_addr_o <= `ZeroWord;
            branch_info_o = {`ZeroWord,`NotBranch, `ZeroWord, `BTYPE_NUL};
            waddr1_o <= `NOPRegAddr;
            waddr2_o <= `NOPRegAddr;
            we1_o <= `WriteDisable;
            we2_o <= `WriteDisable;
            wdata1_o <= `ZeroWord;
            wdata2_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            aluop1_o <= `EXE_NOP_OP;
            mem_addr_o <= `ZeroWord;
            reg2_o <= `ZeroWord;
            LLbit_o <= 1'b0;
            LLbit_we_o <= `WriteDisable;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= 5'b00000;
            cp0_wdata_o <= `ZeroWord;
            is_in_delayslot1_o <= `NotInDelaySlot;
            is_in_delayslot2_o <= `NotInDelaySlot;
            exception_type1_o <= `ZeroWord;
            exception_type2_o <= `ZeroWord;
        end else if (stall[1] == `NoStop) begin
            inst1_addr_o <= inst1_addr_i;
            inst2_addr_o <= inst2_addr_i;
            branch_info_o = branch_info_i;
            waddr1_o <= waddr1_i;
            waddr2_o <= waddr2_i;
            we1_o <= we1_i;
            we2_o <= we2_i;
            wdata1_o <= wdata1_i;
            wdata2_o <= wdata2_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;
            aluop1_o <= aluop1_i;
            mem_addr_o <= mem_addr_i;
            reg2_o <= reg2_i;
            LLbit_o <= LLbit_i;
            LLbit_we_o <= LLbit_we_i;
            cp0_wsel_o <= 3'b000;
            cp0_we_o <= cp0_we_i;
            cp0_waddr_o <= cp0_waddr_i;
            cp0_wdata_o <= cp0_wdata_i;
            is_in_delayslot1_o <= is_in_delayslot1_i;
            is_in_delayslot2_o <= is_in_delayslot2_i;
            exception_type1_o <= exception_type1_i;
            exception_type2_o <= exception_type2_i;
        end
    end
    
    assign inst1_bpu_corr_o = inst1_bpu_corr_i;
    assign inst2_bpu_corr_o = inst2_bpu_corr_i;

endmodule