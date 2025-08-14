--============================================================================--
-- Copyright 2017 University of Las Palmas de Gran Canaria 
--
-- Institute for Applied Microelectronics (IUMA)
-- Campus Universitario de Tafira s/n
-- 35017, Las Palmas de Gran Canaria
-- Canary Islands, Spain
--
-- This code may be freely used, copied, modified, and redistributed
-- by the European Space Agency for the Agency's own requirements.
--============================================================================--
-- ESA IP-CORE LICENSE
--
-- This code is provided under the terms of the
-- ESA Licence (Agreement) on Synthesisable HDL Models,
-- which you have signed prior to receiving the code.
--
-- The code is provided "as is", there is no warranty that
-- the code is correct or suitable for any purpose,
-- neither implicit nor explicit. The code and the information in it
-- contained do not necessarily reflect the policy of the
-- European Space Agency or of <originator>.
--
-- No technical support is available from ESA for this IP core,
-- however, news on the IP will be posted on the web page:
-- http://www.esa.int/TEC/Microelectronics
--
-- Any feedback (bugs, improvements etc.) shall be reported to ESA
-- at E-Mail IpCoreRequest@esa.int
--============================================================================--
-- Design unit  : ccsds121 top module
--
-- File name    : ccsds121_shyloc_top.vhd
--
-- Purpose      : Component instantiation of the ccsds121 components, and control signals management 
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es, ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es
--
-- Instantiates : predictor (ccsds121_predictor_top), block coder (ccsds121_blockcoder_top)
--============================================================================

--!@file #ccsds121_shyloc_top.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es, ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es
--!@brief  Component instantiation of the ccsds121 components, and control signals management

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

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

--! ccsds121_shyloc_top entity  Top module of the CCSDS121 IP
--! Component instantiation of the ccsds121 components, and control signals management 
entity ccsds121_shyloc_top is
    generic (
    EN_RUNCFG            : integer := EN_RUNCFG;          --! (0) Disables runtime configuration; (1) Enables runtime configuration   
    RESET_TYPE           : integer := RESET_TYPE;         --! (0) Asynchronous reset; (1) Synchronous reset   
    EDAC                 : integer := EDAC;               --! (0) Inhibits EDAC implementation; (1) EDAC is implemented  
    HSINDEX_121          : integer := HSINDEX_121;        --! AHB slave index   
    HSCONFIGADDR_121     : integer := HSCONFIGADDR_121;   --! ADDR field of the AHB Slave  
    HSADDRMASK_121       : integer := HSADDRMASK_121;     --! MASK field of the AHB slave  

    Nx_GEN               : integer := Nx_GEN;             --! Maximum allowed number of samples in a line   
    Ny_GEN               : integer := Ny_GEN;             --! Maximum allowed number of samples in a row  
    Nz_GEN               : integer := Nz_GEN;             --! Maximum allowed number of bands  
    -- These parameters define format characteristics of input/output data  
    D_GEN                : integer := D_GEN;              --! Maximum dynamic range of the input samples  
    IS_SIGNED_GEN        : integer := IS_SIGNED_GEN;      --! (0) Unsigned samples; (1) Signed samples  
    ENDIANESS_GEN        : integer := ENDIANESS_GEN;      --! (0) Little-Endian; (1) Big-Endian  
    -- Compression Algorithm Parameters  

    J_GEN                : integer := J_GEN;              --! Block Size  
    REF_SAMPLE_GEN       : integer := REF_SAMPLE_GEN;     --! Reference Sample Interval   
    CODESET_GEN          : integer := CODESET_GEN;        --! Code Option  
    W_BUFFER_GEN         : integer := W_BUFFER_GEN;       --! Bit width of the output buffer  
    -- These parameters control integration with external systems  
    PREPROCESSOR_GEN     : integer := PREPROCESSOR_GEN;   --! (0) No preprocessor; (1) CCSDS123 preprocessor; (2) Other preprocessor  
    DISABLE_HEADER_GEN   : integer := DISABLE_HEADER_GEN; --! (0) Enable header; (1) Disable header  
    TECH                 : integer := TECH               --! Memory technology selection  
    );  
  port (
    -- System Interface
    Clk_S: in std_logic;            --! Clock signal.
    Rst_N: in std_logic;            --! Reset signal. Active low.
    
    -- Amba Interface
    AHBSlave121_In   : in ahb_slv_in_type;    --! AHB slave input signals.
    Clk_AHB      : in std_logic;        --!  AHB clock.
    Reset_AHB    : in std_logic;        --! AHB reset.
    AHBSlave121_Out  : out ahb_slv_out_type;    --! AHB slave output signals.
    
    -- Data Input Interface
    DataIn      : in std_logic_vector(D_GEN-1 downto 0);  --! Input data sample (uncompressed samples).
    DataIn_NewValid  : in std_logic;                --! Flag to validate input signals.
    IsHeaderIn    : in std_logic;               --! The data in DataIn corresponds to the header of a pre-processor block.
    NbitsIn      : in Std_Logic_Vector (5 downto 0);      --! Number of valid bits in the input header.      
    
    -- Data Output Interface
    DataOut        : out std_logic_vector (W_BUFFER_GEN-1 downto 0);  --! Output compressed bit stream.
    DataOut_NewValid  : out std_logic;                  --! Flag to validate output bit stream.
        
    -- Control Interface
    ForceStop    : in std_logic;             --! Force the stop of the compression.
    Ready_Ext    : in std_logic;             --! External receiver not ready.
    AwaitingConfig  : out std_logic;             --! The IP core is waiting to receive the configuration.
    Ready      : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
    FIFO_Full    : out std_logic;             --! The input FIFO is full.
    EOP        : out std_logic;             --! Compression of last sample has started.
    Finished    : out std_logic;             --! The IP has finished compressing all samples.
    Error      : out std_logic             --! There has been an error during the compression.
      
  );
end ccsds121_shyloc_top;
 
--! @brief Architecture of ccsds121_shyloc_top 
architecture arch of ccsds121_shyloc_top is
  --Endianess swapped input
  
  signal DataIn_swap      : std_logic_vector(D_GEN-1 downto 0);

  -- Predictor signals
  signal DataOut_pred: std_logic_vector(W_BUFFER_GEN-1 downto 0);
  signal DataOut_NewValid_pred: std_logic;
  signal stop: std_Logic;
  signal control_out_pred: ctrls;
  signal Pred_config: config_121;
  
  -- Block coder signals
  signal DataIn_coder: std_logic_vector(D_GEN-1 downto 0);
  signal DataIn_NewValid_coder, IsHeaderIn_coder: std_logic;
  signal NbitsIn_coder: std_logic_vector(5 downto 0);
  signal Stop_pred: std_logic;
  signal Ready_coder: std_logic;
  signal config_valid: std_logic;
  
begin

  ---------------------------
  --!@brief endianess swap
  ---------------------------
  gen_endianness_swap_32: if (D_GEN > 24) generate
    --curr_sample <= SampleIn(7 downto 0)&SampleIn(15 downto 8)&SampleIn(23 downto 16)&SampleIn(D_GEN-1 downto 24) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 24))
    DataIn_swap <= DataIn(D_GEN-25 downto 0)&DataIn(D_GEN-17 downto D_GEN-24)&DataIn(D_GEN-9 downto D_GEN-16)&DataIn(D_GEN-1 downto D_GEN-8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 24)) 
      else DataIn(D_GEN-1 downto 24)&DataIn(7 downto 0)&DataIn(15 downto 8)&DataIn(23 downto 16) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 16)) 
      else DataIn(D_GEN-1 downto 16)&DataIn(7 downto 0)&DataIn(15 downto 8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 8))
      else DataIn;
  end generate gen_endianness_swap_32;

  gen_endianness_swap_24: if ((D_GEN > 16) and(D_GEN <= 24)) generate
    --DataIn_swap <= DataIn(7 downto 0)&DataIn(15 downto 8)&DataIn(D_GEN-1 downto 16) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 16)) 
    DataIn_swap <= DataIn(D_GEN-17 downto 0)&DataIn(D_GEN-9 downto D_GEN-16)&DataIn(D_GEN-1 downto D_GEN-8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 16))
      else DataIn(D_GEN-1 downto 16)&DataIn(7 downto 0)&DataIn(15 downto 8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 8))
      else DataIn;
  end generate gen_endianness_swap_24;

  gen_endianness_swap_16: if ((D_GEN > 8) and(D_GEN <= 16)) generate
    --DataIn_swap <= DataIn(7 downto 0)&DataIn(D_GEN-1 downto 8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 8))
    DataIn_swap <=  DataIn(D_GEN-9 downto 0)&DataIn(D_GEN-1 downto D_GEN-8) when ((Pred_config.ENDIANESS = "0") and (Pred_config.BYPASS) = "0" and (unsigned(Pred_config.D) > 8))
      else DataIn;
  end generate gen_endianness_swap_16;
  
  gen_endianness_noswap: if (D_GEN <= 8) generate
    DataIn_swap <= DataIn;
  end generate gen_endianness_noswap;
  
  ---------------------------
  --!@brief predictor top
  ---------------------------
  gen_predictor: if (PREPROCESSOR_GEN = 2) generate

  begin
    predictor: entity shyloc_121.ccsds121_predictor_top(arch)
      port map (
        -- System Interface
        Clk_S => Clk_S,            --! Clock signal.
        Rst_N => Rst_N,            --! Reset signal. Active low.
        
        -- Data Input Interface
        DataIn =>      DataIn_swap,        --! Input data sample (uncompressed samples).
        DataIn_NewValid =>  DataIn_NewValid,  --! Flag to validate input signals.      
        
        -- Data Output Interface
        DataOut =>      DataOut_pred,      --! Output compressed bit stream.
        DataOut_NewValid =>  DataOut_NewValid_pred,  --! Flag to validate output bit stream.
            
        -- Control Interface
        ForceStop =>    stop,          --! Force the stop of the compression.
        Ready_Ext =>     Ready_coder,      --! External receiver not ready.
        Control_out_s =>  control_out_pred,            --! Status flags (see below)
        --AwaitingConfig  : out std_logic;             --! The IP core is waiting to receive the configuration.
        --Ready        : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
        --FIFO_Full      : out std_logic;             --! The input FIFO is full.
        --EOP        : out std_logic;             --! Compression of last sample has started.
        --Finished      : out std_logic;             --! The IP has finished compressing all samples.
        --Error        : out std_logic             --! There has been an error during the compression.
        
        -- Configuration Interface
        config_s =>    Pred_config,        --! Current configuration parameters
        config_valid =>    config_valid          --! Validation of configuration parameters
      );
  end generate;

  gen_nopredictor: if (PREPROCESSOR_GEN /= 2) generate

  begin
    DataOut_pred <= (others => '0');      
    DataOut_NewValid_pred <= '0';
    control_out_pred.AwaitingConfig <= '0';
    control_out_pred.Ready <= '0';
    control_out_pred.FIFO_Full <= '0';
    control_out_pred.EOP <= '0';
    control_out_pred.Finished <= '0';
    control_out_pred.Error <= '0';
    control_out_pred.ErrorCode <= (others =>'0');
  end generate;

  --------------------------
  --! Input data redirection (depending on whether preprocessor is present or not)
  --------------------------
  gen_input_pred: if (PREPROCESSOR_GEN = 2) generate

  begin
    DataIn_coder      <= std_logic_vector(resize(unsigned(DataOut_pred),D_GEN));
    DataIn_NewValid_coder  <= DataOut_NewValid_pred;
    IsHeaderIn_coder    <= '0';
    NbitsIn_coder      <= (others => '0');
  end generate;
  
  gen_input_nopred: if (PREPROCESSOR_GEN /= 2) generate

  begin
    DataIn_coder      <= DataIn_swap;
    DataIn_NewValid_coder  <= DataIn_NewValid;
    IsHeaderIn_coder    <= IsHeaderIn;
    NbitsIn_coder      <= NbitsIn;
  end generate;
  
  
  --------------------------
  --! Control signals redirection
  --------------------------
  stop <= ForceStop or Stop_pred;
  Ready <= control_out_pred.Ready when (PREPROCESSOR_GEN = 2)
    else Ready_coder;
  
  ---------------------------
  --!@brief block coder top
  ---------------------------
  blockcoder: entity shyloc_121.ccsds121_blockcoder_top(arch)
    port map(
      -- System Interface
      Clk_S => Clk_S,            --! Clock signal.
      Rst_N => Rst_N,            --! Reset signal. Active low.
      
      -- Amba Interface
      AHBSlave121_In =>  AHBSlave121_In,    --! AHB slave input signals.
      Clk_AHB =>      Clk_AHB,      --!  AHB clock.
      Reset_AHB =>    Reset_AHB,      --! AHB reset.
      AHBSlave121_Out =>  AHBSlave121_Out,  --! AHB slave output signals.
      
      -- Data Input Interface
      DataIn =>      DataIn_coder,      --! Input data sample (uncompressed samples).
      DataIn_NewValid =>  DataIn_NewValid_coder,  --! Flag to validate input signals.
      IsHeaderIn =>    IsHeaderIn_coder,    --! The data in DataIn corresponds to the header of a pre-processor block.
      NbitsIn =>      NbitsIn_coder,      --! Number of valid bits in the input header.      
      
      -- Data Output Interface
      DataOut =>      DataOut,      --! Output compressed bit stream.
      DataOut_NewValid =>  DataOut_NewValid,  --! Flag to validate output bit stream.
          
      -- Control Interface
      ForceStop =>     ForceStop,      --! Force the stop of the compression.
      Ready_Ext =>    Ready_Ext,      --! External receiver not ready.
      Stop_pred =>    Stop_pred,      --! Stop signal for the unit-delay predictor
      config_s_out =>    Pred_config,
      config_valid_out =>  config_valid,
      Control_pred =>    control_out_pred,  --! Control flags from predictor
      AwaitingConfig =>   AwaitingConfig,    --! The IP core is waiting to receive the configuration.
      Ready =>       Ready_coder,    --! Configuration has been received and the IP is ready to receive new samples.
      FIFO_Full =>     FIFO_Full,      --! The input FIFO is full.
      EOP =>         EOP,        --! Compression of last sample has started.
      Finished =>     Finished,      --! The IP has finished compressing all samples.
      Error =>       Error        --! There has been an error during the compression.
    );
end arch;
