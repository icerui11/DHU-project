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
-- Design unit  : ccsds121 main components 
--
-- File name    : ccsds121_shyloc_comp.vhd.vhd
--
-- Purpose      : Makes the connections between the different modules of the CCSDS 121 block coder.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Instantiates : int (ccsds121_shyloc_interface), header_gen (header121_shyloc), snd_extension (sndextension), gamma_fifo (fifop2), mapped_fifo (fifop2), lk_computation (lkoptions), optioncoder (optcoder), fscoder (fscoderv2), splitpacker (bitpackv2), fifosplit(fifop2), split (splitter), packing_final (packing_top)
--============================================================================

--!@file #ccsds121_shyloc_comp.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Makes the connections between the different modules of the CCSDS 121 block coder.

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

--! ccsds121_shyloc_comp entity  Component module of the CCSDS121- Block Coder
--! Component instantiation of the main components
entity ccsds121_shyloc_comp is
  generic (
    W_MAP    : integer := 32;   --! Bit width of the mapped prediction residuals.
    W_BUFFER  : integer := 64;  --! Bit width of the output buffer.
    RESET_TYPE  : integer := 1    --! Reset type.
  );
  port (
    -- System Interface
    clk     : in std_logic;   --! Clock signal.
    rst_n   : in std_logic;   --! Reset signal. Active low.
    clear     : in std_logic;   --! Clear signal.
    
    -- Data Output Interface
    buff_out    : out std_logic_vector (W_BUFFER-1 downto 0);     --! Output compressed bit stream.
    buff_full   : out std_logic;                    --! Flag to validate output bit stream.
    
    -- Interface module signals 
    en_interface  : in std_logic;           --! Enable interface module.
    config_in   : in config_121;          --! Configuration received by AMBA.
    config_valid  : out std_logic;          --! Configuration validation.
    config_int    : out config_121;         --! Configuration of the compressor.
    error     : out std_logic;          --! There has been an error during the compression configuration.
    error_code    : out std_logic_vector(3 downto 0); --! Code of the configuration error.
        
    -- Header generator signals
    en_header121  : in std_logic;     --! Enable header generation module.
    
    -- Second extension signals
    en_sndextension   : in std_logic;               --! Enable sndextension module.
    mapped        : in std_logic_vector (W_MAP-1 downto 0); --! Input data (Sample to compress).
    zero_mapped     : in std_logic;               --! Forced mapped prediction residuals to zero.
    clear_sndextension  : in std_logic;               --! Clear sndextension module.
    
    -- lk computation signals
    en_lk     : in std_logic;             --! Enable lk_options module.
    en_k_winner   : in std_logic;             --! Enable k_winner option.
    clear_lkoptions : in std_logic;             --! Clear lk_options module.
    eos       : in std_logic;             --! End of segment reached.
    dump_zeroes   : in std_logic;             --! Zeroes have to be dumped.
    zero_code   : out std_logic_vector (1 downto 0);  --! Zero code.
    -- Modified by AS: new interface ports --
    zero_count_out  : out std_logic_vector (W_ZERO_GEN-1 downto 0);
    ref_block_lk  : in std_logic;              --! Reference sample included in the current block (for length computation)
    ref_block_fs  : in std_logic;              --! Reference sample included in the current block (for fs coder)
    ------------------------------------
    
    -- option coder signals
    en_optcoder   : in std_logic;                   --! Enable option coder module.
    option_out    : out std_logic_vector (W_OPT_GEN - 1 downto 0);  --! Chosen option.
    
    -- fs coder signals
    en_fscoder    : in std_logic;   --! Enable fscoder module.
    start_fscoder : in std_logic;   --! Start fscoder.
    
    -- splitpacker signals
    en_bitpack_split  : in std_logic; --! Enable bitpack_split module.
    flush_split     : in std_logic; --! flush remaining split data.
    
    -- splitter signals
    en_splitter     : in std_logic; --! Enable splitter module.
    start_splitter    : in std_logic; --! Start splitter.
    
    -- packing_final signals
    en_bitpack_final      : in std_logic;                     --! Enable packing_final module.
    header_prep         : in std_logic_vector (W_MAP-1 downto 0);       --! Pre-procesing header data.
    n_bits_header_prep      : in std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0);  --! Number of valid bits in the input header.
    flag_pack_fs        : in std_logic;                     --! There is fs to process.
    flag_split_flush_register : in std_logic;                     --! There is split flush register to process.
    flag_split_fifo       : in std_logic;                     --! There are split bits to process.
    flag_pack_header      : in std_logic;                     --! There is header to process.
    flag_pack_header_prep   : in std_logic;                     --! There is pre-processing header to process.
    flag_pack_bypass      : in std_logic;                     --! There are residuals to process.
    flush_final         : in std_logic;                     --! Flush the bit packer.
  
    -- mapped fifo control signals  
    w_update_mapped   : in std_logic;   --! mapped fifo control signals 
    r_update_mapped   : in std_logic;
    empty_mapped    : out std_logic;
    full_mapped     : out std_logic;
    afull_mapped    : out std_logic;
    aempty_mapped   : out std_logic;
    
    -- gamma fifo control signals
    r_update_gamma    : in std_logic;   --! gamma fifo control signals
    empty_gamma     : out std_logic;  
    full_gamma      : out std_logic;  
    afull_gamma     : out std_logic;
    aempty_gamma    : out std_logic;
    
    -- split fifo control signals
    r_update_split    : in std_logic;   --! split fifo control signals
    empty_split     : out std_logic;  
    full_split      : out std_logic;  
    afull_split     : out std_logic;  
    aempty_split    : out std_logic;  
    we_fifo_split_out : out std_logic;

    number_of_samples_out : out std_logic_vector(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0)  
  );
end ccsds121_shyloc_comp;

--! @brief Architecture of ccsds121_shyloc_comp 
architecture arch of ccsds121_shyloc_comp is

  -- configuration signals
  signal config     : config_121;
  signal config_valid_aux : std_logic;
  signal Nx_times_Ny : std_logic_vector (W_Nx_GEN + W_Ny_GEN -1 downto 0); 
  
  -- header signals
  signal header     : std_logic_vector (W_BUFFER-1 downto 0);
  signal n_bits_header  : std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0);
  
  -- snd_extension
  signal mapped_local   : std_logic_vector (W_MAP-1 downto 0);
  signal zero_mapped_d1 : std_logic;
  signal gamma      : std_logic_vector (W_GAMMA_GEN-1 downto 0);
  signal gamma_valid    : std_logic;
  signal l_gamma      : std_logic_vector (W_L_GAMMA_GEN-1 downto 0);
  
  -- gamma FIFO signals
  signal gamma_out_fifo : std_logic_vector (W_GAMMA_GEN-1 downto 0);
  
  -- lk_computation signals
  signal winner_l_k : std_logic_vector (W_L_K_GEN -1 downto 0);
  signal winner_k   : std_logic_vector(W_K_GEN -1 downto 0);
  signal winner_l   : std_logic_vector (W_L_GEN-1 downto 0);
  signal zero_count : std_logic_vector (W_ZERO_GEN-1 downto 0);
  
  -- optioncoder signals
  signal winner_k_out : std_logic_vector (W_K_GEN -1 downto 0);
  signal option: std_logic_vector (W_OPT_GEN-1 downto 0);
  
  -- fscoder signals
  signal fs_sequence      : std_logic_vector (W_FS_OPT_GEN-1 downto 0);
  signal nbits_fs       : std_logic_vector (W_NBITS_GEN-1 downto 0);
  signal nbits_k        : std_logic_vector (W_NBITS_K_GEN-1 downto 0);
  signal split_bits     : std_logic_vector (W_BUFFER-1 downto 0);
  
  -- fifosplit signals
  signal split_fifo_out   : std_logic_vector (W_BUFFER-1 downto 0);
  
  -- splitpacker signals
  signal split_bits_packed  : std_logic_vector (W_BUFFER-1 downto 0);
  signal buff_left: std_logic_vector (W_BUFFER -1 downto 0);
  signal bits_flush: std_logic_vector (W_W_BUFFER_GEN -1 downto 0);
  
  -- mapped_fifo signals
  signal mapped_out_fifo: std_logic_vector (W_MAP-1 downto 0);
  
  -- split signals
  signal fs_buffered: std_logic_vector (W_BUFFER-1 downto 0);
  signal n_bits_fs_buffered: std_logic_vector (W_NBITS_GEN-1 downto 0);
  
  -- finalpacking signals
  signal n_splits_sig : std_logic_vector(W_W_BUFFER_GEN -1 downto 0);
  
  -- General purpose signals 
  signal zero_code_out: std_logic_vector (1 downto 0);
  signal we_fifo_split: std_logic;
  signal W_BUFFER_conf : integer := 0;

begin
  
  ------------------------------------
  --! Data Output assignments
  ------------------------------------
  config_valid <= config_valid_aux;
  config_int <= config;
  option_out <= option;
  we_fifo_split_out <= we_fifo_split;
  zero_code <= zero_code_out; 
  
  --Modified by AS & YB: zero_count signal assigment
  zero_count_out <= zero_count;
  -----------------------------
  
  ------------------------------------
  --! Number of bits in each of the split bits
  ------------------------------------
  W_BUFFER_conf <= to_integer(unsigned(config.W_BUFFER));
  n_splits_sig <= std_logic_vector (to_unsigned(W_BUFFER_conf, W_W_BUFFER_GEN));
  
  ---------------------------------
  --! Residuals-forced-to-zero flag
  ---------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      zero_mapped_d1 <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        zero_mapped_d1 <= '0';
      else
        zero_mapped_d1 <= zero_mapped;
      end if;
    end if;
  end process;
  
  ---------------------
  --! mapped assignment
  ---------------------
  mapped_local <= mapped when zero_mapped_d1 = '0' else (others => '0');
  
  ------------------------------------
  --!@brief interface module
  ------------------------------------
  int: entity VH_compressor.ccsds121_shyloc_interface(arch)
    generic map (
      RESET_TYPE => RESET_TYPE
    )
    port map (
      clk => clk,
      rst_n => rst_n,
      config_in => config_in,
      en => en_interface,
      clear => clear,
      config => config,
      config_valid => config_valid_aux,
      Nx_times_Ny => Nx_times_Ny,
      error => error,
      error_code => error_code
    );
  
  ------------------------------------
  --!@brief header generator
  ------------------------------------
  header_gen: entity VH_compressor.header121_shyloc(arch_shyloc)
    generic map(
      HEADER_ADDR => HEADER_ADDR, 
      W_BUFFER_GEN => W_BUFFER_GEN, 
      W_NBITS_HEAD_GEN => W_NBITS_HEAD_GEN,
      RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_header121,
      clear => clear,
      config_in => config,
      Nx_times_Ny => Nx_times_Ny,
      config_received =>  config_valid_aux,
      header_out => header,
      n_bits => n_bits_header,
      number_of_samples_out => number_of_samples_out      
    );

  ------------------------------------
  --!@brief second extension
  ------------------------------------
  snd_extension: entity VH_compressor.sndextension(arch)
    generic map (
      BLOCK_SIZE => J_GEN, 
      W_MAP => W_MAP,   
      W_GAMMA =>  W_GAMMA_GEN, 
      W_L_GAMMA => W_L_GAMMA_GEN, 
      MAX_SIZE => MAX_SIZE_GEN,
      RESET_TYPE => RESET_TYPE) 
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_sndextension,                  
      mapped => mapped_local,   
      clear => clear,       
      clear_acc => clear_sndextension, 
      -- Modified by AS: new interface ports --
      ref_block => ref_block_lk,
      config_in => config,
      ------------------------------------
      gamma => gamma, 
      gamma_valid => gamma_valid,
      l_gamma => l_gamma
  );

  ------------------------------------
  --! gamma fifo
  ------------------------------------
   -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  gamma_fifo: entity shyloc_utils.fifop2(arch)
    generic map (
      W => W_GAMMA_GEN,
      NE => NE_GAMMA_FIFO_GEN,
      W_ADDR => W_ADDR_FIFO_GAMMA_GEN,
      RESET_TYPE => RESET_TYPE, 
      EDAC => 0, 
      TECH => TECH)
    port map (
      clk => clk,
      rst_n => rst_n, 
      clr => clear, 
      w_update => gamma_valid, 
      r_update => r_update_gamma, 
      data_in => gamma, 
      data_out => gamma_out_fifo,
      empty => empty_gamma,
      full => full_gamma, 
      afull => afull_gamma, 
      aempty => aempty_gamma
    );
    
  ------------------------------------
  --!@brief mapped FIFO
  ------------------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
   -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  mapped_fifo: entity shyloc_utils.fifop2(arch)
    generic map (
      W => W_MAP,
      NE => NE_MAP_FIFO_GEN,
      W_ADDR => W_ADDR_MAP_FIFO_GEN,
      RESET_TYPE => RESET_TYPE,
      EDAC => 0, 
      TECH => TECH
      )
    port map (
      clk => clk,
      rst_n => rst_n, 
      clr => clear, 
      w_update => w_update_mapped, 
      r_update => r_update_mapped, 
      data_in => mapped_local, 
      data_out => mapped_out_fifo,
      empty => empty_mapped,
      full => full_mapped, 
      afull => afull_mapped, 
      aempty => aempty_mapped
    );
    
  ------------------------------------
  --!@brief lk computation module
  ------------------------------------
  lk_computation: entity VH_compressor.lkoptions(arch)
    generic map (
      W_MAP => W_MAP,
      N_K => N_K_GEN,
      W_K => W_K_GEN,
      W_L_K => W_L_K_GEN,
      MAX_SIZE => MAX_SIZE_GEN,
      BLOCK_SIZE => J_GEN, 
      EOF_IS_EOS => EOF_IS_EOS_GEN,
      W_ZERO => W_ZERO_GEN,
      RESET_TYPE => RESET_TYPE)
    port map (
      clk => clk, 
      rst_n => rst_n, 
      en_lk => en_lk, 
      en_k_winner => en_k_winner, 
      config_in => config,        
      mapped => mapped_local,
      clear => clear,
      clear_acc => clear_lkoptions,
      eos => eos, 
      dump_zeroes => dump_zeroes,
      -- Modified by AS: new interface port --
      ref_block => ref_block_lk,
      ------------------------------------
      zero_code => zero_code_out,
      zero_count => zero_count,
      winner_l_k => winner_l_k,
      winner_k => winner_k
    );

  ------------------------------------
  --!@brief option coder module
  ------------------------------------
  optioncoder: entity VH_compressor.optcoder (arch)
    generic map (
      W_OPT => W_OPT_GEN,
      W_L => W_L_GEN,
      W_L_GAMMA => W_L_GAMMA_GEN, 
      W_K => W_K_GEN,
      MAX_SIZE => MAX_SIZE_GEN,
      W_MAP => W_MAP,
      RESET_TYPE => RESET_TYPE)
    port map (
      clk => clk, 
      rst_n => rst_n,
      clear => clear,
      en => en_optcoder, 
      config_in => config,        
      l_gamma => l_gamma,
      winner_l_k => winner_l_k, 
      winner_k => winner_k,
      option => option, 
      zero_code => zero_code_out, 
      winner_l => winner_l, 
      winner_k_out => winner_k_out
    );
  
  ------------------------------------
  --!@brief fscoder module
  ------------------------------------
  fscoder: entity VH_compressor.fscoderv2(arch)
    generic map (
      W_BUFFER => W_BUFFER,
      BLOCK_SIZE => J_GEN, 
      W_K => W_K_GEN, 
      W_OPT => W_OPT_GEN, 
      W_L => W_L_GEN,
      W_NBITS => W_NBITS_GEN, 
      W_NBITS_K => W_NBITS_K_GEN,
      W_MAP => W_MAP, 
      W_FS_OPT => W_FS_OPT_GEN, 
      K_MAX => K_MAX_GEN, 
      W_GAMMA => W_GAMMA_GEN, 
      W_ZERO => W_ZERO_GEN,
      RESET_TYPE => RESET_TYPE)
    port map (
      clk => clk, 
      rst_n => rst_n,
      en => en_fscoder, 
      clear => clear,       
      start => start_fscoder, 
      -- Modified by AS: new interface port --
      ref_block => ref_block_fs,
      ------------------------------------
      config_in => config,        
      winner_k => winner_k_out,
      winner_l => winner_l, 
      option => option, 
      mapped => mapped_out_fifo,
      gamma => gamma_out_fifo, 
      zero_count => zero_count, 
      zero_code => zero_code_out, 
      fs_sequence => fs_sequence, 
      nbits_fs => nbits_fs, 
      nbits_k => nbits_k, 
      split_bits => split_bits
    );
  
  ------------------------------------
  --!@brief split packer module
  ------------------------------------
  splitpacker: entity shyloc_utils.bitpackv2(arch)
    generic map (
      W_W_BUFFER_GEN => W_W_BUFFER_GEN,
      W_BUFFER => W_BUFFER, 
      W_NBITS => W_NBITS_K_GEN,
      RESET_TYPE => RESET_TYPE)
    port map (
      clk => clk, 
      rst_n => rst_n, 
      en => en_bitpack_split, 
      clear => clear,       
      W_BUFFER_configured => config.W_BUFFER,       
      config_valid => config_valid_aux,
      n_bits => nbits_k,
      flush => flush_split, 
      codeword => split_bits, 
      buff_left => buff_left, 
      bits_flush => bits_flush,
      buff_out => split_bits_packed, 
      buff_full => we_fifo_split
    );  
  
  ------------------------------------
  --!@brief fifosplit FIFO
  ------------------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
   -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  fifosplit:  entity shyloc_utils.fifop2(arch)
    generic map (
      W => W_BUFFER,
      NE => NE_SPLIT_FIFO_GEN,
      W_ADDR => W_ADDR_SPLIT_FIFO_GEN,
      RESET_TYPE => RESET_TYPE, 
      EDAC => 0, 
      TECH => TECH)
    port map (
      clk => clk,
      rst_n => rst_n, 
      clr => clear, 
      w_update => we_fifo_split, 
      r_update => r_update_split, 
      data_in => split_bits_packed, 
      data_out => split_fifo_out,
      empty => empty_split,
      full => full_split, 
      afull => afull_split, 
      aempty => aempty_split
    );
  
  ------------------------------------
  --!@brief splitter module
  ------------------------------------
  split: entity VH_compressor.splitter(arch)
    generic map (
      W_BUFFER => W_BUFFER, 
      W_FS_OPT => W_FS_OPT_GEN, 
      W_NBITS => W_NBITS_GEN,
      W_NBITS_K => W_NBITS_K_GEN,
      RESET_TYPE => RESET_TYPE
      )
    port map (
      clk => clk, 
      rst_n => rst_n, 
      clear => clear,
      en => en_splitter, 
      config_in => config,        
      start => start_splitter, 
      n_bits_fs => nbits_fs,
      fs_sequence => fs_sequence, 
      fs_buffered => fs_buffered, 
      n_bits_fs_buffered => n_bits_fs_buffered
    );
    
  ------------------------------------
  --!@brief packing module
  ------------------------------------
  packing_final: entity VH_compressor.packing_top(arch)
    generic map(
      W_BUFFER => W_BUFFER, 
      W_NBITS_K => W_NBITS_K_GEN, 
      W_NBITS => W_NBITS_GEN,
      W_OPT => W_OPT_GEN, 
      W_MAP => W_MAP,
      RESET_TYPE => RESET_TYPE)
    port map(
      clk  => clk, 
      rst_n => rst_n, 
      clear => clear,       
      en_bitpack_final => en_bitpack_final, 
      config_in => config,
      config_valid => config_valid_aux,
      flag_pack_header => flag_pack_header, 
      header => header, 
      n_bits_header => n_bits_header, 
      
      flag_pack_header_prep => flag_pack_header_prep,
      header_prep => header_prep, 
      n_bits_header_prep => n_bits_header_prep, 
      
      flag_pack_fs => flag_pack_fs,
      fs_buffered => fs_buffered, 
      n_bits_fs_buffered => n_bits_fs_buffered,
      
      flag_split_fifo => flag_split_fifo, 
      split_bits => split_fifo_out, 
      n_bits_split => n_splits_sig, 
      
      flag_split_flush_register => flag_split_flush_register, 
      buff_left => buff_left, 
      bits_flush => bits_flush,
      
      flag_pack_bypass => flag_pack_bypass,
      residuals_buffered => mapped,
      
      flush_final => flush_final, 
      buff_out => buff_out, 
      buff_full => buff_full
    );


end arch;
