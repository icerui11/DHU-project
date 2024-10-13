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
entity spw_ctrl is
	generic( 
		constant clock_frequency : real  
	);
	port ( 
		-- General
		clock                : in    std_logic;
		reset                : in    std_logic;
		
		-- Control
		link_disabled        : in    boolean;
		link_start           : in    boolean;
		link_autostart       : in    boolean;
		
		-- Status
		link_ok              :   out boolean;

		-- Rx interface
		rx_tchar           : in    boolean;
		rx_nchar           : in    boolean;
		rx_fct             : in    boolean;
		rx_error           : in    boolean;
		rx_init            : in    boolean; -- rx has seen a valid initialisation sequence
		rx_enable          :   out boolean;
	
		-- Tx interface
		tx_enable          :   out boolean;
		tx_OK_to_FCT       :   out boolean
    );
end spw_ctrl;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_ctrl is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- Timing
	constant t_6u4s                       : integer := integer(  6.4e-6 * clock_frequency );
	constant t_12u8s                      : integer := integer( 12.8e-6 * clock_frequency );
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- Link states   see Draft F(2) section 8.7
	type states                           is ( ErrorReset, ErrorWait, Ready, Started, Connecting, Run );
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal state                          : states ;--  := ErrorReset;
	
	signal rx_run                         : boolean;-- := false;
	signal tx_run                         : boolean;-- := false;
	signal tx_go_FCT                      : boolean;-- := false;
	
	signal link_good                      : boolean;-- := false;
	
	-- aux  
	signal error_fct_nchar_or_tchar       : boolean;-- := false;
	signal error_fct_nchar_tchar_or_12u8s : boolean;-- := false;
	signal error_nchar_tchar_or_12u8s     : boolean;-- := false;
	signal error_or_not_enabled           : boolean;-- := false;
	signal timer_run                      : boolean;-- := false;
	signal zero_timer                     : boolean;
	
	signal timer                          : integer range 0 to t_12u8s+1;
	
	signal at_12u8s                       : boolean;
	signal at_6u4s                        : boolean;
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
	link_OK      <= link_good;

	rx_enable    <= rx_run;
	tx_enable    <= tx_run;
	
	tx_OK_to_FCT <= tx_go_FCT;
	
	at_6u4s  <= timer_run and timer = t_6u4s;
    at_12u8s <= timer_run and timer = t_12u8s;
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process( clock, reset )
      variable link_enabled : boolean;
    begin
		if (reset = '1') then
			timer <= 0;
		elsif rising_edge(clock) then
			if (timer_run and (timer /= (t_12u8s+1))) then
				timer    <= timer + 1;
			else
				timer    <= 0;
			end if;
		end if;
    end process;
	
	
	-- Spacewire state machine
    process( clock, reset )
		variable link_enabled : boolean;
	begin
		if (reset = '1') then
			link_enabled                    := false;
			state                           <= ErrorReset;
			error_fct_nchar_or_tchar        <= false;
			error_fct_nchar_tchar_or_12u8s  <= false;
			error_nchar_tchar_or_12u8s      <= false;
			error_or_not_enabled            <= false;
			timer_run                       <= false;
			rx_run                          <= false;
			tx_run                          <= false;
			tx_go_FCT                       <= false;
			
		elsif rising_edge(clock) then
	
			link_enabled := not link_disabled and ( link_start or ( link_autostart and rx_init ) );
	
			error_fct_nchar_or_tchar       <= rx_error or rx_fct or rx_nchar or rx_tchar;
			error_fct_nchar_tchar_or_12u8s <= rx_error or rx_fct or rx_nchar or rx_tchar or (timer_run and at_12u8s);
			error_nchar_tchar_or_12u8s     <= rx_error or           rx_nchar or rx_tchar or (timer_run and at_12u8s);
			error_or_not_enabled           <= rx_error or not link_enabled;
	
			case state is
				when ErrorReset => 
					rx_run <= false;
					tx_run <= false;

					if timer_run and at_6u4s then
						timer_run <= false;
						state     <= ErrorWait;
					else
						timer_run <= true;
					end if;
					
				when ErrorWait  => 
					rx_run <= true;
					tx_run <= false;

					if error_fct_nchar_or_tchar then
						timer_run <= false;
						state     <= ErrorReset;

					elsif timer_run and at_12u8s then
						timer_run <= false;
						state     <= Ready;

					else
						timer_run <= true;
					end if;
	
				when Ready      => 
					rx_run <= true;
					tx_run <= false;
	
					if error_fct_nchar_or_tchar then
						state     <= ErrorReset;
	
					elsif link_enabled then
						state     <= Started;
					end if;
		
				when Started    => 
					rx_run <= true;
					tx_run <= true;
	
					if error_fct_nchar_tchar_or_12u8s then
						timer_run <= false;
						state     <= ErrorReset;
	
					elsif rx_init then
						timer_run <= false;
						state     <= Connecting;
	
					else
						timer_run <= true;
					end if;
		
				when Connecting => 
					rx_run <= true;
					tx_run <= true;
	
					if error_nchar_tchar_or_12u8s then
						timer_run <= false;
						state     <= ErrorReset;
	
					elsif rx_fct then
						timer_run <= false;
						state     <= Run;
	
					else
						timer_run <= true;
					end if;
		
				when Run        => 
					rx_run <= true;
					tx_run <= true;
	
					if error_or_not_enabled then
						timer_run <= false;
						state     <= ErrorReset;
					end if;
			end case;
	
			link_good        <= state = Run;
			tx_go_FCT        <= state = Connecting or state = Run;
	
		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;