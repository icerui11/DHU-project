--============================================================================--
-- Design unit  : AHB master interface.
-- File name    : ahb_master.vhd

-- Purpose      : Master interface to communicate with AHB bus. 
-- Author       : Rui Yin
--                TUBS IDK RoSy
--============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
library shyloc_utils;
use shyloc_utils.amba.all;
library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;
--use shyloc_123.ccsds_ahb_debug_func.all;

--!@file #ahb_master.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@brief Master interface to communicate with AHB bus.
--No support for 128 bits. 

entity ahb_master is
  port (
    rst_n : in  std_logic; --! AHB reset (active low)
    clk   : in  std_logic; --! AHB clock
    
    ctrli : in  ahbtbm_ctrl_in_type;  --! AHB control signals (input)
    ctrlo : out ahbtbm_ctrl_out_type; --! AHB control signals (output)
  
    ahbmi : in  ahb_mst_in_type; --! AHB input record
    ahbmo : out ahb_mst_out_type --! AHB output record
    );
end;      

architecture rtl of ahb_master is
  
    signal hrdata_r   : std_logic_vector(31 downto 0);
    signal grant_r  : std_logic; 
    signal grant2_r : std_logic;
    signal retryac_r : ahbtbm_access_type;
    signal ac_r: ahbtbm_access_array_type;
    signal retry_r    : std_logic_vector(1 downto 0);
    signal curac_r     : ahbtbm_access_type;
    signal hdata_r     : std_logic_vector(31 downto 0);
    signal read_r      : std_logic; 
    signal write_r     : std_logic; 
    signal status_r    : ahbtbm_status_type;
    signal dvalid_r    : std_logic;
    
    signal hrdata_c    : std_logic_vector(31 downto 0); 
    signal grant_c  : std_logic; 
    signal grant2_c : std_logic;
    signal retryac_c : ahbtbm_access_type;
    signal ac_c : ahbtbm_access_array_type;
    signal retry_c    : std_logic_vector(1 downto 0);
    signal curac_c     : ahbtbm_access_type;
    signal hdata_c     : std_logic_vector(31 downto 0);
    signal read_c      : std_logic;
    signal write_c     : std_logic; 
    signal status_c    : ahbtbm_status_type;
    signal dvalid_c    : std_logic;
begin

  ctrlo.rst <= rst_n;
  ctrlo.clk <= clk;

  comb : process(ahbmi, ctrli, rst_n, hrdata_r , grant_r, grant2_r, retryac_r, ac_r,retry_r, curac_r, hdata_r, read_r, write_r, status_r, dvalid_r)

    variable hrdata_v    : std_logic_vector(31 downto 0);
    variable grant_v  : std_logic; 
    variable grant2_v : std_logic;
    variable oldhtrans_v : std_logic_vector(1 downto 0);
    variable retryac_v : ahbtbm_access_type;
    variable ac_v: ahbtbm_access_array_type;
    variable retry_v    : std_logic_vector(1 downto 0);
    variable curac_v     : ahbtbm_access_type;
    variable hdata_v     : std_logic_vector(31 downto 0);
    variable haddr_v     : std_logic_vector(31 downto 0);
    variable hwrite_v    : std_logic;    
    variable dbgl_v      : integer;
    variable hsize_v     : std_logic_vector(2 downto 0);
    variable read_v      : std_logic; -- indicate 
    variable write_v     : std_logic; 
    variable status_v    : ahbtbm_status_type;
    variable dvalid_v    : std_logic;

    variable update  : std_logic;
    variable hbusreq : std_logic;    -- bus request
    variable kblimit : std_logic;     -- 1 kB limit indicator

    variable ready   : std_logic;
    variable retry   : std_logic;
    variable mexc    : std_logic;
    variable inc     : std_logic_vector(3 downto 0);    -- address increment

    variable haddr   : std_logic_vector(31 downto 0);   -- AHB address
    variable hwdata  : std_logic_vector(31 downto 0);   -- AHB write data
    variable htrans  : std_logic_vector(1 downto 0);    -- transfer type
    variable hwrite  : std_logic;                       -- read/write
    variable hburst  : std_logic_vector(2 downto 0);    -- burst type
    variable newaddr : std_logic_vector(10 downto 0);   -- next sequential address
    variable hprot   : std_logic_vector(3 downto 0);    -- transfer type
  begin
    
    hrdata_v :=   hrdata_r;
    grant_v  :=   grant_r;
    grant2_v :=   grant2_r;
    retryac_v :=  retryac_r;
    ac_v     :=   ac_r;    
    retry_v  :=   retry_r; 
    curac_v  :=   curac_r; 
    hdata_v  :=   hdata_r;
    read_v   :=   read_r;  
    write_v  :=   write_r; 
    status_v :=   status_r;
    dvalid_v :=   dvalid_r;
    
    
    update := '0'; 
    hbusreq := '0';
    dvalid_v := '0'; 
    hprot := "1110";
    
    hrdata_v := ahbmi.hrdata(31 downto 0);
    status_v.err := '0';
    kblimit := '0';
    
    if ahbmi.hready = '1' then
      grant_v := ahbmi.hgrant;
      grant2_v := grant_r;
      oldhtrans_v := ac_r(1).htrans;
    end if;
    
    -- 1k limit
    if (ac_r(0).htrans = HTRANS_SEQ 
        and (ac_r(0).haddr(10) xor ac_r(1).haddr(10)) = '1')
       or (retryac_r.htrans = HTRANS_SEQ 
        and (retryac_r.haddr(10) xor ac_r(1).haddr(10)) = '1' and retry_r = "10") then
      kblimit := '1';        
    end if;

    if ahbmi.hready = '0' and (ahbmi.hresp = HRESP_RETRY or ahbmi.hresp = HRESP_SPLIT) and grant2_r = '1' then 
      if retry_r = "00" then
        retryac_v := ac_r(1);
        ac_v(1) := curac_r;
        ac_v(1).htrans := HTRANS_IDLE;
        ac_v(1).hburst := "000";
        retry_v := "01";
      elsif retry_r = "10" then
        ac_v(1) := retryac_r;
        if kblimit = '1' then ac_v(1).htrans := HTRANS_NONSEQ; end if;
      end if;
    
    elsif ahbmi.hready = '1' and ( grant_r = '1' or ac_r(1).htrans = HTRANS_IDLE) and retry_r = "00" then
      ac_v(1) := ac_r(0); 
      ac_v(0) := ctrli.ac;
      curac_v := ac_r(1);
      hdata_v := ac_r(1).hdata; 
      haddr_v := ac_r(1).haddr; 
      hwrite_v := ac_r(1).hwrite; 
      dbgl_v := ac_r(1).ctrl.dbgl;
      hsize_v := ac_r(1).hsize;

      read_v := (not ac_r(1).hwrite) and ac_r(1).htrans(1);
      write_v :=  ac_r(1).hwrite and ac_r(1).htrans(1);
      update := '1';
      
      if kblimit = '1' then 
        ac_v(1).htrans := HTRANS_NONSEQ; 
      end if;
    elsif ahbmi.hready = '0' and (ahbmi.hresp = HRESP_RETRY or ahbmi.hresp = HRESP_SPLIT) and grant2_r = '1' then 
      if retry_r = "00" then
        retryac_v := ac_r(1);
        ac_v(1) := curac_r;
        ac_v(1).htrans := HTRANS_IDLE;
        ac_v(1).hburst := "000";
        retry_v := "01";
      elsif retry_r = "10" then
        ac_v(1) := retryac_r;
        if kblimit = '1' then 
          ac_v(1).htrans := HTRANS_NONSEQ; 
        end if;
      end if;
    elsif retry_r = "01" then
      ac_v(1).htrans := HTRANS_NONSEQ;
      ac_v(1).hburst := curac_r.hburst;
      read_v := '0';
      write_v :=  '0';
      retry_v := "10";
    elsif ahbmi.hready = '1' and grant_r = '1' and retry_r = "10" then
      read_v := (not ac_r(1).hwrite) and ac_r(1).htrans(1);
      write_v :=  ac_r(1).hwrite and ac_r(1).htrans(1);
      ac_v(1) := retryac_r;
      if kblimit = '1' then 
        ac_v(1).htrans := HTRANS_NONSEQ; 
      end if;
        retry_v := "00";
    end if;
      
    -- NONSEQ if burst is interrupted
    if grant_r = '0' and ac_r(1).htrans = HTRANS_SEQ then
      ac_v(1).htrans := HTRANS_NONSEQ;
    end if;

    if ac_r(1).htrans = HTRANS_NONSEQ or (ac_r(1).htrans = HTRANS_SEQ 
          and ac_r(0).htrans /= HTRANS_NONSEQ and kblimit = '0') then
      hbusreq := '1';
    end if;
  
    if grant_r = '0' and ahbmi.hready = '1' then
      read_v := '0';
    end if;

    if read_r = '1' and ahbmi.hresp = HRESP_OKAY and ahbmi.hready = '1' then
      dvalid_v := '1';
    elsif read_r = '1' and ahbmi.hresp = HRESP_ERROR and ahbmi.hready = '1' then
      status_v.err := '1';
    end if;

    if write_r = '1' and ahbmi.hresp = HRESP_ERROR and ahbmi.hready = '1' then
      status_v.err := '1';
    end if;

    if rst_n = '0' then 
      ac_v(0).htrans := (others => '0');
      ac_v(1).htrans := (others => '0');
      retry_v := (others => '0');
      read_v := '0';
      
      ac_v(1).haddr := (others => '0');
      ac_v(1).htrans := (others => '0');
      ac_v(1).hwrite := '0';
      ac_v(1).hsize := (others => '0');
      ac_v(1).hburst := (others =>'0');
    end if;
    
    hrdata_c <=   hrdata_v;
    grant_c  <=   grant_v;
    grant2_c <=   grant2_v;
    retryac_c <=   retryac_v;
    ac_c     <=   ac_v;    
    retry_c  <=   retry_v; 
    curac_c  <=   curac_v; 
    hdata_c  <=   hdata_v;
    read_c   <=   read_v;  
    write_c  <=   write_v; 
    status_c <=   status_v;
    dvalid_c <=   dvalid_v;

    ctrlo.update <= update;
    ctrlo.status <= status_r;
    ctrlo.hrdata <= hrdata_r;
    ctrlo.dvalid <= dvalid_r;

    ahbmo.haddr   <= ac_r(1).haddr;
    ahbmo.htrans  <= ac_r(1).htrans;
    ahbmo.hbusreq <= hbusreq;
    ahbmo.hwdata  <= hdata_r; 
    ahbmo.hlock   <= '0';
    ahbmo.hwrite  <= ac_r(1).hwrite;
    ahbmo.hsize   <= ac_r(1).hsize;
    ahbmo.hburst  <= ac_r(1).hburst;
    ahbmo.hprot   <= ac_r(1).hprot;
  end process;

  reg : process (clk, rst_n)
  begin
    if (clk'event and clk = '1') then
      hrdata_r <=   hrdata_c;
      grant_r  <=   grant_c;
      grant2_r <=   grant2_c;
      retryac_r<=   retryac_c;
      ac_r     <=   ac_c;    
      retry_r  <=   retry_c; 
      curac_r  <=   curac_c; 
      hdata_r  <=   hdata_c;
      read_r   <=   read_c;  
      write_r  <=   write_c; 
      status_r <=   status_c;
      dvalid_r <=   dvalid_c;
      -- print_access (ahbmi, r, rin);
    end if; 
  end process;

end;
