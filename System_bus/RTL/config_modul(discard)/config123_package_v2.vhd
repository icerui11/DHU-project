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
-- Design unit  : Package for configuration modules of the CCSDS 123
--
-- File name    : config123_package.vhd
--
-- Purpose      : Assing desired values to configuration records of the CCSDS123
--
-- Note         : 
--
-- Library      : shyloc_123
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--          35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : 
--                
-- Instantiates : 
--============================================================================
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; 

use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all; 


--!@file #config123_package.vhd#
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Implements the function that reads the configuration values from the memory-mapped registers.
--!@details Includes other useful signals to for assigments to configuration record. 

package config123_package is

-----------------------------------------------------------------------------
--! Assign values to configuration record from memory-mapped registers
-----------------------------------------------------------------------------
procedure ahb_read_config_123 (config: inout config_123_f; datain: in std_logic_vector; address: in std_logic_vector; values_read: inout std_logic_vector; error: inout std_logic);

-----------------------------------------------------------------------------
--! Set all values in configuration record to zero
-----------------------------------------------------------------------------
procedure zero_config (signal config:  inout config_123_f);

-----------------------------------------------------------------------------
--! Set all values in configuration record to zero
-----------------------------------------------------------------------------
procedure zero_config_var (variable config:  inout config_123_f);

-----------------------------------------------------------------------------
--! Set all values in control record to zero
-----------------------------------------------------------------------------
procedure zero_config (signal ctrl:  inout ctrls);

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
function configure_image return config_123_image;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
function configure_image return config_123_image_f;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
function configure_image (config_in: in config_123_f) return config_123_image;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
function configure_image (config_in: in config_123_f)  return config_123_image_f;

-----------------------------------------------------------------------------
--! Set predictor configuration
-----------------------------------------------------------------------------
function configure_predictor return config_123_predictor;

-----------------------------------------------------------------------------
--! Set predictor configuration
-----------------------------------------------------------------------------
function configure_predictor return config_123_predictor_f;

-----------------------------------------------------------------------------
--! Set predictor configuration
-----------------------------------------------------------------------------
function configure_predictor (config_in: in config_123_f)  return config_123_predictor;

-----------------------------------------------------------------------------
--! Set predictor configuration
-----------------------------------------------------------------------------
function configure_predictor (config_in: in config_123_f)  return config_123_predictor_f;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
-----------------------------------------------------------------------------
function configure_sample return config_123_sample;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
-----------------------------------------------------------------------------
function configure_sample return config_123_sample_f;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
-----------------------------------------------------------------------------
function configure_sample (config_in: in config_123_f)  return config_123_sample;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
-----------------------------------------------------------------------------
function configure_sample (config_in: in config_123_f)   return config_123_sample_f;

-- Number of configuration words
constant N_CONFIG_WORDS : integer := 6;

end config123_package;

package body config123_package is
-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
  function configure_image return config_123_image is
    variable config_image: config_123_image;
  begin 
    config_image.Nx := std_logic_vector(to_unsigned(Nx_GEN, config_image.Nx'length));
    config_image.Ny := std_logic_vector(to_unsigned(Ny_GEN, config_image.Ny'length));
    config_image.Nz := std_logic_vector(to_unsigned(Nz_GEN, config_image.Nz'length));
    config_image.IS_SIGNED := std_logic_vector(to_unsigned(IS_SIGNED_GEN, config_image.IS_SIGNED'length));
    config_image.ENDIANESS := std_logic_vector(to_unsigned(ENDIANESS_GEN, config_image.ENDIANESS'length));
    config_image.D := std_logic_vector(to_unsigned(D_GEN, config_image.D'length));
    config_image.DISABLE_HEADER := std_logic_vector(to_unsigned(DISABLE_HEADER_GEN, config_image.DISABLE_HEADER'length));
    config_image.BYPASS := std_logic_vector(to_unsigned(BYPASS_GEN, config_image.BYPASS'length));
    config_image.W_BUFFER := std_logic_vector(to_unsigned(W_BUFFER_GEN, config_image.W_BUFFER'length));
    config_image.ENCODER_SELECTION := std_logic_vector(to_unsigned(ENCODER_SELECTION_GEN, config_image.ENCODER_SELECTION'length));
    return config_image;
  end function;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
  function configure_image return config_123_image_f is
    variable config_image: config_123_image_f;
  begin 
    config_image.Nx := std_logic_vector(to_unsigned(Nx_GEN, config_image.Nx'length));
    config_image.Ny := std_logic_vector(to_unsigned(Ny_GEN, config_image.Ny'length));
    config_image.Nz := std_logic_vector(to_unsigned(Nz_GEN, config_image.Nz'length));
    config_image.IS_SIGNED := std_logic_vector(to_unsigned(IS_SIGNED_GEN, config_image.IS_SIGNED'length));
    config_image.ENDIANESS := std_logic_vector(to_unsigned(ENDIANESS_GEN, config_image.ENDIANESS'length));
    config_image.D := std_logic_vector(to_unsigned(D_GEN, config_image.D'length));
    config_image.DISABLE_HEADER := std_logic_vector(to_unsigned(DISABLE_HEADER_GEN, config_image.DISABLE_HEADER'length));
    config_image.BYPASS := std_logic_vector(to_unsigned(BYPASS_GEN, config_image.BYPASS'length));
    config_image.W_BUFFER := std_logic_vector(to_unsigned(W_BUFFER_GEN, config_image.W_BUFFER'length));
    config_image.ENCODER_SELECTION := std_logic_vector(to_unsigned(ENCODER_SELECTION_GEN, config_image.ENCODER_SELECTION'length));
    return config_image;
  end function;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------

  --from port 
  function configure_image (config_in: in config_123_f) return config_123_image is
    variable config_image: config_123_image;
  begin 
    config_image.Nx :=  std_logic_vector(resize(unsigned(config_in.Nx), config_image.Nx'length));
    config_image.Ny := std_logic_vector(resize(unsigned(config_in.Ny), config_image.Ny'length));
    config_image.Nz := std_logic_vector(resize(unsigned(config_in.Nz), config_image.Nz'length));
    config_image.IS_SIGNED := std_logic_vector(resize(unsigned(config_in.IS_SIGNED), config_image.IS_SIGNED'length));
    config_image.ENDIANESS := std_logic_vector(resize(unsigned(config_in.ENDIANESS), config_image.ENDIANESS'length));
    config_image.D := std_logic_vector(resize(unsigned(config_in.D), config_image.D'length));
    config_image.DISABLE_HEADER := std_logic_vector(resize(unsigned(config_in.DISABLE_HEADER), config_image.DISABLE_HEADER'length));
    config_image.BYPASS := std_logic_vector(resize(unsigned(config_in.BYPASS), config_image.BYPASS'length));
    config_image.W_BUFFER := std_logic_vector(resize(unsigned(config_in.W_BUFFER), config_image.W_BUFFER'length));
    config_image.ENCODER_SELECTION := std_logic_vector(resize(unsigned(config_in.ENCODER_SELECTION), config_image.ENCODER_SELECTION'length));
    return config_image;
  end function;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
  function configure_image (config_in: in config_123_f) return config_123_image_f is
    variable config_image: config_123_image_f;
  begin 
    config_image.Nx :=  std_logic_vector(resize(unsigned(config_in.Nx), config_image.Nx'length));
    config_image.Ny := std_logic_vector(resize(unsigned(config_in.Ny), config_image.Ny'length));
    config_image.Nz := std_logic_vector(resize(unsigned(config_in.Nz), config_image.Nz'length));
    config_image.IS_SIGNED := std_logic_vector(resize(unsigned(config_in.IS_SIGNED), config_image.IS_SIGNED'length));
    config_image.ENDIANESS := std_logic_vector(resize(unsigned(config_in.ENDIANESS), config_image.ENDIANESS'length));
    config_image.D := std_logic_vector(resize(unsigned(config_in.D), config_image.D'length));
    config_image.DISABLE_HEADER := std_logic_vector(resize(unsigned(config_in.DISABLE_HEADER), config_image.DISABLE_HEADER'length));
    config_image.BYPASS := std_logic_vector(resize(unsigned(config_in.BYPASS), config_image.BYPASS'length));
    config_image.W_BUFFER := std_logic_vector(resize(unsigned(config_in.W_BUFFER), config_image.W_BUFFER'length));
    config_image.ENCODER_SELECTION := std_logic_vector(resize(unsigned(config_in.ENCODER_SELECTION), config_image.ENCODER_SELECTION'length));
    return config_image;
  end function;

-----------------------------------------------------------------------------
--! Set image metadata configuration
-----------------------------------------------------------------------------
  function configure_predictor (config_in: in config_123_f) return config_123_predictor is
    variable config_predictor: config_123_predictor;
  begin
    config_predictor.P := std_logic_vector(resize(unsigned(config_in.P), config_predictor.P'length));
    config_predictor.PREDICTION := std_logic_vector(resize(unsigned(config_in.PREDICTION), config_predictor.PREDICTION'length));
    config_predictor.LOCAL_SUM := std_logic_vector(resize(unsigned(config_in.LOCAL_SUM), config_predictor.LOCAL_SUM'length));
    config_predictor.OMEGA := std_logic_vector(resize(unsigned(config_in.OMEGA), config_predictor.OMEGA'length));
    config_predictor.R := std_logic_vector(resize(unsigned(config_in.R), config_predictor.R'length));
    config_predictor.VMAX :=  std_logic_vector(resize(signed(config_in.VMAX), config_predictor.VMAX'length));
    config_predictor.VMIN := std_logic_vector(resize(signed(config_in.VMIN), config_predictor.VMIN'length));
    config_predictor.TINC := std_logic_vector(resize(unsigned(config_in.TINC), config_predictor.TINC'length));
    config_predictor.Q := std_logic_vector(resize(unsigned(config_in.Q), config_predictor.Q'length));
    -- Modified by AS: assignment of new configuration parameter WR -- 
    config_predictor.WR := std_logic_vector(resize(unsigned(config_in.WR), config_predictor.WR'length));
    -----------------------------
    config_predictor.WEIGHT_INIT := std_logic_vector(resize(unsigned(config_in.WEIGHT_INIT), config_predictor.WEIGHT_INIT'length));
    config_predictor.ExtMemAddress := config_in.ExtMemAddress;
    return config_predictor;
  end function;

-----------------------------------------------------------------------------
--! Set predictor configuration
----------------------------------------------------------------------------- 
  function configure_predictor (config_in: in config_123_f) return config_123_predictor_f is
    variable config_predictor: config_123_predictor_f;
  begin
    config_predictor.P := std_logic_vector(resize(unsigned(config_in.P), config_predictor.P'length));
    config_predictor.PREDICTION := std_logic_vector(resize(unsigned(config_in.PREDICTION), config_predictor.PREDICTION'length));
    config_predictor.LOCAL_SUM := std_logic_vector(resize(unsigned(config_in.LOCAL_SUM), config_predictor.LOCAL_SUM'length));
    config_predictor.OMEGA := std_logic_vector(resize(unsigned(config_in.OMEGA), config_predictor.OMEGA'length));
    config_predictor.R := std_logic_vector(resize(unsigned(config_in.R), config_predictor.R'length));
    config_predictor.VMAX :=  std_logic_vector(resize(signed(config_in.VMAX), config_predictor.VMAX'length));
    config_predictor.VMIN := std_logic_vector(resize(signed(config_in.VMIN), config_predictor.VMIN'length));
    config_predictor.TINC := std_logic_vector(resize(unsigned(config_in.TINC), config_predictor.TINC'length));
    config_predictor.Q := std_logic_vector(resize(unsigned(config_in.Q), config_predictor.Q'length));
    -- Modified by AS: assignment of new configuration parameter WR -- 
    config_predictor.WR := std_logic_vector(resize(unsigned(config_in.WR), config_predictor.WR'length));
    --------------------------------
    config_predictor.WEIGHT_INIT := std_logic_vector(resize(unsigned(config_in.WEIGHT_INIT), config_predictor.WEIGHT_INIT'length));
    config_predictor.ExtMemAddress := config_in.ExtMemAddress;
    return config_predictor;
  end function;

-----------------------------------------------------------------------------
--! Set predictor configuration
----------------------------------------------------------------------------- 
  function configure_predictor return config_123_predictor is
    variable config_predictor: config_123_predictor;
  begin
    config_predictor.P := std_logic_vector(to_unsigned(P_MAX, config_predictor.P'length));
    config_predictor.PREDICTION := std_logic_vector(to_unsigned(PREDICTION_GEN, config_predictor.PREDICTION'length));
    config_predictor.LOCAL_SUM := std_logic_vector(to_unsigned(LOCAL_SUM_GEN, config_predictor.LOCAL_SUM'length));
    config_predictor.OMEGA := std_logic_vector(to_unsigned(OMEGA_GEN, config_predictor.OMEGA'length));
    config_predictor.R := std_logic_vector(to_unsigned(R_GEN, config_predictor.R'length));
    config_predictor.VMAX := std_logic_vector(to_signed(VMAX_GEN, config_predictor.VMAX'length));
    config_predictor.VMIN := std_logic_vector(to_signed(VMIN_GEN, config_predictor.VMIN'length));
    config_predictor.TINC := std_logic_vector(to_unsigned(T_INC_GEN, config_predictor.TINC'length));
    config_predictor.Q := std_logic_vector(to_unsigned(Q_GEN, config_predictor.Q'length));
    -- Modified by AS: assignment of new configuration parameter WR (with compile-time configuration, WR is always set to 1) -- 
    config_predictor.WR := std_logic_vector(to_unsigned(1, config_predictor.WR'length));
    -------------------------------
    config_predictor.WEIGHT_INIT := std_logic_vector(to_unsigned(WEIGHT_INIT_GEN, config_predictor.WEIGHT_INIT'length));
    config_predictor.ExtMemAddress := std_logic_vector(to_unsigned(ExtMemAddress_GEN, 12)) & std_logic_vector(to_unsigned(0, 20));
    return config_predictor;
  end function;
  
-----------------------------------------------------------------------------
--! Set predictor configuration
----------------------------------------------------------------------------- 
  function configure_predictor return config_123_predictor_f is
    variable config_predictor: config_123_predictor_f;
  begin
    config_predictor.P := std_logic_vector(to_unsigned(P_MAX, config_predictor.P'length));
    config_predictor.PREDICTION := std_logic_vector(to_unsigned(PREDICTION_GEN, config_predictor.PREDICTION'length));
    config_predictor.LOCAL_SUM := std_logic_vector(to_unsigned(LOCAL_SUM_GEN, config_predictor.LOCAL_SUM'length));
    config_predictor.OMEGA := std_logic_vector(to_unsigned(OMEGA_GEN, config_predictor.OMEGA'length));
    config_predictor.R := std_logic_vector(to_unsigned(R_GEN, config_predictor.R'length));
    config_predictor.VMAX := std_logic_vector(to_signed(VMAX_GEN, config_predictor.VMAX'length));
    config_predictor.VMIN := std_logic_vector(to_signed(VMIN_GEN, config_predictor.VMIN'length));
    config_predictor.TINC := std_logic_vector(to_unsigned(T_INC_GEN, config_predictor.TINC'length));
    config_predictor.Q := std_logic_vector(to_unsigned(Q_GEN, config_predictor.Q'length));
    -- Modified by AS: assignment of new configuration parameter WR (with compile-time configuration, WR is always set to 1) -- 
    config_predictor.WR := std_logic_vector(to_unsigned(1, config_predictor.WR'length));
    ------------------------------------------
    config_predictor.WEIGHT_INIT := std_logic_vector(to_unsigned(WEIGHT_INIT_GEN, config_predictor.WEIGHT_INIT'length));
    config_predictor.ExtMemAddress := std_logic_vector(to_unsigned(ExtMemAddress_GEN, 12)) & std_logic_vector(to_unsigned(0, 20));
    return config_predictor;
  end function;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
-----------------------------------------------------------------------------
  function configure_sample return config_123_sample is
    variable config_sample: config_123_sample;
  begin
    config_sample.INIT_COUNT_E := std_logic_vector(to_unsigned(INIT_COUNT_E_GEN, config_sample.INIT_COUNT_E'length));
    config_sample.ACC_INIT_TYPE := std_logic_vector(to_unsigned(ACC_INIT_TYPE_GEN, config_sample.ACC_INIT_TYPE'length));
    config_sample.ACC_INIT_CONST := std_logic_vector(to_unsigned(ACC_INIT_CONST_GEN, config_sample.ACC_INIT_CONST'length));
    config_sample.RESC_COUNT_SIZE := std_logic_vector(to_unsigned(RESC_COUNT_SIZE_GEN, config_sample.RESC_COUNT_SIZE'length));
    config_sample.U_MAX := std_logic_vector(to_unsigned(U_MAX_GEN, config_sample.U_MAX'length));
    return config_sample;
  end function;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
----------------------------------------------------------------------------- 
  function configure_sample return config_123_sample_f is
    variable config_sample: config_123_sample_f;
  begin
    config_sample.INIT_COUNT_E := std_logic_vector(to_unsigned(INIT_COUNT_E_GEN, config_sample.INIT_COUNT_E'length));
    config_sample.ACC_INIT_TYPE := std_logic_vector(to_unsigned(ACC_INIT_TYPE_GEN, config_sample.ACC_INIT_TYPE'length));
    config_sample.ACC_INIT_CONST := std_logic_vector(to_unsigned(ACC_INIT_CONST_GEN, config_sample.ACC_INIT_CONST'length));
    config_sample.RESC_COUNT_SIZE := std_logic_vector(to_unsigned(RESC_COUNT_SIZE_GEN, config_sample.RESC_COUNT_SIZE'length));
    config_sample.U_MAX := std_logic_vector(to_unsigned(U_MAX_GEN, config_sample.U_MAX'length));
    return config_sample;
  end function;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
----------------------------------------------------------------------------- 
  function configure_sample (config_in: in config_123_f) return config_123_sample is
    variable config_sample: config_123_sample;
  begin
    config_sample.INIT_COUNT_E := std_logic_vector(resize(unsigned(config_in.INIT_COUNT_E), config_sample.INIT_COUNT_E'length));
    config_sample.ACC_INIT_TYPE := std_logic_vector(resize(unsigned(config_in.ACC_INIT_TYPE), config_sample.ACC_INIT_TYPE'length));
    config_sample.ACC_INIT_CONST := std_logic_vector(resize(unsigned(config_in.ACC_INIT_CONST), config_sample.ACC_INIT_CONST'length));
    config_sample.RESC_COUNT_SIZE := std_logic_vector(resize(unsigned(config_in.RESC_COUNT_SIZE), config_sample.RESC_COUNT_SIZE'length));
    config_sample.U_MAX := std_logic_vector(resize(unsigned(config_in.U_MAX), config_sample.U_MAX'length));
    return config_sample;
  end function;

-----------------------------------------------------------------------------
--! Set sample-adaptive configuration
----------------------------------------------------------------------------- 
  function configure_sample(config_in: in config_123_f) return config_123_sample_f is
    variable config_sample: config_123_sample_f;
  begin
    config_sample.INIT_COUNT_E := std_logic_vector(resize(unsigned(config_in.INIT_COUNT_E), config_sample.INIT_COUNT_E'length));
    config_sample.ACC_INIT_TYPE := std_logic_vector(resize(unsigned(config_in.ACC_INIT_TYPE), config_sample.ACC_INIT_TYPE'length));
    config_sample.ACC_INIT_CONST := std_logic_vector(resize(unsigned(config_in.ACC_INIT_CONST), config_sample.ACC_INIT_CONST'length));
    config_sample.RESC_COUNT_SIZE := std_logic_vector(resize(unsigned(config_in.RESC_COUNT_SIZE), config_sample.RESC_COUNT_SIZE'length));
    config_sample.U_MAX := std_logic_vector(resize(unsigned(config_in.U_MAX), config_sample.U_MAX'length));
    return config_sample;
  end function;
  
-----------------------------------------------------------------------------
--! Set all values in configuration record to zero
-----------------------------------------------------------------------------

  procedure zero_config (signal config:  inout config_123_f) is
  begin
    config.ENABLE <= (others => '0');
    config.WEIGHT_TAB <= (others => (others => '0'));
    config.Nx <=(others => '0');
    config.Nz <= (others => '0');
    config.Ny <= (others => '0');
    config.IS_SIGNED <= (others => '0');
    config.ENDIANESS <= (others => '0');
    config.D <= (others => '0');
    config.DISABLE_HEADER <= (others => '0');
    config.ENCODER_SELECTION <= (others => '0');
    config.W_BUFFER <= (others => '0');
    config.BYPASS <= (others => '0');
    config.P <= (others => '0');
    config.PREDICTION <= (others => '0');
    config.LOCAL_SUM <= (others => '0');
    config.OMEGA <= (others => '0');
    config.R <= (others => '0');
    config.VMAX <= (others => '0');
    config.VMIN <= (others => '0');
    config.TINC <= (others => '0');
    config.WEIGHT_INIT <= (others => '0');
    config.INIT_COUNT_E <= (others => '0');
    config.ACC_INIT_TYPE <= (others => '0');
    config.ACC_INIT_CONST <= (others => '0');
    config.RESC_COUNT_SIZE <= (others => '0');
    config.U_MAX <= (others => '0');
    config.Q <= (others => '0');
    -- Modified by AS: default value of new WR configuration parameter --
    config.WR <= (others => '0');
    -----------------------------
    config.ExtMemAddress <= (others => '0');
    config.WEIGHT_TAB <= (others => (others =>'0'));
  end procedure zero_config;

-----------------------------------------------------------------------------
--! Set all values in configuration record to zero
-----------------------------------------------------------------------------

  procedure zero_config_var (variable config:  inout config_123_f) is 
  begin
    config.ENABLE := (others => '0');
    config.WEIGHT_TAB := (others => (others => '0'));
    config.Nx :=(others => '0');
    config.Nz := (others => '0');
    config.Ny := (others => '0');
    config.IS_SIGNED := (others => '0');
    config.ENDIANESS := (others => '0');
    config.D := (others => '0');
    config.DISABLE_HEADER := (others => '0');
    config.ENCODER_SELECTION := (others => '0');
    config.W_BUFFER := (others => '0');
    config.BYPASS := (others => '0');
    config.P := (others => '0');
    config.PREDICTION := (others => '0');
    config.LOCAL_SUM := (others => '0');
    config.OMEGA := (others => '0');
    config.R := (others => '0');
    config.VMAX := (others => '0');
    config.VMIN := (others => '0');
    config.TINC := (others => '0');
    config.WEIGHT_INIT := (others => '0');
    config.INIT_COUNT_E := (others => '0');
    config.ACC_INIT_TYPE := (others => '0');
    config.ACC_INIT_CONST := (others => '0');
    config.RESC_COUNT_SIZE := (others => '0');
    config.U_MAX := (others => '0');
    config.Q := (others => '0');
    config.ExtMemAddress := (others => '0');
    config.WEIGHT_TAB := (others => (others =>'0'));
  end procedure zero_config_var;

-----------------------------------------------------------------------------
--! Set all values in control record to zero
-----------------------------------------------------------------------------
  
  procedure zero_config (signal ctrl:  inout ctrls) is
  begin
    ctrl.AwaitingConfig <= '0';
    ctrl.Ready <= '0';
    ctrl.FIFO_Full <= '0';
    ctrl.EOP <= '0';
    ctrl.Finished <= '0';
    ctrl.Error <= '0';
    ctrl.ErrorCode <= (others => '0');
  end zero_config;

-----------------------------------------------------------------------------
--! Assign values to configuration record from memory-mapped registers
-----------------------------------------------------------------------------
  procedure rx_read_config_123 (config: inout config_123_f; datain: in std_logic_vector; address: in std_logic_vector; values_read: inout std_logic_vector; error: inout std_logic)  is
    constant off0: integer := 16#0#;
    constant off4: integer := 16#1#;
    constant off8: integer := 16#2#;
    constant offC: integer := 16#3#;
    constant off10: integer := 16#4#;
    constant off14: integer := 16#5#;
    constant off18: integer := 16#6#;
    constant off1C: integer := 16#7#;
    constant off20: integer := 16#8#;
    constant off24: integer := 16#9#;
    constant off28: integer := 16#A#;
    constant off2C: integer := 16#B#;
    constant off30: integer := 16#C#;
    constant off34: integer := 16#D#;
    constant off38: integer := 16#E#;
    constant off3C: integer := 16#F#;
    constant off40: integer := 16#10#;
    constant off44: integer := 16#11#;
    constant off48: integer := 16#12#;
    constant off4C: integer := 16#13#;
    constant off50: integer := 16#14#;
    constant off54: integer := 16#15#;
    constant off58: integer := 16#16#;
    constant off5C: integer := 16#17#;
    constant off60: integer := 16#18#;
    
    variable vaddress: integer;
    variable weight_index: integer;
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
        config.ExtMemAddress := datain(config.ExtMemAddress'high downto 0);
        values_read(1) := '1';
      when off8 =>
        config.Nx := datain(16+config.Nx'high downto 16);
        config.D := datain(11+config.D'high downto 11);
        config.IS_SIGNED := datain(10 downto 10);
        config.DISABLE_HEADER := datain(9 downto 9);
        config.ENCODER_SELECTION := datain(7+config.ENCODER_SELECTION'high downto 7);
        config.P := datain(3+config.P'high downto 3);
        config.BYPASS := datain(2 downto 2);
        --Bits (1:0) reserved
        values_read(2) := '1';
      when offC =>
        config.Ny := datain(16+config.Ny'high downto 16);
        config.PREDICTION := datain(15 downto 15);
        config.LOCAL_SUM := datain(14 downto 14);
        config.OMEGA := datain(9+config.OMEGA'high downto 9);
        config.R := datain(2+config.R'high downto 2);
        --Bits (1:0) reserved
        values_read(3) := '1';
      when off10 =>
        config.Nz := datain(16+config.Nz'high downto 16);
        --config.VMAX := datain(12+config.VMAX'high downto 12);
        config.VMAX := datain(11+config.VMAX'high downto 11);
        --config.VMIN := datain(8+config.VMIN'high downto 8);
        config.VMIN := datain(6+config.VMIN'high downto 6);
        --config.TINC := datain(4+config.TINC'high downto 4);
        config.TINC := datain(2+config.TINC'high downto 2);
        --config.WEIGHT_INIT := datain(3 downto 3);
        config.WEIGHT_INIT := datain(1 downto 1);
        --config.ENDIANESS := datain(2 downto 2);
        config.ENDIANESS := datain(0 downto 0);       
        --Bits (1:0) reserved
        values_read(4) := '1';
        --check if we need to wait for weight init table (functionality not included, 
        -- lines left comented)
        --if config.WEIGHT_INIT = "0" then --no weight table
          --values_read(24 downto 6) :=  (others => '1');
        --else
        --  weight_index := 6 + to_integer(unsigned(not(config.PREDICTION)))*3 + to_integer(unsigned(config.P)) - 1;
        --  for i in 24 downto 6 loop
        --    if i > weight_index then
        --      values_read(i) := '0';
        --    else
        --      values_read(i) := '1';
        --    end if;
        --  end loop;
        --end if;
      when off14 =>
        config.INIT_COUNT_E := datain(28+config.INIT_COUNT_E'high downto 28);
        config.ACC_INIT_TYPE := datain(27 downto 27);
        config.ACC_INIT_CONST := datain(23+config.ACC_INIT_CONST'high downto 23);
        config.RESC_COUNT_SIZE := datain(19+config.RESC_COUNT_SIZE'high downto 19);
        config.U_MAX := datain(13+config.U_MAX'high downto 13);
        config.W_BUFFER := datain(6+config.W_BUFFER'high downto 6);
        -- Modified by AS: read new configuration parameters from AHB configuration registers --
        config.Q := datain(1+config.Q'high downto 1);
        config.WR := datain(0 downto 0);
        ---------------------------------
        --Bits (12:0) reserved
        values_read(5) := '1';
      when others =>
        values_read(values_read'high downto 0) := (others => '0');
        --config := (others => others => '0');
    end case;
  end procedure rx_read_config_123; 
end package body config123_package;
