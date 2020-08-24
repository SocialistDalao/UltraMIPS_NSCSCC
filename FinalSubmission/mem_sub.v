//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  ex2_sub
// File:    ex2_sub.v
// Author:
// E-mail:
// Description: 访存阶段
// Revision: 1.1
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem_sub(

	input rst,
	
	//来自执行阶段的信息	
	input[`RegAddrBus]     waddr_i,
	input                  we_i,
	input[`RegBus]         wdata_i,
	
	//送到回写阶段的信息
	output reg[`RegAddrBus]    waddr_o,
	output reg                 we_o,
	output reg[`RegBus]        wdata_o
	
);

    always @ (*) begin
        if (rst == `RstEnable) begin
            waddr_o = `NOPRegAddr;
            we_o = `WriteDisable;
            wdata_o = `ZeroWord;
        end else begin
            waddr_o = waddr_i;
            we_o = we_i;
            wdata_o = wdata_i;
        end
    end

endmodule