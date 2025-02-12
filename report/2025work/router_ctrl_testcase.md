# testcase design

1. Normal functionality tests
2. Boundary condition tests
3. Error handlign tests

classic testbench

## testcase1

testcase1:check spw link can set up, and can send first path address, then transmit data from port 1 and receive the same data through port2, 这里需要注意因为是在router 内部，所以实际check signal 应该是txdata 或者是 gen_dut_tx 中的codec_Rx_data

1. Tx\_IR is controlled by the IP core and Tx\_OR is asserted by user logic.
2. Rx_OR is output and is set by the core, and Rx_IR is controlled by user logic
3. 在generate spw_tx 时 assert all codecs.Rx_IR


## testcase2

SHyLoC output compressed data, the router_controller should transmit the logic address to port1, and then through router port1 transmit compressed data
