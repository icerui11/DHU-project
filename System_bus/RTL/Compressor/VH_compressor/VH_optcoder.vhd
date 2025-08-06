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
-- Design unit  : optcoder module
--
-- File name    : optcoder.vhd
--
-- Purpose      : This module will calculate the optcode and the winning option for compression.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos 
--============================================================================

--!@file #optcoder.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  This module will calculate the optcode and the winning option for compression.

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

--! optcoder entity  Calculates the optcode and the winning option for compression.
entity optcoder is
  generic (
    W_OPT   : integer   := 5;     --! Number of bits for the option identifier.
    W_L   : integer   := 9;   --! Bit width of the different options.
    W_L_GAMMA : integer   := 8;   --! Bit width of the length for gamma option.
    BLOCK_SIZE  : integer   := 16;    --! Size of the block (J).
    W_K     : integer   := 5;   --! Bit width of the number of bits to split (k).
    MAX_SIZE  : integer := 256;   --! Maximum size (in bits) of a compressed block J*D.
    W_MAP   : integer   := 16;    --! Bit width of the mapped prediction residuals.
    RESET_TYPE  : integer   := 1    --! Bit width of the zero_block counter.
    );      
  port (
    -- System Interface
    clk   : in std_logic;                     --! Clock signal.
    rst_n : in std_logic;                     --! Reset signal. Active low.
    
    -- Configuration Interface
    config_in : in config_121;              --! Current configuration parameters.
    clear   : in std_logic;               --! It forces the module to its initial state.
    en      : in std_logic;               --! Enable signal.
    
    -- Control and Data Interface
    l_gamma     : in std_logic_vector (W_L_GAMMA-1 downto 0);   --! Length in bits of the second extension encoded block.
    winner_l_k    : in std_logic_vector (W_L-1 downto 0);       --! Length in bits of the sample split encoded block.
    winner_k    : in std_logic_vector (W_K -1 downto 0);      --! "k" value for the sample split option.
    zero_code   : in std_logic_vector(1 downto 0);          --! Code for zero_block.
    option      : out std_logic_vector (W_OPT-1 downto 0);      --! Selected encoding option.
    winner_l    : out std_logic_vector (W_L-1 downto 0);      --! Length of the encoded block with the selected option.
    winner_k_out  : out std_logic_vector (W_K -1 downto 0)      --! "k" value for the sample split option.
    );
end optcoder;

--! @brief Architecture of optcoder

architecture arch of optcoder is

  -- Intermediate signals for candidates and necessary signal to calculate them 
  signal candidate2   : unsigned (W_L-1 downto 0);
  signal candidate1   : unsigned (W_L-1 downto 0);
  signal l_gamma_cmb    : unsigned (W_L-1 downto 0);
  signal winner_l_k_cmb : unsigned (W_L-1 downto 0);
  signal winner_k_cmb   : std_logic_vector (W_K -1 downto 0);
  signal winner_k_cmb1  : std_logic_vector (W_K -1 downto 0);
  signal opt_cmb2     : std_logic_vector (W_OPT-1 downto 0);
  signal opt_cmb1     : std_logic_vector (W_OPT-1 downto 0);
  signal zeros      : std_logic_vector (W_OPT-2 downto 0);
  
begin
  
  -----------------------------------------------------------------------------------------------------
  --! Final size of gamma option  (including + 1 for correction (because OPTION id for gamma takes +1))
  -----------------------------------------------------------------------------------------------------
  l_gamma_cmb <= resize(unsigned (l_gamma), l_gamma_cmb'length) + resize((unsigned(config_in.J) srl 1), l_gamma_cmb'length) + 1;
  winner_l_k_cmb <= unsigned(winner_l_k);
  zeros <= (others => '0');
  
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      winner_l <= (others => '0');
      winner_k_out <= (others => '0');
      option <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        winner_l <= (others => '0');
        winner_k_out <= (others => '0');
        option <= (others => '0');
      else
        if (en = '1') then
          if (zero_code(0) = '1') then
            winner_k_out <= (others => '0');
            winner_l <= (others => '0');
            option <= (others => '0');
          else
            winner_k_out <= winner_k_cmb1;
            winner_l <= std_logic_vector(candidate1);
            option <= opt_cmb1;
          end if;
        end if;
      end if;
    end if; 
  end process;
  
  -----------------------------------------
  --! Select between l_gamma and winner_l_k
  -----------------------------------------
  process (l_gamma_cmb, winner_l_k_cmb, winner_k, zeros)
  begin
    if(winner_l_k_cmb < l_gamma_cmb) then
      candidate2 <= winner_l_k_cmb;
      --opt_cmb2 <= std_logic_vector(unsigned('1'&(winner_k(winner_k'high-1 downto 0))) + 1); 
      opt_cmb2 <= std_logic_vector(unsigned('1'&(winner_k(winner_k'high-1 downto 0))) + 1); 
      winner_k_cmb <= winner_k;
    else
      candidate2 <= l_gamma_cmb;
      opt_cmb2 <= zeros & '1';
      winner_k_cmb <= (others => '0');
    end if;
  end process;
  
  ------------------------------------------------------------
  --! select between candidate2, no compression and zero_block
  ------------------------------------------------------------
  process (candidate2, opt_cmb2, winner_k_cmb, config_in)
    variable max_size_aux: unsigned (W_D_GEN + W_J_GEN - 1  downto 0) := (others => '0');
    variable shift_value: integer := 0;
  begin
    for i in 0 to (config_in.J'high) loop
      -- find the first zero en signs(i) (using zeros instead of 1s to make it easier to detect)
      if (config_in.J (i) = '1') then 
         shift_value := i;
         exit;
       else
         shift_value := 0;    
       end if;    
     end loop;
    
    max_size_aux := shift_left(resize(unsigned(config_in.D),max_size_aux'length), shift_value);
    -- CANDIDATE2 (SECOND OR K)
    if(candidate2 < resize(max_size_aux, candidate2'length)) then 
      candidate1 <= candidate2;
      opt_cmb1 <= opt_cmb2;
      winner_k_cmb1 <= winner_k_cmb;
    -- NO COMPRESSION
    else 
      candidate1 <= resize(max_size_aux, candidate2'length);
      opt_cmb1 <= (others => '1');
      winner_k_cmb1 <= std_logic_vector(resize(unsigned(config_in.D), winner_k_cmb'length));
    end if;
  end process;

end arch;
