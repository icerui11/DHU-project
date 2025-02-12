# testcase design

1. Normal functionality tests
2. Boundary condition tests
3. Error handlign tests

classic testbench

router_fifo_ctrl_top 数据类型应该都该array，应该和router 的port数量有关，定义新的数据package


|  spw_fifo_in  |  | from | col3 |
| :-----------: | :-: | :--: | :--: |
|    rx_data    |  |      |      |
|   rx_valid   |  |      |      |
|   connected   |  |      |      |
|    rx_time    |  |      |      |
| rx_time_valid |  |      |      |
|   tx_ready   |  |      |      |
| tx_time_ready |  |      |      |


| spw_fifo_out  | col2 | col3 |
| ------------- | ---- | ---- |
| tx_data       |      |      |
| tx_valid      |      |      |
| tx_time       |      |      |
| tx_time_valid |      |      |
| rx_ready      |      |      |
| rx_time_ready |      |      |

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
2. fifo
