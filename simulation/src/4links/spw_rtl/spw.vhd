----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	1

-- File Description         :

-- Document Number			:  xxx-xxxx-xxx
----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Copyright (c) 2018-2023, 4Links Ltd All rights reserved.
--
-- Redistribution and use in source and synthesised forms, with or without 
-- modification, are permitted provided that the following conditions are met:
-- 1. Redistributions of source code must retain the above copyright notice, 
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in synthesised form must reproduce the above copyright 
--    notice, this list of conditions and the following disclaimer in the 
--    documentation and/or other materials provided with the distribution.
-- 3. All advertising materials mentioning features or use of this code
--    must display the following acknowledgement: This product includes
--    code developed by 4Links Ltd.
-- 4. Neither the name of 4Links Ltd nor the names of its contributors may be
--    used to endorse or promote products derived from this code without 
--    specific prior written permission.
--
-- THIS CODE IS PROVIDED BY 4LINKS LTD "AS IS" AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
-- EVENT SHALL 4LINKS LTD BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS CODE, EVEN IF 
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-- Library Declarations  --
----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------------------------------------------------------
-- Package Declarations --
----------------------------------------------------------------------------------------------------------------------------------
context work.spw_context;
use work.all;

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw is
	generic(
		constant CLOCK_FREQUENCY : real      := 200000000.0;	-- clock frequency (in Hz)
		constant RX_FIFO_SIZE    : integer   :=  8;				-- number of SpW packets in RX fifo
		constant TX_FIFO_SIZE    : integer   :=  1				-- number of SpW packets in TX fifo
	);
	port( 
		-- General
		clock                 : in    std_logic	:= '0';
		clock_b               : in    std_logic	:= '0';
		reset                 : in    std_logic	:= '0';
		
		-- Control         
		Disable               : in    boolean;
		Legacy                : in    boolean;
		Error_select          : in    std_logic_vector(3 downto 0) := (others => '0');
		Error_inject          : in    boolean;
		Force_timeout_error   : in    boolean;
		
		-- Status
		Out_Stalled           :   out boolean;
		Connected             :   out boolean;
		
		-- DS                
		RxD_r                 : in    std_logic := '0';  -- Rising edge clock Rx data
		RxD_f                 : in    std_logic := '0';  -- Falling edge clock Rx data
		RxS_r                 : in    std_logic := '0';  -- Rising edge clock Rx strobe
		RxS_f                 : in    std_logic := '0';  -- Falling edge clock Rx strobe
		
		TxD                   :   out std_logic;  -- Rising edge clock Tx data
		TxS                   :   out std_logic;  -- Falling edge clock Tx strobe
		
		-- Data              
		Rx_Data               :   out std_logic_vector(8 downto 0 );
		Rx_Data_OR            :   out boolean;
		Rx_Data_IR            : in    boolean;
							
		Rx_ESC_ESC            :   out boolean;
		Rx_ESC_EOP            :   out boolean;
		Rx_ESC_EEP            :   out boolean;
		Rx_Parity_error       :   out boolean;
		Rx_bits               :   out integer range 0 to 2;
		Rx_rate               :   out std_logic_vector(15 downto 0);
		
		-- Time              
		Rx_Time               :   out std_logic_vector(7 downto 0 ) := (others => '0');
		Rx_Time_OR            :   out boolean;
		Rx_Time_IR            : in    boolean;
		
		Tx_Time               : in    octet;
		Tx_Time_OR            : in    boolean;
		Tx_Time_IR            :   out boolean;
		
		-- Data              
		Tx_Data               : in    std_logic_vector(8 downto 0 );
		Tx_Data_OR            : in    boolean;
		Tx_Data_IR            :   out boolean;
		
		-- prescalar load interface
		Tx_PSC					: in 	t_byte := (others => '0');
        Tx_PSC_valid			: in 	std_logic := '0';
		Tx_PSC_ready			: out 	std_logic := '0'
		
    );
end spw;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal first              : std_logic;
	signal second             : std_logic;
	signal valid              : boolean;
	signal bit_ok             : boolean;
	signal timeout_error      : boolean;
	signal combined_timeout_error : boolean;
	signal proper             : boolean;
	
	signal rx_enable          : boolean;
	signal rx_fct_received    : boolean;
	signal rx_too_many_fcts   : boolean;
	signal rx_init            : boolean;
	signal rx_error           : boolean;
	
	signal rx_raw_data        : nonet;
	signal rx_raw_or          : boolean;
	signal rx_raw_ir          : boolean;
	
	signal rx_buffered_data   : nonet;
	signal rx_buffered_or     : boolean;
	signal rx_buffered_ir     : boolean;
	
	signal rx_terminated_data : nonet;
	signal rx_terminated_or   : boolean;
	signal rx_terminated_ir   : boolean;
	
	signal clear_rx_fifo      : boolean;
	
	signal tx_enable          : boolean;
	signal tx_send_fct        : boolean;
	signal tx_fct_sent        : boolean;
	
	signal tx_buffered_data   : nonet;
	signal tx_buffered_or     : boolean;
	signal tx_buffered_ir     : boolean;
	
	signal link_ok            : boolean;
	
	signal tx_can_send_fct    : boolean;
	
	
	signal tx_valid_data      : nonet;
	signal tx_valid_or        : boolean;
	signal tx_valid_ir        : boolean;
	
	signal txdata             : nonet;
	signal txdata_or          : boolean;
	signal txdata_ir          : boolean;
	
	signal rx_tchar          : boolean;
	
	signal rx_rate_reset     : boolean;
	signal bits_per_clock    : integer range 0 to 2;
	
	signal rx_time_or_i      : boolean;
	
	signal txdi : std_logic;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------
	-- Alias Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-- Transmit data
	-------------------------------------------------------------------------------
	u_spw_tx_discard: entity spw_tx_discard
    port map (
		clock      => clock,
		reset      => reset,
		
		Link_OK    => Link_OK,
		
		in_data    => Tx_Data,
		in_OR      => Tx_Data_OR,
		in_IR      => Tx_Data_IR,
		
		out_data   => Tx_Valid_Data,
		out_OR     => Tx_Valid_OR,
		out_IR     => Tx_Valid_IR
    );
    
    u_spw_tx_flowcontrol: entity spw_tx_flowcontrol
    port map (
		clock         => clock,
		reset         => reset,
		
		rx_enable     => rx_enable,
		FCT_received  => Rx_FCT_received,
		too_many_FCTs => Rx_too_many_FCTs,
		
		stalled       => Out_Stalled,
		
		in_data       => Tx_Valid_Data,
		in_OR         => Tx_Valid_OR,
		in_IR         => Tx_Valid_IR,
	
		out_data      => Tx_Buffered_Data,
		out_OR        => Tx_Buffered_OR,
		out_IR        => Tx_Buffered_IR
	);
    
    u_tx_ds: entity spw_tx_ds
	generic map (
	  CLOCK_FREQUENCY => CLOCK_FREQUENCY
	)
	port map(
	    clock         => clock,
	    reset         => reset,
	    
	    enable        => Tx_enable,
	    Error_select  => Error_select,
	    Error_inject  => Error_inject,
	    
	    Link_OK       => Link_OK,
	    
	    D            => TxDi, --TxD,
	    S            => TxS,
	    
	    TxD          => Tx_Buffered_Data,
	    TxD_OR       => Tx_Buffered_OR,
	    TxD_IR       => Tx_Buffered_IR,
	    
	    TxT          => Tx_Time,   
	    TxT_OR       => Tx_Time_OR,
	    TxT_IR       => Tx_Time_IR,
		
		-- prescalar load interface
		PSC			=> Tx_PSC,			
        PSC_valid	=> Tx_PSC_valid,
		PSC_ready	=> Tx_PSC_ready,	
	    
	    FCT          => Tx_send_FCT,
	    FCT_sent     => Tx_FCT_sent
    );
	
	-------------------------------------------------------------------------------
	-- Link Control
	-------------------------------------------------------------------------------
	u_spw_ctrl: entity spw_ctrl
	generic map(
	  CLOCK_FREQUENCY => CLOCK_FREQUENCY
	)
	port map(
		clock          => clock,
		reset          => reset,
		
		link_disabled  => Disable, --false,
		link_start     => Proper,  --true,
		link_autostart => Legacy,  --false,
		
		Link_OK        => Link_OK,
		
		Rx_tchar       => Rx_Tchar,
		Rx_nchar       => Rx_Raw_OR,
		Rx_FCT         => Rx_FCT_received,
		Rx_error       => Rx_error,
		Rx_init        => Rx_init,
		rx_enable      => Rx_enable,
		
		tx_enable      => Tx_enable,
		Tx_OK_to_FCT   => Tx_can_send_FCT
	);
	
	-- Credit Flow control 
    u_spw_rx_flowcredit_x: entity spw_rx_flowcredit_x
	generic map(
		FIFO_SIZE     => RX_FIFO_SIZE
    )
	port map(
		clock            => clock,
		reset            => reset,
	
		Rx_FIFO_out_data => rx_buffered_data,
		Rx_FIFO_out_OR   => rx_buffered_OR,
		Rx_FIFO_out_IR   => rx_buffered_IR,
	
		Tx_can_send_FCT  => Tx_can_send_FCT,
		send_FCT         => Tx_send_FCT,
		FCT_sent         => Tx_FCT_sent
    );

	 -- Rx Detect timeout              
    u_spw_timeout_det: entity spw_timeout_det
	generic map( 
		CLOCK_FREQUENCY => CLOCK_FREQUENCY 
	)
	port map(
		clock           => clock,
		reset           => reset,
		
		enable          => Rx_enable,
		bit_ok          => bit_ok,
		timeout_error   => timeout_error
	);
	
	u_spw_rx_bit_rate: entity spw_rx_bit_rate
	generic map(
		CLOCK_FREQUENCY    => CLOCK_FREQUENCY,
		MAX_BITS_PER_CLOCK => 2
	)
	port map( 
		clock           => clock,
		reset           => rx_rate_reset,
		
		bits_per_clock  => bits_per_clock,
		rx_rate         => Rx_rate
	);
	
	-------------------------------------------------------------------------------
	-- Receive data
	-------------------------------------------------------------------------------
	 -- Rx DS link input, convert to 2bit data
    u_spw_rx_to_2b: entity spw_rx_to_2b
	port map(
		clock           => clock,
		clock_b         => clock_b,
		reset           => reset,
				
		Din_r           => RxD_r,
		Din_f           => RxD_f,
		Sin_r           => RxS_r,
		Sin_f           => RxS_f,
		
		first           => first,
		second          => second,
		valid           => valid,
		bit_ok          => bit_ok
 );

    -- Rx Convert 2bit data into 9bit word    
    u_spw_rx_to_data: entity spw_rx_to_data
	port map (
		clock           => clock,
		reset           => reset,
		
		enable          => Rx_enable,
		
		See_null        => false, -- true if null is to be reported
		See_fct         => false, -- true if fct is to be reported
				
		first           => first,
		second          => second,
		valid           => valid,
		
		RxD             => Rx_Raw_Data,
		RxD_OR          => Rx_Raw_OR,
		RxD_IR          => Rx_Raw_IR,  -- Not implemented yet
		
		RxT_OR          => Rx_Tchar,
		RxT             => Rx_Time,
		
		timeout_error   => combined_timeout_error,
		too_many_FCTs   => Rx_too_many_FCTs,  -- Not implemented yet
		
		NULL_seen       => Rx_init,
		FCT_received    => Rx_FCT_received,
		Error           => Rx_error
    );
	
	u_spw_fifo_2C: entity spw_fifo_2c
	generic map( 
		FIFO_SIZE => RX_FIFO_SIZE 
	)
	port map(
		Clear      => clear_rx_fifo,
		
		In_clock   => clock,
		In_reset   => reset,
		Din        => Rx_Raw_Data,
		Din_OR     => Rx_Raw_OR,
		Din_IR     => Rx_Raw_IR,
			
		Out_clock  => clock,
		out_reset  => reset,
		Dout       => rx_buffered_Data,
		Dout_OR    => rx_buffered_OR,
		Dout_IR    => rx_buffered_IR
	);
	
	u_spw_rx_add_eep: entity spw_rx_add_eep
	port map (
		clock           => clock,
		reset           => reset,
		
		rx_enable       => rx_enable,
	
		in_Data         => rx_buffered_Data,
		in_OR           => rx_buffered_OR,
		in_IR           => rx_buffered_IR,
		
		out_Data        => rx_terminated_Data,
		out_OR          => rx_terminated_OR,
		out_IR          => rx_terminated_IR
	);

	u_spw_filter_errors: entity spw_filter_errors
    port map (
		clock             => clock,
		reset             => reset,
		
		Report_all_errors => false,
				
		in_Data           => rx_terminated_Data,
		in_OR             => rx_terminated_OR,
		in_IR             => rx_terminated_IR,
	
		out_Data          => Rx_Data,
		out_OR            => Rx_Data_OR,
		out_IR            => Rx_Data_IR
    );
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	-- TX signal assignments --
	TxD <= TxDi;
	
	-- link control assignments
	Proper <= not Legacy;
	Connected <= Link_OK;
	-- Inject Rx timeout error
    combined_timeout_error <= timeout_error or Force_timeout_error;
    -- Detect Rx data rate
    bits_per_clock <= 2 when valid else 0;
    Rx_bits        <= bits_per_clock;
    rx_rate_reset  <= not rx_enable;
	
	-- RX signal assignments
	-- Rx FIFO buffer
    clear_rx_fifo <= not rx_enable;
	
	-- process assignments
	Rx_Time_OR    <= rx_time_or_i;
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-- Report Rx special characters/commands				 
    process(Clock)
    begin
	--	if (reset = '1') then
	--		rx_time_or_i      <= false;
	--		
	--		Rx_ESC_ESC        <= false;
	--		Rx_ESC_EOP        <= false;
	--		Rx_ESC_EEP        <= false;
	--		Rx_Parity_error   <= false;	
	  
		if rising_edge( Clock ) then
			if (reset = '1') then
				rx_time_or_i      <= false;
				Rx_ESC_ESC        <= false;
				Rx_ESC_EOP        <= false;
				Rx_ESC_EEP        <= false;
				Rx_Parity_error   <= false;
			else
				rx_time_or_i    <= Rx_Tchar or (rx_time_or_i and not Rx_Time_IR and Rx_enable);
				Rx_ESC_ESC      <= Rx_Raw_OR and Rx_Raw_IR and Rx_Raw_Data = SPW_ESC_ESC;
				Rx_ESC_EOP      <= Rx_Raw_OR and Rx_Raw_IR and Rx_Raw_Data = SPW_ESC_EOP;
				Rx_ESC_EEP      <= Rx_Raw_OR and Rx_Raw_IR and Rx_Raw_Data = SPW_ESC_EEP;
				Rx_Parity_error <= Rx_Raw_OR and Rx_Raw_IR and Rx_Raw_Data = SPW_PERROR1;
			end if;
		end if;
    end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;