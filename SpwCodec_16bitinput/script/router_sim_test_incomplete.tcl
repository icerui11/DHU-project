# Generic TCL script structure for VHDL simulation
# author : Rui Yin date : 2025/01/20

# Set the working directory 
# SHyLoc_ip
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
# set the working directory, do $DUT/SpwCodec_16bitinput/script/DUT_16bitInput_DO.tcl
set DUT C:/Users/yinrui/Desktop/Envison_DHU/DHU-project
# 

set lib_exists [file exists grlib]
if $lib_exists==1 {vdel -all -lib grlib}
vlib grlib
set lib_exists [file exists techmap]
if $lib_exists==1 {vdel -all -lib techmap}
vlib techmap
set lib_exists [file exists gaisler]
if $lib_exists==1 {vdel -all -lib gaisler}
vlib gaisler
do $SRC/modelsim/tb_scripts/setGRLIB.do
#set spw include common package
if $lib_exists==1 {vdel -all -lib spw_codec}
vlib spw_codec
if $lib_exists==1 {vdel -all -lib spw}
vlib spw
if $lib_exists==1 {vdel -all -lib router}
vlib router
if $lib_exists==1 {vdel -all -lib rmap}
vlib rmap
if $lib_exists==1 {vdel -all -lib spw_utils}
vlib spw_utils
#set IP test parameters
set lib_exists [file exists shyloc_121]
if $lib_exists==1 {vdel -all -lib shyloc_121}
vlib shyloc_121
set lib_exists [file exists shyloc_utils]
if $lib_exists==1 {vdel -all -lib shyloc_utils}
vlib shyloc_utils
set lib_exists [file exists shyloc_123]
if $lib_exists==1 {vdel -all -lib shyloc_123}
vlib shyloc_123
set lib_exists [file exists post_syn_lib]
if $lib_exists==1 {vdel -all -lib post_syn_lib}
vlib post_syn_lib
set lib_exists [file exists BROM]
if $lib_exists==1 {vdel -all -lib BROM}
vlib BROM
set lib_exists [file exists src]
if $lib_exists==1 {vdel -all -lib src}
vlib src
vcom -work shyloc_123 -93 -explicit  $SRC/modelsim/tb_stimuli/30_Test/ccsds123_parameters.vhd
vcom -work shyloc_121 -93 -explicit  $SRC/modelsim/tb_stimuli/30_Test/ccsds121_parameters.vhd
do $SRC/modelsim/tb_scripts/ip_core.do
do $SRC/modelsim/tb_scripts/ip_core_block.do

#testbench for DUT_16bitInput
#vcom -work work -2008 -explicit $DUT/SpwCodec_16bitinput/RTL/spw_utils/DUT_16bitInput_tb.vhd
#start the simulate
#vsim work.DUT_16bitInput_tb -voptargs=+acc=bcglnprst+DUT_16bitInput_tb
#onbreak {resume}
#run -all