----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				: mixed_width_ram_top.vhd
-- @ Engineer				: Rui
-- @ Role					:
-- @ Company				: IDA

-- @ VHDL Version			:
-- @ Supported Toolchain	:
-- @ Target Device			: sm2

-- @ Revision #				:

-- File Description         : initialises the routing table(mixed width ram) with the default values

-- Document Number			:  06.12.2024
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-- Library Declarations  --
----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------------------------------------------------------------
-- Package Declarations --
----------------------------------------------------------------------------------------------------------------------------------
context work.router_context;

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity mixed_width_ram_top is 

	port(
		-- standard register control signals --
		clk_in 		: in 	std_logic := '0';											-- clock in (rising_edge)
        rst_in  : in    std_logic;                                              --import rst
		
		wr_en		: in 	std_logic := '0';											-- write enable (asserted high)
		w_addr		: in 	std_logic_vector(9 downto 0) := (others => '0');	-- write 1024
		w_data          : in    std_logic_vector(7 downto 0) := (others => '0');	    -- write data byte 
		
		r_addr		: in 	std_logic_vector(7 downto 0) := (others => '0');    -- read address 256
		r_data		: out 	std_logic_vector(31 downto 0) := (others => '0')	-- read data dwords
		
	);
end entity mixed_width_ram_top;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------

architecture rtl of mixed_width_ram_top is

	attribute ram_style : string;
	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	--define function 
    function calculate_length(input : std_logic_vector) return natural is
        begin
            return input'length;
    end function;
-- calculate the length 
    constant w_addr_width : natural := calculate_length(w_addr);             -- write address width, 10 bits
    constant w_data_width : natural := calculate_length(w_data);             -- write data width, 8 bits
    constant r_addr_width : natural := calculate_length(r_addr);             -- read address width, 32 bits
    constant r_data_width : natural := calculate_length(r_data);             -- read data width, 8 bits

	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	subtype mem_element is std_logic_vector(w_data_width-1 downto 0);				-- declare size of each memory element in RAM
	type t_ram is array (natural range <>) of mem_element;						-- declare RAM as array of memory element
	
	--state machine states
    type init_state is (idle, get_pre_data, initial, init_done);
    signal rt_state : init_state := idle;

	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal s_ram : t_ram(0 to (2**w_addr_width)-1);             -- := init_router_mem(256);	-- declare ram and initialize using above function
    signal data_reg : std_logic_vector(w_data_width-1 downto 0) := (others => '0');

    --signal for routing table ram
    signal wr_en_reg : std_logic := '0';
    signal wr_addr_reg : std_logic_vector(w_addr_width-1 downto 0) := (others => '0');
    signal wr_data_reg : std_logic_vector(w_data_width-1 downto 0) := (others => '0');
    signal rd_data_reg : std_logic_vector(r_data_width-1 downto 0) := (others => '0');
    --control signals
--    signal init_wr_en   : std_logic;
 --   signal init_wr_addr : unsigned(addr_width-1 downto 0) := (others => '0');
  --  signal init_wr_data : std_logic_vector(data_width-1 downto 0);

    signal index : integer range 0 to 31:= 0;
    signal init_done_r : std_logic := '0';
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------
begin

    r_data <= rd_data_reg;                                        --assign read data to output

    --state machine for initialisation
    init_fsm: process(clk_in)

    variable element : std_logic_vector(31 downto 0) := (others => '0');
    variable init_wr_en   : std_logic := '0';
    variable init_wr_addr : unsigned(w_addr_width-1 downto 0) := (others => '0');
    variable init_wr_data : std_logic_vector(w_data_width-1 downto 0);
    variable chunk : integer range 0 to 3 := 0;                                 --4 chunk for each read address
 --   variable index : integer range 0 to 31:= 0;
    begin
        if (rising_edge(clk_in)) then
            if (rst_in = '1') then
                rt_state <= idle;
                init_wr_en := '0';
                init_wr_addr := (others => '0');
                element := (others => '0');
                element(0) := '1';
                index <= 0;
                chunk := 0;
            else 
                case rt_state is 

                    when idle =>
   --                     init_wr_en := '1';                                                       --start init next cycle
                        rt_state <= get_pre_data;                                               --move to get_pre_data state
                        index <= 0;
    --                    init_wr_data := "00000001";

                    when get_pre_data =>  
                         init_wr_data := "00000001";
                         init_wr_en := '1';                                                       --start init next cycle
                         rt_state <= initial;                                                    --move to initial state

                    when initial =>                       
                        if index < c_num_ports then
                            element := (others => '0');
                            element(index) := '1';
                            init_wr_en := '1';
                            chunk := (chunk + 1) mod 4;
                            if chunk = 0 then 
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                init_wr_addr := init_wr_addr + 1;
         --                       wr_addr_reg <= std_logic_vector(init_wr_addr);
                            elsif chunk = 1 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                init_wr_addr := init_wr_addr + 1;
         --                     wr_addr_reg <= std_logic_vector(init_wr_addr);
                            elsif chunk = 2 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                init_wr_addr := init_wr_addr + 1;
         --                       wr_addr_reg <= std_logic_vector(init_wr_addr);
                            elsif chunk = 3 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                init_wr_addr := init_wr_addr + 1;
         --                       wr_addr_reg <= std_logic_vector(init_wr_addr);
                                index <= index + 1;                                                            --shift to next element
                            end if;
     --                       wr_addr_reg <= std_logic_vector(init_wr_addr);
                        else
                            rt_state <= init_done;                                        --init done 
     --                       init_wr_en <= '0';                                            --stop init
                        end if;

                    when init_done =>
                        init_wr_en := '0';
    --                    wr_addr_reg <= wr_addr;
    --                    wr_data_reg <= wr_data;
                    when others =>
                        rt_state <= idle;

                end case;
            end if;
        end if;
        
        --remove wr_addr logic for init_done state
        wr_data_reg <= init_wr_data when (rt_state = initial or rt_state = get_pre_data)  else w_data;                          --create mux for chose input or initial value
        wr_addr_reg <= std_logic_vector(init_wr_addr) when rt_state = initial else w_addr;
        wr_en_reg   <= init_wr_en when rt_state = initial else wr_en;
    end process;

    --ram component
    mixed_width_ram: entity work.mixed_width_ram_comp(rtl)
                 
    port map(
		clk_in	=> clk_in,										-- clk input, rising edge trigger
		
		wr_en	=> 	wr_en_reg,
		r_addr 	=> 	r_addr,                                     -- from input port
		w_addr 	=>	wr_addr_reg,
		
		
		w_data  => wr_data_reg,
		r_data	=> rd_data_reg                                  -- to output port
    );
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
end rtl;