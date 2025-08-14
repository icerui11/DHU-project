---====================== Start Copyright Notice ========================---
--==                                                                    ==--
--== Filename ..... parameter_mem_shadow.vhd                            ==--
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

entity parameter_mem_shadow is
   generic (
      NUM_CORES        : integer := 10;  -- Number of cores (0-7 small, 8-9 large)
      ADDR_WIDTH       : integer := 6    -- Address width for 32-bit access
   );
   port (
      clk              : in  std_logic;
      rst_n            : in  std_logic;
      
      -- Write interface (from configuration controller)
      wr_en            : in  std_logic;
      wr_core_sel      : in  std_logic_vector(3 downto 0);  -- Core selection
      wr_addr          : in  std_logic_vector(5 downto 0);  -- Register address
      wr_data          : in  std_logic_vector(31 downto 0);
      
      -- Read interface (for processor)
      rd_en            : in  std_logic;
      rd_core_sel      : in  std_logic_vector(3 downto 0);
      rd_addr          : in  std_logic_vector(5 downto 0);
      rd_data          : out std_logic_vector(31 downto 0);
      
      -- Configuration status per core
      core_config_valid   : out std_logic_vector(NUM_CORES-1 downto 0);
      core_config_error   : out std_logic_vector(NUM_CORES-1 downto 0);
      core_ready          : in  std_logic_vector(NUM_CORES-1 downto 0);
      
      -- Control signals
      config_start        : in  std_logic_vector(NUM_CORES-1 downto 0);
      config_complete     : out std_logic_vector(NUM_CORES-1 downto 0);
      
      -- Error information
      error_code          : out std_logic_vector(3 downto 0);
      error_core          : out std_logic_vector(3 downto 0)
   );
end entity parameter_mem_shadow;

architecture rtl of parameter_mem_shadow is
   
   -- Memory organization: Each core has up to 64 registers
   type core_mem_t is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(31 downto 0);
   type shadow_mem_t is array (0 to NUM_CORES-1) of core_mem_t;
   signal shadow_memory : shadow_mem_t := (others => (others => (others => '0')));
   
   -- Status registers per core
   signal config_valid_reg : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   signal config_error_reg : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   signal config_complete_reg : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   
   -- Error tracking
   signal error_code_reg : std_logic_vector(3 downto 0) := (others => '0');
   signal error_core_reg : std_logic_vector(3 downto 0) := (others => '0');
   
   -- Internal signals
   signal rd_data_reg : std_logic_vector(31 downto 0);
   
   -- Configuration requirements for different core types
   constant CCSDS121_REG_COUNT : integer := 4;  -- 4 registers for CCSDS121
   constant CCSDS123_REG_COUNT : integer := 6;  -- 6 registers for CCSDS123
   
begin

   -- Write process
   process(clk, rst_n)
   begin
      if rst_n = '0' then
         shadow_memory <= (others => (others => (others => '0')));
      elsif rising_edge(clk) then
         if wr_en = '1' then
            if to_integer(unsigned(wr_core_sel)) < NUM_CORES then
               shadow_memory(to_integer(unsigned(wr_core_sel)))(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
         end if;
      end if;
   end process;
   
   -- Read process
   process(clk, rst_n)
   begin
      if rst_n = '0' then
         rd_data_reg <= (others => '0');
      elsif rising_edge(clk) then
         if rd_en = '1' then
            if to_integer(unsigned(rd_core_sel)) < NUM_CORES then
               rd_data_reg <= shadow_memory(to_integer(unsigned(rd_core_sel)))(to_integer(unsigned(rd_addr)));
            else
               rd_data_reg <= (others => '0');
            end if;
         end if;
      end if;
   end process;
   
   -- Configuration validation process
   process(clk, rst_n)
      variable required_regs : integer;
      variable all_regs_valid : boolean;
   begin
      if rst_n = '0' then
         config_valid_reg <= (others => '0');
         config_error_reg <= (others => '0');
         config_complete_reg <= (others => '0');
         error_code_reg <= (others => '0');
         error_core_reg <= (others => '0');
      elsif rising_edge(clk) then
         
         for i in 0 to NUM_CORES-1 loop
            -- Determine required register count based on core type
            if i <= 7 then  -- Cores 0-7 are CCSDS121
               required_regs := CCSDS121_REG_COUNT;
            else  -- Cores 8-9 are CCSDS123
               required_regs := CCSDS123_REG_COUNT;
            end if;
            
            -- Check if configuration is started for this core
            if config_start(i) = '1' then
               config_complete_reg(i) <= '0';
               config_error_reg(i) <= '0';
               
               -- Validate configuration
               all_regs_valid := true;
               for j in 0 to required_regs-1 loop
                  -- Check if register is properly configured (not all zeros)
                  if shadow_memory(i)(j) = X"00000000" and j > 0 then  -- Skip control register check
                     all_regs_valid := false;
                  end if;
               end loop;
               
               if all_regs_valid then
                  config_valid_reg(i) <= '1';
                  config_complete_reg(i) <= '1';
               else
                  config_error_reg(i) <= '1';
                  config_complete_reg(i) <= '1';
                  error_code_reg <= "0001";  -- Configuration incomplete
                  error_core_reg <= std_logic_vector(to_unsigned(i, 4));
               end if;
            end if;
            
            -- Clear valid flag if core reports error
            if core_ready(i) = '0' and config_valid_reg(i) = '1' then
               config_error_reg(i) <= '1';
               config_valid_reg(i) <= '0';
               error_code_reg <= "0010";  -- Core error
               error_core_reg <= std_logic_vector(to_unsigned(i, 4));
            end if;
         end loop;
      end if;
   end process;
   
   -- Output assignments
   rd_data <= rd_data_reg;
   core_config_valid <= config_valid_reg;
   core_config_error <= config_error_reg;
   config_complete <= config_complete_reg;
   error_code <= error_code_reg;
   error_core <= error_core_reg;
   
end architecture rtl;