`include "defines.v"

module pc_reg(

	input clk,
	input resetn,
    input[4:0] stall,
    input flush,
    input flush_cause,
    
    input               stallreq_from_icache,
    input               branch_flag,
    input[`InstAddrBus] npc_actual,
    input[`InstAddrBus] ex_pc,
    input[`InstAddrBus] npc_from_cache,
	input[`InstAddrBus] epc,
	input               ibuffer_full,
	
	 output reg[`InstAddrBus] pc,
	output reg rreq_to_icache
	
);
    
    reg[`InstAddrBus] npc;
    
    always @ (*) begin
        if (resetn == `RstEnable) npc = `Entry;
        else if (flush == `Flush && flush_cause == `Exception) npc = epc;
        else if (flush == `Flush && flush_cause == `FailedBranchPrediction && branch_flag == `Branch) npc = npc_actual;
        else if (flush == `Flush && flush_cause == `FailedBranchPrediction && branch_flag == `NotBranch) npc = ex_pc + 32'h8;
        else if (ibuffer_full) npc = pc;
        else npc = npc_from_cache;
    end
    
    always @ (*) begin
        if (resetn == `RstEnable || flush == `Flush || ibuffer_full) rreq_to_icache = `ReadDisable;
        else rreq_to_icache = `ReadEnable;
    end
    
    always @ (posedge clk) pc <= npc;
    
    
    //////////////////////////
    reg [31:0] branch_count;
    reg [31:0] hit_count;
    
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            branch_count <= 0;
            hit_count<= 0;
        end else begin
            if(branch_flag)begin
                branch_count <= branch_count + 1;
            end 
            if(branch_flag && !(branch_flag & flush & flush_cause))begin
                hit_count <= hit_count + 1;
            end
        end
    end
    /////////////////////////
    
endmodule