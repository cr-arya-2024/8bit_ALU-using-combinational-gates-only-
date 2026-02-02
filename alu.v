// ===============================================================
// FULL ADDER
// ===============================================================
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

// ===============================================================
// 8-BIT ADDER / SUBTRACTOR
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

// ===============================================================
// LOGIC UNIT
// ===============================================================
module logic_unit (
    input [7:0] a, b,
    input [1:0] sel,
    output reg [7:0] y
);
    always @(*) begin
        case (sel)
            2'b00: y = a & b;
            2'b01: y = a | b;
            2'b10: y = a ^ b;
            2'b11: y = ~(a & b);
        endcase
    end
endmodule

// ===============================================================
// MULTIPLIER
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

// ===============================================================
// DIVIDER
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

// ===============================================================
// ALU (8 OPERATIONS)
// ===============================================================
module alu_8bit (
    input  signed [7:0] A, B,
    input  [2:0] OP,
    output reg signed [15:0] R
);
    wire [7:0] addsub, logic;
    wire signed [15:0] mul, div;

    add_sub_8bit AS (A, B, OP[0], addsub);
    logic_unit   LU (A, B, OP[1:0], logic);
    multiplier   M  (A, B, mul);
    divider      D  (A, B, div);

    always @(*) begin
        case (OP)
            3'b000: R = {{8{addsub[7]}}, addsub}; // ADD
            3'b001: R = {{8{addsub[7]}}, addsub}; // SUB
            3'b010: R = mul;
            3'b011: R = div;
            3'b100: R = {8'b0, logic};            // AND
            3'b101: R = {8'b0, logic};            // OR
            3'b110: R = {8'b0, logic};            // XOR
            3'b111: R = {8'b0, logic};            // NAND
        endcase
    end
endmodule

// ===============================================================
// BINARY TO ASCII (Conversion for LCD)
// ===============================================================
module bin_to_ascii (
    input [7:0] bin,
    output [7:0] h, t, o
);
    assign h = (bin/100) + 8'd48;
    assign t = ((bin%100)/10) + 8'd48;
    assign o = (bin%10) + 8'd48;
endmodule

// ===============================================================
// LCD CONTROLLER (Enhanced for DE2-115)
// ===============================================================
module lcd_controller (
    input clk,
    input [2:0] op_sel,
    input [7:0] h, t, o,
    output reg [7:0] LCD_DATA,
    output reg LCD_RS, LCD_RW, LCD_EN
);
    reg [5:0] state = 0;
    reg [19:0] count = 0;
    reg [23:0] op_name;

    // Convert Op-code to 3-character ASCII string
    always @(*) begin
        case (op_sel)
            3'b000: op_name = "ADD";
            3'b001: op_name = "SUB";
            3'b010: op_name = "MUL";
            3'b011: op_name = "DIV";
            3'b100: op_name = "AND";
            3'b101: op_name = "OR ";
            3'b110: op_name = "XOR";
            3'b111: op_name = "NAN";
            default: op_name = "ALU";
        endcase
    end

    always @(posedge clk) begin
        count <= count + 1;
        if (count == 0) begin
            LCD_RW <= 0;
            case (state)
                // --- Initialization ---
                0: begin LCD_DATA <= 8'h38; LCD_RS <= 0; state <= 1; end // 8-bit mode
                1: begin LCD_DATA <= 8'h0C; LCD_RS <= 0; state <= 2; end // Display On
                2: begin LCD_DATA <= 8'h01; LCD_RS <= 0; state <= 3; end // Clear
                3: begin LCD_DATA <= 8'h06; LCD_RS <= 0; state <= 4; end // Entry mode
                
                // --- Display Operation ---
                4: begin LCD_DATA <= op_name[23:16]; LCD_RS <= 1; state <= 5; end
                5: begin LCD_DATA <= op_name[15:8];  LCD_RS <= 1; state <= 6; end
                6: begin LCD_DATA <= op_name[7:0];   LCD_RS <= 1; state <= 7; end
                7: begin LCD_DATA <= ":";            LCD_RS <= 1; state <= 8; end
                8: begin LCD_DATA <= " ";            LCD_RS <= 1; state <= 9; end
                
                // --- Display Result ---
                9:  begin LCD_DATA <= h; LCD_RS <= 1; state <= 10; end
                10: begin LCD_DATA <= t; LCD_RS <= 1; state <= 11; end
                11: begin LCD_DATA <= o; LCD_RS <= 1; state <= 12; end
                
                // --- Loop back to update ---
                12: begin LCD_DATA <= 8'h80; LCD_RS <= 0; state <= 4; end // Force cursor to start
                default: state <= 0;
            endcase
            LCD_EN <= 1;
        end else if (count == 20'h02000) begin
            LCD_EN <= 0; // Create the falling edge pulse for LCD
        end
    end
endmodule

// ===============================================================
// TOP MODULE
// ===============================================================
module alu (
    input CLOCK_50,
    input [15:0] SW,         // SW[7:0]=A, SW[15:8]=B
    input [2:0]  KEY,        // Operation Select
    output [7:0] LCD_DATA,
    output LCD_RS, LCD_RW, LCD_EN,
    output LCD_ON, LCD_BLON  // Power and Backlight pins
);
    // Fixed Hardware Pins for DE2-115
    assign LCD_ON = 1'b1;
    assign LCD_BLON = 1'b1;

    wire [2:0] op_code = ~KEY; // Keys are active-low
    wire signed [15:0] result;
    wire [7:0] h, t, o;

    // ALU Logic
    alu_8bit ALU_UNIT (
        .A(SW[7:0]), 
        .B(SW[15:8]), 
        .OP(op_code), 
        .R(result)
    );

    // BCD Conversion (Showing lower 8 bits of result)
    bin_to_ascii B2A (
        .bin(result[7:0]), 
        .h(h), .t(t), .o(o)
    );

    // LCD Controller
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