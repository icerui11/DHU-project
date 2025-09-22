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
-- Memory user/interface
--
-- Request indicates valid
--   - Address         (40-bits)
--   - Bytes           (24-bits)
--   - Logical address (received)
--   - Key             (received)
--   - Write           (not write ==> read)
--   - Static_address  (address won't increment)
--
-- Reply with one of
--   - Reject_target          (reject the request - highest priority) * \
--   - IO_invalid_key         (reject the request                   ) *  \ Uses the highest asserted priority
--   - Reject_request         (reject the request                   ) *  / if more than one is asserted
--   - Accept_request         (if OK to proceed   - lowest priority ) * /
--
--   Use none to all of the above valid signals to make a decision
--
-- For a read request, the number of bytes read/returned is given by the smaller of ( output Bytes, input Read_bytes )
--   (if not otherwise required, connect Read_bytes to Bytes)
--
-- If the request is accepted
-- Write: there will be a sequence of <Bytes>      writes followed by Done
-- Read : there will be a sequence of <Read_bytes> reads  followed by Done
--
-- Done is asserted for one clock cycle at the end of the transaction
-- OK is valid when Done is asserted
--   OK is true if
--     - verify is not set
--    or
--     - verify is set and the transaction has no error
--
-- RW_request indicates valid read or write
--   - assert RW_acknowledge when done *
--
-- * can be given constant values (e.g. always accept, write/read done immediately)
--
--
-- Possible status reply values:
--    constant success                 : integer :=  0;
--    constant unused_type_code        : integer :=  2;
--    constant invalid_key             : integer :=  3;
--    constant invalid_data_CRC        : integer :=  4;
--    constant unexpected_EOP          : integer :=  5;
--    constant too_much_data           : integer :=  6;
--    constant unexpected_EEP          : integer :=  7;
--    constant verify_buffer_overrun   : integer :=  9;
--    constant command_not_possible    : integer := 10;
--    constant invalid_target_address  : integer := 12;
-- Revision History :
-------------------------------------------------------------------------------

library ieee;  
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 4Links packages (uses context clause in router design) 
context work.rmap_context;

entity rmap_target is
	port( 
		clock              : in    std_logic;
		async_reset        : in    boolean;	-- disconnected 
		reset              : in    boolean;

		-- Data Flow Link input, Requests
		In_data            : in    t_nonet;
		In_ir              :   out boolean;
		In_or              : in    boolean;
		
		-- Data Flow Link output, Response
		Out_data           :   out t_nonet;
		Out_IR             : in    boolean;
		Out_OR             :   out boolean;
		
		-- Memory Interface
		Address            :   out unsigned(39 downto 0);
		wr_en              :   out boolean;
		Write_data         :   out std_logic_vector( 7 downto 0);
		Bytes              :   out unsigned(23 downto 0);
		Read_data          : in    std_logic_vector( 7 downto 0);
		Read_bytes         : in    unsigned(23 downto 0);

		-- Bus handshake
		RW_request         :   out boolean;
		RW_acknowledge     : in    boolean;

		-- Control/Status 
		Echo_required      : in    boolean;
		Echo_port          : in    t_byte;

		Logical_address    :   out unsigned(7 downto 0);
		Key                :   out std_logic_vector(7 downto 0);
		Static_address     :   out boolean;

		Checksum_fail      :   out boolean;
		
		Request            :   out boolean;
		Reject_target      : in    boolean;
		Reject_key         : in    boolean;
		Reject_request     : in    boolean;
		Accept_request     : in    boolean;

		Verify_overrun     : in    boolean;

		OK                 :   out boolean;
		Done               :   out boolean
    );
end rmap_target;

architecture RTL of rmap_target is

-- --In-> incrc --S-> rmap --Y-> outcrc --Out->

  signal echo_path       : t_byte;

  -- CRC'ed SpW
  signal s_data          : t_nonet;
  signal s_CRC_OK        : boolean;
  signal s_OR            : boolean;
  signal s_IR            : boolean;

  -- RMAP to SpW
  signal y_data          : t_nonet;
  signal y_or            : boolean;
  signal y_ir            : boolean;
  signal y_crc           : boolean;
  
  signal TxCRC           : t_byte;

  signal to_spw_data     : t_nonet;
  
  signal io_bytes_null : boolean := false;

-------------------------------------------------------------------------------
-- RMAP states
-------------------------------------------------------------------------------
    type states               is ( IDLE,
                                   RX,
                                   DISCARD,
                                   RMAP_READ,
                                   RMAP_RD,
                                   RMAP_WRITE,
                                   RMAP_WR,
                                   MWRITE,
                                   MWRITE_1,
                                   MWRITE_1A,
                                   MWRITE_2,
                                   MWRITE_3,
                                   DISCARD_AND_REPLY,
                                   REPLY,
                                   REPLY_E,
                                   REPLY_R,
                                   REPLY_PREFIX,
                                   REPLY_PREFIX_2,
                                   REPLY_DESTINATION,
                                   REPLY_PROTOCOL_ID,
                                   REPLY_TYPE,
                                   REPLY_STATUS_CODE,
                                   REPLY_SOURCE,
                                   REPLY_TRANSACTION_MSB,
                                   REPLY_TRANSACTION_LSB,
                                   REPLY_READ,
                                   REPLY_LENGTH_MSB,
                                   REPLY_LENGTH_SSB,
                                   REPLY_LENGTH_LSB,
                                   REPLY_HEADER_CRC,
                                   REPLY_DATA,
                                   REPLY_DATA_ACK,
                                   REPLY_DATA_ACKA,
                                   REPLY_FINAL_CRC,
                                   REPLY_EOP,
                                   REPLY_EOP_DONE
                                 );
    signal state               : states;
    signal N                   : integer range 0 to 15;
    signal expected            : integer range 0 to 31;
    signal rx_byte             : t_nonet_array(15 downto 0);
    signal rmap_status_code    : integer range 0 to 255;

    signal target_logical_address    : std_logic_vector( 7 downto 0);
    signal instruction               : std_logic_vector( 7 downto 0);
    signal initiator_logical_address : std_logic_vector( 7 downto 0);
    signal transaction_identifier    : std_logic_vector(15 downto 0);
--    signal rmap_length               : std_logic_vector(23 downto 0);

    signal read_command              : boolean;
    signal write_command             : boolean;
    signal verify                    : boolean;
    signal reply_required            : boolean;
    signal increment_address         : boolean;
    
    signal request_address           : std_logic_vector(39 downto 0);
    signal request_bytes             : std_logic_vector(23 downto 0);

    signal io_address                : unsigned(39 downto 0);
    signal io_bytes                  : unsigned(23 downto 0);

    signal command_type              : std_logic_vector( 1 downto 0);
    signal command_code              : std_logic_vector( 3 downto 0);

    signal reply_prefix_bytes        : integer range 0 to 12;
    signal reply_prefix_candidates   : integer range 0 to 12;
    signal reply_prefix_data         : t_byte_array(11 downto 0);
    signal reply_prefix_N            : integer range 0 to 12;
	
	signal has_eep_eop_incrc		: std_logic := '0';

-- These should be in a separate module
    constant PROTOCOL_RMAP           : integer :=  1;
-- These should be in a separate module
    constant SUCCESS                 : integer :=  0;
    constant GENERAL_ERROR           : integer :=  1;
    constant UNUSED_TYPE_CODE        : integer :=  2;
    constant INVALID_KEY             : integer :=  3;
    constant INVALID_DATA_CRC        : integer :=  4;
    constant UNEXPECTED_EOP          : integer :=  5;
    constant TOO_MUCH_DATA           : integer :=  6;
    constant UNEXPECTED_EEP          : integer :=  7;
  --constant -reserved-              : integer :=  8;
    constant VERIFY_BUFFER_OVERRUN   : integer :=  9;
    constant COMMAND_NOT_POSSIBLE    : integer := 10;
  --constant RMW_DATA_LENGTH_ERROR   : integer := 11;
    constant INVALID_TARGET_ADDRESS  : integer := 12;

  ----------------------------------------------------------------------------------------------------------------------------------------
    
begin
    
    target_logical_address    <= rx_byte( 0)(7 downto 0);
    --Protocol_ID             <= rx_byte( 1)(7 downto 0);
    instruction               <= rx_byte( 2)(7 downto 0);
    Key                       <= rx_byte( 3)(7 downto 0);
    initiator_Logical_Address <= rx_byte( 4)(7 downto 0);
    transaction_Identifier    <= rx_byte( 5)(7 downto 0)
                               & rx_byte( 6)(7 downto 0);
    request_address           <= rx_byte( 7)(7 downto 0)
                               & rx_byte( 8)(7 downto 0)
                               & rx_byte( 9)(7 downto 0)
                               & rx_byte(10)(7 downto 0)
                               & rx_byte(11)(7 downto 0);
    request_bytes             <= rx_byte(12)(7 downto 0)
                               & rx_byte(13)(7 downto 0)
                               & rx_byte(14)(7 downto 0);
    --Header_CRC              <= rx_byte(15)(7 downto 0);
    
    
    command_type              <= rx_byte(2)(7 downto 6);
    command_code              <= rx_byte(2)(5 downto 2);

    read_command              <= rx_byte(2)(7 downto 3) = "01001";
    write_command             <= rx_byte(2)(7 downto 5) = "011";
    verify                    <= rx_byte(2)(4) = '1';
    reply_required            <= rx_byte(2)(3) = '1';
    increment_address         <= rx_byte(2)(2) = '1';
    
    
    Logical_address           <= unsigned( target_logical_address );
--    wr_en                     <= write_command;
    Address                   <= io_address;
    Bytes                     <= io_bytes;
    Static_address            <= not increment_address;
    io_bytes_null 			  <= io_bytes = 0;

    -- CRC SpW In_data

    incrc: block
		type states      is (/*SOP,*/ RX, CRC_LOOP, CRC_DONE, COPY );
		signal state      : states;
		signal I          : integer range 0 to 7;
		signal CRC        : std_logic_vector(7 downto 0);   
    begin
	
		process (clock)
		begin
			if rising_edge( clock ) then
				if reset then
					state     <= RX; --SOP;
					s_data    <= (others => '0');
					s_OR      <= false;
					In_IR     <= false;
					I         <= 0;
					CRC       <= (others => '0');
					s_CRC_OK  <= false;
					echo_path <= (others => '0');
				else
					case state is
					--	when IDLE     => 
					--		state <= SOP;
	
					--	when SOP      => 
					--		In_IR <= true;
					--		CRC   <= (others => '0');
					--		state <= RX;
		
						when RX       => 
							has_eep_eop_incrc <= '0';
							In_IR <= true;
							if In_OR then
								echo_path <= Echo_port;						
								s_data <= In_data;	
								state <= CRC_LOOP;	
								In_IR <= false;
								if In_data = SPW_EOP or In_data = SPW_EEP then
									has_eep_eop_incrc <= '1';
									s_OR  <= true;
									state <= COPY;
								else -- everything else, including errors, goes for CRC (should fail) and to S
									I     <= 0;
								end if;
							end if;
		
						when CRC_LOOP => 
							CRC <=	CRC(6 downto 2)
									& (s_data(I) xor CRC(7) xor CRC(1))
									& (s_data(I) xor CRC(7) xor CRC(0))
									& (s_data(I) xor CRC(7)           );
							if I = 7 then
								state <= CRC_DONE;
							else
								I <= I + 1;
							end if;
		
						when CRC_DONE => 
							s_OR     <= true;
							s_CRC_OK <= CRC = X"00"; -- evaluates true when CRC == x"00", false when others...
							state    <= COPY;
		
						when COPY     => 
							if s_IR then
								s_OR  <= false;
								In_IR <= true;
								state <= RX;
								if has_eep_eop_incrc = '1' then
									state <= RX; --SOP;
									CRC   <= (others => '0');
									In_IR <= false;
								end if;
								
							end if;
					end case;
				end if;
			end if;
		end process;
		
    end block;


-------------------------------------------------------------------------------
-- RMAP state machine
-------------------------------------------------------------------------------
    process (clock)
    begin
		if rising_edge( clock ) then
			if reset then
				wr_en				 	<= false;
				state                   <= IDLE;
				y_or                    <= false;
				y_data                  <= (others => '0');
				y_crc                   <= true;
				s_ir                    <= false;
				Done                    <= false;
				OK                      <= false;
				rx_byte       		    <= (others => (others => '0'));
				io_bytes                <= (others => '0');
				io_address              <= (others => '0');
				rmap_status_code        <= 0;
				RW_request              <= false;
				Request                 <= false;
				write_data              <= (others => '0');
				N                       <= 0;
				Checksum_fail           <= false;
				reply_prefix_bytes      <= 0;
				reply_prefix_candidates <= 0;
				reply_prefix_data       <= (others => (others => '0'));
				reply_prefix_N          <= 0;
			else
				case state is
					when IDLE => 	
						Done               <= false;
						OK                 <= false;
						N                  <=  0;
						expected           <= 16;
						rmap_status_code   <=  0;
						reply_prefix_bytes <=  0;
						s_ir               <= true;
						state              <= RX;

					when RX  =>	
						if s_or then
							rx_byte(N) <= s_data;
							case N is
								when  0 => -- Check first byte is logical address (also catches early EOP/EEP)
									if s_data(7 downto 5) = "000" or s_data(8) = '1' then
										state <= DISCARD;
									end if;
									N <= N + 1;

								when  1 => -- Check second byte is RMAP protocol ID (1) (also catches earlyEOP/EEP)
									if s_data(8) /= '0' or s_data(7 downto 0) /= std_logic_vector( to_unsigned(protocol_RMAP, 8) ) then
										state <= DISCARD;
									end if;
									N <= N + 1;

								when  2 => -- Check third byte is RMAP command (also catches early EOP/EEP)
									if s_data(6) = '0' or s_data(8) = '1' then
										state <= DISCARD;
									end if;
									-- Check for return Path Address
									reply_prefix_candidates <= 4 * to_integer( unsigned( s_data(1 downto 0) ) );
									N <= N + 1;

								when  3 => -- Check for early EOP/EEP
									if s_data(8) /= '0' then
										state <= DISCARD;
									end if;
									N <= N + 1;
								
								when  4 => -- Check for early EOP/EEP
								
									if reply_prefix_candidates /= 0 and s_data(8) = '0' then
										reply_prefix_candidates <= reply_prefix_candidates - 1;
										if s_data(7 downto 0) /= X"00" or reply_prefix_candidates = 1 or reply_prefix_bytes /= 0 then
											reply_prefix_data(reply_prefix_bytes) <= s_data(7 downto 0);
											reply_prefix_bytes               <= reply_prefix_bytes + 1;
										end if;
									end if;
									
									if s_data(8) = '0' and reply_prefix_candidates = 0 then
										N <= N + 1;
									end if;
									
									if s_data(8) = '1' then
										state <= DISCARD;
									-- Collect return path, if there is one to collect
									end if;
								
								when  5 to 14 => -- Check for early EOP/EEP
									if s_data(8) /= '0' then
										state <= DISCARD;
									end if;
									N <= N + 1;

								when 15 => -- Action setup inital rmap address and size, then check if valid transaction
									io_address <= unsigned( request_address );
									io_bytes   <= unsigned( request_bytes );
									if s_CRC_OK then
										case command_type is
											when "00" => -- Response (we should never get here, we pre-selected only commands)
												state <= DISCARD;
											
											when "01" => -- Command
												case command_code is
													when	"0000" | "0001"	| "0100" | "0101" | "0110" => -- Invalid
														state <= DISCARD; --rmap_status_code <= unused_type_code;
									
													when 	"0010" | "0011" => -- Read single/incrementing address
														state <= RMAP_READ;
													
													when "0111" => -- RMW incrementing addresses
														rmap_status_code <= command_not_possible;
														state            <= DISCARD_AND_REPLY;
										
													when others => -- Write single/incrementing address
														s_ir  <= false;
														state <= RMAP_WRITE;
														
												end case;
											
											when "10" => -- Response: Discard (we should never get here, we pre-selected only commands)
												state <= DISCARD;
											
											when "11" => -- Command: Discard/reply (error code 2)
												rmap_status_code <= unused_type_code;
												state            <= DISCARD_AND_REPLY;
											when others => null;
										
										end case;
									else -- not s_CRC_OK --> header_crc_error
										Checksum_fail <= true;
										state <= DISCARD;
									end if;

							end case;
						end if;

					when DISCARD => 	
						Checksum_fail <= false;
						if s_or and (s_data = SPW_EOP or s_data = SPW_EEP) then
							s_ir     <= false;
							state    <= IDLE;
						end if;

					when DISCARD_AND_REPLY => 
						Done          <= false;
						Checksum_fail <= false;
						if s_or and (s_data = SPW_EOP or s_data = SPW_EEP) then
							s_ir  <= false;
							state <= REPLY;
						end if;

					when RMAP_WRITE	=>	-- Start Write transaction
						Request          <= true;
						state            <= RMAP_WR;
						
					when RMAP_WR  	=>  -- Check for valid request
					
					-- remove elsif chain for timing 
						if Accept_request then
							Request          <= false;
							s_ir             <= true;
							state <= MWRITE; -- multi transer
							if io_bytes_null then 
								state <= MWRITE_2; -- last transfer
							end if;
						end if;
						
						if Reject_request then
							Request          <= false;
							rmap_status_code <= command_not_possible;
							s_ir             <= true;
							state            <= DISCARD_AND_REPLY;    
						end if;
						
						if Reject_key then
							Request          <= false;
							rmap_status_code <= invalid_key;
							s_ir             <= true;
							state            <= DISCARD_AND_REPLY;   
						end if;
						
						if Reject_target then
							Request          <= false;
							rmap_status_code <= invalid_target_address;
							s_ir             <= true;
							state            <= DISCARD_AND_REPLY;   
						end if;

					--	if Reject_target then
					--		Request          <= false;
					--		rmap_status_code <= invalid_target_address;
					--		s_ir             <= true;
					--		state            <= DISCARD_AND_REPLY;                                     
					--	elsif Reject_key then
					--		Request          <= false;
					--		rmap_status_code <= invalid_key;
					--		s_ir             <= true;
					--		state            <= DISCARD_AND_REPLY;                                     
					--	elsif Reject_request then
					--		Request          <= false;
					--		rmap_status_code <= command_not_possible;
					--		s_ir             <= true;
					--		state            <= DISCARD_AND_REPLY;                                   
					--	elsif Accept_request then
					--		Request          <= false;
					--		s_ir             <= true;
					--		state <= MWRITE; -- multi transer
					--		if io_bytes = 0 then 
					--			state <= MWRITE_2; -- last transfer
					--		end if;
					--	end if;

					when MWRITE   => -- Write byte
						wr_en 			 <= false;
						if s_or then
						
							s_ir <= false;
							state            	<= MWRITE_1;
							if(s_data /= SPW_EOP and s_data /= SPW_EEP) then
								wr_en 			 <= true;
								Write_data       <= s_data(7 downto 0);
								RW_request       <= true;
								io_bytes         <= io_bytes - 1;
							end if;
							
							if (s_data = SPW_EOP) then
								rmap_status_code <= unexpected_EOP;
								state            <= REPLY;
							end if;
							
							if (s_data = SPW_EEP) then
								rmap_status_code <= unexpected_EEP;
								state            <= REPLY;
							end if;
							
						end if;

					when MWRITE_1 => -- Wait for RW_acknowledge before moving on
						if RW_acknowledge then
							wr_en 		<= false;
							RW_request 	<= false;
							state      	<= MWRITE_1A; 
						end if;

					when MWRITE_1A=>  -- increment address, get next data
						if increment_address then
							io_address <= io_address + 1;
						end if;
						s_ir <= true;
						if io_bytes_null then
							state <= MWRITE_2; -- last transfer
						else 
							state <= MWRITE;  -- next transfer
						end if;

					when MWRITE_2 => -- Check EOP and CRC is good
						if s_or then
						
							state            <= MWRITE_3;	-- ALL OKAY ?
							if(s_data /= SPW_EOP and s_data /= SPW_EEP and not(S_CRC_OK)) then	-- bad CRC ?
								Checksum_fail    <= true;
								rmap_status_code <= invalid_data_CRC;
								state            <= discard_and_reply;
							end if;
							
							if(s_data = SPW_EOP) then		-- EOP ?
								s_ir             <= false;
								rmap_status_code <= unexpected_EOP;
								io_bytes         <= to_unsigned( 0, 24 );
								state            <= REPLY;
							end if;
							
							if(s_data = SPW_EEP) then	-- EEP ?
								s_ir             <= false;
								rmap_status_code <= unexpected_EEP;
								io_bytes         <= to_unsigned( 0, 24 );
								state            <= REPLY;
							end if;

						end if;

					when MWRITE_3 => -- check for complete packet or too much
						if s_or then
						
							if(s_data /= SPW_EOP and s_data /= SPW_EEP) then
								rmap_status_code <= too_much_data;
								OK               <= not verify;
								state            <= DISCARD_AND_REPLY;
							end if;
						
							if s_data = SPW_EOP then
								s_ir             <= false;
								rmap_status_code <= success;
								if Verify_overrun then
									rmap_status_code <= Verify_buffer_overrun;
								end if;
								OK               <= true;
								state            <= REPLY;
							end if;
							
							if s_data = SPW_EEP then
								s_ir             <= false;
								rmap_status_code <= unexpected_EEP;
								OK               <= not verify;
								state            <= REPLY;
							end if;
							
						end if;

					when RMAP_READ=> -- check for complete packet or too much
					
						if s_or then
							if(s_data /= SPW_EOP and s_data /= SPW_EEP) then
								rmap_status_code <= too_much_data;
								io_bytes         <= to_unsigned( 0, 24 );
								state            <= DISCARD_AND_REPLY;
							end if;
							
							if s_data = SPW_EOP then
								s_ir     		 <= false;
								Request  		 <= true;
								state    		 <= RMAP_RD;   
							end if;
							
							if s_data = SPW_EEP then
								s_ir             <= false;
								rmap_status_code <= unexpected_EEP;
								io_bytes         <= to_unsigned( 0, 24 );
								state            <= REPLY;
							end if;
						end if;

					when RMAP_RD   => -- Check for valid request and read data
						
						
						if Accept_request then
							Request          <= false;
							if Read_bytes < io_bytes then
								io_bytes <= Read_bytes;
							end if;
							state            <= REPLY;
						end if;
						
						if Reject_request then
							Request          <= false;
							rmap_status_code <= command_not_possible;
							io_bytes         <= to_unsigned( 0, 24 );
							state            <= REPLY;   
						end if;
						
						if Reject_key then
							Request          <= false;
							rmap_status_code <= invalid_key;
							io_bytes         <= to_unsigned( 0, 24 );
							state            <= REPLY;
						end if;
						
						if Reject_target then
							Request          <= false;
							rmap_status_code <= invalid_target_address;
							io_bytes         <= to_unsigned( 0, 24 );
							state            <= REPLY;     
						end if;
						
					--	if Reject_target then
					--		Request          <= false;
					--		rmap_status_code <= invalid_target_address;
					--		io_bytes         <= to_unsigned( 0, 24 );
					--		state            <= REPLY;                                  
					--	elsif Reject_key then
					--		Request          <= false;
					--		rmap_status_code <= invalid_key;
					--		io_bytes         <= to_unsigned( 0, 24 );
					--		state            <= REPLY;
					--	elsif Reject_request then
					--		Request          <= false;
					--		rmap_status_code <= command_not_possible;
					--		io_bytes         <= to_unsigned( 0, 24 );
					--		state            <= REPLY;                                    
					--	elsif Accept_request then
					--		Request          <= false;
					--		if Read_bytes < io_bytes then
					--			io_bytes <= Read_bytes;
					--		end if;
					--		state            <= REPLY;
					--	end if;

					when REPLY    => -- check if response required
						if reply_required then
							if Echo_required then
								y_data <= '0' & echo_path;
								y_crc  <= false;
								y_or   <= true;
								state  <= REPLY_E;
							else
								state  <= REPLY_R;
							end if;
						else
							Done  <= true;
							state <= IDLE;
						end if;
                        
					when REPLY_E  => -- Send Echo
						if y_ir then
							y_or  <= false;
							state <= REPLY_R;
						end if;
							 
					when REPLY_R  => -- Create response header
						if reply_prefix_bytes /= 0 then
							state  <= REPLY_PREFIX;
						else 
							state  <= REPLY_DESTINATION;
						end if;
                
					when REPLY_PREFIX =>  -- All replies
						y_data <= '0' & reply_prefix_data(0);
						y_crc  <= false;
						y_or   <= true;
						reply_prefix_N <= 1;
						state  <= REPLY_PREFIX_2;
                              
					when REPLY_PREFIX_2 =>
						if y_ir then
							if reply_prefix_N = reply_prefix_bytes then
								y_or  <= false;
								state <= REPLY_DESTINATION;
							else
								y_data <= '0' & reply_prefix_data(reply_prefix_N);
								reply_prefix_N <= reply_prefix_N + 1;
							end if;
						end if;
                                 
					when REPLY_DESTINATION =>
						y_data <= '0' & initiator_logical_address;  -- now the destination logical address
						y_crc  <= true;
						y_or   <= true;
						state  <= REPLY_PROTOCOL_ID;
                                 
					when REPLY_PROTOCOL_ID =>
						if y_ir then
							y_data <= '0' & std_logic_vector( to_unsigned(protocol_RMAP, 8) );
							state  <= REPLY_TYPE;
						end if;

					when REPLY_TYPE =>
						if y_ir then
							y_data <= '0' & "00" & instruction(5 downto 0);  -- Turn command into response
							state  <= REPLY_STATUS_CODE;
						end if;

					when REPLY_STATUS_CODE =>
						if y_ir then
							y_data <= '0' & std_logic_vector( to_unsigned(rmap_status_code, 8) );
							state  <= REPLY_SOURCE;
						end if;

					when REPLY_SOURCE => 
						if y_ir then
							y_data <= '0' & target_logical_address; -- Here: we were the target and are now the source
							state  <= REPLY_TRANSACTION_MSB;
						end if;

					when REPLY_TRANSACTION_MSB =>
						if y_ir then
							y_data <= '0' & Transaction_identifier(15 downto 8);
							state  <= REPLY_TRANSACTION_LSB;
						end if;

					when REPLY_TRANSACTION_LSB =>
						if y_ir then
							y_data <= '0' & Transaction_identifier( 7 downto 0);
							if read_command then
								state  <= REPLY_READ;
							else 
								state  <= REPLY_FINAL_CRC;
							end if;
						end if;

                
					when REPLY_READ => -- Read reply
						OK <= true;
						if y_ir then
							y_data <= '0' & X"00"; -- "reserved"
							state  <= REPLY_LENGTH_MSB;
						end if;

					when REPLY_LENGTH_MSB =>
						if y_ir then
							y_data <= '0' & std_logic_vector( io_bytes(23 downto 16) );  --length(23 downto 16);
							state  <= REPLY_LENGTH_SSB;
						end if;
					
					when REPLY_LENGTH_SSB =>
						if y_ir then
							y_data <= '0' & std_logic_vector( io_bytes(15 downto  8) );  --length(15 downto  8);
							state  <= REPLY_LENGTH_LSB;
						end if;

					when REPLY_LENGTH_LSB =>
						if y_ir then
							y_data <= '0' & std_logic_vector( io_bytes( 7 downto  0) );  --length( 7 downto  0);
							state  <= REPLY_HEADER_CRC;
						end if;

					when REPLY_HEADER_CRC =>
						if y_ir then
							y_data <= '0' & bitrev(TxCRC);
						--	if io_bytes = 0 then
							if io_bytes_null then 
								state <= REPLY_FINAL_CRC;
							else 
								state <= REPLY_DATA;
							end if;
						end if;
					
					when REPLY_DATA => -- get MEM read data
						if y_ir then
							y_or         <= false;
							RW_request   <= true;
							io_bytes     <= io_bytes - 1;
							state        <= REPLY_DATA_ACK;
						end if;
					
					when REPLY_DATA_ACK => -- wait for MEM data to be ready
						if RW_acknowledge then
							RW_request <= false;
							state      <= REPLY_DATA_ACKA;  -- so we don't change the address at the same time as de-asserting RW_request
						end if;
					
					when REPLY_DATA_ACKA => -- setup next MEM data transaction
						y_data <= '0' & Read_data;
						y_or   <= true;
						if increment_address then
							io_address <= io_address + 1;
						end if;
					--	if io_bytes = 0 then
						if io_bytes_null then
							state <= REPLY_FINAL_CRC;
						else 
							state <= REPLY_DATA;
						end if;
					
					when REPLY_FINAL_CRC =>  -- Send RMAP data CRC
						if y_ir then
							y_data <= '0' & bitrev(TxCRC);
							state  <= REPLY_EOP;
						end if;
					
					when REPLY_EOP => -- Send RMAP EOP
						if y_ir then
							y_data <= SPW_EOP;
							state  <= REPLY_EOP_DONE;
						end if;
					
					when REPLY_EOP_DONE => -- complete RMAP repsonse 
						if y_ir then
							y_or   <= false;
							Done   <= true;
							state  <= IDLE;
						end if;
					
				end case;
			end if;
		end if;
    end process;    


-------------------------------------------------------------------------------
-- Copy Y to SpW, calculate CRC
-------------------------------------------------------------------------------
    outcrc: block
		type states is ( IDLE, BYTE, CRC, SEND );
		signal state : states;-- := IDLE;
		signal I : integer range 0 to 7 := 0;
    begin
    
		process (clock)
		begin
			if rising_edge( clock ) then
				if reset then
					state       <= IDLE;
					Out_OR      <= false;
					y_ir        <= false;
					I           <= 0;
					TxCRC       <= (others => '0');
					to_spw_data <= (others => '0');
				else
					case state is
						when idle => 
							TxCRC <= (others => '0');
							y_ir  <= false;
							state <= BYTE;
			
						when BYTE => 
							if y_or then
								-- defer y_ir until thr CRC is done
								to_SpW_data <= y_data;
								I           <= 0;
								if y_crc then
									state       <= crc;
								else
									y_ir        <= true;
									Out_OR      <= true;
									state       <= SEND;
								end if;
							end if;
			
						when CRC  => 
							TxCRC <= TxCRC(6 downto 2)
									& (to_SpW_data(I) xor TxCRC(7) xor TxCRC(1))
									& (to_SpW_data(I) xor TxCRC(7) xor TxCRC(0))
									& (to_SpW_data(I) xor TxCRC(7)             );
							if I = 7 then
								y_ir        <= true;
								Out_OR      <= true;
								state       <= SEND;
							else
								I <= I + 1;
							end if;
			
						when send => 
							y_ir <= false;
							if Out_IR then
								Out_OR <= false;
	
								if to_SpW_data = SPW_EOP or to_SpW_data = SPW_EEP then
									state <= IDLE;
								else
									state <= BYTE;
								end if;	
							end if;
					end case;
				end if;
			end if;
		end process;   
		
    end block;

    Out_data  <= to_SpW_data;



  end RTL;
