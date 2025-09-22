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
entity router_timecode_logic is
	generic(
		g_num_ports		: natural range 1 to 32 := c_num_ports
	);
	port( 
		-- standard register control signals --
		clk_in			: in 	std_logic 	:= '0';		-- clk input, rising edge trigger
		rst_in			: in 	std_logic 	:= '0';		-- reset input, active high
		
		connected		: in 	t_ports;
		tc_master_mask	: in 	t_dword;
		
		tc_rx_in		: in 	r_maxi_lite_byte_array(0 to g_num_ports-2) := (others => c_maxi_lite_byte);
		tc_rx_out		: out 	r_saxi_lite_byte_array(0 to g_num_ports-2) := (others => c_saxi_lite_byte);
		
		tc_tx_in		: in 	r_saxi_lite_byte_array(0 to g_num_ports-2) := (others => c_saxi_lite_byte); 	
		tc_tx_out		: out 	r_maxi_lite_byte_array(0 to g_num_ports-2) := (others => c_maxi_lite_byte);
		
		tc_reg_out		: out 	t_byte := (others => '0')
		
		
    );
end router_timecode_logic;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_timecode_logic is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_one_ht_array : t_dword_array(0 to 31) := one_ht_gen_array;
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_tc_states is (get_tc, check_tc, output_tc);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal tc_states : t_tc_states;-- := get_tc;
	
	signal tc_valid_in_bits 	: t_dword := (others => '0');
	signal tc_ready_out_bits	: t_dword := (others => '0');
	
	signal tc_tx_valid_bits 	: t_dword := (others => '0');
	signal tc_tx_ready_bits 	: t_dword := (others => '0');
	
	signal valid_mask_bits		: t_dword := (others => '0');
	signal not_master_mask		: t_dword := (others => '0');
	
	signal tc_ready_addr		: integer range 0 to 31 := 0;
	signal tc_master_byte_mux 	: t_byte := (others => '0');
	signal tc_master_byte	 	: unsigned(7 downto 0) := (others => '0');
	signal has_new_tc 			: std_logic := '0';
	signal current_tc			: unsigned(7 downto 0) := (others => '0');
	signal next_tc				: unsigned(7 downto 0) := (others => '0');
	signal tc_handshake			: t_dword := (others => '0');
	signal connected_reg		: t_dword := (others => '0');
	
	signal data_array			: t_byte_array(0 to 31) := (others => (others => '0'));
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
	bits_gen:for i in 0 to g_num_ports-2 generate -- generate for all ports, unusued ones will be disconnected in top level and removed in synthesis
		tc_valid_in_bits(i+1) 	<= tc_rx_in(i).tvalid;			-- 0th bit of dword mask is always '0'.
		tc_rx_out(i).tready 	<= tc_ready_out_bits(i+1);		-- 0th bit of dword mask is always '0'.
		tc_tx_out(i).tvalid 	<= tc_tx_valid_bits(i+1);		-- 0th bit of dword mask is always '0'.
		tc_tx_ready_bits(i+1) 	<= tc_tx_in(i).tready;      	-- 0th bit of dword mask is always '0'.
		tc_tx_out(i).tdata 		<= std_logic_vector(current_tc);
		data_array(i+1) 		<= tc_rx_in(i).tdata;
	end generate bits_gen;
	
--	next_tc 		<= (tc_master_byte + 1) mod 64;	-- next valid timecode bits 
	not_master_mask <= not tc_master_mask;	-- get inverse of mask for broadcast channels, blank out invalid ports 
	tc_reg_out <= std_logic_vector(current_tc);
	-- Valid Address Decoder logic -- 
	with valid_mask_bits select
		tc_master_byte_mux 	<= 	data_array(1)  	when c_one_ht_array(1),
								data_array(2)  	when c_one_ht_array(2),
								data_array(3)  	when c_one_ht_array(3),
								data_array(4)  	when c_one_ht_array(4),
								data_array(5)  	when c_one_ht_array(5),
								data_array(6)  	when c_one_ht_array(6),
								data_array(7)  	when c_one_ht_array(7),
								data_array(8)  	when c_one_ht_array(8),
								data_array(9)  	when c_one_ht_array(9),
								data_array(10) 	when c_one_ht_array(10),
								data_array(11) 	when c_one_ht_array(11),
								data_array(12) 	when c_one_ht_array(12),
								data_array(13) 	when c_one_ht_array(13),
								data_array(14) 	when c_one_ht_array(14),
								data_array(15) 	when c_one_ht_array(15),
								data_array(16) 	when c_one_ht_array(16),
								data_array(17) 	when c_one_ht_array(17),
								data_array(18) 	when c_one_ht_array(18),
								data_array(19) 	when c_one_ht_array(19),
								data_array(20) 	when c_one_ht_array(20),
								data_array(21) 	when c_one_ht_array(21),
								data_array(22) 	when c_one_ht_array(22),
								data_array(23) 	when c_one_ht_array(23),
								data_array(24) 	when c_one_ht_array(24),
								data_array(25) 	when c_one_ht_array(25),
								data_array(26) 	when c_one_ht_array(26),
								data_array(27) 	when c_one_ht_array(27),
								data_array(28) 	when c_one_ht_array(28),
								data_array(29) 	when c_one_ht_array(29),
								data_array(30) 	when c_one_ht_array(30),
								data_array(31) 	when c_one_ht_array(31),
								(others => '0')   		when others; 
	
--	valid_mask_bits <= tc_valid_in_bits and tc_master_mask;	-- mask for valid signal from TC Rx port of Master SpW Codec 
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	main_proc:process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			connected_reg(g_num_ports-1 downto 0) <= connected(g_num_ports-1 downto 0);
			if(rst_in = '1') then
				tc_states <= get_tc;
				next_tc <= (others => '0');
				tc_master_byte <= (others => '0');
			else
				tc_ready_out_bits 	<= valid_mask_bits;						-- set ready bits for handshake if valid is asserted 
				valid_mask_bits 	<= tc_valid_in_bits and tc_master_mask;	-- mask for valid signal from TC Rx port of Master SpW Codec
				next_tc <= (current_tc + 1) mod 64;							-- next valid timecode bits 				
				case tc_states is
					when get_tc =>											--wait for valid timecode input from master 
						if((tc_ready_out_bits and valid_mask_bits) = valid_mask_bits and valid_mask_bits /= x"0000_0000") then	-- handshake asserted ?
							tc_master_byte 		<= unsigned(tc_master_byte_mux);						-- register byte after mux to help with setup time.
							tc_states <= check_tc;
						end if;
						
					when check_tc =>
						current_tc <= tc_master_byte;		-- update timecode register. 
						if(next_tc = tc_master_byte) then 	-- timecode submitted is chronological 
							-- mask off ports which are disconnected, prevents lock-ups
							tc_tx_valid_bits(31 downto 1) <= (not_master_mask(31 downto 1) and connected_reg(31 downto 1)); 	-- set transmission valid bits for Tx TimeCode Handshake, do not sent to master port
							tc_states <= output_tc;
						else								-- timecode submitted clashed with predicted value...
							tc_states <= get_tc;			-- do not broadcast, go back to receive tc. 
						end if;
					
					
					when output_tc =>							-- broadcast valid timecode to eligible ports
					--	tc_tx_valid_bits(31 downto 1) <= not_master_mask(31 downto 1); 	-- set transmission valid bits 	for Tx TimeCode Handshake, do not sent to master port
						for i in 1 to g_num_ports-1 loop	-- loop through all bits			
							if(tc_tx_ready_bits(i) = '1' and tc_tx_valid_bits(i) = '1') then	-- handshake asserted at port ?
							--	tc_tx_valid_bits(i)		<= '0';									-- de-assert valid for port
								tc_handshake(i) <= '1';
							end if;
							-- wait for acknowledgement where ready goes low.
							if(tc_handshake(i) = '1' and tc_tx_ready_bits(i) = '0') then	
								tc_tx_valid_bits(i)		<= '0';			-- only when submission is acknowledged does the valid bit de-assert
							end if;
						end loop;
						
						if(tc_tx_valid_bits = x"0000_0000") then	-- all 0's ? All transactions made ?	
							tc_states <= get_tc;					-- go back to get timecode state 
						end if;
					
					when others => 							-- FSM implementation using binary counter produces a 4th unsafe state.
						tc_states <= get_tc;
						
				end case;
			
			end if;
		end if; 
	end process;


end rtl;