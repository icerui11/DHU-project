# scheme change

4.9 Run-time configuration file mentioned road need to modified

since there could be three 3D compression core here, that implies at least six AHB slave interfaces would be required to receive configuration data, making the design overly complex

especailly since the configuration parameters themselves don't need high-speed transfer

所以在设计中将使用IO口而不是AHB bus对compression core进行配置，所以需要将configuration module 中AHB slave不使用ahb bus进行配置

对于SHyLoC compression core 由于设计需要，需要使用processor发送configuration parameter 给FPGA，所以在设计中将使用IO口而不是AHB bus对compression core进行配置，所以需要将configuration module 中AHB slave不使用ahb bus进行配置



# modified in toplevel of compression core


* `ccsds123_ahbs.vhd` - AHB slave interface for receiving configuration via memory-mapped registers
* `ccsds123_clk_adapt.vhd` - Handles clock domain crossing for configuration data
* `ccsds123_shyloc_interface.vhd` - Validates and distributes configuration parameters
* `ccsds123_config_core.vhd` - Top-level configuration module coordinating the above components
