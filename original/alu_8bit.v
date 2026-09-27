// ===============================================================
// ALU (8 OPERATIONS) — ORIGINAL VERSION
// Uses ripple-carry add_sub_8bit + behavioral multiplier/divider.
// ===============================================================
module alu_8bit (
    input  signed [7:0] A, B,
    input  [2:0] OP,
    output reg signed [15:0] R
);
    wire [7:0] addsub, logic_out;
    wire signed [15:0] mul, div;

    add_sub_8bit AS (A, B, OP[0], addsub);
    logic_unit   LU (A, B, OP[1:0], logic_out);
    multiplier   M  (A, B, mul);
    divider      D  (A, B, div);

    always @(*) begin
        case (OP)
            3'b000: R = {{8{addsub[7]}}, addsub}; // ADD
            3'b001: R = {{8{addsub[7]}}, addsub}; // SUB
            3'b010: R = mul;
            3'b011: R = div;
            3'b100: R = {8'b0, logic_out};        // AND
            3'b101: R = {8'b0, logic_out};        // OR
            3'b110: R = {8'b0, logic_out};        // XOR
            3'b111: R = {8'b0, logic_out};        // NAND
        endcase
    end
endmodule
