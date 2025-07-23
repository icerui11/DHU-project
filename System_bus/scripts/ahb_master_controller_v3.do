#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#set lib_exists [file exists work]
#do $DUT/DHU-project/System_bus/scripts/ahb_master_controller_v3.do
#if $lib_exists==1 {vdel -lib work -all }
#vlib work
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
vdel -lib work -all
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
vcom -2008 -work work -quiet $DUT/DHU-project/System_bus/RTL/config_controller/tb/ahb_master_controller_v2_tb.vhd
vsim -coverage work.ahb_master_controller_v2_tb -voptargs="+acc"
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/clk
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/rst_n
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/compressor_status_HR
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/compressor_status_LR
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/compressor_status_H
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ram_wr_en
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/wr_addr
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/wr_data
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ctrli
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ctrlo
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/state_reg_ahbw
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/state_next_ahbw
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ctrl
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ctrl_reg
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/remaining_writes
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/remaining_writes_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/address_write
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/address_write_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/address_read
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/address_read_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/data
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/data_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/size
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/size_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/htrans
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/htrans_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/hburst
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/hburst_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/debug
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/debug_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/appidle
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/appidle_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahbwrite
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahbwrite_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahbread_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahbread
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/count_burst
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/count_burst_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/burst_size
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/burst_size_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/beats
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/beats_reg
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahb_wr_cnt_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahb_wr_cnt_reg
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ram_start_addr
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ram_read_num
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/config_done
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/config_done_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/arbiter_grant
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/arbiter_grant_valid
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/arbiter_config_req
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ahb_target_addr
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ram_rd_data_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/ram_rd_valid_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/empty_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/full_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/hfull_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/afull_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/aempty_cmb
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/data_out_fifo
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/r_update_reg
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/w_update_reg
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/r
add wave -position end  sim:/ahb_master_controller_v2_tb/dut_controller/rin
# vsim -coverage work.ahb_master_controller_v2_tb -vopt -t 1ns -voptargs="+acc"
#wave file

