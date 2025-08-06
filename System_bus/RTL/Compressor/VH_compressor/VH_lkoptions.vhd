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
-- Design unit  : lkoptions module
--
-- File name    : lkoptions.vhd
--
-- Purpose      : This module finds the minimum length for all the sample split options. The length for each of the sample_split options is calculated and the minimum is found by subtraction.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Instantiates : compute_l_k (lkcomp)
--============================================================================

--!@file #lkoptions.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief   This module finds the minimum length for all the sample split options.
--!@details The length for each of the sample_split options is calculated and the minimum is found by subtraction.

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
--! Use shyloc_functions functions
use shyloc_utils.shyloc_functions.all;

--! lkoptions entity. Finds the minimum length for all the sample split options.
entity lkoptions is
  generic (
       W_MAP    : integer := 16;    --! Dynamic range of the mapped prediction residuals.
       N_K    : integer := 13;    --! Number of k option.
       W_K    : integer := 5;     --! Bits to represent k.
       W_L_K    : integer := 9;       --! Maximum size of length for k option.
       MAX_SIZE : integer:= 256;    --! Maximum block size in bits.
       BLOCK_SIZE : integer := 16;    --! Number of samples in a block.
       EOF_IS_EOS : integer := 1;     --! Behaviour when end of file is reached (1 --> end of file = end of segment (UAB software) 0 --> end of file /= end of segment (ESA software).
       W_ZERO   : integer := 7;     --! Bit width of the zero_block counter.
       RESET_TYPE : integer := 16     --! Reset type.
       );     
  port (
    -- System Interface
    clk   : in std_logic;                 --! Clock signal.
    rst_n : in std_logic;                 --! Reset signal. Active low.
    
    -- Configuration and Control Interface
    config_in : in config_121;              --! Current configuration parameters.
    en_lk   : in std_logic;               --! Enable signal.
    en_k_winner : in std_logic;               --! Enable the computation of the k_winner.
    clear     : in std_logic;               --! It forces the module to its initial state.
    clear_acc  : in std_logic;                --! Flag to clear accumulators. Activated with the first sample of each block.
    eos     : in std_logic;                 --! End of segment/reference sample flag.
    dump_zeroes : in std_logic;               --! Flag to indicate that the zeroes have to be dumped.
    -- Modified by AS: new interface port --
    ref_block  : in std_logic;                --! Reference sample included in the current block
    ------------------------------------
    
    -- Data Interface
    mapped    : in std_logic_vector (W_MAP-1 downto 0);   --! Mapped prediction residual.
    zero_count  : out std_logic_vector (W_ZERO-1 downto 0);   --! Counter for zero block.
    zero_code : out std_logic_vector (1 downto 0);      --! Code for zero option.
    winner_l_k  : out std_logic_vector (W_L_K -1 downto 0);   --! Length of the minimum sample split sequence.
    winner_k  : out std_logic_vector(W_K -1 downto 0)     --! Length of the second extension option.
    );    
end lkoptions;

--! @brief Architecture of lkoptions
--! @details This module finds the minimum length for all the sample split options. The length for each of the sample_split options is calculated and the minimum is found by subtraction.
architecture arch of lkoptions is

  type arr_type is array (0 to N_K) of std_logic_vector (W_L_K-1 downto 0); 
  signal p_l_k: arr_type; -- possible lk
  
  type arr_type1 is array (0 to N_K-1) of signed (W_L_K downto 0);  
  signal sub_l_k: arr_type1; -- subtraction results
  
  type arr_type2 is array (0 to N_K) of std_logic;  
  signal overflow_k: arr_type2;
  
  signal signs: std_logic_vector(0 to N_K-1);
  signal k_min_cmb: unsigned (winner_k'high downto 0);

  signal winner_l_k_cmb: std_logic_vector (W_L_K -1 downto 0);
  
  -- for zero block option
  signal zero_count_tmp, zero_count_out: std_logic_vector (W_ZERO-1 downto 0);
  signal zero_code_tmp: std_logic_vector (1 downto 0);
  -- Modified by AS & YB: signal to register the reference block signal
  signal ref_block_reg : std_logic;
  ------------------------
  
begin

  ----------------------
  --! Output assignments
  ----------------------
  zero_count <= zero_count_out;
  zero_code <= zero_code_tmp;

  -----------------------------------------------------------------
  --!@brief lkcomp and substractors for one each k possible options
  -----------------------------------------------------------------
  lk_comtutation: for k in 0 to N_K generate
    
    ----------------
    --!@brief lkcomp
    ----------------
    compute_l_k: entity VH_compressor.lkcomp(arch)
    generic map (
      W_MAP => W_MAP,
      K => k,
      W_L_K => W_L_K,
      MAX_SIZE => MAX_SIZE)
    port map (
      clk => clk,
      rst_n => rst_n,
      mapped => mapped,
      clear => clear,
      en => en_lk,
      clear_acc => clear_acc,
      -- Modified by AS: new interface ports --
      ref_block => ref_block,
      config_in => config_in,
      ----------------------
      l_k => p_l_k (k),
      overflow_out => overflow_k(k)
      );
      
    ---------------------
    --!@brief substractor
    ---------------------
    subtractors:
    if k > 0 generate
      sub_l_k (k-1) <=  signed('0'&p_l_k (k)) - signed('0'& p_l_k (k-1));
      signs(k-1)    <= sub_l_k (k-1)(sub_l_k (k-1)'high) when (overflow_k(k) and overflow_k(k-1)) = '0' else '1';
    end generate;
  end generate;

  ---------------------
  --!@brief substractor
  ---------------------
  process (signs, p_l_k, config_in)
    variable k_min: integer := 0;
    -- Maximum K value allowed by configuration
    variable n_k_opt: integer := 0;           
  begin
    
    
    for i in 0 to (N_K - 1) loop
      -- find the first zero en signs(i) (using zeros instead of 1s to make it easier to detect)
      if (signs (i) = '0') then 
        k_min := i; 
        exit;
      else 
        k_min := N_K;
      end if;
    end loop;
    n_k_opt := get_n_k_options(to_integer(unsigned(config_in.D)), to_integer(unsigned(config_in.CODESET)));
    if (k_min > n_k_opt) then
      k_min := n_k_opt;
    end if;
    k_min_cmb <= to_unsigned(k_min, k_min_cmb'length);
    winner_l_k_cmb <= p_l_k (k_min);
  end process;
  
  ---------------------
  --! Output registration
  ---------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      winner_k <= (others => '0');
      winner_l_k <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        winner_k <= (others => '0');
        winner_l_k <= (others => '0');
      else
        if (en_k_winner = '1') then
          winner_k  <= std_logic_vector (k_min_cmb);
          winner_l_k <= winner_l_k_cmb;
        end if;
      end if;
    end if;
  end process;
  
  --------------------------
  --! Process for zero_block
  --------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      zero_count_out <= (others => '0');
      zero_count_tmp <= (others => '0');
      zero_code_tmp <= (others => '0');
      -- Modified by AS & YB: signal to register the reference block signal
      ref_block_reg <= '0';
      ------------------------
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        zero_count_out <= (others => '0');
        zero_count_tmp <= (others => '0');
        zero_code_tmp <= (others => '0');
        -- Modified by AS & YB: signal to register the reference block signal
        ref_block_reg <= '0';
        ------------------------
      else 
        -- Modified by AS & YB: signal to register the reference block signal
        if (clear_acc = '1') then
          ref_block_reg <= ref_block;
        end if;
        -----------------------------
        if (en_k_winner = '1') then
          if (dump_zeroes = '1') then
            --if (EOF_IS_EOS = 1) then
              zero_code_tmp <= "11";
              zero_count_tmp <= std_logic_vector(to_unsigned(0, zero_count_tmp'length));
            -- Next section commented since EOF_IS_EOS is always 1 (for the moment)
            -- else
              -- if (eos = '1') then
                -- zero_code_tmp <= "11"; 
                -- zero_count_tmp <= std_logic_vector(to_unsigned(0, zero_count_tmp'length));
              -- else
                -- zero_count_tmp <= (others => '0');
                -- if (zero_code_tmp = "01") then -- Encode zero blocks
                  -- zero_code_tmp <= "10";
                -- else
                  -- zero_code_tmp <= "00";
                  -- zero_count_out <= (others => '0'); 
                -- end if;
              -- end if;
            --end if;   
          -- Modified by AS & YB: condition to detect a zero-block extended to consider the blocks with reference sample    
          elsif (((unsigned(p_l_k (0)) = resize(unsigned(config_in.J), p_l_k (0)'length)) and (ref_block_reg = '0')) or ((unsigned(p_l_k (0)) = resize(unsigned(config_in.J), p_l_k (0)'length) + resize(unsigned(config_in.D), p_l_k (0)'length) - 1) and (ref_block_reg = '1'))) then
          ----------------------------------
            zero_count_out <= std_logic_vector(unsigned(zero_count_tmp)+1);
            -- End of segment is reached
            if (eos = '1') then 
              --if (unsigned(zero_count_tmp) = 0) then
              --  zero_code_tmp <= "01";
              --  zero_count_tmp <= std_logic_vector(unsigned(zero_count_tmp)+1);
              --else
                zero_code_tmp <= "11";
                zero_count_tmp <= std_logic_vector(to_unsigned(0, zero_count_tmp'length));
              --end if;           
            else
              zero_code_tmp <= "01";
              zero_count_tmp <= std_logic_vector(unsigned(zero_count_tmp)+1);
            end if;
          else
            zero_count_tmp <= (others => '0');
            -- Encode zero blocks
            if (zero_code_tmp = "01") then 
              zero_code_tmp <= "10";
            else
              zero_code_tmp <= "00";
              zero_count_out <= (others => '0'); 
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  
end arch;
