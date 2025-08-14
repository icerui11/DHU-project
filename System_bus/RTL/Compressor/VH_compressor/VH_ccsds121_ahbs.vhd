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
-- Design unit  : AHB Slave for configuration.
--
-- File name    : ccsds121_ahbs.vhd
--
-- Purpose      : AHB Slave interface to read the configuration values. 
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Instantiates : aram2(reg_bank)
--============================================================================


--!@file #ccsds121_ahbs.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  AHB Slave interface to read the configuration values. 
--!@details This module will read the configuration values from the memory-mapped registers. 
--!Once the configuration is received and a '1' is read in the ENABLE field of the Control&Status register, 
--!the valid flag will be activated at the output. All the registers are clocked with the AHB clock. 
--!The module additionally checks if the necessary configuration values have been received before being enabled. 
--!Otherwise it raises the error signal. 
--!If a new configuration value is received after the module has been enabled, the configuration is ignored and the module replies with AHB error. 

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;


--! Use shyloc_utils library
library shyloc_utils;
--! Use shyloc_utils amba
use shyloc_utils.amba.all;

library VH_compressor;
--! Use specific shyloc121 parameters
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;
--! Use shyloc configuration package
use VH_compressor.config121_package.all;

--! Use shyloc_utils library
library shyloc_utils;
--! Use shyloc functions
use shyloc_utils.shyloc_functions.all;


--! ccsds121_ahbs entity  AHB Slave interface to read the configuration values. 
entity ccsds121_ahbs is
  generic (
    hindex    : integer := 0;       --!Slave index.
    haddr     : integer := 0;       --!Slave address.
    hmask     : integer := 16#fff#; --!Slave mask.
    kbytes    : integer := 1;       --!Kbytes used to store values (actually not needed).
    RESET_TYPE  : integer := 1        --!Reset type.
  );      
  port (
    -- System Interface
  clk   : in  std_ulogic;                --! AHB clock.
  rst     : in  std_ulogic;              --! AHB reset.
    
  -- Slave signals
  ahbsi   : in  ahb_slv_in_type;      --! AHB slave input signals.
  ahbso   : out ahb_slv_out_type;     --! AHB slave output signals.
  
  -- Control and Data Interface
  control_out_ahb : in ctrls;           --! Control values to check the status of the interface.
  clear     : in std_logic;             --! Clear signal for registers.
  config      : out config_121;         --! Configuration values that have been received.
  error     : out std_logic;            --! Indicates that there was an error during the reception of the configuration.
  valid     : out std_logic             --! Validates configuration once arrived for one clk.
  );
end;

--!@brief Architecture of the ccsds121_ahbs
architecture rtl of ccsds121_ahbs is

  constant abits : integer := log2_exact(kbytes) + 8;
  constant ws : std_logic_vector(7 downto 0) :="00000000";
  constant retry : integer := 0;
  
  signal hwrite_c : std_ulogic;
  signal hready_c : std_ulogic;
  signal hsel_c   : std_ulogic;
  signal addr_c   : std_logic_vector(abits+1 downto 0);
  signal size_c   : std_logic_vector(1 downto 0);
  signal hresp_c  : std_logic_vector(1 downto 0);
  signal ws_c     : std_logic_vector(7 downto 0);
  signal rty_c    : std_logic_vector(3 downto 0);
  signal retry_c  : std_logic;
  
  signal hwrite_r : std_ulogic;
  signal hready_r : std_ulogic;
  signal hsel_r   : std_ulogic;
  signal addr_r   : std_logic_vector(abits+1 downto 0);
  signal size_r   : std_logic_vector(1 downto 0);
  signal hresp_r  : std_logic_vector(1 downto 0);
  signal ws_r     : std_logic_vector(7 downto 0);
  signal rty_r    : std_logic_vector(3 downto 0);
  signal retry_r  : std_logic;

  --signal r, c : reg_type;
  signal ramsel : std_ulogic;
  signal write : std_logic_vector(3 downto 0);
  signal ramaddr  : std_logic_vector(abits-1 downto 0);
  signal ramaddr_local: std_logic_vector(abits-1 downto 0);
  signal ramdata  : std_logic_vector(31 downto 0);
  signal config_c, config_r: config_121;
  signal values_read_c, values_read_r: std_logic_vector (N_CONFIG_WORDS-1 downto 0);
  signal error_c, error_r: std_logic;
  signal valid_c, valid_r : std_logic;
  signal data_in_mem: std_logic_vector(31 downto 0);
  --signal r0, r0_reg: std_logic_vector(31 downto 0) := (others => '0');
  signal r0: std_logic_vector(31 downto 0) := (others => '0');
  constant reserved: std_logic_vector(21 downto 1):= (others => '0');
  signal r0_conf: std_logic_vector(31 downto 22);
  --signal write_aux: std_logic;
  --signal control_reg: ctrls;
  signal write_flag: std_logic;
  --signal ini: std_logic;
  --signal enable_aux: std_logic;
  constant ramaddr_zero: std_logic_vector(ramaddr'length -1 downto 0) := (others => '0');
begin

  comb : process (ahbsi, hwrite_r, hready_r, hsel_r, addr_r, size_r, hresp_r, ws_r, rty_r, retry_r, rst, ramdata, valid_r, clear)
    variable bs : std_logic_vector(3 downto 0);
    --variable v : reg_type;
    variable haddr  : std_logic_vector(abits-1 downto 0);
    variable ip_error_v: std_logic := '0';
    variable hwrite_v : std_ulogic;
    variable hready_v : std_ulogic;
    variable hsel_v   : std_ulogic;
    variable addr_v   : std_logic_vector(abits+1 downto 0);
    variable size_v   : std_logic_vector(1 downto 0);
    variable hresp_v  : std_logic_vector(1 downto 0);
    variable ws_v     : std_logic_vector(7 downto 0);
    variable rty_v    : std_logic_vector(3 downto 0);
    variable retry_v  : std_logic;
  begin
  --default values
    --v := r; 
    hwrite_v := hwrite_r;
    hready_v := hready_r;
    hsel_v   :=  hsel_r;
    addr_v   :=  addr_r;
    size_v   :=  size_r;
    hresp_v  := hresp_r;
    ws_v     :=  ws_r;
    rty_v    :=  rty_r;
    retry_v  := retry_r;
    
    hready_v := '1'; 
    bs := (others => '0');
    hresp_v := HRESP_OKAY;
    ip_error_v := '0';
  
    if ahbsi.hready = '1' then 
    -- i'm i being selected
      hsel_v := ahbsi.hsel and ahbsi.htrans(1);
    -- it's a write opration
      hwrite_v := ahbsi.hwrite and hsel_v;
    -- the address
      addr_v := ahbsi.haddr(abits+1 downto 0); 
    -- the size of the transfer
      size_v := ahbsi.hsize(1 downto 0);
      ws_v := ws;
     
    -- I already received the configuration
    if hsel_v = '1' and hwrite_v = '1' then
      if valid_r = '1' then
        ip_error_v := '1';
      end if;
    end if;
    
      if retry = 1 then
        if hsel_v = '1' then
          rty_v := std_logic_vector(unsigned(rty_r) - 1);
          if rty_r = "0000" then
            retry_v := '0';
            rty_v := "0010";
          else
            retry_v := '1';
          end if;
        end if;
      else
          retry_v := '0';
      end if;
    end if;
    
    if ws_r /= "00000000" and hsel_r = '1' then
      ws_v := std_logic_vector(unsigned(ws_r) - 1);
    end if;

    if ws_v /= "00000000" and hsel_v = '1' then
      hready_v := '0';
    elsif hsel_v = '1' and retry_v = '1' then
      if hresp_r = HRESP_OKAY then
        hready_v := '0';
    hresp_v := HRESP_RETRY;
      else
        hready_v := '1';
        hresp_v := HRESP_RETRY;
        retry_v := '0';
      end if;
    elsif hsel_v = '1' and ip_error_v = '1' then
    hready_v := '0';
        hresp_v := HRESP_ERROR;
   elsif hresp_r = HRESP_ERROR then
     hready_v := '1';
         hresp_v := HRESP_ERROR;
  end if;
    if (hwrite_r or not hready_r) = '1' then 
      haddr := addr_r(abits+1 downto 2);
    else
      haddr := ahbsi.haddr(abits+1 downto 2); 
      bs := (others => '0'); 
    end if;


    if hwrite_r = '1' and hready_r = '1' then
      case size_r(1 downto 0) is
        when "00" => bs (to_integer(unsigned(addr_r(1 downto 0)))) := '1';
        when "01" => bs := addr_r(1) & addr_r(1) & not (addr_r(1) & addr_r(1));
        when others => bs := (others => '1');
      end case;
    end if;

   if clear = '1' or rst = '0' then 
      hwrite_v := '0'; 
      hready_v := '1'; 
      ws_v := ws; 
      rty_v := "0010"; 
      hresp_v := HRESP_OKAY;
    end if;
  
    write <= bs; 
    ramsel <= hsel_v or hwrite_r; 
    ahbso.hready <= hready_r; 
    ramaddr <= haddr; 
  
    hwrite_c <= hwrite_v;
    hready_c <= hready_v;
    hsel_c   <= hsel_v;  
    addr_c   <= addr_v;  
    size_c   <= size_v;  
    hresp_c  <= hresp_v; 
    ws_c     <= ws_v;    
    rty_c    <= rty_v;   
    retry_c  <= retry_v; 
  
    ahbso.hrdata <= ramdata;
  end process;
  
  comb121: process(hready_r, hwrite_r, ramaddr, ahbsi, config_r, values_read_r, clear, error_r, rst)
    variable config_v : config_121;
    variable values_read_v : std_logic_vector (N_CONFIG_WORDS-1 downto 0);
    variable error_v : std_logic;
    variable enable : std_logic;
  begin
    config_v := config_r;
    values_read_v := values_read_r;
    error_v := error_r;
    error_c <= error_r;
    if clear = '1' or rst = '0' then
      values_read_v := (others => '0');
      error_v := '0';
      config_v := (others => (others => '0'));
    elsif (hwrite_r = '1' and hready_r = '1') then
      if values_read_r = "1111" then
        -- pragma translate_off
          assert false report "Attempt to send new configuration during compression" severity note;
        -- pragma translate_on
      else
        ahb_read_config (config_v, ahbsi.hwdata, ramaddr, values_read_v, error_v);
        if values_read_v(0) = '1' and values_read_v(3 downto 0) /= "1111" then
          -- pragma translate_off
          assert false report "Attempt to enable compressor without sending the necessary configuration" severity warning;
          -- pragma translate_on
          values_read_v(0) := '0';
          error_v := '1';
        end if;
      end if;
  end if;
  
    enable := values_read_v(0);
    for i in 1 to N_CONFIG_WORDS-1 loop
      enable := enable and values_read_v(i);
    end loop;
  
    valid_c <= values_read_v(0) or error_v;
    error_c <= error_v;
    values_read_c <= values_read_v;
    config_c <= config_v;
  end process;

  --------------------
  -- output assingment
  --------------------
  ahbso.hresp   <= hresp_r;
  ahbso.hsplit  <= (others => '0'); 
  
  config <= config_r;
  valid <= valid_r;
  error <= error_r;

  aram2 :  entity shyloc_utils.reg_bank(arch)
  generic map (RESET_TYPE => RESET_TYPE, Cz => 4, W => 32, W_ADDRESS => 2, TECH => TECH)
  port map (clk => clk, rst_n => '1', clear => clear, data_in => data_in_mem, data_out => ramdata, read_addr => ramaddr(1 downto 0), write_addr => ramaddr_local(1 downto 0), we => write_flag, re => '1');
  
  -----------------------------------
  --! Control part of the r0 register
  -----------------------------------
  r0_conf <= control_out_ahb.AwaitingConfig & control_out_ahb.Ready & control_out_ahb.FIFO_Full & control_out_ahb.EOP & control_out_ahb.Finished & control_out_ahb.Error & control_out_ahb.ErrorCode;
  
  -----------------------------------
  --! Status and control register
  -----------------------------------
  r0 <= r0_conf & reserved & '0'; -- do not write the enable value
  
  -----------------------------------
  --! Input to write in memory: when data comes from AHB, write incoming data; when data comes from control signals, writen in addr0
  -----------------------------------
  data_in_mem <= ahbsi.hwdata when write(0) = '1' and ramaddr /= ramaddr_zero else r0;
  ramaddr_local <= ramaddr when write(0) = '1' else (others => '0');
  write_flag <= '1'; -- write enable
  
  ------------------------------------------
  --! Registers for some signals and records
  ------------------------------------------
  reg : process (clk, rst)
  begin
    if (rst = '0' and RESET_TYPE = 0) then
      hwrite_r <= '0'; 
      hready_r <= '1'; 
      ws_r <= ws; 
      rty_r <= "0010"; 
      hresp_r <= HRESP_OKAY;
      config_r <= (others => (others => '0'));
      values_read_r <= (others => '0');
      error_r <= '0';
      valid_r <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst = '0' and RESET_TYPE= 1)) then
        hwrite_r <= '0'; 
        hready_r <= '1'; 
        ws_r <= ws; 
        rty_r <= "0010"; 
        hresp_r <= HRESP_OKAY;
        values_read_r <= (others => '0');
        error_r <= '0';
        config_r <= (others => (others => '0'));
        valid_r <= '0';
      else
      --  r <= c;
        hwrite_r <= hwrite_c;
        hready_r <= hready_c;
        hsel_r   <= hsel_c;  
        addr_r   <= addr_c;  
        size_r   <= size_c;  
        hresp_r  <= hresp_c; 
        ws_r     <= ws_c;    
        rty_r    <= rty_c;   
        retry_r  <= retry_c; 
        config_r <= config_c; 
        values_read_r <= values_read_c;
        error_r <= error_c;
        valid_r <= valid_c;
      end if;
    end if;
  end process;

end;
