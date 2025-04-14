--------------------------------------------------------------------------------
-- Company: IDA
--
-- File: router_ahb_reg.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: This register module is derived from router_status_reg and has been extended
--              with an AHB slave interface.
--              AXI bus x"06"
--
-- <Description here>
--
-- Targeted device: <Family::SmartFusion2> <Die::M2S150TS> <Package::1152 FC>
-- Author: Rui Yin
--
--------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-- Library Declarations  --
----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------------------------------------------------------
-- Package Declarations --
----------------------------------------------------------------------------------------------------------------------------------
-- use work.ip4l_data_types.all;
context work.router_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity router_ahb_reg is
	generic(
        --AHB parameters
        hindex          : integer := 0;		-- AHB slave index
        haddr   : integer := 0;             --!Slave address
        hmask   : integer := 16#fff#;       --!Slave mask   
        -- register parameters        
		g_addr_width 	: natural range 5 to 16 	:= 8;		-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		: t_byte 					:= x"06"	-- axi Bus address for this module configure in router_pckg.vhd
	);
	port( 
		
		-- standard register control signals --
		in_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		out_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		out_rst			: in 	std_logic 			:= '0';		-- reset input, active high
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			: in 	r_maxi_lite_dword	:= c_maxi_lite_dword; 	-- wdata is unused as this is a read only module 
		axi_out			: out 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		
		status_reg_in	: in 	t_byte_array(0 to (2**g_addr_width)-1) := (others => (others => '0'))	-- status register inputs 
		
    );
end router_ahb_reg;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
-- c_num_stat_reg is stored in router.router_pckg(.vhd) library file. Top Constant Declarations....


architecture rtl of router_ahb_reg is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal axi_addr 	: integer range 0 to (2**g_addr_width)-1 := 0;	-- convert axi address LSByte to integer
	signal rd_data		: t_byte := (others => '0');
	signal status_reg 	: t_byte_array(0 to (2**g_addr_width)-1) := (others => (others => '0'));
	signal is_valid		: std_logic := '0';		-- flag reg used to track valid assertions. 
	
	signal sync_reg_2	: t_byte_array(0 to (2**g_addr_width)-1) := (others => (others => '0'));
	signal sync_reg_1	: t_byte_array(0 to (2**g_addr_width)-1) := (others => (others => '0'));
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------


	
begin


	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	axi_proc: process(out_clk)
	begin
		if(rising_edge(out_clk)) then
			axi_out.tready <= '0';	-- de-assert axi ready 
			is_valid <= '0';		-- de-assert valid target flag
			
			if(axi_in.tvalid = '1' and axi_in.taddr(23 downto 16) = g_axi_addr) then
				is_valid 	<= '1';			-- assert that target is valid for this address. 
				axi_addr 	<= to_integer(unsigned(axi_in.taddr(g_addr_width-1 downto 0)));	-- get register address	
			end if;
			
			if(axi_in.tvalid = '1' and is_valid = '1') then
				axi_out.tready <= '1';			-- assert ready now read data will be ready 
				axi_out.rdata <= status_reg(axi_addr);
			end if;
			
			if(axi_out.tready = '1' and axi_in.tvalid = '1') then
				axi_out.tready <= '0';		-- de-assert handshake
				is_valid <= '0';			-- de-assert proload 
			end if;
			status_reg(0 to (2**g_addr_width)-1) <= sync_reg_2; 
		end if;
	end process;
	-- ports write to their own status register, no need for WR address on Ports..

	sync_proc: process(in_clk)
	begin
		if(rising_edge(in_clk)) then
			sync_reg_1 <= status_reg_in;
			sync_reg_2 <= sync_reg_1;
		end if;
	end process;


end rtl;