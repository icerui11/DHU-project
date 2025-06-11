-- define the package for configuration types
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;

package config_types_pkg is
    
    -- Compressor types / 压缩器类型
    type compressor_type is (CCSDS123, CCSDS121_1, CCSDS121_2);
    
    -- Configuration register structure / 配置寄存器结构
    type config_reg_type is record
        addr    : std_logic_vector(31 downto 0);    -- Register address / 寄存器地址
        data    : std_logic_vector(31 downto 0);    -- Register data / 寄存器数据
        valid   : std_logic;                        -- Valid flag / 有效标志
    end record;
    
    -- Compressor status type 
    type compressor_status is record
        AwaitingConfig : std_logic;  
        Ready          : std_logic;
        Finished       : std_logic;
        Error          : std_logic;
    end record;

    type compressor_status_array is array (0 to c_num_compressors-1) of compressor_status;
    
    constant compressor_status_init : compressor_status := (                -- compressor after reset state
        AwaitingConfig => '1',
        Ready          => '0',
        Finished       => '0',
        Error          => '0'
    );

    -- Configuration array for each compressor / 每个压缩器的配置数组
    constant MAX_CONFIG_REGS : integer := 16;
    type config_array_type is array (0 to MAX_CONFIG_REGS-1) of config_reg_type;
    
    -- Multi-compressor configuration / 多压缩器配置
    type multi_config_type is record
        ccsds123    : config_array_type;
        ccsds121_1  : config_array_type;
        ccsds121_2  : config_array_type;
    end record;
    
end package;

