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
    constant g_num_ports  : natural := 3;
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

    --spw signals
    signal    reset_spw                                      :       std_logic := '0';           -- activ high
    -- Channels
    signal    Tx_Data_spw         , Tx_Data_2_spw            :       nonet;                      -- 9 bits of Tx Data (data to send)  
    signal    Tx_OR_spw           , Tx_OR_2_spw              :       boolean;                    -- Tx data Output Ready           
    signal    Tx_IR_spw           , Tx_IR_2_spw              :       boolean;                    -- Tx data Input Ready             
    
    signal    Rx_Data_spw         , Rx_Data_2_spw            :       nonet;                      -- 9 bits of Rx Data (data received)  
    signal    Rx_OR_spw           , Rx_OR_2_spw              :       boolean;                    -- Rx data Output Ready            
    signal    Rx_IR_spw           , Rx_IR_2_spw              :       boolean;                    -- Rx data Input Ready 

    signal    Rx_ESC_ESC_spw      , Rx_ESC_ESC_2_spw         :       boolean;                    
    signal    Rx_ESC_EOP_spw      , Rx_ESC_EOP_2_spw         :       boolean;                    
    signal    Rx_ESC_EEP_spw      , Rx_ESC_EEP_2_spw         :       boolean;                    
    signal    Rx_Parity_Error_spw  , Rx_Parity_Error_2_spw    :       boolean;                    
    signal    Rx_Bits_spw         , Rx_Bits_2_spw            :       integer range 0 to 2;      
    signal    Rx_Rate_spw         , Rx_Rate_2_spw            :       std_logic_vector(15 downto 0) := (others => '0');  
    
    signal    Rx_Time_spw         , Rx_Time_2_spw            :       octet;                      
    signal    Rx_Time_OR_spw      , Rx_Time_OR_2_spw         :       boolean;                    
    signal    Rx_Time_IR_spw      , Rx_Time_IR_2_spw         :       boolean;                    
    
    signal    Tx_Time_spw         , Tx_Time_2_spw            :       octet;                      
    signal    Tx_Time_OR_spw      , Tx_Time_OR_2_spw         :       boolean;                    
    signal    Tx_Time_IR_spw      , Tx_Time_IR_2_spw         :       boolean;          
	
    -- Control		             
	signal	Disable         ,Disable_2            :  		boolean;
	signal	Connected       ,Connected_2          :  		boolean;
	signal	Error_select    ,Error_select_2       :  		std_logic_vector(3 downto 0) := (others => '0');
	signal	Error_inject    ,Error_inject_2       :  		boolean;

	-- SpW Ports, Init low. 
    signal    Din_p_spw           :       std_logic := '0';
    signal    Din_n_spw           :       std_logic := '0';
    signal    Sin_p_spw           :       std_logic := '0';
    signal    Sin_n_spw           :       std_logic := '0';
    signal    Dout_p_spw          :       std_logic := '0';
    signal    Dout_n_spw          :       std_logic := '0';
    signal    Sout_p_spw          :       std_logic := '0';
    signal    Sout_n_spw          :       std_logic := '0';
    
	
	signal 	spw_debug_tx		: 		std_logic_vector(8 downto 0)	:= (others => '0');
	signal 	spw_debug_raw		: 		std_logic_vector(13 downto 0)	:= (others => '0');
	signal 	spw_debug_parity	: 		std_logic;
	signal 	spw_debug_cmd		: 		string(1 to 3);
	signal 	spw_debug_time		: 		std_logic_vector(7 downto 0) 	:= (others => '0');
	
	signal 	rx_data_buf			: 		nonet_mem(0 to 63) := (others => (others => '0'));	-- rx data buffer
	
	signal 	ip_connected			: 		std_logic;


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
        din_p => din_p,
        din_n => din_n,
        sin_p => sin_p,
        sin_n => sin_n,
        dout_p => dout_p,
        dout_n => dout_n,
        sout_p => sout_p,
        sout_n => sout_n,
        spw_error => spw_error
    );

    SPW_DUT_tx: entity work.spw_wrap_top_level(rtl)
    generic map(
		g_clock_frequency   =>	c_clock_frequency,  
		g_rx_fifo_size      =>  c_rx_fifo_size,      
		g_tx_fifo_size      =>  c_tx_fifo_size,      
		g_mode				=>  c_mode				
	)
	port map( 
		-- clock & reset signals
		clock               =>	clk,					                 
		reset               =>  reset_spw, 
		
        -- Data Channels          
        Tx_data             =>  Tx_Data_spw,                                                -- transmit raw data
        Tx_OR               =>  Tx_OR_spw,           
        Tx_IR               =>  Tx_IR_spw,           
      
        Rx_data             =>  Rx_Data_spw,         
        Rx_OR               =>  Rx_OR_spw,           
        Rx_IR               =>  Rx_IR_spw,           
        
        -- Error Channels 
        Rx_ESC_ESC          =>  Rx_ESC_ESC_spw,      
        Rx_ESC_EOP          =>  Rx_ESC_EOP_spw,      
        Rx_ESC_EEP          =>  Rx_ESC_EEP_spw,      
        Rx_Parity_error     =>  Rx_Parity_Error_spw, 
        Rx_bits             =>  Rx_Bits_spw,         
        Rx_rate             =>  Rx_Rate_spw,         
   
        -- Time Code Channels
        Rx_Time             =>  Rx_Time_spw,         
        Rx_Time_OR          =>  Rx_Time_OR_spw,      
        Rx_Time_IR          =>  Rx_Time_IR_spw,      
 
        Tx_Time             =>  Tx_Time_spw,         
        Tx_Time_OR          =>  Tx_Time_OR_spw,      
        Tx_Time_IR          =>  Tx_Time_IR_spw,      
    
        -- Control Channels           	
        Disable             =>  Disable,         
        Connected           =>  Connected,       
        Error_select        =>  Error_select,    
        Error_inject        =>  Error_inject,    
        
        -- SpW IO Ports, not used when "custom" mode.  	                
        Din_p               =>  din_p(1),  	 -- Used when Diff & Single     
        Din_n               =>  '0',         -- Used when Diff only
        Sin_p               =>  sin_p(1),  	 -- Used when Diff & Single       
        Sin_n               =>  '0',         -- Used when Diff only
        Dout_p              =>  dout_p(1),		 -- Used when Diff & Single      
        Dout_n              =>  open,            -- Used when Diff only
        Sout_p              =>  sout_p(1),  	 -- Used when Diff & Single      
        Sout_n              =>  open     	     -- Used when Diff only
    );
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
        wait for clk_period*10;
        rst_n <= '1';
        wait for clk_period*2;
        
        -- Test Case 1: Send raw 8-bit data through SpaceWire
        din_p(1) <= '1';  -- Simulate incoming SpaceWire data
        wait for clk_period;
        din_p(1) <= '0';
        
        -- Wait for data processing
        wait for clk_period*5;
        
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
        
        -- Test Case 3: Test FIFO full condition
        for i in 0 to 5 loop
            ccsds_datain <= std_logic_vector(to_unsigned(i, W_BUFFER_GEN));
            w_update <= '1';
            wait for clk_period;
            w_update <= '0';
            wait for clk_period*2;
        end loop;
        
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