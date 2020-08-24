//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 13:31:53
// Design Name: 
// Module Name: patter_history_table
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

module patter_history_table(
    input wire resetn,
    input wire clk,
    input wire stall,
    
    input wire [`SIZE_OF_PHT_ADDR]    addr0,
    //input [`SIZE_OF_PHT_ADDR]    addr1,

    input wire                   branch_info_valid,
    input wire                   branch_dir0,
    //input                        branch_dir1,       //id阶段实际分支情况
    
    output reg                 predict_dir0
    //output reg[`SIZE_OF_BHR]     predict_dir1
    
    );
    
    reg [`SIZE_OF_BP_FSM] pht [`SIZE_OF_PHT];
    reg [`SIZE_OF_PHT_ADDR]    addr_buffer0[`SIZE_OF_BPBUFF];
    //reg [`SIZE_OF_PHT_ADDR]    addr_buffer1;  //此处可能需要改FIFO
    
    
    //读
    always@(*)begin
        if(resetn == `RstEnable)begin
            predict_dir0 = `False_v;
            //predict_dir1 = `False_v;
        end else begin
            case(pht[addr0])
                `SNT:     begin
                    predict_dir0 = `False_v;
                end
                `WNT:     begin
                    predict_dir0 = `False_v;
                end
                `WT:      begin
                    predict_dir0 = `True_v;
                end
                `ST:      begin
                    predict_dir0 = `True_v;
                end
                default:  begin
                    predict_dir0 = `False_v;
                end
            endcase
            /*
            case(pht[addr1])
                `SNT:     begin
                    predict_dir1 = `False_v;
                end
                `WNT:     begin
                    predict_dir1 = `False_v;
                end
                `WT:      begin
                    predict_dir1 = `True_v;
                end
                `ST:      begin
                    predict_dir1 = `True_v;
                end
                default:  begin
                    predict_dir1 = `False_v;
                end
            endcase*/
        end
    
    end
    
    //写
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            
        end else if(stall == `True_v) begin
            
        end else begin
            if(branch_info_valid == `True_v)begin
                case(pht[addr_buffer0[1]])
                    `SNT:  begin
                        if(branch_dir0 == `True_v)begin
                            pht[addr_buffer0[1]] <= `WNT;                      
                        end else begin
                           
                        end
                    end
                    `WNT:  begin
                        if(branch_dir0 == `True_v)begin
                            pht[addr_buffer0[1]] <= `WT;                      
                        end else begin
                            pht[addr_buffer0[1]] <= `SNT;  
                        end
                    end
                    `WT:   begin
                        if(branch_dir0 == `True_v)begin
                            pht[addr_buffer0[1]] <= `ST;                      
                        end else begin
                            pht[addr_buffer0[1]] <= `WNT;  
                        end
                    end
                    `ST:   begin
                        if(branch_dir0 == `True_v)begin
                                              
                        end else begin
                            pht[addr_buffer0[1]] <= `WT;  
                        end
                    end
                    default: pht[addr_buffer0[1]] <= `WT; //////
            
                endcase
                /*
                case(pht[addr_buffer1])
                    `SNT:  begin
                        if(branch_dir1 == `True_v)begin
                            pht[addr_buffer1] <= `WNT;                      
                        end else begin
                           
                        end
                    end
                    `WNT:  begin
                        if(branch_dir1 == `True_v)begin
                            pht[addr_buffer1] <= `WT;                      
                        end else begin
                            pht[addr_buffer1] <= `SNT;  
                        end
                    end
                    `WT:   begin
                        if(branch_dir1 == `True_v)begin
                            pht[addr_buffer1] <= `ST;                      
                        end else begin
                            pht[addr_buffer1] <= `WNT;  
                        end
                    end
                    `ST:   begin
                        if(branch_dir1 == `True_v)begin
                                              
                        end else begin
                            pht[addr_buffer1] <= `WT;  
                        end
                    end
                    default: pht[addr_buffer1] <= `SNT;
                endcase*/
                addr_buffer0[0] <= addr0;
                addr_buffer0[1] <= addr_buffer0[0];
                //addr_buffer1 <= addr1;
            end
        end
    end
    
endmodule
