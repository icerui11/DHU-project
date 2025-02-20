# 20.02

### router_multi_shyloc_ctrl

Purpose: Three SHyLoC compressors are connected to the SPW router, and the compressors must be connected to the SpW FIFO ports.

create router_multi_shyloc_ctrl.vhd

### simulation

vsim -qwavedb=+signal is a simulation option that controls the behavior of the waveform recording

+signal: specifies to record waveform data for all signals


1. 建立router_fifo_ctrl_top_tb_uvvm.vhd
   1. corresponding router_fifo_ctrl_uvvm.do , add uvvm compile script

# UVVM work

* [ ]  using logging and alert handling
* [ ]  using simple procedure based transactions like uart_transmit() and avalon_read() for simple verification scenarios
* [ ]  using constrained Random from dead simple to Enhanced and Optimised
* [ ]  understanding and using functional Coverage
* [ ]  using verification components and advanced transactions (TLM) for complex scenarios
* [ ]  understanding and using Scoreboards and models
