--============================================================================--
-- Modified CCSDS123 Configuration Core without AHB Slave Interface
--== Filename ..... ccsds123_config_core_modified.vhd                                      ==--             
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... 28.05 2025                                            ==--
-- Uses handshake protocol for configuration parameter reception
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

--! @brief Modified configuration core with handshake interface instead of AHB slave
entity ccsds123_config_core_modified is
  generic(
    RESET_TYPE: integer := 1;           --! Reset flavour (0) asynchronous (1) synchronous
    PREDICTION_TYPE: integer := 1;      --! Prediction architecture (0) BIP (1) BIP-MEM (2) BSQ (3) BIL (4) BIL-MEM
    CONFIG_DATA_WIDTH: integer := 32    --! Configuration data width
  );
  port (
    Clk: in std_logic;                  --! Main clock signal 
    Rst_n: in std_logic;                --! Reset signal, active low 
    
    -- Configuration Handshake Interface 
    config_data_in: in std_logic_vector(CONFIG_DATA_WIDTH-1 downto 0); --! Configuration data input 
    config_addr_in: in std_logic_vector(7 downto 0);  --! Configuration address 
    config_valid_in: in std_logic;      --! Configuration data valid 
    config_ready_out: out std_logic;    --! Ready to accept configuration 
    
    -- Interface Control 
    en_interface: out std_logic;        --! Enable ccsds123_shyloc_interface module operation
    interface_awaiting_config: out std_logic; --! Waiting for configuration signal
    interface_error: out std_logic;     --! Signals configuration error when high
    error_code: out std_logic_vector(3 downto 0); --! Error code identification
    
    -- Header Generation
    dispatcher_ready: in std_logic;     --! Output dispatcher ready signal
    header: out std_logic_vector(W_BUFFER_GEN-1 downto 0); --! Header value packed
    header_valid: out std_logic;        --! Header validation signal
    n_bits_header: out std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0); --! Valid bits in header
    
    -- Configuration Outputs 
    config_image: out config_123_image;     --! Image metadata configuration
    config_predictor: out config_123_predictor; --! Prediction configuration
    config_sample: out config_123_sample;   --! Sample-adaptive configuration
    config_weight_tab: out weight_tab_type; --! Custom weight vectors table
    config_valid: out std_logic;        --! Configuration validation signal
    
    -- Control and Status 
    control_out_s: in ctrls;            --! Control signals record
    clear: in std_logic                 --! Synchronous clear signal
  );
end ccsds123_config_core_modified;

architecture arch of ccsds123_config_core_modified is

  -- Configuration RX Module Signals 
  signal config_rx_data: config_123_f;
  signal config_rx_valid: std_logic := '0';
  signal config_rx_error: std_logic := '0';
  
  -- Interface Module Signals / 接口模块信号
  signal config_valid_local: std_logic := '0';
  signal error_code_local: std_logic_vector(3 downto 0) := (others => '0');
  signal awaiting_config_local: std_logic := '0';
  signal en_int: std_logic := '0';
  
  -- Configuration Records / 配置记录
  signal config_image_int: config_123_image := (others => (others => '0'));
  signal config_predictor_int: config_123_predictor := (others => (others => '0'));
  signal config_sample_int: config_123_sample := (others => (others => '0'));
  signal config_weight_tab_int: weight_tab_type := (others => (others => '0'));

begin

  -- Output Assignments / 输出分配
  config_image <= config_image_int;
  config_predictor <= config_predictor_int;
  config_sample <= config_sample_int;
  config_weight_tab <= config_weight_tab_int;
  config_valid <= config_valid_local;
  error_code <= error_code_local;
  interface_awaiting_config <= awaiting_config_local;
  en_interface <= en_int;

  --! Configuration RX Module - receives config via handshake protocol
  --! 配置接收模块 - 通过握手协议接收配置
  config_rx_inst: entity work.ccsds123_config_rx(rtl)
  generic map(
    RESET_TYPE => RESET_TYPE,
    CONFIG_DATA_WIDTH => CONFIG_DATA_WIDTH
  )
  port map(
    clk => Clk,
    rst_n => Rst_n,
    clear => clear,
    
    -- Handshake Interface / 握手接口
    config_data_in => config_data_in,
    config_addr_in => config_addr_in,
    config_valid_in => config_valid_in,
    config_ready_out => config_ready_out,
    
    -- Configuration Output / 配置输出
    config_out => config_rx_data,
    config_valid_out => config_rx_valid,
    config_error_out => config_rx_error
  );

  --! Enable Process - manages interface enabling based on configuration status
  --! 使能进程 - 根据配置状态管理接口使能
  enable_process: process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then 
      en_int <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE = 1)) then
        en_int <= '0';
      else
        -- Enable interface when valid configuration received
        -- 当接收到有效配置时使能接口
        en_int <= config_rx_valid;
      end if;
    end if;
  end process;

  --! Configuration Interface Module - validates and processes configuration
  --! 配置接口模块 - 验证和处理配置
  interface_gen: entity shyloc_123.ccsds123_shyloc_interface(arch)
  port map(
    clk => Clk,
    rst_n => Rst_n,
    config_in => config_rx_data,
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

  --! Header Generation Module 
  header_gen: entity shyloc_123.header123_gen(arch)
  generic map(
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
  port map(
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