----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_pckg.vhd
-- @ Engineer				: 	James E Logan
-- @ Role					:	FPGA & Electronics Engineer
-- @ Company				:	4Links ltd

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE/Intel Quartus 18.1+
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	N/A
--								

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should compile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library spw;
use spw.spw_data_types.all;
use spw.spw_codes.all;

package router_pckg is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------
	-- router top level generic configuration constants --
	constant c_fabric_bus_width 	: natural range 1 to 4 		:= 1;				-- nonet-witdth of Xbar fabric data channel. 1 = 9 bits, 4 = 36 bits
	constant c_spw_clk_freq			: real						:= 100_000_000.0;	-- frequency of SpaceWire Clock in Hz (default 200MHz)
	constant c_router_clk_freq		: real 						:= 100_000_000.0;	-- frequency of Router Fabric & Arbitration (sim only)
	constant c_num_ports 			: natural range 2 to 32  	:= 6;		        -- number of router ports, 0 is internal address, maximum 32 (31 + 1)
	constant c_port_mode			: string 					:= "single";        -- valid options are "single", "diff" and "custom". 
	constant c_priority				: string 					:= "fifo";          -- valid options are "fifo" and "none"
	constant c_ram_style			: string 					:= "auto";			-- type of ram (xilinx) to use for FiFo (block, auto, see Xillinx user guide)
	constant c_tc_master_mask		: t_dword 	:= b"0000_0000_0000_0000_0000_0000_0010_0000";	-- set single-bit high to set that port as TimeCode Master
	constant c_fifo_ports			: t_dword 	:=( -- select which ports are fifos. Ports outside c_num_ports will be ignored at synthesis
		0 	=> '0',					-- 0 has no effect, always '0' as Port 0 is an internal port, not a physical one. 
		1 	=> '0',
		2 	=> '0',
		3 	=> '0',
		4	=> '0',
		5   => '1',
		6   => '0',
		7   => '0',
		8   => '0',
		9   => '0',
		10  => '0',
		11  => '0',
		12  => '0',
		13  => '0',
		14  => '0',
		15  => '0',
		16  => '0',
		17  => '0',
		18  => '0',
		19  => '0',
		20  => '0',
		21  => '0',
		22  => '0',
		23  => '0',
		24  => '0',
		25  => '0',
		26  => '0',
		27  => '0',
		28  => '0',
		29  => '0',
		30  => '0',
		31  => '0'
	);

	constant c_num_config_reg		: natural range 96 to 255 	:= 128;		-- number of config registers 
	constant c_num_stat_reg			: natural range 96 to 255 	:= 128;		-- number of status registers 
	-- Module Addresses for AXI Bus access through config Port 0 RMAP address field. 
	constant c_routing_table_addr	: t_byte := x"00";	-- routing table RMAP address
	constant c_status_reg_addr		: t_byte := x"02";	-- Status Register RMAP Address
	constant c_spw_config_reg_addr	: t_byte := x"01";	-- SpaceWire Codec Config register RMAP Address
	constant c_misc_status_reg_addr	: t_byte := x"03";	-- misc status register, contains time code byte 
	constant c_misc_config_reg_addr	: t_byte := x"04";	-- misc config register, contains time code mask
	constant c_spw_speed_config_mem	: t_byte := x"05";	-- set spacewire Tx speed prescalar counter
	
	-- default this variable is configured at synthesis. WIth some lite modificationt his can be changed to an IO port or Configuration Register. 
	constant c_target_key			: t_byte := x"01";					-- port 0 RMAP Target Key 
	
	-- minimum is 32 as 0 to 31 are pre-assigned 
	constant c_tc_address			: integer range 0 to 31 := 0;	-- address of last time code in status registers 

	constant c_router_port_addr     : integer range 0 to 31 := 1;   -- router_fifo_ctrl transmit to which port address   

	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	-- this subtype is passed around the x-bar fabric, it's why we can't simply use the generic Configuration for port numbers 
	subtype t_ports is std_logic_vector(c_num_ports-1 downto 0);
	-- this type is especially useful for connecting the X-bar fabric and port arbitration controller(s). 
	type t_ports_array is array (natural range <>) of t_ports;
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Records	Declerations --
	--------------------------------------------------------------------------------------------------------------------------

	
	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	

	-- generate 1-hot encoding states for N wide ports 
    impure function one_ht_gen(i1 : integer; size : integer) return std_logic_vector;

    impure function one_ht_gen_array return t_dword_array;
    
	impure function point_mask_gen(i1 : integer; size : integer) return std_logic_vector;
    
    impure function point_mask_gen_array return t_dword_array;
    
	impure function port_1_gen return t_ports;

	impure function port_0_gen return std_logic_vector;
	
	impure function or_reduce_quick(std : std_logic_vector) return std_logic_vector;
	
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- generates clock signal for test-benching...
	procedure clock_gen(
		signal clock			: inout std_logic;	-- clock signal
		constant clock_num 		: natural;			-- number of clock pulses
		constant clock_period 	: time				-- clock period
	);
	
	
end package router_pckg;

package body router_pckg is 
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------
	-- returns XORed value of two 4-bit unsigned numbers

	
	
	-- generate 1-hot encoding states for N wide ports 
    	-- generate 1-hot encoding states for N wide ports 
    impure function one_ht_gen(i1 : integer; size : integer) return std_logic_vector is
        variable slv : std_logic_vector(size-1 downto 0) := (others => '0');	-- slv to return
    begin
        slv(i1) := '1';
        return slv;
    end function one_ht_gen;
	
	impure function one_ht_gen_array return t_dword_array is
		variable ret_array : t_dword_array(0 to 31);
	begin
		for i in 0 to 31 loop
			ret_array(i) := one_ht_gen(i, 32);
		end loop;
		
		return ret_array;
	end function one_ht_gen_array;
	
	
	impure function point_mask_gen(i1 : integer; size : integer) return std_logic_vector is
		variable slv : std_logic_vector(size downto 0) := (others => '1');	-- slv to return
	begin
		slv(i1 downto 0) := (others => '0');
		return slv(size downto 1);
	end function point_mask_gen;
	
	impure function point_mask_gen_array return t_dword_array is
		variable ret_array : t_dword_array(0 to 31);
	begin
	
		for i in 0 to 31 loop
			ret_array(i) := point_mask_gen(i, 32);
		end loop;
		
		return ret_array;
		
	end function point_mask_gen_array;
	
	impure function port_1_gen return t_ports is
		variable slv : t_ports := (others => '1');
	begin
		return slv;
	end function port_1_gen;
	
	impure function port_0_gen return std_logic_vector is
		variable slv	: t_ports := (others => '0');
	begin
		return slv;
	end function port_0_gen;
	
	impure function or_reduce_quick(std : std_logic_vector) return std_logic_vector is
		variable v_std : std_logic_vector(std'length-1 downto 0) := (others => '0');
	begin	
		v_std := 	(others => '0') when std = std_logic_vector(to_unsigned(0, std'length)) else
					(others => '1');
			
		return v_std;
	end function or_reduce_quick;

	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- generates clock signal for test-benching
	procedure clock_gen(
		signal   clock			: inout std_logic;	-- clock signal
		constant clock_num 		: natural;			-- number of clock pulses
		constant clock_period 	: time				-- clock period
	) is
	begin
		for i in 0 to clock_num loop
			wait for clock_period/2;
			clock <= not clock;
			wait for clock_period/2;
			clock <= not clock;
		end loop;
		report "clock gen finished" severity failure;
		wait;
	end clock_gen;
	
	
	

end package body router_pckg;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------