`include "defines.v"

module LLbit_reg(

    input clk,
    input rst,

    input flush,
    input flush_cause,

    input LLbit_i,
    input we,
	
    output reg LLbit_o
	
);


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            LLbit_o <= 1'b0;
        end else if (flush == `Flush && flush_cause == `Exception) begin
            LLbit_o <= 1'b0;
        end else if (we == `WriteEnable) begin
            LLbit_o <= LLbit_i;
        end
    end

endmodule