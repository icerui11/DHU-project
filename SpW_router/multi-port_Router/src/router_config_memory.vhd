----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_config_memory.vhd
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	2

-- File Description         :	router configuration memory controller

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
entity router_config_memory is
	generic(
		g_addr_width 	: natural range 4 to 16 	:= 5;		-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		: t_byte 					:= x"01"	-- axi Bus address for this module configure in router_pckg.vhd
	);
	port( 
		-- standard register control signals --
		in_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		out_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		in_rst			: in 	std_logic 			:= '0';		-- reset input, active high
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			: in 	r_maxi_lite_dword	:= c_maxi_lite_dword;
		axi_out			: out 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		
		config_mem_out	: out 	t_byte_array(0 to 31) := (others => (others => '0'))
    );
end router_config_memory;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
/*
	contains read/write registers 	0  to 31 == Port Control Registers, 
									32 to 35 == System Config Registers
*/

architecture rtl of router_config_memory is

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
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal config_mem 	: t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	signal axi_addr 	: natural range 0 to (2**g_addr_width)-1 	:= 0;								-- address is for both read & write 
	signal rd_data		: t_byte 									:= (others => '0');
	signal wr_data		: t_byte 									:= (others => '0');
	signal wr_en 		: std_logic 								:= '0';
	signal is_valid		: std_logic									:= '0';
	
	signal sync_reg_2		:  	t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	signal sync_reg_1		: 	t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
--	config_mem_out <= config_mem(0 to c_num_config_reg-1);		-- register outputs...
--	axi_out.rdata   <= config_mem(axi_addr);			-- read back byte at axi address byte 
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-- handles AXI handshake and registers IO with config port 
	-- router clock domain 
	axi_proc: process(in_clk)
	begin
		if(rising_edge(in_clk)) then
			if(in_rst = '1') then
				axi_out.tready 	<= '0';									-- force de-assert ready..
				is_valid 		<= '0';			
			--	config_mem 		<= (others => (others => '0'));
			else
				axi_out.tready <= '0';
				is_valid <= '0';
				wr_data 		<= axi_in.wdata;					-- load write data to register
				axi_out.rdata   <= config_mem(axi_addr);			-- read back byte at axi address byte 	
				axi_addr 		<= to_integer(unsigned(axi_in.taddr(g_addr_width-1 downto 0)));	-- get requested address
				
				if(axi_in.tvalid = '1' and axi_in.taddr(23 downto 16) = g_axi_addr) then				-- handshake request and valid address for this module ?
					is_valid 		<= '1';															-- valid high ? (used for register preload)
					wr_en 			<= axi_in.w_en;						    						-- load write status 				
				end if;
				
				if(is_valid = '1' and axi_in.tvalid = '1') then				-- bus target valid ?
					axi_out.tready 	<= '1';									-- assert handshake ready 
				end if;			

				if(axi_out.tready = '1' and axi_in.tvalid = '1') then		-- axi handshake asserted ?
					axi_out.tready 	<= '0';									-- force de-assert ready..
					is_valid 		<= '0';									-- de-assert pre-load 
				end if;
				
				if(wr_en = '1')then											-- write enable asserted ?
					config_mem(axi_addr) <= wr_data;						-- write config byte to element
				end if;
			end if;
		end if;
	end process;
	
	-- dual register outputs in spacewire clock domain 
	out_proc: process(out_clk)
	begin
		if(rising_edge(out_clk)) then
			sync_reg_1 <= config_mem;
			config_mem_out <= sync_reg_1;
		end if;
	end process;


end rtl;