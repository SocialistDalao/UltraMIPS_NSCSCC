//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/24 16:48:43
// Design Name: 
// Module Name: id
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

module id(

	input rst,
	input stallreq_from_ex,
	input stallreq_from_dcache,
	 input[`InstBus]     inst1_i,
	 input[`InstBus]     inst2_i,
	input[`InstAddrBus] inst1_addr_i,
	input[`InstAddrBus] inst2_addr_i,
	
    input[`SIZE_OF_CORR_PACK] inst1_bpu_corr_i,
    input[`SIZE_OF_CORR_PACK] inst2_bpu_corr_i,
    
	input               issue_en_i,
	input               is_in_delayslot_i,
	
	input[`RegBus]      reg1_data_i,
	input[`RegBus]      reg2_data_i,
	input[`RegBus]      reg3_data_i,
	input[`RegBus]      reg4_data_i,
	
    input[`RegAddrBus]  ex_waddr1_i,
	input[`RegAddrBus]  ex_waddr2_i,
	input               ex_we1_i,
	input               ex_we2_i,
	input[`RegBus]      ex_wdata1_i,
	input[`RegBus]      ex_wdata2_i,
	input[`RegAddrBus]  mem_waddr1_i,
	input[`RegAddrBus]  mem_waddr2_i,
	input               mem_we1_i,
	input               mem_we2_i,
	input[`RegBus]      mem_wdata1_i,
	input[`RegBus]      mem_wdata2_i,
	
    input[`AluOpBus]    ex_aluop1_i,
    
	input[`RegBus]           hi_i,
	input[`RegBus]           lo_i,
	
	input[`RegBus]           ex_hi_i,
	input[`RegBus]           ex_lo_i,
	input                    ex_whilo_i,

	input[`RegBus]           mem_hi_i,
	input[`RegBus]           mem_lo_i,
	input                    mem_whilo_i,
	
	input[`RegBus]           commit_hi_i,
	input[`RegBus]           commit_lo_i,
	input                    commit_whilo_i,
    
	output[`InstAddrBus]      inst1_addr_o,
	output[`InstAddrBus]      inst2_addr_o,
	
	
    output[`SIZE_OF_CORR_PACK] inst1_bpu_corr_o,
    output[`SIZE_OF_CORR_PACK] inst2_bpu_corr_o,
	
	output[`RegAddrBus]       reg1_raddr_o,
	output[`RegAddrBus]       reg2_raddr_o,
	output[`RegAddrBus]       reg3_raddr_o,
	output[`RegAddrBus]       reg4_raddr_o,
	
	output[`AluOpBus]         aluop1_o,
	output[`AluSelBus]        alusel1_o,
	output[`AluOpBus]         aluop2_o,
	output[`AluSelBus]        alusel2_o,
	output[`RegBus]           reg1_o,
	output[`RegBus]           reg2_o,
	output[`RegBus]           reg3_o,
	output[`RegBus]           reg4_o,
	output[`RegAddrBus]       waddr1_o,
	output[`RegAddrBus]       waddr2_o,
	output                    we1_o,
	output                    we2_o,
	
	output                     is_in_delayslot1_o,
	output                     is_in_delayslot2_o,
	
	output[`RegBus]            imm_fnl1_o,
	
	output reg[`RegBus]            hi_o,
	output reg[`RegBus]            lo_o,
	
	output                     ninst_in_delayslot,
	
	output[`RegAddrBus]        cp0_addr_o,
	output[2:0]                cp0_sel_o,
	output[31:0]               exception_type1,
	output[31:0]               exception_type2,
	
	output reg                     issue_o,
	output reg                     issued_o,
	output reg                     stallreq_from_id
	
);
    wire[`AluOpBus] id_sub_2_aluop_o;
    wire[`AluSelBus] id_sub_2_alusel_o;
    wire[`RegAddrBus] id_sub_2_waddr_o;
    wire id_sub_2_we_o;
    wire[31:0] id_sub_2_exception_type;
    wire[`RegBus] id_sub_2_reg1_o;
    wire[`RegBus] id_sub_2_reg2_o;
    reg[`AluOpBus] id_aluop2_o;
    reg[`AluSelBus] id_alusel2_o;
    reg[`RegAddrBus] id_waddr2_o;
    reg id_we2_o;
    reg[31:0] id_exception_type2_o;
    reg[`RegBus] id_reg3_o;
    reg[`RegBus] id_reg4_o;
    wire next_inst_in_delayslot;
    wire id2_inst_in_delayslot;
    reg reg3_raw_dependency;
    reg reg4_raw_dependency;
    reg hilo_raw_dependency;
    wire reg12_load_dependency;
    wire reg34_load_dependency;
    wire load_dependency;
    wire is_md1, is_md2, is_jb1, is_jb2, is_ls1, is_ls2, is_cp01, is_cp02;
    wire hilo_re1, hilo_re2, hilo_we1, hilo_we2;
    wire reg3_read_o;
    wire reg4_read_o;
    
    assign id2_inst_in_delayslot = issue_o == `DualIssue ? next_inst_in_delayslot : `NotInDelaySlot;
    assign ninst_in_delayslot = issue_o ==  `SingleIssue ? next_inst_in_delayslot : `NotInDelaySlot;
    assign is_in_delayslot1_o = is_in_delayslot_i;
    assign is_in_delayslot2_o = issue_o == `DualIssue ? id2_inst_in_delayslot : `NotInDelaySlot;
    assign load_dependency = reg12_load_dependency == `LoadDependent || reg34_load_dependency == `LoadDependent ? `LoadDependent : `LoadIndependent;
    
    assign is_load = ex_aluop1_i == `EXE_LB_OP || ex_aluop1_i == `EXE_LBU_OP || ex_aluop1_i == `EXE_LH_OP || ex_aluop1_i == `EXE_LHU_OP ||
                     ex_aluop1_i == `EXE_LW_OP || ex_aluop1_i == `EXE_LWR_OP || ex_aluop1_i == `EXE_LWL_OP || ex_aluop1_i == `EXE_LL_OP ||
                     ex_aluop1_i == `EXE_SC_OP;
                     
    assign reg1_raddr_o = rst == `RstEnable ? `NOPRegAddr : inst1_i[25:21];
    assign reg2_raddr_o = rst == `RstEnable ? `NOPRegAddr : inst1_i[20:16];
    assign reg3_raddr_o = rst == `RstEnable ? `NOPRegAddr : inst2_i[25:21];
    assign reg4_raddr_o = rst == `RstEnable ? `NOPRegAddr : inst2_i[20:16];
                     
    id_sub u_id_sub_1(
    
        .rst(rst),
        .pc_i(inst1_addr_i),
        .inst_i(inst1_i),
        
        .reg1_data_i(reg1_data_i),
        .reg2_data_i(reg2_data_i),
        
        .ex_waddr1_i(ex_waddr1_i),
	    .ex_waddr2_i(ex_waddr2_i),
	    .ex_we1_i(ex_we1_i),
        .ex_we2_i(ex_we2_i),
        .ex_wdata1_i(ex_wdata1_i),
        .ex_wdata2_i(ex_wdata2_i),
        .mem_waddr1_i(mem_waddr1_i),
        .mem_waddr2_i(mem_waddr2_i),
        .mem_we1_i(mem_we1_i),
        .mem_we2_i(mem_we2_i),
        .mem_wdata1_i(mem_wdata1_i),
        .mem_wdata2_i(mem_wdata2_i),
        
        .is_load(is_load),
        
        .is_md(is_md1),
        .is_jb(is_jb1),
        .is_ls(is_ls1),
        .is_cp0(is_cp01),
        
        .aluop_o(aluop1_o),
        .alusel_o(alusel1_o),
        .reg1_o(reg1_o),
        .reg2_o(reg2_o),
        .reg1_read_o(),
        .reg2_read_o(),
        .waddr_o(waddr1_o),
        .we_o(we1_o),
        .cp0_addr_o(cp0_addr_o),
        .cp0_sel_o(cp0_sel_o),
        .next_inst_in_delayslot(next_inst_in_delayslot),
        
        .hilo_re(hilo_re1),
        .hilo_we(hilo_we1),
        
        .exception_type(exception_type1),
        
        .imm_fnl_o(imm_fnl1_o),
        
        .load_dependency(reg12_load_dependency)
        
        );
    
    id_sub u_id_sub_2(
    
        .rst(rst),
        .pc_i(inst2_addr_i),
        .inst_i(inst2_i),
        
        .reg1_data_i(reg3_data_i),
        .reg2_data_i(reg4_data_i),
        
        .ex_waddr1_i(ex_waddr1_i),
	    .ex_waddr2_i(ex_waddr2_i),
	    .ex_we1_i(ex_we1_i),
        .ex_we2_i(ex_we2_i),
        .ex_wdata1_i(ex_wdata1_i),
        .ex_wdata2_i(ex_wdata2_i),
        .mem_waddr1_i(mem_waddr1_i),
        .mem_waddr2_i(mem_waddr2_i),
        .mem_we1_i(mem_we1_i),
        .mem_we2_i(mem_we2_i),
        .mem_wdata1_i(mem_wdata1_i),
        .mem_wdata2_i(mem_wdata2_i),
        
        .is_load(is_load),
        
        .is_md(is_md2),
        .is_jb(is_jb2),
        .is_ls(is_ls2),
        .is_cp0(is_cp02),
        
        .aluop_o(id_sub_2_aluop_o),
        .alusel_o(id_sub_2_alusel_o),
        .reg1_o(id_sub_2_reg1_o),
        .reg2_o(id_sub_2_reg2_o),
        .reg1_read_o(reg3_read_o),
        .reg2_read_o(reg4_read_o),
        .waddr_o(id_sub_2_waddr_o),
        .we_o(id_sub_2_we_o),
        .cp0_addr_o(),
        .cp0_sel_o(),
        .next_inst_in_delayslot(),
        
        .hilo_re(hilo_re2),
        .hilo_we(hilo_we2),
        
        .exception_type(id_sub_2_exception_type),
        
        .imm_fnl_o(),
        
        .load_dependency(reg34_load_dependency)
        
        );
    
    always @ (*) begin
        if (issue_o == `SingleIssue) begin
            id_aluop2_o = `EXE_NOP_OP;
            id_alusel2_o = `EXE_RES_NOP;
            id_reg3_o = `ZeroWord;
            id_reg4_o = `ZeroWord;
            id_waddr2_o = `NOPRegAddr;
            id_we2_o = `WriteDisable;
            id_exception_type2_o = `ZeroWord;
        end else begin
            id_aluop2_o = id_sub_2_aluop_o;
            id_alusel2_o = id_sub_2_alusel_o;
            id_reg3_o = id_sub_2_reg1_o;
            id_reg4_o = id_sub_2_reg2_o;
            id_waddr2_o = id_sub_2_waddr_o;
            id_we2_o = id_sub_2_we_o;
            id_exception_type2_o = id_sub_2_exception_type;
        end
    end
    
    assign aluop2_o = id_aluop2_o;
    assign alusel2_o = id_alusel2_o;
    assign reg3_o = id_reg3_o;
    assign reg4_o = id_reg4_o;
    assign waddr2_o = id_waddr2_o;
    assign we2_o = id_we2_o;
    assign exception_type2 = id_exception_type2_o;
    assign inst1_addr_o = inst1_addr_i;
    assign inst2_addr_o = issue_o == `SingleIssue ? `ZeroWord : inst2_addr_i;
    assign inst1_bpu_corr_o = inst1_bpu_corr_i;
    assign inst2_bpu_corr_o = issue_o == `SingleIssue ? {1'b0, inst2_bpu_corr_i[86:0]} : inst2_bpu_corr_i; // To be discussed
    
    always @ (*) begin
		if (rst == `RstEnable) {hi_o, lo_o} = {`ZeroWord, `ZeroWord};
		else if (ex_whilo_i == `WriteEnable) {hi_o, lo_o} = {ex_hi_i, ex_lo_i};
		else if (mem_whilo_i == `WriteEnable) {hi_o, lo_o} = {mem_hi_i, mem_lo_i};
		else if (commit_whilo_i == `WriteEnable) {hi_o, lo_o} = {commit_hi_i, commit_lo_i};
		else {hi_o, lo_o} = {hi_i, lo_i};
	end
	
    always @ (*) begin
        if (rst == `RstEnable) reg3_raw_dependency = `RAWIndependent;
        else if (reg3_read_o == `ReadEnable && we1_o == `WriteEnable && waddr1_o == inst2_i[25:21]) reg3_raw_dependency = `RAWDependent;
        else reg3_raw_dependency = `RAWIndependent;
    end
    
    always @ (*) begin
        if (rst == `RstEnable) reg4_raw_dependency = `RAWIndependent;
        else if (reg4_read_o == `ReadEnable && we1_o == `WriteEnable && waddr1_o == inst2_i[20:16]) reg4_raw_dependency = `RAWDependent;
        else reg4_raw_dependency = `RAWIndependent;
    end
    
    always @ (*) begin
        if (rst == `RstEnable) hilo_raw_dependency = `RAWIndependent;
        else if (hilo_we1 == `WriteEnable && hilo_re2 == `ReadEnable) hilo_raw_dependency = `RAWDependent;
        else hilo_raw_dependency = `RAWIndependent;
    end
    
    always @ (*) begin
        if (rst == `RstEnable) issue_o = `DualIssue;
        else if (is_md1 | is_md2 | is_in_delayslot_i | is_jb2 | is_ls1 | is_ls2 | is_cp01 | is_cp02) issue_o = `SingleIssue;
        else if (reg3_raw_dependency == `RAWDependent || reg4_raw_dependency == `RAWDependent || hilo_raw_dependency == `RAWDependent) issue_o = `SingleIssue;
        else issue_o = `DualIssue;
    end
    
    always @ (*) begin
        if (rst == `RstEnable || stallreq_from_ex == `Stop || stallreq_from_dcache == `Stop) begin
            issued_o = 1'b0;
            stallreq_from_id = `NoStop;
        end else if (is_in_delayslot_i) begin
            issued_o = 1'b1;
            stallreq_from_id = `NoStop;
        end else if (issue_en_i == 1'b1 && load_dependency == `LoadIndependent) begin
            issued_o = 1'b1;
            stallreq_from_id = `NoStop;
        end else begin
            issued_o = 1'b0;
            stallreq_from_id = `Stop;
        end
    end

endmodule