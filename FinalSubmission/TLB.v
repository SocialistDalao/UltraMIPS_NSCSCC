`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/25 16:03:16
// Design Name: 
// Module Name: TLB
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


module TLB(
    input wire [`DataAddrBus]virtual_addr_i,
    output wire [`DataAddrBus]physical_addr_o,
	output wire uncached
    );
    
	assign uncached = (virtual_addr_i[31:28] == 4'hB)?`Valid:
						(virtual_addr_i[31:28] == 4'hA)?`Valid
													 :`Invalid;
	assign physical_addr_o = (virtual_addr_i[31:28]==4'h8)||(virtual_addr_i[31:28]==4'h9)
									||(virtual_addr_i[31:28]==4'ha)||(virtual_addr_i[31:28]==4'hb)? 
										virtual_addr_i & {3'b0,29'h1fffffff}: virtual_addr_i ;

endmodule
