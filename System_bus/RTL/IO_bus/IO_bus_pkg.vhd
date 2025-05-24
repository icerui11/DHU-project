---====================== Start Copyright Notice ========================---
--==                                                                    ==--
--== Filename ..... IO_bus_pkg.vhd                                      ==--
--== Download ..... http://www.ida.ing.tu-bs.de                         ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Contact ......                                      ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... May 2025                                            ==--
--==                                                                    ==--
---======================= End Copyright Notice =========================---

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--== Version ...... 2.00                                                ==--
---======================= End Copyright Notice =========================---

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE IO_bus_pkg IS

    -- Core interface for standard cores (256 bytes address space)
    TYPE write_core_if_type IS RECORD
        add      : std_logic_vector(7 downto 0);  -- 8-bit address for 256 bytes
        w_data   : std_logic_vector(31 downto 0); -- 32-bit write data
        read_en  : std_logic;                     -- Read enable
        write_en : std_logic;                     -- Write enable
    END RECORD;

    TYPE read_core_if_type IS RECORD
        r_data   : std_logic_vector(31 downto 0); -- 32-bit read data
    END RECORD;

    -- Core interface vectors for multiple cores
    TYPE write_core_if_vector IS ARRAY (NATURAL RANGE <>) OF write_core_if_type;
    TYPE read_core_if_vector IS ARRAY (NATURAL RANGE <>) OF read_core_if_type;

    -- GPIO RAM interface
    TYPE gpio_ram_if_type IS RECORD
        addr     : std_logic_vector(7 downto 0);  -- 8-bit address
        w_data   : std_logic_vector(7 downto 0);  -- 8-bit write data
        r_data   : std_logic_vector(7 downto 0);  -- 8-bit read data
        write_en : std_logic;                     -- Write enable
        read_en  : std_logic;                     -- Read enable
    END RECORD;

    -- Shadow parameter RAM interface
    TYPE shadow_ram_if_type IS RECORD
        addr     : std_logic_vector(7 downto 0);  -- 8-bit address
        w_data   : std_logic_vector(31 downto 0); -- 32-bit write data
        r_data   : std_logic_vector(31 downto 0); -- 32-bit read data
        write_en : std_logic;                     -- Write enable
        read_en  : std_logic;                     -- Read enable
    END RECORD;

    -- SHyLoC core configuration constants
    CONSTANT CCSDS123_LR_BASE_ADDR : std_logic_vector(11 downto 0) := x"000"; -- 0x000-0x0FF
    CONSTANT CCSDS123_HR_BASE_ADDR : std_logic_vector(11 downto 0) := x"100"; -- 0x100-0x1FF
    CONSTANT CCSDS121_LR_BASE_ADDR : std_logic_vector(11 downto 0) := x"200"; -- 0x200-0x2FF
    CONSTANT CCSDS121_HR_BASE_ADDR : std_logic_vector(11 downto 0) := x"300"; -- 0x300-0x3FF
    CONSTANT CCSDS121_EX_BASE_ADDR : std_logic_vector(11 downto 0) := x"400"; -- 0x400-0x4FF
    CONSTANT GPIO_RAM_BASE_ADDR    : std_logic_vector(11 downto 0) := x"500"; -- 0x500-0x5FF
    CONSTANT SHADOW_RAM_BASE_ADDR  : std_logic_vector(11 downto 0) := x"600"; -- 0x600-0x6FF

    -- CCSDS123 register offsets (from datasheet)
    CONSTANT CCSDS123_CTRL_STATUS_OFFSET : std_logic_vector(7 downto 0) := x"00"; -- 0x00
    CONSTANT CCSDS123_EXTMEM_OFFSET      : std_logic_vector(7 downto 0) := x"04"; -- 0x04
    CONSTANT CCSDS123_CFG0_OFFSET        : std_logic_vector(7 downto 0) := x"08"; -- 0x08
    CONSTANT CCSDS123_CFG1_OFFSET        : std_logic_vector(7 downto 0) := x"0C"; -- 0x0C
    CONSTANT CCSDS123_CFG2_OFFSET        : std_logic_vector(7 downto 0) := x"10"; -- 0x10
    CONSTANT CCSDS123_CFG3_OFFSET        : std_logic_vector(7 downto 0) := x"14"; -- 0x14

    -- CCSDS121 register offsets (from datasheet)
    CONSTANT CCSDS121_CTRL_STATUS_OFFSET : std_logic_vector(7 downto 0) := x"00"; -- 0x00
    CONSTANT CCSDS121_CFG0_OFFSET        : std_logic_vector(7 downto 0) := x"04"; -- 0x04
    CONSTANT CCSDS121_CFG1_OFFSET        : std_logic_vector(7 downto 0) := x"08"; -- 0x08
    CONSTANT CCSDS121_CFG2_OFFSET        : std_logic_vector(7 downto 0) := x"0C"; -- 0x0C

END PACKAGE IO_bus_pkg;