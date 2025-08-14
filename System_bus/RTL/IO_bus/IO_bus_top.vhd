---====================== Start Copyright Notice ========================---
--==                                                                    ==--
--== Filename ..... IO_bus_top.vhd                                      ==--
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
LIBRARY IDA;
USE IDA.IO_bus_pkg.ALL;

entity IO_bus_top is
   generic (
      ver_model                    : std_logic_vector(2 downto 0) := "000";
      generic_boot_prom            : boolean := true;
      NUM_CORES                    : integer := 10;
      AHB_ADDR_WIDTH              : integer := 32
   );
   port (
      clk                        : in    std_logic;
      async_rst_n                : in    std_logic;
      
      -- GPIO bidirectional interface
      gpio_data   : inout std_logic_vector(7 downto 0);  
      gpio_addr   : inout std_logic_vector(7 downto 0);  
      
      -- GPIO control signals
      i_GR712_mem_romsn_0        : in    std_logic;
      gpio_dir    : out std_logic;    -- 方向控制：0=输入模式，1=输出模式
      gpio_oe     : out std_logic;    -- outout enable
      gpio_we     : out std_logic;    -- write enable
      gpio_re     : out std_logic;    -- read enable
      gpio_valid  : out std_logic;    -- data valid
      gpio_ready  : in  std_logic;    
 --     gpio_ack    : out std_logic;    -- acknowledge signal 
      

      
      
      -- Compression core base addresses (configurable)
      core_base_addr             : in    std_logic_vector(NUM_CORES*AHB_ADDR_WIDTH-1 downto 0);
      
      -- Compression core status
      core_ready                 : in    std_logic_vector(NUM_CORES-1 downto 0);
      
      -- Configuration control and status
      config_trigger             : out   std_logic_vector(NUM_CORES-1 downto 0);
      config_status              : out   std_logic_vector(7 downto 0);  -- Status register
      config_error_info          : out   std_logic_vector(15 downto 0); -- Error information
      
      -- Interrupt output to processor
      config_interrupt           : out   std_logic
   );
end entity IO_bus_top;

architecture rtl of IO_bus_top is
   
   -- Component declarations
   component IO_bus is
      generic (
         ver_model                 : std_logic_vector(2 downto 0);
         generic_boot_prom         : boolean
      );
      port (
         clk                       : in    std_logic;
         async_rst_n               : in    std_logic;
         i_GR712_mem_romsn_0       : in    std_logic;
         i_GR712_mem_romsn_1       : in    std_logic;
         i_GR712_mem_iosn          : in    std_logic;
         i_GR712_mem_writen        : in    std_logic;
         i_GR712_mem_oen           : in    std_logic;
         i_GR712_mem_add           : in    std_logic_vector(11 downto 0);
         io_GR712_mem_data         : inout std_logic_vector(31 downto 0);
         o_nor_flash_dir           : out   std_logic;
         o_core_if                 : out   write_core_if_vector(0 to 7);
         i_core_if                 : in    read_core_if_vector(0 to 7);
         o_large_core_if           : out   write_large_core_if_vector(8 to 9);
         i_large_core_if           : in    read_core_if_vector(8 to 9);
         o_bootrom_csn             : out   std_logic;
         o_bootrom_add             : out   std_logic_vector(11 downto 0);
         i_bootrom_data            : in    std_logic_vector(7 downto 0)
      );
   end component;
   
   -- Internal signals
   signal param_mem_wr_en        : std_logic;
   signal param_mem_wr_addr      : std_logic_vector(7 downto 0);
   signal param_mem_wr_data      : std_logic_vector(7 downto 0);
   signal param_mem_rd_en        : std_logic;
   signal param_mem_rd_addr      : std_logic_vector(7 downto 0);
   signal param_mem_rd_data      : std_logic_vector(7 downto 0);
   
   signal param_mem_rd_en_32     : std_logic;
   signal param_mem_rd_addr_32   : std_logic_vector(5 downto 0);
   signal param_mem_rd_data_32   : std_logic_vector(31 downto 0);
   
   signal shadow_wr_en           : std_logic;
   signal shadow_wr_core_sel     : std_logic_vector(3 downto 0);
   signal shadow_wr_addr         : std_logic_vector(5 downto 0);
   signal shadow_wr_data         : std_logic_vector(31 downto 0);
   
   signal shadow_rd_en           : std_logic;
   signal shadow_rd_core_sel     : std_logic_vector(3 downto 0);
   signal shadow_rd_addr         : std_logic_vector(5 downto 0);
   signal shadow_rd_data         : std_logic_vector(31 downto 0);
   
   signal core_config_valid      : std_logic_vector(NUM_CORES-1 downto 0);
   signal core_config_error      : std_logic_vector(NUM_CORES-1 downto 0);
   signal config_start           : std_logic_vector(NUM_CORES-1 downto 0);
   signal config_complete        : std_logic_vector(NUM_CORES-1 downto 0);
   signal error_code             : std_logic_vector(3 downto 0);
   signal error_core             : std_logic_vector(3 downto 0);
   
   signal controller_busy        : std_logic;
   signal controller_error       : std_logic;
   signal current_core           : std_logic_vector(3 downto 0);
   
   -- Configuration memory map
   -- 0x000-0x03F: CCSDS121 parameters for cores 0-7 (8 bytes each)
   -- 0x040-0x0BF: CCSDS123 parameters for cores 8-9 (24 bytes each)
   -- 0x0C0-0x0FF: Control and status registers
   
   signal config_mem_sel         : std_logic;
   signal control_reg_sel        : std_logic;
   signal config_trigger_reg     : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   signal status_reg             : std_logic_vector(7 downto 0);
   signal error_info_reg         : std_logic_vector(15 downto 0);
   signal interrupt_enable_reg   : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   signal interrupt_status_reg   : std_logic_vector(NUM_CORES-1 downto 0) := (others => '0');
   
   -- Modified core interfaces for configuration
   signal modified_core_if_in    : read_core_if_vector(0 to 7);
   signal modified_large_core_if_in : read_core_if_vector(8 to 9);
   
begin

   -- Instantiate original IO_bus
   io_bus_inst : IO_bus
   generic map (
      ver_model         => ver_model,
      generic_boot_prom => generic_boot_prom
   )
   port map (
      clk               => clk,
      async_rst_n       => async_rst_n,
      i_GR712_mem_romsn_0 => i_GR712_mem_romsn_0,
      i_GR712_mem_romsn_1 => i_GR712_mem_romsn_1,
      i_GR712_mem_iosn  => i_GR712_mem_iosn,
      i_GR712_mem_writen => i_GR712_mem_writen,
      i_GR712_mem_oen   => i_GR712_mem_oen,
      i_GR712_mem_add   => i_GR712_mem_add,
      io_GR712_mem_data => io_GR712_mem_data,
      o_nor_flash_dir   => o_nor_flash_dir,
      o_core_if         => o_core_if,
      i_core_if         => modified_core_if_in,
      o_large_core_if   => o_large_core_if,
      i_large_core_if   => modified_large_core_if_in,
      o_bootrom_csn     => o_bootrom_csn,
      o_bootrom_add     => o_bootrom_add,
      i_bootrom_data    => i_bootrom_data
   );
   
   -- Parameter memory instance
   param_mem_inst : entity work.parameter_mem
   generic map (
      ADDR_WIDTH_8BIT  => 8,
      ADDR_WIDTH_32BIT => 6
   )
   port map (
      clk           => clk,
      rst_n         => async_rst_n,
      wr_en_8       => param_mem_wr_en,
      wr_addr_8     => param_mem_wr_addr,
      wr_data_8     => param_mem_wr_data,
      rd_en_8       => param_mem_rd_en,
      rd_addr_8     => param_mem_rd_addr,
      rd_data_8     => param_mem_rd_data,
      rd_en_32      => param_mem_rd_en_32,
      rd_addr_32    => param_mem_rd_addr_32,
      rd_data_32    => param_mem_rd_data_32,
      mem_ready     => open,
      mem_error     => open
   );
   
   -- Shadow parameter memory instance
   shadow_mem_inst : entity work.parameter_mem_shadow
   generic map (
      NUM_CORES  => NUM_CORES,
      ADDR_WIDTH => 6
   )
   port map (
      clk              => clk,
      rst_n            => async_rst_n,
      wr_en            => shadow_wr_en,
      wr_core_sel      => shadow_wr_core_sel,
      wr_addr          => shadow_wr_addr,
      wr_data          => shadow_wr_data,
      rd_en            => shadow_rd_en,
      rd_core_sel      => shadow_rd_core_sel,
      rd_addr          => shadow_rd_addr,
      rd_data          => shadow_rd_data,
      core_config_valid => core_config_valid,
      core_config_error => core_config_error,
      core_ready       => core_ready,
      config_start     => config_start,
      config_complete  => config_complete,
      error_code       => error_code,
      error_core       => error_core
   );
   
   -- Configuration controller instance
   config_ctrl_inst : entity work.config_controller
   generic map (
      NUM_CORES     => NUM_CORES,
      AHB_ADDR_WIDTH => AHB_ADDR_WIDTH
   )
   port map (
      clk                => clk,
      rst_n              => async_rst_n,
      param_rd_en        => param_mem_rd_en_32,
      param_rd_addr      => param_mem_rd_addr_32,
      param_rd_data      => param_mem_rd_data_32,
      shadow_wr_en       => shadow_wr_en,
      shadow_wr_core_sel => shadow_wr_core_sel,
      shadow_wr_addr     => shadow_wr_addr,
      shadow_wr_data     => shadow_wr_data,
      config_trigger     => config_trigger_reg,
      config_start       => config_start,
      config_complete    => config_complete,
      config_error       => core_config_error,
      ahb_m_haddr        => ahb_m_haddr,
      ahb_m_htrans       => ahb_m_htrans,
      ahb_m_hwrite       => ahb_m_hwrite,
      ahb_m_hsize        => ahb_m_hsize,
      ahb_m_hburst       => ahb_m_hburst,
      ahb_m_hwdata       => ahb_m_hwdata,
      ahb_m_hready       => ahb_m_hready,
      ahb_m_hresp        => ahb_m_hresp,
      ahb_m_hrdata       => ahb_m_hrdata,
      core_base_addr     => core_base_addr,
      controller_busy    => controller_busy,
      controller_error   => controller_error,
      current_core       => current_core
   );
   
   -- Memory mapping and control logic
   process(clk, async_rst_n)
   begin
      if async_rst_n = '0' then
         config_trigger_reg <= (others => '0');
         interrupt_enable_reg <= (others => '0');
         interrupt_status_reg <= (others => '0');
      elsif rising_edge(clk) then
         -- Handle configuration triggers (auto-clear after one cycle)
         config_trigger_reg <= (others => '0');
         
         -- Handle processor writes to configuration memory
         for i in 0 to 7 loop  -- Check small cores
            if o_core_if(i).write_en = '1' then
               case o_core_if(i).add is
                  when "111100" =>  -- 0x3C - Configuration trigger register
                     config_trigger_reg <= o_core_if(i).w_data(NUM_CORES-1 downto 0);
                  when "111101" =>  -- 0x3D - Interrupt enable register
                     interrupt_enable_reg <= o_core_if(i).w_data(NUM_CORES-1 downto 0);
                  when "111110" =>  -- 0x3E - Clear interrupt status
                     interrupt_status_reg <= interrupt_status_reg and not o_core_if(i).w_data(NUM_CORES-1 downto 0);
                  when others =>
                     -- Handle parameter memory writes
                     if o_core_if(i).add(5 downto 4) /= "11" then  -- Not control registers
                        param_mem_wr_en <= '1';
                        param_mem_wr_addr <= std_logic_vector(to_unsigned(i, 3)) & o_core_if(i).add(4 downto 0);
                        param_mem_wr_data <= o_core_if(i).w_data(7 downto 0);  -- Only lower 8 bits
                     end if;
               end case;
            end if;
         end loop;
         
         -- Update interrupt status on configuration completion
         for i in 0 to NUM_CORES-1 loop
            if config_complete(i) = '1' then
               interrupt_status_reg(i) <= '1';
            end if;
         end loop;
         
      end if;
   end process;
   
   -- Read data multiplexing
   process(o_core_if, status_reg, error_info_reg, interrupt_status_reg, param_mem_rd_data, shadow_rd_data)
   begin
      for i in 0 to 7 loop
         modified_core_if_in(i) <= i_core_if(i);  -- Default pass-through
         
         if o_core_if(i).read_en = '1' then
            case o_core_if(i).add is
               when "111100" =>  -- Status register
                  modified_core_if_in(i).r_data <= X"000000" & status_reg;
               when "111101" =>  -- Error info register (lower)
                  modified_core_if_in(i).r_data <= X"0000" & error_info_reg;
               when "111110" =>  -- Interrupt status
                  modified_core_if_in(i).r_data <= X"000000" & interrupt_status_reg(7 downto 0);
               when "111111" =>  -- Core config status
                  modified_core_if_in(i).r_data <= X"0000" & core_config_error(7 downto 0) & core_config_valid(7 downto 0);
               when others =>
                  if o_core_if(i).add(5 downto 4) /= "11" then  -- Parameter memory
                     modified_core_if_in(i).r_data <= X"000000" & param_mem_rd_data;
                  end if;
            end case;
         end if;
      end loop;
   end process;
   
   -- Status register composition
   status_reg <= controller_busy & controller_error & "00" & current_core;
   error_info_reg <= X"0" & error_core & error_code & "0000";
   
   -- Generate interrupt
   config_interrupt <= '1' when (interrupt_status_reg and interrupt_enable_reg) /= (interrupt_status_reg'range => '0') else '0';
   
   -- Output assignments
   config_trigger <= config_trigger_reg;
   config_status <= status_reg;
   config_error_info <= error_info_reg;
   modified_large_core_if_in <= i_large_core_if;  -- Pass through for large cores
   
   -- Parameter memory control (simplified - extend as needed)
   param_mem_rd_en <= '1';  -- Always enable for simplicity
   param_mem_rd_addr <= (others => '0');  -- Default address
   
end architecture rtl;