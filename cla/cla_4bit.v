// ===============================================================
// 4-BIT CARRY LOOK-AHEAD BLOCK
// Computes sum[3:0] and internal carries directly from bit-level
// P/G terms instead of rippling through 4 full adders. Exports
// block-level Group Generate (GG) / Group Propagate (GP) so
// cla_adder_8bit.v can chain blocks with a second-level lookahead
// instead of rippling between blocks too.
// ===============================================================
module cla_4bit (
    input  [3:0] a, b,
    input        cin,
    output [3:0] sum,
    output       GG,
    output       GP
);
    wire [3:0] p, g;
    wire [3:1] c;

    assign p = a ^ b;
    assign g = a & b;

    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);

    assign sum = p ^ {c[3:1], cin};

    assign GG = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign GP = p[3] & p[2] & p[1] & p[0];
endmodule
