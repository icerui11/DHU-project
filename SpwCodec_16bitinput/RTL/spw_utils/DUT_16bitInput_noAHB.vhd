----------------------------------------------------------------------
-- Created by SmartDesign Tue Sep 17 11:43:01 2024
-- Version: 2024.1 2024.1.0.3
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library smartfusion2;
use smartfusion2.all;
library post_syn_lib;
use post_syn_lib.all;
library shyloc_121;
use shyloc_121.all;
library src;
use src.all;
----------------------------------------------------------------------
-- DUT entity declaration
----------------------------------------------------------------------
entity DUT_16bitInput_noAHB is
    -- Port list
    port(
        -- Inputs
        Clk_AHB    : in  std_logic;
        Clk_S      : in  std_logic;
        Rst_AHB    : in  std_logic;
        Rst_N      : in  std_logic;
        rst_n_spw  : in  std_logic;
        spw_Din_n  : in  std_logic;
        spw_Din_p  : in  std_logic;
        spw_Sin_n  : in  std_logic;
        spw_Sin_p  : in  std_logic;
        ForceStop  : in  std_logic;                  -- in TB file input
        -- Outputs
        Finished   : out std_logic;                  -- for TB file closed
        spw_Dout_p : out std_logic;
        spw_Sout_p : out std_logic
        );
end DUT_16bitInput_noAHB;
----------------------------------------------------------------------
-- DUT architecture body
----------------------------------------------------------------------
architecture RTL of DUT_16bitInput_noAHB is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
-- ccsds121_top_wrapper
-- using entity instantiation for component ccsds121_top_wrapper
-- ccsds123_top_wrapper
-- using entity instantiation for component ccsds123_top_wrapper


component spw_rxlogic_top_fifo
    -- Port list
    port(
        -- Inputs
        clk                : in  std_logic;
        fifo_clr           : in  std_logic;
        fifo_datain        : in  std_logic_vector(31 downto 0);
        rst_n              : in  std_logic;
        rx_cmd_ready       : in  std_logic;
        rx_data_ready      : in  std_logic;
        spw_Din_n          : in  std_logic;
        spw_Din_p          : in  std_logic;
        spw_Sin_n          : in  std_logic;
        spw_Sin_p          : in  std_logic;
        w_update           : in  std_logic;
        -- Outputs
        asym_FIFO_full     : out std_logic;
        ccsds_data         : out std_logic_vector(15 downto 0);
        ccsds_datanewValid : out std_logic;
        ccsds_ready_ext    : out std_logic;
        rx_cmd_out         : out std_logic_vector(2 downto 0);
        rx_cmd_valid       : out std_logic;
        rx_data_out        : out std_logic_vector(7 downto 0);
        rx_data_valid      : out std_logic;
        spw_Dout_n         : out std_logic;
        spw_Dout_p         : out std_logic;
        spw_Sout_n         : out std_logic;
        spw_Sout_p         : out std_logic;
        spw_error          : out std_logic
        );
end component;
----------------------------------------------------------------------
-- Signal declarations
----------------------------------------------------------------------
signal ccsds121_top_wrapper_0_AwaitingConfig          : std_logic;
signal ccsds121_top_wrapper_0_DataOut                 : std_logic_vector(31 downto 0);
signal ccsds121_top_wrapper_0_DataOut_NewValid        : std_logic;
signal ccsds121_top_wrapper_0_EOP                     : std_logic;
signal ccsds121_top_wrapper_0_FIFO_Full               : std_logic;
signal ccsds121_top_wrapper_0_Finished                : std_logic;
signal ccsds121_top_wrapper_0_Ready                   : std_logic;
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HADDR  : std_logic_vector(31 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HBURST : std_logic_vector(2 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HLOCK  : std_logic;
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HPROT  : std_logic_vector(3 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HSIZE  : std_logic_vector(2 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HTRANS : std_logic_vector(1 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HWDATA : std_logic_vector(31 downto 0);
signal ccsds123_top_wrapper_0_AHBMaster123_Out_HWRITE : std_logic;
signal ccsds123_top_wrapper_0_DataOut_4               : std_logic_vector(31 downto 0);
signal ccsds123_top_wrapper_0_DataOut_NewValid        : std_logic;
signal ccsds123_top_wrapper_0_ForceStop_Ext           : std_logic;
signal ccsds123_top_wrapper_0_IsHeaderOut             : std_logic;
signal ccsds123_top_wrapper_0_NbitsOut                : std_logic_vector(5 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HADDR              : std_logic_vector(31 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HBURST             : std_logic_vector(2 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HMASTLOCK          : std_logic;
signal CoreAHBLite_C0_0_AHBmslave4_HPROT              : std_logic_vector(3 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HRDATA             : std_logic_vector(31 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HREADY             : std_logic;
signal CoreAHBLite_C0_0_AHBmslave4_HREADYOUT          : std_logic;
signal CoreAHBLite_C0_0_AHBmslave4_HRESP              : std_logic_vector(1 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HSELx              : std_logic;
signal CoreAHBLite_C0_0_AHBmslave4_HSIZE              : std_logic_vector(2 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HTRANS             : std_logic_vector(1 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HWDATA             : std_logic_vector(31 downto 0);
signal CoreAHBLite_C0_0_AHBmslave4_HWRITE             : std_logic;
signal CoreAHBLite_C0_0_HRDATA_M0                     : std_logic_vector(31 downto 0);
signal CoreAHBLite_C0_0_HREADY_M0                     : std_logic;
signal CoreAHBLite_C0_0_HRESP_M0                      : std_logic_vector(1 downto 0);
signal Error                                          : std_logic;
--signal forcestop_out_0_forcestop_out                  : std_logic;          --DUT direkt in tb input forcestop signal
signal Ready                                          : std_logic;
signal spw_Dout_p_net_0                               : std_logic;
signal spw_rxlogic_top_0_ccsds_data                   : std_logic_vector(15 downto 0);
signal spw_rxlogic_top_0_ccsds_datanewValid           : std_logic;
signal spw_rxlogic_top_0_ccsds_ready_ext              : std_logic;
signal spw_Sout_p_net_0                               : std_logic;
signal spw_Dout_p_net_1                               : std_logic;
signal spw_Sout_p_net_1                               : std_logic;
----------------------------------------------------------------------
-- TiedOff Signals
----------------------------------------------------------------------
signal GND_net                                        : std_logic;
signal AHBSlave121_In_HADDR_const_net_0               : std_logic_vector(31 downto 0);
signal AHBSlave121_In_HTRANS_const_net_0              : std_logic_vector(1 downto 0);
signal AHBSlave121_In_HSIZE_const_net_0               : std_logic_vector(2 downto 0);
signal AHBSlave121_In_HBURST_const_net_0              : std_logic_vector(2 downto 0);
signal AHBSlave121_In_HWDATA_const_net_0              : std_logic_vector(31 downto 0);
signal AHBSlave121_In_HPROT_const_net_0               : std_logic_vector(3 downto 0);
signal AHBSlave121_In_HMASTER_const_net_0             : std_logic_vector(3 downto 0);
signal VCC_net                                        : std_logic;
signal AHBSlave123_In_HADDR_const_net_0               : std_logic_vector(31 downto 0);
signal AHBSlave123_In_HTRANS_const_net_0              : std_logic_vector(1 downto 0);
signal AHBSlave123_In_HSIZE_const_net_0               : std_logic_vector(2 downto 0);
signal AHBSlave123_In_HBURST_const_net_0              : std_logic_vector(2 downto 0);
signal AHBSlave123_In_HWDATA_const_net_0              : std_logic_vector(31 downto 0);
signal AHBSlave123_In_HPROT_const_net_0               : std_logic_vector(3 downto 0);
signal AHBSlave123_In_HMASTER_const_net_0             : std_logic_vector(3 downto 0);
signal AHBMaster123_In_HRESP_const_net_0              : std_logic_vector(1 downto 0);
signal AHBMaster123_In_HRDATA_const_net_0             : std_logic_vector(31 downto 0);

begin
----------------------------------------------------------------------
-- Constant assignments
----------------------------------------------------------------------
 GND_net                            <= '0';
 AHBSlave121_In_HADDR_const_net_0   <= B"00000000000000000000000000000000";
 AHBSlave121_In_HTRANS_const_net_0  <= B"00";
 AHBSlave121_In_HSIZE_const_net_0   <= B"000";
 AHBSlave121_In_HBURST_const_net_0  <= B"000";
 AHBSlave121_In_HWDATA_const_net_0  <= B"00000000000000000000000000000000";
 AHBSlave121_In_HPROT_const_net_0   <= B"0000";
 AHBSlave121_In_HMASTER_const_net_0 <= B"0000";
 VCC_net                            <= '1';
 AHBSlave123_In_HADDR_const_net_0   <= B"00000000000000000000000000000000";
 AHBSlave123_In_HTRANS_const_net_0  <= B"00";
 AHBSlave123_In_HSIZE_const_net_0   <= B"000";
 AHBSlave123_In_HBURST_const_net_0  <= B"000";
 AHBSlave123_In_HWDATA_const_net_0  <= B"00000000000000000000000000000000";
 AHBSlave123_In_HPROT_const_net_0   <= B"0000";
 AHBSlave123_In_HMASTER_const_net_0 <= B"0000";

 AHBMaster123_In_HRESP_const_net_0 <= B"00";                                --AHB response 2bits
 AHBMaster123_In_HRDATA_const_net_0 <= B"00000000000000000000000000000000";


----------------------------------------------------------------------
-- Top level output port assignments
----------------------------------------------------------------------
 spw_Dout_p_net_1 <= spw_Dout_p_net_0;
 spw_Dout_p       <= spw_Dout_p_net_1;
 spw_Sout_p_net_1 <= spw_Sout_p_net_0;
 spw_Sout_p       <= spw_Sout_p_net_1;
----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------
-- ccsds121_top_wrapper_0
ccsds121_top_wrapper_0 : entity post_syn_lib.ccsds121_top_wrapper
    port map( 
        -- Inputs
        Clk_S                    => Clk_S,
        Rst_N                    => Rst_N,
        Clk_AHB                  => Clk_AHB,
        Reset_AHB                => Rst_AHB,
        DataIn                   => ccsds123_top_wrapper_0_DataOut_4,
        DataIn_NewValid          => ccsds123_top_wrapper_0_DataOut_NewValid,
        IsHeaderIn               => ccsds123_top_wrapper_0_IsHeaderOut,
        NbitsIn                  => ccsds123_top_wrapper_0_NbitsOut,
        AHBSlave121_In_HSEL      => GND_net,
        AHBSlave121_In_HADDR     => AHBSlave121_In_HADDR_const_net_0,
        AHBSlave121_In_HWRITE    => GND_net,
        AHBSlave121_In_HTRANS    => AHBSlave121_In_HTRANS_const_net_0,
        AHBSlave121_In_HSIZE     => AHBSlave121_In_HSIZE_const_net_0,
        AHBSlave121_In_HBURST    => AHBSlave121_In_HBURST_const_net_0,
        AHBSlave121_In_HWDATA    => AHBSlave121_In_HWDATA_const_net_0,
        AHBSlave121_In_HPROT     => AHBSlave121_In_HPROT_const_net_0,
        AHBSlave121_In_HREADY    => GND_net,
        AHBSlave121_In_HMASTER   => AHBSlave121_In_HMASTER_const_net_0,
        AHBSlave121_In_HMASTLOCK => GND_net,
        ForceStop                => ccsds123_top_wrapper_0_ForceStop_Ext,
        Ready_Ext                => spw_rxlogic_top_0_ccsds_ready_ext,
        -- Outputs
        AHBSlave121_Out_HREADY   => OPEN,
        AHBSlave121_Out_HRESP    => OPEN,
        AHBSlave121_Out_HRDATA   => OPEN,
        AHBSlave121_Out_HSPLIT   => OPEN,
        DataOut                  => ccsds121_top_wrapper_0_DataOut,
        DataOut_NewValid         => ccsds121_top_wrapper_0_DataOut_NewValid,
        AwaitingConfig           => ccsds121_top_wrapper_0_AwaitingConfig,
        Ready                    => ccsds121_top_wrapper_0_Ready,
        FIFO_Full                => ccsds121_top_wrapper_0_FIFO_Full,
        EOP                      => ccsds121_top_wrapper_0_EOP,
        Finished                 => ccsds121_top_wrapper_0_Finished,
        Error                    => Error 
        );
-- ccsds123_top_wrapper_0
ccsds123_top_wrapper_0 : entity post_syn_lib.ccsds123_top_wrapper
    port map( 
        -- Inputs
        Clk_S                    => Clk_S,
        Rst_N                    => Rst_N,
        Clk_AHB                  => Clk_AHB,
        Rst_AHB                  => Rst_AHB,
        DataIn_NewValid          => spw_rxlogic_top_0_ccsds_datanewValid,
        ForceStop                => ForceStop,
        AHBSlave123_In_HSEL      => GND_net,
        AHBSlave123_In_HWRITE    => GND_net,
        AHBSlave123_In_HREADY    => GND_net,
        AHBSlave123_In_HMASTLOCK => GND_net,
        AHBMaster123_In_HGRANT   => VCC_net,
        AHBMaster123_In_HREADY   => CoreAHBLite_C0_0_HREADY_M0,
        AwaitingConfig_Ext       => ccsds121_top_wrapper_0_AwaitingConfig,
        Ready_Ext                => ccsds121_top_wrapper_0_Ready,
        FIFO_Full_Ext            => ccsds121_top_wrapper_0_FIFO_Full,
        EOP_Ext                  => ccsds121_top_wrapper_0_EOP,
        Finished_Ext             => ccsds121_top_wrapper_0_Finished,
        Error_Ext                => Error,
        DataIn                   => spw_rxlogic_top_0_ccsds_data,
        AHBSlave123_In_HADDR     => AHBSlave121_In_HADDR_const_net_0,
        AHBSlave123_In_HTRANS    => AHBSlave121_In_HTRANS_const_net_0,
        AHBSlave123_In_HSIZE     => AHBSlave121_In_HSIZE_const_net_0,
        AHBSlave123_In_HBURST    => AHBSlave121_In_HBURST_const_net_0,
        AHBSlave123_In_HWDATA    => AHBSlave121_In_HWDATA_const_net_0,
        AHBSlave123_In_HPROT     => AHBSlave121_In_HPROT_const_net_0,
        AHBSlave123_In_HMASTER   => AHBSlave121_In_HMASTER_const_net_0,
        AHBMaster123_In_HRESP    => AHBMaster123_In_HRESP_const_net_0,
        AHBMaster123_In_HRDATA   => AHBMaster123_In_HRDATA_const_net_0,
        
        -- Outputs
        DataOut_NewValid         => ccsds123_top_wrapper_0_DataOut_NewValid,
        IsHeaderOut              => ccsds123_top_wrapper_0_IsHeaderOut,
        AwaitingConfig           => OPEN,
        Ready                    => Ready,
        FIFO_Full                => OPEN,
        EOP                      => OPEN,
        Finished                 => Finished,
        Error                    => OPEN,
        AHBSlave123_Out_HREADY   => OPEN,
        AHBMaster123_Out_HBUSREQ => OPEN,
        AHBMaster123_Out_HLOCK   => OPEN,
        AHBMaster123_Out_HWRITE  => OPEN,
        ForceStop_Ext            => ccsds123_top_wrapper_0_ForceStop_Ext,
        DataOut                  => ccsds123_top_wrapper_0_DataOut_4,
        NbitsOut                 => ccsds123_top_wrapper_0_NbitsOut,
        AHBSlave123_Out_HRESP    => OPEN,
        AHBSlave123_Out_HRDATA   => OPEN,
        AHBSlave123_Out_HSPLIT   => OPEN,
        AHBMaster123_Out_HTRANS  => OPEN,
        AHBMaster123_Out_HADDR   => OPEN,
        AHBMaster123_Out_HSIZE   => OPEN,
        AHBMaster123_Out_HBURST  => OPEN,
        AHBMaster123_Out_HPROT   => OPEN,
        AHBMaster123_Out_HWDATA  => OPEN 
        );

spw_rxlogic_top_0 : spw_rxlogic_top_fifo
    port map( 
        -- Inputs
        rst_n              =>  rst_n_spw,
        clk                => Clk_S,
        rx_cmd_ready       => VCC_net,
        rx_data_ready      => Ready,
        fifo_clr           => GND_net,
        w_update           => ccsds121_top_wrapper_0_DataOut_NewValid,
        spw_Din_p          => spw_Din_p,
        spw_Din_n          => spw_Din_n,
        spw_Sin_p          => spw_Sin_p,
        spw_Sin_n          => spw_Sin_n,
        fifo_datain        => ccsds121_top_wrapper_0_DataOut,
        -- Outputs
        rx_cmd_valid       => OPEN,
        ccsds_datanewValid => spw_rxlogic_top_0_ccsds_datanewValid,
        rx_data_valid      => OPEN,
        asym_FIFO_full     => OPEN,
        ccsds_ready_ext    => spw_rxlogic_top_0_ccsds_ready_ext,
        spw_Dout_p         => spw_Dout_p_net_0,
        spw_Dout_n         => OPEN,
        spw_Sout_p         => spw_Sout_p_net_0,
        spw_Sout_n         => OPEN,
        spw_error          => OPEN,
        rx_cmd_out         => OPEN,
        ccsds_data         => spw_rxlogic_top_0_ccsds_data,
        rx_data_out        => OPEN 
        );

end RTL;
