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
entity router_xbar_top_level is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports;
		g_priority 	: string 				:= "fifo"
	);
	port( 
		
		-- standard register control signals --
		clk_in				: in 	std_logic := '0';		-- clk input, rising edge trigger
		rst_in				: in 	std_logic := '0';		-- reset input, active high
		
		address_req_in		: in 	t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));
		address_tar_in		: in 	t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));
		address_req_valid	: in 	std_logic := '0';
		address_req_ready	: out 	std_logic := '0';
		
		bus_in_m			: in 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
		bus_in_s			: in 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
		bus_out_m			: out 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
		bus_out_s			: out 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
		
		addr_active			: in 	t_ports := (others => '0')
		
    );
end router_xbar_top_level;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_xbar_top_level is

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
	signal	sw_address_out 	:	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0')); 	-- active Xbar Address states 
	signal	sw_address_valid:	std_logic				:= '0';								-- valid
    signal  sw_address_ready:	std_logic 				:= '0';								-- ready 
    signal	sw_req_address 	:	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0'));
	signal  sw_requesters	:	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0'));	
	signal  request_active		:   t_ports := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Alias Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------

	priority_gen: if (g_priority = "fifo" or g_priority = "FiFo") generate -- use FIFO based priority 
		
		xbar_fifo_con: entity work.router_xbar_req_arbiter_fifo_priority(rtl)
		generic map(
			g_num_ports => g_num_ports
		)
		port map( 
			
			-- standard register control signals --
			clk_in				=> clk_in,
			rst_in				=> rst_in,
			
			addr_req			=> addr_active,

			req_address_in 		=> address_req_in(0),	
			tar_address_in		=> address_tar_in(0),
			address_valid		=> address_req_valid,
			address_ready   	=> address_req_ready,
			
			sw_address_out 	 	=> sw_address_out, 
			sw_address_valid 	=> sw_address_valid,
			sw_address_ready 	=> sw_address_ready
			
		);
		
		
	else generate -- else use fair round robin priority 
		
		xbar_con: entity work.router_xbar_req_arbiter(rtl)
		generic map(
			g_num_ports => g_num_ports
		)
		port map( 
			
			-- standard register control signals --
			clk_in				=> clk_in,
			rst_in				=> rst_in,
			
			addr_req			=> addr_active,

			address_in 			=> address_req_in,	
			address_valid		=> address_req_valid,
			address_ready   	=> address_req_ready,
			
			sw_address_out 	 	=> sw_address_out, 
			sw_address_valid 	=> sw_address_valid,
			sw_address_ready 	=> sw_address_ready
			
		);
		
	end generate priority_gen;
	
	
	xbar_fabric: entity work.router_xbar_switch_fabric(rtl)
	generic map(
		g_num_ports	 => g_num_ports
	)
	port map( 
		
		-- standard register control signals --
		clk_in			=> clk_in,

		target_addr_32	=> 	sw_address_out,
		addr_valid		=> 	sw_address_valid,
		addr_ready		=> 	sw_address_ready,
		req_assert		=> 	addr_active,

		bus_in_m		=> 	bus_in_m,
		bus_in_s		=> 	bus_in_s,

		bus_out_m		=> 	bus_out_m,
		bus_out_s		=> 	bus_out_s

    );

	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------



end rtl;