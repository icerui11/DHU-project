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
