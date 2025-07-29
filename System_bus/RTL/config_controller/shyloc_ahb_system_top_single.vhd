--------------------------------------------------------------------------------
-- Engineer: Rui Yin
-- 
-- Create Date: 2025-07-26
-- Design Name: SHyLoC AHB System Single Compressor
-- Module Name: shyloc_ahb_system_top_single
-- Project Name: SHyLoC Compression System - Single Core Version
-- Description: 
--   Simplified single-compressor version with AHB master controller
--   简化的单压缩器版本，带有AHB主控制器
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

entity shyloc_ahb_system_top_single is
  generic (
    -- AHB address configuration for HR compressor
    COMPRESSOR_BASE_ADDR_HR_123 : std_logic_vector(31 downto 0) := x"20000000";
    COMPRESSOR_BASE_ADDR_HR_121 : std_logic_vector(31 downto 0) := x"10000000"
  );
  port (
    -- System signals / 系统信号
    clk_sys     : in std_logic;  -- System clock for compression core
    clk_ahb     : in std_logic;  -- AHB bus clock
    rst_n       : in std_logic;  -- Global reset (active low)
    rst_n_hr    : in std_logic;  -- HR compressor reset (active low)
    
    -- Configuration RAM interface / 配置RAM接口
    -- Used to load configuration data from external source
    -- 用于从外部源加载配置数据
    ram_wr_en   : in std_logic;
    ram_wr_addr : in std_logic_vector(c_input_addr_width-1 downto 0);
    ram_wr_data : in std_logic_vector(7 downto 0);
    
    -- Data interface for HR compressor / HR压缩器数据接口
    -- Input data stream to be compressed
    -- 待压缩的输入数据流
    data_in_HR      : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_HR: in  std_logic;
    
    -- Compressed output data stream
    -- 压缩后的输出数据流
    data_out_HR     : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_HR: out std_logic;
    
    -- Control signals / 控制信号
    force_stop      : in  std_logic;  -- Force compression to stop
    ready_ext       : in  std_logic;  -- External ready signal
    
    -- Status outputs / 状态输出
    system_ready    : out std_logic;  -- System is ready for operation
    system_error    : out std_logic;   -- Error condition detected
    config_done      : out std_logic   -- Configuration done signal
  );
end entity shyloc_ahb_system_top_single;

architecture rtl of shyloc_ahb_system_top_single is

  -----------------------------------------------------------------------------
  -- Internal signals / 内部信号
  -----------------------------------------------------------------------------
  
  -- Default AHB master input for unused master interface
  -- 未使用的主接口的默认AHB主输入
  constant AHB_MST_IN_DEFAULT : AHB_Mst_In_Type := (
    hgrant  => '0',                  -- No grant
    hready  => '1',                  -- Always ready (no wait states)
    hresp   => "00",                 -- OKAY response
    hrdata  => (others => '0')       -- Zero data
  );
  
  -- AHB signals from master controller / 来自主控制器的AHB信号
  signal ahbmo : ahb_mst_out_type;   -- Master output signals
  signal ahbmi : ahb_mst_in_type;    -- Master input signals
  
  -- AHB signals to/from slave (compressor) / 到/从从机（压缩器）的AHB信号
  signal ahbsi_123 : AHB_Slv_In_Type;    -- Slave input for CCSDS123
  signal ahbso_123 : AHB_Slv_Out_Type;   -- Slave output from CCSDS123
  signal ahbsi_121 : AHB_Slv_In_Type;    -- Slave input for CCSDS121
  signal ahbso_121 : AHB_Slv_Out_Type;   -- Slave output from CCSDS121
  
  -- Control signals between master controller and AHB master
  -- 主控制器和AHB主机之间的控制信号
  signal ctrli : ahbtbm_ctrl_in_type;    -- Control input to AHB master
  signal ctrlo : ahbtbm_ctrl_out_type;   -- Control output from AHB master
  
  -- Compressor status signals / 压缩器状态信号
  signal compressor_status_HR : compressor_status;
  
  -- Individual status signals from compressor
  -- 来自压缩器的各个状态信号
  signal awaiting_config_HR : std_logic;
  signal ready_HR          : std_logic;
  signal finished_HR       : std_logic;
  signal error_HR          : std_logic;
  
  -- Address decode signals / 地址解码信号
  signal slave_sel         : std_logic;  -- '0' for 123, '1' for 121
  signal slave_sel_reg     : std_logic;  -- Registered for data phase

begin

  -----------------------------------------------------------------------------
  -- AHB Master Controller instantiation / AHB主控制器实例化
  -- This controller manages the configuration process
  -- 该控制器管理配置过程
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
      -- Compressor status (only HR in this version)
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_allzero,  -- Not used in single version
      compressor_status_H  => compressor_status_allzero,  -- Not used in single version
      -- RAM interface for configuration data
      ram_wr_en   => ram_wr_en,
      wr_addr     => ram_wr_addr,
      wr_data     => ram_wr_data,
      -- AHB control interface
      ctrli       => ctrli,
      ctrlo       => ctrlo
    );

  -----------------------------------------------------------------------------
  -- AHB Master interface instantiation / AHB主接口实例化
  -- Converts control signals to AHB protocol
  -----------------------------------------------------------------------------
  ahb_mst_inst : entity shyloc_123.ccsds123_ahb_mst
    port map (
      rst_n => rst_n,
      clk   => clk_ahb,
      ctrli => ctrli,
      ctrlo => ctrlo,
      ahbmi => ahbmi,
      ahbmo => ahbmo
    );

  -----------------------------------------------------------------------------
  -- Simplified AHB Decoder Logic / 简化的AHB解码器逻辑
  -- For single compressor, we only need to decode between 123 and 121 addresses
  -- 对于单个压缩器，我们只需要在123和121地址之间解码
  -----------------------------------------------------------------------------
  ahb_decoder_proc : process(ahbmo, ahbso_123, ahbso_121, slave_sel_reg)
    variable addr_masked : std_logic_vector(31 downto 0);
  begin
    -- Extract upper address bits for decoding / 提取高位地址用于解码
    addr_masked := ahbmo.haddr and x"F0000000";  -- Check upper 4 bits
    
    -- Determine which configuration interface is being accessed
    -- 确定正在访问哪个配置接口
    if addr_masked = COMPRESSOR_BASE_ADDR_HR_123 then
      slave_sel <= '0';  -- CCSDS123 configuration
    elsif addr_masked = COMPRESSOR_BASE_ADDR_HR_121 then
      slave_sel <= '1';  -- CCSDS121 configuration
    else
      slave_sel <= '0';  -- Default to 123
    end if;
    
    -- Simple grant logic (always grant when requested)
    -- 简单的授权逻辑（请求时始终授权）
    ahbmi.hgrant <= ahbmo.hbusreq;
    
    -- Multiplex slave responses based on registered select
    -- 基于注册的选择复用从机响应
    if slave_sel_reg = '0' then
      -- CCSDS123 slave response
      ahbmi.hready <= ahbso_123.hready;
      ahbmi.hresp  <= ahbso_123.hresp;
      ahbmi.hrdata <= ahbso_123.hrdata;
    else
      -- CCSDS121 slave response
      ahbmi.hready <= ahbso_121.hready;
      ahbmi.hresp  <= ahbso_121.hresp;
      ahbmi.hrdata <= ahbso_121.hrdata;
    end if;
    
    -- Route master signals to appropriate slave
    -- 将主机信号路由到适当的从机
    -- CCSDS123 slave inputs
    if slave_sel = '0' and ahbmo.htrans /= "00" then
      ahbsi_123.hsel    <= '1';
      ahbsi_123.haddr   <= ahbmo.haddr;
      ahbsi_123.hwrite  <= ahbmo.hwrite;
      ahbsi_123.htrans  <= ahbmo.htrans;
      ahbsi_123.hsize   <= ahbmo.hsize;
      ahbsi_123.hburst  <= ahbmo.hburst;
      ahbsi_123.hwdata  <= ahbmo.hwdata;
      ahbsi_123.hprot   <= ahbmo.hprot;
      ahbsi_123.hready  <= '1';
      ahbsi_123.hmaster <= (others => '0');
      ahbsi_123.hmastlock <= '0';
    else
      -- Deselect CCSDS123
      ahbsi_123.hsel    <= '0';
      ahbsi_123.haddr   <= (others => '0');
      ahbsi_123.hwrite  <= '0';
      ahbsi_123.htrans  <= "00";  -- IDLE
      ahbsi_123.hsize   <= "000";
      ahbsi_123.hburst  <= "000";
      ahbsi_123.hwdata  <= ahbmo.hwdata;
      ahbsi_123.hprot   <= "0000";
      ahbsi_123.hready  <= '1';
      ahbsi_123.hmaster <= (others => '0');
      ahbsi_123.hmastlock <= '0';
    end if;
    
    -- CCSDS121 slave inputs
    if slave_sel = '1' and ahbmo.htrans /= "00" then
      ahbsi_121.hsel    <= '1';
      ahbsi_121.haddr   <= ahbmo.haddr;
      ahbsi_121.hwrite  <= ahbmo.hwrite;
      ahbsi_121.htrans  <= ahbmo.htrans;
      ahbsi_121.hsize   <= ahbmo.hsize;
      ahbsi_121.hburst  <= ahbmo.hburst;
      ahbsi_121.hwdata  <= ahbmo.hwdata;
      ahbsi_121.hprot   <= ahbmo.hprot;
      ahbsi_121.hready  <= '1';
      ahbsi_121.hmaster <= (others => '0');
      ahbsi_121.hmastlock <= '0';
    else
      -- Deselect CCSDS121
      ahbsi_121.hsel    <= '0';
      ahbsi_121.haddr   <= (others => '0');
      ahbsi_121.hwrite  <= '0';
      ahbsi_121.htrans  <= "00";  -- IDLE
      ahbsi_121.hsize   <= "000";
      ahbsi_121.hburst  <= "000";
      ahbsi_121.hwdata  <= ahbmo.hwdata;
      ahbsi_121.hprot   <= "0000";
      ahbsi_121.hready  <= '1';
      ahbsi_121.hmaster <= (others => '0');
      ahbsi_121.hmastlock <= '0';
    end if;
  end process;
  
  -- Register slave select for data phase / 为数据阶段注册从机选择
  -- AHB protocol requires address phase and data phase alignment
  -- AHB协议需要地址阶段和数据阶段对齐
  slave_sel_reg_proc : process(clk_ahb, rst_n)
  begin
    if rst_n = '0' then
      slave_sel_reg <= '0';
    elsif rising_edge(clk_ahb) then
      if ahbmi.hready = '1' then
        slave_sel_reg <= slave_sel;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- HR Compressor Core Instantiation / HR压缩器核心实例化
  -- Single instance of the SHyLoC compression core
  -- SHyLoC压缩核心的单个实例
  -----------------------------------------------------------------------------
  compressor_HR : entity work.SHyLoC_toplevel_v2
    port map (
      -- System clocks and reset
      -- 系统时钟和复位
      Clk_S            => clk_sys,
      Rst_N            => rst_n_hr,
      
      -- CCSDS121 AHB slave interface
      -- CCSDS121 AHB从机接口
      AHBSlave121_In   => ahbsi_121,
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_hr,
      AHBSlave121_Out  => ahbso_121,
      
      -- CCSDS123 AHB slave interface
      -- CCSDS123 AHB从机接口
      AHBSlave123_In   => ahbsi_123,
      AHBSlave123_Out  => ahbso_123,
      
      -- Master interface not used in slave mode
      -- 从模式下不使用主接口
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,
      AHBMaster123_Out => open,
      
      -- Data interface / 数据接口
      DataIn_shyloc    => data_in_HR,
      DataIn_NewValid  => data_in_valid_HR,
      DataOut          => data_out_HR,
      DataOut_NewValid => data_out_valid_HR,
      
      -- Control and status / 控制和状态
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop,
      AwaitingConfig   => awaiting_config_HR,
      Ready            => ready_HR,
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished_HR,
      Error            => error_HR
    );

  -----------------------------------------------------------------------------
  -- Status signal generation / 状态信号生成
  -- Simplify status management for single compressor
  -- 简化单压缩器的状态管理
  -----------------------------------------------------------------------------
  
  -- Pack status for HR compressor / 打包HR压缩器的状态
  compressor_status_HR.AwaitingConfig <= awaiting_config_HR;
  compressor_status_HR.ready <= ready_HR;
  compressor_status_HR.finished <= finished_HR;
  compressor_status_HR.error <= error_HR;
  
  -- System status outputs / 系统状态输出
  -- Directly reflect single compressor status
  -- 直接反映单个压缩器状态
  system_ready <= ready_HR;
  system_error <= error_HR;
  config_done <= not awaiting_config_HR and ready_HR;
  -- Configuration done signal needs to come from master controller
  -- This is typically pulsed when configuration is complete
  -- config_done信号需要来自主控制器
  -- 通常在配置完成时脉冲

end architecture rtl;