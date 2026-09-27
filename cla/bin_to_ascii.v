// ===============================================================
// BINARY TO ASCII (Conversion for LCD)
// Identical in both versions.
// ===============================================================
module bin_to_ascii (
    input [7:0] bin,
    output [7:0] h, t, o
);
    assign h = (bin/100) + 8'd48;
    assign t = ((bin%100)/10) + 8'd48;
    assign o = (bin%10) + 8'd48;
endmodule
