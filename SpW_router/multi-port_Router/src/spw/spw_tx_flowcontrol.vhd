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
entity spw_tx_flowcontrol is
	port( 
		-- General
		clock               : in    std_logic;
		reset               : in    std_logic;
		rx_enable           : in    boolean;

		fct_received        : in    boolean;
		too_many_fcts       :   out boolean;
		stalled             :   out boolean;
		
		-- Data
		in_Data             : in    nonet;
		in_OR               : in    boolean;
		in_IR               :   out boolean;

		out_Data            :   out nonet;
		out_OR              :   out boolean;
		out_IR              : in    boolean
		);
end spw_tx_flowcontrol;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_tx_flowcontrol is

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
	signal Tx_sent             : integer range 0 to 7;
	signal FCTs                : std_logic_vector(6 downto 0);
	signal FCT_used            : boolean;
	signal excess_fcts         : boolean;
	signal waiting             : boolean;
	signal full                : boolean;
	signal data                : nonet;
	
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
	too_many_fcts <= excess_fcts;
	stalled       <= waiting;
	
	in_IR    <= not full and (Tx_Sent /= 0 or FCTs(0) = '1');
    out_Data <= data;
    out_OR   <= full;
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clock)
    begin

		if rising_edge( clock ) then
			if (reset = '1') then
				waiting     <= false;
				excess_fcts <= false;
				FCTs        <= (others => '0');	
			else
			
				if not rx_enable then 
					FCTs <= "0000000";
				elsif FCT_received and not FCT_used then 
					FCTs <= FCTs(5 downto 0) & '1';
				elsif not FCT_received and     FCT_used then
					FCTs <= '0' & FCTS(6 downto 1);
				end if;

				excess_fcts <= FCT_received and not FCT_used and FCTs(6) = '1';
				waiting     <= FCTs(0) = '0' and in_OR;  -- no FCT and data waiting
			end if;
		end if;
    end process;
	
	
	process(clock)
    begin
		if rising_edge( clock ) then
			if (reset = '1') then
				full       <= false;
				FCT_used   <= false;
				Tx_sent    <= 0;
				data       <= (others => '0');	    
			else
				if rx_enable then
					--FCT_used <= not full and Tx_sent = 0 and FCTs(0) = '1' and in_OR;
					if full then
						full       <= not out_IR;
						FCT_used   <= false;
					elsif in_OR and (Tx_Sent /= 0 or FCTs(0) = '1') then
						data       <= in_Data;
						full       <= true;
						FCT_used   <= Tx_Sent = 0;
						Tx_sent    <= (Tx_sent + 1) mod 8;
					else
						FCT_used   <= false;
					end if;
				else -- not rx_enable
					full     <= false;
					FCT_used <= false;
					Tx_sent  <= 0;
				end if;
			end if;
		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;