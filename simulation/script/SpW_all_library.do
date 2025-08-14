# compile the common package
#spw library
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/spw_data_types.vhd
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/spw_codes.vhd
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/SpaceWire_Sim_lib.vhd
#rmap library
vcom -2008 -quiet  -work rmap $DUT/DHU-project/simulation/src/4links/rmap/rmap_initiator_lib.vhd
#vcom -2008 -quiet  -work rmap $DUT/SpW_router/rmap_periph_pckg.vhd
#router library
vcom -work router -2008 -quiet $DUT/DHU-project/simulation/src/4links/router/router_pckg.vhd
vcom -work router -2008 -quiet $DUT/DHU-project/simulation/src/4links/router/router_records.vhd
#compile system_constant_pckg in work library
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/other/system_constant_pckg.vhd