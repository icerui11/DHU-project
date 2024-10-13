----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   2008
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
entity router_xbar_target_arbiter is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports
	);
	port( 
		
		-- standard register control signals --
		clk_in		: in 	std_logic := '0';		-- clk input, rising edge trigger
		rst_in		: in 	std_logic := '0';		-- reset input, active high

		
		arb_sync	: in 	std_logic := '0';					-- toggled to synchronize with Requester arbitration logic 
	--	rr_pointer	: in 	t_ports 	:= (others => '0');		-- pointer is synchonized with Requester arbitration logic 
		pointer_mask: in 	t_ports 	:= (others => '0');
		addr_req	: in 	t_ports 	:= (others => '0');		-- input bits ('1' = wants control of output)
		req_lock	: in 	t_ports 	:= (others => '0');	
		
		addr_active : in	t_ports 	:= (others => '0');		-- assert to clear current output, check new inputs. 
		addr_gnt 	: out	t_ports		:= (others => '0')		-- active output channel, only 1 at a time. 
    );
end router_xbar_target_arbiter;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
/*
	Previous design of this module performed arbitration. 
	Now, this simply masks the outstanding requester addresses with the current
	assigned requester from controller logic. 
	
	performs the same function, greatly reduces logic required to implement. 
	legacy version still available in subdirectory as required. 


*/
architecture rtl of router_xbar_target_arbiter is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_arbiter_state is(
		get_requests, 			-- 1 or more requests to be processed
		grant_access,			-- grant request access 
		get_response,
		lock_access
	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------


	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal arbiter_state 			: t_arbiter_state;-- := get_requests;	-- states for arbiter 

	signal rr_pointer_reg			: t_dword := (0 => '1', others => '0');-- round roubin priority pointer. 
	
	signal pointer_mask_reg			: t_dword := (others => '0');

	signal req_queue				: t_dword := (others => '0');
	signal req_queue_old			: t_dword := (others => '0');
	
	signal clk_delays				: integer range 0 to 4 := 0;
	signal grant_locked_reg			: t_dword := (others => '0');
	
	signal req_lock_reg				: t_ports := (others => '0');
	signal check_active				: t_ports := (others => '0');
	signal lock_check				: t_ports := (others => '0');
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin
	
---------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------



	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			req_lock_reg <= req_lock;
			check_active <= (addr_active and addr_gnt);
			lock_check <= (req_lock_reg and addr_gnt);
			pointer_mask_reg(g_num_ports-1 downto 0) <= pointer_mask;	-- load in pointer mask bit
			if(rst_in = '1') then
				clk_delays <= 0;
				arbiter_state <= get_requests;
			else
				case arbiter_state is 
					
					when get_requests =>	-- get request queue 
					
					--	pointer_mask_reg(g_num_ports-1 downto 0) <= pointer_mask;
						req_queue(g_num_ports-1 downto 0) <= addr_req;	-- load in request queue
						if(arb_sync = '1') then
							arbiter_state <= grant_access;	-- perform arbitatin 
						end if;
						
					when grant_access =>
				
						addr_gnt <= pointer_mask_reg(g_num_ports-1 downto 0) and req_queue(g_num_ports-1 downto 0);	-- if address to assign at current pointer, this will be high
						
						if(clk_delays = 3) then
							clk_delays <= 0;
							arbiter_state <= get_response;							-- check is arbitation is OKAY
						else
							clk_delays <= clk_delays + 1;
						end if;
						
					when get_response =>
					
						if(clk_delays = 3) then										-- wait for comparison response from requester logic 
							clk_delays <= 0;
							arbiter_state <= get_requests;
							if(lock_check /= port_0_gen) then                    -- Requester arbiter requests to lock ports ?
								arbiter_state <= lock_access;						-- lock target access 
							end if;
						else
							clk_delays <= clk_delays + 1;
						end if;
					
					when lock_access =>
	
						if(check_active = port_0_gen) then	-- Locked Requester no longer active 
							arbiter_state <= get_requests;
						end if;
					
				end case;
			end if;
		end if;
	end process;


end rtl;