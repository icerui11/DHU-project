----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:
-- @ Engineer				:	James E Logan
-- @ Role					:	
-- @ Company				:	
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
use work.all;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_rx_to_2b_RTG4 is
	port( 
		-- General
		clock               : in    std_logic := '0';
		reset               : in    std_logic := '0';
		
		-- DS
		Din_r               : in    std_logic := '0';
		Din_f               : in    std_logic := '0';
		Sin_r               : in    std_logic := '0';
		Sin_f               : in    std_logic := '0';
		
		-- D
		first               : out 	std_logic := '0';
		second              : out 	std_logic := '0';
		bit_ok              : out 	boolean;
		valid               : out 	boolean
    );
end spw_rx_to_2b_RTG4;
---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_rx_to_2b_RTG4 is

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
	signal disable        : boolean := true;

	-- DS signals  
	signal D_r            : std_logic := '0';
	signal D_f            : std_logic := '0';

	signal D_fst          : std_logic := '0';
	signal D_scd          : std_logic := '0';
	signal D_first        : std_logic := '0';
	signal D_second       : std_logic := '0';

	signal S_r            : std_logic := '0';
	signal S_f            : std_logic := '0';

	signal S_fst          : std_logic := '0';
	signal S_scd          : std_logic := '0';

	signal C_scd          : std_logic := '0';

	signal V_first        : std_logic := '0';
	signal V_second       : std_logic := '0';

	signal V1             : std_logic := '0';
	signal V2             : std_logic := '0';
	signal VV1            : std_logic := '0';
	signal VV2            : std_logic := '0';

	signal D1             : std_logic := '0';
	signal D2             : std_logic := '0';
	signal DD3            : std_logic := '0';

	signal bit_seen       : boolean;
	signal pair           : boolean;
	
	signal bit_1          : std_logic := '0';
	signal bit_2          : std_logic := '0';
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
	u_rx_sync_d: entity work.spw_rx_sync_RTG4		-- rx DATA input sample logic
	port map(
		clock    => clock,				-- rising_edge clock
		reset    => reset,				-- async reset
		D_r      => Din_r,				-- Data input (rising)
		D_f      => Din_f,				-- Data input (falling)
		Qr       => D_r,				-- Data output (rising)
		Qf       => D_f					-- Data output (falling)
	);
		
	u_rx_sync_s: entity work.spw_rx_sync_RTG4		-- rx STROBE input sample logic
	port map(
	   clock    => clock,				-- rising_edge clock
	   reset    => reset,               -- async reset
	   D_r      => Sin_r,               -- Strobe input (rising)
	   D_f      => Sin_f,               -- Strobe input (falling)
	   Qr       => S_r,                 -- Strobe output (rising)
	   Qf       => S_f                  -- Strobe output (falling)
	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	first  <= bit_1;					-- assign bit_1 to first
    second <= bit_2;					-- assign bit_2 to second
    bit_ok <= bit_seen;					-- assing bit_ok to bit_seen
    Valid  <= pair;						-- assing valid to pair.
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clock)
	begin
		if rising_edge(clock) then
			if(reset = '1') then
				disable <= true;
			else
				disable <= false;
			end if;
		end if;
	end process;

    process(clock)
    begin
		if rising_edge(clock) then		-- rising edge clock ?
			if (reset = '1') then		-- reset asserted ?
				D_fst    <= '0';		-- clear registers
				D_scd    <= '0';        

				S_fst    <= '0';
				S_scd    <= '0';

				C_scd    <= '0';

				V_first  <= '0';
				V_second <= '0';

				D_first  <= '0';
				D_second <= '0';

				V1       <= '0';
				V2       <= '0';
				VV1      <= '0';
				VV2      <= '0';

				D1       <= '0';
				D2       <= '0';
				DD3      <= '0';

				bit_1    <= '0';
				bit_2    <= '0';

				bit_seen <= false;
				pair     <= false;
			else
			
				D_fst <= D_f;					-- sample D_first as falling_edge D input
				D_scd <= D_r;					-- sample D_second as rising_edge D input

				S_fst <= S_f;					-- sample S_first as falling_edge D input
				S_scd <= S_r;                   -- sample S_second as rising_edge D input

				C_scd <= S_scd xor D_scd;		-- recover signal clock from XOR of S & D

			  -----------------------------------------------
			  -- One or 2 bits and their valid flags, either could be valid (or both)
			  
				V_first  <= S_fst xor D_fst xor C_scd;				-- first bit valid ?
				V_second <= S_scd xor D_scd xor S_fst xor D_fst;	-- second bit valid ?

				bit_seen <= V_first = '1' or V_second = '1';		-- either first or second bit valid ?

				D_first  <= D_fst;									-- carry D_first into next clock cycle via register
				D_second <= D_scd;									-- carry D_second into next clock cycle via register
			  
			  -----------------------------------------------
			  -- Pack downward

				V1 <= V_first or V_second;							-- valid data sampled on rising of sample clock ?
				V2 <= V_first and V_second;							-- valid data on falling edge of sample clock ?

				if V_first = '1' then 								-- valid data on first edge ?
					D1 <= D_first;									-- load into D1 register
				else 												-- v_first not valid ?
					D1 <= D_second;									-- load second sample into D1
				end if;
				D2 <= D_second;										-- load second sample into D2

			  -- D1/V1 is first D2/V2 is second
			  -----------------------------------------------

				if VV1 = '0' and VV2 = '0' then
					bit_1  <= D1;
					VV1    <= V1 and not V2;
					bit_2  <= D2;
					pair   <= disable or (V1 = '1' and V2 = '1');

				elsif VV1 = '0' and VV2 = '1' then
					bit_1  <= DD3;
					VV1    <= VV2 and not V1;
					bit_2  <= D1;
					DD3    <= D2;
					VV2    <= V2;
					pair   <= disable or (V1 = '1');

				elsif VV1 = '1' /*and VV2 = '0' */then
					VV1    <= not V1;
					bit_2  <= D1;
					DD3    <= D2;
					VV2    <= V2;
					pair   <= disable or (V1 = '1');
				else
					pair   <= disable;
				end if;
			end if;
		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;