#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#set lib_exists [file exists work]
#do $DUT/DHU-project/System_bus/scripts/spw_ccsds121_system.do
#if $lib_exists==1 {vdel -lib work -all }
#vlib work
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
vdel -lib work -all
vlib work
set lib_exists [file exists grlib]
if $lib_exists==1 {vdel -lib grlib -all }
vlib grlib
set lib_exists [file exists techmap]
if $lib_exists==1 {vdel -lib techmap -all}
vlib techmap
set lib_exists [file exists gaisler]
if $lib_exists==1 {vdel -lib gaisler -all}
vlib gaisler
do $SRC/modelsim/tb_scripts/setGRLIB.do
#set IP test parameters
set lib_exists [file exists shyloc_121]
if $lib_exists==1 {vdel -all -lib shyloc_121}
vlib shyloc_121
set lib_exists [file exists shyloc_utils]
if $lib_exists==1 {vdel -all -lib shyloc_utils}
vlib shyloc_utils
set lib_exists [file exists compressor]
if $lib_exists==1 {vdel -all -lib compressor}
vlib compressor
set lib_exists [file exists post_syn_lib]
if $lib_exists==1 {vdel -all -lib post_syn_lib}
vlib post_syn_lib
#set spw include common package
if $lib_exists==1 {vdel -all -lib spw}
vlib spw
if $lib_exists==1 {vdel -all -lib router}
vlib router
if $lib_exists==1 {vdel -all -lib rmap}
vlib rmap
set lib_exists [file exists config_controller]
if $lib_exists==1 {vdel -all -lib config_controller}
vlib config_controller
vcom -work shyloc_123 -93 -explicit  $SRC/modelsim/tb_stimuli/30_Test/ccsds123_parameters.vhd
vcom -work shyloc_121 -93 -explicit  $SRC/modelsim/tb_stimuli/30_Test/ccsds121_parameters.vhd
do $SRC/modelsim/tb_scripts/ip_core.do
do $SRC/modelsim/tb_scripts/ip_core_block.do
vcom -work work -93 -explicit $SRC/modelsim/tb_stimuli/30_Test/ccsds123_tb_parameters.vhd
vcom -work work -93 -explicit $SRC/modelsim/tb_stimuli/30_Test/ccsds121_tb_parameters.vhd
#do $SRC/modelsim/tb_scripts/testbench.do
#router library
do $DUT/DHU-project/simulation/script/SpW_all_library.do
do $DUT/DHU-project/simulation/script/ip_core_spw.do
do $DUT/DHU-project/simulation/script/ip_core_rmap.do
do $DUT/DHU-project/simulation/script/ip_core_router.do
#config_controller library
do $DUT/DHU-project/System_bus/scripts/ip_core_config.do   
do $DUT/DHU-project/simulation/script/ip_core_system.do
# Venspec-H 1D compressor
do $DUT/DHU-project/System_bus/scripts/ip_compressor.do
do $DUT/DHU-project/System_bus/scripts/ip_grlib_amba.do
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Topwrapper/spw_ccsds121_system_top.vhd
vcom -2008 -work work $DUT/DHU-project/System_bus/RTL/Topwrapper/spw_ccsds121_system_top.vhd
vcom -2008 -work work -quiet $DUT/DHU-project/System_bus/RTL/tb/spw_ccsds121_system_top_tb.vhd
vsim -coverage work.spw_ccsds121_system_top_tb -voptargs="+acc"

add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/clk_in
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/rst_n
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/config_s
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/rx_data_in
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/rx_data_valid
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/ccsds_data_input
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/ccsds_data_valid
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/ccsds_data_ready
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/clear_fifo
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/error_out
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Clk_S
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Rst_N
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/AHBSlave121_In
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Clk_AHB
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Reset_AHB
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/AHBSlave121_Out
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/DataIn
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/DataIn_NewValid
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/IsHeaderIn
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/NbitsIn
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/DataOut
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/DataOut_NewValid
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/ForceStop
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Ready_Ext
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/AwaitingConfig
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Ready
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/FIFO_Full
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/EOP
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Finished
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/compressor_inst/Error
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/bytes_needed_int
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/assemble_cnt
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/assemble_finished
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/byte_counter
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/data_buffer
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/data_valid_reg
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/fifo_wr_en
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/fifo_rd_en
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/fifo_data_in
add wave -position end  sim:/spw_ccsds121_system_top_tb/dut/u_router_shyloc_fifo/fifo_data_out