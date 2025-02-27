----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:router_routing_table_top.vhd
-- @ Engineer				: Rui
-- @ Role					:
-- @ Company				:IDA

-- @ VHDL Version			:
-- @ Supported Toolchain	:
-- @ Target Device			: sm2

-- @ Revision #				:

-- File Description         : initialises the routing table with the default values

-- Document Number			:  xxx-xxxx-xxx
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
entity router_routing_table_top_v2 is 
	generic(
		data_width	: natural := 32;			-- bit-width of ram element (0-31 = port number)
		addr_width	: natural := 8				-- address width of RAM (256 address, (0 -> 31) and 255 are reserved)
	);
	port(
		-- standard register control signals --
		clk_in 		: in 	std_logic := '0';											-- clock in (rising_edge)
        rst_in  : in    std_logic;                                              --import rst
		enable_in 	: in 	std_logic := '0';											-- enable input (active high)
		
		wr_en		: in 	std_logic := '0';											-- write enable (asserted high)
		wr_addr		: in 	std_logic_vector(addr_width-1 downto 0) := (others => '0');	-- write address
		wr_data     : in    std_logic_vector(data_width-1 downto 0) := (others => '0');	-- write data
		
		rd_addr		: in 	std_logic_vector(addr_width-1 downto 0) := (others => '0'); -- read address 
		rd_data		: out 	std_logic_vector(data_width-1 downto 0) := (others => '0')	-- read data
		
	);
end entity router_routing_table_top_v2;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------

architecture rtl of router_routing_table_top_v2 is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	--state machine states
    type init_state is (idle, get_pre_data, initial_path, initial_logic, init_done);
    signal rt_state : init_state := idle;

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------


    --signal for routing table ram
    signal wr_en_reg : std_logic := '0';
    signal wr_addr_reg : std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal wr_data_reg : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal rd_data_reg : std_logic_vector(data_width-1 downto 0) := (others => '0');
    --control signals


    signal index : integer range 0 to 31:= 0;
    signal init_done_r : std_logic := '0';
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin

    rd_data <= rd_data_reg;                                        --assign read data to output

    --state machine for initialisation
    init_fsm: process(clk_in)

    variable element : std_logic_vector(31 downto 0) := (others => '0');
    variable init_wr_en   : std_logic := '0';
    variable init_wr_addr : integer range 0 to 1023 := 0;                      --unsigned(addr_width-1 downto 0) := (others => '0');
    variable init_wr_data : std_logic_vector(data_width-1 downto 0);
    variable chunk : integer range 0 to 3 := 0;                                 --4 chunk for each read address

    begin
        if (rising_edge(clk_in)) then
            if (rst_in = '1') then
                rt_state <= idle;
                init_wr_en := '0';
                init_wr_addr := 0;
                element := (others => '0');
                element(0) := '1';
                index <= 0;
                chunk := 0;
            else 
                case rt_state is 

                    when idle =>
                        rt_state <= get_pre_data;                                               --move to get_pre_data state
                        index <= 0;

                    when get_pre_data =>  
                         init_wr_data := "00000001";
                         init_wr_en := '1';                                                       --start init next cycle
                         rt_state <= initial_path;                                                    --move to initial state

                    when initial_path =>                       
                        if index < c_num_ports then
                            element := (others => '0');
                            element(index) := '1';                                                --set the port number
                            init_wr_en := '1';
                            chunk := (chunk + 1) mod 4;
                            init_wr_addr := init_wr_addr + 1;
                            if chunk = 0 then 
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                            elsif chunk = 1 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                            elsif chunk = 2 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                            elsif chunk = 3 then
                                init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                index <= index + 1;                                                            --shift to next element
                            end if;

                        else
                            rt_state <= initial_logic;                                      --init done 
                            index <= 1;                                                     --initial logic address from port 1
                            init_wr_addr := 128;                                            --initial logic address from 0x80
                            chunk := 0;                                                     
                            init_wr_en := '1';                                            
                            element := (others => '0');
                            element(1) := '1';                                              --prefetch port 1 for logic address 0x20(0x80)
                            init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                        end if;

                    when initial_logic =>

                        if init_wr_addr < 1019 then                                             --initial logic address to 0xFC, FF is reserved

                                if index < c_num_ports then                                       --shift to next element and not exceed c_num_ports
                                element := (others => '0');
                                element(index) := '1';
                                init_wr_en := '1';
                                chunk := (chunk + 1) mod 4;
                                init_wr_addr := init_wr_addr + 1;
                                    if chunk = 0 then 
                                        init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                    elsif chunk = 1 then
                                        init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                    elsif chunk = 2 then
                                        init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                    elsif chunk = 3 then
                                        init_wr_data := element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                        index <= index + 1;                                                            --shift to next element
                                    end if;
                                else 
                                    index <= 1;
                                    init_wr_en := '0';
                                end if;
                            elsif init_wr_addr < 1023 then                                        -- initialize logic address 0xFF
                                init_wr_addr := init_wr_addr + 1;
                                init_wr_data := "00000000";
                                init_wr_en := '1';
                            elsif init_wr_addr = 1023 then
                                rt_state <= init_done;
                                init_wr_data := "00000000";
                                init_wr_en := '0';
                            end if;

                    when init_done =>
                        init_wr_en := '0';

                    when others =>
                        rt_state <= idle;

                end case;
            end if;
        end if;
        
        --remove wr_addr logic for init_done state
        wr_data_reg <= wr_data when (rt_state = init_done)  else init_wr_data ;                          --create mux for chose input or initial value
        wr_addr_reg <= wr_addr when (rt_state = init_done) else std_logic_vector(to_unsigned(init_wr_addr,10));
        wr_en_reg   <= wr_en when (rt_state = init_done) else init_wr_en;
    end process;

    --ram component
    routing_table_ram: entity work.routing_table_ram(rtl)
    generic map(
        data_width => data_width,
        addr_width => addr_width
    )                    
    port map(
        clk_in => clk_in,
        enable_in => enable_in,
        wr_en   => wr_en_reg,
        wr_addr => wr_addr_reg,
        wr_data => wr_data_reg,

        rd_addr => rd_addr,
        rd_data => rd_data_reg
    );
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
end rtl;