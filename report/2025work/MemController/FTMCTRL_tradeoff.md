# IP requirement

32 data bits plus 16bits EDAC

SDRAM: 3GbitSDRAM3DSD3G48VQ6486 ? from jerome thesis,

* 3D PLUS manufacturer
* <br/>64M x48    <br/>133 MT/s

# CoreSDR_AHB

from microchip

feature:

1. free but need limited support for SDRAM over 1GB
2. High performance, SDR controller for standard SDRAM chips and dual in-line memory modules (DIMMs) • Synchronous interface, fully pipelined internal architecture • Supports up to 1,024 MB of memory • Bank management logic monitors status of up to 8 SDRAM banks • Support for AHB slave interface • Data access of 8, 16, or 32 bits are allowed by masters

# FTMCTRL GRLIB

can handle 4 type devices: PROM, SRAM, SDRAM and memory mapped I/O

feature:

1. External chip-selects are provided for up to to four PROM banks, one I/O bank, five SRAM banks and two SDRAM banks.
2. EDAC is supported only for 8-bit and 39 bit memories

# FTSDCTRL - 32/64-bit PC133 SDRAM Controller with EDAC GRLIB

feature:

1. compatible memory devices attached to a 32 or 64 wide data bus
2. option EDAC （only for the 32 bit bus）
3. The controller supports 64, 256 and 512 Mbyte devices with 8 - 12 column-address bits, up to 13 row-address bits, and 4 banks. The size of each of the two banks can be programmed in binary steps between 4 Mbyte and 512 Mbyte

# FTMCTRL - 8/16/32-bit Memory Controller with EDAC IP32
