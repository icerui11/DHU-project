--------------------------------------------------------------------------------
-- Company: IDA
--
-- File: ShyLoc_top_Wrapper.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: CCSDS-123 IP Core and CCSDS-121 IP Core Wrapper
--
-- <Description here>
--
-- Targeted device: <Family::SmartFusion2> <Die::M2S150TS> <Package::1152 FC>
-- Author: Rui Yin
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;  

--! Use shyloc_121 library
library shyloc_121; 
--! Use generic shyloc121 parameters
use shyloc_121.ccsds121_parameters.all;
--! Use constant shyloc121 constants
use shyloc_121.ccsds121_constants.all;

--! Use shyloc_utils library
library shyloc_utils;
--! Use shyloc functions
use shyloc_utils.shyloc_functions.all;
--! Use amba functions
use shyloc_utils.amba.all;


entity ShyLoc_top_Wrapper is

port (
        -- System Interface
    Clk_S: in std_logic;            --! Clock signal.
    Rst_N: in std_logic;            --! Reset signal. Active low.
    
    -- Amba Interface
    AHBSlave121_In   : in AHB_Slv_In_Type;      --! AHB slave input signals.
    Clk_AHB          : in std_logic;                --!  AHB clock.
    Reset_AHB        : in std_logic;                --! AHB reset.
    AHBSlave121_Out  : out AHB_Slv_Out_Type;    --! AHB slave output signals.
    
    -- AHB 123 Slave interface, from 123
    AHBSlave123_In   : in  AHB_Slv_In_Type;   --! AHB slave input signals
    AHBSlave123_Out  : out AHB_Slv_Out_Type;  --! AHB slave input signals

    -- AHB 123 Master interface
    AHBMaster123_In  : in  AHB_Mst_In_Type;   --! AHB slave input signals
    AHBMaster123_Out : out AHB_Mst_Out_Type;  --! AHB slave input signals

    -- Data Input Interface
    DataIn_shyloc    :   in std_logic_vector (shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);                 --from the input interface 
    DataIn_NewValid  :   in std_logic;                          --! Flag to validate input signals.
    IsHeaderIn       :   in std_logic;                          --! The data in DataIn corresponds to the header of a pre-processor block.
    NbitsIn          :   in Std_Logic_Vector (5 downto 0);      --! Number of valid bits in the input header.      
    
    -- Data Output Interface CCSDS121
    DataOut           : out std_logic_vector (shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    DataOut_NewValid  : out std_logic;                  --! Flag to validate output bit stream.
    -- for CCSDS121 
    Ready_Ext         : in std_logic;             --! External receiver not ready.

    -- CCSDS123 IP Core Interface
    ForceStop         : in std_logic;             --! Force the stop of the compression.
    AwaitingConfig    : out std_logic;             --! The IP core is waiting to receive the configuration.
    Ready             : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
    FIFO_Full         : out std_logic;             --! The input FIFO is full.
    EOP               : out std_logic;             --! Compression of last sample has started.
    Finished          : out std_logic;             --! The IP has finished compressing all samples.
    Error             : out std_logic             --! There has been an error during the compression. ccsds123
    );

end ShyLoc_top_Wrapper;

architecture arch of ShyLoc_top_Wrapper is

    --signal declarations
    
    --interconnection signals   
    signal AwaitingConfig_Ext: std_logic;                                                                -- the signal from CCSDS-121 IP core to CCSDS-123 IP core
    signal Ready_121: std_logic;     
    signal FIFO_Full_Ext_121: std_logic;    
    signal EOP_Ext_121: std_logic;     
    signal Finished_Ext: std_logic;    
    signal Error_Ext: std_logic;                                                                         -- error signal from CCSDS121 to 123
    signal ForceStop_Ext: std_logic; 
    
    signal Block_DataIn_Valid:  std_logic;                                                               -- the signal from CCSDS-123 IP core to CCSDS-121 IP core DataIn_NewValid
    signal Block_Ready_Ext: std_logic; 
    signal Block_IsHeaderIn: std_logic; 
    signal Block_DataIn : Std_Logic_Vector(shyloc_123.ccsds123_parameters.W_BUFFER_GEN-1 downto 0);      -- the signal from CCSDS-123 IP core to CCSDS-121 IP core
    signal Block_NBitsIn: Std_Logic_Vector(5 downto 0); 
    signal ErrorCode_Ext: Std_Logic_Vector(3 downto 0); 

    begin
    ---------------------------
    --!@brief CCSDS-123 IP Core 
    ---------------------------
    ccsds123:  entity shyloc_123.ccsds123_top(arch)
    port map
      (
      clk_s            => clk_s, 
      rst_n            => rst_n, 
      clk_ahb          => Clk_ahb, 
      rst_ahb          => Reset_AHB, 

      DataIn           => DataIn_shyloc,                            --from the input interface 
      DataIn_NewValid  => DataIn_NewValid,                          --from the entity interface 
      AwaitingConfig   => open, 

      Ready            => Ready,                                    -- from the entity interface 
      FIFO_Full        => FIFO_Full, 
      EOP              => EOP,                                      -- output of 123, to entity      
      Finished         => Finished,                                  
      ForceStop        => ForceStop,                                -- from the entity interface
      Error            => Error,

      AHBSlave123_In   => AHBSlave123_In, 
      AHBSlave123_Out  => AHBSlave123_Out,   
      AHBMaster123_In  => AHBMaster123_In, 
      AHBMaster123_Out => AHBMaster123_Out,

      DataOut          => Block_DataIn,                            -- the signal from CCSDS-123 IP core to CCSDS-121 IP core
      DataOut_NewValid => Block_DataIn_Valid,                      -- the signal from CCSDS-123 IP core to CCSDS-121 IP core DataIn_NewValid
      IsHeaderOut      => Block_IsHeaderIn, 
      NbitsOut         => Block_NBitsIn,                           -- to the CCSDS-121 IP core

      --external encoder signals, when encoder_selection = 2 
      ForceStop_Ext    =>   ForceStop_Ext,
      AwaitingConfig_Ext => AwaitingConfig_Ext,                    -- from the CCSDS-121 IP core
      Ready_Ext       => Ready_121,                                -- from the CCSDS-121 IP core 
      FIFO_Full_Ext   => FIFO_Full_Ext_121,                        -- from the CCSDS-121 IP core
      EOP_Ext         => EOP_Ext_121,                              -- input from the CCSDS-121 IP core, compression of last sample has started
      Finished_Ext    => Finished_Ext,                              
      Error_Ext       => Error_Ext
      );

    	-- Instance of the CCSDS121-IP core
	ccsds121top: entity shyloc_121.ccsds121_shyloc_top(arch)
    port map (
        Clk_S => Clk_S, 
        Rst_N => Rst_N, 

        AHBSlave121_In          => 	AHBSlave121_In,                                    
        AHBSlave121_Out         =>  AHBSlave121_Out,
        
        Clk_AHB                 => Clk_AHB,
        Reset_AHB               => Reset_AHB,
        DataIn_NewValid         => Block_DataIn_Valid,                               -- from CCSDS 123 IP core
        DataIn                  => Block_DataIn,                                     -- from CCSDS 123 IP core                
        NBitsIn                 => Block_NBitsIn,                                          -- from CCSDS 123 IP core
        DataOut                 => DataOut, 
        DataOut_NewValid        => DataOut_NewValid,
        ForceStop               => ForceStop_Ext,                                    -- from CCSDS 123 
        IsHeaderIn              => Block_IsHeaderIn,                                 -- from CCSDS 123 IP core
        AwaitingConfig          => AwaitingConfig_Ext,                               -- to CCSDS 123 IP core
        Ready                   => Ready_121,                                        -- to CCSDS 123 IP core
        FIFO_Full               => FIFO_Full_Ext_121,                                -- to CCSDS 123 IP core
        EOP                     => EOP_Ext_121,                                      -- output of 121, compression of last sample has started
        Finished                => Finished_Ext,                                     -- to CCSDS 123 IP core
        Error                   => Error_Ext,
        Ready_Ext               => Ready_Ext		                                 -- from entity input
    );

    end arch;
