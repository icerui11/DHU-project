---====================== Configuration Types Package ====================---
--== Package for compression core configuration system types            ==--
---=======================================================================---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package config_types is

    -- Configuration Controller Interface Types
    type config_write_if is record
        read_en  : std_logic;
        write_en : std_logic;
        add      : std_logic_vector(7 downto 0);  -- 8-bit address for 256 bytes
        w_data   : std_logic_vector(31 downto 0);
    end record;
    
    type config_read_if is record
        r_data   : std_logic_vector(31 downto 0);
    end record;

    -- AHB Master interface types (simplified)
    type ahb_mst_out_type is record
        haddr    : std_logic_vector(31 downto 0);
        htrans   : std_logic_vector(1 downto 0);
        hwrite   : std_logic;
        hsize    : std_logic_vector(2 downto 0);
        hburst   : std_logic_vector(2 downto 0);
        hwdata   : std_logic_vector(31 downto 0);
    end record;
    
    type ahb_mst_in_type is record
        hrdata   : std_logic_vector(31 downto 0);
        hready   : std_logic;
        hresp    : std_logic_vector(1 downto 0);
    end record;

    -- Configuration memory address constants
    constant CCSDS121_BASE_ADDR : std_logic_vector(7 downto 0) := X"00";  -- 0x700
    constant CCSDS123_BASE_ADDR : std_logic_vector(7 downto 0) := X"40";  -- 0x740
    constant CONTROL_BASE_ADDR  : std_logic_vector(7 downto 0) := X"60";  -- 0x760
    constant STATUS_BASE_ADDR   : std_logic_vector(7 downto 0) := X"70";  -- 0x770
    
    -- Configuration sizes
    constant CCSDS121_CONFIG_SIZE : integer := 16;  -- 16 bytes (4 x 32-bit words)
    constant CCSDS123_CONFIG_SIZE : integer := 24;  -- 24 bytes (6 x 32-bit words)
    
    -- Control register bit positions
    constant CTRL_ENABLE_121_BIT    : integer := 0;
    constant CTRL_ENABLE_123_BIT    : integer := 1;
    constant CTRL_START_CONFIG_BIT  : integer := 2;
    constant CTRL_RESET_ERROR_BIT   : integer := 3;
    
    -- Status register bit positions
    constant STAT_CONFIG_DONE_BIT   : integer := 0;
    constant STAT_CONFIG_ERROR_BIT  : integer := 1;
    constant STAT_121_READY_BIT     : integer := 2;
    constant STAT_123_READY_BIT     : integer := 3;
    constant STAT_121_ERROR_BIT     : integer := 4;
    constant STAT_123_ERROR_BIT     : integer := 5;
    
    -- AHB target addresses (these should match your compression cores' addresses)
    constant CCSDS121_AHB_ADDR : std_logic_vector(31 downto 0) := X"40000000";
    constant CCSDS123_AHB_ADDR : std_logic_vector(31 downto 0) := X"50000000";
    
    -- Configuration state machine states
    type config_state_type is (
        IDLE, 
        READ_PARAMS, 
        WRITE_121_CONFIG, 
        WRITE_123_CONFIG, 
        WAIT_RESPONSE, 
        CHECK_STATUS, 
        ERROR_STATE
    );

    -- Helper functions
    function bytes_to_word(byte3, byte2, byte1, byte0 : std_logic_vector(7 downto 0)) 
        return std_logic_vector;
    
    function word_to_bytes(word : std_logic_vector(31 downto 0)) 
        return std_logic_vector; -- returns 32 bits as concatenated bytes

end package config_types;

package body config_types is

    function bytes_to_word(byte3, byte2, byte1, byte0 : std_logic_vector(7 downto 0)) 
        return std_logic_vector is
    begin
        return byte3 & byte2 & byte1 & byte0;  -- Big endian
    end function;
    
    function word_to_bytes(word : std_logic_vector(31 downto 0)) 
        return std_logic_vector is
    begin
        return word;  -- Just return as is, can be indexed as needed
    end function;

end package body config_types;