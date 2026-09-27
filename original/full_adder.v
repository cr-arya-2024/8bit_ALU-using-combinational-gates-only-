// ===============================================================
// FULL ADDER (1-bit)
// Basic combinational full adder, chained 8x in add_sub_8bit.v
// to build the ripple-carry adder.
// ===============================================================
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
