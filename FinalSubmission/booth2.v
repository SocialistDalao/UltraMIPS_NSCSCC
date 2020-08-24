module booth2(
    input[32:0] x, // 被乘数
    input[2:0] y, // 乘数的三位
    output reg[63:0] z, // 部分积
    output reg[1:0] c // 进位
    );
    wire[32:0] x_neg;
    assign x_neg = ~x;
    always @ * begin
        case(y)
            3'b011: begin
                z = {{30{x[32]}}, x, 1'b0};
                c = 2'b00;
            end
            3'b100: begin
                z = {{30{x_neg[32]}}, x_neg, 1'b0};
                c = 2'b10;
            end
            3'b001, 3'b010: begin
                z = {{31{x[32]}}, x};
                c = 2'b00;
            end
            3'b101, 3'b110: begin
                z = {{31{x_neg[32]}}, x_neg};
                c = 2'b01;
            end
            default: begin
                z = 64'b0;
                c = 2'b00;
            end
        endcase
    end
endmodule
