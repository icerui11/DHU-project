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
-- Design unit  : ccsds121_predictor_fsm 
--
-- File name    : ccsds121_predictor_fsm.vhd
--
-- Purpose      : FSM to control the behaviour of the unit-delay predictor.
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
--============================================================================

--!@file #ccsds121_predictor_fsm.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  FSM to control the behaviour of the unit-delay predictor.

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

--! ccsds121_predictor_fsm entity Controls the behaviour of the pre-processor.
entity ccsds121_predictor_fsm is
  generic(
    RESET_TYPE  : integer := 1        --! Reset type
  );
  port(
    -- System Interface
    clk      : in std_logic;        --! Clock signal
    rst_n    : in std_logic;        --! Reset signal. Active low
    
    -- Configuration Interface
    config_valid    : in std_logic;    --! Validation of configuration parameters
    config_s      : in config_121;  --! Current configuration parameters
    
    -- Control Interface
    DataIn_NewValid  : in std_logic;      --! Flag to validate input signals.  
    ForceStop    : in std_logic;     --! Force the stop of the compression.
    Ready_Ext    : in std_logic;     --! External receiver not ready.
    clear      : out std_logic;      --! Clear signal. Send the predictor to its initial state
    bypass      : out std_logic;    --! Bypass preprocessor in order to insert reference samples
    Control_out_s  : out ctrls;      --! Status flags (see below)
    --AwaitingConfig  : out std_logic;         --! The IP core is waiting to receive the configuration.
    --Ready        : out std_logic;         --! Configuration has been received and the IP is ready to receive new samples.
    --FIFO_Full      : out std_logic;         --! The input FIFO is full.
    --EOP        : out std_logic;         --! Compression of last sample has started.
    --Finished      : out std_logic;         --! The IP has finished compressing all samples.
    --Error        : out std_logic         --! There has been an error during the compression.
    
    -- input FIFO control signals
    w_fifo_datain    : out std_logic;  --! Write request
    r_fifo_datain    : out std_logic;  --! Read request
    fifo_datain_empty  : in std_logic;
    fifo_datain_full  : in std_logic;
    fifo_datain_afull  : in std_logic;
    
    -- output FIFO control signals
    w_fifo_dataout    : out std_logic;  --! Write request
    r_fifo_dataout    : out std_logic;  --! Read request
    fifo_dataout_empty  : in std_logic;
    fifo_dataout_full  : in std_logic
  );
end ccsds121_predictor_fsm;

--! @brief Architecture of ccsds121_predictor_fsm 
architecture arch of ccsds121_predictor_fsm is

  -- signals for the state machine
  type state_type_pred is (idle, preprocess, halted, finish, no_state);
  signal curr_state, next_state, prev_state: state_type_pred;    -- Modified by AS: prev_state signal added to control input samples
  
  -- internal counters
  signal ref_sample_count :  unsigned((W_J_GEN + W_REF_SAMPLE_GEN - 1) downto 0);
  signal samples_count :    unsigned((W_Nx_GEN + W_Ny_GEN + W_Nz_GEN - 1) downto 0);
  
  -- control signals
  signal ref_sample_int :   unsigned((W_J_GEN + W_REF_SAMPLE_GEN - 1) downto 0);
  signal sample_valid :    std_logic;
  signal processing_sample :  std_logic;
  signal datain_read_en :    std_logic;
  signal datain_write_en :  std_logic;
  signal clear_f :      std_logic;
  
  signal AwaitingConfig :   std_logic;         --! The IP core is waiting to receive the configuration.
  signal Ready :        std_logic;         --! Configuration has been received and the IP is ready to receive new samples.
  signal FIFO_Full :      std_logic;         --! The input FIFO is full.
  signal EOP :        std_logic;         --! Compression of last sample has started.
  signal finished :      std_logic;         --! The IP has finished compressing all samples.
  signal Error :        std_logic;         --! There has been an error during the compression.
  signal ErrorCode :      std_logic_vector(3 downto 0);
  signal Ready_Ext_d1, Ready_Ext_d2, Ready_out: std_logic;
begin

   Ready <= Ready_out and (Ready_Ext and Ready_Ext_d2);
  ----------------------------------
  -- state machine behaviour
  ----------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      curr_state <= idle;
      prev_state <= idle;              -- Modified by AS: prev_state signal initialized
      Ready_Ext_d2 <= '0';
      Ready_Ext_d1 <= '0';
    elsif (clk'event and clk = '1') then
      if (rst_n = '0' and RESET_TYPE= 1) then
        curr_state <= idle;
        prev_state <= idle;            -- Modified by AS: prev_state signal initialized
        Ready_Ext_d2 <= '0';
        Ready_Ext_d1 <= '0';
      else
        curr_state <= next_state;
        prev_state <= curr_state;        -- Modified by AS: prev_state registers the previous state
        Ready_Ext_d1 <= Ready_Ext;
        Ready_Ext_d2 <= Ready_Ext_d1;
      end if;
      
    end if;
  end process;
  
  process(curr_state, config_valid, ForceStop, Ready_Ext, fifo_datain_full, Ready_Ext_d2)
  begin
    AwaitingConfig <=  '0';
    Ready_out <=       '0';
    Error <=       '0';
    ErrorCode <=    (others => '0');
    clear_f <=      '0';
    case curr_state is
    when idle =>
      AwaitingConfig <= '1';
      if (config_valid = '1') then
        next_state <= preprocess;
      else
        next_state <= idle;
      end if;
    when preprocess =>
      Ready_out <= (not fifo_datain_full); 
      if (ForceStop = '1') then    -- Should we include the condition (finished = '1')?
        --clear_f <= '1';
        next_state <= finish;
      elsif (Ready_Ext = '0') then  -- Check halted init condition
        next_state <= halted;
      else
        next_state <= preprocess;
      end if;
    when halted =>
      if (ForceStop = '1') then
        --clear_f <= '1';
        next_state <= finish;
      elsif (Ready_Ext = '1') then  -- Check resume preprocessing condition
        next_state <= preprocess;
      else
        next_state <= halted;
      end if;
    -- Modified by AS: additional state to insert one cycle delay when ForceStop is activated. FIFO clear must be done in this state
    when finish =>
      clear_f <= '1';
      next_state <= idle;
    -----------------------
    when others =>
      Error <= '1';
      ErrorCode <= "0100";
      next_state <= idle;
    end case;
  end process;
  
  ----------------------------------
  -- input FIFO control
  ----------------------------------
  -- FIFO full condition
  FIFO_Full <= fifo_datain_full and datain_write_en;      -- Detect write error.
  --FIFO_Full <= fifo_datain_full and fifo_datain_afull;    -- Almost full condition (old condition);
  
  -- Write input data
  datain_write_en <= '1' when (DataIn_NewValid = '1') and (fifo_datain_full = '0')      -- Modified by AS: the reading of input samples is controlled with prev_state, not by curr_state
    else '0';
  w_fifo_datain <= datain_write_en;
  
  -- Read input data
  datain_read_en <= '1' when ((curr_state = preprocess) and (fifo_datain_empty = '0') and ((processing_sample = '0') or (sample_valid = '1')))
    else '0'; 
  r_fifo_datain <= datain_read_en;
  
  ----------------------------------
  -- output FIFO control
  ----------------------------------
  -- Validate preprocessed data
  sample_valid <= '1' when ((curr_state = preprocess) and (processing_sample = '1') and (fifo_dataout_full = '0'))
    else '0';
  
  -- Write output data
  w_fifo_dataout <=  sample_valid;
  
  -- Read output data
  r_fifo_dataout <= '1' when ((Ready_Ext = '1') and (fifo_dataout_empty = '0'))
    else '0';
  
  ----------------------------------
  -- Internal counters
  ----------------------------------
  -- Total sample counter
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      samples_count <= to_unsigned(0, W_Nx_GEN + W_Ny_GEN + W_Nz_GEN);
    elsif (clk'event and clk = '1') then
      if (clear_f = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        samples_count <= to_unsigned(0, W_Nx_GEN + W_Ny_GEN + W_Nz_GEN);
      elsif (curr_state = preprocess) then
        if (sample_valid = '1') then
          samples_count <= samples_count - 1;
        end if;
      elsif ((config_valid = '1') and (curr_state = idle)) then    -- Modified by AS: samples_count cannot be reset while the preprocessor is halted
        samples_count <= (unsigned(config_s.Nx) * unsigned(config_s.Ny) * unsigned(config_s.Nz));
      end if;
    end if;
  end process;
  
  -- Reference sample interval computation
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      ref_sample_int <= to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN);
    elsif (clk'event and clk = '1') then
      if (clear_f = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ref_sample_int <= to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN);
      elsif (config_valid = '1') then
        ref_sample_int <= (unsigned(config_s.J) * unsigned(config_s.REF_SAMPLE));
      end if;
    end if;
  end process;
  
  -- Reference sample counter
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      ref_sample_count <= to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN);
    elsif (clk'event and clk = '1') then
      if (clear_f = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ref_sample_count <= to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN);
      elsif ((curr_state = preprocess) and (sample_valid = '1')) then
        if (ref_sample_count = to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN)) then
          ref_sample_count <= ref_sample_int - 1;
        else
          ref_sample_count <= ref_sample_count - 1;
        end if;
      end if;
    end if;
  end process;
  
  ----------------------------------
  -- Control signals
  ----------------------------------
  -- Flag to indicate if there is a valid data in the preprocessing path
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      processing_sample <= '0';
    elsif (clk'event and clk = '1') then
      if (clear_f = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        processing_sample <= '0';
      else
        if (datain_read_en = '1') then
          processing_sample <= '1';
        elsif (sample_valid = '1') then
          processing_sample <= '0';
        end if;
      end if;
    end if;
  end process;
    
  -- Finish and EOP flags
  EOP <= '1' when ((samples_count = to_unsigned(1, W_Nx_GEN + W_Ny_GEN + W_Nz_GEN)) and (curr_state = preprocess))
    else '0';
  finished <= '1' when ((samples_count = to_unsigned(0, W_Nx_GEN + W_Ny_GEN + W_Nz_GEN)) and (curr_state = preprocess))
    else '0';
  
  ----------------------------------
  -- Output assignments
  ----------------------------------
  clear <= clear_f;
  bypass <= '1' when ((curr_state = preprocess) and (ref_sample_count = to_unsigned(0, W_J_GEN + W_REF_SAMPLE_GEN)))
    else '0';
  Control_out_s.AwaitingConfig <=  AwaitingConfig;
  Control_out_s.Ready <=      Ready;
  Control_out_s.FIFO_Full <=    FIFO_Full;
  Control_out_s.EOP <=      EOP;
  Control_out_s.Finished <=    finished;
  Control_out_s.Error <=      Error;
  Control_out_s.ErrorCode <=    ErrorCode;
end arch;
