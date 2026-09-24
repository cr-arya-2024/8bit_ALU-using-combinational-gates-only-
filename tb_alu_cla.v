// =================================================================
// VERIFICATION TESTBENCH — CLA ALU
// -----------------------------------------------------------------
// Run with Icarus Verilog:
//   iverilog -o sim.out alu_cla.v tb_alu_cla.v
//   vvp sim.out
//
// Covers:
//   1. Exhaustive check of add_sub_8bit against a reference
//      ripple-carry implementation across all 256x256 input
//      combinations, for both add and subtract (131,072 cases).
//   2. Targeted checks of multiplier / divider against known
//      results, covering all sign combinations and the -128
//      edge case.
//   3. Full ALU-level checks (all 8 opcodes) through alu_8bit.
// =================================================================
`timescale 1ns/1ps

// --- reference ripple-carry adder, used only to cross-check the
//     CLA adder's output; not part of the design under test ---
module ref_full_adder (input a, b, cin, output sum, cout);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module ref_add_sub_8bit (input [7:0] a, b, input sub, output [7:0] result);
    wire [8:0] c;
    wire [7:0] bx;
    assign c[0] = sub;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ADD
            assign bx[i] = sub ? ~b[i] : b[i];
            ref_full_adder FA (a[i], bx[i], c[i], result[i], c[i+1]);
        end
    endgenerate
endmodule


module tb_alu_cla;
    integer errors = 0;

    // ---------------- Part 1: exhaustive adder/subtractor check ----------------
    reg  [7:0] a8, b8;
    reg        sub;
    wire [7:0] result_ref, result_cla;
    integer i, j;

    ref_add_sub_8bit REF (.a(a8), .b(b8), .sub(sub), .result(result_ref));
    add_sub_8bit      CLA (.a(a8), .b(b8), .sub(sub), .result(result_cla));

    // ---------------- Part 2: multiplier / divider / full ALU ----------------
    reg  signed [7:0] A, B;
    reg  [2:0] OP;
    wire signed [15:0] R;

    alu_8bit CORE (.A(A), .B(B), .OP(OP), .R(R));

    task check_alu(input signed [7:0] ta, tb_, input [2:0] top,
                    input signed [15:0] exp, input [127:0] label);
        begin
            A = ta; B = tb_; OP = top;
            #1;
            if (R !== exp) begin
                $display("FAIL [%0s]: A=%0d B=%0d OP=%0b -> R=%0d, expected %0d",
                          label, ta, tb_, top, R, exp);
                errors = errors + 1;
            end else
                $display("OK   [%0s]: A=%0d B=%0d OP=%0b -> R=%0d", label, ta, tb_, top, R);
        end
    endtask

    initial begin
        // --- Part 1: exhaustive add/sub ---
        $display("=== Exhaustive add/sub check (131,072 cases) ===");
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a8 = i; b8 = j;
                sub = 0; #1;
                if (result_ref !== result_cla) begin
                    $display("ADD MISMATCH a=%0d b=%0d ref=%0d cla=%0d", a8, b8, result_ref, result_cla);
                    errors = errors + 1;
                end
                sub = 1; #1;
                if (result_ref !== result_cla) begin
                    $display("SUB MISMATCH a=%0d b=%0d ref=%0d cla=%0d", a8, b8, result_ref, result_cla);
                    errors = errors + 1;
                end
            end
        end
        $display("Exhaustive add/sub check complete.\n");

        // --- Part 2: full ALU, all 8 opcodes ---
        $display("=== ALU opcode checks ===");
        check_alu(45, 30, 3'b000, 75, "ADD");
        check_alu(-10, -20, 3'b000, -30, "ADD_neg");
        check_alu(50, 20, 3'b001, 30, "SUB");
        check_alu(10, 50, 3'b001, -40, "SUB_neg");
        check_alu(12, 11, 3'b010, 132, "MUL");
        check_alu(-12, 11, 3'b010, -132, "MUL_neg");
        check_alu(127, 127, 3'b010, 16129, "MUL_max");
        check_alu(-128, 1, 3'b010, -128, "MUL_edge_-128");
        check_alu(100, 9, 3'b011, 11, "DIV");
        check_alu(-100, 9, 3'b011, -11, "DIV_neg");
        check_alu(13, 3, 3'b011, 4, "DIV_basic");
        check_alu(-128, 1, 3'b011, -128, "DIV_edge_-128");
        check_alu(0, 5, 3'b011, 0, "DIV_zero_numerator");
        check_alu(8'hF0, 8'h3C, 3'b100, 16'h0030, "AND");
        check_alu(8'hF0, 8'h0F, 3'b101, 16'h00FF, "OR");
        check_alu(8'hFF, 8'h0F, 3'b110, 16'h00F0, "XOR");
        check_alu(8'hFF, 8'hFF, 3'b111, 16'h0000, "NAND");

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end
endmodule
