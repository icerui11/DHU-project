-- AHB Master Controller Compression Arbiter
-- Compressor Configuration Arbiter
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... June 2025                                            ==--
-- Functional Description:
-- fest priority HR > LR > H 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.config_types_pkg.all;

entity config_arbiter is
    generic (
        g_ram_addr_width : integer := c_ram_addr_width;               -- RAM address width
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
        read_num        : out  integer range 0 to 10;   -- Number of CFG to read

        -- ahb w/r address
        ahb_base_addr_123   : out std_logic_vector(31 downto 0);  -- AHB base address for configuration
        ahb_base_addr_121   : out std_logic_vector(31 downto 0);  -- AHB base address for configuration

        -- Grant Interface
        grant           : out std_logic_vector(1 downto 0);  -- "00": HR, "01": LR, "10": H, "11": None
        grant_valid     : out std_logic 
    );
end entity;

architecture rtl of config_arbiter is
    constant GRANT_HR   : std_logic_vector(1 downto 0) := "00";  -- HR compressor
    constant GRANT_LR   : std_logic_vector(1 downto 0) := "01";  -- LR compressor
    constant GRANT_H    : std_logic_vector(1 downto 0) := "10";  -- H compressor
    constant GRANT_NONE : std_logic_vector(1 downto 0) := "11";  -- No grant

-- internal signals 
    signal hr_req, lr_req, h_req : std_logic;
    signal busy : std_logic;
    signal grant_reg : std_logic_vector(1 downto 0);

    signal config_active : std_logic;                             -- to start config 
    signal current_grant : std_logic_vector(1 downto 0);
    signal rr_counter    : unsigned(1 downto 0); 

begin
  process(clk, rst_n)
        variable grant_found : std_logic;
        variable temp_counter : unsigned(1 downto 0);
    begin
        if rst_n = '0' then
            config_active <= '0';
            read_num <= 0;                       
            current_grant <= GRANT_NONE;
            rr_counter <= "00";                   -- start from HR
        elsif rising_edge(clk) then
            if config_done = '1' then             -- Configuration completion, start round-robin arbitration
                config_active <= '0';
   --             current_grant <= GRANT_NONE;
                if rr_counter = 2 then
                    rr_counter <= "00";
                else
                    rr_counter <= rr_counter + 1;
                end if;
            end if;
            
            -- Round-robin arbitration
            if config_active = '0' then
                grant_found := '0';
                temp_counter := rr_counter;
                for i in 0 to 2 loop
                    if grant_found = '0' then
                        case temp_counter is
                            when "00" =>  -- HR
                                if compressor_status_HR.AwaitingConfig = '1' then
                                    current_grant <= GRANT_HR;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= x"00";                      -- Set start address for HR
                                    read_num <= 10;                      -- Read 10 registers for HR
                                    ahb_base_addr_123 <= x"20000000";                 -- w/r ahb base address 
                                    ahb_base_addr_121 <= x"1000000"; 
                                end if;
                            when "01" =>  -- LR
                                if compressor_status_LR.AwaitingConfig = '1' then
                                    current_grant <= GRANT_LR;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= x"30";                      -- Set start address for LR
                                    read_num <= 10;                      -- Read 7 registers for LR
                                    ahb_base_addr_123 <= x"4000000";                 -- w/r ahb base address 
                                    ahb_base_addr_121 <= x"5000000";   
                                end if;
                            when "10" =>  -- H
                                if compressor_status_H.AwaitingConfig = '1' then
                                    current_grant <= GRANT_H;
                                    config_active <= '1';
                                    grant_found := '1';
                                    start_add <= x"54";                      -- Set start address for V-H
                                    read_num <= 4;                      -- Read 3 registers for V-H
                                    ahb_base_addr_121 <= x"7000000";   
                                end if;
                            when others =>  -- No grant
                                current_grant <= GRANT_NONE;
                                config_active <= '0';
                                grant_found := '0';  -- No more grants available
                        end case;
                        
                        if temp_counter = 2 then                -- round again 
                            temp_counter := "00";
                        else
                            temp_counter := temp_counter + 1;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    grant <= current_grant;
    grant_valid <= config_active;
    config_req <= config_active;

end;