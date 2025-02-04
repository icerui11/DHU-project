# 15.01~~~~

router_fifo_ctrl_top continue

1. in port part the DS port data type should be std_logic_vector(1 to g_num_ports-1)
   1. 当g_is_fifo 时直接将fifo type的数据类型和router_top_level_RTG4相连 ，每一个FIFO type都将产生一个router_fifo_spwctrl
   2. gen_fifo_controller: for i in 1 to g_num_ports-1 generate, 这里 from 0 begin due to port 0 exist only in router
   3. 在router fifo node generate 生成controller时也生成一个asymmetric fifo 因为需要将SHyLoC compressed data needs to broken down into 8bits of data so that it can be transferred via SpW , according to the manual, W_buffer_gen must be a multiple of 8, so it satisfies the condition
2. ccsds_ready_ext
3. 注意在router 中spw_fifo_out output是tx_data, 和在spw中是相反的
4. FSM sends the data via s_ram_reg via spw, so here is ram_data_in assigned to s_ram_reg in read_mem state, and asym_fifo splits the 32 bit data into 8 bit data on top to router_controller.
   Here, ram_data_in is assigned to s_ram_reg in read_mem state, and asym_fifo splits 32 bit data into 8 bit data to router_controller on top.
   So spw_Tx_data is assigned to spw_fifo_in.rx_data.
5. asym\_fifo里通过done signal 切换到下一个chunk，controller对应信号是write\_done

# ##  20.01

1. set DUT C:/Users/yinrui/Desktop/Envison_DHU/DHU-project
   1. do $DUT/SpwCodec_16bitinput/script/router_sim_test_incomplete.tcl

# 21.01

1. 测试方案：先编写testbench 测试router_fifo_ctrl_top 功能是否正常

# 23.01

1. 在router_fifo_spwctrl 中 添加 spw
2. vsim work.router_fifo_ctrl_top_tb -vopt -t 1ns -voptargs="+acc"

# 25.01

1. 在router_fifo_ controller 中 有spw_connected input, 在router 中有port_connected 信号， 将fifo port 相关port 的connected信号与之 相连

# 30.01

1. router_fifo_controller 先会在reset 后进入ready state，然后当fifo_empty =0 and spw_connected = 1  进入addr_send state
   1. 观察到状态机没进入下一个状态的原因是spw_Connected 一直为低，
   2. 但逻辑有一个硬伤，这个controller是根据spw_controller 修改的，如果是physical port, connected信号是output, 可是fifo_connected 信号是input signal
   3. fifo数据需要先从 fifo port receive, then data enter RX controller, processes the received packets, extracts destination address, requests routing table arbitration, then transfer via Crossbar Switch, establishes connection based on the routing table, transfer data from source port to destination port, then sends data through SpaceWire codec
   4. 所有需要在controller中，即使fifo port 传输的数据，第一个也需要是地址。
   5. 但根据项目方案应该是spw port 先传输数据，然后才使用FIFO port 传输数据
   6. according to Venspec design, 通过FIFO port transmit 的数据实际上是传输给port1

# 01.02-03.02

1. router_fifo_ctrl_top_tb 首先是注意router 中的connect 信号， 然后是VHDL在使用external signal时， each name in the path should be the instance label
2. 因为router_fifo_ctrl_top 中直接将router中的port_Connected 与 controller所需要的 spw_connected input 相连，所以在router_fifo_ctrl_top 的port_Connected signal can be marked as unused

   1. 32bit的ccsds_datain 只连接到router 的FIFO port
   2. w_update connect with ccsds dataout newvalid

   w_update         : in std_logic;                                                                    --connect with ccsds dataout newvalid
