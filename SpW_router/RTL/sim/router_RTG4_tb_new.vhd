----------------------------------------------------------------------------------
-- Company: 	4Links Ltd
-- Engineer: 	James E Logan 
-- 
-- Create Date: 09.08.2023 19:45:58
-- Design Name: 
-- Module Name: router_top_level_RTG4_tb - bench
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

context work.router_context;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;



entity router_top_level_RTG4_tb is
--  Port ( );
end router_top_level_RTG4_tb;

architecture bench of router_top_level_RTG4_tb is
	
	constant c_tb_clock_freq : real := c_spw_clk_freq;									-- router clock frequency, found in router_pckg.vhd
	constant router_clk_p	: 	time := (1_000_000_000.0/c_router_clk_freq) * 1 ns;
    constant clk_period 	: 	time := (1_000_000_000.0/c_tb_clock_freq) * 1 ns;			-- get clock period from selected frequency
	constant c_client_gen 	: 	t_dword :=(				-- if '1' port is RMAP client, else RMAP target 
		0 	=> '0',					-- has no effect, always '0' as Port 0 is an internal port, not a physical one. 
		1 	=> '0',
		2 	=> '0',
		3 	=> '0',
		4	=> '0',
		5   => '0',
		6   => '0',
		7   => '0',
		8   => '0',
		9   => '0',
		10  => '0',
		11  => '0',
		12  => '0',
		13  => '0',
		14  => '0',
		15  => '0',
		16  => '0',
		17  => '0',
		18  => '0',
		19  => '0',
		20  => '0',
		21  => '0',
		22  => '0',
		23  => '0',
		24  => '0',
		25  => '0',
		26  => '0',
		27  => '0',
		28  => '0',
		29  => '0',
		30  => '0',
		31  => '0'
	);
	
	-- assert bits (which are not high in c_client_gen) to set as raw spacewire Codec 
	constant c_raw_gen	: t_dword :=(
		0 	=> '0',					-- has no effect, always '0' as Port 0 is an internal port, not a physical one. 
		1 	=> '1',
		2 	=> '1',
		3 	=> '1',
		4	=> '1',
		5   => '1',
		6   => '1',
		7   => '1',
		8   => '1',
		9   => '1',
		10  => '1',
		11  => '1',
		12  => '1',
		13  => '1',
		14  => '1',
		15  => '1',
		16  => '1',
		17  => '1',
		18  => '1',
		19  => '1',
		20  => '1',
		21  => '1',
		22  => '1',
		23  => '1',
		24  => '1',
		25  => '1',
		26  => '1',
		27  => '1',
		28  => '1',
		29  => '1',
		30  => '1',
		31  => '1'
	);

  
	signal	clk_in					:  	std_logic := '0';		-- clk input, rising edge trigger
	signal 	clk_in_b				: 	std_logic := '1';
	signal  router_clk				: 	std_logic := '0';
	signal 	rst_in					: 	std_logic := '1';
	signal 	enable					: 	std_logic := '0';
	
	signal	DDR_din_r				: 	std_logic_vector(1 to c_num_ports-1)		:= (others => '0');
	signal	DDR_din_f   			: 	std_logic_vector(1 to c_num_ports-1)     := (others => '0');
	signal	DDR_sin_r   			: 	std_logic_vector(1 to c_num_ports-1)     := (others => '0');
	signal	DDR_sin_f   			: 	std_logic_vector(1 to c_num_ports-1)     := (others => '0');
	signal	SDR_Dout				: 	std_logic_vector(1 to c_num_ports-1)     := (others => '0');
	signal	SDR_Sout				: 	std_logic_vector(1 to c_num_ports-1)     := (others => '0');
	
	signal	spw_fifo_in				: 	r_fifo_master_array(1 to c_num_ports-1) := (others => c_fifo_master);
	signal	spw_fifo_out			: 	r_fifo_slave_array(1 to c_num_ports-1)	:= (others => c_fifo_slave);
	signal	last_time_code			: 	t_byte 		:= (others => '0');
	signal	tc_master_mask			: 	t_dword 	:= b"0000_0000_0000_0001_0000_0000_0000_0000";
	signal	RMAP_KEY_REG			: 	t_byte 		:= (others => '0');
	
	signal	Din_p  					:  std_logic_vector(1 to c_num_ports-1) 	:= (others => '0');
	signal	Din_n                   :  std_logic_vector(1 to c_num_ports-1) 	:= (others => '0');
	signal	Sin_p                   :  std_logic_vector(1 to c_num_ports-1) 	:= (others => '0');
	signal	Sin_n                   :  std_logic_vector(1 to c_num_ports-1) 	:= (others => '0');
	signal	Dout_p                  :  std_logic_vector(1 to c_num_ports-1)	:= (others => '0');
	signal	Dout_n                  :  std_logic_vector(1 to c_num_ports-1)  := (others => '0');
	signal	Sout_p                  :  std_logic_vector(1 to c_num_ports-1)  := (others => '0');
	signal	Sout_n                  :  std_logic_vector(1 to c_num_ports-1)  := (others => '0');
	signal 	test_slv				:  t_byte  	:= b"0010_0010";
	signal  test_std				: 	std_logic := '0';
	
	signal  check_okay				: t_bool_array(0 to 31);
	signal  s_rx_ready				: t_dword := (others => '0');
	
	signal  Router_Port_Connected	: std_logic_vector(31 downto 1) := (others => '0');
	
	
	impure function or_reduce(slv: std_logic_vector) return std_logic is
		variable std: std_logic := '0';
	begin
		for i in 0 to (slv'length)-1 loop
			std := (slv(i) or std);
			exit when std = '1';
		end loop;
		return std;
	end function or_reduce;
	
	
--	type t_rmap_frame_array is array (natural range <>) of t_rmap_frame;
	
	
	-- create signal arrays for RMAP initiators(s) 
	signal 	initiators				: 	r_rmap_init_interface_array(1 to  c_num_ports-1) := (others => c_rmap_init_interface);		-- create array of initiator interfaces 
	signal 	targets					: 	r_rmap_target_interface_array(1 to  c_num_ports-1) := (others => c_rmap_target_interface);	-- create array of target interfaces
	signal 	codecs					:	r_codec_interface_array(1 to c_num_ports-1) := (others => c_codec_interface);				-- create array of codec interfaces
	signal 	spw_debugs				:	r_spw_debug_signals_array(1 to c_num_ports-1);
	signal  spw_debugs_in			: 	r_spw_debug_signals_array(1 to  c_num_ports-1);

	signal  path_bytes_2 			: t_integer_array_256(0 to 0) := (
		0 => 0
	);
	signal data_bytes_2 : t_byte_array(0 to 3) :=(
		0 => b"0000_0000",
		1 => b"0010_0000",
		2 => b"0100_0000",
		3 => b"0000_0000"
	);
	shared variable rmap_command_4	: t_rmap_command;	-- RMAP Initiator Commands 
	shared variable rmap_command_2  : t_rmap_command;	-- RMAP Initiator Commands 
	shared variable rmap_command_22 : t_rmap_command;	-- RMAP Initiator Commands 
	
	shared variable rmap_frame_2	: t_rmap_frame;
	
	shared variable rmap_frame_22	: t_rmap_frame;
	shared variable rmap_frame_23	: t_rmap_frame;
	shared variable rmap_frame_24	: t_rmap_frame;
	shared variable rmap_frame_25	: t_rmap_frame;
	shared variable rmap_frame_26	: t_rmap_frame;
	shared variable rmap_frame_27	: t_rmap_frame;
	shared variable rmap_frame_28	: t_rmap_frame;
	shared variable rmap_frame_29	: t_rmap_frame;
	
	shared variable rmap_frames		: t_rmap_frame_array;
	
	

begin

	
	-- generate our DDR clock signals for SpW IP
    p_clk_gen: process
    begin
        clk_in <= '1';
        wait for clk_period/2;
        clk_in <= '0';
        wait for clk_period/2;
    end process;
	
	n_clk_gen: process
	begin
		clk_in_b <= '0';
        wait for clk_period/2;
        clk_in_b <= '1';
        wait for clk_period/2;
	end process;
	
	router_clk_gen: process
	begin
		router_clk <= '0';
		wait for router_clk_p/2;
		router_clk <= '1';
		wait for router_clk_p/2;
	end process;
	

	port_stim : for i in 1 to c_num_ports-1 generate	-- configured in router_pckg.vhd
		process
			variable  channel : integer;
			variable v_path_bytes 	: t_integer_array_256(0 to 0) := (others => 0);
			variable config_addr 	: t_byte_array(0 to 3);
			variable status_addr    : t_byte_array(0 to 3);
			variable rt_address		: std_logic_vector(9 downto 0);
			variable data_ints		: t_integer_array_256(0 to 3);
		begin
			check_okay(i) <= false;
			channel := i;
			v_path_bytes(0) := c_num_ports - i;
			rmap_frames.set_path_bytes(i, v_path_bytes);						-- specify path bytes (if used)
			rmap_frames.has_path_addr(i,true);                               -- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 254);                             -- set logical address (254 is path bytes used)
			rmap_frames.set_pid(i,1);                                        -- set Protocol ID
			rmap_frames.set_instruction(i, "write", false, false, true, "00"); -- set Instruction Byte (RD/WR, Verify ?, Reply Required ? Increment Address ? Reply Address Field length ?
			rmap_frames.set_key(i, 1);                                        -- set Key 
			rmap_frames.set_init_address(i, i);                               -- set Initiator Address
			rmap_frames.set_trans_id(i, 98+i);                                  -- set Transaction ID
			rmap_frames.set_mem_address(i, 120+i);                              -- set Memory Address (32-bit)
			rmap_frames.set_data_length(i, 16);                                -- set length of Data field (if required)
			rmap_frames.set_data_bytes(i, c_data_test_pattern_1);                      -- set data bytes (if required)
		--	rmap_frames.set_header_crc(i);
		
			wait until rst_in = '0';
			wait for  25.4 us;
			
			
			send_rmap_frame_raw_array(
				channel,
				codecs(i).Tx_data,
				codecs(i).Tx_OR,
				codecs(i).Tx_IR,
				rmap_frames
			);
			
			rmap_frames.has_path_addr(i,false);                               	-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 45+i);                             -- set logical address (254 is path bytes used)
			rmap_frames.set_trans_id(i, 158+i);                                  -- set Transaction ID
			
		--	if (i = 1 or i = 4 or i = 11 or i = 5) then
				for j in 0 to 4 loop
				--	rmap_frames.set_logical_addr(i, 34+(i*j));                             -- set logical address (254 is path bytes used)
					rmap_frames.set_logical_addr(i, 34);
					rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
				
					send_rmap_frame_raw_array(
						channel,
						codecs(i).Tx_data,
						codecs(i).Tx_OR,
						codecs(i).Tx_IR,
						rmap_frames
					);
				end loop;
			-- end if;
			
			if(i = 16) then
				codecs(i).Tx_Time <= b"0000_0001";
				codecs(i).Tx_Time_OR <= '1';
				if(codecs(i).Tx_Time_IR = '0') then
					wait until codecs(i).Tx_Time_IR = '1';
				end if;
				if(codecs(i).Tx_Time_IR = '1') then
					wait until codecs(i).Tx_Time_IR = '0';
				end if;
				codecs(i).Tx_Time_OR <= '0';
			end if;
			
			wait for 30 us;
			
			rmap_frames.has_path_addr(i,false);                               	-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 45+i);                             -- set logical address (254 is path bytes used)
			rmap_frames.set_trans_id(i, 158+i);                                  -- set Transaction ID
			
			
			send_rmap_frame_raw_array(
				channel,
				codecs(i).Tx_data,
				codecs(i).Tx_OR,
				codecs(i).Tx_IR,
				rmap_frames
			);
			
			rmap_frames.has_path_addr(i,false);                               	-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 45+i);                             -- set logical address (254 is path bytes used)
			rmap_frames.set_trans_id(i, 158+i);                                  -- set Transaction ID
			
			send_rmap_frame_raw_array(
				channel,
				codecs(i).Tx_data,
				codecs(i).Tx_OR,
				codecs(i).Tx_IR,
				rmap_frames
			);
			
			for j in 0 to 95 loop
				rmap_frames.set_logical_addr(i, 33+i+j);                             -- set logical address (254 is path bytes used)
				rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
			
				send_rmap_frame_raw_array(
					channel,
					codecs(i).Tx_data,
					codecs(i).Tx_OR,
					codecs(i).Tx_IR,
					rmap_frames
				);
			end loop;
			
			for j in 0 to 6 loop
				rmap_frames.set_logical_addr(i, 33+(i*j));                             -- set logical address (254 is path bytes used)
				rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
			
				send_rmap_frame_raw_array(
					channel,
					codecs(i).Tx_data,
					codecs(i).Tx_OR,
					codecs(i).Tx_IR,
					rmap_frames
				);
			end loop;
			
		--	wait for 100 us;
			
			v_path_bytes(0) := 	0;
			rt_address 		:= 	std_logic_vector(to_unsigned(132 + (i*4), rt_address'length));
			config_addr(0) 	:= 	rt_address(7 downto 0);
			config_addr(1) 	:=	b"0000_00"& rt_address(9 downto 8);
			config_addr(2) 	:= 	x"00";
			config_addr(3) 	:=	x"00";		
			data_ints := (0, 7, 127, 34);
			rmap_frames.set_path_bytes(i, v_path_bytes);						-- specify path bytes (if used)
			rmap_frames.has_path_addr(i,true);                               	-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 254);                            	-- set logical address (254 is path bytes used)
			rmap_frames.set_trans_id(i, 0+i);                                  	-- set Transaction ID
			rmap_frames.set_data_length(i, 4);                               	 -- set length of Data field (if required)
			rmap_frames.set_mem_address(i, config_addr);
			rmap_frames.set_data_bytes(i, int_to_byte_array(data_ints));                      	-- set data bytes (if required)
			
			send_rmap_frame_raw_array(
				channel,
				codecs(i).Tx_data,
				codecs(i).Tx_OR,
				codecs(i).Tx_IR,
				rmap_frames
			);
			
			status_addr(0) 	:= 	rt_address(7 downto 0);
			status_addr(1) 	:=	b"0000_00"& rt_address(9 downto 8);
			status_addr(2) 	:= 	x"00";
			status_addr(3) 	:=	x"00";		
			rmap_frames.set_mem_address(i, status_addr);
			rmap_frames.set_instruction(i, "read", false, true, true, "00");
			
			send_rmap_frame_raw_array(
				channel,
				codecs(i).Tx_data,
				codecs(i).Tx_OR,
				codecs(i).Tx_IR,
				rmap_frames
			);
			
			
			rmap_frames.has_path_addr(i,false);                               	-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 45+i);                             -- set logical address (254 is path bytes used)
			rmap_frames.set_trans_id(i, 158+i);                                  -- set Transaction ID
			v_path_bytes(0) := 32 - i;
			rmap_frames.set_path_bytes(i, v_path_bytes);						-- specify path bytes (if used)
			rmap_frames.set_pid(i,1);                                        -- set Protocol ID
			rmap_frames.set_instruction(i, "write", false, false, true, "00"); -- set Instruction Byte (RD/WR, Verify ?, Reply Required ? Increment Address ? Reply Address Field length ?
			rmap_frames.set_key(i, 1);                                        -- set Key 
			rmap_frames.set_init_address(i, i);                               -- set Initiator Address
			rmap_frames.set_trans_id(i, 98+i);                                  -- set Transaction ID
			rmap_frames.set_mem_address(i, 120+i);                              -- set Memory Address (32-bit)
			rmap_frames.set_data_length(i, 16);                                -- set length of Data field (if required)
			rmap_frames.set_data_bytes(i, c_data_test_pattern_1);                      -- set data bytes (if required)
			
			for j in 0 to 6 loop
				rmap_frames.set_logical_addr(i, 33+(i*j));                             -- set logical address (254 is path bytes used)
				rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
			
				send_rmap_frame_raw_array(
					channel,
					codecs(i).Tx_data,
					codecs(i).Tx_OR,
					codecs(i).Tx_IR,
					rmap_frames
				);
			end loop;
			
			for j in 0 to 127 loop
				rmap_frames.set_logical_addr(i, 33+i+j);                             -- set logical address (254 is path bytes used)
				rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
			
				send_rmap_frame_raw_array(
					channel,
					codecs(i).Tx_data,
					codecs(i).Tx_OR,
					codecs(i).Tx_IR,
					rmap_frames
				);
			end loop;
			
			wait for 100 us;
			
			if (i = 4 or i = 26) then
				for j in 0 to 6 loop
					rmap_frames.set_logical_addr(i, 33+(i*j));                             -- set logical address (254 is path bytes used)
					rmap_frames.set_trans_id(i, 0+i+j);                                  -- set Transaction ID
				
					send_rmap_frame_raw_array(
						channel,
						codecs(i).Tx_data,
						codecs(i).Tx_OR,
						codecs(i).Tx_IR,
						rmap_frames
					);
				end loop;
			end if;
			
			
			check_okay(i) <= true;
			
			wait;
		end process;
		
	--	port_check_proc: process
	--		variable v_channel : integer range 1 to 31;
	--		variable v_in_channel : integer range 1 to 31;
	--	--	variable v_path_bytes : t_integer_array_256(0 to 0) := (others => 0);
	--	begin
	--		v_channel := 32 - i;
	--		v_in_channel := i;
	--		wait for  25.7 us;
	--		rmap_rd_buffer_raw(
	--			v_in_channel,
	--			codecs(v_channel).Rx_data,
	--			codecs(v_channel).Rx_OR,
	--			s_rx_readyv_channel),
	--			check_okay(i),
	--			rmap_frames
	--		);
	--		wait;
	--	end process port_check_proc;
	
	end generate port_stim;
	
--	timecode_proc: process
--	begin
--		wait for 220.3 us;
--		codecs(16).Tx_Time <= b"0000_0110";
--		codecs(16).Tx_Time_OR <= '1';
--		if(codecs(16).Tx_Time_IR = '0') then
--			wait until codecs(16).Tx_Time_IR = '1';
--		end if;
--		if(codecs(16).Tx_Time_IR = '1') then
--			wait until codecs(16).Tx_Time_IR = '0';
--		end if;
--		codecs(16).Tx_Time_OR <= '0';
--		wait;
--	end process;
	
	spw_debug_gen: for i in 1 to c_num_ports-1 generate
		spw_debug_i: process
		begin
			wait until rst_in = '0';
			debug_loop: loop
				spw_get_poll(
					spw_debugs(i),
					Dout_p(i),
					Sout_p(i),
					1					
				);
			end loop;
			wait;
		end process;
	end generate spw_debug_gen;
	
	spw_debug_gen_in: for i in 1 to c_num_ports-1 generate
		spw_debug_i: process
		begin
			wait until rst_in = '0';
			debug_loop: loop
				spw_get_poll(
					spw_debugs_in(i),
					Din_p(i),
					Sin_p(i),
					1					
				);
			end loop;
			wait;
		end process;
	end generate spw_debug_gen_in;
	
	
--	c_router_header_pattern_2 
	-- stimulus generation 
    Initiator_stim_gen :process
    begin
		RMAP_KEY_REG <= x"01";	-- set RMAP key to 01. 
	--	rst_in <= '1';
		enable <= '1';
		wait for 45.24 ns;
		rst_in <= '0';
		test_std <= or_reduce(test_slv);
		report "tests started" severity warning;
		
		wait until check_okay(1 to c_num_ports-1) = (1 to c_num_ports-1 => true);
		wait for 10 us;
		report "stim finished @ :" & to_string(now) severity warning;
		finish;
    end process;
	
	default_stop: process
	begin
		wait for 2500 us;
		
		report "sim timed out" severity failure;
		wait;
	end process;
    

	-- instantiate the RMAP router 
	router_inst: entity work.router_top_level_RTG4(rtl)
    generic map(
		g_clock_freq => c_router_clk_freq,
        g_num_ports => c_num_ports,
		g_mode		=> "diff",
		g_priority	=> c_priority
    )
	port map( 
	
		-- standard register control signals --
		router_clk				=>  router_clk		,
		rst_in					=>  rst_in			,	
	
		DDR_din_r				=> 	open			,	
		DDR_din_f   			=> 	open			,  
		DDR_sin_r   			=> 	open			,  
		DDR_sin_f   			=> 	open			,  
		SDR_Dout				=> 	open			,
		SDR_Sout				=> 	open			,
		
		Din_p               	=>	Din_p			,  
		Din_n               	=>  Din_n			,  
		Sin_p               	=>  Sin_p			,  
		Sin_n               	=>  Sin_n			,  
		Dout_p              	=>  Dout_p			, 
		Dout_n              	=>  Dout_n			, 
		Sout_p              	=>  Sout_p			, 
		Sout_n              	=>  Sout_n  


    );
	/*
		This is where things get BIG, for full coverage, we must test in full 32x32 mode for 
		we need to instantiate SpW CoDecs on each port so that they do not time out. 
		Therefore at minimum we need 31 SpaceWire CoDecs, one for each physical port. 
		Since data will be formatted for RMAP, we need a mixture of RMAP Clients and targets,
		this emulates a SpaceWire Network where multiple targets may be connected to multiple
		clients in a SpaceWire network. 
		For testing we will use a single SpaceWire target with 30 SpaceWire Targets.
		
		We will then validate using multiple clients, all requesting the same output ports.
		this will test the arbitration scheme implementation for the routing table.
		on start-up, the lowest addressed RMAP Client will send configuration data to the
		RMAP Router, configuring the routing table and enabling ports. 
		
			Start-up Sequence:
			1 - Write Routing table information to Routing table
			2 - All port to enabled by default, writing 0x01 to Tx and Rx config registers 
				RMAP Address: 0x0000_011F to 0x0000_015D will disable port(s).  
			3 - wait 5 clock cycles for all registers to update
			4 - begin transactions and wait before checking results. length of wait depends on path. 
			
		will expand this section as required. 
		
		
	*/
	
	
	-- instantiate RMAP Clients on Selected Ports 
	ports_initiators_gen: for i in 1 to c_num_ports-1 generate	-- start from 1 since config port is virtual port 
	
			raw_gen: if(c_raw_gen(i) = '1') generate
				codec_inst: entity work.spw_wrap_top_level_RTG4(rtl)
				generic map(
					g_clock_frequency  	=> c_router_clk_freq,			-- clock frequency for SpaceWire IP (>2MHz)
					g_rx_fifo_size     	=> 56,						-- must be >8
					g_tx_fifo_size     	=> 56, 						-- must be >8
					g_mode				=> "diff"					-- valid options are "diff", "single" and "custom".
				)
				port map( 
					clock                => clk_in						,
					reset                =>	rst_in						,

					-- Channels
					Tx_data              => codecs(i).Tx_data			,
					Tx_OR                =>	codecs(i).Tx_OR             ,
					Tx_IR                => codecs(i).Tx_IR             ,
					
					Rx_data              =>	codecs(i).Rx_data           ,
					Rx_OR                => codecs(i).Rx_OR             ,
					Rx_IR                => codecs(i).Rx_IR             ,
					
					Rx_ESC_ESC           => codecs(i).Rx_ESC_ESC        ,
					Rx_ESC_EOP           => codecs(i).Rx_ESC_EOP        ,
					Rx_ESC_EEP           => codecs(i).Rx_ESC_EEP        ,
					Rx_Parity_error      => codecs(i).Rx_Parity_error   ,
					Rx_bits              => codecs(i).Rx_bits           ,
					Rx_rate              => codecs(i).Rx_rate           ,
					
					Rx_Time              => codecs(i).Rx_Time           ,
					Rx_Time_OR           => codecs(i).Rx_Time_OR        ,
					Rx_Time_IR           => codecs(i).Rx_Time_IR        ,
			
					Tx_Time              => codecs(i).Tx_Time           ,
					Tx_Time_OR           => codecs(i).Tx_Time_OR        ,
					Tx_Time_IR           => codecs(i).Tx_Time_IR        ,
				
					-- Control	                                        
					Disable              => codecs(i).Disable           ,
					Connected            => codecs(i).Connected         ,
					Error_select         => codecs(i).Error_select      ,
					Error_inject         => codecs(i).Error_inject      ,
					
					-- SpW	                                           
					Din_p                => Dout_p(i)             		,
					Sin_p                => Sout_p(i)          			,
					Dout_p               => Din_p(i)         			,
					Sout_p               => Sin_p(i)		         
				);
				
				codecs(i).Rx_IR <= '1';
				codecs(i).Rx_Time_IR <= '1';
			
			
			end generate raw_gen;
			
		
	
	end generate ports_initiators_gen;
	


 
end bench;
