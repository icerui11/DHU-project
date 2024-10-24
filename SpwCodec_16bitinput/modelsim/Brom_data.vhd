--============================================================================--
-- Design unit  : Rom_controller module
--
-- File name    : Brom_data.vhd
--
-- Purpose      : read data from rom
--
-- Note         :
--
-- Library      : BROM
--
-- Author       : Rui Yin
--
-- Instantiates : 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library BROM;
use BROM.ROM_Package.all;

entity Brom_data is
    generic(
        width : integer:= 8;
	depth : integer:= 3072;
	addr  : integer:= 9);
    
     Port ( 
        CE :              in STD_LOGIC;							 
	rom_addr:         in std_logic_vector (addr-1 downto 0);
	clk:              in std_logic;
	rst_n:            in std_logic;
        rom_data_o :      out STD_LOGIC_VECTOR(width-1 downto 0);
        DataIn_NewValid : out STD_LOGIC
        );
attribute syn_preserve : boolean;
attribute syn_preserve of rom_data_o : signal is true;
end Brom_data;

architecture rtl of Brom_data is
    signal rom_data_o_tmp : STD_LOGIC_VECTOR(width-1 downto 0) := (others => '0');
    signal DataIn_NewValid_tmp : std_logic := '0';
 --   signal DataIn_NewValid_tmp2 : std_logic := '0';
begin

    process(clk)
    begin
      if rising_edge(clk) then
        if(rst_n = '0') then
           rom_data_o_tmp <= (others => '1');
           DataIn_NewValid_tmp <= '0';
      else
            if CE = '1' then
              rom_data_o_tmp <= ROM_CONTENT(to_integer(unsigned(rom_addr)));        -- read data from ROM_CONTENT, rom_addr is the address of ROM_CONTENT
              DataIn_NewValid_tmp <= '1';
            else
              rom_data_o_tmp <= (others =>'1');
              DataIn_NewValid_tmp <= '0';
            end if;
        end if;
      end if;
     end process;
      DataIn_NewValid <= DataIn_NewValid_tmp;
      rom_data_o <= rom_data_o_tmp;
--process(clk)
--begin
--   if rising_edge(clk) then
--      rom_data_o <= rom_data_o_tmp;
----     DataIn_NewValid_tmp2 <= DataIn_NewValid_tmp;
--      DataIn_NewValid <= DataIn_NewValid_tmp;
--    end if;
--end process;
end rtl;