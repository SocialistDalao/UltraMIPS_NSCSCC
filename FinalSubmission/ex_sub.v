`include "defines.v"

module ex_sub(
    input rst,
    
    // 输入
	input[`AluOpBus]         aluop_i,
	input[`AluSelBus]        alusel_i,
	input[`RegBus]           reg1_i,
	input[`RegBus]           reg2_i,
	input[`RegAddrBus]       waddr_i,
    input                    we_i,
    
    input[`RegBus]           hi_i,
    input[`RegBus]           lo_i,
    
    input                    mul_ready_i,
    input[`DoubleRegBus]     mul_i,
    input[`DoubleRegBus]     div_result_i,
    input                    div_ready_i,
    
    input[`RegBus]           imm_i,
    input[`InstAddrBus]      pc_i,
    input[`SIZE_OF_CORR_PACK]inst_bpu_corr_i,
    
    input                    LLbit_i,
    
    input[2:0]               cp0_sel_i,
    input[`RegAddrBus]       cp0_addr_i,
    input[`RegBus]           cp0_data_i,
    input[2:0]               mem_cp0_wsel_i,
    input                    mem_cp0_we_i,
    input[`RegAddrBus]       mem_cp0_waddr_i,
    input[`RegBus]           mem_cp0_wdata_i,
    input[2:0]               commit_cp0_wsel_i,
    input                    commit_cp0_we_i,
    input[`RegAddrBus]       commit_cp0_waddr_i,
    input[`RegBus]           commit_cp0_wdata_i,
    
    input                    mem_exception_flag_i,
    input[31:0]              exception_type_i,
	
    output reg[`RegAddrBus] waddr_o,
    output reg              we_o,
    output reg[`RegBus]     wdata_o,
    output reg[`RegBus]     hi_o,
    output reg[`RegBus]     lo_o,
    output reg              whilo_o,
    
    output reg              mul_req_o,
    output reg              mul_s_o,
    
    output reg[`RegBus]     div_opdata1_o,
    output reg[`RegBus]     div_opdata2_o,
    output reg              div_start_o,
    output reg              signed_div_o,
    
    output reg[`InstAddrBus]         npc_actual,
    output reg                       branch_flag_actual,
	output reg                       pred_flag,
	output reg[`SIZE_OF_BRANCH_INFO] branch_info,
	
	output[`RegBus]            mem_addr_o,
	
	output reg[`RegBus]              mem_raddr_o,
	output reg[`RegBus]              mem_waddr_o,
	output reg                       mem_we_o,
	output reg[3:0]                  mem_sel_o,
	output reg[`RegBus]              mem_data_o,
	output reg                       mem_re_o,
	
	output reg                       LLbit_o,
	output reg                       LLbit_we_o,
	
	output reg[`RegAddrBus]          cp0_raddr_o,
    output reg                       cp0_we_o,
	output reg[`RegAddrBus]          cp0_waddr_o,
	output reg[`RegBus]              cp0_wdata_o,
	
	output[31:0] exception_type_o,
    
    output stallreq
    
    );
    
    reg[`RegBus] logicres;
    reg[`RegBus] shiftres;
    reg[`RegBus] moveres;
    reg[`RegBus] arithmeticres;
    reg[`RegBus] jbres;
    reg[`InstAddrBus] jbaddr;
    reg[`RegBus] scres;
    wire[`DoubleRegBus] mulres;
    wire ov_sum; // 加法溢出
    wire sub; // 是否要执行减法
    wire[31:0] sum; // 加法器和输出
    wire[31:0] carry; // 加法器进位输出
    wire[`InstAddrBus] pc_4;
    wire[`InstAddrBus] pc_8;
    reg stallreq_for_mul;
    reg stallreq_for_div;
    reg stallreq_for_mfc0;
    reg trapassert;
    reg ovassert;
    reg adel_exception;
    reg ades_exception;
    reg mem_re;
    reg mem_we;
    
    assign stallreq = stallreq_for_mul | stallreq_for_div | stallreq_for_mfc0;
    assign exception_type_o = {exception_type_i[31:14], trapassert, ovassert, exception_type_i[11:6], ades_exception, adel_exception | exception_type_i[4], exception_type_i[3:0]};
    assign mem_addr_o = reg1_i + imm_i;
    
    always @ (*) mem_re_o = mem_re && ~|exception_type_o && mem_exception_flag_i == `ExceptionNotInduced;
    always @ (*) mem_we_o = mem_we && ~|exception_type_o && mem_exception_flag_i == `ExceptionNotInduced;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            logicres = `ZeroWord;
        end else begin
            case (aluop_i)
            `EXE_OR_OP: logicres = reg1_i | reg2_i;
            `EXE_AND_OP: logicres = reg1_i & reg2_i;
            `EXE_XOR_OP: logicres = reg1_i ^ reg2_i;
            `EXE_NOR_OP: logicres = ~(reg1_i | reg2_i);
            default: logicres = `ZeroWord;
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            shiftres = `ZeroWord;
        end else begin
            case (aluop_i)
            `EXE_SLL_OP: shiftres = reg2_i << reg1_i[4:0];
            `EXE_SRL_OP: shiftres = reg2_i >> reg1_i[4:0];
            `EXE_SRA_OP: shiftres = $signed(reg2_i) >>> reg1_i[4:0];
            default: shiftres = `ZeroWord;
            endcase
        end
    end
    
    assign sub = (aluop_i == `EXE_SUB_OP) | (aluop_i == `EXE_SUBU_OP) | (aluop_i == `EXE_SLT_OP) |
                 (aluop_i == `EXE_TGE_OP) | (aluop_i == `EXE_TGEI_OP) | (aluop_i == `EXE_TLT_OP) | (aluop_i == `EXE_TLTI_OP);
//    fa32 u_fa32(.a(reg1_i), .b(reg2_i), .cin(1'b0), .sub(sub), .s(sum), .cout(carry));
//    assign ov_sum = carry[31] ^ carry[30];
    
	wire [`RegBus] reg2_i_mux = sub? (~reg2_i)+1 : reg2_i;
	assign sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!sum[31]));  
    
    always @ (*) begin
        if (rst == `RstEnable) arithmeticres = `ZeroWord;
        else begin
            case (aluop_i)
            `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUB_OP, `EXE_SUBU_OP: arithmeticres = sum;
            `EXE_SLT_OP: begin
                if (reg1_i[31] & ~reg2_i[31]) arithmeticres = 1'b1;
                else if (~reg1_i[31] & reg2_i[31]) arithmeticres = 1'b0;
                else arithmeticres = sum[31];
            end
            `EXE_SLTU_OP: arithmeticres = reg1_i < reg2_i;
            /*
            `EXE_CLZ_OP: begin
                arithmeticres = reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
													 reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
													 reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 : 
													 reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
													 reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : 
													 reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 : 
													 reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
													 reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 : 
													 reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 : 
													 reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 : 
													 reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32 ;
			end
			`EXE_CLO_OP: begin
			     arithmeticres = ~reg1_i[31] ? 0 : ~reg1_i[30] ? 1 : ~reg1_i[29] ? 2 :
													~reg1_i[28] ? 3 : ~reg1_i[27] ? 4 : ~reg1_i[26] ? 5 :
													~reg1_i[25] ? 6 : ~reg1_i[24] ? 7 : ~reg1_i[23] ? 8 : 
													~reg1_i[22] ? 9 : ~reg1_i[21] ? 10 : ~reg1_i[20] ? 11 :
													~reg1_i[19] ? 12 : ~reg1_i[18] ? 13 : ~reg1_i[17] ? 14 : 
													~reg1_i[16] ? 15 : ~reg1_i[15] ? 16 : ~reg1_i[14] ? 17 : 
													~reg1_i[13] ? 18 : ~reg1_i[12] ? 19 : ~reg1_i[11] ? 20 :
													~reg1_i[10] ? 21 : ~reg1_i[9] ? 22 : ~reg1_i[8] ? 23 : 
													~reg1_i[7] ? 24 : ~reg1_i[6] ? 25 : ~reg1_i[5] ? 26 : 
													~reg1_i[4] ? 27 : ~reg1_i[3] ? 28 : ~reg1_i[2] ? 29 : 
													~reg1_i[1] ? 30 : ~reg1_i[0] ? 31 : 32 ;
			end
			*/
            default: arithmeticres = `ZeroWord;
            endcase
        end
    end
    
    // 判断是否发生自陷异常
    always @ (*) begin
        if (rst == `RstEnable) trapassert = `TrapNotAssert;
        else begin
            trapassert = `TrapNotAssert;
            case (aluop_i)
                `EXE_TEQ_OP, `EXE_TEQI_OP: trapassert = reg1_i == reg2_i ? `TrapAssert : `TrapNotAssert;
                `EXE_TGE_OP, `EXE_TGEI_OP: begin
                    if (~reg1_i[31] & reg2_i[31]) trapassert = `TrapAssert;
                    else if (reg1_i[31] & ~reg2_i[31]) trapassert = `TrapNotAssert;
                    else trapassert = ~sum[31] ? `TrapAssert : `TrapNotAssert;
                end
                `EXE_TGEU_OP, `EXE_TGEIU_OP: trapassert = reg1_i >= reg2_i ? `TrapAssert : `TrapNotAssert;
                `EXE_TLT_OP, `EXE_TLTI_OP: begin
                    if (~reg1_i[31] & reg2_i[31]) trapassert = `TrapNotAssert;
                    else if (reg1_i[31] & ~reg2_i[31]) trapassert = `TrapAssert;
                    else trapassert = sum[31] ? `TrapAssert : `TrapNotAssert;
                end
                `EXE_TLTU_OP, `EXE_TLTIU_OP: trapassert = reg1_i < reg2_i ? `TrapAssert : `TrapNotAssert;
                `EXE_TNE_OP, `EXE_TNEI_OP: trapassert = reg1_i != reg2_i ? `TrapAssert : `TrapNotAssert;
                default: ;
            endcase
        end
    end
    
    assign mulres = mul_i;
    
    always @ (*) begin
		if (rst == `RstEnable) begin
			stallreq_for_div = `NoStop;
	        div_opdata1_o = `ZeroWord;
			div_opdata2_o = `ZeroWord;
			div_start_o = `DivStop;
			signed_div_o = 1'b0;
		end else begin
			stallreq_for_div = `NoStop;
	        div_opdata1_o = `ZeroWord;
			div_opdata2_o = `ZeroWord;
			div_start_o = `DivStop;
			signed_div_o = 1'b0;	
			case (aluop_i) 
			`EXE_DIV_OP: begin
				if (div_ready_i == `DivResultNotReady) begin
	    			div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStart;
					signed_div_o = 1'b1;
					stallreq_for_div = `Stop;
				end else if(div_ready_i == `DivResultReady) begin
	    			div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStop;
					signed_div_o = 1'b1;
					stallreq_for_div = `NoStop;
				end else begin						
	    			div_opdata1_o = `ZeroWord;
					div_opdata2_o = `ZeroWord;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
					stallreq_for_div = `NoStop;
				end					
			end
			`EXE_DIVU_OP: begin
				if(div_ready_i == `DivResultNotReady) begin
	    			div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStart;
					signed_div_o = 1'b0;
					stallreq_for_div = `Stop;
				end else if (div_ready_i == `DivResultReady) begin
	    			div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
					stallreq_for_div = `NoStop;
				end else begin						
	    			div_opdata1_o = `ZeroWord;
					div_opdata2_o = `ZeroWord;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
					stallreq_for_div = `NoStop;
				end					
			end
			default: begin
			end
			endcase
		end
	end	
    
    always @ (*) begin
        stallreq_for_mfc0 = `NoStop;
        cp0_raddr_o = 5'b00000;
        if (rst == `RstEnable) moveres = `ZeroWord;
        else begin
            case (aluop_i)
            `EXE_MFHI_OP: moveres = hi_i;
            `EXE_MFLO_OP: moveres = lo_i;
            `EXE_MOVZ_OP: moveres = reg1_i;
            `EXE_MOVN_OP: moveres = reg1_i;
            `EXE_MFC0_OP: begin
                cp0_raddr_o = cp0_addr_i;
                moveres = cp0_data_i;
                if (mem_cp0_we_i == `WriteEnable && mem_cp0_waddr_i == cp0_addr_i && mem_cp0_wsel_i == cp0_sel_i) stallreq_for_mfc0 = `Stop;
                else if (commit_cp0_we_i == `WriteEnable && commit_cp0_waddr_i == cp0_addr_i && commit_cp0_wsel_i == cp0_sel_i) stallreq_for_mfc0 = `Stop;
            end
            default: moveres = `ZeroWord;
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            mul_req_o = 1'b0;
            mul_s_o = 1'b0;
            stallreq_for_mul = `NoStop;
        end else if (aluop_i == `EXE_MUL_OP || aluop_i == `EXE_MULT_OP) begin
            mul_req_o = 1'b1;
            mul_s_o = 1'b1;
            stallreq_for_mul = mul_ready_i ? `NoStop : `Stop;
        end else if (aluop_i == `EXE_MULTU_OP) begin
            mul_req_o = 1'b1;
            mul_s_o = 1'b0;
            stallreq_for_mul = mul_ready_i ? `NoStop : `Stop;
        end else begin
            mul_req_o = 1'b0;
            mul_s_o = 1'b0;
            stallreq_for_mul = `NoStop;
        end
    end
    
    assign pc_4 = pc_i + 4;
//    fa32 u_fa32_jb(.a(pc_i), .b(32'h8), .cin(1'b0), .sub(1'b0), .s(pc_8), .cout());
    assign pc_8 = pc_i + 8;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            npc_actual = `ZeroWord;
            branch_flag_actual = `NotBranch;
            pred_flag = `ValidPrediction;
            branch_info = {`ZeroWord,`NotBranch, `ZeroWord, 2'b00};
        end else begin
            case (aluop_i)
                `EXE_J_OP: begin
                    branch_flag_actual = `Branch;
                    npc_actual = {pc_4[31:28], imm_i[27:0]};
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_CAL};
                end
                `EXE_JAL_OP: begin
                    branch_flag_actual = `Branch;
                    npc_actual = {pc_4[31:28], imm_i[27:0]};
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_CAL};
                end
                `EXE_JR_OP: begin
                    branch_flag_actual = `Branch;
                    npc_actual = reg1_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_RET};
                end
                `EXE_JALR_OP: begin
                    branch_flag_actual = `Branch;
                    npc_actual = reg1_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_CAL};
                end
                `EXE_BEQ_OP: begin
                    branch_flag_actual = reg1_i == reg2_i ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BGTZ_OP: begin
                    branch_flag_actual = (reg1_i[31] == 1'b0) && (reg1_i != 32'b0) ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BLEZ_OP: begin
                    branch_flag_actual = (reg1_i[31] == 1'b1) || (reg1_i == 32'b0) ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BNE_OP: begin
                    branch_flag_actual = reg1_i != reg2_i ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BGEZ_OP: begin
                    branch_flag_actual = reg1_i[31] == 1'b0 ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BGEZAL_OP: begin
                    branch_flag_actual = reg1_i[31] == 1'b0 ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_CAL};
                end
                `EXE_BLTZ_OP: begin
                    branch_flag_actual = reg1_i[31] == 1'b1 ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_NUL};
                end
                `EXE_BLTZAL_OP: begin
                    branch_flag_actual = reg1_i[31] == 1'b1 ? `Branch : `NotBranch;
                    npc_actual = pc_4 + imm_i;
                    pred_flag = inst_bpu_corr_i[`CRR_PRED_DIR] == `Branch && branch_flag_actual == `Branch && inst_bpu_corr_i[`CRR_PRED_TAR] == npc_actual ||
                                inst_bpu_corr_i[`CRR_PRED_DIR] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InvalidPrediction;
                    branch_info = {pc_i,branch_flag_actual, npc_actual, `BTYPE_CAL};
                end
                default: begin
                    branch_flag_actual = `NotBranch;
                    npc_actual = `ZeroWord;
                    pred_flag = `ValidPrediction;
                    branch_info = {`ZeroWord,`NotBranch, `ZeroWord, 2'b00};
                end
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) jbres = `ZeroWord;
        else if (aluop_i == `EXE_JAL_OP || aluop_i == `EXE_JALR_OP || aluop_i == `EXE_BGEZAL_OP || aluop_i == `EXE_BLTZAL_OP) jbres = pc_8;
        else jbres = `ZeroWord;
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            mem_raddr_o = `ZeroWord;
            mem_waddr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_sel_o = 4'b0000;
            mem_data_o = `ZeroWord;
            mem_re = `ReadDisable;
            scres = `ZeroWord;
            LLbit_o = 1'b0;
            LLbit_we_o = `WriteDisable;
            adel_exception = 1'b0;
            ades_exception = 1'b0;
        end else begin
            mem_raddr_o = `ZeroWord;
            mem_waddr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_sel_o = 4'b0000;
            mem_data_o = `ZeroWord;
            mem_re = `ReadDisable;
            scres = `ZeroWord;
            LLbit_o = 1'b0;
            LLbit_we_o = `WriteDisable;
            adel_exception = 1'b0;
            ades_exception = 1'b0;
            case (aluop_i)
            `EXE_LB_OP: begin
                mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0001;
                    2'b01: mem_sel_o = 4'b0010;
                    2'b10: mem_sel_o = 4'b0100;
                    2'b11: mem_sel_o = 4'b1000;
                    default: ;
                endcase
            end
            `EXE_LBU_OP: begin
                mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0001;
                    2'b01: mem_sel_o = 4'b0010;
                    2'b10: mem_sel_o = 4'b0100;
                    2'b11: mem_sel_o = 4'b1000;
                    default: ;
                endcase
            end
            `EXE_LH_OP: begin
                mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0011;
                    2'b10: mem_sel_o = 4'b1100;
                    default: begin
                        mem_sel_o = 4'b0000;
                        adel_exception = 1'b1;
                    end
                endcase
            end
            `EXE_LHU_OP: begin
                mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0011;
                    2'b10: mem_sel_o = 4'b1100;
                    default: begin
                        mem_sel_o = 4'b0000;
                        adel_exception = 1'b1;
                    end
                endcase
            end
            `EXE_LW_OP: begin
                mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                mem_sel_o = 4'b1111;
                adel_exception = mem_addr_o[1:0] != 2'b00;
            end
            `EXE_LWL_OP: begin
				mem_raddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteDisable;
				mem_re = `ReadEnable;
                mem_sel_o = 4'b1111;
            end
            `EXE_LWR_OP: begin
				mem_raddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteDisable;
				mem_re = `ReadEnable;
                mem_sel_o = 4'b1111;
            end
            `EXE_SB_OP: begin
                mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0001;
                    2'b01: mem_sel_o = 4'b0010;
                    2'b10: mem_sel_o = 4'b0100;
                    2'b11: mem_sel_o = 4'b1000;
                    default: ;
                endcase
            end
            `EXE_SH_OP: begin
                mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = {reg2_i[15:0], reg2_i[15:0]};
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0011;
                    2'b10: mem_sel_o = 4'b1100;
                    default: begin
                        mem_sel_o = 4'b0000;
                        ades_exception = 1'b1;
                    end
                endcase
            end
            `EXE_SW_OP: begin
                mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = reg2_i[31:0];
                mem_sel_o = 4'b1111;
                ades_exception = mem_addr_o[1:0] != 2'b00;
            end
            `EXE_SWL_OP: begin
				mem_waddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteEnable;
				case (mem_addr_o[1:0])
                    2'b00: begin
                        mem_sel_o = 4'b0001;
                        mem_data_o = {24'b0, reg2_i[31:24]};
                    end
                    2'b01: begin
                        mem_sel_o = 4'b0011;
                        mem_data_o = {16'b0, reg2_i[31:16]};
                    end
                    2'b10: begin
                        mem_sel_o = 4'b0111;
                        mem_data_o = {8'b0, reg2_i[31:8]};
                    end
                    2'b11: begin
                        mem_sel_o = 4'b1111;
                        mem_data_o = reg2_i;
                    end
                    default: ;
                endcase				
            end
            `EXE_SWR_OP: begin
				mem_waddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteEnable;
				case (mem_addr_o[1:0])
                    2'b00: begin
                        mem_sel_o = 4'b1111;
                        mem_data_o = reg2_i;
                    end
                    2'b01: begin
                        mem_sel_o = 4'b1110;
                        mem_data_o = {reg2_i[23:0], 8'b0};
                    end
                    2'b10: begin
                        mem_sel_o = 4'b1100;
                        mem_data_o = {reg2_i[15:0], 16'b0};
                    end
                    2'b11: begin
                        mem_sel_o = 4'b1000;
                        mem_data_o = {reg2_i[7:0], 24'b0};
                    end
                    default: ;
                endcase				
            end
            `EXE_LL_OP: begin
                mem_waddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                LLbit_o = 1'b1;
                LLbit_we_o = `WriteEnable;
            end
            `EXE_SC_OP: begin
                if (LLbit_i == 1'b1) begin
                    mem_waddr_o = mem_addr_o;
                    mem_we = `WriteEnable;
                    scres = 32'b1;
                    mem_sel_o = 4'b1111;
                    mem_data_o = reg2_i;
                    LLbit_o = 1'b0;
                    LLbit_we_o = `WriteEnable;
                end else scres = 32'b0;
            end
            default: ;
            endcase
        end
    end
    
    always @ (*) begin
        waddr_o = waddr_i;
        we_o = we_i;
        ovassert = `OverflowNotAssert;
        case (alusel_i)
        `EXE_RES_LOGIC: wdata_o = logicres;
        `EXE_RES_SHIFT: wdata_o = shiftres;
        `EXE_RES_ARITHMETIC: begin
            wdata_o = arithmeticres;
            if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
                we_o = `WriteDisable;
                ovassert = `OverflowAssert; // 加减法溢出
            end else ovassert = `OverflowNotAssert;
        end
        `EXE_RES_MUL: wdata_o = mulres[31:0];
        `EXE_RES_MOVE: begin
            wdata_o = moveres;
            case (aluop_i)
            `EXE_MOVZ_OP: if (reg2_i != 0) we_o = `WriteDisable;
            `EXE_MOVN_OP: if (reg2_i == 0) we_o = `WriteDisable;
            default: ;
            endcase
        end
        `EXE_RES_JUMP_BRANCH: wdata_o = jbres;
        `EXE_RES_LOAD_STORE: wdata_o = scres;
        default: wdata_o = `ZeroWord;
        endcase
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
        end else if (aluop_i == `EXE_MTHI_OP) begin
            whilo_o = `WriteEnable;
            hi_o = reg1_i;
            lo_o = lo_i;
        end else if (aluop_i == `EXE_MTLO_OP) begin
            whilo_o = `WriteEnable;
            hi_o = hi_i;
            lo_o = reg1_i;
        end else if (aluop_i == `EXE_MULT_OP || aluop_i == `EXE_MULTU_OP) begin
            whilo_o = `WriteEnable;
            hi_o = mulres[63:32];
            lo_o = mulres[31:0];
        end else if (aluop_i == `EXE_DIV_OP || aluop_i == `EXE_DIVU_OP) begin
            whilo_o = `WriteEnable;
            hi_o = div_result_i[63:32];
            lo_o = div_result_i[31:0];
        end else begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            cp0_we_o = `WriteDisable;
            cp0_waddr_o = `NOPRegAddr;
            cp0_wdata_o = `ZeroWord;
        end else if (aluop_i == `EXE_MTC0_OP) begin
            cp0_we_o = `WriteEnable;
            cp0_waddr_o = cp0_addr_i;
            cp0_wdata_o = reg2_i;
        end else begin
            cp0_we_o = `WriteDisable;
            cp0_waddr_o = `NOPRegAddr;
            cp0_wdata_o = `ZeroWord;
        end
    end
    
endmodule
