# 8-bit ALU using Combinational Gates Only

## Overview

This project implements a fully functional 8-bit Arithmetic Logic Unit (ALU) using combinational logic gates in Verilog HDL. The ALU is designed for the **DE2-115 FPGA board** and includes an LCD display interface for real-time operation visualization.

Two implementations are included:

| Version | File | Adder | Multiplier | Divider |
|---|---|---|---|---|
| **Original** | `alu.v` | Ripple-carry | Behavioral shift-add | Behavioral repeated subtraction (up to 255 iterations) |
| **Optimized** | `alu_cla.v` | Hierarchical carry-look-ahead (CLA) | Structural shift-add (CLA-based accumulation) | Structural restoring division (8 stages, CLA-based subtractor) |

Both versions have identical top-level ports and are drop-in replacements for each other.

## Features

- **8 Operations**: Addition, Subtraction, Multiplication, Division, AND, OR, XOR, NAND
- **Pure Combinational Logic**: No sequential elements in core arithmetic operations
- **Signed Arithmetic**: Supports signed 8-bit integers using two's complement
- **LCD Display**: Real-time display of operation and results on 16x2 LCD
- **DE2-115 Compatible**: Optimized for Altera DE2-115 FPGA development board
- **Two arithmetic core implementations**, benchmarked against each other.

## Architecture

### Module Hierarchy

**Original (`alu.v`):**
```
alu (Top Module)
├── alu_8bit (8-bit ALU Core)
│   ├── add_sub_8bit (Ripple-carry Adder/Subtractor)
│   │   └── full_adder (1-bit Full Adder, chained x8)
│   ├── logic_unit (Logic Operations)
│   ├── multiplier (Behavioral shift-add, for-loop)
│   └── divider (Behavioral repeated subtraction, for-loop, up to 255 iterations)
├── bin_to_ascii (Binary to ASCII Converter)
└── lcd_controller (LCD Display Driver)
```

**Optimized (`alu_cla.v`):**
```
alu (Top Module)
├── alu_8bit (8-bit ALU Core)
│   ├── add_sub_8bit (CLA-based Adder/Subtractor)
│   │   └── cla_adder_8bit (Two 4-bit CLA blocks + block-level lookahead)
│   │       └── cla_4bit (x2 — generate/propagate carry logic)
│   ├── logic_unit (Logic Operations, unchanged)
│   ├── multiplier_cla (Structural shift-add array multiplier)
│   │   └── cla_adder_16bit (x8 — one per partial-product accumulation stage)
│   └── divider_cla (Structural restoring divider, 8 stages)
│       └── add_sub_9bit_cla (x8 — CLA-based subtract/compare per stage)
├── bin_to_ascii (Binary to ASCII Converter, unchanged)
└── lcd_controller (LCD Display Driver, unchanged)
```

### Supported Operations

| Opcode | Operation | Description |
| ------ | --------- | ----------- |
| 3'b000 | ADD       | A + B       |
| 3'b001 | SUB       | A - B       |
| 3'b010 | MUL       | A × B       |
| 3'b011 | DIV       | A ÷ B       |
| 3'b100 | AND       | A & B       |
| 3'b101 | OR        | A \| B      |
| 3'b110 | XOR       | A ^ B       |
| 3'b111 | NAND      | ~(A & B)    |

## Performance Optimization

The original design's ripple-carry adder and iterative multiplier/divider are simple and easy to follow, but neither is built for speed:
- The ripple-carry adder's critical path grows linearly (O(n)) with bit-width, since each bit's carry-out depends on the previous bit's carry-out resolving first.
- The original divider computes its result by repeated subtraction in a `for` loop bounded at 255 iterations — functionally correct, but it synthesizes into a very large chain of unrolled combinational subtraction stages.

The optimized version (`alu_cla.v`) replaces these with:
- A **hierarchical carry-look-ahead (CLA) adder**: two 4-bit CLA blocks, each computing its carries directly from generate/propagate terms, plus a second-level block carry — critical path is ~2 lookahead levels instead of 8 rippled stages.
- A **structural shift-add multiplier** built from 8 chained 16-bit CLA adders (one per partial product), instead of a behavioral `+` loop.
- A **structural restoring divider**: one subtract-and-compare stage per output bit (8 stages total), each built from a 9-bit CLA subtractor, instead of the original's up-to-255-iteration repeated-subtraction loop.

### Code Quality: No Latch Inference

Beyond the timing/area numbers, there's a synthesis-quality difference worth noting. Compiling the original `divider`/`multiplier` in Quartus produces warnings like:

```
Warning (10240): Verilog HDL Always Construct warning at divider(...): inferring latch(es) for variable "x", which holds its previous value in one or more paths through the always block
```

This happens because their `for`-loop-based `always` blocks (using variables like `x`, `d_val`, `i`) don't assign every signal on every possible path, so the synthesizer inserts a latch to hold the "previous value" on the unhandled paths — usually still functionally correct here, but it's a code smell and not something you want in a supposedly pure-combinational design.

The CLA version's `multiplier_cla` and `divider_cla` are built entirely from `generate` loops instantiating adders structurally (continuous assignments and module instances, not iterative `always`-block logic), so there's no ambiguous "what if this path doesn't assign it" case for the tool to worry about. Compiling `alu_cla.v` produces **zero latch-inference warnings**.

### Verification
Correctness was checked with [Icarus Verilog](http://iverilog.icarus.com/) ( `tb_alu_cla.v`):


Run :
```bash
iverilog -o sim.out alu_cla.v tb_alu_cla.v
vvp sim.out
```

### Results

Measured in Quartus Prime Lite (20.1) targeting a Cyclone IV E (EP4CE115F29C7, the DE2-115's actual device), using TimeQuest Timing Analyzer with a virtual clock constraint on the standalone `alu_8bit` core (see [How to Reproduce](#how-to-reproduce-the-timing-results) below):

| Metric | Original (`alu.v`) | Optimized (`alu_cla.v`) | Improvement |
|---|---:|---:|---:|
| Fmax (Slow 1200mV 85°C model) | 0.84 MHz | 32.96 MHz | **≈39×** |
| Total logic elements | ≈17,470 | 591 | **≈97% reduction** |

**Important context on where the gain comes from:** the divider is the dominant factor in both numbers above. The original divider's repeated-subtraction loop unrolls into roughly 255 chained combinational stages in hardware; the restoring divider does the same job in 8 structural stages — this accounts for most of the ≈30× drop in logic element count and a large share of the Fmax improvement. The CLA adder's own contribution was verified independently: it is bit-for-bit identical to the ripple-carry adder in function (see Verification above), and its logic-depth reduction (O(log n) vs O(n) lookahead) is real but smaller in absolute terms at 8 bits than the divider's algorithmic change from O(255) to O(8) stages. Framed accurately, this is as much an **algorithmic complexity improvement in the divider** as it is a **classic CLA-vs-ripple-carry comparison** in the adder.

### How to Reproduce the Timing Results

1. Create a Quartus project targeting **Cyclone IV E, EP4CE115F29C7** (or your actual board's device).
2. Add `alu_cla.v` (or `alu.v` for the baseline) to the project.
3. Set **`alu_8bit`** as the top-level entity (not the full `alu` top with the LCD controller) — `alu_8bit` is purely combinational with no clock pin, so an accurate combinational-delay measurement needs a virtual clock reference rather than a real one.
4. Add an SDC file with:
   ```tcl
   create_clock -name virtual_clk -period 20.000
   set_input_delay  -clock virtual_clk 0 [get_ports {A[*] B[*] OP[*]}]
   set_output_delay -clock virtual_clk 0 [get_ports {R[*]}]
   derive_clock_uncertainty
   ```
5. Compile, then in TimeQuest Timing Analyzer: **Slow 1200mV 85°C Model → Fmax Summary**.
6. Repeat with the other `.v` file (same SDC, same top-level) for the comparison.


## Implementation Details

### 1. Full Adder / CLA Adder

- **Original**: Pure combinational full adder (XOR/AND gates), chained 8x via ripple carry.
- **Optimized**: Two 4-bit carry-look-ahead blocks with block-level lookahead carry — see `cla_4bit` and `cla_adder_8bit` in `alu_cla.v`.

### 2. Adder/Subtractor

- Ripple carry (original) or CLA (optimized), with configurable subtraction mode via B-input inversion and two's-complement arithmetic — same interface either way.

### 3. Multiplier

- **Original**: Behavioral shift-and-add via a `for` loop.
- **Optimized**: Structural array multiplier — 8 partial products, accumulated through 8 chained `cla_adder_16bit` instances.

### 4. Divider

- **Original**: Iterative (repeated-subtraction) division, up to 255 loop iterations.
- **Optimized**: Structural restoring division — 8 stages (one per output bit), each a 9-bit CLA subtract-and-compare.
- Both handle signed division with proper sign management; division by zero returns 0.

### 5. Logic Unit

- Implements bitwise operations: AND, OR, XOR, NAND (unchanged between versions).

### 6. LCD Controller

- State machine-based controller (unchanged between versions).
- Automatically initializes LCD on startup, displays operation name and result, updates continuously.

## Usage

### Simulation

1. Use `tb_alu_cla.v` as a starting point, or write your own testbench.
2. Instantiate the `alu` module (or `alu_8bit` directly for arithmetic-only testing).
3. Apply test vectors to `SW`/`KEY` (or `A`/`B`/`OP` for `alu_8bit`).
4. Monitor the `result`/`R` output.

### FPGA Implementation

1. **Create Project**: Open Quartus II/Prime and create a new project targeting your board's device.
2. **Add Source**: Add `alu.v` or `alu_cla.v` to your project (not both — they define modules with the same names).
3. **Pin Assignment**: Assign pins according to your board's pin mapping.
4. **Compile**: Compile the design.
5. **Program**: Download to FPGA using USB Blaster.
6. **Test**: Use switches to input operands and keys to select operations.

### Example Operation

```
// Example: 5 + 3
SW[7:0] = 8'd5;    // Input A = 5
SW[15:8] = 8'd3;   // Input B = 3
KEY[2:0] = 3'b111; // Active low, so 000 → ADD operation
// Result displayed on LCD: "ADD: 008"
```

## File Structure

```
.
├── alu.v              # Original implementation (ripple-carry adder, behavioral mult/div)
├── alu_cla.v           # Optimized implementation (CLA adder, structural mult/div)
├── tb_alu_cla.v        # Verification testbench (exhaustive adder check + targeted ALU checks)
├── README.md           # This file
└── images/             # Diagrams and demo photos
```

## Technical Specifications

- **Data Width**: 8-bit inputs, 16-bit output
- **Number Format**: Two's complement signed integers
- **Input Range**: -128 to +127
- **Output Range**: -32768 to +32767 (for multiplication)
- **Clock Frequency**: 50 MHz (LCD controller only — arithmetic core is combinational)
- **LCD Update Rate**: Continuous refresh

## Design Principles

- **Modularity**: Each functional block is a separate module
- **Reusability**: Adder/subtractor logic is reused wherever addition or subtraction is needed
- **Parameterization**: Generate statements for scalable designs
- **Combinational Focus**: Core ALU operations are purely combinational
- **Measured, not assumed, performance**: The optimization above is backed by actual TimeQuest Fmax data and an exhaustive functional-equivalence check, not just theoretical big-O reasoning

## Limitations

- LCD displays only lower 8 bits of result
- No overflow/underflow flags
- Limited to 8-bit operands
- The optimized divider's Fmax gain is dominated by its algorithmic change (255-iteration repeated subtraction → 8-stage restoring division); the CLA adder's own isolated contribution is smaller and was not separately decomposed from the divider's effect in the headline numbers above

## Future Enhancements

- [x] Carry-look-ahead adder
- [x] Structural (non-behavioral) multiplier and divider
- [ ] Add status flags (Zero, Carry, Overflow, Sign)
- [ ] Implement Booth's algorithm for the multiplier
- [ ] Add shift and rotate operations
- [ ] Extend to 16-bit or 32-bit operations
- [ ] Add pipeline stages for higher clock frequencies
- [ ] Implement full 16-bit result display on LCD
- [ ] Isolate the CLA adder's individual Fmax contribution from the divider's algorithmic change

## Testing

To verify the design:

1. Run `tb_alu_cla.v` (see [Verification](#verification) above) for functional correctness.
2. Test each operation with positive and negative numbers.
3. Check edge cases: -128, 0, +127.
4. Verify division by zero handling.
5. Test LCD display refresh.
6. Validate timing constraints in Quartus TimeQuest (see [How to Reproduce](#how-to-reproduce-the-timing-results)).


## FPGA Implementation

### Block Diagram

The following shows the functional block diagram of the ALU:

[![Block Diagram](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/block_diagram.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/block_diagram.png.png)

*Functional block diagram showing ALU components and data flow*

### RTL Schematic

RTL schematic generated by Quartus Prime:

[![RTL Schematic](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/rtl_schematic.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/rtl_schematic.png.png)

*RTL view of the 8-bit ALU design*

## Project Demonstration

Below are photos demonstrating all 8 operations of the ALU running on the DE2-115 board with real-time LCD display:

### Addition Operation

[![Addition](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/addition.jpg.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/addition.jpg.png)

*Addition operation: Displaying result on LCD*

### Subtraction Operation

[![Subtraction](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/subtraction.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/subtraction.png.png)

*Subtraction operation: A - B with LCD output*

### Multiplication Operation

[![Multiplication](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/multiplication.jpg.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/multiplication.jpg.png)

*Multiplication operation: A × B displayed on LCD*

### Division Operation

[![Division](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/division.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/division.png.png)

*Division operation: A ÷ B with quotient display*

### AND Operation

[![AND](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/and.jpg.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/and.jpg.png)

*Bitwise AND operation with result visualization*

### OR Operation

[![OR](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/or.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/or.png.png)

*Bitwise OR operation displayed on LCD*

### XOR Operation

[![XOR](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/xor.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/xor.png.png)

*Bitwise XOR operation with real-time output*

### NAND Operation

[![NAND](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/nand.jpg.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/nand.jpg.png)

*NAND operation: Negated AND result on LCD*

## Simulation Results

### Timing Waveforms

[![Simulation Waveforms](https://github.com/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/raw/main/images/simulation.png.png)](/cr-arya-2024/8bit_ALU-using-combinational-gates-only-/blob/main/images/simulation.png.png)

*Simulation results showing correct operation for all ALU functions*

### Timing Analysis Results (New — CLA Optimization)

If you added screenshots of the Fmax comparison and logic-element counts from Quartus (see [Results](#results) above), reference them here the same way, e.g.:

```markdown
![Fmax Comparison](images/fmax_comparison.png)
*Fmax Summary: 0.84 MHz (original) vs 32.96 MHz (CLA-optimized)*
```

---
