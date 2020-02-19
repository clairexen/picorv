# vivado -mode batch -source test.tcl -nojournal -log test_vivado.log

read_verilog test.v
read_verilog picorv_core.v
read_verilog picorv_ctrl.v
read_verilog picorv_exec.v
read_verilog picorv_ldst.v
read_xdc test.xdc

synth_design -part xcku035-fbva676-2-e -top test
opt_design -sweep -remap -propconst
opt_design -directive Explore

place_design -directive Explore
phys_opt_design -retime -rewire -critical_pin_opt -placement_opt -critical_cell_opt
route_design -directive Explore
place_design -post_place_opt
phys_opt_design -retime
route_design -directive NoTimingRelaxation

report_utilization
report_timing
