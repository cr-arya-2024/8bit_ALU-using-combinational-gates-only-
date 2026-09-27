// ===============================================================
// 8-BIT ADDER / SUBTRACTOR (RIPPLE-CARRY)
// Chains 8 full_adder instances. Critical path grows linearly
// with bit-width since each stage waits on the previous carry.
// ===============================================================
module add_sub_8bit (
    input  [7:0] a, b,
    input        sub,
    output [7:0] result
);
    wire [8:0] c;
    wire [7:0] bx;
    assign c[0] = sub;

    genvar i;
    generate
        for (i=0;i<8;i=i+1) begin : ADD
            assign bx[i] = sub ? ~b[i] : b[i];
            full_adder FA (a[i], bx[i], c[i], result[i], c[i+1]);
        end
    endgenerate
endmodule
