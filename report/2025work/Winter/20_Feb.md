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

### week report

Last week, I completed the pure HDL development process in Libero, which means I did not use SmartDesign for development, and resolved the issue of Libero being unable to synthesize record signals. However, there are still some issues with the entire system when configuring certain parameters of the SHyLoC, because I have only simulated the router\_ctrl and have not simulated the entire system yet. Therefore, my next step is to simulate the entire system

# 23.02 system_SHyLoC_top_tb

1. instantiate a Shyloc in testbench entity work.
2. 如果需要在没有VVC的情况下实现类似的功能。如果没有VVC，就需要手动编写监控和驱动的逻辑
3. set DUT C:/Users/yinrui/Desktop/Envison_DHU
   do $DUT/DHU-project/simulation/script/system_SHyLoC_top_test.do

# UVVM work

* [ ]  using logging and alert handling
* [ ]  using simple procedure based transactions like uart_transmit() and avalon_read() for simple verification scenarios
* [ ]  using constrained Random from dead simple to Enhanced and Optimised
* [ ]  understanding and using functional Coverage
* [ ]  using verification components and advanced transactions (TLM) for complex scenarios
* [ ]  understanding and using Scoreboards and models
* [ ]  需解决问题 为什么ccsds123 big endia  not work

## simple router_fifo_ctrl_top_tb_uvvm

1. clock_generator(clk, clock_ena, C_CLK_PERIOD, "DHT clock start");

   1.
   2. msg, a custom message to be appended in the log/alert
   3.
2. await\_uvvm\_initialization() serves as a synchronization point between your test sequencer and the UVVM freamwork

   1. procedure await_uvvm_initialization(
      constant dummy : in t_void) is
      begin
      while (shared_uvvm_state /= INIT_COMPLETED) loop
      wait for 0 ns;
      end loop;
      end procedure;
   2. prevent test commands from being sent before the system is ready
3. in the main stimulus process block, constant and variable definition:
