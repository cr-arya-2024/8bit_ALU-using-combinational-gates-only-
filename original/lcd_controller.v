// ===============================================================
// LCD CONTROLLER (Enhanced for DE2-115)
// Identical in both versions.
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
                0: begin LCD_DATA <= 8'h38; LCD_RS <= 0; state <= 1; end
                1: begin LCD_DATA <= 8'h0C; LCD_RS <= 0; state <= 2; end
                2: begin LCD_DATA <= 8'h01; LCD_RS <= 0; state <= 3; end
                3: begin LCD_DATA <= 8'h06; LCD_RS <= 0; state <= 4; end
                4: begin LCD_DATA <= op_name[23:16]; LCD_RS <= 1; state <= 5; end
                5: begin LCD_DATA <= op_name[15:8];  LCD_RS <= 1; state <= 6; end
                6: begin LCD_DATA <= op_name[7:0];   LCD_RS <= 1; state <= 7; end
                7: begin LCD_DATA <= ":";            LCD_RS <= 1; state <= 8; end
                8: begin LCD_DATA <= " ";            LCD_RS <= 1; state <= 9; end
                9:  begin LCD_DATA <= h; LCD_RS <= 1; state <= 10; end
                10: begin LCD_DATA <= t; LCD_RS <= 1; state <= 11; end
                11: begin LCD_DATA <= o; LCD_RS <= 1; state <= 12; end
                12: begin LCD_DATA <= 8'h80; LCD_RS <= 0; state <= 4; end
                default: state <= 0;
            endcase
            LCD_EN <= 1;
        end else if (count == 20'h02000) begin
            LCD_EN <= 0;
        end
    end
endmodule
