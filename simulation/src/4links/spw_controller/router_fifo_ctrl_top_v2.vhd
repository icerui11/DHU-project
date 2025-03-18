----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- transmit the data from the fifo to the spacewire router interface and receive the data from the spacewire interface
--                    v2 add the ability to communicate with the multiple SHyLoCs
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_fifo_ctrl_top_v2.vhd
-- @ Engineer				:	Rui
-- @ Date					: 	15.03.2024

-- @ VHDL Version			:   2008
-- @ Supported Toolchain	:	libero 12.0
-- @ Target Device			: 	m2s150t

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library smartfusion2;
use smartfusion2.all;

--! Use shyloc_121 library
library shyloc_121; 
--! Use generic shyloc121 parameters
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;
library work;
use work.system_constant_pckg.all;

context work.router_context;

entity router_fifo_ctrl_top_v2 is 
    generic (
    g_num_ports         : natural range 1 to 32     := c_num_ports;         -- number of ports
    g_is_fifo           : t_dword                   := c_fifo_ports;        -- fifo ports
    g_clock_freq        : real                      := c_spw_clk_freq;      -- clock frequency
    g_addr_width		: integer 					:= 9;					-- address width of connecting RAM/fifo
    g_data_width		: integer 					:= 8;					-- data width of connecting RAM/fifo
    g_mode				: string 					:= "single";			-- valid options are "diff", "single" and "custom".
    g_priority          : string                    := c_priority;          
    g_ram_style         : string                    := c_ram_style;
    g_router_port_addr  : integer                   := c_router_port_addr           
    );                                                                                                    

port(
    rst_n            : in std_logic;				-- active low reset
    clk              : in std_logic;				-- clock input
		
    rx_cmd_out		 : out 	rx_cmd_out_array(1 to c_num_fifoports);		            -- control char output bits(only fifo ports)
    rx_cmd_valid	 : out 	std_logic_vector(1 to c_num_fifoports);					-- asserted when valid command to output
    rx_cmd_ready	 : in 	std_logic_vector(1 to c_num_fifoports);					-- assert to receive rx command. 
    
    rx_data_out		 : out 	rx_data_out_array(1 to c_num_fifoports);		        -- received spacewire data output
    rx_data_valid	 : out 	std_logic_vector(1 to c_num_fifoports);					-- valid rx data on output
    rx_data_ready	 : in 	std_logic_vector(1 to c_num_fifoports);					-- assert to receive rx data

    ccsds_datain     : in   ccsds_datain_array(1 to c_num_fifoports);               --convert to 8 bit data in asym_FIFO
    w_update         : in   std_logic_vector(1 to c_num_fifoports);                 --connect with ccsds dataout newvalid
    asym_FIFO_full   : out  std_logic_vector(1 to c_num_fifoports);					-- fifo full signal
    ccsds_ready_ext  : out  std_logic_vector(1 to c_num_fifoports);					-- fifo ready signal
    
    raw_ccsds_data     : out raw_ccsds_data_array(1 to c_num_fifoports);            -- transmit to ccsds 123 encoder
    ccsds_datanewValid : out std_logic_vector(1 to c_num_fifoports);	            -- enable ccsds data input
    --DS signal chose by the c_port_mode 
    Din_p  			 : in 	std_logic_vector(1 to g_num_ports-1);	                -- IO used for "single" and "diff" io modes
    Sin_p            : in 	std_logic_vector(1 to g_num_ports-1);                   -- IO used for "single" and "diff" io modes
    Dout_p           : out 	std_logic_vector(1 to g_num_ports-1);                   -- IO used for "single" and "diff" io modes
    Sout_p           : out 	std_logic_vector(1 to g_num_ports-1);                   -- IO used for "single" and "diff" io modes

    spw_error        : out  std_logic_vector(1 to c_num_fifoports);
    router_connected : out  std_logic_vector(31 downto 1) := (others => '0')        -- output, asserted when SpW Link is Connected
);

end router_fifo_ctrl_top_v2;

architecture rtl of router_fifo_ctrl_top_v2 is 

    	-- Channels                                                                 	           
	signal spw_Rx_ESC_ESC           : std_logic_vector(1 to c_num_fifoports);                                
	signal spw_Rx_ESC_EOP           : std_logic_vector(1 to c_num_fifoports);                                
	signal spw_Rx_ESC_EEP           : std_logic_vector(1 to c_num_fifoports);                                
	signal spw_Rx_Parity_error      : std_logic_vector(1 to c_num_fifoports);                                                        
    
    signal reset           : std_logic := '1';								 -- reset signal
    signal fifo_data       : fifo_data_array(1 to c_num_fifoports);	     -- data FROM fifo
    signal fifo_clear      : std_logic_vector(1 to c_num_fifoports) := (others => '0');			-- clear signal for fifo
    signal fifo_r_update   : std_logic_vector(1 to c_num_fifoports);								         -- fifo read update signal
    signal asym_FIFO_empty : std_logic_vector(1 to c_num_fifoports);								         -- fifo empty signal

    signal fifo_ack        : std_logic_vector(1 to c_num_fifoports);		                                 -- fifo ack signal
    signal write_done      : std_logic_vector(1 to c_num_fifoports);		                                 -- write done signal   

    signal spw_fifo_in	   : r_fifo_master_array(1 to g_num_ports-1) := (others => c_fifo_master);
    signal spw_fifo_out	   : r_fifo_slave_array(1 to g_num_ports-1)  := (others => c_fifo_slave);
    --------------------------------------------------
    --function declaration
    --------------------------------------------------
    -- Create a mapping from FIFO indices to router port indices
    type t_fifo_port_map is array (1 to g_num_ports-1) of integer range 1 to c_num_fifoports;

    function create_fifo_map return t_fifo_port_map is
        variable map_result : t_fifo_port_map;
        variable fifo_count : integer := 0;
    begin
        for i in 1 to g_num_ports-1 loop
            if g_is_fifo(i) = '1' then
                fifo_count := fifo_count + 1;
                if fifo_count <= c_num_fifoports then
                    map_result(i) := fifo_count;
                end if;
            end if;
        end loop;
        return map_result;
    end function;
    
    constant fifo_port_map : t_fifo_port_map := create_fifo_map;

begin 

    reset  <= '1' when rst_n = '0' else '0';                                -- microchip use active low reset

    router_inst: entity work.router_top_level_RTG4(rtl)                 	-- instantiate SpaceWire Router 
	generic map(
		g_clock_freq 	=> g_clock_freq,
		g_num_ports 	=> g_num_ports,
		g_is_fifo 		=> g_is_fifo,
		g_mode			=> "single",					-- custom mode, we're instantiating SpaceWire in this top-level architecture
		g_priority 		=> g_priority,
		g_ram_style 	=> g_ram_style                  
	) 

	port map( 
		router_clk              => clk,
		rst_in					=> reset,	           -- router reset active high
		
		Din_p               	=> Din_p, 
		Sin_p               	=> Sin_p, 
		Dout_p              	=> Dout_p, 
		Sout_p              	=> Sout_p, 

		spw_fifo_in             => spw_fifo_in,
		spw_fifo_out	        => spw_fifo_out,
		
		Port_Connected			=> router_connected
	);
/*
    constant c_fifo_master : r_fifo_master :=(
		rx_data  		=> (others => '0'),
	    rx_valid 		=> '0',
		rx_time			=> (others => '0'),
		rx_time_valid 	=> '0',
        tx_ready 		=> '1',
		tx_time_ready 	=> '1',
		connected 		=> '0'
	);		
	
	constant c_fifo_slave : r_fifo_slave :=(
		tx_data  		=> (others => '0'),
		tx_valid		=> '0',
		tx_time			=> (others => '0'),
		tx_time_valid	=> '0',
		rx_ready 		=> '0',
		rx_time_ready   => '0'
	);
*/
--generate the fifo port data controller

    gen_fifo_controller: for i in 1 to g_num_ports-1 generate 
        gen_ctrl: if (g_is_fifo(i) = '1') generate
            router_fifo_ctrl_inst: entity work.router_fifo_spwctrl_16bit_v2(rtl)
            generic map (
            g_addr_width	   => g_addr_width,
            g_router_port_addr => g_router_port_addr,             -- fifo data to which port
            g_count_max 	   => g_data_width                    -- count for every ram address
            )
            port map( 
            -- standard register control signals --
            clk_in				=> 	clk,						-- clk input, rising edge trigger
            rst_in				=>	reset,						-- reset input, active high
            fifo_full			=>	asym_FIFO_full(fifo_port_map(i)),				-- fifo full signal
            fifo_empty          =>  asym_FIFO_empty(fifo_port_map(i)),			-- fifo empty signal
            fifo_r_update       =>  fifo_r_update(fifo_port_map(i)),              
            ccsds_ready_ext     =>  ccsds_ready_ext(fifo_port_map(i)),  
            fifo_ack            =>  fifo_ack(fifo_port_map(i)),                   
            write_done          =>  write_done(fifo_port_map(i)),                           
            -- RAM signals
            ram_data_in			=> 	fifo_data(fifo_port_map(i)),					              -- ram read data
  
            -- SpW Data Signals
            spw_Tx_data			=> 	spw_fifo_in(i).rx_data(7 downto 0),	      -- router fifo rxdata, is different from normal spw
            spw_Tx_Con			=> 	spw_fifo_in(i).rx_data(8),				  -- SpW Control Char Bit
            spw_Tx_OR			=> 	spw_fifo_in(i).rx_valid,			      -- output
            spw_Tx_IR			=> 	spw_fifo_out(i).rx_ready,			      -- input from router fifo

            spw_Rx_data			=>	spw_fifo_out(i).tx_data(7 downto 0),     -- input, from router_fifo,spw_Rx_data(7 downto 0), spw_fifo_out
            spw_Rx_Con		    =>	spw_fifo_out(i).tx_data(8),              
            spw_Rx_OR		    =>  spw_fifo_out(i).tx_valid,                -- input,spw_Rx_OR, input indicate the data is ready to transmit 
            spw_Rx_IR		    =>  spw_fifo_in(i).tx_ready,                 -- output,spw_Rx_IR, output from controller,indicate the RX data is valid,but in fifp port is tx_data

            rx_cmd_out		    =>  open,                                    -- not used
            rx_cmd_valid	    =>	rx_cmd_valid(fifo_port_map(i)),                            
            rx_cmd_ready	    =>  rx_cmd_ready(fifo_port_map(i)),                            

            rx_data_out		    =>	rx_data_out(fifo_port_map(i)),                             --rx_data_out, output 8 bit data to SHyLoc as raw data
  --          rx_data_valid	    =>	rx_data_valid,                           --not spw_Rx_Con; assert data valid if data received and handshake is asserted
            rx_data_ready	    =>	rx_data_ready(fifo_port_map(i)),                                                
            
            -- ccsds raw data input
            raw_ccsds_data      =>  raw_ccsds_data(fifo_port_map(i)),                         -- output, raw ccsds data
		    ccsds_datanewValid  =>  ccsds_datanewValid(fifo_port_map(i)),                     -- output, enable ccsds data input

            -- SpW Control Signals
            spw_Connected	 	=>  '1',			                        -- asserted when SpW Link is Connected(in this case, always asserted when fifo port is generated)
            spw_Rx_ESC_ESC	 	=> 	spw_Rx_ESC_ESC(fifo_port_map(i)),                     	  -- SpW ESC_ESC error 
            spw_ESC_EOP 	 	=> 	spw_Rx_ESC_EOP(fifo_port_map(i)),   		              -- SpW ESC_EOP error 
            spw_ESC_EEP      	=> 	spw_Rx_ESC_EEP(fifo_port_map(i)),     	                  -- SpW ESC_EEP error 
            spw_Parity_error 	=> 	spw_Rx_Parity_error(fifo_port_map(i)),                    -- SpW Parity error
     
            error_out			=> 	spw_error(fifo_port_map(i))				                  -- assert when error
            );
        
            spw_fifo_in(i).connected <= '1';                                -- assert router fifo connected when fifo port is generated

        asym_FIFO_inst_0: entity work.asym_FIFO 
        generic map(
            RESET_TYPE  => 1,         --! Reset type (Synchronous or asynchronous).
            W_Size      => 32,        --! Bit width of the stored values.
            R_Size      => 8,         --! Bit width of the read values.
            NE          => 64,        --! Number of elements of the FIFO.
            W_ADDR      => 8,         --! Bit width of the address.
            TECH        => 0)         --! Parameter used to change technology; (0) uses inferred memories.
        port map( 
            -- Inputs
            clk      => clk,
            rst_n    => rst_n,
            clr      => '0',
            w_update => w_update(fifo_port_map(i)),
            r_update => fifo_r_update(fifo_port_map(i)),
            data_in  => ccsds_datain(fifo_port_map(i)),
            done     => write_done(fifo_port_map(i)),
            -- Outputs
            hfull    => OPEN,
            empty    => asym_FIFO_empty(fifo_port_map(i)),
            full     => asym_FIFO_full(fifo_port_map(i)),
            afull    => OPEN,
            aempty   => OPEN,
            ack      => fifo_ack(fifo_port_map(i)),
            data_out_chunk => fifo_data(fifo_port_map(i)) 
            );
          
        end generate gen_ctrl; 
    end generate gen_fifo_controller;
end rtl;