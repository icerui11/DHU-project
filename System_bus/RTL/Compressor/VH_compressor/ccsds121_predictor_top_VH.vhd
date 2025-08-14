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
-- Design unit  : ccsds121 predictor top module
--
-- File name    : ccsds121_predictor_top.vhd
--
-- Purpose      : Component instantiation of the ccsds121 predictor components, and control signals management 
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
-- Contact      : ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : fsm (ccsds121_predictor_fsm), inputfifo (fifop2), outputfifo (fifop2), components (ccsds121_predictor_comp)
--============================================================================

--!@file #ccsds121_predictor_top.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Component instantiation of the ccsds121 predictor components, and control signals management

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

library VH_compressor;
--! Use specific shyloc121 parameters
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;

--! Use shyloc_utils library
library shyloc_utils;
--! Use shyloc functions
use shyloc_utils.shyloc_functions.all;

--! ccsds121_predictor_top entity  Top module of the CCSDS121 pre-processing stage
entity ccsds121_predictor_top_VH is
  generic (
      D_GEN              : integer := D_GEN;  --! Maximum input sample bitwidth IP core is implemented for. 
      W_BUFFER_GEN       : integer := W_BUFFER_GEN;
      RESET_TYPE         : integer := RESET_TYPE;  --! Reset flavour asynchronous (0) synchronous (1)
      EDAC               : integer := EDAC; 
      TECH               : integer := TECH
    );
  port (
    -- System Interface
    Clk_S: in std_logic;            --! Clock signal.
    Rst_N: in std_logic;            --! Reset signal. Active low.
    
    -- Data Input Interface
    DataIn      : in std_logic_vector(D_GEN-1 downto 0);  --! Input data sample (uncompressed samples).
    DataIn_NewValid  : in std_logic;                --! Flag to validate input signals.      
    
    -- Data Output Interface
    DataOut        : out std_logic_vector (W_BUFFER_GEN-1 downto 0);  --! Output compressed bit stream.
    DataOut_NewValid  : out std_logic;                  --! Flag to validate output bit stream.
        
    -- Control Interface
    ForceStop    : in std_logic;             --! Force the stop of the compression.
    Ready_Ext    : in std_logic;             --! External receiver not ready.
    Control_out_s  : out ctrls;              --! Status flags (see below)
    --AwaitingConfig  : out std_logic;             --! The IP core is waiting to receive the configuration.
    --Ready        : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
    --FIFO_Full      : out std_logic;             --! The input FIFO is full.
    --EOP        : out std_logic;             --! Compression of last sample has started.
    --Finished      : out std_logic;             --! The IP has finished compressing all samples.
    --Error        : out std_logic             --! There has been an error during the compression.
    
    -- Configuration Interface
    config_s    : in config_121;            --! Current configuration parameters
    config_valid  : in std_logic            --! Validation of configuration parameters
      
  );
end ccsds121_predictor_top_VH;

--! @brief Architecture of ccsds121_predictor_top 
architecture arch of ccsds121_predictor_top_VH is
  -- fsm signals
  signal clear    : std_logic;
  signal bypass    : std_logic;
  signal sample_valid : std_logic;

  -- Input FIFO signals and configuration
  constant NE_FIFO_IN        : integer := 4;         
  constant W_ADDR_FIFO_IN      : integer := shyloc_utils.shyloc_functions.log2(NE_FIFO_IN);
  signal input_sample        : std_logic_vector (D_GEN-1 downto 0);    -- FIFO data output
  signal w_fifo_datain      : std_logic;
  signal r_fifo_datain      : std_logic;
  signal fifo_datain_empty    : std_logic;
  signal fifo_datain_aempty    : std_logic;
  signal fifo_datain_full      : std_logic;
  signal fifo_datain_afull     : std_logic;
  
  -- Output FIFO signals and configuration
  constant NE_FIFO_OUT      : integer := 4;         
  constant W_ADDR_FIFO_OUT    : integer := shyloc_utils.shyloc_functions.log2(NE_FIFO_OUT);
  signal processed_sample     : std_logic_vector(D_GEN-1 downto 0);  -- FIFO data input
  signal DataOut_s         : std_logic_vector(D_GEN-1 downto 0);  -- FIFO data output
  --signal w_fifo_dataout      : std_logic;      -- same as sample_valid
  signal r_fifo_dataout      : std_logic;
  signal fifo_dataout_empty    : std_logic;
  signal fifo_dataout_aempty    : std_logic;
  signal fifo_dataout_full    : std_logic;
  signal fifo_dataout_afull     : std_logic;  
  
  signal DataOut_NewValid_s    : std_logic;

begin
  ---------------------------
  --!@brief fsm
  ---------------------------
  fsm: entity VH_compressor.ccsds121_predictor_fsm(arch)
    generic map(
      RESET_TYPE =>   RESET_TYPE    --! Reset type.
    )
    port map(
      -- System Interface
      clk  =>          Clk_S,        --! Clock signal.
      rst_n =>        Rst_N,        --! Reset signal. Active low.
      
      -- Configuration Interface
      config_valid =>      config_valid,    --! Validation of configuration parameters
      config_s =>        config_s,      --! Current configuration parameters
      
      -- Control Interface
      DataIn_NewValid  =>    DataIn_NewValid,  --! Flag to validate input signals.  
      ForceStop =>      ForceStop,      --! Force the stop of the compression.
      Ready_Ext =>      Ready_Ext,      --! External receiver not ready.
      clear =>        clear,        --! Clear signal. Send the predictor to its initial state
      bypass =>        bypass,        --! Bypass preprocessor in order to insert reference samples
      Control_out_s =>    Control_out_s,    --! Status flags (see below)
      --AwaitingConfig    : out std_logic;         --! The IP core is waiting to receive the configuration.
      --Ready          : out std_logic;         --! Configuration has been received and the IP is ready to receive new samples.
      --FIFO_Full        : out std_logic;         --! The input FIFO is full.
      --EOP          : out std_logic;         --! Compression of last sample has started.
      --Finished        : out std_logic;         --! The IP has finished compressing all samples.
      --Error          : out std_logic         --! There has been an error during the compression.
      
      -- input FIFO control signals
      w_fifo_datain =>    w_fifo_datain,    --! Write request
      r_fifo_datain =>    r_fifo_datain,    --! Read request
      fifo_datain_empty =>  fifo_datain_empty,
      fifo_datain_full =>    fifo_datain_full,
      fifo_datain_afull =>  fifo_datain_afull,
      
      -- output FIFO control signals
      w_fifo_dataout =>    sample_valid,    --! Write request
      r_fifo_dataout =>    r_fifo_dataout,    --! Read request
      fifo_dataout_empty =>  fifo_dataout_empty,
      fifo_dataout_full =>  fifo_dataout_full
    );
  
  ---------------------------
  --!@brief components module
  ---------------------------
  components: entity VH_compressor.ccsds121_predictor_comp(arch)
    generic map(
      W_Sample =>   D_GEN,       --! Bit width of the samples and mapped prediction residuals.
      RESET_TYPE =>   RESET_TYPE    --! Reset type.
    )
    port map(
      -- System Interface
      clk =>      Clk_S,      --! Clock signal.
      rst_n =>    Rst_N,      --! Reset signal. Active low.
      clear =>    clear,      --! Clear signal.
      
      -- Configuration Interface
      config_valid =>  config_valid,  --! Validation of configuration parameters
      config_s =>    config_s,    --! Current configuration parameters
      
      -- Control Interface
      sample_valid =>  sample_valid,  --! Validates pre-processed sample
      bypass_pred  =>  bypass,      --! Bypass preprocessor in order to insert reference samples
      
      -- Data Interface
      SampleIn =>    input_sample,
      SampleOut =>  processed_sample
    );
  
  ---------------------------
  --!@brief input data FIFO
  ---------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  inputfifo: entity shyloc_utils.fifop2(arch)
  generic map (
    W =>       D_GEN,
    NE =>       NE_FIFO_IN,
    W_ADDR =>     W_ADDR_FIFO_IN,
    RESET_TYPE =>   RESET_TYPE, 
    EDAC => 0, 
    TECH =>     TECH
  )
  port map (
     Clk =>     Clk_S, 
     rst_n =>     Rst_N, 
     clr =>     clear, 
     w_update =>   w_fifo_datain,
     r_update =>   r_fifo_datain, 
     data_in =>   DataIn, 
     data_out =>   input_sample,
     full =>     fifo_datain_full,
     afull =>     fifo_datain_afull,
     empty =>     fifo_datain_empty,
     aempty =>     fifo_datain_aempty
  );
   
  ---------------------------
  --!@brief output data FIFO
  ---------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  outputfifo: entity shyloc_utils.fifop2(arch)
  generic map (
    W =>       D_GEN,
    NE =>       NE_FIFO_OUT,
    W_ADDR =>     W_ADDR_FIFO_OUT,
    RESET_TYPE =>   RESET_TYPE,
    EDAC => EDAC, 
    TECH =>     TECH
  )
  port map (
     Clk =>     Clk_S, 
     rst_n =>     Rst_N, 
     clr =>     clear, 
     w_update =>   sample_valid,
     r_update =>   r_fifo_dataout, 
     data_in =>   processed_sample, 
     data_out =>   DataOut_s,
     full =>     fifo_dataout_full,
     afull =>     fifo_dataout_afull,
     empty =>     fifo_dataout_empty,
     aempty =>     fifo_dataout_aempty
  );
  
  -- Delay r_fifo_dataout one cycle to obtain DataOut_NewValid
  process (Clk_S, Rst_N)
  begin
    if (Rst_N = '0' and RESET_TYPE = 0) then
      DataOut_NewValid_s <= '0';
    elsif (Clk_S'event and Clk_S = '1') then
      if (Rst_N = '0' and RESET_TYPE= 1) then
        DataOut_NewValid_s <= '0';
      else
        DataOut_NewValid_s <= r_fifo_dataout;
      end if;
    end if;
  end process;
  
   ---------------------------
  --!@brief output asignments
  ---------------------------
  DataOut <= std_logic_vector(resize(unsigned(DataOut_s),W_BUFFER_GEN));
  DataOut_NewValid <= DataOut_NewValid_s;
   
end arch;
