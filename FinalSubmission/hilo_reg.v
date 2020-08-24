`include "defines.v"

module hilo_reg(

	input clk,
	input rst,
	
	//Ð´¶Ë¿Ú
	input we,
	input [`RegBus] hi_i,
	input [`RegBus] lo_i,
	
	//¶Á¶Ë¿Ú1
	output reg[`RegBus] hi_o,
	output reg[`RegBus] lo_o
	
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if((we == `WriteEnable)) begin
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end

endmodule
