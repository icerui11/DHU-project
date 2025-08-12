-- AHB Master Controller Compression Arbiter (Synthesis-Friendly Multi-Stage)
-- Compressor Configuration Arbiter with Multi-Stage Per Compressor
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin (Modified for Synthesis with Enumerations)     ==--
--== Project ...... Compression Core Configuration                         ==--
--== Version ...... 3.02 (Enumeration-Based State Machine)                ==--
--== Conception ... June 2025                                               ==--
-- Functional Description:
-- Three-compressor arbitration (HR, LR, H) with multi-stage configuration
-- HR: CCSDS123 -> CCSDS121 (2 stages)
-- LR: CCSDS123 -> CCSDS121 (2 stages) 
-- H:  CCSDS121 only (1 stage)
-- Synthesis-friendly implementation with enumeration types

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library config_controller;
use config_controller.config_pkg.all;

entity config_arbiter_v3 is
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
        read_num        : out  integer range 0 to 10;   -- Number of CFG to read

        -- AHB target address 
        ahb_target_addr : out std_logic_vector(31 downto 0);  -- Current target AHB address

        -- Grant Interface (3 compressors)
        grant           : out std_logic_vector(1 downto 0);  -- "00": HR, "01": LR, "10": H, "11": None
        grant_valid     : out std_logic 
    );
end entity;

architecture rtl of config_arbiter_v3 is
    -- Grant encoding for 3 compressors (keep as constants for output interface)
    constant GRANT_HR       : std_logic_vector(1 downto 0) := "00";  -- HR compressor
    constant GRANT_LR       : std_logic_vector(1 downto 0) := "01";  -- LR compressor  
    constant GRANT_H        : std_logic_vector(1 downto 0) := "10";  -- H compressor
    constant GRANT_NONE     : std_logic_vector(1 downto 0) := "11";  -- No grant

    -- Enumeration type for configuration stages
    -- This makes the code more readable and allows synthesis tools to optimize better
    type config_stage_type is (
        STAGE_IDLE,      -- Initial state, no configuration active
        STAGE_CCSDS123,  -- Configuring CCSDS123 compression stage
        STAGE_CCSDS121,  -- Configuring CCSDS121 compression stage  
        STAGE_COMPLETE   -- All stages completed for current compressor
    );
    
    -- Enumeration type for main state machine
    -- Clear separation of concerns: idle -> arbitrate -> execute -> wait
    type config_state_type is (
        CONFIG_IDLE,        -- Waiting for configuration requests
        CONFIG_ARBITRATE,   -- Selecting which compressor gets access
        CONFIG_EXECUTE,     -- Setting up configuration parameters
        CONFIG_WAIT_DONE    -- Waiting for configuration completion
    );

    -- Enumeration type for compressor selection (internal use)
    -- This provides type safety and better readability than std_logic_vector
    type compressor_type is (
        COMP_HR,    -- High Resolution compressor
        COMP_LR,    -- Low Resolution compressor  
        COMP_H,     -- H compressor
        COMP_NONE   -- No compressor selected
    );

    -- Internal registers using enumeration types
    signal config_state_reg     : config_state_type;
    signal current_grant_reg    : compressor_type;
    signal current_stage_reg    : config_stage_type;
    signal rr_counter_reg       : unsigned(1 downto 0);  -- Round-robin counter (0-2 for HR, LR, H)
    signal config_active_reg    : std_logic;

    -- Configuration parameters (registered outputs for better timing)
    signal start_add_reg        : std_logic_vector(g_ram_addr_width-1 downto 0);
    signal read_num_reg         : integer range 0 to 10;
    signal ahb_target_addr_reg  : std_logic_vector(31 downto 0);

    -- Next state signals using enumeration types
    signal next_config_state    : config_state_type;
    signal next_current_grant   : compressor_type;
    signal next_current_stage   : config_stage_type;
    signal next_rr_counter      : unsigned(1 downto 0);
    signal next_config_active   : std_logic;

    -- Compressor request signals (combinational)
    signal hr_needs_config      : std_logic;
    signal lr_needs_config      : std_logic;
    signal h_needs_config       : std_logic;
    signal any_needs_config     : std_logic;

    -- Stage transition logic outputs
    signal grant_complete       : std_logic;
    signal next_stage_valid     : std_logic;
    
    -- Simplified arbitration signals (priority encoder based)
    signal arbitration_grant    : compressor_type;
    signal arbitration_valid    : std_logic;

begin
    
    -- Combinational logic for compressor configuration needs
    -- This replaces the function calls with direct signal assignments
    hr_needs_config <= compressor_status_HR.AwaitingConfig;
    lr_needs_config <= compressor_status_LR.AwaitingConfig;  
    h_needs_config  <= compressor_status_H.AwaitingConfig;
    any_needs_config <= hr_needs_config or lr_needs_config or h_needs_config;

    -- Combinational logic for stage completion detection
    -- Using enumeration comparison is more readable than bit pattern matching
    grant_complete <= '1' when current_stage_reg = STAGE_COMPLETE else '0';

    -- Next stage determination using enumeration types
    -- This is much clearer than bit pattern comparisons
    next_stage_determination: process(current_grant_reg, current_stage_reg,config_done)
    begin
        case current_grant_reg is
            when COMP_HR | COMP_LR =>  -- HR and LR need both CCSDS123 and CCSDS121
                case current_stage_reg is
                    when STAGE_IDLE     => 
                        next_current_stage <= STAGE_CCSDS123;
                        next_stage_valid <= '1';
                    when STAGE_CCSDS123 => 
                        if config_done = '1' then
                            next_current_stage <= STAGE_CCSDS121;
                            next_stage_valid <= '1';
                        else
                            next_current_stage <= STAGE_CCSDS123;  -- Stay in CCSDS123 until done
                            next_stage_valid <= '0';
                        end if;
                    when STAGE_CCSDS121 => 
                        if config_done = '1' then
                            next_current_stage <= STAGE_COMPLETE;  -- All stages done
                            next_stage_valid <= '0';
                        else
                            next_current_stage <= STAGE_CCSDS121;  -- Stay in CCSDS121 until done
                            next_stage_valid <= '1';
                        end if;
                    when others         => 
                        next_current_stage <= STAGE_COMPLETE;
                        next_stage_valid <= '0';
                end case;
                
            when COMP_H =>              -- H only needs CCSDS121
                case current_stage_reg is
                    when STAGE_IDLE => 
                        next_current_stage <= STAGE_CCSDS121;
                        next_stage_valid <= '1';

                    when STAGE_CCSDS121 =>
                        if config_done = '1' then
                            next_current_stage <= STAGE_COMPLETE;  -- All stages done
                            next_stage_valid <= '0';
                        else
                            next_current_stage <= STAGE_CCSDS121;  -- Stay in CCSDS121 until done
                            next_stage_valid <= '1';
                        end if;

                    when others     => 
                        next_current_stage <= STAGE_COMPLETE;
                        next_stage_valid <= '0';
                end case;
                
            when others =>
                next_current_stage <= STAGE_IDLE;
                next_stage_valid <= '0';
        end case;
    end process;

    -- Configuration parameter setting using enumeration types
    -- Much more readable than decoding bit patterns
    config_param_setting: process(current_grant_reg, next_current_stage, next_stage_valid)
    begin
        -- Default values to ensure all signals are assigned
        start_add_reg <= (others => '0');
        read_num_reg <= 0;
        ahb_target_addr_reg <= (others => '0');

        if next_stage_valid = '1' then
            case current_grant_reg is
                when COMP_HR =>  -- HR compressor configuration
                    case next_current_stage is
                        when STAGE_CCSDS123 =>
                            start_add_reg <= "00000";           -- HR CCSDS123 config start address
                            read_num_reg <= 6;                  -- Read 6 registers for CCSDS123
                            ahb_target_addr_reg <= x"20000000"; -- CCSDS123 address for HR
                        when STAGE_CCSDS121 =>
                            start_add_reg <= "00110";           -- HR CCSDS121 config start address
                            read_num_reg <= 4;                  -- Read 4 registers for CCSDS121
                            ahb_target_addr_reg <= x"10000000"; -- CCSDS121 address for HR
                        when others =>
                            null; -- Keep default values
                    end case;
                    
                when COMP_LR =>  -- LR compressor configuration
                    case next_current_stage is
                        when STAGE_CCSDS123 =>
                            start_add_reg <= "01010";           -- LR CCSDS123 config start address
                            read_num_reg <= 6;                  -- Read 6 registers for CCSDS123
                            ahb_target_addr_reg <= x"50000000"; -- CCSDS123 address for LR
                        when STAGE_CCSDS121 =>
                            start_add_reg <= "10000";           -- LR CCSDS121 config start address
                            read_num_reg <= 4;                  -- Read 4 registers for CCSDS121
                            ahb_target_addr_reg <= x"40000000"; -- CCSDS121 address for LR
                        when others =>
                            null; -- Keep default values
                    end case;
                    
                when COMP_H =>   -- H compressor configuration
                    case next_current_stage is
                        when STAGE_CCSDS121 =>
                            start_add_reg <= "10100";           -- H CCSDS121 config start address
                            read_num_reg <= 4;                  -- Read 4 registers for H
                            ahb_target_addr_reg <= x"70000000"; -- CCSDS121 address for H
                        when others =>
                            null; -- Keep default values
                    end case;
                    
                when others =>
                    null; -- Keep default values
            end case;
        end if;
    end process;

    -- Simplified round-robin arbitration using priority encoder approach
    -- Now returns enumeration type instead of std_logic_vector
    rotated_priority: process(hr_needs_config, lr_needs_config, h_needs_config, rr_counter_reg)
        -- Create request vector: [H, LR, HR] (bit 2, 1, 0)
        variable request_vector : std_logic_vector(2 downto 0);
        -- Rotated request vectors for each round-robin position
        variable rotated_requests : std_logic_vector(2 downto 0);
        -- Grant vector after rotation
        variable grant_vector : std_logic_vector(2 downto 0);
    begin
        -- Build request vector (easier to work with as a vector)
        request_vector := h_needs_config & lr_needs_config & hr_needs_config;
        
        -- Rotate request vector based on round-robin counter
        -- This gives priority to different positions in rotation
        case rr_counter_reg is
            when "00" =>  -- HR has highest priority: [H, LR, HR]
                rotated_requests := request_vector;
            when "01" =>  -- LR has highest priority: [HR, H, LR] 
                rotated_requests := request_vector(0) & request_vector(2) & request_vector(1);
            when "10" =>  -- H has highest priority: [LR, HR, H]
                rotated_requests := request_vector(1) & request_vector(0) & request_vector(2);
            when others =>
                rotated_requests := request_vector;
        end case;
        
        -- Simple priority encoder: highest bit wins
        -- This eliminates the complex if-elsif chain!
        if rotated_requests(2) = '1' then
            grant_vector := "100";
        elsif rotated_requests(1) = '1' then  
            grant_vector := "010";
        elsif rotated_requests(0) = '1' then
            grant_vector := "001";
        else
            grant_vector := "000";
        end if;
        
        -- Convert grant vector back to compressor selection using enumeration
        -- This is much clearer than bit pattern assignments
        case rr_counter_reg is
            when "00" =>  -- No rotation needed
                if grant_vector(2) = '1' then      -- H granted
                    arbitration_grant <= COMP_H;
                elsif grant_vector(1) = '1' then   -- LR granted  
                    arbitration_grant <= COMP_LR;
                elsif grant_vector(0) = '1' then   -- HR granted
                    arbitration_grant <= COMP_HR;
                else
                    arbitration_grant <= COMP_NONE;
                end if;
                
            when "01" =>  -- Reverse rotation: [HR, H, LR] -> [H, LR, HR]
                if grant_vector(2) = '1' then      -- HR granted (was highest)
                    arbitration_grant <= COMP_HR;
                elsif grant_vector(1) = '1' then   -- H granted (was middle)
                    arbitration_grant <= COMP_H;
                elsif grant_vector(0) = '1' then   -- LR granted (was lowest)
                    arbitration_grant <= COMP_LR;
                else
                    arbitration_grant <= COMP_NONE;
                end if;
                
            when "10" =>  -- Reverse rotation: [LR, HR, H] -> [H, LR, HR]
                if grant_vector(2) = '1' then      -- LR granted (was highest)
                    arbitration_grant <= COMP_LR;
                elsif grant_vector(1) = '1' then   -- HR granted (was middle)
                    arbitration_grant <= COMP_HR;
                elsif grant_vector(0) = '1' then   -- H granted (was lowest)
                    arbitration_grant <= COMP_H;
                else
                    arbitration_grant <= COMP_NONE;
                end if;
                
            when others =>
                arbitration_grant <= COMP_NONE;
        end case;
        
        -- Set arbitration valid flag
        arbitration_valid <= '1' when grant_vector /= "000" else '0';
    end process;

    -- Main state machine next state logic using enumeration types
    -- Much more readable and maintainable than bit pattern comparisons
    next_state_logic: process(config_state_reg, any_needs_config, arbitration_valid, arbitration_grant,
                             grant_complete, config_done, next_stage_valid)
    begin
        -- Default assignments (important for synthesis - all signals must be assigned)
        next_config_state <= config_state_reg;  -- Hold current state
        next_current_grant <= current_grant_reg; -- Hold current grant
        next_rr_counter <= rr_counter_reg;      -- Hold current counter
        next_config_active <= '0';              -- Default to inactive

        case config_state_reg is
            when CONFIG_IDLE =>
                if any_needs_config = '1' then
                    next_config_state <= CONFIG_ARBITRATE;
                end if;

            when CONFIG_ARBITRATE =>
                -- Simple arbitration using the priority encoder result
                if arbitration_valid = '1' then
                    next_current_grant <= arbitration_grant;
                    next_config_state <= CONFIG_EXECUTE;
                else
                    next_current_grant <= COMP_NONE;
                    next_config_state <= CONFIG_IDLE;
                end if;

            when CONFIG_EXECUTE =>
                if grant_complete = '1' then
                    -- All stages complete for current compressor, advance round-robin
                    if rr_counter_reg = 2 then
                        next_rr_counter <= "00";
                    else
                        next_rr_counter <= rr_counter_reg + 1;
                    end if;
                    
                    next_config_state <= CONFIG_IDLE;
                    next_current_grant <= COMP_NONE;
                    next_config_active <= '0';
                elsif next_stage_valid = '1' then
                    -- Valid next stage exists, start configuration
                    next_config_active <= '1';
                    next_config_state <= CONFIG_WAIT_DONE;
                else
                    -- Invalid state, return to idle
                    next_config_state <= CONFIG_IDLE;
                    next_current_grant <= COMP_NONE;
                end if;

            when CONFIG_WAIT_DONE =>
                next_config_active <= '1';  -- Maintain active state
                if config_done = '1' then
                    next_config_active <= '0';
                    next_config_state <= CONFIG_EXECUTE;  -- Move to next stage
                end if;
                
            when others =>
                -- This should never happen with enumeration types, but good practice
                next_config_state <= CONFIG_IDLE;
                next_current_grant <= COMP_NONE;
        end case;
    end process;

    -- Registered state machine using enumeration types
    -- Reset values are much clearer with enumeration names
    state_registers: process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Clear reset state using enumeration literals
            config_state_reg <= CONFIG_IDLE;
            current_grant_reg <= COMP_NONE;
            current_stage_reg <= STAGE_IDLE;
            rr_counter_reg <= "00";           -- Start from HR
            config_active_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Registered updates on clock edge
            config_state_reg <= next_config_state;
            current_grant_reg <= next_current_grant;
            current_stage_reg <= next_current_stage;
            rr_counter_reg <= next_rr_counter;
            config_active_reg <= next_config_active;
        end if;
    end process;

    -- Output register process (improves timing closure)
    output_registers: process(clk, rst_n)
    begin
        if rst_n = '0' then
            start_add <= (others => '0');
            read_num <= 0;
            ahb_target_addr <= (others => '0');
        elsif rising_edge(clk) then
            -- Only update outputs when transitioning to active configuration
            if next_config_active = '1' and config_active_reg = '0' then
                start_add <= start_add_reg;
                read_num <= read_num_reg;
                ahb_target_addr <= ahb_target_addr_reg;
            end if;
        end if;
    end process;
    
    -- Output assignments with enumeration to std_logic_vector conversion
    -- This conversion function makes the interface mapping clear
    grant <= GRANT_HR   when current_grant_reg = COMP_HR and config_active_reg = '1' else
             GRANT_LR   when current_grant_reg = COMP_LR and config_active_reg = '1' else
             GRANT_H    when current_grant_reg = COMP_H  and config_active_reg = '1' else
             GRANT_NONE;
             
    grant_valid <= config_active_reg;
    config_req <= config_active_reg;

end architecture rtl;