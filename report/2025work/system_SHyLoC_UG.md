# system_SHyLoC_top signal connection


| router_fifo_ctrl_top | direction | ShyLoc_top_Wrapper |                   parameter                   |
| :------------------: | :-------: | :----------------: | :-------------------------------------------: |
|       w_update       |           | data_out_newvalid  |                                               |
|     ccsds_datain     |           |  data_out_shyloc   | shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 |
|   ccsds_ready_ext    |           |  ccsds_ready_ext   |  ccsds_ready_ext <= '0' when fifo_full = '1' in fifo_spwctrl  |
|      rx_data_out     | out         |       data_in_shyloc  |              shyloc_123.ccsds123_parameters.D_GEN-1(normal 8)                                 |
|    rx_data_valid     |  out        |        DataIn_NewValid |                                               |
|        rx_data_ready  | in      |          ready   |                                               |
|     rx_cmd_valid  |       out    |        open            |                                               |
|     rx_cmd_out  |   out       |       open             |                                               |
| rx_cmd_ready        |  in          |                    |                                               |
|                      |           |                    |                                               |
|                      |           |                    |                                               |
|                      |           |                    |                                               |