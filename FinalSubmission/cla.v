//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/01 16:24:15
// Design Name: 
// Module Name: cla
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


module cla(
    input[3:0] p,
    input[3:0] g,
    input cin,
    output[3:0] cout,
    output gout,
    output pout
    );
    assign cout[0] = g[0] | (p[0] & cin);
    assign cout[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign cout[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign gout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign pout = p[0] & p[1] & p[2] & p[3];
    assign cout[3] = gout | (pout & cin);
endmodule
