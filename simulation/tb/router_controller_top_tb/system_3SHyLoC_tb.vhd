----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- verify the whole system function inlude the router, 3 SHyLoC
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	system_3SHyLoC_tb.vhd
-- @ Engineer				:	Rui
-- @ Date					: 	23.03.2025
-- @ Version				:	1.0
-- @ VHDL Version			:   2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

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

entity system_3SHyLoC_tb is
end system_3SHyLoC_tb;

architecture rtl of system_3SHyLoC_tb is
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
    signal rx_cmd_out : rx_cmd_out_array(1 to c_num_fifoports);
    signal rx_cmd_valid : std_logic_vector(1 to c_num_fifoports);
    signal rx_cmd_ready : std_logic_vector(1 to c_num_fifoports) := (others => '1');

    -- Data signals
    signal rx_data_out : rx_data_out_array(1 to c_num_fifoports);
    signal rx_data_valid : std_logic_vector(1 to c_num_fifoports);
    signal rx_data_ready : std_logic_vector(1 to c_num_fifoports) := (others => '1');

    -- CCSDS signals
    signal ccsds_datain : ccsds_datain_array(1 to c_num_fifoports);
    signal w_update : std_logic_vector(1 to c_num_fifoports) := (others => '0');
    signal asym_fifo_full : std_logic_vector(1 to c_num_fifoports);
--    signal ccsds_ready_ext : std_logic_vector(1 to c_num_fifoports);

    -- Data Interface signals
--    signal raw_ccsds_data : raw_ccsds_data_array(1 to c_num_fifoports);
    signal ccsds_datanewValid : std_logic_vector(1 to c_num_fifoports);

    -- Error signal
    signal spw_error : std_logic_vector(1 to c_num_fifoports);

    --shyloc record signals
    signal r_shyloc : shyloc_record_array(1 to c_num_fifoports);                                         -- define in system_constant_type
    --declare intermediate signals
    signal ready_signals : std_logic_vector(1 to c_num_fifoports);
    signal dataout_signals : ccsds_datain_array(1 to c_num_fifoports);
    signal dataout_newvalid_signals : std_logic_vector(1 to c_num_fifoports);
    signal ready_ext_signals : std_logic_vector(1 to c_num_fifoports);
    signal datain_signals : raw_ccsds_data_array(1 to c_num_fifoports);
    signal datain_newvalid_signals : std_logic_vector(1 to c_num_fifoports);

    -- SpaceWire Interface signals (using single mode)
    signal din_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal sin_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal dout_p : std_logic_vector(1 to g_num_ports-1);
    signal sout_p : std_logic_vector(1 to g_num_ports-1);

    -- create signal arrary for spw tx
    signal codecs               :       r_codec_interface_array(1 to c_num_ports-1);
    signal reset_spw            :       std_logic := '0';                                      -- activ high

	signal 	router_connected	: 		std_logic_vector(31 downto 1);

 --   signal   spw_codec  :  r_codec_interface;         -- define in spw_data_type
    ---------------------files------------------------
    type bin_file_type is file of character;
    file bin_file               : bin_file_type;
    file output_file            : bin_file_type;
    signal file_opened : boolean := false;

    signal   byte_value : std_logic := '0';                                                        --indicate read value high or low            
    --gen_stim datatx_state declaration
    type t_spw_tx_state is (
        IDLE, WAIT_CONNECTION, OPEN_FILE, SEND_ADDR, READ_FILE, SPW_TX, SEND_EOP, CLOSE_FILE
        );                                                         
    signal datatx_state : t_spw_tx_state := IDLE;                                                                  
    
    --------------------------------------------------------------------
    --! Testbench procedures
    --------------------------------------------------------------------

    procedure read_pixel_data(
        file     bin_file      : bin_file_type;
        variable data_out      : out std_logic_vector(work.ccsds123_tb_parameters.D_G_tb-1 downto 0);
        constant data_width    : in integer;
        constant endianness    : in integer
      ) is
        variable pixel_file    : character;
        variable value_high    : natural;
        variable value_low     : natural;
      begin
        -- read data depending on data width
        if data_width <= 8 then
          -- single byte data
          read(bin_file, pixel_file);
          value_high := character'pos(pixel_file);
          data_out := std_logic_vector(to_unsigned(value_high, data_width));
        else
          read(bin_file, pixel_file);
          value_high := character'pos(pixel_file);
          read(bin_file, pixel_file);
          value_low := character'pos(pixel_file);
          
          if endianness = 0 then
            -- 小端序
            data_out := std_logic_vector(to_unsigned(value_high, 8)) & 
                       std_logic_vector(to_unsigned(value_low, data_width-8));
          else
            -- 大端序
            data_out := std_logic_vector(to_unsigned(value_high, data_width-8)) & 
                       std_logic_vector(to_unsigned(value_low, 8));
          end if;
        end if;
    end procedure;

begin 
    reset_spw <= not rst_n;                 -- reset signal for SpW IP core
    -- Instantiate DUT using package constants

    gen_signals: for i in 1 to c_num_fifoports generate
        ready_signals(i)            <= r_shyloc(i).Ready;
        dataout_signals(i)          <= r_shyloc(i).DataOut;
        dataout_newvalid_signals(i) <= r_shyloc(i).DataOut_NewValid;

        r_shyloc(i).Ready_Ext       <= ready_ext_signals(i);
        r_shyloc(i).DataIn_shyloc   <= datain_signals(i);
        r_shyloc(i).DataIn_NewValid <= datain_newvalid_signals(i);
    end generate;

    DUT: entity work.router_fifo_ctrl_top_v2 
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
        rx_cmd_ready       => (others => '0'),
        rx_data_out        => rx_data_out,
        rx_data_valid      => rx_data_valid,
        rx_data_ready      => ready_signals,
        ccsds_datain       => dataout_signals,
        w_update           => dataout_newvalid_signals,
        asym_fifo_full     => open,
        ccsds_ready_ext    => ready_ext_signals,               --output

        raw_ccsds_data     => datain_signals,                  --output
        ccsds_datanewValid => datain_newvalid_signals,
        -- SpaceWire Interface
        din_p              => din_p,
        sin_p              => sin_p,
        dout_p             => dout_p,
        sout_p             => sout_p,

        spw_error          => spw_error,
        router_connected   => router_connected
    );
    
    --! Instantiate the SHyLoC_subtop component
    gen_SHyLoC: for i in 1 to c_num_fifoports generate
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
        DataIn_shyloc     => r_shyloc(i).DataIn_shyloc,
        DataIn_NewValid   => r_shyloc(i).DataIn_NewValid,
        
        -- Data Output Interface CCSDS121
        DataOut           => r_shyloc(i).DataOut,
        DataOut_NewValid  => r_shyloc(i).DataOut_NewValid,

        Ready_Ext         => r_shyloc(i).Ready_Ext,                  --input, external receiver not ready such external fifo is full
        
        -- CCSDS123 IP Core Interface
        ForceStop         => r_shyloc(i).ForceStop,
        AwaitingConfig    => r_shyloc(i).AwaitingConfig,
        Ready             => r_shyloc(i).Ready,                     --output, configuration received and IP ready for new samples
        FIFO_Full         => r_shyloc(i).FIFO_Full,
        EOP               => r_shyloc(i).EOP,
        Finished          => r_shyloc(i).Finished,
        Error             => r_shyloc(i).Error
    );
    end generate gen_SHyLoC;

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

    -- Stimulus process first SHyLoC
    gen_stim: process (clk) 
        -- File and data variables
        variable pixel_file : character;
        variable v_value_high : natural;
        variable v_value_low  : natural;
        variable s_in_var   : std_logic_vector(work.ccsds123_tb_parameters.D_G_tb-1 downto 0);            
        variable sample_count  : unsigned(31 downto 0) := (others => '0');
        variable total_samples : unsigned(31 downto 0);
        variable file_status   : file_open_status;
        variable route_addr    : std_logic_vector(8 downto 0);
        constant spw_port      : integer := 1;                       -- Use SpW port 1
        variable compress_cnt    : integer := 0;                       -- compress counter
        constant read_cycle      : integer := 1;                       -- compress times

    begin
        if rising_edge(clk) then
        -- Default signal settings
           codecs(1).Tx_OR <= '0';
            if rst_n = '0' then
                -- Reset state and variables
                datatx_state <= IDLE;
                sample_count := (others => '0');
    --            codecs(spw_port).Tx_data <= (others => '0');
                codecs(spw_port).Tx_OR <= '0';
                compress_cnt := 0;
            else 
            -- State machine
                case datatx_state is
                when IDLE =>
                    -- Initialize, prepare to start transmission
                    total_samples := to_unsigned(work.ccsds123_tb_parameters.Nx_tb * 
                                              work.ccsds123_tb_parameters.Ny_tb * 
                                              work.ccsds123_tb_parameters.Nz_tb*2, 32);
                    route_addr := '0' & std_logic_vector(to_unsigned(36, 8)); -- Assume router port 5
                    codecs(spw_port).Tx_OR <= '0';
                    if compress_cnt < read_cycle then
                        datatx_state <= WAIT_CONNECTION;
                        report "Initializing SpW transmission to router port 5" severity note;
                    else
                        report "All compressions completed" severity note;
                        datatx_state <= IDLE;
                    end if;

                when WAIT_CONNECTION =>
                    -- Wait for SpW link to be established
                    if codecs(spw_port).Connected = '1' and router_connected(spw_port) = '1' then
                        report "SpW port " & integer'image(spw_port) & " connected" severity note;
                        datatx_state <= OPEN_FILE;
                    end if;
                    
                when OPEN_FILE =>
                    -- Open file
                    file_open(file_status, bin_file, work.ccsds123_tb_parameters.stim_file, read_mode);
                    if file_status = open_ok then
                        log(ID_FILE_OPEN_CLOSE, "File opened successfully: " & work.ccsds123_tb_parameters.stim_file);
                        report "File opened successfully: " & work.ccsds123_tb_parameters.stim_file severity note;
                        datatx_state <= SEND_ADDR;
                    else
                        report "Unable to open file: " & work.ccsds123_tb_parameters.stim_file severity error;
                        datatx_state <= CLOSE_FILE;
                    end if;
                    
                    when SEND_ADDR =>

                        if r_shyloc(1).Ready = '1' then
                            -- Send the router address
                            codecs(spw_port).Tx_data <= route_addr;
                            if codecs(spw_port).Tx_IR = '1' then
                            codecs(spw_port).Tx_OR <= '1';
                            end if;
                            if codecs(spw_port).Tx_IR = '1' and codecs(spw_port).Tx_OR = '1'then
                            codecs(spw_port).Tx_OR <= '0';
                            report "Sent routing address: " & to_string(route_addr) severity note;
                            datatx_state <= READ_FILE;
                            end if;
                        end if;
                  
                        when READ_FILE =>
                            if r_shyloc(1).Finished = '1' or r_shyloc(1).ForceStop = '1' then
                                report "Early termination requested" severity note;
                                datatx_state <= SEND_EOP;
    
                            -- Read and send next sample when ready
                            elsif r_shyloc(1).Ready = '1' and r_shyloc(1).AwaitingConfig = '0' then
                                if (work.ccsds123_tb_parameters.D_G_tb <= 8) then               
                                    -- Read data from file based on data width
                                    read_pixel_data(bin_file, s_in_var, work.ccsds123_tb_parameters.D_G_tb, 0);

                                    codecs(spw_port).Tx_data <= '0' & s_in_var;
                                    report "Sent sample " & integer'image(to_integer(sample_count)) & ": " & to_string(s_in_var) severity note;                                       
                                    datatx_state <= SPW_TX;
                                else
                                    if byte_value = '0' then  
                                        read_pixel_data(bin_file, s_in_var, work.ccsds123_tb_parameters.D_G_tb, 0);
                                        codecs(spw_port).Tx_data <= '0' & s_in_var(15 downto 8);
                                        byte_value <= '1';
                                        datatx_state <= SPW_TX;
                                    else 
                                        codecs(spw_port).Tx_data <= '0' & s_in_var(7 downto 0);
                                        byte_value <= '0';
                                        report "Sent sample " & integer'image(to_integer(sample_count)) & ": " & to_string(s_in_var) severity note;
                                        datatx_state <= SPW_TX;
                                    end if;
                                end if;
                            end if;   

                        when SPW_TX =>
                            if codecs(spw_port).Tx_IR = '1' then
                                codecs(spw_port).Tx_OR <= '1';
                            end if; 
                            
                            if codecs(spw_port).Tx_IR = '1' and codecs(spw_port).Tx_OR = '1' then
                                codecs(spw_port).Tx_OR <= '0';
                                sample_count := sample_count + 1;
                                if sample_count >= total_samples then
                                    report "All samples processed: " & integer'image(to_integer(sample_count)) severity note;
                                    datatx_state <= SEND_EOP;
                                else
                                    datatx_state <= READ_FILE;
                                end if;
                            end if;

                        when SEND_EOP =>
                        -- Send End-of-Packet marker

                        if codecs(spw_port).Tx_IR = '1' then
                            codecs(spw_port).Tx_data <= "100000010";  -- EOP
                            codecs(spw_port).Tx_OR <= '1';
                            report "Transmission complete, sending EOP" severity note;                      
                        end if;
                        if codecs(spw_port).Tx_IR = '1' and codecs(spw_port).Tx_OR = '1' then
                            codecs(spw_port).Tx_OR <= '0';
                            datatx_state <= CLOSE_FILE;
                        end if;
                    
                        when CLOSE_FILE =>
                        -- Close file and return to idle
                        if codecs(spw_port).Tx_OR = '1' then
                            codecs(spw_port).Tx_OR <= '0';
                        else
                            file_close(bin_file);
                            report "File closed, sent " & to_string(sample_count) & " samples" severity note;
                            datatx_state <= IDLE;
                            compress_cnt := compress_cnt + 1;
                        end if;
                    end case;
                end if;
        end if;
    end process;

    write_pixel_data_process: process(clk)
        variable ini        : integer := 0;
        variable fin        : integer := 0;
        variable error_f    : integer := 1;
        variable probe      : std_logic_vector(7 downto 0);
        variable uns        : unsigned(7 downto 0);
        variable int        : integer;
        variable pixel_file : character;
        variable size       : integer;
        variable status     : FILE_OPEN_STATUS;
    begin
        if rising_edge(clk) then
            -- Handle reset condition
            if reset_n_s = '0' then
                ini := 0;
                fin := 0;
            -- Handle force stop condition
            elsif r_shyloc(1).ForceStop = '1' then
                assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
                file_close(output_file);
                ini := 0;
                fin := 0;
                error_f := 0;
            -- Handle error condition
            elsif r_shyloc(1).Error = '1' then
                if error_f = 1 then
                    assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
                    file_close(output_file);
                    ini := 0;
                    fin := 0;
                    error_f := 0;
                end if;
            else
                -- Process valid data
                if r_shyloc(1).DataOut_NewValid = '1' and r_shyloc(1).AwaitingConfig = '0' then
                    -- Initialize file if first time
                    if ini = 0 then
                        file_open(status, output_file, work.ccsds123_tb_parameters.out_file, write_mode);
                        report "Output file opened successfully: " & work.ccsds123_tb_parameters.out_file severity note;
                        ini := 1;
                        fin := 1;
                    end if;
                    
                    -- Determine buffer size
                    if work.ccsds123_tb_parameters.EN_RUNCFG_G = 1 then
                        size := work.ccsds121_tb_parameters.W_BUFFER_tb;
                    else
                        size := work.ccsds121_tb_parameters.W_BUFFER_G_tb;
                    end if;
                    
                    -- Write data to file byte by byte
                    for i in 0 to (size/8) - 1 loop
                        probe := r_shyloc(1).DataOut((((size/8) - 1 - i) + 1) * 8 - 1 downto ((size/8) - 1 - i) * 8);
                        uns := unsigned(probe);
                        int := to_integer(uns);
                        pixel_file := character'val(int);
                        write(output_file, pixel_file);
                    end loop;
                end if;
                
                -- Handle completion
                if r_shyloc(1).Finished = '1' then
                    if fin = 1 then
                        assert false report "Compression has been done and written to file" severity note;
                        file_close(output_file);
                        ini := 0;
                        fin := 0;
                        error_f := 0;
                    end if;
                end if;
            end if;
        end if;
    end process write_pixel_data_process;
   
    stim_sequencer: process
    variable file_write_status : file_open_status;                --write file status
    begin 
        set_log_file_name("datatransfer.txt");

        reset_n_s <= '0';
        r_shyloc(1).ForceStop <= '0';                                              -- default value
        wait until (codecs(1).Connected = '1' and router_connected(1) = '1');	-- wait for SpW instances to establish connection, make sure Spw link is connected
        report "SpW port_1 Uplink Connected !" severity note;

        reset_n_s <= '1';

        set_log_file_name("router_fifo_ctrl_log.txt");
        set_alert_file_name("router_fifo_ctrl_alert.txt");

        log(ID_LOG_HDR, "transmit data from port 1 and receive the same data through port2");
        log(ID_LOG_HDR, "Test1 completed");
        wait;
        wait until r_shyloc(1).Finished = '1';
        assert false report "**** system Testbench done ****" severity note; 
        stop(0);
        wait;
    end process;


end rtl;