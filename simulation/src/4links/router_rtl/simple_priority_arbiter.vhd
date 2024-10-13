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
context work.router_context;

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity simple_priority_arbiter is
	generic(
		g_port_num 	: natural range 1 to 32 := c_num_ports
	);
	port( 
		
		clk_in		: in 	std_logic := '0';
		
		reqs_in		: in 	t_ports := (others => '0');
		grant_out	: out 	t_ports := (others => '0')

		
    );
end simple_priority_arbiter;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of simple_priority_arbiter is


	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal higher_priority_reqs : std_logic_vector(g_port_num-1 downto 0) := (others => '0');
	signal reqs_in_reg 	: t_ports := (others => '0');

	
begin


	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	higher_priority_reqs(g_port_num-1 downto 1) <= higher_priority_reqs(g_port_num-2 downto 0) or reqs_in_reg(g_port_num-2 downto 0);
	higher_priority_reqs(0) <= '0';
--	grant_out(g_port_num-1 downto 0) <= reqs_in and not(higher_priority_reqs(g_port_num-1 downto 0));
	
	process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			reqs_in_reg <= reqs_in;
			grant_out(g_port_num-1 downto 0) <= reqs_in_reg and not(higher_priority_reqs(g_port_num-1 downto 0));
		end if;
	end process;
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------



end rtl;