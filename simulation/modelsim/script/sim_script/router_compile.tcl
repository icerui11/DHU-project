#compile package and record

vcom -2008 -work router router_pack.vhd
vcom -2008 -work router router_records.vhd
vcom -2008 ip4l_context_RTG4.vhd

# Compile SPW files with VHDL-2008
vcom -2008 spw_ctrl.vhd
vcom -2008 spw_fifo_2c.vhd
vcom -2008 spw_filter_errors.vhd
vcom -2008 spw_rx_add_eep.vhd
vcom -2008 spw_rx_bit_rate.vhd
vcom -2008 spw_rx_flowcredit_x.vhd
vcom -2008 spw_tx_discard.vhd
vcom -2008 spw_timeout_det.vhd
vcom -2008 spw_tx_data.vhd
vcom -2008 spw_tx_ds.vhd
vcom -2008 spw_tx_flowcontrol.vhd
vcom -2008 spw_rx_sync_RTG4.vhd
vcom -2008 spw_rx_to_2b_RTG4.vhd
vcom -2008 spw_RTG4.vhd
vcom -2008 spw_wrap_top_level_RTG4.vhd

# Compile Router files with VHDL-2008
vcom -2008 mixed_width_ram.vhd
vcom -2008 fifo_gpu_buffer.vhd
vcom -2008 router_config_memory.vhd
vcom -2008 router_fabric_mux_32.vhd
vcom -2008 router_fabric_32_to_1.vhd
vcom -2008 router_port_rx_controller.vhd
vcom -2008 router_port_tx_controller.vhd
vcom -2008 router_port_0_controller.vhd
vcom -2008 router_routing_table.vhd
vcom -2008 router_status_reg.vhd
vcom -2008 router_timecode_logic.vhd
vcom -2008 router_xbar_arbiter_fifo_priority.vhd
vcom -2008 router_xbar_switch_fabric.vhd
vcom -2008 router_xbar_target_arbiter.vhd
vcom -2008 router_xbar_req_arbiter.vhd
vcom -2008 router_spw_top_level.vhd
vcom -2008 simple_priority_arbiter.vhd
vcom -2008 router_rt_arbiter.vhd
vcom -2008 router_rt_arbiter_fifo_priority.vhd
vcom -2008 spw_rx_dp_fifo_buffer.vhd
vcom -2008 spw_tx_dp_fifo_buffer.vhd
vcom -2008 router_top_level_RTG4.vhd

# Compile RMAP files with VHDL-2008
vcom -2008 rmap_target_full.vhd
vcom -2008 single_port_single_clock_ram.vhd
vcom -2008 rmap_command_controller.vhd
vcom -2008 rmap_command_controller_parallel_interface.vhd
vcom -2008 rmap_crc_checker.vhd
vcom -2008 rmap_initiator.vhd
vcom -2008 rmap_initiator.vhd
vcom -2008 rmap_reply_controller.vhd
vcom -2008 rmap_reply_controller_parallel_interface.vhd
vcom -2008 rmap_spw_wrap.vhd
vcom -2008 rmap_initiator_top_level.vhd

vcom -2008 router_top_level_tb.vhd
vcom -2008 router_top_level_tb_ip_test.vhd