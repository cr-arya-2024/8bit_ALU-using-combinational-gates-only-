// ===============================================================
// ALU (8 OPERATIONS) — CLA-OPTIMIZED VERSION
// Uses CLA-based adder/subtractor, structural multiplier, and
// structural divider instead of ripple-carry / behavioral loops.
// Depends on: add_sub_8bit.v, logic_unit.v, multiplier.v, divider.v
// (and transitively all the cla_*.v files)
// ===============================================================
module alu_8bit (
    input  signed [7:0] A, B,
    input  [2:0] OP,
    output reg signed [15:0] R
);
    wire [7:0] addsub, logic_out;
    wire signed [15:0] mul, div;

    add_sub_8bit AS (.a(A), .b(B), .sub(OP[0]), .result(addsub));
    logic_unit   LU (A, B, OP[1:0], logic_out);
    multiplier   M  (.a(A), .b(B), .y(mul));
    divider      D  (.a(A), .b(B), .y(div));

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
