// ===============================================================
// DIVIDER (BEHAVIORAL REPEATED SUBTRACTION)
// Up to 255 loop iterations, unrolled by the synthesizer into a
// very large chain of combinational subtraction stages
// (~17,470 logic elements in the full ALU on a Cyclone IV E).
// See cla/divider.v for the structural 8-stage replacement.
// ===============================================================
module divider (
    input signed [7:0] a, b,
    output reg signed [15:0] y
);
    reg signed [15:0] x, d_val;
    integer i;
    always @(*) begin
        if (b == 0) y = 0;
        else begin
            x = (a < 0) ? -a : a;
            d_val = (b < 0) ? -b : b;
            y = 0;
            for (i=0;i<255;i=i+1)
                if (x >= d_val) begin
                    x = x - d_val;
                    y = y + 1;
                end
            if (a[7] ^ b[7]) y = -y;
        end
    end
endmodule
