# task

* [ ]  memory controller, may be GRLIB, need to be determined
* [ ]  Time code for SpaceWire
* [ ]  研究压缩数据流 到memory 后完整性
* [X]  16bits Shyloc input, Venspec-U data will always be 16 bit
* [ ]  地址数据需要删除

## week report

# router_fifo_spwctrl_16bit

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU
   do $DUT/DHU-project/simulation/script/router_fifo_ctrl.do

   do $DUT/DHU-project/simulation/script/system_SHyLoC_top_test.do
2. address_send state need to strip off the logic address (greater than 31)
3. compressor need 16 bits input data, spw transmit 8 bits data. SHyLoC receive the raw data from Router spw_fifo_out.tx_data. In the router_fifo_spwctrl module, rx_data should be assembled into a 16-bit CCSDS raw data
4. modify router_fifo_spwctrl_16bit in router_fifo_ctrl_top
5. this version is able to compress data correctly, except for the scenarios involving input logic addresses

## control_rx channel

1. add an indicator to track whether we have the upper or lower byte
   1. byte_concat_fin
2. temporarily keep rx_data_out for simulation
3. rx_data_valid will not used as datain_newvalid connected to SHyloc
4. ccsds_datanewvalid 赋值完没有deassert， 需要替代rx_data_valid
5. 还存在的问题就是会将第一个地址的数据传输出去，需要额外逻辑处理
6. 发现不但logic address 收到了，即使是path address 也没去掉
   1. 添加信号验证，主要是router_port_rx_controller rx_state should in strip_path_addr remove path address
   2. the issue was found to be that byte_concat is assert to high when receiving the first raw data
      1. however it is opposite to the simulation, i suspect it's because the byte_concat signal is not deasserted during reset
7. the issue, repeat the identical data transfer but found that each compressed data are different, the root reason is because ccsds_datanewvalid needs to be asserted only when both ccsds_data_ready and rx_data_valid are asserted simultaneously, the issue arises that ccsds_data_ready doesn't take into account the scenario where, after the rx_channel completes transmitting 16-bit data and stop receving, but it doesn't deassert ccsds_data_ready

# router_fifo_ctrl_top

1. 需要给Shyloc 的fifo_full 添加接口，full 需要停止发送数据, 但不需要在这里添加，因为这属于可能有数据遗失的情况
2. best practice is to deassert the Ready signal before the FIFO actually becomes full, rather than waiting until FIFO_Full is asserted
   1. if we wait unitil FIFO_Full is asserted before deasserting Ready
      1. Timing lag issues: when the fifo_full signal is asserted, there may already be new data in transit.
      2. Data loss risk: if the upstream device cannot respond promptly changes in the Ready signal, data sent when the FIFO is full will be lost
3. ccsds_ready_ext 用于告诉shyloc dataout 已满，不要发送压缩数据，(asym fifo)
4.

# system_SHyLoC_top_tb

debug

1. Ready_Ext asserted了，是因为ccsds_ready_ext <= '0' when fifo_full = '1' else '1';
   1. 原因是asym fifo深度不够，需要NE 设置为256

tb:

1. add use std.env.all;
   stop(0);                        --is commonly used to immediately terminate a simulation. the parameter (0) represents an exit code of 0, indicating a normal or successful termination
2. if want to keep the sensivity list with r_shyloc.Finished, must remove all wait statements and implement a state machine to manage the flow, the remove the sensitivity List.
   1. 或者删除敏感信号

write_pixel_data

1. 将procedure改为process，因为write procedure is only called once in the stim_sequencer process
2. split read_and_send state to read_file and spw_tx two state,
   避免重复发送地址
3. 问题在于read_file number 错误，因为16bit data，但是sample_count 计算的是传输8bit 数据的数量
4.

## gen_stim

1. s_in_var: since the datainput format is not fix and it is most likely 16bits bandwidth, for convenient processing handle it by parameterizing the data type
2. read_and_send state, because spw send only 8 bits data, it need to adapt it according to SHyLoC data format
