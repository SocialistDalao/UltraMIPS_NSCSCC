//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/30 16:40:58
// Design Name: 
// Module Name: choice_patter_histroy_table
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

module choice_patter_history_table(
    input wire resetn,
    input wire clk,
    input wire stall,
    
    input wire [`SIZE_OF_PHT_ADDR]    addr0,
    //input [`SIZE_OF_PHT_ADDR]    addr1,

    input wire                 pre0_result0,  //全局预测结果
    //input                      pre0_result1,
    input wire                 pre1_result0,  //局部预测结果
    //input                      pre1_result1,
    
    output reg   predict_method0
    //output reg[`SIZE_OF_BHR]   predict_method1
    
    );
    
    reg [`SIZE_OF_BP_FSM] cpht [`SIZE_OF_PHT];
    reg [`SIZE_OF_PHT_ADDR]    addr_buffer0[`SIZE_OF_BPBUFF];
    //reg [`SIZE_OF_PHT_ADDR]    addr_buffer1;  //此处可能需要改FIFO
    
    
    //读
    always@(*)begin
        if(resetn == `RstEnable)begin
            predict_method0 = `METHOD_GH;
            //predict_method1 = `METHOD_GH; //默认使用全局历史预测
        end else begin
            
            case(cpht[addr0])
                `SP1:     begin
                    predict_method0 = `METHOD_GH;
                end
                `WP1:     begin
                    predict_method0 = `METHOD_GH;
                end
                `WP2:      begin
                    predict_method0 = `METHOD_LH;
                end
                `SP2:      begin
                    predict_method0 = `METHOD_LH;
                end
                default:  begin
                    predict_method0 = `METHOD_GH;
                end
            endcase
            /*
            case(cpht[addr1])
                `SP1:     begin
                    predict_method1 = `METHOD_GH;
                end
                `WP1:     begin
                    predict_method1 = `METHOD_GH;
                end
                `WP2:      begin
                    predict_method1 = `METHOD_LH;
                end
                `SP2:      begin
                    predict_method1 = `METHOD_LH;
                end
                default:  begin
                    predict_method1 = `METHOD_GH;
                end
            endcase*/
        end
    
    end
    
    //写
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            
        end else if(stall == `True_v) begin
            
        end else begin
            case(cpht[addr_buffer0[1]])
                `SP1:   begin
                    if(pre0_result0 == `False_v && pre1_result0 == `True_v)begin
                        cpht[addr_buffer0[1]] <= `WP1; //全局错误，局部正确
                    end
                end
                `WP1:   begin
                    if(pre0_result0 == `False_v && pre1_result0 == `True_v)begin
                        cpht[addr_buffer0[1]] <= `WP2; 
                    end
                    if(pre0_result0 == `True_v && pre1_result0 == `False_v)begin
                        cpht[addr_buffer0[1]] <= `SP1; //全局正确，局部错误
                    end
                end
                `WP2:   begin
                    if(pre0_result0 == `False_v && pre1_result0 == `True_v)begin
                        cpht[addr_buffer0[1]] <= `SP2;
                    end
                    if(pre0_result0 == `True_v && pre1_result0 == `False_v)begin
                        cpht[addr_buffer0[1]] <= `WP1;
                    end
                end
                `SP2:   begin
                    if(pre0_result0 == `True_v && pre1_result0 == `False_v)begin
                        cpht[addr_buffer0[1]] <= `WP2;
                    end
                end
                default:cpht[addr_buffer0[1]] <= `WP1;
            endcase
            /*
            case(cpht[addr_buffer1])
                `SP1:   begin
                    if(pre0_result1 == `False_v && pre1_result1 == `True_v)begin
                        cpht[addr_buffer1] <= `WP1;
                    end
                end
                `WP1:   begin
                    if(pre0_result1 == `False_v && pre1_result1 == `True_v)begin
                        cpht[addr_buffer1] <= `WP2;
                    end
                    if(pre0_result1 == `True_v && pre1_result1 == `False_v)begin
                        cpht[addr_buffer1] <= `SP1;
                    end
                end
                `WP2:   begin
                    if(pre0_result1 == `False_v && pre1_result1 == `True_v)begin
                        cpht[addr_buffer1] <= `SP2;
                    end
                    if(pre0_result1 == `True_v && pre1_result1 == `False_v)begin
                        cpht[addr_buffer1] <= `WP1;
                    end
                end
                `SP2:   begin
                    if(pre0_result1 == `True_v && pre1_result1 == `False_v)begin
                        cpht[addr_buffer1] <= `WP2;
                    end
                end
                default: cpht[addr_buffer1] <= `WP1;
            endcase*/
            addr_buffer0[0] <= addr0;
            addr_buffer0[1] <= addr_buffer0[0];
            //addr_buffer1 <= addr1;    
            
        end
    end
    
    
endmodule
