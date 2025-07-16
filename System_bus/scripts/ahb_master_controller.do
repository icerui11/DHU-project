#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#set lib_exists [file exists work]
#do $DUT/DHU-project/System_bus/scripts/ahb_master_controller.do
#if $lib_exists==1 {vdel -lib work -all }
#vlib work
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
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
vcom -2008 -work work -quiet $DUT/DHU-project/System_bus/RTL/config_controller/tb/ahb_master_controller_tb.vhd
vsim -coverage work.ahb_master_controller_tb -voptargs="+acc"
add wave -position end  sim:/ahb_master_controller_tb/dut/clk
add wave -position end  sim:/ahb_master_controller_tb/dut/rst_n
add wave -position end  sim:/ahb_master_controller_tb/dut/compressor_status_HR
add wave -position end  sim:/ahb_master_controller_tb/dut/compressor_status_LR
add wave -position end  sim:/ahb_master_controller_tb/dut/compressor_status_H
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_wr_en
add wave -position end  sim:/ahb_master_controller_tb/dut/wr_addr
add wave -position end  sim:/ahb_master_controller_tb/dut/wr_data
add wave -position end  sim:/ahb_master_controller_tb/dut/ctrli
add wave -position end  sim:/ahb_master_controller_tb/dut/ctrlo
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_read_cnt
add wave -position end  sim:/ahb_master_controller_tb/dut/read_ram_done
add wave -position end  sim:/ahb_master_controller_tb/dut/state_reg_ahbw
add wave -position end  sim:/ahb_master_controller_tb/dut/state_next_ahbw
add wave -position end  sim:/ahb_master_controller_tb/dut/ctrl
add wave -position end  sim:/ahb_master_controller_tb/dut/ctrl_reg
add wave -position end  sim:/ahb_master_controller_tb/dut/remaining_writes
add wave -position end  sim:/ahb_master_controller_tb/dut/remaining_writes_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/address_write
add wave -position end  sim:/ahb_master_controller_tb/dut/address_write_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/address_read
add wave -position end  sim:/ahb_master_controller_tb/dut/address_read_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/data
add wave -position end  sim:/ahb_master_controller_tb/dut/data_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/size
add wave -position end  sim:/ahb_master_controller_tb/dut/size_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/htrans
add wave -position end  sim:/ahb_master_controller_tb/dut/htrans_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/hburst
add wave -position end  sim:/ahb_master_controller_tb/dut/hburst_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/debug
add wave -position end  sim:/ahb_master_controller_tb/dut/debug_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/appidle
add wave -position end  sim:/ahb_master_controller_tb/dut/appidle_cmb
#add wave -position end  sim:/ahb_master_controller_tb/dut/data_valid
#add wave -position end  sim:/ahb_master_controller_tb/dut/data_valid_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/ahbwrite
add wave -position end  sim:/ahb_master_controller_tb/dut/ahbwrite_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/ahbread_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/ahbread
add wave -position end  sim:/ahb_master_controller_tb/dut/rev_counter
add wave -position end  sim:/ahb_master_controller_tb/dut/rev_counter_reg
add wave -position end  sim:/ahb_master_controller_tb/dut/count_burst
add wave -position end  sim:/ahb_master_controller_tb/dut/count_burst_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/burst_size
add wave -position end  sim:/ahb_master_controller_tb/dut/burst_size_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/beats
add wave -position end  sim:/ahb_master_controller_tb/dut/beats_reg
add wave -position end  sim:/ahb_master_controller_tb/dut/ahb_wr_cnt_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/ahb_wr_cnt_reg
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_start_addr
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_read_num
add wave -position end  sim:/ahb_master_controller_tb/dut/config_done
add wave -position end  sim:/ahb_master_controller_tb/dut/config_done_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/arbiter_grant
add wave -position end  sim:/ahb_master_controller_tb/dut/arbiter_grant_valid
add wave -position end  sim:/ahb_master_controller_tb/dut/arbiter_config_req
add wave -position end  sim:/ahb_master_controller_tb/dut/ahb_base_addr_123
add wave -position end  sim:/ahb_master_controller_tb/dut/ahb_base_addr_121
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_rd_data_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/ram_rd_valid_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/empty_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/full_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/hfull_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/afull_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/aempty_cmb
add wave -position end  sim:/ahb_master_controller_tb/dut/data_out_fifo
add wave -position end  sim:/ahb_master_controller_tb/dut/r
add wave -position end  sim:/ahb_master_controller_tb/dut/fifo_no_edac/w_update
add wave -position end  sim:/ahb_master_controller_tb/dut/fifo_no_edac/r_update
add wave -position end  sim:/ahb_master_controller_tb/dut/fifo_no_edac/empty
add wave -position end  sim:/ahb_master_controller_tb/dut/fifo_no_edac/data_in
add wave -position end  sim:/ahb_master_controller_tb/dut/fifo_no_edac/data_out
# vsim -coverage work.ahb_master_controller_tb -vopt -t 1ns -voptargs="+acc"
#wave file

