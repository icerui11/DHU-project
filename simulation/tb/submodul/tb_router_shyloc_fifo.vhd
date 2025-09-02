--================================================================================================================================--
-- Engineer: FPGA Senior Engineer  
-- Create Date: 2025-09-02
-- Module Name: tb_router_shyloc_fifo
--
-- Description: Comprehensive testbench for router_shyloc_fifo module
-- Tests data assembly functionality for D_GEN = 16, 24, and 32 bits
-- 
-- Test scenarios:
-- 1. D_GEN = 16: 2-byte assembly (8-bit -> 16-bit)
-- 2. D_GEN = 24: 3-byte assembly (8-bit -> 24-bit) 
-- 3. D_GEN = 32: 4-byte assembly (8-bit -> 32-bit)
-- 4. FIFO functionality verification
-- 5. Error conditions testing
--================================================================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Mock library declarations for compilation
library shyloc_utils;
library VH_compressor;

entity tb_router_shyloc_fifo is
end tb_router_shyloc_fifo;

architecture sim of tb_router_shyloc_fifo is

    -- Clock and reset
    constant CLK_PERIOD : time := 10 ns;
    signal clk_in       : std_logic := '0';
    signal rst_n        : std_logic := '0';
    
    -- Test parameters for different D_GEN values
    type test_config_t is record
        d_gen       : integer;
        bytes_needed : integer;
        test_name   : string(1 to 20);
    end record;
    
    type test_config_array_t is array (natural range <>) of test_config_t;
    constant TEST_CONFIGS : test_config_array_t(0 to 2) := (
        0 => (d_gen => 16, bytes_needed => 2, test_name => "D_GEN=16 (2 bytes) "),
        1 => (d_gen => 24, bytes_needed => 3, test_name => "D_GEN=24 (3 bytes) "),
        2 => (d_gen => 32, bytes_needed => 4, test_name => "D_GEN=32 (4 bytes) ")
    );
    
    -- Mock config_121 type (simplified for testbench)
    type config_121 is record
        D : std_logic_vector(7 downto 0);
    end record;
    
    -- Signals for DUT with maximum width (32-bit)
    constant MAX_D_GEN : integer := 32;
    signal config_s         : config_121;
    signal rx_data_in       : std_logic_vector(7 downto 0);
    signal rx_data_valid    : std_logic;
    signal rx_data_ready    : std_logic;
    signal ccsds_data_input : std_logic_vector(MAX_D_GEN-1 downto 0);
    signal ccsds_data_valid : std_logic;
    signal ccsds_data_ready : std_logic;
    signal enable           : std_logic;
    signal clear_fifo       : std_logic;
    signal error_out        : std_logic;
    signal debug_state      : std_logic_vector(3 downto 0);
    signal debug_byte_count : std_logic_vector(2 downto 0);
    
    -- Test control signals
    signal test_running     : boolean := false;
    signal test_passed      : boolean := false;
    signal current_test     : integer := 0;
    
    -- Test data arrays
    type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant TEST_DATA_BYTES : byte_array_t(0 to 15) := (
        x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08",
        x"09", x"0A", x"0B", x"0C", x"0D", x"0E", x"0F", x"10"
    );
    
    -- Expected results for each test configuration
    type word32_array_t is array (natural range <>) of std_logic_vector(31 downto 0);
    
    -- Expected results for D_GEN=16 (2 bytes per word)
    constant EXPECTED_16BIT : word32_array_t(0 to 7) := (
        x"0000" & x"02" & x"01",  -- Bytes 0,1
        x"0000" & x"04" & x"03",  -- Bytes 2,3  
        x"0000" & x"06" & x"05",  -- Bytes 4,5
        x"0000" & x"08" & x"07",  -- Bytes 6,7
        x"0000" & x"0A" & x"09",  -- Bytes 8,9
        x"0000" & x"0C" & x"0B",  -- Bytes 10,11
        x"0000" & x"0E" & x"0D",  -- Bytes 12,13
        x"0000" & x"10" & x"0F"   -- Bytes 14,15
    );
    
    -- Expected results for D_GEN=24 (3 bytes per word)  
    constant EXPECTED_24BIT : word32_array_t(0 to 4) := (
        x"00" & x"03" & x"02" & x"01",  -- Bytes 0,1,2
        x"00" & x"06" & x"05" & x"04",  -- Bytes 3,4,5
        x"00" & x"09" & x"08" & x"07",  -- Bytes 6,7,8
        x"00" & x"0C" & x"0B" & x"0A",  -- Bytes 9,10,11
        x"00" & x"0F" & x"0E" & x"0D"   -- Bytes 12,13,14 (last one incomplete)
    );
    
    -- Expected results for D_GEN=32 (4 bytes per word)
    constant EXPECTED_32BIT : word32_array_t(0 to 3) := (
        x"04" & x"03" & x"02" & x"01",  -- Bytes 0,1,2,3
        x"08" & x"07" & x"06" & x"05",  -- Bytes 4,5,6,7
        x"0C" & x"0B" & x"0A" & x"09",  -- Bytes 8,9,10,11
        x"10" & x"0F" & x"0E" & x"0D"   -- Bytes 12,13,14,15
    );

begin

    -- Clock generation
    clk_process : process
    begin
        clk_in <= '0';
        wait for CLK_PERIOD/2;
        clk_in <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- DUT instantiation (instantiate for D_GEN=32 to handle all test cases)
    DUT_32BIT: entity work.router_shyloc_fifo(rtl)
        generic map (
            RESET_TYPE      => 1,
            FIFO_DEPTH      => 32,
            FIFO_ADDR_WIDTH => 5,
            TECH            => 0,
            EDAC            => 0,
            D_GEN           => MAX_D_GEN
        )
        port map (
            clk_in           => clk_in,
            rst_n            => rst_n,
            config_s         => config_s,
            rx_data_in       => rx_data_in,
            rx_data_valid    => rx_data_valid,
            rx_data_ready    => rx_data_ready,
            ccsds_data_input => ccsds_data_input,
            ccsds_data_valid => ccsds_data_valid,
            ccsds_data_ready => ccsds_data_ready,
            enable           => enable,
            clear_fifo       => clear_fifo,
            error_out        => error_out,
            debug_state      => debug_state,
            debug_byte_count => debug_byte_count
        );

    -- Main test process
    main_test_proc : process
        variable bytes_sent : integer;
        variable words_received : integer;
        variable expected_words : integer;
        variable test_data_val : std_logic_vector(31 downto 0);
        variable error_count : integer := 0;
        
        -- Procedure to send a byte
        procedure send_byte(data : in std_logic_vector(7 downto 0)) is
        begin
            rx_data_in <= data;
            rx_data_valid <= '1';
            wait for CLK_PERIOD;
            while rx_data_ready = '0' loop
                wait for CLK_PERIOD;
            end loop;
            rx_data_valid <= '0';
            wait for CLK_PERIOD;
        end procedure;
        
        -- Procedure to receive and check a word
        procedure receive_and_check_word(
            expected : in std_logic_vector(31 downto 0);
            d_width  : in integer;
            word_num : in integer
        ) is
            variable received_data : std_logic_vector(31 downto 0);
        begin
            ccsds_data_ready <= '1';
            
            -- Wait for data valid
            while ccsds_data_valid = '0' loop
                wait for CLK_PERIOD;
            end loop;
            
            -- Capture data
            received_data := ccsds_data_input;
            wait for CLK_PERIOD;
            ccsds_data_ready <= '0';
            
            -- Check data (only compare relevant bits)
            if received_data(d_width-1 downto 0) = expected(d_width-1 downto 0) then
                report "✓ Word " & integer'image(word_num) & " PASSED: " & 
                       "Expected=0x" & to_hstring(expected(d_width-1 downto 0)) & 
                       " Got=0x" & to_hstring(received_data(d_width-1 downto 0));
            else
                report "✗ Word " & integer'image(word_num) & " FAILED: " & 
                       "Expected=0x" & to_hstring(expected(d_width-1 downto 0)) & 
                       " Got=0x" & to_hstring(received_data(d_width-1 downto 0))
                       severity error;
                error_count := error_count + 1;
            end if;
        end procedure;
        
    begin
        -- Initialize signals
        rst_n <= '0';
        rx_data_valid <= '0';
        rx_data_in <= (others => '0');
        ccsds_data_ready <= '0';
        enable <= '0';
        clear_fifo <= '0';
        config_s.D <= (others => '0');
        
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';
        wait for 2 * CLK_PERIOD;
        
        report "=== Starting Router SHYLOC FIFO Testbench ===";
        
        -- Loop through all test configurations
        for test_idx in TEST_CONFIGS'range loop
            current_test <= test_idx;
            
            report "=== " & TEST_CONFIGS(test_idx).test_name & " Test Starting ===";
            
            -- Configure for current test
            config_s.D <= std_logic_vector(to_unsigned(TEST_CONFIGS(test_idx).d_gen, 8));
            enable <= '1';
            clear_fifo <= '1';
            wait for 2 * CLK_PERIOD;
            clear_fifo <= '0';
            wait for 2 * CLK_PERIOD;
            
            -- Calculate expected number of words for this test
            expected_words := 16 / TEST_CONFIGS(test_idx).bytes_needed;
            
            -- Send test data
            report "Sending " & integer'image(16) & " bytes of test data...";
            for byte_idx in TEST_DATA_BYTES'range loop
                send_byte(TEST_DATA_BYTES(byte_idx));
                if byte_idx mod 4 = 3 then
                    wait for 2 * CLK_PERIOD; -- Small gap every 4 bytes
                end if;
            end loop;
            
            report "Data sending complete. Receiving assembled words...";
            wait for 5 * CLK_PERIOD;
            
            -- Receive and verify assembled data
            for word_idx in 0 to expected_words-1 loop
                case TEST_CONFIGS(test_idx).d_gen is
                    when 16 =>
                        receive_and_check_word(EXPECTED_16BIT(word_idx), 16, word_idx);
                    when 24 =>
                        receive_and_check_word(EXPECTED_24BIT(word_idx), 24, word_idx);
                    when 32 =>
                        receive_and_check_word(EXPECTED_32BIT(word_idx), 32, word_idx);
                    when others =>
                        report "Unsupported D_GEN value" severity error;
                end case;
                
                wait for 2 * CLK_PERIOD;
            end loop;
            
            -- Check that no more data is available
            ccsds_data_ready <= '1';
            wait for 5 * CLK_PERIOD;
            if ccsds_data_valid = '1' then
                report "✗ Unexpected extra data available" severity warning;
            else
                report "✓ No unexpected extra data";
            end if;
            ccsds_data_ready <= '0';
            
            report "=== " & TEST_CONFIGS(test_idx).test_name & " Test Complete ===";
            wait for 10 * CLK_PERIOD;
        end loop;
        
        -- Additional tests: Error conditions
        report "=== Testing Error Conditions ===";
        
        -- Test FIFO overflow
        config_s.D <= std_logic_vector(to_unsigned(16, 8));
        enable <= '1';
        clear_fifo <= '1';
        wait for 2 * CLK_PERIOD;
        clear_fifo <= '0';
        ccsds_data_ready <= '0';  -- Don't read from FIFO
        
        -- Send enough data to fill FIFO
        report "Testing FIFO overflow condition...";
        for i in 1 to 100 loop  -- Send more data than FIFO can hold
            if rx_data_ready = '1' then
                send_byte(std_logic_vector(to_unsigned(i mod 256, 8)));
            else
                exit;  -- FIFO full, stop sending
            end if;
        end loop;
        
        wait for 10 * CLK_PERIOD;
        
        if error_out = '1' then
            report "✓ FIFO overflow error correctly detected";
        else
            report "✗ FIFO overflow error not detected" severity warning;
        end if;
        
        -- Test summary
        if error_count = 0 then
            report "=== ALL TESTS PASSED ===";
            test_passed <= true;
        else
            report "=== " & integer'image(error_count) & " TESTS FAILED ===" severity error;
            test_passed <= false;
        end if;
        
        test_running <= false;
        wait;
        
    end process;

    -- Monitor process for debugging
    monitor_proc : process
    begin
        wait until test_running = false;
        report "=== Test Summary ===";
        report "Final test result: " & boolean'image(test_passed);
        
        -- Generate waveform markers
        for i in 0 to 2 loop
            report "Marker: Test_" & integer'image(i) & "_" & TEST_CONFIGS(i).test_name;
        end loop;
        
        wait;
    end process;

    -- Set test running flag
    test_running <= true, false after 50 us;

end sim;

--================================================================================================================================--
-- Simulation commands for QuestaSim:
-- 
-- # Compile
-- vlib work
-- vcom -2008 router_shyloc_fifo.vhd
-- vcom -2008 tb_router_shyloc_fifo.vhd
--
-- # Simulate  
-- vsim -t 1ps work.tb_router_shyloc_fifo
--
-- # Add waves
-- add wave -group "Clock_Reset" /tb_router_shyloc_fifo/clk_in /tb_router_shyloc_fifo/rst_n
-- add wave -group "Input_Data" /tb_router_shyloc_fifo/rx_data_in /tb_router_shyloc_fifo/rx_data_valid /tb_router_shyloc_fifo/rx_data_ready
-- add wave -group "Output_Data" /tb_router_shyloc_fifo/ccsds_data_input /tb_router_shyloc_fifo/ccsds_data_valid /tb_router_shyloc_fifo/ccsds_data_ready  
-- add wave -group "Control" /tb_router_shyloc_fifo/enable /tb_router_shyloc_fifo/clear_fifo /tb_router_shyloc_fifo/error_out
-- add wave -group "Debug" /tb_router_shyloc_fifo/debug_state /tb_router_shyloc_fifo/debug_byte_count /tb_router_shyloc_fifo/current_test
-- add wave -group "Internal" /tb_router_shyloc_fifo/DUT_32BIT/current_state /tb_router_shyloc_fifo/DUT_32BIT/assemble_cnt /tb_router_shyloc_fifo/DUT_32BIT/data_buffer
-- add wave -group "FIFO" /tb_router_shyloc_fifo/DUT_32BIT/fifo_empty /tb_router_shyloc_fifo/DUT_32BIT/fifo_full /tb_router_shyloc_fifo/DUT_32BIT/fifo_wr_en /tb_router_shyloc_fifo/DUT_32BIT/fifo_rd_en
-- 
-- # Run simulation
-- run 50 us
--
--================================================================================================================================--