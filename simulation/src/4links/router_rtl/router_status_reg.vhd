----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	2

-- File Description         :

-- Document Number			:  xxx-xxxx-xxx
----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Copyright (c) 2018-2023, 4Links Ltd All rights reserved.
--
-- Redistribution and use in source and synthesised forms, with or without 
-- modification, are permitted provided that the following conditions are met:
-- 1. Redistributions of source code must retain the above copyright notice, 
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in synthesised form must reproduce the above copyright 
--    notice, this list of conditions and the following disclaimer in the 
--    documentation and/or other materials provided with the distribution.
-- 3. All advertising materials mentioning features or use of this code
--    must display the following acknowledgement: This product includes
--    code developed by 4Links Ltd.
-- 4. Neither the name of 4Links Ltd nor the names of its contributors may be
--    used to endorse or promote products derived from this code without 
--    specific prior written permission.
--
-- THIS CODE IS PROVIDED BY 4LINKS LTD "AS IS" AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
-- EVENT SHALL 4LINKS LTD BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS CODE, EVEN IF 
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
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
entity router_status_memory is
	generic(
		g_addr_width 	: natural range 5 to 16 	:= 8;		-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		: t_byte 					:= x"02"	-- axi Bus address for this module configure in router_pckg.vhd
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
end router_status_memory;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
-- c_num_stat_reg is stored in router.router_pckg(.vhd) library file. Top Constant Declarations....


architecture rtl of router_status_memory is

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