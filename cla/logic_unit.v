// ===============================================================
// LOGIC UNIT
// Bitwise AND / OR / XOR / NAND. Identical in both versions.
// ===============================================================
module logic_unit (
    input [7:0] a, b,
    input [1:0] sel,
    output reg [7:0] y
);
    always @(*) begin
        case (sel)
            2'b00: y = a & b;
            2'b01: y = a | b;
            2'b10: y = a ^ b;
            2'b11: y = ~(a & b);
        endcase
    end
endmodule
