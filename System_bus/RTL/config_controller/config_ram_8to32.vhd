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
 --   signal base_addr : integer;
    -- Read state machine signals
    type read_state_type is (IDLE, READING);
    signal read_state : read_state_type;
    
    -- Read control signals
    signal byte_counter : unsigned(1 downto 0);  -- 0 to 3, tracks which byte we're reading
    signal base_addr_reg : unsigned(INPUT_ADDR_WIDTH-1 downto 0);  -- Base address for current read
    signal current_addr : integer range 0 to 95;  -- Current byte address being read
    signal rd_data_temp : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);  -- Temporary data accumulator
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
/*
    -- Read process
    read_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then  
            rd_data <= (others => '0');
            rd_valid <= '0';
        elsif rising_edge(clk) then  
            if rd_en = '1' then
                base_addr <= to_integer(unsigned(rd_addr) & "00");

                rd_data(7 downto 0)   <= ram_memory(base_addr);
                rd_data(15 downto 8)  <= ram_memory(base_addr + 1);
                rd_data(23 downto 16) <= ram_memory(base_addr + 2);
                rd_data(31 downto 24) <= ram_memory(base_addr + 3);
       --         rd_data <= temp_data;
                rd_valid <= '1';
            else
                rd_data <= (others => '0');
                rd_valid <= '0';
            end if;
        end if;
    end process read_proc;
--    rd_data <= rd_data_reg;
--    rd_valid <= rd_valid_reg;
*/

    read_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Asynchronous reset: initialize all signals
            read_state <= IDLE;
            byte_counter <= (others => '0');
            base_addr_reg <= (others => '0');
            rd_data_temp <= (others => '0');
            rd_valid_reg <= '0';
            
        elsif rising_edge(clk) then
            
            case read_state is
                
                when IDLE =>
                    -- Wait for read enable signal
                    rd_valid_reg <= '0';  -- Clear valid signal in idle state
                    
                    if rd_en = '1' then
                        -- Start new read sequence
                        read_state <= READING;
                        byte_counter <= (others => '0');  -- Start from byte 0
                        -- Calculate base address: 5-bit rd_addr becomes 7-bit base address
                        base_addr_reg <= (others => '0');
                        rd_data_temp <= (others => '0');  -- Clear temp data
                    end if;
                
                when READING =>
                    -- Sequential byte reading state
                    
                    -- Calculate current byte address
                    current_addr <= to_integer(base_addr_reg + byte_counter);
                    
                    -- Read current byte and place it in correct position
                    case byte_counter is
                        when "00" =>  -- Reading byte 0 (LSB)
                            rd_data_temp(7 downto 0) <= ram_memory(current_addr);
                        when "01" =>  -- Reading byte 1
                            rd_data_temp(15 downto 8) <= ram_memory(current_addr);
                        when "10" =>  -- Reading byte 2
                            rd_data_temp(23 downto 16) <= ram_memory(current_addr);
                        when "11" =>  -- Reading byte 3 (MSB)
                            rd_data_temp(31 downto 24) <= ram_memory(current_addr);
                        when others =>
                            -- Should never reach here
                            null;
                    end case;
                    
                    -- Check if we've read all 4 bytes
                    if byte_counter = "11" then
                        -- Finished reading all bytes
                        read_state <= IDLE;
                        rd_valid_reg <= '1';  -- Assert valid signal
                        byte_counter <= (others => '0');
                    else
                        -- Move to next byte
                        byte_counter <= byte_counter + 1;
                    end if;
                    
            end case;
        end if;
    end process read_proc;

    -- Output assignments
    rd_data <= rd_data_temp;
    rd_valid <= rd_valid_reg;
end architecture rtl;