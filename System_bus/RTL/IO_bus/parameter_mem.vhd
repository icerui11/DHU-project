---====================== Start Copyright Notice ========================---
--==                                                                    ==--
--== Filename ..... parameter_mem.vhd                                   ==--
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

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

entity parameter_mem is
   generic (
      ADDR_WIDTH_8BIT  : integer := 8;  -- Address width for 8-bit access (256 bytes)
      ADDR_WIDTH_32BIT : integer := 6   -- Address width for 32-bit access (64 words)
   );
   port (
      clk              : in  std_logic;
      rst_n            : in  std_logic;
      
      -- 8-bit write interface (from GPIO)
      wr_en_8          : in  std_logic;
      wr_addr_8        : in  std_logic_vector(ADDR_WIDTH_8BIT-1 downto 0);
      wr_data_8        : in  std_logic_vector(7 downto 0);
      
      -- 8-bit read interface (for GPIO readback)
      rd_en_8          : in  std_logic;
      rd_addr_8        : in  std_logic_vector(ADDR_WIDTH_8BIT-1 downto 0);
      rd_data_8        : out std_logic_vector(7 downto 0);
      
      -- 32-bit read interface (for configuration controller)
      rd_en_32         : in  std_logic;
      rd_addr_32       : in  std_logic_vector(ADDR_WIDTH_32BIT-1 downto 0);
      rd_data_32       : out std_logic_vector(31 downto 0);
      
      -- Status signals
      mem_ready        : out std_logic;
      mem_error        : out std_logic
   );
end entity parameter_mem;

architecture rtl of parameter_mem is
   
   -- Memory array: 256 bytes organized as 64 x 32-bit words
   type mem_array_t is array (0 to 2**(ADDR_WIDTH_32BIT)-1) of std_logic_vector(31 downto 0);
   signal memory : mem_array_t := (others => (others => '0'));
   
   -- Internal signals
   signal wr_word_addr    : std_logic_vector(ADDR_WIDTH_32BIT-1 downto 0);
   signal wr_byte_sel     : std_logic_vector(1 downto 0);
   signal rd_data_8_reg   : std_logic_vector(7 downto 0);
   signal rd_data_32_reg  : std_logic_vector(31 downto 0);
   signal mem_ready_reg   : std_logic;
   
begin

   -- Address conversion for 8-bit to 32-bit access
   wr_word_addr <= wr_addr_8(ADDR_WIDTH_8BIT-1 downto 2);
   wr_byte_sel  <= wr_addr_8(1 downto 0);
   
   -- Memory write process (8-bit interface)
   process(clk, rst_n)
   begin
      if rst_n = '0' then
         memory <= (others => (others => '0'));
         mem_ready_reg <= '1';
      elsif rising_edge(clk) then
         if wr_en_8 = '1' then
            case wr_byte_sel is
               when "00" => memory(to_integer(unsigned(wr_word_addr)))(7 downto 0)   <= wr_data_8;
               when "01" => memory(to_integer(unsigned(wr_word_addr)))(15 downto 8)  <= wr_data_8;
               when "10" => memory(to_integer(unsigned(wr_word_addr)))(23 downto 16) <= wr_data_8;
               when "11" => memory(to_integer(unsigned(wr_word_addr)))(31 downto 24) <= wr_data_8;
               when others => null;
            end case;
         end if;
      end if;
   end process;
   
   -- Memory read process (8-bit interface)
   process(clk, rst_n)
      variable rd_word_addr : std_logic_vector(ADDR_WIDTH_32BIT-1 downto 0);
      variable rd_byte_sel  : std_logic_vector(1 downto 0);
      variable temp_word    : std_logic_vector(31 downto 0);
   begin
      if rst_n = '0' then
         rd_data_8_reg <= (others => '0');
      elsif rising_edge(clk) then
         if rd_en_8 = '1' then
            rd_word_addr := rd_addr_8(ADDR_WIDTH_8BIT-1 downto 2);
            rd_byte_sel  := rd_addr_8(1 downto 0);
            temp_word    := memory(to_integer(unsigned(rd_word_addr)));
            
            case rd_byte_sel is
               when "00"   => rd_data_8_reg <= temp_word(7 downto 0);
               when "01"   => rd_data_8_reg <= temp_word(15 downto 8);
               when "10"   => rd_data_8_reg <= temp_word(23 downto 16);
               when "11"   => rd_data_8_reg <= temp_word(31 downto 24);
               when others => rd_data_8_reg <= (others => '0');
            end case;
         end if;
      end if;
   end process;
   
   -- Memory read process (32-bit interface)
   process(clk, rst_n)
   begin
      if rst_n = '0' then
         rd_data_32_reg <= (others => '0');
      elsif rising_edge(clk) then
         if rd_en_32 = '1' then
            rd_data_32_reg <= memory(to_integer(unsigned(rd_addr_32)));
         end if;
      end if;
   end process;
   
   -- Output assignments
   rd_data_8  <= rd_data_8_reg;
   rd_data_32 <= rd_data_32_reg;
   mem_ready  <= mem_ready_reg;
   mem_error  <= '0'; -- Can be extended for error detection
   
end architecture rtl;