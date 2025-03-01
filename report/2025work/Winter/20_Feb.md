# thinking

* 问题：当SHyLoC 在结束reset后 会立即输出header，所以需要等待router connected完成后 再reset shyloc

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
4. 读取文件：use text and line-based reading when dealing with structured text files where each line contains meaningful data that can be processes as a unit
   1. use character when you need to precisely control reading and processing at a character level
      1. sequential reading, each call to the read procedure fetches the next character from ther current position in the file
      2. no need for line buffer
   2. read function from std.textio, the general syntax : read(file_var, variable);
   3. 但似乎read file 并不适合使用procedure完成, (可以不全部包含在一个procedure中完成)
      1. i declared bin_file parameter as character type, but i pass a file to it,
      2. in VHDL cannot directly define a file parameter as a character type
         1. You first need to define a file type using the `file of` syntax
         2. character represents a single character value (similar to char in C), not a file stream.
5. File opening: the file should be declared outside the procedure, typically in a process or architecture declarative area, so it maintains its state between procedure calls
   1. ensure the file is opened for reading before entering the loop or procedure that will read data
   2. 原因：the file handle maintains its internal position pointer regardless of  scope changes, typically do so with a file variable (or handle) that represents the connection of the external file
   3. 如果需要多个process 访问同一个文件，declare the file handle outside all processes and perform file operations by referencing this handle
      4.integer'image(to_integer(sample_count)) 用于转换成integer 字符串
6. gen_stim process中的问题在于codecs.Tx_data 是t_nonet,
7. 问题是shyloc datain newvalid 没有响应，需检查dut 中的router_fifo_spwctrl，rx_data_valid
   1. 只看见fifo_in 的rx_data, 也就是来自SHYloc 的数据，没有raw data
   2. 验证router spw node 1
   3. 原因是send_addr router_addr应提前assign，但也发现传输两次path address, the reason is that the handshake signal is not nested after Shyloc is ready

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
