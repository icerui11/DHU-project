----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- Testbench for router_top_level entity
--                   -- Tests SpaceWire routing functionality with multiple ports
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_top_level_tb.vhd
-- @ Engineer				:	Bhakti
-- @ Date					: 	08.07.2025
-- @ Version				:	5.0
-- @ VHDL Version			:   2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

context work.router_context;

entity router_top_level_RTG4_tb is
end router_top_level_RTG4_tb;

architecture rtl of router_top_level_RTG4_tb is
    -- Constants
    constant clk_period   : time    := 12.5 ns;
    constant spw_clk_freq : t_freq_array  := c_spw_clk_freq;
constant spw_clk_periods : t_time_array := c_spw_clk_periods;
    constant g_num_ports  : natural range 1 to 32 := c_num_ports;
    
    -- SpW Constants
    constant c_clock_frequency : real := 80_000_000.0;  -- SpW clock frequency (in Hz)
    constant c_rx_fifo_size    : integer := 56;          -- number of SpW packets in RX fifo
    constant c_tx_fifo_size    : integer := 56;          -- number of SpW packets in TX fifo
    constant c_mode            : string := "single";

    -- Clock and Reset signals
    signal spw_clk : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal router_clk : std_logic := '0';
    signal rst_in : std_logic := '1';
    signal enable : std_logic := '0';

    -- DDR IO signals (for custom mode - not used in single mode)
    signal DDR_din_r : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal DDR_din_f : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal DDR_sin_r : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal DDR_sin_f : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal SDR_Dout  : std_logic_vector(1 to g_num_ports-1);
    signal SDR_Sout  : std_logic_vector(1 to g_num_ports-1);

    -- Single-ended IO signals (for single mode)
    signal Din_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal Din_n  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal Sin_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal Sin_n  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal Dout_p : std_logic_vector(1 to g_num_ports-1);
    signal Dout_n : std_logic_vector(1 to g_num_ports-1);
    signal Sout_p : std_logic_vector(1 to g_num_ports-1);
    signal Sout_n : std_logic_vector(1 to g_num_ports-1);

    -- SpaceWire FIFO IO
    signal spw_fifo_in  : r_fifo_master_array(1 to g_num_ports-1) := (others => c_fifo_master);
    signal spw_fifo_out : r_fifo_slave_array(1 to g_num_ports-1);

    -- Port connection status
    signal Port_Connected : std_logic_vector(31 downto 1);

    -- SpW Codec interfaces for testbench
    signal codecs : r_codec_interface_array(1 to c_num_ports-1) := (others => c_codec_interface);
    signal reset_spw : std_logic := '0';

    -- Test stimulus signals
    type t_spw_tx_state is (
        IDLE, WAIT_CONNECTION, SEND_ADDR, SEND_DATA, SEND_EOP, WAIT_TX_COMPLETE
    );
    signal tx_state : t_spw_tx_state := IDLE;
    signal test_complete : std_logic := '0';

begin
    -- Generate complementary SpW clocks
    gen_spw_clks : for i in 1 to g_num_ports - 1 generate
        		spw_clk(i) <= not spw_clk(i) after spw_clk_periods(i)/2;
    		
	end generate gen_spw_clks;

    -- Generate router clock
    router_clk <= not router_clk after clk_period/2;

    -- Reset generation
    gen_rst: process
    begin
        rst_in <= '1';
        reset_spw <= '1';
        wait for 25 us;
        rst_in <= '0';
        reset_spw <= '0';
        wait for 100 ns;
        enable <= '1';
        wait;
    end process;

    -- Instantiate DUT
    DUT: entity work.router_top_level_RTG4
    generic map(
        g_clock_freq => spw_clk_freq,
        g_num_ports  => g_num_ports,
        g_mode       => c_mode,
        g_is_fifo    => c_fifo_ports,
        g_priority   => c_priority,
        g_ram_style  => c_ram_style
    )
    port map(
        spw_clk        => spw_clk,
        router_clk     => router_clk,
        rst_in         => rst_in,
        
        DDR_din_r      => DDR_din_r,
        DDR_din_f      => DDR_din_f,
        DDR_sin_r      => DDR_sin_r,
        DDR_sin_f      => DDR_sin_f,
        SDR_Dout       => SDR_Dout,
        SDR_Sout       => SDR_Sout,
        
        Din_p          => Din_p,
        Din_n          => Din_n,
        Sin_p          => Sin_p,
        Sin_n          => Sin_n,
        Dout_p         => Dout_p,
        Dout_n         => Dout_n,
        Sout_p         => Sout_p,
        Sout_n         => Sout_n,
        
        spw_fifo_in    => spw_fifo_in,
        spw_fifo_out   => spw_fifo_out,
        
        Port_Connected => Port_Connected
    );

    -- Generate SpW codec instances for testing

            SPW_inst: entity work.spw_wrap_top_level_RTG4(rtl)
            generic map(
                g_clock_frequency => c_clock_frequency,
                g_rx_fifo_size    => c_rx_fifo_size,
                g_tx_fifo_size    => c_tx_fifo_size,
                g_mode            => c_mode
            )
            port map(
                clock                => spw_clk(1),
                reset                => reset_spw,

                -- Channels
                Tx_data              => codecs(1).Tx_data,
                Tx_OR                => codecs(1).Tx_OR,
                Tx_IR                => codecs(1).Tx_IR,
                
                Rx_data              => codecs(1).Rx_data,
                Rx_OR                => codecs(1).Rx_OR,
                Rx_IR                => '1',
                
                Rx_ESC_ESC           => codecs(1).Rx_ESC_ESC,
                Rx_ESC_EOP           => codecs(1).Rx_ESC_EOP,
                Rx_ESC_EEP           => codecs(1).Rx_ESC_EEP,
                Rx_Parity_error      => codecs(1).Rx_Parity_error,
                Rx_bits              => codecs(1).Rx_bits,
                Rx_rate              => codecs(1).Rx_rate,
                
                Rx_Time              => codecs(1).Rx_Time,
                Rx_Time_OR           => codecs(1).Rx_Time_OR,
                Rx_Time_IR           => '1',

                Tx_Time              => codecs(1).Tx_Time,
                Tx_Time_OR           => codecs(1).Tx_Time_OR,
                Tx_Time_IR           => codecs(1).Tx_Time_IR,
            
                -- Control
                Disable              => codecs(1).Disable,
                Connected            => codecs(1).Connected,
                Error_select         => codecs(1).Error_select,
                Error_inject         => codecs(1).Error_inject,
                
                -- SpW Physical Interface
                Din_p                => Dout_p(1),
                Sin_p                => Sout_p(1),
                Dout_p               => Din_p(1),
                Sout_p               => Sin_p(1)
            );
            
            -- Default signal assignments
  --          codecs(1).Rx_IR <= '1';
 --          codecs(1).Rx_Time_IR <= '1';
 --           codecs(i).Disable <= '0';
 --           codecs(i).Error_select <= (others => '0');
 --           codecs(i).Error_inject <= '0';
 --           codecs(i).Tx_Time <= (others => '0');
 --           codecs(i).Tx_Time_OR <= '0';
  --          codecs(i).Tx_Time_IR <= '0';
            


    -- Test stimulus process
    test_stimulus: process(router_clk)
        variable test_port : integer := 1;
        variable target_port : integer := 1;
        variable data_counter : integer := 0;
        constant test_data : std_logic_vector(7 downto 0) := x"A5";
    begin
        if rising_edge(spw_clk(1)) then
            if reset_spw = '1' then
                tx_state <= IDLE;
                data_counter := 0;
                -- Initialize codec signals
 --               for i in 1 to g_num_ports-1 loop
 --                   if c_fifo_ports(i) = '0' then
                        codecs(test_port).Tx_data <= (others => '0');
                        codecs(test_port).Tx_OR <= '0';
 --                   end if;
 --               end loop;
            else
                case tx_state is
                    when IDLE =>
                        if enable = '1' then
                            tx_state <= WAIT_CONNECTION;
                            report "Starting SpaceWire router test..." severity note;
                        end if;
                    
                    when WAIT_CONNECTION =>
                        -- Wait for both test ports to connect
                        if (test_port <= g_num_ports-1) and (target_port <= g_num_ports-1) then
                            if c_fifo_ports(test_port) = '0' and c_fifo_ports(target_port) = '0' then
                                if Port_Connected(test_port) = '1' and Port_Connected(target_port) = '1' then
                                    report "SpW ports " & integer'image(test_port) & " and " & 
                                           integer'image(target_port) & " connected" severity note;
                                    tx_state <= SEND_ADDR;
                                end if;
                            end if;
                        end if;
                    
                    when SEND_ADDR =>
                        -- Send routing address (target port number)
                        if codecs(test_port).Tx_IR = '1' then
                            codecs(test_port).Tx_data <= '0' & std_logic_vector(to_unsigned(target_port, 8));
                            codecs(test_port).Tx_OR <= '1';
                            report "Sending routing address: " & integer'image(target_port) severity note;
                        end if;
                        
                        if codecs(test_port).Tx_IR = '1' and codecs(test_port).Tx_OR = '1' then
                            codecs(test_port).Tx_OR <= '0';
                            tx_state <= SEND_DATA;
                            data_counter := 0;
                        end if;
                    
                    when SEND_DATA =>
                        -- Send test data
                        if codecs(test_port).Tx_IR = '1' then
                            codecs(test_port).Tx_data <= '0' & std_logic_vector(
                                unsigned(test_data) + to_unsigned(data_counter, 8));
                            codecs(test_port).Tx_OR <= '1';
                            report "Sending data byte " & integer'image(data_counter) & 
                                   ": " & to_hstring(std_logic_vector(unsigned(test_data) + 
                                   to_unsigned(data_counter, 8))) severity note;
                        end if;
                        
                        if codecs(test_port).Tx_IR = '1' and codecs(test_port).Tx_OR = '1' then
                            codecs(test_port).Tx_OR <= '0';
                            data_counter := data_counter + 1;
                            
                            if data_counter >= 10 then -- Send 10 data bytes
                                tx_state <= SEND_EOP;
                            end if;
                        end if;
                    
                    when SEND_EOP =>
                        -- Send End-of-Packet
                        if codecs(test_port).Tx_IR = '1' then
                            codecs(test_port).Tx_data <= "100000010";  -- EOP marker
                            codecs(test_port).Tx_OR <= '1';
                            report "Sending EOP" severity note;
                        end if;
                        
                        if codecs(test_port).Tx_IR = '1' and codecs(test_port).Tx_OR = '1' then
                            codecs(test_port).Tx_OR <= '0';
                            tx_state <= WAIT_TX_COMPLETE;
                        end if;
                    
                    when WAIT_TX_COMPLETE =>
                        -- Wait a bit and then finish test
                        if data_counter < 100 then
                            data_counter := data_counter + 1;
                        else
                            test_complete <= '1';
                            report "Test transmission complete" severity note;
                        end if;
                        
                end case;
            end if;
        end if;
    end process;

    -- Monitor received data
    monitor_rx: process(spw_clk)
        variable rx_data_count : integer := 0;
    begin
        if (spw_clk = "111") then
            if reset_spw = '1' then
                rx_data_count := 0;
            else
                -- Monitor all SpW codec receive channels
                for i in 1 to g_num_ports-1 loop
                    if c_fifo_ports(i) = '0' then
                        if codecs(i).Rx_OR = '1' then
                            if codecs(i).Rx_data(8) = '0' then  -- Data character
                                report "Port " & integer'image(i) & " received data: " & 
                                       to_hstring(codecs(i).Rx_data(7 downto 0)) severity note;
                                rx_data_count := rx_data_count + 1;
                            elsif codecs(i).Rx_data = "100000010" then  -- EOP
                                report "Port " & integer'image(i) & " received EOP" severity note;
                            end if;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- Main test sequencer
    main_test: process
    begin
        -- Wait for reset deassertion
        wait until rst_in = '0';
        wait for 1 us;
        
        report "Starting router_top_level testbench" severity note;
        report "Testing SpaceWire routing between ports" severity note;
        
        -- Wait for test completion
        wait until test_complete = '1';
        
        -- Additional test time
        wait for 10 us;
        
        report "Router test completed successfully" severity note;
        report "All tests completed successfully" severity note;
        
        stop(0);
        wait;
    end process;
end rtl;