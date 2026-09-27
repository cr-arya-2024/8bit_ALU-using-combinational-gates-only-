// ===============================================================
// 8-BIT ADDER / SUBTRACTOR (CLA VERSION)
// Same name/port list as the original ripple-carry module, so it
// slots into alu_8bit.v without any other changes.
// Depends on: cla_adder_8bit.v (and transitively cla_4bit.v)
// ===============================================================
module add_sub_8bit (
    input  [7:0] a, b,
    input        sub,
    output [7:0] result
);
    wire [7:0] bx = sub ? ~b : b;
    wire       cout_unused;
    cla_adder_8bit ADD (.a(a), .b(bx), .cin(sub), .sum(result), .cout(cout_unused));
endmodule
