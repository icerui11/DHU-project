--------------------------------------------------------------------------------
-- Company: Your Company
-- Engineer: Your Name
-- 
-- Create Date: 2025-01-20
-- Design Name: SHyLoC AHB System Top Level
-- Module Name: shyloc_ahb_system_top
-- Project Name: SHyLoC Compression System
-- Description: 
--   Top-level integration of AHB master controller with multiple SHyLoC 
--   compressor cores using AHB decoder for multi-slave support
--   顶层集成：AHB主控制器与多个SHyLoC压缩核心，使用AHB解码器支持多从机
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

entity shyloc_ahb_system_top is
  generic (
    -- Number of compressor cores / 压缩核心数量
    NUM_COMPRESSORS : integer := 5;
    
    -- AHB address configuration 
    COMPRESSOR_BASE_ADDR_HR_123 : std_logic_vector(31 downto 0) := x"20000000";
    COMPRESSOR_BASE_ADDR_HR_121 : std_logic_vector(31 downto 0) := x"10000000";
    COMPRESSOR_BASE_ADDR_LR_123 : std_logic_vector(31 downto 0) := x"40000000";
    COMPRESSOR_BASE_ADDR_LR_121 : std_logic_vector(31 downto 0) := x"50000000";
    COMPRESSOR_BASE_ADDR_H_121  : std_logic_vector(31 downto 0) := x"70000000"
  );
  port (
    -- System signals / 系统信号
    clk_sys     : in std_logic;
    clk_ahb     : in std_logic;
    rst_n       : in std_logic;
    rst_n_lr    : in std_logic;
    rst_n_hr    : in std_logic;
    rst_n_h     : in std_logic;
    
    -- Configuration RAM interface / 配置RAM接口
    ram_wr_en   : in std_logic;
    ram_wr_addr : in std_logic_vector(c_input_addr_width-1 downto 0);
    ram_wr_data : in std_logic_vector(7 downto 0);
    
    -- Data interfaces for compressors / 压缩器数据接口
    -- HR Compressor
    data_in_HR      : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_HR: in  std_logic;
    data_out_HR     : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_HR: out std_logic;
    
    -- LR Compressor  
    data_in_LR      : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_LR: in  std_logic;
    data_out_LR     : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_LR: out std_logic;
    
    -- H Compressor
    data_in_H       : in  std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    data_in_valid_H : in  std_logic;
    data_out_H      : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    data_out_valid_H: out std_logic;
    
    -- Control signals / 控制信号
    force_stop      : in  std_logic;
    ready_ext       : in  std_logic;
    
    -- Status outputs / 状态输出
    system_ready    : out std_logic;
    config_done     : out std_logic;
    system_error    : out std_logic
  );
end entity shyloc_ahb_system_top;

architecture rtl of shyloc_ahb_system_top is

  -----------------------------------------------------------------------------
  -- Internal signals / 内部信号
  -----------------------------------------------------------------------------
    constant AHB_MST_IN_DEFAULT : AHB_Mst_In_Type := (
    hgrant  => '0',      -- No grant
    hready  => '1',      -- Always ready (no wait states)
    hresp   => "00",     -- OKAY response
    hrdata  => (others => '0')  -- Zero data
  );
  -- AHB signals from master / 来自主机的AHB信号
  signal ahbmo : ahb_mst_out_type;
  signal ahbmi : ahb_mst_in_type;
  
  -- AHB signals to/from slaves / 到/从从机的AHB信号
  type ahb_slv_in_array is array (0 to NUM_COMPRESSORS-1) of AHB_Slv_In_Type;
  type ahb_slv_out_array is array (0 to NUM_COMPRESSORS-1) of AHB_Slv_Out_Type;
  signal ahbsi : ahb_slv_in_array;
  signal ahbso : ahb_slv_out_array;
  
  -- Control signals between master controller and AHB master
  signal ctrli : ahbtbm_ctrl_in_type;
  signal ctrlo : ahbtbm_ctrl_out_type;
  
  -- Compressor status signals / 压缩器状态信号
  signal compressor_status_HR : compressor_status;
  signal compressor_status_LR : compressor_status;
  signal compressor_status_H  : compressor_status;
  
  -- Individual compressor signals / 各个压缩器信号
  signal awaiting_config : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal ready          : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal finished       : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  signal error          : std_logic_vector(NUM_COMPRESSORS-1 downto 0);
  
  -- Decoder select signal / 解码器选择信号
  signal slave_sel      : integer range 0 to NUM_COMPRESSORS-1;
  signal slave_sel_reg  : integer range 0 to NUM_COMPRESSORS-1;
  signal slave_active   : std_logic;

begin

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
      -- Compressor status / 压缩器状态
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_LR,
      compressor_status_H  => compressor_status_H,
      -- RAM interface / RAM接口
      ram_wr_en   => ram_wr_en,
      wr_addr     => ram_wr_addr,
      wr_data     => ram_wr_data,
      -- AHB control / AHB控制
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
      ahbmi => ahbmi,
      ahbmo => ahbmo
    );

  -----------------------------------------------------------------------------
  -- AHB Decoder Logic / AHB解码器逻辑
  -- Maps master requests to appropriate slave based on address
  -- 根据地址将主机请求映射到适当的从机
  -----------------------------------------------------------------------------
  ahb_decoder_proc : process(ahbmo, ahbso, slave_sel_reg)
    variable addr_masked : std_logic_vector(31 downto 0);
  begin
    -- Default assignments / 默认赋值
    slave_active <= '0';
    slave_sel <= 0;
    
    -- Extract upper address bits for decoding / 提取高位地址用于解码
    addr_masked := ahbmo.haddr and x"FFFFF000";  -- 4KB boundaries
    
    case addr_masked is
      when COMPRESSOR_BASE_ADDR_HR_123 =>
        slave_sel <= 0;  -- HR compressor 123
        slave_active <= '1';
      when COMPRESSOR_BASE_ADDR_HR_121 =>
        slave_sel <= 1;  -- HR compressor 121
        slave_active <= '1';
      when COMPRESSOR_BASE_ADDR_LR_123 =>
        slave_sel <= 2;  -- LR compressor 123
        slave_active <= '1';
      when COMPRESSOR_BASE_ADDR_LR_121 =>
        slave_sel <= 3;  -- LR compressor 121
        slave_active <= '1';
      when COMPRESSOR_BASE_ADDR_H_121 =>
        slave_sel <= 4;  -- H compressor 121
        slave_active <= '1';
      when others =>
        slave_sel <= NUM_COMPRESSORS-1;  -- Default to last slave (error handling)
        slave_active <= '0';  -- No active slave
    end case;

    
    -- Connect selected slave to master / 将选定的从机连接到主机
    if slave_active = '1' then
      ahbmi.hgrant  <= ahbmo.hbusreq;  -- Simple grant (improve for real system)
      ahbmi.hready  <= ahbso(slave_sel_reg).hready;
      ahbmi.hresp   <= ahbso(slave_sel_reg).hresp;
      ahbmi.hrdata  <= ahbso(slave_sel_reg).hrdata;
    else
      -- No slave selected - return error / 未选择从机 - 返回错误
      ahbmi.hgrant  <= '0';
      ahbmi.hready  <= '1';
      ahbmi.hresp   <= "01";  -- ERROR response
      ahbmi.hrdata  <= (others => '0');
    end if;
    
    -- Route master signals to all slaves / 将主机信号路由到所有从机
    for i in 0 to NUM_COMPRESSORS-1 loop
      if i = slave_sel and slave_active = '1' then
        -- Active slave gets real signals / 活动从机获得真实信号
        ahbsi(i).hsel    <= '1';
        ahbsi(i).haddr   <= ahbmo.haddr;
        ahbsi(i).hwrite  <= ahbmo.hwrite;
        ahbsi(i).htrans  <= ahbmo.htrans;
        ahbsi(i).hsize   <= ahbmo.hsize;
        ahbsi(i).hburst  <= ahbmo.hburst;
        ahbsi(i).hwdata  <= ahbmo.hwdata;
        ahbsi(i).hprot   <= ahbmo.hprot;
        ahbsi(i).hready  <= '1';  -- Simplified
        ahbsi(i).hmaster <= (others => '0');
        ahbsi(i).hmastlock <= '0';
      else
        -- Inactive slaves / 非活动从机
        ahbsi(i).hsel    <= '0';
        ahbsi(i).haddr   <= (others => '0');
        ahbsi(i).hwrite  <= '0';
        ahbsi(i).htrans  <= "00";  -- IDLE
        ahbsi(i).hsize   <= "000";
        ahbsi(i).hburst  <= "000";
        ahbsi(i).hwdata  <= (others => '0');
        ahbsi(i).hprot   <= "0000";
        ahbsi(i).hready  <= '1';
        ahbsi(i).hmaster <= (others => '0');
        ahbsi(i).hmastlock <= '0';
      end if;
    end loop;
  end process;
  
  -- Register slave select for data phase / 为数据阶段注册从机选择
  slave_sel_reg_proc : process(clk_ahb, rst_n)
  begin
    if rst_n = '0' then
      slave_sel_reg <= 0;
    elsif rising_edge(clk_ahb) then
      if ahbmi.hready = '1' then
        slave_sel_reg <= slave_sel;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Compressor Core Instantiations / 压缩器核心实例化
  -----------------------------------------------------------------------------
  
  -- HR Compressor (High Resolution) / 高分辨率压缩器
  compressor_HR : entity work.SHyLoC_toplevel_v2
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_hr,
      AHBSlave121_In   => ahbsi(0),
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_hr,
      AHBSlave121_Out  => ahbso(0),
      AHBSlave123_In   => ahbsi(0),
      AHBSlave123_Out  => open,  -- Not used in slave mode
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,
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
    
  -- LR Compressor (Low Resolution) / 低分辨率压缩器
  compressor_LR : entity work.SHyLoC_toplevel_v2
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_lr,
      AHBSlave121_In   => ahbsi(1),
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_lr,
      AHBSlave121_Out  => ahbso(1),
      AHBSlave123_In   => ahbsi(1),
      AHBSlave123_Out  => open,
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,
      AHBMaster123_Out => open,
      DataIn_shyloc    => data_in_LR,
      DataIn_NewValid  => data_in_valid_LR,
      DataOut          => data_out_LR,
      DataOut_NewValid => data_out_valid_LR,
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop,
      AwaitingConfig   => awaiting_config(1),
      Ready            => ready(1),
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished(1),
      Error            => error(1)
    );
    
  -- H Compressor (Hyperspectral) / 高光谱压缩器
  compressor_H : entity work.SHyLoC_toplevel_v2
    port map (
      Clk_S            => clk_sys,
      Rst_N            => rst_n_h,
      AHBSlave121_In   => ahbsi(2),
      Clk_AHB          => clk_ahb,
      Reset_AHB        => rst_n_h,
      AHBSlave121_Out  => ahbso(2),
      AHBSlave123_In   => ahbsi(2),
      AHBSlave123_Out  => open,
      AHBMaster123_In  => AHB_MST_IN_DEFAULT,
      AHBMaster123_Out => open,
      DataIn_shyloc    => data_in_H,
      DataIn_NewValid  => data_in_valid_H,
      DataOut          => data_out_H,
      DataOut_NewValid => data_out_valid_H,
      Ready_Ext        => ready_ext,
      ForceStop        => force_stop,
      AwaitingConfig   => awaiting_config(2),
      Ready            => ready(2),
      FIFO_Full        => open,
      EOP              => open,
      Finished         => finished(2),
      Error            => error(2)
    );

  -----------------------------------------------------------------------------
  -- Status signal generation / 状态信号生成
  -----------------------------------------------------------------------------
  
  -- Pack status for each compressor / 打包每个压缩器的状态
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
  
  -- System status outputs / 系统状态输出
  system_ready <= '1' when ready = (ready'range => '1') else '0';
  system_error <= '1' when error /= (error'range => '0') else '0';
  
  -- config_done would come from the master controller
  -- This is a simplified connection - implement proper status aggregation
  -- config_done将来自主控制器
  -- 这是一个简化的连接 - 实现适当的状态聚合

end architecture rtl;