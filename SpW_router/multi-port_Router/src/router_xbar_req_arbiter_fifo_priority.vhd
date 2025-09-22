----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_xbar_req_arbiter_fifo_priority.vhd
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
entity router_xbar_req_arbiter_fifo_priority is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports
	);
	port( 
		
		-- standard register control signals --
		clk_in			: in 	std_logic := '0';		-- clk input, rising edge trigger
		rst_in			: in 	std_logic := '0';		-- reset input, active high
		
		addr_req		: in 	t_ports 				:= (others => '0');		-- input bits ('1' = wants control of output)

		tar_address_in 	: in	t_ports					:= (others => '0'); 	-- target address to be added to queue
		req_address_in	: in 	t_ports					:= (others => '0');		-- request address to be added to queue 
		address_valid	: in	std_logic 				:= '0';					-- valid
		address_ready   : out 	std_logic 				:= '0';					-- ready
		
		sw_address_out 	: out 	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0')); 	-- active Xbar Address states 
		sw_address_valid: out 	std_logic				:= '0';								-- valid
        sw_address_ready: in 	std_logic 				:= '0'							-- ready 
	
    );
end router_xbar_req_arbiter_fifo_priority;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
-- performs arbitration of single port for 32-way Xbar router. 
-- generate required number in top-level XBar Fabric controller logic. 
/*
	Active requests are serviced using a fair round-robin arbitation method. For each target port,
	fair-round-robin arbitation is also used to determine the current valid output.
	if arbitated targets are equal to the required targets for that requester, the ports are assigned AND
	locked until the active requester de-asserts its request. 
	the same RR pointer is shared between rquester and target RR arbitation.
	Target arbitration is synchronized to the requester arbitration using a toggle signal. 
	
	This implementation supports full Non-Blocking comminication for non-conflicting target ports. 
	It can also resolve simulataneous multicast requests with conflicting port assignments. 
	
	full implementa is "Fair Round-Robin with low-port priority access". Lower port numbers will be given priority if the RR pointer
	is not active. All ports will be serviced, regardless of request, in  N-Request cycles, where N is the number of ports on Xbar farbic.	
	Each request cycle lasts around 12 clock cycles. 
*/


architecture rtl of router_xbar_req_arbiter_fifo_priority is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_arbiter_state is(
		get_requests, 			-- 1 or more requests to be processed
		grant_access,			-- grant request access 
		check_targets,			-- check granted vs requested target ports
		submit_requests,		-- submit requester addresses to Xbar fabric 
		move_pointer			-- move round robin pointer to next element. 
	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal arbiter_state 			: t_arbiter_state;-- := get_requests;	-- states for arbiter 
	signal clk_delays 				: integer range 0 to 3 := 0;
	signal stack_rd_pointer 		: integer range 0 to (g_num_ports-1) := 0;							-- stack write pointer
	signal stack_wr_pointer 		: integer range 0 to (g_num_ports) := 0;							-- stack write pointer
	signal stack_target_queue		: t_ports_array(0 to g_num_ports) := (others => (others => '0'));	-- stack target_queue
	signal stack_request_queue		: t_ports_array(0 to g_num_ports) := (others => (others => '0'));	-- stack request queue 
	signal active_tar_queue			: t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));	-- active targets 
	signal active_req_queue			: t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));	-- active targets 
	signal tar_comp_reg				: t_ports := (others => '0');
	signal req_comp_reg				: t_ports := (others => '0');
	signal grant_okay				: t_ports := (others => '0');
	
	signal tar_is_null				: boolean;		-- target is all NULL
	signal tar_conflict				: t_bool_array(0 to g_num_ports-1) := (others => false);	-- target conflict on assignment 
	signal tar_p_conflict			: boolean := false;	-- target conflict with priority port assignment. 
	signal tar_rd_0					: boolean := false;											-- read pointer is 0
	signal bool_grant				: boolean := false;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin



	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------

	-- get output access queue buffer from target access map
	v_gen_1: for i in 0 to g_num_ports-1 generate			-- get target bits
		v_gen_2: for j in 0 to g_num_ports-1 generate		-- get requester port
			active_req_queue(i)(j) <= active_tar_queue(j)(i);	-- get active requesters from ordered active target list 
		end generate v_gen_2;
		
	--	sw_req_address(i) <= active_tar_queue(i);
	end generate v_gen_1;
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	
	-- main arbitration FSM process 
	main_proc:process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			address_ready <= '0';
			sw_address_out <= active_tar_queue;	-- output active target address list
		--	sw_requesters <= active_req_queue;	-- output active request address list
			bool_grant 		<= grant_okay = port_1_gen;
			tar_is_null 	<= tar_comp_reg = port_0_gen;	
			tar_p_conflict	<= ((tar_comp_reg and stack_target_queue(0)) = port_0_gen);	-- asserted when no priority port conflict 
			tar_rd_0		<= (stack_rd_pointer = 0);								-- asserted when read pointer is at priority port 
			
			if(rst_in = '1') then
				stack_wr_pointer 	<= 0;
				stack_rd_pointer 	<= 0;
				clk_delays 			<= 0;
				stack_target_queue 	<= (others => (others => '0'));
				stack_request_queue <= (others => (others => '0'));
				arbiter_state 		<= get_requests;
			else
				case arbiter_state is
					when get_requests 		=> 	-- get outstanding requests 
						address_ready <= '1';
						arbiter_state <= grant_access;
						
					when grant_access 		=>	-- grant access to priority 
						tar_comp_reg <= stack_target_queue(stack_rd_pointer);
						req_comp_reg <= stack_request_queue(stack_rd_pointer);
						arbiter_state <= check_targets;
						
					when check_targets 		=>	-- check for port conflict
				
						if(clk_delays = 3) then
							clk_delays <= 0;
							arbiter_state <= get_requests;
				
							if(bool_grant) then
								for i in 0 to g_num_ports-1 loop
									if(req_comp_reg(i) = '1') then				-- get correct queue element 
										active_tar_queue(i) <= tar_comp_reg;	-- load new targets at selected queue element. 
									end if;
								end loop;
								arbiter_state <= submit_requests;
							end if;
						
							
							if(not(bool_grant)) then
								if(stack_rd_pointer = g_num_ports-1) then
									stack_rd_pointer <= 0;
								else
									stack_rd_pointer <= stack_rd_pointer + 1;
								end if;
							end if;
							
							if(not(bool_grant) and tar_is_null) then -- not granted and no valid targets in stack element ?
								stack_rd_pointer <= 0; -- likely read pointer > current write pointer, so no valid address/targets
							end if;
							
						else
							clk_delays <= clk_delays + 1;
						end if;

					when submit_requests 	=>		-- update rd/wr pointers. Shift data as required 
						sw_address_valid <= '1';
						if(sw_address_valid = '1' and sw_address_ready = '1') then
							sw_address_valid <= '0';
							arbiter_state <= move_pointer;
						end if;
						
					when move_pointer =>	-- update rd/wr pointers. Shift data as required 
						
						-- shift across (if pointer is not on last element)
						for i in 0 to g_num_ports-1 loop
							if(i = stack_rd_pointer) then
								stack_target_queue(i to g_num_ports-1) <= stack_target_queue(i+1 to g_num_ports);-- & port_0_gen; 
								stack_request_queue(i to g_num_ports-1)  <= stack_request_queue(i+1 to g_num_ports);-- & port_0_gen;
							end if;
						end loop;
						
						stack_target_queue(g_num_ports) <= port_0_gen;
						stack_request_queue(g_num_ports) <= port_0_gen;
						
						stack_rd_pointer <= 0;	
 

						if(stack_wr_pointer /= 0) then
							stack_wr_pointer <= stack_wr_pointer - 1;	-- reduce write pointer 
						end if;
						arbiter_state <= get_requests;
				end case;
			
			end if;
			
			if(address_ready = '1' and address_valid = '1') then	-- load next queue element
				stack_target_queue(stack_wr_pointer) 	<= 	tar_address_in;	-- get new target list 
				stack_request_queue(stack_wr_pointer) 	<=  req_address_in;	-- get new request list 
				
				if(stack_wr_pointer /= g_num_ports) then
					stack_wr_pointer <= stack_wr_pointer + 1;					-- increment stack pointer to next element in stack 
				end if;
				address_ready <= '0';
			end if;
			
			-- reset logic on address request de-asserted 
			for i in 0 to g_num_ports-1 loop									
				if(addr_req(i) = '0') then			-- RX port has de-asserted request ?
					active_tar_queue(i) <= (others => '0');	-- wipe target queue 
					sw_address_out(i) <= (others => '0');	-- wipe output queue
				end if;
			end loop;

		end if;
	end process;
	
	-- want to pipeline all of this larger comparisons for better timing...
	-- performs target masking for each requester based on target selection 
	-- This should *probably* be optimized 
	mask_gen: for i in 0 to g_num_ports-1 generate 
		mask_proc: process(clk_in)
		begin
			if(rising_edge(clk_in)) then
				grant_okay(i) <= '0';		-- '0' when conflict or blocking priority port 
				tar_conflict(i) <= ((tar_comp_reg and active_tar_queue(i)) = port_0_gen);	-- asserted when no port conflicts 			
				if(tar_conflict(i) and not(tar_is_null)) then	-- no conflicts on port ?
					if(not(tar_rd_0) and tar_p_conflict) then		-- not blocking the priority port ?
						grant_okay(i) <= '1';	-- '1' when no conflict for target on ports 
					end if;
					
					if(tar_rd_0) then		-- is priority port 
						grant_okay(i) <= '1';
					end if;
				end if;
			end if;
		end process;
	
	end generate mask_gen;

end rtl;