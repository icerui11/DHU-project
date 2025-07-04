--============================================================================--
-- CCSDS123 Configuration RX Module
--== Filename ..... ccsds123_config_rx.vhd    
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... 28.05 2025                                            ==--
-- Receives configuration parameters via handshake protocol
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

entity ccsds123_config_rx is
  generic(
    RESET_TYPE: integer := 1;           --! Reset type (0) async (1) sync
    CONFIG_DATA_WIDTH: integer := 32    --! Configuration data width
  );
  port(
    clk: in std_logic;                  
    rst_n: in std_logic;                
    clear: in std_logic;                --! Clear signal 
    
    -- Handshake Interface 
    config_data_in: in std_logic_vector(CONFIG_DATA_WIDTH-1 downto 0); --! Configuration data input
    config_addr_in: in std_logic_vector(7 downto 0);  --! Configuration address (register select)
    config_valid_in: in std_logic;      --! Input data valid signal 
    config_ready_out: out std_logic;    --! Ready to accept data 
    
    -- Configuration Output / 配置输出
    config_out      : out config_123_f;       --! Configuration record output 
    config_valid_out: out std_logic;    --! Configuration valid output 
    config_error_out: out std_logic     --! Configuration error output 
  );
end ccsds123_config_rx;

architecture rtl of ccsds123_config_rx is

  -- FSM States 
  type rx_state_type is (IDLE, RECEIVING, VALIDATE, ERROR_STATE);
  signal current_state, next_state: rx_state_type;
  
  -- Configuration Storage / 配置存储
  signal config_reg, config_next: config_123_f;
  
  -- Control Signals / 控制信号
  signal values_received_reg, values_received_next: std_logic_vector(N_CONFIG_WORDS-1 downto 0);
  signal config_complete: std_logic;
  signal config_valid_reg, config_valid_next: std_logic;
  signal config_error_reg, config_error_next: std_logic;
  signal ready_reg, ready_next: std_logic;
  
  -- Address Decoding / 地址解码
  constant ADDR_CONTROL: std_logic_vector(7 downto 0) := x"00";
  constant ADDR_NX: std_logic_vector(7 downto 0) := x"04";
  constant ADDR_NY: std_logic_vector(7 downto 0) := x"08";
  constant ADDR_NZ: std_logic_vector(7 downto 0) := x"0C";
  constant ADDR_D: std_logic_vector(7 downto 0) := x"10";
  constant ADDR_P: std_logic_vector(7 downto 0) := x"14";
  constant ADDR_OMEGA: std_logic_vector(7 downto 0) := x"18";
  constant ADDR_R: std_logic_vector(7 downto 0) := x"1C";
  
begin

  -- Output Assignments / 输出分配
  config_out <= config_reg;
  config_valid_out <= config_valid_reg;
  config_error_out <= config_error_reg;
  config_ready_out <= ready_reg;
  
  -- Check if all required configuration received / 检查是否接收到所有必需配置
  config_complete <= values_received_reg(N_CONFIG_WORDS-1) and 
                     and_reduce(values_received_reg(N_CONFIG_WORDS-2 downto 0));

  --! FSM Combinational Process / 状态机组合逻辑进程
  fsm_comb: process(current_state, config_valid_in, config_complete, clear, 
                   config_data_in, config_addr_in, values_received_reg, config_reg)
  variable temp_config: config_123_f;
  variable temp_values: std_logic_vector(N_CONFIG_WORDS-1 downto 0);
  begin
    -- Default assignments / 默认分配
    next_state <= current_state;
    config_next <= config_reg;
    values_received_next <= values_received_reg;
    config_valid_next <= '0';
    config_error_next <= '0';
    ready_next <= '0';
    
    temp_config := config_reg;
    temp_values := values_received_reg;
    
    case current_state is
      when IDLE =>
        ready_next <= '1';
        if config_valid_in = '1' then
          next_state <= RECEIVING;
          ready_next <= '0';
        end if;
        
      when RECEIVING =>
        -- Address decoding and data storage / 地址解码和数据存储
        case config_addr_in is
          when ADDR_CONTROL =>
            temp_config.BYPASS := config_data_in(0 downto 0);
            temp_config.ENCODER_SELECTION := config_data_in(4 downto 1);
            temp_config.DISABLE_HEADER := config_data_in(5 downto 5);
            temp_config.IS_SIGNED := config_data_in(6 downto 6);
            temp_config.ENDIANESS := config_data_in(7 downto 7);
            temp_values(0) := '1';
            
          when ADDR_NX =>
            temp_config.Nx := config_data_in(15 downto 0);
            temp_values(1) := '1';
            
          when ADDR_NY =>
            temp_config.Ny := config_data_in(15 downto 0);
            temp_values(2) := '1';
            
          when ADDR_NZ =>
            temp_config.Nz := config_data_in(15 downto 0);
            temp_values(3) := '1';
            
          when ADDR_D =>
            temp_config.D := config_data_in(4 downto 0);
            temp_config.W_BUFFER := config_data_in(11 downto 6);
            temp_values(4) := '1';
            
          when ADDR_P =>
            temp_config.P := config_data_in(3 downto 0);
            temp_config.PREDICTION := config_data_in(4 downto 4);
            temp_config.LOCAL_SUM := config_data_in(5 downto 5);
            temp_values(5) := '1';
            
          when ADDR_OMEGA =>
            temp_config.OMEGA := config_data_in(4 downto 0);
            temp_values(6) := '1';
            
          when ADDR_R =>
            temp_config.R := config_data_in(5 downto 0);
            temp_config.VMAX := config_data_in(9 downto 6);
            temp_config.VMIN := config_data_in(13 downto 10);
            temp_config.TINC := config_data_in(17 downto 14);
            temp_config.WEIGHT_INIT := config_data_in(18 downto 18);
            temp_values(7) := '1';
            
          when others =>
            -- Invalid address / 无效地址
            config_error_next <= '1';
            next_state <= ERROR_STATE;
        end case;
        
        config_next <= temp_config;
        values_received_next <= temp_values;
        
        -- Check if this was the enable command / 检查是否为使能命令
        if config_addr_in = ADDR_CONTROL and config_data_in(31) = '1' then
          next_state <= VALIDATE;
        else
          next_state <= IDLE;
        end if;
        
      when VALIDATE =>
        if config_complete = '1' then
          config_valid_next <= '1';
          next_state <= IDLE;
        else
          config_error_next <= '1';
          next_state <= ERROR_STATE;
        end if;
        
      when ERROR_STATE =>
        config_error_next <= '1';
        if clear = '1' then
          next_state <= IDLE;
        end if;
        
      when others =>
        next_state <= IDLE;
    end case;
    
    -- Clear override 
    if clear = '1' then
      next_state <= IDLE;
      values_received_next <= (others => '0');
      zero_config_var(temp_config);
      config_next <= temp_config;
      config_valid_next <= '0';
      config_error_next <= '0';
    end if;
    
  end process fsm_comb;

  --! Sequential Process 
  fsm_seq: process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      current_state <= IDLE;
      zero_config(config_reg);
      values_received_reg <= (others => '0');
      config_valid_reg <= '0';
      config_error_reg <= '0';
      ready_reg <= '1';
      
    elsif rising_edge(clk) then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE = 1)) then
        current_state <= IDLE;
        zero_config(config_reg);
        values_received_reg <= (others => '0');
        config_valid_reg <= '0';
        config_error_reg <= '0';
        ready_reg <= '1';
      else
        current_state <= next_state;
        config_reg <= config_next;
        values_received_reg <= values_received_next;
        config_valid_reg <= config_valid_next;
        config_error_reg <= config_error_next;
        ready_reg <= ready_next;
      end if;
    end if;
  end process fsm_seq;

end rtl;