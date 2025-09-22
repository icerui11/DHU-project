library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--router package
context work.router_context;

entity spw_router_loopback_test is
    generic(
        g_clock_freq	: real 					:= c_spw_clk_freq;		-- these are located in router_pckg.vhd
        g_num_ports 	: natural range 1 to 32 := c_num_ports;         -- these are located in router_pckg.vhd
		g_mode			: string				:= c_port_mode;         -- these are located in router_pckg.vhd
		g_is_fifo		: t_dword 				:= c_fifo_ports;        -- these are located in router_pckg.vhd
		g_priority		: string 				:= c_priority;          -- these are located in router_pckg.vhd
		g_ram_style 	: string				:= c_ram_style			-- style of RAM to use (Block, Auto, URAM etc),     
    );

    port(
        		-- standard register control signals --
		router_clk		: in 	std_logic := '0';		-- router clock input 
		rst_in			: in 	std_logic := '0';		-- reset input, active high
	
		Din_p  			: in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "single" and "diff" io modes
		Sin_p           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Dout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
		Sout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0')  -- IO used for "single" and "diff" io modes

    );

end spw_router_loopback_test;

architecture rtl of spw_router_loopback_test is


component router_top_level_RTG4 is
    generic(
        g_clock_freq	: real 					:= c_spw_clk_freq;		-- these are located in router_pckg.vhd
        g_num_ports 	: natural range 1 to 32 := c_num_ports;         -- these are located in router_pckg.vhd
        g_mode			: string				:= c_port_mode;         -- these are located in router_pckg.vhd
        g_is_fifo		: t_dword 				:= c_fifo_ports;        -- these are located in router_pckg.vhd
        g_priority      : string                := c_priority;          
        g_ram_style 	: string				:= c_ram_style			-- style of RAM to use (Block, Auto, URAM etc),
    );
    port(
        -- standard register control signals --
        router_clk		: in 	std_logic := '0';		-- router clock input 
        rst_in			: in 	std_logic := '0';		-- reset input, active high

        DDR_din_r		: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "custom" io mode 
        DDR_din_f   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
        DDR_sin_r   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
        DDR_sin_f   	: in	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
        SDR_Dout		: out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 
        SDR_Sout		: out	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "custom" io mode 

        Din_p  			: in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0');	-- IO used for "single" and "diff" io modes
        Din_n           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Sin_p           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Sin_n           : in 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Dout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Dout_n          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Sout_p          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes
        Sout_n          : out 	std_logic_vector(1 to g_num_ports-1)	:= (others => '0'); -- IO used for "single" and "diff" io modes

        spw_fifo_in		: in 	r_fifo_master_array(1 to g_num_ports-1) := (others => c_fifo_master);
        spw_fifo_out	: out 	r_fifo_slave_array(1 to g_num_ports-1)	:= (others => c_fifo_slave);
        Port_Connected	: out 	std_logic_vector(31 downto 1) := (others => '0')	-- High when "connected" May want to map these to LEDs
    );


begin

    router_inst : router_top_level_RTG4
    generic map(
        g_clock_freq	=> g_clock_freq,
        g_num_ports 	=> g_num_ports,
        g_mode			=> g_mode,
        g_is_fifo		=> g_is_fifo,
        g_priority		=> g_priority,
        g_ram_style 	=> g_ram_style
    )
    port map(
        router_clk		=> router_clk,
        rst_in			=> rst_in,
        DDR_din_r		=> '0',
        DDR_din_f   	=> '0',
        DDR_sin_r   	=> '0',
        DDR_sin_f   	=> '0',
        SDR_Dout		=> open,
        SDR_Sout		=> open,
        Din_p  			=> Din_p,
        Din_n           => '0',
        Sin_p           => Sin_p,
        Sin_n           => '0',
        Dout_p          => Dout_p,
        Dout_n          => open,
        Sout_p          => Sout_p,
        Sout_n          => open,
        spw_fifo_in		=> '0',
        spw_fifo_out	=> open,
        Port_Connected	=> open
    );
    
end rtl;