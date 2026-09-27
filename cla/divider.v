// ===============================================================
// STRUCTURAL RESTORING DIVIDER USING CLA SUBTRACTOR
// One subtract-and-compare per output bit (8 stages), each built
// from add_sub_9bit_cla, instead of the original's up-to-255-
// iteration repeated-subtraction loop. Uses the single-register
// shift trick: `quo` starts holding the dividend; as each bit gets
// shifted out of its MSB into the remainder, the freed LSB
// position is filled with the new quotient bit.
// Fully structural (generate loop instantiating subtractors, no
// iterative always-block state) — this is why it produces no
// latch-inference warnings, unlike the original behavioral loop.
// Depends on: add_sub_9bit_cla.v (and transitively cla_adder_8bit.v, cla_4bit.v)
// ===============================================================
module divider (
    input  signed [7:0] a, b,
    output reg signed [15:0] y
);
    wire [7:0] au = a[7] ? (~a + 1'b1) : a;
    wire [7:0] bu = b[7] ? (~b + 1'b1) : b;
    wire       sign_y = a[7] ^ b[7];
    wire [8:0] bu9 = {1'b0, bu};

    wire [8:0] rem [0:8];
    wire [7:0] quo [0:8];

    assign rem[0] = 9'b0;
    assign quo[0] = au;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : DIV_STAGE
            wire [8:0] shifted_rem = {rem[i][7:0], quo[i][7]};
            wire [8:0] sub_result;
            wire       stage_cout;

            add_sub_9bit_cla SUB (
                .a(shifted_rem), .b(bu9), .sub(1'b1),
                .result(sub_result), .cout(stage_cout)
            );
            assign rem[i+1] = stage_cout ? sub_result : shifted_rem;
            assign quo[i+1] = {quo[i][6:0], stage_cout};
        end
    endgenerate

    wire [7:0] mag_y = quo[8];

    always @(*) begin
        if (b == 0) y = 0;
        else        y = sign_y ? -{8'b0, mag_y} : {8'b0, mag_y};
    end
endmodule
