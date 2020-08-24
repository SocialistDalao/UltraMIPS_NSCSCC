//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/28 20:00:40
// Design Name: 
// Module Name: branch_prediction
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

module branch_prediction(
    input wire resetn,
    input wire clk,
    input wire stall,
    
    input wire[`RegBus] pc,
    
    //id返回实际分支信息
    input wire[`SIZE_OF_BRANCH_INFO] id_branch_info0, //分支信息:是否跳1bit + 跳的地址32bit + 跳转类型2bit  
    input wire pred_flag,       //预测失败的清除信号
    
    //预测结果
    output reg[`SIZE_OF_PTA] pta0   //33bit:是否跳1bit + 跳的地址32bit
    
    );
    //ghr
    reg[`SIZE_OF_GHR] ghr;
    (*DONT_TOUCH = "1"*)reg[`SIZE_OF_GHR] ghr_checkpoint[`SIZE_OF_BPBUFF];   //可能需要改成FIFO
    
    //bhr
    wire[`SIZE_OF_BHR] bhr0;
    //wire[`SIZE_OF_BHR] bhr1;
    
    //ras
    reg[`SIZE_OF_RASR] ras [`SIZE_OF_RAS];
    reg[2:0]           ras_top;  //栈顶指针
    wire[2:0]          ras_top_p1;
    assign             ras_top_p1 = ras_top+1;
    
    //pc接线
    wire[`RegBus]           pc_p4;
    wire[`RegBus]           pc_p8;
    //wire[`RegBus]           pc_p12;
    wire[13:0]              pc0_hash14;
    wire[`SIZE_OF_PC_HASH]  pc0_hash8;
    wire[13:0]              pc1_hash14;
    wire[`SIZE_OF_PC_HASH]  pc1_hash8;
    
    assign pc_p4 = pc + 32'd4;
    assign pc_p8 = pc + 32'd8;
    
    assign pc0_hash14 = {pc[31:27],pc[26:23]^pc[22:19],pc[18:15]^pc[14:11],pc[10:7]^pc[6:3],pc[2]};
    assign pc0_hash8 = {pc[13:10]^pc[9:6],pc[5:2]};
    
     
    //////方向预测方式选择//////
    wire cpht_method0;
    //wire cpht_method1;
    
    ////方向预测结果////
    reg  direct_predict0;
    //reg  direct_predict1;
    wire pht0_pred_dir0;
    //wire pht0_pred_dir1;
    wire pht1_pred_dir0;
    //wire pht1_pred_dir1;
    
    ///////记录上次预测结果，以便更新CPHT。如果取指切流水，需要更换为buffer//////
    reg  prev_pht0_direct0[`SIZE_OF_BPBUFF];  
    //reg  prev_pht0_direct1;  //pht0
    reg  prev_pht1_direct0[`SIZE_OF_BPBUFF];  
    //reg  prev_pht1_direct1;  //pht1
    //上次预测结果的正误
    reg  prev_pht0_jud0;  
    //reg  prev_pht0_jud1;  //pht0
    reg  prev_pht1_jud0;  
    //reg  prev_pht1_jud1;  //pht1  
    
    ///////cache///////
    //btb
    wire btb_hit0;
    //wire btb_hit1;  //是否命中
    wire [`BTB_TYP] btb_pred_type0;
    //wire [`BTB_TYP] btb_pred_type1;  //预测分支类型
    wire [`RegBus]  btb_pred_tar0;
     
    ////////distribute ram 的地址 包括tc、pht、cpht、bht、btb
    wire [`SIZE_OF_TCACHE_ADDR]   tc_addr0;
    //wire [`SIZE_OF_TCACHE_ADDR]   tc_addr1;
    wire [`SIZE_OF_PHT_ADDR]      pht0_addr0;
    //wire [`SIZE_OF_PHT_ADDR]      pht0_addr1;
    wire [`SIZE_OF_PHT_ADDR]      pht1_addr0;
    //wire [`SIZE_OF_PHT_ADDR]      pht1_addr1;
    wire [`SIZE_OF_PHT_ADDR]      cpht_addr0;
    //wire [`SIZE_OF_PHT_ADDR]      cpht_addr1;
    wire [`SIZE_OF_BHT_ADDR]      bht_addr0;
    //wire [`SIZE_OF_BHT_ADDR]      bht_addr1;
    
    //addr
    //assign tc_addr0 = bhr0 ^ pc0_hash8;
    //assign tc_addr1 = bhr1 ^ pc1_hash8;
    assign pht0_addr0 = ghr ^ pc0_hash8;
    //assign pht0_addr1 = ghr ^ pc1_hash8;
    assign pht1_addr0 = bhr0 ^ pc0_hash8;
    //assign pht1_addr1 = bhr1 ^ pc1_hash8;
    assign cpht_addr0 = pht0_addr0 ^ pht1_addr0;
    //assign cpht_addr1 = pht0_addr1 ^ pht1_addr1;
    assign bht_addr0 = pc0_hash8;
    //assign bht_addr1 = pc1_hash8;
    
    
    //////////check list//////////
    //ghr控制  时序 maybe ok
    //ghr checkpoint 恢复  maybe ok
    //ras控制  写、指针控制是时序ok  读是组合ok
    //cpht控制  组合 包括两种预测方法正误的判断  ok
    //dir选择  组合  ok
    //tar选择  组合  ok 
    //pta控制  组合  ok
    //reg checkpoint ???

    
    always@(*)begin
        if(resetn == `RstEnable)begin
            pta0 = 65'd0;
            //pta1 = 65'd0;
            prev_pht0_jud0 = `False_v;
            prev_pht1_jud0 = `False_v;
        end else begin
            /////cpht控制/////
            //两种方法预测结果判断            
            prev_pht0_jud0 = prev_pht0_direct0[1] & id_branch_info0[`BRANCH_INFO_DIR];   
            prev_pht1_jud0 = prev_pht1_direct0[1] & id_branch_info0[`BRANCH_INFO_DIR];      
            
            /////PTA方向设置/////
            pta0[`PTA_DIR] = direct_predict0;
            /////PTA目标地址设置/////      
            
            if(btb_hit0 == `True_v && btb_pred_type0 == `BTYPE_RET && ras_top != 3'b111)begin  
                pta0[`PTA_PADDR] = ras[ras_top];   ///ret
            end else if(btb_hit0 == `True_v)begin 
                pta0[`PTA_PADDR] = btb_pred_tar0;  ///call + 直接
            end else begin
                pta0[`PTA_PADDR] = `ZeroWord; 
            end
        end
    end
    
    always@(*)begin
        if(resetn == `RstEnable)begin
            direct_predict0 = `False_v;
            //direct_predict1 = `False_v;
        end else begin
            /////方向预测选择/////
            if(btb_hit0 == `False_v )begin
                direct_predict0 = `False_v;
            end else if(cpht_method0 == `METHOD_GH)begin
                if(pht0_pred_dir0 == `True_v)begin
                    direct_predict0 = `True_v;
                end else begin
                    direct_predict0 = `False_v;
                end
            end else if(cpht_method0 == `METHOD_LH)begin
                if(pht1_pred_dir0 == `True_v)begin
                    direct_predict0 = `True_v;
                end else begin
                    direct_predict0 = `False_v;
                end
            end else begin
                direct_predict0 = `False_v;
            end
        end
    end
    
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            ghr <= 8'h00;
            ras_top <= 3'b111;
            
        end else if(stall == `True_v)begin
            
        end else begin
            ////控制ghr更新////
            if(pred_flag == `InvalidPrediction)begin
                ghr <= {ghr_checkpoint[1][4:1],id_branch_info0[`BRANCH_INFO_DIR],ghr[1:0],direct_predict0};
                ghr_checkpoint[0] <= {ghr[7:3],id_branch_info0[`BRANCH_INFO_DIR],ghr[1:0]}; 
                ghr_checkpoint[1] <= {ghr_checkpoint[0][7:2],id_branch_info0[`BRANCH_INFO_DIR],ghr_checkpoint[0][0]};
            end else begin
                ghr_checkpoint[0] <= ghr; 
                ghr_checkpoint[1] <= ghr_checkpoint[0];  
                ghr <= {ghr[6:0],direct_predict0};//{ghr[5:0],direct_predict0,direct_predict1};
            end
            
            ////ras控制////
            //写入////
            if(btb_pred_type0 == `BTYPE_CAL)begin
                if(pc_p8 == ras[ras_top][`RAS_TAR] && ras[ras_top][`RAS_COUNT]!= 6'b111111)begin
                    ras[ras_top][`RAS_COUNT] <= ras[ras_top][`RAS_COUNT] + 1;
                end else begin
                    //到顶了也要继续塞，希望栈没事
                    ras[ras_top_p1][`RAS_COUNT] <= 6'd0;
                    ras[ras_top_p1][31:0] <= pc_p8;//需要跳过延迟槽
                    ras_top <= ras_top + 1;
                    
                end
            end
            //控制ras读出时指针减小
            if (btb_hit0 == `True_v && btb_pred_type0 == `BTYPE_RET)begin
                if(ras[ras_top][`RAS_COUNT] == 0)begin
                    ras_top <= ras_top - 1;
                end else if(ras[ras_top][`RAS_COUNT] > 0)begin
                    ras[ras_top][`RAS_COUNT] <= ras[ras_top][`RAS_COUNT] - 1;
                end else begin
                    
                end
            end
            
            //记录当前预测结果
            prev_pht0_direct0[0] <= pht0_pred_dir0;
            prev_pht0_direct0[1] <= prev_pht0_direct0[0];
            //prev_pht0_direct1 <= pht0_pred_dir1;
            prev_pht1_direct0[0] <= pht1_pred_dir0;
            prev_pht1_direct0[1] <= prev_pht1_direct0[0];
            //prev_pht1_direct1 <= pht1_pred_dir1;
        
        end
    end
    
    
    //////模块实例化//////
    
    branch_history_table bht0(
        .resetn(resetn),
        .clk(clk),
        .stall(stall),
        .addr0(bht_addr0),
        //.addr1(bht_addr1),
        .branch_info0(id_branch_info0),
        //.branch_info1(id_branch_info1),
        .branch_info_valid(1'b1),
        .bhr0(bhr0)
        //.bhr1(bhr1)
    );
    
    patter_history_table pht0(
        .resetn(resetn),
        .clk(clk),
        .stall(stall),
        .addr0(pht0_addr0),
        //.addr1(pht0_addr1),
        .branch_dir0(id_branch_info0[`BRANCH_INFO_DIR]),
        //.branch_dir1(id_branch_info1[`BRANCH_INFO_DIR]),
        .branch_info_valid(1'b1),
        .predict_dir0(pht0_pred_dir0)
        //.predict_dir1(pht0_pred_dir1)
    );
    
    patter_history_table pht1(
        .resetn(resetn),
        .clk(clk),
        .stall(stall),
        .addr0(pht1_addr0),
        //.addr1(pht1_addr1),
        .branch_dir0(id_branch_info0[`BRANCH_INFO_DIR]),
        //.branch_dir1(id_branch_info1[`BRANCH_INFO_DIR]),
        .branch_info_valid(1'b1),
        .predict_dir0(pht1_pred_dir0)
        //.predict_dir1(pht1_pred_dir1)
    );
    
    choice_patter_history_table cpht0(
        .resetn(resetn),
        .clk(clk),
        .stall(stall),
        .addr0(cpht_addr0),
        //.addr1(cpht_addr1),
        .pre0_result0(prev_pht0_jud0),
        //.pre0_result1(prev_pht0_jud1),
        .pre1_result0(prev_pht1_jud0),
        //.pre1_result1(prev_pht1_jud1),
        .predict_method0(cpht_method0)
        //.predict_method1(cpht_method1)
    );
    
    branch_target_buffer btb0(
        .resetn(resetn),
        .clk(clk),
        .stall(stall),
        .pc(pc),
        .pc_p4(pc_p4),
        .branch_info0(id_branch_info0),
        //.branch_info1(id_branch_info1),
        .branch_info_valid(1'b1),
        .predict_type0(btb_pred_type0),
        //.predict_type1(btb_pred_type1),
        .predict_tar0(btb_pred_tar0),
        //.predict_tar1(btb_pred_tar1),
        .hit0(btb_hit0)
        //.hit1(btb_hit1)
    );
endmodule
