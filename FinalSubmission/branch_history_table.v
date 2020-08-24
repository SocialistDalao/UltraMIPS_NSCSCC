//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/29 13:31:53
// Design Name: 
// Module Name: branch_history_table
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

module branch_history_table(
    input wire resetn,
    input wire clk,
    input wire stall,
    
    input wire [`SIZE_OF_BHT_ADDR]    addr0,
    //input [`SIZE_OF_BHT_ADDR]    addr1,
    input wire [`SIZE_OF_BRANCH_INFO] branch_info0,
    //input [`SIZE_OF_BRANCH_INFO] branch_info1,
    input wire branch_info_valid,     //id分支信息是否可用
    
    output wire [`SIZE_OF_BHR]        bhr0
    //output [`SIZE_OF_BHR]        bhr1
    
    );
    
    reg [`SIZE_OF_BHR]bht [`SIZE_OF_BHT];
    reg [`SIZE_OF_BHT_ADDR] addr_buffer0[`SIZE_OF_BPBUFF];
    //wire [`SIZE_OF_BHT_ADDR] abuff_top;
    //assign abuff_top = addr_buffer0[1];
    //reg [`SIZE_OF_BHT_ADDR] addr_buffer1; //此处可能需要改FIFO
    
    //读取
    assign bhr0 = resetn == `RstEnable ? 8'h00 : bht[addr0];
    //assign bhr1 = resetn == `RstEnable ? 8'h00 : bht[addr1];
    
    //写入
    always@(posedge clk)begin
        if(resetn == `RstEnable)begin
            
        end else if(stall == `True_v)begin 
            
        end else begin
            if(branch_info_valid == `True_v)begin  //此处可能需要更改Buffer
                bht[addr_buffer0[1]] <= {bht[addr_buffer0[1]][6:0],branch_info0[`BRANCH_INFO_DIR]};
                //bht[addr_buffer1] <= {bht[addr_buffer1][6:0],branch_info1[`BRANCH_INFO_DIR]};
            end else begin
            
            end
            addr_buffer0[0] <= addr0;
            addr_buffer0[1] <= addr_buffer0[0];
            //addr_buffer1 <= addr1; //更新buffer
        end
    end
    
endmodule
