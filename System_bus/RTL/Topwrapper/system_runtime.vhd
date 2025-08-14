--------------------------------------------------------------------------------
-- File Description: Top-level module integrating SpaceWire router interface 
--                   with multiple compression cores (HR, LR, H)
--------------------------------------------------------------------------------
-- @ File Name        : spw_compressor_system_top.vhd
-- @ Engineer         : Senior FPGA Engineer
-- @ Date             : 2025-08-15
-- @ VHDL Version     : 2008
-- @ Target Device    : RTG4 / SmartFusion2
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- SmartFusion2/RTG4 libraries
library smartfusion2;
use smartfusion2.all;

-- SHyLoC libraries for compression
library shyloc_121;
use shyloc_121.ccsds121_parameters.all;

library shyloc_123;
use shyloc_123.ccsds123_parameters.all;

-- System packages
library work;
use work.system_constant_pckg.all;
context work.router_context;

entity spw_compressor_system_top is
    generic (
        -- SpaceWire router parameters
        g_num_ports         : natural range 1 to 32     := c_num_ports;
        g_is_fifo           : t_dword                   := c_fifo_ports;
        g_clock_freq        : real                      := c_spw_clk_freq;
        g_addr_width        : integer                   := 9;
        g_data_width        : integer                   := 8;
        g_mode              : string                    := "single";
        g_priority          : string                    := c_priority;
        g_ram_style         : string                    := c_ram_style;
        syn_mode            : string                    := "lsram";
        g_router_port_addr  : integer                   := c_router_port_addr;
        
        -- Compressor parameters
        NUM_COMPRESSORS     : integer := 3;  -- HR, LR, H compressors
        
        -- AHB address configuration
        COMPRESSOR_BASE_ADDR_HR_123 : integer := 16#200#;
        COMPRESSOR_BASE_ADDR_HR_121 : integer := 16#100#;
        COMPRESSOR_BASE_ADDR_LR_123 : integer := 16#400#;
        COMPRESSOR_BASE_ADDR_LR_121 : integer := 16#500#;
        COMPRESSOR_BASE_ADDR_H_121  : integer := 16#700#
    );
    port (
        -- System clocks and resets
        clk_sys             : in std_logic;      -- System clock for compressors
        clk_ahb             : in std_logic;      -- AHB bus clock
        clk_spw             : in std_logic;      -- SpaceWire clock
        
        -- Reset signals (active low)
        rst_n               : in std_logic;      -- Global reset
        rst_n_lr            : in std_logic;      -- LR compressor reset
        rst_n_hr            : in std_logic;      -- HR compressor reset
        rst_n_h             : in std_logic;      -- H compressor reset
        
        -- Configuration interface for AHB master
        ram_wr_en           : in std_logic;
        ram_wr_addr         : in std_logic_vector(c_input_addr_width-1 downto 0);
        ram_wr_data         : in std_logic_vector(7 downto 0);
        
        -- SpaceWire external interface (DS signals)
        Din_p               : in  std_logic_vector(1 to g_num_ports-1);
        Sin_p               : in  std_logic_vector(1 to g_num_ports-1);
        Dout_p              : out std_logic_vector(1 to g_num_ports-1);
        Sout_p              : out std_logic_vector(1 to g_num_ports-1);
        
        -- Control signals
        force_stop          : in  std_logic;
        force_stop_lr       : in  std_logic;
        force_stop_h        : in  std_logic;
        ready_ext           : in  std_logic;
        
        -- Status outputs
        system_ready        : out std_logic;
        config_done         : out std_logic;
        system_error        : out std_logic;
        spw_error           : out std_logic_vector(1 to c_num_fifoports);
        router_connected    : out std_logic_vector(31 downto 1)
    );
end entity spw_compressor_system_top;

architecture rtl of spw_compressor_system_top is

    ------------------------------------------------------------------------
    -- Internal signals for router-compressor interconnection
    ------------------------------------------------------------------------
    
    -- Router to Compressor data path (received from SpaceWire)
    signal rx_cmd_out       : rx_cmd_out_array(1 to c_num_fifoports);
    signal rx_cmd_valid     : std_logic_vector(1 to c_num_fifoports);
    signal rx_cmd_ready     : std_logic_vector(1 to c_num_fifoports);
    
    signal rx_data_out      : rx_data_out_array(1 to c_num_fifoports);
    signal rx_data_valid    : std_logic_vector(1 to c_num_fifoports);
    signal rx_data_ready    : std_logic_vector(1 to c_num_fifoports);
    
    -- Compressor to Router data path (to be transmitted via SpaceWire)
    signal ccsds_datain     : ccsds_datain_array(1 to c_num_fifoports);
    signal w_update         : std_logic_vector(1 to c_num_fifoports);
    signal asym_FIFO_full   : std_logic_vector(1 to c_num_fifoports);
    signal ccsds_ready_ext  : std_logic_vector(1 to c_num_fifoports);
    
    -- Raw CCSDS data for encoder
    signal raw_ccsds_data   : raw_ccsds_data_array(1 to c_num_fifoports);
    signal ccsds_datanewValid : std_logic_vector(1 to c_num_fifoports);
    
    -- Compressor output signals
    signal data_out_HR      : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_valid_HR: std_logic;
    signal data_out_LR      : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_valid_LR: std_logic;
    signal data_out_H       : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_valid_H : std_logic;
    
    -- Compressor input signals
    signal data_in_HR       : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_valid_HR : std_logic;
    signal data_in_LR       : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_valid_LR : std_logic;
    signal data_in_H        : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_valid_H  : std_logic;
    
    -- Constants for port assignment
    constant PORT_HR        : integer := 1;  -- HR compressor uses FIFO port 1
    constant PORT_LR        : integer := 2;  -- LR compressor uses FIFO port 2
    constant PORT_H         : integer := 3;  -- H compressor uses FIFO port 3

begin

    ------------------------------------------------------------------------
    -- SpaceWire Router with FIFO Control
    ------------------------------------------------------------------------
    router_fifo_ctrl_inst : entity work.router_fifo_ctrl_top_v2
        generic map (
            g_num_ports         => g_num_ports,
            g_is_fifo           => g_is_fifo,
            g_clock_freq        => g_clock_freq,
            g_addr_width        => g_addr_width,
            g_data_width        => g_data_width,
            g_mode              => g_mode,
            g_priority          => g_priority,
            g_ram_style         => g_ram_style,
            syn_mode            => syn_mode,
            g_router_port_addr  => g_router_port_addr
        )
        port map (
            rst_n               => rst_n,
            clk                 => clk_spw,
            
            -- Router receive interface (from SpaceWire to compressor)
            rx_cmd_out          => rx_cmd_out,
            rx_cmd_valid        => rx_cmd_valid,
            rx_cmd_ready        => rx_cmd_ready,
            rx_data_out         => rx_data_out,
            rx_data_valid       => rx_data_valid,
            rx_data_ready       => rx_data_ready,
            
            -- Router transmit interface (from compressor to SpaceWire)
            ccsds_datain        => ccsds_datain,
            w_update            => w_update,
            asym_FIFO_full      => asym_FIFO_full,
            ccsds_ready_ext     => ccsds_ready_ext,
            
            -- Raw CCSDS data
            raw_ccsds_data      => raw_ccsds_data,
            ccsds_datanewValid  => ccsds_datanewValid,
            
            -- SpaceWire physical interface
            Din_p               => Din_p,
            Sin_p               => Sin_p,
            Dout_p              => Dout_p,
            Sout_p              => Sout_p,
            
            -- Status
            spw_error           => spw_error,
            router_connected    => router_connected
        );

    ------------------------------------------------------------------------
    -- Compression System with AHB Interface
    ------------------------------------------------------------------------
    compressor_system_inst : entity work.shyloc_ahb_system_top
        generic map (
            NUM_COMPRESSORS                 => NUM_COMPRESSORS,
            COMPRESSOR_BASE_ADDR_HR_123     => COMPRESSOR_BASE_ADDR_HR_123,
            COMPRESSOR_BASE_ADDR_HR_121     => COMPRESSOR_BASE_ADDR_HR_121,
            COMPRESSOR_BASE_ADDR_LR_123     => COMPRESSOR_BASE_ADDR_LR_123,
            COMPRESSOR_BASE_ADDR_LR_121     => COMPRESSOR_BASE_ADDR_LR_121,
            COMPRESSOR_BASE_ADDR_H_121      => COMPRESSOR_BASE_ADDR_H_121
        )
        port map (
            -- Clocks and resets
            clk_sys             => clk_sys,
            clk_ahb             => clk_ahb,
            rst_n               => rst_n,
            rst_n_lr            => rst_n_lr,
            rst_n_hr            => rst_n_hr,
            rst_n_h             => rst_n_h,
            
            -- Configuration interface
            ram_wr_en           => ram_wr_en,
            ram_wr_addr         => ram_wr_addr,
            ram_wr_data         => ram_wr_data,
            
            -- Data interfaces
            data_in_HR          => data_in_HR,
            data_in_valid_HR    => data_in_valid_HR,
            data_out_HR         => data_out_HR,
            data_out_valid_HR   => data_out_valid_HR,
            
            data_in_LR          => data_in_LR,
            data_in_valid_LR    => data_in_valid_LR,
            data_out_LR         => data_out_LR,
            data_out_valid_LR   => data_out_valid_LR,
            
            data_in_H           => data_in_H,
            data_in_valid_H     => data_in_valid_H,
            data_out_H          => data_out_H,
            data_out_valid_H    => data_out_valid_H,
            
            -- Control
            force_stop          => force_stop,
            force_stop_lr       => force_stop_lr,
            force_stop_h        => force_stop_h,
            ready_ext           => ready_ext,
            
            -- Status
            system_ready        => system_ready,
            config_done         => config_done,
            system_error        => system_error
        );

    ------------------------------------------------------------------------
    -- Data Path Connections
    ------------------------------------------------------------------------
    
    -- Connect SpaceWire RX data to compressor inputs
    -- HR Compressor (Port 1)
    process(clk_sys, rst_n)
    begin
        if rst_n = '0' then
            -- CCSDS HR 
            data_in_valid_HR <= '0';
            rx_data_ready(PORT_HR) <= '0';
            w_update(PORT_HR) <= '0';
            -- CCSDS LR
            data_in_valid_LR <= '0';
            rx_data_ready(PORT_LR) <= '0';
            w_update(PORT_LR) <= '0';
            -- CCSDS H
            data_in_valid_H <= '0';
            rx_data_ready(PORT_H) <= '0';
            w_update(PORT_H) <= '0';
        elsif rising_edge(clk_sys) then
            if rx_data_valid(PORT_HR) = '1' then
                -- Adapt 8-bit SpaceWire data to compressor input width
                data_in_HR <= std_logic_vector(resize(unsigned(rx_data_out(PORT_HR)), data_in_HR'length));
                data_in_valid_HR <= '1';
                rx_data_ready(PORT_HR) <= '1';
            else
                data_in_valid_HR <= '0';
                rx_data_ready(PORT_HR) <= '0';
            end if;
             -- CCSDS LR 
             if rx_data_valid(PORT_LR) = '1' then
                data_in_LR <= std_logic_vector(resize(unsigned(rx_data_out(PORT_LR)), data_in_LR'length));
                data_in_valid_LR <= '1';
                rx_data_ready(PORT_LR) <= '1';
            else
                data_in_valid_LR <= '0';
                rx_data_ready(PORT_LR) <= '0';
            end if;
            -- CCSDS H
            if rx_data_valid(PORT_H) = '1' then
                data_in_H <= std_logic_vector(resize(unsigned(rx_data_out(PORT_H)), data_in_H'length));
                data_in_valid_H <= '1';
                rx_data_ready(PORT_H) <= '1';
            else
                data_in_valid_H <= '0';
                rx_data_ready(PORT_H) <= '0';
            end if;

        end if;
    end process;

    
    -- Connect compressor outputs to SpaceWire TX
    -- HR Compressor output
    process(clk_sys, rst_n)
    begin
        if rst_n = '0' then
            w_update(PORT_HR) <= '0';
        elsif rising_edge(clk_sys) then
            if data_out_valid_HR = '1' and asym_FIFO_full(PORT_HR) = '0' then
                -- Adapt compressor output to 32-bit CCSDS data
                ccsds_datain(PORT_HR) <= std_logic_vector(resize(unsigned(data_out_HR), 32));
                w_update(PORT_HR) <= '1';
            else
                w_update(PORT_HR) <= '0';
            end if;
        end if;
    end process;
    
    -- LR Compressor output
    process(clk_sys, rst_n)
    begin
        if rst_n = '0' then
            w_update(PORT_LR) <= '0';
        elsif rising_edge(clk_sys) then
            if data_out_valid_LR = '1' and asym_FIFO_full(PORT_LR) = '0' then
                ccsds_datain(PORT_LR) <= std_logic_vector(resize(unsigned(data_out_LR), 32));
                w_update(PORT_LR) <= '1';
            else
                w_update(PORT_LR) <= '0';
            end if;
        end if;
    end process;
    
    -- H Compressor output
    process(clk_sys, rst_n)
    begin
        if rst_n = '0' then
            w_update(PORT_H) <= '0';
        elsif rising_edge(clk_sys) then
            if data_out_valid_H = '1' and asym_FIFO_full(PORT_H) = '0' then
                ccsds_datain(PORT_H) <= std_logic_vector(resize(unsigned(data_out_H), 32));
                w_update(PORT_H) <= '1';
            else
                w_update(PORT_H) <= '0';
            end if;
        end if;
    end process;
    
    -- Initialize unused ports
    gen_unused_ports: for i in 4 to c_num_fifoports generate
        ccsds_datain(i) <= (others => '0');
        w_update(i) <= '0';
        rx_data_ready(i) <= '0';
        rx_cmd_ready(i) <= '0';
    end generate gen_unused_ports;
    
    -- Command interface (not used in this application)
    rx_cmd_ready <= (others => '0');

end architecture rtl;