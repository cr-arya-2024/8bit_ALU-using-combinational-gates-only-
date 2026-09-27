# =================================================================
# Timing constraints for the standalone alu_8bit top-level
# -----------------------------------------------------------------
# alu_8bit has no clock pin - it's a pure combinational block
# (A, B, OP in -> R out). TimeQuest needs a clock reference to run
# setup analysis, so we give it a "virtual" clock: one that isn't
# attached to any real pin, just used as a timing reference. The
# period here (20 ns) is arbitrary - Report Timing will show you
# the actual worst-case data delay regardless of what you pick,
# and that delay IS the number you want (the combinational
# propagation time through the ALU).
# =================================================================

create_clock -name virtual_clk -period 20.000

set_input_delay  -clock virtual_clk 0 [get_ports {A[*] B[*] OP[*]}]
set_output_delay -clock virtual_clk 0 [get_ports {R[*]}]

derive_clock_uncertainty
