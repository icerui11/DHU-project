----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- transmit the data from the fifo to the spacewire router interface and receive the data from the spacewire interface
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_fifo_spwctrl.vhd
-- @ Engineer				:	Rui
-- @ Date					: 	10.01.2024
-- @ version				:	2.0
-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	libero 12.0
-- @ Target Device			: 	m2s150t

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

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity router_fifo_spwctrl is
	generic(
		g_addr_width	: natural := 9;								 	-- address width of connecting RAM
        g_router_port_addr : integer range 1 to 32 :=1;                  -- router port addr, not include port 0, defined in package
		g_count_max 	: integer := 8   	                           -- count period between every ram address
	);
	port( 
		
		-- standard register control signals --
		clk_in	: in 	std_logic;		-- clk input, rising edge trigger
		rst_in	: in 	std_logic;		-- reset input, active high
        fifo_full   : in 	std_logic;		-- fifo full signal
		fifo_empty  : in 	std_logic;		-- enable input, asserted high. 
		fifo_r_update : out 	std_logic;	-- fifo read request signal.
        ccsds_ready_ext : out std_logic;	-- ccsds ready signal
        fifo_ack    : in 	std_logic;		-- fifo ack signal
        write_done  : out 	std_logic;		-- write done signal
        
		-- RAM signals
		ram_data_in		: in 	std_logic_vector(7 downto 0) ;	-- data read from RAM

		-- SpW Data Signals
		spw_Tx_data		: out   std_logic_vector(7 downto 0);		-- SpW Tx_data
		spw_Tx_Con		: out 	std_logic;					-- SpW character control bit
		spw_Tx_OR		: out 	std_logic;					-- SpW Tx_data Output Ready
		spw_Tx_IR		: in 	std_logic;					-- SpW Tx_data Input Ready	
		
		spw_Rx_data		: in   	std_logic_vector(7 downto 0);		-- SpW Rx_data
		spw_Rx_Con		: in 	std_logic						:= '0';					-- SpW character control bit
		spw_Rx_OR		: in 	std_logic						:= '0';					-- SpW Rx_data Output Ready
		spw_Rx_IR		: out 	std_logic						:= '1';					-- SpW Rx_data Input Ready	
		
		rx_cmd_out		: out 	std_logic_vector(2 downto 0)	:= (others => '0');		-- control char output bits
		rx_cmd_valid	: out 	std_logic;												-- asserted when valid command to output
		rx_cmd_ready	: in 	std_logic;												-- assert to receive rx command. 
		
		rx_data_out		: out 	std_logic_vector(7 downto 0)	:= (others => '0');		-- received spacewire data output
		rx_data_valid	: out 	std_logic := '0';										-- valid rx data on output
		rx_data_ready	: in 	std_logic := '1';										-- assert to receive rx data
		
		-- SpW Control Signals
		spw_Connected	: in 	std_logic	:= '0';										-- asserted when SpW Link is Connected
		spw_Rx_ESC_ESC	: in 	std_logic 	:= '0';    
		spw_ESC_EOP 	: in	std_logic 	:= '0';    
		spw_ESC_EEP     : in	std_logic 	:= '0';
		spw_Parity_error: in	std_logic 	:= '0';
		
		ccsds_datanewValid : out std_logic;	                                            -- enable ccsds data input
		error_out		   : out std_logic 	:= '0'									    -- assert when error
    );
end router_fifo_spwctrl;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_fifo_spwctrl is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_spw_eop	: 	std_logic_vector(7 downto 0) := x"02";
    constant c_port_addr:   std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(g_router_port_addr,8));
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_states is (ready, addr_send, read_mem, spw_tx, ramaddr_delay, eop_tx);	-- declare state machine states. 
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal s_state : t_states := ready;	                                    -- declare state machines, init safe. 
	signal s_addr_counter	: natural range 0 to (2**g_addr_width)-1 := 0;	-- counts RAM read address
	signal s_time_counter	: natural range 0 to g_count_max-1 := 0;		-- counts time between memory reads...
    signal r_update         : std_logic := '0';
	signal s_ram_reg		: std_logic_vector(7 downto 0) := (others => '0');	-- register for storing SpW Characters from RAM, or port address data
	signal rx_ready			: std_logic := '0';
    signal write_done_r     : std_logic := '0';
	signal convert_valid    : std_logic := '0';                --indicate convert logic data start convert


begin
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	rx_ready 		<= rx_cmd_ready or rx_data_ready;	-- rx output ready ?
	fifo_r_update   <= r_update;
    write_done      <= write_done_r;
    --ccsds ready_ext , when fifo full stop compression
    ccsds_ready_ext <= '0' when fifo_full = '1' else '1';    --fifo full, stop compression	

	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	control_tx_fsm: process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			spw_Tx_OR 		<= '0';
			if(rst_in = '1') then							-- Synchronous reset condition. 
				s_time_counter	<= 0;
				spw_Tx_Con 		<= '0';
				spw_Tx_data		<= (others => '0');
				spw_Tx_OR		<= '0';
				s_state 		<= ready;
			else
				case s_state is 

					when ready =>															-- ready state
					    write_done_r <= '0';	                                        --? if not, will continue to increase chunk
						if(fifo_empty = '0' and spw_Connected = '1') then				-- fifo data need to transfer and Spacewire Connected ?
							s_state 		<= addr_send;									-- go to read fifo 
                            r_update        <= '1';
                        else 
                            r_update        <= '0';
						end if;	                                                                                                                           

                    when addr_send =>														-- send port address to router
                            s_ram_reg <= c_port_addr;                                       -- first fetch port address
                            s_state <= spw_tx;												-- go to spw transmit state
                            
					when read_mem =>														-- read memory state					                                           
					    if fifo_ack = '1' then
                           r_update <= '0'; 
                           s_ram_reg <= ram_data_in;											-- read RAM data into buffer.                        	
						   write_done_r <= '1';                                                -- indicate fifo data successfully read by spwtx
						   s_state <= spw_tx;													-- got to spw transmit state
                        else
						   write_done_r <= '0';	
                           r_update <= '1';  
                        end if;                                                                                                                                                                                                                                                                 
                                                                                                                                                                             
					when spw_tx =>															-- spacewire transmit state						
					    write_done_r <= '0';
					    spw_Tx_data <= s_ram_reg;											-- output stored data
						if(spw_Tx_IR = '1') then											-- spw ready for data ?
							spw_Tx_OR <= '1';												-- assert Tx data output ready. 
						end if;							
						if(spw_Tx_IR = '1' and spw_Tx_OR = '1') then						-- IR/OR handshake valid on spw Tx data ?
							spw_Tx_OR 		<= '0';											-- de-assert Tx data output ready
							s_state			<= ramaddr_delay;									-- go to ramaddr delay state
						end if;	
	                                                                                		                                                                                                                                                                     
					when ramaddr_delay =>														-- ramaddr delay state						
						s_time_counter <= (s_time_counter + 1) mod g_count_max;				-- increment time counter... transmit 8 bit data
						if(s_time_counter = g_count_max-1) then								-- time counter max ?
       --                   write_done_r <= '1';	
                          s_state <= read_mem;											-- go to read_mem state.                       
                        end if;					
						if fifo_empty = '1' then	                               -- address counter rolled over and max count reached ?	
							s_ram_reg 	<= c_spw_eop;                                       -- load EOP character x02 into buffer
							s_state 	<= eop_tx;											-- go to transmit EOP state.
						end if;
					
					when eop_tx =>															-- transmit EOP state. 				
						spw_Tx_Con		<= '1';
						spw_Tx_data 	<= s_ram_reg;
						
						if(spw_Tx_IR = '1') then											-- spw ready for data ?
							spw_Tx_OR <= '1';												-- assert Tx data output ready. 
						end if;					
				
						if(spw_Tx_IR = '1' and spw_Tx_OR = '1') then						-- IR/OR handshake valid on spw Tx data ?
							spw_Tx_OR 		<= '0';											-- de-assert Tx data output ready
							spw_Tx_Con		<= '0';
							s_state			<= ready;										-- go to ready state
						end if;
						
					when others =>															-- others state, for safe FSM operation. 
						s_state <= ready;													-- default ready state...
				end case;	
			end if;
		end if;
	end process;
	
	-- interface for receiving Rx Data. AXI Handshake style 
	control_rx: process(clk_in)	
	begin
		if(rising_edge(clk_in)) then							-- Synchronous to rising edge
		    error_out <= (spw_Rx_ESC_ESC or spw_ESC_EOP  or spw_ESC_EEP or spw_Parity_error);
			spw_Rx_IR <= '0';									-- default spw_Rx_IR low
			if(rst_in = '1') then								-- if synchronous reset asserted ?
				rx_data_valid 	<= '0';							-- de-assert rx_data valid
				rx_cmd_valid 	<= '0';							-- de-assert rx_cmd valid
			else												-- reset de-asserted ?
			
				if(rx_data_ready = '1') then					-- rx data output logic ready ?
					rx_data_valid <= '0';						-- de-assert rx data valid
				end if;
				
				if(rx_cmd_ready = '1') then						-- rx cmd output logic ready ?	
					rx_cmd_valid <= '0';						-- de-assert rx cmd valid
				end if;
				
				if(spw_Rx_OR = '1' and rx_ready = '1') then		-- new data from spacewire codec and rx receive logic is ready?
					spw_Rx_IR <= '1';							-- assert spacewire Rx IR register
				end if;

				-- earlier rx_data_valid/rx_cmd_valid assignments are overwritten if valid data/cmd detected 
				if(spw_Rx_OR = '1' and spw_Rx_IR = '1') then	-- spacewire codec OR/IR handshake valid ?
					spw_Rx_IR <= '0';							-- de-assert spacewire Rx Input Ready signal
					rx_data_out 	<= spw_Rx_data(7 downto 0);	-- output potential data bits
					rx_cmd_out 		<= spw_Rx_data(2 downto 0);	-- output potential character bits 
					rx_cmd_valid 	<= spw_Rx_Con;				-- assert cmd valid if command received
					rx_data_valid   <= not spw_Rx_Con;			-- assert data valid if data received
					if spw_Rx_Con = '0' then
					   convert_valid <= '1';
					end if;
				end if;									
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
end rtl;