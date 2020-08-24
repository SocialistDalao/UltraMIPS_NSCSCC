`include "defines.v"

module mem(
	
    input rst,
	
	input[`RegBus] mem_data_i,
	
	//来自执行阶段的信息
    input[`InstAddrBus]    inst1_addr_i,
    input[`InstAddrBus]    inst2_addr_i,
	input[`RegAddrBus]     waddr1_i,
	input[`RegAddrBus]     waddr2_i,
	input                  we1_i,
	input                  we2_i,
	input[`RegBus]         wdata1_i,
	input[`RegBus]         wdata2_i,
	input[`RegBus]         hi_i,
	input[`RegBus]         lo_i,
	input                  whilo_i,
	input[`AluOpBus]       aluop1_i,
	input[`RegBus]         mem_addr_i,
	input[`RegBus]         reg2_i,
	input                  LLbit_i,
	input                  LLbit_we_i,
	input[2:0]             cp0_wsel_i,
	input                  cp0_we_i,
	input[`RegAddrBus]     cp0_waddr_i,
	input[`RegBus]         cp0_wdata_i,
	
	input                  is_in_delayslot1_i,
	input                  is_in_delayslot2_i,
	input[31:0]            exception_type1_i,
	input[31:0]            exception_type2_i,
	input[`RegBus]         cp0_status_i,
	input[`RegBus]         cp0_cause_i,
	input[`RegBus]         cp0_epc_i,
	input[`RegBus]         cp0_ebase_i,
	input[2:0]             commit_cp0_wsel_i,
	input                  commit_cp0_we_i,
	input[`RegAddrBus]     commit_cp0_waddr_i,
	input[`RegBus]         commit_cp0_wdata_i,
	
	//送到回写阶段的信息
    output[`InstAddrBus]   inst1_addr_o,
    output[`InstAddrBus]   inst2_addr_o,
    
	output reg[`RegAddrBus]    waddr1_o,
	output reg[`RegAddrBus]    waddr2_o,
	output reg                 we1_o,
	output reg                 we2_o,
	output reg[`RegBus]        wdata1_o,
	output reg[`RegBus]        wdata2_o,
	output reg[`RegBus]        hi_o,
	output reg[`RegBus]        lo_o,
	output reg                 whilo_o,
	output reg                 LLbit_o,
	output reg                 LLbit_we_o,
	output reg[2:0]            cp0_wsel_o,
	output reg                 cp0_we_o,
	output reg[`RegAddrBus]    cp0_waddr_o,
	output reg[`RegBus]        cp0_wdata_o,
	output reg[4:0]            exception_type_o,
	output reg                 exception_flag_o,
	output reg                 exception_first_inst_o, // 是否是第二条指令发生异常
	
	output[`RegBus]     mem_addr_o,
	output[`InstAddrBus]cp0_epc_o,
	output[`RegBus]     cp0_ebase_o,
	output              is_in_delayslot1_o,
	output              is_in_delayslot2_o
	

);
    
    reg[`RegBus] cp0_status;
    reg[`RegBus] cp0_cause;
    reg[`RegBus] cp0_epc;
    reg[`RegBus] cp0_ebase;
    reg[`RegBus] mem_we;
    reg[4:0] exception_type1;
    reg[4:0] exception_type2;
    reg exception_flag1;
    reg exception_flag2;
    
    assign mem_addr_o = mem_addr_i;
    
    always @ (*) begin
        if (rst == `RstEnable) cp0_status = `CP0_REG_STATUS_VAL;
		else if ((commit_cp0_wsel_i == 3'b000) && (commit_cp0_we_i == `WriteEnable) && (commit_cp0_waddr_i == `CP0_REG_STATUS)) cp0_status = {cp0_status_i[31:16], commit_cp0_wdata_i[15:8], cp0_status_i[7:2], cp0_status_i[1:0]};
		else cp0_status = cp0_status_i;
	end
	
	always @ (*) begin
		if (rst == `RstEnable) cp0_epc = `ZeroWord;
		else if ((commit_cp0_wsel_i == 3'b000) && (commit_cp0_we_i == `WriteEnable) && (commit_cp0_waddr_i == `CP0_REG_EPC)) cp0_epc = commit_cp0_wdata_i;
		else cp0_epc = cp0_epc_i;
	end
	
	always @ (*) begin
		if (rst == `RstEnable) cp0_ebase = `ZeroWord;
		else if ((commit_cp0_wsel_i == 3'b001) && (commit_cp0_we_i == `WriteEnable) && (commit_cp0_waddr_i == `CP0_REG_EBase)) cp0_ebase = commit_cp0_wdata_i;
		else cp0_ebase = cp0_ebase_i;
	end
	
    always @ (*) begin
        if (rst == `RstEnable) cp0_cause = `ZeroWord;
        else if ((commit_cp0_wsel_i == 3'b000) && (commit_cp0_we_i == `WriteEnable) && (commit_cp0_waddr_i == `CP0_REG_CAUSE)) cp0_cause = {cp0_cause_i[31:10], commit_cp0_wdata_i[9:8], cp0_cause_i[7:0]};
        else cp0_cause = cp0_cause_i;
    end
    
    assign cp0_epc_o = cp0_epc;
    assign cp0_ebase_o = cp0_ebase;
    assign is_in_delayslot1_o = is_in_delayslot1_i;
    assign is_in_delayslot2_o = is_in_delayslot2_i;
    assign inst1_addr_o = inst1_addr_i;
    assign inst2_addr_o = inst2_addr_i;
    
    always @ (*) begin
		if (rst == `RstEnable) begin
			exception_type1 = 5'b0;
			exception_flag1 = `ExceptionNotInduced;
		end else begin
			exception_type1 = 5'b0;
			exception_flag1 = `ExceptionNotInduced;
			if (inst1_addr_i != `ZeroWord) begin // 流水线当前没有清除或阻塞
				if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin 
				    exception_type1 = `EXCEPTION_INT;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[4] == 1'b1) begin 
				    exception_type1 = `EXCEPTION_ADEL;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[5] == 1'b1) begin
				    exception_type1 = `EXCEPTION_ADES;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[8] == 1'b1) begin 
				    exception_type1 = `EXCEPTION_SYS;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[9] == 1'b1) begin
				    exception_type1 = `EXCEPTION_BP;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[10] ==1'b1) begin
				    exception_type1 = `EXCEPTION_RI;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[12] == 1'b1) begin
				    exception_type1 = `EXCEPTION_OV;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[13] == 1'b1) begin
				    exception_type1 = `EXCEPTION_TR;
				    exception_flag1 = `ExceptionInduced;
				end else if (exception_type1_i[14] == 1'b1) begin
				    exception_type1 = `EXCEPTION_ERET;
				    exception_flag1 = `ExceptionInduced;
				end
			end
		end
	end
	
	always @ (*) begin
		if (rst == `RstEnable) begin
			exception_type2 = 5'b0;
			exception_flag2 = `ExceptionNotInduced;
		end else begin
			exception_type2 = 5'b0;
			exception_flag2 = `ExceptionNotInduced;
			if (inst2_addr_i != `ZeroWord) begin
				if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin 
				    exception_type2 = `EXCEPTION_INT;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[4] == 1'b1) begin 
				    exception_type2 = `EXCEPTION_ADEL;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[5] == 1'b1) begin
				    exception_type2 = `EXCEPTION_ADES;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[8] == 1'b1) begin 
				    exception_type2 = `EXCEPTION_SYS;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[9] == 1'b1) begin
				    exception_type2 = `EXCEPTION_BP;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[10] ==1'b1) begin
				    exception_type2 = `EXCEPTION_RI;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[12] == 1'b1) begin
				    exception_type2 = `EXCEPTION_OV;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[13] == 1'b1) begin
				    exception_type2 = `EXCEPTION_TR;
				    exception_flag2 = `ExceptionInduced;
				end else if (exception_type2_i[14] == 1'b1) begin
				    exception_type2 = `EXCEPTION_ERET;
				    exception_flag2 = `ExceptionInduced;
				end
			end
		end
	end
	
	always @ (*) begin
	    if (exception_flag1 == `ExceptionInduced) begin
	        exception_flag_o = `ExceptionInduced;
	        exception_type_o = exception_type1;
	        exception_first_inst_o = 1'b1;
	    end else if (exception_flag2 == `ExceptionInduced) begin
	        exception_flag_o = `ExceptionInduced;
	        exception_type_o = exception_type2;
	        exception_first_inst_o = 1'b0;
	    end else begin
	        exception_flag_o = `ExceptionNotInduced;
	        exception_type_o = 5'b0;
	        exception_first_inst_o = 1'b0;
	    end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            waddr1_o = `NOPRegAddr;
            waddr2_o = `NOPRegAddr;
            we1_o = `WriteDisable;
            we2_o = `WriteDisable;
            wdata1_o = `ZeroWord;
            wdata2_o = `ZeroWord;
            hi_o = `ZeroWord;
            lo_o = `ZeroWord;
            whilo_o = `WriteDisable;
            LLbit_o = 1'b0;
            LLbit_we_o = `WriteDisable;
            cp0_we_o = `WriteDisable;
            cp0_waddr_o = 5'b00000;
            cp0_wdata_o = `ZeroWord;
            cp0_wsel_o = 3'b000;
        end else begin
            waddr1_o = waddr1_i;
            waddr2_o = waddr2_i;
            we1_o = we1_i;
            we2_o = we2_i;
            wdata1_o = wdata1_i;
            wdata2_o = wdata2_i;
            hi_o = hi_i;
            lo_o = lo_i;
            whilo_o = whilo_i;
            LLbit_o = LLbit_i;
            LLbit_we_o = LLbit_we_i;
            cp0_we_o =cp0_we_i;
            cp0_waddr_o = cp0_waddr_i;
            cp0_wdata_o = cp0_wdata_i;
            cp0_wsel_o = cp0_wsel_i;
            case (aluop1_i)
            `EXE_LB_OP: begin
                case (mem_addr_i[1:0])
                    2'b00: wdata1_o = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                    2'b01: wdata1_o = {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                    2'b10: wdata1_o = {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                    2'b11: wdata1_o = {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                    default: ;
                endcase
            end
            `EXE_LBU_OP: begin
                case (mem_addr_i[1:0])
                    2'b00: wdata1_o = {24'b0, mem_data_i[7:0]};
                    2'b01: wdata1_o = {24'b0, mem_data_i[15:8]};
                    2'b10: wdata1_o = {24'b0, mem_data_i[23:16]};
                    2'b11: wdata1_o = {24'b0, mem_data_i[31:24]};
                    default: ;
                endcase
            end
            `EXE_LH_OP: begin
                case (mem_addr_i[1:0])
                    2'b00: wdata1_o = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                    2'b10: wdata1_o = {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                    default: ;
                endcase
            end
            `EXE_LHU_OP: begin
                case (mem_addr_i[1:0])
                    2'b00: wdata1_o = {16'b0, mem_data_i[15:0]};
                    2'b10: wdata1_o = {16'b0, mem_data_i[31:16]};
                    default: ;
                endcase
            end
            `EXE_LW_OP: wdata1_o = mem_data_i;
            `EXE_LWL_OP: begin
                case (mem_addr_i[1:0])
                    2'b00: wdata1_o = {mem_data_i[7:0], reg2_i[23:0]};
                    2'b01: wdata1_o = {mem_data_i[15:0],reg2_i[15:0]};
                    2'b10: wdata1_o = {mem_data_i[23:0],reg2_i[7:0]};
                    2'b11: wdata1_o = mem_data_i;
                    default: ;
                endcase
            end
            `EXE_LWR_OP: begin
				case (mem_addr_i[1:0])
                    2'b00: wdata1_o = mem_data_i;
                    2'b01: wdata1_o = {reg2_i[31:24], mem_data_i[31:8]};
                    2'b10: wdata1_o = {reg2_i[31:16], mem_data_i[31:16]};
                    2'b11: wdata1_o = {reg2_i[31:8], mem_data_i[31:24]};
                    default: ;
                endcase
            end
            `EXE_LL_OP: wdata1_o = mem_data_i;
            default: ;
            endcase
        end
    end

endmodule