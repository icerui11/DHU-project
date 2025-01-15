# 15.01~~~~

router_fifo_ctrl_top continue

1. in port part the DS port data type should be std_logic_vector(1 to g_num_ports-1)
   1. 当g_is_fifo 时直接将fifo type的数据类型和router_top_level_RTG4相连 ，每一个FIFO type都将产生一个router_fifo_spwctrl
   2. gen_fifo_controller: for i in 1 to g_num_ports-1 generate, 这里 from 0 begin due to port 0 exist only in router
   3. 在router fifo node generate 生成controller时也生成一个asymmetric fifo 因为需要将SHyLoC compressed data needs to broken down into 8bits of data so that it can be transferred via SpW , according to the manual, W_buffer_gen must be a multiple of 8, so it satisfies the condition
