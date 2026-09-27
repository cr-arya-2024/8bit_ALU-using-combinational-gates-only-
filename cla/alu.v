// ===============================================================
// TOP MODULE — CLA-OPTIMIZED VERSION (for DE2-115)
// Same ports as original/alu.v, so it's a drop-in replacement.
// Compile this together with every other .v file in this folder.
// ===============================================================
module alu (
    input CLOCK_50,
    input [15:0] SW,
    input [2:0]  KEY,
    output [7:0] LCD_DATA,
    output LCD_RS, LCD_RW, LCD_EN,
    output LCD_ON, LCD_BLON
);
    assign LCD_ON = 1'b1;
    assign LCD_BLON = 1'b1;

    wire [2:0] op_code = ~KEY;
    wire signed [15:0] result;
    wire [7:0] h, t, o;

    alu_8bit ALU_UNIT (
        .A(SW[7:0]),
        .B(SW[15:8]),
        .OP(op_code),
        .R(result)
    );

    bin_to_ascii B2A (
        .bin(result[7:0]),
        .h(h), .t(t), .o(o)
    );

    lcd_controller LCD_DISPLAY (
        .clk(CLOCK_50),
        .op_sel(op_code),
        .h(h), .t(t), .o(o),
        .LCD_DATA(LCD_DATA),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN)
    );
endmodule
