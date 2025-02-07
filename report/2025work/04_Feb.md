# 04.02``本周任务

* [ ]  完成SHyLoc_subtop testbench and tcl
* [ ]  完成router_fifo_ctrl testbench and tcl
* [ ]  上板进行综合

## ~~~~high priority task

* [ ]  study python
* [ ]  EGSE Ground Support Python GSpy
  * [ ]  configurate enviroment and install dependency

# ~~~~04.02-

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU/DHU-project
2. 重新编写router_fifo_ctrl_top_tb,因为之前的tb 只generate 了一个spw tx, 更新的testbench should according to predefined package g_num_ports and c_fifo_ports决定generated spw instances.
3. 因为spw become as a arrary, refer to the codec signal and r_codec_interface_array defined in the router_top_level_tb in the source code
   1. 注意spw Rx_IR and Rx_Time_IR is setting to high, this configuration allows continuous data transfer without blocking due to receiver not being ready. In tb we want to simplify this complex buffer control mechanism

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
