//全局
`define RstEnable 1'b0
`define RstDisable 1'b1
`define ZeroWord 32'h00000000
`define Entry 32'hbfc00000 // 系统入口地址
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define AluOpBus 7:0
`define AluSelBus 2:0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define OverflowAssert 1'b1
`define OverflowNotAssert 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define True_v 1'b1
`define False_v 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define RAWDependent 1'b1
`define RAWIndependent 1'b0
`define DualIssue 1'b1
`define SingleIssue 1'b0
`define ValidPrediction 1'b1
`define InvalidPrediction 1'b0
`define Flush 1'b1
`define NoFlush 1'b0
`define FailedBranchPrediction 1'b1
`define Exception 1'b0
`define LoadDependent 1'b1
`define LoadIndependent 1'b0
`define ExceptionInduced 1'b1
`define ExceptionNotInduced 1'b0

//指令
`define EXE_AND  6'b100100
`define EXE_OR   6'b100101
`define EXE_XOR 6'b100110
`define EXE_NOR 6'b100111
`define EXE_ANDI 6'b001100
`define EXE_ORI  6'b001101
`define EXE_XORI 6'b001110
`define EXE_LUI 6'b001111

`define EXE_SLL  6'b000000
`define EXE_SLLV  6'b000100
`define EXE_SRL  6'b000010
`define EXE_SRLV  6'b000110
`define EXE_SRA  6'b000011
`define EXE_SRAV  6'b000111
`define EXE_SYNC  6'b001111
`define EXE_PREF  6'b110011

`define EXE_MOVZ  6'b001010
`define EXE_MOVN  6'b001011
`define EXE_MFHI  6'b010000
`define EXE_MTHI  6'b010001
`define EXE_MFLO  6'b010010
`define EXE_MTLO  6'b010011

`define EXE_SLT  6'b101010
`define EXE_SLTU  6'b101011
`define EXE_SLTI  6'b001010
`define EXE_SLTIU  6'b001011   
`define EXE_ADD  6'b100000
`define EXE_ADDU  6'b100001
`define EXE_SUB  6'b100010
`define EXE_SUBU  6'b100011
`define EXE_ADDI  6'b001000
`define EXE_ADDIU  6'b001001
`define EXE_CLZ  6'b100000
`define EXE_CLO  6'b100001

`define EXE_MULT  6'b011000
`define EXE_MULTU  6'b011001
`define EXE_MUL  6'b000010
`define EXE_MADD  6'b000000
`define EXE_MADDU  6'b000001
`define EXE_MSUB  6'b000100
`define EXE_MSUBU  6'b000101

`define EXE_DIV  6'b011010
`define EXE_DIVU  6'b011011

`define EXE_J  6'b000010
`define EXE_JAL  6'b000011
`define EXE_JALR  6'b001001
`define EXE_JR  6'b001000
`define EXE_BEQ  6'b000100
`define EXE_BGEZ  5'b00001
`define EXE_BGEZAL  5'b10001
`define EXE_BGTZ  6'b000111
`define EXE_BLEZ  6'b000110
`define EXE_BLTZ  5'b00000
`define EXE_BLTZAL  5'b10000
`define EXE_BNE  6'b000101

`define EXE_LB  6'b100000
`define EXE_LBU  6'b100100
`define EXE_LH  6'b100001
`define EXE_LHU  6'b100101
`define EXE_LL  6'b110000
`define EXE_LW  6'b100011
`define EXE_LWL  6'b100010
`define EXE_LWR  6'b100110
`define EXE_SB  6'b101000
`define EXE_SC  6'b111000
`define EXE_SH  6'b101001
`define EXE_SW  6'b101011
`define EXE_SWL  6'b101010
`define EXE_SWR  6'b101110

`define EXE_COP0 6'b010000

`define EXE_SYSCALL 6'b001100
`define EXE_BREAK 6'b001101
   
`define EXE_TEQ 6'b110100
`define EXE_TEQI 5'b01100
`define EXE_TGE 6'b110000
`define EXE_TGEI 5'b01000
`define EXE_TGEIU 5'b01001
`define EXE_TGEU 6'b110001
`define EXE_TLT 6'b110010
`define EXE_TLTI 5'b01010
`define EXE_TLTIU 5'b01011
`define EXE_TLTU 6'b110011
`define EXE_TNE 6'b110110
`define EXE_TNEI 5'b01110
   
`define EXE_ERET 32'b01000010000000000000000000011000

`define EXE_NOP 6'b000000
`define SSNOP 32'b00000000000000000000000001000000

`define EXE_SPECIAL_INST 6'b000000
`define EXE_REGIMM_INST 6'b000001
`define EXE_SPECIAL2_INST 6'b011100

//AluOp
`define EXE_AND_OP   8'b00100100
`define EXE_OR_OP    8'b00100101
`define EXE_XOR_OP  8'b00100110
`define EXE_NOR_OP  8'b00100111
`define EXE_ANDI_OP  8'b01011001
`define EXE_ORI_OP  8'b01011010
`define EXE_XORI_OP  8'b01011011
`define EXE_LUI_OP  8'b01011100   

`define EXE_SLL_OP  8'b01111100
`define EXE_SLLV_OP  8'b00000100
`define EXE_SRL_OP  8'b00000010
`define EXE_SRLV_OP  8'b00000110
`define EXE_SRA_OP  8'b00000011
`define EXE_SRAV_OP  8'b00000111

`define EXE_MOVZ_OP  8'b00001010
`define EXE_MOVN_OP  8'b00001011
`define EXE_MFHI_OP  8'b00010000
`define EXE_MTHI_OP  8'b00010001
`define EXE_MFLO_OP  8'b00010010
`define EXE_MTLO_OP  8'b00010011

`define EXE_SLT_OP  8'b00101010
`define EXE_SLTU_OP  8'b00101011
`define EXE_SLTI_OP  8'b01010111
`define EXE_SLTIU_OP  8'b01011000   
`define EXE_ADD_OP  8'b00100000
`define EXE_ADDU_OP  8'b00100001
`define EXE_SUB_OP  8'b00100010
`define EXE_SUBU_OP  8'b00100011
`define EXE_ADDI_OP  8'b01010101
`define EXE_ADDIU_OP  8'b01010110
`define EXE_CLZ_OP  8'b10110000
`define EXE_CLO_OP  8'b10110001

`define EXE_MULT_OP  8'b00011000
`define EXE_MULTU_OP  8'b00011001
`define EXE_MUL_OP  8'b10101001
`define EXE_MADD_OP  8'b10100110
`define EXE_MADDU_OP  8'b10101000
`define EXE_MSUB_OP  8'b10101010
`define EXE_MSUBU_OP  8'b10101011

`define EXE_DIV_OP  8'b00011010
`define EXE_DIVU_OP  8'b00011011

`define EXE_J_OP  8'b01001111
`define EXE_JAL_OP  8'b01010000
`define EXE_JALR_OP  8'b00001001
`define EXE_JR_OP  8'b00001000
`define EXE_BEQ_OP  8'b01010001
`define EXE_BGEZ_OP  8'b01000001
`define EXE_BGEZAL_OP  8'b01001011
`define EXE_BGTZ_OP  8'b01010100
`define EXE_BLEZ_OP  8'b01010011
`define EXE_BLTZ_OP  8'b01000000
`define EXE_BLTZAL_OP  8'b01001010
`define EXE_BNE_OP  8'b01010010

`define EXE_LB_OP  8'b11100000
`define EXE_LBU_OP  8'b11100100
`define EXE_LH_OP  8'b11100001
`define EXE_LHU_OP  8'b11100101
`define EXE_LL_OP  8'b11110000
`define EXE_LW_OP  8'b11100011
`define EXE_LWL_OP  8'b11100010
`define EXE_LWR_OP  8'b11100110
`define EXE_PREF_OP  8'b11110011
`define EXE_SB_OP  8'b11101000
`define EXE_SC_OP  8'b11111000
`define EXE_SH_OP  8'b11101001
`define EXE_SW_OP  8'b11101011
`define EXE_SWL_OP  8'b11101010
`define EXE_SWR_OP  8'b11101110
`define EXE_SYNC_OP  8'b00001111

`define EXE_MFC0_OP 8'b01011101
`define EXE_MTC0_OP 8'b01100000

`define EXE_BREAK_OP 8'b00001101
`define EXE_SYSCALL_OP 8'b00001100

`define EXE_TEQ_OP 8'b00110100
`define EXE_TEQI_OP 8'b01001000
`define EXE_TGE_OP 8'b00110000
`define EXE_TGEI_OP 8'b01000100
`define EXE_TGEIU_OP 8'b01000101
`define EXE_TGEU_OP 8'b00110001
`define EXE_TLT_OP 8'b00110010
`define EXE_TLTI_OP 8'b01000110
`define EXE_TLTIU_OP 8'b01000111
`define EXE_TLTU_OP 8'b00110011
`define EXE_TNE_OP 8'b00110110
`define EXE_TNEI_OP 8'b01001001
   
`define EXE_ERET_OP 8'b01101011

`define EXE_NOP_OP    8'b00000000

//AluSel
`define EXE_RES_LOGIC 3'b001
`define EXE_RES_SHIFT 3'b010
`define EXE_RES_MOVE 3'b011	
`define EXE_RES_ARITHMETIC 3'b100	
`define EXE_RES_MUL 3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE 3'b111	

`define EXE_RES_NOP 3'b000

`define InstAddrBus 31:0
`define InstBus 31:0
`define DataAddrBus 31:0
`define DataBus 31:0

//通用寄存器regfile
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000

//乘法mul
`define MUL_IDLE 1'b0
`define MUL_ON 1'b1

//除法div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

//CP0寄存器地址
`define CP0_REG_BADVADDR 5'b01000        //只读
`define CP0_REG_COUNT    5'b01001        //可读写
`define CP0_REG_COMPARE  5'b01011        //可读写
`define CP0_REG_STATUS   5'b01100        //可读写
`define CP0_REG_CAUSE    5'b01101        //只读
`define CP0_REG_EPC      5'b01110        //可读写
`define CP0_REG_PrId     5'b01111        //只读
`define CP0_REG_CONFIG   5'b10000        //只读
`define CP0_REG_EBase     5'b01111        //可读写

///////////////////branch prediction//////////////////

`define SIZE_OF_GHR 7:0
`define SIZE_OF_BHT 255:0
`define SIZE_OF_BHR 7:0
`define SIZE_OF_BHT_ADDR 7:0
`define SIZE_OF_PHT 255:0
`define SIZE_OF_PHT_ADDR 7:0
`define SIZE_OF_BP_FSM 1:0
`define SIZE_OF_CPHT 255:0
//`define SIZE_OF_CPHR 1:0
`define SIZE_OF_RAS 255:0
`define SIZE_OF_RASR 32:0
`define SIZE_OF_BTB 511:0//255:0//63:0
`define SIZE_OF_BTBR 46:0
`define SIZE_OF_BTBTAG 11:0
`define SIZE_OF_BTBINDEX 8:0
`define SIZE_OF_TCACHE 255:0
`define SIZE_OF_TCACHER 32:0
`define SIZE_OF_TCACHE_ADDR 7:0
`define SIZE_OF_PTA 32:0
`define SIZE_OF_PC_HASH 7:0
`define SIZE_OF_BRANCH_INFO 66:0 

`define SIZE_OF_BUFFER 1:0 //待定，取决于流水线的设计
`define SIZE_OF_BUF_ADDR

`define SIZE_OF_BPBUFF 1:0

`define SIZE_OF_CORR_PACK 87:0
`define CRR_PRED_DIR 87
`define CRR_PRED_TAR 86:55
`define CRR_DIR0 54   //by pht0
`define CRR_DIR1 53   //by pht1 
`define CRR_BTBTAG   52:41
`define CRR_BTBINDEX 40:32
`define CRR_PHT0ADDR 31:24
`define CRR_PHT1ADDR 23:16
`define CRR_BHTADDR  15:8
`define CRR_CPHTADDR 7:0

`define BRANCH_INFO_PC 66:35
`define BRANCH_INFO_DIR 34
`define BRANCH_INFO_TAR 33:2
`define BRANCH_INFO_TYP 1:0 

`define BTB_TAG 45:34
`define BTB_VALID 46
`define BTB_TAR 33:2
`define BTB_TYP 1:0
`define BTB_ADDRBUFF_TAG 20:9
`define BTB_ADDRBUFF_INDEX 8:0

`define TCACHE_VALID 32
`define TCACHE_TAR 31:0 

`define METHOD_GH 1'b0
`define METHOD_LH 1'b1

`define RAS_COUNT 37:32
`define RAS_VALID 32
`define RAS_TAR 31:0

`define PTA_DIR   32
`define PTA_PADDR 31:0

//FSM
`define SNT 2'b00
`define WNT 2'b01
`define WT  2'b10
`define ST  2'b11

`define SP1 2'b00
`define WP1 2'b01
`define WP2 2'b10
`define SP2 2'b11


//branch type
`define BTYPE_ABS  2'b00  //
`define BTYPE_CAL  2'b01  //call
`define BTYPE_RET  2'b10  //return
`define BTYPE_NUL  2'b11  //直接跳转


///////////////////////////////////////////////////

`define CP0_REG_STATUS_VAL 32'b00000000010000000000000000000000
`define CP0_REG_CONFIG_VAL 32'b00000000000000001000000000000000
`define CP0_REG_PRID_VAL   32'b00000000010011000000000100000010


`define EXCEPTION_INT 5'h00
`define EXCEPTION_ADEL 5'h04
`define EXCEPTION_ADES 5'h05
`define EXCEPTION_SYS 5'h08
`define EXCEPTION_BP 5'h09
`define EXCEPTION_RI 5'h0a
`define EXCEPTION_OV 5'h0c
`define EXCEPTION_TR 5'h0d
`define EXCEPTION_ERET 5'h0e

// 异常入口地址

`define VECTOR_EXCEPTION 32'hBFC00380