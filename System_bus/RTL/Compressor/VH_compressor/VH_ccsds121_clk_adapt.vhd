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
-- Design unit  : ccsds121_clk_adapt 
--
-- File name    : ccsds121_clk_adapt.vhd
--
-- Purpose      : Performs a clock adaptation between two different clock domains
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Instantiates : syng_ctrli synchronizer(two_ff)), sync_valid (synchronizer(two_ff)), sync_clear (synchronizer(toggle)), sync_clear_ack (synchronizer(toggle)), sync_error (synchronizer(two_ff))
--
--============================================================================

--!@file #ccsds121_clk_adapt.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Performs a clock adaptation between two different clock domains

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

library VH_compressor;
use VH_compressor.ccsds121_constants_VH.all;

--! Use shyloc_utils library
library shyloc_utils;

--! ccsds121_clk_adapt entity  Clock adaption module
--! Performs a clock adaptation between two different clock domains
entity ccsds121_clk_adapt is
  port (
    -- System Interface
  clk_ahb     : in  std_ulogic;   --! AMBA Clock signal.
  clk_s     : in  std_ulogic;   --! System Clock signal.
  rst       : in  std_ulogic;   --! Reset signal.
    
  -- Data Interface
  valid_ahb   : in std_logic;     --! AMBA configuration validation.
    config_ahb    : in config_121;    --! AMBA configuration.
  control_out_s : in ctrls;       --! Output control signals.
  clear_s     : in std_logic;     --! Clear signal.
  error_ahb_in  : in std_logic;     --! AMBA error.
  clear_ahb_out : out std_logic;    --! Clear signal adapted to IP clock domain. (Flag to clear ahb and be able to send a new configuration).
  clear_ahb_ack_s : out std_logic;    --! To be sent to the output, handshake to be sure ahb was cleared.
  control_out_ahb : out ctrls;      --! Output control signals adapted to AMBA clock domain.
  config_s    : out config_121;   --! AMBA configuration adapted to IP clock domain.
  error_s_out   : out std_logic;    --! AMBA error adapted to IP clock domain.
  valid_s_out   : out std_logic     --! AMBA configuration validation adapted to IP clock domain (valid for one clk).
  );
end;

--! @brief Architecture of ccsds121_clk_adapt
architecture registers of ccsds121_clk_adapt is 

  
  type state_type is (idle, validate, invalidate);
  signal state_reg, state_cmb: state_type;
  
  
  signal valid_s, valid_c: std_logic;
  signal clear_ahb_c, clear_ahb_ack_c: std_logic;
  signal error_s, error_c: std_logic;
  signal clear_ahb_ack_c_s: std_logic;
  signal control_signals_s: std_logic_vector (9 downto 0);
  signal control_signals_ahb: std_logic_vector (9 downto 0);
  
  
begin

  ----------------------
  --! Output assingments
  ----------------------
  clear_ahb_out <= clear_ahb_c;
  clear_ahb_ack_s <= clear_ahb_ack_c_s;
  
  -----------------------------------
  --! Record to std_logic in S domain
  -----------------------------------
  control_signals_s(9) <= control_out_s.ErrorCode(3);
  control_signals_s(8) <= control_out_s.ErrorCode(2);
  control_signals_s(7) <= control_out_s.ErrorCode(1);
  control_signals_s(6) <= control_out_s.ErrorCode(0);
  
  control_signals_s(5) <= control_out_s.AwaitingConfig;
  control_signals_s(4) <= control_out_s.Ready;
  control_signals_s(3) <= control_out_s.FIFO_Full;
  control_signals_s(2) <= control_out_s.EOP;
  control_signals_s(1) <= control_out_s.Finished;
  control_signals_s(0) <= control_out_s.Error;
  
  -------------------------------------
  --! std_logic to record in AHB domain
  -------------------------------------
  control_out_ahb.ErrorCode(3) <= control_signals_ahb(9);
  control_out_ahb.ErrorCode(2) <= control_signals_ahb(8);
  control_out_ahb.ErrorCode(1) <= control_signals_ahb(7);
  control_out_ahb.ErrorCode(0) <= control_signals_ahb(6);
    
  control_out_ahb.AwaitingConfig <= control_signals_ahb(5);
  control_out_ahb.Ready          <= control_signals_ahb(4);
  control_out_ahb.FIFO_Full      <= control_signals_ahb(3);
  control_out_ahb.EOP            <= control_signals_ahb(2);
  control_out_ahb.Finished       <= control_signals_ahb(1);
  control_out_ahb.Error          <= control_signals_ahb(0);
  
    
  -------------------------------------------
  --!@brief  synchronizer for control signals
  -------------------------------------------
  gen_ctr_sync: for i in 0 to control_signals_s'high generate
  
    syng_ctrli: entity shyloc_utils.synchronizer(two_ff)
      port map(
        rst => rst, 
        clk_a => clk_s,
        clk_b => clk_ahb, 
        input_a => control_signals_s(i),
        output_b => control_signals_ahb(i)
      );
  end generate gen_ctr_sync;
    
  -----------------------
  --!@brief  synchronizer
  -----------------------
  sync_valid: entity shyloc_utils.synchronizer(two_ff)
    port map (
      rst => rst, 
      clk_a => clk_ahb,
      clk_b => clk_s, 
      input_a => valid_ahb,
      output_b => valid_s
    );
    
  -----------------------
  --!@brief  synchronizer
  -----------------------
  sync_clear: entity shyloc_utils.synchronizer(toggle)
    port map (
      rst => rst, 
      clk_a => clk_s,
      clk_b => clk_ahb, 
      input_a => clear_s,
      output_b => clear_ahb_c
    );
    
  -----------------------
  --!@brief  synchronizer
  -----------------------
  sync_clear_ack: entity shyloc_utils.synchronizer(toggle)
    port map (
      rst => rst, 
      clk_a => clk_ahb,
      clk_b => clk_s, 
      input_a => clear_ahb_ack_c,
      output_b => clear_ahb_ack_c_s
    );
    
  -----------------------
  --!@brief  synchronizer
  -----------------------
  sync_error: entity shyloc_utils.synchronizer(two_ff)
    port map (
      rst => rst, 
      clk_a => clk_ahb,
      clk_b => clk_s, 
      input_a => error_ahb_in,
      output_b => error_s
    );
  
  ------------------------------------------
  --! FSM generates valid signal for one clk
  ------------------------------------------
  process (state_reg, valid_s, error_s, clear_ahb_ack_c_s) is
  
  begin
    --default values
    valid_c <= '0';
    error_c <= '0';
    state_cmb <= state_reg;
    case state_reg is
      when idle =>
        if valid_s = '1' then
          valid_c <= '1';
          --if error_s = '1' then
          error_c <= error_s;
          --end if;
          state_cmb <= validate;
        else
          state_cmb <= idle;
        end if;
      when validate =>
        valid_c <= '0';
        error_c <= '0';
        --state_cmb <= invalidate;
        if clear_ahb_ack_c_s = '0' then
          state_cmb <= validate;
        else
          state_cmb <= idle;
        end if;
      when others =>
--pragma translate_off
        assert false report "Wrong state for state_reg fsm in ccsds121_clk_adapt module." severity warning;
--pragma translate_on
        state_cmb <= idle;
    end case;
  end process;
  
  
  --------------------------
  --! clear_ahb_ack_c update
  --------------------------
  process (clk_ahb, rst) is
  begin
    if rst = '0' then
      clear_ahb_ack_c <= '0';
    elsif clk_ahb'event and clk_ahb = '1' then
      clear_ahb_ack_c <= clear_ahb_c;
    end if;
  end process;
  
  ------------------
  --! Output updates
  ------------------
  process (clk_s, rst) is
  begin
    if rst = '0' then
      state_reg <= idle;
      valid_s_out <= '0';
      error_s_out <= '0';
      config_s <= (others => (others => '0'));
    elsif clk_s'event and clk_s = '1' then
      state_reg <= state_cmb;
      valid_s_out <= valid_c;
      error_s_out <= error_c;
      config_s <= config_ahb;
    end if;
  end process;

end registers;





