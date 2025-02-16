-- Created by rui Yin
-- File name: system_SHyLoC_top.vhd
-- note : SD is not suitable for VHDL record type
-- softwareVersion: Libero 2024.1 
-- Date: 11.02.2025
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library smartfusion2;
use smartfusion2.all;
library src;
use src.all;

--! Use shyloc_121 library
library shyloc_121; 
--! Use generic shyloc121 parameters
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

context work.router_context;

entity system_SHyLoC_top is 
    port(
        rst_n_spw    : in std_logic;
        rst_n        : in std_logic;
        Din_p_1      : in  std_logic;
        Din_p_2      : in  std_logic;
        Din_p_3      : in  std_logic;
        Din_p_4      : in  std_logic;
        Sin_p_1      : in  std_logic;
        Sin_p_2      : in  std_logic;
        Sin_p_3      : in  std_logic;
        Sin_p_4      : in  std_logic;
        -- Outputs
        Dout_p_1     : out std_logic;
        Dout_p_2     : out std_logic;
        Dout_p_3     : out std_logic;
        Dout_p_4     : out std_logic;
        Sout_p_1     : out std_logic;
        Sout_p_2     : out std_logic;
        Sout_p_3     : out std_logic;
        Sout_p_4     : out std_logic;
        spw_fmc_en   : out std_logic;
        spw_fmc_en_2 : out std_logic;
        spw_fmc_en_3 : out std_logic;
        spw_fmc_en_4 : out std_logic
    );
end entity system_SHyLoC_top;

architecture rtl of system_SHyLoC_top is

----------------------------------------------------------------------
-- Component Declaration
----------------------------------------------------------------------
--SHyLoC_subtop
--router_fifo_ctrl_top
--Debounce module
--FCCC

component FCCC_C0
    -- Port list
    port(
        -- Inputs
        RCOSC_25_50MHZ : in  std_logic;
        -- Outputs
        GL0            : out std_logic;
        GL1            : out std_logic;
        LOCK           : out std_logic
        );
end component;
-- OSC_C0
component OSC_C0
    -- Port list
    port(
        -- Outputs
        RCOSC_25_50MHZ_CCC : out std_logic
        );
end component;

component router_fifo_ctrl_top
port(
    rst_n               : in std_logic;				-- active low reset
    clk                 : in std_logic;				-- clock input
		
    rx_cmd_out		 : out 	std_logic_vector(2 downto 0)	:= (others => '0');		-- control char output bits
    rx_cmd_valid	 : out 	std_logic;												-- asserted when valid command to output
    rx_cmd_ready	 : in 	std_logic;												-- assert to receive rx command. 
    
    rx_data_out		 : out 	std_logic_vector(7 downto 0)	:= (others => '0');		-- received spacewire data output
    rx_data_valid	 : out 	std_logic := '0';										-- valid rx data on output
    rx_data_ready	 : in 	std_logic := '1';										-- assert to receive rx data
    ram_enable_tx    : out   std_logic;

    ccsds_datain     : in std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);     --convert to 8 bit data in asym_FIFO
    w_update         : in std_logic;                                                                    --connect with ccsds dataout newvalid
    asym_FIFO_full   : out std_logic;								                                    -- fifo full signal
    ccsds_ready_ext  : out std_logic;								                                    -- fifo ready signal

    --TX_IR indicate fifo read data and transmit data to spw
    TX_IR_fifo_rupdata : out std_logic;
    --DS signal chose by the c_port_mode 
    DDR_din_r		 : in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "custom" io mode 
    DDR_din_f   	 : in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
    DDR_sin_r   	 : in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
    DDR_sin_f   	 : in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
    SDR_Dout		 : out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
    SDR_Sout		 : out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 

    Din_p  			 : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "single" and "diff" io modes
    Din_n            : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Sin_p            : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Sin_n            : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Dout_p           : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Dout_n           : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Sout_p           : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
    Sout_n           : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes                                                     
    spw_error        : out  std_logic;

    router_connected    : out  std_logic_vector(31 downto 1) := (others => '0')            -- output, asserted when SpW Link is Connected
);
end component;

--! Instantiate the SHyLoC_subtop component
component ShyLoc_top_Wrapper is
    port (
        -- System Interface
        Clk_S            : in  std_logic;                    --! Clock signal
        Rst_N            : in  std_logic;                    --! Reset signal. Active low
        
        -- Amba Interface
        AHBSlave121_In   : in  AHB_Slv_In_Type;             --! AHB slave input signals
        Clk_AHB          : in  std_logic;                    --! AHB clock
        Reset_AHB        : in  std_logic;                    --! AHB reset
        AHBSlave121_Out  : out AHB_Slv_Out_Type;            --! AHB slave output signals
        
        -- AHB 123 Slave interface
        AHBSlave123_In   : in  AHB_Slv_In_Type;             --! AHB slave input signals
        AHBSlave123_Out  : out AHB_Slv_Out_Type;            --! AHB slave output signals
        
        -- AHB 123 Master interface
        AHBMaster123_In  : in  AHB_Mst_In_Type;             --! AHB slave input signals
        AHBMaster123_Out : out AHB_Mst_Out_Type;            --! AHB slave output signals
        
        -- Data Input Interface
        DataIn_shyloc    : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);  --from the input interface
        DataIn_NewValid  : in  std_logic;                    --! Flag to validate input signals
        
        -- Data Output Interface CCSDS121
        DataOut          : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        DataOut_NewValid : out std_logic;                    --! Flag to validate output bit stream
        Ready_Ext        : in  std_logic;                    --! External receiver not ready
        
        -- CCSDS123 IP Core Interface
        ForceStop        : in  std_logic;                    --! Force the stop of the compression
        AwaitingConfig   : out std_logic;                    --! The IP core is waiting to receive the configuration
        Ready            : out std_logic;                    --! Configuration received and IP ready for new samples
        FIFO_Full        : out std_logic;                    --! The input FIFO is full
        EOP              : out std_logic;                    --! Compression of last sample has started
        Finished         : out std_logic;                    --! The IP has finished compressing all samples
        Error            : out std_logic                     --! Error during compression
    );
end component;

component Debounce_Single_Input is
    generic (
        DEBOUNCE_LIMIT : integer := 250000    -- Debounce time limit parameter
    );
    port (
        i_Clk       : in  std_logic;          -- Input clock signal
        rst_n       : in  std_logic;          -- Asynchronous reset (active low)
        rst_n_spw   : in  std_logic;          -- SpaceWire reset (active low)
        locked      : in  std_logic;          -- Clock locked signal
        spw_fmc_en  : out std_logic;          -- SpaceWire FMC enable signal 1
        spw_fmc_en_2: out std_logic;          -- SpaceWire FMC enable signal 2
        spw_fmc_en_3: out std_logic;          -- SpaceWire FMC enable signal 3
        spw_fmc_en_4: out std_logic;          -- SpaceWire FMC enable signal 4
        reset_n_spw : out std_logic;          -- SpaceWire reset output (active low)
        rst_spw     : out std_logic;          -- SpaceWire reset output (active high)
        reset_n     : out std_logic           -- System reset output (active low)
    );
end component;

    ----------------------------------------------------------------------
    -- Signal declaration
    ----------------------------------------------------------------------
    signal OSC_out_25_50MHZ : std_logic;
    signal clk_s            : std_logic;
    signal clk_AHB          : std_logic;
    signal locked           : std_logic;

    ----------------------------------------------------------------------
    -- Signal declarations for ShyLoc_top_Wrapper
    ----------------------------------------------------------------------
    -- AHB Interface signals
    signal ahb_slave121_in    : AHB_Slv_In_Type;    -- AHB slave input signals
    signal ahb_slave121_out   : AHB_Slv_Out_Type;   -- AHB slave output signals
    signal ahb_slave123_in    : AHB_Slv_In_Type;    -- AHB 123 slave input signals
    signal ahb_slave123_out   : AHB_Slv_Out_Type;   -- AHB 123 slave output signals
    signal ahb_master123_in   : AHB_Mst_In_Type;    -- AHB 123 master input signals
    signal ahb_master123_out  : AHB_Mst_Out_Type;   -- AHB 123 master output signals
    
    -- Data Interface signals
    signal data_in_shyloc     : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_newvalid   : std_logic;
    signal data_out           : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_newvalid  : std_logic;
    
    -- Control signals
    signal ready_ext          : std_logic;
    signal force_stop         : std_logic;
    signal awaiting_config    : std_logic;
    signal ready              : std_logic;
    signal fifo_full          : std_logic;
    signal eop                : std_logic;
    signal finished           : std_logic;
    signal error              : std_logic;

    ----------------------------------------------------------------------
    -- Reset Management Signals
    ----------------------------------------------------------------------
    signal reset_n_spw_s : std_logic;             -- Debounced SpaceWire reset (active low)
    signal rst_spw_s     : std_logic;             -- Debounced SpaceWire reset (active high)
    signal reset_n_s     : std_logic;             -- Debounced system reset (active low)

begin

--! Instantiate the FCCC_C0 component
FCCC_C0_0 : FCCC_C0
    port map( 
        -- Inputs
        RCOSC_25_50MHZ => OSC_out_25_50MHZ,
        -- Outputs
        GL0            => clk_s,
        GL1            => clk_AHB,
        LOCK           => locked 
        );

--! Instantiate the OSC_C0 component
OSC_C0_0 : OSC_C0
    port map( 
        -- Outputs
        RCOSC_25_50MHZ_CCC => OSC_out_25_50MHZ  
        );

----------------------------------------------------------------------
-- ShyLoc_top_Wrapper instantiation
----------------------------------------------------------------------
ShyLoc_top_inst : ShyLoc_top_Wrapper
    port map(
        -- System Interface
        Clk_S             => clk_s,              -- Using the clock from FCCC
        Rst_N             => rst_n,              -- Using the top-level reset
        
        -- Amba Interface
        AHBSlave121_In    => ahb_slave121_in,
        Clk_AHB           => clk_AHB,            -- Using the AHB clock from FCCC
        Reset_AHB         => not rst_n,          -- Inverting reset for AHB
        AHBSlave121_Out   => ahb_slave121_out,
        
        -- AHB 123 Interfaces
        AHBSlave123_In    => ahb_slave123_in,
        AHBSlave123_Out   => ahb_slave123_out,
        AHBMaster123_In   => ahb_master123_in,
        AHBMaster123_Out  => ahb_master123_out,
        
        -- Data Input Interface
        DataIn_shyloc     => data_in_shyloc,
        DataIn_NewValid   => data_in_newvalid,
        
        -- Data Output Interface CCSDS121
        DataOut           => data_out,
        DataOut_NewValid  => data_out_newvalid,
        Ready_Ext         => ready_ext,
        
        -- CCSDS123 IP Core Interface
        ForceStop         => force_stop,
        AwaitingConfig    => awaiting_config,
        Ready             => ready,
        FIFO_Full         => fifo_full,
        EOP               => eop,
        Finished          => finished,
        Error             => error
    );

----------------------------------------------------------------------
-- Reset Management Instantiation
----------------------------------------------------------------------
Debounce_inst : Debounce_Single_Input
    generic map (
        DEBOUNCE_LIMIT => 250000              -- Using default value, adjust as needed
    )
    port map (
        i_Clk        => clk_s,                -- Connect to system clock from FCCC
        rst_n        => rst_n,                -- Connect to top-level reset input
        rst_n_spw    => rst_n_spw,           -- Connect to SpaceWire reset input
        locked       => locked,               -- Connect to FCCC locked signal
        spw_fmc_en   => spw_fmc_en,          -- Connect directly to top-level output
        spw_fmc_en_2 => spw_fmc_en_2,        -- Connect directly to top-level output
        spw_fmc_en_3 => spw_fmc_en_3,        -- Connect directly to top-level output
        spw_fmc_en_4 => spw_fmc_en_4,        -- Connect directly to top-level output
        reset_n_spw  => reset_n_spw_s,        -- Connect to internal signal
        rst_spw      => rst_spw_s,           -- Connect to internal signal
        reset_n      => reset_n_s             -- Connect to internal signal
    );

end architecture rtl;