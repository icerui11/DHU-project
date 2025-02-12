# 04.02``本周任务

* [ ]  完成SHyLoc_subtop testbench and tcl
* [ ]  完成router_fifo_ctrl testbench and tcl
* [ ]  上板进行综合

## ~~~~high priority task

* [ ]  study python
* [ ]  EGSE Ground Support Python GSpy

  * [ ]  configurate enviroment and install dependency
* [X]  build test script for router_ctrl
* [ ]  verification for controller

  * [ ]  coverage report
  * [ ]  testcase

# ~~~~04.02-12

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU
   1. do $DUT/DHU-project/simulation/script/router_fifo_ctrl.do
   2. write new script
   3. 注意编译新的routing_table都要用version 2
2. 重新编写router_fifo_ctrl_top_tb,因为之前的tb 只generate 了一个spw tx, 更新的testbench should according to predefined package g_num_ports and c_fifo_ports决定generated spw instances.
3. 因为spw become as a arrary, refer to the codec signal and r_codec_interface_array defined in the router_top_level_tb in the source code
   1. 注意spw Rx_IR and Rx_Time_IR is setting to high, this configuration allows continuous data transfer without blocking due to receiver not being ready. In tb we want to simplify this complex buffer control mechanism
4. in tb, there is a error for : external name cannot denote an element of an array
   1. use alias name
   2. directly a new monitor record
5. testcase concept
   1. testcase1:check spw link can set up, and can send first path address, then transmit data from port 1 and receive the same data through port2, 这里需要注意因为是在router 内部，所以实际check signal 应该是txdata 或者是 gen_dut_tx 中的codec_Rx_data
      1. Tx\_IR is controlled by the IP core and Tx\_OR is asserted by user logic.
      2. Rx_OR is output and is set by the core, and Rx_IR is controlled by user logic
      3. 在generate spw_tx 时 assert all codecs.Rx_IR
   2. testcase2: che
6. 不同的procedure can interact with each other
   1. use shared signal
   2. shared variables
   3. parameter passing

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
