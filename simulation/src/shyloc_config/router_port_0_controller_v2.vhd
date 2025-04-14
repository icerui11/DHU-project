--------------------------------------------------------------------------------
-- Company: IDA
--
-- File: router_port_0_controller_v2.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: This register module is derived from router_port_0_controller and add axi_in_6
--              AXI bus x"06"
--
-- <Description here>
--
-- Targeted device: <Family::SmartFusion2> <Die::M2S150TS> <Package::1152 FC>
-- Author: Rui Yin
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
entity router_port_0_controller_v2 is	-- replaces port 0 TX Controller. 
	generic(
		g_ram_style		: string := "auto"
	);
	port( 
		
		-- standard register control signals --
		wr_clk				: in 	std_logic 			:= '0';					-- clk input, rising edge trigger
		rd_clk				: in 	std_logic			:= '0';
		wr_rst_in			: in 	std_logic 			:= '0';
		rd_rst_in			: in 	std_logic 			:= '0';					-- reset input, active high

		-- SpaceWire Data to CoDec -- This time connect to RX controller, no SpW IP needed. 
		spw_tx_data			: out	t_nonet 			:= (others => '0');		-- SpW Data Nonet (9 bits)
		spw_tx_data_valid   : out 	std_logic 			:= '0';             	-- SpW IR
		spw_tx_data_ready   : in 	std_logic 			:= '0';             	-- SpW OR
		
		-- SpaceWire Frame Data input (Request across Xbar fabric) -- 
		frame_bus_in		: in 	r_fabric_data_bus_m := c_fabric_data_bus_m;	
		frame_bus_out		: out 	r_fabric_data_bus_s := c_fabric_data_bus_s;
		
		-- AXI-Style Memory Read/wr_enaddress signals from RMAP Target
		axi_out 		: out 	r_maxi_lite_dword	:= c_maxi_lite_dword;
		
		axi_in_0		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		axi_in_1		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		axi_in_2		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		axi_in_3		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		axi_in_4		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
		axi_in_5		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;
        axi_in_6		: in 	r_saxi_lite_dword	:= c_saxi_lite_dword;        -- new added for router_ahb_reg
		
		key_in			: in 	t_byte 				:= (others => '0')	-- RMAP Key input (from config memory)
		
    );
end router_port_0_controller_v2;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of router_port_0_controller_v2 is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
--	type t_state is (
--		check_request,
--		write_data,
--		read_data
--	);
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- RMAP Target Port Signals --
	signal 	data_reg			: t_fabric_data_bus := (others => (others => '0'));
	signal 	count_reg			: std_logic_vector(0 to c_fabric_bus_width-1) := (others => '0');
	
	signal	In_data            	: 	t_nonet;
	signal	In_ir              	: 	boolean;
	signal	In_or              	:  	boolean;
	signal	Out_data           	:  	t_nonet;
	signal	Out_IR             	:  	boolean;
	signal	Out_OR             	:  	boolean;
	signal	Address            	:  	unsigned(39 downto 0);
	signal	wr_en             	:  	boolean;
	signal	Write_data         	:  	std_logic_vector( 7 downto 0);
	signal	Bytes              	:  	unsigned(23 downto 0);
	signal	Read_data          	:  	std_logic_vector( 7 downto 0);
--	signal	Read_bytes         	:  	unsigned(23 downto 0);	-- re-configured reply length not required. 
	signal	RW_request         	:  	boolean;
	signal	RW_acknowledge     	:  	boolean;
	signal	Echo_required      	:  	boolean := false;
	signal	Echo_port          	:  	t_byte	:= (others => '0');
	signal	Logical_address    	:  	unsigned(7 downto 0);
	signal	Key                	:  	std_logic_vector(7 downto 0);
	signal	Static_address     	:  	boolean;
	signal	Checksum_fail      	:  	boolean	:= false;	-- asserted when Checksum_fail. 
	signal	Request            	:  	boolean := false;
	signal	Reject_target      	:  	boolean := false;
	signal	Reject_key         	:  	boolean := false;
	signal	Reject_request     	:  	boolean := false;
	signal	Accept_request     	:  	boolean := true;	-- always accept requests, drive this input high ALWAYS 
	signal	Verify_overrun     	:  	boolean	:= false;
	signal	OK                 	:  	boolean	:= false;
	signal	Done               	:  	boolean	:= false;
	
	signal 	input_ready			: 	std_logic := '0';
	signal 	output_ready 		: 	std_logic := '0';
	signal 	axi_read_data		: 	t_byte := (others => '0');
	signal 	ready_mux			:   std_logic_vector(6 downto 0) := (others => '0');       -- add one bit for axi_in_6

--	signal  state				: t_state := check_request;
	
			-- SpaceWire Frame Data input (Request across Xbar fabric) -- 
	signal	fifo_bus_in			:  r_fabric_data_bus_m := c_fabric_data_bus_m;	
	signal	fifo_bus_out		:  r_fabric_data_bus_s := c_fabric_data_bus_s;
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
	port0_fabric_tx_con: entity work.router_port_tx_controller(rtl)
	port map( 
		-- standard register control signals --
		-- standard register control signals --
		clk_in				=>	wr_clk,		-- clk input, rising edge trigger
		rst_in				=>	wr_rst_in,		-- reset input, active high
		enable  			=>	'1',		-- enable input, asserted high. 
		
		frame_bus_in		=> 	frame_bus_in,
		frame_bus_out	    => 	frame_bus_out,

		fifo_bus_in			=>	fifo_bus_out,	
		fifo_bus_out		=>	fifo_bus_in
	
	);

	
	
	-- DP fifo for Router to SpW Clock Domain 
	port0_fabric_fifo: entity work.spw_tx_dp_fifo_buffer(rtl)
	generic map(
		g_rd_mult 		=> 	c_fabric_bus_width,
		g_fifo_depth 	=> 	4,
		g_ram_style 	=> 	g_ram_style
	)
	port map(
		wr_clk 			=> 	wr_clk,
		rd_clk 			=> 	rd_clk,
		wr_rst_in		=> 	wr_rst_in,
		rd_rst_in		=>  rd_rst_in,
		
		-- SpaceWire Codec Interface (Connect to SpW RX Data)
		spw_rd_data 	=>	In_data,
		spw_rd_valid	=>  output_ready,
		spw_rd_ready	=>  input_ready, 
		
		-- Router Data Interface (Connect to Tx Controller)
		FIFO_wr_m		=>	fifo_bus_in,
		FIFO_wr_s		=>  fifo_bus_out
	
	);
	
	rmap_target_inst: entity work.rmap_target(rtl)	-- feed packets into RMAP target for processing. Target does Memory Read/wr_encommands 
	port map( 
		clock              =>	rd_clk			,
		async_reset        => 	false		    ,
		reset              => 	to_bool(rd_rst_in)	,

		-- Data Flow Link input, Requests
		In_data            => 	In_data     	,       
		In_ir              => 	In_ir           ,   
		In_or              => 	In_or           ,   

		-- Data Flow Link out                   
		Out_data           =>	Out_data        ,   
		Out_IR             =>	Out_IR          ,   
		Out_OR             =>	Out_OR          ,   

		-- Memory Interface                  
		Address            => 	Address         ,   
		wr_en              => 	wr_en           ,   
		Write_data         => 	Write_data      ,   
		Bytes              => 	Bytes           ,   
		Read_data          => 	Read_data       ,   
		Read_bytes         => 	Bytes      		,  	-- re-configured reply length not required for this application  

		-- Bus handshake     
		RW_request         => 	RW_request      ,   -- asserted when read/wr_enbyte is ready/valid...
		RW_acknowledge     => 	RW_acknowledge  ,   -- assert when read/wr_enbyte is valid/ready...

		-- Control/Status    -- Control/Status  
		Echo_required      => 	Echo_required   ,   
		Echo_port          => 	Echo_port       ,   

		Logical_address    => 	Logical_address ,   
		Key                => 	Key             ,   
		Static_address     => 	Static_address  ,   

		Checksum_fail      => 	Checksum_fail   ,   

		Request            => 	Request         ,   
		Reject_target      => 	Reject_target   ,   
		Reject_key         => 	Reject_key      ,   
		Reject_request     => 	Reject_request  ,   
		Accept_request     => 	Accept_request  ,   

		Verify_overrun     => 	Verify_overrun  ,   

		OK                 => 	OK              ,   
		Done               => 	Done               
    );

	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	
	In_OR <= to_bool(output_ready);
	input_ready <= to_std(In_IR);
--	ready_mux(0) <= axi_in_0.tready;
--	ready_mux(1) <= axi_in_1.tready;
--	ready_mux(2) <= axi_in_2.tready;
--	ready_mux(3) <= axi_in_3.tready;
	
	-- Link up data output
	spw_tx_data <= Out_data;
	-- Assign read/valid signals, perform boolean/std_logic conversion as required. 
	spw_tx_data_valid <= to_std(Out_OR);
	Out_IR <= to_bool(spw_tx_data_ready);
	
	-- connect up AXI Bus IO signals, convert boolean/std_logic as required. 
	axi_out.taddr 	<= std_logic_vector(Address(31 downto 0));	-- not using extended address field 
	axi_out.wdata 	<= Write_data;
	axi_out.w_en  	<= to_std(wr_en);
	axi_out.tvalid 	<= to_std(RW_request);
	
	--Read_data 		<= axi_read_data;
	RW_acknowledge 	<= to_bool(axi_in_0.tready or axi_in_1.tready or axi_in_2.tready or axi_in_3.tready or axi_in_4.tready or axi_in_5.tready);
	
--In_data <= frame_byte_in.tdata;
--In_or  <= to_bool(frame_byte_in.tvalid);
--frame_byte_out.tready <= to_std(In_IR);
	
	with ready_mux select 
		Read_data 	<= 		axi_in_0.rdata when "0000001",
							axi_in_1.rdata when "0000010",
							axi_in_2.rdata when "0000100",
							axi_in_3.rdata when "0001000",
							axi_in_4.rdata when "0010000",
							axi_in_5.rdata when "0100000",
                            axi_in_6.rdata when "1000000",	  -- new added bit

							(others => '0') when others;
							
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	key_check_proc: process(rd_clk)
	begin
		if(rising_edge(rd_clk)) then
		
			ready_mux(0) <= axi_in_0.tready;
			ready_mux(1) <= axi_in_1.tready;
			ready_mux(2) <= axi_in_2.tready;
			ready_mux(3) <= axi_in_3.tready;
			ready_mux(4) <= axi_in_4.tready;
			ready_mux(5) <= axi_in_5.tready;
            ready_mux(6) <= axi_in_6.tready;	-- new added bit

			
			Reject_key <= false;
			Accept_request <= false;
			if(Request = true and (key_in = key)) then
				Accept_request <= true;
			elsif(Request = true) then
				Reject_key <= true;
			end if;
		end if;
	end process;
	

--	data_proc: process(rd_clk)
--	begin
--		if(rising_edge(rd_clk)) then
--			if(rst_in = '1') then
--				in_state <= get_data;
--				frame_bus_out.tready <= '0';
--			else
--			
--				case in_state is
--				
--					when get_data =>
--						frame_bus_out.tready <= '0';
--						if(frame_bus_in.tvalid = '1') then
--							frame_bus_out.tready <= '1';
--							count_reg <= frame_bus_in.tcount;
--							data_reg <= frame_bus_in.tdata;
--						end if;
--						
--						if(frame_bus_in.tvalid = '0' and frame_bus_out.tready = '1') then
--							in_state <= send_data;
--						end if;
--						
--					when send_data =>
--						In_data <= data_reg(0);
--						In_OR <= true;
--						if(In_OR and In_IR) then
--							In_OR <= false;
--							for i in 0 to c_fabric_bus_width-1 loop
--								if(i = c_fabric_bus_width-1) then
--									count_reg(i) <= '0';
--									data_reg(i) <= b"0_0000_0000";
--								else
--									count_reg(i) <= count_reg(i+1);
--									data_reg(i) <= data_reg(i+1);
--								end if;
--							end loop;
--
--						end if;
--						
--						if(count_reg(0) = '0') then	-- all valid data sent ?
--							In_OR <= false;
--							in_state <= get_data;
--						end if;
--						
--				end case;
--			end if;
--		
--		end if;
--	end process data_proc;

end rtl;