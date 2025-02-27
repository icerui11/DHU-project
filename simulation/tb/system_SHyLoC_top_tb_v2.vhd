----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- verify the whole system function inlude the router, SHyLoC
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	system_SHyLoC_top_tb_v2.vhd
-- @ Engineer				:	Rui
-- @ Date					: 	26.02.2024
-- @ Version				:	1.0
-- @ VHDL Version			:   2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library shyloc_121;
use work.ccsds121_tb_parameters.all;

library shyloc_123; 
use work.ccsds123_tb_parameters.all;

context work.router_context;

library work;
use work.system_constant_pckg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

entity system_SHyLoC_top_tb_v2 is
end system_SHyLoC_top_tb_v2;

architecture rtl of system_SHyLoC_top_tb_v2 is
    -- Constants
    constant clk_period   : time    := 10 ns;
    constant g_num_ports  : natural range 1 to 32 := c_num_ports ;      --  defined in package    
    constant g_data_width : integer := 8;
    constant g_addr_width : integer := 9;
    
    --spw Constants
    constant c_clock_frequency 	: 		real      	:=  100_000_000.0;	-- clock frequency (in Hz)
	constant c_rx_fifo_size    	: 		integer   	:=  56;				-- number of SpW packets in RX fifo
	constant c_tx_fifo_size    	: 		integer   	:=  56;				-- number of SpW packets in TX fifo
	constant c_mode				: 		string 		:= "single";

    -- Component signals
    signal rst_n : std_logic := '0';
    signal clk : std_logic := '0';
    
    -- DUT signals
    signal reset_n_s : std_logic := '0';

    -- Control signals
    signal rx_cmd_out : std_logic_vector(2 downto 0);
    signal rx_cmd_valid : std_logic;
    signal rx_cmd_ready : std_logic := '1';
    
    -- Data signals
    signal rx_data_out : std_logic_vector(7 downto 0);
    signal rx_data_valid : std_logic;
    signal rx_data_ready : std_logic := '1';

    -- CCSDS signals
    signal ccsds_datain  : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal w_update      : std_logic := '0';
    signal asym_fifo_full : std_logic;
    signal ccsds_ready_ext : std_logic;
    signal tx_ir_fifo_rupdata : std_logic;
    --shyloc record signals
    signal r_shyloc : shyloc_record;                                         -- define in system_constant_type
    
    -- Data Interface signals
    signal data_in_shyloc     : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_newvalid   : std_logic;
    signal data_out_shyloc    : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_newvalid  : std_logic;

    -- SpaceWire Interface signals (using single mode)
    signal din_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal sin_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal dout_p : std_logic_vector(1 to g_num_ports-1);
    signal sout_p : std_logic_vector(1 to g_num_ports-1);
    
    signal spw_error : std_logic;

    -- create signal arrary for spw tx
    signal codecs               :       r_codec_interface_array(1 to c_num_ports-1) := (others => c_codec_interface);
    signal reset_spw            :       std_logic := '0';                                      -- activ high
	
	signal 	spw_debug_tx		: 		std_logic_vector(8 downto 0)	:= (others => '0');
	signal 	spw_debug_raw		: 		std_logic_vector(13 downto 0)	:= (others => '0');
	signal 	spw_debug_parity	: 		std_logic;
	signal 	spw_debug_cmd		: 		string(1 to 3);
	signal 	spw_debug_time		: 		std_logic_vector(7 downto 0) 	:= (others => '0');

	signal 	router_connected	: 		std_logic_vector(31 downto 1);

    --! Testbench signals
    signal s                    : std_logic_vector (work.ccsds123_tb_parameters.D_G_tb-1 downto 0);
    signal s_valid              : std_logic;
    signal sign: std_logic;
    signal counter: unsigned(1 downto 0);
    signal counter_samples: unsigned (31 downto 0);

    signal   spw_codec  :  r_codec_interface;         -- define in spw_data_type
    ---------------------files------------------------
    type bin_file_type is file of character;
    file bin_file               : bin_file_type;
    file output                 : bin_file_type;
    --gen_stim state declaration
    type t_spw_tx_state is (
        IDLE, WAIT_CONNECTION, OPEN_FILE, SEND_ADDR, READ_AND_SEND, SEND_EOP, CLOSE_FILE
        );
    signal state : t_spw_tx_state := IDLE;

    --declaration the same state type in testbench
    type t_states is (fsm_ready, addr_send, read_mem, spw_tx, ramaddr_delay, eop_tx);
    signal router_ctrl_state : t_states; 
    
    --alias name
    alias router_fifo_debug_rx  is  
       << signal .system_SHyLoC_top_tb_v2.DUT.router_inst.spw_fifo_in : r_fifo_master_array(1 to g_num_ports-1)>>; 
    
    --alias name for testcase2
    alias port1_rx_data is 
       <<signal .system_SHyLoC_top_tb_v2.DUT.router_inst.gen_ports(1).gen_spw.gen_fifo.spw_port_inst.Rx_data : std_logic_vector(8 downto 0)>>;
    --------------------------------------------------------------------
    --! Testbench procedures
    --------------------------------------------------------------------

    procedure monitor_data is
    begin
    end monitor_data;

begin
    
    reset_spw <= not rst_n;                 -- reset signal for SpW IP core
    -- Instantiate DUT using package constants

    DUT: entity work.router_fifo_ctrl_top 
    generic map(
        g_num_ports        => g_num_ports,
        g_data_width       => g_data_width,
        g_addr_width       => g_addr_width
    )
    port map(
        rst_n              => rst_n,
        clk                => clk,
        rx_cmd_out         => open,
        rx_cmd_valid       => open,
        rx_cmd_ready       => '0',
        rx_data_out        => rx_data_out,
        rx_data_valid      => rx_data_valid,
        rx_data_ready      => r_shyloc.Ready,                      -- from SHyLoC
        ccsds_datain       => data_out_shyloc,            -- output data from SHyLoC 32-bit
        w_update           => data_out_newvalid,          -- write update signal
        asym_fifo_full     => open,
        ccsds_ready_ext    => ccsds_ready_ext,

        -- SpaceWire Interface
        din_p              => din_p,
        sin_p              => sin_p,
        dout_p             => dout_p,
        sout_p             => sout_p,

        spw_error          => spw_error,
        router_connected   => router_connected
    );
    
    --! Instantiate the SHyLoC_subtop component
    ShyLoc_top_inst : entity work.ShyLoc_top_Wrapper(arch)
    port map(
        -- System Interface
        Clk_S             => clk,                    
        Rst_N             => reset_n_s,                   -- differe from reset_n
        
        -- Amba Interface
        AHBSlave121_In    => C_AHB_SLV_IN_ZERO,          --declared in router_package.vhd
        Clk_AHB           => clk,                  
        Reset_AHB         => reset_n_s,          
        AHBSlave121_Out   => open,
        
        -- AHB 123 Interfaces
        AHBSlave123_In    => C_AHB_SLV_IN_ZERO,
        AHBSlave123_Out   => open,
        AHBMaster123_In   => C_AHB_MST_IN_ZERO,
        AHBMaster123_Out  => open,
        
        -- Data Input Interface
        DataIn_shyloc     => rx_data_out,
        DataIn_NewValid   => rx_data_valid,
        
        -- Data Output Interface CCSDS121
        DataOut           => data_out_shyloc,
        DataOut_NewValid  => data_out_newvalid,

        Ready_Ext         => ccsds_ready_ext,           --input, external receiver not ready such external fifo is full
        
        -- CCSDS123 IP Core Interface
        ForceStop         => r_shyloc.ForceStop,
        AwaitingConfig    => r_shyloc.AwaitingConfig,
        Ready             => r_shyloc.Ready,                     --output, configuration received and IP ready for new samples
        FIFO_Full         => r_shyloc.FIFO_Full,
        EOP               => r_shyloc.EOP,
        Finished          => r_shyloc.Finished,
        Error             => r_shyloc.Error
    );

    gen_dut_tx: for i in 1 to g_num_ports-1 generate
      gen_spw_tx: if c_fifo_ports(i) = '0' generate
       SPW_inst: entity work.spw_wrap_top_level_RTG4(rtl)
        generic map(
            g_clock_frequency   =>	c_clock_frequency,  
            g_rx_fifo_size      =>  c_rx_fifo_size,      
            g_tx_fifo_size      =>  c_tx_fifo_size,      
            g_mode				=>  c_mode				
        )
        port map( 
            clock                => clk 						,
            reset                =>	reset_spw    				,

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
            Din_p                => dout_p(i)             		,
            Sin_p                => sout_p(i)          			,
            Dout_p               => din_p(i)          			,
            Sout_p               => sin_p(i)          					         
        );
        codecs(i).Rx_IR <= '1';
        codecs(i).Rx_Time_IR <= '1';

        end generate gen_spw_tx;
    end generate gen_dut_tx;

    -- Clock process
    clk_proc: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    --------------------------------------------------------------------
    --! reset signal generation
    --------------------------------------------------------------------
    gen_rst: process
    begin
        -- Initial reset
        rst_n <= '0';
        wait for 16.456 us;								-- wait for > 500us before de-asserting reset
        rst_n <= '1';
        wait;
    end process;

    -- Stimulus process
    gen_stim: process (clk, rst_n)
    
        -- File and data variables
        variable pixel_file : character;
        variable value_high : natural;
        variable value_low  : natural;
        variable s_in_var   : std_logic_vector(work.ccsds123_tb_parameters.D_G_tb-1 downto 0);
        variable sample_count  : unsigned(31 downto 0) := (others => '0');
        variable total_samples : unsigned(31 downto 0);
        variable file_status   : file_open_status;
        variable route_addr    : std_logic_vector(8 downto 0);
        constant spw_port      : integer := 1;                       -- Use SpW port 1

    begin
        if rst_n = '0' then
            -- Reset state and variables
            state <= IDLE;
            sample_count := (others => '0');
            codecs(spw_port).Tx_data <= (others => '0');
            codecs(spw_port).Tx_OR <= '0';
            
        elsif rising_edge(clk) then
            -- Default signal settings
            spw_codec.Tx_IR <= '0';
            
            -- State machine
            case state is
                when IDLE =>
                    -- Initialize, prepare to start transmission
                    total_samples := to_unsigned(work.ccsds123_tb_parameters.Nx_tb * 
                                              work.ccsds123_tb_parameters.Ny_tb * 
                                              work.ccsds123_tb_parameters.Nz_tb + 4, 32);
                    route_addr := '0' & std_logic_vector(to_unsigned(5, 8)); -- Assume router port 5
                    state <= WAIT_CONNECTION;
                    report "Initializing SpW transmission to router port 5" severity note;

                when WAIT_CONNECTION =>
                    -- Wait for SpW link to be established
                    if codecs(spw_port).Connected = '1' and router_connected(spw_port) = '1' then
                        report "SpW port " & integer'image(spw_port) & " connected" severity note;
                        state <= OPEN_FILE;
                    end if;
                    
                when OPEN_FILE =>
                    -- Open file
                    file_open(file_status, bin_file, work.ccsds123_tb_parameters.stim_file, read_mode);
                    if file_status = open_ok then
                        report "File opened successfully: " & work.ccsds123_tb_parameters.stim_file severity note;
                        state <= SEND_ADDR;
                    else
                        report "Unable to open file: " & work.ccsds123_tb_parameters.stim_file severity error;
                        state <= CLOSE_FILE;
                    end if;
                    
                    when SEND_ADDR =>
                        -- Send the router address
                        if codecs(spw_port).Tx_IR = '1' then
                          codecs(spw_port).Tx_OR <= '1';
                        end if;
                        if codecs(spw_port).Tx_IR = '1' and codecs(spw_port).Tx_OR = '1'then
                          codecs(spw_port).Tx_data <= route_addr;
                          codecs(spw_port).Tx_OR <= '0';
                          report "Sent routing address: " & to_string(route_addr) severity note;
                          state <= READ_AND_SEND;
                        end if;
                    
                    when READ_AND_SEND =>
                        if codecs(spw_port).Tx_IR = '1' then
                            codecs(spw_port).Tx_OR <= '1';
                        end if;

                        -- Check termination conditions
                        if r_shyloc.Finished = '1' or r_shyloc.ForceStop = '1' then
                            report "Early termination requested" severity note;
                            state <= SEND_EOP;
                        elsif sample_count >= total_samples then
                            report "All samples processed: " & to_string(sample_count) severity note;
                            state <= SEND_EOP;
                        -- Read and send next sample when ready
                        elsif codecs(spw_port).Tx_IR = '1' and codecs(spw_port).Tx_OR = '1'then
                            codecs(spw_port).Tx_OR <= '0';

                          if r_shyloc.Ready = '1' and r_shyloc.AwaitingConfig = '0' and codecs(spw_port).Tx_IR = '1' then
                            -- Read data from file based on data width
                            if work.ccsds123_tb_parameters.D_G_tb <= 8 then
                            read(bin_file, pixel_file);
                            value_high := character'pos(pixel_file);
                            s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb));
                            else
                            -- Handle multi-byte data with proper endianness
                            read(bin_file, pixel_file);
                            value_high := character'pos(pixel_file);
                            read(bin_file, pixel_file);
                            value_low := character'pos(pixel_file);
                            
                                if work.ccsds123_tb_parameters.ENDIANESS_tb = 0 then
                                    -- Little endian
                                    s_in_var := std_logic_vector(to_unsigned(value_high, 8)) & 
                                                std_logic_vector(to_unsigned(value_low, work.ccsds123_tb_parameters.D_G_tb-8));
                                else
                                    -- Big endian
                                    s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb-8)) & 
                                                std_logic_vector(to_unsigned(value_low, 8));
                                end if;
                            end if;
                            
                            -- Send data through SpW port
                            codecs(spw_port).Tx_data <= '0' & s_in_var;
                            codecs(spw_port).Tx_OR <= '1';
                            sample_count := sample_count + 1;
                            
                            -- Log progress periodically
                            if sample_count mod 1000 = 0 then
                            report "Sent " & to_string(sample_count) & " / " & 
                                    to_string(total_samples) & " samples" severity note;
                            end if;
                        end if;
                        
                        when SEND_EOP =>
                        -- Send End-of-Packet marker
                        if codecs(spw_port).Tx_OR = '1' then
                            codecs(spw_port).Tx_OR <= '0';
                        elsif codecs(spw_port).Tx_IR = '1' then
                            codecs(spw_port).Tx_data <= "100000010";  -- EOP
                            codecs(spw_port).Tx_OR <= '1';
                            report "Transmission complete, sending EOP" severity note;
                            state <= CLOSE_FILE;
                        end if;
                        
                        when CLOSE_FILE =>
                        -- Close file and return to idle
                        if codecs(spw_port).Tx_OR = '1' then
                            codecs(spw_port).Tx_OR <= '0';
                        else
                            file_close(bin_file);
                            report "File closed, sent " & to_string(sample_count) & " samples" severity note;
                            state <= IDLE;
                        end if;
                    end case;
        end if;
    end process;

    stim_sequencer: process
    procedure test1 is 
        begin 
          -- Test Case 1: Send raw 8-bit data through gen_spw_tx port 1
          wait until (codecs(1).Connected = '1' and router_connected(1) = '1');	-- wait for SpW instances to establish connection, make sure Spw link is connected
          report "SpW port_1 Uplink Connected !" severity note;
  
          wait for 3.532 us;	
          -- load Tx data to send --
          if(codecs(1).Tx_IR = '0') then
              wait until codecs(1).Tx_IR = '1';
          end if;
  
           wait for clk_period;
          codecs(1).Tx_data  <= "000000010";						-- Load TX SpW Data port 1, first data as path address
          codecs(1).Tx_OR <= '1';									-- set Tx Data OR port
          wait for clk_period;							    -- wait for data to be clocked in
          report "SpW Data Loaded : " & to_string(codecs(1).Tx_data) severity note;
          codecs(1).Tx_OR <= '0';									-- de-assert TxOR
          
          wait for clk_period;
          codecs(1).Tx_data  <= "011110100";						-- Load TX SpW Data port 1, first data as path address
          codecs(1).Tx_OR <= '1';									-- set Tx Data OR port
          report "SpW Data Loaded : " & to_string(codecs(1).Tx_data) severity note;
  
          if codecs(2).Rx_data = "011110100" and codecs(2).Rx_OR = '1' then
              assert false
              report "router port2 has successfully transmit data and spw receive data: " & to_string(codecs(2).Rx_data)
              severity note;
          end if;
  
          wait for clk_period;							    -- wait for data to be clocked in
          codecs(1).Tx_OR <= '0';	
  
          -- Wait for data processing
          wait for clk_period*5;
  
          --bind the state signal to the state of router controller
          router_ctrl_state <= <<signal .system_SHyLoC_top_tb_v2.DUT.gen_fifo_controller(5).gen_ctrl.router_fifo_ctrl_inst.s_state : t_states>>;
          if router_ctrl_state = addr_send then
          assert false
              report "router send port1 address:" & to_string(router_fifo_debug_rx(5).rx_data)
              severity note; 
          end if;
        end test1;
        
        procedure test2 is
        begin 	
          wait until (clk'event and clk = '1') and router_connected(5) = '1' and router_connected(1) = '1';	-- because the fifo_in data is come from other router spw port
          assert false
              report "router port5 is connected" severity note;
          wait for 3 us;
          -- Test Case 2: Send 32-bit compressed data
          ccsds_datain <= x"00000700";  -- Example 32-bit compressed data
          w_update <= '1';
          report "CCSDS Data Loaded : " & to_string(ccsds_datain) severity note;
          wait for clk_period;
          w_update <= '0';
          wait for clk_period;
          ccsds_datain <= x"08000510";  -- Example 32-bit compressed data
          w_update <= '1';
          wait for clk_period;
          w_update <= '0';
          wait for clk_period;
          ccsds_datain <= x"00051400";  -- Example 32-bit compressed data
          w_update <= '1';
          wait for clk_period;
          w_update <= '0';
          wait for clk_period;
          ccsds_datain <= x"1800f70f";  -- Example 32-bit compressed data
          w_update <= '1';
          wait for clk_period;
          w_update <= '0';
          
          -- Wait for FIFO processing
          wait until asym_fifo_full = '0';
          wait for clk_period*5;
        end test2;

    begin 


        wait for 100 ns; 
        
        set_log_file_name("router_fifo_ctrl_log.txt");
        set_alert_file_name("router_fifo_ctrl_alert.txt");
       -- test1;
        log(ID_LOG_HDR, "transmit data from port 1 and receive the same data through port2");
        log(ID_LOG_HDR, "Test1 completed");
        wait;
        -- test2;   
        -- Wait for error conditions

        wait until spw_error = '0';
    end process;
end rtl;