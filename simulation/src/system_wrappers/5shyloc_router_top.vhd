--------------------------------------------------------------------------------
-- File Description  -- Integrated top-level system combining SpaceWire router
--                      with multiple SHyLoC compressor cores  
--------------------------------------------------------------------------------
-- @ File Name        : integrated_shyloc_spw_system_top.vhd
-- @ Engineer          : Rui (Senior FPGA Engineer)
-- @ Date              : 25.08.2025
-- @ VHDL Version      : 2008
-- @ Supported Toolchain : Questasim, Libero
-- @ Target Device     : RTG4, SmartFusion2
-- @ Description       : Complete system integrating SpaceWire router/FIFO 
--                       controller with 7-core SHyLoC compression system
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- SmartFusion2 specific libraries / SmartFusion2专用库
library smartfusion2;
use smartfusion2.all;

-- SHyLoC compression libraries / SHyLoC压缩库
library shyloc_121; 
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

library VH_compressor;
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;

-- System constants and router context / 系统常数和路由器上下文
library work;
use work.system_constant_pckg.all;
context work.router_context;

-- Configuration controller library / 配置控制器库
library config_controller;
use config_controller.config_pkg.all;

entity integrated_shyloc_spw_system_top is 
    generic (
        -- SpaceWire Router Configuration / SpaceWire路由器配置
        g_num_ports         : natural range 1 to 32     := c_num_ports;         -- Number of SpW ports / SpW端口数量
        g_is_fifo           : t_dword                   := c_fifo_ports;        -- FIFO port configuration / FIFO端口配置
        g_clock_freq        : real                      := c_spw_clk_freq;      -- SpW clock frequency / SpW时钟频率
        g_addr_width        : integer                   := 9;                   -- FIFO address width / FIFO地址宽度
        g_data_width        : integer                   := 8;                   -- FIFO data width / FIFO数据宽度
        g_mode              : string                    := "single";            -- SpW IO mode / SpW IO模式
        g_priority          : string                    := c_priority;          -- SpW priority / SpW优先级
        g_ram_style         : string                    := c_ram_style;         -- RAM style / RAM样式
        syn_mode            : string                    := "lsram";             -- Synthesis RAM mode / 综合RAM模式
        g_router_port_addr  : integer                   := c_router_port_addr;  -- Router port address / 路由器端口地址
        
        -- Compressor System Configuration / 压缩器系统配置
        NUM_COMPRESSORS     : integer                   := 7;                   -- Number of compressor cores / 压缩器核心数量
        COMPRESSOR_BASE_ADDR_HR_123 : integer          := 16#200#;             -- HR CCSDS123 base address / HR CCSDS123基地址
        COMPRESSOR_BASE_ADDR_HR_121 : integer          := 16#100#;             -- HR CCSDS121 base address / HR CCSDS121基地址
        COMPRESSOR_BASE_ADDR_HR_121_2 : integer        := 16#110#;             -- Additional HR CCSDS121 base address
        COMPRESSOR_BASE_ADDR_LR_123 : integer          := 16#400#;             -- LR CCSDS123 base address / LR CCSDS123基地址
        COMPRESSOR_BASE_ADDR_LR_121 : integer          := 16#500#;             -- LR CCSDS121 base address / LR CCSDS121基地址
        COMPRESSOR_BASE_ADDR_LR_121_2 : integer        := 16#510#;             -- Additional LR CCSDS121 base address
        COMPRESSOR_BASE_ADDR_H_121  : integer          := 16#700#              -- H CCSDS121 base address / H CCSDS121基地址
    );                                                                                                    

    port(
        -- System Clock and Reset / 系统时钟和复位
        clk_sys             : in std_logic;                                    -- System clock for compressor cores / 压缩器核心系统时钟
        clk_spw             : in std_logic;                                    -- SpaceWire clock / SpaceWire时钟
        clk_ahb             : in std_logic;                                    -- AHB bus clock / AHB总线时钟
        rst_n               : in std_logic;                                    -- Global reset (active low) / 全局复位(低有效)
        rst_n_lr            : in std_logic;                                    -- LR compressor reset / LR压缩器复位
        rst_n_hr            : in std_logic;                                    -- HR compressor reset / HR压缩器复位
        rst_n_h             : in std_logic;                                    -- H compressor reset / H压缩器复位
        
        -- SpaceWire Interface / SpaceWire接口
        -- Differential SpaceWire signals for RTG4/SmartFusion2
        -- RTG4/SmartFusion2的差分SpaceWire信号
        Din_p               : in  std_logic_vector(1 to g_num_ports-1);       -- SpW data input positive / SpW数据输入正端
        Sin_p               : in  std_logic_vector(1 to g_num_ports-1);       -- SpW strobe input positive / SpW选通输入正端
        Dout_p              : out std_logic_vector(1 to g_num_ports-1);       -- SpW data output positive / SpW数据输出正端
        Sout_p              : out std_logic_vector(1 to g_num_ports-1);       -- SpW strobe output positive / SpW选通输出正端

        -- Configuration RAM Interface / 配置RAM接口
        -- Used for runtime configuration of compressor cores
        -- 用于压缩器核心的运行时配置
        ram_wr_en           : in std_logic;                                    -- RAM write enable / RAM写使能
        ram_wr_addr         : in std_logic_vector(c_input_addr_width-1 downto 0); -- RAM write address / RAM写地址
        ram_wr_data         : in std_logic_vector(7 downto 0);               -- RAM write data / RAM写数据
        
        -- External Control Signals / 外部控制信号
        force_stop          : in  std_logic;                                   -- Force stop for all compressors / 强制停止所有压缩器
        force_stop_lr       : in  std_logic;                                   -- Force stop for LR compressors / 强制停止LR压缩器
        force_stop_h        : in  std_logic;                                   -- Force stop for H compressor / 强制停止H压缩器
        ready_ext           : in  std_logic;                                   -- External ready signal / 外部就绪信号
        
        -- Compressed Data Outputs / 压缩数据输出
        -- High Resolution outputs / 高分辨率输出
        data_out_HR         : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        data_out_valid_HR   : out std_logic;                                   -- HR data valid / HR数据有效
        data_out_HR_121_2   : out std_logic_vector(VH_compressor.VH_ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        data_out_valid_HR_121_2 : out std_logic;                              -- Additional HR CCSDS121 output valid
        
        -- Low Resolution outputs / 低分辨率输出
        data_out_LR         : out std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        data_out_valid_LR   : out std_logic;                                   -- LR data valid / LR数据有效
        data_out_LR_121_2   : out std_logic_vector(VH_compressor.VH_ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        data_out_valid_LR_121_2 : out std_logic;                              -- Additional LR CCSDS121 output valid
        
        -- Hyperspectral outputs / 超光谱输出
        data_out_H          : out std_logic_vector(VH_compressor.VH_ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        data_out_valid_H    : out std_logic;                                   -- H data valid / H数据有效
        
        -- System Status Outputs / 系统状态输出
        system_ready        : out std_logic;                                   -- System ready flag / 系统就绪标志
        config_done         : out std_logic;                                   -- Configuration complete / 配置完成
        system_error        : out std_logic;                                   -- System error flag / 系统错误标志
        spw_error           : out std_logic_vector(1 to c_num_fifoports);     -- SpW error flags / SpW错误标志
        router_connected    : out std_logic_vector(31 downto 1)               -- SpW connection status / SpW连接状态
    );

end integrated_shyloc_spw_system_top;

architecture rtl of integrated_shyloc_spw_system_top is 

    -----------------------------------------------------------------------------
    -- Internal Signal Declarations / 内部信号声明
    -----------------------------------------------------------------------------
    
    -- Raw CCSDS data from SpaceWire router to compressors
    -- 从SpaceWire路由器到压缩器的原始CCSDS数据
    signal raw_ccsds_data       : raw_ccsds_data_array(1 to c_num_fifoports);
    signal ccsds_datanewValid   : std_logic_vector(1 to c_num_fifoports);
    
    -- Processed data for compressor inputs
    -- 压缩器输入的处理数据
    signal data_in_HR_internal      : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_valid_HR_internal: std_logic;
    signal data_in_HR_2_internal    : std_logic_vector(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
    signal data_in_valid_HR_2_internal : std_logic;
    
    signal data_in_LR_internal      : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_valid_LR_internal: std_logic;
    signal data_in_LR_2_internal    : std_logic_vector(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
    signal data_in_valid_LR_2_internal : std_logic;
    
    signal data_in_H_internal       : std_logic_vector(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
    signal data_in_valid_H_internal : std_logic;
    
    -- FIFO control signals between router and compressors
    -- 路由器和压缩器之间的FIFO控制信号
    signal ccsds_datain         : ccsds_datain_array(1 to c_num_fifoports);
    signal w_update             : std_logic_vector(1 to c_num_fifoports);
    signal asym_FIFO_full       : std_logic_vector(1 to c_num_fifoports);
    signal ccsds_ready_ext      : std_logic_vector(1 to c_num_fifoports);
    
    -- SpaceWire router status and control
    -- SpaceWire路由器状态和控制
    signal rx_cmd_out           : rx_cmd_out_array(1 to c_num_fifoports);
    signal rx_cmd_valid         : std_logic_vector(1 to c_num_fifoports);
    signal rx_cmd_ready         : std_logic_vector(1 to c_num_fifoports);
    
    signal rx_data_out          : rx_data_out_array(1 to c_num_fifoports);
    signal rx_data_valid        : std_logic_vector(1 to c_num_fifoports);
    signal rx_data_ready        : std_logic_vector(1 to c_num_fifoports);

    -----------------------------------------------------------------------------
    -- Data Width Conversion Functions / 数据位宽转换函数
    -----------------------------------------------------------------------------
    
    -- Function to convert raw CCSDS data to compressor input format
    -- 将原始CCSDS数据转换为压缩器输入格式的函数
    function convert_raw_to_hr_123(raw_data : std_logic_vector(15 downto 0)) 
        return std_logic_vector is
        variable result : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    begin
        -- Resize and sign-extend if necessary / 如有必要，调整大小并符号扩展
        if shyloc_123.ccsds123_parameters.D_GEN >= 8 then
            result := (others => '0');
            result(7 downto 0) := raw_data;
        else
            result := raw_data(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
        end if;
        return result;
    end function;
    
    function convert_raw_to_vh_121(raw_data : std_logic_vector(7 downto 0)) 
        return std_logic_vector is
        variable result : std_logic_vector(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
    begin
        -- Resize and sign-extend if necessary / 如有必要，调整大小并符号扩展
        if VH_compressor.VH_ccsds121_parameters.D_GEN >= 8 then
            result := (others => '0');
            result(7 downto 0) := raw_data;
        else
            result := raw_data(VH_compressor.VH_ccsds121_parameters.D_GEN-1 downto 0);
        end if;
        return result;
    end function;

begin 

    -----------------------------------------------------------------------------
    -- SpaceWire Router and FIFO Controller Instantiation
    -- SpaceWire路由器和FIFO控制器实例化
    -----------------------------------------------------------------------------
    
    router_fifo_ctrl_inst: entity work.router_fifo_ctrl_top_v2(rtl)
    generic map(
        g_num_ports         => g_num_ports,
        g_is_fifo           => g_is_fifo,
        g_clock_freq        => g_clock_freq,
        g_addr_width        => g_addr_width,
        g_data_width        => g_data_width,
        g_mode              => g_mode,
        g_priority          => g_priority,
        g_ram_style         => g_ram_style,
        syn_mode            => syn_mode,
        g_router_port_addr  => g_router_port_addr
    )
    port map( 
        rst_n               => rst_n,
        clk                 => clk_spw,
        
        -- SpaceWire interface / SpaceWire接口
        Din_p               => Din_p,
        Sin_p               => Sin_p,
        Dout_p              => Dout_p,
        Sout_p              => Sout_p,
        
        -- Command and data interfaces to compressors
        -- 到压缩器的命令和数据接口
        rx_cmd_out          => rx_cmd_out,
        rx_cmd_valid        => rx_cmd_valid,
        rx_cmd_ready        => rx_cmd_ready,
        
        rx_data_out         => rx_data_out,
        rx_data_valid       => rx_data_valid,
        rx_data_ready       => rx_data_ready,
        
        -- FIFO data flow to compressors / 到压缩器的FIFO数据流
        ccsds_datain        => ccsds_datain,
        w_update            => w_update,
        asym_FIFO_full      => asym_FIFO_full,
        ccsds_ready_ext     => ccsds_ready_ext,
        
        -- Raw CCSDS data output for compressors
        -- 为压缩器输出的原始CCSDS数据
        raw_ccsds_data      => raw_ccsds_data,
        ccsds_datanewValid  => ccsds_datanewValid,
        
        -- Status outputs / 状态输出
        spw_error           => spw_error,
        router_connected    => router_connected
    );
    
    -----------------------------------------------------------------------------
    -- Multiple Compressor System Instantiation
    -- 多压缩器系统实例化
    -----------------------------------------------------------------------------
    
    compressor_system_inst: entity work.shyloc_ahb_system_top_5compressor(rtl)
    generic map(
        NUM_COMPRESSORS             => NUM_COMPRESSORS,
        COMPRESSOR_BASE_ADDR_HR_123 => COMPRESSOR_BASE_ADDR_HR_123,
        COMPRESSOR_BASE_ADDR_HR_121 => COMPRESSOR_BASE_ADDR_HR_121,
        COMPRESSOR_BASE_ADDR_HR_121_2 => COMPRESSOR_BASE_ADDR_HR_121_2,
        COMPRESSOR_BASE_ADDR_LR_123 => COMPRESSOR_BASE_ADDR_LR_123,
        COMPRESSOR_BASE_ADDR_LR_121 => COMPRESSOR_BASE_ADDR_LR_121,
        COMPRESSOR_BASE_ADDR_LR_121_2 => COMPRESSOR_BASE_ADDR_LR_121_2,
        COMPRESSOR_BASE_ADDR_H_121  => COMPRESSOR_BASE_ADDR_H_121
    )
    port map(
        -- System clocks and resets / 系统时钟和复位
        clk_sys             => clk_sys,
        clk_ahb             => clk_ahb,
        rst_n               => rst_n,
        rst_n_lr            => rst_n_lr,
        rst_n_hr            => rst_n_hr,
        rst_n_h             => rst_n_h,
        
        -- Configuration interface / 配置接口
        ram_wr_en           => ram_wr_en,
        ram_wr_addr         => ram_wr_addr,
        ram_wr_data         => ram_wr_data,
        
        -- Data inputs from SpaceWire router (converted)
        -- 来自SpaceWire路由器的数据输入(已转换)
        data_in_HR          => data_in_HR_internal,
        data_in_valid_HR    => data_in_valid_HR_internal,
        data_in_HR_2        => data_in_HR_2_internal,
        data_in_valid_HR_2  => data_in_valid_HR_2_internal,
        
        data_in_LR          => data_in_LR_internal,
        data_in_valid_LR    => data_in_valid_LR_internal,
        data_in_LR_2        => data_in_LR_2_internal,
        data_in_valid_LR_2  => data_in_valid_LR_2_internal,
        
        data_in_H           => data_in_H_internal,
        data_in_valid_H     => data_in_valid_H_internal,
        
        -- Compressed data outputs / 压缩数据输出
        data_out_HR         => data_out_HR,
        data_out_valid_HR   => data_out_valid_HR,
        data_out_HR_121_2   => data_out_HR_121_2,
        data_out_valid_HR_121_2 => data_out_valid_HR_121_2,
        
        data_out_LR         => data_out_LR,
        data_out_valid_LR   => data_out_valid_LR,
        data_out_LR_121_2   => data_out_LR_121_2,
        data_out_valid_LR_121_2 => data_out_valid_LR_121_2,
        
        data_out_H          => data_out_H,
        data_out_valid_H    => data_out_valid_H,
        
        -- Control signals / 控制信号
        force_stop          => force_stop,
        force_stop_lr       => force_stop_lr,
        force_stop_h        => force_stop_h,
        ready_ext           => ready_ext,
        
        -- System status / 系统状态
        system_ready        => system_ready,
        config_done         => config_done,
        system_error        => system_error
    );
    
    -----------------------------------------------------------------------------
    -- Data Flow Control and Conversion Logic
    -- 数据流控制和转换逻辑
    -----------------------------------------------------------------------------
    
    -- Process to handle data distribution from SpaceWire router to compressors
    -- 处理从SpaceWire路由器到压缩器的数据分发过程
    data_distribution_proc: process(clk_sys, rst_n)
    begin
        if rst_n = '0' then
            -- Initialize all internal data signals / 初始化所有内部数据信号
            data_in_HR_internal <= (others => '0');
            data_in_valid_HR_internal <= '0';
            data_in_HR_2_internal <= (others => '0');
            data_in_valid_HR_2_internal <= '0';
            
            data_in_LR_internal <= (others => '0');
            data_in_valid_LR_internal <= '0';
            data_in_LR_2_internal <= (others => '0');
            data_in_valid_LR_2_internal <= '0';
            
            data_in_H_internal <= (others => '0');
            data_in_valid_H_internal <= '0';
            
        elsif rising_edge(clk_sys) then
            
            -- Distribute data based on FIFO port availability
            -- 基于FIFO端口可用性分发数据
            
            -- HR Compressor data assignment (FIFO port 1)
            -- HR压缩器数据分配(FIFO端口1)
            if c_num_fifoports >= 1 then
                if ccsds_datanewValid(1) = '1' then
                    data_in_HR_internal <= convert_raw_to_hr_123(raw_ccsds_data(1));
                    data_in_valid_HR_internal <= '1';
                    data_in_HR_2_internal <= convert_raw_to_vh_121(raw_ccsds_data(1));
                    data_in_valid_HR_2_internal <= '1';
                else
                    data_in_valid_HR_internal <= '0';
                    data_in_valid_HR_2_internal <= '0';
                end if;
            end if;
            
            -- LR Compressor data assignment (FIFO port 2)
            -- LR压缩器数据分配(FIFO端口2)
            if c_num_fifoports >= 2 then
                if ccsds_datanewValid(2) = '1' then
                    data_in_LR_internal <= convert_raw_to_hr_123(raw_ccsds_data(2));
                    data_in_valid_LR_internal <= '1';
                    data_in_LR_2_internal <= convert_raw_to_vh_121(raw_ccsds_data(2));
                    data_in_valid_LR_2_internal <= '1';
                else
                    data_in_valid_LR_internal <= '0';
                    data_in_valid_LR_2_internal <= '0';
                end if;
            end if;
            
            -- H Compressor data assignment (FIFO port 3)
            -- H压缩器数据分配(FIFO端口3)
            if c_num_fifoports >= 3 then
                if ccsds_datanewValid(3) = '1' then
                    data_in_H_internal <= convert_raw_to_vh_121(raw_ccsds_data(3));
                    data_in_valid_H_internal <= '1';
                else
                    data_in_valid_H_internal <= '0';
                end if;
            end if;
            
        end if;
    end process data_distribution_proc;
    
    -----------------------------------------------------------------------------
    -- Flow Control Logic / 流控制逻辑
    -----------------------------------------------------------------------------
    
    -- Simple ready signal generation based on compressor system readiness
    -- 基于压缩器系统就绪状态的简单就绪信号生成
    flow_control_proc: process(clk_spw, rst_n)
    begin
        if rst_n = '0' then
            rx_cmd_ready <= (others => '0');
            rx_data_ready <= (others => '0');
            
        elsif rising_edge(clk_spw) then
            -- Ready signals based on system status and FIFO availability
            -- 基于系统状态和FIFO可用性的就绪信号
            for i in 1 to c_num_fifoports loop
                rx_cmd_ready(i) <= not asym_FIFO_full(i) and system_ready;
                rx_data_ready(i) <= not asym_FIFO_full(i) and system_ready;
            end loop;
        end if;
    end process flow_control_proc;
    
    -----------------------------------------------------------------------------
    -- Additional FIFO Data Assignment
    -- 额外的FIFO数据分配
    -----------------------------------------------------------------------------
    
    -- Assign FIFO data inputs from SpaceWire data outputs
    -- 从SpaceWire数据输出分配FIFO数据输入
    fifo_data_assignment: for i in 1 to c_num_fifoports generate
        -- Convert 8-bit SpaceWire data to 32-bit FIFO input format
        -- 将8位SpaceWire数据转换为32位FIFO输入格式
        ccsds_datain(i) <= rx_data_out(i) & rx_data_out(i) & rx_data_out(i) & rx_data_out(i);
        w_update(i) <= rx_data_valid(i);
        ccsds_ready_ext(i) <= not asym_FIFO_full(i);
    end generate fifo_data_assignment;

end rtl;