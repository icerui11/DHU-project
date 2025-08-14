
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library compression_config;
use compression_config.config_types.all;

entity tb_configuration_controller is
    generic (
        runner_cfg : string;
        TEST_CASE  : string := "basic_configuration"
    );
end entity;

architecture tb of tb_configuration_controller is
    constant CLK_PERIOD : time := 10 ns;
    
    signal clk : std_logic := '0';
    signal rst_n : std_logic;
    
    -- DUT信号
    signal config_if_in  : config_write_if;
    signal config_if_out : config_read_if;
    signal ahb_master_out : ahb_mst_out_type;
    signal ahb_master_in  : ahb_mst_in_type;
    
    -- 测试控制信号
    signal test_done : boolean := false;
    
begin
    
    -- 时钟生成
    clk <= not clk after CLK_PERIOD/2 when not test_done;
    
    -- DUT实例化
    dut : entity compression_config.configuration_controller
        port map (
            clk => clk,
            rst_n => rst_n,
            config_if_in => config_if_in,
            config_if_out => config_if_out,
            ahb_master_out => ahb_master_out,
            ahb_master_in => ahb_master_in,
            ccsds121_ready => '1',
            ccsds121_error => '0',
            ccsds123_ready => '1',
            ccsds123_error => '0'
        );
    
    -- 主测试进程
    main : process
        
        procedure reset_dut is
        begin
            rst_n <= '0';
            wait for 100 ns;
            rst_n <= '1';
            wait for 100 ns;
        end procedure;
        
        procedure write_config(addr : integer; data : std_logic_vector(31 downto 0)) is
        begin
            config_if_in.add <= std_logic_vector(to_unsigned(addr, 8));
            config_if_in.w_data <= data;
            config_if_in.write_en <= '1';
            wait until rising_edge(clk);
            config_if_in.write_en <= '0';
        end procedure;
        
    begin
        test_runner_setup(runner, runner_cfg);
        
        -- 初始化信号
        config_if_in.read_en <= '0';
        config_if_in.write_en <= '0';
        config_if_in.add <= (others => '0');
        config_if_in.w_data <= (others => '0');
        
        ahb_master_in.hrdata <= (others => '0');
        ahb_master_in.hready <= '1';
        ahb_master_in.hresp <= "00";
        
        reset_dut;
        
        while test_suite loop
            if run(TEST_CASE) then
                info("Running test: " & TEST_CASE);
                
                if TEST_CASE = "basic_configuration" then
                    -- 写入测试配置数据
                    for i in 0 to 15 loop
                        write_config(i, std_logic_vector(to_unsigned(i*16 + i, 32)));
                    end loop;
                    
                    -- 启动配置
                    write_config(16#60#, X"00000005");  -- Enable + Start
                    
                    -- 等待完成
                    wait for 1 us;
                    
                    info("Basic configuration test completed");
                    
                elsif TEST_CASE = "error_handling" then
                    -- 模拟AHB错误
                    ahb_master_in.hresp <= "01";  -- ERROR
                    
                    write_config(16#60#, X"00000005");
                    wait for 500 ns;
                    
                    -- 检查错误状态应该会被检测到
                    info("Error handling test completed");
                    
                end if;
            end if;
        end loop;
        
        test_done <= true;
        test_runner_cleanup(runner);
    end process;
    
end architecture;