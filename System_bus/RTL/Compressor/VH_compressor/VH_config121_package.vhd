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
-- Design unit  : Package for configuration modules of the CCSDS 121
--
-- File name    : config121_package.vhd
--
-- Purpose      : Implements the function that reads the configuration values from the memory-mapped registers. Includes function to set the configuration set to generics.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--============================================================================

--!@file #config121_package.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief Implements the function that reads the configuration values from the memory-mapped registers.
--!@details Includes function to set the configuration set to generics.

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


--! config121_package package
package config121_package is

-----------------------------------------------------------------------
--! Number of configuration words for the CCSDS121 Block-Adaptive Coder
-----------------------------------------------------------------------
constant N_CONFIG_WORDS : integer := 4;

----------------------------------------------------------------------
--! Assign values to configuration record from memory-mapped registers
----------------------------------------------------------------------
procedure ahb_read_config (config: inout config_121; datain: in std_logic_vector; address: in std_logic_vector; values_read: inout std_logic_vector; error: inout std_logic);

-----------------------------------------------------------------------------
--! Set configuration from generic values
-----------------------------------------------------------------------------
function configure_gen return config_121;

end config121_package;

package body config121_package is
  ----------------------------------------------------------------------
  --! Assign values to configuration record from memory-mapped registers
  ----------------------------------------------------------------------
  procedure ahb_read_config (config: inout config_121; datain: in std_logic_vector; address: in std_logic_vector; values_read: inout std_logic_vector; error: inout std_logic)  is
    constant off0: integer := 16#0#;
    constant off4: integer := 16#1#;
    constant off8: integer := 16#2#;
    constant offC: integer := 16#3#;
    
    variable vaddress: integer;
  begin
    vaddress := to_integer(unsigned(address));
    case (vaddress) is
      when off0 => 
        config.ENABLE := datain(0+config.ENABLE'high downto 0);
        if datain(0) = '1' then
          values_read(0) := '1';
        else 
          values_read(0) := '0';
        end if;
      when off4 =>
        config.Nx := datain(16+config.Nx'high downto 16);
        config.CODESET := datain(15 downto 15);
        config.DISABLE_HEADER := datain(14 downto 14);
        config.J := datain(7+config.J'high downto 7);
        config.W_BUFFER := datain (config.W_BUFFER'high  downto 0);
        values_read(1) := '1';
      when off8 =>
        config.Ny := datain(16+config.Ny'high downto 16);
        config.REF_SAMPLE := datain(3+config.REF_SAMPLE'high downto 3);
        values_read(2) := '1';
      when offC =>
        config.Nz := datain(16+config.Nz'high downto 16);
        config.D := datain(10+config.D'high downto 10);
        -- Modified by AS: New configuration parameter: sign of input samples --
        config.IS_SIGNED := datain(9 downto 9);
        ------------------------------------
        config.ENDIANESS := datain(8 downto 8);
        config.PREPROCESSOR := datain(7 downto 6);
        config.BYPASS := datain (5 downto 5);
        values_read(3) := '1';
      when others =>
        values_read(values_read'high downto 0) := (others => '0');
    end case;
  end procedure ahb_read_config; 
  
  -----------------------------------------------------------------------------
  --! Set configuration from generic values
  -----------------------------------------------------------------------------
  function configure_gen return config_121 is
    variable config_set: config_121;
  begin 
    config_set.Nx := std_logic_vector(to_unsigned(Nx_GEN, config_set.Nx'length));
    config_set.Ny := std_logic_vector(to_unsigned(Ny_GEN, config_set.Ny'length));
    config_set.Nz := std_logic_vector(to_unsigned(Nz_GEN, config_set.Nz'length));
    -- Modified by AS: New configuration parameter: sign of input samples --
    config_set.IS_SIGNED := std_logic_vector(to_unsigned(IS_SIGNED_GEN, config_set.IS_SIGNED'length));
    ------------------------------------
    config_set.ENDIANESS := std_logic_vector(to_unsigned(ENDIANESS_GEN, config_set.ENDIANESS'length));
    config_set.D := std_logic_vector(to_unsigned(D_GEN, config_set.D'length));
    config_set.J := std_logic_vector(to_unsigned(J_GEN, config_set.J'length));
    config_set.REF_SAMPLE := std_logic_vector(to_unsigned(REF_SAMPLE_GEN, config_set.REF_SAMPLE'length));
    config_set.CODESET := std_logic_vector(to_unsigned(CODESET_GEN, config_set.CODESET'length));
    config_set.W_BUFFER := std_logic_vector(to_unsigned(W_BUFFER_GEN, config_set.W_BUFFER'length));
    config_set.BYPASS := std_logic_vector(to_unsigned(BYPASS_GEN, config_set.BYPASS'length));
    config_set.PREPROCESSOR := std_logic_vector(to_unsigned(PREPROCESSOR_GEN, config_set.PREPROCESSOR'length));
    config_set.DISABLE_HEADER := std_logic_vector(to_unsigned(DISABLE_HEADER_GEN, config_set.DISABLE_HEADER'length));
    return config_set;
  end function;
end package body;
