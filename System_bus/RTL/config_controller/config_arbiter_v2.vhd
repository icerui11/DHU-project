-- AHB Master Controller Compression Arbiter
-- Compressor Configuration Arbiter
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 2.00                                                ==--
--== Conception ... July 2025                                            ==--
-- Individual arbitration for each configuration target
-- 5 targets: HR_123, HR_121, LR_123, LR_121, H_121

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library config_controller;
use config_controller.config_pkg.all;

entity config_arbiter_v2 is
    generic (
        g_ram_addr_width : integer := c_output_addr_width               -- RAM address width
    );
    port (
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        
        -- Compressor Status Interface
        compressor_status_HR : in compressor_status;
        compressor_status_LR : in compressor_status;
        compressor_status_H  : in compressor_status;
        
        -- Configuration Control Interface
        config_done     : in  std_logic;  -- Configuration completed 
        config_req      : out std_logic;  -- Request configuration 
        
        start_add       : out  std_logic_vector(g_ram_addr_width-1 downto 0);  -- Start address for configuration read
        read_num        : out  integer range 0 to 6;   -- Number of CFG to read

        -- AHB target address (single output since we arbitrate individually)
        ahb_target_addr : out std_logic_vector(31 downto 0);  -- Current target AHB address

        -- Grant Interface (expanded for 5 targets)
        grant           : out std_logic_vector(2 downto 0);  -- "000": HR_123, "001": HR_121, "010": LR_123, "011": LR_121, "100": H_121, "111": None
        grant_valid     : out std_logic 
    );
end entity;

architecture rtl of config_arbiter_v2 is
    -- Grant encoding for 5 individual targets
    constant GRANT_HR_123   : std_logic_vector(2 downto 0) := "000";  -- HR CCSDS123
    constant GRANT_HR_121   : std_logic_vector(2 downto 0) := "001";  -- HR CCSDS121
    constant GRANT_LR_123   : std_logic_vector(2 downto 0) := "010";  -- LR CCSDS123
    constant GRANT_LR_121   : std_logic_vector(2 downto 0) := "011";  -- LR CCSDS121
    constant GRANT_H_121    : std_logic_vector(2 downto 0) := "100";  -- H CCSDS121
    constant GRANT_NONE     : std_logic_vector(2 downto 0) := "111";  -- No grant

    -- Internal signals for tracking configuration status
    type config_status_array is array (0 to 2) of std_logic;
    signal config_pending : config_status_array;  -- Track which configs are pending
    signal config_active  : std_logic;            -- Currently configuring
    signal current_grant  : std_logic_vector(2 downto 0);
    signal rr_counter     : unsigned(2 downto 0); -- Round-robin counter (0-4)

    -- Helper function to determine if a specific config is needed
    function is_config_needed(
        compressor_status : compressor_status;
        target_index      : integer
    ) return std_logic is
    begin
        -- All configs are needed when AwaitingConfig is set
        if compressor_status.AwaitingConfig = '1' then
            return '1';
        else
            return '0';
        end if;
    end function;

begin
    -- Update pending configuration requests
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            config_pending <= (others => '0');
        elsif rising_edge(clk) then
            -- Update pending status based on compressor status
            -- HR needs both CCSDS123 and CCSDS121
            config_pending(0) <= is_config_needed(compressor_status_HR, 0);  -- HR_123
  --          config_pending(1) <= is_config_needed(compressor_status_HR, 1);  -- HR_121
            
            -- LR needs both CCSDS123 and CCSDS121
            config_pending(1) <= is_config_needed(compressor_status_LR, 1);  -- LR_123
 --           config_pending(3) <= is_config_needed(compressor_status_LR, 3);  -- LR_121
            
            -- H only needs CCSDS121
            config_pending(2) <= is_config_needed(compressor_status_H, 2);   -- H_121
        end if;
    end process;

    -- Main arbitration process
    process(clk, rst_n)
        variable grant_found : std_logic;
        variable temp_counter : unsigned(2 downto 0);
    begin
        if rst_n = '0' then
            config_active <= '0';
            read_num <= 0;                       
            current_grant <= GRANT_NONE;
            rr_counter <= "000";                   -- Start from HR_123
            start_add <= (others => '0');
            ahb_target_addr <= (others => '0');
        elsif rising_edge(clk) then
            if config_done = '1' then             -- Configuration completion
                config_active <= '0';
                -- Clear the pending flag for completed configuration
                case current_grant is
                    when GRANT_HR_123 => config_pending(0) <= '0';
                    when GRANT_HR_121 => config_pending(1) <= '0';
                    when GRANT_LR_123 => config_pending(2) <= '0';
                    when GRANT_LR_121 => config_pending(3) <= '0';
                    when GRANT_H_121  => config_pending(4) <= '0';
                    when others => null;
                end case;
                
                -- Advance round-robin counter
                if rr_counter = 4 then
                    rr_counter <= "000";
                else
                    rr_counter <= rr_counter + 1;
                end if;
            end if;
            
            -- Round-robin arbitration for individual targets
            if config_active = '0' then
                grant_found := '0';
                temp_counter := rr_counter;
                
                -- Check all 5 possible grants in round-robin order
                for i in 0 to 4 loop
                    if grant_found = '0' then
                        case temp_counter is
                            when "000" =>  -- HR_123
                                if config_pending(0) = '1' then
                                    current_grant <= GRANT_HR_123;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= "00000";              -- HR config start address
                                    read_num <= 6;                     -- Read 6 registers for CCSDS123
                                    ahb_target_addr <= x"20000000";    -- CCSDS123 address for HR
                                end if;
                                
                            when "001" =>  -- HR_121
                                if config_pending(1) = '1' then
                                    current_grant <= GRANT_HR_121;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= "00101";              -- HR config start address + offset
                                    read_num <= 4;                     -- Read 4 registers for CCSDS121
                                    ahb_target_addr <= x"10000000";    -- CCSDS121 address for HR
                                end if;
                                
                            when "010" =>  -- LR_123
                                if config_pending(2) = '1' then
                                    current_grant <= GRANT_LR_123;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= "01010";              -- LR config start address
                                    read_num <= 6;                     -- Read 6 registers for CCSDS123
                                    ahb_target_addr <= x"40000000";    -- CCSDS123 address for LR
                                end if;
                                
                            when "011" =>  -- LR_121
                                if config_pending(3) = '1' then
                                    current_grant <= GRANT_LR_121;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= "01111";              -- LR config start address + offset
                                    read_num <= 4;                     -- Read 4 registers for CCSDS121
                                    ahb_target_addr <= x"50000000";    -- CCSDS121 address for LR
                                end if;
                                
                            when "100" =>  -- H_121
                                if config_pending(4) = '1' then
                                    current_grant <= GRANT_H_121;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= "10100";              -- H config start address
                                    read_num <= 4;                     -- Read 4 registers for H
                                    ahb_target_addr <= x"70000000";    -- CCSDS121 address for H
                                end if;
                                
                            when others =>  -- No grant
                                current_grant <= GRANT_NONE;
                                config_active <= '0';
                                grant_found := '0';
                        end case;
                        
                        -- Advance to next target in round-robin
                        if temp_counter = 4 then
                            temp_counter := "000";
                        else
                            temp_counter := temp_counter + 1;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    -- Output assignments
    grant <= current_grant;
    grant_valid <= config_active;
    config_req <= config_active;

end architecture;