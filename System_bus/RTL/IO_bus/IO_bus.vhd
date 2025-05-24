---====================== Start Copyright Notice ========================---
--== Filename ..... IO_bus.vhd                                          ==--
--== Project ...... SHyLoC Configuration IO_Bus                         ==--
--== Description .. IO Bus for SHyLoC compression core configuration     ==--
--== Authors ...... Modified for SHyLoC integration                      ==--
--== Version ...... 2.00                                                 ==--
---======================= End Copyright Notice =========================---

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 
library work; use work.IO_bus_pkg.all; 

entity IO_bus is 
generic ( 
    ver_model : std_logic_vector(2 downto 0) := "010" -- default to qm/fm model 
    );
port ( 
    clk         :  in std_logic; 
    async_rst_n : in std_logic;
    -- gr712 processor interface
    i_gr712_mem_iosn           : in    std_logic;
    i_gr712_mem_writen         : in    std_logic;
    i_gr712_mem_oen            : in    std_logic;
    i_gr712_mem_add            : in    std_logic_vector(11 downto 0);
    io_gr712_mem_data          : inout std_logic_vector(31 downto 0);
    
    -- gpio interface for 8-bit configuration
    io_gpio_data               : inout std_logic_vector(7 downto 0);
    i_gpio_addr                : in    std_logic_vector(7 downto 0);
    i_gpio_read_en             : in    std_logic;
    i_gpio_write_en            : in    std_logic;
    o_gpio_ready               : out   std_logic;
    
    -- shyloc ccsds123 lr channel interface
    o_ccsds123_lr_if           : out   write_core_if_type;
    i_ccsds123_lr_if           : in    read_core_if_type;
    
    -- shyloc ccsds123 hr channel interface  
    o_ccsds123_hr_if           : out   write_core_if_type;
    i_ccsds123_hr_if           : in    read_core_if_type;
    
    -- shyloc ccsds121 lr channel interface
    o_ccsds121_lr_if           : out   write_core_if_type;
    i_ccsds121_lr_if           : in    read_core_if_type;
    
    -- shyloc ccsds121 hr channel interface
    o_ccsds121_hr_if           : out   write_core_if_type;
    i_ccsds121_hr_if           : in    read_core_if_type;
    
    -- shyloc ccsds121 venspec-h channel interface
    o_ccsds121_ex_if           : out   write_core_if_type;
    i_ccsds121_ex_if           : in    read_core_if_type;
    
    -- debug/status outputs
    o_debug_addr               : out   std_logic_vector(11 downto 0);
    o_debug_core_sel           : out   std_logic_vector(2 downto 0);
    o_debug_access_type        : out   std_logic_vector(1 downto 0) -- 00=none, 01=read, 10=write, 11=gpio
);
END ENTITY IO_bus;

architecture rtl of IO_bus is

 -- internal signal declarations
signal gr712_mem_iosn         : std_logic;
signal gr712_mem_iosn_reg1    : std_logic;
signal gr712_mem_writen       : std_logic;
signal gr712_mem_oen          : std_logic;
signal gr712_mem_add          : std_logic_vector(11 downto 0);
signal gr712_mem_add_reg      : std_logic_vector(11 downto 0);

signal reg_i_gr712_mem_data   : std_logic_vector(31 downto 0);
signal reg2_i_gr712_mem_data  : std_logic_vector(31 downto 0);

signal gr712_mem_data         : std_logic_vector(31 downto 0);
signal gr712_mem_data_reg     : std_logic_vector(31 downto 0);

signal cores_read_en          : std_logic;
signal cores_write_en         : std_logic;
signal cores_read_en_reg      : std_logic;
signal set_data_outs          : std_logic;

-- core selection signals
signal ccsds123_lr_sel        : std_logic;
signal ccsds123_hr_sel        : std_logic;
signal ccsds121_lr_sel        : std_logic;
signal ccsds121_hr_sel        : std_logic;
signal ccsds121_ex_sel        : std_logic;
signal gpio_ram_sel           : std_logic;
signal shadow_ram_sel         : std_logic;

-- core interfaces
signal ccsds123_lr_if         : write_core_if_type;
signal ccsds123_hr_if         : write_core_if_type;
signal ccsds121_lr_if         : write_core_if_type;
signal ccsds121_hr_if         : write_core_if_type;
signal ccsds121_ex_if         : write_core_if_type;

-- gpio ram interface
signal gpio_ram_if            : gpio_ram_if_type;
signal shadow_ram_if          : shadow_ram_if_type;

-- gpio signals
signal gpio_data_reg          : std_logic_vector(7 downto 0);
signal gpio_ready_reg         : std_logic;

-- ram arrays
type gpio_ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
type shadow_ram_type is array (0 to 255) of std_logic_vector(31 downto 0);
signal gpio_ram               : gpio_ram_type;
signal shadow_ram             : shadow_ram_type;

-- debug signals
signal debug_core_sel         : std_logic_vector(2 downto 0);
signal debug_access_type      : std_logic_vector(1 downto 0);
begin
-- input register process
p_input_reg : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        gr712_mem_iosn       <= '1';
        gr712_mem_iosn_reg1  <= '1';
        gr712_mem_writen     <= '1';
        gr712_mem_oen        <= '1';
        gr712_mem_add        <= (others => '0');
        gr712_mem_add_reg    <= (others => '0');
        reg_i_gr712_mem_data <= (others => '0');
        reg2_i_gr712_mem_data <= (others => '0');
    elsif (clk'event and clk = '1') then
        gr712_mem_iosn <= i_gr712_mem_iosn;
        gr712_mem_iosn_reg1 <= gr712_mem_iosn;
        gr712_mem_writen <= i_gr712_mem_writen;
        gr712_mem_oen <= i_gr712_mem_oen;
        gr712_mem_add <= i_gr712_mem_add;
        gr712_mem_add_reg <= gr712_mem_add;
        reg_i_gr712_mem_data <= io_gr712_mem_data;
        reg2_i_gr712_mem_data <= reg_i_gr712_mem_data;
    end if;
end process;

-- address decode and read/write enable generation
p_rw_en_reg : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        cores_read_en <= '0';
        cores_write_en <= '0';
    elsif (clk'event and clk = '1') then
        cores_read_en <= not(gr712_mem_iosn or gr712_mem_oen);
        cores_write_en <= not(gr712_mem_iosn_reg1 or gr712_mem_iosn or gr712_mem_writen);
    end if;
end process;

-- core selection logic based on address
ccsds123_lr_sel <= '1' when gr712_mem_add_reg(11 downto 8) = x"0" else '0';
ccsds123_hr_sel <= '1' when gr712_mem_add_reg(11 downto 8) = x"1" else '0';
ccsds121_lr_sel <= '1' when gr712_mem_add_reg(11 downto 8) = x"2" else '0';
ccsds121_hr_sel <= '1' when gr712_mem_add_reg(11 downto 8) = x"3" else '0';
ccsds121_ex_sel <= '1' when gr712_mem_add_reg(11 downto 8) = x"4" else '0';
gpio_ram_sel    <= '1' when gr712_mem_add_reg(11 downto 8) = x"5" else '0';
shadow_ram_sel  <= '1' when gr712_mem_add_reg(11 downto 8) = x"6" else '0';

-- core interface assignment
ccsds123_lr_if.add <= gr712_mem_add_reg(7 downto 0);
ccsds123_lr_if.w_data <= reg2_i_gr712_mem_data;
ccsds123_lr_if.read_en <= ccsds123_lr_sel and cores_read_en;
ccsds123_lr_if.write_en <= ccsds123_lr_sel and cores_write_en;

ccsds123_hr_if.add <= gr712_mem_add_reg(7 downto 0);
ccsds123_hr_if.w_data <= reg2_i_gr712_mem_data;
ccsds123_hr_if.read_en <= ccsds123_hr_sel and cores_read_en;
ccsds123_hr_if.write_en <= ccsds123_hr_sel and cores_write_en;

ccsds121_lr_if.add <= gr712_mem_add_reg(7 downto 0);
ccsds121_lr_if.w_data <= reg2_i_gr712_mem_data;
ccsds121_lr_if.read_en <= ccsds121_lr_sel and cores_read_en;
ccsds121_lr_if.write_en <= ccsds121_lr_sel and cores_write_en;

ccsds121_hr_if.add <= gr712_mem_add_reg(7 downto 0);
ccsds121_hr_if.w_data <= reg2_i_gr712_mem_data;
ccsds121_hr_if.read_en <= ccsds121_hr_sel and cores_read_en;
ccsds121_hr_if.write_en <= ccsds121_hr_sel and cores_write_en;

ccsds121_ex_if.add <= gr712_mem_add_reg(7 downto 0);
ccsds121_ex_if.w_data <= reg2_i_gr712_mem_data;
ccsds121_ex_if.read_en <= ccsds121_ex_sel and cores_read_en;
ccsds121_ex_if.write_en <= ccsds121_ex_sel and cores_write_en;

-- output core interfaces (registered)
p_core_if_reg : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        o_ccsds123_lr_if <= ((others => '0'), (others => '0'), '0', '0');
        o_ccsds123_hr_if <= ((others => '0'), (others => '0'), '0', '0');
        o_ccsds121_lr_if <= ((others => '0'), (others => '0'), '0', '0');
        o_ccsds121_hr_if <= ((others => '0'), (others => '0'), '0', '0');
        o_ccsds121_ex_if <= ((others => '0'), (others => '0'), '0', '0');
    elsif (clk'event and clk = '1') then
        o_ccsds123_lr_if <= ccsds123_lr_if;
        o_ccsds123_hr_if <= ccsds123_hr_if;
        o_ccsds121_lr_if <= ccsds121_lr_if;
        o_ccsds121_hr_if <= ccsds121_hr_if;
        o_ccsds121_ex_if <= ccsds121_ex_if;
    end if;
end process;

-- gpio ram process
p_gpio_ram : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        gpio_ram <= (others => (others => '0'));
    elsif (clk'event and clk = '1') then
        -- write from gr712 side
        if gpio_ram_sel = '1' and cores_write_en = '1' then
            gpio_ram(to_integer(unsigned(gr712_mem_add_reg(7 downto 0)))) <= reg2_i_gr712_mem_data(7 downto 0);
        end if;
        -- write from gpio side
        if i_gpio_write_en = '1' then
            gpio_ram(to_integer(unsigned(i_gpio_addr))) <= io_gpio_data;
        end if;
    end if;
end process;

-- shadow ram process
p_shadow_ram : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        shadow_ram <= (others => (others => '0'));
    elsif (clk'event and clk = '1') then
        if shadow_ram_sel = '1' and cores_write_en = '1' then
            shadow_ram(to_integer(unsigned(gr712_mem_add_reg(7 downto 0)))) <= reg2_i_gr712_mem_data;
        end if;
    end if;
end process;

-- read enable register
p_cores_read_en_reg : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        cores_read_en_reg <= '0';
    elsif (clk'event and clk = '1') then
        cores_read_en_reg <= cores_read_en;
    end if;
end process;

-- read data multiplexer
p_read_data_mux : process (gr712_mem_add_reg, cores_read_en_reg, 
                           i_ccsds123_lr_if, i_ccsds123_hr_if,
                           i_ccsds121_lr_if, i_ccsds121_hr_if, i_ccsds121_ex_if,
                           gpio_ram, shadow_ram)
begin
    if cores_read_en_reg = '1' then
        case gr712_mem_add_reg(11 downto 8) is
            when x"0" => gr712_mem_data <= i_ccsds123_lr_if.r_data;
            when x"1" => gr712_mem_data <= i_ccsds123_hr_if.r_data;
            when x"2" => gr712_mem_data <= i_ccsds121_lr_if.r_data;
            when x"3" => gr712_mem_data <= i_ccsds121_hr_if.r_data;
            when x"4" => gr712_mem_data <= i_ccsds121_ex_if.r_data;
            when x"5" => gr712_mem_data <= x"000000" & gpio_ram(to_integer(unsigned(gr712_mem_add_reg(7 downto 0))));
            when x"6" => gr712_mem_data <= shadow_ram(to_integer(unsigned(gr712_mem_add_reg(7 downto 0))));
            when others => gr712_mem_data <= (others => '0');
        end case;
    else
        gr712_mem_data <= (others => '0');
    end if;
end process;

-- gpio handling
p_gpio_ctrl : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        gpio_ready_reg <= '0';
        gpio_data_reg  <= (others => '0');
    elsif (clk'event and clk = '1') then
        gpio_ready_reg <= '1';
        if i_gpio_read_en = '1' then
            gpio_data_reg <= gpio_ram(to_integer(unsigned(i_gpio_addr)));
        end if;
    end if;
end process;

-- gpio tristate control
io_gpio_data <= gpio_data_reg when i_gpio_read_en = '1' else (others => 'Z');
o_gpio_ready <= gpio_ready_reg;

-- output data control
set_data_outs <= cores_read_en_reg and not(gr712_mem_iosn);

-- tristate buffer for gr712 data bus
p_bidirectional_io : process (set_data_outs, gr712_mem_data_reg)
begin
    case set_data_outs is
        when '1'    => io_gr712_mem_data <= gr712_mem_data_reg;
        when '0'    => io_gr712_mem_data <= (others => 'Z');
        when others => io_gr712_mem_data <= (others => 'X');
    end case;
end process;

-- output data register
p_output_reg : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        gr712_mem_data_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
        gr712_mem_data_reg <= gr712_mem_data;
    end if;
end process;

-- debug output assignment
p_debug : process (clk, async_rst_n)
begin
    if (async_rst_n = '0') then
        debug_core_sel   <= (others => '0');
        debug_access_type <= (others => '0');
    elsif (clk'event and clk = '1') then
        -- core selection encoding
        debug_core_sel <= "000" when ccsds123_lr_sel  = '1' else
                          "001" when ccsds123_hr_sel  = '1' else
                          "010" when ccsds121_lr_sel  = '1' else
                          "011" when ccsds121_hr_sel  = '1' else
                          "100" when ccsds121_ex_sel  = '1' else
                          "101" when gpio_ram_sel     = '1' else
                          "110" when shadow_ram_sel   = '1' else
                          "111";
        
        -- access type encoding
        debug_access_type <= "01" when cores_read_en  = '1' else
                             "10" when cores_write_en = '1' else
                             "11" when (i_gpio_read_en = '1' or i_gpio_write_en = '1') else
                             "00";
    end if;
end process;

o_debug_addr        <= gr712_mem_add_reg;
o_debug_core_sel    <= debug_core_sel;
o_debug_access_type <= debug_access_type;

end architecture rtl;