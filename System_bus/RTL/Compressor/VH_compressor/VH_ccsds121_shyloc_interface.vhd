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
-- Design unit  : ccsds121_shyloc_interface 
--
-- File name    : ccsds121_shyloc_interface.vhd
--
-- Purpose      : Selects the proper configuration parameters for the compression, between generic values and the values received by AMBA, according to the EN_RUNCFG generic
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--============================================================================

--!@file #ccsds121_shyloc_interface.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Selects the proper configuration parameters for the compression, between generic values and the values received by AMBA, according to the EN_RUNCFG generic

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

--! Use constant shyloc121 configuration package
use VH_compressor.config121_package.all;

--! ccsds121_shyloc_interface entity  Selects the proper configuration parameters for the compression
--! Selecting values between generic values and the values received by AMBA, according to the EN_RUNCFG generic
entity ccsds121_shyloc_interface is
  generic (
    RESET_TYPE : integer := 1   --! Reset type
  );
  port (
    -- System Interface
    clk   : in std_logic;             --! Clock signal.
    rst_n : in std_logic;           --! Reset signal. Active low.
    
    -- Interface 
    config_in: in config_121;         --! Configuration captured by AMBA
    en: in std_logic;             --! Enable the configuration selection
    clear: in std_logic;            --! Compression has been forced to stop. Go back to idle state
    
    -- Configuration data
    config:     out config_121;           --! Configuration selected
    config_valid :  out std_logic;            --! Configuration selected is valid
    Nx_times_Ny:  out std_logic_vector (W_Nx_GEN + W_Ny_GEN -1 downto 0); --! Initial multiplication of coordinates.
    error:      out std_logic;            --! Indicates an error on the configuration selected
    error_code:   out std_logic_vector(3 downto 0)  --! Indicates the error
  );
end ccsds121_shyloc_interface;

--! @brief Architecture of ccsds121_shyloc_interface
--! @details Besides selecting the proper configuration values, there compliance with certain restrictions are checked and error flag and error code are generated if necessary.
architecture arch of ccsds121_shyloc_interface is

  -- signals to store configuration and validate it
  signal config_reg   : config_121:= (others => (others => '0'));
  signal config_cmb   : config_121:= (others => (others => '0'));
  signal config_valid_reg : std_logic := '0';
  signal config_valid_cmb : std_logic := '0';
  
  -- signals to store error code and validate it
  signal error_reg    : std_logic := '0';
  signal error_cmb    : std_logic := '0';
  signal error_code_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal error_code_cmb : std_logic_vector(3 downto 0) := (others => '0');
    
begin
  
  ----------------------
  --! output assignments
  ----------------------  
  config <= config_reg;
  error <= error_reg;
  error_code <= error_code_reg;
  config_valid <= config_valid_reg and not en;
  
  -----------------------
  --! output registration
  ----------------------- 
  process (clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      config_reg <= (others => (others => '0'));    
      config_valid_reg <= '0';      
      error_reg <= '0';           
      error_code_reg <= (others => '0'); 
      Nx_times_Ny <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        config_reg <= (others => (others => '0'));
        error_reg <= '0';
        error_code_reg <= (others => '0');
        config_valid_reg <= '0';
        Nx_times_Ny <= (others => '0');
      else 
        Nx_times_Ny <= std_logic_vector(unsigned(config_cmb.Nx)*unsigned(config_cmb.Ny));
        config_reg <= config_cmb;
        config_valid_reg <= config_valid_cmb;
        error_reg <= error_cmb;
        error_code_reg <= error_code_cmb;
      end if;
    end if;
  end process;
  
  ----------------------------------------------
  --! Capture of the proper configuration values 
  ----------------------------------------------
  process (config_in, en, error_reg, error_code_reg, config_reg, config_valid_reg)
    variable config_aux: config_121;
  begin
    config_cmb <= config_reg;
    error_cmb <= error_reg;
    error_code_cmb <= error_code_reg;
    config_valid_cmb <= config_valid_reg;
    if (en = '1') then
      -- Capturing configuration values from generics
      if (EN_RUNCFG = 0) then
        config_cmb <= configure_gen;
        config_aux := configure_gen;
        
      -- Capturing configuration values from received configuration
      else
        config_cmb <= config_in;
        config_aux := config_in; 
      end if;
      -- Checking errors in configuration parameters selected
      if (unsigned(config_aux.Nx) = 0 or unsigned(config_aux.Ny) = 0 or unsigned(config_aux.Nz) = 0) then
        error_cmb <= '1';
        error_code_cmb <= "0001";
      elsif (unsigned(config_aux.Nx) < 1 or unsigned(config_aux.Nx) > Nx_GEN or unsigned(config_aux.Nx) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      elsif (unsigned(config_aux.Ny) < 1 or unsigned(config_aux.Ny) > Ny_GEN or unsigned(config_aux.Ny) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      elsif (unsigned(config_aux.Nz) < 1 or unsigned(config_aux.Nz) > Nz_GEN or unsigned(config_aux.Nz) > 65535) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      -- Modified by AS: Now the maxium value for D is 32 --  
      elsif (unsigned(config_aux.D) > D_GEN or unsigned(config_aux.D)  < 2 or unsigned(config_aux.D)  > 32) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      -- Modified by AS: Value PREPROCESSOR_GEN = 3 is now supported --  
      elsif (PREPROCESSOR_GEN > 3) then
      ------------------------------------
        error_cmb <= '1';
        error_code_cmb <= "0010";
      elsif (config_aux.J(2 downto 0) /= "000" or unsigned(config_aux.J) = 0) or (unsigned(config_aux.J) > 64) then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      elsif (unsigned(config_aux.REF_SAMPLE) > REF_SAMPLE_GEN) or (unsigned(config_aux.REF_SAMPLE) > 4096 )then
        error_cmb <= '1';
        error_code_cmb <= "0010";
      elsif (unsigned(config_aux.W_BUFFER) < unsigned(config_aux.D) or unsigned(config_aux.W_BUFFER) > W_BUFFER_GEN) then
        error_cmb <= '1';
        error_code_cmb <= "0011";
      elsif (W_BUFFER_GEN < (D_GEN) or W_BUFFER_GEN > 64) then
        error_cmb <= '1';
        error_code_cmb <= "0011";
      -- No error detected in configuration
      else 
        error_cmb <= '0';
        error_code_cmb <= "0000";
        config_valid_cmb <= '1';
      end if;   
    
    end if;
  end process;
  

  
end arch;
