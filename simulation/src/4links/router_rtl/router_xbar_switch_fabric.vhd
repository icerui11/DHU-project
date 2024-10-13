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
entity router_xbar_switch_fabric is
	generic(
		g_num_ports	 : natural range 1 to 32 := c_num_ports
	);
	port( 
		
		-- standard register control signals --
		clk_in			: in 	std_logic 				:= '0';		-- clk input, rising edge trigger

		target_addr_32	: in 	t_ports_array(0 to g_num_ports-1)	:= (others => (others => '0'));
		addr_valid		: in 	std_logic 				:= '0';
		addr_ready		: out 	std_logic 				:= '0';
		req_assert		: in 	t_ports	:= (others => '0');
		
		bus_in_m		: in 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
		bus_in_s		: in 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
		
		bus_out_m		: out 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
		bus_out_s		: out 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s)
		
	
    );
end router_xbar_switch_fabric;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_xbar_switch_fabric is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_xpoint_fabric_data_bus_m_array is array (natural range <>) of r_fabric_data_bus_m_array(0 to g_num_ports-1);
	type t_xpoint_fabric_data_bus_s_array is array (natural range <>) of r_fabric_data_bus_s_array(0 to g_num_ports-1);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
 
	signal xpoint_data_m_connections  		: t_xpoint_fabric_data_bus_m_array(0 to g_num_ports-1) 	:=  (others => (others => c_fabric_data_bus_m));
	signal xpoint_data_s_connections  		: t_xpoint_fabric_data_bus_s_array(0 to g_num_ports-1) 	:=  (others => (others => c_fabric_data_bus_s));

	signal xpoint_data_m_connections_out  	: t_xpoint_fabric_data_bus_m_array(0 to g_num_ports-1) 	:=  (others => (others => c_fabric_data_bus_m));
	signal xpoint_data_s_connections_out 	: t_xpoint_fabric_data_bus_s_array(0 to g_num_ports-1) 	:=  (others => (others => c_fabric_data_bus_s));
	
	
	signal target_addr_32_reg			: t_ports_array(0 to g_num_ports-1) 		:= (others => (others => '0'));
--	signal sw_targets_reg				: t_ports_array(0 to g_num_ports-1)			:= (others => (others => '0'));
--	signal sw_requesters_reg			: t_ports_array(0 to g_num_ports-1)			:= (others => (others => '0'));
--	signal route_valid_out				: t_ports_array(0 to g_num_ports-1) 		:= (others => (others => '0'));
	signal request_addr_32_reg			: t_ports_array(0 to g_num_ports-1) 		:= (others => (others => '0'));
--	signal addr_active_reg				: t_ports									:= (others => '0');
	signal tar_addr_active_reg			: t_ports									:= (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	-- left over connections will be removed in synthesis/implementation. 
	
	
	
	
xbar_encode_gen: for i in 0 to g_num_ports-1 generate
		-- decode onto bus 
		port_mux: entity work.router_fabric_mux_32(rtl)
		generic map(
			g_num_ports => g_num_ports
		)
		port map( 
			
			target_addr		=> 	target_addr_32_reg(i),
			req_addr		=> 	request_addr_32_reg(i),
			
			data_in_m		=>	bus_in_m(i),
            data_in_s	    =>  bus_in_s(i),
			
            data_out_m	    => 	xpoint_data_m_connections(i),
            data_out_s	    => 	xpoint_data_s_connections(i)

		);
		
		target_mux: entity work.router_fabric_mux_32_to_1(rtl)
		generic map(
			g_num_ports => g_num_ports
		)
		port map( 	
			clk_in			=> 	clk_in,
		--	addr_active 	=> 	addr_active_reg(i),
			data_out_m		=> 	bus_out_m(i),
			data_out_s		=> 	bus_out_s(i),

			data_in_m		=> 	xpoint_data_m_connections_out(i),
			data_in_s		=> 	xpoint_data_s_connections_out(i),
			
			sw_requesters 	=>	request_addr_32_reg(i), --sw_requesters_reg(i),
			sw_targets   	=> 	target_addr_32_reg(i)--sw_targets_reg(i)
			
		);
		
	end generate xbar_encode_gen;
	
	-- generate Xbar connections between Input N Interconnects and output N Interconnects
	xbar_decode_gen: for i in 0 to g_num_ports-1 generate
		con_gen: for j in 0 to g_num_ports-1 generate
			xpoint_data_m_connections_out(i)(j) <= xpoint_data_m_connections(j)(i);
			xpoint_data_s_connections_out(i)(j) <= xpoint_data_s_connections(j)(i);
			request_addr_32_reg(i)(j) <= target_addr_32_reg(j)(i);
	    end generate con_gen;
	end generate xbar_decode_gen;
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	
	addr_reg_proc: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
		
			addr_ready <= '0';
			if(addr_valid = '1') then		-- prevents a high-fanout net being created on ready 
				target_addr_32_reg  <= target_addr_32;
			--	sw_targets_reg		<= sw_targets;
			--	sw_requesters_reg 	<= sw_requesters;
			--	addr_active_reg		<= addr_active;
				addr_ready <= '1';
			end if;
			
			if(addr_valid = '1' and addr_ready = '1') then	-- perform "ready" acknowledgement
				addr_ready <= '0';
			end if;
			
			for i in 0 to g_num_ports-1 loop
				if(req_assert(i) = '0') then
					target_addr_32_reg(i) <= (others => '0');
				--	addr_active_reg(i) <= '0';
				--	sw_targets_reg(i) <= (others => '0');
				--	for j in 0 to g_num_ports-1 loop
				--		sw_requesters_reg(j)(i) <= '0';
				--	end loop;
				end if;
			end loop;

		end if;
		
	
	end process;
end rtl;