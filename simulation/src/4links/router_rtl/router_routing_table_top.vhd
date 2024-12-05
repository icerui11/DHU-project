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
entity router_routing_table_top is 
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
end entity router_routing_table_top;

---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------

	-- See Xilinx User Guide UG974 for US+ ram_style options. --
	-- Instantiates Single-port, Single-clock, Read-first Xilinx RAM. 

architecture rtl of router_routing_table_top is

	attribute ram_style : string;
	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
    constant s_ram_reg_0 : std_logic_vector(data_width-1 downto 0) := "00000001";                    --initialize the port 0 value
	constant s_ram_reg_1 : std_logic_vector(data_width-1 downto 0) := "00000000";
	constant s_ram_reg_2 : std_logic_vector(data_width-1 downto 0) := "00000000";
	constant s_ram_reg_3 : std_logic_vector(data_width-1 downto 0) := "00000000";
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	subtype mem_element is std_logic_vector(data_width-1 downto 0);				-- declare size of each memory element in RAM
	type t_ram is array (natural range <>) of mem_element;						-- declare RAM as array of memory element
	
   
	--state machine states
    type init_state is (idle, initial, init_done);
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
	signal s_ram : t_ram(0 to (2**addr_width)-1);             -- := init_router_mem(256);	-- declare ram and initialize using above function
    signal data_reg : std_logic_vector(data_width-1 downto 0) := (others => '0');

    --signal for routing table ram
    signal wr_en_reg : std_logic := '0';
    signal wr_addr_reg : std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal wr_data_reg : std_logic_vector(data_width-1 downto 0) := (others => '0');

    --control signals
    signal init_wr_en : std_logic;
    signal init_wr_addr : std_logic_vector(addr_width-1 downto 0);
    signal init_wr_data : std_logic_vector(data_width-1 downto 0);

    signal shift : integer range 0 to 3 := 0;
    signal init_done_r : std_logic := '0';
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin
	--dual control 
    wr_en_reg <= wr_en or init_wr_en;

    init_fsm: process(clk_in)
    variable v_ram : t_ram(0 to (ram_depth*4)-1);
    variable element : std_logic_vector(31 downto 0) := (others => '0');

    variable chunk : integer range 0 to 3 := 0;                                 --4 chunk for each read address
    variable index : integer range 0 to c_num_ports := 0;
    begin
        if (rising_edge(clk_in)) then
            if (rst_in = '1') then
                rt_state < idle;

            else 
                case rt_state is 

                    when idle =>
                        rt_state <= initial;
                        index := 0;

                    when initial =>
                        data_reg <= init_ram;
                        
                        if index <= c_num_ports then
                            element := (others => '0');
                            element(index) := '1';
                            init_wr_en <= '1';
                            chunk := chunk + 1;
                            if chunk = 0 then 
                                wr_data_reg <= element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                wr_addr_reg <= wr_addr_reg + 1;
                            elsif chunk = 1 then
                                wr_data_reg <= element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                wr_addr_reg <= wr_addr_reg + 1;
                            elsif chunk = 2 then
                                wr_data_reg <= element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                wr_addr_reg <= wr_addr_reg + 1;
                            elsif chunk = 3 then
                                wr_data_reg <= element(((8 * (chunk + 1)) - 1) downto (8 * chunk));
                                wr_addr_reg <= wr_addr_reg + 1;
                                index := index + 1;                                                            --shift to next element
                            end if;
                        else
                            rt_state <= init_done;                                        --init done 
                        end if;

                    when init_done =>
                        init_wr_en <= '0';
                    
                    when others =>
                        rt_state <= idle;

                end case;
            end if;
        end if;
    end process;


/*
    process(clk_in)
        variable index : integer range 0 to c_num_ports := 0;
    --    variable element : t_ram(0 to (ram_depth*4)-1);
        variable element : std_logic_vector(((data_width*4)-1) downto 0) := (others => '0');
        variable v_ram : t_ram(0 to (c_num_ports*4)-1);
        variable chunk : integer range 0 to 3 := 0;
        begin
        if rising_edge(clk) then
        wr_data_reg <= data_reg;

            if reset = '1' then
                -- Initialize signals on reset
                index := 0;
                v_counter <= 1;
    --            element := (others => '0');
                wr_addr_reg <= (others => '0');
                wr_data_reg <= (others => '0');
            else
                if rt_state = initial then
                    -- Update v_counter
                    if(v_counter = c_num_ports-1) then
                        v_counter <= 1;
                    else
                        v_counter <= v_counter + 1;
                    end if;
        
                    -- Address each ratio step individually within current index
                    for j in 0 to ratio-1 loop
                        v_ram(j + (ratio * index)) <= element(((8 * (j + 1)) - 1) downto (8 * j));
                    end loop;
                    
                    -- Move to the next index
                    index <= index + 1;

                end if;
            end if;
        end if;
     end process;
*/

    --ram component
    routing_table_ram: entity work.routing_table_ram(rtl)
    generic map(
        data_width => data_width,
        addr_width => addr_width
    )                    
    port map(
        clk_in => clk_in,

        wr_en => wr_en_reg,
        wr_addr => wr_addr,
        wr_data => wr_data,

        rd_addr => rd_addr,
        rd_data => rd_data
    );


	ram_proc:process(clk_in)
	begin
		if(rising_edge(clk_in)) then
			if(enable_in = '1') then
				if(wr_en = '1') then
					s_ram(to_integer(unsigned(wr_addr))) <= wr_data;
				end if;
				rd_data <= s_ram(to_integer(unsigned(rd_addr)));
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
end rtl;