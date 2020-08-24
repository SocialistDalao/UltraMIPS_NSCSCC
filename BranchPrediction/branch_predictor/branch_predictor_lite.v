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
    
    input wire cp0_exl_i,
    
    //actual branch infomation from ex
    input wire[`SIZE_OF_BRANCH_INFO] branch_info0, // pc + jump flag 1bit + jump target 32bit + branch type2bit
    
    // instruction address error exceptions
    input wire TLB_Imiss,
    input wire ADEL_assert,
    input wire TLB_Iinvalid,
    input wire TLB_Iillegal,
        
    //predict result
    output reg[`SIZE_OF_PTA] pta0,   //33bit:jump flag 1bit + jump target 32bit
    output reg[`SIZE_OF_PTA] pta1,
    output reg[`SIZE_OF_CORR_PACK] corr_pack0_o, 
    output reg[`SIZE_OF_CORR_PACK] corr_pack1_o
    
    );
    
    wire[`BUS_WIDTH]     corr_pc0;
    wire[`BUS_WIDTH]     corr_pc1;
    
    wire[`SIZE_TAG]     corr_tag0;                
    wire[`SIZE_TAG]     corr_tag1;                
    wire[`SIZE_INDEX]   corr_index0;              
    wire[`SIZE_INDEX]   corr_index1;              
                                       
    wire[`SIZE_TAG]     tag0;            
    wire[`SIZE_TAG]     tag1;            
    wire[`SIZE_INDEX]   index0;          
    wire[`SIZE_INDEX]   index1;          
                                       
    wire [`TYPE_WIDTH]  predict_type0; 
    wire [`TYPE_WIDTH]  predict_type1; 
    wire [`BUS_WIDTH]   predict_tar0;  
    wire [`BUS_WIDTH]   predict_tar1;  
    wire                predict_dir0;  
    wire                predict_dir1;  
    wire                hit0;          
    wire                hit1;         
    wire                pred_flag0;
    
   
    assign corr_pc0 = branch_info0[`BRANCH_INFO_PC];
    assign corr_tag0 = corr_pc0[31:10];
    assign corr_index0 = corr_pc0[9:2];
    
    assign index0 = pc[9:2];
    assign index1 = pc_p4[9:2];
    assign tag0 = pc[31:10];
    assign tag1 = pc_p4[31:10];
    
    assign pred_flag0 = ~(|branch_info0[34:0]);
    
    //assign corr_pack0_o = hit0?{predict_dir0,predict_tar0,55'd0}:88'd0;
    //assign corr_pack1_o = hit1?{predict_dir1,predict_tar1,55'd0}:88'd0;
    //////////////////////////////////////////////////////////////
    /*
    reg[`SIZE_OF_RASR] ras [`SIZE_OF_RAS];  //33bit*256 valid+target
    reg[7:0]           ras_top;  //栈顶指针
    reg[7:0]           ras_top_p1;
    reg[7:0]           ras_top_d1;
    reg[31:0]          pc_p8;
    reg[31:0]          pc_p12;
    */
    //////////////////////////////////////////////////////////////
    always@(*)begin
        if(hit0 == 1'b1)begin
            pta0 = {predict_dir0,predict_tar0};
            corr_pack0_o = {predict_dir0,predict_tar0,46'd0,cp0_exl_i,4'd0,TLB_Imiss,ADEL_assert,TLB_Iillegal,TLB_Iinvalid};
        end else begin
            pta0 = 33'd0;
            corr_pack0_o = {84'd0,TLB_Imiss,ADEL_assert,TLB_Iillegal,TLB_Iinvalid};
        end
        
        if(hit1 == 1'b1)begin
            pta1 = {predict_dir1,predict_tar1};
            corr_pack1_o = {predict_dir1,predict_tar1,46'd0,cp0_exl_i,4'd0,TLB_Imiss,ADEL_assert,TLB_Iillegal,TLB_Iinvalid};
        end else begin
            pta1 = 33'd0;
            corr_pack1_o = {84'd0,TLB_Imiss,ADEL_assert,TLB_Iillegal,TLB_Iinvalid};
        end
    end 

    ////////////////  ras  ///////////////////
    /*
    reg ras_sig0;
    reg ras_sig1;
    reg ras_pop0;
    reg ras_pop1;
    
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
          
            ras_top <= 3'b111;
            ras_sig0 <= 1'b0;
            ras_sig1 <= 1'b0;
            ras_pop0 <= 1'b0;
            ras_pop1 <= 1'b0; 
        end else begin
            ////ras控制////
            //写入////
            if(ras_sig0)begin               
                //到顶了也要继续塞，希望栈没事
                ras[ras_top_p1][`RAS_VALID] <= 1'b1;
                ras[ras_top_p1][31:0] <= pc_p8;//需要跳过延迟槽
                ras_top <= ras_top_p1;                           
            end 
            
            if(ras_sig1)begin
                ras[ras_top_p1][`RAS_VALID] <= 1'b1;
                ras[ras_top_p1][31:0] <= pc_p12;//需要跳过延迟槽
                ras_top <= ras_top_p1; 
            end          

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
            end

            if (ras_pop0)begin               
                ras_top <= ras_top_d1;               
            end else if(ras_pop1)begin
                ras_top <= ras_top_d1;
            end
            
            if (ras_pop1)begin               
                ras_top <= ras_top_d1;               
            end else if(ras_pop1)begin
                ras_top <= ras_top_d1;
            end


        end
    end

    always @(posedge clk) begin
        pc_p8 <= pc+8;
        pc_p12 <= pc_p4+8;
        ras_top_p1 <= ras_top + 1;
        ras_top_d1 <= ras_top - 1;
    end*/
    
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
        predict_tar0, 
        predict_tar1, 
        predict_dir0, 
        predict_dir1, 
        hit0,         
        hit1          

    );
    
endmodule
