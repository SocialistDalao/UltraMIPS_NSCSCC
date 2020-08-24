module ex_sub_2(
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
    
    input[31:0]              exception_type_i,
	
    output reg[`RegAddrBus] waddr_o,
    output reg              we_o,
    output reg[`RegBus]     wdata_o,
    output reg[`RegBus]     hi_o,
    output reg[`RegBus]     lo_o,
    output reg              whilo_o,
	
	output[31:0] exception_type_o
    
    );
    
    reg[`RegBus] logicres;
    reg[`RegBus] shiftres;
    reg[`RegBus] moveres;
    reg[`RegBus] arithmeticres;
    wire ov_sum; // 加法溢出
    wire sub; // 是否要执行减法
    wire[31:0] sum; // 加法器和输出
    wire[31:0] carry; // 加法器进位输出
    reg ovassert;
    
    assign exception_type_o = {exception_type_i[31:13], ovassert, exception_type_i[11:0]};
    
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
    
    assign sub = (aluop_i == `EXE_SUB_OP) | (aluop_i == `EXE_SUBU_OP) | (aluop_i == `EXE_SLT_OP);
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
    
    always @ (*) begin
        if (rst == `RstEnable) moveres = `ZeroWord;
        else begin
            case (aluop_i)
            `EXE_MFHI_OP: moveres = hi_i;
            `EXE_MFLO_OP: moveres = lo_i;
            `EXE_MOVZ_OP: moveres = reg1_i;
            `EXE_MOVN_OP: moveres = reg1_i;
            default: moveres = `ZeroWord;
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
        `EXE_RES_MOVE: begin
            wdata_o = moveres;
            case (aluop_i)
            `EXE_MOVZ_OP: if (reg2_i != 0) we_o = `WriteDisable;
            `EXE_MOVN_OP: if (reg2_i == 0) we_o = `WriteDisable;
            default: ;
            endcase
        end
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
        end else begin
            whilo_o = `WriteDisable;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
        end
    end
    
endmodule
