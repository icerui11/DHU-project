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


----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_rx_bit_rate is
generic(
		clock_frequency    : real;
		max_bits_per_clock : integer
    );
port( 
       clock               : in    	std_logic;
       reset               : in    	boolean;
       bits_per_clock      : in    	integer range 0 to max_bits_per_clock;
       rx_rate             : out 	std_logic_vector(15 downto 0) := X"0000"
    );
end spw_rx_bit_rate;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_rx_bit_rate is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant clocks_in_4us   : integer := integer(   4.0e-6 * clock_frequency );
	constant clocks_in_40us  : integer := integer(  40.0e-6 * clock_frequency );
	constant clocks_in_400us : integer := integer( 400.0e-6 * clock_frequency );
	
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
	signal time_count             : integer range 0 to clocks_in_400us + 20;
  
	signal t0                : boolean;
	signal t4                : boolean;
	signal t40               : boolean;
	signal t400              : boolean;

	signal count             : integer range 0 to 4090;
	signal rounded_count     : integer range 0 to 1023;

	signal low_count         : boolean;
	signal high_count        : boolean;
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
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clock, reset)
    begin
		if reset then
			rx_rate       <= (others => '0');
			time_count    <= 0;
			t0            <= false;
			t4            <= false;
			t40           <= false;
			t400          <= false;
			low_count     <= true;
			high_count    <= false;
			count         <= 0;
			rounded_count <= 0;
       
		elsif rising_edge(clock) then

			if time_count= clocks_in_400us + 10 then 
				time_count<= 0;
			else 
				time_count<= time_count+ 1;
			end if;
			
			t0   <= time_count= 0;
			t4   <= time_count= 2 + clocks_in_4us;
			t40  <= time_count= 1 + clocks_in_40us;
			t400 <= time_count= 0 + clocks_in_400us;
			
	
			if t0 then
				count      <= 0;
				low_count  <= true;
				high_count <= false;
			else
				if not high_count then 
					count <= count + bits_per_clock;
				end if;
				low_count  <= count < 398;
				high_count <=              3998 <= count;
			end if;
            
			rounded_count <= (count / 4) + ((count / 2) mod 2);
            
			if low_count then
				if t400 then 
					rx_rate <= X"0000";
				end if;
			else
				if not high_count then
					if t400 then 
						rx_rate <= "100110" & std_logic_vector( to_unsigned(rounded_count, 10) ); --   1.00 to   9.99
					elsif t40 then 
						rx_rate <= "100111" & std_logic_vector( to_unsigned(rounded_count, 10) ); --  10.0  to  99.9
					elsif t4 then 
						rx_rate <= "101000" & std_logic_vector( to_unsigned(rounded_count, 10) ); -- 100    to 999
					end if;
				end if;
			end if;
		end if;
    end process;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;