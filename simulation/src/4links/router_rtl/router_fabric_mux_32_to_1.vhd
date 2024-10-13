----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_fabric_mux_32_to_1.vhd
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
entity router_fabric_mux_32_to_1 is
	generic(
		g_num_ports : natural range 1 to 32 := c_num_ports
	);
	port( 	
		clk_in			: in 	std_logic   := '0';
		
	--	addr_active		: in 	std_logic				:= '0';	-- requester address active input 
		sw_targets		: in 	t_ports					:= (others => '0');		-- requested address(es) from Routing Table Entry. 
		sw_requesters 	: in 	t_ports					:= (others => '0');		-- requested address(es) from Routing Table Entry. 
		-- Input from Routing Fabric
		
		
		data_out_m		: out 	r_fabric_data_bus_m								:= c_fabric_data_bus_m; -- port valid, data, count input 
		data_out_s		: out 	r_fabric_data_bus_s								:= c_fabric_data_bus_s;	-- target ready input
		
		data_in_m		: in 	r_fabric_data_bus_m_array(0 to g_num_ports-1)	:= (others => c_fabric_data_bus_m);
		data_in_s		: in   	r_fabric_data_bus_s_array(0 to g_num_ports-1)   := (others => c_fabric_data_bus_s)
		
    );
end router_fabric_mux_32_to_1;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_fabric_mux_32_to_1 is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_one_ht_gen  : t_dword_array(0 to 31) := one_ht_gen_array;
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type count_arr is array (natural range <>) of std_logic_vector(0 to c_fabric_bus_width-1);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
--	-- generate 1-hot encoding states for N wide ports 
--    impure function one_ht_gen(i1 : integer; size : integer) return std_logic_vector is
--        variable slv : std_logic_vector(size-1 downto 0) := (others => '0');	-- slv to return
--    begin
--        slv(i1) := '1';
--        return slv;
--    end function one_ht_gen;
	
--	impure function port_0_gen return std_logic_vector IS
--		variable slv	: t_ports := (others => '0');
--	begin
--		return slv;
--	end function port_0_gen;
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	signal mux_data_out_reg  	: t_fabric_data_bus 							:= (others => (others => '0'));
	signal mux_count_out_reg 	: std_logic_vector(0 to c_fabric_bus_width-1) 	:= (others => '0');
	signal mux_valid_out_reg 	: std_logic := '0';
	signal mux_ready_out_reg 	: std_logic := '0';
	signal route_data_in_32	 	: t_fabric_data_bus_array(0 to 31) 	:= (others => (others => (others => '0')));	-- data sent from requester to target
	signal route_count_in_32 	: count_arr(0 to 31) 				:= (others => (others => '0'));
	signal sw_requesters_32		: t_dword 							:= (others => '0');	-- pad to 32-bit wide 
	signal route_ready_in		: t_ports							:= (others => '0');
	signal route_valid_in		: t_ports							:= (others => '0');
	signal sw_targets_reg		: t_ports 							:= (others => '0');
	

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

	-- pad ports to 32-bit wide and connect up here
	pad_gen: for i in 0 to g_num_ports-1 generate
		route_valid_in(i) 		<= data_in_m(i).tvalid;				
		route_data_in_32(i) 	<= data_in_m(i).tdata;			
		route_count_in_32(i) 	<= data_in_m(i).tcount;
		route_ready_in(i) 		<= data_in_s(i).tready;
		sw_requesters_32(i) 	<= sw_requesters(i);
	end generate pad_gen;
	
	-- multiplex the input data using the requester address 
	with sw_requesters_32 select
		mux_data_out_reg <= route_data_in_32(0)  	when c_one_ht_gen(0),
							route_data_in_32(1)  	when c_one_ht_gen(1),
							route_data_in_32(2)  	when c_one_ht_gen(2),
							route_data_in_32(3)  	when c_one_ht_gen(3),
							route_data_in_32(4)  	when c_one_ht_gen(4),
							route_data_in_32(5)  	when c_one_ht_gen(5),
							route_data_in_32(6)  	when c_one_ht_gen(6),
							route_data_in_32(7)  	when c_one_ht_gen(7),
							route_data_in_32(8)  	when c_one_ht_gen(8),
							route_data_in_32(9)  	when c_one_ht_gen(9),
							route_data_in_32(10) 	when c_one_ht_gen(10),
							route_data_in_32(11) 	when c_one_ht_gen(11),
							route_data_in_32(12) 	when c_one_ht_gen(12),
							route_data_in_32(13) 	when c_one_ht_gen(13),
							route_data_in_32(14) 	when c_one_ht_gen(14),
							route_data_in_32(15) 	when c_one_ht_gen(15),
							route_data_in_32(16) 	when c_one_ht_gen(16),
							route_data_in_32(17) 	when c_one_ht_gen(17),
							route_data_in_32(18) 	when c_one_ht_gen(18),
							route_data_in_32(19) 	when c_one_ht_gen(19),
							route_data_in_32(20) 	when c_one_ht_gen(20),
							route_data_in_32(21) 	when c_one_ht_gen(21),
							route_data_in_32(22) 	when c_one_ht_gen(22),
							route_data_in_32(23) 	when c_one_ht_gen(23),
							route_data_in_32(24) 	when c_one_ht_gen(24),
							route_data_in_32(25) 	when c_one_ht_gen(25),
							route_data_in_32(26) 	when c_one_ht_gen(26),
							route_data_in_32(27) 	when c_one_ht_gen(27),
							route_data_in_32(28) 	when c_one_ht_gen(28),
							route_data_in_32(29) 	when c_one_ht_gen(29),
							route_data_in_32(30) 	when c_one_ht_gen(30),
							route_data_in_32(31) 	when c_one_ht_gen(31),
							(others => (others => '0'))   when others; 
							
	-- multiplex "count" signal for bus data 
	with sw_requesters_32 select
		mux_count_out_reg 	<= 	route_count_in_32(0)  	when c_one_ht_gen(0),
								route_count_in_32(1)  	when c_one_ht_gen(1),
								route_count_in_32(2)  	when c_one_ht_gen(2),
								route_count_in_32(3)  	when c_one_ht_gen(3),
								route_count_in_32(4)  	when c_one_ht_gen(4),
								route_count_in_32(5)  	when c_one_ht_gen(5),
								route_count_in_32(6)  	when c_one_ht_gen(6),
								route_count_in_32(7)  	when c_one_ht_gen(7),
								route_count_in_32(8)  	when c_one_ht_gen(8),
								route_count_in_32(9)  	when c_one_ht_gen(9),
								route_count_in_32(10) 	when c_one_ht_gen(10),
								route_count_in_32(11) 	when c_one_ht_gen(11),
								route_count_in_32(12) 	when c_one_ht_gen(12),
								route_count_in_32(13) 	when c_one_ht_gen(13),
								route_count_in_32(14) 	when c_one_ht_gen(14),
								route_count_in_32(15) 	when c_one_ht_gen(15),
								route_count_in_32(16) 	when c_one_ht_gen(16),
								route_count_in_32(17) 	when c_one_ht_gen(17),
								route_count_in_32(18) 	when c_one_ht_gen(18),
								route_count_in_32(19) 	when c_one_ht_gen(19),
								route_count_in_32(20) 	when c_one_ht_gen(20),
								route_count_in_32(21) 	when c_one_ht_gen(21),
								route_count_in_32(22) 	when c_one_ht_gen(22),
								route_count_in_32(23) 	when c_one_ht_gen(23),
								route_count_in_32(24) 	when c_one_ht_gen(24),
								route_count_in_32(25) 	when c_one_ht_gen(25),
								route_count_in_32(26) 	when c_one_ht_gen(26),
								route_count_in_32(27) 	when c_one_ht_gen(27),
								route_count_in_32(28) 	when c_one_ht_gen(28),
								route_count_in_32(29) 	when c_one_ht_gen(29),
								route_count_in_32(30) 	when c_one_ht_gen(30),
								route_count_in_32(31) 	when c_one_ht_gen(31),
								(others => '0')   		when others; 						


	-- Asynchronous assignment of valid and ready 
	data_out_m.tvalid	<= mux_valid_out_reg;
	data_out_s.tready   <= mux_ready_out_reg;

	
	process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			-- register mux outputs 
			mux_ready_out_reg <= '0';
			if((route_ready_in = sw_targets) and sw_targets /= port_0_gen) then -- ready matches requester addresses 
				mux_ready_out_reg <= '1';
			end if;
			
			-- register mux outputs 
			mux_valid_out_reg <= '0';
			if((route_valid_in = sw_requesters) and sw_requesters /= port_0_gen) then
				mux_valid_out_reg <= '1';
			end if;
			
			-- register data output 
			data_out_m.tcount 	<= mux_count_out_reg;	--register outputs to re-time 
			data_out_m.tdata  	<= mux_data_out_reg;    --register outputs to re-time 
		end if;

	end process;

	
	---------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------



end rtl;