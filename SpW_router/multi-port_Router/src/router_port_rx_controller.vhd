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
use work.all;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity router_port_rx_controller is
	port( 
		
		-- standard register control signals --
		clk_in				: in 	std_logic 			:= '0';					-- clk input, rising edge trigger
		rst_in				: in 	std_logic 			:= '0';					-- reset input, active high
		enable  			: in 	std_logic 			:= '0';					-- enable input, asserted high. 
		
		-- use these signals when using sepeate router/codec clock domains 
		spw_rx_fifo_m		: in 	r_fabric_data_bus_m := c_fabric_data_bus_m;
		spw_rx_fifo_s		: out 	r_fabric_data_bus_s	:= c_fabric_data_bus_s;
		

		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SpaceWire Address Byte (first byte) output--
		addr_byte_out		: out   r_maxi_lite_byte 	:= c_maxi_lite_byte;	-- data, valid
		addr_byte_in		: in 	r_saxi_lite_byte 	:= c_saxi_lite_byte;	-- ready
		
		-- SpaceWire Frame Data output (Across XBar Fabric to target port) -- 
		frame_bus_out		: out 	r_fabric_data_bus_m := c_fabric_data_bus_m;	-- custom data width interface for sending data across X-bar fabric
		frame_bus_in		: in 	r_fabric_data_bus_s := c_fabric_data_bus_s;	-- ready response from target controller. 
		
		bad_addr			: in 	std_logic 			:= '0';					-- asserted for 1 clock cycle when bad RT address
		frame_active 		: out 	std_logic  			:= '0'					-- asserted when active transaction, de-asserting releases Target on XBar fabric  

    );
end router_port_rx_controller;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
/*
	!TODO: Add AXI-Lite Interface Records for Data + Address Ports ...
*/

architecture rtl of router_port_rx_controller is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_rx_state is(
		idle,					-- initialize RX controller registers
		get_addr_byte,			-- get RMAP address byte from SpW Port
		post_routing_table,		-- post address byte to routing table 
		strip_path_addr,		-- was logical address ? strip it from frame.
		send_frame_bytes,		-- stream frame bytes from SpW Rx to Tx Controller. 
		get_frame_bytes,
--		eop_eep_received,		-- EOP/EEP received in data stream ?
		discard,
		frame_done				-- completed frame with EOP/EEP received ?
	);
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal rx_state 		: t_rx_state;-- := idle;
	
	signal spw_rx_reg		: t_nonet := (others => '0');
	
	signal spw_rx_data_reg	: t_fabric_data_bus := (others => (others => '0'));
	signal spw_rx_count_reg	: std_logic_vector(0 to c_fabric_bus_width-1) := (others => '0'); 
	
	signal fifo_has_eop 	: std_logic_vector(0 to c_fabric_bus_width-1) := (others => '0'); 
	signal reg_has_eop 		: std_logic_vector(0 to c_fabric_bus_width-1) := (others => '0'); 

--	signal cnt_rst			: std_logic := '0';
--	signal cnt_enable		: std_logic := '0';
--	signal gray_out			: std_logic_vector(11 downto 0) := (others => '0');
--	signal time_out_count	: unsigned(12 downto 0) := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
--	time_out_counter: entity gray_counter(rtl)
--	generic map(
--		g_count_size => gray_out'length
--	)
--	port map
--	(
--		clk		   => clk_in,
--		reset	   => cnt_rst,
--		enable	   => cnt_enable,
--		gray_count => gray_out
--	);

	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
--	status_reg_out.tdata <= status_reg;

	bool_gen: for i in 0 to c_fabric_bus_width-1 generate
		fifo_has_eop(i) <= to_std((spw_rx_fifo_m.tdata(i) = SPW_EEP) or (spw_rx_fifo_m.tdata(i) = SPW_EOP));
		reg_has_eop(i) <= to_std((spw_rx_data_reg(i) = SPW_EEP) or (spw_rx_data_reg(i) = SPW_EOP));
	end generate bool_gen;
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	main_fsm: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			frame_bus_out.tvalid 	<= '0';	
			addr_byte_out.tvalid 	<= '0';			
			if(rst_in = '1') then
				rx_state <= idle;
				spw_rx_fifo_s.tready <= '0';
			else
				case rx_state is 
					
					when idle =>			
						
						rx_state <= get_addr_byte;
						frame_active <= '0';
						
					when get_addr_byte =>
					
						spw_rx_fifo_s.tready <= '1';
						if(spw_rx_fifo_m.tvalid = '1' and spw_rx_fifo_s.tready = '1') then
							spw_rx_fifo_s.tready <= '0';
							spw_rx_data_reg  <= spw_rx_fifo_m.tdata;
							spw_rx_count_reg <= spw_rx_fifo_m.tcount;
							rx_state <= post_routing_table;
							
							if(unsigned(fifo_has_eop) /= 0 ) then			-- was EOP or EEP ?
								rx_state <= frame_done;								-- overwrite to EOP/EEP
								frame_active <= '0';
							end if;
						end if;
						

					when post_routing_table =>

						addr_byte_out.tdata <= spw_rx_data_reg(0)(7 downto 0);				-- load addr_byte_out, resize bits...
						addr_byte_out.tvalid <= '1';

						if(addr_byte_in.tready = '1' and addr_byte_out.tvalid = '1') then
							addr_byte_out.tvalid <= '0';
							frame_active <= '1';
							rx_state <= send_frame_bytes;								
							if(spw_rx_data_reg(0)(7 downto 5) = "000") then		-- is path address and was NOT bypassed ?
								rx_state <= strip_path_addr;								-- overwrite rx state register to send frame bytes...
								frame_active <= '0';
							end if;
						end if;
						
					when strip_path_addr => -- we will always have N nonets of data in this buffer, so we can just shift, no need to read in next set of nonets 
					
						-- shift data & count pointer across 
						-- done with way to be compatible with c_fabric_bus_width set to 1;
						for i in 0 to c_fabric_bus_width-1 loop
							if(i = c_fabric_bus_width-1) then	-- for last element, load with '0's. This if for bus width = 1 compatibility
								spw_rx_data_reg(c_fabric_bus_width-1) <= b"0_0000_0000";
								spw_rx_count_reg(c_fabric_bus_width-1) <= '0';
							else
								spw_rx_data_reg(i) <= spw_rx_data_reg(i+1);
								spw_rx_count_reg(i) <= spw_rx_count_reg(i+1);
							end if;
						end loop;
						
					--	spw_rx_data_reg(c_fabric_bus_width-1) <= b"0_0000_0000";
					--	spw_rx_count_reg(c_fabric_bus_width-1) <= '0';
						frame_active <= '1';
						
						rx_state <= send_frame_bytes;
						if(c_fabric_bus_width = 1) then	-- go to this state when fabric bus width is 1 element wide 
							rx_state <= get_frame_bytes;
						end if;
						
					when send_frame_bytes =>												-- send frame bytes to XBar Fabric (check for EOPs/EEPs)

						frame_bus_out.tdata 	<= spw_rx_data_reg;
						frame_bus_out.tcount  	<= spw_rx_count_reg;
						frame_bus_out.tvalid 	<= '1';										-- assert data valid register. 
						if(frame_bus_out.tvalid = '1' and frame_bus_in.tready = '1') then	-- frame handshake complete ?											-- reset time-out counter on valid transaction. 
							frame_bus_out.tvalid <= '0';	
							rx_state <= get_frame_bytes;
						end if;
						
						
					when get_frame_bytes =>													-- get frame bytes from SpW IP FIFO (do we need or this or direct stream from IP??)
						
						spw_rx_fifo_s.tready <= '1';
						if(spw_rx_fifo_m.tvalid = '1' and spw_rx_fifo_s.tready = '1') then
							spw_rx_fifo_s.tready <= '0';
							spw_rx_data_reg <= spw_rx_fifo_m.tdata;
							spw_rx_count_reg <= spw_rx_fifo_m.tcount;
							rx_state <= send_frame_bytes;
						end if;
						
						if(unsigned(reg_has_eop) /= 0) then						-- was EOP or EEP ?
							spw_rx_fifo_s.tready <= '0';
							rx_state <= frame_done;								-- overwrite to EOP/EEP
							frame_active <= '0';
						end if;
						
					when discard =>
					
						spw_rx_fifo_s.tready 	<= '1';
						if(spw_rx_fifo_m.tvalid = '1') then
							spw_rx_fifo_s.tready 	<= '0';
						end if;
						
						spw_rx_data_reg 		<= spw_rx_fifo_m.tdata;
						spw_rx_count_reg 		<= spw_rx_fifo_m.tcount;
						
						if(unsigned(reg_has_eop) /= 0) then						-- was EOP or EEP ?
							spw_rx_fifo_s.tready 	<= '0';
							rx_state 				<= frame_done;								-- overwrite to EOP/EEP
							frame_active 			<= '0';
						end if;


					when frame_done =>
						
						frame_active <= '0';
						rx_state <= idle;
			
				end case;
				
				if(bad_addr = '1') then
					rx_state <= discard;
				end if;
				
			end if;

			
		end if;
	end process;
	

end rtl;