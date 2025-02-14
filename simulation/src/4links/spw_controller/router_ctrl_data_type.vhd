----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_ctrl_data_type.vhd
-- @ Engineer				: 	Rui Yin
-- @ Role					:	FPGA Engineer
-- @ Company				:	IDA 

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Microsemi Libero SoC
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	data types for router controller
--								constructs for RTL & Testbenching. 

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should coimpile by default, added just in case....
use std.textio.all;				-- for basic textio functions


package router_ctrl_data_type is