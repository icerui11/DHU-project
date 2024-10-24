library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

context work.spw_context;
use work.all;

entity DUT_16bitInput_tb is
end DUT_16bitInput_tb;

architecture behavior of DUT_16bitInput_tb is

    -- Component declarations
    component spw_TXlogic_top
        generic (
            g_clock_frequency : real := 100_000_000.0;
            g_rx_fifo_size    : integer range 16 to 56 := 56;
            g_tx_fifo_size    : integer range 16 to 56 := 56;
            g_addr_width      : integer := 9;
            g_data_width      : integer := 8;
            g_ram_depth       : integer := 3072;
            g_mode            : string := "single"
        );
        port (
            rst_n          : in  std_logic;
            clk            : in  std_logic;
            enable         : in  std_logic;
            rx_cmd_out     : out std_logic_vector(2 downto 0) := (others => '0');
            rx_cmd_valid   : out std_logic;
            rx_cmd_ready   : in  std_logic;
            rx_data_out    : out std_logic_vector(7 downto 0) := (others => '0');
            rx_data_valid  : out std_logic;
            rx_data_ready  : in  std_logic;
            spw_Din_p      : in  std_logic;
            spw_Din_n      : in  std_logic;
            spw_Sin_p      : in  std_logic;
            spw_Sin_n      : in  std_logic;
            spw_Dout_p     : out std_logic;
            spw_Dout_n     : out std_logic;
            spw_Sout_p     : out std_logic;
            spw_Sout_n     : out std_logic;
-- for tb
            spw_Connected_mon : out std_logic;
            spw_error      : out std_logic
        );
    end component;

    component DUT_16bitInput_noAHB
        port (
            Clk_AHB    : in  std_logic;
            Clk_S      : in  std_logic;
            Rst_AHB    : in  std_logic;
            Rst_N      : in  std_logic;
            rst_n_spw  : in  std_logic;
            spw_Din_n  : in  std_logic;
            spw_Din_p  : in  std_logic;
            spw_Sin_n  : in  std_logic;
            spw_Sin_p  : in  std_logic;
            ForceStop  : in  std_logic;                    -- tb forcestop the DUT
            Finished   : out std_logic;
            spw_Dout_p : out std_logic;
            spw_Sout_p : out std_logic
        );
    end component;

    -- Signals for clock and reset
    signal Clk_AHB : std_logic := '0';
    signal Clk_S   : std_logic := '0';
    signal Rst_AHB : std_logic := '0';
    signal Rst_N   : std_logic := '0';
    signal rst_n_spw : std_logic := '0';
    -- Signals for connecting the two modules
    signal spw_Din_p, spw_Din_n, spw_Sin_p, spw_Sin_n : std_logic;
    signal spw_Dout_p, spw_Dout_n, spw_Sout_p, spw_Sout_n : std_logic;
    signal spw_Dout_p_net, spw_Sout_p_net : std_logic;
    signal spw_Sout_p_txnet, spw_Dout_p_txnet : std_logic;

    -- Additional signals for the transmit module
    signal enable : std_logic := '0';
    signal rx_cmd_out : std_logic_vector(2 downto 0);
    signal rx_cmd_valid, rx_cmd_ready : std_logic;
    signal rx_data_out : std_logic_vector(7 downto 0);
    signal rx_data_valid, rx_data_ready : std_logic;
    signal spw_error : std_logic;

    signal spw_Connected_mon  : std_logic;

    signal ForceStop : std_logic := '0';                  -- for tb forcestop the DUT
    -- for file close
    signal Finished : std_logic;
    file     out_file			: text; 

    -- Clock period definitions
    constant Clk_AHB_period : time := 10 ns;
    constant Clk_S_period   : time := 10 ns;
    
begin

    -- Instantiate the transmit module (UUT)
    uut_transmit: spw_TXlogic_top
        generic map (
            g_clock_frequency => 100_000_000.0,
            g_rx_fifo_size    => 56,
            g_tx_fifo_size    => 56,
            g_addr_width      => 9,
            g_data_width      => 8,
            g_ram_depth       => 3072,
            g_mode            => "single"
        )
        port map (
            rst_n          => rst_n_spw,
            clk            => Clk_S,
            enable         => enable,
            rx_cmd_out     => rx_cmd_out,
            rx_cmd_valid   => rx_cmd_valid,
            rx_cmd_ready   => rx_cmd_ready,
            rx_data_out    => rx_data_out,
            rx_data_valid  => rx_data_valid,
            rx_data_ready  => rx_data_ready,
            spw_Din_p      => spw_Dout_p_net,              -- connect to DUT, receive compressed data
            spw_Din_n      => spw_Din_n,                   -- not used in single mode
            spw_Sin_p      => spw_Sout_p_net,
            spw_Sin_n      => spw_Sin_n,
            spw_Dout_p     => spw_Dout_p_txnet,           --transmit raw data to DUT
            spw_Dout_n     => spw_Dout_n,
            spw_Sout_p     => spw_Sout_p_txnet,
            spw_Sout_n     => spw_Sout_n,

            spw_Connected_mon => spw_Connected_mon,
            spw_error      => spw_error
        );

    -- Instantiate the DUT
    uut_dut: DUT_16bitInput_noAHB
        port map (
            Clk_AHB    => Clk_AHB,
            Clk_S      => Clk_S,
            Rst_AHB    => Rst_AHB,
            Rst_N      => Rst_N,
            rst_n_spw  => rst_n_spw,
            spw_Din_n  => spw_Din_n,
            spw_Din_p  => spw_Dout_p_txnet,
            spw_Sin_n  => spw_Sin_n,
            spw_Sin_p  => spw_Sout_p_txnet,
            ForceStop  => ForceStop,
            Finished   => Finished,
            spw_Dout_p => spw_Dout_p_net,  
            spw_Sout_p => spw_Sout_p_net
        );

    -- Clock process definitions
    Clk_AHB_process : process
    begin
        Clk_AHB <= '1';
        wait for Clk_AHB_period/2;
        Clk_AHB <= '0';
        wait for Clk_AHB_period/2;
    end process;

    Clk_S_process : process
    begin
        Clk_S <= '1';
        wait for Clk_S_period/2;
        Clk_S <= '0';
        wait for Clk_S_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        ForceStop <= '0';
        rst_n_spw <= '0';
        Rst_AHB <= '0';
        Rst_N <= '0';
        wait for 10 ns;     -- Hold SPW reset state for 12.8 us
        rst_n_spw <= '1';
       wait for 12.9 us;     -- Hold SPW reset state for 12.8 us



        -- Enable the transmit module
        enable <= '1';

        -- Simulate some data transmission
        rx_cmd_ready <= '1';
        rx_data_ready <= '1';
        wait until spw_Connected_mon = '1'; 
        Rst_AHB <= '1';
        Rst_N <= '1';   

        wait;
    end process;

    ccsds_datawrite : process(Clk_S, Rst_N)
    variable ini: integer := 0;
    variable fin: integer := 0;
    variable uns: unsigned(7 downto 0);                           
    variable line_in : line;
--    variable vect_out : std_logic_vector(g_data_width-1 downto 0);
    variable cnt: integer := 0;
    variable hex_str: string(1 to 2); -- String for two hex characters
    variable out_str: string(1 to 3); -- Two hex characters plus a space
 --   file out_file : text;
begin
    if rising_edge(Clk_S) then
        if Rst_N = '0' then
            ini := 0;
            fin := 0;
            cnt := 0;
        elsif rx_data_valid = '1' and fin = 0 then
            if ini = 0 then 
                file_open(out_file, "C:\Users\yinrui\Desktop\Envison_DHU\rawdata\compressed_data\16bitBIPinc.txt", write_mode);
                ini := 1;
            end if;

            -- Convert the output to unsigned
            uns := unsigned(rx_data_out);

            -- Convert unsigned to hex string and capture relevant part for 8-bit data
            hex_str := to_hstring(uns);
            out_str(1) := hex_str(hex_str'length - 1);
            out_str(2) := hex_str(hex_str'length);
            out_str(3) := ' ';  -- Add space character

            -- Write the output string to the line buffer
            write(line_in, out_str);

            -- Increment the counter
            cnt := cnt + 1;

            -- Check if it's time to write a new line
            if cnt mod 16 = 0 then
                writeline(out_file, line_in);
                line_in.all := ""; -- Clear the line buffer
            end if;

            -- Check if reached the specified depth
            if Finished = '1' then                      --Finished indicate the ccsds compress done
                -- Write any remaining data in the buffer to the file
                if line_in'length > 0 then
                    writeline(out_file, line_in);
                end if;
                file_close(out_file);
                fin := 1;  -- Set the fin flag
                ini := 0;  -- Reset the ini
                cnt := 0;  -- Reset the counter
            end if;
        end if;
    end if;
end process;

end behavior;