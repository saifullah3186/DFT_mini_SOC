# Functional simulation of the un-instrumented design (needs iverilog).
# The Tessent steps are run separately - see README.md.
.PHONY: sim clean
sim:
	iverilog -g2005 -o sim.vvp tb/tb_mini_soc.v rtl/mini_soc.v library/memory/SYNC_1RW_64x8.v
	vvp sim.vvp | tee sim.log
	@grep -q "^PASS" sim.log   # tb prints FAIL but does not set an exit code
clean:
	rm -f sim.vvp sim.log
