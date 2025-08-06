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
-- Design unit  : ccsds121_shyloc_fsm 
--
-- File name    : ccsds121_shyloc_fsm.vhd
--
-- Purpose      : FSM to control the behaviour of the encoder.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--============================================================================

--!@file #ccsds121_shyloc_fsm.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  FSM to control the behaviour of the encoder.

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

--! ccsds121_shyloc_fsm entity Controls the behaviour of the encoder.
entity ccsds121_shyloc_fsm is
  generic (
    W_MAP    : integer := 32;       --! Bit width of the mapped prediction residuals
    W_NBITS_K : integer := 6;       --! Bit width of "k".
    W_BUFFER  : integer := 32;      --! Bit width of the output buffer.
    N_SAMPLES : integer := 58720256;    --! Total number of samples - default value is the AVIRIS size.
    W_N_SAMPLES : integer := 32;        --! Bit width of the sample counter.
    BLOCK_SIZE  : integer := 16;      --! Size of a block (J)
    RESET_TYPE  : integer := 1;      --! Reset type
    -- Modified by AS & YB: new generic to specify the zero_code size
    W_ZERO    : integer := 7      --! Bit width of the zero_block counter.
  );
  port (
    -- System Interface
    clk     : in std_logic;       --! Clock signal
    rst_n   : in std_logic;       --! Reset signal. Active low
    
    -- Control Interface
    error       : in std_logic;     --! Error asserted
    enable        : in std_logic;     --! Enable compression (with AMBA configuration parameters)
    valid_ahb_s     : in std_logic;     --! Validation of AMBA configuration parameters reception
    --last_DataIn     : in std_logic;     --! Last sample input flag    
    number_of_samples   : in std_logic_vector(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);  --! Number of samples to compress
    clear       : in std_logic;     --! Clear signal. Send the FSM to its initial state
    eop         : out std_logic;    --! Compression of the last samples has started
    finished_out    : out std_logic;    --! Finished signal. Compression has finished
    zero_mapped_out   : out std_logic;    --! mapped prediction residuals forced to zero
    fsm_invalid_state : out std_logic;    --! Invalid state signal
    
    -- Configuration Interface
    config_valid    : in std_logic;     --! Validation of configuration parameters
    config_int      : in config_121;    --! Current configuration parameters
    en_interface_out  : out std_logic;    --! Enable interface module
    
    
    -- Header generation module
    en_header_out: out std_logic;     --! Enable header generation module
    
    -- fifo header_in signals
    fifo_headerin_aempty  : in std_logic;   --! Almost empty
    fifo_headerin_empty   : in std_logic;   --! Empty
    r_update_headerin_out : out std_logic;  --! Read request
    
    -- fifo data_in signals
    w_update_fifo_datain  : out std_logic;  --! Write request
    r_update_mapped_in_out  : out std_logic;  --! Read request
    
    -- fifo mapped signals 
    mapped_fifo_aempty    : in std_logic;   --! Almost empty
    mapped_fifo_empty   : in std_logic;   --! Empty
    w_update_mapped_out   : out std_logic;  --! Write request
    r_update_mapped_out   : out std_logic;  --! Read request
    
    -- fifo gamma
    r_update_gamma_out  : out std_logic;    --! Read request
    
    -- split fifo
    r_update_split_out  : out std_logic;    --! Read request
    
    -- Second extension signals
    en_sndextension_out   : out std_logic;  --! Enable second extension module
    clear_sndextension_out  : out std_logic;  --! Clear second extension module
    
    -- lk computation module signals
    zero_code       : in std_logic_vector (1 downto 0);   --! Code for zero option
    en_lk_out       : out std_logic;            --! Enable lk computation
    clear_lkoptions_out   : out std_logic;            --! Clear lk computation
    en_k_winner_out     : out std_logic;            --! Enable the computation of the k_winner
    eos_out         : out std_logic;            --! End of segment/reference sample flag
    dump_zeroes_out     : out std_logic;            --! Zeroes have to be dumped
    -- Modified by AS: new interface ports --
    zero_count  : in std_logic_vector (W_ZERO-1 downto 0);          --! Counter for zero block.
    ref_block_lk      : out std_logic;            --! Reference sample included in the current block (for length computation)
    ref_block_fs      : out std_logic;            --! Reference sample included in the current block (for fs coder)
    ------------------------------------
    
    -- Option coder module signals
    option_in       : in std_logic_vector (W_OPT_GEN-1 downto 0);   --! Code option
    en_optcoder_out     : out std_logic;                  --! Enable option coder module
    
    -- fs coder module signals
    en_fscoder_out    : out std_logic;    --! Enable fs coder module
    start_fscoder_out : out std_logic;    --! Start signal
    
    -- Split packer module signals
    we_fifo_split_in    : in std_logic;     --! To count the amount of words written in FIFO split
    en_bitpack_split_out  : out std_logic;    --! Enable splitacker module
    flush_split_out     : out std_logic;    --! Flush split 
    
    -- Splitter module signals
    en_splitter_out     : out std_logic;  --! Enable splitter module
    start_splitter_out    : out std_logic;  --! Start signal
    
    -- Packing final module signals
    en_bitpack_final_out      : out std_logic;  --! Flag to enable packing of the final codewords
    flag_pack_header_out      : out std_logic;  --! Flag to enable packing the generated header
    flag_pack_header_prep_out   : out std_logic;  --! Flag to pack header from pre-processor
    flag_pack_fs_out        : out std_logic;  --! Flag to enable packing of the FS codeword.
    flag_split_flush_register_out : out std_logic;  --! Flag to pack the flush register of split bits
    flag_split_fifo_out       : out std_logic;  --! Flag to enable packing of split bits allocated in split FIFO
    flag_pack_bypass_out      : out std_logic;  --! Flag to enable packing of the residuals
    flush_final_out         : out std_logic   --! Flag to perform a flush at the end of the compressed file

  );
end ccsds121_shyloc_fsm;

--! @brief Architecture of ccsds121_shyloc_fsm 
architecture arch of ccsds121_shyloc_fsm is
  
  constant W_COUNT: integer := log2(BLOCK_SIZE);
  
  ----------------------------------
  -- signals for the state machines
  ----------------------------------
  -- AMBA state machine
  type state_type_amba is (idle, s1, s2, no_state);
  signal state_reg_amba, state_next_amba: state_type_amba;
  -- Interface state machine
  type state_type_interface is (idle, s1, s2, no_state);
  signal state_reg_interface, state_next_interface: state_type_interface;
  -- Preprocessing header state machine
  type state_type_header_prep is (idle, header_prep_stage, header_prep_done, no_state);
  signal state_reg_header_prep, state_next_header_prep: state_type_header_prep;
  -- Header state machine
  type state_type_header is (idle, processing_header, header_done, no_state);
  signal state_reg_header, state_next_header: state_type_header;
  -- fsm1 state machine (to control input sample requests, and later lk computation, second extension  and option coder control signals)
  type state_type is (idle, s1, s2, s3, s4, s_bypass, s_bypass_d1, s_bypass_d2, s_bypass_d3, s_bypass_d4, s_bypass_d5, finish, no_state);
  signal state_reg_fsm1, state_next_fsm1: state_type;
  -- fsm2 state machine
  type state_type2 is (idle, s1, s2, s3, s4, no_state);
  signal state_reg_fsm2, state_next_fsm2: state_type2;
  -- fsm3 state machine
  type state_type3 is (idle, fs, lapse, split, flush1, flush2, flush3, no_state);
  signal state_reg_fsm3, state_next_fsm3: state_type3;
  attribute syn_encoding: string;
  attribute syn_encoding of state_reg_amba: signal is "onehot";
  
  -- generic invalid state signal
  signal fsm_invalid_state_reg, fsm_invalid_state_reg_amba, fsm_invalid_state_reg_interface, fsm_invalid_state_reg_header_prep, fsm_invalid_state_reg_header, fsm_invalid_state_reg_fsm1, fsm_invalid_state_reg_fsm2, fsm_invalid_state_reg_fsm3, fsm_invalid_state_reg_amba_cmb, fsm_invalid_state_reg_interface_cmb, fsm_invalid_state_reg_header_prep_cmb, fsm_invalid_state_reg_header_cmb, fsm_invalid_state_reg_fsm1_cmb, fsm_invalid_state_reg_fsm2_cmb, fsm_invalid_state_reg_fsm3_cmb : std_logic;
  
  -- Counters for the state machines
  signal counter1, counter1_cmb, counter2, counter2_cmb: unsigned (W_COUNT-1 downto 0) := (others => '0');
  signal counter3, counter3_cmb, counter4, counter4_cmb: unsigned (W_COUNT-1 downto 0) := (others => '0');

  
  -- Intermediate signals
  signal r_update_mapped_in     : std_logic;
  signal r_update_mapped_in_cmb   : std_logic;
  signal r_update_headerin      : std_logic;
  signal r_update_headerin_cmb    : std_logic;
  signal r_update_mapped        : std_logic;
  signal r_update_mapped_cmb      : std_logic;
  signal r_update_gamma       : std_logic;
  signal r_update_gamma_cmb     : std_logic;
  signal r_update_split       : std_logic;
  signal r_update_split_cmb     : std_logic;
  
  signal w_update_mapped        : std_logic;
  signal w_update_fifo_datain_out   : std_logic;
  signal w_update_fifo_datain_out_cmb : std_logic;
  
  signal en_sndextension  : std_logic;
  signal en_lk      : std_logic;
  signal en_k_winner    : std_logic;
  signal en_optcoder    : std_logic;
  signal en_fscoder, en_fscoder_later   : std_logic;
  signal en_bitpack_split : std_logic;
  signal start_fscoder  : std_logic;  
  signal en_splitter    : std_logic;
  signal en_splitter_cmb  : std_logic;
  signal en_bitpack_final : std_logic;
  signal en_header    : std_logic;
  signal en_header_cmb  : std_logic;
  signal en_interface   : std_logic;
  signal en_interface_cmb : std_logic;
  signal start_prep   : std_logic;
  signal start_prep_cmb : std_logic;
  signal start_int    : std_logic;
  signal start_int_cmb  : std_logic;
  signal start_splitter : std_logic;
  signal start_fsm1   : std_logic;
  signal start_fsm1_cmb : std_logic;
  signal start_bypass   : std_logic;
  signal start_bypass_cmb : std_logic;
  signal start_header   : std_logic;
  signal start_header_cmb : std_logic;
  
  -- Modified by AS: shift register to propagate the ref_block signal from FSM1 to FSM2 --
  signal ref_block_s    : std_logic;
  signal ref_block_shift  : std_logic_vector(2 downto 0);
  signal ref_zero_block    : std_logic;
  ------------------------------------
  
  signal clear_sndextension   : std_logic;
  signal clear_sndextension_cmb : std_logic;
  signal clear_lkoptions      : std_logic;
  signal clear_lkoptions_cmb    : std_logic;
  
  
  signal flush_split      : std_logic;
  signal flush_split_d1   : std_logic;
  signal flush_final      : std_logic;
  signal flush_final_cmb    : std_logic;
  signal flush_final_2    : std_logic;
  signal flush_final_2_cmb  : std_logic;
  signal flush_bypass     : std_logic;
  signal flush_bypass_cmb   : std_logic;
  
  signal flag_pack_fs: std_logic;
  signal flag_pack_header: std_logic;
  signal flag_pack_prep_header: std_logic;
  signal flag_split_fifo: std_logic;
  signal flag_pack_bypass: std_logic;
  signal flag_split_flush_register: std_logic;
  signal flag_split_flush_register_cmb: std_logic;
  signal flag_fs_gamma: std_logic;
  signal flag_fs_gamma_cmb: std_logic;
  signal flag_prep_header : std_logic;
  
  signal last           : std_logic;
  signal n_words_split      : unsigned (W_COUNT-1 downto 0) := (others => '0'); -- maximum is block size
  signal n_words_split_tmp    : unsigned (W_COUNT-1 downto 0) := (others => '0'); -- maximum is block size
  signal zeroes         : std_logic_vector (option_in'high downto 0);
  signal sample_counter     : unsigned (W_N_SAMPLES downto 0) := (others => '0');  -- + 1 bit because it's signed
  signal sample_counter_cmb   : unsigned (W_N_SAMPLES downto 0) := (others => '0');  -- + 1 bit because it's signed
  signal zero_mapped        : std_logic;
  signal last_sample        : std_logic;
  signal last_sample2       : std_logic;
  signal last_sample2_d1      : std_logic;
  signal last_sample2_d2      : std_logic;
  signal last_sample2_cmb     : std_logic;
  signal last_sample3       : std_logic;
  signal last_sample3_cmb     : std_logic;
  signal last_sample4       : std_logic;
  signal last_sample4_cmb     : std_logic;
  signal ref_sample_count     : unsigned(W_REF_SAMPLE_GEN-1 downto 0) := (others => '0');
  signal segment_count      : unsigned (W_ZERO_GEN-1 downto 0) := (others => '0');
  signal flush_zero_blocks    : std_logic;
  signal flush_zero_blocks_cmb  : std_logic;
  signal counter_header     : unsigned (HEADER_ADDR-1 downto 0);
  signal counter_header_cmb   : unsigned (HEADER_ADDR-1 downto 0);
  signal count_tail       : unsigned (W_W_BUFFER_GEN-1 downto 0);
  signal count_tail_next      : unsigned (W_W_BUFFER_GEN-1 downto 0);
  signal pending_zero       : std_logic;
  signal last_reg         : std_logic;
  signal last_flag        : std_logic;
  --signal n_fs_aux         : integer;
  signal n_fs_aux         : unsigned (W_COUNT -1 downto 0);
  signal n_fs_reg         : unsigned (2*W_COUNT -1 downto 0);
  
  signal eos: std_logic;
  signal dump_zeroes: std_logic;
  signal finished: std_logic;
  
begin

  ----------------------
  --! Output assignments
  ----------------------
  en_interface_out <= en_interface;
  en_header_out <= en_header;
  en_sndextension_out <= en_sndextension;
  en_lk_out <= en_lk;
  en_k_winner_out <= en_k_winner;
  en_optcoder_out <= en_optcoder;
  en_fscoder_out <= en_fscoder;
  en_splitter_out <= en_splitter;
  en_bitpack_split_out <= en_bitpack_split;
  en_bitpack_final_out <= en_bitpack_final;
  
  start_fscoder_out <= start_fscoder;
  start_splitter_out <= start_splitter;
  
  r_update_headerin_out <= r_update_headerin;
  r_update_mapped_in_out <= r_update_mapped_in;
  r_update_mapped_out <= r_update_mapped;
  r_update_gamma_out <= r_update_gamma;
  r_update_split_out <= r_update_split;
  
  w_update_mapped_out <= w_update_mapped;
  
  clear_sndextension_out <= clear_sndextension;
  clear_lkoptions_out <= clear_lkoptions;
  
  flag_pack_fs_out <= flag_pack_fs;
  flag_pack_header_out <= flag_pack_header;
  flag_pack_header_prep_out <= flag_pack_prep_header;
  flag_split_fifo_out <= flag_split_fifo;
  flag_split_flush_register_out <= flag_split_flush_register;
  flag_pack_bypass_out <= flag_pack_bypass;
  
  flush_final_out <= (flush_final or flush_bypass);
  flush_split_out <= flush_split;
  
  finished_out <= finished;
  zero_mapped_out <= zero_mapped; 
  dump_zeroes_out <= dump_zeroes; 
  eos_out <= eos;
  fsm_invalid_state <= fsm_invalid_state_reg;
  
  -- Modified by AS: ref_block output assignments --
  gen_ref: if (PREPROCESSOR_GEN = 2) generate
    ref_block_lk <= ref_block_s;
    ref_block_fs <= ref_zero_block when (option_in = (std_logic_vector(to_unsigned(0,option_in'length))))
      else ref_block_shift(2);
  end generate gen_ref;
  
  gen_noref: if (PREPROCESSOR_GEN /= 2) generate
    ref_block_lk <= '0';
    ref_block_fs <= '0';
  end generate gen_noref;
  ------------------------------------
  
  ---------------------
  --! Other assignments
  ---------------------
  --Process to calculate n_fs_aux. It takes several cycles, 
  --but it is fine, because it is in FSM3
  process (clk, rst_n)
    variable num_const : integer := 0;
    --variable div : natural := 0;
  --Modified by AS & YB: new variable to fix the shift in order to avoid the division operation
    variable pow_shift : natural := 0;
  ------------------------------------------
  begin
    num_const := SEGMENT_GEN + W_OPT_GEN;
-- coverage off
    case to_integer(unsigned(config_int.W_BUFFER)) is
      when 8 =>
        --div := 8;
        pow_shift := 3;
      when 16 =>
        --div := 16;
        pow_shift := 4;
      when 24 =>
        --div := 24;
        pow_shift := 4;
      when 32 => 
        --div := 32;
        pow_shift := 5;
      when 40 => 
        --div := 40;
        pow_shift := 5;
      when 48 => 
        --div := 48;
        pow_shift := 5;
      when 56 => 
        --div := 56;
        pow_shift := 5;
      when 64 =>
        --div := 64;
        pow_shift := 6;
      when others =>
        --div := 8;
        pow_shift := 3;
    end case;
-- coverage on    
    if (rst_n = '0' and RESET_TYPE = 0) then
      n_fs_aux <= (others => '0');
      n_fs_reg <= (others => '0');
    elsif clk'event and clk = '1' then 
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        n_fs_aux <= (others => '0');
      else
        if config_valid = '1' then 
          if (segment_gen + w_opt_gen > 3*to_integer(unsigned(config_int.J))) then
            n_fs_reg <= to_unsigned(num_const, 2*W_COUNT);
          else
            n_fs_reg <= resize((3*unsigned(config_int.J)+ 1), 2*W_COUNT);
          end if;
          -- Modified by AS & YB: division has been replaced by right shifts
          n_fs_aux <= resize((n_fs_reg srl pow_shift) + 1, n_fs_aux'length);
        end if;
      end if;
    end if;
  end process;
  
  --n_fs_aux <=  n_fs_calc(to_unsigned(SEGMENT_GEN, W_COUNT), to_unsigned(W_OPT_GEN, W_COUNT), resize(unsigned(config_int.J), W_COUNT), to_integer(unsigned(config_int.W_BUFFER))) when config_valid = '1' else 0;
  zeroes <= (others => '0');
  last_flag <= '1' when ((last = '1') and (last_reg='0')) else '0';
  
  ---------------------------
  --! Control signals control
  ---------------------------
  process (clk, rst_n)
    
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      finished <= '0';
      fsm_invalid_state_reg <= '0';
      en_bitpack_final <= '0';
    elsif (clk'event and clk = '1') then
      if (clear= '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        finished <= ('0' or clear);
        fsm_invalid_state_reg <= '0';
        en_bitpack_final <= '0';
      else
        finished <= (flush_final_2_cmb or error or flush_bypass);
        fsm_invalid_state_reg <= fsm_invalid_state_reg_amba or fsm_invalid_state_reg_interface or fsm_invalid_state_reg_header_prep or fsm_invalid_state_reg_header or fsm_invalid_state_reg_fsm1 or fsm_invalid_state_reg_fsm2 or fsm_invalid_state_reg_fsm3;
        if ((unsigned(config_int.BYPASS) = 0 and EN_RUNCFG = 1) or (BYPASS_GEN = 0 and EN_RUNCFG = 0)) then
          en_bitpack_final <= en_splitter or r_update_split or flag_split_flush_register_cmb or en_header or r_update_headerin; -- after i      
        else
          en_bitpack_final <= en_header or r_update_mapped_in; -- after i 
        end if;
      end if;
    end if;
  end process;
  
    
  ----------------------------------------------
  --! AMBA fsm (Controls interface start signal)
  ----------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_amba <= '0';
      start_int <= '0';
      state_reg_amba <= idle;
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_amba <= '0';
        start_int <= '0';
        state_reg_amba <= idle;
      else
        fsm_invalid_state_reg_amba <= fsm_invalid_state_reg_amba_cmb;
        start_int <= start_int_cmb;
        state_reg_amba <= state_next_amba;
      end if;
    end if;
  end process;

  ----------------------------------------------
  --! AMBA fsm (Controls interface start signal)
  ----------------------------------------------
  process (state_reg_amba, valid_ahb_s, enable, finished, rst_n)
  begin 
    fsm_invalid_state_reg_amba_cmb <= '0'; 
    start_int_cmb <= '0';
    state_next_amba <= state_reg_amba;
    case state_reg_amba is
    when idle =>
      if (rst_n = '1') then
        state_next_amba <= s1;
      end if;
    when s1 => 
      -- AMBA configuration shall be used
      if (EN_RUNCFG = 1 and enable = '1' and valid_ahb_s = '1') then
        start_int_cmb <= '1';
        state_next_amba <= s2;
      -- Generic configuration shall be used
      elsif (EN_RUNCFG = 0) then
        start_int_cmb <= '1';
        state_next_amba <= s2;
      end if;
    when s2 => 
      if (finished = '1') then
         state_next_amba <= s1;
      end if;
    when others => 
--pragma translate_off
      assert false report "Wrong state for state_reg_amba fsm." severity warning;
--pragma translate_on
      fsm_invalid_state_reg_amba_cmb <= '1'; 
      state_next_amba <= idle;
    end case;
  end process;
  
    
  --------------------------------------------------------------
  --! interface fsm (Controls preprocessing-header start signal)
  --------------------------------------------------------------
  process (clk, rst_n)
  
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_interface <= '0'; 
        start_prep <= '0';
      state_reg_interface <= idle;
      en_interface <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_interface <= '0';
        start_prep <= '0';
        state_reg_interface <= idle;
        en_interface <= '0';
      else
        en_interface <= en_interface_cmb;
        fsm_invalid_state_reg_interface <= fsm_invalid_state_reg_interface_cmb;
        start_prep <= start_prep_cmb;
        state_reg_interface <= state_next_interface;
      end if;
    end if;
  end process;
  
  --------------------------------------------------------------
  --! interface fsm (Controls preprocessing-header start signal)
  --------------------------------------------------------------
  process (start_int, state_reg_interface, config_valid)
    
  begin 
    fsm_invalid_state_reg_interface_cmb <= '0'; 
    start_prep_cmb <= '0';
    en_interface_cmb <= '0';
    state_next_interface <= state_reg_interface;
    case state_reg_interface is
      when idle =>
        if (start_int = '1') then
          en_interface_cmb <= '1';
          state_next_interface <= s1;
        end if; 
      when s1 => 
        state_next_interface <= s2;
      when s2 => 
        -- Here configuration and checking parameters should be done
        if (config_valid = '1') then
          start_prep_cmb <= '1';
        end if;
        state_next_interface <= idle;
      when others => 
--pragma translate_off
        assert false report "Wrong state for state_reg_interface fsm." severity warning;
--pragma translate_on
        fsm_invalid_state_reg_interface_cmb <= '1'; 
            state_next_interface <= idle;
      end case;
  end process;
    
  -----------------------------------------------------------
  --! preprocessing-header fsm (Controls header start signal)
  -----------------------------------------------------------
  process (clk, rst_n)
  
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_header_prep <= '0';
      start_header <= '0';
      state_reg_header_prep <= idle;
      flag_pack_prep_header <= '0';
      flag_prep_header <= '0';
      r_update_headerin <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_header_prep <= '0';
          start_header <= '0';
        state_reg_header_prep <= idle;
        flag_pack_prep_header <= '0';
        flag_prep_header <= '0';
        r_update_headerin <= '0';
      else
        fsm_invalid_state_reg_header_prep <= fsm_invalid_state_reg_header_prep_cmb;
        start_header <= start_header_cmb;
        state_reg_header_prep <= state_next_header_prep;
        flag_pack_prep_header <= r_update_headerin;
        flag_prep_header <= r_update_headerin;
        r_update_headerin <= r_update_headerin_cmb;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------
  --! preprocessing-header fsm (Controls header start signal)
  -----------------------------------------------------------
  process (start_prep, state_reg_header_prep, fifo_headerin_aempty, fifo_headerin_empty, mapped_fifo_empty, config_int)
    variable ACTUAL_HEADER_SIZE: integer := 6;
    variable B: integer := W_BUFFER_GEN/8;
    variable N_IT: integer := 0;
  begin 
    fsm_invalid_state_reg_header_prep_cmb <= '0';
    start_header_cmb <= '0';
    r_update_headerin_cmb <= '0';
    state_next_header_prep <= state_reg_header_prep;
    case state_reg_header_prep is
      when idle =>
        -- header enabled and preprocessor header
        if (start_prep = '1' and unsigned(config_int.DISABLE_HEADER) = 0 and (unsigned(config_int.PREPROCESSOR) = 1 or unsigned(config_int.PREPROCESSOR) = 2)) then
          state_next_header_prep <= header_prep_stage;
        -- header enabled but no preprocessor header
        elsif (start_prep = '1' and unsigned(config_int.DISABLE_HEADER) = 0) then
          state_next_header_prep <= header_prep_done;
        -- no header enabled and no preprocessor header
        elsif (start_prep = '1' and unsigned(config_int.DISABLE_HEADER) = 1) then
          state_next_header_prep <= header_prep_done;
        else
          state_next_header_prep <= idle;
        end if;
      when header_prep_stage => 
        -- Header from preprocessor to pack still pending
        if ((fifo_headerin_aempty or fifo_headerin_empty) /= '1') then
          -- aviso al packer
          r_update_headerin_cmb <= '1';
          --flag_pack_prep_header_cmb <= '1';
        -- no header samples right now, but we have to check if there are images samples to check there are no more pending header words
        elsif (mapped_fifo_empty = '1') then
          state_next_header_prep <= state_reg_header_prep;
        -- There are image samples, so we have finished with the header fifo and thus, the header stage
        else
          state_next_header_prep <= header_prep_done;
        end if;
      when header_prep_done => 
        start_header_cmb <= '1';
        state_next_header_prep <= idle;
      when others => 
        fsm_invalid_state_reg_header_prep_cmb <= '1';
--pragma translate_off
        assert false report "Wrong state for state_reg_header_prep fsm." severity warning;
--pragma translate_on
        state_next_header_prep <= idle;
    end case;
  end process;
  
  ------------------------------------------------------
  --! header fsm (Controls fsm1 and bypass start signal)
  ------------------------------------------------------
  process (clk, rst_n)
  
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_header <= '0';
      start_fsm1 <= '0';
      start_bypass <= '0';
      state_reg_header <= idle;
      en_header <= '0';
      counter_header <= (others => '0');
      flag_pack_header <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_header <= '0';
          start_fsm1 <= '0';
        start_bypass <= '0';
        state_reg_header <= idle;
        en_header <= '0';
        counter_header <= (others => '0');
        flag_pack_header <= '0';
      else
        fsm_invalid_state_reg_header <= fsm_invalid_state_reg_header_cmb;
          start_fsm1 <= start_fsm1_cmb;
        start_bypass <= start_bypass_cmb;
        state_reg_header <= state_next_header;
        en_header <= en_header_cmb;
        counter_header <= counter_header_cmb;
        flag_pack_header <= en_header;
      end if;
    end if;
  end process;
  
  ------------------------------------------------------
  --! header fsm (Controls fsm1 and bypass start signal)
  ------------------------------------------------------
  process (start_header, state_reg_header, counter_header, start_bypass, config_int)
    variable ACTUAL_HEADER_SIZE: integer := 6;
    variable B: integer := W_BUFFER_GEN/8;
    variable N_IT: integer := 0;
  begin 
    fsm_invalid_state_reg_header_cmb <= '0';
    counter_header_cmb <= counter_header;
    en_header_cmb <= '0';
    start_fsm1_cmb <= '0';
    state_next_header <= state_reg_header;
    start_bypass_cmb <= start_bypass;
    case state_reg_header is
      when idle =>
        if (start_header = '1' and unsigned(config_int.DISABLE_HEADER) = 0) then
          state_next_header <= processing_header;
          counter_header_cmb <= (others => '0');
        elsif (start_header = '1' and unsigned(config_int.DISABLE_HEADER) = 1) then
          if (unsigned(config_int.BYPASS) = 0) then 
            start_fsm1_cmb <= '1';
          else
            start_bypass_cmb <= '1';
          end if;
        else
          state_next_header <= idle;
        end if;
      when processing_header =>
        -- case to_integer(unsigned(config_int.W_BUFFER)) is
          -- when 8 =>
            -- B := 1;
          -- when 16 =>
            -- B := 2;
          -- when 24 =>
            -- B := 3;
          -- when 32 => 
            -- B := 4;
          -- when 40 => 
            -- B := 5;
          -- when 48 => 
            -- B := 6;
          -- when 56 => 
            -- B := 7;
          -- when 64 =>
            -- B := 8;
          -- when others =>
            -- B := 1;
        -- end case;
        

-- coverage off
        -- Modified by AS: header generation when the CCSDS123 IP is not present (instead of config_int.PREPROCESSOR=0) --
        if ((unsigned(config_int.PREPROCESSOR)) = 0 or (unsigned(config_int.PREPROCESSOR)= 2)) then
        --------------------
          if (unsigned(config_int.J) > 16 or unsigned(config_int.REF_SAMPLE) > 256 or unsigned(config_int.CODESET) = 1) then
            ACTUAL_HEADER_SIZE := 6;
            case to_integer(unsigned(config_int.W_BUFFER)) is
              when 8 =>
                N_IT := ceil (6,  1) +1;
                B := 1;
              when 16 =>
                B := 2;
                N_IT := ceil (6,  2) +1;
              when 24 =>
                B := 3;
                N_IT := ceil (6,  3) +1;
              when 32 => 
                B := 4;
                N_IT := ceil (6,  4) +1;
              when 40 => 
                B := 5;
                N_IT := ceil (6,  5) +1;
              when 48 => 
                B := 6;
                N_IT := 2;
              when 56 => 
                B := 7;
                N_IT := 2;
              when 64 =>
                B := 8;
                N_IT := 2;
              when others =>
                B := 1;
                N_IT := 2;
            end case;
          else
            ACTUAL_HEADER_SIZE := 4;
            case to_integer(unsigned(config_int.W_BUFFER)) is
              when 8 =>
                N_IT := ceil (4,  1) +1;
                B := 1;
              when 16 =>
                B := 2;
                N_IT := ceil (4,  2) +1;
              when 24 =>
                B := 3;
                N_IT := ceil (4,  3) +1;
              when 32 => 
                B := 4;
                N_IT := 2;
              when 40 => 
                B := 5;
                N_IT := 2;
              when 48 => 
                B := 6;
                N_IT := 2;
              when 56 => 
                B := 7;
                N_IT := 2;
              when 64 =>
                B := 8;
                N_IT := 2;
              when others =>
                B := 1;
                N_IT := 2;
            end case;
          end if;
        else
          ACTUAL_HEADER_SIZE := 2;
          case to_integer(unsigned(config_int.W_BUFFER)) is
            when 8 =>
              N_IT := ceil (2,  1) +1;
              B := 1;
            when 16 =>
              B := 2;
              N_IT := ceil (2,  2) +1;
            when 24 =>
              B := 3;
              N_IT := 2;
            when 32 => 
              B := 4;
              N_IT := 2;
            when 40 => 
              B := 5;
              N_IT := 2;
            when 48 => 
              B := 6;
              N_IT := 2;
            when 56 => 
              B := 7;
              N_IT := 2;
            when 64 =>
              B := 8;
              N_IT := 2;
            when others =>
              B := 1;
              N_IT := 2;
          end case;
        end if;
-- coverage on  
        --B := to_integer(resize(unsigned(config_int.W_BUFFER),config_int.W_BUFFER'length +3)  srl 3); --instead of /8
        --N_IT := ceil (ACTUAL_HEADER_SIZE,  B) +1;
        if (counter_header  = to_unsigned(N_IT - 1, counter_header'length)) then
          state_next_header <= header_done;
          counter_header_cmb <= (others => '1');
          en_header_cmb <= '0';
        else  
          state_next_header <= processing_header;
          counter_header_cmb <= counter_header + 1;
          en_header_cmb <= '1';
        end if;
      when header_done => 
        if (unsigned(config_int.BYPASS) = 0) then 
          start_fsm1_cmb <= '1';
        else
          start_bypass_cmb <= '1';
        end if;
        state_next_header <= idle;
      when others => 
        fsm_invalid_state_reg_header_cmb <= '1';
--pragma translate_off
            assert false report "Wrong state for state_reg_header fsm." severity warning;
--pragma translate_on
        state_next_header <= idle;
    end case;
  end process;
  
  --------------------------------------------------------------------------------------------------------------
  --! FSM1: This process is to control the input sample requests, and clear signals for lkoptions and second extension
  --------------------------------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable last_sample_aux: std_logic := '0';
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_fsm1 <= '0';
      state_reg_fsm1 <= idle;
      sample_counter <= (others => '0');
      counter1 <= (others => '0');
      last_sample2_d1 <= '0';
      last_sample2_d2 <= '0';
      last_sample2 <= '0';
      w_update_fifo_datain_out <= '0';
      clear_sndextension <= '0';
      r_update_mapped_in <= '0';
      clear_lkoptions <= '0';
      flush_zero_blocks <= '0';
      flush_bypass <= '0';
      segment_count <= (others => '0');
      ref_sample_count <= (others => '0');
      last_sample <= '0';
      zero_mapped <= '0';
      -- Modified by AS: initialization of ref_block shift register (excepting last position) --
      ref_block_shift(1 downto 0) <= "00";
      ------------------------------------
          
      -- For output signals
      eop <= '0';
      last_sample_aux := '0';
      w_update_fifo_datain <= '0';
      w_update_mapped <= '0';     
      en_sndextension <= '0';
      en_lk <= '0';   
      flag_pack_bypass <= '0';
      en_k_winner <= '0';
      dump_zeroes <= '0';
      eos <= '0';
      en_optcoder <= '0';
              
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_fsm1 <= '0';
        state_reg_fsm1 <= idle;
        sample_counter <= (others => '0');
        counter1 <= (others => '0');
        last_sample2_d1 <= '0';
        last_sample2_d2 <= '0';
        last_sample2 <= '0';
        w_update_fifo_datain_out <= '0';
        clear_sndextension <= '0';
        r_update_mapped_in <= '0';
        clear_lkoptions <= '0';
        flush_zero_blocks <= '0';
        flush_bypass <= '0';
        segment_count <= (others => '0');
        ref_sample_count <= (others => '0');
        last_sample <= '0';
        zero_mapped <= '0';
        -- Modified by AS: initialization of ref_block shift register (excepting last position) --
        ref_block_shift(1 downto 0) <= "00";
        ------------------------------------
        
        -- For output signals
        eop <= '0';
        last_sample_aux := '0';
        w_update_fifo_datain <= '0';
        w_update_mapped <= '0';     
        en_sndextension <= '0';
        en_lk <= '0';   
        flag_pack_bypass <= '0';  
        en_k_winner <= '0';
        dump_zeroes <= '0';
        eos <= '0';
        en_optcoder <= '0';
        
      else 
        fsm_invalid_state_reg_fsm1 <= fsm_invalid_state_reg_fsm1_cmb;
        state_reg_fsm1 <= state_next_fsm1;
        sample_counter <= sample_counter_cmb;
        last_sample2 <= last_sample2_cmb;
        last_sample2_d1 <= last_sample2;
        last_sample2_d2 <= last_sample2_d1;
        counter1 <= counter1_cmb;
        w_update_fifo_datain_out <= w_update_fifo_datain_out_cmb;
        clear_sndextension <= clear_sndextension_cmb;
        r_update_mapped_in <= r_update_mapped_in_cmb;
        clear_lkoptions <= clear_lkoptions_cmb;
        flush_zero_blocks <= flush_zero_blocks_cmb;
        flush_bypass <= flush_bypass_cmb;
        if (sample_counter = 0 and state_reg_fsm1 /= idle) then
          last_sample <= '1';
        end if;
        zero_mapped <= last_sample;
        
        
        -- For output signals
        eop <= '0';
        if (last_sample = '1') then
          if (last_sample and not last_sample_aux) = '1' then
            eop <= '1';
          end if;
          last_sample_aux := '1';
        else
          last_sample_aux := '0';
        end if;
        w_update_fifo_datain <= w_update_fifo_datain_out;
        if ((unsigned(config_int.BYPASS) = 0 and EN_RUNCFG = 1) or (BYPASS_GEN = 0 and EN_RUNCFG = 0)) then
          w_update_mapped <= r_update_mapped_in;  
          en_sndextension <= r_update_mapped_in; 
          en_lk <= r_update_mapped_in;  
          w_update_mapped <= r_update_mapped_in;    
          
        else
          w_update_mapped <= '0'; 
          en_sndextension <= '0';
          en_lk <= '0';   
          w_update_mapped <= '0';     
          flag_pack_bypass <= r_update_mapped_in;         
        end if;
        if (counter1 = 0) then
          if (flush_zero_blocks = '1') then
            en_k_winner <= '1';
            dump_zeroes <= '1';
            -- Modified by AS: ref_block signal propagation from lk_comp to k_winner --
            ref_block_shift(0) <= ref_block_s;
            ------------------------------------
          else
            en_k_winner <= en_lk;
          end if;
          if (en_lk = '1') then
            if (segment_count = to_unsigned (SEGMENT_GEN-1, segment_count'length) or ref_sample_count = resize (unsigned(config_int.REF_SAMPLE)-1, ref_sample_count'length)) then
              eos <= '1';
              -- segment_count must be reset wheneos is asserted (either SEGMENT_GEN is reached or REF_SAMPLE)
              --if segment_count = to_unsigned (SEGMENT_GEN-1, segment_count'length) then
                segment_count <= (others => '0');
              --else
                --segment_count <= segment_count + 1;
              --end if;
              if (ref_sample_count = resize (unsigned(config_int.REF_SAMPLE)-1, ref_sample_count'length)) then 
                ref_sample_count <= (others => '0');
              else
                ref_sample_count <= ref_sample_count + 1;
              end if;
            else
              segment_count <= segment_count + 1;
              ref_sample_count <= ref_sample_count + 1;
              eos <= '0';
            end if;
            -- Modified by AS: ref_block signal propagation from lk_comp to k_winner --
            ref_block_shift(0) <= ref_block_s;
            ------------------------------------
          end if;       
        else
          en_k_winner <= '0';
        end if;
        en_optcoder <= en_k_winner;
        -- Modified by AS: ref_block signal propagation from k_winner to optcoder --
        if en_k_winner = '1' then
          ref_block_shift(1) <= ref_block_shift(0);
        end if;
        ------------------------------------
        
      end if;
    end if;
  end process;
  
  -- Modified by AS: Flag to indicate if a block includes a reference sample --
  ref_block_s <= '1' when (ref_sample_count = to_unsigned(0, ref_sample_count'length))
      else '0';
  ------------------------------------
    
  --------------------------------------------------------------------------------------------------------------
  --! FSM1: This process is to control the input sample requests, and clear signals for lkoptions and second extension
  --------------------------------------------------------------------------------------------------------------
  --process (state_reg_fsm1, start_fsm1, counter1, rst_n, sample_counter, last_sample, last_sample2, config_int, mapped_fifo_empty, mapped_fifo_aempty, last_DataIn, start_bypass)
  process (state_reg_fsm1, start_fsm1, counter1, rst_n, sample_counter, last_sample, last_sample2, config_int, mapped_fifo_empty, mapped_fifo_aempty, start_bypass, r_update_mapped_in, number_of_samples)
  
  begin
    state_next_fsm1 <= state_reg_fsm1;
    fsm_invalid_state_reg_fsm1_cmb <= '0';
    r_update_mapped_in_cmb <= '0';
    last_sample2_cmb <= last_sample2;
    counter1_cmb <= counter1;
    sample_counter_cmb <= sample_counter;
    flush_zero_blocks_cmb <= '0';
    flush_bypass_cmb <= '0';
    w_update_fifo_datain_out_cmb <= '0';
    clear_lkoptions_cmb <= '0';
    clear_sndextension_cmb <= '0';
    case state_reg_fsm1 is
      when idle =>
        --sample_counter_cmb <= ('0' & resize(unsigned(config_int.Nx)*unsigned(config_int.Ny)*unsigned(config_int.Nz)-1, sample_counter'length-1));
        sample_counter_cmb <= ('0' & resize(unsigned(number_of_samples), sample_counter'length-1));
        counter1_cmb <= (others => '0');
        -- compression is going to be performed
        if (start_fsm1 = '1' and rst_n = '1') then
          state_next_fsm1 <= s1;
        -- no compression to performe (bypass)
        elsif (start_bypass = '1' and rst_n = '1') then
          state_next_fsm1 <= s_bypass;
        else
          state_next_fsm1 <= idle;
        end if;
      when s1 => 
        -- wait for flag indicating that first sample of a new block is available
        if (mapped_fifo_empty = '0' and r_update_mapped_in = '0') then
          r_update_mapped_in_cmb <= '1';
          sample_counter_cmb <= sample_counter - 1;
          state_next_fsm1 <= s3;
          counter1_cmb <= (others => '0');
        elsif (last_sample = '1') then 
          r_update_mapped_in_cmb <= '0';
          last_sample2_cmb <= '1';
          state_next_fsm1 <= finish; 
        
        else
          r_update_mapped_in_cmb <= '0'; 
          state_next_fsm1 <= s1;
        end if;
      when s3 =>    
        if (counter1 = 0) then 
          counter1_cmb <= counter1 + 1;
          clear_sndextension_cmb <= '1';
          clear_lkoptions_cmb <= '1';
        end if;       
        -- last sample of a block has been read and not sure if there is another one available
        if (counter1 = resize(unsigned(config_int.J)-1, counter1'length) and (mapped_fifo_aempty or mapped_fifo_empty) = '1') then
          r_update_mapped_in_cmb <= '0';
          if (last_sample = '0' and sample_counter /= 0) then
            state_next_fsm1 <= s1;
          else
            last_sample2_cmb <= '1';
            state_next_fsm1 <= finish;
          end if;
          counter1_cmb <= (others => '0');
        elsif (counter1 = resize(unsigned(config_int.J)-1, counter1'length) ) then
          -- last sample of a block has been read and there are available samples (not one, but more than one)
          -- Not necessary to check empty flag, because even if last sample in the fifo has been read, the flag would not be updated until two cycles after
          --if (mapped_fifo_empty = '0') then
            counter1_cmb <= (others => '0');
            if (last_sample = '0') then
              state_next_fsm1 <= s3;
              r_update_mapped_in_cmb <= '1';
              sample_counter_cmb <= sample_counter - 1;
            
            else
              r_update_mapped_in_cmb <= '0';
              last_sample2_cmb <= '1';
              state_next_fsm1 <= finish; 
            end if;
          --end if;
        -- We are in the middle of a block, and there are available samples
        elsif ((mapped_fifo_aempty or mapped_fifo_empty) /= '1') then
            r_update_mapped_in_cmb <= '1';
            sample_counter_cmb <= sample_counter - 1;
            state_next_fsm1 <= s3;
            counter1_cmb <= counter1 + 1;
            --if (counter1 = resize(unsigned(config_int.J)-1, counter1'length) and last_sample = '1' ) then
              --last_sample2_cmb <= '1';
            --end if;
        -- We are in the middle of a block, and there is only one sample available (make sure no previous read, so flags are updated)
        elsif (mapped_fifo_empty = '0' and r_update_mapped_in = '0') then
          r_update_mapped_in_cmb <= '1';
            sample_counter_cmb <= sample_counter - 1;
            state_next_fsm1 <= s3;
            counter1_cmb <= counter1 + 1;
        elsif (last_sample = '1') then
          w_update_fifo_datain_out_cmb <= '1';
        -- this is a special case
        elsif counter1 = 0 then 
          state_next_fsm1 <= s4;
        end if;
      -- waiting state in the middle of a when counter is 0 
      when s4 =>  
        if ((mapped_fifo_aempty or mapped_fifo_empty) /= '1') then
          r_update_mapped_in_cmb <= '1';
          sample_counter_cmb <= sample_counter - 1;
          state_next_fsm1 <= s3;
        end if;
      when finish => 
        if (counter1 = resize(unsigned(config_int.J)-1, counter1'length)) then
          flush_zero_blocks_cmb <= '1';
          state_next_fsm1 <= idle;
          counter1_cmb <= (others => '0');
        else
          flush_zero_blocks_cmb <= '0';
          counter1_cmb <= counter1 + 1;
          state_next_fsm1 <= finish;
        end if;
      -- control for bypass
      when s_bypass => 
        if ((mapped_fifo_aempty or mapped_fifo_empty) /= '1') then
          r_update_mapped_in_cmb <= '1';
          sample_counter_cmb <= sample_counter - 1;
        end if;
        if (sample_counter = 0) then
          state_next_fsm1 <= s_bypass_d1;
        end if;
        -- if (last_DataIn = '1') then
          -- sample_counter_cmb <= sample_counter - 1;
          -- r_update_mapped_in_cmb <= '1';
          -- state_next_fsm1 <= s_bypass_d1;
        -- end if;
      when s_bypass_d1 => 
        -- if ((mapped_fifo_aempty or mapped_fifo_empty) /= '1') then
          -- r_update_mapped_in_cmb <= '1';
          state_next_fsm1 <= s_bypass_d2;
        -- end if;
      when s_bypass_d2 => 
        state_next_fsm1 <= s_bypass_d3;
      when s_bypass_d3 => 
        state_next_fsm1 <= s_bypass_d4;
      when s_bypass_d4 => 
        state_next_fsm1 <= s_bypass_d5;
      when s_bypass_d5 => 
        flush_bypass_cmb <= '1';
        state_next_fsm1 <= idle;
      when others => 
        fsm_invalid_state_reg_fsm1_cmb <= '1';
--pragma translate_off
            assert false report "Wrong state for state_reg_fsm1 fsm." severity warning;
--pragma translate_on
        state_next_fsm1 <= idle;
    end case;
  end process;

  
  ----------------------------------------------------------------------------------
  --! FSM2: Controls the read of fifo mapped and fifo gamma (through the gamma flag)
  ----------------------------------------------------------------------------------
  process (clk, rst_n)
  
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_fsm2 <= '0';
      r_update_mapped <= '0';
      r_update_gamma <= '0';
      flag_fs_gamma <= '0';
      last_sample3 <= '0';
      counter2 <= (others => '0');
      state_reg_fsm2 <= idle;
      last_reg <= '0';
      -- Modified by AS: initialization of ref_block shift register (last position) and ref_zero_block --
      ref_block_shift(2) <= '0';
      ref_zero_block <= '0';
      ------------------------------------
      
      -- For output signals
      en_fscoder <= '0';
      start_fscoder <= '0';
      flush_split <= '0';
      last <= '0';
      en_bitpack_split <= '0';
      pending_zero <= '0';
      start_splitter <= '0'; 
      en_fscoder_later <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_fsm2 <= '0';
        r_update_mapped <= '0';
        r_update_gamma <= '0';
        flag_fs_gamma <= '0';
        last_sample3 <= '0';
        counter2 <= (others => '0');
        state_reg_fsm2 <= idle;
        last_reg <= '0';
        -- Modified by AS: initialization of ref_block shift register (last position) and ref_zero_block --
        ref_block_shift(2) <= '0';
        ref_zero_block <= '0';
        ------------------------------------
        
        -- For output signals
        en_fscoder <= '0';
        start_fscoder <= '0';
        flush_split <= '0';
        last <= '0';
        en_bitpack_split <= '0';
        pending_zero <= '0';
        start_splitter <= '0'; 
        en_fscoder_later <= '0';
      else
        fsm_invalid_state_reg_fsm2 <= fsm_invalid_state_reg_fsm2_cmb;
        r_update_mapped <= r_update_mapped_cmb;
        r_update_gamma <= r_update_gamma_cmb;
        flag_fs_gamma <= flag_fs_gamma_cmb;
        last_sample3 <= last_sample3_cmb;
        counter2 <= counter2_cmb;
        state_reg_fsm2 <= state_next_fsm2;
        last_reg <= last;
        
        -- For output signals
        if (zero_code(0) = '0') then 
          -- zero_code = "10" -> block is not zero and there are pending zero blocks.
          -- zero_code = "00" -> block is not zero and there are no pending zero blocks.
          if (counter2 = 0) then 
            en_fscoder <= r_update_mapped;
            start_fscoder <= r_update_mapped;
            -- Modified by AS: ref_block signal propagation from optcoder to fs coder --
            if r_update_mapped = '1' then
              ref_block_shift(2) <= ref_block_shift(0);
            end if;
            --if (ref_zero_block = '0' and ref_block_s = '1') then
            --  ref_zero_block <= '1';
            --elsif (ref_zero_block = '1' and option_in /= (std_logic_vector(to_unsigned(0,option_in'length)))) then
            --  ref_zero_block <= '0';
            --end if;
            ------------------------------------
          -- split bits
          elsif (option_in(option_in'high) = '1') then -- k-split option, read mapped residuals
            en_fscoder <= r_update_mapped;
            start_fscoder <= '0';
          -- second extension and no-compression 
          --elsif (option_in(option_in'high) = '0' and option_in (0) = '1') then -- gamma option read mapped residuals
          else
            en_fscoder <= r_update_gamma;
            start_fscoder <= '0';
          end if;
          -- Last block in the segment is zero, and we are FS coding the previous one
          -- Activate FS coder for this last block later (when counter2 = J -1).
          if (counter2 = resize(unsigned(config_int.J)-1, counter1'length)) then
            if eos = '1' then 
              en_fscoder_later <= '1';
            end if;
          end if;
        elsif (counter2 = resize(unsigned(config_int.J)-1, counter1'length)) then  
          -- Before encoding a block, check if there are pending zero_blocks.
          -- If zero_code = "01" there might be a pending zero block.
          -- Activate fs_coder before starting the fs_coding of the next block.
          -- If next block is also zero, no action will be taken by fs_coder. 
          if (zero_code /= "11") then 
            if (en_k_winner = '1') then
              en_fscoder <= '1';
            else
              en_fscoder <= '0';
              pending_zero <= '1';
            end if;
            
            start_fscoder <= '0';
          else 
            -- The end of segment case (zero_code = "11") is a special case, so we do not activate fs_coder at this moment.
            en_fscoder <= '0';
            start_fscoder <= '0';
          end if; 
        --elsif counter2 = 0 and zero_code = "11" and last_sample3 = '0' then
        --  en_fscoder_later <= '1';
        --  en_fscoder <= '0';
        --  start_fscoder <= '0';
        else
          en_fscoder <= '0';
          start_fscoder <= '0';
        end if;
        
        -- Modified by AS: ref_block signal propagation from optcoder to fs coder --
        -- ref_block_s replaced with ref_block_shift(0) to fix the signaling of a reference sample with zero-block option

        if (counter2 = 0) then 
          if (ref_zero_block = '0' and ref_block_shift(0) = '1') then
            ref_zero_block <= '1';
          elsif (ref_zero_block = '1' and option_in /= (std_logic_vector(to_unsigned(0,option_in'length)))) then
            ref_zero_block <= '0';
          end if;
          -- Statement to control the ref_sample insertion when zero_block option is selected
          if (zero_count = (std_logic_vector(to_unsigned(1,zero_count'length)))) then
            start_fscoder <= '1';
          end if;
        end if;
        ------------------------------------------
        
        -- Check if there are pending zero blocks if we reach the end of a segment
        -- while fs-coding a non-zero block. 
        -- This will be noticed because en_fscoder_later = '1'.
        if (counter2 = resize(unsigned(config_int.J)-2, counter1'length)) then
          if en_fscoder_later = '1' then 
            en_fscoder_later <= '0';
            if  zero_code = "11" then
              en_fscoder <= '1';
              start_fscoder <= '0';
            end if;
          end if;
        end if;
        
        if (counter2 = 0 and pending_zero = '1' and en_k_winner = '1') then
          en_fscoder <= '1';
          start_fscoder <= '0';
          pending_zero <= '0';
        end if;
        
        -- When we finish fs-coding a block, we activate the last flag to trigger
        -- the rest of operations (split and subsequent packing).
        if (counter2 = resize(unsigned(config_int.J)-1, counter1'length)) then
          --If last block is not a zero at the end of a segment. 
          if (zero_code /= "11") then 
            -- Fs-encoded block is a zero (not at the end of a segment), it will not be encoded now.
            -- if zero code wait for the reception of next block, otherwise continue
            if (zero_code(0) = '1') then 
              if (en_k_winner = '1') then -- Get results from fs-coding the pending zero block before fs-coding the non-zero block. 
                last <= '1';
              end if;
            else -- fs-encoded block is not zero
              last <= '1';
            end if;
          elsif (zero_code = "11" and en_fscoder = '1') then
            --We activated fs_coder because there was a single pending zero_block at the end of segment
            --which was fs-encoded later. 
            last <= '1';
          else
            --There was > 1 zero_block at the end of a segment.
            --We do not need to activate last, because there was a previous zero block that activated it. 
            last <= '0';
          end if;
        else
          last <= '0';
        end if;
        -- Trigger ther rest of operations in FSM3
        flush_split <= last_flag;
        start_splitter <= last_flag; 
        en_bitpack_split <= en_fscoder or last_flag;        
      end if;
    end if;
  end process;
  
  ----------------------------------------------------------------------------------
  --! FSM2: Controls the read of fifo mapped and fifo gamma (through the gamma flag)
  ----------------------------------------------------------------------------------
  process (state_reg_fsm2, en_k_winner, counter2, flag_fs_gamma, last_sample2_d1, last_sample3, config_int, last_sample2_d2)
  
  begin
    fsm_invalid_state_reg_fsm2_cmb <= '0';
    r_update_mapped_cmb <= '0';
    r_update_gamma_cmb <= '0';
    flag_fs_gamma_cmb <= '0';
    last_sample3_cmb <= last_sample3;
    counter2_cmb <= counter2;
    state_next_fsm2 <= state_reg_fsm2;
    case state_reg_fsm2 is  
      when idle => 
        r_update_mapped_cmb <= en_k_winner; 
        r_update_gamma_cmb <= en_k_winner;
        counter2_cmb <= (others => '0');
        if (last_sample2_d2 = '1') then
          last_sample3_cmb <= '1';
        end if;
        if (en_k_winner = '1') then
          state_next_fsm2 <= s1;
        else
          state_next_fsm2 <= idle;
        end if;
      when s1 => 
        if (counter2 = resize(unsigned(config_int.J)-1, counter1'length) and en_k_winner = '1') then
          if (last_sample2_d2 = '1') then
            last_sample3_cmb <= '1';
          end if;
          if (last_sample3 = '0') then
            r_update_mapped_cmb <= en_k_winner;
            r_update_gamma_cmb <= en_k_winner;
            state_next_fsm2 <= s1;
          else
            state_next_fsm2 <= idle;
          end if;
          counter2_cmb <= (others => '0');
        elsif (counter2 = resize(unsigned(config_int.J)-1, counter1'length) and en_k_winner = '0') then
          if (last_sample2_d1 = '1') then
            last_sample3_cmb <= '1';
            state_next_fsm2 <= idle;
            counter2_cmb <= (others => '0');
          end if;
        else
          r_update_mapped_cmb <= '1';
          r_update_gamma_cmb <= '1' and flag_fs_gamma;
          state_next_fsm2 <= s1;
          flag_fs_gamma_cmb <= not flag_fs_gamma;
          counter2_cmb <= counter2 + 1;
        end if;
      when others =>
        fsm_invalid_state_reg_fsm2_cmb <= '1';
--pragma translate_off
        assert false report "Wrong state for state_reg_fsm2 fsm." severity warning;
--pragma translate_on
        state_next_fsm2 <= idle;
    end case;
  end process;
  
  ------------------------------------------------------------------------------------------------------------
  --! FSM3: Controls the behaviour of splitter - reads from fifo split - packs final process for n_words_split
  ------------------------------------------------------------------------------------------------------------
  process (clk, rst_n)
  
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fsm_invalid_state_reg_fsm3 <= '0';
      en_splitter <= '0';
      r_update_split <= '0'; 
      flag_split_flush_register <= '0';
      flush_final <= '0';
      flush_final_2 <= '0';
      last_sample4 <= '0';
      counter3 <= (others => '0');
      counter4 <= (others => '0');
      count_tail <= (others=> '0');
      state_reg_fsm3 <= idle;
      flush_split_d1 <= '0';
      n_words_split_tmp <= (others => '0');
      n_words_split <= (others => '0');
      
      -- For output signals
      flag_pack_fs <= '0'; 
      flag_split_fifo <= '0'; 
    elsif (clk'event and clk = '1') then
      if (clear = '1' or finished = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fsm_invalid_state_reg_fsm3 <= '0';
        en_splitter <= '0';
        r_update_split <= '0'; 
        flag_split_flush_register <= '0';
        flush_final <= '0';
        flush_final_2 <= '0';
        last_sample4 <= '0';
        counter3 <= (others => '0');
        counter4 <= (others => '0');
        count_tail <= (others=> '0');
        state_reg_fsm3 <= idle;
        flush_split_d1 <= '0';
        n_words_split_tmp <= (others => '0');
        n_words_split <= (others => '0');
        
        -- For output signals
        flag_pack_fs <= '0'; 
        flag_split_fifo <= '0'; 
      else
        fsm_invalid_state_reg_fsm3 <= fsm_invalid_state_reg_fsm3_cmb;
        en_splitter <= en_splitter_cmb;
        r_update_split <= r_update_split_cmb;
        flag_split_flush_register <= flag_split_flush_register_cmb;
        flush_final <= flush_final_cmb;
        flush_final_2 <= flush_final_2_cmb;
        last_sample4 <= last_sample4_cmb;
        counter3 <= counter3_cmb;
        counter4 <= counter4_cmb;
        count_tail <= count_tail_next;
        state_reg_fsm3 <= state_next_fsm3;
        flush_split_d1 <= flush_split; 
        if (flush_split_d1 = '1') then
          if (we_fifo_split_in = '1') then
            n_words_split <= n_words_split + 1;
          end if;
        elsif (flush_split = '1') then 
          n_words_split_tmp <= (others => '0');
          if (we_fifo_split_in = '1') then
            n_words_split <= n_words_split_tmp + 1;
          else
            n_words_split <= n_words_split_tmp;
          end if;
        elsif we_fifo_split_in = '1' then
          n_words_split_tmp <= n_words_split_tmp + 1;
        end if;
        
        -- For output signals
        flag_pack_fs <= en_splitter; 
        flag_split_fifo <= r_update_split; 
      end if;
    end if;
  end process;
  
  ------------------------------------------------------------------------------------------------------------
  --! FSM3: Controls the behaviour of splitter - reads from fifo split - packs final process for n_words_split
  ------------------------------------------------------------------------------------------------------------
  process (state_reg_fsm3, counter3, last_flag, counter4, n_words_split, last_sample3, last_sample4, config_int, count_tail, zero_code, n_fs_aux)
    variable N_FS: std_logic_vector(W_COUNT-1 downto 0) := (others => '0');
  begin
    fsm_invalid_state_reg_fsm3_cmb <= '0';
    en_splitter_cmb <= '0';
    r_update_split_cmb <= '0';
    flag_split_flush_register_cmb <= '0';
    flush_final_cmb <= '0';
    flush_final_2_cmb <= '0';
    last_sample4_cmb <= last_sample4;
    counter3_cmb <= counter3;
    counter4_cmb <= counter4; 
    count_tail_next <= count_tail;
    state_next_fsm3 <= state_reg_fsm3;
    case state_reg_fsm3 is
      when idle => 
        -- start when split has finished
        if (last_flag = '1') then 
          state_next_fsm3 <= fs;
          en_splitter_cmb <= '1'; 
          if (last_sample3 = '1') then
            last_sample4_cmb <= '1';
          end if;
        elsif last_sample3 = '1' and zero_code = "11" and last_sample4 = '0' then
          state_next_fsm3 <= flush2;
        else
          state_next_fsm3 <= idle;
        end if;
      when fs =>
      --  N_FS := std_logic_vector(to_signed(n_fs_aux, W_COUNT));
        N_FS := std_logic_vector(n_fs_aux);
        if (unsigned(N_FS) < to_unsigned(2, N_FS'length)) then
          N_FS := std_logic_vector(to_unsigned(2, N_FS'length));
        end if;
        
        if (counter3 = resize(unsigned(N_FS) - 1, counter3'length)) then
          counter3_cmb <= (others => '0');  
          state_next_fsm3 <= lapse;
        else
          en_splitter_cmb <= '1';
          counter3_cmb <= counter3 +1;
          state_next_fsm3 <= fs;
        end if;
      when lapse => 
        if (n_words_split = 0) then
          r_update_split_cmb <= '0';
          -- you always have to flush, even when there are no split bits
          state_next_fsm3 <= flush1; 
        else
          r_update_split_cmb <= '1';
          state_next_fsm3 <= split;
          counter4_cmb <= counter4 + 1;
        end if;
      when split => 
        if (counter4 >= n_words_split) then
          state_next_fsm3 <= flush1;
          counter4_cmb <= (others => '0');
        else
          r_update_split_cmb <= '1';
          counter4_cmb <= counter4 + 1;
          state_next_fsm3 <= split;
        end if;
      when flush1 =>
        flag_split_flush_register_cmb <= '1';
        if (last_sample4 = '0') then
          state_next_fsm3 <= idle;
        else
          state_next_fsm3 <= flush2;
        end if;
      -- flush final ONLY for the last block
      when flush2 => 
        flush_final_cmb <= '1';
        state_next_fsm3 <= flush3;
        last_sample4_cmb <= '1';
      -- flush final ONLY for the last block
      when flush3 => 
        if (unsigned(count_tail) = unsigned(config_int.W_BUFFER)/8) then
          state_next_fsm3 <= idle;
          flush_final_2_cmb <= '1';
          count_tail_next <= (others => '0');
        else
          count_tail_next <= count_tail + 1;
        end if;
      when others => 
        fsm_invalid_state_reg_fsm3_cmb <= '1';
--pragma translate_off
        assert false report "Wrong state for state_reg_fsm3 fsm." severity warning;
--pragma translate_on
        state_next_fsm3 <= idle;
    end case;
  end process;
    
  
end arch;
