//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/01 16:24:15
// Design Name: 
// Module Name: fa16
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


module fa16(
    input[15:0] a,
    input[15:0] b,
    input cin,
    output gout,
    output pout,
    output[15:0] s,
    output[15:0] cout
    );
    wire[3:0] p;
    wire[3:0] g;
    wire[3:0] c;
    fa4 u_fa40(.a(a[3:0]), .b(b[3:0]), .cin(cin), .gout(g[0]), .pout(p[0]), .s(s[3:0]), .cout(cout[3:0]));
    fa4 u_fa41(.a(a[7:4]), .b(b[7:4]), .cin(c[0]), .gout(g[1]), .pout(p[1]), .s(s[7:4]), .cout(cout[7:4]));
    fa4 u_fa42(.a(a[11:8]), .b(b[11:8]), .cin(c[1]), .gout(g[2]), .pout(p[2]), .s(s[11:8]), .cout(cout[11:8]));
    fa4 u_fa43(.a(a[15:12]), .b(b[15:12]), .cin(c[2]), .gout(g[3]), .pout(p[3]), .s(s[15:12]), .cout(cout[15:12]));
    cla u_cla(.p(p), .g(g), .cin(cin), .cout(c), .gout(gout), .pout(pout));
endmodule
