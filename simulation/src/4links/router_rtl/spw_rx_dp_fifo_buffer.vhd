----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	dp_fifo_buffer
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	2

-- File Description         :

-- Document Number			:  xxx-xxxx-xxx
----------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------
-- Library Declarations  --
----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------------------------------------------------------
-- Package Declarations --
----------------------------------------------------------------------------------------------------------------------------------
context work.router_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_rx_dp_fifo_buffer is
	generic(
		g_rd_mult 		: natural  		:= c_fabric_bus_width;
		g_fifo_depth 	: natural 		:= 4;
		g_ram_style		: string 		:= "auto"
	);
	port(
		wr_clk 		: in	std_logic 						:= '0';		-- SpW Rx Clock (400 MHz)
		rd_clk 		: in	std_logic 						:= '0';		-- Router Clock (200 MHz)
		wr_rst_in 	: in	std_logic 						:= '0';		-- Synchronous reset (hold for both domains)
		rd_rst_in 	: in	std_logic 						:= '0';		-- Synchronous reset (hold for both domains)
		
		-- SpaceWire Codec Interface (Connect to SpW RX Data)
		spw_wr_data 	: in	t_nonet 				:= (others => '0');	
		spw_wr_valid	: in	std_logic 				:= '0';
		spw_wr_ready	: out	std_logic 				:= '0';
		
		-- Router Data Interface (Connect to Rx Controller)
		FIFO_rd_m		: out 	r_fabric_data_bus_m 	:= c_fabric_data_bus_m;
		FIFO_rd_s		: in	r_fabric_data_bus_s 	:= c_fabric_data_bus_s
	
	);

end entity spw_rx_dp_fifo_buffer;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_rx_dp_fifo_buffer is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant d_width : natural := (t_nonet'length*g_rd_mult)+g_rd_mult;
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_state is (get_data, send_data);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal state 		: 	t_state := get_data;
	signal count_reg	: 	std_logic_vector(0 to g_rd_mult-1) := (others => '0');
	signal pointer		: 	integer range 0 to g_rd_mult-1 := 0;
	signal last_wr_data		: 	t_nonet 	:= (others => '0');
	signal rd_data		: 	t_nonet 	:= (others => '0');
	signal rd_valid		: 	std_logic 	:= '0';
	signal rd_ready		: 	std_logic 	:= '0';
	
	signal fifo_full 	: 	std_logic 	:= '0';
	signal fifo_empty 	: 	std_logic 	:= '0';
--	signal fifo_has_eop : 	std_logic_vector(0 to g_rd_mult-1) := (others => '0');
	signal fifo_has_eop	: 	std_logic := '0';
	
	signal FIFO_wr_valid: 	std_logic := '0';
	signal FIFO_wr_ready: 	std_logic := '0';
	signal fifo_wr_data : 	std_logic_vector(0 to d_width-1) := (others => '0');
	signal fifo_rd_data : 	std_logic_vector(0 to d_width-1) := (others => '0');
	
	signal wr_data_reg 	:	t_fabric_data_bus := (others => (others => '0'));
	signal wr_count_reg	: 	std_logic_vector(0 to g_rd_mult-1) := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	dp_fifo_inst:entity work.dp_fifo_buffer(rtl)
	generic map(
		g_data_width	=> d_width,
		g_addr_width	=> g_fifo_depth,
		g_ram_style		=> g_ram_style
	)
	port map( 
		
		-- standard register control signals --
		wr_clk_in		=> 	wr_clk,				-- write clk input, rising edge trigger
		rd_clk_in		=> 	rd_clk,				-- read clk input, rising edge trigger
		wr_rst_in		=> 	wr_rst_in,				-- reset input, active high hold for several clock cycles of both wr and rd
		rd_rst_in		=> 	rd_rst_in,				-- reset input, active high hold for several clock cycles of both wr and rd
		
		-- FiFO buffer Wr/Rd Interface --
		FIFO_wr_data	=> 	fifo_wr_data,
		FIFO_wr_valid	=>	FIFO_wr_valid,
		FIFO_wr_ready	=>	FIFO_wr_ready,
		
		FIFO_rd_data	=>	fifo_rd_data,
		FIFO_rd_valid	=>	FIFO_rd_m.tvalid,
		FIFO_rd_ready	=>	FIFO_rd_s.tready,

		full			=> 	fifo_full, 			-- asserted when Fifo is Full (Write Clock Domain)
		empty			=> 	fifo_empty			-- asserted when Fifo is Empty (Read Clock Domain)
		
    );

	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	bus_gen: for i in 0 to g_rd_mult-1 generate
		FIFO_rd_m.tdata(i) <= fifo_rd_data((i*t_nonet'length) to ((i+1)*t_nonet'length)-1);
		FIFO_rd_m.tcount((g_rd_mult-1)-i) <= fifo_rd_data((d_width-1)-i);
		
		fifo_wr_data((i*t_nonet'length) to ((i+1)*t_nonet'length)-1) <= wr_data_reg(i);
		fifo_wr_data((d_width-1)-i) <= wr_count_reg((g_rd_mult-1)-i);
		
	end generate bus_gen;
	
	-- highest element contains EOP/EEP ?
	fifo_has_eop <= to_std((last_wr_data = SPW_EEP) or (last_wr_data = SPW_EOP));
	wr_count_reg <= count_reg;	-- load count register 
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	read_proc: process(wr_clk)
	begin
		if(rising_edge(wr_clk)) then
			if(wr_rst_in = '1') then
				last_wr_data 	<= (others => '0');
				count_reg 		<= (others => '0');
				FIFO_wr_valid 	<= '0';
				pointer 		<= 0;
				state 			<= get_data;
			else
				case state is 
				
					when get_data =>	-- get data from FiFo
						spw_wr_ready <= '1';
						
						if(spw_wr_ready = '1' and spw_wr_valid = '1') then	-- read in data on handshake 
							spw_wr_ready <= '0';
							last_wr_data			 	<= spw_wr_data;
							wr_data_reg(pointer) 		<= spw_wr_data;	-- read in data to lowest element
							for i in 0 to g_rd_mult-1 loop
								if(i = 0) then
									count_reg(0) <= '1';				-- shift in  '1' to count register 
								else
									count_reg(i) <= count_reg(i-1);
								end if;
							end loop;
							pointer <= pointer + 1 mod g_rd_mult;
						end if;
						
						if((count_reg(g_rd_mult-1) = '1') or (fifo_has_eop = '1')) then	-- full or EOP/EEP detected ?
							spw_wr_ready 	<= '0';
							state	 		<= send_data;
						end if;
					
					when send_data =>	-- send data from FiFo interface
						-- data register is pre-loaded in last state 
						FIFO_wr_valid 	<= '1';		-- assert valid 
						last_wr_data 	<= (others => '0');
						pointer 		<= 0;
						
						if(FIFO_wr_valid = '1' and FIFO_wr_ready = '1') then	-- handshake ?	
							FIFO_wr_valid 	<= '0';								-- de-assert valid 
							count_reg 		<= (others => '0');
							wr_data_reg		<= (others => (others => '0'));
							state 			<= get_data;										-- get data state 
						end if;

				end case;
			
			end if;
		end if;
	end process;
	
	

end rtl;