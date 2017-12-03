################################################################################
# DESIGN COMPILER:  Logic Synthesis Tool                                       #
################################################################################
remove_design -all
#set_hdlin_vrlg_std "2001" 
set hdlin_vrlg_std 2001

# Add search paths for our technology libs.
set search_path "$search_path . ./verilog /w/apps2/public.2/tech/synopsys/32-28nm/SAED32_EDK/lib/stdcell_rvt/db_nldm" 
set target_library "saed32rvt_ff1p16vn40c.db saed32rvt_ss0p95v125c.db"
set link_library "* saed32rvt_ff1p16vn40c.db saed32rvt_ss0p95v125c.db dw_foundation.sldb"
set synthetic_library "dw_foundation.sldb"

# Define work path (note: The work path must exist, so you need to create a folder WORK first)
define_design_lib WORK -path ./WORK
set alib_library_analysis_path “./alib-52/”


# Read the gate-level verilog files
analyze -format verilog {Image_Classifier.v neuron_block_2.v FixedPointAdder.v  FixedPointMultiplier.v SynLib.v define.h}
 set DESIGN_NAME Image_Classifier
# set DESIGN_NAME neuron_block_2

elaborate $DESIGN_NAME
current_design $DESIGN_NAME
link


set_operating_conditions -min ff1p16vn40c -max ss0p95v125c


# Describe the clock waveform & setup operating conditions
set Tclk 2.0
set TCU  0.02


create_clock -name "clk" -period $Tclk [get_ports "clk"]
set_fix_hold clk
set_dont_touch_network [get_clocks "clk"]
set_clock_uncertainty $TCU [get_clocks "clk"]

# set_max_area 10.0

ungroup -flatten -all
uniquify

compile -only_design_rule
compile -map_effort high
compile -boundary_optimization
compile -only_hold_time

report_timing -path full -delay min -max_paths 10 -nworst 2 > Design.holdtiming
report_timing -path full -delay max -max_paths 10 -nworst 2 > Design.setuptiming
report_area -hierarchy > Design.area
report_power -hier -hier_level 2 > Design.power
report_resources > Design.resources
report_constraint -verbose > Design.constraint
check_design > Design.check_design
check_timing > Design.check_timing


write -hierarchy -format verilog -output $DESIGN_NAME.vg
write_sdf -version 1.0 -context verilog $DESIGN_NAME.sdf
set_propagated_clock [all_clocks]
write_sdc $DESIGN_NAME.sdc