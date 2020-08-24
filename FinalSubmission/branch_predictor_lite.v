`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/01 09:13:08
// Design Name: 
// Module Name: branch_predictor_lite
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
`define SIZE_TAG   21:0
`define SIZE_INDEX 7:0
`define BUS_WIDTH  31:0
`define TYPE_WIDTH 1:0
`include "defines.v"

module branch_predictor_lite(
    input wire resetn,
    input wire clk,
    input wire stall,  //stall from ex!
    
    input wire[`RegBus] pc,
    input wire[`RegBus] pc_p4,
    
    //actual branch infomation from ex
    input wire[`SIZE_OF_BRANCH_INFO] branch_info0, //分支信息: pc + 是否跳1bit + 跳的地址32bit + 跳转类型2bit
    input wire[31:0] reg31,
    //预测结果
    output reg[`SIZE_OF_PTA] pta0,   //33bit:dir 1bit + target 32bit
    output reg[`SIZE_OF_PTA] pta1,
    output reg[`SIZE_OF_CORR_PACK] corr_pack0_o, 
    output reg[`SIZE_OF_CORR_PACK] corr_pack1_o
    
    );
    
    wire[`BUS_WIDTH]    corr_pc0;
    wire[`BUS_WIDTH]    corr_pc1;
    
    wire[`SIZE_TAG]     corr_tag0;                
    wire[`SIZE_TAG]     corr_tag1;                
    wire[`SIZE_INDEX]   corr_index0;              
    wire[`SIZE_INDEX]   corr_index1;             
                                       
    wire[`SIZE_TAG]     tag0;            
    wire[`SIZE_TAG]     tag1;            
    wire[`SIZE_INDEX]   index0;          
    wire[`SIZE_INDEX]   index1;          
                                       
    wire [`TYPE_WIDTH]  predict_type0; 
    wire [`TYPE_WIDTH]  predict_type1; //有什么用？？？
    wire [`BUS_WIDTH]   predict_tar0;  
    wire [`BUS_WIDTH]   predict_tar1;  
    wire                predict_dir0;  
    wire                predict_dir1;  
    wire                hit0;          
    wire                hit1;
    wire [`BUS_WIDTH]   btb_tar0;   
    wire [`BUS_WIDTH]   btb_tar1;                  
    wire                pred_flag0;
    
    //ras
    reg[`SIZE_OF_RASR] ras [`SIZE_OF_RAS];  //33bit*256 valid+target
    reg[7:0]           ras_top;  //栈顶指针
    reg[7:0]           ras_top_p1;
    reg[7:0]           ras_top_d1;
    reg[31:0]          pc_p8;
    reg[31:0]          pc_p12;
    reg ras_sig0;
    reg ras_sig1;
    reg ras_pop0;
    reg ras_pop1;
    
    
    assign corr_pc0 = branch_info0[`BRANCH_INFO_PC];  
    assign corr_tag0 = corr_pc0[31:10];  
    assign corr_index0 = corr_pc0[9:2];

    
    assign index0 = pc[9:2];
    assign index1 = pc_p4[9:2];
    assign tag0 = pc[31:10];
    assign tag1 = pc_p4[31:10];
    
    assign pred_flag0 = ~(|branch_info0[34:0]);

    assign predict_tar0 = btb_tar0; //(predict_type0 == `BTYPE_RET )? reg31 : btb_tar0;
    assign predict_tar1 = btb_tar1; //(predict_type1 == `BTYPE_RET )? reg31 : btb_tar1;
    
    always@(*)begin
        if(hit0 == 1'b1)begin
            pta0 = {predict_dir0,predict_tar0};
            corr_pack0_o = {predict_dir0,predict_tar0,55'd0};
        end else begin
            pta0 = 33'd0;
            corr_pack0_o = 88'd0;
        end
        
        if(hit1 == 1'b1)begin
            pta1 = {predict_dir1,predict_tar1};
            corr_pack1_o = {predict_dir1,predict_tar1,55'd0};
        end else begin
            pta1 = 33'd0;
            corr_pack1_o = 88'd0;
        end
    end 
    
    
    /////////////////////  return addr stack  /////////////////////
    reg stall_reg;
    reg[7:0] rar_count[255:0];
    /*
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            stall_reg <= 1'b0;
        end else begin
            stall_reg <= stall;
        end
    end
    
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin        
            ras_top <= 8'h00;
            ras_sig0 <= 1'b0;
            ras_sig1 <= 1'b0;
            ras_pop0 <= 1'b0;
            ras_pop1 <= 1'b0; 
            //stall_reg <= 1'b0;
        end else begin
            ////ras控制////
            //写入////
            if(hit0 == `True_v && predict_type0 == `BTYPE_CAL && !stall_reg && ras_top != 8'hff)begin                      
                ras[ras_top+1][`RAS_VALID] <= 1'b1;
                ras[ras_top+1][31:0] <= pc+8;//需要跳过延迟槽
                ras_top <= ras_top+1;  
                rar_count[ras_top+1] <= 0;                            
            end else if (hit0 == `True_v && predict_type0 == `BTYPE_RET && ras_top != 1)begin
                ras_top <= ras_top - 1;     
                ras[ras_top][`RAS_VALID]<=1'b0;  
            end else if(hit1 == `True_v && predict_type1 == `BTYPE_CAL && !stall_reg && ras_top != 8'hff)begin
                ras[ras_top+1][`RAS_VALID] <= 1'b1;
                ras[ras_top+1][31:0] <= pc+12;//需要跳过延迟槽
                ras_top <= ras_top+1;  
                rar_count[ras_top+1] <= 0;                       
            end else if(hit1 == `True_v && predict_type1 == `BTYPE_RET && ras_top != 1)begin
                ras_top <= ras_top - 1;     
                ras[ras_top][`RAS_VALID]<=1'b0;   
            end         
            //
            if(!ras_sig0 && predict_type0 == `BTYPE_CAL)begin
                ras_sig0 <= 1'b1;
                ras_sig1 <= 1'b0;
            end else if(!ras_sig1 && predict_type1 == `BTYPE_CAL)begin
                ras_sig0 <= 1'b0;
                ras_sig1 <= 1'b1;
            end else begin
                ras_sig0 <= 1'b0;
                ras_sig1 <= 1'b0;
            end
            
            //控制ras读出时指针减小
            if (hit0 == `True_v && predict_type0 == `BTYPE_RET)begin               
                ras_pop0 <= 1'b1;  
                ras_pop1 <= 1'b0;               
            end else if(hit1 == `True_v && predict_type1 == `BTYPE_RET)begin
                ras_pop0 <= 1'b0;  
                ras_pop1 <= 1'b1;  
            end else begin
                ras_pop0 <= 1'b0;  
                ras_pop1 <= 1'b0; 
            end//    
        end
    end
   
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            ras_top <= 3'b111;
        end else begin
            if(branch_info0[`BRANCH_INFO_TYP] == `BTYPE_CAL)begin
                ras[ras_top+1] <= branch_info0[`BRANCH_INFO_PC]+8;
                ras[ras_top+1][`RAS_VALID] <= 1'b1;
                ras_top <= ras_top + 1;
            end
            
            if(branch_info0[`BRANCH_INFO_TYP] == `BTYPE_RET )begin
                ras[ras_top][`RAS_VALID] <= 1'b0;
                ras_top <= ras_top - 1;
            end 
        end
    end
    
    always @(posedge clk) begin
        pc_p8 <= pc+8;
        pc_p12 <= pc_p4+8;
        ras_top_p1 <= ras_top + 1;
        ras_top_d1 <= ras_top - 1;
    end*/
    /////////////////////////////////////////////////////////////   
 
    branch_buffer_lite bbl0(
        resetn,      
        clk,         
                          
        branch_info0[34:0],
        
        pred_flag0, 
                    
        corr_tag0,  
        corr_index0,   
        
        tag0,           
        tag1,           
        index0,         
        index1,         
                        
        predict_type0,
        predict_type1,
        btb_tar0, 
        btb_tar1, 
        predict_dir0, 
        predict_dir1, 
        hit0,         
        hit1          

    );
    
endmodule
