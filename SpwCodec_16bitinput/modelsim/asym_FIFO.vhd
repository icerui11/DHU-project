--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils
library shyloc_utils;

--context work.spw_context;
--use work.all;

--! fifop2_base entity. FIFO memory element. 
entity asym_FIFO is
  generic (
    RESET_TYPE  : integer := 1;     --! Reset type (Synchronous or asynchronous).
    W_Size: natural := 32;        --! Bit width of the stored values.
    R_Size: natural := 8;        --! Bit width of the read values.
    NE      : integer := 16;    --! Number of elements of the FIFO.
    W_ADDR    : integer := 5;     --! Bit width of the address.
    TECH    : integer := 0);    --! Parameter used to change technology; (0) uses inferred memories.
  port (
    
    -- System Interface
    clk   : in std_logic;     --! Clock signal.
    rst_n : in std_logic;     --! Reset signal. Active low.
    
    -- Control Interface
    clr     : in std_logic;   --! Clear signal.
    w_update  : in std_logic;   --! Write request.
    r_update  : in std_logic;   --! Read request.
    hfull   : out std_logic;  --! Flag to indicate half full FIFO.
    empty   : out std_logic;  --! Flag to indicate empty FIFO.
    full    : out std_logic;  --! Flag to indicate full FIFO.
    afull   : out std_logic;  --! Flag to indicate almost full FIFO.
    aempty    : out std_logic;  --! Flag to indicate almost empty FIFO.
    ack     : out std_logic;  --! Acknowledge signal.
    done    : in std_logic;   --! Done signal.
    -- Data Interface
    data_in   : in std_logic_vector(W_Size-1 downto 0);  --! Data to store in the FIFO.
    data_out_chunk  : out std_logic_vector(R_Size-1 downto 0)  --! Read data from the FIFO.
    );
    
end asym_FIFO;

--! @brief Architecture of fifop2_base  
architecture arch of asym_FIFO is
  
    --ratio between the write and read side
  constant C_num_FIFO : integer := W_Size / R_Size;
  -- signals to control FIFO's capacity
  constant HALF   : integer := 2**W_ADDR/2;
  constant TOTAL    : integer := 2**(W_ADDR+1);
  signal is_empty   : std_logic;
  signal is_full    : std_logic;
  signal is_hfull   : std_logic;
  
  -- signals to perform read and write operations 
  signal r_pointer  : unsigned(W_ADDR downto 0);
  signal w_pointer  : unsigned(W_ADDR downto 0);
  signal we_ram   : std_logic;
  signal re_ram   : std_logic;
  signal en_rami    : std_logic;
  signal rd_chunk_fin : std_logic;
  signal dataout_fifo : std_logic_vector(W_Size-1 downto 0);
  signal dataout_valid : std_logic;
  signal rd_chunk  : integer range 0 to 4 := 0;
  type state_type is (ready, chunk_1, chunk_2, chunk_3, chunk_4);
  signal chunk_state : state_type;
  signal ack_latched : std_logic := '0';
  signal en_r_update :std_logic;
  constant ENDIANESS_GEN : integer := 1;
begin

  ------------------
  --!@brief reg_bank
  ------------------
  fifo_bank: entity work.reg_bank_inf_asym2(arch_reset_flavour)
      generic map 
        (RESET_TYPE => RESET_TYPE,
        Cz => 2**W_ADDR,
        W =>  W_Size,
        W_ADDRESS => W_ADDR
        )
      port map (
        clk => clk,
        rst_n => rst_n,
        clear => clr,
        data_in => data_in,
        data_out => dataout_fifo,                                                 --read data 32bit
        dataout_valid => dataout_valid,
        read_addr => std_logic_vector(r_pointer(r_pointer'high - 1 downto 0)),
        write_addr => std_logic_vector(w_pointer(w_pointer'high - 1 downto 0)),
        we => we_ram,
        re => en_r_update);
        
  ------------------
  --! Enable updates
  ------------------
  we_ram <= w_update and (not(is_full));
  re_ram <= r_update and (not(is_empty));
  
  en_rami <= re_ram or we_ram;
  -------------------
  --! Flag assignments
  -------------------
  empty <= is_empty;
  full <= is_full;
  hfull <= is_hfull;

  --asymetric read data
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      rd_chunk_fin <= '0';
      ack <= '0';
      r_pointer <= (others => '0');
      chunk_state <= ready;
    elsif rising_edge(clk) then
      if clr = '1' then
        ack <= '0';
        rd_chunk_fin <= '0';
        r_pointer <= (others => '0');
        chunk_state <= ready;
 
      elsif ENDIANESS_GEN = 0 then      
            case chunk_state is
              when ready =>                                           --wait fifodata takeout 
              ack <= '0';
              en_r_update <= '0';
              rd_chunk_fin <= '0';
              if re_ram = '1' then
                chunk_state <= chunk_1;
                en_r_update <= '0';
              end if;

              when chunk_1 =>
                rd_chunk_fin <= '0';
                en_r_update <= '1';
                if dataout_valid = '1' then
                    data_out_chunk <= dataout_fifo(7 downto 0);
                    en_r_update <= '0'; -- already read fifo data, read next address
                    if ack_latched = '0' then
                        ack <= '1';
                        ack_latched <= '1'; -- Latch the ack
                    end if;
                else
                    if ack_latched = '0' then
                        ack <= '0';
                    end if;
                end if;
                if done = '1' then -- wait spw transfer done
                    chunk_state <= chunk_2;
                    ack_latched <= '0'; -- Reset the latch for next chunk state transition
                end if;
              
              
            when chunk_2 =>                
              rd_chunk_fin <= '0';
              en_r_update <= '1';
              if dataout_valid = '1' then
                data_out_chunk <= dataout_fifo(15 downto 8);
                en_r_update <= '0';                             --already read fifo data,read next address
                ack <= '1';
              else
                ack <= '0';
              end if;
                if done = '1' then                                --wait spw transfer done
                  chunk_state <= chunk_3;                    
                end if;

            when chunk_3 =>
              rd_chunk_fin <= '0';
              en_r_update <= '1';
              if dataout_valid = '1' then
                data_out_chunk <= dataout_fifo(23 downto 16);
                en_r_update <= '0';                             --already read fifo data,read next address
                ack <= '1';
              else
                ack <= '0';
              end if;
                if done = '1' then                                --wait spw transfer done
                  chunk_state <= chunk_4;                    
                end if;

            when chunk_4 =>
              rd_chunk_fin <= '0';
              en_r_update <= '1';
              if dataout_valid = '1' then
                data_out_chunk <= dataout_fifo(31 downto 24);
                en_r_update <= '0';                              --already read fifo data,read next address
                ack <= '1';
              else
                ack <= '0';
              end if;
                if done = '1' then                                --wait spw transfer done
                  chunk_state <= ready;  
                  rd_chunk_fin <= '1';    
                  r_pointer <= r_pointer + 1;               
                end if;

            when others =>
              chunk_state <= ready;
            end case;             
        else
              case chunk_state is
              
                when ready =>                                           --wait fifodata takeout 
                  ack <= '0';
                  en_r_update <= '0';
                  rd_chunk_fin <= '0';
                  if re_ram = '1' then
                    chunk_state <= chunk_1;
                    en_r_update <= '0';
                  end if;

                  when chunk_1 =>
                    rd_chunk_fin <= '0';
                    en_r_update <= '1';
                    if dataout_valid = '1' then
                        data_out_chunk <= dataout_fifo(31 downto 24);
                        en_r_update <= '0';                             -- already read fifo data, read next address
                        if ack_latched = '0' then
                            ack <= '1';
                            ack_latched <= '1';                              -- Latch the ack
                        end if;
                    else
                        if ack_latched = '0' then
                            ack <= '0';
                        end if;
                    end if;
                    if done = '1' then                                 -- wait spw transfer done
                        chunk_state <= chunk_2;
                        ack_latched <= '0';                            -- Reset the latch for next chunk state transition
                    end if;
                  
                  
                when chunk_2 =>                
                  rd_chunk_fin <= '0';
                  en_r_update <= '1';
                  if dataout_valid = '1' then
                    data_out_chunk <= dataout_fifo(23 downto 16);
                    en_r_update <= '0';                             --already read fifo data,read next address
                    ack <= '1';
                  else
                    ack <= '0';
                  end if;
                    if done = '1' then                                --wait spw transfer done
                      chunk_state <= chunk_3;                    
                    end if;
  
                when chunk_3 =>
                  rd_chunk_fin <= '0';
                  en_r_update <= '1';
                  if dataout_valid = '1' then
                    data_out_chunk <= dataout_fifo(15 downto 8);
                    en_r_update <= '0';                             --already read fifo data,read next address
                    ack <= '1';
                  else
                    ack <= '0';
                  end if;
                    if done = '1' then                                --wait spw transfer done
                      chunk_state <= chunk_4;                    
                    end if;
  
                when chunk_4 =>
                  rd_chunk_fin <= '0';
                  en_r_update <= '1';
                  if dataout_valid = '1' then
                    data_out_chunk <= dataout_fifo(7 downto 0);
                    en_r_update <= '0';                              --already read fifo data,read next address
                    ack <= '1';                                      --acknowledge indicates successful read
                  else
                    ack <= '0';
                  end if;
                    if done = '1' then                                --wait spw transfer done
                      chunk_state <= ready;  
                      rd_chunk_fin <= '1';                     
                      r_pointer <= r_pointer + 1;                     --read next address
                    end if;

                when others =>
                  chunk_state <= ready;
              end case; 
        end if;
    end if;
  end process;
  
  -------------------
  --! Pointers update
  -------------------
  process (clk, rst_n, clr)
  begin
    if (rst_n = '0') then
      w_pointer <= (others => '0');
    elsif (clr = '1') then
      w_pointer <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (we_ram = '1') then
        w_pointer <= w_pointer + 1; 
      end if;     
    end if;
  end process;
  
  ----------------
  --! Flags update
  ----------------
  process (r_pointer, w_pointer)
    variable pointer_diff: signed(W_ADDR+1 downto 0);
  begin   
    if (r_pointer(w_pointer'high-1 downto 0) = w_pointer(w_pointer'high-1 downto 0))then 
      if (w_pointer(w_pointer'high) /= r_pointer(r_pointer'high)) then 
        is_full <= '1';
        is_empty <= '0';
      else
        is_full <= '0';
        is_empty <= '1';
      end if;
    else
      is_full <= '0';
      is_empty <= '0';
    end if;
    -- checking if FIFO is half full
    if signed('0'&w_pointer) >= signed('0'&r_pointer) then
      --here pointer diff equals the number of elements used
      pointer_diff := signed('0'&w_pointer) - signed('0'&r_pointer);
    else
      --here pointer diff equals the number of elements left
      pointer_diff := signed('0'&r_pointer)- signed('0'&w_pointer);
      pointer_diff := TOTAL - pointer_diff-1;
    end if;
    
    if (pointer_diff >= HALF) then
      is_hfull <= '1';
    else
      is_hfull <= '0';
    end if;
    -- end of checking if FIFO is half full
    if ((w_pointer(w_pointer'high-1 downto 0) = r_pointer(r_pointer'high-1 downto 0)-1)) then
      afull <= '1';
    else
      afull <= '0';
    end if;
      if (r_pointer(r_pointer'high-1 downto 0) = w_pointer(w_pointer'high-1 downto 0)-1) then
      aempty <= '1';
    else
      aempty <= '0';
    end if;
  end process;
      
end arch;
    