--------------------------------------------------------------------------------
--== Filename ..... config_ram_8to32.vhd                                      ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... June 2025                                            ==--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity config_ram_8to32 is
    generic (
        INPUT_DATA_WIDTH  : integer := 8;      --  Input data width
        INPUT_ADDR_WIDTH  : integer := 7;      -- Input address width (2^7 = 128 > 96)
        INPUT_DEPTH       : integer := 96;     -- Input address depth

        OUTPUT_DATA_WIDTH : integer := 32;     -- Output data width
        OUTPUT_ADDR_WIDTH : integer := 5;      -- Output address width (2^5 = 32 > 24)
        OUTPUT_DEPTH      : integer := 24      -- Output address depth
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        --  8-bit write port
        wr_en       : in  std_logic;
        wr_addr     : in  std_logic_vector(INPUT_ADDR_WIDTH-1 downto 0);
        wr_data     : in  std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);

        -- 32-bit read port  
        rd_en       : in  std_logic;
        rd_addr     : in  std_logic_vector(OUTPUT_ADDR_WIDTH-1 downto 0);
        rd_data     : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
        rd_valid    : out std_logic
    );
end entity config_ram_8to32;

architecture rtl of config_ram_8to32 is  
    -- RAM storage type definition
    type ram_type is array (0 to INPUT_DEPTH-1) of std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
    signal ram_memory : ram_type;
    -- Read registers
    signal rd_data_reg : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    signal rd_valid_reg : std_logic;

begin

    write_proc : process(clk)
    begin
        if rising_edge(clk) then    
            if wr_en = '1' then
                ram_memory(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process write_proc;

    -- Read process
    read_proc : process(clk)
        variable base_addr : integer;
        variable temp_data : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                rd_data_reg <= (others => '0');
                rd_valid_reg <= '0';
            elsif rd_en = '1' then
                    base_addr := to_integer(unsigned(rd_addr)& "00");                         --  covert 5-bit address to 7-bit base address
                    
                    temp_data(7 downto 0)   := ram_memory(base_addr);
                    temp_data(15 downto 8)  := ram_memory(base_addr + 1);
                    temp_data(23 downto 16) := ram_memory(base_addr + 2);
                    temp_data(31 downto 24) := ram_memory(base_addr + 3);
                    
                    rd_data_reg <= temp_data;
                    rd_valid_reg <= '1';
                
            else
                rd_valid_reg <= '0';
            end if;
        end if;
    end process read_proc;

    rd_data <= rd_data_reg;
    rd_valid <= rd_valid_reg;

end architecture rtl;