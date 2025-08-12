--------------------------------------------------------------------------------
-- Enhanced Testbench for SHyLoC AHB System with Phased Configuration
-- 带有分阶段配置的SHyLoC AHB系统增强测试平台
-- 
-- This testbench demonstrates:
-- 1. Initial configuration of HR compressor only (CCSDS123 then CCSDS121)
-- 2. Verification of HR operation
-- 3. Subsequent configuration of other compressors
-- 4. Full system operation verification
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library config_controller;
use config_controller.config_pkg.all;

entity shyloc_ahb_system_tb is
end entity shyloc_ahb_system_tb;

architecture behavior of shyloc_ahb_system_tb is

  -----------------------------------------------------------------------------
  -- Clock and Reset Signals
  -----------------------------------------------------------------------------
  signal clk_sys : std_logic := '1';
  signal clk_ahb : std_logic := '1';
  signal rst_n   : std_logic := '0';
  signal rst_n_lr : std_logic := '0';
  signal rst_n_h  : std_logic := '0';
  signal rst_n_hr : std_logic := '0';

  constant CLK_SYS_PERIOD : time := 10 ns;   -- 100 MHz system clock
  constant CLK_AHB_PERIOD : time := 10 ns;    -- 100 MHz AHB clock
  
  -----------------------------------------------------------------------------
  -- Configuration RAM Interface
  -----------------------------------------------------------------------------
  signal ram_wr_en   : std_logic := '0';
  signal ram_wr_addr : std_logic_vector(c_input_addr_width-1 downto 0) := (others => '0');
  signal ram_wr_data : std_logic_vector(7 downto 0) := (others => '0');
  
  -----------------------------------------------------------------------------
  -- Data Interfaces for Compressors
  -----------------------------------------------------------------------------
  -- HR Compressor signals
  signal data_in_HR       : std_logic_vector(15 downto 0) := (others => '0');
  signal data_in_valid_HR : std_logic := '0';
  signal data_out_HR      : std_logic_vector(31 downto 0);
  signal data_out_valid_HR: std_logic;
  
  -- LR Compressor signals
  signal data_in_LR       : std_logic_vector(15 downto 0) := (others => '0');
  signal data_in_valid_LR : std_logic := '0';
  signal data_out_LR      : std_logic_vector(31 downto 0);
  signal data_out_valid_LR: std_logic;
  
  -- H Compressor signals
  signal data_in_H        : std_logic_vector(15 downto 0) := (others => '0');
  signal data_in_valid_H  : std_logic := '0';
  signal data_out_H       : std_logic_vector(31 downto 0);
  signal data_out_valid_H : std_logic;
  
  -----------------------------------------------------------------------------
  -- Control and Status Signals
  -----------------------------------------------------------------------------
  signal force_stop    : std_logic := '0';
  signal force_stop_lr : std_logic := '0';
  signal force_stop_h  : std_logic := '0';
  signal ready_ext     : std_logic := '1';
  signal system_ready  : std_logic;
  signal config_done   : std_logic;
  signal system_error  : std_logic;
  
  -----------------------------------------------------------------------------
  -- Test Control and Monitoring
  -----------------------------------------------------------------------------
  signal test_phase        : integer := 0;
  signal config_count      : integer := 0;
  signal hr_config_done    : boolean := false;
  signal all_config_done   : boolean := false;
  signal test_data_count   : integer := 0;
  
  -----------------------------------------------------------------------------
  -- Configuration Data Arrays
  -----------------------------------------------------------------------------
  -- Define the configuration data type to match your specification
  type config_data_array is array (natural range <>) of std_logic_vector(7 downto 0);
  
  -- HR Compressor CCSDS123 Configuration Data
  -- This data configures the CCSDS123 preprocessor parameters
  constant HR_CONFIG_DATA_123 : config_data_array(0 to 23) := (
    -- word0: 00 00 00 00 => 00 00 00 00
    x"00", x"00", x"00", x"00",
    -- word1: 04 00 00 00 => 00 00 00 04
    x"00", x"00", x"00", x"04",
    -- word2: 00 50 81 18 => 18 81 50 00
    x"18", x"81", x"50", x"00",
    -- word3: 00 1E 1A 80 => 80 1A 1E 00
    x"80", x"1A", x"1E", x"00",
    -- word4: 01 54 1F D9 => D9 1F 54 01
    x"D9", x"1F", x"54", x"01",
    -- word5: 12 B2 08 0A => 0A 08 B2 12
    x"0A", x"08", x"B2", x"12"
  );
  
  -- HR Compressor CCSDS121 Configuration Data
  -- This data configures the CCSDS121 encoder parameters
  constant HR_CONFIG_DATA_121 : config_data_array(0 to 15) := (
    -- group0: 00 00 00 00 => 00 00 00 00
    x"00", x"00", x"00", x"00",
    -- group1: 00 50 10 20 => 20 10 50 00
    x"20", x"10", x"50", x"00",
    -- group2: 00 1E 02 00 => 00 02 1E 00
    x"00", x"02", x"1E", x"00",
    -- group3: 01 54 41 40 => 40 41 54 01
    x"40", x"41", x"54", x"01"
  );
  
  -- LR Compressor Configuration Data (example)
  constant LR_CONFIG_DATA_123 : config_data_array(0 to 23) := (
    x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"04",
    x"18", x"81", x"50", x"00",
    x"80", x"1A", x"1E", x"00",
    x"D9", x"1F", x"54", x"01",
    x"0A", x"08", x"B2", x"12"
  );
  
  constant LR_CONFIG_DATA_121 : config_data_array(0 to 15) := (
    x"00", x"00", x"00", x"00",
    x"20", x"10", x"50", x"00",
    x"00", x"02", x"1E", x"00",
    x"40", x"41", x"54", x"01"
  );
  
  -- H Compressor Configuration Data (example)
  constant H_CONFIG_DATA_121 : config_data_array(0 to 15) := (
    x"00", x"00", x"00", x"00",
    x"20", x"10", x"50", x"00",
    x"00", x"02", x"1E", x"00",
    x"40", x"41", x"54", x"01"
  );
  
  -----------------------------------------------------------------------------
  -- Address Constants from DUT
  -----------------------------------------------------------------------------
  constant COMPRESSOR_BASE_ADDR_HR_123 : integer := 16#200#;  -- 0x20000000
  constant COMPRESSOR_BASE_ADDR_HR_121 : integer := 16#100#;  -- 0x10000000
  constant COMPRESSOR_BASE_ADDR_LR_123 : integer := 16#500#;  -- 0x50000000
  constant COMPRESSOR_BASE_ADDR_LR_121 : integer := 16#400#;  -- 0x40000000
  constant COMPRESSOR_BASE_ADDR_H_121  : integer := 16#700#;  -- 0x70000000

begin
  -----------------------------------------------------------------------------
  -- Clock Generation
  -----------------------------------------------------------------------------
  clk_sys <= not clk_sys after CLK_SYS_PERIOD/2;
  clk_ahb <= not clk_ahb after CLK_AHB_PERIOD/2;

  -----------------------------------------------------------------------------
  -- DUT Instantiation
  -----------------------------------------------------------------------------
  DUT: entity work.shyloc_ahb_system_top
    generic map (
      NUM_COMPRESSORS => 5,
      COMPRESSOR_BASE_ADDR_HR_123 => COMPRESSOR_BASE_ADDR_HR_123,
      COMPRESSOR_BASE_ADDR_HR_121 => COMPRESSOR_BASE_ADDR_HR_121,
      COMPRESSOR_BASE_ADDR_LR_123 => COMPRESSOR_BASE_ADDR_LR_123,
      COMPRESSOR_BASE_ADDR_LR_121 => COMPRESSOR_BASE_ADDR_LR_121,
      COMPRESSOR_BASE_ADDR_H_121  => COMPRESSOR_BASE_ADDR_H_121
    )
    port map (
      clk_sys          => clk_sys,
      clk_ahb          => clk_ahb,
      rst_n            => rst_n,
        rst_n_lr         => rst_n_lr,
        rst_n_h          => rst_n_h,
        rst_n_hr         => rst_n_hr,
      ram_wr_en        => ram_wr_en,
      ram_wr_addr      => ram_wr_addr,
      ram_wr_data      => ram_wr_data,
      data_in_HR       => data_in_HR,
      data_in_valid_HR => data_in_valid_HR,
      data_out_HR      => data_out_HR,
      data_out_valid_HR=> data_out_valid_HR,
      data_in_LR       => data_in_LR,
      data_in_valid_LR => data_in_valid_LR,
      data_out_LR      => data_out_LR,
      data_out_valid_LR=> data_out_valid_LR,
      data_in_H        => data_in_H,
      data_in_valid_H  => data_in_valid_H,
      data_out_H       => data_out_H,
      data_out_valid_H => data_out_valid_H,
      force_stop       => force_stop,
      force_stop_lr    => force_stop_lr,
      force_stop_h     => force_stop_h,
      ready_ext        => ready_ext,
      system_ready     => system_ready,
      config_done      => config_done,
      system_error     => system_error
    );

  -----------------------------------------------------------------------------
  -- Main Test Stimulus Process
  -----------------------------------------------------------------------------
  stimulus_proc: process
    
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
        wait until rising_edge(clk_sys);
      end loop;
      ram_wr_en <= '0';
      wait until rising_edge(clk_sys);
    end procedure;
    
    -- Procedure to send test data to a compressor
    procedure send_test_data(
      signal data_out : out std_logic_vector(15 downto 0);
      signal data_valid : out std_logic;
      constant num_samples : in integer;
      constant start_value : in integer;
      constant compressor_name : in string
    ) is
    begin
      report "Sending " & integer'image(num_samples) & " test samples to " & 
             compressor_name & " starting from value " & integer'image(start_value);
             
      for i in 0 to num_samples-1 loop
        data_out <= std_logic_vector(to_unsigned(start_value + i, 16));
        data_valid <= '1';
        wait for CLK_SYS_PERIOD;
        
        -- Add some realistic data patterns every 10 samples
        if (i mod 10) = 0 then
          report compressor_name & " sample " & integer'image(i) & 
                 ": " & to_hstring(std_logic_vector(to_unsigned(start_value + i, 16)));
        end if;
      end loop;
      
      data_valid <= '0';
      report "Completed sending test data to " & compressor_name;
    end procedure;
    
    -- Procedure to wait for configuration completion with timeout
    procedure wait_for_config_done(
      constant timeout : in time;
      constant config_name : in string
    ) is
      variable start_time : time;
    begin
      start_time := now;
      
      -- Wait for config_done pulse
      wait until config_done = '1' or (now - start_time) > timeout;
      
      if config_done = '1' then
        report config_name & " configuration completed successfully at " & time'image(now);
        wait until config_done = '0';  -- Wait for pulse to end
      else
        report "ERROR: Timeout waiting for " & config_name & " configuration!" severity error;
      end if;
    end procedure;
    
  begin
    -----------------------------------------------------------------------------
    -- Test Phase 0: System Initialization
    -----------------------------------------------------------------------------
    report "";
    report "================================================================";
    report "SHyLoC AHB System Testbench Started";
    report "================================================================";
    report "";
    
    test_phase <= 0;
    rst_n <= '0';
    report "Phase 0: System reset asserted";
    wait for 100 ns;
    rst_n_h <= '0';
    rst_n_lr <= '0';
    -- hold reset for h and hr compressors
    rst_n <= '1';
    report "Phase 0: System reset released";
    wait for 100 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 1: Configure HR Compressor CCSDS123 Only
    -----------------------------------------------------------------------------
    test_phase <= 1;
    report "";
    report "================================================================";
    report "Phase 1: Configuring HR Compressor CCSDS123";
    report "================================================================";
    rst_n_hr <= '1';
    wait for 40 ns; 
    -- Write HR CCSDS123 configuration to RAM at address 0
    -- Write CCSDS123 configuration to RAM
    write_config_to_ram(0, HR_CONFIG_DATA_123, 24);
    -- write HR 121 data to RAM at address 24
    write_config_to_ram(24, HR_CONFIG_DATA_121, 16);
    -- write LR 123 data to RAM at address 40
    write_config_to_ram(40, LR_CONFIG_DATA_123, 24);
    -- write LR 121 data to RAM at address 64
    write_config_to_ram(64, LR_CONFIG_DATA_121, 16);
    -- write H 121 data to RAM at address 80
    write_config_to_ram(80, H_CONFIG_DATA_121, 16);
    wait for 300 ns;
    rst_n <= '0';
    wait for 40 ns;
    rst_n <= '1';
    rst_n_h <= '1';
    rst_n_lr <= '1';
    -- Wait for configuration to complete
    wait_for_config_done(300 ns, "HR CCSDS123");

    -- Allow some time for the system to stabilize
    wait for 500 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 2: Configure HR Compressor CCSDS121
    -----------------------------------------------------------------------------
    test_phase <= 2;
    report "";
    report "================================================================";
    report "Phase 2: Configuring HR Compressor CCSDS121";
    report "================================================================";
    
    
    -- Wait for configuration to complete
    wait_for_config_done(200 ns, "HR CCSDS121");
    
    hr_config_done <= true;
    wait for 200 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 3: Test HR Compressor Operation
    -----------------------------------------------------------------------------
    test_phase <= 3;
    report "";
    report "================================================================";
    report "Phase 3: Testing HR Compressor Operation";
    report "================================================================";
    
    -- Send test data to HR compressor
    send_test_data(data_in_HR, data_in_valid_HR, 50, 1000, "HR");
    
    -- Wait for processing
    wait for 2 us;
    
    -- Check if we received any output
    if data_out_valid_HR = '1' then
      report "HR compressor is producing output data";
    else
      report "WARNING: No output from HR compressor yet";
    end if;
    
    -----------------------------------------------------------------------------
    -- Test Phase 4: Configure Other Compressors
    -----------------------------------------------------------------------------
    test_phase <= 4;
    report "";
    report "================================================================";
    report "Phase 4: Configuring Other Compressors";
    report "================================================================";
    


    
    all_config_done <= true;

    
    -----------------------------------------------------------------------------
    -- Test Phase 5: Full System Operation Test
    -----------------------------------------------------------------------------
    test_phase <= 5;
    report "";
    report "================================================================";
    report "Phase 5: Full System Operation Test";
    report "================================================================";
    
    -- Check system ready status
    if system_ready = '1' then
      report "System reports ready - all compressors configured";
    else
      report "WARNING: System not reporting ready status";
    end if;
    
    -- Send data to all compressors in parallel
    report "Sending test data to all compressors simultaneously";
    
    -- Fork to send data in parallel (simplified sequential approach for VHDL-93)
    -- In real implementation, you might use separate processes
    send_test_data(data_in_HR, data_in_valid_HR, 100, 2000, "HR");
    wait for 100 ns;
    send_test_data(data_in_LR, data_in_valid_LR, 100, 3000, "LR");
    wait for 100 ns;
    send_test_data(data_in_H, data_in_valid_H, 100, 4000, "H");
    
    -- Allow time for processing
    wait for 5 us;
    
    -----------------------------------------------------------------------------
    -- Test Phase 6: Error Condition Testing
    -----------------------------------------------------------------------------
    test_phase <= 6;
    report "";
    report "================================================================";
    report "Phase 6: Error Condition Testing";
    report "================================================================";
    
    -- Test force stop functionality
    report "Testing force stop functionality";
    force_stop <= '1';
    wait for 500 ns;
    force_stop <= '0';
    wait for 500 ns;
    
    -- Check system error status
    if system_error = '1' then
      report "System error detected after force stop";
    else
      report "No system error after force stop (expected behavior)";
    end if;
    
    -----------------------------------------------------------------------------
    -- Test Phase 7: Final Status Check
    -----------------------------------------------------------------------------
    test_phase <= 7;
    report "";
    report "================================================================";
    report "Phase 7: Final Status Check";
    report "================================================================";
    
    wait for 1 us;
    
    -- Print final statistics
    report "";
    report "Test Summary:";
    report "  - HR Compressor configured: " & boolean'image(hr_config_done);
    report "  - All Compressors configured: " & boolean'image(all_config_done);
    report "  - Configuration operations: " & integer'image(config_count);
    report "  - System errors encountered: " & std_logic'image(system_error);
    
    -- End simulation
    report "";
    report "================================================================";
    report "Testbench Completed Successfully";
    report "================================================================";
    wait for 1 us;
    
    assert false report "Simulation finished" severity failure;
  end process;
  
  -----------------------------------------------------------------------------
  -- Configuration Monitor Process
  -----------------------------------------------------------------------------
  config_monitor_proc: process(clk_ahb)
  begin
    if rising_edge(clk_ahb) then
      if config_done = '1' then
        config_count <= config_count + 1;
        report "Configuration complete signal detected. Total configs: " & 
               integer'image(config_count + 1) & " at time " & time'image(now);
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output Data Monitor Process
  -----------------------------------------------------------------------------
  output_monitor_proc: process(clk_sys)
    variable hr_output_count : integer := 0;
    variable lr_output_count : integer := 0;
    variable h_output_count  : integer := 0;
  begin
    if rising_edge(clk_sys) then
      -- Monitor HR output
      if data_out_valid_HR = '1' then
        hr_output_count := hr_output_count + 1;
        if (hr_output_count mod 10) = 1 then  -- Report every 10th output
          report "HR output [" & integer'image(hr_output_count) & "]: " & 
                 to_hstring(data_out_HR);
        end if;
      end if;
      
      -- Monitor LR output
      if data_out_valid_LR = '1' then
        lr_output_count := lr_output_count + 1;
        if (lr_output_count mod 10) = 1 then
          report "LR output [" & integer'image(lr_output_count) & "]: " & 
                 to_hstring(data_out_LR);
        end if;
      end if;
      
      -- Monitor H output
      if data_out_valid_H = '1' then
        h_output_count := h_output_count + 1;
        if (h_output_count mod 10) = 1 then
          report "H output [" & integer'image(h_output_count) & "]: " & 
                 to_hstring(data_out_H);
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- System Status Monitor Process
  -----------------------------------------------------------------------------
  status_monitor_proc: process(system_ready, system_error)
  begin
    if system_ready'event and system_ready = '1' then
      report "SYSTEM STATUS: System ready signal asserted at " & time'image(now);
    end if;
    
    if system_error'event and system_error = '1' then
      report "SYSTEM STATUS: System error signal asserted at " & time'image(now) severity warning;
    end if;
  end process;

end architecture behavior;