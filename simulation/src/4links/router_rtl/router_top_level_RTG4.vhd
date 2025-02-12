----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_top_level_RTG4.vhd
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
-- use work.ip4l_data_types.all;
context work.router_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity router_top_level_RTG4 is
    generic(
		g_clock_freq	: real 					:= c_spw_clk_freq;		-- these are located in router_pckg.vhd
        g_num_ports 	: natural range 1 to 32 := c_num_ports;         -- these are located in router_pckg.vhd
		g_mode			: string				:= c_port_mode;         -- these are located in router_pckg.vhd
		g_is_fifo		: t_dword 				:= c_fifo_ports;        -- these are located in router_pckg.vhd
		g_priority		: string 				:= c_priority;          -- these are located in router_pckg.vhd
		g_ram_style 	: string				:= c_ram_style			-- style of RAM to use (Block, Auto, URAM etc), 
    );
	port( 
	
		-- standard register control signals --
		router_clk		: in 	std_logic := '0';		-- router clock input 
		rst_in			: in 	std_logic := '0';		-- reset input, active high
	
		DDR_din_r		: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "custom" io mode 
		DDR_din_f   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
		DDR_sin_r   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
		DDR_sin_f   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
		SDR_Dout		: out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
		SDR_Sout		: out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 

		Din_p  			: in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "single" and "diff" io modes
		Din_n           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sin_p           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sin_n           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Dout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Dout_n          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sout_n          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		
		-- SpaceWire FIFO IO (SpW Port Clock Domain)
		spw_fifo_in		: in 	r_fifo_master_array(1 to g_num_ports-1) := (others => c_fifo_master);
		spw_fifo_out	: out 	r_fifo_slave_array(1 to g_num_ports-1)	:= (others => c_fifo_slave);
		
		Port_Connected	: out 	std_logic_vector(31 downto 1) := (others => '0')	-- High when "connected" May want to map these to LEDs


    );
end router_top_level_RTG4;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_top_level_RTG4 is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_ports_slice : integer := c_num_ports-1; -- for modelsim....
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
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
	signal  rst_in_sync         	:   std_logic := '0';
	signal  router_rst				: 	std_logic := '0';
	signal	address_tar_out			:  	t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));
	signal	address_req_out			:  	t_ports_array(0 to g_num_ports-1) := (others => (others => '0'));
	signal	address_req_valid		:  	std_logic := '0';
	signal	address_req_ready		: 	std_logic := '0';
	
	-- rx port controller signals
	signal	rx_spw_rx_data			: 	t_nonet_array(0 to g_num_ports-1)			:= (others => (others =>'0'));		-- SpW Data Nonet (9 bits)
	signal	rx_spw_rx_data_valid   	: 	t_ports 									:= (others => '0');            		-- SpW IR
	signal	rx_spw_rx_data_ready   	: 	t_ports 									:= (others => '0');             	-- SpW OR
	signal	rx_addr_byte_out		: 	r_maxi_lite_byte_array(0 to g_num_ports-1)	:= (others => c_maxi_lite_byte);	-- data, valid
	signal	rx_addr_byte_in			: 	r_saxi_lite_byte_array(0 to g_num_ports-1) 	:= (others => c_saxi_lite_byte);	-- ready
	signal	rx_frame_active 		: 	t_ports  									:= (others => '0'); 				-- asserted when active transaction, de-asserting releases Target on XBar fabric  

	-- tx port controller signals
	signal	tx_spw_tx_data			: 	t_nonet_array(0 to g_num_ports-1) 			:= (others => (others =>'0'));		-- SpW Data Nonet (9 bits)
	signal	tx_spw_tx_data_valid   	: 	t_ports 									:= (others => '0');              	-- SpW IR
	signal	tx_spw_tx_data_ready   	: 	t_ports 									:= (others => '0');              	-- SpW OR

	-- xbar fabric data connections 
	signal	addr_byte_in			: 	t_byte_array(0 to g_num_ports-1) 	:= (others => (others => '0'));
	signal	addr_byte_valid			: 	t_ports 							:= (others => '0');				-- req in 
	signal	addr_byte_ready			: 	t_ports 							:= (others => '0'); 			-- grant out 
	signal	req_active				: 	t_ports 							:= (others => '0');
	signal 	req_reject				: 	t_ports 							:= (others => '0');

	-- master has valid and data, slave has ready 
	signal tc_rx_master				: 	r_maxi_lite_byte_array(1 to g_num_ports-1) := (others => c_maxi_lite_byte);
	signal tc_rx_slave				: 	r_saxi_lite_byte_array(1 to g_num_ports-1) := (others => c_saxi_lite_byte);
	signal tc_tx_master				: 	r_maxi_lite_byte_array(1 to g_num_ports-1) := (others => c_maxi_lite_byte);
	signal tc_tx_slave				: 	r_saxi_lite_byte_array(1 to g_num_ports-1) := (others => c_saxi_lite_byte);
	
	signal	axi_bus_master 			: 	r_maxi_lite_dword	:= c_maxi_lite_dword;
	signal	axi_bus_slave_0			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	signal	axi_bus_slave_1			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	signal	axi_bus_slave_2			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	signal	axi_bus_slave_3			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	signal	axi_bus_slave_4			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	signal	axi_bus_slave_5			: 	r_saxi_lite_dword	:= c_saxi_lite_dword;
	
	signal 	bad_addr				: 	t_ports 			:= (others => '0');
	
	signal  spw_status_memory		: 	t_byte_array(0 to 31) := (others => (others => '0'));	-- spacewire port status memory
	signal 	spw_config_memory		: 	t_byte_array(0 to 31) := (others => (others => '0')); 	-- spacewire port configuration memory
	
	-- init timecode master constant in timecode misc registers 
	signal	misc_config_registers	: 	t_byte_array(0 to 31) := (
		0 => c_tc_master_mask(7 downto 0),
		1 => c_tc_master_mask(15 downto 8),
		2 => c_tc_master_mask(23 downto 16), 
		3 => c_tc_master_mask(31 downto 24), 
		others => (others => '0')
	);
	
	signal  misc_status_registers	: 	t_byte_array(0 to 31) := (others => (others => '0'));
	
	signal  tc_master_mask			:  	t_dword := (others => '0');								-- set time-code master port (one-hot encoding)
	
	signal connected               	: 	t_ports := (others => '0');
	
	signal 	Tx_PSC_reg 				: t_byte_array(0 to 31) := (others => (others => '0'));	
	signal	Tx_PSC_valid 			: std_logic_vector(1 to g_num_ports-1) := (others => '0');
	signal  Tx_PSC_ready			: std_logic_vector(1 to g_num_ports-1) := (others => '0');	

	signal 	spw_rx_fifo_m			: 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
	signal 	spw_rx_fifo_s			: 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
	
	signal	req_fabric_bus_m		: 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
	signal	req_fabric_bus_s		: 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
	
	signal 	tar_fabric_bus_m		: 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
	signal	tar_fabric_bus_s		: 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
	
	signal  spw_tx_fifo_m			: 	r_fabric_data_bus_m_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_m);
	signal  spw_tx_fifo_s			: 	r_fabric_data_bus_s_array(0 to g_num_ports-1) := (others => c_fabric_data_bus_s);
	
	
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

	
	-- stores SpW Port Status Information
	spw_status_mem_inst: entity work.router_status_memory(rtl)
	generic map(
		g_addr_width 	=> 	5,	-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		=>	c_status_reg_addr			
	)
	port map( 
		
		-- standard register control signals --
		in_clk			=>	router_clk,
		out_clk	        =>	router_clk,
		out_rst	        =>	router_rst,

		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			=> 	axi_bus_master,
		axi_out			=> 	axi_bus_slave_2,
		
		status_reg_in	=> 	spw_status_memory(0 to 31)
    );
	
	-- Stores Generic router status such as TimeCode register and master Mask 
	misc_status_mem_inst: entity work.router_status_memory(rtl)
	generic map(
		g_addr_width 	=> 	5,	-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		=>	c_misc_status_reg_addr			
	)
	port map( 
		
		-- standard register control signals --
		in_clk			=>	router_clk,
		out_clk	        =>	router_clk,
		out_rst	        =>	router_rst,
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			=> 	axi_bus_master,
		axi_out			=> 	axi_bus_slave_3,
		
		status_reg_in	=> 	misc_status_registers(0 to 31)
    );
	
	spw_config_mem_inst:entity work.router_config_memory(rtl)
	generic map(
		g_addr_width 	=> 	5,					-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		=> 	c_spw_config_reg_addr	-- axi Bus address for this module configure in router_pckg.vhd
	)
	port map( 
		-- standard register control signals --
		in_clk			=> router_clk,
		out_clk			=> router_clk,
		in_rst			=> router_rst,
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			=> 	axi_bus_master,
		axi_out			=>	axi_bus_slave_1,
		
		config_mem_out	=> 	spw_config_memory(0 to 31)
    );
	
	misc_config_mem_inst:entity work.router_config_memory(rtl)
	generic map(
		g_addr_width 	=> 	5,					-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		=> 	c_misc_config_reg_addr	-- axi Bus address for this module configure in router_pckg.vhd
	)
	port map( 
		-- standard register control signals --
		in_clk			=> router_clk,
		out_clk			=> router_clk,
		in_rst			=> router_rst,
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			=> 	axi_bus_master,
		axi_out			=>	axi_bus_slave_4,
		
		config_mem_out	=> 	misc_config_registers(0 to 31)
    );
	
	-- Stores Generic router status such as TimeCode register and master Mask 
	spw_speed_config_mem: entity work.router_config_memory(rtl)
	generic map(
		g_addr_width 	=> 	5,	-- limit 32-bit AXI address to these bits, default 6 == 64 memory elements
		g_axi_addr		=>	c_spw_speed_config_mem			
	)
	port map( 
		
		-- standard register control signals --
		in_clk			=> router_clk,
		out_clk			=> router_clk,
		in_rst			=> router_rst,
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_in 			=> 	axi_bus_master,
		axi_out			=> 	axi_bus_slave_5,
		
		config_mem_out	=> 	Tx_PSC_reg
    );
	
	
	-- connect TC master mask bytes from configuration registers
	tc_master_mask(7 downto 0) 		<= misc_config_registers(0);
	tc_master_mask(15 downto 8) 	<= misc_config_registers(1);
	tc_master_mask(23 downto 16) 	<= misc_config_registers(2);
	tc_master_mask(31 downto 24) 	<= misc_config_registers(3);
	
	-- time code logic and controller, will broadcast new timecodes when required
	tc_logic_inst: entity work.router_timecode_logic(rtl)
	generic map(
		g_num_ports  	=> g_num_ports
	)
	port map(
		clk_in			=> 	router_clk,
		rst_in			=>	rst_in_sync,
		
		connected		=> 	connected,
	
		tc_master_mask	=> 	tc_master_mask,
		
		tc_rx_in		=> 	tc_rx_master(1 to g_num_ports-1),
		tc_rx_out		=> 	tc_rx_slave(1 to g_num_ports-1),
		
		tc_tx_in		=> 	tc_tx_slave(1 to g_num_ports-1),	
		tc_tx_out		=> 	tc_tx_master(1 to g_num_ports-1),
		
		tc_reg_out		=> 	misc_status_registers(c_tc_address)
	
	);	
	
	
	priority_gen: if(g_priority = "fifo" or g_priority = "FiFo") generate 
		rt_arbiter_inst:entity work.router_rt_arbiter_fifo_priority(rtl)
		generic map(
			g_num_ports  => g_num_ports
		)
		port map( 
			
			-- standard register control signals --
			clk_in				=> router_clk,
			enable 				=> '1',
			rst_in				=> router_rst,
			
			address_assert		=> req_active,
			addr_byte_in(0 to c_ports_slice)	=> addr_byte_in,		
			addr_byte_valid		=> addr_byte_valid,	
			addr_byte_ready		=> addr_byte_ready,	
			bad_addr			=> bad_addr,
			
			address_req_out		=> address_req_out(0),
			address_tar_out		=> address_tar_out(0),
			address_req_valid	=> address_req_valid,	
			address_req_ready	=> address_req_ready,	
			
			axi_in				=> axi_bus_master,			
			axi_out  		    => axi_bus_slave_0  	

		);
	
	else generate 
		-- routing table arbitration controller 
		rt_arbiter_inst:entity work.router_rt_arbiter(rtl)
		generic map(
			g_num_ports  => g_num_ports
		)
		port map( 
			
			-- standard register control signals --
			clk_in				=> router_clk,
			enable 				=> '1',
			rst_in				=> router_rst,
			
			address_assert		=> req_active,
			addr_byte_in(0 to c_ports_slice)	=> addr_byte_in,		
			addr_byte_valid		=> addr_byte_valid,	
			addr_byte_ready		=> addr_byte_ready,	
			bad_addr			=> bad_addr,

			address_req_out		=> address_req_out,	
			address_req_valid	=> address_req_valid,	
			address_req_ready	=> address_req_ready,	
			
			axi_in				=> axi_bus_master,			
			axi_out  		    => axi_bus_slave_0  	

		);
	end generate priority_gen;

	-- X-Bar fabric top-level architecture
	xbar_tl_inst: entity work.router_xbar_top_level(rtl)
	generic map(
		g_num_ports => g_num_ports,
		g_priority 	=> g_priority
	)
	port map( 
		
		-- standard register control signals --
		clk_in				=> router_clk,
		rst_in				=> router_rst,
		
		address_tar_in		=> address_tar_out,
		address_req_in		=> address_req_out,	
		address_req_valid	=> address_req_valid,
		address_req_ready	=> address_req_ready,
		
		bus_in_m			=> req_fabric_bus_m,
		bus_in_s			=> tar_fabric_bus_s,
		bus_out_m			=> tar_fabric_bus_m,
		bus_out_s			=> req_fabric_bus_s,

		addr_active			=> req_active		

    );
	
	-- generate individual ports & control logic
	gen_ports: for i in 0 to g_num_ports-1 generate
		rx_con_inst: entity work.router_port_rx_controller(rtl)
		port map( 
			
			-- standard register control signals --
			clk_in				=> 	router_clk,				-- clk input, rising edge trigger
			rst_in				=> 	router_rst,				-- reset input, active high-- clk input, rising edge trigger
			enable  			=> 	'1',					-- enable input, asserted high. -- reset input, active high
			-- enable input, asserted high. 
			-- SpaceWire Data from CoDec -- 
			
			spw_rx_fifo_m		=>  spw_rx_fifo_m(i),		
			spw_rx_fifo_s		=>  spw_rx_fifo_s(i), 		

			-- SpaceWire Address Byte (first byte) output--
			addr_byte_out		=> 	rx_addr_byte_out(i),	
			addr_byte_in		=> 	rx_addr_byte_in(i),	
			
			-- SpaceWire Frame Data output (Across XBar Fabric to target port) -- 	
			frame_bus_out		=>	req_fabric_bus_m(i),		-- custom data width interface for sending data across X-bar fabric
			frame_bus_in		=>	req_fabric_bus_s(i),		-- ready response from target controller. 
			bad_addr			=>  bad_addr(i),
			frame_active 		=> 	req_active(i)	

		);

		gen_spw: if(i > 0) generate
		
			-- DP fifo for SpW to Router Clock Domain
			rx_spw_fifo: entity work.spw_rx_dp_fifo_buffer(rtl)
			generic map(
				g_rd_mult 		=> 	c_fabric_bus_width,
				g_fifo_depth 	=> 	4,
				g_ram_style 	=> 	g_ram_style
			)
			port map(
				wr_clk 			=> 	router_clk,
				rd_clk 			=> 	router_clk,
				wr_rst_in		=> 	router_rst,
				rd_rst_in		=>  router_rst,
				-- SpaceWire Codec Interface (Connect to SpW RX Data)
				spw_wr_data 	=>	rx_spw_rx_data(i),			
				spw_wr_valid	=>	rx_spw_rx_data_valid(i),
				spw_wr_ready	=>	rx_spw_rx_data_ready(i),
				
				-- Router Data Interface (Connect to Rx Controller)
				FIFO_rd_m		=>	spw_rx_fifo_m(i),
				FIFO_rd_s		=>  spw_rx_fifo_s(i)
			
			);
		
			tx_con_inst: entity work.router_port_tx_controller(rtl)
			port map( 
				-- standard register control signals --
				-- standard register control signals --
				clk_in				=>	router_clk,		-- clk input, rising edge trigger
				rst_in				=>	router_rst,		-- reset input, active high
				enable  			=>	'1',			-- enable input, asserted high. 
				
				frame_bus_in		=> 	tar_fabric_bus_m(i),
			    frame_bus_out	    => 	tar_fabric_bus_s(i),

			    fifo_bus_in			=>	spw_tx_fifo_s(i),	
				fifo_bus_out		=>	spw_tx_fifo_m(i)	
			
			);
			
			-- DP fifo for Router to SpW Clock Domain 
			tx_spw_fifo: entity work.spw_tx_dp_fifo_buffer(rtl)
			generic map(
				g_rd_mult 		=> 	c_fabric_bus_width,
				g_fifo_depth 	=> 	4,
				g_ram_style 	=> 	g_ram_style
			)
			port map(
				wr_clk 			=> 	router_clk,
				rd_clk 			=> 	router_clk,
				wr_rst_in		=> 	router_rst,
				rd_rst_in		=>  router_rst,
				
				-- SpaceWire Codec Interface (Connect to SpW RX Data)
				spw_rd_data 	=>	tx_spw_tx_data(i),
				spw_rd_valid	=>  tx_spw_tx_data_valid(i),
				spw_rd_ready	=>  tx_spw_tx_data_ready(i),
				
				-- Router Data Interface (Connect to Tx Controller)
				FIFO_wr_m		=>	spw_tx_fifo_m(i),
				FIFO_wr_s		=>  spw_tx_fifo_s(i)
			
			);
			
			gen_fifo:if (g_is_fifo(i) = '1') generate	-- generate data ports as FIFO interfaces
		
				rx_spw_rx_data(i) 				<= spw_fifo_in(i).rx_data;			-- rx data
				rx_spw_rx_data_valid(i) 		<= spw_fifo_in(i).rx_valid;			-- rx data valid
				tc_rx_master(i).tdata 			<= spw_fifo_in(i).rx_time;			-- rx time code 
				tc_rx_master(i).tvalid 			<= spw_fifo_in(i).rx_time_valid;	-- rx time code valid
				tx_spw_tx_data_ready(i) 		<= spw_fifo_in(i).tx_ready;			-- tx data ready
				tc_tx_slave(i).tready 			<= spw_fifo_in(i).tx_time_ready;	-- tx time code ready
				connected(i) 					<= spw_fifo_in(i).connected;
				
				spw_fifo_out(i).tx_data 		<= tx_spw_tx_data(i);
				spw_fifo_out(i).tx_valid 		<= tx_spw_tx_data_valid(i);
				spw_fifo_out(i).tx_time 		<= tc_tx_master(i).tdata;
				spw_fifo_out(i).tx_time_valid 	<= tc_tx_master(i).tvalid;
				spw_fifo_out(i).rx_ready 		<= rx_spw_rx_data_ready(i);
				spw_fifo_out(i).rx_time_ready	<= tc_rx_slave(i).tready;
				
				spw_status_memory(i)(0) <= connected(i);                          --remove comment to enable connected status
				
			else generate
			
				spw_port_inst: entity work.spw_wrap_top_level_RTG4(rtl)
				generic map(
					g_clock_frequency  	=> g_clock_freq,			-- clock frequency for SpaceWire IP (>2MHz)
					g_rx_fifo_size     	=> 56, 						-- must be >8
					g_tx_fifo_size     	=> 56, 						-- must be >8
					g_mode				=> g_mode					-- valid options are "diff", "single" and "custom".
				)
				port map( 
					clock               =>	router_clk,
					reset               => 	router_rst,
					-- Channels
					Tx_data             => 	tx_spw_tx_data(i),
					Tx_OR               =>	tx_spw_tx_data_valid(i),
					Tx_IR               =>	tx_spw_tx_data_ready(i),
					
					Rx_data             => 	rx_spw_rx_data(i),		
					Rx_OR               => 	rx_spw_rx_data_valid(i),
					Rx_IR               => 	rx_spw_rx_data_ready(i),
					
					Rx_ESC_ESC          =>	spw_status_memory(i)(1),
					Rx_ESC_EOP          =>  spw_status_memory(i)(2),
					Rx_ESC_EEP          =>  spw_status_memory(i)(3),
					Rx_Parity_error     =>  spw_status_memory(i)(4),
					Rx_bits             =>  open,
					Rx_rate             =>  open,
			
					Rx_Time             =>	tc_rx_master(i).tdata,
					Rx_Time_OR          =>  tc_rx_master(i).tvalid,
					Rx_Time_IR          =>  tc_rx_slave(i).tready,
				
					Tx_Time             =>	tc_tx_master(i).tdata,
					Tx_Time_OR          =>  tc_tx_master(i).tvalid,
					Tx_Time_IR          =>  tc_tx_slave(i).tready,
					
					Tx_PSC				=> 	Tx_PSC_reg(i),			
					Tx_PSC_valid		=> 	Tx_PSC_valid(i),
					Tx_PSC_ready		=> 	Tx_PSC_ready(i),		
					
					-- Control	
					Disable             => 	spw_config_memory(i)(0),
					Connected           => 	connected(i), --spw_status_memory(i-1)(0),
					Error_select        => 	spw_config_memory(i)(5 downto 2),
					Error_inject        => 	spw_config_memory(i)(1),
					
					-- DDR/SDR IO, only when "custom" mode is used
					-- when instantiating, if not used, you can ignore these ports. 
					DDR_din_r			=> 	DDR_din_r(i),
					DDR_din_f           => 	DDR_din_f(i),
					DDR_sin_r           =>	DDR_sin_r(i), 
					DDR_sin_f           =>	DDR_sin_f(i),
					SDR_Dout			=>	SDR_Dout(i),
					SDR_Sout			=>	SDR_Sout(i),

					Din_p               =>	Din_p(i),   
					Din_n               =>  Din_n(i),   
					Sin_p               =>  Sin_p(i),    
					Sin_n               =>  Sin_n(i),    
					Dout_p              =>  Dout_p(i),   
					Dout_n              =>  Dout_n(i),   
					Sout_p              =>  Sout_p(i),   
					Sout_n              =>  Sout_n(i)  

				);
				Port_Connected(i) <= connected(i);
				spw_status_memory(i)(0) <= connected(i);
			end generate gen_fifo;
			
		else generate 	-- generate port 0 controller logic instead of a Physical SpaceWire Port here... 
			
			port_0_inst: entity work.router_port_0_controller(rtl)	-- replaces port 0 TX Controller and SpaceWire IP 
			generic map(
				g_ram_style 	=> 	g_ram_style
			)
			port map( 

				-- standard register control signals --
				wr_clk				=> 	router_clk,				-- clk input, rising edge trigger
				rd_clk				=> 	router_clk,
				wr_rst_in			=> 	router_rst,		-- reset input, active high
				rd_rst_in			=> 	router_rst,		
				
				-- SpaceWire Data to CoDec -- This time connect to RX controller, no SpW IP needed. 
				spw_tx_data			=>	rx_spw_rx_data(i),
				spw_tx_data_valid 	=>	rx_spw_rx_data_valid(i),
				spw_tx_data_ready   => 	rx_spw_rx_data_ready(i),
				
				-- SpaceWire Frame Data input (Request across Xbar fabric) -- 
				frame_bus_in		=> 	tar_fabric_bus_m(i),
				frame_bus_out	 	=> 	tar_fabric_bus_s(i),
				
				-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
				axi_out 			=>	axi_bus_master,
				axi_in_0			=> 	axi_bus_slave_0,
				axi_in_1			=> 	axi_bus_slave_1,
				axi_in_2			=> 	axi_bus_slave_2,
				axi_in_3			=> 	axi_bus_slave_3,
				axi_in_4			=> 	axi_bus_slave_4,
				axi_in_5			=> 	axi_bus_slave_5,
				
				key_in				=>	c_target_key
				
			);
			
			-- DP fifo in router clock domain (for port 0 controller)
			rx_spw_fifo: entity work.spw_rx_dp_fifo_buffer(rtl)
			generic map(
				g_rd_mult 		=> 	c_fabric_bus_width,
				g_fifo_depth 	=> 	4,
				g_ram_style 	=> 	g_ram_style
			)
			port map(
				wr_clk 			=> 	router_clk,
				rd_clk 			=> 	router_clk,
				wr_rst_in		=>	router_rst,
				rd_rst_in 		=>  router_rst,
				
				-- SpaceWire Codec Interface (Connect to SpW RX Data)
				spw_wr_data 	=>	rx_spw_rx_data(i),			
				spw_wr_valid	=>	rx_spw_rx_data_valid(i),
				spw_wr_ready	=>	rx_spw_rx_data_ready(i),
				
				-- Router Data Interface (Connect to Rx Controller)
				FIFO_rd_m		=>	spw_rx_fifo_m(i),
				FIFO_rd_s		=>  spw_rx_fifo_s(i)
			
			);
		
		end generate gen_spw;
		
		-- connect up interfaces 
		addr_byte_in(i) 	<= rx_addr_byte_out(i).tdata;
		addr_byte_valid(i) 	<= rx_addr_byte_out(i).tvalid;
		rx_addr_byte_in(i).tready <= addr_byte_ready(i);
		
		
		
	end generate gen_ports;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------

	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-- buffer/Synchonize reset signals for respective clocks
	process(router_clk)
	begin
		if(rising_edge(router_clk)) then
			rst_in_sync <= rst_in;
			Tx_PSC_valid <= (others => '1');
			if(rst_in_sync = '1') then
				Tx_PSC_valid <= (others => '0');
			end if;
		end if;
	end process;
	
	process(router_clk)
	begin
		if(rising_edge(router_clk)) then
			router_rst <= rst_in;
		end if;
	end process;


end rtl;