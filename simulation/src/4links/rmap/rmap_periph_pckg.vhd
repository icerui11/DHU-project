----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	rmap_periph_pckg.vhd
-- @ Engineer				: 	James E Logan
-- @ Role					:	FPGA & Electronics Engineer
-- @ Company				:	4Links 

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE/Intel Quartus 18.1+
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	Standard work library containing useful functions, data types, constants and simulation
--								constructs for RTL & Testbenching. 

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should coimpile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library spw;
use spw.spw_data_types.all;
use spw.spw_codes.all;
use spw.SpaceWire_Sim_lib.all;

package rmap_periph_pckg is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------

	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------

	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------

	
	--------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Records	Declerations --
	--------------------------------------------------------------------------------------------------------------------------

	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	procedure uart_tx_proc(
		signal 	 tx				: inout std_logic;
		variable data_bits		: std_logic_vector;
		variable baud			: integer;
		variable parity			: natural;
		variable stop_bits		: natural
	);
	
	procedure uart_tx_proc_s(
		signal 	 	tx				: inout std_logic;
		signal 		data_bits		: std_logic_vector;
		signal 		baud			: integer;
		signal 		parity			: natural;
		signal 		stop_bits		: natural
	);
	
	procedure uart_tx_proc_c(
		signal 	 	tx				: inout std_logic;
		constant 		data_bits		: std_logic_vector;
		constant 		baud			: integer;
		constant 		parity			: natural;
		constant 		stop_bits		: natural
	);
	
	procedure uart_rx_proc(
		signal 	 rx				: in 	std_logic;
		variable data_bits		: out 	std_logic_vector;
		signal   IQR			: inout std_logic;
		variable baud			: integer;
		variable parity			: natural;
		variable stop_bits		: natural
	);
	
end package rmap_periph_pckg;

package body rmap_periph_pckg is 
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------



	
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- procedure for writing uart data
	procedure uart_tx_proc(											-- procedure to send UART Tx data
		signal 	 tx				: inout std_logic;
		variable data_bits		: std_logic_vector;
		variable baud			: integer;
		variable parity			: natural;
		variable stop_bits		: natural
	) is
		variable bit_counter	: natural := 0;
		variable start_bits		: natural := 1;
		variable v_baud         : real;
		variable uart_clk		: time;
	begin
        v_baud  := 1_000_000_000.0/(1.0 * baud);  
		uart_clk 	:= (v_baud * ns);							-- get uart clock period from baud (nano seconds)
		tx <= '1';												-- TX idles high
		wait for uart_clk;										-- idle high for 1 uart clock period
		
		for i in 0 to start_bits-1 loop							-- start bits loop
			tx <= '0';											-- assert Tx low for start condition
			wait for (uart_clk);								-- wait for uart clk
		end loop;
		
		for i in (data_bits'length)-1 downto 0 loop					-- data bits loop
			tx <= data_bits(i);						-- set TX bitMSB first
		--	bit_counter := bit_counter + 1;						-- set next Tx bit
			wait for uart_clk;									-- wait for clk period
		end loop;
		
		if (parity > 0) then									-- valid parity set ?
			for i in 0 to parity-1 loop							-- set parity 
				tx <= '0';										-- assert Tx low for parity
				wait for uart_clk;								-- wait for clk period
			end loop;
		end if;
		
		for i in 0 to stop_bits-1 loop							-- set stop bits
			tx <= '1';											-- assert TX high on stop bits
			wait for uart_clk;									-- wait for clk period
		end loop;
	
	
	end uart_tx_proc;
	
	-- procedure for writing uart data
	procedure uart_tx_proc_s(											-- procedure to send UART Tx data
		signal 	 tx				: inout std_logic;
		signal data_bits		: std_logic_vector;
		signal baud				: integer;
		signal parity			: natural;
		signal stop_bits		: natural
	) is
		variable bit_counter	: natural := 0;
		variable start_bits		: natural := 1;
		variable v_baud         : real;
		variable uart_clk		: time;
	begin
        v_baud  := 1_000_000_000.0/(1.0 * baud); 
		uart_clk 	:= (v_baud * ns);							-- get uart clock period from baud (nano seconds)
		tx <= '1';												-- TX idles high
		wait for uart_clk;										-- idle high for 1 uart clock period
		
		for i in 0 to start_bits-1 loop							-- start bits loop
			tx <= '0';											-- assert Tx low for start condition
			wait for (uart_clk);								-- wait for uart clk
		end loop;
		
		for i in (data_bits'length)-1 downto 0 loop					-- data bits loop
			tx <= data_bits(i);						-- set TX bitMSB first
		--	bit_counter := bit_counter + 1;						-- set next Tx bit
			wait for uart_clk;									-- wait for clk period
		end loop;
		
		if (parity > 0) then									-- valid parity set ?
			for i in 0 to parity-1 loop							-- set parity 
				tx <= '0';										-- assert Tx low for parity
				wait for uart_clk;								-- wait for clk period
			end loop;
		end if;
		
		for i in 0 to stop_bits-1 loop							-- set stop bits
			tx <= '1';											-- assert TX high on stop bits
			wait for uart_clk;									-- wait for clk period
		end loop;
	
	
	end uart_tx_proc_s;
	
	procedure uart_tx_proc_c(											-- procedure to send UART Tx data
		signal 	 tx				: inout std_logic;
		constant data_bits		: std_logic_vector;
		constant baud			: integer;
		constant parity			: natural;
		constant stop_bits		: natural
	) is
		variable bit_counter	: natural := 0;
		variable start_bits		: natural := 1;
		variable v_baud         : real;
		variable uart_clk		: time;
	begin
        v_baud  := 1_000_000_000.0/(1.0 * baud); 
		uart_clk 	:= (v_baud * ns);							-- get uart clock period from baud (nano seconds)
		tx <= '1';												-- TX idles high
		wait for uart_clk;										-- idle high for 1 uart clock period
		
		for i in 0 to start_bits-1 loop							-- start bits loop
			tx <= '0';											-- assert Tx low for start condition
			wait for (uart_clk);								-- wait for uart clk
		end loop;
		
		for i in (data_bits'length)-1 downto 0 loop					-- data bits loop
			tx <= data_bits(i);						-- set TX bitMSB first
		--	bit_counter := bit_counter + 1;						-- set next Tx bit
			wait for uart_clk;									-- wait for clk period
		end loop;
		
		if (parity > 0) then									-- valid parity set ?
			for i in 0 to parity-1 loop							-- set parity 
				tx <= '0';										-- assert Tx low for parity
				wait for uart_clk;								-- wait for clk period
			end loop;
		end if;
		
		for i in 0 to stop_bits-1 loop							-- set stop bits
			tx <= '1';											-- assert TX high on stop bits
			wait for uart_clk;									-- wait for clk period
		end loop;
	
	
	end uart_tx_proc_c;
	
	-- procedure for reading UART data
	procedure uart_rx_proc(
		signal 	 rx				: in 	std_logic;
		variable data_bits		: out 	std_logic_vector;
		signal   IQR			: inout std_logic;
		variable baud			: integer;
		variable parity			: natural;
		variable stop_bits		: natural
	) is
		variable uart_old		: std_logic := '1';
		variable bit_counter	: natural := 0;
		variable start_bits		: natural := 1;
		variable uart_clk		: time;
		variable v_baud         : real;
		variable rx_bits 		: std_logic_vector(data_bits'length-1 downto 0) := (others => '0');
	begin
		v_baud  := 1_000_000_000.0/(1.0 * baud);  
		uart_clk 	:= (v_baud * ns);		-- get uart_clk (ns)
		
		RX_loop:loop												-- loop, looking for start condition
			uart_old := rx;											-- store previous value of RX line
			wait for uart_clk/2;									-- wait for clock period
			IQR <= '0';
			exit RX_loop when (uart_old = '1' and rx = '0');		-- exit when start bit detected.
		end loop;
		
		for i in 0 to data_bits'length-1 loop	-- get data bits...
			wait for uart_clk;
			rx_bits(bit_counter) := rx;			-- load data bits (MSB first)
			bit_counter := bit_counter + 1;		-- decrement data bits counter
		end loop;
		
		if(parity > 0) then						-- valid parity bits set ? 
			for i in 0 to parity-1 loop			-- loop through parity periods
				wait for uart_clk;
			end loop;
		end if;
		
		for i in 0 to stop_bits-1 loop
			stop_loop: loop
				wait for uart_clk/2;
				exit stop_loop when rx = '1';
			end loop;
		end loop;
		
		data_bits := rx_bits;					-- output Received data
		IQR <= '1';
		
	end uart_rx_proc;
	
	

end package body rmap_periph_pckg;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------