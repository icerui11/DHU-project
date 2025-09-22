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

-- @ Revision #				:	2

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

context work.rmap_context;



----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity rmap_target_full is
	generic(
		g_freq 			: real 		:= 125_000_000.0;
		g_fifo_depth 	: positive 	:= 16;
		g_mode			: string 	:= "single"
	);
	port( 
		
		clock              		: in    	std_logic 	:= '0';
		clock_b			   		: in 		std_logic 	:= '0';
		async_reset        		: in    	std_logic 	:= '0';
		reset              		: in    	std_logic 	:= '0';
		
		Rx_Time              	: out 		t_byte		:= (others => '0');
		Rx_Time_OR           	: out 		std_logic	:= '0';
		Rx_Time_IR           	: in    	std_logic	:= '0';
		
		Tx_Time              	: in    	t_byte		:= (others => '0');
		Tx_Time_OR           	: in    	std_logic	:= '0';
		Tx_Time_IR           	: out 		std_logic	:= '0';
		
		Rx_ESC_ESC           	: out 		std_logic 	:= '0';
		Rx_ESC_EOP           	: out 		std_logic 	:= '0';
		Rx_ESC_EEP           	: out 		std_logic 	:= '0';
		Rx_Parity_error      	: out 		std_logic 	:= '0';
		Rx_bits              	: out 		std_logic_vector(1 downto 0)	:= (others => '0');
		Rx_rate              	: out 		std_logic_vector(15 downto 0)	:= (others => '0');
		
		-- Control		
		Disable              	: in    	std_logic	:= '0';
		Connected            	: out 		std_logic	:= '0';
		Error_select         	: in    	std_logic_vector(3 downto 0)	:= (others => '0');
		Error_inject         	: in    	std_logic	:= '0';
		
		-- prescalar load interface
		Tx_PSC					: in 		t_byte := (others => '0');
        Tx_PSC_valid			: in 		std_logic := '0';
		Tx_PSC_ready			: out 		std_logic := '0';
		
		-- DDR/SDR IO, only when "custom" mode is used
		-- when instantiating, if not used, you can ignore these ports. 
		DDR_din_r				: in 		std_logic := '0';
		DDR_din_f           	: in 		std_logic := '0';
		DDR_sin_r           	: in 		std_logic := '0';
		DDR_sin_f           	: in 		std_logic := '0';
		SDR_Dout				: out 		std_logic := '0';
		SDR_Sout				: out 		std_logic := '0';
	
		-- SpW	
		Din_p                	: in    	std_logic := '0';
		Din_n                	: in    	std_logic := '0';
		Sin_p                	: in    	std_logic := '0';
		Sin_n                	: in    	std_logic := '0';
		Dout_p               	: out 		std_logic := '0';
		Dout_n               	: out 		std_logic := '0';
		Sout_p               	: out 		std_logic := '0';
		Sout_n               	: out 		std_logic := '0';

		-- Memory Interface
		Address            		: out 		std_logic_vector(39 downto 0):= (others => '0');
		wr_en              		: out 		std_logic := '0';
		Write_data         		: out 		std_logic_vector( 7 downto 0):= (others => '0');
		Bytes              		: out 		std_logic_vector(23 downto 0):= (others => '0');
		Read_data          		: in    	std_logic_vector( 7 downto 0):= (others => '0');
		Read_bytes         		: in    	std_logic_vector(23 downto 0):= (others => '0');
		
		-- Bus handshake		
		RW_request         		: out 		std_logic 	:= '0';
		RW_acknowledge     		: in    	std_logic 	:= '0';
		
		-- Control/Status 		
		Echo_required      		: in   	 	std_logic 	:= '0';
		Echo_port          		: in    	t_byte 		:= (others => '0');
		
		Logical_address    		: out 		std_logic_vector(7 downto 0)	:= (others => '0');
		Key                		: out 		std_logic_vector(7 downto 0)	:= (others => '0');
		Static_address     		: out 		std_logic	:= '0';
		
		Checksum_fail      		: out 		std_logic	:= '0';
				
		Request            		: out 		std_logic	:= '0';
		Reject_target      		: in    	std_logic	:= '0';
		Reject_key         		: in    	std_logic	:= '0';
		Reject_request     		: in    	std_logic	:= '0';
		Accept_request     		: in    	std_logic	:= '0';
		
		Verify_overrun     		: in    	std_logic	:= '0';
		
		OK                 		: out 		std_logic	:= '0';
		Done               		: out 		std_logic	:= '0'
		
    );
end rmap_target_full;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of rmap_target_full is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
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
	-- Data Flow Link input, Requests
	signal	In_data            	: 	t_nonet;
	signal	In_ir              	: 	boolean;
	signal	In_or              	: 	std_logic;
	
	-- Data Flow Link output, Response
	signal	Out_data           	:	t_nonet;
	signal	Out_IR             	:  	std_logic;
	signal	Out_OR             	:  	boolean;
	
	signal 	wr_bool 			: 	boolean;
	signal 	RW_request_bool		: 	boolean;
	signal 	Static_address_bool : 	boolean;
	signal 	Checksum_fail_bool 	: 	boolean;
	signal 	Request_bool 		: 	boolean;
	signal 	OK_bool				: 	boolean;
	signal 	Done_bool			: 	boolean;
	signal  Address_u			: 	unsigned(39 downto 0);
	signal 	Bytes_u				: 	unsigned(23 downto 0);
	signal 	Logical_address_u	: 	unsigned(7 downto 0);
	
	signal  Rx_bits_int			: 	integer range 0 to 2 := 0;
	signal 	Rx_ESC_ESC_bool  		:	boolean;  
	signal 	Rx_ESC_EOP_bool         :	boolean;
	signal 	Rx_ESC_EEP_bool         :	boolean;
	signal 	Rx_Parity_error_bool    :	boolean;
	
	signal 	Rx_Time_OR_bool  	:	boolean;
	signal 	Tx_Time_IR_bool  	:	boolean;
	signal 	Connected_bool		:	boolean;
	
	
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

	wr_en <= to_std(wr_bool);
	RW_request <= to_std(RW_request_bool);
	Static_address <= to_std(Static_address_bool);
	Checksum_fail <= to_std(Checksum_fail_bool);
	Request <= to_std(Request_bool);
	OK <= to_std(OK_bool);
	Done <= to_std(Done_bool);
--	Rx_bits <= std_logic_vector(to_unsigned(Rx_bits_int, Rx_bits'length)); 
	
	Address <= std_logic_vector(Address_u);
	Bytes <= std_logic_vector(Bytes_u);
	Logical_address <= std_logic_vector(Logical_address_u);
	
	

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	u_rmap_target_inst: entity work.rmap_target
	port map( 
		clock              	=> clock,
		async_reset        	=> to_bool(async_reset),
		reset              	=> to_bool(reset),

		-- Data Flow Link input, Requests
		In_data            	=> 	In_data, 	 
		In_ir              	=> 	In_ir,  	 
		In_or              	=>	to_bool(In_or),     
		
		-- Data Flow Link output, Response
		Out_data           	=> Out_data,
		Out_IR             	=> to_bool(Out_IR),  
		Out_OR             	=> Out_OR, 
		
		-- Memory Interface
		Address            	=> Address_u,      
		wr_en      		   	=> wr_bool,         
		Write_data         	=> Write_data,   
		Bytes              	=> Bytes_u,        
		Read_data          	=> Read_data,   
		Read_bytes         	=> unsigned(Read_bytes), 

		-- Bus handshake
		RW_request	 		=>  RW_request_bool,    
		RW_acknowledge     	=>  to_bool(RW_acknowledge),

		-- Control/Status 
		Echo_required      	=> to_bool(Echo_required), 
		Echo_port          	=> Echo_port,     

		Logical_address    	=> Logical_address_u, 
		Key                	=> Key,             
		Static_address      => Static_address_bool,

		Checksum_fail     	=> Checksum_fail_bool,   
		
		Request            	=> Request_bool,       
		Reject_target      	=> to_bool(Reject_target), 
		Reject_key         	=> to_bool(Reject_key),    
		Reject_request     	=> to_bool(Reject_request),
		Accept_request     	=> to_bool(Accept_request),
    
		Verify_overrun     	=> to_bool(Verify_overrun),

		OK                 	=> OK_bool,            
		Done               	=> Done_bool          
    );
	
	-- copy into design entity architecture -- 
	u_spw_inst: entity work.spw_wrap_top_level_RTG4
	generic map(
		g_clock_frequency   =>	g_freq,
		g_rx_fifo_size      =>  g_fifo_depth,      
		g_tx_fifo_size      =>  g_fifo_depth,      
		g_mode				=>  g_mode				
	)
	port map( 
		-- clock & reset signals
		clock               =>	clock,					           
	--	clock_b             =>  clock_b,        
		reset               =>  reset, 
		
		-- Data Channels          
		Tx_data             =>  Out_data,         
		Tx_OR               =>  to_std(Out_OR),           
		Tx_IR               =>  Out_IR,           
      
		Rx_data             =>  In_data,         
		Rx_OR               =>  In_or,           
		Rx_IR               =>  to_std(In_IR),           
		
		-- Error Channels 
		Rx_ESC_ESC          =>  Rx_ESC_ESC,      
		Rx_ESC_EOP          =>  Rx_ESC_EOP,      
		Rx_ESC_EEP          =>  Rx_ESC_EEP,      
		Rx_Parity_error     =>  Rx_Parity_error,
		Rx_bits             =>  Rx_bits,         
		Rx_rate             =>  Rx_rate,         
   
		-- Time Code Channels
		Rx_Time             =>  Rx_Time,         
		Rx_Time_OR          =>  Rx_Time_OR,      
		Rx_Time_IR          =>  Rx_Time_IR,      
 
		Tx_Time             =>  Tx_Time,         
		Tx_Time_OR          =>  Tx_Time_OR,      
		Tx_Time_IR          =>  Tx_Time_IR,      
    
		-- Control Channels           	
		Disable             =>  Disable,         
		Connected           =>  Connected,       
		Error_select        =>  Error_select,    
		Error_inject        =>  Error_inject,    
		
		-- prescalar load interface
		Tx_PSC			=> Tx_PSC,			
        Tx_PSC_valid	=> Tx_PSC_valid,
		Tx_PSC_ready	=> Tx_PSC_ready,
		
		-- DDR/SDR IO, only when "custom" mode is used
		-- when instantiating, if not used, you can ignore these ports. 
		DDR_din_r			=>	DDR_din_r,		-- Data in Rising Edge Input	
		DDR_din_f           =>  DDR_din_f, 		-- Data in Falling Edge Input  
		DDR_sin_r           =>  DDR_sin_r,   	-- Strobe in Rising Edge Input	
		DDR_sin_f           =>  DDR_sin_f,      -- Strobe in Falling Edge Input 
		SDR_Dout			=>  SDR_Dout,		-- Data Output (rising edge of Clock)
		SDR_Sout			=>  SDR_Sout,		-- Strobe output (rising edge of Clock)

		-- SpW IO Ports, not used when "custom" mode.  	                
		Din_p               =>  Din_p,  	-- Used when Diff & Single     
		Din_n               =>  Din_n,      -- Used when Diff only
		Sin_p               =>  Sin_p,  	-- Used when Diff & Single       
		Sin_n               =>  Sin_n,      -- Used when Diff only
		Dout_p              =>  Dout_p,		-- Used when Diff & Single      
		Dout_n              =>  Dout_n,     -- Used when Diff only
		Sout_p              =>  Sout_p,  	-- Used when Diff & Single      
		Sout_n              =>  Sout_n     	-- Used when Diff only
	);

	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------



end rtl;