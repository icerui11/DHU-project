--============================================================================--
-- CCSDS123 Configuration Transmitter Module with FSM
-- Reads configuration from RAM and transmits via handshake protocol
--============================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
use shyloc_123.ccsds123_constants.all;    
use shyloc_123.config123_package.all;

entity ccsds123_config_tx is
  generic (
    RESET_TYPE: integer := 1;  --! Reset Flavour (1) synchronous (0) asynchronous
    RAM_DEPTH: integer := 8    --! RAM depth for configuration storage (8 words = 6 config + 2 spare)
  );
  port (
    rst_n       : in  std_logic;                        --! Reset signal. Active low.
    clk         : in  std_logic;                        --! Clock signal.
    
    -- Control Interface
    awaiting_config : in  std_logic;                    --! Signal from CCSDS123 core indicating waiting for config
    start_tx        : in  std_logic;                    --! Start transmission trigger
    tx_complete     : out std_logic;                    --! Transmission complete flag
    tx_error        : out std_logic;                    --! Transmission error flag
    
    -- RAM Interface for Configuration Storage
    ram_addr        : out std_logic_vector(2 downto 0); --! RAM address (3 bits for 8 words)
    ram_data        : in  std_logic_vector(31 downto 0); --! RAM data input
    ram_read_en     : out std_logic;                    --! RAM read enable
    write_disable   : out std_logic;                    --! Disable write to RAM during transmission
    
    -- Handshake Configuration Interface (to CCSDS123 RX)
    config_data : out std_logic_vector(31 downto 0); --! 32-bit configuration data output
    config_addr : out std_logic_vector(2 downto 0);  --! Configuration address (3 bits for 8 words)   
    tx_valid : out std_logic;                        --! Valid signal for configuration data
    tx_ready : in  std_logic                         --! Ready signal from receiver
  );
end ccsds123_config_tx;

architecture fsm of ccsds123_config_tx is

  -- FSM states for transmission control
  type tx_state_type is (
    IDLE,           -- Waiting for start trigger
 --   CHECK_READY,    -- Check if receiver is ready
    READ_RAM,       -- Read data from RAM
    TRANSMIT,       -- Transmit data to receiver
    WAIT_ACK,       -- Wait for acknowledgment
    NEXT_WORD,      -- Move to next configuration word
    COMPLETE,       -- Transmission complete
    ERROR_STATE     -- Error state
  );
  
  signal tx_state_cur, tx_state_next: tx_state_type;
  
  -- Internal registers
  signal word_count_reg, word_count_cmb: unsigned(2 downto 0);
  signal ram_addr_reg, ram_addr_cmb: std_logic_vector(2 downto 0);
  signal config_data_reg, config_data_cmb: std_logic_vector(31 downto 0);
  signal config_valid_reg, config_valid_cmb: std_logic;
  signal ram_read_en_reg, ram_read_en_cmb: std_logic;
  signal tx_complete_reg, tx_complete_cmb: std_logic;
  signal tx_error_reg, tx_error_cmb: std_logic;

  signal en_config: std_logic;             -- Enable signal for transmit CFG from RAM
  signal write_disable_reg: std_logic;     -- Disable write to RAM during transmission
  signal cfg_count: unsigned(2 downto 0);  -- Counter for configuration addresses
  signal config_data_reg : std_logic_vector(31 downto 0); -- Register for configuration data
  signal config_addr_reg : std_logic_vector(2 downto 0);  -- Register for configuration address
  signal tx_valid_reg : std_logic;                        -- Register for transmit valid signal
   
  -- Timeout counter for error detection
  signal timeout_count_reg, timeout_count_cmb: unsigned(15 downto 0);
  constant TIMEOUT_LIMIT: unsigned(15 downto 0) := x"FFFF";
  
  -- Total number of configuration words to transmit
  constant TOTAL_CONFIG_WORDS: unsigned(2 downto 0) := to_unsigned(N_CONFIG_WORDS, 6);

begin

  -- Output assignments
  ram_addr <= ram_addr_reg;

  config_data_out <= config_data_reg;
  config_valid_out <= config_valid_reg;
  tx_complete <= tx_complete_reg;
  tx_error <= tx_error_reg;

  write_disable <= write_disable_reg;                -- Disable RAM write during transmission
  
  process (clk, rst_n)
    begin
    if (rst_n = '0') then
        tx_state_cur <= IDLE;  -- Reset state to IDLE

        elsif (clk'event and clk = '1') then
        tx_state_cur <= tx_state_next;  -- Update state on clock edge
        end if;
   end process;
  --tx channel fsm combinational logic
  comb_tx: process(awaiting_config, en_config, cfg_count)

  begin
    tx_state_next <= tx_state_cur;  

    case tx_state_cur is 
        when IDLE =>
            if (awaiting_config = '1' and en_config = '1') then 
                tx_state_next <= READ_RAM;
                
            end if;

        when READ_RAM =>
            


        when TRANSMIT =>
            if en_config = '1' then
                if cfg_count <= TOTAL_CONFIG_WORDS-1 then         
                    tx_state_next <= TRANSMIT;  -- Read next addr from RAM (0 to 5)
                else
                    tx_state_next <= TRANSMIT;  -- All words transmitted, go to COMPLETE
                end if;
            else
                tx_state_next <= IDLE;  -- If not ready, go back to IDLE
            end if;

        when COMPLETE =>
            tx_state_next <= IDLE;  -- After complete, go back to IDLE

        when others =>
            tx_state_next <= IDLE;  -- Default case, reset to IDLE
    end case;
  end process comb_tx;
        
 -- ram_read_en <= '1' when tx_state_cur = TRANSMIT else '0';  -- Enable RAM read only in TRANSMIT state
 -- cfg_count <= cfg_count + 1 when tx_state_cur = TRANSMIT else (others => '0');  -- Increment cfg_count in TRANSMIT state
  ram_addr <= std_logic_vector(cfg_count);  -- Set RAM address based on cfg_count
  write_disable_reg <= '0' when tx_state_cur = IDLE else '1';  -- Disable RAM write when in into transfer state

  -- Read RAM counter
  process(clk,rst_n)
    begin
        if (rst_n = '0') then
            cfg_count <= (others => '0');  -- Reset counter to 0
            ram_read_en <= '0';            -- Disable RAM read on reset
        elsif (clk'event and clk = '1') then
            if tx_state_cur = TRANSMIT then
                cfg_count <= cfg_count + 1;  -- Increment counter in TRANSMIT state
                ram_read_en <= '1';
            end if;
        end if;
    end process;
  -----------------------------------------------------------------------------
  --! Combinational logic for FSM and control
  -----------------------------------------------------------------------------
  comb_tx: process(tx_state_reg, awaiting_config, start_tx, config_ready_in, ram_data,
                   word_count_reg, ram_addr_reg, config_data_reg, config_valid_reg,
                   ram_read_en_reg, tx_complete_reg, tx_error_reg, timeout_count_reg)
    variable tx_state_v: tx_state_type;
    variable word_count_v: unsigned(2 downto 0);
    variable ram_addr_v: std_logic_vector(2 downto 0);
    variable config_data_v: std_logic_vector(31 downto 0);
    variable config_valid_v: std_logic;
    variable ram_read_en_v: std_logic;
    variable tx_complete_v: std_logic;
    variable tx_error_v: std_logic;
    variable timeout_count_v: unsigned(15 downto 0);
  begin
    -- Default assignments
    tx_state_v := tx_state_reg;
    word_count_v := word_count_reg;
    ram_addr_v := ram_addr_reg;
    config_data_v := config_data_reg;
    config_valid_v := config_valid_reg;
    ram_read_en_v := ram_read_en_reg;
    tx_complete_v := tx_complete_reg;
    tx_error_v := tx_error_reg;
    timeout_count_v := timeout_count_reg;
    
    case tx_state_reg is
      when IDLE =>
        config_valid_v := '0';
        ram_read_en_v := '0';
        tx_complete_v := '0';
        tx_error_v := '0';
        word_count_v := (others => '0');
        ram_addr_v := (others => '0');
        timeout_count_v := (others => '0');
        
        -- Start transmission when awaiting_config is high and start_tx is triggered
        if awaiting_config = '1' and start_tx = '1' then
          tx_state_v := CHECK_READY;
        end if;
        
      when CHECK_READY =>
        config_valid_v := '0';
        ram_read_en_v := '0';
        
        -- Check if receiver is ready to accept data
        if config_ready_in = '1' then
          tx_state_v := READ_RAM;
          ram_addr_v := std_logic_vector(word_count_reg);
        else
          -- Increment timeout counter
          timeout_count_v := timeout_count_reg + 1;
          if timeout_count_reg >= TIMEOUT_LIMIT then
            tx_state_v := ERROR_STATE;
            tx_error_v := '1';
          end if;
        end if;
        
      when READ_RAM =>
        ram_read_en_v := '1';
        ram_addr_v := std_logic_vector(word_count_reg);
        tx_state_v := TRANSMIT;
        timeout_count_v := (others => '0');
        
      when TRANSMIT =>
        ram_read_en_v := '0';
        config_data_v := ram_data;  -- Latch RAM data
        config_valid_v := '1';      -- Assert valid signal
        
        if config_ready_in = '1' then
          tx_state_v := WAIT_ACK;
        else
          -- Increment timeout counter
          timeout_count_v := timeout_count_reg + 1;
          if timeout_count_reg >= TIMEOUT_LIMIT then
            tx_state_v := ERROR_STATE;
            tx_error_v := '1';
          end if;
        end if;
        
      when WAIT_ACK =>
        config_valid_v := '0';  -- Deassert valid after acknowledgment
        tx_state_v := NEXT_WORD;
        
      when NEXT_WORD =>
        -- Move to next configuration word
        word_count_v := word_count_reg + 1;
        
        -- Check if all words transmitted
        if word_count_reg >= TOTAL_CONFIG_WORDS - 1 then
          tx_state_v := COMPLETE;
          tx_complete_v := '1';
        else
          tx_state_v := CHECK_READY;
        end if;
        
      when COMPLETE =>
        config_valid_v := '0';
        ram_read_en_v := '0';
        tx_complete_v := '1';
        -- Stay in complete state until reset or new transmission
        
      when ERROR_STATE =>
        config_valid_v := '0';
        ram_read_en_v := '0';
        tx_error_v := '1';
        -- Stay in error state until reset
        
      when others =>
        tx_state_v := IDLE;
    end case;
    
    -- Drive combinational outputs
    tx_state_cmb <= tx_state_v;
    word_count_cmb <= word_count_v;
    ram_addr_cmb <= ram_addr_v;
    config_data_cmb <= config_data_v;
    config_valid_cmb <= config_valid_v;
    ram_read_en_cmb <= ram_read_en_v;
    tx_complete_cmb <= tx_complete_v;
    tx_error_cmb <= tx_error_v;
    timeout_count_cmb <= timeout_count_v;
  end process;

  -----------------------------------------------------------------------------
  --! Sequential logic for registers
  -----------------------------------------------------------------------------
  reg : process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      tx_state_reg <= IDLE;
      word_count_reg <= (others => '0');
      ram_addr_reg <= (others => '0');
      config_data_reg <= (others => '0');
      config_valid_reg <= '0';
      ram_read_en_reg <= '0';
      tx_complete_reg <= '0';
      tx_error_reg <= '0';
      timeout_count_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (rst_n = '0' and RESET_TYPE = 1) then
        tx_state_reg <= IDLE;
        word_count_reg <= (others => '0');
        ram_addr_reg <= (others => '0');
        config_data_reg <= (others => '0');
        config_valid_reg <= '0';
        ram_read_en_reg <= '0';
        tx_complete_reg <= '0';
        tx_error_reg <= '0';
        timeout_count_reg <= (others => '0');
      else
        tx_state_reg <= tx_state_cmb;
        word_count_reg <= word_count_cmb;
        ram_addr_reg <= ram_addr_cmb;
        config_data_reg <= config_data_cmb;
        config_valid_reg <= config_valid_cmb;
        ram_read_en_reg <= ram_read_en_cmb;
        tx_complete_reg <= tx_complete_cmb;
        tx_error_reg <= tx_error_cmb;
        timeout_count_reg <= timeout_count_cmb;
      end if;
    end if;
  end process;

end fsm;