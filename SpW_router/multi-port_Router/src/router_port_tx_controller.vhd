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
entity router_port_tx_controller is
	port( 
		-- standard register control signals --
		clk_in				: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		rst_in				: in 	std_logic 			:= '0';		-- reset input, active high
		enable  			: in 	std_logic 			:= '0';		-- enable input, asserted high. 
		
		-- SpaceWire Data from CoDec -- 
		
		frame_bus_in		: in 	r_fabric_data_bus_m := c_fabric_data_bus_m;	
		frame_bus_out		: out 	r_fabric_data_bus_s := c_fabric_data_bus_s;
		
		fifo_bus_in			: in 	r_fabric_data_bus_s := c_fabric_data_bus_s;	
		fifo_bus_out		: out 	r_fabric_data_bus_m := c_fabric_data_bus_m

    );
    
end entity router_port_tx_controller;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_port_tx_controller is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_tx_state is (get_data, send_data);
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal tx_state 	: t_tx_state;-- := get_data;
	signal count_reg	: std_logic_vector(0 to c_fabric_bus_width-1) := (others => '0');	
	signal tx_data		: t_fabric_data_bus := (others => (others => '0'));
	
	
--	signal frame_byte_reg : t_nonet := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
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
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	tx_fsm: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			if(rst_in = '1') then
				tx_state <= get_data;
				frame_bus_out.tready <= '0';
				fifo_bus_out.tvalid <= '0';
			else 
				case tx_state is				
				
					when get_data =>						-- get data using axi-handshake over X-Bar switch fabric 
					
						frame_bus_out.tready <= '0';										-- default de-assert frame_byte_out;
						if(frame_bus_in.tvalid = '1') then									-- valid asserted ?
							frame_bus_out.tready <= '1';									-- assert ready 
							fifo_bus_out.tdata  	<= frame_bus_in.tdata;								-- load SpW Tx Output Register 
							fifo_bus_out.tcount		<= frame_bus_in.tcount;								-- store count register bits 
						end if;
						
						-- need to wait for allignment of transactions, otherwise concurrent multicasting breaks the router
						if(frame_bus_in.tvalid = '0' and frame_bus_out.tready = '1') then
						--	fifo_bus_out.tvalid <= '1';
							tx_state <= send_data;	
						end if;
						
						
					when send_data =>
						
						fifo_bus_out.tvalid <= '1';
	
						if(fifo_bus_out.tvalid = '1' and fifo_bus_in.tready = '1') then		-- axi handshake ?
							fifo_bus_out.tvalid <= '0';
							tx_state <= get_data;
						end if;
						
				end case;
			end if;

		end if;
	end process;


end rtl;
