--============================================================================--
-- CCSDS123 Configuration RX Module
-- Receives configuration parameters via handshake protocol
--== Filename ..... ccsds123_config_rx.vhd                                      ==--             
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... 01.06 2025                                            ==--
--============================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
use shyloc_123.ccsds123_constants.all;
use shyloc_123.config123_package.all;

library shyloc_utils;
use shyloc_utils.shyloc_functions.all;

--!@brief Configuration receiver module with handshake protocol
--!@details Receives 32-bit configuration data and assembles into config_123_f record
entity ccsds123_config_rx is
  generic (
    RESET_TYPE: integer := 1        --! Reset flavour (0) asynchronous (1) synchronous
  );
  port (
    clk: in std_logic;              --! Clock signal
    rst_n: in std_logic;            --! Reset signal. Active low
    clear: in std_logic;            --! Clear signal for registers
    
    -- RX Interface (Handshake protocol)
    rx_data: in std_logic_vector(31 downto 0);     --! 32-bit configuration data
    rx_valid: in std_logic;                         --! Data valid signal from TX
    rx_ready: out std_logic;                        --! Ready to receive data
    rx_addr: in std_logic_vector(3 downto 0);      --! Register address (0-15)
    rx_last: in std_logic;                          --! Last data in configuration sequence
    
    -- Configuration output
    config: out config_123_f;                       --! Configuration values received
    config_valid: out std_logic;                    --! Validates configuration once complete
    error: out std_logic                            --! Indicates error during reception
  );
end ccsds123_config_rx;

--!@brief Architecture definition of the ccsds123_config_rx entity
architecture rtl of ccsds123_config_rx is

  -- State machine for RX protocol
  type rx_state_type is (IDLE, RECEIVING, COMPLETE, ERROR_STATE);
  signal rx_state_reg, rx_state_next: rx_state_type;
  
  -- Configuration registers
  signal config_reg, config_next: config_123_f;
  
  -- Control signals
  signal ready_reg, ready_next: std_logic;
  signal valid_reg, valid_next: std_logic;
  signal error_reg, error_next: std_logic;
  
  -- Register tracking - which registers have been received
  signal registers_received_reg, registers_received_next: std_logic_vector(N_CONFIG_WORDS-1 downto 0);
  
  -- Internal signals
  signal all_registers_received: std_logic;
  signal valid_address: std_logic;
  
begin

  -- Output assignments
  rx_ready <= ready_reg;
  config <= config_reg;
  config_valid <= valid_reg;
  error <= error_reg;
  
  -- Check if all required registers have been received
  all_registers_received <= '1' when rx_config_complete(registers_received_reg) else '0';
  
  -- Address validation (0 to N_CONFIG_WORDS-1)
  valid_address <= '1' when to_integer(unsigned(rx_addr)) < N_CONFIG_WORDS else '0';
  
  --!@brief Combinational logic for state machine and register updates
  rx_comb_proc: process(rx_state_reg, rx_data, rx_valid, rx_addr, rx_last, 
                        config_reg, ready_reg, valid_reg, error_reg,
                        registers_received_reg, all_registers_received, valid_address)
    variable config_var: config_123_f;
    variable registers_var: std_logic_vector(N_CONFIG_WORDS-1 downto 0);
    variable error_var: std_logic;
    variable validation_error: std_logic;
    variable validation_error_code: std_logic_vector(3 downto 0);
  begin
    -- Default assignments
    rx_state_next <= rx_state_reg;
    config_next <= config_reg;
    ready_next <= ready_reg;
    valid_next <= valid_reg;
    error_next <= error_reg;
    registers_received_next <= registers_received_reg;
    
    -- Initialize variables
    config_var := config_reg;
    registers_var := registers_received_reg;
    error_var := '0';
    
    case rx_state_reg is
      when IDLE =>
        ready_next <= '1';
        valid_next <= '0';
        error_next <= '0';
        
        if rx_valid = '1' and valid_address = '1' then
          rx_state_next <= RECEIVING;
          ready_next <= '0';
          
          -- Use RX-specific configuration procedure
          rx_read_config_123(config_var, rx_data, rx_addr, registers_var, error_var);
          config_next <= config_var;
          registers_received_next <= registers_var;
          
          if error_var = '1' then
            rx_state_next <= ERROR_STATE;
            error_next <= '1';
          elsif rx_last = '1' then
            -- Check if all registers received using function
            if rx_config_complete(registers_var) then
              -- Validate the complete configuration
              rx_validate_config(config_var, validation_error, validation_error_code);
              if validation_error = '0' then
                rx_state_next <= COMPLETE;
                valid_next <= '1';
              else
                rx_state_next <= ERROR_STATE;
                error_next <= '1';
              end if;
            else
              rx_state_next <= ERROR_STATE;
              error_next <= '1';
            end if;
          end if;
        elsif rx_valid = '1' and valid_address = '0' then
          rx_state_next <= ERROR_STATE;
          error_next <= '1';
        end if;
        
      when RECEIVING =>
        ready_next <= '1';
        
        if rx_valid = '1' and valid_address = '1' then
          -- Use RX-specific configuration procedure
          rx_read_config_123(config_var, rx_data, rx_addr, registers_var, error_var);
          config_next <= config_var;
          registers_received_next <= registers_var;
          
          if error_var = '1' then
            rx_state_next <= ERROR_STATE;
            error_next <= '1';
          elsif rx_last = '1' then
            -- Check if all registers received using function
            if rx_config_complete(registers_var) then
              -- Validate the complete configuration
              rx_validate_config(config_var, validation_error, validation_error_code);
              if validation_error = '0' then
                rx_state_next <= COMPLETE;
                valid_next <= '1';
              else
                rx_state_next <= ERROR_STATE;
                error_next <= '1';
              end if;
            else
              rx_state_next <= ERROR_STATE;
              error_next <= '1';
            end if;
          end if;
        elsif rx_valid = '1' and valid_address = '0' then
          rx_state_next <= ERROR_STATE;
          error_next <= '1';
        end if;
        
      when COMPLETE =>
        ready_next <= '0';
        valid_next <= '1';
        -- Stay in complete state until clear
        
      when ERROR_STATE =>
        ready_next <= '0';
        valid_next <= '0';
        error_next <= '1';
        -- Stay in error state until clear
        
      when others =>
        rx_state_next <= IDLE;
    end case;
  end process;
  
  --!@brief Sequential logic for registers
  rx_seq_proc: process(clk, rst_n)
    variable config_var: config_123_f;
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      rx_state_reg <= IDLE;
      rx_reset_config(config_var);
      config_reg <= config_var;
      ready_reg <= '1';
      valid_reg <= '0';
      error_reg <= '0';
      registers_received_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE = 1)) then
        rx_state_reg <= IDLE;
        rx_reset_config(config_var);
        config_reg <= config_var;
        ready_reg <= '1';
        valid_reg <= '0';
        error_reg <= '0';
        registers_received_reg <= (others => '0');
      else
        rx_state_reg <= rx_state_next;
        config_reg <= config_next;
        ready_reg <= ready_next;
        valid_reg <= valid_next;
        error_reg <= error_next;
        registers_received_reg <= registers_received_next;
      end if;
    end if;
  end process;

end rtl;