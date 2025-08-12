--------------------------------------------------------------------------------
-- Engineer: Rui Yin
-- Create Date: 2025-08-11
-- version : 2.0
-- Design Name: SHyLoC AHB System multiple Compressor
-- Module Name: shyloc_ahb_system_top
-- Project Name: SHyLoC Compression System - multiple Core Version
-- Modified shyloc_ahb_system_top with ahbctrl replacing manual decoder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library grlib;
use grlib.amba.all;
use grlib.devices.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;
use shyloc_123.ccsds123_parameters.all;

library shyloc_121;
use shyloc_121.ccsds121_parameters.all;

library config_controller;
use config_controller.config_pkg.all;

library VH_compressor;
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;

entity shyloc_ahb_system_top is
  generic (
    -- Number of compressor cores 
    NUM_COMPRESSORS : integer := 5;
    
    -- AHB address configuration for slave mapping
    -- Each slave gets 256MB space (0x10000000)
    COMPRESSOR_BASE_ADDR_HR_123 : integer := 16#200#;  -- 0x20000000
    COMPRESSOR_BASE_ADDR_HR_121 : integer := 16#100#;  -- 0x10000000
    COMPRESSOR_BASE_ADDR_LR_123 : integer := 16#400#;  -- 0x40000000
    COMPRESSOR_BASE_ADDR_LR_121 : integer := 16#500#;  -- 0x50000000
    COMPRESSOR_BASE_ADDR_H_121  : integer := 16#700#   -- 0x70000000
  );
  port (
    -- System signals / 系统信号
    clk_sys     : in std_logic;
    clk_ahb     : in std_logic;
    rst_n       : in std_logic;
    rst_n_lr    : in std_logic;
    rst_n_hr    : in std_logic;
    rst_n_h     : in std_logic;
    
    -- Configuration RAM interface 
    ram_wr_en   : in std_logic;
    ram_wr_addr : in std_logic_vector(c_input_addr_width-1 downto 0);
    ram_wr_data : in std_logic_vector(7 downto 0);
    
    -- Data interfaces for compressors 
    data_in_HR      : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_HR: in  std_logic;
    data_out_HR     : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_HR: out std_logic;
    
    data_in_LR      : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_LR: in  std_logic;
    data_out_LR     : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_LR: out std_logic;
    
    data_in_H       : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_H : in  std_logic;
    data_out_H      : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_H: out std_logic;
    
    -- Control signals 
    force_stop      : in  std_logic;
    force_stop_lr   : in  std_logic;
    force_stop_h    : in  std_logic;
    ready_ext       : in  std_logic;
    
    -- Status outputs
    system_ready    : out std_logic;
    config_done     : out std_logic;
    system_error    : out std_logic
  );
end entity shyloc_ahb_system_top;

architecture rtl of shyloc_ahb_system_top is

  -----------------------------------------------------------------------------
  -- Constants for ahbctrl 
  -----------------------------------------------------------------------------
  constant NAHBM : integer := 1;  -- Number of AHB masters 
  constant NAHBS : integer := 5;  -- Number of AHB slaves 
  -- ahb master default 
  constant AHB_MST_IN_DEFAULT : shyloc_utils.amba.AHB_Mst_In_Type := (
    hgrant  => '0',                  -- No grant
    hready  => '1',                  -- Always ready (no wait states)
    hresp   => "00",                 -- OKAY response
    hrdata  => (others => '0')       -- Zero data
  );
  
  -- AHB master and slave vectors for ahbctrl
  signal msti : grlib.amba.ahb_mst_in_type;
  signal msto : grlib.amba.ahb_mst_out_vector;
  signal slvi : grlib.amba.ahb_slv_in_type;
  signal slvo : grlib.amba.ahb_slv_out_vector;
  
  signal AHBmaster_in : shyloc_utils.amba.ahb_mst_in_type;
  signal AHBmaster_out : shyloc_utils.amba.ahb_mst_out_type;
  signal AHBslave_in : shyloc_utils.amba.ahb_slv_in_type;
  signal AHBslave_out : shyloc_utils.amba.ahb_slv_out_type;

  -- compressor ahb signals
  -- compressor VU HR
  signal HR_AHBSlave123_In:  shyloc_utils.amba.ahb_slv_in_type;
  signal HR_AHBSlave123_Out: shyloc_utils.amba.ahb_slv_out_type;

  signal HR_AHBSlave121_In:  shyloc_utils.amba.ahb_slv_in_type;
  signal HR_AHBSlave121_Out: shyloc_utils.amba.ahb_slv_out_type;

  -- compressor VU LR
  signal LR_AHBSlave123_In:  shyloc_utils.amba.ahb_slv_in_type;
  signal LR_AHBSlave123_Out: shyloc_utils.amba.ahb_slv_out_type;

  signal LR_AHBSlave121_In: shyloc_utils.amba.ahb_slv_in_type;
  signal LR_AHBSlave121_Out: shyloc_utils.amba.ahb_slv_out_type;

  -- compressor VH
  signal VH_AHBSlave121_In:  shyloc_utils.amba.ahb_slv_in_type;
  signal VH_AHBSlave121_Out: shyloc_utils.amba.ahb_slv_out_type;
  -- Control signals between master controller and AHB master
  signal ctrli : ahbtbm_ctrl_in_type;
  signal ctrlo : ahbtbm_ctrl_out_type;
  
  -- Compressor status signals 
  signal compressor_status_HR : compressor_status;
  signal compressor_status_LR : compressor_status;
  signal compressor_status_H  : compressor_status;
  
  -- Individual compressor signals 
  signal awaiting_config : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal ready          : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal finished       : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal error          : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  
  -- Reset signal conversion
  signal rst : std_ulogic;

begin

  -- Reset signal conversion
  rst <= not rst_n;

  -----------------------------------------------------------------------------
  -- AHB Controller (Arbiter/Decoder/Mux) instantiation
  -- AHB控制器（仲裁器/解码器/多路复用器）实例化
  -----------------------------------------------------------------------------
  ahbctrl_inst : entity grlib.ahbctrl
    generic map (
      defmast  => 0,      -- Default master
      split    => 0,      -- No split support
      rrobin   => 0,      -- Fixed priority arbitration
      timeout  => 0,      -- No timeout
      ioaddr   => 16#FFF#,-- I/O area disabled
      iomask   => 16#FFF#,
      cfgaddr  => 16#FF0#,-- Config area 
      cfgmask  => 16#FF0#,
      nahbm    => NAHBM,  -- 1 master
      nahbs    => NAHBS,  -- 5 slaves
      ioen     => 0,      -- Disable I/O area
      disirq   => 1,      -- Disable interrupt routing
      fixbrst  => 0,      -- No fixed burst support
      debug    => 2,      -- Enable debug output
      fpnpen   => 0,      -- Disable full PnP decoding
      icheck   => 0,
      devid    => 0,
      enbusmon => 0,      -- Disable bus monitor
      assertwarn => 0,
      asserterr  => 0,
      hmstdisable => 0,
      hslvdisable => 0,
      arbdisable => 0,
      mprio    => 0,
      mcheck   => 0,
      ccheck   => 0,
      acdm     => 0,
      index    => 0,
      ahbtrace => 0,
      hwdebug  => 0,
      fourgslv => 0,
      shadow   => 0,
      unmapslv => 0
    )
    port map (
      rst     => rst,
      clk     => clk_ahb,
      msti    => msti,      -- for controller single ahb master in type  output port
      msto    => msto,              -- for controller ahb master out vectortype input port
      slvi    => slvi,             -- for controller single ahb slave in type  output port
      slvo    => slvo,
      testen  => '0',
      testrst => '1',
      scanen  => '0',
      testoen => '1'
    );

  -----------------------------------------------------------------------------
  -- AHB Master Controller instantiation / AHB主控制器实例化
  -----------------------------------------------------------------------------
  ahb_master_ctrl_inst : entity config_controller.ahb_master_controller_v2
    generic map (
      hindex => 0,
      haddr_mask => 16#FFF#,
      hmaxburst => 16,
      g_input_data_width  => c_input_data_width,
      g_input_addr_width  => c_input_addr_width,
      g_input_depth       => c_input_depth,
      g_output_data_width => c_output_data_width,
      g_output_addr_width => c_output_addr_width,
      g_output_depth      => c_output_depth
    )
    port map (
      clk         => clk_ahb,
      rst_n       => rst_n,
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_LR,
      compressor_status_H  => compressor_status_H,
      ram_wr_en   => ram_wr_en,
      wr_addr     => ram_wr_addr,
      wr_data     => ram_wr_data,
      ctrli       => ctrli,
      ctrlo       => ctrlo
    );

  -----------------------------------------------------------------------------
  -- AHB Master interface instantiation / AHB主接口实例化
  -----------------------------------------------------------------------------
  ahb_mst_inst : entity shyloc_123.ccsds123_ahb_mst
    port map (
      rst_n => rst_n,
      clk   => clk_ahb,
      ctrli => ctrli,
      ctrlo => ctrlo,
      ahbmi => AHBmaster_in,
      ahbmo => AHBmaster_out  -- Connect to first master slot
    );

  -- Initialize unused master outputs comment because we only use one master
 -- ahbmo_init: for i in 1 to NAHBMST-1 generate
  --  ahbmo(i) <= ahbm_none;
 -- end generate;
  AHBmaster_in.HGRANT <= msti.hgrant(0);
  AHBmaster_in.HREADY <= msti.hready;
  AHBmaster_in.HRESP  <= msti.hresp;
  AHBmaster_in.HRDATA <= msti.hrdata;

  msto(0).HBUSREQ <= AHBmaster_out.hbusreq;
  msto(0).HLOCK   <= AHBmaster_out.hlock;
  msto(0).HTRANS  <= AHBmaster_out.htrans;
  msto(0).HADDR   <= AHBmaster_out.haddr;
  msto(0).HWRITE  <= AHBmaster_out.hwrite;
  msto(0).HSIZE   <= AHBmaster_out.hsize;
  msto(0).HBURST  <= AHBmaster_out.hburst;
  msto(0).HPROT   <= AHBmaster_out.hprot;
  msto(0).HWDATA  <= AHBmaster_out.hwdata;
  msto(0).HIRQ    <= (others => '0');  -- No IRQ support
  msto(0).HCONFIG <= (0 => ahb_device_reg ( VENDOR_GAISLER, 0, 0, 0, 0), others => zero32);
  msto(0).HINDEX  <= 0;


  -----------------------------------------------------------------------------
  -- Compressor Core Instantiations 
  -----------------------------------------------------------------------------
  
  -- HR Compressor (High Resolution) - Slave 0 (123) and Slave 1 (121)
  compressor_HR : entity work.SHyLoC_toplevel_v2
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_hr,
      AHBSlave121_In   => HR_AHBSlave121_In,      -- Connected to slave 1
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_hr,
      AHBSlave121_Out  => HR_AHBSlave121_Out,   -- Output for slave 1
      AHBSlave123_In   => HR_AHBSlave123_In,                -- Connected to slave 0
      AHBSlave123_Out  => HR_AHBSlave123_Out,   -- Output for slave 0
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,   -- Default master input not used
      AHBMaster123_Out => open,
      DataIn_shyloc    => data_in_HR,
      DataIn_NewValid  => data_in_valid_HR,
      DataOut          => data_out_HR,
      DataOut_NewValid => data_out_valid_HR,
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop,
      AwaitingConfig   => awaiting_config(0),
      Ready            => ready(0),
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished(0),
      Error            => error(0)
    );
  -- slave 0 CCSDS121  
  slvo(0).hready <=  HR_AHBSlave121_Out.HREADY; 
  slvo(0).hresp  <=  HR_AHBSlave121_Out.HRESP;
  slvo(0).hrdata <=  HR_AHBSlave121_Out.HRDATA;
  slvo(0).hsplit <=  HR_AHBSlave121_Out.HSPLIT;
  slvo(0).hconfig <= (0 => zero32,  4 => ahb_membar(16#100#, '1', '1', 16#FFF#),  others => zero32);
  slvo(0).hindex <= 0;
  -- slave 1 CCSDS123  
  slvo(1).hready <=  HR_AHBSlave123_Out.HREADY; 
  slvo(1).hresp  <=  HR_AHBSlave123_Out.HRESP;
  slvo(1).hrdata <=  HR_AHBSlave123_Out.HRDATA;
  slvo(1).hsplit <=  HR_AHBSlave123_Out.HSPLIT;
  slvo(1).hconfig <= (0 => zero32,  4 => ahb_membar(16#200#, '1', '1', 16#FFF#),  others => zero32);
  slvo(1).hindex <= 1;
  --ahb slave input
  HR_AHBSlave121_In.HSEL      <= slvi.hsel(0);
  HR_AHBSlave121_In.HADDR     <= slvi.haddr;       
  HR_AHBSlave121_In.HWRITE    <= slvi.hwrite;    
  HR_AHBSlave121_In.HTRANS    <= slvi.htrans;      
  HR_AHBSlave121_In.HSIZE     <= slvi.hsize;       
  HR_AHBSlave121_In.HBURST    <= slvi.hburst;      
  HR_AHBSlave121_In.HWDATA    <= slvi.hwdata;     
  HR_AHBSlave121_In.HPROT     <= slvi.hprot;       
  HR_AHBSlave121_In.HREADY    <= slvi.hready;    
  HR_AHBSlave121_In.HMASTER   <= slvi.hmaster;     
  HR_AHBSlave121_In.HMASTLOCK <= slvi.hmastlock;   
  HR_AHBSlave123_In.HSEL <= slvi.hsel(1);
  HR_AHBSlave123_In.HADDR     <= slvi.haddr;       
  HR_AHBSlave123_In.HWRITE    <= slvi.hwrite;    
  HR_AHBSlave123_In.HTRANS    <= slvi.htrans;      
  HR_AHBSlave123_In.HSIZE     <= slvi.hsize;       
  HR_AHBSlave123_In.HBURST    <= slvi.hburst;      
  HR_AHBSlave123_In.HWDATA    <= slvi.hwdata;     
  HR_AHBSlave123_In.HPROT     <= slvi.hprot;       
  HR_AHBSlave123_In.HREADY    <= slvi.hready;    
  HR_AHBSlave123_In.HMASTER   <= slvi.hmaster;     
  HR_AHBSlave123_In.HMASTLOCK <= slvi.hmastlock; 
  -- LR Compressor (Low Resolution) - Slave 2 (123) and Slave 3 (121)
  compressor_LR : entity work.SHyLoC_toplevel_v2
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_lr,
      AHBSlave121_In   => LR_AHBSlave121_In,      -- Connected to slave 3
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_lr,
      AHBSlave121_Out  => LR_AHBSlave121_Out,   -- Output for slave 3
      AHBSlave123_In   => LR_AHBSlave123_In,      -- Connected to slave 2
      AHBSlave123_Out  => LR_AHBSlave123_Out,   -- Output for slave 2
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,
      AHBMaster123_Out => open,
      DataIn_shyloc    => data_in_LR,
      DataIn_NewValid  => data_in_valid_LR,
      DataOut          => data_out_LR,
      DataOut_NewValid => data_out_valid_LR,
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop_lr,
      AwaitingConfig   => awaiting_config(1),
      Ready            => ready(1),
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished(1),
      Error            => error(1)
    );
  -- slave 2 CCSDS121  
  slvo(2).hready <=  LR_AHBSlave121_Out.HREADY; 
  slvo(2).hresp  <=  LR_AHBSlave121_Out.HRESP;
  slvo(2).hrdata <=  LR_AHBSlave121_Out.HRDATA;
  slvo(2).hsplit <=  LR_AHBSlave121_Out.HSPLIT;
  slvo(2).hconfig <= (0 => zero32,  4 => ahb_membar(16#400#, '1', '1', 16#FFF#),  others => zero32);
  slvo(2).hindex <= 2;
  -- slave 3 CCSDS123  
  slvo(3).hready <=  LR_AHBSlave123_Out.HREADY; 
  slvo(3).hresp  <=  LR_AHBSlave123_Out.HRESP;
  slvo(3).hrdata <=  LR_AHBSlave123_Out.HRDATA;
  slvo(3).hsplit <=  LR_AHBSlave123_Out.HSPLIT;
  slvo(3).hconfig <= (0 => zero32,  4 => ahb_membar(16#500#, '1', '1', 16#FFF#),  others => zero32);
  slvo(3).hindex <= 2;
   --ahb slave input
  LR_AHBSlave121_In.HSEL <= slvi.hsel(2);
  LR_AHBSlave121_In.HADDR     <= slvi.haddr;       
  LR_AHBSlave121_In.HWRITE    <= slvi.hwrite;    
  LR_AHBSlave121_In.HTRANS    <= slvi.htrans;      
  LR_AHBSlave121_In.HSIZE     <= slvi.hsize;       
  LR_AHBSlave121_In.HBURST    <= slvi.hburst;      
  LR_AHBSlave121_In.HWDATA    <= slvi.hwdata;     
  LR_AHBSlave121_In.HPROT     <= slvi.hprot;       
  LR_AHBSlave121_In.HREADY    <= slvi.hready;    
  LR_AHBSlave121_In.HMASTER   <= slvi.hmaster;     
  LR_AHBSlave121_In.HMASTLOCK <= slvi.hmastlock;   
  LR_AHBSlave123_In.HSEL <= slvi.hsel(3);
  LR_AHBSlave123_In.HADDR     <= slvi.haddr;       
  LR_AHBSlave123_In.HWRITE    <= slvi.hwrite;    
  LR_AHBSlave123_In.HTRANS    <= slvi.htrans;      
  LR_AHBSlave123_In.HSIZE     <= slvi.hsize;       
  LR_AHBSlave123_In.HBURST    <= slvi.hburst;      
  LR_AHBSlave123_In.HWDATA    <= slvi.hwdata;     
  LR_AHBSlave123_In.HPROT     <= slvi.hprot;       
  LR_AHBSlave123_In.HREADY    <= slvi.hready;    
  LR_AHBSlave123_In.HMASTER   <= slvi.hmaster;     
  LR_AHBSlave123_In.HMASTLOCK <= slvi.hmastlock; 
  -- H Compressor (Hyperspectral) - Slave 4
  compressor_H : entity VH_compressor.ccsds121_shyloc_top_VH
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_h,
      AHBSlave121_In   => VH_AHBSlave121_In,      -- Connected to slave 4
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_h,
      AHBSlave121_Out  => VH_AHBSlave121_Out,   -- Output for slave 4
      DataIn           => data_in_H,
      DataIn_NewValid  => data_in_valid_H,
      IsHeaderIn       => '0',
      NbitsIn          => "000000",
      DataOut          => data_out_H,
      DataOut_NewValid => data_out_valid_H,
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop_h,
      AwaitingConfig   => awaiting_config(2),
      Ready            => ready(2),
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished(2),
      Error            => error(2)
    );

  -- slave 4 CCSDS121  
  slvo(4).hready <=  VH_AHBSlave121_Out.HREADY; 
  slvo(4).hresp  <=  VH_AHBSlave121_Out.HRESP;
  slvo(4).hrdata <=  VH_AHBSlave121_Out.HRDATA;
  slvo(4).hsplit <=  VH_AHBSlave121_Out.HSPLIT;
  slvo(4).hconfig <= (0 => zero32,  4 => ahb_membar(16#700#, '1', '1', 16#FFF#),  others => zero32);
  slvo(4).hindex  <= 4;
  --ahb slave input
  VH_AHBSlave121_In.HSEL <= slvi.hsel(4);
  VH_AHBSlave121_In.HADDR     <= slvi.haddr;       
  VH_AHBSlave121_In.HWRITE    <= slvi.hwrite;    
  VH_AHBSlave121_In.HTRANS    <= slvi.htrans;      
  VH_AHBSlave121_In.HSIZE     <= slvi.hsize;       
  VH_AHBSlave121_In.HBURST    <= slvi.hburst;      
  VH_AHBSlave121_In.HWDATA    <= slvi.hwdata;     
  VH_AHBSlave121_In.HPROT     <= slvi.hprot;       
  VH_AHBSlave121_In.HREADY    <= slvi.hready;    
  VH_AHBSlave121_In.HMASTER   <= slvi.hmaster;     
  VH_AHBSlave121_In.HMASTLOCK <= slvi.hmastlock;   
  -----------------------------------------------------------------------------
  -- Status signal generation 
  -----------------------------------------------------------------------------
  
  -- Pack status for each compressor
  compressor_status_HR.AwaitingConfig <= awaiting_config(0);
  compressor_status_HR.ready <= ready(0);
  compressor_status_HR.finished <= finished(0);
  compressor_status_HR.error <= error(0);
  
  compressor_status_LR.AwaitingConfig <= awaiting_config(1);
  compressor_status_LR.ready <= ready(1);
  compressor_status_LR.finished <= finished(1);
  compressor_status_LR.error <= error(1);
  
  compressor_status_H.AwaitingConfig <= awaiting_config(2);
  compressor_status_H.ready <= ready(2);
  compressor_status_H.finished <= finished(2);
  compressor_status_H.error <= error(2);
  
  -- System status outputs
  system_ready <= '1' when ready = (ready'range => '1') else '0';
  system_error <= '1' when error /= (error'range => '0') else '0';
  
  -- config_done signal (simplified)
  config_done <= '1' when awaiting_config = (awaiting_config'range => '0') 
                     and ready /= (ready'range => '0') else '0';

end architecture rtl;