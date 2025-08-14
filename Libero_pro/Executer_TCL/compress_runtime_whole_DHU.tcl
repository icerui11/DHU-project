# Microsemi Tcl Script
# libero
# Date: Tue Aug 12 23:46:57 2025
# Directory C:\Microchip\Libero_SoC_v2024.2\Designer\bin
# File C:\Microchip\Libero_SoC_v2024.2\Designer\bin\exported.tcl

new_project -location {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU} -name {Compress_runtime_whole_DHU} -project_description {} -block_mode 0 -standalone_peripheral_initialization 0 -instantiate_in_smartdesign 0 -ondemand_build_dh 1 -use_relative_path 0 -linked_files_root_dir_env {} -hdl {VHDL} -family {SmartFusion2} -die {M2S150TS} -package {1152 FC} -speed {-1} -die_voltage {1.2} -part_range {COM} -adv_options {DSW_VCCA_VOLTAGE_RAMP_RATE:100_MS} -adv_options {IO_DEFT_STD:LVCMOS 2.5V} -adv_options {PLL_SUPPLY:PLL_SUPPLY_25} -adv_options {RESTRICTPROBEPINS:0} -adv_options {RESTRICTSPIPINS:0} -adv_options {SYSTEM_CONTROLLER_SUSPEND_MODE:0} -adv_options {TEMPR:COM} -adv_options {VCCI_1.2_VOLTR:COM} -adv_options {VCCI_1.5_VOLTR:COM} -adv_options {VCCI_1.8_VOLTR:COM} -adv_options {VCCI_2.5_VOLTR:COM} -adv_options {VCCI_3.3_VOLTR:COM} -adv_options {VOLTR:COM} 
import_files \
         -convert_EDN_to_HDL 0 \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/config_controller/ahb_master_controller_v2.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/config_controller/config_arbiter_v3.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/config_controller/config_ram_8to32.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/config_controller/config_pkg.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/config_controller/config_types_pkg.vhd} 
build_design_hierarchy 
add_library -library {config_controller} 
add_file_to_library -library {config_controller} -file {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU/hdl/config_ram_8to32.vhd} -file {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU/hdl/config_arbiter_v3.vhd} -file {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU/hdl/ahb_master_controller_v2.vhd} -file {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU/hdl/config_pkg.vhd} -file {D:/users/Venspec_work/libero_project/dma/Compress_runtime_whole_DHU/hdl/config_types_pkg.vhd} 
export_script -file {C:/Microchip/Libero_SoC_v2024.2/Designer/bin/exported.tcl} -relative_path 1 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {VH_compressor} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_blockcoder_top_VH.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_constants_VH.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_predictor_top_VH.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_shyloc_top_VH.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_ahbs.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_clk_adapt.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_parameters.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_predictor_comp.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_predictor_fsm.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_comp.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_fsm.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_interface.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_config121_package.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_fscoderv2.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_header121_shyloc.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_lkcomp.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_lkoptions.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_optcoder.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_packing_top.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_sndextension.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_splitter.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {grlib} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/amba/amba.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/amba/apbctrl.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/amba/devices.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {grlib} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/stdlib.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/testlib.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/stdio.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/config_types.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/config.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/System_bus/RTL/grlib/stdlib/version.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -hdl_source_folder {C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/src/shyloc_utils} \
         -library {shyloc_utils} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -hdl_source_folder {C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/src/shyloc_123} \
         -library {shyloc_123} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -hdl_source_folder {C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL/src/shyloc_121} \
         -library {shyloc_121} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {spw} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/spw/SpaceWire_Sim_lib.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/spw/spw_codes.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/spw/spw_data_types.vhd} 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {rmap} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/rmap/rmap_initiator_lib.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/rmap/rmap_periph_pckg.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {router} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router/router_pckg.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router/router_records.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/other/system_constant_pckg.vhd} 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_fifo_2c.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_filter_errors.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_RTG4.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_add_eep.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_bit_rate.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_dp_fifo_buffer.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_flowcredit_x.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_sync_RTG4.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_to_2b_RTG4.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_rx_to_data.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_timeout_det.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_tx_discard.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_tx_dp_fifo_buffer.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_tx_ds.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_tx_flowcontrol.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_wrap_top_level_RTG4.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/spw_ctrl.vhd} 
build_design_hierarchy 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/ip4l_context_RTG4.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_config_memory.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_fabric_mux_32.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_fabric_mux_32_to_1.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_pckg.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_port_0_controller.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_port_rx_controller.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_port_tx_controller.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_records.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_routing_table.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_rt_arbiter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_rt_arbiter_fifo_priority.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_status_reg.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_timecode_logic.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_top_level_RTG4.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_top_level_tb.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_top_level_tb_ip_test.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_xbar_req_arbiter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_xbar_req_arbiter_fifo_priority.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_xbar_switch_fabric.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_xbar_target_arbiter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/router_xbar_top_level.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/simple_priority_arbiter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/fifo_gray_counter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/asym_FIFO.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/SpW_router/dp_fifo_buffer.vhd} 
build_design_hierarchy 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/mixed_width_ram_top_v2.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/mixed_width_ram_comp.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/router_routing_table_top_v2.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/routing_table_ram.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/router_rt_arbiter.vhd} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/router_rtl/router_rt_arbiter_fifo_priority.vhd} 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/spw_controller/router_fifo_spwctrl_16input/router_fifo_spwctrl_16bit_v2.vhd} 
import_files \
         -convert_EDN_to_HDL 0 \
         -library {work} \
         -hdl_source {C:/Users/yinrui/Desktop/Envison_DHU/DHU-project/simulation/src/4links/spw_controller/router_fifo_ctrl_top_v2.vhd} 
build_design_hierarchy 
