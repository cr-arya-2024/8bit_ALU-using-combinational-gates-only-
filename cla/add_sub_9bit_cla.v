// ===============================================================
// 9-BIT ADD/SUB (CLA), built by reusing cla_adder_8bit for the low
// 8 bits. Needed by divider.v: a shifted remainder can briefly
// exceed 8 bits. Bit 8 is a single full-adder equation — at 1-bit
// width there's no ripple to eliminate in the first place, so
// there's nothing to "look ahead" over; the lookahead saving all
// happens in the reused 8-bit block below it.
// Depends on: cla_adder_8bit.v (and transitively cla_4bit.v)
// ===============================================================
module add_sub_9bit_cla (
    input  [8:0] a, b,
    input        sub,
    output [8:0] result,
    output       cout
);
    wire [8:0] bx = sub ? ~b : b;
    wire       c8;

    cla_adder_8bit LOW8 (.a(a[7:0]), .b(bx[7:0]), .cin(sub), .sum(result[7:0]), .cout(c8));

    assign result[8] = a[8] ^ bx[8] ^ c8;
    assign cout       = (a[8] & bx[8]) | (c8 & (a[8] ^ bx[8]));
endmodule
