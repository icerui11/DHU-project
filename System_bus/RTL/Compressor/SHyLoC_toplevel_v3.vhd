--------------------------------------------------------------------------------
-- Company: IDA
-- Author: Rui Yin
-- File: SHyLoC_toplevel_v2.vhd
-- File history:
--      <v2.0>: <05.04.2025>: <Modified to support conditional component instantiation>
--      <v1.0>: <Original version>
-- 
-- Description: CCSDS-123 IP Core and CCSDS-121 IP Core Wrapper
-- Dynamically configures for three different modes:
-- 1) 1D compression: Both preprocessor and encoder use CCSDS121
-- 2) 3D compression: CCSDS123 with sample-adaptive encoder
-- 3) 3D compression: CCSDS123 preprocessor with CCSDS121 block-adaptive encoder
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


entity SHyLoC_toplevel_v2 is  

port (
        -- System Interface
    Clk_S: in std_logic;            --! Clock signal.
    Rst_N: in std_logic;            --! Reset signal. Active low.
    
    -- Amba Interface
    AHBSlave121_In   : in AHB_Slv_In_Type;      --! AHB slave input signals.
    Clk_AHB          : in std_logic;            --!  AHB clock.
    Reset_AHB        : in std_logic;            --! AHB reset.
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
    
    -- Data Output Interface CCSDS121
    DataOut           : out std_logic_vector (shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    DataOut_NewValid  : out std_logic;                  --! Flag to validate output bit stream.
    -- for CCSDS121 
    Ready_Ext         : in std_logic;             --! External receiver not ready.

    -- CCSDS123 IP Core Interface
    ForceStop         : in std_logic;             --! Force the stop of the compression.
    AwaitingConfig    : out std_logic;             --! The IP core is waiting to receive the configuration.from 123
    Ready             : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
    FIFO_Full         : out std_logic;             --! The input FIFO is full.
    EOP               : out std_logic;             --! Compression of last sample has started.
    Finished          : out std_logic;             --! The IP has finished compressing all samples.
    Error             : out std_logic             --! There has been an error during the compression. ccsds123
    );

end SHyLoC_toplevel_v2;

architecture arch of SHyLoC_toplevel_v2 is
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

    -- Internal signals for 1D mode
    signal DataOut_1D: std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal DataOut_NewValid_1D: std_logic;
    signal AwaitingConfig_1D: std_logic;
    signal Ready_1D: std_logic;
    signal FIFO_Full_1D: std_logic;
    signal EOP_1D: std_logic;
    signal Finished_1D: std_logic;
    signal Error_1D: std_logic;

    -- Internal signals for 3D mode with internal encoder
    signal DataOut_3D_Int: std_logic_vector(shyloc_123.ccsds123_parameters.W_BUFFER_GEN-1 downto 0);
    signal DataOut_NewValid_3D_Int: std_logic;
    signal AwaitingConfig_3D_Int: std_logic;
    signal Ready_3D_Int: std_logic;
    signal FIFO_Full_3D_Int: std_logic;
    signal EOP_3D_Int: std_logic;
    signal Finished_3D_Int: std_logic;
    signal Error_3D_Int: std_logic;

    -- Constants for configuration detection
    constant MODE_1D : boolean := (shyloc_121.ccsds121_parameters.PREPROCESSOR_GEN = 2) and 
                                  (shyloc_123.ccsds123_parameters.ENCODING_TYPE = 0);
    constant MODE_3D_sample : boolean := (shyloc_123.ccsds123_parameters.ENCODING_TYPE = 1);
    constant MODE_3D_EXTERNAL : boolean := (shyloc_123.ccsds123_parameters.ENCODING_TYPE = 0) and
                                          (shyloc_121.ccsds121_parameters.PREPROCESSOR_GEN = 1);

begin

    ---------------------------
    -- Mode Selection Logic
    ---------------------------
    
    -- 1D mode: CCSDS121 with internal preprocessor
    GEN_1D_MODE: if MODE_1D generate
        ccsds121_only: entity shyloc_121.ccsds121_shyloc_top(arch)
        port map (
            Clk_S               => Clk_S, 
            Rst_N               => Rst_N, 
            AHBSlave121_In      => AHBSlave121_In,                                    
            AHBSlave121_Out     => AHBSlave121_Out,
            Clk_AHB             => Clk_AHB,
            Reset_AHB           => Reset_AHB,
            DataIn_NewValid     => DataIn_NewValid, 
            DataIn              => DataIn_shyloc, 
            NBitsIn             => (others => '0'),  -- Not used in this mode
            DataOut             => DataOut, 
            DataOut_NewValid    => DataOut_NewValid,
            ForceStop           => ForceStop,
            IsHeaderIn          => '0',              -- Not used in this mode
            AwaitingConfig      => AwaitingConfig,
            Ready               => Ready,
            FIFO_Full           => FIFO_Full,
            EOP                 => EOP,
            Finished            => Finished,
            Error               => Error,
            Ready_Ext           => Ready_Ext
        );
        
    end generate GEN_1D_MODE;
    
    -- 3D mode: CCSDS123 with internal sample-adaptive encoder
    GEN_3D_INTERNAL_MODE: if MODE_3D_sample generate
        ccsds123_only: entity shyloc_123.ccsds123_top(arch)
        port map (
            Clk_S               => Clk_S, 
            Rst_N               => rst_n, 
            Clk_AHB             => Clk_AHB,
            Rst_AHB             => Reset_AHB,
            DataIn              => DataIn_shyloc,
            DataIn_NewValid     => DataIn_NewValid,
            AwaitingConfig      => AwaitingConfig,
            Ready               => Ready,
            FIFO_Full           => FIFO_Full,
            EOP                 => EOP,
            Finished            => Finished,
            ForceStop           => ForceStop,
            error               => Error,
            AHBSlave123_In      => AHBSlave123_In, 
            AHBSlave123_Out     => AHBSlave123_Out,   
            AHBMaster123_In     => AHBMaster123_In, 
            AHBMaster123_Out    => AHBMaster123_Out,
            DataOut             => DataOut,
            DataOut_NewValid    => DataOut_NewValid,
            IsHeaderOut         => open,  -- Not connected in this mode
            NbitsOut            => open,  -- Not connected in this mode

            -- External encoder signals not used in this mode
            ForceStop_Ext       => open,
            AwaitingConfig_Ext  => '0',
            Ready_Ext           => Ready_Ext,
            FIFO_Full_Ext       => '0',
            EOP_Ext             => '0',
            Finished_Ext        => '0',
            Error_Ext           => '0'
        );
        
    end generate GEN_3D_INTERNAL_MODE;
    
    -- 3D mode: CCSDS123 preprocessor with CCSDS121 block-adaptive encoder
    GEN_3D_EXTERNAL_MODE: if MODE_3D_EXTERNAL generate
        ---------------------------
        --! CCSDS-123 IP Core (Preprocessor)
        ---------------------------
        ccsds123: entity shyloc_123.ccsds123_top(arch)
        port map (
            clk_s            => clk_s, 
            rst_n            => rst_n, 
            clk_ahb          => Clk_ahb, 
            rst_ahb          => Reset_AHB, 
            DataIn           => DataIn_shyloc,
            DataIn_NewValid  => DataIn_NewValid,
            AwaitingConfig   => AwaitingConfig, 
            Ready            => Ready,
            FIFO_Full        => FIFO_Full, 
            EOP              => EOP,
            Finished         => Finished,
            ForceStop        => ForceStop,
            Error            => Error,
            AHBSlave123_In   => AHBSlave123_In, 
            AHBSlave123_Out  => AHBSlave123_Out,   
            AHBMaster123_In  => AHBMaster123_In, 
            AHBMaster123_Out => AHBMaster123_Out,
            DataOut          => Block_DataIn,
            DataOut_NewValid => Block_DataIn_Valid,
            IsHeaderOut      => Block_IsHeaderIn, 
            NbitsOut         => Block_NBitsIn,
            ForceStop_Ext    => ForceStop_Ext,
            AwaitingConfig_Ext => AwaitingConfig_Ext,
            Ready_Ext        => Ready_121,
            FIFO_Full_Ext    => FIFO_Full_Ext_121,
            EOP_Ext          => EOP_Ext_121,
            Finished_Ext     => Finished_Ext,
            Error_Ext        => Error_Ext
        );

        -- Instance of the CCSDS121-IP core (Encoder)
        ccsds121top: entity shyloc_121.ccsds121_shyloc_top(arch)
        port map (
            Clk_S => Clk_S, 
            Rst_N => Rst_N, 
            AHBSlave121_In          => AHBSlave121_In,                                    
            AHBSlave121_Out         => AHBSlave121_Out,
            Clk_AHB                 => Clk_AHB,
            Reset_AHB               => Reset_AHB,
            DataIn_NewValid         => Block_DataIn_Valid,
            DataIn                  => Block_DataIn,
            NBitsIn                 => Block_NBitsIn,
            DataOut                 => DataOut, 
            DataOut_NewValid        => DataOut_NewValid,
            ForceStop               => ForceStop_Ext,
            IsHeaderIn              => Block_IsHeaderIn,
            AwaitingConfig          => AwaitingConfig_Ext,
            Ready                   => Ready_121,
            FIFO_Full               => FIFO_Full_Ext_121,
            EOP                     => EOP_Ext_121,
            Finished                => Finished_Ext,
            Error                   => Error_Ext,
            Ready_Ext               => Ready_Ext
        );
    end generate GEN_3D_EXTERNAL_MODE;

end arch;