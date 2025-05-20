# scheme change

4.9 Run-time configuration file mentioned road need to modified

since there could be three 3D compression core here, that implies at least six AHB slave interfaces would be required to receive configuration data, making the design overly complex

especailly since the configuration parameters themselves don't need high-speed transfer

所以在设计中将使用IO口而不是AHB bus对compression core进行配置，所以需要将configuration module 中AHB slave不使用ahb bus进行配置

对于SHyLoC compression core 由于设计需要，需要使用processor发送configuration parameter 给FPGA，所以在设计中将使用IO口而不是AHB bus对compression core进行配置，所以需要将configuration module 中AHB slave不使用ahb bus进行配置

因为FPGA IO口有限，因此address 5bit, data 8bit. 我应该怎么设计这个IO接口，用以接收GR712 给FPGA Shyloc 的配置数据，并且使compression core 能正常配置，是否应该修改ShyLoC 中的configuration modul部分以适配IO 口接收configuration parameter, 还是IO 转APB, 再转AHB,哪种方案工作量更少, 需要trade off

# modified in toplevel of compression core

* `ccsds123_ahbs.vhd` - AHB slave interface for receiving configuration via memory-mapped registers
* `ccsds123_clk_adapt.vhd` - Handles clock domain crossing for configuration data
* `ccsds123_shyloc_interface.vhd` - Validates and distributes configuration parameters
* `ccsds123_config_core.vhd` - Top-level configuration module coordinating the above components


#
