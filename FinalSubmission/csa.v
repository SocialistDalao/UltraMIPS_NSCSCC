//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/19 14:59:05
// Design Name: 
// Module Name: csa
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


module csa( // ������λ�ӷ���
    input[63:0] x, // ��һ������
    input[63:0] y, // �ڶ�������
    input[63:0] z, // ����������
    output[63:0] s, // ��
    output[63:0] c // ��λ
    );
    genvar i;
    generate
        for (i=0; i<64; i=i+1)
        begin: bit
            assign s[i] = x[i] ^ y[i] ^ z[i];
            assign c[i] = (x[i] & y[i]) | (y[i] & z[i]) | (z[i] & x[i]);
        end
    endgenerate
endmodule
