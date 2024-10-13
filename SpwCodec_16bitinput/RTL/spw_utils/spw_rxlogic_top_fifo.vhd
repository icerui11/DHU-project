-- connect spw codec and spw datacontroller als Spacewire Receiver
-- rui yin
--10.06.2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

context work.spw_context;

library smartfusion2;
use smartfusion2.all;
library BROM;
use BROM.all;

entity spw_rxlogic_top_fifo is 
    generic (
    g_clock_frequency   : real 						:= 75_000_000.0;			-- clock frequency for SpaceWire IP (>2MHz)
    g_rx_fifo_size      : integer range 16 to 56 	:= 56; 					-- must be >8
    g_tx_fifo_size      : integer range 16 to 56 	:= 56; 					-- must be >8
    g_addr_width		: integer 					:= 9;					-- address width of connecting RAM/fifo
    g_data_width		: integer 					:= 8;					-- data width of connecting RAM/fifo
 --   g_fifo_depth        : integer 					:= 32;				-- number of component of the vector in fifo
    CCSDS_INbitwidth    : integer                   := 16;                  --input bitwidth of CCSDS data
    g_RESET_TYPE        : integer 					:= 1;					-- Implement Asynchronous Reset (0) or Synchronous Reset (1)
    g_mode		: string 					:= "single"				-- valid options are "diff", "single" and "custom".
);

port(
    rst_n               : in std_logic;				-- active low reset
    clk                 : in std_logic;				-- clock input
 --   enable  		: in 	std_logic := '0';										-- enable input, asserted high. 
		
    rx_cmd_out		: out 	std_logic_vector(2 downto 0)	:= (others => '0');		-- control char output bits
    rx_cmd_valid	: out 	std_logic;												-- asserted when valid command to output
    rx_cmd_ready	: in 	std_logic;												-- assert to receive rx command. 
    
    ccsds_datanewValid  : out   std_logic;
    ccsds_data          : out   std_logic_vector(CCSDS_INbitwidth-1 downto 0);                 --adjust to CCSDS

    rx_data_out		: out 	std_logic_vector(7 downto 0)	:= (others => '0');		-- received spacewire data output
    rx_data_valid	: out 	std_logic := '0';										-- valid rx data on output
    rx_data_ready	: in 	std_logic := '1';										-- assert to receive rx data
--    ram_enable_tx      : out   std_logic;
    fifo_clr         : in std_logic;						-- fifo clear signal
    fifo_datain      : in std_logic_vector(31 downto 0);		-- data to be written to fifo
    w_update         : in std_logic;                      --connect with ccsds dataout newvalid
    asym_FIFO_full   : out std_logic;								-- fifo full signal
    ccsds_ready_ext  : out std_logic;								-- fifo ready signal
--TX_IR indicate fifo read data and transmit data to spw
--  TX_IR_fifo_rupdata : out std_logic;
    -- SpW Rx IO
    spw_Din_p 		: in	std_logic := '0';
    spw_Din_n       : in    std_logic := '1';
    spw_Sin_p       : in    std_logic := '0';
    spw_Sin_n       : in    std_logic := '1'; 
    
    -- SpW Tx IO
    spw_Dout_p      : out   std_logic := '0';
    spw_Dout_n      : out   std_logic := '1';
    spw_Sout_p      : out   std_logic := '0';
    spw_Sout_n      : out   std_logic := '1';
    
    spw_error       : out     std_logic := '0'
);
end spw_rxlogic_top_fifo;

architecture rtl of spw_rxlogic_top_fifo is 

    	-- Channels                                                                 	--
	signal spw_Tx_data              :    	nonet;                                  --
	signal spw_Tx_OR                :    	std_logic := '0';                       -- converted to std_logic for use in entity/component outputs...
	signal spw_Tx_IR                :  		std_logic;                                --
	signal spw_Rx_data              :  		nonet;                                  --
	signal spw_Rx_OR                :  		std_logic;                                --
	signal spw_Rx_IR                :    	        std_logic := '0';                       --
	signal spw_Rx_ESC_ESC           :  		std_logic;                                --
	signal spw_Rx_ESC_EOP           :  		std_logic;                                --
	signal spw_Rx_ESC_EEP           :  		std_logic;                                --
	signal spw_Rx_Parity_error      :  		std_logic;                                --
	signal spw_Rx_bits              :  		integer range 0 to 2;                   --
	signal spw_Rx_rate              :  		std_logic_vector(15 downto 0);          --
	signal spw_Connected            : 		std_logic;                                --
    
    signal         reset           : std_logic := '1';								-- reset signal
    signal         ram_addr        : std_logic_vector(g_addr_width-1 downto 0);
    signal         ram_enable      : std_logic;
    signal         fifo_data       : std_logic_vector(g_data_width-1 downto 0);	     -- data FROM fifo
    signal         fifo_clear      : std_logic := '0';								-- clear signal for fifo
    signal         fifo_dataout    : std_logic_vector(g_data_width-1 downto 0);	-- data out from fifo
    signal         fifo_r_update   : std_logic;								-- fifo read update signal
    signal         asym_FIFO_empty : std_logic;								-- fifo empty signal
    signal         ccsds_ready_ext_wire : std_logic;      	                          -- fifo ready signal
    signal         fifo_ack       : std_logic; 		
    signal         write_done     : std_logic;					
begin 
--    TX_IR_fifo_rupdata <= spw_Tx_IR;
    ccsds_ready_ext    <= ccsds_ready_ext_wire;

    reset  <= '1' when rst_n = '0' else '0';                                -- microchip use active low reset
--    ram_enable_tx <= ram_enable;
    spw_wrap_top_rtg4: entity work.spw_wrap_top_level_RTG4(rtl)
    generic map (
        g_clock_frequency   => g_clock_frequency,
        g_rx_fifo_size      => g_rx_fifo_size,
        g_tx_fifo_size      => g_tx_fifo_size,
        g_mode				=> g_mode
    )
    port map (
        clock  				=>  clk,          
        reset               => 	reset,
        
        -- Channels         	-- Channels      	  
        Tx_data             =>  spw_Tx_data        	   	,
        Tx_OR               =>  spw_Tx_OR             	,
        Tx_IR               =>  spw_Tx_IR              	,
        
        Rx_data             =>  spw_Rx_data            	,
        Rx_OR               =>  spw_Rx_OR              	,
        Rx_IR               =>  spw_Rx_IR            	,
        
        Rx_ESC_ESC          =>  spw_Rx_ESC_ESC        	,
        Rx_ESC_EOP          =>  spw_Rx_ESC_EOP         	,
        Rx_ESC_EEP          =>  spw_Rx_ESC_EEP         	,
        Rx_Parity_error     =>  spw_Rx_Parity_error   	,
        Rx_bits             =>  open          			,
        Rx_rate             =>  open            		,
        
        Rx_Time             =>  open            		,
        Rx_Time_OR          =>  open         			,
        Rx_Time_IR          =>  '0'         			,

        Tx_Time             =>  (others => '0')         ,
        Tx_Time_OR          =>  '0'         		,
        Tx_Time_IR          =>  open     		,

        -- Control              -- Control         
        Disable             =>  '0'                     ,
        Connected           =>  spw_Connected          	,
        Error_select        =>  (others => '0')       	,
        Error_inject        =>  '0'       		,
        
        -- SpW                  -- SpW             
        Din_p               =>  spw_Din_p              	,
        Din_n               =>  spw_Din_n              	,
        Sin_p               =>  spw_Sin_p              	,
        Sin_n               =>  spw_Sin_n              	,
        Dout_p              =>  spw_Dout_p             	,
        Dout_n              =>  spw_Dout_n             	,
        Sout_p              =>  spw_Sout_p             	,
        Sout_n              =>  spw_Sout_n             
    );

    spw_datactrl_fifo: entity work.spw_datactrl_fifo(rtl)
    generic map (
        g_addr_width		=> g_addr_width,
        CCSDS_INbitwidth        => CCSDS_INbitwidth,        -- input bitwidth of CCSDS data
        g_count_max 		=> g_data_width             -- count for every ram address
    )
    port map( 

    -- standard register control signals --
    clk_in				=> 	clk,						-- clk input, rising edge trigger
    rst_in				=>	reset,						-- reset input, active high
    fifo_full			=>	asym_FIFO_full,				-- fifo full signal
    fifo_empty          =>  asym_FIFO_empty,					-- fifo empty signal
    fifo_r_update       =>  fifo_r_update,
    ccsds_ready_ext     =>  ccsds_ready_ext_wire,
    fifo_ack            =>  fifo_ack,
    write_done          =>  write_done,
    ccsds_data          =>  ccsds_data,                                         -- when 16bit input CCSDS
    -- RAM signals
    ram_data_in			=> 	fifo_data,					-- ram read data
    
    -- SpW Data Signals
    spw_Tx_data			=> 	spw_Tx_data(7 downto 0),	-- SpW Tx Data
    spw_Tx_Con			=> 	spw_Tx_data(8),				-- SpW Control Char Bit
    spw_Tx_OR			=> 	spw_Tx_OR,					-- SpW Tx Output Ready signal
    spw_Tx_IR			=> 	spw_Tx_IR,			-- SpW Tx Input Ready signal
    
    spw_Rx_data			=>	spw_Rx_data(7 downto 0),
    spw_Rx_Con		    =>	spw_Rx_data(8),
    spw_Rx_OR		    =>  spw_Rx_OR,
    spw_Rx_IR		    =>  spw_Rx_IR,

    rx_cmd_out		    =>	rx_cmd_out,
    rx_cmd_valid	    =>	rx_cmd_valid,
    rx_cmd_ready	    =>  rx_cmd_ready,

    rx_data_out		    =>	rx_data_out,
    rx_data_valid	    =>	rx_data_valid,
    rx_data_ready	    =>	rx_data_ready,
    
    -- SpW Control Signals
    spw_Connected	 	=> 	spw_Connected,			-- asserted when SpW Link is Connected
    spw_Rx_ESC_ESC	 	=> 	spw_Rx_ESC_ESC,     	-- SpW ESC_ESC error 
    spw_ESC_EOP 	 	=> 	spw_Rx_ESC_EOP,   		-- SpW ESC_EOP error 
    spw_ESC_EEP      	        => 	spw_Rx_ESC_EEP,     	-- SpW ESC_EEP error 
    spw_Parity_error 	        => 	spw_Rx_Parity_error,    -- SpW Parity error
    
    ccsds_datanewValid          =>      ccsds_datanewValid,      --enable ccsds data input
    error_out			=> 	spw_error						-- assert when error
);

asym_FIFO_inst_0 : entity work.asym_FIFO
    port map( 
        -- Inputs
        clk      => clk,
        rst_n    => rst_n,
        clr      => fifo_clr,
        w_update => w_update,
        r_update => fifo_r_update,
        data_in  => fifo_datain,
        -- Outputs
        ack      => fifo_ack,
        done     => write_done,
        hfull    => OPEN,
        empty    => asym_FIFO_empty,
        full     => asym_FIFO_full,
        afull    => OPEN,
        aempty   => OPEN,
        data_out_chunk => fifo_data 
        );
end rtl;