--============================================================================--
-- Modified CCSDS123 Configuration Core without AHB Slave Interface
-- 修改后的CCSDS123配置核心，移除AHB slave接口，使用握手协议
--============================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;
use shyloc_123.config123_package.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;

--!@brief Modified configuration core using handshake protocol instead of AHB
--!@details 使用握手协议替代AHB接口的配置核心
entity ccsds123_config_core_handshake is
  generic(
    EN_RUNCFG: integer := 1;        --! Enables or disables runtime configuration. 启用或禁用运行时配置
    RESET_TYPE: integer := 1;       --! Reset flavour (0) asynchronous (1) synchronous. 复位类型
    PREDICTION_TYPE: integer := 1   --! Prediction architecture 预测架构类型
  );
  port (
    -- Clock and Reset 时钟和复位
    Clk: in std_logic;              --! Clock signal 时钟信号
    Rst_n: in std_logic;            --! Reset signal. Active low 复位信号，低有效
    
    -- Handshake Configuration Interface 握手配置接口
    config_data_in: in std_logic_vector(31 downto 0);  --! 32-bit configuration data input 32位配置数据输入
    config_addr_in: in std_logic_vector(4 downto 0);   --! Configuration address 配置地址
    config_valid_in: in std_logic;                      --! Configuration data valid 配置数据有效
    config_ready_out: out std_logic;                    --! Ready to accept configuration 准备接收配置
    
    -- Control and Status 控制和状态
    en_interface: out std_logic;                        --! Enable interface module operation 使能接口模块
    interface_awaiting_config: out std_logic;           --! Waiting for configuration 等待配置
    interface_error: out std_logic;                     --! Configuration error 配置错误
    error_code: out std_logic_vector (3 downto 0);      --! Error code 错误代码
    
    -- Header Generation 头部生成
    dispatcher_ready: in std_logic;                     --! Output dispatcher ready 输出调度器就绪
    header : out std_logic_vector(W_BUFFER_GEN-1 downto 0); --! Header value 头部值
    header_valid: out std_logic;                        --! Header valid 头部有效
    n_bits_header: out std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0); --! Number of valid bits 有效位数
    
    -- Configuration Outputs 配置输出
    config_image : out config_123_image;                --! Image metadata configuration 图像元数据配置
    config_predictor: out config_123_predictor;         --! Prediction configuration 预测配置
    config_sample: out config_123_sample;               --! Sample-adaptive configuration 样本自适应配置
    config_weight_tab: out weight_tab_type;             --! Custom weight table 自定义权重表
    config_valid: out std_logic;                        --! Configuration valid 配置有效
    
    -- Control Signals 控制信号
    control_out_s: in ctrls;                            --! Control signals record 控制信号记录
    clear: in std_logic                                 --! Synchronous clear 同步清零
  );
end ccsds123_config_core_handshake;
  
architecture arch of ccsds123_config_core_handshake is
  
  -- Configuration RX module signals RX模块信号
  signal config_rx_out: config_123_f;
  signal config_rx_valid: std_logic;
  signal config_rx_error: std_logic;
  
  -- Interface module signals 接口模块信号
  signal config_valid_local: std_logic := '0';
  signal error_code_local: std_logic_vector(3 downto 0) := (others => '0');
  signal awaiting_config_local: std_logic := '0';
  signal valid_s_out: std_logic := '0';
  
  -- Configuration values 配置值
  signal config_image_int : config_123_image := (others => (others => '0'));
  signal config_predictor_int: config_123_predictor := (others => (others => '0'));
  signal config_sample_int: config_123_sample := (others => (others => '0'));
  signal config_weight_tab_int: weight_tab_type := (others => (others => '0'));
  signal en_int: std_logic := '0';

begin

  config_valid <= config_valid_local;
  error_code <= error_code_local;
  interface_awaiting_config <= awaiting_config_local;
  
  config_image <= config_image_int;
  config_predictor <= config_predictor_int;
  config_sample <= config_sample_int;
  config_weight_tab <= config_weight_tab_int;
  
  en_interface <= en_int;
  
  --! Configuration RX module - replaces AHB slave
  --! 配置接收模块 - 替代AHB slave
  config_rx_inst : entity work.config_rx_handshake(rtl)
  generic map(
    RESET_TYPE => RESET_TYPE
  )
  port map(
    clk => Clk,
    rst_n => Rst_n,
    clear => clear,
    
    -- Handshake interface 握手接口
    config_data_in => config_data_in,
    config_addr_in => config_addr_in,
    config_valid_in => config_valid_in,
    config_ready_out => config_ready_out,
    
    -- Configuration output 配置输出
    config_out => config_rx_out,
    config_valid_out => config_rx_valid,
    config_error_out => config_rx_error
  );
  
  -----------------------------------------------------------------------------------------
  -- Enable logic for interface module
  -- 接口模块使能逻辑
  -----------------------------------------------------------------------------------------
  process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then 
      en_int <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        en_int <= '0';
      else
        if (EN_RUNCFG = 1) then
          en_int <= config_rx_valid;
        else
          en_int <= '1';  -- Always enabled when runtime config is disabled
        end if;
      end if;
    end if;
  end process;
  
  --! Interface module (validates configuration and puts it in records)
  --! 接口模块（验证配置并放入记录中）
  interface_gen : entity shyloc_123.ccsds123_shyloc_interface(arch)
  port map (
    clk => Clk,
    rst_n => Rst_n,
    config_in => config_rx_out,
    en => en_int,
    clear => clear,
    config_image => config_image_int,             
    config_predictor => config_predictor_int,         
    config_sample => config_sample_int,           
    config_weight_tab => config_weight_tab_int,       
    config_valid => config_valid_local,
    error => interface_error,
    error_code => error_code_local,
    awaiting_config => awaiting_config_local
  );
  
  --! Header generation module
  --! 头部生成模块
  header_gen : entity shyloc_123.header123_gen(arch)
  generic map (
    HEADER_ADDR => MAX_HEADER_SIZE,  
    W_BUFFER_GEN => W_BUFFER_GEN,
    PREDICTION_TYPE => PREDICTION_TYPE,
    W_NBITS_HEAD_GEN => W_NBITS_HEAD_GEN,
    RESET_TYPE => RESET_TYPE,    
    MAX_HEADER_SIZE => MAX_HEADER_SIZE, 
    Nz_GEN => Nz_GEN,      
    Q_GEN => Q_GEN,     
    W_MAX_HEADER_SIZE => W_MAX_HEADER_SIZE,
    WEIGHT_INIT_GEN => WEIGHT_INIT_GEN, 
    ENCODING_TYPE => ENCODING_TYPE, 
    ACC_INIT_TYPE_GEN => ACC_INIT_TYPE_GEN
  )
  port map (
    Clk => Clk,
    Rst_N => Rst_n,
    clear => clear,
    config_image_in => config_image_int,
    config_predictor_in => config_predictor_int,
    config_sample_in => config_sample_int,
    config_weight_tab_in => config_weight_tab_int,
    config_received => config_valid_local,
    dispatcher_ready => dispatcher_ready,
    header_out => header,   
    header_out_valid => header_valid,
    n_bits => n_bits_header
  ); 

end arch;