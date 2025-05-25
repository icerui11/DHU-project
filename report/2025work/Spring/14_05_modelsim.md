# task

* [ ]  runtime configuration new scheme
* [ ]  I/O interface control
* [X]  设计两套bus,为compression core configuration part 设计一套bus
* [X]  V-U resource utilzation excel
* [ ]  need whole FPGA resource usage overview
* [X]  FPGA project for seperate spw codec clk
* [X]  FPGA project for another indien student : memory-mapped configuration for SHyLoC

# TBD specification

* [ ]  确认IO port 将使用什么协议：SPI，I2C, UART, Parallel Interface

# 14.05 use questa from lattice

set DUT C:/Users/yinrui/Desktop/Envison_DHU
do $DUT/DHU-project/simulation/script_modelsim/pre_syn_submodul/system_3SHyLoC_test.do

need to recompile UVVM library and vlib smartfusion2 precompile library

# 21.05

对于SHyLoC compression core 由于设计需要，需要使用processor发送configuration parameter 给FPGA，所以在设计中将使用IO口而不是AHB bus对compression core进行配置，所以需要将configuration module 中AHB slave不使用ahb bus进行配置

对多个 compression IP核所需的配置register 地址 partitioning

目前Venspec -U LR and HR both has individual 3D compression core, which means here has 4 part need to be configured(2 123, 2 121), and for

## 23.05 system_bus doc

create a word FPGA_sys_bus_001

## 26.05 two task WP complete

SHyLoC runtime cfg

multiple clk router

both WP in word file
