// ===============================================================
// 8-BIT HIERARCHICAL CARRY LOOK-AHEAD ADDER
// Two 4-bit CLA blocks + a block-level lookahead carry. Critical
// path is ~2 lookahead levels, not O(n) like a ripple-carry chain.
// Depends on: cla_4bit.v
// ===============================================================
module cla_adder_8bit (
    input  [7:0] a, b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    wire GG0, GP0, GG1, GP1;
    wire c4;

    cla_4bit BLOCK0 (.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .GG(GG0), .GP(GP0));
    assign c4 = GG0 | (GP0 & cin);

    cla_4bit BLOCK1 (.a(a[7:4]), .b(b[7:4]), .cin(c4), .sum(sum[7:4]), .GG(GG1), .GP(GP1));
    assign cout = GG1 | (GP1 & c4);
endmodule
