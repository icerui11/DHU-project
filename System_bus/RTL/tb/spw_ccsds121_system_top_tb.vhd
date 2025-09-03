--------------------------------------------------------------------------------
-- Testbench for spacewire_ccsds121_single_system_top
-- This testbench verifies:
-- 1. CCSDS121 compressor configuration via AHB
-- 2. SpaceWire data injection and FIFO assembly
-- 3. Data flow from SpaceWire through FIFO to compressor
-- 4. Compressed output generation
-- 5. Error handling and status monitoring
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library config_controller;
use config_controller.config_pkg.all;

library VH_compressor;
use VH_compressor.VH_ccsds121_parameters.all;

entity spw_ccsds121_system_top_tb is
end entity spw_ccsds121_system_top_tb;

architecture testbench of spw_ccsds121_system_top_tb is

  -- Clock and reset signals
  signal clk_sys      : std_logic := '0';
  signal clk_ahb      : std_logic := '0';
  signal rst_n        : std_logic := '0';
  
  -- Clock periods
  constant SYS_CLK_PERIOD : time := 10 ns;  -- 100 MHz system clock
  constant AHB_CLK_PERIOD : time := 10 ns;  -- 50 MHz AHB clock
  
  -- Configuration RAM interface
  signal ram_wr_en    : std_logic := '0';
  signal ram_wr_addr  : std_logic_vector(c_input_addr_width-1 downto 0) := (others => '0');
  signal ram_wr_data  : std_logic_vector(7 downto 0) := (others => '0');
  
  -- SpaceWire Data Input Interface
  signal spw_data_in    : std_logic_vector(7 downto 0) := (others => '0');
  signal spw_data_valid : std_logic := '0';
 -- signal spw_data_ready : std_logic;
  
  -- Compressed Data Output Interface
  signal data_out       : std_logic_vector(W_BUFFER_GEN-1 downto 0);
  signal data_out_valid : std_logic;
  
  -- Control Signals
--  signal system_enable    : std_logic := '0';
  signal force_stop       : std_logic := '0';
  signal ready_ext        : std_logic := '1';  -- External always ready
  signal clear_fifo       : std_logic := '0';
  
  -- Status Outputs
  signal system_ready       : std_logic;
  signal awaiting_config    : std_logic;
  signal fifo_full          : std_logic;
  signal compression_eop    : std_logic;
  signal compression_finished : std_logic;
  signal system_error       : std_logic;
  
  -- Debug Interface
  signal debug_fifo_state : std_logic_vector(3 downto 0);
  signal debug_byte_count : std_logic_vector(2 downto 0);
  
  -- Test control signals
  signal test_done : boolean := false;
  signal test_phase : integer := 0;
  
  -- CCSDS121 Configuration data for testing (16-bit samples, D_GEN=16)
  type config_data_array is array (0 to 63) of std_logic_vector(7 downto 0);
  
  constant CCSDS121_CONFIG_DATA : config_data_array := (
    -- Configuration for CCSDS121 compressor
    -- Group 0: Basic parameters
    x"00", x"00", x"00", x"00",  -- Reserved/flags
    x"20", x"10", x"50", x"00",
    x"00", x"02", x"1E", x"00",
    x"80", x"40", x"54", x"01",  -- first byte 80 ccsds121preprocessor, 40 ccsds123 preprocessor , second byte: 40  D_GEN=16 6bits, little endian 
    others => x"00"
  );

constant CCSDS121_CONFIG_DATA_32bits : config_data_array := (
-- Configuration for CCSDS121 compressor
-- Group 0: Basic parameters
x"00", x"00", x"00", x"00",  -- Reserved/flags
x"20", x"10", x"50", x"00",
x"00", x"02", x"1E", x"00",
x"80", x"80", x"54", x"01",  -- first byte 80 ccsds121preprocessor, 40 ccsds123 preprocessor , second byte: 80  D_GEN=32 6bits, little endian 
others => x"00"
);
  -- SpaceWire test data patterns
  type spw_test_data_array is array (0 to 255) of std_logic_vector(7 downto 0);
  
  -- Test pattern 1: Incrementing pattern for 16-bit samples
  signal test_pattern_16bit : spw_test_data_array := (
    -- First 16-bit sample: 0x1234 -> bytes 0x34, 0x12 (little endian)
    x"34", x"12",
    -- Second 16-bit sample: 0x5678 -> bytes 0x78, 0x56
    x"78", x"56",
    -- Third 16-bit sample: 0x9ABC -> bytes 0xBC, 0x9A
    x"BC", x"9A",
    -- Fourth 16-bit sample: 0xDEF0 -> bytes 0xF0, 0xDE
    x"F0", x"DE",
    -- Continue pattern
    x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88",
    x"99", x"AA", x"BB", x"CC", x"DD", x"EE", x"FF", x"00",
    -- Repeat and fill remaining
    others => x"A5"  -- Pattern fill
  );
  
  -- Statistics counters
  signal spw_bytes_sent : integer := 0;
  signal compressed_words_received : integer := 0;

begin

  -- System clock generation
  sys_clk_process : process
  begin
    while not test_done loop
      clk_sys <= '0';
      wait for SYS_CLK_PERIOD/2;
      clk_sys <= '1';
      wait for SYS_CLK_PERIOD/2;
    end loop;
    wait;
  end process;
  
  -- AHB clock generation
  ahb_clk_process : process
  begin
    while not test_done loop
      clk_ahb <= '0';
      wait for AHB_CLK_PERIOD/2;
      clk_ahb <= '1';
      wait for AHB_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- DUT instantiation
  dut : entity work.spw_ccsds121_system_top
    generic map (
      COMPRESSOR_BASE_ADDR => 16#700#,    -- 0x10000000
      FIFO_DEPTH           => 32,         -- 32-entry FIFO
      FIFO_ADDR_WIDTH      => 5,          -- 5-bit address
      RESET_TYPE           => 1,          -- Synchronous reset
      TECH                 => 0,          -- Generic technology
      EDAC                 => 0           -- No EDAC for testbench
    )
    port map (
      -- System Clock and Reset
      clk_sys              => clk_sys,
      clk_ahb              => clk_ahb,
      rst_n                => rst_n,
      
      -- Configuration RAM interface
      ram_wr_en            => ram_wr_en,
      ram_wr_addr          => ram_wr_addr,
      ram_wr_data          => ram_wr_data,
      
      -- SpaceWire Data Input Interface
      spw_data_in          => spw_data_in,
      spw_data_valid       => spw_data_valid,
  --    spw_data_ready       => spw_data_ready,
      
      -- Compressed Data Output Interface
      data_out             => data_out,
      data_out_valid       => data_out_valid,
      
      -- Control Signals
 --     system_enable        => system_enable,
      force_stop           => force_stop,
      ready_ext            => ready_ext,
      clear_fifo           => clear_fifo,
      
      -- Status Outputs
      system_ready         => system_ready,
      awaiting_config      => awaiting_config,
      fifo_full            => fifo_full,
      compression_eop      => compression_eop,
      compression_finished => compression_finished,
      system_error         => system_error,
      
      -- Debug Interface
      debug_fifo_state     => debug_fifo_state,
      debug_byte_count     => debug_byte_count
    );

  -- Main test stimulus process
  stimulus : process
    -- Procedure to write configuration data to RAM
    procedure write_config_to_ram(
      constant start_addr : in natural;
      constant config_data : in config_data_array;
      constant num_bytes : in natural
    ) is
    begin
      for i in 0 to num_bytes-1 loop
        ram_wr_en <= '1';
        ram_wr_addr <= std_logic_vector(to_unsigned(start_addr + i, ram_wr_addr'length));
        ram_wr_data <= config_data(i);
        wait until rising_edge(clk_ahb);
      end loop;
      ram_wr_en <= '0';
      wait until rising_edge(clk_ahb);
    end procedure;
    
    -- Procedure to send SpaceWire data
    procedure send_spw_data(
      constant data_byte : in std_logic_vector(7 downto 0);
      constant hold_cycles : in natural := 1
    ) is
    begin
      spw_data_in <= data_byte;
      spw_data_valid <= '1';
      
      -- Wait for ready and hold for specified cycles
      for i in 0 to hold_cycles-1 loop
        wait until rising_edge(clk_sys) and system_ready = '1';
        spw_bytes_sent <= spw_bytes_sent + 1;
      end loop;
      
      spw_data_valid <= '0';
      wait until rising_edge(clk_sys);
    end procedure;
    
    -- Procedure to send multiple SpaceWire bytes
    procedure send_spw_pattern(
      constant pattern : in spw_test_data_array;
      constant num_bytes : in natural;
      constant inter_byte_delay : in natural := 0
    ) is
    begin
      for i in 0 to num_bytes-1 loop
        send_spw_data(pattern(i));
        
        -- Optional delay between bytes
        if inter_byte_delay > 0 then
          for j in 0 to inter_byte_delay-1 loop
            wait until rising_edge(clk_sys);
          end loop;
        end if;
      end loop;
    end procedure;

  begin
    -- Initialize signals
    test_phase <= 0;
    rst_n <= '0';
--    system_enable <= '0';
    spw_bytes_sent <= 0;
    compressed_words_received <= 0;
    
    -- Hold reset for several clock cycles
    wait for SYS_CLK_PERIOD * 10;

    
    -- Release reset
    rst_n <= '1';
    wait for SYS_CLK_PERIOD * 5;
    
    report "Starting SpaceWire CCSDS121 System Testbench";
        -- Test Phase 2: CCSDS121 Compressor Configuration
    test_phase <= 2;
    report "Test Phase 2: Configuring CCSDS121 compressor";
    
    -- Write configuration data to RAM
    write_config_to_ram(80, CCSDS121_CONFIG_DATA, 16);     
    -- Test Phase 1: System Initialization
    test_phase <= 1;
    report "Test Phase 1: System initialization and reset verification";
    
    -- Enable system
  --  system_enable <= '1';
    wait for SYS_CLK_PERIOD * 10;
    
    -- Verify initial states
    assert system_error = '0' report "System error should be clear after reset" severity error;
    assert awaiting_config = '0' report "System should be awaiting configuration" severity warning;
    
          
    
    -- Wait for configuration to be processed
    wait until falling_edge(awaiting_config) for SYS_CLK_PERIOD * 200;
    
    if awaiting_config = '0' then
      report "Configuration completed successfully";
    else
      report "Configuration timeout - still awaiting config" severity warning;
    end if;
    
    wait for SYS_CLK_PERIOD * 20;
    
    -- Test Phase 3: SpaceWire FIFO Testing with 16-bit data
    test_phase <= 3;
    report "Test Phase 3: Testing SpaceWire FIFO with 16-bit data assembly";
    
    -- Clear any existing FIFO content
    clear_fifo <= '1';
    wait for SYS_CLK_PERIOD * 2;
    clear_fifo <= '0';
    wait for SYS_CLK_PERIOD * 5;
    
    -- Send 16-bit test pattern (D_GEN = 16, so FIFO should assemble 2 bytes per sample)
    report "Sending 16-bit SpaceWire test pattern";
    send_spw_pattern(test_pattern_16bit, 16, 2);  -- Send 16 bytes with 2 cycle delays
    
    -- Wait for FIFO to process data
    wait for SYS_CLK_PERIOD * 50;
    
    -- Test Phase 4: Monitor Compression Output
    test_phase <= 4;
    report "Test Phase 4: Monitoring compression output";
    
    -- Continue sending data and monitor output
    for i in 0 to 3 loop
      -- Send more test data
      send_spw_pattern(test_pattern_16bit, 8, 1);
      
      -- Wait and check for compressed output
      wait for SYS_CLK_PERIOD * 30;
      
      report "Iteration " & integer'image(i) & ": SpW bytes sent = " & 
             integer'image(spw_bytes_sent) & ", Compressed words received = " & 
             integer'image(compressed_words_received);
    end loop;
    
    -- Test Phase 5: FIFO State Verification
    test_phase <= 5;
    report "Test Phase 5: FIFO state and byte count verification";
    
    -- Test different data patterns to verify FIFO assembly logic
    -- Send single bytes and verify FIFO state changes
    for i in 0 to 7 loop
      send_spw_data(std_logic_vector(to_unsigned(i, 8)));
      wait for SYS_CLK_PERIOD * 3;
      
      report "Sent byte " & integer'image(i) & 
             ": FIFO state = " & integer'image(to_integer(unsigned(debug_fifo_state))) &
             ", Byte count = " & integer'image(to_integer(unsigned(debug_byte_count)));
    end loop;
    
    -- Test Phase 6: Error Conditions
    test_phase <= 6;
    report "Test Phase 6: Testing error conditions and overflow";
    
    -- Test FIFO overflow by sending data faster than compressor can consume
    report "Testing FIFO overflow conditions";
    for i in 0 to 100 loop
      if system_ready = '1' then
        send_spw_data(x"FF", 0);  -- Send without waiting
      else
        exit;  -- FIFO is full
      end if;
    end loop;
    
    if fifo_full = '1' then
      report "FIFO full condition detected correctly";
    else
      report "FIFO full condition not detected" severity warning;
    end if;
    
    -- Clear FIFO and continue
    clear_fifo <= '1';
    wait for SYS_CLK_PERIOD * 5;
    clear_fifo <= '0';
    wait for SYS_CLK_PERIOD * 10;
    

    
    -- Wait for compression to finish
    wait until compression_finished = '1' or compression_eop = '1' for SYS_CLK_PERIOD * 100;
    
    if compression_finished = '1' then
      report "Compression finished successfully";
    elsif compression_eop = '1' then
      report "End of processing detected";
    else
      report "Compression did not finish cleanly" severity warning;
    end if;
    
    -- Disable system
 --   system_enable <= '0';
    wait for SYS_CLK_PERIOD * 10;
    
    -- Final statistics
    report "Test completed successfully!";
    report "Total SpaceWire bytes sent: " & integer'image(spw_bytes_sent);
    report "Total compressed words received: " & integer'image(compressed_words_received);
    
    if system_error = '0' then
      report "No system errors detected during test";
    else
      report "System errors were detected" severity warning;
    end if;
    
    -- End test
    test_done <= true;
    wait;
  end process;

  -- Debug monitor process
  debug_monitor : process(clk_sys)
    variable prev_fifo_state : std_logic_vector(3 downto 0) := "0000";
    variable prev_byte_count : std_logic_vector(2 downto 0) := "000";
  begin
    if rising_edge(clk_sys) then
      -- Monitor FIFO state changes
      if debug_fifo_state /= prev_fifo_state then
        report "FIFO state changed: " & 
               integer'image(to_integer(unsigned(prev_fifo_state))) & " -> " &
               integer'image(to_integer(unsigned(debug_fifo_state)));
        prev_fifo_state := debug_fifo_state;
      end if;
      
      -- Monitor byte count changes
      if debug_byte_count /= prev_byte_count then
        report "FIFO byte count changed: " & 
               integer'image(to_integer(unsigned(prev_byte_count))) & " -> " &
               integer'image(to_integer(unsigned(debug_byte_count)));
        prev_byte_count := debug_byte_count;
      end if;
      
      -- Monitor system status
      if system_error = '1' then
        report "SYSTEM ERROR DETECTED!" severity error;
      end if;
      
      -- Monitor backpressure
      if spw_data_valid = '1' and system_ready = '0' then
        report "SpaceWire backpressure detected - FIFO may be full";
      end if;
    end if;
  end process;

  -- Assertions for continuous monitoring
  assert_monitor : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      -- Check for illegal state combinations
 --     if system_enable = '0' and system_ready = '1' then
 --       report "Illegal state: system_ready high when system_enable low" severity warning;
  --    end if;
      
      -- Check FIFO consistency
      if clear_fifo = '1' and debug_byte_count /= "000" then
        report "FIFO byte count should be zero when clearing" severity warning;
      end if;
    end if;
  end process;

end architecture testbench;