--------------------------------------------------------------------------------
-- Simplified Testbench for Single Compressor SHyLoC AHB System
-- 单压缩器SHyLoC AHB系统的简化测试平台 (Chinese text in comments only)
-- 
-- This testbench demonstrates:
-- 1. Configuration of HR compressor CCSDS123 parameters
-- 2. Configuration of HR compressor CCSDS121 parameters  
-- 3. Data processing through the compressor
-- 4. Status monitoring and error handling
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library config_controller;
use config_controller.config_pkg.all;

entity shyloc_ahb_system_tb_single is
end entity shyloc_ahb_system_tb_single;

architecture behavior of shyloc_ahb_system_tb_single is

  signal clk_sys : std_logic := '0';
  signal clk_ahb : std_logic := '0';
  signal rst_n   : std_logic := '0';
  signal rst_n_hr : std_logic := '0';

  constant CLK_SYS_PERIOD : time := 10 ns;   -- 100 MHz system clock
  constant CLK_AHB_PERIOD : time := 10 ns;    
  
  -----------------------------------------------------------------------------
  -- Configuration RAM Interface / 配置RAM接口
  -----------------------------------------------------------------------------
  signal ram_wr_en   : std_logic := '0';
  signal wr_addr : std_logic_vector(c_input_addr_width-1 downto 0) := (others => '0');
  signal wr_data : std_logic_vector(7 downto 0) := (others => '0');
  
  -----------------------------------------------------------------------------
  -- Data Interface for HR Compressor / HR压缩器数据接口
  -----------------------------------------------------------------------------
  signal data_in_HR       : std_logic_vector(15 downto 0) := (others => '0');
  signal data_in_valid_HR : std_logic := '0';
  signal data_out_HR      : std_logic_vector(31 downto 0);
  signal data_out_valid_HR: std_logic;
  
  -----------------------------------------------------------------------------
  -- Control and Status Signals / 控制和状态信号
  -----------------------------------------------------------------------------
  signal force_stop    : std_logic := '0';
  signal ready_ext     : std_logic := '1';
  signal system_ready  : std_logic;
  signal system_error  : std_logic;
  signal config_done   : std_logic;  -- Configuration done signal
  -----------------------------------------------------------------------------
  -- Test Control and Monitoring / 测试控制和监控
  -----------------------------------------------------------------------------
  signal test_phase        : integer := 0;
  signal config_count      : integer := 0;
  signal input_sample_count : integer := 0;
  signal output_sample_count : integer := 0;
  
  -----------------------------------------------------------------------------
  -- Configuration Data Arrays / 配置数据数组
  -----------------------------------------------------------------------------
  type config_data_array is array (natural range <>) of std_logic_vector(7 downto 0);
  
  -- HR Compressor CCSDS123 Configuration Data
  -- HR压缩器CCSDS123配置数据
  -- This data configures the preprocessing parameters
  -- 此数据配置预处理参数
  constant HR_CONFIG_DATA_123 : config_data_array(0 to 23) := (
    -- word0: Sample type and encoding order
    x"00", x"00", x"00", x"00",
    -- word1: Number of spectral bands
    x"00", x"00", x"00", x"04",
    -- word2: Image dimensions and parameters
    x"18", x"81", x"50", x"00",
    -- word3: Predictor configuration
    x"80", x"1A", x"1E", x"00",
    -- word4: Weight initialization parameters
    x"D9", x"1F", x"54", x"01",
    -- word5: Additional compression parameters
    x"0A", x"08", x"B2", x"12"
  );
  
  -- HR Compressor CCSDS121 Configuration Data
  -- HR压缩器CCSDS121配置数据
  -- This data configures the entropy encoder parameters
  -- 此数据配置熵编码器参数
  constant HR_CONFIG_DATA_121 : config_data_array(0 to 15) := (
    -- group0: Encoding mode and options
    x"00", x"00", x"00", x"00",
    -- group1: Block size and segment size
    x"20", x"10", x"50", x"00",
    -- group2: Quantization parameters
    x"00", x"02", x"1E", x"00",
    -- group3: Output format configuration
    x"40", x"41", x"54", x"01"
  );
  
  -----------------------------------------------------------------------------
  -- Address Constants / 地址常量
  -----------------------------------------------------------------------------
  constant COMPRESSOR_BASE_ADDR_HR_123 : std_logic_vector(31 downto 0) := x"20000000";
  constant COMPRESSOR_BASE_ADDR_HR_121 : std_logic_vector(31 downto 0) := x"10000000";

begin

  -----------------------------------------------------------------------------
  -- Clock Generation / 时钟生成
  -----------------------------------------------------------------------------
  clk_sys <= not clk_sys after CLK_SYS_PERIOD/2;
  clk_ahb <= not clk_ahb after CLK_AHB_PERIOD/2;

  -----------------------------------------------------------------------------
  -- DUT Instantiation / 被测设计实例化
  -----------------------------------------------------------------------------
  DUT: entity work.shyloc_ahb_system_top_single
    generic map (
      COMPRESSOR_BASE_ADDR_HR_123 => COMPRESSOR_BASE_ADDR_HR_123,
      COMPRESSOR_BASE_ADDR_HR_121 => COMPRESSOR_BASE_ADDR_HR_121
    )
    port map (
      clk_sys          => clk_sys,
      clk_ahb          => clk_ahb,
      rst_n            => rst_n,
      rst_n_hr         => rst_n_hr,
      ram_wr_en        => ram_wr_en,
      ram_wr_addr      => wr_addr,
      ram_wr_data      => wr_data,
      data_in_HR       => data_in_HR,
      data_in_valid_HR => data_in_valid_HR,
      data_out_HR      => data_out_HR,
      data_out_valid_HR=> data_out_valid_HR,
      force_stop       => force_stop,
      ready_ext        => ready_ext,
      system_ready     => system_ready,
      system_error     => system_error,
      config_done      => config_done
    );

  -----------------------------------------------------------------------------
  -- Main Test Stimulus Process / 主测试激励过程
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
        wr_addr <= std_logic_vector(to_unsigned(start_addr + i, wr_addr'length));
        wr_data <= config_data(i);
        wait until rising_edge(clk_sys);
      end loop;
      ram_wr_en <= '0';
      wait until rising_edge(clk_sys);
    end procedure;
    
    -- Procedure to send test data
    -- 发送测试数据的过程
     procedure send_test_data(
      signal data_out : out std_logic_vector(15 downto 0);
      signal data_valid : out std_logic;
      constant num_samples : in integer;
      constant pattern_type : in string(1 to 4)  -- 明确指定字符串长度为4
    ) is
      variable sample_value : unsigned(15 downto 0);
    begin
      -- All report statements now use only ASCII characters
      report "Sending " & integer'image(num_samples) & " samples with " & pattern_type & " pattern";
      
      for i in 0 to num_samples-1 loop
        -- Generate different patterns based on type
        -- 根据类型生成不同的模式
        case pattern_type is
          when "RAMP" =>
            sample_value := to_unsigned(i mod 65536, 16);
          when "SINE" =>
            -- Simplified sine wave pattern
            -- 简化的正弦波模式
            sample_value := to_unsigned(32768 + (i * 1000) mod 16384, 16);
          when "RAND" =>  -- 改为4字符以匹配类型定义
            -- Pseudo-random pattern
            -- 伪随机模式
            sample_value := to_unsigned((i * 31421 + 6927) mod 65536, 16);
          when others =>
            sample_value := to_unsigned(i, 16);
        end case;
        
        data_out <= std_logic_vector(sample_value);
        data_valid <= '1';
        wait for CLK_SYS_PERIOD;
        
        -- Report progress periodically
        -- 定期报告进度
        if (i mod 100) = 0 then
          report "Sample " & integer'image(i) & "/" & integer'image(num_samples);
        end if;
      end loop;
      
      data_valid <= '0';
      report "Test data transmission complete";
    end procedure;
    
    -- Procedure to wait for configuration with timeout
    -- 等待配置完成的过程（带超时）
    procedure wait_for_config_done(
      constant timeout : in time;
      constant config_name : in string
    ) is
      variable start_time : time;
    begin
      start_time := now;
      
      wait until config_done = '1' or (now - start_time) > timeout;
      
      if config_done = '1' then
        report config_name & " configuration completed at " & time'image(now);
        config_count <= config_count + 1;
        wait until config_done = '0';
      else
        report "ERROR: Timeout waiting for " & config_name & " configuration!";
        assert false report "Configuration timeout error" severity error;
      end if;
    end procedure;
    
  begin
    -----------------------------------------------------------------------------
    -- Test Phase 0: System Initialization / 系统初始化
    -----------------------------------------------------------------------------
    report "";
    report "================================================================";
    report "SHyLoC Single Compressor AHB System Testbench Started";
    report "================================================================";
    report "";
    
    test_phase <= 0;
    rst_n <= '0';
    rst_n_hr <= '0';
    report "Phase 0: System reset asserted";
    wait for 100 ns;
    
    rst_n <= '1';
    report "Phase 0: Global reset released";
    wait for 50 ns;
    
    rst_n_hr <= '1';
    report "Phase 0: HR compressor reset released";
    wait for 100 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 1: Configure CCSDS123 / 配置CCSDS123
    -----------------------------------------------------------------------------
    test_phase <= 1;
    report "";
    report "================================================================";
    report "Phase 1: Configuring CCSDS123 Preprocessor";
    report "================================================================";
    
    -- Write CCSDS123 configuration to RAM
    write_config_to_ram(0, HR_CONFIG_DATA_123, 24);
    -- write HR 121 data to RAM at address 24
    write_config_to_ram(24, HR_CONFIG_DATA_121, 16);
    
    -- Trigger configuration by toggling reset
   -- wait for 100 ns;
   -- rst_n_hr <= '0';
    wait for 40 ns;
    rst_n_hr <= '1';

    -- Wait for configuration to complete
   -- wait_for_config_done(2 us, "CCSDS123");
    
    wait for 500 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 2: Configure CCSDS121 / 配置CCSDS121
    -----------------------------------------------------------------------------
    test_phase <= 2;
    report "";
    report "================================================================";
    report "Phase 2: Configuring CCSDS121 Encoder";
    report "================================================================";
    
    -- Write CCSDS121 configuration to RAM
  
    
    
    wait for 500 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 3: Verify System Ready / 验证系统就绪
    -----------------------------------------------------------------------------
    test_phase <= 3;
    report "";
    report "================================================================";
    report "Phase 3: System Ready Verification";
    report "================================================================";
    
    if system_ready = '1' then
      report "SUCCESS: System is ready for operation";
    else
      report "WARNING: System not reporting ready status" severity warning;
    end if;
    
    wait for 200 ns;
    
    -----------------------------------------------------------------------------
    -- Test Phase 4: Send Test Data / 发送测试数据
    -----------------------------------------------------------------------------
    test_phase <= 4;
    report "";
    report "================================================================";
    report "Phase 4: Data Processing Test";
    report "================================================================";
    
    -- Test with different data patterns
    -- 使用不同的数据模式进行测试
    
    -- Ramp pattern
    send_test_data(data_in_HR, data_in_valid_HR, 256, "RAMP");
    wait for 1 us;
    
    -- Sine wave pattern
    send_test_data(data_in_HR, data_in_valid_HR, 512, "SINE");
    wait for 1 us;
    
    -- Random pattern
    send_test_data(data_in_HR, data_in_valid_HR, 128, "RAND");
    wait for 2 us;
    
    -----------------------------------------------------------------------------
    -- Test Phase 5: Error Handling Test / 错误处理测试
    -----------------------------------------------------------------------------
    test_phase <= 5;
    report "";
    report "================================================================";
    report "Phase 5: Error Handling Test";
    report "================================================================";
    
    -- Test force stop functionality
    report "Testing force stop functionality";
    
    -- Send some data
    send_test_data(data_in_HR, data_in_valid_HR, 100, "RAMP");
    
    -- Assert force stop during processing
    wait for 200 ns;
    force_stop <= '1';
    report "Force stop asserted";
    wait for 500 ns;
    force_stop <= '0';
    report "Force stop released";
    
    -- Check system error
    if system_error = '1' then
      report "System error detected (as expected)";
    else
      report "No system error after force stop";
    end if;
    
    wait for 1 us;
    /*
    -----------------------------------------------------------------------------
    -- Test Phase 6: Performance Test / 性能测试
    -----------------------------------------------------------------------------
    test_phase <= 6;
    report "";
    report "================================================================";
    report "Phase 6: Performance Test";
    report "================================================================";
    
    -- Reset system for clean performance test
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait for 500 ns;
    
    -- Reconfigure system
    write_config_to_ram(0, HR_CONFIG_DATA_123, COMPRESSOR_BASE_ADDR_HR_123, "CCSDS123");
    wait_for_config_done(2 us, "CCSDS123");
    
    write_config_to_ram(100, HR_CONFIG_DATA_121, COMPRESSOR_BASE_ADDR_HR_121, "CCSDS121");
    wait_for_config_done(2 us, "CCSDS121");
    
    -- Send continuous data stream
    report "Sending continuous data stream";
    send_test_data(data_in_HR, data_in_valid_HR, 1000, "RAMP");
    
    -- Allow processing time
    wait for 5 us;
    */
    -----------------------------------------------------------------------------
    -- Test Phase 7: Final Report / 最终报告
    -----------------------------------------------------------------------------
    test_phase <= 7;
    report "";
    report "================================================================";
    report "Test Summary";
    report "================================================================";
    report "Configuration operations: " & integer'image(config_count);
    report "Input samples sent: " & integer'image(input_sample_count);
    report "Output samples received: " & integer'image(output_sample_count);
    report "Final system ready status: " & std_logic'image(system_ready);
    report "Final system error status: " & std_logic'image(system_error);
    report "";
    report "================================================================";
    report "Testbench Completed Successfully";
    report "================================================================";
    
    wait for 1 us;
    assert false report "Simulation finished" severity failure;
  end process;
  
  -----------------------------------------------------------------------------
  -- Input Data Monitor Process / 输入数据监控过程
  -----------------------------------------------------------------------------
  input_monitor_proc: process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if data_in_valid_HR = '1' then
        input_sample_count <= input_sample_count + 1;
        -- Report every 1000 samples
        if (input_sample_count mod 1000) = 0 then
          report "Input samples: " & integer'image(input_sample_count);
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output Data Monitor Process / 输出数据监控过程
  -----------------------------------------------------------------------------
  output_monitor_proc: process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if data_out_valid_HR = '1' then
        output_sample_count <= output_sample_count + 1;
        -- Report first few outputs and then periodically
        if output_sample_count < 10 or (output_sample_count mod 100) = 0 then
          report "Output [" & integer'image(output_sample_count) & "]: " & 
                 to_hstring(data_out_HR) & " at time " & time'image(now);
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- System Status Monitor / 系统状态监控
  -----------------------------------------------------------------------------
  status_monitor_proc: process(system_ready, system_error, config_done)
  begin
    if system_ready'event then
      report "SYSTEM STATUS: Ready = " & std_logic'image(system_ready) & 
             " at " & time'image(now);
    end if;
    
    if system_error'event then
      report "SYSTEM STATUS: Error = " & std_logic'image(system_error) & 
             " at " & time'image(now);
    end if;
    
    if config_done'event and config_done = '1' then
      report "SYSTEM STATUS: Configuration done pulse detected at " & time'image(now);
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Timeout Watchdog / 超时看门狗
  -----------------------------------------------------------------------------
  timeout_proc: process
  begin
    wait for 50 us;
    report "TIMEOUT: Simulation time limit reached" severity failure;
  end process;

end architecture behavior;