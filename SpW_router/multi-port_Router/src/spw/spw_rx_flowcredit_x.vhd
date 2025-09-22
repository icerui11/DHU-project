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

-- @ Revision #				:	1

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
context work.spw_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_rx_flowcredit_x is
	generic(
		fifo_size          : integer := 24
	);
	port(
		clock               : in    std_logic;
		reset				: in    std_logic;

		Tx_can_send_FCT     : in    boolean;

		Rx_FIFO_out_data    : in    nonet;
		Rx_FIFO_out_OR      : in    boolean;
		Rx_FIFO_out_IR      : in    boolean;
	
		send_FCT            :   out boolean;
		FCT_sent            : in    boolean
	);
end spw_rx_flowcredit_x;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_rx_flowcredit_x is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal FCT_to_send        : std_logic_vector( fifo_size / 8 downto 1 );
	signal nchars_read        : integer range 0 to 7;
	signal last_lsb           : integer range 0 to 1;
	signal up                 : boolean;
	signal down               : boolean;
	signal FCT_Sent_d         : boolean;
	signal extn               : boolean;
	signal extn_count         : unsigned(3 downto 0);
	signal Rx_FIFO_out_data_reg		: t_nonet := (others => '0');
	signal Tx_can_send_FCT_reg		: boolean;
	signal Rx_FIFO_out_OR_reg	: 	boolean;
	signal Rx_FIFO_out_IR_reg   : 	boolean;
	signal FCT_sent_reg 		: boolean;
	
	signal was_EEP				: boolean;
	signal was_EOP				: boolean;
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Alias Declarations --
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
	extn <= Rx_FIFO_out_data_reg(8) = '1' and not(Rx_FIFO_out_data_reg = SPW_EOP or Rx_FIFO_out_data_reg = SPW_EEP);
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clock)
    begin
		if rising_edge(clock) then
			Rx_FIFO_out_data_reg <= Rx_FIFO_out_data;
			-- pipeline EOP/EEP Checking as this is critical path in CODEC.
			-- this has moved the FCT out check 1 clock cycle in future. 
	
		--	extn <= Rx_FIFO_out_data(8) = '1' and Rx_FIFO_out_data /= SPW_EOP and Rx_FIFO_out_data /= SPW_EEP;
		--	extn <= false;
		--	if(Rx_FIFO_out_data(8) = '1' and not(Rx_FIFO_out_data = SPW_EOP or Rx_FIFO_out_data = SPW_EEP)) then
		--		extn <= true;
		--	end if;
			Tx_can_send_FCT_reg <= Tx_can_send_FCT;
			Rx_FIFO_out_OR_reg <= Rx_FIFO_out_OR;
			Rx_FIFO_out_IR_reg <= Rx_FIFO_out_IR;
			FCT_sent_reg	<= FCT_sent;
			if (reset = '1') then
				FCT_to_send <= (others => '1');
				nchars_read <= fifo_size mod 8;
				last_lsb    <= 0;
				send_FCT    <= false;
				FCT_sent_d  <= false;
				extn_count  <= (others => '0');
			elsif Tx_can_send_FCT_reg then
				if Rx_FIFO_out_OR_reg and Rx_FIFO_out_IR_reg then
					
					case extn is
						when true =>
						
							extn_count <= (others => '0');
							if Rx_FIFO_out_data_reg(7) = '1' then
								extn_count <= unsigned(Rx_FIFO_out_data_reg(3 downto 0));
							end if;
							
						when false =>
							
							if(extn_count = 0) then
								nchars_read <= (nchars_read + 1) mod 8;
							else
								extn_count <= extn_count - 1;
							end if;
					
					end case;
			--		if Rx_FIFO_out_data_reg(7) = '1' and extn = true then 
			--			extn_count <= unsigned(Rx_FIFO_out_data_reg(3 downto 0));
			--		elsif(extn = true) then
			--			extn_count <= (others => '0');
			--		end if;
			--		
			--		if(extn = false and extn_count = 0) then
			--			nchars_read <= (nchars_read + 1) mod 8;
			--		elsif(extn = false) then
			--			extn_count <= extn_count - 1;
			--		end if;
					
				end if;

				up   <= 	not FCT_sent_reg and     (nchars_read = 0 and last_lsb = 1);
				down <=     FCT_sent_reg and not (nchars_read = 0 and last_lsb = 1);

				if up then 
					FCT_to_send <= FCT_to_send(FCT_to_send'high-1 downto 1) & '1';
				elsif down then 
					FCT_to_send <= '0' & FCT_to_send(FCT_to_send'high   downto 2);
				end if;
          
				last_lsb <= nchars_read mod 2;
            
				FCT_sent_d <= FCT_sent_reg;
				send_FCT <= Fct_to_send(1) = '1' and not FCT_sent_reg and not FCT_sent_d;
        
            else
				FCT_to_send <= (others => '1');
				nchars_read <= fifo_size mod 8;
				last_lsb    <= fifo_size mod 2;
				send_FCT    <= false;
				FCT_sent_d  <= false;
			end if;

		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;