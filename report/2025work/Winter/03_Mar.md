# task

* [ ]  memory controller, may be GRLIB, need to be determined
* [ ]  Time code for SpaceWire
* [ ]  研究压缩数据流 到memory 后完整性

# router_fifo_spwctrl_16bit

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU
   do $DUT/DHU-project/simulation/script/router_fifo_ctrl.do

   do $DUT/DHU-project/simulation/script/system_SHyLoC_top_test.do
2. address_send state need to strip off the logic address (greater than 31)
3. compressor need 16 bits input data, spw transmit 8 bits data. SHyLoC receive the raw data from Router spw_fifo_out.tx_data. In the router_fifo_spwctrl module, rx_data should be assembled into a 16-bit CCSDS raw data
4. modify router_fifo_spwctrl_16bit in router_fifo_ctrl_top

## control_rx channel

1. add an indicator to track whether we have the upper or lower byte
   1. byte_concat_fin
2. temporarily keep rx_data_out for simulation
3. rx_data_valid will not used as datain_newvalid connected to SHyloc
4. ccsds_datanewvalid 赋值完没有deassert， 需要替代rx_data_valid

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
   1. 原因是asym fifo深度不够，需要N

## gen_stim

1. s_in_var: since the datainput format is not fix and it is most likely 16bits bandwidth, for convenient processing handle it by parameterizing the data type
2. read_and_send state, because spw send only 8 bits data, it need to adapt it according to SHyLoC data format
