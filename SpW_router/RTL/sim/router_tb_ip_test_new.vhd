----------------------------------------------------------------------------------
-- Company: 	4Links Ltd
-- Engineer: 	James E Logan 
-- 
-- Create Date: 09.08.2023 19:45:58
-- Design Name: 
-- Module Name: router_top_level_tb_ip_test - bench
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

library spw;
--use spw_data_types.all;
use spw.SpaceWire_Sim_lib.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity router_tb_ip_test_new is
--  Port ( );
end router_tb_ip_test_new;

architecture bench of router_tb_ip_test_new is
	
	constant c_tb_clock_freq : real := c_router_clk_freq;									-- router clock frequency, found in router_pckg.vhd
    constant clk_period 	: 	time := (1_000_000_000.0/c_tb_clock_freq) * 1 ns;			-- get clock period from selected frequency
	constant c_client_gen 	: 	t_dword :=(				-- if '1' port is RMAP client, else RMAP target 
		0 	=> '0',					-- has no effect, always '0' as Port 0 is an internal port, not a physical one. 
		1 	=> '0',
		2 	=> '1',
		3 	=> '0',
		4	=> '0',
		5   => '0',
		6   => '1',
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
	
	subtype mem_element is std_logic_vector(7 downto 0);				-- declare size of each memory element in RAM
	type t_ram is array (natural range <>) of mem_element;						-- declare RAM as array of memory element
  
	signal	clk_in					:  	std_logic := '0';		-- clk input, rising edge trigger
	signal 	clk_in_b				: 	std_logic := '1';
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
	signal	Dout_p                  :  std_logic_vector(1 to c_num_ports-1)		:= (others => '0');
	signal	Dout_n                  :  std_logic_vector(1 to c_num_ports-1)  	:= (others => '0');
	signal	Sout_p                  :  std_logic_vector(1 to c_num_ports-1)  	:= (others => '0');
	signal	Sout_n                  :  std_logic_vector(1 to c_num_ports-1)  	:= (others => '0');
	signal 	test_slv				:  t_byte  	:= b"0010_0010";
	signal  test_std				: 	std_logic := '0';
	
	signal  has_target				: std_logic_vector(1 to c_num_ports-1) := (others => '0');
	signal  check_okay				: t_bool_array(0 to 31);
	signal  s_rx_ready				: t_dword := (others => '0');
	
	signal  rx_mem 					: t_byte_array_3d(1 to 31)(0 to 255);
	

--	alias	target_mem_1 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(1 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_2 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(2 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_3 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(3 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_4 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(4 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_5 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(5 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_6 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(6 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_7 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(7 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_8 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(8 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_9 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(9 ).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_10 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(10).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_11	is << signal router_top_level_tb_ip_test.ports_initiators_gen(11).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
--	alias	target_mem_12 	is << signal router_top_level_tb_ip_test.ports_initiators_gen(12).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
	
	
	
	
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
	signal 	initiators				: 	r_rmap_init_interface_array(1 to 31) := (others => c_rmap_init_interface);		-- create array of initiator interfaces 
	signal 	targets					: 	r_rmap_target_interface_array(1 to 31) := (others => c_rmap_target_interface);	-- create array of target interfaces
	signal 	codecs					:	r_codec_interface_array(1 to 31) := (others => c_codec_interface);				-- create array of codec interfaces
	signal 	spw_debugs				:	r_spw_debug_signals_array(1 to 31);
	signal  spw_debugs_in			: 	r_spw_debug_signals_array(1 to 31);

	signal  path_bytes_2 			: t_integer_array_256(0 to 0) := (
		0 => 0
	);
	signal data_bytes_2 : t_byte_array(0 to 3) :=(
		0 => b"0000_0000",
		1 => b"0010_0000",
		2 => b"0100_0000",
		3 => b"0000_0000"
	);

	
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
	

	port_stim : for i in 1 to c_num_ports-1 generate	-- configured in router_pckg.vhd               --only 4 ports
		process
			variable  channel : integer;
			variable v_path_bytes 	: t_integer_array_256(0 to 0) := (others => 0);                    -- the only one path address
			variable config_addr 	: t_byte_array(0 to 3);
			variable status_addr    : t_byte_array(0 to 3);
			variable rt_address		: std_logic_vector(9 downto 0);
			variable data_ints		: t_integer_array_256(0 to 3);
			variable reply_bytes	: t_byte_array(3 downto 0);
		begin
			check_okay(i) <= false;
			channel := i;
			v_path_bytes(0) := c_num_ports - i;
			reply_bytes(3) := std_logic_vector(to_unsigned(i, 8));                  -- modify from 8 to 4
			reply_bytes(2 downto 0) := (others => (others => '0'));
			rmap_frames.set_path_bytes(i, v_path_bytes);							-- specify path bytes (if used)
			rmap_frames.has_path_addr(i,true);                               		-- are path bytes to be used ?
			rmap_frames.set_logical_addr(i, 254);                             		-- set logical address (254 is path bytes used)
			rmap_frames.set_pid(i,1);                                        		-- set Protocol ID
			rmap_frames.set_instruction(i, "write", false, true, true, "01");	 	-- set Instruction Byte (Channel, RD/WR, Verify ?, Reply Required ? Increment Address ? Reply Address Field length ?
			rmap_frames.set_reply_addresses(i, reply_bytes);
			rmap_frames.set_key(i, 1);                                       	 	-- set Key 
			rmap_frames.set_init_address(i, 254);                               	-- set Initiator Address
			rmap_frames.set_trans_id(i, 98+i);                                  	-- set Transaction ID
			rmap_frames.set_mem_address(i, 0);                              		-- set Memory Address (32-bit)
			rmap_frames.set_data_length(i, 16);                                		-- set length of Data field (if required)
			rmap_frames.set_data_bytes(i, c_data_test_pattern_1);                   -- set data bytes (if required) (16 bytes to write)
		
			wait until rst_in = '0';
			wait for  25.4 us;
			
			if(c_client_gen(i) = '1') then	-- is an RMAP initiator on port ?
				send_rmap_frame_array(
					channel,						--	variable channel 		: in integer;
					initiators(i).tx_header,		--	signal 	wr_header		: out 	t_byte;
					initiators(i).tx_header_valid,	--	signal  wr_header_valid : out 	std_logic;
					initiators(i).tx_header_ready,	--	signal 	wr_header_ready : in 	std_logic;
					initiators(i).tx_data,			--	signal  wr_data			: out 	t_byte;
					initiators(i).tx_data_valid,	--	signal  wr_data_valid   : out 	std_logic;
					initiators(i).tx_data_ready,	--	signal  wr_data_ready	: in 	std_logic;
					rmap_frames						--	variable rmap_frame		: inout t_rmap_frame_array
				);
				
				v_path_bytes(0) := 3;                                                   --route to p3
				rmap_frames.set_path_bytes(i, v_path_bytes);							-- specify path bytes (if used)
				send_rmap_frame_array(
					channel,						--	variable channel 		: in integer;
					initiators(i).tx_header,		--	signal 	wr_header		: out 	t_byte;
					initiators(i).tx_header_valid,	--	signal  wr_header_valid : out 	std_logic;
					initiators(i).tx_header_ready,	--	signal 	wr_header_ready : in 	std_logic;
					initiators(i).tx_data,			--	signal  wr_data			: out 	t_byte;
					initiators(i).tx_data_valid,	--	signal  wr_data_valid   : out 	std_logic;
					initiators(i).tx_data_ready,	--	signal  wr_data_ready	: in 	std_logic;
					rmap_frames						--	variable rmap_frame		: inout t_rmap_frame_array
				);
				
				v_path_bytes(0) := 3;
				rmap_frames.set_path_bytes(i, v_path_bytes);							-- specify path bytes (if used)
				rmap_frames.set_instruction(i, "read", false, true, true, "01");	 	-- set Instruction Byte (Channel, RD/WR, Verify ?, Reply Required ? Increment Address ? Reply Address Field length ?
				
				send_rmap_frame_array(
					channel,						--	variable channel 		: in integer;
					initiators(i).tx_header,		--	signal 	wr_header		: out 	t_byte;
					initiators(i).tx_header_valid,	--	signal  wr_header_valid : out 	std_logic;
					initiators(i).tx_header_ready,	--	signal 	wr_header_ready : in 	std_logic;
					initiators(i).tx_data,			--	signal  wr_data			: out 	t_byte;
					initiators(i).tx_data_valid,	--	signal  wr_data_valid   : out 	std_logic;
					initiators(i).tx_data_ready,	--	signal  wr_data_ready	: in 	std_logic;
					rmap_frames						--	variable rmap_frame		: inout t_rmap_frame_array
				);
				
				v_path_bytes(0) := 3;
				send_rmap_frame_array(
					channel,						--	variable channel 		: in integer;
					initiators(i).tx_header,		--	signal 	wr_header		: out 	t_byte;
					initiators(i).tx_header_valid,	--	signal  wr_header_valid : out 	std_logic;
					initiators(i).tx_header_ready,	--	signal 	wr_header_ready : in 	std_logic;
					initiators(i).tx_data,			--	signal  wr_data			: out 	t_byte;
					initiators(i).tx_data_valid,	--	signal  wr_data_valid   : out 	std_logic;
					initiators(i).tx_data_ready,	--	signal  wr_data_ready	: in 	std_logic;
					rmap_frames						--	variable rmap_frame		: inout t_rmap_frame_array
				);
				
			end if;
			
			wait for 10 us; -- wait for stimulus to finish....
			
			check_okay(i) <= true;	-- end of channel stimulus ? set OKAY for watchdog process. 
			
			wait;
		end process;
		
	--	rx_mem(i) <= << signal ^.router_top_level_tb_ip_test.ports_initiators_gen(i).initiator_gen.raw_gen.target_ram_inst.s_ram : t_byte_array >>;
		

		
	--	port_check_proc: process
	--		variable v_channel : integer range 1 to 31;
	--		variable v_in_channel : integer range 1 to 31;
	--		variable v_path_bytes : t_integer_array_256(0 to 0) := (others => 0);
	--	begin
	--		v_channel := 32 - i;
	--		v_in_channel := i;
	--		wait for  25.7 us;
	--		
	--		
	--		
	--		wait;
	--	end process port_check_proc;
	
	end generate port_stim;
	

	
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
	
	
	-- stimulus generation 
    watch_dog_proc :process
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
    end process watch_dog_proc;
	
	-- sets a system time-out to end simulation after 2500 us. 
	default_stop: process
	begin
		wait for 2500 us;
		
		report "sim timed out" severity failure;
		wait;
	end process default_stop;
    
	
	
	-- instantiate the RMAP router 
	router_inst: entity work.router_top_level_RTG4(rtl)
    generic map(
		g_clock_freq => c_tb_clock_freq,
                g_num_ports  => c_num_ports,
		g_is_fifo 	=> c_fifo_ports,
		g_mode		=> "single"
    )
	port map( 
	
		-- standard register control signals --
		router_clk				=>  clk_in			,	
	--	clk_in_b				=>  clk_in_b		,
		rst_in					=>  rst_in			,	
	--	enable  				=>  enable			,  
	
		DDR_din_r				=> 	open			,	
		DDR_din_f   			=> 	open			,  
		DDR_sin_r   			=> 	open			,  
		DDR_sin_f   			=> 	open			,  
		SDR_Dout				=> 	open			,
		SDR_Sout				=> 	open			,
		
		Din_p               	=>	Din_p,  
		Din_n               	=>  Din_n,  
		Sin_p               	=>  Sin_p,  
		Sin_n               	=>  Sin_n,  
		Dout_p              	=>  Dout_p, 
		Dout_n              	=>  Dout_n, 
		Sout_p              	=>  Sout_p, 
		Sout_n              	=>  Sout_n,  

		spw_fifo_in				=>	spw_fifo_in		,		
		spw_fifo_out			=>	spw_fifo_out		

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

		initiator_gen:	if(c_client_gen(i) = '1') generate
			initiator_inst:entity work.rmap_initiator_top_level(rtl)
			generic map(
				g_clock_freq		=>  c_tb_clock_freq,
				g_tx_fifo_size		=>  16,
				g_rx_fifo_size		=>  16,
				g_tx_fifo_interface	=> 	true,			-- generate Tx interface as Fifo ?
		        g_rx_fifo_interface	=>  true,			-- generate Rx interface as Fifo ?
				g_mode				=> 	"single"        -- Diff, Single or Custom. Use Custom and put DDR registers outside of core
			)
			port map( 
				-- Standard Register Channels --
				clock				=> 	clk_in,
				clock_b				=>	clk_in_b,
				rst_in				=>	rst_in,
				enable  			=>	enable,
				----------------------------------------------------------------------------------
				-- Time Code Channels --
				tx_time				=>	initiators(i).tx_time,
				tx_time_valid		=>	initiators(i).tx_time_valid,
				tx_time_ready		=>	initiators(i).tx_time_ready,

				rx_time				=>	initiators(i).rx_time,
				rx_time_valid		=>	initiators(i).rx_time_valid,
				rx_time_ready		=>  initiators(i).rx_time_ready,
				----------------------------------------------------------------------------------
				-- Tx Command Channels --
				tx_assert_path		=> 	initiators(i).tx_assert_path,
				tx_assert_char		=> 	initiators(i).tx_assert_char,
				tx_header			=>	initiators(i).tx_header,
				tx_header_valid		=>	initiators(i).tx_header_valid,
				tx_header_ready		=>	initiators(i).tx_header_ready,
				
				tx_data				=>	initiators(i).tx_data,
				tx_data_valid		=>  initiators(i).tx_data_valid,
				tx_data_ready		=>  initiators(i).tx_data_ready,
				----------------------------------------------------------------------------------
				-- Rx Reply Channels --
				rx_assert_char		=>	initiators(i).rx_assert_char,
				rx_header			=>	initiators(i).rx_header,
				rx_header_valid		=>  initiators(i).rx_header_valid,
				rx_header_ready 	=>  initiators(i).rx_header_ready,

				rx_data				=>	initiators(i).rx_data,
				rx_data_valid		=>  initiators(i).rx_data_valid,
				rx_data_ready 		=>  initiators(i).rx_data_ready,
				----------------------------------------------------------------------------------
				-- Tx Error Channels --
				tx_error			=>	initiators(i).tx_error,	
				tx_error_valid		=>	initiators(i).tx_error_valid,	
				tx_error_ready		=>  initiators(i).tx_error_ready,	
				----------------------------------------------------------------------------------
				-- Rx Error Channels --
				rx_error			=>	initiators(i).rx_error,			 
				rx_error_valid		=>  initiators(i).rx_error_valid,		
				rx_error_ready		=>  initiators(i).rx_error_ready,		
				----------------------------------------------------------------------------------
				spw_Rx_ESC_ESC      =>  initiators(i).spw_Rx_ESC_ESC,      
				spw_Rx_ESC_EOP      =>  initiators(i).spw_Rx_ESC_EOP,      
				spw_Rx_ESC_EEP      =>  initiators(i).spw_Rx_ESC_EEP,      
				spw_Rx_Parity_error =>  initiators(i).spw_Rx_Parity_error, 
				spw_Rx_bits         =>  initiators(i).spw_Rx_bits,         
				spw_Rx_rate         =>  initiators(i).spw_Rx_rate,         
				spw_Disable     	=>  initiators(i).spw_Disable,     	
				spw_Connected       =>  initiators(i).spw_Connected,       
				spw_Error_select    =>  initiators(i).spw_Error_select,    
				spw_Error_inject    =>  initiators(i).spw_Error_inject,   
				
				DDR_din_r			=>	open,
				DDR_din_f           =>	open,
				DDR_sin_r           =>	open,
				DDR_sin_f           =>	open,
				SDR_Dout			=>  open,
				SDR_Sout			=>  open,
				
				Din_p               =>	Dout_p(i), 
				Din_n               =>  Dout_n(i), 
				Sin_p               =>  Sout_p(i), 
				Sin_n               =>  Sout_n(i),  
				Dout_p              =>  Din_p(i), 
				Dout_n              =>  Din_n(i), 
				Sout_p              =>  Sin_p(i), 
				Sout_n              =>  Sin_n(i)  
				
			);
			initiators(i).rx_data_ready <= '1';
			initiators(i).rx_header_ready <= '1';
		else generate	-- generate targets on ports (use RMAP Target Full /w integrated SpaceWire CoDec 
			
			raw_gen: if(c_raw_gen(i) = '1') generate
				codec_inst: entity work.spw_wrap_top_level_RTG4(rtl)
				generic map(
					g_clock_frequency  	=> c_tb_clock_freq,			-- clock frequency for SpaceWire IP (>2MHz)
					g_rx_fifo_size     	=> 16,						-- must be >8
					g_tx_fifo_size     	=> 16, 						-- must be >8
					g_mode				=> "single"					-- valid options are "diff", "single" and "custom".
				)
				port map( 
					clock                => clk_in						,
		--			clock_b              =>	clk_in_b					,
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
			
			else generate
				target_inst: entity work.rmap_target_full(rtl)
				generic map(
					g_freq 			=> c_tb_clock_freq,
					g_fifo_depth 	=> 16,
					g_mode			=> "single"
				)
				port map( 
					
					clock              		=> 	clk_in,
					clock_b			   		=> 	clk_in_b,
					async_reset        		=> 	rst_in,
					reset              		=> 	rst_in,
					
					Rx_Time              	=>	targets(i).Rx_Time  			,  
					Rx_Time_OR           	=>	targets(i).Rx_Time_OR           ,
					Rx_Time_IR           	=>	targets(i).Rx_Time_IR           ,
				
					Tx_Time              	=>	targets(i).Tx_Time              ,
					Tx_Time_OR           	=>  targets(i).Tx_Time_OR           ,
					Tx_Time_IR           	=>  targets(i).Tx_Time_IR           ,
			
					Rx_ESC_ESC           	=>	targets(i).Rx_ESC_ESC           ,
					Rx_ESC_EOP           	=>  targets(i).Rx_ESC_EOP           ,
					Rx_ESC_EEP           	=>  targets(i).Rx_ESC_EEP           ,
					Rx_Parity_error      	=>  targets(i).Rx_Parity_error      ,
					Rx_bits              	=>  targets(i).Rx_bits              ,
					Rx_rate              	=>  targets(i).Rx_rate              ,

					Disable              	=>	targets(i).Disable              ,
					Connected            	=>  targets(i).Connected            ,
					Error_select         	=>  targets(i).Error_select         ,
					Error_inject         	=>  targets(i).Error_inject         ,
			
					-- SpW	     
					Din_p                	=>  Dout_p(i)                       ,
					Sin_p                	=>  Sout_p(i)                       ,
					Dout_p               	=>  Din_p(i)                        ,
					Sout_p               	=>  Sin_p(i)                        ,
			
					-- Memory Interface                                         
					Address           	 	=>	targets(i).Address              ,
					wr_en             	 	=>  targets(i).wr_en                ,
					Write_data        	 	=>  targets(i).Write_data           ,
					Bytes             	 	=>  targets(i).Bytes                ,
					Read_data         	 	=>  targets(i).Read_data            ,
					Read_bytes        	 	=>  targets(i).Bytes            	,
				
					-- Bus handshake                                            
					RW_request         		=>	targets(i).RW_request           ,
					RW_acknowledge     		=>  targets(i).RW_acknowledge       ,
					
					-- Control/Status                                           
					Echo_required      		=>	targets(i).Echo_required        ,
					Echo_port          		=>  targets(i).Echo_port            ,
				
					Logical_address    		=>	targets(i).Logical_address      ,
					Key                		=>  targets(i).Key                  ,
					Static_address     		=>  targets(i).Static_address       ,
					
					Checksum_fail      		=>	targets(i).Checksum_fail        ,
					
					Request            		=>	targets(i).Request              ,
					Reject_target      		=>  targets(i).Reject_target        ,
					Reject_key         		=>  targets(i).Reject_key           ,
					Reject_request     		=>  targets(i).Reject_request       ,
					Accept_request     		=>  targets(i).Accept_request       ,
				
					Verify_overrun     		=>	targets(i).Verify_overrun       ,
			
					OK                 		=>	targets(i).OK                   ,
					Done               		=>	targets(i).Done              
					
				);
				
				targets(i).Accept_request    	<= '1';
				targets(i).RW_acknowledge   	<= '1';
				
				target_ram_inst:entity work.xilinx_single_port_single_clock_ram(rtl) 
				generic map(
					ram_type	=> "auto",			-- ram type to infer (auto, distributed, block, register, ultra)
					data_width	=> 8,				-- bit-width of ram element
					addr_width	=> 8,				-- address width of RAM
					ram_str		=> "HELLO_WORLD"		
				)
				port map(
					-- standard register control signals --
					clk_in 		=> clk_in,											-- clock in (rising_edge)
					enable_in 	=> '1',										-- enable input (active high)
					
					wr_en		=> targets(i).wr_en,											-- write enable (asserted high)
					addr		=> targets(i).Address(7 downto 0),
					wr_data     => targets(i).Write_data,
					rd_data		=> targets(i).Read_data
				);
			
				
			end generate raw_gen;
		
		end generate initiator_gen;
		
		
		
	
	end generate ports_initiators_gen;
	
	

 
end bench;