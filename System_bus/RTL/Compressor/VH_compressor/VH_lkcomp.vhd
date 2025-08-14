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
-- Design unit  : lkcomp module
--
-- File name    : lkcomp.vhd
--
-- Purpose      : This module will calculate lk = sum(mapped(i) >> k) for one of the possible k options
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
-- Instantiates : 
--============================================================================

--!@file #lkcomp.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief   This module will calculate lk = sum(mapped(i) >> k) for one of the possible k options.

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
--! Use shyloc_utils functions
use shyloc_utils.shyloc_functions.all;

--! lkcomp entity. Finds the minimum length for all the sample split options.
entity lkcomp is
  generic (
       W_MAP: integer := 16;      --! Dynamic range of the mapped prediction residuals.
       K: integer := 0;       --! k option.
       W_L_K: integer := 9;       --! Maximum size of length for k option.
       MAX_SIZE: integer:= 256);    --! Maximum block size.
  port (
    -- System Interface
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    
    -- Control Interface
    en      : in std_logic;               --! Enable signal.
    clear   : in std_logic;               --! It forces the module to its initial state.
    clear_acc  : in std_logic;                --! Clear output accumulator l_gamma. Activated with the first sample of each block.
    -- Modified by AS: new interface ports --
    ref_block  : in std_logic;                --! Reference sample included in the current block
    config_in  : in config_121;              --! Current configuration parameters.
    ------------------------------------
    
    -- Data Interface
    mapped      : in std_logic_vector (W_MAP-1 downto 0);   --! Mapped prediction residual.
    l_k       : out std_logic_vector (W_L_K -1 downto 0);   --! Length of the second extension option.
    overflow_out  : out std_logic                 --! The result corresponds to an overflow. 
    );    
end lkcomp;

--! @brief Architecture of lkcomp
architecture arch of lkcomp is

  -- Zeroes signal and limit for length variables.
  constant W_K_TMP: integer := maximum (W_MAP, W_L_K); 
  signal zero     : std_logic_vector (W_MAP-1 downto 0);

  -- Signals to store lengths and shifted mapped
  signal mapped_shifted : unsigned (W_MAP-1 downto 0);
  signal l_k_tmp      : unsigned (W_K_TMP downto 0); -- +1 bit to avoid overflow
  signal l_k_cmb      : unsigned (W_K_TMP downto 0); -- +1 bit to avoid overflow
  
  -- Signals for overflow detection.
  signal overflow_cmb   : std_logic;
  signal overflow     : std_logic;
  
begin
  ----------------------
  --! Output assignments
  ----------------------
  l_k <= std_logic_vector(l_k_tmp (W_L_K-1 downto 0));
  overflow_out <= overflow;
  
  -------------------
  --! Shift operation
  -------------------
  zero <= (others => '0');  
  mapped_shifted  <= unsigned(zero (K-1 downto 0) & mapped (W_MAP-1 downto K));
  -- When the reference sample is inserted, the length is computed taking into account that the first sample is sent uncompressed,
  -- hence, we do not use the mapped_shifted, but the config_in.D 
  -- I think the situation is covered here with the clear_acc flag, which marks the beginning of a block, but better check the waveform. 
  -- Modified by AS: old accumulator initialization preserved when unit-delay predictor is not included --
  gen_acc_noref: if (PREPROCESSOR_GEN /= 2) generate
  l_k_cmb <= mapped_shifted + l_k_tmp + to_unsigned(K, l_k_cmb'length) + 1 when clear_acc = '0' else mapped_shifted + to_unsigned(K, l_k_cmb'length) +1; 
  end generate gen_acc_noref;
  -- -- Accumulator initialization with unit-delay predictor --
  gen_acc_ref: if (PREPROCESSOR_GEN = 2) generate
    process (mapped_shifted, l_k_tmp, clear_acc, ref_block, config_in)
    begin
      if clear_acc = '1' then
        if ref_block = '1' then    -- Initialization with reference sample: first sample uncompressed
          l_k_cmb <= resize(unsigned(config_in.D), l_k_cmb'length);
        else            -- Initialization without reference sample: first sample compressed as usual
          l_k_cmb <= mapped_shifted + to_unsigned(K, l_k_cmb'length) + 1;
        end if;
      else
        l_k_cmb <= mapped_shifted + l_k_tmp + to_unsigned(K, l_k_cmb'length) + 1;
      end if;
    end process;
  end generate gen_acc_ref;
  ------------------------------------
  
  ----------------------
  --! Overflow detector
  ----------------------
  overflow_cmb <= '1' when ( l_k_cmb >= to_unsigned(MAX_SIZE, l_k_tmp'length)) else '0';

  -----------------------------------
  --! Overflow and length calculation
  -----------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      l_k_tmp <= (others => '0');
      overflow <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        l_k_tmp <= (others => '0');
        overflow <= '0';
      else
        if (en = '1') then
          -- To put overflow back to 0 when the next block comes after 
          if (clear_acc = '1') then 
            if (overflow_cmb = '1') then
              overflow <= '1';
              l_k_tmp <= to_unsigned ((MAX_SIZE), l_k_tmp'length);
            else
              overflow <= '0';
              l_k_tmp <= l_k_cmb;
            end if;
          else
            if (overflow = '0') then
              if (overflow_cmb = '1') then
                overflow <= '1';
                l_k_tmp <= to_unsigned ((MAX_SIZE), l_k_tmp'length);
              else
                l_k_tmp <= l_k_cmb;
              end if;       
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
end arch;
