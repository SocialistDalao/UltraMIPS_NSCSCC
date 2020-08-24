//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/30 15:46:07
// Design Name: 
// Module Name: npc
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

`include "defines.v"
`include "defines_cache.v"

module npc(
    input rst,
    input[5:0] stall,
    input flush,
    input flush_cause,
    
    input singleissue_req_from_icache,
    
    input[`InstAddrBus] pc,
    input ce,
    input[`InstBus] inst1,
    input[`InstBus] inst2,
    
    input[`SIZE_OF_PTA] pta,
    input               branch_flag,
    input[`InstAddrBus] npc_actual,
    input[`InstAddrBus] ex_pc,
    input               ex_issue_mode,
    
    input[`InstAddrBus] epc,
    
    input first_inst_in_delayslot_i,
    
    output in_delayslot1_o,
    output in_delayslot2_o,
    
    output next_first_inst_in_delayslot_o,
        
    output reg[`InstAddrBus] npc,
    output branch_flag_o,
    output reg issue
    );
    
    reg delayslot;
    
    wire is_ssnop1, is_ssnop2;
    reg is_md1, is_md2, is_j1, is_j2;
    wire is_ls1, is_ls2;
    wire is_privileged1, is_privileged2;
    wire is_trap1, is_trap2;
    wire is_eret;
    wire single_issue;
    assign is_ssnop1 = (inst1 == `SSNOP);
    assign is_ssnop2 = (inst2 == `SSNOP);
    assign single_issue = is_ssnop1 | is_ssnop2 | is_md1 | is_md2 | is_j2 | is_ls1 | is_ls2 | is_trap1 | is_trap2 | is_eret | is_privileged1 | is_privileged2;
    assign in_delayslot1_o = first_inst_in_delayslot_i;
    assign in_delayslot2_o = is_j1 && issue == `DualIssue ? `InDelaySlot : `NotInDelaySlot;
    assign next_first_inst_in_delayslot_o = is_j1 && issue == `SingleIssue ? `InDelaySlot : `NotInDelaySlot;
    
    always @ (*) begin
        if (ce == `ChipDisable) npc = `Entry;
        else if (flush == `Flush && flush_cause == `Exception) npc = epc;
        else if (flush == `Flush && flush_cause == `FailedBranchPrediction)
            if (branch_flag == `Branch) npc = npc_actual;
            else if (ex_issue_mode == `SingleIssue) npc = ex_pc + 4'h4;
            else npc = ex_pc + 4'h8;
        else if (stall[0] == `Stop) npc = pc;
        else if (issue == `SingleIssue) npc = pc + 4'h4;
        else if (is_j1 && pta[`PTA_DIR] == `Branch) npc = pta[`PTA_PADDR];
        else npc = pc + 4'h8;
    end
    
    assign branch_flag_o = pta[`PTA_DIR];
    
    // 判断是否为乘除指令
    always @ (*) begin
        if (inst1[31:26] == `EXE_SPECIAL_INST && (inst1[5:0] == `EXE_MULT || inst1[5:0] == `EXE_MULTU || inst1[5:0] == `EXE_DIV || inst1[5:0] == `EXE_DIVU)) is_md1 = 1'b1;
        else if (inst1[31:26] == `EXE_SPECIAL2_INST && (inst1[5:0] == `EXE_MUL || inst1[5:0] == `EXE_MADD || inst1[5:0] == `EXE_MADDU || inst1[5:0] == `EXE_MSUB || inst1[5:0] == `EXE_MSUBU)) is_md1 = 1'b1;
        else is_md1 = 1'b0;
    end
    
    always @ (*) begin
        if (inst2[31:26] == `EXE_SPECIAL_INST && (inst2[5:0] == `EXE_MULT || inst2[5:0] == `EXE_MULTU || inst2[5:0] == `EXE_DIV || inst2[5:0] == `EXE_DIVU)) is_md2 = 1'b1;
        else if (inst2[31:26] == `EXE_SPECIAL2_INST && (inst2[5:0] == `EXE_MUL || inst2[5:0] == `EXE_MADD || inst2[5:0] == `EXE_MADDU || inst2[5:0] == `EXE_MSUB || inst2[5:0] == `EXE_MSUBU)) is_md2 = 1'b1;
        else is_md2 = 1'b0;
    end
    
    // 判断是否为跳转/分支指令
    always @ (*) begin
        if (inst1[31:26] == `EXE_SPECIAL_INST && (inst1[5:0] == `EXE_JR || inst1[5:0] == `EXE_JALR)) is_j1 = 1'b1;
        else if (inst1[31:26] == `EXE_REGIMM_INST && (inst1[20:16] == `EXE_BLTZ || inst1[20:16] == `EXE_BLTZAL || inst1[20:16] == `EXE_BGEZ || inst1[20:16] == `EXE_BGEZAL)) is_j1 = 1'b1;
        else if (inst1[31:26] == `EXE_J || inst1[31:26] == `EXE_JAL || inst1[31:26] == `EXE_BEQ || inst1[31:26] == `EXE_BGTZ || inst1[31:26] == `EXE_BLEZ || inst1[31:26] == `EXE_BNE) is_j1 = 1'b1;
        else is_j1 = 1'b0;
    end
    
    always @ (*) begin
        if (inst2[31:26] == `EXE_SPECIAL_INST && (inst2[5:0] == `EXE_JR || inst2[5:0] == `EXE_JALR)) is_j2 = 1'b1;
        else if (inst2[31:26] == `EXE_REGIMM_INST && (inst2[20:16] == `EXE_BLTZ || inst2[20:16] == `EXE_BLTZAL || inst2[20:16] == `EXE_BGEZ || inst2[20:16] == `EXE_BGEZAL)) is_j2 = 1'b1;
        else if (inst2[31:26] == `EXE_J || inst2[31:26] == `EXE_JAL || inst2[31:26] == `EXE_BEQ || inst2[31:26] == `EXE_BGTZ || inst2[31:26] == `EXE_BLEZ || inst2[31:26] == `EXE_BNE) is_j2 = 1'b1;
        else is_j2 = 1'b0;
    end
    
    // 判断是否为访存类指令
    assign is_ls1 = inst1[31:26] == `EXE_LB || inst1[31:26] == `EXE_LBU || inst1[31:26] == `EXE_LH || inst1[31:26] == `EXE_LHU ||
                    inst1[31:26] == `EXE_LW || inst1[31:26] == `EXE_SB || inst1[31:26] == `EXE_SH || inst1[31:26] == `EXE_SW ||
                    inst1[31:26] == `EXE_LWL || inst1[31:26] == `EXE_LWR || inst1[31:26] == `EXE_SWL || inst1[31:26] == `EXE_SWR ||
                    inst1[31:26] == `EXE_LL || inst1[31:26] == `EXE_SC;
    
    assign is_ls2 = inst2[31:26] == `EXE_LB || inst2[31:26] == `EXE_LBU || inst2[31:26] == `EXE_LH || inst2[31:26] == `EXE_LHU ||
                    inst2[31:26] == `EXE_LW || inst2[31:26] == `EXE_SB || inst2[31:26] == `EXE_SH || inst2[31:26] == `EXE_SW ||
                    inst2[31:26] == `EXE_LWL || inst2[31:26] == `EXE_LWR || inst2[31:26] == `EXE_SWL || inst2[31:26] == `EXE_SWR ||
                    inst2[31:26] == `EXE_LL || inst2[31:26] == `EXE_SC;
    
    assign is_trap1 = inst1[31:26] == `EXE_SPECIAL_INST &&
                      (inst1[5:0] == `EXE_TEQ || inst1[5:0] == `EXE_TGE || inst1[5:0] == `EXE_TGEU
                      || inst1[5:0] == `EXE_TLT || inst1[5:0] == `EXE_TLTU || inst1[5:0] == `EXE_TNE
                      || inst1[5:0] == `EXE_SYSCALL || inst1[5:0] == `EXE_BREAK);
    
    assign is_trap2 = inst2[31:26] == `EXE_SPECIAL_INST &&
                      (inst2[5:0] == `EXE_TEQ || inst2[5:0] == `EXE_TGE || inst2[5:0] == `EXE_TGEU
                      || inst2[5:0] == `EXE_TLT || inst2[5:0] == `EXE_TLTU || inst2[5:0] == `EXE_TNE
                      || inst2[5:0] == `EXE_SYSCALL || inst2[5:0] == `EXE_BREAK);
    
    assign is_eret = inst1 == `EXE_ERET || inst2 == `EXE_ERET;
    
    assign is_privileged1 = inst1[31:26] == `EXE_COP0 && (inst1[25:21] == 5'b00000 || inst1[25:21] == 5'b00100) && inst1[10:3] == 8'b00000000;
    assign is_privileged2 = inst2[31:26] == `EXE_COP0 && (inst2[25:21] == 5'b00000 || inst2[25:21] == 5'b00100) && inst2[10:3] == 8'b00000000;
    
    // 决定是否双发射
    always @ (*) begin
        if (rst == `RstEnable) issue = `DualIssue;
        if (single_issue || singleissue_req_from_icache == `Valid) issue = `SingleIssue;
        else issue = `DualIssue;
    end
    
endmodule
