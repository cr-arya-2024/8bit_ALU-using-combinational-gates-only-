// ===============================================================
// 16-BIT CLA ADDER (two 8-bit CLA adders chained) — used by
// multiplier.v for its 16-bit partial-product accumulation.
// Depends on: cla_adder_8bit.v (and transitively cla_4bit.v)
// ===============================================================
module cla_adder_16bit (
    input  [15:0] a, b,
    input         cin,
    output [15:0] sum,
    output        cout
);
    wire c8;
    cla_adder_8bit LOW  (.a(a[7:0]),  .b(b[7:0]),  .cin(cin), .sum(sum[7:0]),  .cout(c8));
    cla_adder_8bit HIGH (.a(a[15:8]), .b(b[15:8]), .cin(c8),  .sum(sum[15:8]), .cout(cout));
endmodule
