`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/01 09:13:08
// Design Name: 
// Module Name: branch_buffer_lite
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
//`define SNT  2'b00
//`define WNT  2'b01
//`define WT   2'b10
//`define ST   2'b11
`include "defines.v"

module branch_buffer_lite(
    input wire                          resetn,
    input wire                          clk,
    //input wire              stall,
    
    input wire[`SIZE_OF_BRANCH_INFO]    branch_info0,
    //input wire[`SIZE_OF_BRANCH_INFO]    branch_info1,       //id阶段实际分支情况
    
    input wire     pred_flag0,
    //input wire     pred_flag1,

    input wire[`SIZE_TAG]     corr_tag0,
    //input wire     corr_tag1,
    input wire[`SIZE_INDEX]     corr_index0,
    //input wire     corr_index1,
    
    input wire[`SIZE_TAG]   tag0,    
    input wire[`SIZE_TAG]   tag1,    
    input wire[`SIZE_INDEX] index0,
    input wire[`SIZE_INDEX] index1,
    
    output reg [`TYPE_WIDTH]  predict_type0, //预测的分支类型 
    output reg [`TYPE_WIDTH]  predict_type1,
    output reg [`BUS_WIDTH]   predict_tar0,  //预测的分支地址
    output reg [`BUS_WIDTH]   predict_tar1,
    output reg                predict_dir0,  //预测跳或不跳
    output reg                predict_dir1,
    output reg                hit0,          //是否命中
    output reg                hit1

    );
    
    reg [`SIZE_TAG]   taglist [255:0];
    reg [`BUS_WIDTH]  tarlist [255:0];
    reg [`TYPE_WIDTH] typelist[255:0];
    reg [1:0] dirlist [255:0];
    reg [255:0] valid;
    
    //方向预测
    always@(*)begin
        if(resetn == `RstEnable)begin
            predict_dir0 <= 1'b0;
            predict_dir1 <= 1'b0;
        end else begin
            case(dirlist[index0])
                `SNT:predict_dir0 <= 1'b0;
                `WNT:predict_dir0 <= 1'b0;
                `WT:predict_dir0 <= 1'b1;
                `ST:predict_dir0 <= 1'b1;
                default:predict_dir0 <= 1'b0;          
            endcase
            case(dirlist[index1])
                `SNT:predict_dir1 <= 1'b0;
                `WNT:predict_dir1 <= 1'b0;
                `WT:predict_dir1 <= 1'b1;
                `ST:predict_dir1 <= 1'b1;
                default:predict_dir1 <= 1'b0;          
            endcase
        end
    end
    
    //其他预测
    always@(*)begin
        if(resetn == `RstEnable)begin
            hit0 <= `False_v;
            predict_type0 <= 2'b00;
            predict_tar0 <= `ZeroWord;
            hit1 <= `False_v;
            predict_type1 <= 2'b00;
            predict_tar1 <= `ZeroWord;
        end else begin
            
            if(taglist[index0] == tag0 && valid[index0] == `True_v)begin 
                hit0 <= `True_v;       //hit
                predict_type0 <= typelist[index0];
                predict_tar0 <= tarlist[index0];                
            end else begin          
                hit0 <= `False_v;      //miss
                predict_type0 <= 2'b00;
                predict_tar0 <= `ZeroWord;             
            end
            
            if(taglist[index1] == tag1 && valid[index1] == `True_v)begin 
                hit1 <= `True_v;       //hit
                predict_type1 <= typelist[index1];
                predict_tar1 <= tarlist[index1];
            end else begin          
                hit1 <= `False_v;      //miss
                predict_type1 <= 2'b00;
                predict_tar1 <= `ZeroWord;
            end          
        end
    end
    
    //修正
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            valid <= 256'h0;
        end else begin
            if(pred_flag0 == 1'b0)begin
                taglist [corr_index0] <= corr_tag0;
                tarlist [corr_index0] <= branch_info0[`BRANCH_INFO_TAR];
                typelist[corr_index0] <= branch_info0[`BRANCH_INFO_TYP];
                valid[corr_index0] <= |(branch_info0[`BRANCH_INFO_TAR]);
            end
        end
    end
    
    //方向修正
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
        
        
        end else if( branch_info0[`BRANCH_INFO_TYP] == `BTYPE_CAL || branch_info0[`BRANCH_INFO_TYP] == `BTYPE_RET)begin
            dirlist[corr_index0] <= `ST;

        end else begin
            case(dirlist[corr_index0])
                `SNT:begin
                    if(branch_info0[`BRANCH_INFO_DIR])begin
                        dirlist[corr_index0] <= `WNT;
                    end                   
                end
                `WNT:begin
                    if(branch_info0[`BRANCH_INFO_DIR])begin
                        dirlist[corr_index0] <= `WT;            
                    end else begin
                        dirlist[corr_index0] <= `SNT;
                    end              
                end
                `WT:begin
                    if(branch_info0[`BRANCH_INFO_DIR])begin
                        dirlist[corr_index0] <= `ST;                         
                    end else begin
                        dirlist[corr_index0] <= `WNT;
                    end  
                end
                `ST:begin
                    if(!branch_info0[`BRANCH_INFO_DIR])begin
                        dirlist[corr_index0] <= `WT;
                    end           
                end
                default:dirlist[corr_index0] <= `WT;             
            endcase 
        end 
    end
endmodule
