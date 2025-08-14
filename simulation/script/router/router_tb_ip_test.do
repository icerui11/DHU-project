#set DUT C:/Users/yinrui/Desktop/Envison_DHU
set lib_exists [file exists work]
if $lib_exists==1 {vdel -lib work -all }
vlib work
#set spw include common package
if $lib_exists==1 {vdel -all -lib spw}
vlib spw
if $lib_exists==1 {vdel -all -lib router}
vlib router
if $lib_exists==1 {vdel -all -lib rmap}
vlib rmap
#router library
do $DUT/DHU-project/simulation/script/SpW_all_library.do
do $DUT/DHU-project/simulation/script/ip_core_spw.do
do $DUT/DHU-project/simulation/script/ip_core_rmap.do
do $DUT/DHU-project/simulation/script/ip_core_router.do
vcom -2008 -work work -quiet $DUT/DHU-project/SpW_router/RTL/sim/router_tb_ip_test_new.vhd
vsim -coverage work.router_tb_ip_test_new -vopt -t 1ns -voptargs="+acc"
