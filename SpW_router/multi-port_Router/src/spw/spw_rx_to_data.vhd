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
entity spw_rx_to_data is
	port( 
		-- General
		Clock               : in    std_logic;
		reset               : in    std_logic;

		Enable              : in    boolean;

		See_null            : in    boolean; -- true if null is to be reported
		See_fct             : in    boolean; -- true if fct is to be reported

		-- Received 2bit data from rx_to_2b
		First               : in    std_logic;
		Second              : in    std_logic;
		Valid               : in    boolean;

		-- Problems
		Too_many_FCTs       : in    boolean;
		Timeout_error       : in    boolean;
		Error               : out 	boolean;

		-- Received data output
		RxD                 : out 	nonet;
		RxD_OR              : out 	boolean;
		RxD_IR              : in    boolean;

		-- Received time output
		RxT                 : out 	octet := (others => '0');
		RxT_OR              : out 	boolean;

		-- MISC
		NULL_seen           : out 	boolean;
		FCT_received        : out 	boolean
    );
end spw_rx_to_data;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_rx_to_data is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type states           is ( disabled, idle, Rx_PC, Rx_01, Rx_23, Rx_45, Rx_67, stalled, restart );

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal Rx01           : boolean;
	signal Rx0111         : boolean;
	signal Rx011101       : boolean;
	signal Rx01110100     : boolean;
	signal state          : states;
  
	signal RxDi           : nonet;  
	signal Parity         : std_logic;

	signal Ctrl_bit       : std_logic;
	signal Rx_Nchar       : boolean;
	signal Rx_Tchar       : boolean;
	signal Rx_FCT         : boolean;
	signal Rx_ESC         : boolean;
	signal Rx_ESC_FCT     : boolean;
	signal Rx_ESC_EOP     : boolean;
	signal Rx_ESC_EEP     : boolean;
	signal Rx_ESC_ESC     : boolean;

	signal too_much_data  : boolean;

	signal data_rdy       : boolean;
	signal time_rdy       : boolean;
	signal fct_rdy        : boolean;

	signal rxd_or_stretch : boolean;
	signal rxt_or_stretch : boolean;
	signal fct_stretch    : boolean;
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
	NULL_seen 		<= state /= idle;
	RxD_OR       	<= rxd_or_stretch;
    RxT_OR       	<= rxt_or_stretch;
    FCT_received 	<= fct_stretch;
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
    process(Clock)
    begin
		if rising_edge( Clock ) then
			if (reset = '1') then
				state           <= disabled;
				Rx01            <= false;
				Rx0111          <= false;
				Rx011101        <= false;
				Rx01110100      <= false;
				Parity          <= '0';
				Ctrl_bit        <= '0';
				RxDi            <= (others => '0');
				RxD             <= (others => '0');
				Rx_ESC          <= false;
				Rx_ESC_EOP      <= false;
				Rx_ESC_EEP      <= false;
				Rx_ESC_ESC      <= false;
				Rx_Nchar        <= false;
				Rx_Tchar        <= false;
				Rx_FCT          <= false;
				data_rdy        <= false;
				time_rdy        <= false;
				fct_rdy         <= false;
				rxd_or_stretch  <= false;
				rxt_or_stretch  <= false;
				fct_stretch     <= false;
			else
				case state is
					when disabled=>
						Error           <= false;
						Rx01            <= false;
						Rx0111          <= false;
						Rx011101        <= false;
						Rx01110100      <= false;
						rxd_or_stretch  <= false;
						rxt_or_stretch  <= false;
						fct_stretch     <= false;
						data_rdy        <= false;
						time_rdy        <= false;
						fct_rdy         <= false;
						Rx_ESC          <= false;
						Rx_ESC_FCT      <= false;
						Rx_ESC_EOP      <= false;
						Rx_ESC_EEP      <= false;
						Rx_ESC_ESC      <= false;
						Rx_Nchar        <= false;
						Rx_Tchar        <= false;
						Rx_FCT          <= false;
						Parity          <= '0';
						
						if enable
						  then state <= idle;
						end if;
				
					when idle    => -- Effectively: Rx_PC
						if timeout_error	then
							state <= restart;
						elsif valid then
							Rx01         <=                first = '0' and second = '1';
							Rx0111       <= Rx01       and first = '1' and second = '1';
							Rx011101     <= Rx0111     and first = '0' and second = '1';
							Rx01110100   <= Rx011101   and first = '0' and second = '0';
							if              Rx01110100 and first = '0' and second = '1' then 
								state <= Rx_01;
							end if;
							
							Ctrl_bit     <= '1'; -- required in above (second) -- Control bit delayed from Rx_PC to Rx_01

						end if;  

					when Rx_PC   =>
						if timeout_error then
							state <= stalled;

						elsif valid then
							--time_rdy <= (Parity xor first xor second) = '1' and Rx_Tchar;
							fct_rdy  <= (Parity xor first xor second) = '1' and Rx_FCT;
							
							case (Parity xor first xor second) is
							  --when '1' => if    Rx_ESC and second = '0' then RxDi <= TCODE;    data_rdy <= true;  state <= Rx_01;
								when '1' => 
									if Rx_ESC and second = '0' then
										state 		<= Rx_01;
									elsif Rx_Nchar then                      
										data_rdy 	<= true;  
										state 		<= Rx_01;
									elsif Rx_Tchar                then 
										RxDi(8) 	<= '0';  
										time_rdy 	<= true;  
										state 		<= Rx_01;
									elsif Rx_ESC_ESC              then 
										RxDi 		<= SPW_ESC_ESC;  
										data_rdy 	<= true;  
										state 		<= restart;
									elsif Rx_ESC_EOP              then 
										RxDi 		<= SPW_ESC_EOP;  
										data_rdy 	<= true;  
										state 		<= restart;
									elsif Rx_ESC_EEP              then 
										RxDi 		<= SPW_ESC_EEP;  
										data_rdy 	<= true;  
										state	 	<= restart;
									elsif Rx_FCT     and see_fct  then 
										RxDi 		<= SPW_FCT;      
										data_rdy 	<= true;  
										state 		<= Rx_01;
									elsif Rx_ESC_FCT and see_null then 
										RxDi 		<= SPW_ESC_FCT;  
										data_rdy 	<= true;  
										state 		<= Rx_01;
									else                                                     
										data_rdy 	<= false; 
										state 		<= Rx_01;
									end if;
									
								when others =>                                 
									RxDi 		<= SPW_PERROR1;  
									data_rdy 	<= true;  
									state 		<= restart;
									
							end case;
							
							Ctrl_bit     <= second; -- Control bit delayed from Rx_PC to Rx_01
							
						end if; -- valid

					when Rx_01   =>
						data_rdy <= false;
						fct_rdy  <= false;
						time_rdy <= false;
						
						if timeout_error then
							state <= stalled;
						elsif valid then
							data_rdy     <= false;
							fct_rdy      <= false;
							time_rdy     <= false;

							Parity       <= first xor second;
						
							RxDi(0)      <= first;
							RxDi(1)      <= second;
							RxDi(2)      <= '0';
							RxDi(3)      <= '0';
							RxDi(4)      <= '0';
							RxDi(5)      <= '0';
							RxDi(6)      <= '0';
							RxDi(7)      <= '0';
							RxDi(8)      <= Ctrl_bit; -- and not Rx_ESC   instead of splitting Nchar and Tchar ???
						
							Rx_Nchar     <= 	not Rx_ESC and ( Ctrl_bit = '0' or (Ctrl_bit = '1' and first /= second) );
							Rx_FCT       <= 	not Rx_ESC and Ctrl_bit = '1' and first = '0' and second = '0';
							Rx_ESC       <= 	not Rx_ESC and Ctrl_bit = '1' and first = '1' and second = '1';

							Rx_Tchar     <=     Rx_ESC and Ctrl_bit = '0';
							Rx_ESC_FCT   <=     Rx_ESC and Ctrl_bit = '1' and first = '0' and second = '0';
							Rx_ESC_EOP   <=     Rx_ESC and Ctrl_bit = '1' and first = '0' and second = '1';
							Rx_ESC_EEP   <=     Rx_ESC and Ctrl_bit = '1' and first = '1' and second = '0';
							Rx_ESC_ESC   <=     Rx_ESC and Ctrl_bit = '1' and first = '1' and second = '1';
						
							if Ctrl_bit = '1' then 
								state <= Rx_PC; --  4-bit token
							else 
								state <= Rx_23; -- 10-bit token
							end if;
						end if;

					when Rx_23   =>
						if timeout_error then
							state <= stalled;
							
						elsif valid then
							Parity  <= Parity xor first xor second;
							RxDi(2) <= first;
							RxDi(3) <= second;
							state   <= Rx_45;
						end if;
	 
					when Rx_45   =>
						if timeout_error then
							state <= stalled;	
						elsif valid then
							Parity  <= Parity xor first xor second;
							RxDi(4) <= first;
							RxDi(5) <= second;
							state   <= Rx_67;
						end if;

					when Rx_67   =>
						if timeout_error then
							state <= stalled;
						elsif valid then
							Parity  <= Parity xor first xor second;
							RxDi(6) <= first;
							RxDi(7) <= second;
							state   <= Rx_PC;
						end if;
				
					when stalled => 
						RxDi	 	<= SPW_TIMEOUT;
						data_rdy   	<= true;
						state      	<= restart;
						
					when restart => 
						data_rdy   <= false;
						Error      <= true;
						if not enable then	-- if enable = '0'
							state <= disabled;
						end if;
						
				end case;

			  if data_rdy then
				RxD <= rxDi;
			  end if;

			  if time_rdy then
				RxT <= rxDi(7 downto 0);
			  end if;

			  rxd_or_stretch 	<= data_rdy;
			  
			  rxt_or_stretch 	<= time_rdy;
			  
			  fct_stretch 		<= fct_rdy;
			end if;
		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;