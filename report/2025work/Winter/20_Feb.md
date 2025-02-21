# 20.02

### router_multi_shyloc_ctrl

Purpose: Three SHyLoC compressors are connected to the SPW router, and the compressors must be connected to the SpW FIFO ports.

create router_multi_shyloc_ctrl.vhd

### simulation

vsim -qwavedb=+signal is a simulation option that controls the behavior of the waveform recording

+signal: specifies to record waveform data for all signals

1. 建立router_fifo_ctrl_top_tb_uvvm.vhd
   1. corresponding router_fifo_ctrl_uvvm.do , add uvvm compile script
   2. 首先按照UVVM_light demo_tb 生成可用的testbench
   3.

# UVVM work

* [ ]  using logging and alert handling
* [ ]  using simple procedure based transactions like uart_transmit() and avalon_read() for simple verification scenarios
* [ ]  using constrained Random from dead simple to Enhanced and Optimised
* [ ]  understanding and using functional Coverage
* [ ]  using verification components and advanced transactions (TLM) for complex scenarios
* [ ]  understanding and using Scoreboards and models

## simple router_fifo_ctrl_top_tb_uvvm

1. clock_generator(clk, clock_ena, C_CLK_PERIOD, "DHT clock start");
   1. msg, a custom message to be appended in the log/alert
2.
