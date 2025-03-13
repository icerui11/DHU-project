#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#set lib_exists [file exists work]
#if $lib_exists==1 {vdel -lib work -all }
vcom -work work -2008 -quiet $DUT/SpW_router/fifo_gray_counter.vhd
#vcom -work work -2008 -quiet $DUT/SpW_router/mixed_width_ram.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/mixed_width_ram_comp.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/mixed_width_ram_top_v2.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/dp_fifo_buffer.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_config_memory.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_fabric_mux_32.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_fabric_mux_32_to_1.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/spw_rx_dp_fifo_buffer.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/spw_tx_dp_fifo_buffer.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_port_rx_controller.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_port_tx_controller.vhd
#vcom -work work -2008 -quiet $DUT/SpW_router/router_routing_table.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/routing_table_ram.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/router_routing_table_top_v2.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_status_reg.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_timecode_logic.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/simple_priority_arbiter.vhd
#vcom -work work -2008 -quiet $DUT/SpW_router/router_rt_arbiter_fifo_priority.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/router_rt_arbiter.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/router_rt_arbiter_fifo_priority.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_xbar_req_arbiter_fifo_priority.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_xbar_switch_fabric.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_xbar_target_arbiter.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_xbar_req_arbiter.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_xbar_top_level.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/router_port_0_controller.vhd
#compile the new router submodules rt 
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/router_rtl/router_top_level_RTG4.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/reg_bank_inf_asym2.vhd
vcom -work work -2008 -quiet $DUT/SpW_router/asym_FIFO.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/spw_controller/router_fifo_spwctrl_16input/router_fifo_spwctrl_16bit.vhd
vcom -work work -2008 -quiet $DUT/DHU-project/simulation/src/4links/spw_controller/router_fifo_ctrl_top.vhd
