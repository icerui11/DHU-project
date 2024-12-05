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
entity router_rt_arbiter is
	generic(
		g_num_ports 	: natural range 1 to 32 := c_num_ports;
		g_axi_addr		: t_byte 				:= x"00"	-- axi Bus address for this module configure in router_pckg.vhd
	);
	port( 
		
		-- standard register control signals --
		clk_in				: in 	std_logic := '0';		-- clk input, rising edge trigger
		enable 				: in 	std_logic := '0';
		rst_in				: in 	std_logic := '0';		-- reset input, active high
		
		address_assert		: in 	t_ports := (others => '0');
		addr_byte_in		: in 	t_byte_array(0 to g_num_ports-1) := (others => (others => '0'));
		addr_byte_valid		: in 	t_ports := (others => '0');	-- req in 
		addr_byte_ready		: out 	t_ports := (others => '0'); -- grant out 
		bad_addr			: out 	t_ports := (others => '0');
		
		address_req_out		: out 	t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));
		address_req_valid	: out 	std_logic := '0';
		address_req_ready	: in 	std_logic := '0';
		
		
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 				: in 	r_maxi_lite_dword	:= c_maxi_lite_dword;
		axi_out				: out 	r_saxi_lite_dword	:= c_saxi_lite_dword
	
    );
end router_rt_arbiter;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_rt_arbiter is

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
		get_address,
		get_mem_rd_data,			-- send received address to routing table
	--	check_rt_address,
		send_rt_address,
		move_pointer			-- move round robin pointer to next element. 
	);
	
	type t_axi_state is(
		idle, 
		valid_assert
	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- generate 1-hot encoding states for N wide ports 
--    impure function one_ht_gen(i1 : integer; size : integer) return std_logic_vector is
--        variable slv : std_logic_vector(size-1 downto 0) := (others => '0');	-- slv to return
--    begin
--        slv(i1) := '1';
--        return slv;
--    end function one_ht_gen;
--	
--	--return rr pointer mask bits from one-hot-encoded valid bits 
--	impure function point_mask_gen(i1 : integer; size : integer) return std_logic_vector is	
--		variable slv : std_logic_vector(size downto 0) := (others => '1');	-- slv to return
--	begin
--		slv(i1 downto 0) := (others => '0');
--		return slv(size downto 1);
--	end function point_mask_gen;
--	
--	-- return slv with all bits 0, length is number of ports
--	impure function port_1_gen return t_ports is	-- return slv with all bits 0, length is number of ports
--		variable slv : t_ports := (others => '1');
--	begin
--		return slv;
--	end function port_1_gen;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal arbiter_state 			: t_arbiter_state;-- := get_requests;
	signal last_req					: t_dword := (others => '0');
	
	signal last_grant 				: t_dword := (others => '0');	-- grant mask bits for current grant bit 
	
	signal rr_pointer 				: t_dword := (0 => '1', others => '0');-- round roubin priority pointer. 
	
	signal pointer_mask				: t_dword := (others => '0');
	signal pointer_mask_and_req  	: t_dword := (others => '0');
	signal mask_grant				: t_dword := (others => '0');
	
	signal req_queue				: t_dword := (others => '0');
	signal unmask_grant				: t_dword := (others => '0');
	
	signal no_mask_and_unmask_grant : t_dword := (others => '0');
	
	signal grant					: t_dword := (others => '0');
	
	signal clk_delays				: integer range 0 to 7 := 0;
	
	signal data_reg 				: t_ports := (others => '0');
	signal data_mux 				: t_byte := (others => '0');
	
	signal mem_rd_addr  			:	t_byte := (others => '0');
	signal mem_rd_data  			:	t_dword := (others => '0');
	signal addr_byte_in_32 			: 	t_byte_array(0 to 31) := (others => (others => '0'));
	
	
	signal grant_decode 			: 	integer range 0 to 31 := 0;
	
	signal 	axi_state				: 	t_axi_state := idle;
	signal	axi_wr_en				:	std_logic := '0';	
	signal	axi_addr  				:	std_logic_vector(9 downto 0) := (others => '0');
	signal  axi_wr_data				: 	t_byte := (others => '0');
	signal  axi_rd_data				:   t_byte := (others => '0');
	signal 	axi_byte_counter		: 	integer range 0 to 3 := 0;
	signal  ready_req				: 	t_dword := (others => '0');
	signal 	addr_byte_valid_old		:   t_dword := (others => '0');
	signal  new_reqs				: 	t_dword := (others => '0');
--	signal 	connected_reg 			: 	t_ports := (others => '0');
--	signal	reject_mask				: 	t_ports := (others => '1');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------

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
	
	rout_table_mem: entity work.mixed_width_ram(rtl)
	port map( 
		
		-- standard register control signals --
		clk_in	=> clk_in,										-- clk input, rising edge trigger
		
		wr_en	=> 	axi_wr_en,
		r_addr 	=> 	mem_rd_addr,
		w_addr 	=>	axi_addr,
		
		
		w_data  => axi_wr_data,
		r_data	=> mem_rd_data

    );

	
	shadow_rout_table_mem: entity work.router_routing_table_top(rtl)
	generic map(
		data_width	=> 8,			-- bit-width of ram element (0-31 = port number)
		addr_width	=> 10
	)
	port map(
		-- standard register control signals --
		clk_in 		=> clk_in,										-- clock in (rising_edge)
		enable_in 	=> enable,										-- enable input (active high)
		
		wr_en		=> axi_wr_en,									-- write enable (asserted high)
		wr_addr		=> axi_addr,
		wr_data 	=> axi_wr_data,
		
		rd_addr  	=> axi_addr,									-- read address for axi memory
		rd_data	 	=> axi_rd_data		
	);


	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
--	no_mask_and_unmask_grant <= not(or_reduce_quick(pointer_mask_and_req)) and unmask_grant;
--	pointer_mask_and_req <= req_queue and pointer_mask;
--	addr_byte_ready	<= grant(g_num_ports-1 downto 0);
	pad_gen: for i in 0 to g_num_ports-1 generate
		addr_byte_in_32(i) <= addr_byte_in(i);
	end generate pad_gen;
	-- round robin priority pointer... 
	with rr_pointer select 
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
						
	-- data input mux selected from grant signal. 					
	with grant select
		data_mux <= addr_byte_in_32(0) when c_one_ht_array(0), 
		            addr_byte_in_32(1) when c_one_ht_array(1),
		            addr_byte_in_32(2) when c_one_ht_array(2),
		            addr_byte_in_32(3) when c_one_ht_array(3),
		            addr_byte_in_32(4) when c_one_ht_array(4),
		            addr_byte_in_32(5) when c_one_ht_array(5),
		            addr_byte_in_32(6) when c_one_ht_array(6),
		            addr_byte_in_32(7) when c_one_ht_array(7),
		            addr_byte_in_32(8) when c_one_ht_array(8),
		            addr_byte_in_32(9) when c_one_ht_array(9),
		            addr_byte_in_32(10) when c_one_ht_array(10),
		            addr_byte_in_32(11) when c_one_ht_array(11),
		            addr_byte_in_32(12) when c_one_ht_array(12),
		            addr_byte_in_32(13) when c_one_ht_array(13),
		            addr_byte_in_32(14) when c_one_ht_array(14),
		            addr_byte_in_32(15) when c_one_ht_array(15),
		            addr_byte_in_32(16) when c_one_ht_array(16),
		            addr_byte_in_32(17) when c_one_ht_array(17),
		            addr_byte_in_32(18) when c_one_ht_array(18),
		            addr_byte_in_32(19) when c_one_ht_array(19),
		            addr_byte_in_32(20) when c_one_ht_array(20),
		            addr_byte_in_32(21) when c_one_ht_array(21),
		            addr_byte_in_32(22) when c_one_ht_array(22),
		            addr_byte_in_32(23) when c_one_ht_array(23),
		            addr_byte_in_32(24) when c_one_ht_array(24),
		            addr_byte_in_32(25) when c_one_ht_array(25),
		            addr_byte_in_32(26) when c_one_ht_array(26),
		            addr_byte_in_32(27) when c_one_ht_array(27),
		            addr_byte_in_32(28) when c_one_ht_array(28),
		            addr_byte_in_32(29) when c_one_ht_array(29),
		            addr_byte_in_32(30) when c_one_ht_array(30),
		            addr_byte_in_32(31) when c_one_ht_array(31),
					(others => '0') when others;
					
--
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	main_fsm: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			bad_addr <= (others => '0');
			pointer_mask_and_req <= req_queue and pointer_mask;
			no_mask_and_unmask_grant <= not(or_reduce_quick(pointer_mask_and_req)) and unmask_grant;
			grant <= no_mask_and_unmask_grant or mask_grant;
			address_req_valid <= '0';
			addr_byte_valid_old(g_num_ports-1 downto 0) <= addr_byte_valid;
			addr_byte_ready <= (others => '0');
			ready_req(g_num_ports-1 downto 0) <= addr_byte_ready(g_num_ports-1 downto 0) and req_queue(g_num_ports-1 downto 0);
			if(rst_in = '1') then
			--	req_queue <= (others => '0');
				rr_pointer <= (0 => '1', others => '0');	-- initialize RR pointer with first bit 1, others 0. Will rotate around...
				clk_delays <= 0;
				new_reqs <= (others => '0');
				arbiter_state <= get_requests;
			else
				case arbiter_state is 
					
					when get_requests =>	-- check incoming requests

						req_queue(g_num_ports-1 downto 0) <= new_reqs(g_num_ports-1 downto 0);	-- load new requests 
					--	if(req_queue(g_num_ports-1 downto 0) /= addr_byte_valid and addr_byte_valid /= port_0_gen) then
						if(new_reqs(g_num_ports-1 downto 0) /= port_0_gen) then	-- outstanding requests ?
							arbiter_state <= grant_access;	-- arbitrate and grant access to outstanding requests...
						end if;
						
					when grant_access =>	-- axi handshake for incoming address byte (ready = grant)
						
						if(clk_delays = 4) then	-- wait for clock delays through RR logic...
							clk_delays <= 0;
							arbiter_state <= get_address; 	-- get 32bit address from Routing table memory 
						else
							clk_delays <= clk_delays + 1;
						end if;
						
					when get_address =>
					
						last_grant <= grant;		-- store last grant 
						addr_byte_ready	<= grant(g_num_ports-1 downto 0);
						mem_rd_addr <= data_mux;		-- load in data register. 
						if(ready_req(g_num_ports-1 downto 0) /= port_0_gen) then
							addr_byte_ready <= (others => '0');
							arbiter_state <= get_mem_rd_data;	-- go to send address state 
						end if;
					
					when get_mem_rd_data =>	-- read complementary address byte from routing table memory 
					
						data_reg <= mem_rd_data(g_num_ports-1 downto 0);	-- re-size data register, output Xbar address
						clk_delays <= clk_delays + 1;
						if(clk_delays = 2) then
							clk_delays <= 0;
							arbiter_state <= send_rt_address;
						end if;
						
					when send_rt_address =>	-- send routing table address to Xbar fabric Controller. 

						for i in 0 to g_num_ports-1 loop
							if(last_grant(i) = '1') then		-- last-grant is one-hot encoded 
								address_req_out(i) <= data_reg;	-- load output register 
								new_reqs(i) <= '0';				-- de-assert serviced request 
							end if;
						end loop;
						address_req_valid <= '1';
						
						if(address_req_valid = '1' and address_req_ready = '1') then	-- handshake valid ?
							address_req_valid <= '0';
							arbiter_state <= move_pointer;
						end if;
							-- all 0's, invalid RT address ?
						if(data_reg = port_0_gen) then
							address_req_valid 	<= '0';				-- do not assert request valid 
							bad_addr 			<= last_grant(g_num_ports-1 downto 0);		-- assert bad address on port 
							arbiter_state 		<= move_pointer;	-- move pointer 
						end if;
						
						
					when move_pointer =>	-- move priority pointer, return to address request 
						rr_pointer(g_num_ports-1 downto 0) <= rr_pointer(g_num_ports-2 downto 0) & rr_pointer(g_num_ports-1);	-- rotate rr pointer. 
						arbiter_state <= get_requests;	-- got to get_requests...
					
				end case;
			end if;
			
			for i in 0 to g_num_ports-1 loop
				if(address_assert(i) = '0') then
					address_req_out(i) <= (others => '0');
				end if;
				-- rising edge, so new request submitted ?
				if(addr_byte_valid_old(i) = '0' and addr_byte_valid(i) = '1') then
					new_reqs(i) <= '1';	-- assert new request
				end if;
				
			end loop;
		end if;
	end process;
	
	-- process to manage AXI configuration port access  
	axi_proc: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			if(rst_in = '1') then	-- force reset condition 
				axi_out.tready <= '0';		-- force ready low 
				axi_wr_en 		<= '0';
			else 
				axi_addr 		<= axi_in.taddr(9 downto 0);	-- pre-load memory element address 
				axi_out.tready 	<= '0';		-- force ready low 
				axi_wr_data  	<= axi_in.wdata;				-- write data will be 4 bytes, per valid memory element, this is frist byte 
				axi_out.rdata 	<= axi_rd_data;
				axi_wr_en 		<= '0';
				
				if(axi_in.tvalid = '1' and axi_in.taddr(23 downto 16) = g_axi_addr) then	-- valid and addressed to this module ?
					axi_out.tready 	<= '1';
				end if;
		
				if(axi_in.tvalid = '1' and axi_out.tready = '1') then
					axi_out.tready 	<= '0';		-- force ready low 
					axi_wr_en 		<= axi_in.w_en;					-- get write status 
				end if;
				
			end if;
		end if;
	end process;


end rtl;