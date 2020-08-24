//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/01 16:24:15
// Design Name: 
// Module Name: fa
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


module fa(
    input a,
    input b,
    input cin,
    output g,
    output p,
    output s,
    output cout
    );
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
    assign g = a & b;
    assign p = a | b;
endmodule
