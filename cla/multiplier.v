// ===============================================================
// STRUCTURAL SHIFT-ADD MULTIPLIER USING CLA ADDERS
// 8x8 -> 16-bit combinational array multiplier: one
// cla_adder_16bit per partial product, chained. Handles signed
// operands via two's-complement conversion at the boundary.
// Fully structural (generate loops instantiating adders, no
// iterative always-block state) — this is why it produces no
// latch-inference warnings, unlike the original behavioral loop.
// Depends on: cla_adder_16bit.v (and transitively cla_adder_8bit.v, cla_4bit.v)
// ===============================================================
module multiplier (
    input  signed [7:0] a, b,
    output reg signed [15:0] y
);
    wire [7:0] au = a[7] ? (~a + 1'b1) : a;
    wire [7:0] bu = b[7] ? (~b + 1'b1) : b;
    wire        sign_y = a[7] ^ b[7];

    wire [15:0] pp  [0:7];
    wire [15:0] acc [0:8];
    wire        dummy_cout [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : PP
            assign pp[i] = bu[i] ? ({8'b0, au} << i) : 16'b0;
        end
    endgenerate

    assign acc[0] = 16'b0;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ACC
            cla_adder_16bit STAGE (
                .a(acc[i]), .b(pp[i]), .cin(1'b0),
                .sum(acc[i+1]), .cout(dummy_cout[i])
            );
        end
    endgenerate

    wire [15:0] mag_y = acc[8];
    always @(*) begin
        y = sign_y ? (~mag_y + 1'b1) : mag_y;
    end
endmodule
