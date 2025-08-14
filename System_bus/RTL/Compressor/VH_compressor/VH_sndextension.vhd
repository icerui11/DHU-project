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
-- Design unit  : second extension module
--
-- File name    : sndextension.vhd
--
-- Purpose      : This module will calculate gamma value and the length of the sequence.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
--
-- Instantiates : 
--============================================================================
--!@file #sndextension.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief   This module will calculate gamma = [(mapped(i)+mapped(i+1))*(mapped(i)+mapped(i+1) + 1)] >> 2 + mapped(i+1) and the length of the sequence.


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

--! sndextension entity  Calculates the gamma value
entity sndextension is
  generic (
    BLOCK_SIZE  : integer := 16;      --! Size of the block (J).
    W_MAP    : integer := 32;       --! Bit width of the mapped prediction residuals.
    W_GAMMA    : integer := 5;       --! Bit width of each gamma value.
    W_L_GAMMA  : integer := 9;       --! Bit width of the length of the second extension sequence.
    MAX_SIZE  : integer := 512;      --! Maximum size of the sequence (in bits).
    RESET_TYPE   : integer := 1        --! Reset type.
  );
  port (
    -- System Interface
    clk   : in std_logic;         --! Clock signal.
    rst_n : in std_logic;         --! Reset signal. Active low.
    
    -- System Interface
    mapped    : in std_logic_vector (W_MAP-1 downto 0); --! Mapped prediction residuals.
    clear   : in std_logic;               --! It forces the module to its initial state.
    clear_acc  : in std_logic;                --! Clear accumulators. Activated with the first sample of each block.
    -- Modified by AS: new interface ports --
    ref_block  : in std_logic;                --! Reference sample included in the current block
    config_in  : in config_121;              --! Current configuration parameters.
    ------------------------------------
    
    -- System Interface
    en        : in std_logic;                   --! Enable signal.
    gamma     : out std_logic_vector (W_GAMMA-1 downto 0);    --! Gamma value.
    gamma_valid   : out std_logic;                  --! Flag to validate gamma.
    l_gamma     : out std_logic_vector (W_L_GAMMA-1 downto 0)   --! Length in bits of the second extension encoded block.
  );
end sndextension;

--! @brief Architecture of sndextension 
architecture arch of sndextension is

  -- control signals for performing calculation or storing and validating output
  signal en_compute : std_logic;
  signal en_store_n : std_logic;
  signal gamma_valid1 : std_logic;
  signal clear_d1   : std_logic;
  signal clear_d2   : std_logic;
  signal gamma_cmb  : unsigned (W_GAMMA-1 downto 0);
  signal en_output  : std_logic;
  
  -- to store previous mapped value
  signal mapped_prev  : std_logic_vector (W_MAP-1 downto 0);
  signal mapped_tmp : std_logic_vector (W_MAP-1 downto 0);
  
  -- intermediate values
  signal v0_tmp   : unsigned (mapped'length downto 0);

  signal v0_cmb   : unsigned (mapped'length downto 0);
  signal l_gamma_tmp  : unsigned (W_L_GAMMA-1 downto 0);
  signal l_gamma_cmb  : unsigned (W_L_GAMMA-1 downto 0);

  
  -- overflow flags
  signal flag_ov1 : std_logic;
  signal flag_ov2 : std_logic;
  signal flag_ov3 : std_logic;
  signal overflow : std_logic;
  

begin

  ------------------------------------
  --! Data Output assignments
  ------------------------------------
  l_gamma <= std_logic_vector (l_gamma_tmp);
  
  ------------------------------------
  --! Registration process
  ------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      gamma <= (others => '0');
      gamma_valid <= '0';
      l_gamma_tmp <= (others => '0');
      mapped_prev <= (others => '0');
      v0_tmp <=  (others => '0');
      mapped_tmp <= (others => '0');
      gamma_valid1 <= '0';
      clear_d1 <= '0';
      clear_d2 <= '0';
      en_store_n <= '0';
      en_compute <= '0';
      en_output <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        gamma <= (others => '0');
        gamma_valid <= '0';
        l_gamma_tmp <= (others => '0');
        mapped_prev <= (others => '0');
        v0_tmp <=  (others => '0');
        mapped_tmp <= (others => '0');
        gamma_valid1 <= '0';
        clear_d1 <= '0';
        clear_d2 <= '0';
        en_store_n <= '0';
        en_compute <= '0';
        en_output <= '0';
      else
        --en_compute <= '0';
        if (en = '1') then
          if (en_store_n = '0') then
            mapped_prev <= mapped;
            -- Modified by AS: When the reference sample is included in a block, the first value used for gamma computation is 0 instead of the reference sample --
            if ((clear_acc = '1') and (ref_block = '1')) then
              mapped_prev <= (others => '0');
            end if;
            ------------------------------------
            en_store_n <= '1';
            en_compute <= '1';
          -- en_store_n will be 0 other way
          --elsif en_compute = '1' then 
          else
            en_store_n <= '0';
          end if;
          if (en_compute = '1') then
            mapped_tmp <= mapped;
            en_compute <= '0';
          end if; 
        end if; 
        en_output <= en_compute and en;
        v0_tmp <= v0_cmb;
        if (en_output = '1') then
          l_gamma_tmp <=  l_gamma_cmb;
          gamma  <= std_logic_vector(gamma_cmb);
        end if; 
        gamma_valid1 <= en_compute and en;
        gamma_valid <= gamma_valid1;
        if (en = '1') then --capture only if enabled
          clear_d1 <= clear_acc;
          clear_d2 <= clear_d1;
        end if;
      end if;
    end if;
  end process;
  
  --------------------------------------------------------------------------------------
  --! Process to obtain the proper value of gamma and flags to control possible overflow
  --------------------------------------------------------------------------------------
  process (en_compute, en, v0_tmp, mapped_prev, clear_d2, overflow, l_gamma_tmp, mapped, mapped_tmp, flag_ov1, flag_ov2, ref_block, config_in) 
    constant W_MULT: integer := W_GAMMA*2;
    constant MAX_GAMMA: integer := 2**W_GAMMA -1;
    variable v0: unsigned (mapped'length downto 0);
    variable v1: unsigned (mapped'length downto 0);
    variable v2:  unsigned (W_MULT-1 downto 0);
    variable v3: unsigned (W_MULT-1 downto 0);
    variable v4: unsigned (l_gamma_cmb'length-1 downto 0);
   
  begin
    if (en_compute = '1' and en = '1') then
      v0 := resize(unsigned (mapped), v0'length)  + resize(unsigned (mapped_prev), v0'length);
    else
      v0 := v0_tmp;
    end if;
    v0_cmb <= v0;
    v1 := v0_tmp + 1;
    
    if (v1 < to_unsigned (MAX_GAMMA, v1'length)) then
      flag_ov1 <= '0';
    else 
      flag_ov1 <= '1';
    end if;
    
    --v2 := (v1(W_GAMMA-1 downto 0)*v0_tmp(W_GAMMA-1 downto 0)) srl 1;
    v2 := ((resize(v1,W_GAMMA))*(resize(v0_tmp,W_GAMMA))) srl 1;
    
    v3 := v2 + resize(unsigned(mapped_tmp), v2'length);
    
    if (v3 < to_unsigned (MAX_GAMMA, v1'length)) then
      flag_ov2 <= '0';
    else 
      flag_ov2 <= '1';
    end if;
    
    -- Here take into account when computing the length of the gamma option (l_gamma_cmb), that if the reference sample is inserted
    -- we encode it with config_in.D bits
    if (clear_d2 = '1') then
      l_gamma_cmb <= resize(v3, l_gamma_cmb'length);
      -- Modified by AS: Accumulator initialization with reference sample --
      if (ref_block = '1') then
        l_gamma_cmb <= resize(v3, l_gamma_cmb'length) + resize(unsigned(config_in.D), l_gamma_cmb'length);
      end if;
      ------------------------------------
      gamma_cmb <= v3(W_GAMMA-1 downto 0);
      flag_ov3 <= '0';
    elsif (overflow = '1' or flag_ov1 = '1' or flag_ov2 = '1') then 
      gamma_cmb <= (others => '1');
      l_gamma_cmb <= to_unsigned(MAX_SIZE, l_gamma_cmb'length);
      flag_ov3 <= '0';
    else
      gamma_cmb <= v3(W_GAMMA-1 downto 0);
      v4 := resize(l_gamma_tmp, v4'length) + resize(v3, v4'length);

      if (v4 > to_unsigned (MAX_SIZE, v4'length)) then
        flag_ov3 <= '1';
        l_gamma_cmb <= to_unsigned(MAX_SIZE, l_gamma_cmb'length);
      else
        flag_ov3 <= '0';
        l_gamma_cmb <= v4 (l_gamma_cmb'high downto 0);
      end if;
    end if; 
  end process;
  
  -----------------------------------
  --! Control for a possible overflow
  -----------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      overflow <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        overflow <= '0';
      else
        if (clear_d2 = '1') then
          overflow <= '0';
        elsif flag_ov1 = '1' or flag_ov2 = '1' or overflow = '1' or flag_ov3 = '1' then
          overflow <= '1';
        end if;
      end if;
    end if;
  end process;

end arch;
