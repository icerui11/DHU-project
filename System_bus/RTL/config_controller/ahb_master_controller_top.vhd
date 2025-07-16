--------------------------------------------------------------------------------
--== Filename ..... ahb_master_controller_top.vhd                           ==--
--== Institute .... IDA TU Braunschweig RoSy                                ==--
--== Authors ...... Rui Yin                                                 ==--
--== Copyright .... Copyright (c) 2025 IDA                                  ==--
--== Project ...... Compression Core Configuration                          ==--
--== Version ...... 1.00                                                    ==--
--== Conception ... July 2025                                             ==--
-- AHB Master Controller Top Level Module
-- This top-level module integrates the AHB master controller with the AHB master interface
-- Controller reads configuration data from RAM and writes to compression cores via AHB
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;

--library define in config_types_pkg
library config_controller;
use config_controller.config_pkg.all;

entity ahb_master_controller_top is
  generic (
    -- AHB Master parameters / AHB主控制器参数
    hindex      : integer := 0;                    -- AHB master index / AHB主控制器索引
    haddr_mask  : integer := 16#FFF#;              -- Address mask / 地址掩码
    hmaxburst   : integer := 16;                   -- Maximum burst length / 最大突发长度

    -- Config RAM parameters / 配置RAM参数
    g_input_data_width  : integer := c_input_data_width;   -- Input data width / 输入数据宽度
    g_input_addr_width  : integer := c_input_addr_width;   -- Input address width / 输入地址宽度
    g_input_depth       : integer := c_input_depth;        -- Input address depth / 输入地址深度
    g_output_data_width : integer := c_output_data_width;  -- Output data width / 输出数据宽度
    g_output_addr_width : integer := c_output_addr_width;  -- Output address width / 输出地址宽度
    g_output_depth      : integer := c_output_depth;       -- Output address depth / 输出地址深度
    
    -- Compression cores base addresses / 压缩核心基地址
    ccsds123_1_base : std_logic_vector(31 downto 0) := x"40010000";
    ccsds123_2_base : std_logic_vector(31 downto 0) := x"40020000";
    ccsds121_base   : std_logic_vector(31 downto 0) := x"40030000";
    
    -- Configuration sizes (in 32-bit words) / 配置大小（32位字）
    ccsds123_cfg_size : integer := 6;             -- Number of config registers for CCSDS123
    ccsds121_cfg_size : integer := 4              -- Number of config registers for CCSDS121
  );
  port (
    -- System signals / 系统信号
    clk         : in  std_ulogic;                 -- System clock / 系统时钟
    rst_n       : in  std_ulogic;                 -- Active low reset / 低电平复位
    
    -- Compression core status interface / 压缩核心状态接口
    compressor_status_HR : in compressor_status;  -- High Resolution compressor status / 高分辨率压缩器状态
    compressor_status_LR : in compressor_status;  -- Low Resolution compressor status / 低分辨率压缩器状态
    compressor_status_H  : in compressor_status;  -- Hyperspectral compressor status / 高光谱压缩器状态
    
    -- RAM configuration interface / RAM配置接口
    ram_wr_en   : in  std_logic;                  -- Write enable signal for RAM / RAM写使能信号
    wr_addr     : in  std_logic_vector(g_input_addr_width-1 downto 0);  -- Write address / 写地址
    wr_data     : in  std_logic_vector(7 downto 0);  -- Write data / 写数据
    
    -- AHB Bus interface / AHB总线接口
    ahbmi : in  ahb_mst_in_type;                  -- AHB master input signals / AHB主控制器输入信号
    ahbmo : out ahb_mst_out_type                  -- AHB master output signals / AHB主控制器输出信号
  );
end entity ahb_master_controller_top;

architecture rtl of ahb_master_controller_top is

  -- Internal signals for connecting controller to AHB master / 连接控制器到AHB主控制器的内部信号
  signal ctrl_to_ahb_master   : ahbtbm_ctrl_in_type;   -- Control signals from controller to AHB master
  signal ctrl_from_ahb_master : ahbtbm_ctrl_out_type;  -- Control signals from AHB master to controller

begin

  -----------------------------------------------------------------------------
  -- AHB Master Controller Instance / AHB主控制器实例
  -- This module manages the configuration process and generates AHB control signals
  -- 该模块管理配置过程并生成AHB控制信号
  -----------------------------------------------------------------------------
  ahb_master_controller_inst : entity config_controller.ahb_master_controller
    generic map (
      hindex            => hindex,
      haddr_mask        => haddr_mask,
      hmaxburst         => hmaxburst,
      g_input_data_width  => g_input_data_width,
      g_input_addr_width  => g_input_addr_width,
      g_input_depth       => g_input_depth,
      g_output_data_width => g_output_data_width,
      g_output_addr_width => g_output_addr_width,
      g_output_depth      => g_output_depth,
      ccsds123_1_base     => ccsds123_1_base,
      ccsds123_2_base     => ccsds123_2_base,
      ccsds121_base       => ccsds121_base,
      ccsds123_cfg_size   => ccsds123_cfg_size,
      ccsds121_cfg_size   => ccsds121_cfg_size
    )
    port map (
      clk                   => clk,
      rst_n                 => rst_n,
      compressor_status_HR  => compressor_status_HR,
      compressor_status_LR  => compressor_status_LR,
      compressor_status_H   => compressor_status_H,
      ram_wr_en             => ram_wr_en,
      wr_addr               => wr_addr,
      wr_data               => wr_data,
      ctrli                 => ctrl_to_ahb_master,     -- Output to AHB master
      ctrlo                 => ctrl_from_ahb_master    -- Input from AHB master
    );

  -----------------------------------------------------------------------------
  -- AHB Master Interface Instance / AHB主接口实例
  -- This module handles the actual AHB bus transactions
  -- 该模块处理实际的AHB总线事务
  -----------------------------------------------------------------------------
  ccsds123_ahb_mst_inst : entity shyloc_123.ccsds123_ahb_mst
    port map (
      rst_n => rst_n,
      clk   => clk,
      ctrli => ctrl_to_ahb_master,     -- Input from controller
      ctrlo => ctrl_from_ahb_master,   -- Output to controller
      ahbmi => ahbmi,                  -- AHB master input from bus
      ahbmo => ahbmo                   -- AHB master output to bus
    );

end architecture rtl;