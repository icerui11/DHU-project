# testcase design

1. Normal functionality tests
2. Boundary condition tests
3. Error handlign tests

classic testbench

router_fifo_ctrl_top 数据类型应该都该array，应该和router 的port数量有关，定义新的数据package


|  spw_fifo_in  |  | from controller | col3 |
| :-----------: | :-: | :-------------: | :--: |
|    rx_data    |  |   spw_Tx_data   |      |
|   rx_valid   |  |    spw_Tx_OR    |      |
|   connected   |  |                |      |
|    rx_time    |  |                |      |
| rx_time_valid |  |                |      |
|   tx_ready   |  |    spw_Rx_IR    |      |
| tx_time_ready |  |                |      |


| spw_fifo_out  | from controller | col3                                                                                     |
| ------------- | --------------- | ---------------------------------------------------------------------------------------- |
| tx_data       | spw_Rx_data     |                                                                                          |
| tx_valid      | spw_Rx_OR       |                                                                                          |
| tx_time       |                 |                                                                                          |
| tx_time_valid |                 |                                                                                          |
| rx_ready      | spw_Tx_IR       | in state spw_tx, Handshake signal, only when Tx_IR is asserted,<br />OR will be asserted |
| rx_time_ready |                 |                                                                                          |

new parameter g_router_port_addr is defined in router_pckg c_router_port_addr, predifine as port 1

创建新的monitor_data procedure

* placing the monitor procedure in the architecture befor begin , higher reusability
* 其余的testcase procedure 还是放在process中， direct access to all process signal and variable
  * testcase procedure use component signal, if declare before begin, there is no driven signal
* the visibility and calling of procedures depends on where they are declared

## monitor_data procedure

purpose: check whether the data transmitted through the router is consistent with the input data, this includes checking the path address, EOP, and in the future, the compressed packet headers etc

# UVVM implement

1. logging and verbosity control
   1. set_log_file_name("router_fifo_ctrl_log.txt");
      set_alert_file_name("router_fifo_ctrl_alert.txt");
   2. **log**(ID\_LOG\_HDR**,** **"Starting test sequence"**)**;**      **-- 主要测试步骤的标题** **
   3. log**(ID\_SEQUENCER**,** **"Sending data to UART"**)**;**      **-- 测试序列器的操作**
   4. **log**(ID\_BFM**,** **"Writing value 0xAA to register"**)**;**  **-- BFM 层的操作**
   5. **log**(ID\_INFO**,** **"Test configuration complete"**)**;**     **-- 一般信息**
      1. **-- 使用默认 ID** **log**(**"Simple log message"**)**;**    **-- 或使用 NOTE 级别（推荐用于简单日志）**
      2. **log**(NOTE**,** **"Another simple message"**)**;**
      3. 当不需要消息分类时
2. check_value function
   1. but if i want to check that the values of inputs and outputs are continuous, how should i handle that?

## testcase1

testcase1:check spw link can set up, and can send first path address, then transmit data from port 1 and receive the same data through port2, 这里需要注意因为是在router 内部，所以实际check signal 应该是txdata 或者是 gen_dut_tx 中的codec_Rx_data

1. Tx\_IR is controlled by the IP core and Tx\_OR is asserted by user logic.
2. Rx_OR is output and is set by the core, and Rx_IR is controlled by user logic
3. 在generate spw_tx 时 assert all codecs.Rx_IR

## testcase2

SHyLoC output compressed data, the router_controller should transmit the logic address to port1, and then through router port1 transmit compressed data

需要观察spw_tx 1 receive data是否是收到的压缩数据，controller能否将数据传回到port1

debug:

1. router port5 is unconnected, port5 是FIFO port，这时spw_fifo_in.connected need to be asserted
   1. 应该修改fifo_in.connected 逻辑，在router_controller中置一，因为一旦生成fifo port,就证明连接上了router，这样spw_config_mem 不会disable,
   2. controller 中的 spw_fifo_in and out signal are defined as signal instead as port
   3. spw_status_memory(i)(0) <= connected(i); uncomment in router_top_level_RTG4
      1. 问题是router 中Port_connected(5) 不能置1
2. fifo

Alert report:

error:

1. receive spw_port rx_data is inconsistent with controller tx_data
2. controller first data should be predifined path address

warning:

1. asym fifo is full
