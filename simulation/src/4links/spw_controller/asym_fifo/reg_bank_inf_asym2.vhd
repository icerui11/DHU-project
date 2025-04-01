--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! reg_bank entity. Register bank to store intermediate data
entity reg_bank_inf_asym2 is
  generic (RESET_TYPE: integer := 1;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
       Cz: natural := 15;       --! Number of components of the vectors.
       W: natural := 32;        --! Bit width of the stored values.
       W_ADDRESS: natural := 32);   --! Bit width of the address signal. 
  port (
    -- System Interface
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low. 
    
    -- Control and data Interface
    clear: in std_logic;                  --! Clear signal.
    data_in: in std_logic_vector (W - 1 downto 0);      --! Input data to be stored.
    data_out: out std_logic_vector (W -1 downto 0);     --! Output read data.
    dataout_valid: out std_logic;         --! Output data valid signal.
    read_addr: in std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
    write_addr: in std_logic_vector (W_ADDRESS-1 downto 0); --! Write address.
    we: in std_logic;                   --! Write enable. Active high.
    re: in std_logic                    --! Read enable. Active high. 
    );
      
end reg_bank_inf_asym2;

--! @brief Architecture of reg_bank considering reset signals
architecture arch_reset_flavour of reg_bank_inf_asym2 is
  type array_type is array (0 to Cz-1) of std_logic_vector (data_in'high downto 0);
  signal bank: array_type;
begin

  process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then 
      bank <= (others => (others => '0'));
  --    data_out <= (others =>'0');  
      dataout_valid <= '0'; 
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        bank <= (others => (others => '0'));
  --      data_out <= (others =>'0');  
        dataout_valid <= '0'; 
      else
        -- Same read and write addresses
        dataout_valid <= '0';
        if (read_addr = write_addr) then
          if (re = '1' and we = '1') then
            data_out <= data_in;
            dataout_valid <= '1';
            bank(to_integer(unsigned(write_addr))) <= data_in;
          elsif (re = '1') then  
            data_out <= bank(to_integer(unsigned(read_addr))); 
            dataout_valid <= '1';
          elsif (we = '1') then
            bank(to_integer(unsigned(write_addr))) <= data_in;
          end if;
        -- Different read and write addresses
        else 
          if (re = '1') then
            data_out <= bank(to_integer(unsigned(read_addr))); 
            dataout_valid <= '1';
          end if;
          if (we = '1') then 
            bank(to_integer(unsigned(write_addr))) <= data_in;
          end if;
        end if;
      end if;
    end if;
  end process;
end arch_reset_flavour;