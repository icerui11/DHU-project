----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_fabric_mux_32.vhd
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	2

-- File Description         :	1 to 32 fabric multiplexer 	

-- Document Number			:   xxx-xxxx-xxx
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
entity router_fabric_mux_32 is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports
	);
	port( 	
		target_addr		: in 	t_ports		:= (others => '0');
		req_addr		: in 	t_ports 	:= (others => '0');
		
		data_in_m		: in 	r_fabric_data_bus_m								:= c_fabric_data_bus_m; -- port valid, data, count input 
		data_in_s		: in 	r_fabric_data_bus_s								:= c_fabric_data_bus_s;	-- target ready input
		
		data_out_m		: out 	r_fabric_data_bus_m_array(0 to g_num_ports-1)	:= (others => c_fabric_data_bus_m);
		data_out_s		: out   r_fabric_data_bus_s_array(0 to g_num_ports-1)   := (others => c_fabric_data_bus_s)

    );
end router_fabric_mux_32;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_fabric_mux_32 is

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

	mux_gen: for i in 0 to g_num_ports-1 generate
		data_out_m(i).tvalid 		<= (target_addr(i) and data_in_m.tvalid);	-- mask off required bits 
		data_out_m(i).tcount 		<= data_in_m.tcount;						-- output byte valid count 
		data_out_m(i).tdata 		<= data_in_m.tdata;							-- data broadcast to all channels, this will be synthesized to a single net
		data_out_s(i).tready 		<= (req_addr(i) and data_in_s.tready);		-- mask off required bits 
	end generate mux_gen;

	
	---------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------



end rtl;