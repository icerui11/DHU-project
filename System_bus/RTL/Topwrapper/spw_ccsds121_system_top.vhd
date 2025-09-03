--------------------------------------------------------------------------------
-- Engineer: FPGA Senior Engineer
-- Create Date: 2025-09-03
-- Design Name: SpaceWire CCSDS121 Single Compressor System
-- Module Name: spacewire_ccsds121_single_system_top
-- Project Name: SpaceWire to CCSDS121 Compression System - Single Core Version
-- Description: Integrated system with SpaceWire FIFO and single CCSDS121 compressor
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

library config_controller;
use config_controller.config_pkg.all;

library VH_compressor;
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;

entity spw_ccsds121_system_top is
  generic (
    -- AHB Configuration
    COMPRESSOR_BASE_ADDR : integer := 16#100#;  -- 0x10000000
    
    -- FIFO Configuration Parameters
    FIFO_DEPTH           : integer := 32;       -- FIFO depth (power of 2)
    FIFO_ADDR_WIDTH      : integer := 5;        -- FIFO address width
    
    -- System Configuration Parameters
    RESET_TYPE           : integer := 1;        -- Reset type (0: async, 1: sync)
    TECH                 : integer := 0;        -- Technology selection
    EDAC                 : integer := 0         -- EDAC enable (0: disabled, 1: enabled)
  );
  port (
    -- System Clock and Reset Signals
    clk_sys     : in std_logic;                 -- System clock
    clk_ahb     : in std_logic;                 -- AHB clock
    rst_n       : in std_logic;                 -- System reset (active low)
    
    -- Configuration RAM interface 
    ram_wr_en   : in std_logic;                 -- RAM write enable
    ram_wr_addr : in std_logic_vector(c_input_addr_width-1 downto 0); -- RAM write address
    ram_wr_data : in std_logic_vector(7 downto 0); -- RAM write data
    
    -- SpaceWire Data Input Interface
    spw_data_in      : in  std_logic_vector(7 downto 0);  -- SpaceWire 8-bit data input
    spw_data_valid   : in  std_logic;                     -- SpaceWire data valid
  --  spw_data_ready   : out std_logic;                     -- Ready to receive SpaceWire data
    
    -- Compressed Data Output Interface
    data_out         : out std_logic_vector(VH_compressor.VH_ccsds121_parameters.W_BUFFER_GEN-1 downto 0); -- Compressed output
    data_out_valid   : out std_logic;                     -- Compressed data valid
    
    -- Control Signals
 --   system_enable    : in  std_logic;                     -- System enable
    force_stop       : in  std_logic;                     -- Force stop compression
    ready_ext        : in  std_logic;                     -- External ready signal
    clear_fifo       : in  std_logic;                     -- Clear FIFO command
    
    -- Status Outputs
    system_ready     : out std_logic;                     -- System ready    -- from ccsds_to_fifo_ready
    awaiting_config  : out std_logic;                     -- Awaiting configuration
    fifo_full        : out std_logic;                     -- FIFO full status
    compression_eop  : out std_logic;                     -- End of processing
    compression_finished : out std_logic;                 -- Compression finished
    system_error     : out std_logic;                     -- System error
    
    -- Debug Interface
    debug_fifo_state : out std_logic_vector(3 downto 0);  -- FIFO state debug
    debug_byte_count : out std_logic_vector(2 downto 0)   -- Byte count debug
  );
end entity spw_ccsds121_system_top;

architecture rtl of spw_ccsds121_system_top is

  -----------------------------------------------------------------------------
  -- Constants for AHB Controller
  -----------------------------------------------------------------------------
  constant NAHBM : integer := 1;  -- Number of AHB masters
  constant NAHBS : integer := 1;  -- Number of AHB slaves
  
  -- AHB master default
  constant AHB_MST_IN_DEFAULT : shyloc_utils.amba.AHB_Mst_In_Type := (
    hgrant  => '0',
    hready  => '1',
    hresp   => "00",
    hrdata  => (others => '0')
  );
  
  -- AHB master and slave vectors for ahbctrl
  signal msti : grlib.amba.ahb_mst_in_type;
  signal msto : grlib.amba.ahb_mst_out_vector;
  signal slvi : grlib.amba.ahb_slv_in_type;
  signal slvo : grlib.amba.ahb_slv_out_vector;
  
  -- AHB interface signals
  signal AHBmaster_in  : shyloc_utils.amba.ahb_mst_in_type;
  signal AHBmaster_out : shyloc_utils.amba.ahb_mst_out_type;
  signal AHBslave_in   : shyloc_utils.amba.ahb_slv_in_type;
  signal AHBslave_out  : shyloc_utils.amba.ahb_slv_out_type;

  -- Compressor AHB signals
  signal compressor_AHBSlave_In  : shyloc_utils.amba.ahb_slv_in_type;
  signal compressor_AHBSlave_Out : shyloc_utils.amba.ahb_slv_out_type;
  
  -- Control signals between master controller and AHB master
  signal ctrli : shyloc_123.ccsds_ahb_types.ahbtbm_ctrl_in_type;
  signal ctrlo : shyloc_123.ccsds_ahb_types.ahbtbm_ctrl_out_type;
  
  -- Compressor status signals
  signal compressor_status : compressor_status;
  
  -- FIFO to Compressor interface signals
  signal fifo_to_ccsds_data  : std_logic_vector(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
  signal fifo_to_ccsds_valid : std_logic;
  signal ccsds_to_fifo_ready : std_logic;
  
  -- FIFO configuration
  signal config_fifo : config_121;
  
  -- Individual compressor control signals
  signal comp_awaiting_config : std_logic;
  signal comp_ready          : std_logic;
  signal comp_finished       : std_logic;
  signal comp_error          : std_logic;
  signal comp_fifo_full      : std_logic;
  signal comp_eop            : std_logic;
  
  -- FIFO error signals
  signal fifo_error          : std_logic;
  
  -- Reset signal conversion
  signal rst : std_ulogic;

begin

  -- Reset signal conversion
  rst <= not rst_n;

  -----------------------------------------------------------------------------
  -- AHB Controller (Arbiter/Decoder/Mux) instantiation
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
      nahbs    => NAHBS,  -- 1 slave
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
      msti    => msti,
      msto    => msto,
      slvi    => slvi,
      slvo    => slvo,
      testen  => '0',
      testrst => '1',
      scanen  => '0',
      testoen => '1'
    );

  -----------------------------------------------------------------------------
  -- AHB Master Controller instantiation
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
      compressor_status_HR => compressor_status, -- Use single compressor status
      compressor_status_LR => compressor_status_init, -- Initialize unused
      compressor_status_H  => compressor_status_init, -- Initialize unused
      ram_wr_en   => ram_wr_en,
      wr_addr     => ram_wr_addr,
      wr_data     => ram_wr_data,
      ctrli       => ctrli,
      ctrlo       => ctrlo
    );

  -----------------------------------------------------------------------------
  -- AHB Master interface instantiation
  -----------------------------------------------------------------------------
  ahb_mst_inst : entity shyloc_123.ccsds123_ahb_mst
    port map (
      rst_n => rst_n,
      clk   => clk_ahb,
      ctrli => ctrli,
      ctrlo => ctrlo,
      ahbmi => AHBmaster_in,
      ahbmo => AHBmaster_out
    );

  -- AHB Master connections
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
  msto(0).HIRQ    <= (others => '0');
  msto(0).HCONFIG <= (0 => ahb_device_reg(VENDOR_GAISLER, 0, 0, 0, 0), others => zero32);
  msto(0).HINDEX  <= 0;

  -----------------------------------------------------------------------------
  -- SpaceWire FIFO Controller instantiation
  -----------------------------------------------------------------------------
  u_router_shyloc_fifo : entity VH_compressor.router_shyloc_fifo
    generic map (
      RESET_TYPE      => RESET_TYPE,
      FIFO_DEPTH      => FIFO_DEPTH,
      FIFO_ADDR_WIDTH => FIFO_ADDR_WIDTH,
      TECH            => TECH,
      EDAC            => EDAC
    )
    port map (
      clk_in              => clk_sys,
      rst_n               => rst_n,

      -- Configuration interface
      config_s            => config_fifo,
      
      -- SpaceWire data input interface
      rx_data_in          => spw_data_in,
      rx_data_valid       => spw_data_valid,

      -- CCSDS121 compressor interface
      ccsds_data_input    => fifo_to_ccsds_data,
      ccsds_data_valid    => fifo_to_ccsds_valid,
      ccsds_data_ready    => ccsds_to_fifo_ready,

      -- Control interface
  --    enable              => system_enable,
      clear_fifo          => clear_fifo,

      -- Status and error interface
      error_out           => fifo_error,

      -- Debug interface
      debug_state         => debug_fifo_state,
      debug_byte_count    => debug_byte_count
    );

  -----------------------------------------------------------------------------
  -- CCSDS121 Compressor instantiation
  -----------------------------------------------------------------------------
  compressor_inst : entity VH_compressor.ccsds121_shyloc_top_VH
    generic map (
      EN_RUNCFG            => EN_RUNCFG,
      RESET_TYPE           => RESET_TYPE,
      EDAC                 => EDAC,
      HSINDEX_121          => 0, -- Single slave index
      HSCONFIGADDR_121     => COMPRESSOR_BASE_ADDR,
      HSADDRMASK_121       => 16#FFF#,
      Nx_GEN               => Nx_GEN,
      Ny_GEN               => Ny_GEN,
      Nz_GEN               => Nz_GEN,
      D_GEN                => D_GEN,
      IS_SIGNED_GEN        => IS_SIGNED_GEN,
      ENDIANESS_GEN        => ENDIANESS_GEN,
      J_GEN                => J_GEN,
      REF_SAMPLE_GEN       => REF_SAMPLE_GEN,
      CODESET_GEN          => CODESET_GEN,
      W_BUFFER_GEN         => W_BUFFER_GEN,
      PREPROCESSOR_GEN     => PREPROCESSOR_GEN,
      DISABLE_HEADER_GEN   => DISABLE_HEADER_GEN,
      TECH                 => TECH
    )
    port map (
      -- System interface
      Clk_S                => clk_sys,
      Rst_N                => rst_n,
      
      -- AHB interface
      AHBSlave121_In       => compressor_AHBSlave_In,
      Clk_AHB              => clk_ahb,
      Reset_AHB            => rst_n,
      AHBSlave121_Out      => compressor_AHBSlave_Out,
      
      -- Data input interface (from FIFO)
      DataIn               => fifo_to_ccsds_data,
      DataIn_NewValid      => fifo_to_ccsds_valid,
      IsHeaderIn           => '0',
      NbitsIn              => (others => '0'),
      
      -- Data output interface
      DataOut              => data_out,
      DataOut_NewValid     => data_out_valid,
      
      -- Control interface
      ForceStop            => force_stop,
      Ready_Ext            => ready_ext,
      AwaitingConfig       => comp_awaiting_config,
      Ready                => ccsds_to_fifo_ready, -- Connected to FIFO ready
      FIFO_Full            => comp_fifo_full,
      EOP                  => comp_eop,
      Finished             => comp_finished,
      Error                => comp_error
    );

  -- AHB Slave connections for single compressor
  slvo(0).hready  <= compressor_AHBSlave_Out.HREADY;
  slvo(0).hresp   <= compressor_AHBSlave_Out.HRESP;
  slvo(0).hrdata  <= compressor_AHBSlave_Out.HRDATA;
  slvo(0).hsplit  <= compressor_AHBSlave_Out.HSPLIT;
  slvo(0).hconfig <= (0 => zero32, 4 => ahb_membar(COMPRESSOR_BASE_ADDR, '1', '1', 16#FFF#), others => zero32);
  slvo(0).hindex  <= 0;
  
  compressor_AHBSlave_In.HSEL      <= slvi.hsel(0);
  compressor_AHBSlave_In.HADDR     <= slvi.haddr;
  compressor_AHBSlave_In.HWRITE    <= slvi.hwrite;
  compressor_AHBSlave_In.HTRANS    <= slvi.htrans;
  compressor_AHBSlave_In.HSIZE     <= slvi.hsize;
  compressor_AHBSlave_In.HBURST    <= slvi.hburst;
  compressor_AHBSlave_In.HWDATA    <= slvi.hwdata;
  compressor_AHBSlave_In.HPROT     <= slvi.hprot;
  compressor_AHBSlave_In.HREADY    <= slvi.hready;
  compressor_AHBSlave_In.HMASTER   <= slvi.hmaster;
  compressor_AHBSlave_In.HMASTLOCK <= slvi.hmastlock;

  -----------------------------------------------------------------------------
  -- Status signal generation and output assignments
  -----------------------------------------------------------------------------
  
  -- Pack status for compressor
  compressor_status.AwaitingConfig <= comp_awaiting_config;
  compressor_status.ready <= comp_ready;
  compressor_status.finished <= comp_finished;
  compressor_status.error <= comp_error;
  
  -- Output assignments
  system_ready         <= ccsds_to_fifo_ready;
  awaiting_config      <= comp_awaiting_config;
  fifo_full            <= comp_fifo_full;
  compression_eop      <= comp_eop;
  compression_finished <= comp_finished;
  system_error         <= comp_error or fifo_error;
  
  -- Set comp_ready from ccsds_to_fifo_ready for status
 -- comp_ready <= ccsds_to_fifo_ready;
  
  -- FIFO configuration assignment (should be set via AHB or external means)
  -- For now, setting default values - in real system this would come from configuration
  config_fifo.D <= std_logic_vector(to_unsigned(VH_compressor.VH_ccsds121_parameters.D_GEN, config_fifo.D'length));
  -- Add other necessary config_fifo assignments here

end architecture rtl;