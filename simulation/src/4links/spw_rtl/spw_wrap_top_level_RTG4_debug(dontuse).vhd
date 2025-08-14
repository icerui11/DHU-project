----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	spw_wrap_top_level_std.vhd
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	17/05/2024

-- @ VHDL Version			:   2008
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

-- Library For rtg4 technology specific Primitives
--library rtg4; 
--use rtg4.all;
library smartfusion2;
use smartfusion2.all;
----------------------------------------------------------------------------------------------------------------------------------
-- Package Declarations --
----------------------------------------------------------------------------------------------------------------------------------
context work.router_context;
use work.all;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_wrap_top_level_RTG4 is
	generic(
		g_clock_frequency   : real 						:= 125000000.0;			-- clock frequency for SpaceWire IP (>2MHz)
		g_rx_fifo_size      : integer range 16 to 56 	:= 56; 					-- must be >8
		g_tx_fifo_size      : integer range 16 to 56 	:= 56; 					-- must be >8
		g_mode				: string 					:= "diff"				-- valid options are "diff", "single" and "custom".
	);
	port( 
		clock                : in    	std_logic := '0';
		reset                : in    	std_logic := '0';
	
		-- Channels
		Tx_data              : in    	t_nonet;
		Tx_OR                : in    	std_logic := '0';
		Tx_IR                : out 		std_logic := '0';
		
		Rx_data              : out 		t_nonet;
		Rx_OR                : out 		std_logic := '0';
		Rx_IR                : in    	std_logic := '0';
		
		Rx_ESC_ESC           : out 		std_logic := '0';
		Rx_ESC_EOP           : out 		std_logic := '0';
		Rx_ESC_EEP           : out 		std_logic := '0';
		Rx_Parity_error      : out 		std_logic := '0';
		Rx_bits              : out 		std_logic_vector(1 downto 0) := (others => '0');--integer range 0 to 2;
		Rx_rate              : out 		std_logic_vector(15 downto 0) := (others => '0');
		
		Rx_Time              : out 		t_byte;
		Rx_Time_OR           : out 		std_logic := '0';
		Rx_Time_IR           : in    	std_logic := '0';
		
		Tx_Time              : in    	t_byte;
		Tx_Time_OR           : in    	std_logic := '0';
		Tx_Time_IR           : out 		std_logic := '0';
		
		-- prescalar load interface
		Tx_PSC				: in 		t_byte := (others => '0');
        Tx_PSC_valid		: in 		std_logic := '0';
		Tx_PSC_ready		: out 		std_logic := '0';
		
		-- Control	
		Disable              : in    	std_logic := '0';
		Connected            : out 		std_logic;
		Error_select         : in    	std_logic_vector(3 downto 0) := (others => '0');
		Error_inject         : in    	std_logic := '0';
		
		-- DDR/SDR IO, only when "custom" mode is used
		-- when instantiating, if not used, you can ignore these ports. 
		DDR_din_r			: in 		std_logic := '0';
		DDR_din_f           : in 		std_logic := '0';
		DDR_sin_r           : in 		std_logic := '0';
		DDR_sin_f           : in 		std_logic := '0';
		SDR_Dout			: out 		std_logic := '0';
		SDR_Sout			: out 		std_logic := '0';
		
		-- SpW	
		Din_p                : in    	std_logic := '0';
		Din_n                : in    	std_logic := '0';
		Sin_p                : in    	std_logic := '0';
		Sin_n                : in    	std_logic := '0';
		Dout_p               : out 		std_logic := '0';
		Dout_n               : out 		std_logic := '0';
		Sout_p               : out 		std_logic := '0';
		Sout_n               : out 		std_logic := '0'
	);
end spw_wrap_top_level_RTG4;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_wrap_top_level_RTG4 is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- returns std_logic value of boolean 
	function to_stdlog(bool : boolean) return std_logic;

	function to_stdlog(bool : boolean) return std_logic is
		variable std	: std_logic;
	begin
		if(bool = true) then
			std := '1';
		else
			std := '0';
		end if;
		return  '1';
	end function;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	component DDR_IN
	port(
		D		: in  std_logic;  
		CLK		: in  std_logic; 
		EN		: in  std_logic;
		ALn 	: in  std_logic;
		ADn 	: in  std_logic;
		SLn 	: in  std_logic;
		SD  	: in  std_logic;
		
		QR		: out std_logic;
		QF  	: out std_logic
	);
	end component;
	
	-- 3.3V LVCMOS IO Buffers (change as required) for single-ended
	component INBUF
	port(
		PAD 	: in 	std_logic;
		Y 	 	: out 	std_logic
	);
	end component;
	
	component OUTBUF
	port(
		D 		: in 	std_logic;
		PAD 	: out 	std_logic
	);
	end component;
	
	-- Differential IO Buffers (Differential Mode)
	component INBUF_DIFF
	port(
		PADP	: in 	std_logic;
		PADN	: in 	std_logic;
		Y 		: out 	std_logic
	);
	end component;
	
	component OUTBUF_DIFF
	port(
		D		: in  std_logic;
		PADP	: out std_logic;
		PADN	: out std_logic	
	);
	end component;
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal 	legacy                : boolean;
	
	signal 	din                   : std_logic := '0';
	signal 	sin                   : std_logic := '0';
	signal 	dout                  : std_logic := '0';
	signal 	sout                  : std_logic := '0';
	
	signal 	i_doutp               : std_logic := '0';
	signal 	i_doutn               : std_logic := '0';
	signal 	i_soutp               : std_logic := '0';
	signal 	i_soutn               : std_logic := '0';
	signal 	dout_b                : std_logic := '0';
	signal 	sout_b                : std_logic := '0';
	
	signal 	din_r                 : std_logic := '0';
	signal 	din_f                 : std_logic := '0';
	signal 	sin_r                 : std_logic := '0';
	signal 	sin_f                 : std_logic := '0';
	
	signal 	timetagged_timecode   : long;
	
	signal 	link_disable          : boolean;
	signal 	forced_link_fail      : boolean;
	
	signal  Rx_bits_int				: 	integer range 0 to 2 := 0;
	signal 	Rx_ESC_ESC_bool  		:	boolean;  
	signal 	Rx_ESC_EOP_bool         :	boolean;
	signal 	Rx_ESC_EEP_bool         :	boolean;
	signal 	Rx_Parity_error_bool    :	boolean;
	
	signal 	Rx_Time_OR_bool  	:	boolean;
	signal 	Tx_Time_IR_bool  	:	boolean;
	signal 	Connected_bool		:	boolean;
	
	signal 	Tx_IR_bool          : boolean;
	signal 	Rx_OR_bool          : boolean;
	
	signal 	n_reset				: std_logic := '1';
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
	u_spw: entity work.spw_RTG4
    generic map(
		CLOCK_FREQUENCY     => g_clock_frequency,
		RX_FIFO_SIZE        => g_rx_fifo_size,
		TX_FIFO_SIZE        => g_tx_fifo_size
    )
    port map(
		clock           	=> clock,
		reset           	=> reset,
		
		-- Control
		Disable         	=> link_disable,
		Legacy          	=> Legacy,
		Error_select    	=> Error_select,
		Error_inject    	=> to_bool(Error_inject),
		Force_timeout_error => false,       
		-- Status
		Out_Stalled     	=> open,
		Connected       	=> Connected_bool,
		
		-- SpW DS	Interface			  
		RxD_r           	=> din_r,
		RxD_f           	=> din_f,
		RxS_r           	=> sin_r,
		RxS_f           	=> sin_f,
		TxD             	=> dout,
		TxS             	=> sout,
		
		-- Received Data Out
		Rx_data         	=> Rx_data,
		Rx_Data_OR      	=> Rx_OR_bool,
		Rx_Data_IR      	=> to_bool(Rx_IR),
	
		Rx_ESC_ESC      	=> Rx_ESC_ESC_bool,      
		Rx_ESC_EOP      	=> Rx_ESC_EOP_bool,      
		Rx_ESC_EEP      	=> Rx_ESC_EEP_bool,      
		Rx_Parity_error 	=> Rx_Parity_error_bool, 
		Rx_bits         	=> Rx_bits_int,         
		Rx_rate         	=> Rx_rate,         

		-- Time            
		Rx_Time         	=> Rx_Time,         
		Rx_Time_OR      	=> Rx_Time_OR_bool,      
		Rx_Time_IR      	=> to_bool(Rx_Time_IR),     
	
		Tx_Time         	=> Tx_Time,         
		Tx_Time_OR      	=> to_bool(Tx_Time_OR),     
		Tx_Time_IR      	=> Tx_Time_IR_bool,     

		-- prescalar load interface
		Tx_PSC				=> Tx_PSC,			
        Tx_PSC_valid		=> Tx_PSC_valid,
		Tx_PSC_ready		=> Tx_PSC_ready,			
		
		-- Transmit Data In               
		Tx_data         	=> Tx_data,
		Tx_Data_OR      	=> to_bool(Tx_OR),
		Tx_Data_IR      	=> Tx_IR_bool
		
		
    );
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	-- to_std converts boolean signals to std_logic...
	Rx_ESC_ESC		<= to_std(Rx_ESC_ESC_bool);  	     
	Rx_ESC_EOP      <= to_std(Rx_ESC_EOP_bool);      
	Rx_ESC_EEP      <= to_std(Rx_ESC_EEP_bool);      
	Rx_Parity_error <= to_std(Rx_Parity_error_bool); 
	
	
	Rx_Time_OR	<= to_std( Rx_Time_OR_bool 	);
	Tx_Time_IR  <= to_std( Tx_Time_IR_bool 	);
	Connected   <= '1'; -- to_stdlog( Connected_bool	);
	
	Rx_OR <= to_std(Rx_OR_bool);
	Tx_IR <= to_stdlog(Tx_IR_bool);

	Rx_bits <= std_logic_vector(to_unsigned(Rx_bits_int, Rx_bits'length));

	link_disable <= to_bool(Disable) or forced_link_fail;
	-- Link Auto Start when True
	legacy            	<= False;
	n_reset 			<= not(reset);
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-- Technology specific instantiation for DE Signals 
	-------------------------------------------------------------------------------
	g_mode_select: if(g_mode = "diff") generate	-- generate for differential signaling 
	----------------------------------------------------------------------------------	
	-- Modify this section to use technology specific primitives 					-- 
	----------------------------------------------------------------------------------
		-- LVDS Input Buffers 
		u_Din_LVDS : INBUF_DIFF
		port map(
			PADP	=> Din_p	,
			PADN	=> Din_n	, 
			Y 		=> Din
		);
		
		u_Sin_LVDS : INBUF_DIFF
		port map(
			PADP	=> Sin_p	,
			PADN	=> Sin_n	, 
			Y 		=> Sin
		);
	
		-- RTG4 DDR input instantiations
		u_Din_iDDR: DDR_IN
		port map(
			D		=>  Din		,
			CLK		=> 	clock	,
			EN		=>	'1'		,
			ALn 	=>  '1'		,
			ADn 	=>	'1'		,
			SLn 	=>	n_reset ,
			SD  	=> 	'0'		,
			
			QR		=> 	din_r	,
			QF  	=> 	din_f
		);
		
		u_Sin_iDDR: DDR_IN
		port map(
			D		=>  Sin		,
			CLK		=> 	clock	,
			EN		=>	'1'		,
			ALn 	=>  '1'		,
			ADn 	=>	'1'		,
			SLn 	=>	n_reset ,
			SD  	=> 	'0'		,
			
			QR		=> 	sin_r	,
			QF  	=> 	sin_f
		);
		
		-- LVDS Output Buffers 
		u_Dout_LVDS : OUTBUF_DIFF
		port map(
			D 		=> Dout		,
			PADP 	=> Dout_p	,
			PADN 	=> Dout_n
		);
		
		u_Sout_LVDS : OUTBUF_DIFF
		port map(
			D 		=> Sout		,
			PADP 	=> Sout_p	,
			PADN 	=> Sout_n
		);

	elsif(g_mode = "single") generate	-- single-ended most 
	----------------------------------------------------------------------------------	
	-- Modify this section to use technology specific primitives 					-- 
	----------------------------------------------------------------------------------
		u_Din_buf: INBUF
		port map(
			PAD => Din_p,
			Y  	=> Din	
		);
		
		u_Sin_buf: INBUF
		port map(
			PAD => Sin_p,
			Y  	=> Sin	
		);
		
		u_Dout_buf: OUTBUF
		port map(
			D   => Dout,
			PAD => Dout_p
		);
		
		u_Sout_buf: OUTBUF
		port map(
			D   => Sout,
			PAD => Sout_p
		);
		
		-- RTG4 DDR input instantiations
		u_Din_iDDR: DDR_IN
		port map(
			D		=>  Din		,
			CLK		=> 	clock	,
			EN		=>	'1'		,
			ALn 	=>  '1'		,
			ADn 	=>	'1'		,
			SLn 	=>	n_reset ,
			SD  	=> 	'0'		,
			
			QR		=> 	din_r	,
			QF  	=> 	din_f
		);
		
		u_Sin_iDDR: DDR_IN
		port map(
			D		=>  Sin		,
			CLK		=> 	clock	,
			EN		=>	'1'		,
			ALn 	=>  '1'		,
			ADn 	=>	'1'		,
			SLn 	=>	n_reset ,
			SD  	=> 	'0'		,
			
			QR		=> 	sin_r	,
			QF  	=> 	sin_f
		);

	else generate		-- custom bypass for use with Block diagram DDR Primitives 
	-- use custom if you are including primitves outside of this architecture --
	-- do not modify this section --
		din_r		<= DDR_din_r;
		din_f   	<= DDR_din_f;
		sin_r   	<= DDR_sin_r;
		sin_f   	<= DDR_sin_f;
		SDR_Dout 	<= dout;
		SDR_Sout 	<= sout;

	end generate g_mode_select;
	
	-------------------------------------------------------------------------------
	-- Body of top level
	-------------------------------------------------------------------------------
	
	p_link_fail: process ( clock, reset )
    begin
		if (reset = '1') then
			forced_link_fail <= false;
		elsif rising_edge( clock ) then
			if Error_inject then
				case Error_select is
					when force_link_fail => 
						forced_link_fail <= true;
						
					when unforce_link_fail => 	
						forced_link_fail <= false;
						
					when others  => 
						null;
				end case;
			end if;
		end if;
    end process p_link_fail;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;