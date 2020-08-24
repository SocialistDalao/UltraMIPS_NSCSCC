//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/01 16:24:15
// Design Name: 
// Module Name: fa32
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


module fa32(
    input[31:0] a,
    input[31:0] b,
    input cin,
    input sub, // 是否是减法，1为是，0为不是
    output[31:0] s,
    output[31:0] cout
    );
    wire[31:0] b_in;
    wire cin_in;
    assign b_in = sub ? ~b : b;
    assign cin_in = cin ^ sub;
    fa16 u_fa161(.a(a[15:0]), .b(b_in[15:0]), .cin(cin_in), .s(s[15:0]), .cout(cout[15:0]));
    fa16 u_fa162(.a(a[31:16]), .b(b_in[31:16]), .cin(cout[15]), .s(s[31:16]), .cout(cout[31:16]));
endmodule
