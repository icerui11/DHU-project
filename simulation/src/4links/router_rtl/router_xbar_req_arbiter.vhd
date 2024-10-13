----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_xbar_req_arbiter.vhd
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
entity router_xbar_req_arbiter is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports
	);
	port( 
		
		-- standard register control signals --
		clk_in			: in 	std_logic := '0';		-- clk input, rising edge trigger
		rst_in			: in 	std_logic := '0';		-- reset input, active high
		
		addr_req		: in 	t_ports 	:= (others => '0');		-- input bits ('1' = wants control of output)

		address_in 		: in	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0')); 	-- address to be added to queue
		address_valid	: in	std_logic 				:= '0';								-- valid
		address_ready   : out 	std_logic 				:= '0';								-- ready
		
		addr_active		: out 	t_ports					:= (others => '0');		-- asserted when address output is active 
		sw_address_out 	: out 	t_ports_array(0 to g_num_ports-1) 	:= (others => (others => '0')); 	-- active Xbar Address states 
		sw_address_valid: out 	std_logic				:= '0';								-- valid
        sw_address_ready: in 	std_logic 				:= '0'								-- ready 
	
		
    );
end router_xbar_req_arbiter;


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


architecture rtl of router_xbar_req_arbiter is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_one_ht_array  : t_dword_array(0 to 31) := one_ht_gen_array;
	constant c_point_mask_array : t_dword_array(0 to 31) := point_mask_gen_array;
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_arbiter_state is(
		get_requests, 			-- 1 or more requests to be processed
		grant_access,			-- grant request access 
		check_targets,			-- check granted vs requested target ports
		submit_requests			-- submit requester addresses to Xbar fabric 
	--	move_pointer			-- move round robin pointer to next element. 
	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal arbiter_state 			: t_arbiter_state;-- := get_requests;	-- states for arbiter 
	signal last_req					: t_dword := (others => '0');
	
--	signal last_gnt 		: t_ports := (others => '0');	-- grant mask bits for current grant bit 
	
	signal rr_pointer_reg				: t_dword := (0 => '1', others => '0');-- round roubin priority pointer. 
	
	signal pointer_mask				: t_dword := (others => '0');
	signal pointer_mask_and_req  	: t_dword := (others => '0');
	signal mask_grant				: t_dword := (others => '0');
	
	signal req_queue				: t_dword := (others => '0');
	signal unmask_grant				: t_dword := (others => '0');
	
	signal no_mask_and_unmask_grant : t_dword := (others => '0');
	signal grant					: t_dword := (others => '0');
	signal last_grant				: t_dword := (others => '0');
	
	signal addr_clear               : t_ports := (others => '0');
	signal clk_delays				: integer range 0 to 4 := 0;
	signal grant_locked_reg			: t_dword := (others => '0');
	
	signal target_queue				: t_dword_array(0 to 31)	:= (others => (others => '0')); 
	signal request_queue			: t_dword_array(0 to 31) := (others => (others => '0')); 
	signal port_requests			: t_dword := (others => '0');
	signal port_requests_reg		: t_dword := (others => '0');
	signal req_grant                : t_dword := (others => '0');
	signal targets_granted			: t_dword := (others => '0');
	signal targets_granted_reg		: t_dword := (others => '0');
	signal request_port 			: t_ports := (others => '0');
	signal lock_targets_mask		: t_dword := (others => '1'); 
	signal release_targets_mask     : t_dword := (others => '1');
	signal lock_targets				: t_ports := (others => '0'); 
	signal release_targets     		: t_ports := (others => '0');
	signal grants_rotated			: t_dword_array(0 to 31)	:= (others => (others => '0')); 
	signal grants_normal			: t_dword_array(0 to 31)	:= (others => (others => '0')); 
	signal arb_sync					: std_logic := '0';
	signal grant_decode				: integer range 0 to 31 := 0;
	signal addr_req_reg				: t_ports := (others => '0');
	signal new_req					: t_ports := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin

	target_arb_gen: for i in 0 to g_num_ports-1 generate
		tarb: entity work.router_xbar_target_arbiter(rtl) 
		generic map(
			g_num_ports => g_num_ports
		)
		port map( 
			
			-- standard register control signals --
			clk_in			=> 	clk_in,
			rst_in			=> 	rst_in,

			arb_sync		=> 	arb_sync,
			pointer_mask	=> 	(no_mask_and_unmask_grant(g_num_ports-1 downto 0) or mask_grant(g_num_ports-1 downto 0)),
			addr_req		=> 	request_queue(i)(g_num_ports-1 downto 0),
			req_lock		=> 	lock_targets,
			
			addr_active 	=> 	addr_req_reg,	-- assert to clear current output, check new inputs. 
			addr_gnt 		=> 	grants_rotated(i)(g_num_ports-1 downto 0)
		);
	
	end generate target_arb_gen;
	
	
	
	arb1: entity work.simple_priority_arbiter(rtl)
	generic map(
		g_port_num 	=> c_num_ports
	)
	port map( 
		clk_in		=> clk_in,
		reqs_in		=> req_queue(g_num_ports-1 downto 0),
		grant_out	=> unmask_grant(g_num_ports-1 downto 0)
		
    );
	
	arb2: entity work.simple_priority_arbiter(rtl)
	generic map(
		g_port_num 	=> c_num_ports
	)
	port map( 
		clk_in		=> clk_in,
		reqs_in		=> pointer_mask_and_req(g_num_ports-1 downto 0),
		grant_out	=> mask_grant(g_num_ports-1 downto 0)
		
    );
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------

--	no_mask_and_unmask_grant <= not(or_reduce_quick(pointer_mask_and_req)) and unmask_grant;
--	pointer_mask_and_req <= req_queue and pointer_mask;

	-- get generate pointer mask from RR register 
	with rr_pointer_reg select 
		pointer_mask <= c_point_mask_array(0) when c_one_ht_array(0),
						c_point_mask_array(1) when c_one_ht_array(1),
						c_point_mask_array(2) when c_one_ht_array(2),
						c_point_mask_array(3) when c_one_ht_array(3),
						c_point_mask_array(4) when c_one_ht_array(4),
						c_point_mask_array(5) when c_one_ht_array(5),
						c_point_mask_array(6) when c_one_ht_array(6),
						c_point_mask_array(7) when c_one_ht_array(7),
						c_point_mask_array(8) when c_one_ht_array(8),
						c_point_mask_array(9) when c_one_ht_array(9),
						c_point_mask_array(10) when c_one_ht_array(10),
						c_point_mask_array(11) when c_one_ht_array(11),
						c_point_mask_array(12) when c_one_ht_array(12),
						c_point_mask_array(13) when c_one_ht_array(13),
						c_point_mask_array(14) when c_one_ht_array(14),
						c_point_mask_array(15) when c_one_ht_array(15),
						c_point_mask_array(16) when c_one_ht_array(16),
						c_point_mask_array(17) when c_one_ht_array(17),
						c_point_mask_array(18) when c_one_ht_array(18),
						c_point_mask_array(19) when c_one_ht_array(19),
						c_point_mask_array(20) when c_one_ht_array(20),
						c_point_mask_array(21) when c_one_ht_array(21),
						c_point_mask_array(22) when c_one_ht_array(22),
						c_point_mask_array(23) when c_one_ht_array(23),
						c_point_mask_array(24) when c_one_ht_array(24),
						c_point_mask_array(25) when c_one_ht_array(25),
						c_point_mask_array(26) when c_one_ht_array(26),
						c_point_mask_array(27) when c_one_ht_array(27),
						c_point_mask_array(28) when c_one_ht_array(28),
						c_point_mask_array(29) when c_one_ht_array(29),
						c_point_mask_array(30) when c_one_ht_array(30),
						c_point_mask_array(31) when c_one_ht_array(31),
						(others => '0') when others;
					
	with req_grant select
		port_requests <= target_queue(0) when c_one_ht_array(0),
		                 target_queue(1) when c_one_ht_array(1),
		                 target_queue(2) when c_one_ht_array(2),
		                 target_queue(3) when c_one_ht_array(3),
		                 target_queue(4) when c_one_ht_array(4),
		                 target_queue(5) when c_one_ht_array(5),
		                 target_queue(6) when c_one_ht_array(6),
		                 target_queue(7) when c_one_ht_array(7),
		                 target_queue(8) when c_one_ht_array(8),
		                 target_queue(9) when c_one_ht_array(9),
		                 target_queue(10) when c_one_ht_array(10),
		                 target_queue(11) when c_one_ht_array(11),
		                 target_queue(12) when c_one_ht_array(12),
		                 target_queue(13) when c_one_ht_array(13),
						 target_queue(14) when c_one_ht_array(14),
		                 target_queue(15) when c_one_ht_array(15),
		                 target_queue(16) when c_one_ht_array(16),
		                 target_queue(17) when c_one_ht_array(17),
		                 target_queue(18) when c_one_ht_array(18),
		                 target_queue(19) when c_one_ht_array(19),
		                 target_queue(20) when c_one_ht_array(20),
		                 target_queue(21) when c_one_ht_array(21),
		                 target_queue(22) when c_one_ht_array(22),
		                 target_queue(23) when c_one_ht_array(23),
		                 target_queue(24) when c_one_ht_array(24),
		                 target_queue(25) when c_one_ht_array(25),
		                 target_queue(26) when c_one_ht_array(26),
		                 target_queue(27) when c_one_ht_array(27),
		                 target_queue(28) when c_one_ht_array(28),
		                 target_queue(29) when c_one_ht_array(29),
		                 target_queue(30) when c_one_ht_array(30),
		                 target_queue(31) when c_one_ht_array(31),
						 (others => '0') when others;
						 
	with req_grant select
		targets_granted <= 	grants_normal(0) when c_one_ht_array(0),
							grants_normal(1) when c_one_ht_array(1),
							grants_normal(2) when c_one_ht_array(2),
							grants_normal(3) when c_one_ht_array(3),
							grants_normal(4) when c_one_ht_array(4),
							grants_normal(5) when c_one_ht_array(5),
							grants_normal(6) when c_one_ht_array(6),
							grants_normal(7) when c_one_ht_array(7),
							grants_normal(8) when c_one_ht_array(8),
							grants_normal(9) when c_one_ht_array(9),
							grants_normal(10) when c_one_ht_array(10),
							grants_normal(11) when c_one_ht_array(11),
							grants_normal(12) when c_one_ht_array(12),
							grants_normal(13) when c_one_ht_array(13),
							grants_normal(14) when c_one_ht_array(14),
							grants_normal(15) when c_one_ht_array(15),
							grants_normal(16) when c_one_ht_array(16),
							grants_normal(17) when c_one_ht_array(17),
							grants_normal(18) when c_one_ht_array(18),
							grants_normal(19) when c_one_ht_array(19),
							grants_normal(20) when c_one_ht_array(20),
							grants_normal(21) when c_one_ht_array(21),
							grants_normal(22) when c_one_ht_array(22),
							grants_normal(23) when c_one_ht_array(23),
							grants_normal(24) when c_one_ht_array(24),
							grants_normal(25) when c_one_ht_array(25),
							grants_normal(26) when c_one_ht_array(26),
							grants_normal(27) when c_one_ht_array(27),
							grants_normal(28) when c_one_ht_array(28),
							grants_normal(29) when c_one_ht_array(29),
							grants_normal(30) when c_one_ht_array(30),
							grants_normal(31) when c_one_ht_array(31),
							 (others => '0') when others;	
--
	-- get output access queue buffer from target access map
	v_gen_1: for i in 0 to g_num_ports-1 generate			-- get target bits
		v_gen_2: for j in 0 to g_num_ports-1 generate		-- get requester port
			request_queue(i)(j) <= target_queue(j)(i);	 -- rotate into arbiter
			grants_normal(j)(i) <= grants_rotated(i)(j); -- rotate arbiter output back to normal
		end generate v_gen_2;
	
--	sw_req_address(i) <= target_queue(i)(g_num_ports-1 downto 0);
	end generate v_gen_1;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			-- pipe-lined registers assignments with no reset condition. 
			no_mask_and_unmask_grant <= not(or_reduce_quick(pointer_mask_and_req)) and unmask_grant;
			pointer_mask_and_req <= req_queue and pointer_mask;
			addr_req_reg <= addr_req;
			sw_address_valid <= '0';
			arb_sync <= '0';
			req_grant(g_num_ports-1 downto 0) <= (no_mask_and_unmask_grant(g_num_ports-1 downto 0) or mask_grant(g_num_ports-1 downto 0));	-- grant arb
			port_requests_reg <= port_requests;
			targets_granted_reg <= targets_granted;
			
			if(rst_in = '1') then	-- Synchronous reset 
				rr_pointer_reg <= (0 => '1', others => '0');	-- initialize RR pointer with first bit 1, others 0. Will rotate around...
				clk_delays <= 0;								-- re-set clock delays
				arbiter_state <= get_requests;					-- go to get_requests and start new arbitration cycle 
				new_req <= (others => '0');
			else
				case arbiter_state is 
					
					when get_requests =>								-- load new requests 
					
						rr_pointer_reg(g_num_ports-1 downto 0) <= rr_pointer_reg(g_num_ports-2 downto 0) & rr_pointer_reg(g_num_ports-1); -- move pointer
						address_ready <= '1';							-- load new requester assignemnts (if any are valid)
						req_queue(g_num_ports-1 downto 0) <= new_req;	-- load new active queue 
						arb_sync <= '1';								-- toggle sync to synchronize Target arbiters
						arbiter_state <= grant_access;					-- go to grant access (waits around for arbitration completion)
						
					when grant_access =>								-- wait around for 4 clock cylces for arbitation (required for pipelined registers)		
						if(clk_delays = 3) then							-- wait 4 clock cycles for arbitration 
							clk_delays <= 0;
							arbiter_state <= check_targets;				-- check requested targets 
						else
							clk_delays <= clk_delays + 1;
						end if;
						
					when check_targets =>					-- check if target ports match granted ports 

						if(clk_delays = 3) then				-- wait 4 clock cylces for arbitration response.
							clk_delays <= 0;
							arbiter_state <= get_requests;	-- no matches ? re-start arbitation cycle 
							if((port_requests_reg(g_num_ports-1 downto 0) = targets_granted_reg(g_num_ports-1 downto 0)) and (port_requests_reg(g_num_ports-1 downto 0) /= port_0_gen)) then	-- match between granted and requested ?
								arbiter_state <= submit_requests;	-- if requested targets match granted targets ?
							end if;
						else
							clk_delays <= clk_delays + 1;
						end if;
						
					when submit_requests =>			-- submit new target/requester addresses to SpaceWire Fabric
					--	last_grant <= req_grant;
						for i in 0 to g_num_ports-1 loop
						--	sw_requesters(i)  <= grants_rotated(i)(g_num_ports-1 downto 0);	-- load all requesters for all ports
							if(req_grant(i) = '1') then	-- load asserted targets (note req_grant uses one-hot encoding so only one will load per arbitration cycle)
								sw_address_out(i) <= grants_normal(i)(g_num_ports-1 downto 0);
								new_req(i) <= '0';	-- de-assert granted requests 
							end if;
						end loop;
					
						sw_address_valid <= '1';	-- assert valid 
						if(sw_address_valid = '1' and sw_address_ready = '1') then	-- address handshake. 
							sw_address_valid <= '0';
							arbiter_state <= get_requests;	-- address_out loaded, start new arbitration cycle
						end if;
					
				end case;
				
				if(address_ready = '1' and address_valid = '1') then	-- new Target list ?
					for i in 0 to g_num_ports-1 loop
						target_queue(i)(g_num_ports-1 downto 0) <= address_in(i)(g_num_ports-1 downto 0);	-- get new target list 
					end loop;
					address_ready <= '0';
				end if;
				
				
			end if;
			
			
			
			for i in 0 to g_num_ports-1 loop									
				if(addr_req(i) = '0') then			-- RX port has de-asserted request ?
					target_queue(i) <= (others => '0');	-- wipe target queue 
					sw_address_out(i) <= (others => '0');	-- wipe output queue
				end if;
				-- new request seen ? this prevents a lock-up and reduces address serve latency by ~75%
				if(addr_req(i) = '1' and addr_req_reg(i) = '0') then
					new_req(i) <= '1';	-- track request
				end if;
				
				lock_targets(i) <= '0';
				if(target_queue(i) = grants_normal(i)) then
					lock_targets(i) <= req_grant(i);-- and lock_targets_mask(g_num_ports-1 downto 0);
				end if;

			
			end loop;
			
		end if;
		
		
	end process;


end rtl;