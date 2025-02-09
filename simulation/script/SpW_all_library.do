# compile the common package
#spw library
vcom -2008 -quiet  -work spw $DUT/SpW_router/spw_data_types.vhd
vcom -2008 -quiet  -work spw $DUT/SpW_router/spw_codes.vhd
vcom -2008 -quiet  -work spw $DUT/SpW_router/SpaceWire_Sim_lib.vhd
#rmap library
vcom -2008 -quiet  -work rmap $DUT/SpW_router/rmap_initiator_lib.vhd
#vcom -2008 -quiet  -work rmap $DUT/SpW_router/rmap_periph_pckg.vhd
#router library
vcom -work router -2008 -quiet $DUT/SpW_router/router_pckg.vhd
vcom -work router -2008 -quiet $DUT/SpW_router/router_records.vhd