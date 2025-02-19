# system_SHyLoC_top signal connection


| router_fifo_ctrl_top | direction | ShyLoc_top_Wrapper |                          parameter                          |
| :------------------: | :-------: | :----------------: | :---------------------------------------------------------: |
|       w_update       |          | data_out_newvalid |                                                            |
|     ccsds_datain     |          |  data_out_shyloc  |        shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1        |
|   ccsds_ready_ext   |          |  ccsds_ready_ext  | ccsds_ready_ext <= '0' when fifo_full = '1' in fifo_spwctrl |
|     rx_data_out     |    out    |   data_in_shyloc   |      shyloc_123.ccsds123_parameters.D_GEN-1(normal 8)      |
|    rx_data_valid    |    out    |  DataIn_NewValid  |                                                            |
|    rx_data_ready    |    in    |       ready       |                                                            |
|     rx_cmd_valid     |    out    |        open        |                                                            |
|      rx_cmd_out      |    out    |        open        |                                                            |
|     rx_cmd_ready     |    in    |                    |                                                            |
|                      |          |                    |                                                            |
|                      |          |                    |                                                            |
|                      |          |                    |                                                            |

# Timing

create_clock -ignore_errors -name {OSC_C0_0/OSC_C0_0/I_RCOSC_25_50MHZ/CLKOUT} -period 20 [ get_pins { OSC_C0_0/OSC_C0_0/I_RCOSC_25_50MHZ/CLKOUT } ]
create_generated_clock -name {FCCC_C0_0/FCCC_C0_0/GL0} -multiply_by 12 -divide_by 6 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/RCOSC_25_50MHZ } ] -phase 0 [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ]
create_generated_clock -name {FCCC_C0_0/FCCC_C0_0/GL1} -multiply_by 12 -divide_by 6 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/RCOSC_25_50MHZ } ] -phase 0 [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL1 } ]


* -period 20 ,       50MHz
* GL0                    50x12/6 =100MHz
* GL1


# io Constraint

* rst_n_pad                H23          SW4
* rst_n_spw_pad        J25           SW1
*

set_io {Din_p[1]}     
-pinname AD33     
-fixed yes        
-DIRECTION INPUT

set_io {Din_p[2]}     
-pinname AF28     
-fixed yes        
-DIRECTION INPUT

set_io {Din_p[3]}     
-pinname W31      
-fixed yes        
-DIRECTION INPUT

set_io {Din_p[4]}     
-pinname AC25     
-fixed yes        
-DIRECTION INPUT

set_io {Dout_p[1]}     
-pinname AA33      
-fixed yes         
-DIRECTION OUTPUT

set_io {Dout_p[2]}     
-pinname AF30      
-fixed yes         
-DIRECTION OUTPUT

set_io {Dout_p[3]}     
-pinname AG30      
-fixed yes         
-DIRECTION OUTPUT

set_io {Dout_p[4]}     
-pinname AB25      
-fixed yes         
-DIRECTION OUTPUT

set_io {Sin_p[1]}     
-pinname AD34     
-fixed yes        
-DIRECTION INPUT

set_io {Sin_p[2]}     
-pinname AE28     
-fixed yes        
-DIRECTION INPUT

set_io {Sin_p[3]}     
-pinname V31      
-fixed yes        
-DIRECTION INPUT

set_io {Sin_p[4]}     
-pinname AC26     
-fixed yes        
-DIRECTION INPUT

set_io {Sout_p[1]}     
-pinname AA34      
-fixed yes         
-DIRECTION OUTPUT

set_io {Sout_p[2]}     
-pinname AG31      
-fixed yes         
-DIRECTION OUTPUT

set_io {Sout_p[3]}     
-pinname AF29      
-fixed yes         
-DIRECTION OUTPUT

set_io {Sout_p[4]}     
-pinname AB26      
-fixed yes         
-DIRECTION OUTPUT

set_io rst_n_pad
-pinname H23
-fixed yes
-DIRECTION INPUT

set_io spw_fmc_en      
-pinname AE31      
-fixed yes         
-DIRECTION OUTPUT

set_io spw_fmc_en_2    
-pinname AE32      
-fixed yes         
-DIRECTION OUTPUT

set_io spw_fmc_en_3    
-pinname AD28      
-fixed yes         
-DIRECTION OUTPUT

set_io spw_fmc_en_4
-pinname AD29
-fixed yes
-DIRECTION OUTPUT
