---------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_records.vhd
-- @ Engineer				: 	James E Logan
-- @ Role					:	FPGA & Electronics Engineer
-- @ Company				:	4Links 

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE/Intel Quartus 18.1+
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	for 4Links RMAP Router IP. Record Types & Initialization Constants
--								

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should coimpile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library spw;
use spw.spw_data_types.all;

library router;
use router.router_pckg.all;

package router_records is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------

	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	-- Giasler method of spliting interface to seperate In/Out records. 
	-- could use VHDL-2019 Mode Views but 2019 support is still lack-luster...
	
	type r_maxi_lite_byte is record
		tdata 	: t_byte;
		tvalid	: std_logic;
	end record r_maxi_lite_byte;
	
	type r_saxi_lite_byte is record
		tready 	: std_logic;
	end record r_saxi_lite_byte;
	
	type r_maxi_lite_nonet is record
		tdata 	: t_nonet;
		tvalid	: std_logic;
	end record r_maxi_lite_nonet;
	
	type r_saxi_lite_nonet is record
		tready 	: std_logic;
	end record r_saxi_lite_nonet;
	
	type r_maxi_lite_dword is record
		taddr	: t_dword;
		wdata 	: t_byte;
		w_en	: std_logic;
		tvalid	: std_logic;
	end record r_maxi_lite_dword;
	
	type r_saxi_lite_dword is record
		rdata	: t_byte;
		tready	: std_logic;
	end record r_saxi_lite_dword;
	
	type r_fifo_master is record
		rx_data  		: t_nonet;
		rx_valid 		: std_logic;
		rx_time			: t_byte;
		rx_time_valid 	: std_logic;
		tx_ready 		: std_logic;
		tx_time_ready	: std_logic;
		connected 		: std_logic;
	end record r_fifo_master;
	
	type r_fifo_slave is record
		tx_data  		: t_nonet;
		tx_valid 		: std_logic;
		tx_time			: t_byte;
		tx_time_valid	: std_logic;
		rx_ready 		: std_logic;
		rx_time_ready	: std_logic;
	end record r_fifo_slave;
	
	type t_fabric_data_bus is array (0 to c_fabric_bus_width-1) of t_nonet;
	type t_fabric_data_bus_array is array (natural range <>) of t_fabric_data_bus;

	type r_fabric_data_bus_m is record
		tdata 	: t_fabric_data_bus;
		tcount 	: std_logic_vector(0 to c_fabric_bus_width-1);
		tvalid	: std_logic;
	end record r_fabric_data_bus_m;
	
	type r_fabric_data_bus_s is record
		tready : std_logic;
	end record r_fabric_data_bus_s;
	
	type r_fabric_data_bus_m_array is array (natural range <>) of r_fabric_data_bus_m;
	type r_fabric_data_bus_s_array is array (natural range <>) of r_fabric_data_bus_s;

	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------
	type r_maxi_lite_byte_array is array (natural range <>) of r_maxi_lite_byte;
	type r_saxi_lite_byte_array is array (natural range <>) of r_saxi_lite_byte;
	type r_maxi_lite_nonet_array is array (natural range <>) of r_maxi_lite_nonet;
	type r_saxi_lite_nonet_array is array (natural range <>) of r_saxi_lite_nonet;
	type r_fifo_master_array is array (natural range <>) of r_fifo_master;
	type r_fifo_slave_array is array (natural range <>) of r_fifo_slave;
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------

	constant c_maxi_lite_byte : r_maxi_lite_byte :=(
		tdata => (others => '0'),
		tvalid => '0'
	);
	
	constant c_saxi_lite_byte : r_saxi_lite_byte :=(
		tready => '0'
	);
	
	constant c_maxi_lite_nonet : r_maxi_lite_nonet :=(
		tdata => (others => '0'),
		tvalid => '0'
	);
	
	constant c_saxi_lite_nonet : r_saxi_lite_nonet :=(
		tready => '0'
	);
	
	constant c_maxi_lite_dword : r_maxi_lite_dword :=(
		taddr	=> (others => '0'),
		wdata 	=> (others => '0'),
		w_en	=> '0',
		tvalid	=> '0'
	);
	
	constant c_saxi_lite_dword	: r_saxi_lite_dword :=(
		rdata => (others => '0'),
		tready => '0'
	);
	
	constant c_fifo_master : r_fifo_master :=(
		rx_data  		=> (others => '0'),
	    rx_valid 		=> '0',
		rx_time			=> (others => '0'),
		rx_time_valid 	=> '0',
        tx_ready 		=> '1',
		tx_time_ready 	=> '1',
		connected 		=> '0'
	);		
	
	constant c_fifo_slave : r_fifo_slave :=(
		tx_data  		=> (others => '0'),
		tx_valid		=> '0',
		tx_time			=> (others => '0'),
		tx_time_valid	=> '0',
		rx_ready 		=> '0',
		rx_time_ready   => '0'
	);
	
	constant  c_fabric_data_bus_m : r_fabric_data_bus_m := (
		tdata 	=> (others => (others => '0')),
		tcount 	=> (others => '0'),
		tvalid 	=> '0'
	);
	
	constant c_fabric_data_bus_s : r_fabric_data_bus_s := (
		tready 	=> '0'
	);
	

	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	

	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
end package router_records;

package body router_records is 
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------

	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	


end package body router_records;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------