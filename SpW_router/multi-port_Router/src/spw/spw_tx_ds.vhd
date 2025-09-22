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
use work.all;

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_tx_ds is
	generic(
		Clock_frequency    : real
	);
	port( 
        -- General
        clock               : in    std_logic;
		reset               : in    std_logic;
        enable              : in    boolean;
        Error_select        : in    std_logic_vector(3 downto 0);-- := (others => '0');
        Error_inject        : in    boolean := false;
        
        Link_OK             : in    boolean;

        -- DS
        D                   :   out std_logic := '0';
        S                   :   out std_logic := '0';

        -- Data to transmit
        TxD                 : in    nonet := (others => '0');
        TxD_OR              : in    boolean;
        TxD_IR              :   out boolean;
        
        -- Time to transmit
        TxT                 : in    octet := (others => '0');
        TxT_OR              : in    boolean;
        TxT_IR              :   out boolean;
		
		-- prescalar load interface
		PSC					: in 	t_byte := (others => '0');
        PSC_valid			: in 	std_logic := '0';
		PSC_ready			: out 	std_logic := '0';
		
        -- FCT request/ack
        FCT                 : in    boolean;
        FCT_sent            :   out boolean
    );
end spw_tx_ds;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_tx_ds is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant N : integer := integer( 100.0e-9 * clock_frequency ) - 1;
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type states           is ( IDLE, RELOAD, SENDING );  
	type SpW_token        is ( SPW_NULL, SPW_NCHAR, SPW_TCHAR, SPW_FCT, SPW_ESC_EOP, SPW_ESC_EEP, SPW_ESC_ESC );  -- SpW_Timecode  	
	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal Parity         : std_logic;
	signal Data           : std_logic_vector(13 downto 0) := (others => '0');
	signal r              : std_logic_vector(13 downto 0) := (others => '0');
	signal Si             : std_logic := '0';
	signal Phase          : std_logic;
	signal next_bit       : boolean;
	signal count          : integer range 0 to N;
	signal TxData         : nonet := (others => '0');
	signal TxData_OR      : boolean;
	signal TxData_IR      : boolean;
	signal TxTime         : octet;
	signal TxTime_OR      : boolean;
	signal TxTime_IR      : boolean;
	
	signal state          : states; 
	
	signal next_token     : SpW_token;
	signal token_sent     : SpW_token;
  
	signal NULL_sent      : boolean;
	signal new_token      : boolean;

	signal pe             : std_logic := '0';
	signal inject_esc_eop : boolean;
	signal inject_esc_eep : boolean;
	signal inject_esc_esc : boolean;
	
	signal prescalar_reg		: unsigned(7 downto 0) := (others => '0');
	signal prescalar_count_reg	: unsigned(7 downto 0) := (others => '0');
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
	TxD_IR <= not TxData_OR;
    TxT_IR <= not TxTime_OR;
	FCT_sent  <= state = RELOAD and next_bit and next_token = SPW_FCT;          -- needs to be here to get >1 FCT at a time
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	process(clock)
		variable c      : std_logic := '0';
		variable p      : std_logic := '0';
    begin    
		
		if rising_edge(clock) then
			if (reset = '1') then
				Parity         <= '0';
				Data           <= (others => '0');
				r              <= (others => '0');
				Si             <= '0';
				Phase          <= '0';
				next_bit       <= true;
				count          <= 0;
				
				TxData         <= (others => '0');	    
				TxData_OR      <= false;
				
				TxTime         <= (others => '0');
				TxTime_OR      <= false;
				
				state          <= IDLE;
			
				next_token     <= SPW_NULL;
				token_sent     <= SPW_NULL;
				NULL_sent      <= false;
				new_token      <= false;
				
				PSC_ready 		<= '0';
				prescalar_reg   <= (others => '0');
				pe             <= '0';
				inject_esc_eop <= false;
				inject_esc_eep <= false;
				inject_esc_esc <= false;
			else
			  -- A 1-word FIFO
			  
			  -- Data
				if TxData_OR then
					TxData_OR  <= enable and not TxData_IR;
				elsif TxD_OR then
					TxData_OR  <= enable;
					TxData   <= TxD;
				end if;
			  
			  -- Time
				if TxTime_OR then
					TxTime_OR  <= enable and not TxTime_IR;
				elsif TxT_OR then
					TxTime_OR  <= enable;
					TxTime     <= TxT;
				end if;
				
				-- only assert PSC_ready when valid is asserted and link is OKAY
				if(PSC_valid = '1' and Link_OK = true) then
					PSC_ready <= '1';
				end if;
				
				-- load in PSC register value on handshake 
				if(PSC_valid and PSC_ready) then
					prescalar_reg <= unsigned(PSC);
				end if;
				

			  -- Reduce bit-rate at link-start
				if count = 0 then
					next_bit <= true;
					
					if (Link_OK) then 
						count <= 0;
					else 
						count <= N;
					end if;
				
				else
					next_bit <= false;
					count    <= count - 1;
				end if;
				
				-- add tx-side prescalar for custom bitrates 
				-- similar logic to above 
				if(prescalar_count_reg = 0 and Link_OK) then	-- only active when link OKAY
					prescalar_count_reg <= prescalar_reg;
					next_bit <= true;							-- set next bit 
				end if;
				
				if(prescalar_count_reg /= 0 and Link_OK) then
					prescalar_count_reg <= prescalar_count_reg - 1;
					next_bit <= false;							-- de-assert next bit 
				end if;
				
				if not enable then
					pe <= '0';
				elsif Error_inject and Error_select = force_parity_error then 
					pe <= '1';
				elsif state = RELOAD and next_bit then
					pe <= '0';
				end if;
			  
				if not enable then 
					inject_esc_eop <= false;
				elsif Error_inject and Error_select = force_esc_eop then 
					inject_esc_eop <= true;
				elsif state = RELOAD and next_bit and next_token = SPW_ESC_EOP then 
					inject_esc_eop <= false;
				end if;
			  
				if not enable  then 
					inject_esc_eep <= false;
				elsif Error_inject and Error_select = force_esc_eep then 
					inject_esc_eep <= true;
				elsif state = RELOAD and next_bit and next_token = SPW_ESC_EEP then 
					inject_esc_eep <= false;
				end if;
			  
				if not enable  then 
					inject_esc_esc <= false;
				elsif Error_inject and Error_select = force_esc_esc then 
					inject_esc_esc <= true;
				elsif state = RELOAD and next_bit and next_token = SPW_ESC_ESC then
					inject_esc_esc <= false;
				end if;
			  
			  -- select next token to send
				if inject_esc_eop  then 
					next_token <= SPW_ESC_EOP;  -- ESC_EOP          has priority over ...
				elsif inject_esc_eep then 
					next_token <= SPW_ESC_EEP;  -- ESC_EEP          has priority over ...
				elsif inject_esc_esc then 
					next_token <= SPW_ESC_ESC;  -- ESC_ESC          has priority over ...
				elsif NULL_sent and TxTime_OR then 
					next_token <= SPW_TCHAR;    -- Time             has priority over ...
				elsif NULL_sent and FCT then 
					next_token <= SPW_FCT;      -- FCT              has priority over ...
				elsif NULL_sent and TxData_OR then 
					next_token <= SPW_NCHAR;    -- Data and EOP/EEP has priority over ...
				else                               
					next_token <= SPW_NULL;     -- NULL
				end if;

				case state is
					when IDLE     => 
						Parity    <= '1';
						NULL_sent <= false;
		
						--if enable and next_bit
						if enable then
							state <= RELOAD;
						end if;

					when RELOAD    => 
						if next_bit then

							c := TxData(8);
							p := TxData(8) xor Parity;
							--t := not TxTime(0);
			
							case next_token is    --                     DD...DD C P DD C    P
								when SPW_ESC_EOP => 
									Data 	<= "000000" & B"10_1_0_11_1" & (not Parity xor pe);  
									r 		<= (13 downto  8 => '1', others => '0'); 
									Si 		<= (Parity xor pe); 
									Parity 	<= '0';  -- ESC_EOP
									
								when SPW_ESC_EEP =>
									Data 	<= "000000" & B"01_1_0_11_1" & (not Parity xor pe);
									r 		<= (13 downto  8 => '1', others => '0'); 
									Si 		<= (Parity xor pe); 
									Parity 	<= '0';  -- ESC_EEP
									
								when SPW_ESC_ESC => 
									Data 	<= "000000" & B"11_1_0_11_1" & (not Parity xor pe); 
									r 		<= (13 downto  8 => '1',  others => '0');
									Si 		<= (Parity xor pe);  
									Parity 	<= '0';  -- ESC_ESC
									
								when SPW_TCHAR   => 
									Data 	<= TxTime  &  B"0_1_11_1" & (not Parity xor pe);
									r		<= ( others => '0'); 
									Si 		<= (Parity xor pe);  
									Parity 	<= '0';  -- Time
									
								when SPW_FCT     => 
									Data	<= "0000000000"  &  B"00_1" & (not Parity xor pe); 
									r 		<= (13 downto  4 => '1', others => '0'); 
									Si 		<= (Parity xor pe);  
									Parity 	<= '1';  -- FCT
									
								when SPW_NCHAR   => 
									Data 	<= "0000" & TxData(7 downto 0) & c  & (p xor pe);  
									r 		<= (13 downto 10 => '1', 9 downto 4 => c, others => '0');  
									Si 		<= (not p  xor pe); 
									Parity 	<= '1';  -- Data and EOP/EEP
									
								when SPW_NULL    => 
									Data 	<= "000000" & B"00_1_0_11_1" & (not Parity xor pe);
									r 		<= (13 downto  8 => '1', others => '0'); 
									Si 		<= (Parity xor pe); 
									Parity 	<= '0';  -- NULL
							end case;
							
							token_sent <= next_token;
							--NULL_sent  <= NULL_sent or next_token = SPW_NULL or next_token = SpW_Turn;
							NULL_sent  <= NULL_sent or next_token = SPW_NULL;
			
							Phase <= '0';
							
							state <= SENDING;
						end if;

					when SENDING   => 
						if next_bit then
							Data   <= '0' & Data(13 downto 1);
							Phase  <= not Phase;
							Parity <= Parity xor Data(2);
							r      <= shr( '1', r );
							Si     <= not r(0) and not r(1) and (Data(1) xor Phase);
							
							--if r(2) = '1' and enable and token_sent /= SpW_Turn
							if r(2) = '1' and enable then
								state <= RELOAD;
		
							elsif r(0) = '1' then -- must have been not enable
								state <= IDLE;
		
							end if;

						end if;

				end case;
			  
				new_token <= state = RELOAD and next_bit;

				TxData_IR <= new_token and token_sent = SPW_NCHAR;
				TxTime_IR <= new_token and token_sent = SPW_TCHAR;
		
			end if;
		end if;
    end process;
	
		-- Registers Output Data/Strobe
    process (clock)
	begin
        if rising_edge(clock) then
			if (reset = '1') then
				D <= '0';
				S <= '0';
			else
				D <= Data(0);
				S <= Si;
			end if;
        end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;