# =============================================================================
# STEP 2 : On-Chip Clock Controller (OCC)   (Tessent Shell 2022.4, design_id rtl2)
#   Run AFTER 01_mbist_ijtag.tcl (reads its TSDB, design_id rtl1).
#   run :  tessent -shell -dofile tcl/02_occ.tcl
#   opt :  setenv TCELLLIB <your .tcelllib>   setenv RUN_SIM 1
# The OCC is added to the same IJTAG network under Sib(occ), so you can compare
# the ICL / IJTAG reports with step 1.
# =============================================================================
file mkdir reports

proc rpt {name} { set_logfile_handling reports/$name.rpt -replace }
proc safe_run {cmd} {
  if {[catch {uplevel 1 $cmd} msg]} { puts "// SKIPPED optional: $cmd -> $msg" }
}

# ---- 2a. load the rtl1 result -----------------------------------------------
rpt 02a_load
set_context dft -rtl -design_id rtl2
set_tsdb_output_directory ./tsdb
if {[info exists ::env(TCELLLIB)]} { read_cell_library $::env(TCELLLIB) }
read_design mini_soc -design_id rtl1
set_current_design mini_soc
report_memory_instances
safe_run report_ijtag_instances

# ---- 2b. DFT signals + requirements + DRC -----------------------------------
# New ports (scan_enable, test_clk_in) are created because they do not exist.
rpt 02b_dft_signals_drc
add_dft_signals ltest_en -create_with_tdr
add_dft_signals scan_en -source_nodes scan_enable
add_dft_signals shift_capture_clock -source_nodes test_clk_in
add_dft_signals memory_bypass_en -create_with_tdr
add_dft_signals tck_occ_en -create_with_tdr
report_dft_signals
set_dft_specification_requirements -logic_test on
# clk is already defined: read_design carries it over from rtl1
check_design_rules
report_clocks
safe_run report_dft_control_points

# ---- 2c. DftSpecification with one OCC on 'clk' ------------------------------
rpt 02c_dft_spec
set spec [create_dft_specification -sri_sib_list occ]
read_config_data -in $spec -from_string {
  OCC {
    ijtag_host_interface : Sib(occ);
  }
}
set occ [add_config_element OCC/Controller(clk_occ) -in $spec]
set_config_value clock_intercept_node -in $occ clk
report_config_data $spec
process_dft_specification -validate_only

# ---- 2d. insert OCC, extract ICL, write synthesis import script -------------
rpt 02d_insert
process_dft_specification
extract_icl
write_design_import_script reports/for_synthesis.tcl -replace
safe_run report_ijtag_instances
safe_run report_icl_modules
safe_run {puts [exec find ./tsdb -type f -name "*.v" -o -type f -name "*.icl" -o -type f -name "*.pdl"]}

# ---- 2e. patterns (OCC + MBIST via IJTAG) and optional simulation -----------
rpt 02e_patterns
create_patterns_specification
process_patterns_specification
if {[info exists ::env(RUN_SIM)] && $::env(RUN_SIM)} {
  set_simulation_library_sources -v ./library/memory/SYNC_1RW_64x8.v
  run_testbench_simulations
  check_testbench_simulations -report_status
}

set_logfile_handling
exit
