--------------------------------------------------------------------------------
--== Filename ..... config_pkg.vhd                                      ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... June 2025                                            ==--

library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should compile by default, added just in case....
use std.textio.all;				-- for basic textio functions

package config_pkg is

    -- Constants
    constant c_num_compressors : integer := 3; -- Number of compressors    
    constant c_ram_addr_width : integer := 8;               -- RAM address width

end package config_pkg;