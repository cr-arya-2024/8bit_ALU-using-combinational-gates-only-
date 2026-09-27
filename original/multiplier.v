// ===============================================================
// MULTIPLIER (BEHAVIORAL SHIFT-ADD)
// Note: the `for` loop here doesn't assign every path on every
// iteration, which is why Quartus reports latch-inference
// warnings when this compiles. See cla/multiplier.v for the
// structural fix.
// ===============================================================
module multiplier (
    input signed [7:0] a, b,
    output reg signed [15:0] y
);
    integer i;
    always @(*) begin
        y = 0;
        for (i=0;i<8;i=i+1)
            if (b[i]) y = y + (a <<< i);
    end
endmodule
