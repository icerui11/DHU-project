04.12
1.the flash-based FPGA don't support initializing block RAMs as ROMs in the manner of a Xilinx device. similar like ProASIC sm2 don't have SRAM-based configuration that is used to 
set the contents of a block RAM meant to be used as ROM
2.trading resource for time: refers to a design optimization strategy in FPGA where you can used more hardware resources(like LUTs, registers, RAM) to achieve faster processing speed. It is essentially a trade-off relationship.