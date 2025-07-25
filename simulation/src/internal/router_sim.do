#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#do $DUT/DHU-project/simulation/src/internal/router_sim.do
#set lib_exists [file exists work]
#if $lib_exists==1 {vdel -lib work -all }
#vlib work
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
vdel -all -lib work
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
vmap SmartFusion2 "C:/Microchip/Libero_SoC_v2024.1/Designer/lib/modelsimpro/precompiled/vlog/smartfusion2"
#router library
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/spw_data_types.vhd
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/spw_codes.vhd
vcom -2008 -quiet  -work spw $DUT/DHU-project/simulation/src/4links/spw/SpaceWire_Sim_lib.vhd
#rmap library
vcom -2008 -quiet  -work rmap $DUT/DHU-project/simulation/src/4links/rmap/rmap_initiator_lib.vhd
#vcom -2008 -quiet  -work rmap $DUT/SpW_router/rmap_periph_pckg.vhd
#router library
vcom -work router -2008 -quiet $DUT/DHU-project/simulation/src/internal/router_pckg.vhd
vcom -work router -2008 -quiet $DUT/DHU-project/simulation/src/4links/router/router_records.vhd
do $DUT/DHU-project/simulation/script/ip_core_spw.do
do $DUT/DHU-project/simulation/script/ip_core_rmap.do
do $DUT/DHU-project/simulation/src/internal/ip_core_router_v1.do
#do $DUT/DHU-project/simulation/script/ip_core_system.do
vcom -2008 -work work -quiet $DUT/DHU-project/simulation/src/internal/router_top_level_RTG4_tb.vhd
vopt +acc .router_top_level_RTG4_tb -o router_top_level_RTG4_tb_opt -debugdb
vsim -t 1ps -debugdb router_top_level_RTG4_tb_opt 
log -r /*
#vsim -coverage work.router_top_level_RTG4_tb -vopt -t 1ns -voptargs="+acc"
#wave file
#do $DUT/DHU-project/simulation/sim_signal/system_SHyLoC_top_tb_v2_signalwave.md 
#run -all
# Create the coverage report directory
#set coverage_dir [file dirname "$DUT/DHU-project/simulation/coverage/system_SHyLoC_top_tb_v2.covhtml"]
#file mkdir -p $coverage_dir
#coverage report -output $DUT/DHU-project/simulation/coverage/system_SHyLoC_top_tb_v2.covhtml -html -cvg -details -assert -codeAll