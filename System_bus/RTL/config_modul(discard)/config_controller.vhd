---====================== Start Copyright Notice ========================---
--==                                                                    ==--
--== Filename ..... configuration_controller.vhd                               ==--
--== Download ..... http://www.ida.ing.tu-bs.de                         ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Contact ......                                      ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... May 2025                                            ==--
--== Handles 8-bit GPIO to 32-bit AHB parameter translation           ==--
---=======================================================================---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library compression_config;
use compression_config.config_types.all;

entity configuration_controller is
    port (
        -- System signals
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        
        -- Configuration interface (from IO_bus)
        config_if_in    : in  config_write_if;
        config_if_out   : out config_read_if;
        
        -- AHB Master interface
        ahb_master_out  : out ahb_mst_out_type;
        ahb_master_in   : in  ahb_mst_in_type;
        
        -- Compression core status inputs
        ccsds121_ready  : in  std_logic;
        ccsds121_error  : in  std_logic;
        ccsds123_ready  : in  std_logic;
        ccsds123_error  : in  std_logic
    );
end entity;

architecture rtl of configuration_controller is

    -- Parameter memory signals
    signal param_mem_addr     : std_logic_vector(7 downto 0);
    signal param_mem_din      : std_logic_vector(7 downto 0);
    signal param_mem_dout     : std_logic_vector(7 downto 0);
    signal param_mem_we       : std_logic;
    
    -- Shadow memory signals (32-bit access)
    signal shadow_mem_addr    : std_logic_vector(5 downto 0);  -- 64 words max
    signal shadow_mem_din     : std_logic_vector(31 downto 0);
    signal shadow_mem_dout    : std_logic_vector(31 downto 0);
    signal shadow_mem_we      : std_logic;
    
    -- Control and status registers
    signal control_reg        : std_logic_vector(31 downto 0);
    signal status_reg         : std_logic_vector(31 downto 0);
    
    -- State machine
    signal current_state      : config_state_type;
    signal next_state         : config_state_type;
    
    -- Internal signals
    signal config_addr_int    : unsigned(7 downto 0);
    signal config_start       : std_logic;
    signal config_121_enable  : std_logic;
    signal config_123_enable  : std_logic;
    signal error_reset        : std_logic;
    
    -- AHB transaction control
    signal ahb_addr_reg       : std_logic_vector(31 downto 0);
    signal ahb_data_reg       : std_logic_vector(31 downto 0);
    signal ahb_write_req      : std_logic;
    signal ahb_busy           : std_logic;
    signal ahb_error          : std_logic;
    
    -- Shadow memory update control
    signal update_shadow      : std_logic;
    signal shadow_update_addr : unsigned(5 downto 0);
    signal shadow_update_done : std_logic;

begin

    --==========================================================================================
    -- Parameter Memory (8-bit width, 256 bytes)
    --==========================================================================================
    param_memory : entity work.parameter_mem
        generic map (
            ADDR_WIDTH => 8,
            DATA_WIDTH => 8,
            DEPTH      => 256
        )
        port map (
            clk    => clk,
            rst_n  => rst_n,
            addr   => param_mem_addr,
            din    => param_mem_din,
            dout   => param_mem_dout,
            we     => param_mem_we
        );

    --==========================================================================================
    -- Shadow Parameter Memory (32-bit width, 64 words)
    --==========================================================================================
    shadow_memory : entity work.parameter_mem_shadow
        generic map (
            ADDR_WIDTH => 6,
            DATA_WIDTH => 32,
            DEPTH      => 64
        )
        port map (
            clk    => clk,
            rst_n  => rst_n,
            addr   => shadow_mem_addr,
            din    => shadow_mem_din,
            dout   => shadow_mem_dout,
            we     => shadow_mem_we
        );

    --==========================================================================================
    -- Address decoding and register access
    --==========================================================================================
    config_addr_int <= unsigned(config_if_in.add);
    
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            control_reg <= (others => '0');
            param_mem_we <= '0';
            param_mem_addr <= (others => '0');
            param_mem_din <= (others => '0');
        elsif rising_edge(clk) then
            param_mem_we <= '0';  -- Default
            
            if config_if_in.write_en = '1' then
                if config_addr_int < 64 then  -- Parameter memory range (0x00-0x3F)
                    param_mem_addr <= config_if_in.add;
                    param_mem_din <= config_if_in.w_data(7 downto 0);  -- Only use lower 8 bits
                    param_mem_we <= '1';
                elsif config_addr_int >= unsigned(CONTROL_BASE_ADDR) and 
                      config_addr_int < unsigned(STATUS_BASE_ADDR) then  -- Control registers
                    control_reg <= config_if_in.w_data;
                end if;
            end if;
        end if;
    end process;
    
    -- Extract control signals
    config_121_enable <= control_reg(CTRL_ENABLE_121_BIT);
    config_123_enable <= control_reg(CTRL_ENABLE_123_BIT);
    config_start      <= control_reg(CTRL_START_CONFIG_BIT);
    error_reset       <= control_reg(CTRL_RESET_ERROR_BIT);

    --==========================================================================================
    -- Shadow memory update process (8-bit to 32-bit conversion)
    --==========================================================================================
    process(clk, rst_n)
        variable byte_addr : unsigned(7 downto 0);
        variable word_addr : unsigned(5 downto 0);
        variable byte_offset : unsigned(1 downto 0);
        variable word_data : std_logic_vector(31 downto 0);
    begin
        if rst_n = '0' then
            update_shadow <= '0';
            shadow_update_addr <= (others => '0');
            shadow_update_done <= '0';
            shadow_mem_we <= '0';
        elsif rising_edge(clk) then
            shadow_mem_we <= '0';  -- Default
            
            if update_shadow = '1' then
                -- Convert 4 consecutive bytes to one 32-bit word
                byte_addr := shadow_update_addr & "00";  -- Word boundary
                word_addr := shadow_update_addr;
                
                -- Read 4 bytes and combine them
                -- This is a simplified version - in practice you'd need a more complex FSM
                -- to read the 4 bytes sequentially from param_mem
                param_mem_addr <= std_logic_vector(byte_addr);
                
                -- For now, assume we can read all 4 bytes in one cycle (simplified)
                word_data := param_mem_dout & param_mem_dout & param_mem_dout & param_mem_dout;
                
                shadow_mem_addr <= std_logic_vector(word_addr);
                shadow_mem_din <= word_data;
                shadow_mem_we <= '1';
                
                if shadow_update_addr = 15 then  -- Updated all 16 words (64 bytes / 4)
                    shadow_update_done <= '1';
                    update_shadow <= '0';
                else
                    shadow_update_addr <= shadow_update_addr + 1;
                end if;
            end if;
            
            if config_start = '1' then
                update_shadow <= '1';
                shadow_update_addr <= (others => '0');
                shadow_update_done <= '0';
            end if;
        end if;
    end process;

    --==========================================================================================
    -- Configuration State Machine
    --==========================================================================================
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    process(current_state, config_start, shadow_update_done, config_121_enable, 
            config_123_enable, ahb_master_in.hready, ahb_master_in.hresp,
            ccsds121_ready, ccsds123_ready, error_reset)
    begin
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if config_start = '1' then
                    next_state <= READ_PARAMS;
                end if;
                
            when READ_PARAMS =>
                if shadow_update_done = '1' then
                    if config_121_enable = '1' then
                        next_state <= WRITE_121_CONFIG;
                    elsif config_123_enable = '1' then
                        next_state <= WRITE_123_CONFIG;
                    else
                        next_state <= IDLE;
                    end if;
                end if;
                
            when WRITE_121_CONFIG =>
                if ahb_master_in.hready = '1' then
                    if ahb_master_in.hresp = "00" then  -- OK
                        if config_123_enable = '1' then
                            next_state <= WRITE_123_CONFIG;
                        else
                            next_state <= CHECK_STATUS;
                        end if;
                    else
                        next_state <= ERROR_STATE;
                    end if;
                end if;
                
            when WRITE_123_CONFIG =>
                if ahb_master_in.hready = '1' then
                    if ahb_master_in.hresp = "00" then  -- OK
                        next_state <= CHECK_STATUS;
                    else
                        next_state <= ERROR_STATE;
                    end if;
                end if;
                
            when CHECK_STATUS =>
                if (config_121_enable = '0' or ccsds121_ready = '1') and
                   (config_123_enable = '0' or ccsds123_ready = '1') then
                    next_state <= IDLE;
                elsif ccsds121_error = '1' or ccsds123_error = '1' then
                    next_state <= ERROR_STATE;
                end if;
                
            when ERROR_STATE =>
                if error_reset = '1' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;

    --==========================================================================================
    -- AHB Master transaction control
    --==========================================================================================
    process(clk, rst_n)
        variable config_word_addr : unsigned(5 downto 0);
    begin
        if rst_n = '0' then
            ahb_master_out.haddr  <= (others => '0');
            ahb_master_out.htrans <= "00";  -- IDLE
            ahb_master_out.hwrite <= '0';
            ahb_master_out.hsize  <= "010"; -- 32-bit
            ahb_master_out.hburst <= "000"; -- SINGLE
            ahb_master_out.hwdata <= (others => '0');
            config_word_addr := (others => '0');
        elsif rising_edge(clk) then
            ahb_master_out.htrans <= "00";  -- Default IDLE
            
            case current_state is
                when WRITE_121_CONFIG =>
                    if config_word_addr < 4 then  -- 4 words for CCSDS121
                        ahb_master_out.haddr <= std_logic_vector(unsigned(CCSDS121_AHB_ADDR) + 
                                                                (config_word_addr * 4));
                        shadow_mem_addr <= std_logic_vector(config_word_addr);
                        ahb_master_out.hwdata <= shadow_mem_dout;
                        ahb_master_out.htrans <= "10";  -- NONSEQ
                        ahb_master_out.hwrite <= '1';
                        
                        if ahb_master_in.hready = '1' then
                            config_word_addr := config_word_addr + 1;
                        end if;
                    end if;
                    
                when WRITE_123_CONFIG =>
                    if config_word_addr < 6 then  -- 6 words for CCSDS123
                        ahb_master_out.haddr <= std_logic_vector(unsigned(CCSDS123_AHB_ADDR) + 
                                                                (config_word_addr * 4));
                        shadow_mem_addr <= std_logic_vector(config_word_addr + 4);  -- Offset by CCSDS121 size
                        ahb_master_out.hwdata <= shadow_mem_dout;
                        ahb_master_out.htrans <= "10";  -- NONSEQ
                        ahb_master_out.hwrite <= '1';
                        
                        if ahb_master_in.hready = '1' then
                            config_word_addr := config_word_addr + 1;
                        end if;
                    end if;
                    
                when others =>
                    config_word_addr := (others => '0');
            end case;
        end if;
    end process;

    --==========================================================================================
    -- Status register generation
    --==========================================================================================
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            status_reg <= (others => '0');
        elsif rising_edge(clk) then
            status_reg(STAT_CONFIG_DONE_BIT) <= '1' when current_state = IDLE else '0';
            status_reg(STAT_CONFIG_ERROR_BIT) <= '1' when current_state = ERROR_STATE else '0';
            status_reg(STAT_121_READY_BIT) <= ccsds121_ready;
            status_reg(STAT_123_READY_BIT) <= ccsds123_ready;
            status_reg(STAT_121_ERROR_BIT) <= ccsds121_error;
            status_reg(STAT_123_ERROR_BIT) <= ccsds123_error;
        end if;
    end process;

    --==========================================================================================
    -- Read data multiplexer
    --==========================================================================================
    process(config_addr_int, param_mem_dout, control_reg, status_reg)
    begin
        config_if_out.r_data <= (others => '0');
        
        if config_addr_int < 64 then  -- Parameter memory
            config_if_out.r_data(7 downto 0) <= param_mem_dout;
        elsif config_addr_int >= unsigned(CONTROL_BASE_ADDR) and 
              config_addr_int < unsigned(STATUS_BASE_ADDR) then  -- Control register
            config_if_out.r_data <= control_reg;
        elsif config_addr_int >= unsigned(STATUS_BASE_ADDR) then  -- Status register
            config_if_out.r_data <= status_reg;
        end if;
    end process;

end architecture;