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

context work.router_context;

entity system_SHyLoC_top is 
    port(
        rst_n_spw : in std_logic;
        rst_n     : in std_logic;
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

----------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------
signal OSC_out_25_50MHZ : std_logic;


begin

--! Instantiate the FCCC_C0 component
FCCC_C0_0 : FCCC_C0
    port map( 
        -- Inputs
        RCOSC_25_50MHZ => OSC_out_25_50MHZ,
        -- Outputs
        GL0            => FCCC_C0_0_GL0_3,
        LOCK           => FCCC_C0_0_LOCK 
        );

--! Instantiate the OSC_C0 component
OSC_C0_0 : OSC_C0
    port map( 
        -- Outputs
        RCOSC_25_50MHZ_CCC => OSC_out_25_50MHZ  
        );

