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
-- Design unit  : ccsds121 predictor components 
--
-- File name    : ccsds121_predictor_comp.vhd.vhd
--
-- Purpose      : Makes the actual pre-processing step of the CCSDS 121 standard.
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
-- Instantiates : ...
--============================================================================

--!@file #ccsds121_predictor_comp.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Makes the actual pre-processing step of the CCSDS 121 standard.

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

--! ccsds121_predictor_comp entity  Component module of the CCSDS121 - predictor
--! Makes the actual pre-processing step of the CCSDS 121 standard.
entity ccsds121_predictor_comp is
  generic(
    W_Sample  : integer := 16;   --! Bit width of the samples and mapped prediction residuals.
    RESET_TYPE  : integer := 1    --! Reset type.
  );
  port(
    -- System Interface
    clk        : in std_logic;    --! Clock signal.
    rst_n      : in std_logic;    --! Reset signal. Active low.
    clear       : in std_logic;    --! Clear signal.
    
    -- Configuration Interface
    config_valid    : in std_logic;    --! Validation of configuration parameters
    config_s      : in config_121;  --! Current configuration parameters
    
    -- Control Interface
    sample_valid  : in std_logic;    --! Validates pre-processed sample
    bypass_pred    : in std_logic;    --! Bypass preprocessor in order to insert reference samples
    
    -- Data Interface
    SampleIn    : in std_logic_vector (W_Sample-1 downto 0);
    SampleOut    : out std_logic_vector (W_Sample-1 downto 0)
  );
end ccsds121_predictor_comp;

--! @brief Architecture of ccsds121_predictor_comp 
architecture arch of ccsds121_predictor_comp is
  -- Intermediate signals
  signal curr_sample  : std_logic_vector (W_Sample-1 downto 0);
  signal pred_sample  : std_logic_vector (W_Sample-1 downto 0);
  signal pred_res    : signed (W_Sample downto 0);
  signal smin, smax  : std_logic_vector (W_Sample downto 0);
  signal mapped_res  : std_logic_vector (W_Sample-1 downto 0);
begin
  ---------------------------
  --!@brief endianess swap
  ---------------------------
  --Endianess 0 means little endian
  --gen_endianess_swap: if (D_GEN > 8) generate
  --  curr_sample <=  SampleIn(D_GEN-9 downto 0)&SampleIn(D_GEN-1 downto D_GEN-8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
  --    else SampleIn;
  --end generate gen_endianess_swap;
  
  --gen_endianess_noswap: if (D_GEN <= 8) generate
  --  curr_sample <= SampleIn;
  --end generate gen_endianess_noswap;
  
  -- Assignment, after endianess swap is moved to top module
  -- just pass the input. 
  
   curr_sample <= SampleIn;
   
   
  --commenting out endianess swap, it is moved to top module.
  --gen_endianness_swap_32: if (D_GEN > 24) generate
    --curr_sample <= SampleIn(7 downto 0)&SampleIn(15 downto 8)&SampleIn(23 downto 16)&SampleIn(D_GEN-1 downto 24) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 24))
    --curr_sample <= SampleIn(D_GEN-25 downto 0)&SampleIn(D_GEN-17 downto D_GEN-24)&SampleIn(D_GEN-9 downto D_GEN-16)&SampleIn(D_GEN-1 downto D_GEN-8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 24)) 
    --  else SampleIn(D_GEN-1 downto 24)&SampleIn(7 downto 0)&SampleIn(15 downto 8)&SampleIn(23 downto 16) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 16)) 
    --  else SampleIn(D_GEN-1 downto 16)&SampleIn(7 downto 0)&SampleIn(15 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
     -- else SampleIn;
  --end generate gen_endianness_swap_32;

  --gen_endianness_swap_24: if ((D_GEN > 16) and(D_GEN <= 24)) generate
    --curr_sample <= SampleIn(7 downto 0)&SampleIn(15 downto 8)&SampleIn(D_GEN-1 downto 16) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 16)) 
    --curr_sample <= SampleIn(D_GEN-17 downto 0)&SampleIn(D_GEN-9 downto D_GEN-16)&SampleIn(D_GEN-1 downto D_GEN-8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 16))
    --  else SampleIn(D_GEN-1 downto 16)&SampleIn(7 downto 0)&SampleIn(15 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
    --  else SampleIn;
  --end generate gen_endianness_swap_24;

 -- gen_endianness_swap_16: if ((D_GEN > 8) and(D_GEN <= 16)) generate
    --curr_sample <= SampleIn(7 downto 0)&SampleIn(D_GEN-1 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
   -- curr_sample <=  SampleIn(D_GEN-9 downto 0)&SampleIn(D_GEN-1 downto D_GEN-8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
   --   else SampleIn;
  --end generate gen_endianness_swap_16;
  
  --gen_endianness_noswap: if (D_GEN <= 8) generate
  --  curr_sample <= SampleIn;
  --end generate gen_endianness_noswap;
  
  ---------------------------
  --!@brief unit-delay predictor
  ---------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      pred_sample <= (others =>'0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        pred_sample <= (others =>'0');
      elsif (sample_valid = '1') then
        pred_sample <= curr_sample;
      end if;
    end if;
  end process;
  
  ---------------------------
  --!@brief prediction residual computation
  ---------------------------
  pred_res <= (resize(signed(curr_sample), W_Sample+1) - resize(signed(pred_sample), W_Sample+1)) when (config_s.IS_SIGNED = "1")    -- signed samples
    else (signed('0' & curr_sample) - signed('0' & pred_sample));                                  -- unsigned samples
  
  ---------------------------
  --!@brief mapper (revisar)
  ---------------------------
  process(config_s)
  begin
    for i in 0 to W_Sample loop
      if config_s.IS_SIGNED = "0" then  -- unsigned samples
        smin(i) <= '0';          -- smin = 0
        if (i < to_integer(unsigned(config_s.D))) then    -- smax = 2 ^ D - 1
          smax(i) <= '1';
        else
          smax(i) <= '0';
        end if;
      else                -- signed samples
        if (i < (to_integer(unsigned(config_s.D)) - 1)) then  -- smin = -2 ^ (D - 1)
          smin(i) <= '0';        -- smax = 2 ^(D - 1) - 1
          smax(i) <= '1';
        else
          smin(i) <= '1';
          smax(i) <= '0';
        end if;
      end if;
    end loop;
  end process;
  
  process (pred_res, pred_sample, smax, smin)
    variable omg_tmp1, omg_tmp2: signed (W_Sample downto 0);
    variable omg: signed (W_Sample downto 0);
    variable abs_pred_residual: signed(W_Sample downto 0);
    variable mapped_var: signed (W_Sample downto 0);
    variable pred_sample_tmp: signed (W_Sample downto 0);  
    
  begin
    if (config_s.IS_SIGNED = "1") then
      pred_sample_tmp := resize(signed(pred_sample), W_Sample+1);
    else
      pred_sample_tmp := signed('0' & pred_sample);
    end if;    

    omg_tmp1 := pred_sample_tmp - signed(smin); 
    omg_tmp2 := signed(smax) - pred_sample_tmp;
    
    if (omg_tmp1 < omg_tmp2) then
      omg := omg_tmp1;
    else
      omg := omg_tmp2;
    end if;
    
    abs_pred_residual := abs(pred_res);
    
    if (abs_pred_residual > omg) then
      mapped_var := abs_pred_residual + omg;
    elsif (pred_res < to_signed(0, W_Sample)) then
      mapped_var := (abs_pred_residual(W_Sample-1 downto 0) & '0') - 1;
    else
      mapped_var := abs_pred_residual(W_Sample-1 downto 0) & '0';
    end if;
    
    mapped_res <= std_logic_vector(mapped_var(W_Sample-1 downto 0));

  end process;
  
  ---------------------------
  --!@brief output assignments
  ---------------------------
  SampleOut <= mapped_res when ((bypass_pred = '0') and (config_s.BYPASS = "0"))
    else curr_sample;
end arch;
