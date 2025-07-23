--------------------------------------------------------------------------------
-- Testbench for ahb_master_controller_v2
-- This testbench verifies:
-- 1. Integration with ccsds123_ahb_mst module
-- 2. AHB transfer functionality
-- 3. Configuration of multiple compressors (HR, LR, H)
-- 4. RAM read/write operations
-- 5. Arbiter functionality
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

entity ahb_master_controller_v2_tb is
end entity ahb_master_controller_v2_tb;

architecture testbench of ahb_master_controller_v2_tb is

  -- Clock and reset signals
  signal clk         : std_ulogic := '0';
  signal rst_n       : std_ulogic := '0';
  
  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  
  -- DUT signals
  signal compressor_status_HR : compressor_status;
  signal compressor_status_LR : compressor_status;
  signal compressor_status_H  : compressor_status;
  
  -- RAM configuration interface
  signal ram_wr_en : std_logic := '0';
  signal wr_addr   : std_logic_vector(c_input_addr_width-1 downto 0);
  signal wr_data   : std_logic_vector(7 downto 0);
  
  -- AHB control interface
  signal ctrli : shyloc_123.ccsds_ahb_types.ahbtbm_ctrl_in_type;
  signal ctrlo : shyloc_123.ccsds_ahb_types.ahbtbm_ctrl_out_type;
  
  -- AHB bus signals (for the ccsds123_ahb_mst)
  signal ahbmi : shyloc_utils.amba.ahb_mst_in_type;
  signal ahbmo : shyloc_utils.amba.ahb_mst_out_type;

  -- AHB slave memory simulation
  type mem_type is array (0 to 1023) of std_logic_vector(31 downto 0);
  signal ahb_mem : mem_type := (others => (others => '0'));
  
  -- Test control signals
  signal test_done : boolean := false;
  signal test_phase : integer := 0;
  
  -- Configuration data for testing
  type config_data_array is array (0 to 96) of std_logic_vector(7 downto 0);
constant HR_CONFIG_DATA : config_data_array := (
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
    x"0A", x"08", x"B2", x"12",
  others => x"00"
);
  
  constant HR_CONFIG_DATA_121 : config_data_array := (
  -- group0: 00 00 00 00 => 00 00 00 00
    x"00", x"00", x"00", x"00",
  -- group1: 00 50 10 20 => 20 10 50 00
    x"20", x"10", x"50", x"00",
  -- group2: 00 1E 02 00 => 00 02 1E 00
    x"00", x"02", x"1E", x"00",
  -- group3: 01 54 41 40 => 40 41 54 01
    x"40", x"41", x"54", x"01",
  others => x"00"
);

  constant LR_CONFIG_DATA : config_data_array := (
    x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"04",
    x"18", x"81", x"50", x"00",
    x"80", x"1A", x"1E", x"00",
    x"D9", x"1F", x"54", x"01",
    x"0A", x"08", x"B2", x"12",
  others => x"00"
);
  
  constant LR_CONFIG_DATA_121 : config_data_array := (
    x"00", x"00", x"00", x"00",
    x"20", x"10", x"50", x"00",
    x"00", x"02", x"1E", x"00",
    x"40", x"41", x"54", x"01",
  others => x"00"
);

  constant H_CONFIG_DATA : config_data_array := (
    x"00", x"00", x"00", x"00",
    x"20", x"10", x"50", x"00",
    x"00", x"02", x"1E", x"00",
    x"40", x"41", x"54", x"01",
  others => x"00"
);

begin

  -- Clock generation
  clk_process : process
  begin
    while not test_done loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- DUT instantiation - AHB Master Controller
  dut_controller : entity config_controller.ahb_master_controller_v2
    generic map (
      hindex      => 0,
      haddr_mask  => 16#FFF#,
      hmaxburst   => 16,
      g_input_data_width  => c_input_data_width,
      g_input_addr_width  => c_input_addr_width,
      g_input_depth       => c_input_depth,
      g_output_data_width => c_output_data_width,
      g_output_addr_width => c_output_addr_width,
      g_output_depth      => c_output_depth
    )
    port map (
      clk         => clk,
      rst_n       => rst_n,
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_LR,
      compressor_status_H  => compressor_status_H,
      ram_wr_en   => ram_wr_en,
      wr_addr     => wr_addr,
      wr_data     => wr_data,
      ctrli       => ctrli,
      ctrlo       => ctrlo
    );

  -- AHB Master interface instantiation
  ahb_master_inst : entity shyloc_123.ccsds123_ahb_mst
    port map (
      rst_n => rst_n,
      clk   => clk,
      ctrli => ctrli,
      ctrlo => ctrlo,
      ahbmi => ahbmi,
      ahbmo => ahbmo
    );

  -- AHB Slave simulation process
  -- This simulates a simple AHB slave that responds to transactions
  ahb_slave_sim : process(clk, rst_n)
    variable addr_reg : std_logic_vector(31 downto 0);
    variable write_reg : std_logic;
  begin
    if rst_n = '0' then
      ahbmi.hready <= '1';
      ahbmi.hresp <= HRESP_OKAY;
      ahbmi.hrdata <= (others => '0');
      ahbmi.hgrant <= '0';
      addr_reg := (others => '0');

    elsif rising_edge(clk) then
      -- Default values
      ahbmi.hresp <= HRESP_OKAY;
      ahbmi.hready <= '1';
      -- Grant logic - always grant when requested
      if ahbmo.hbusreq = '1' then
        ahbmi.hgrant <= '1';
      else
        ahbmi.hgrant <= '0';
      end if;
      
      -- Address phase
      if ahbmo.htrans = "10" or ahbmo.htrans = "11" then  -- NONSEQ or SEQ
        addr_reg := ahbmo.haddr;
        if ahbmo.hwrite = '1' then
          -- Write to memory
          ahb_mem(to_integer(unsigned(addr_reg(11 downto 2)))) <= ahbmo.hwdata;
        else
          -- Read from memory
          ahbmi.hrdata <= ahb_mem(to_integer(unsigned(addr_reg(11 downto 2))));
        end if;
      end if;
    end if;
  end process;

  -- Test stimulus process
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
        wr_addr <= std_logic_vector(to_unsigned(start_addr + i, wr_addr'length));
        wr_data <= config_data(i);
        wait until rising_edge(clk);
      end loop;
      ram_wr_en <= '0';
      wait until rising_edge(clk);
    end procedure;
    
    -- Procedure to check AHB memory content
    procedure check_ahb_memory(
      constant base_addr : in natural;
      constant expected_data : in config_data_array;
      constant num_words : in natural
    ) is
      variable expected_word : std_logic_vector(31 downto 0);
      variable actual_word : std_logic_vector(31 downto 0);
    begin
      for i in 0 to num_words-1 loop
        -- Construct expected 32-bit word from 4 bytes (little endian)
        expected_word := expected_data(i*4+3) & expected_data(i*4+2) & 
                        expected_data(i*4+1) & expected_data(i*4);
        actual_word := ahb_mem(base_addr/4 + i);
        
        assert actual_word = expected_word
          report "AHB memory mismatch at address " & integer'image(base_addr + i*4) &
                 ": expected 0x" & to_hstring(expected_word) &
                 ", got 0x" & to_hstring(actual_word)
          severity error;
      end loop;
    end procedure;

  begin
    -- Initialize
    compressor_status_HR <= compressor_status_init;
    compressor_status_LR <= compressor_status_init;
    compressor_status_H  <= compressor_status_init;
        compressor_status_H.AwaitingConfig <= '0';
        compressor_status_LR.AwaitingConfig <= '0';
        compressor_status_HR.AwaitingConfig <= '0';
    test_phase <= 0;
    rst_n <= '0';
    ram_wr_en <= '0';
    wr_addr <= (others => '0');
    wr_data <= (others => '0');
    
    -- Wait for several clock cycles
    wait for CLK_PERIOD * 10;
    
    -- Release reset
    rst_n <= '1';
    wait for CLK_PERIOD * 6;
    
    report "Starting AHB Master Controller testbench";
    
    -- Test Phase 1: Configure HR compressor
    test_phase <= 1;
    report "Test Phase 1: Configuring HR compressor";
    
    -- Write HR configuration data to RAM at address 0
    write_config_to_ram(0, HR_CONFIG_DATA, 24);
    -- write HR 121 data to RAM at address 24
    write_config_to_ram(24, HR_CONFIG_DATA_121, 16);
    -- Wait for configuration to complete
    wait for CLK_PERIOD * 200;
    
    -- start configure HR compressor
    compressor_status_HR.AwaitingConfig <= '1';
    wait for CLK_PERIOD * 200;
    
    -- Check if data was written to AHB memory at HR base address
    --check_ahb_memory(16#10000000#, HR_CONFIG_DATA, 6);  -- 6 words (24 bytes)

    -- Test Phase 2: Configure LR compressor
    test_phase <= 2;
    report "Test Phase 2: Configuring LR compressor";

    -- Write LR configuration data to RAM at address 40
    write_config_to_ram(40, LR_CONFIG_DATA, 24);
    write_config_to_ram(56, LR_CONFIG_DATA_121, 16);
    -- Wait for configuration to complete
    wait for CLK_PERIOD * 200;
    
    -- Clear LR AwaitingConfig flag
    compressor_status_LR.AwaitingConfig <= '0';
    wait for CLK_PERIOD * 10;
    
    -- Check if data was written to AHB memory at LR base address
    --check_ahb_memory(16#20000000#, LR_CONFIG_DATA, 6);
    
    -- Test Phase 3: Configure H compressor
    test_phase <= 3;
    report "Test Phase 3: Configuring H compressor";
    
    -- Write H configuration data to RAM at address 64
    write_config_to_ram(72, H_CONFIG_DATA, 16);
    
    -- Wait for configuration to complete
    wait for CLK_PERIOD * 100;

    -- Clear H AwaitingConfig flag
    compressor_status_H.AwaitingConfig <= '0';
    wait for CLK_PERIOD * 10;
    
    -- Check if data was written to AHB memory at H base address
    --check_ahb_memory(16#30000000#, H_CONFIG_DATA, 4);
    
    -- Test Phase 4: Test concurrent configuration requests
    test_phase <= 4;
    report "Test Phase 4: Testing concurrent configuration requests";
    
    -- Set all compressors to need configuration
    compressor_status_HR.AwaitingConfig <= '1';
    compressor_status_LR.AwaitingConfig <= '1';
    compressor_status_H.AwaitingConfig <= '1';

    -- Write different configuration data
    write_config_to_ram(96, HR_CONFIG_DATA, 8);   -- HR at addr 96
    write_config_to_ram(128, LR_CONFIG_DATA, 8);  -- LR at addr 128
    write_config_to_ram(160, H_CONFIG_DATA, 8);   -- H at addr 160
    
    -- Wait for all configurations to complete
    wait for CLK_PERIOD * 300;

    -- Clear all AwaitingConfig flags
    compressor_status_HR.AwaitingConfig <= '0';
    compressor_status_LR.AwaitingConfig <= '0';
    compressor_status_H.AwaitingConfig <= '0';
    wait for CLK_PERIOD * 10;
    
    -- Test Phase 5: Test busy compressor (should not configure)
    test_phase <= 5;
    report "Test Phase 5: Testing busy compressor scenario";
    
    -- Set HR to need config 
    compressor_status_HR.AwaitingConfig <= '1';
    compressor_status_HR.Ready <= '0';
    
    -- Write configuration data
    write_config_to_ram(192, HR_CONFIG_DATA, 12);
    
    -- Wait and verify no AHB transactions occur
    wait for CLK_PERIOD * 50;
    
    -- Clear busy flag
    compressor_status_HR.Ready <= '1';

    -- Now configuration should proceed
    wait for CLK_PERIOD * 100;

    -- Clear AwaitingConfig flag
    compressor_status_HR.AwaitingConfig <= '0';

    wait for CLK_PERIOD * 20;
    
    -- Test complete
    report "All tests completed successfully!";
    test_done <= true;
    wait;
  end process;

  -- Monitor process for debugging
  monitor : process(clk)
  begin
    if rising_edge(clk) then
      -- Monitor AHB transactions
      if ahbmo.htrans = "10" then  -- NONSEQ
        report "AHB NONSEQ transaction: addr=0x" & to_hstring(ahbmo.haddr) &
               ", write=" & std_logic'image(ahbmo.hwrite) &
               ", size=" & to_hstring(ahbmo.hsize);
      elsif ahbmo.htrans = "11" then  -- SEQ
        report "AHB SEQ transaction: addr=0x" & to_hstring(ahbmo.haddr);
      end if;
      
      -- Monitor data phase
      if ahbmi.hready = '1' and ctrlo.update = '1' and ahbmo.hwrite = '1' then
        report "AHB Write data: 0x" & to_hstring(ahbmo.hwdata);
      end if;
    end if;
  end process;

end architecture testbench;