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

library work;
use work.system_constant_pckg.all;

--! Use shyloc_121 library
library shyloc_121; 
--! Use generic shyloc121 parameters
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

library shyloc_utils;
use shyloc_utils.amba.all;

context work.router_context;

entity system_SHyLoC_top is 
    generic (
        g_num_ports         : natural range 1 to 32     := c_num_ports;         -- number of ports
        g_is_fifo           : t_dword                   := c_fifo_ports;        -- fifo ports
        g_clock_freq        : real                      := c_spw_clk_freq;      -- clock frequency
        g_mode				: string 					:= "single";			-- valid options are "diff", "single" and "custom".
        g_priority          : string                    := c_priority;          
        g_ram_style         : string                    := c_ram_style;
        g_router_port_addr  : integer                   := c_router_port_addr           
    );                                                                                                    
    
    port(
        rst_n_spw_pad : in std_logic;
        rst_n_pad     : in std_logic;
        rst_AHB_pad   : in std_logic;
		Din_p  		  : in std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "single" and "diff" io modes
		Sin_p         : in std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Dout_p        : out std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sout_p        : out std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        spw_fmc_en    : out std_logic;
        spw_fmc_en_2  : out std_logic;
        spw_fmc_en_3  : out std_logic;
        spw_fmc_en_4  : out std_logic
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
generic (
    g_num_ports         : natural range 1 to 32     := c_num_ports;         -- number of ports
    g_is_fifo           : t_dword                   := c_fifo_ports;        -- fifo ports
    g_clock_freq        : real                      := c_spw_clk_freq;      -- clock frequency
    g_mode				: string 					:= "single";			-- valid options are "diff", "single" and "custom".
    g_priority          : string                    := c_priority;          
    g_ram_style         : string                    := c_ram_style;
    g_router_port_addr  : integer                   := c_router_port_addr           
);
port(
    rst_n               : in std_logic;				-- active low reset
    clk                 : in std_logic;				-- clock input
		
    rx_cmd_out		 : out 	std_logic_vector(2 downto 0)	:= (others => '0');		-- control char output bits
    rx_cmd_valid	 : out 	std_logic;												-- asserted when valid command to output
    rx_cmd_ready	 : in 	std_logic;												-- assert to receive rx command. 
    
    rx_data_out		 : out 	std_logic_vector(7 downto 0)	:= (others => '0');		-- received spacewire data output
    rx_data_valid	 : out 	std_logic := '0';										-- valid rx data on output
    rx_data_ready	 : in 	std_logic := '1';										-- assert to receive rx data

    ccsds_datain     : in   std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);     --convert to 8 bit data in asym_FIFO
    w_update         : in   std_logic;                                                                    --connect with ccsds dataout newvalid
    asym_FIFO_full   : out  std_logic;								                                    -- fifo full signal
    ccsds_ready_ext  : out  std_logic;								                                    -- fifo ready signal

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
--    signal ahb_slave121_in    : AHB_Slv_In_Type;    -- AHB slave input signals
--    signal ahb_slave121_out   : AHB_Slv_Out_Type;   -- AHB slave output signals
--    signal ahb_slave123_in    : AHB_Slv_In_Type;    -- AHB 123 slave input signals
--    signal ahb_slave123_out   : AHB_Slv_Out_Type;   -- AHB 123 slave output signals
--    signal ahb_master123_in   : AHB_Mst_In_Type;    -- AHB 123 master input signals
--    signal ahb_master123_out  : AHB_Mst_Out_Type;   -- AHB 123 master output signals
    
    -- Data Interface signals
    signal data_in_shyloc     : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_newvalid   : std_logic;
    signal data_out_shyloc    : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
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
    -- Signal declarations for router_fifo_ctrl_top
    ----------------------------------------------------------------------
    signal rx_data_out		 : 	std_logic_vector(7 downto 0);
    signal rx_data_valid	 : 	std_logic;
    signal ccsds_ready_ext   :  std_logic;
    ----------------------------------------------------------------------
    -- Reset Management Signals
    ----------------------------------------------------------------------
    signal reset_n_spw_s : std_logic;             -- Debounced SpaceWire reset (active low)
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
-- ShyLoc_top_Wrapper instantiation, CCSDS123+CCSDS121
----------------------------------------------------------------------
ShyLoc_top_inst : ShyLoc_top_Wrapper
    port map(
        -- System Interface
        Clk_S             => clk_s,              -- Using the clock from FCCC
        Rst_N             => reset_n_s,              -- Using the top-level reset
        
        -- Amba Interface
        AHBSlave121_In    => C_AHB_SLV_IN_ZERO,  --declared in router_package.vhd
        Clk_AHB           => clk_AHB,            -- Using the AHB clock from FCCC
        Reset_AHB         => rst_AHB_pad,          
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
        ForceStop         => force_stop,
        AwaitingConfig    => awaiting_config,
        Ready             => ready,                     --output, configuration received and IP ready for new samples
        FIFO_Full         => fifo_full,
        EOP               => eop,
        Finished          => finished,
        Error             => error
    );

    router_fifo_ctrl_inst : router_fifo_ctrl_top
    -- Generic map section defines the configuration parameters
    generic map (
        g_num_ports     => c_num_ports,         -- Number of SpaceWire ports
        g_is_fifo       => c_fifo_ports,        -- Define which ports are FIFO ports
        g_clock_freq    => c_spw_clk_freq,      -- System clock frequency
        g_mode          => "single",            -- Operating mode (single/diff/custom)
        g_priority      => c_priority,          -- Priority scheme for routing
        g_ram_style     => c_ram_style,         -- RAM implementation style
        g_router_port_addr => c_router_port_addr -- Router port address
    )
    -- Port map section connects the actual signals
    port map (
        -- Clock and Reset
        rst_n           => reset_n_spw_s,         -- Active low reset
        clk             => clk_s,                 -- System clock

        -- Receive Command Interface
        rx_cmd_out      => open,                 -- Control character output
        rx_cmd_valid    => open,                 -- Command valid signal
        rx_cmd_ready    => '0',                  -- Command ready signal

        -- Receive Data Interface
        rx_data_out     => rx_data_out,        -- Received raw data and travel to CCSDS
        rx_data_valid   => rx_data_valid,      -- Data valid signal
        rx_data_ready   => ready,              -- from SHyLoC 

        -- CCSDS Interface
        ccsds_datain    => data_out_shyloc,       -- CCSDS output data, compressed data
        w_update        => data_out_newvalid,     -- Write update signal
        asym_FIFO_full  => open ,                 -- inverted signal of ccsds_ready_ext
        ccsds_ready_ext => ccsds_ready_ext,       -- CCSDS ready signal

        -- SpaceWire Interface (Single-ended mode)
        Din_p           => Din_p,              -- Data input positive
        Sin_p           => Sin_p,              -- Strobe input positive
        Dout_p          => Dout_p,             -- Data output positive
        Sout_p          => Sout_p,             -- Strobe output positive

        -- Status Signals
        spw_error        => open,          -- SpaceWire error flag
        router_connected => open    -- Port connection status
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
        rst_n        => rst_n_pad,            -- Connect to top-level reset input
        rst_n_spw    => rst_n_spw_pad,        -- Connect to SpaceWire reset input
        locked       => locked,               -- Connect to FCCC locked signal
        spw_fmc_en   => spw_fmc_en,          -- Connect directly to top-level output
        spw_fmc_en_2 => spw_fmc_en_2,        -- Connect directly to top-level output
        spw_fmc_en_3 => spw_fmc_en_3,        -- Connect directly to top-level output
        spw_fmc_en_4 => spw_fmc_en_4,        -- Connect directly to top-level output
        reset_n_spw  => reset_n_spw_s,        -- Connect to internal signal
        rst_spw      => open,           -- Connect to internal signal
        reset_n      => reset_n_s             -- Connect to internal signal
    );

end architecture rtl;