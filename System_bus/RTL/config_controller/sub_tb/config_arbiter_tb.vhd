-- Configuration Arbiter Testbench
-- Tests round-robin arbitration functionality
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Project ...... Compression Core Configuration                      ==--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.config_types_pkg.all;

entity config_arbiter_tb is
end entity;

architecture behavior of config_arbiter_tb is
    
    -- Clock and reset signals
    -- 时钟和复位信号
    signal clk             : std_logic := '0';
    signal rst_n           : std_logic := '0';
    
    -- DUT interface signals
    -- 被测设备接口信号
    signal compressor_status_HR : compressor_status := compressor_status_init;
    signal compressor_status_LR : compressor_status := compressor_status_init;
    signal compressor_status_H  : compressor_status := compressor_status_init;
    signal config_done          : std_logic := '0';
    signal config_req           : std_logic;
    signal grant                : std_logic_vector(1 downto 0);
    signal grant_valid          : std_logic;
    
    -- Test control signals
    -- 测试控制信号
    signal test_done            : boolean := false;
    
    -- Clock period
    -- 时钟周期
    constant CLK_PERIOD : time := 10 ns;
    
    -- Grant constants for readability
    -- 授权常量定义，便于阅读
    constant GRANT_HR   : std_logic_vector(1 downto 0) := "00";
    constant GRANT_LR   : std_logic_vector(1 downto 0) := "01";
    constant GRANT_H    : std_logic_vector(1 downto 0) := "10";
    constant GRANT_NONE : std_logic_vector(1 downto 0) := "11";

begin

    -- Device Under Test instantiation
    -- 被测设备实例化
    DUT: entity work.config_arbiter
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            compressor_status_HR => compressor_status_HR,
            compressor_status_LR => compressor_status_LR,
            compressor_status_H  => compressor_status_H,
            config_done         => config_done,
            config_req          => config_req,
            grant               => grant,
            grant_valid         => grant_valid
        );
    
    -- Clock generation process
    -- 时钟生成进程
    clk_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Test stimulus process
    -- 测试激励进程
    stimulus_process: process
        variable line_out : line;
    begin
        
        -- Test Case 1: Reset functionality
        -- 测试用例1：复位功能测试
        write(line_out, string'("=== Test Case 1: Reset Test ==="));
        writeline(output, line_out);
        
        rst_n <= '0';
        wait for CLK_PERIOD * 5;
        
        -- Check reset state
        -- 检查复位状态
        assert grant = GRANT_NONE report "ERROR: Grant should be NONE after reset" severity error;
        assert grant_valid = '0' report "ERROR: Grant_valid should be '0' after reset" severity error;
        assert config_req = '0' report "ERROR: Config_req should be '0' after reset" severity error;
        
        write(line_out, string'("Reset test passed"));
        writeline(output, line_out);
        
        -- Release reset
        -- 释放复位
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
    
        -- Test Case 2: Single compressor request (HR)
        -- 测试用例2：单个压缩器请求测试（HR）
        write(line_out, string'("=== Test Case 2: Single HR Request ==="));
        writeline(output, line_out);
        
        compressor_status_HR.AwaitingConfig <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Check HR gets grant
        -- 检查HR获得授权
        assert grant = GRANT_HR report "ERROR: HR should get grant" severity error;
        assert grant_valid = '1' report "ERROR: Grant_valid should be '1'" severity error;
        assert config_req = '1' report "ERROR: Config_req should be '1'" severity error;
        
        write(line_out, string'("HR grant test passed"));
        writeline(output, line_out);
        
        -- Complete configuration
        -- 完成配置
        compressor_status_HR.AwaitingConfig <= '0';
        config_done <= '1';
        wait for CLK_PERIOD;
        config_done <= '0';
        wait for CLK_PERIOD;
        
        -- Check state after config done
        -- 检查配置完成后的状态
        assert grant = GRANT_NONE report "ERROR: Grant should be NONE after config done" severity error;
        assert grant_valid = '0' report "ERROR: Grant_valid should be '0' after config done" severity error;
        
        -- Test Case 3: Multiple requests - Round Robin
        -- 测试用例3：多个请求 - 轮询仲裁
        write(line_out, string'("=== Test Case 3: Round Robin Arbitration ==="));
        writeline(output, line_out);
        
        -- All compressors request simultaneously
        -- 所有压缩器同时请求
        compressor_status_HR.AwaitingConfig <= '1';
        compressor_status_LR.AwaitingConfig <= '1';
        compressor_status_H.AwaitingConfig <= '1';
        wait for CLK_PERIOD * 2;
        
        -- First should be LR (next in round robin after HR)
        -- 第一个应该是LR（轮询中HR之后的下一个）
        assert grant = GRANT_LR report "ERROR: LR should get grant first in round robin" severity error;
        assert grant_valid = '1' report "ERROR: Grant_valid should be '1'" severity error;
        
        write(line_out, string'("Round robin test 1 passed - LR granted"));
        writeline(output, line_out);
        
        -- Complete LR configuration
        -- 完成LR配置
        compressor_status_LR.AwaitingConfig <= '0';
        config_done <= '1';
        wait for CLK_PERIOD;
        config_done <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Next should be H
        -- 下一个应该是H
        assert grant = GRANT_H report "ERROR: H should get grant second in round robin" severity error;
        assert grant_valid = '1' report "ERROR: Grant_valid should be '1'" severity error;
        
        write(line_out, string'("Round robin test 2 passed - H granted"));
        writeline(output, line_out);
        
        -- Complete H configuration
        -- 完成H配置
        compressor_status_H.AwaitingConfig <= '0';
        config_done <= '1';
        wait for CLK_PERIOD;
        config_done <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Finally HR should get grant
        -- 最后HR应该获得授权
        assert grant = GRANT_HR report "ERROR: HR should get grant third in round robin" severity error;
        assert grant_valid = '1' report "ERROR: Grant_valid should be '1'" severity error;
        
        write(line_out, string'("Round robin test 3 passed - HR granted"));
        writeline(output, line_out);
        
        -- Complete HR configuration
        -- 完成HR配置
        compressor_status_HR.AwaitingConfig <= '0';
        config_done <= '1';
        wait for CLK_PERIOD;
        config_done <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test Case 4: No requests
        -- 测试用例4：无请求测试
        write(line_out, string'("=== Test Case 4: No Requests ==="));
        writeline(output, line_out);
        
        -- No compressor requesting
        -- 无压缩器请求
        assert grant = GRANT_NONE report "ERROR: Grant should be NONE when no requests" severity error;
        assert grant_valid = '0' report "ERROR: Grant_valid should be '0' when no requests" severity error;
        assert config_req = '0' report "ERROR: Config_req should be '0' when no requests" severity error;
        
        write(line_out, string'("No request test passed"));
        writeline(output, line_out);
        
        -- Test Case 5: Priority order verification
        -- 测试用例5：优先级顺序验证
        write(line_out, string'("=== Test Case 5: Priority Order Verification ==="));
        writeline(output, line_out);
        
        -- Start with LR having higher priority in round robin
        -- 从LR在轮询中具有更高优先级开始
        wait for CLK_PERIOD * 2;
        
        -- H and LR request (HR should be next in line)
        -- H和LR请求（HR应该是下一个）
        compressor_status_H.AwaitingConfig <= '1';
        compressor_status_LR.AwaitingConfig <= '1';
        wait for CLK_PERIOD * 2;
        
        -- HR should get grant (it's next in round robin)
        -- HR应该获得授权（它是轮询中的下一个）
        assert grant = GRANT_HR report "ERROR: HR should get grant when it's next in round robin" severity error;
        
        write(line_out, string'("Priority order test passed"));
        writeline(output, line_out);
        
        -- Clean up
        -- 清理
        compressor_status_H.AwaitingConfig <= '0';
        compressor_status_LR.AwaitingConfig <= '0';
        config_done <= '1';
        wait for CLK_PERIOD;
        config_done <= '0';
        
        -- Final message
        -- 最终消息
        write(line_out, string'("=== All Tests Completed Successfully ==="));
        writeline(output, line_out);
        
        test_done <= true;
        wait;
        
    end process;
    
    -- Monitor process for debugging
    -- 用于调试的监控进程
    monitor_process: process(clk)
        variable line_out : line;
    begin
        if rising_edge(clk) then
            -- Log state changes
            -- 记录状态变化
            if grant_valid = '1' then
                write(line_out, string'("Grant: "));
                case grant is
                    when GRANT_HR => write(line_out, string'("HR"));
                    when GRANT_LR => write(line_out, string'("LR"));
                    when GRANT_H  => write(line_out, string'("H"));
                    when others   => write(line_out, string'("NONE"));
                end case;
                write(line_out, string'(" at time "));
                write(line_out, now);
                writeline(output, line_out);
            end if;
        end if;
    end process;

end architecture;