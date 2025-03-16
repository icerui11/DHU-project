# task

* [ ]  memory controller, may be GRLIB, need to be determined
* [ ]  Time code for SpaceWire
* [ ]  研究压缩数据流 到memory 后完整性
* [X]  16bits Shyloc input, Venspec-U data will always be 16 bit
* [X]  remove logic address,

## week report

point: FPGA system need generate reset signal after system,additional module to handle it, afterwards, CoreReset_PF can be instantiated

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
8. remove  the endianess convert, since it should be accomplished by ShyLoc IP

# router_fifo_spwctrl_16bit_v2

purpose: When a logic address is received, the logic address should be removed

because in this SpW network only logic address will be used, therefore, there is no need to consider the path address scenario

* [ ]  for improvement: the control_tx_fsm can be simplified because sending one byte requires 12 cycles, the ramaddr_delay is unnecessary since in theroy it only need 10 cycle to transimit 1 byte spw data

## rx_channel

define a rx FSM ,type t_rx_states is (strip_L_addr, get_Nbyte)

1. 在strip_L_addr 中因为不需要 将logic address 发送给ShyLoC, 所以不需要将等待rx_ready
2. 只有logic address 只需2 state， 发现控制位signal 去除第一个logic address
3. 需要更完整测试，目前测试是可以的

# router_fifo_ctrl_top

1. 需要给Shyloc 的fifo_full 添加接口，full 需要停止发送数据, 但不需要在这里添加，因为这属于可能有数据遗失的情况
2. best practice is to deassert the Ready signal before the FIFO actually becomes full, rather than waiting until FIFO_Full is asserted
   1. if we wait unitil FIFO_Full is asserted before deasserting Ready
      1. Timing lag issues: when the fifo_full signal is asserted, there may already be new data in transit.
      2. Data loss risk: if the upstream device cannot respond promptly changes in the Ready signal, data sent when the FIFO is full will be lost
3. ccsds_ready_ext 用于告诉shyloc dataout 已满，不要发送压缩数据，(asym fifo)
4. rx_cmd_out可以保留，用于维护系统完整性

# router_fifo_ctrl_top_v2

purpose : instantiate 3 SHyLoC compressor, therefore router_fifo_ctrl_top need to define multidimensional data type in package

create a create_fifo_map function, is to creates a mapping table

1. type t_fifo_port_map is array (1 to c_num_fifoports) of integer range 1 to g_num_ports-1; like array indices (1 to 3) which represent fifo indices, arrry value represent actual fifo port number, use this function to assign Fifo port 5,6,7 to SHyLoC 1,2,and 3 respectively, selective component instantiation with index remapping
2. create constant fifo_port_map

### router_pckg.vhd

add a spw fifo port number constant c_num_fifoports

### system_constant_pckg.vhd define the SHyloc unconstrained array

1. ccsds_datain_array
2. raw_ccsds_data_array

# system_SHyLoC_top_tb

debug

1. Ready_Ext asserted了，是因为ccsds_ready_ext <= '0' when fifo_full = '1' else '1';
   1. 原因是asym fifo深度不够，需要NE 设置为256
2. 当 使用logic address 时，tx传输了，FIFo_port却没收到数据
   1. 首先通过dut_tx(1) 对router port1 发送数据，router port1 rx_data 经过 rx_dp_fifo 再经过port_rx_controller接收数据
   2. 问题在于ip_core_router.do 里的模块 没有更新成新的module
      1. such like routing_table and mixed_width_ram router_rt_arbiter, 更新后正常了

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
