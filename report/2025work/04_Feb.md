# 04.02``本周任务

* [X]  完成SHyLoc_subtop testbench and tcl
* [X]  完成router_fifo_ctrl testbench and tcl
* [ ]  上板进行综合

## ~~~~high priority task

* [ ]  study python
* [ ]  EGSE Ground Support Python GSpy
  <<<<<<< HEAD

  * [ ]  configurate enviroment and install dependency
* [X]  build test script for router_ctrl
* [ ]  verification for controller

  * [ ]  coverage report
  * [ ]  testcase
* [X]  configurate enviroment and install dependency

# ~~~~04.02-13

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU
2. do $DUT/DHU-project/simulation/script/router_fifo_ctrl.do
3. write new script
4. 注意编译新的routing_table都要用version 2
5. 重新编写router_fifo_ctrl_top_tb,因为之前的tb 只generate 了一个spw tx, 更新的testbench should according to predefined package g_num_ports and c_fifo_ports决定generated spw instances.
6. 因为spw become as a arrary, refer to the codec signal and r_codec_interface_array defined in the router_top_level_tb in the source code

   1. 注意spw Rx_IR and Rx_Time_IR is setting to high, this configuration allows continuous data transfer without blocking due to receiver not being ready. In tb we want to simplify this complex buffer control mechanism
      <<<<<<< HEAD
7. in tb, there is a error for : external name cannot denote an element of an array

   1. use alias name
   2. directly a new monitor record
8. testcase concept

   1. testcase1:check spw link can set up, and can send first path address, then transmit data from port 1 and receive the same data through port2, 这里需要注意因为是在router 内部，所以实际check signal 应该是txdata 或者是 gen_dut_tx 中的codec_Rx_data
      1. Tx\_IR is controlled by the IP core and Tx\_OR is asserted by user logic.
      2. Rx_OR is output and is set by the core, and Rx_IR is controlled by user logic
      3. 在generate spw_tx 时 assert all codecs.Rx_IR
   2. testcase2: che
9. 不同的procedure can interact with each other

   1. use shared signal
   2. shared variables
   3. parameter passing
10. install UVVM

# 13.02-16

1. use UVVM
   1. do $DUT/UVVM-master/script/compile_all.do $DUT/UVVM-master/script $DUT/SpW_router/spw_router_sim
   2. all methods are defined in methods_pkg.vhd
2. BFMs vs VVC
   1. the limitation of process-based BFMs: a process can only execute one thing at a time. when it's running a BFM procedure, it's locked into that task

## 17.02--

* [ ]  optimize the router_fifo_ctrl_top

1. new system top-level file
   1. when declare component, if your component uses generics, you must declare them in the component declaration
   2. structured naming approach
      1. signal type
      2. polarity (_n for active low)
      3. Domain
      4. Location/purpose (_pad for FPGA I/O pad )
2. router_fifo_ctrl_top
   1. remove DDR/SDR related ports, since i've configured g_mode as single
      1. vhdl allows leaving unused inputs unconnected
      2. using 'open'
      3. using default values if specified in the component declaration
   2. 因为已经集成了controller, 所以entity不需要fifo_in data, 来源于ctrl 的spw_Tx_data,spw_Tx_data 在FSM中来源于EOP, or c_port_addr,or in read_mem state = ram_data_in, => asmy_FIFO. data_out_chunk(fifo_data) => 32 bit ccsds_datain split in 4 8bit data
      1. spw_Rx_data is basically from spw_fifo_out.tx_data. need handshake signal to identify when the data is valid, the output is rx_data_out and rx_data_valid <= from not spw_Rx_con
      2. rx_data_ready? rx_ready 	<= rx_cmd_ready or rx_data_ready;  因为spw_Rx_data 用于接收raw data,所以当 SHyLoC ready 时 才能接收来自router fifo_out 传输的raw data,
   3. remove spw_fifo_in and spw_fifo_out signal in router_fifo_ctrl_top because all signal of array signa have already been assigned
   4. declare zero initialization constant for AHB input in router_pckg.vhd
      1. can't directly use others => '0', because different fields have different sizes, the compiler can't automatically convert a single bit value to different sized vector

# EGSE

1. in every EGSE the cornerstone can be identified as "common core". this component implements the fundamental functions : Telemetry monitoring, Telecommand sending, Procedure Execution, Data Archiving, and so on.
2. EGSE is used for the development of the DHU in order to be able to simulate individual instrument or S/C

# Ground Support Python GSpy

1. allows multiple SpaceWire connections to be established and monitored simultaneously from once central point
2. Tim_report:
   1. software is divided into two separate program, the Core class and Hardware class
      1. Core class acts as an interface to the outside for sending and receiving data
   2. GSpy makes extensice use of multithreading
3. 使用python 3.12 配置完成
   1. previous enviroment is 3.6. but the Qt6 don't support vision older than 3.8
