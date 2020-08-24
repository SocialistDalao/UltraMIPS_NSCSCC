//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/25 17:02:32
// Design Name: 
// Module Name: if_id
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



module if_id(

    input clk,
    input rst,
    input flush,
    input flush_cause,
    input[6:0] stall,
    
    input[`InstAddrBus] pc_i,
    input[`InstAddrBus] npc_i,
    input               branch_flag_i,
    input[`InstBus] inst1_i,
    input[`InstBus] inst2_i,
    input issue_i,
    
    output reg[`InstAddrBus] pc_o,
    output reg[`InstAddrBus] npc_o,
    output reg               branch_flag_o,
    output reg[`InstBus] inst1_o,
    output reg[`InstBus] inst2_o,
    output reg issue_o
    
    );
    
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            pc_o <= `ZeroWord;
            npc_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            inst1_o <= `ZeroWord;
            inst2_o <= `ZeroWord;
            issue_o <= `DualIssue;
        end else if (flush == `Flush) begin
            pc_o <= `ZeroWord;
            npc_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            inst1_o <= `ZeroWord;
            inst2_o <= `ZeroWord;
            issue_o <= `DualIssue;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
            pc_o <= `ZeroWord;
            npc_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            inst1_o <= `ZeroWord;
            inst2_o <= `ZeroWord;
            issue_o <= `DualIssue;
        end else if (stall[1] == `NoStop) begin
            pc_o <= pc_i;
            npc_o <= npc_i;
            branch_flag_o <= branch_flag_i;
            inst1_o <= inst1_i;
            inst2_o <= inst2_i;
            issue_o <= issue_i;
        end
    end
    
endmodule
