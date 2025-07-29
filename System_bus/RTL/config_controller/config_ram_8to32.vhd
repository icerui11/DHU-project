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
    -- RAM storage type definition - Changed to 32-bit x 24
    type ram_type is array (0 to OUTPUT_DEPTH-1) of std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    signal ram_memory : ram_type;
    
    -- Write state machine signals
    type write_state_type is (IDLE, WRITING);
    signal write_state : write_state_type;
    
    -- Write control signals
    signal byte_counter : unsigned(1 downto 0);  -- 0 to 3, tracks which byte we're writing
    signal word_addr_reg : unsigned(OUTPUT_ADDR_WIDTH-1 downto 0);  -- Current 32-bit word address
    signal wr_data_temp : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);  -- Temporary data accumulator
    signal word_complete : std_logic;  -- Signal indicating a complete 32-bit word is ready
    
    -- Read registers
    signal rd_data_reg : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    signal rd_valid_reg : std_logic;

begin

    -- Write process - Assembles 4 consecutive 8-bit writes into 32-bit data
    write_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Asynchronous reset: initialize all signals
            write_state <= IDLE;
            byte_counter <= (others => '0');
            word_addr_reg <= (others => '0');
            wr_data_temp <= (others => '0');
            word_complete <= '0';
            
        elsif rising_edge(clk) then
            
            word_complete <= '0';  -- Default: no complete word
            
            case write_state is
                
                when IDLE =>
                    -- Wait for write enable signal
                    byte_counter <= (others => '0');  -- Start from byte 0
                    wr_data_temp <= (others => '0');  -- Clear temp data
                    
                    if wr_en = '1' then
                        -- Start new write sequence
                        write_state <= WRITING;
                        -- Calculate 32-bit word address from 8-bit address (divide by 4)
                        word_addr_reg <= unsigned(wr_addr(INPUT_ADDR_WIDTH-1 downto 2));
                        -- Store first byte
                        wr_data_temp(7 downto 0) <= wr_data;
                        byte_counter <= "01";  -- Next byte position
                    end if;
                
                when WRITING =>
                    -- Sequential byte writing state
                    
                    if wr_en = '1' then
                        -- Check if this write belongs to the same 32-bit word
                        if unsigned(wr_addr(INPUT_ADDR_WIDTH-1 downto 2)) = word_addr_reg then
                            -- Same word, continue accumulating bytes
                            case byte_counter is
                                when "01" =>  -- Writing byte 1
                                    wr_data_temp(15 downto 8) <= wr_data;
                                when "10" =>  -- Writing byte 2
                                    wr_data_temp(23 downto 16) <= wr_data;
                                when "11" =>  -- Writing byte 3 (MSB)
                                    wr_data_temp(31 downto 24) <= wr_data;
                                when others =>
                                    -- Should never reach here
                                    null;
                            end case;
                            
                            -- Check if we've written all 4 bytes
                            if byte_counter = "11" then
                                -- Finished writing all bytes of current word
                                word_complete <= '1';  -- Signal complete word
                                write_state <= IDLE;
                                byte_counter <= (others => '0');
                            else
                                -- Move to next byte
                                byte_counter <= byte_counter + 1;
                            end if;
                            
                        else
                            -- Different word address - write current incomplete word and start new one
                            word_complete <= '1';  -- Write current (possibly incomplete) word
                            write_state <= IDLE;  -- Will restart in next cycle
                        end if;
                    else
                        -- No write enable - stay in current state
                        null;
                    end if;
                    
            end case;
        end if;
    end process write_proc;

    -- RAM write process - Writes complete 32-bit words to RAM
    ram_write_proc : process(clk)
    begin
        if rising_edge(clk) then    
            if word_complete = '1' then
                ram_memory(to_integer(word_addr_reg)) <= wr_data_temp;
            end if;
        end if;
    end process ram_write_proc;

    -- Read process - Directly reads 32-bit data
    read_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            rd_data_reg <= (others => '0');
            rd_valid_reg <= '0';
        elsif rising_edge(clk) then
            if rd_en = '1' then
                -- Direct 32-bit read from RAM
                rd_data_reg <= ram_memory(to_integer(unsigned(rd_addr)));
                rd_valid_reg <= '1';
            else
                rd_valid_reg <= '0';
            end if;
        end if;
    end process read_proc;

    -- Output assignments
    rd_data <= rd_data_reg;
    rd_valid <= rd_valid_reg;

end architecture rtl;