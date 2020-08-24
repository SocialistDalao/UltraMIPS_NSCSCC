//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 13:31:53
// Design Name: 
// Module Name: branch_target_buffer
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

module branch_target_buffer(
    input wire                    resetn,
    input wire                    clk,
    input wire                    stall,
    
    input wire[`RegBus]            pc,
    input wire[`RegBus]            pc_p4,
    
    input wire                          branch_info_valid,
    input wire[`SIZE_OF_BRANCH_INFO]    branch_info0,
    //input[`SIZE_OF_BRANCH_INFO]    branch_info1,       //id阶段实际分支情况
    
    output reg [`BRANCH_INFO_TYP]  predict_type0, //预测的分支类型 
    //output reg [`BRANCH_INFO_TYP]  predict_type1,
    output reg [`RegBus]           predict_tar0,  //预测的分支地址
    //output reg [`RegBus]           predict_tar1,
    output reg                     hit0          //是否命中
    //output reg                     hit1
    
    );
    
    //存放历史tag(12)+index(9)，可能需要改成FIFO
    reg [20:0] addr_buffer0[`SIZE_OF_BPBUFF];
    //reg [19:0] addr_buffer1;
    
    //47bit * 64
    reg[`SIZE_OF_BTBR] btb [`SIZE_OF_BTB];
    
    //tag and index
    wire[`SIZE_OF_BTBTAG] tag0;
    //wire[`SIZE_OF_BTBTAG] tag1;
    wire[`SIZE_OF_BTBINDEX] index0;
    //wire[`SIZE_OF_BTBINDEX] index1;
    
    assign tag0 = {pc[30:28],pc[19:11]};//{pc[31:28]^pc[27:24],pc[23:20]^pc[19:16],pc[15:12]^pc[11:8]};
    //assign tag1 = {pc_p4[31:28]^pc_p4[27:24],pc_p4[23:20]^pc_p4[19:16],pc_p4[15:12]^pc_p4[11:8]};
    assign index0 = pc[10:2];
    //assign index1 = pc_p4[9:2];   
    
    //读出
    always@(*)begin
        if(resetn == `RstEnable)begin
            hit0 = `False_v;
            predict_type0 = 2'b00;
            predict_tar0 = `ZeroWord;
            //hit1 = `False_v;
            //predict_type1 = 2'b00;
            //predict_tar1 = `ZeroWord;
        end else begin
            hit0 = `False_v;
            //hit1 = `False_v;
            if(btb[index0][`BTB_TAG] == tag0 && btb[index0][`BTB_VALID] == `True_v)begin 
                hit0 = `True_v;       //hit
                predict_type0 = btb[index0][`BTB_TYP];
                predict_tar0 = btb[index0][`BTB_TAR];
            end else begin          
                hit0 = `False_v;      //miss
                predict_type0 = 2'b00;
                predict_tar0 = `ZeroWord;
            end
            /*
            if(btb[index1][`BTB_TAG] == tag1 && btb[index1][`BTB_VALID] == `True_v)begin 
                hit1 = `True_v;       //hit
                predict_type1 = btb[index1][`BTB_TYP];
                predict_tar1 = btb[index1][`BTB_TAR];
            end else begin          
                hit1 = `False_v;      //miss
                predict_type1 = 2'b00;
                predict_tar1 = `ZeroWord;
            end*/
        
        end
    end
    
    //写入   
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
        
        end else if(stall == `True_v)begin
        
        end else begin
            if(branch_info_valid == `True_v)begin
                //发生了跳转，则更新BTB，否则不管  !!!btb不存一般的间接跳转!!!
                if(branch_info0[`BRANCH_INFO_DIR] == `True_v && branch_info0[`BRANCH_INFO_TYP] != `BTYPE_ABS)begin
                    btb[addr_buffer0[1][`BTB_ADDRBUFF_INDEX]][`BTB_VALID] <= `True_v;
                    btb[addr_buffer0[1][`BTB_ADDRBUFF_INDEX]][`BTB_TAG] <= addr_buffer0[1][`BTB_ADDRBUFF_TAG];
                    btb[addr_buffer0[1][`BTB_ADDRBUFF_INDEX]][`BTB_TAR] <= branch_info0[`BRANCH_INFO_TAR];
                    btb[addr_buffer0[1][`BTB_ADDRBUFF_INDEX]][`BTB_TYP] <= branch_info0[`BRANCH_INFO_TYP];
                end else begin
                    
                end
                /*
                if(branch_info1[`BRANCH_INFO_DIR] == `True_v && branch_info1[`BRANCH_INFO_TYP] != `BTYPE_ABS)begin
                    btb[addr_buffer1[`BTB_ADDRBUFF_INDEX]][`BTB_VALID] <= `True_v;
                    btb[addr_buffer1[`BTB_ADDRBUFF_INDEX]][`BTB_TAG] <= addr_buffer1[`BTB_ADDRBUFF_TAG];
                    btb[addr_buffer1[`BTB_ADDRBUFF_INDEX]][`BTB_TAR] <= branch_info1[`BRANCH_INFO_TAR];
                    btb[addr_buffer1[`BTB_ADDRBUFF_INDEX]][`BTB_TYP] <= branch_info1[`BRANCH_INFO_TYP];
                end else begin
                
                end*/
            end else begin
            
            end
            addr_buffer0[0] <= {tag0,index0};
            addr_buffer0[1] <= addr_buffer0[0]; 
            //addr_buffer1 <= {tag1,index1};//记录历史地址，用于更新
        end
    end

endmodule
