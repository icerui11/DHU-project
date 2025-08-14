#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#set lib_exists [file exists work]
#do $DUT/DHU-project/System_bus/scripts/shyloc_ahb_system_tb_single.do
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
do $DUT/DHU-project/simulation/script/ip_core_system.do
#config_controller library
do $DUT/DHU-project/System_bus/scripts/ip_core_config.do   
vcom -2008 -work work $DUT/DHU-project/System_bus/RTL/config_controller/shyloc_ahb_system_top_single.vhd
vcom -2008 -work work -quiet $DUT/DHU-project/System_bus/RTL/config_controller/tb/shyloc_ahb_system_tb_single.vhd
vsim -coverage work.shyloc_ahb_system_tb_single -voptargs="+acc"
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Clk_S
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Rst_N
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBSlave121_In
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Clk_AHB
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Reset_AHB
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBSlave121_Out
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBSlave123_In
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBSlave123_Out
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBMaster123_In
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AHBMaster123_Out
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/DataIn_shyloc
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/DataIn_NewValid
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/DataOut
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/DataOut_NewValid
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Ready_Ext
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/ForceStop
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/AwaitingConfig
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Ready
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/FIFO_Full
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/EOP
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Finished
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/compressor_HR/Error
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/clk
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/rst_n
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/compressor_status_HR
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/compressor_status_LR
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/compressor_status_H
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ram_wr_en
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/wr_addr
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/wr_data
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ctrli
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ctrlo
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_mst_inst/ahbmi
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_mst_inst/ahbmo
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/state_reg_ahbw
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/state_next_ahbw
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ctrl
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ctrl_reg
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/remaining_writes
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/remaining_writes_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/address_write
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/address_write_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/address_read
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/address_read_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/data
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/data_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/size
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/size_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/htrans
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/htrans_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/hburst
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/hburst_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/debug
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/debug_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/appidle
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/appidle_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahbwrite
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahbwrite_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahbread_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahbread
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/count_burst
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/count_burst_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/burst_size
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/burst_size_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/beats
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/beats_reg
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahb_wr_cnt_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahb_wr_cnt_reg
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ram_start_addr
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ram_read_num
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_done
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_done_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/arbiter_grant
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/arbiter_grant_valid
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/arbiter_config_req
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ahb_target_addr
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ram_rd_data_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/ram_rd_valid_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/empty_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/full_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/hfull_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/afull_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/aempty_cmb
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/data_out_fifo
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/r_update_reg
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/w_update_reg
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/r_update_out
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/w_update_out
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/r
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/config_done
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/config_req
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/start_add
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/read_num
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/ahb_target_addr
add wave -position end  sim:/shyloc_ahb_system_tb_single/DUT/ahb_master_ctrl_inst/config_arbiter_inst/grant
# vsim -coverage work.shyloc_ahb_system_tb_single -vopt -t 1ns -voptargs="+acc"
#wave file

