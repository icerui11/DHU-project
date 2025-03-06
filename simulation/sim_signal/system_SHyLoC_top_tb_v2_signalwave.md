do $DUT/DHU-project/simulation/script/system_SHyLoC_top_test.do

SHyloc signal

add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Clk_S
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Rst_N

add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/DataIn_shyloc
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/DataIn_NewValid
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/DataOut
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/DataOut_NewValid
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Ready_Ext
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/ForceStop
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/AwaitingConfig
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Ready
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/FIFO_Full
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/EOP
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Finished
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Error
add wave -position end  sim:/system_shyloc_top_tb_v2/ShyLoc_top_inst/Finished_Ext


add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/clock
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/reset
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_data
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_OR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_IR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_data
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_OR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_IR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_ESC_ESC
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_ESC_EOP
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_ESC_EEP
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_Parity_error
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_bits
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_rate
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_Time
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_Time_OR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Rx_Time_IR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_Time
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_Time_OR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_Time_IR
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_PSC
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_PSC_valid
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Tx_PSC_ready
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Disable
add wave -position end  sim:/system_shyloc_top_tb_v2/gen_dut_tx(1)/gen_spw_tx/SPW_inst/Connected

add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/target_addr_32
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/addr_valid
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/addr_ready
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/req_assert
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/bus_in_m
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/bus_in_s
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/bus_out_m
add wave -position end  sim:/system_shyloc_top_tb_v2/DUT/router_inst/xbar_tl_inst/xbar_fabric/bus_out_s

add wave -position end  sim:/system_shyloc_top_tb_v2/counter
add wave -position end  sim:/system_shyloc_top_tb_v2/counter_samples
add wave -position end  sim:/system_shyloc_top_tb_v2/state
add wave -position end  sim:/system_shyloc_top_tb_v2/router_ctrl_state
