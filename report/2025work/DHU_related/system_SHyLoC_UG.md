# system_SHyLoC_top signal connection


| router_fifo_ctrl_top | direction | ShyLoc_top_Wrapper |                          parameter                          |
| :------------------: | :-------: | :----------------: | :---------------------------------------------------------: |
|       w_update       |          | data_out_newvalid |                                                            |
|     ccsds_datain     |          |  data_out_shyloc  |        shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1        |
|   ccsds_ready_ext   |          |  ccsds_ready_ext  | ccsds_ready_ext <= '0' when fifo_full = '1' in fifo_spwctrl |
|    raw_ccsds_data    |    out    |   data_in_shyloc   |      shyloc_123.ccsds123_parameters.D_GEN-1(normal 8)      |
|  ccsds_datanewvalid  |    out    |  DataIn_NewValid  |                                                            |
|    rx_data_ready    |    in    |       Ready       |                                                            |
|     rx_cmd_valid     |    out    |        open        |                                                            |
|      rx_cmd_out      |    out    |        open        |                                                            |
|     rx_cmd_ready     |    in    |                    |                                                            |
|     rx_data_out     |          |                    |             reserved for future possible design             |
|                      |          |                    |                                                            |
|                      |          |                    |                                                            |

# system_SHyLoC_top_v2

create version2 to generate 3 SHyLoC compressor

# SHyLoC parameter

1. Configured ENDIANESS in the CCSDS121 IP core shall be always set to big endian (1).
2. Ny number of lines, Nx : number of columns,  Nz: number of bands

### From Venspec CCU-Channels SWICD

Every sensor readout shall have a fixed predefined data format (number of columns, rows, bits per pixel). The same is true for the number of readouts to compose one 3D cube array.

### Venspec-U runtime-configuration

only calculation the max parameter

spectral 2048

spatial 1024          32x32

bitdepth 16

### Venspec-H runtime-configuration

spectral 384

spatial 256          16x16



## spw_controller

### router_fifo_spwctrl_16bit

This version is able to compress data correctly, except for the scenarios involving input logic addresses. Note that the first transfer will send predefined address(currently, the transmitted address is the path address)

### router_fifo_spwctrl_16bit_v2

when the router sends a logic address, it transmits the address information together with the payload data. However, when sending to the spw_fifo port, the compressor receives non-raw data, so the address needs to be removed in the RX_channel

additionally, remove the sorting caused by endian ordering in control_rx, because the shyloc input allocates based on the data's endianness, elimination the need for the controller to allocate it agian

#### signal

* spw_Rx_IR output: map to router spw_fifo_in.tx_ready
* spw_Rx_OR input

# Sim do.file hierarchical

system_SHyLoC_top_tb_v2
==>router_fifo_ctrl_top
==>generate 1 router_fifo_spwctrl_16bit_v2
==>and 1 asym_FIFO
==>1 ShyLoc_top_Wrapper
==> gen_dut_tx 4 spw_wrap_top_level_RTG4
do $DUT/DHU-project/simulation/script/system_SHyLoC_top_test.do

router_fifo_ctrl_top

# SpaceWire Router

## router clock

in order to keep the SpaceWire link saturated, the router clock speed and data width  must be configured so that the router fabric throughput is greater than the CoDec Tx throughput.

### reset requirement

To improve timing performance, pipeline registers are inserted at several stages within the fabric  architecture. The registers have no associated resets to improve timing, therefore when performing  a system reset, the reset should be held for 5 clock cycles

## router data width

The `c_fabric_bus_width` parameter determines the internal data bus width for the crossbar switch fabric in the RMAP Router.

# decleration spw_codec

type r_codec_interface is record
-- Channels
Tx_data         : 	t_nonet;
Tx_OR           : 	std_logic;
Tx_IR           : 	std_logic;

Rx_data         : 	t_nonet;
Rx_OR           : 	std_logic;
Rx_IR           : 	std_logic;

Rx_ESC_ESC      : 	std_logic;
Rx_ESC_EOP      : 	std_logic;
Rx_ESC_EEP      : 	std_logic;
Rx_Parity_error : 	std_logic;
Rx_bits         : 	std_logic_vector(1 downto 0);
Rx_rate         : 	std_logic_vector(15 downto 0);

Rx_Time         : 	t_byte;
Rx_Time_OR      : 	std_logic;
Rx_Time_IR      : 	std_logic;

Tx_Time         : 	t_byte;
Tx_Time_OR      : 	std_logic;
Tx_Time_IR      : 	std_logic;

-- Contol
Disable         : 	std_logic;
Connected       : 	std_logic;
Error_select    : 	std_logic_vector(3 downto 0);
Error_inject    : 	std_logic;

-- DDR/SDR IO, only when "custom" mode is used
-- when instantiating, if not used, you can ignore these ports.
DDR_din_r		: 	std_logic;
DDR_din_f   	: 	std_logic;
DDR_sin_r   	: 	std_logic;
DDR_sin_f   	: 	std_logic;
SDR_Dout		:  	std_logic;
SDR_Sout		:  	std_logic;

-- SpW
Din_p    		:  	std_logic;
Din_n    		:  	std_logic;
Sin_p    		:  	std_logic;
Sin_n    		:  	std_logic;
Dout_p   		: 	std_logic;
Dout_n   		: 	std_logic;
Sout_p   		:	std_logic;
Sout_n   		: 	std_logic;
end record r_codec_interface;

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
