library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_121;
use shyloc_121.ccsds121_parameters.all;

library smartfusion2;
use smartfusion2.all;

context work.router_context;

entity router_fifo_ctrl_top_tb is
end router_fifo_ctrl_top_tb;

architecture tb of router_fifo_ctrl_top_tb is

    -- Constants
    constant clk_period   : time := 10 ns;
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
    
    -- Control signals
    signal rx_cmd_out : std_logic_vector(2 downto 0);
    signal rx_cmd_valid : std_logic;
    signal rx_cmd_ready : std_logic := '1';
    
    -- Data signals
    signal rx_data_out : std_logic_vector(7 downto 0);
    signal rx_data_valid : std_logic;
    signal rx_data_ready : std_logic := '1';
    signal ram_enable_tx : std_logic;

    -- CCSDS signals
    signal ccsds_datain : std_logic_vector(W_BUFFER_GEN-1 downto 0);
    signal w_update : std_logic := '0';
    signal asym_fifo_full : std_logic;
    signal ccsds_ready_ext : std_logic;
    signal tx_ir_fifo_rupdata : std_logic;

    -- SpaceWire Interface signals (using single mode)
    signal din_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal din_n  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal sin_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal sin_n  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal dout_p : std_logic_vector(1 to g_num_ports-1);
    signal dout_n : std_logic_vector(1 to g_num_ports-1);
    signal sout_p : std_logic_vector(1 to g_num_ports-1);
    signal sout_n : std_logic_vector(1 to g_num_ports-1);
    
    signal spw_error : std_logic;

    -- create signal arrary for spw tx
    signal codecs                 : r_codec_interface_array(1 to c_num_ports-1) := (others => c_codec_interface);
    signal reset_spw                                      :       std_logic := '0';           -- activ high
/*
    --spw signals

    -- Channels
    signal    Tx_Data_spw         , Tx_Data_2_spw            :       nonet;                      -- 9 bits of Tx Data (data to send)  
    signal    Tx_OR_spw           , Tx_OR_2_spw              :       std_logic;                    -- Tx data Output Ready           
    signal    Tx_IR_spw           , Tx_IR_2_spw              :       std_logic;                    -- Tx data Input Ready             
    
    signal    Rx_Data_spw         , Rx_Data_2_spw            :       nonet;                      -- 9 bits of Rx Data (data received)  
    signal    Rx_OR_spw           , Rx_OR_2_spw              :       std_logic;                    -- Rx data Output Ready            
    signal    Rx_IR_spw           , Rx_IR_2_spw              :       std_logic;                    -- Rx data Input Ready 

    signal    Rx_ESC_ESC_spw      , Rx_ESC_ESC_2_spw         :       std_logic;                    
    signal    Rx_ESC_EOP_spw      , Rx_ESC_EOP_2_spw         :       std_logic;                    
    signal    Rx_ESC_EEP_spw      , Rx_ESC_EEP_2_spw         :       std_logic;                    
    signal    Rx_Parity_Error_spw  , Rx_Parity_Error_2_spw    :       std_logic;                    
    signal    Rx_Bits_spw         , Rx_Bits_2_spw            :       std_logic_vector(1 downto 0);      
    signal    Rx_Rate_spw         , Rx_Rate_2_spw            :       std_logic_vector(15 downto 0) := (others => '0');  
    
    signal    Rx_Time_spw         , Rx_Time_2_spw            :       octet;                      
    signal    Rx_Time_OR_spw      , Rx_Time_OR_2_spw         :       std_logic;                    
    signal    Rx_Time_IR_spw      , Rx_Time_IR_2_spw         :       std_logic;                    
    
    signal    Tx_Time_spw         , Tx_Time_2_spw            :       octet;                      
    signal    Tx_Time_OR_spw      , Tx_Time_OR_2_spw         :       std_logic;                    
    signal    Tx_Time_IR_spw      , Tx_Time_IR_2_spw         :       std_logic;          
	
    -- Control		             
	signal	Disable         ,Disable_2            :  		std_logic;
	signal	Connected       ,Connected_2          :  		std_logic;
	signal	Error_select    ,Error_select_2       :  		std_logic_vector(3 downto 0) := (others => '0');
	signal	Error_inject    ,Error_inject_2       :  		std_logic;

	-- SpW Ports, Init low. 
    signal    Din_p_spw           :       std_logic := '0';
    signal    Din_n_spw           :       std_logic := '0';
    signal    Sin_p_spw           :       std_logic := '0';
    signal    Sin_n_spw           :       std_logic := '0';
    signal    Dout_p_spw          :       std_logic := '0';
    signal    Dout_n_spw          :       std_logic := '0';
    signal    Sout_p_spw          :       std_logic := '0';
    signal    Sout_n_spw          :       std_logic := '0';
 */   
	
	signal 	spw_debug_tx		: 		std_logic_vector(8 downto 0)	:= (others => '0');
	signal 	spw_debug_raw		: 		std_logic_vector(13 downto 0)	:= (others => '0');
	signal 	spw_debug_parity	: 		std_logic;
	signal 	spw_debug_cmd		: 		string(1 to 3);
	signal 	spw_debug_time		: 		std_logic_vector(7 downto 0) 	:= (others => '0');
	
	signal 	router_connected	: 		std_logic_vector(31 downto 1);

    --declaration the same state type in testbench
    type t_states is (ready, addr_send, read_mem, spw_tx, ramaddr_delay, eop_tx);
    signal router_ctrl_state : t_states; 

begin
    
    reset_spw <= not rst_n;                 -- reset signal for SpW IP core
    -- Instantiate DUT using package constants
    DUT: entity work.router_fifo_ctrl_top 
    generic map(
        g_num_ports => g_num_ports,
        g_data_width => g_data_width,
        g_addr_width => g_addr_width
    )
    port map(
        rst_n              => rst_n,
        clk                => clk,
        rx_cmd_out         => rx_cmd_out,
        rx_cmd_valid       => rx_cmd_valid,
        rx_cmd_ready       => rx_cmd_ready,
        rx_data_out        => rx_data_out,
        rx_data_valid      => rx_data_valid,
        rx_data_ready      => rx_data_ready,
        ram_enable_tx      => ram_enable_tx,
        ccsds_datain       => ccsds_datain,
        w_update           => w_update,
        asym_fifo_full     => asym_fifo_full,
        ccsds_ready_ext    => ccsds_ready_ext,
        tx_ir_fifo_rupdata => tx_ir_fifo_rupdata,
        
        -- SpaceWire Interface
        din_p  => din_p,
        din_n  => din_n,
        sin_p  => sin_p,
        sin_n  => sin_n,
        dout_p => dout_p,
        dout_n => dout_n,
        sout_p => sout_p,
        sout_n => sout_n,
        spw_error => spw_error,
        router_connected => router_connected
    );
    

    --signal mapping for router_top
 --   din_p(1) <= Dout_p_spw;
 --   sin_p(1) <= Sout_p_spw;

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

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        rst_n <= '0';
        wait for 16.456 us;								-- wait for > 500us before de-asserting reset
        rst_n <= '1';
        wait for clk_period;
        
        -- Test Case 1: Send raw 8-bit data through gen_spw_tx port 1
        wait until (codecs(1).Connected = '1' and router_connected(1) = '1');	-- wait for SpW instances to establish connection, make sure Spw link is connected
		report "SpW port_1 Uplink Connected !" severity note;

		wait for 3.532 us;
		
		-- load Tx data to send --
		if(codecs(1).Tx_IR = '0') then
			wait until codecs(1).Tx_IR = '1';
		end if;

 		wait for clk_period;
		codecs(1).Tx_data  <= "001010110";						-- Load TX SpW Data port 1
		codecs(1).Tx_OR <= '1';									-- set Tx Data OR port
		wait for clk_period;							    -- wait for data to be clocked in
		report "SpW Data Loaded : " & to_string(codecs(1).Tx_data) severity note;
		codecs(1).Tx_OR <= '0';									-- de-assert TxOR
        
        -- Wait for data processing
        wait for clk_period*5;
        --bind the state signal to the state of router controller
        router_ctrl_state <= <<signal .router_fifo_ctrl_top_tb.DUT.gen_fifo_controller(2).gen_ctrl.router_fifo_ctrl_inst.s_state : t_states>>;
        assert router_ctrl_state = addr_send
            report "State check: router send port1 address"
            severity note; 
        
        -- Test Case 2: Send 32-bit compressed data
        ccsds_datain <= x"00000700";  -- Example 32-bit compressed data
        w_update <= '1';
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
   /*     
        -- Test Case 3: Test FIFO full condition
        for i in 0 to 5 loop
            ccsds_datain <= std_logic_vector(to_unsigned(i, W_BUFFER_GEN));
            w_update <= '1';
            wait for clk_period;
            w_update <= '0';
            wait for clk_period*2;
        end loop;
    */    
        -- Wait for error conditions
        wait until spw_error = '0';
        
        -- End simulation
        wait for clk_period*100;
        report "Simulation completed successfully";
        wait;
    end process;

    -- Monitor process
    mon_proc: process
    begin
        wait until rising_edge(clk);
        if rx_data_valid = '1' then
            report "Received data: " & integer'image(to_integer(unsigned(rx_data_out)));
        end if;
        if spw_error = '1' then
            report "SpW Error detected!" severity warning;
        end if;
    end process;

end tb;