--------------------------------------------------------------------------------
-- Company: IDA
--
-- File: router_ahb_reg.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: This register module is derived from router_config_memory and has been extended
--              with an AHB slave interface.
--              AXI bus x"06"
--
-- <Description here>
--
-- Targeted device: <Family::SmartFusion2> <Die::M2S150TS> <Package::1152 FC>
-- Author: Rui Yin
--
--------------------------------------------------------------------------------
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
context work.router_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity router_ahb_reg is
	generic(
        --AHB parameters
        hindex          : integer := 0;		-- AHB slave index
        haddr   : integer := 0;             --!Slave address
        hmask   : integer := 16#fff#;       --!Slave mask   
        -- register parameters        
		g_addr_width 	: natural range 4 to 16 	:= 5;		-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		: t_byte 					:= x"06"	-- axi Bus address for this module configure in router_pckg.vhd
	);
	port( 
		-- standard register control signals --
		in_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		out_clk			: in 	std_logic 			:= '0';		-- clk input, rising edge trigger
		in_rst			: in 	std_logic 			:= '0';		-- reset input, active high
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			: in 	r_maxi_lite_dword	:= c_maxi_lite_dword;
		axi_out			: out 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		
		config_mem_out	: out 	t_byte_array(0 to 31) := (others => (others => '0'));

		-- AHB signals
		clk_ahb         : in    std_logic;
		rst_ahb         : in    std_logic;
		ahbsi   : in  ahb_slv_in_type;        --! AHB slave input signals
		ahbso   : out ahb_slv_out_type;       --! AHB slave output signals
    );
end router_ahb_reg;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------
/*
	contains read/write registers 	0  to 31 == Port Control Registers, 
									32 to 35 == System Config Registers
*/

architecture rtl of router_ahb_reg is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal config_mem 	: t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	signal axi_addr 	: natural range 0 to (2**g_addr_width)-1 	:= 0;								-- address is for both read & write 
	signal rd_data		: t_byte 									:= (others => '0');
	signal wr_data		: t_byte 									:= (others => '0');
	signal wr_en 		: std_logic 								:= '0';
	signal is_valid		: std_logic									:= '0';
	
	signal sync_reg_2		:  	t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	signal sync_reg_1		: 	t_byte_array(0 to (2**g_addr_width)-1) 	:= (others => (others => '0'));	-- create config memory 
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
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
--	config_mem_out <= config_mem(0 to c_num_config_reg-1);		-- register outputs...
--	axi_out.rdata   <= config_mem(axi_addr);			-- read back byte at axi address byte 
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-- handles AXI handshake and registers IO with config port 
	-- router clock domain 
	axi_proc: process(in_clk)
	begin
		if(rising_edge(in_clk)) then
			if(in_rst = '1') then
				axi_out.tready 	<= '0';									-- force de-assert ready..
				is_valid 		<= '0';			
			--	config_mem 		<= (others => (others => '0'));
			else
				axi_out.tready <= '0';
				is_valid <= '0';
				wr_data 		<= axi_in.wdata;					-- load write data to register
				axi_out.rdata   <= config_mem(axi_addr);			-- read back byte at axi address byte 	
				axi_addr 		<= to_integer(unsigned(axi_in.taddr(g_addr_width-1 downto 0)));	-- get requested address
				
				if(axi_in.tvalid = '1' and axi_in.taddr(23 downto 16) = g_axi_addr) then				-- handshake request and valid address for this module ?
					is_valid 		<= '1';															-- valid high ? (used for register preload)
					wr_en 			<= axi_in.w_en;						    						-- load write status 				
				end if;
				
				if(is_valid = '1' and axi_in.tvalid = '1') then				-- bus target valid ?
					axi_out.tready 	<= '1';									-- assert handshake ready 
				end if;			

				if(axi_out.tready = '1' and axi_in.tvalid = '1') then		-- axi handshake asserted ?
					axi_out.tready 	<= '0';									-- force de-assert ready..
					is_valid 		<= '0';									-- de-assert pre-load 
				end if;
				
				if(wr_en = '1')then											-- write enable asserted ?
					config_mem(axi_addr) <= wr_data;						-- write config byte to element
				end if;
			end if;
		end if;
	end process;
	
	-- dual register outputs in spacewire clock domain 
	out_proc: process(out_clk)
	begin
		if(rising_edge(out_clk)) then
			sync_reg_1 <= config_mem;
			config_mem_out <= sync_reg_1;
		end if;
	end process;


end rtl;