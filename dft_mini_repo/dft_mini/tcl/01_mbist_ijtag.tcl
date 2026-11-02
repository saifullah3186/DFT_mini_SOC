# =============================================================================
# STEP 1 : MemoryBIST + IJTAG network       (Tessent Shell 2022.4, design_id rtl1)
#   run :  tessent -shell -dofile tcl/01_mbist_ijtag.tcl
#   opt :  setenv TCELLLIB <your .tcelllib>   (read if set)
#          setenv RUN_SIM 1                    (run Questa testbench at the end)
# Each sub-step writes its own report to reports/01*.rpt so you can read them
# in order and see exactly what changed.
# =============================================================================
file mkdir reports

proc rpt {name} { set_logfile_handling reports/$name.rpt -replace }
# run a command, but do not abort the dofile if an optional report fails
proc safe_run {cmd} {
  if {[catch {uplevel 1 $cmd} msg]} { puts "// SKIPPED optional: $cmd -> $msg" }
}

# ---- 1a. load libraries + design --------------------------------------------
rpt 01a_load
set_context dft -rtl -design_id rtl1
set_tsdb_output_directory ./tsdb
if {[info exists ::env(TCELLLIB)]} { read_cell_library $::env(TCELLLIB) }
set_design_sources -format tcd_memory -y ./library/memory -extension tcd_memory
set_design_sources -format verilog -v ./library/memory/SYNC_1RW_64x8.v
read_verilog ./rtl/mini_soc.v
set_current_design mini_soc
report_design_sources
report_config_data -partition tcd -levels 1
report_memory_instances

# ---- 1b. DFT requirements + design rule check -------------------------------
rpt 01b_requirements_drc
set_design_level physical_block
set_dft_specification_requirements -memory_test on
add_clocks 0 clk -period 10ns
check_design_rules
report_clocks
safe_run report_dft_control_points

# ---- 1c. create + validate the DftSpecification (nothing inserted yet) ------
rpt 01c_dft_spec
set spec [create_dft_specification]
report_config_data $spec
process_dft_specification -validate_only

# ---- 1d. insert MBIST hardware, build IJTAG network, extract ICL ------------
rpt 01d_insert
process_dft_specification
extract_icl
safe_run report_ijtag_instances
safe_run report_icl_modules
safe_run {puts [exec find ./tsdb -type f -name "*.v" -o -type f -name "*.icl" -o -type f -name "*.pdl"]}

# ---- 1e. patterns (MBIST + IJTAG access) and optional simulation ------------
rpt 01e_patterns
create_patterns_specification
process_patterns_specification
if {[info exists ::env(RUN_SIM)] && $::env(RUN_SIM)} {
  set_simulation_library_sources -v ./library/memory/SYNC_1RW_64x8.v
  run_testbench_simulations
  check_testbench_simulations -report_status
}

set_logfile_handling
exit
