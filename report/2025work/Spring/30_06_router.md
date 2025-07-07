# router original IP test

vcom -2008 -work work -quiet $DUT/DHU-project/SpW_router/RTL/sim/router_tb_ip_test_new.vhd

C:\Users\yinrui\Desktop\Envison_DHU\DHU-project\simulation\script\router\router_tb_ip_test.do

do $DUT/DHU-project/simulation/script/router/router_tb_ip_test.do

# controller

do $DUT/DHU-project/System_bus/scripts/ahb_master_controller.do

Noted: 后期应该设计机制，在reset后 需要通过GR712传输完配置参数给parameter_ram 后 再 重新配置compressor
