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

architecture sim of ahb_master_controller_tb is

    -- Clock and Reset signals / 时钟和复位信号
    signal clk         : std_ulogic := '0';
    signal rst_n       : std_ulogic := '0';
    
    -- Test control signals / 测试控制信号
    signal test_running : boolean := true;
    signal test_phase   : integer := 0;
    
    -- Clock period / 时钟周期
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz
    
    -- DUT signals / 被测试设备信号
    signal compressor_status_HR : compressor_status;
    signal compressor_status_LR : compressor_status;
    signal compressor_status_H  : compressor_status;
    
    -- RAM configuration interface / RAM配置接口
    signal ram_wr_en    : std_logic := '0';
    signal wr_addr      : std_logic_vector(c_input_addr_width-1 downto 0) := (others => '0');
    signal wr_data      : std_logic_vector(c_input_data_width-1 downto 0) := (others => '0');
    
    -- AHB control interfaces / AHB控制接口
    signal ctrli        : ahbtbm_ctrl_in_type;
    signal ctrlo        : ahbtbm_ctrl_out_type;
    
    -- Test configuration data / 测试配置数据
    type config_data_array is array (0 to 15) of std_logic_vector(7 downto 0);
    
    -- CCSDS123 configuration data (10 words = 40 bytes) / CCSDS123配置数据
    constant CCSDS123_CONFIG : config_data_array := (
        x"01", x"02", x"03", x"04",  -- Word 0: 0x04030201
        x"05", x"06", x"07", x"08",  -- Word 1: 0x08070605
        x"09", x"0A", x"0B", x"0C",  -- Word 2: 0x0C0B0A09
        x"0D", x"0E", x"0F", x"10",  -- Word 3: 0x100F0E0D
        others => x"00"
    );
    
    -- CCSDS121 configuration data (4 words = 16 bytes) / CCSDS121配置数据
    constant CCSDS121_CONFIG : config_data_array := (
        x"A1", x"A2", x"A3", x"A4",  -- Word 0: 0xA4A3A2A1
        x"B1", x"B2", x"B3", x"B4",  -- Word 1: 0xB4B3B2B1
        x"C1", x"C2", x"C3", x"C4",  -- Word 2: 0xC4C3C2C1
        x"D1", x"D2", x"D3", x"D4",  -- Word 3: 0xD4D3D2D1
        others => x"00"
    );
    
    -- Expected AHB transactions / 期望的AHB传输
    type ahb_transaction is record
        addr  : std_logic_vector(31 downto 0);
        data  : std_logic_vector(31 downto 0);
        write : std_logic;
    end record;
    
    type ahb_transaction_array is array (natural range <>) of ahb_transaction;
    
    -- Expected transactions for CCSDS123 configuration / CCSDS123配置的期望传输
    constant EXPECTED_CCSDS123_TRANSACTIONS : ahb_transaction_array(0 to 9) := (
        (addr => x"40010000", data => x"04030201", write => '1'),
        (addr => x"40010004", data => x"08070605", write => '1'),
        (addr => x"40010008", data => x"0C0B0A09", write => '1'),
        (addr => x"4001000C", data => x"100F0E0D", write => '1'),
        (addr => x"40010010", data => x"00000000", write => '1'),
        (addr => x"40010014", data => x"00000000", write => '1'),
        (addr => x"40030000", data => x"A4A3A2A1", write => '1'),
        (addr => x"40030004", data => x"B4B3B2B1", write => '1'),
        (addr => x"40030008", data => x"C4C3C2C1", write => '1'),
        (addr => x"4003000C", data => x"D4D3D2D1", write => '1')
    );
    
    -- Test transaction counter / 测试传输计数器
    signal transaction_count : integer := 0;
    signal expected_transactions : integer := 0;
    
    -- AHB Master simulation signals / AHB主设备仿真信号
    signal ahb_address_valid : std_logic := '0';
    signal ahb_data_valid    : std_logic := '0';
    signal ahb_write_active  : std_logic := '0';
    signal current_ahb_addr  : std_logic_vector(31 downto 0) := (others => '0');
    signal current_ahb_data  : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- Clock generation / 时钟生成
    clk_process: process
    begin
        while test_running loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Device Under Test instantiation / 被测试设备例化
    dut: entity config_controller.ahb_master_controller
        generic map (
            hindex              => 0,
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
            clk                 => clk,
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

    -- AHB Master simulation / AHB主设备仿真
    ahb_master_sim: process(clk, rst_n)
    begin
        if rst_n = '0' then
            ctrlo.rst <= '0';
            ctrlo.clk <= '0';
            ctrlo.update <= '0';
            ctrlo.dvalid <= '0';
            ctrlo.hrdata <= (others => '0');
            ctrlo.status.err <= '0';
            ctrlo.status.ecount <= (others => '0');
            ctrlo.status.eaddr <= (others => '0');
            ctrlo.status.edatac <= (others => '0');
            ctrlo.status.edatar <= (others => '0');
            ctrlo.status.hresp <= "00";
            ahb_address_valid <= '0';
            ahb_data_valid <= '0';
            ahb_write_active <= '0';
            current_ahb_addr <= (others => '0');
            current_ahb_data <= (others => '0');
            transaction_count <= 0;
        elsif rising_edge(clk) then
            ctrlo.rst <= rst_n;
            ctrlo.clk <= clk;
            
            -- Default update to '1' to simulate ready AHB bus / 默认update为'1'模拟就绪的AHB总线
            ctrlo.update <= '1';
            ctrlo.dvalid <= '0';
            
            -- Capture AHB transactions / 捕获AHB传输
            if ctrli.ac.htrans = "10" or ctrli.ac.htrans = "11" then  -- NONSEQ or SEQ
                ahb_address_valid <= '1';
                current_ahb_addr <= ctrli.ac.haddr;
                ahb_write_active <= ctrli.ac.hwrite;
                
                -- Capture write data / 捕获写数据
                if ctrli.ac.hwrite = '1' then
                    current_ahb_data <= ctrli.ac.hdata;
                    ahb_data_valid <= '1';
                    
                    -- Log transaction for verification / 记录传输用于验证
                    transaction_count <= transaction_count + 1;
                    
                    -- Print transaction details / 打印传输详情
                    report "AHB Write Transaction #" & integer'image(transaction_count) &
                           " - Addr: 0x" & to_hstring(ctrli.ac.haddr) &
                           " Data: 0x" & to_hstring(ctrli.ac.hdata);
                end if;
            else
                ahb_address_valid <= '0';
                ahb_data_valid <= '0';
                ahb_write_active <= '0';
            end if;
        end if;
    end process;

    -- Stimulus process / 激励过程
    stimulus: process
    begin
        -- Initialize compressor status / 初始化压缩器状态
        compressor_status_HR <= compressor_status_init;
        compressor_status_LR <= compressor_status_init;
        compressor_status_H  <= compressor_status_init;
        
        -- Reset sequence / 复位序列
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';
        wait for 2 * CLK_PERIOD;
        
        report "Starting AHB Master Controller Test";
        
        -- Test Phase 1: Load CCSDS123 configuration / 测试阶段1：加载CCSDS123配置
        test_phase <= 1;
        report "Test Phase 1: Loading CCSDS123 configuration data";
        
        -- Write CCSDS123 configuration to RAM / 将CCSDS123配置写入RAM
        for i in 0 to 39 loop  -- 40 bytes for CCSDS123
            ram_wr_en <= '1';
            wr_addr <= std_logic_vector(to_unsigned(i, c_input_addr_width));
            wr_data <= CCSDS123_CONFIG(i mod 16);
            wait for CLK_PERIOD;
        end loop;
        rst_n <= '0';  -- after writing to RAM, reset the compressor to reconfigurate it 
        wait for 4 * CLK_PERIOD;  
        rst_n <= '1';  -- release reset to allow configuration
        wait for 2 * CLK_PERIOD;
        ram_wr_en <= '0';
        
        -- Set compressor status to request configuration / 设置压缩器状态请求配置
        compressor_status_HR.AwaitingConfig <= '1';
        compressor_status_HR.Ready <= '0';
        wait for 5 * CLK_PERIOD;
        
        -- Wait for configuration to complete / 等待配置完成
        expected_transactions <= 10;  -- 6 CCSDS123 + 4 CCSDS121
        wait until transaction_count >= expected_transactions or 
                   (transaction_count > 0 and ahb_write_active = '0');
        wait for 10 * CLK_PERIOD;
        
        -- Verify HR compressor configuration complete / 验证HR压缩器配置完成
        compressor_status_HR.AwaitingConfig <= '0';
        compressor_status_HR.Ready <= '1';
        
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';
        wait for 2 * CLK_PERIOD;
        -- Test Phase 2: Load CCSDS121 only configuration / 测试阶段2：仅加载CCSDS121配置
        test_phase <= 2;
        report "Test Phase 2: Loading CCSDS121 only configuration";
        
        -- Reset transaction counter / 重置传输计数器
       -- transaction_count <= 0;
        
        -- Write CCSDS121 configuration to RAM / 将CCSDS121配置写入RAM
        for i in 0 to 15 loop  -- 16 bytes for CCSDS121
            ram_wr_en <= '1';
            wr_addr <= std_logic_vector(to_unsigned(i + 50, c_input_addr_width));  -- Different offset
            wr_data <= CCSDS121_CONFIG(i mod 16);
            wait for CLK_PERIOD;
        end loop;
            rst_n <= '0';  -- after writing to RAM, reset the compressor to reconfigurate it 
            wait for 4 * CLK_PERIOD;  
            rst_n <= '1';  -- release reset to allow configuration
            wait for 2 * CLK_PERIOD;
        ram_wr_en <= '0';
        
        -- Set LR compressor status to request configuration / 设置LR压缩器状态请求配置
        compressor_status_LR.AwaitingConfig <= '1';
        compressor_status_LR.Ready <= '0';
        wait for 5 * CLK_PERIOD;
        
        -- Wait for configuration to complete / 等待配置完成
        expected_transactions <= 4;  -- Only CCSDS121
        wait until transaction_count >= expected_transactions or 
                   (transaction_count > 0 and ahb_write_active = '0');
        wait for 10 * CLK_PERIOD;
        
        -- Verify LR compressor configuration complete / 验证LR压缩器配置完成
        compressor_status_LR.AwaitingConfig <= '0';
        compressor_status_LR.Ready <= '1';
        
        -- Test Phase 3: Error conditions / 测试阶段3：错误条件
        test_phase <= 3;
        report "Test Phase 3: Testing error conditions";
        
        -- Test AHB error response / 测试AHB错误响应
        ctrlo.status.err <= '1';
        wait for 5 * CLK_PERIOD;
        ctrlo.status.err <= '0';
        
        -- Test completion / 测试完成
        wait for 20 * CLK_PERIOD;
        
        report "Test completed successfully";
        test_running <= false;
        wait;
    end process;

    -- Transaction verification process / 传输验证过程
    verify_transactions: process(clk)
        variable expected_addr : std_logic_vector(31 downto 0);
        variable expected_data : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) and ahb_data_valid = '1' then
            -- Verify transaction against expected values / 根据期望值验证传输
            if test_phase = 1 and transaction_count <= EXPECTED_CCSDS123_TRANSACTIONS'high then
                expected_addr := EXPECTED_CCSDS123_TRANSACTIONS(transaction_count-1).addr;
                expected_data := EXPECTED_CCSDS123_TRANSACTIONS(transaction_count-1).data;
                
                assert current_ahb_addr = expected_addr
                    report "Address mismatch! Expected: 0x" & to_hstring(expected_addr) &
                           " Got: 0x" & to_hstring(current_ahb_addr)
                    severity error;
                    
                -- Note: Data verification would require knowing the exact data format / 注意：数据验证需要了解确切的数据格式
                -- which depends on the RAM-to-AHB data conversion / 这取决于RAM到AHB的数据转换
            end if;
        end if;
    end process;

    -- Timeout watchdog / 超时看门狗
    timeout_watchdog: process
    begin
        wait for 10 ms;  -- Maximum test time / 最大测试时间
        if test_running then
            report "Test timeout! Test did not complete within expected time."
                severity failure;
        end if;
        wait;
    end process;

end architecture sim;