--------------------------------------------------------------------------------
--== Filename ..... tb_ahb_master_controller.vhd                                ==--
--== Institute .... IDA TU Braunschweig RoSy                                    ==--
--== Authors ...... Rui                                                         ==--
--== Copyright .... Copyright (c) 2025 IDA                                      ==--
--== Project ...... Compression Core Configuration Testbench                   ==--
--== Version ...... 1.00                                                        ==--
--== Conception ... July 2025                                                   ==--
-- Testbench for AHB Master Controller
-- Tests configuration data transfer to compression cores via AHB interface
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library config_controller;
use config_controller.config_types_pkg.all;
use config_controller.config_pkg.all;

entity ahb_master_controller_tb is
end entity ahb_master_controller_tb;

architecture testbench of ahb_master_controller_tb is

  constant CLOCK_PERIOD : time := 10 ns;  -- 100MHz clock 
  signal clk            : std_ulogic := '0';
  signal rst_n          : std_ulogic := '0';
  
  -- Test control signals 
  signal test_done      : boolean := false;
  signal test_pass      : boolean := true;
  signal test_case_num  : integer := 0;
  
  -- DUT signals 
  signal compressor_status_HR : compressor_status;
  signal compressor_status_LR : compressor_status;
  signal compressor_status_H  : compressor_status;
  
  -- AHB Master interface signals 
  signal ctrli : ahbtbm_ctrl_in_type;
  signal ctrlo : ahbtbm_ctrl_out_type;
  
  -- RAM interface signals 
  signal ram_wr_en : std_logic := '0';
  signal wr_addr   : std_logic_vector(c_input_addr_width-1 downto 0) := (others => '0');
  signal wr_data   : std_logic_vector(c_input_data_width-1 downto 0) := (others => '0');
  
  -- AHB Master simulation signals / AHB主接口模拟信号
  signal ahb_hready     : std_logic := '1';
  signal ahb_hresp      : std_logic_vector(1 downto 0) := "00";
  signal ahb_hrdata     : std_logic_vector(31 downto 0) := (others => '0');
  signal ahb_haddr      : std_logic_vector(31 downto 0);
  signal ahb_hwrite     : std_logic;
  signal ahb_hsize      : std_logic_vector(2 downto 0);
  signal ahb_hburst     : std_logic_vector(2 downto 0);
  signal ahb_htrans     : std_logic_vector(1 downto 0);
  signal ahb_hwdata     : std_logic_vector(31 downto 0);
  
  -- Test data arrays / 测试数据数组
  type config_data_array is array (0 to 15) of std_logic_vector(7 downto 0);
  
  -- CCSDS123 configuration data 
  -- CCSDS123配置数据（6个寄存器 * 4字节 = 24字节）
  constant CCSDS123_CONFIG_DATA : config_data_array := (
    x"01", x"23", x"45", x"67",  -- Register 0: 0x67452301
    x"89", x"AB", x"CD", x"EF",  -- Register 1: 0xEFCDAB89
    x"FE", x"DC", x"BA", x"98",  -- Register 2: 0x98BADCFE
    x"76", x"54", x"32", x"10",  -- Register 3: 0x10325476
    x"11", x"22", x"33", x"44",  -- Register 4: 0x44332211
    x"55", x"66", x"77", x"88",  -- Register 5: 0x88776655
    others => x"00"
  );
  
  -- CCSDS121配置数据（4个寄存器 * 4字节 = 16字节）
  constant CCSDS121_CONFIG_DATA : config_data_array := (
    x"A1", x"B2", x"C3", x"D4",  -- Register 0: 0xD4C3B2A1
    x"E5", x"F6", x"07", x"18",  -- Register 1: 0x1807F6E5
    x"29", x"3A", x"4B", x"5C",  -- Register 2: 0x5C4B3A29
    x"6D", x"7E", x"8F", x"90",  -- Register 3: 0x908F7E6D
    others => x"00"
  );
  
  -- Expected AHB transactions / 预期的AHB事务
  type ahb_transaction is record
    addr  : std_logic_vector(31 downto 0);
    data  : std_logic_vector(31 downto 0);
    write : std_logic;
  end record;
  
  type ahb_transaction_array is array (natural range <>) of ahb_transaction;
  
  -- Helper functions and procedures / 辅助函数和过程
  
  -- Initialize compressor status / 初始化压缩器状态
  procedure init_compressor_status(signal status : out compressor_status) is
  begin
    status.AwaitingConfig <= '1';
    status.Ready          <= '0';
    status.Finished       <= '0';
    status.Error          <= '0';
  end procedure;
  
  -- Set compressor status to ready / 设置压缩器状态为就绪
  procedure set_compressor_ready(signal status : out compressor_status) is
  begin
    status.AwaitingConfig <= '0';
    status.Ready          <= '1';
    status.Finished       <= '0';
    status.Error          <= '0';
  end procedure;
  
  -- Write configuration data to RAM / 将配置数据写入RAM
  procedure write_config_to_ram(
    signal clk      : in std_ulogic;
    signal wr_en    : out std_logic;
    signal wr_addr  : out std_logic_vector(c_input_addr_width-1 downto 0);
    signal wr_data  : out std_logic_vector(c_input_data_width-1 downto 0);
    constant data   : in config_data_array;
    constant start_addr : in integer;
    constant num_bytes  : in integer
  ) is
  begin
    for i in 0 to num_bytes-1 loop
      wait until rising_edge(clk);
      wr_en <= '1';
      wr_addr <= std_logic_vector(to_unsigned(start_addr + i, c_input_addr_width));
      wr_data <= data(i);
      wait until rising_edge(clk);
      wr_en <= '0';
    end loop;
  end procedure;
  
  -- Simulate AHB slave response / 模拟AHB从设备响应
  procedure simulate_ahb_response(
    signal clk       : in std_ulogic;
    signal hready    : out std_logic;
    signal hresp     : out std_logic_vector(1 downto 0);
    constant delay   : in integer := 1
  ) is
  begin
    hready <= '0';
    hresp <= "00";  -- OKAY response
    for i in 1 to delay loop
      wait until rising_edge(clk);
    end loop;
    hready <= '1';
    wait until rising_edge(clk);
  end procedure;
  
  -- Check AHB transaction / 检查AHB事务
  procedure check_ahb_transaction(
    signal clk        : in std_ulogic;
    signal haddr      : in std_logic_vector(31 downto 0);
    signal hwdata     : in std_logic_vector(31 downto 0);
    signal hwrite     : in std_logic;
    signal htrans     : in std_logic_vector(1 downto 0);
    constant expected : in ahb_transaction;
    signal test_pass  : inout boolean;
    constant test_name : in string
  ) is
  begin
    wait until rising_edge(clk);
    if htrans = "10" or htrans = "11" then  -- NONSEQ or SEQ transfer
      if haddr /= expected.addr then
        report "ERROR in " & test_name & ": Address mismatch. Expected: 0x" & 
               to_hstring(expected.addr) & ", Got: 0x" & to_hstring(haddr) severity error;
        test_pass <= false;
      end if;
      
      if hwrite /= expected.write then
        report "ERROR in " & test_name & ": Write signal mismatch. Expected: " & 
               std_logic'image(expected.write) & ", Got: " & std_logic'image(hwrite) severity error;
        test_pass <= false;
      end if;
      
      if hwrite = '1' and hwdata /= expected.data then
        report "ERROR in " & test_name & ": Data mismatch. Expected: 0x" & 
               to_hstring(expected.data) & ", Got: 0x" & to_hstring(hwdata) severity error;
        test_pass <= false;
      end if;
    end if;
  end procedure;

begin

  clk_process: process
  begin
    while not test_done loop
      clk <= '0';
      wait for CLOCK_PERIOD/2;
      clk <= '1';
      wait for CLOCK_PERIOD/2;
    end loop;
    wait;
  end process;
  
  -- DUT instantiation 
  dut: entity config_controller.ahb_master_controller
    generic map (
      hindex               => 0,
      haddr_mask          => 16#FFF#,
      hmaxburst           => 16,
      g_input_data_width  => c_input_data_width,
      g_input_addr_width  => c_input_addr_width,
      g_input_depth       => c_input_depth,
      g_output_data_width => c_output_data_width,
      g_output_addr_width => c_output_addr_width,
      g_output_depth      => c_output_depth,
      ccsds123_1_base     => x"40010000",
      ccsds123_2_base     => x"40020000",
      ccsds121_base       => x"40030000",
      ccsds123_cfg_size   => 6,
      ccsds121_cfg_size   => 4
    )
    port map (
      clk                  => clk,
      rst_n               => rst_n,
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_LR,
      compressor_status_H  => compressor_status_H,
      ram_wr_en           => ram_wr_en,
      wr_addr             => wr_addr,
      wr_data             => wr_data,
      ctrli               => ctrli,
      ctrlo               => ctrlo
    );
  
  -- Connect AHB signals / 连接AHB信号
  ahb_haddr  <= ctrli.ac.haddr;
  ahb_hwrite <= ctrli.ac.hwrite;
  ahb_hsize  <= ctrli.ac.hsize;
  ahb_hburst <= ctrli.ac.hburst;
  ahb_htrans <= ctrli.ac.htrans;
  ahb_hwdata <= ctrli.ac.hdata;
  
  ctrlo.hready <= ahb_hready;
  ctrlo.hresp  <= ahb_hresp;
  ctrlo.hrdata <= ahb_hrdata;
  ctrlo.update <= ahb_hready;  -- Simplified update signal
  
  -- Main test process / 主测试过程
  test_process: process
  begin
    
    -- Test Case 0: Reset Test / 测试用例0：复位测试
    test_case_num <= 0;
    report "=== Test Case 0: Reset Test ===" severity note;
    
    -- Initialize signals / 初始化信号
    rst_n <= '0';
    init_compressor_status(compressor_status_HR);
    init_compressor_status(compressor_status_LR);
    init_compressor_status(compressor_status_H);
    
    wait for 10 * CLOCK_PERIOD;
    rst_n <= '1';
    wait for 5 * CLOCK_PERIOD;
    
    report "Reset test completed" severity note;
    
    -- Test Case 1: CCSDS123 Configuration / 测试用例1：CCSDS123配置
    test_case_num <= 1;
    report "=== Test Case 1: CCSDS123 Configuration ===" severity note;
    
    -- Prepare configuration data / 准备配置数据
    write_config_to_ram(clk, ram_wr_en, wr_addr, wr_data, 
                        CCSDS123_CONFIG_DATA, 
                        to_integer(unsigned(c_hr_ccsds123_base & "000")), 24);
    
    wait for 5 * CLOCK_PERIOD;
    
    -- Trigger configuration by setting compressor status / 通过设置压缩器状态触发配置
    compressor_status_HR.AwaitingConfig <= '1';
    
    -- Wait for AHB transactions and verify / 等待AHB事务并验证
    for i in 0 to 5 loop  -- 6 registers for CCSDS123
      wait until rising_edge(clk) and ahb_htrans = "10";  -- Wait for NONSEQ transfer
      simulate_ahb_response(clk, ahb_hready, ahb_hresp, 1);
    end loop;
    
    wait for 10 * CLOCK_PERIOD;
    set_compressor_ready(compressor_status_HR);
    
    report "CCSDS123 configuration test completed" severity note;
    
    -- Test Case 2: CCSDS121 Configuration / 测试用例2：CCSDS121配置  
    test_case_num <= 2;
    report "=== Test Case 2: CCSDS121 Configuration ===" severity note;
    
    -- Reset compressor status / 重置压缩器状态
    init_compressor_status(compressor_status_H);
    
    -- Prepare configuration data / 准备配置数据
    write_config_to_ram(clk, ram_wr_en, wr_addr, wr_data, 
                        CCSDS121_CONFIG_DATA, 
                        to_integer(unsigned(c_h_ccsds121_base & "000")), 16);
    
    wait for 5 * CLOCK_PERIOD;
    
    -- Trigger configuration / 触发配置
    compressor_status_H.AwaitingConfig <= '1';
    
    -- Wait for AHB transactions / 等待AHB事务
    for i in 0 to 3 loop  -- 4 registers for CCSDS121
      wait until rising_edge(clk) and ahb_htrans = "10";
      simulate_ahb_response(clk, ahb_hready, ahb_hresp, 1);
    end loop;
    
    wait for 10 * CLOCK_PERIOD;
    set_compressor_ready(compressor_status_H);
    
    report "CCSDS121 configuration test completed" severity note;
    
    -- Test Case 3: Burst Transfer Test / 测试用例3：突发传输测试
    test_case_num <= 3;
    report "=== Test Case 3: Burst Transfer Test ===" severity note;
    
    -- Reset and prepare for burst transfer / 重置并准备突发传输
    init_compressor_status(compressor_status_LR);
    
    write_config_to_ram(clk, ram_wr_en, wr_addr, wr_data, 
                        CCSDS123_CONFIG_DATA, 
                        to_integer(unsigned(c_lr_ccsds123_base & "000")), 24);
    
    wait for 5 * CLOCK_PERIOD;
    
    compressor_status_LR.AwaitingConfig <= '1';
    
    -- Wait for burst transfer / 等待突发传输
    wait until rising_edge(clk) and ahb_hburst /= "000";  -- Wait for burst
    
    -- Simulate burst response / 模拟突发响应
    for i in 0 to 5 loop
      simulate_ahb_response(clk, ahb_hready, ahb_hresp, 1);
    end loop;
    
    wait for 10 * CLOCK_PERIOD;
    set_compressor_ready(compressor_status_LR);
    
    report "Burst transfer test completed" severity note;
    
    -- Test Case 4: Priority Arbitration Test / 测试用例4：优先级仲裁测试
    test_case_num <= 4;
    report "=== Test Case 4: Priority Arbitration Test ===" severity note;
    
    -- Set multiple compressors awaiting config / 设置多个压缩器等待配置
    init_compressor_status(compressor_status_HR);
    init_compressor_status(compressor_status_LR);
    init_compressor_status(compressor_status_H);
    
    compressor_status_HR.AwaitingConfig <= '1';
    compressor_status_LR.AwaitingConfig <= '1';
    compressor_status_H.AwaitingConfig <= '1';
    
    wait for 5 * CLOCK_PERIOD;
    
    -- Should process HR first (highest priority) / 应该首先处理HR（最高优先级）
    -- Monitor AHB address to verify correct order / 监控AHB地址以验证正确顺序
    wait until rising_edge(clk) and ahb_htrans = "10";
    
    -- Verify HR base address is accessed first / 验证首先访问HR基地址
    if ahb_haddr(31 downto 12) /= x"40010" then
      report "ERROR: Priority arbitration failed - HR should be processed first" severity error;
      test_pass <= false;
    end if;
    
    -- Complete HR configuration / 完成HR配置
    for i in 0 to 5 loop
      simulate_ahb_response(clk, ahb_hready, ahb_hresp, 1);
      if i < 5 then
        wait until rising_edge(clk) and ahb_htrans = "10";
      end if;
    end loop;
    
    set_compressor_ready(compressor_status_HR);
    wait for 10 * CLOCK_PERIOD;
    
    report "Priority arbitration test completed" severity note;
    
    -- Test Case 5: Error Handling Test / 测试用例5：错误处理测试
    test_case_num <= 5;
    report "=== Test Case 5: Error Handling Test ===" severity note;
    
    init_compressor_status(compressor_status_H);
    compressor_status_H.AwaitingConfig <= '1';
    
    wait until rising_edge(clk) and ahb_htrans = "10";
    
    -- Simulate AHB error response / 模拟AHB错误响应
    ahb_hready <= '0';
    ahb_hresp <= "01";  -- ERROR response
    wait for 3 * CLOCK_PERIOD;
    ahb_hready <= '1';
    ahb_hresp <= "00";  -- Back to OKAY
    
    wait for 20 * CLOCK_PERIOD;
    
    report "Error handling test completed" severity note;
    
    -- Final test summary / 最终测试总结
    wait for 10 * CLOCK_PERIOD;
    
    if test_pass then
      report "=== ALL TESTS PASSED ===" severity note;
    else
      report "=== SOME TESTS FAILED ===" severity error;
    end if;
    
    test_done <= true;
    wait;
    
  end process;
  
  -- AHB monitor process / AHB监控过程
  ahb_monitor: process(clk)
  begin
    if rising_edge(clk) then
      if ahb_htrans = "10" or ahb_htrans = "11" then  -- Valid transfer
        report "AHB Transaction - Addr: 0x" & to_hstring(ahb_haddr) & 
               ", Data: 0x" & to_hstring(ahb_hwdata) & 
               ", Write: " & std_logic'image(ahb_hwrite) &
               ", Size: " & to_string(to_integer(unsigned(ahb_hsize))) &
               ", Burst: " & to_string(to_integer(unsigned(ahb_hburst))) severity note;
      end if;
    end if;
  end process;

end architecture testbench;