----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	rmap_initiator_lib.vhd
-- @ Engineer				: 	James E Logan
-- @ Role					:	FPGA & Electronics Engineer
-- @ Company				:	4Links 

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE/Intel Quartus 18.1+
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	Standard work library containing useful functions, data types, constants and simulation
--								constructs for RTL & Testbenching. 

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;


library std;					-- should coimpile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library spw;
use spw.spw_data_types.all;
use spw.spw_codes.all;


package rmap_initiator_lib is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------

	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------
  
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------

	type tx_initiator is( 	
		init, 
		ready, 
		get_header_byte, 
		check_header_byte,
		send_header_byte,
		abort_frame,
		get_header_crc,
		send_header_crc,
		add_eop, 
		get_data, 
		send_data,
		send_data_crc,
		error_handle
	);
	
	type rx_initiator is (
		idle, 				-- default state, returns to on reset asserted  
		read_byte,			-- read valid byte from SpW IP
		get_header,			-- get header infor for the SpW Reply
		post_header,		-- post header to controller interface
		get_header_crc,
		rx_abort, 			-- EEP detected ? Discard received data in frame
		discard,
		status_error,
		get_data,			-- get reply data (if any)
		post_data,			-- post rx data to IP interface 
		data_crc,
		get_EOP				-- receive EOP, check for correct termination
	);
	
	
	--subtype t_byte 		is std_logic_vector(7 downto 0);
	--subtype t_nibble 	is std_logic_vector(3 downto 0);
	--subtype t_nonet		is std_logic_vector(8 downto 0);
	--
	--type t_byte_array	is array (natural range <>) of t_byte;
	--type t_nonet_array 	is array (natural range <>) of t_nonet;
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	--------------------------------------------------------------------------------------------------------------------------

	-- SpW Control Character Codes for nonets -- 
	constant c_spw_EOP					: t_nonet := "100000010";
	constant c_spw_EEP					: t_nonet := "100000001";
	
	-- SpW RMAP Error Codes
	-- Tx Errors
	constant c_cmd_early_eop_eep		: t_byte := x"13";
	
	
	-- Rx Errors
	
	constant c_reply_status_error		: t_byte := x"01";
	constant c_reply_crc_error			: t_byte := x"02";
	constant c_early_eop_eep			: t_byte := x"03";

	--------------------------------------------------------------------------------------------------------------------------
	--	Interface Record Declerations 																						--
	--------------------------------------------------------------------------------------------------------------------------
	-- record instantiations for data handshakes module channels --
	-- for VHDL 2008 we cannot used "VIEW" therefore must split Input and Output Signals. 
	-- bad practice to declare inout as this could cause extra logic to be instantiated
	-- and prevent proper directional checking of netlist signals 
	
	
	type r_saxi_rd is record		-- axi slave read signals (input to Master)
		rdata	: t_byte;
		rvalid	: std_logic;
	end record r_saxi_rd;
	
	type r_maxi_rd is record		-- axi master read signals (output from master)
		rready	: std_logic;
	end record r_maxi_rd;
	
	type r_maxi_wr is record		-- axi master write signals (output from master)
		wdata	: t_byte;
		wvalid	: std_logic;
	end record r_maxi_wr;
	
	type r_saxi_wr is record		-- axi slave write signals (input to Master)
		wready	: std_logic;
	end record r_saxi_wr;
	
	type r_saxi_rd_nonet is record		-- axi slave read signals (input to Master)
		rdata	: t_nonet;
		rvalid	: std_logic;
	end record r_saxi_rd_nonet;
	
	type r_maxi_rd_nonet is record		-- axi master read signals (output from master)
		rready	: std_logic;
	end record r_maxi_rd_nonet;
	
	type r_maxi_wr_nonet is record		-- axi master write signals (output from master)
		wdata	: t_nonet;
		wvalid	: std_logic;
	end record r_maxi_wr_nonet;
	
	type r_saxi_wr_nonet is record		-- axi slave write signals (input to Master)
		wready	: std_logic;
	end record r_saxi_wr_nonet;
	
	-- full module interface records should be declared below here --
	--------------------------------------------------------------------------------------
	-- Tx Command Controller IO Records 												--
	--------------------------------------------------------------------------------------	
	-- inputs from user logic
	type r_cmd_controller_logic_in is record
	
		tx_header		: 	r_maxi_wr_nonet;	
		tx_data			:  	r_maxi_wr_nonet;	
		tx_error		:  	r_maxi_rd;
		assert_target   : 	std_logic;						-- assert to force path address (if using path address values >31)
		link_idle		:  	std_logic;						-- asserted when link is ready for new command
		
	end record r_cmd_controller_logic_in;
	
	-- outputs to user logic
	type r_cmd_controller_logic_out is record
	
		tx_header		:  	r_saxi_wr_nonet;
		tx_data   		:  	r_saxi_wr_nonet;
		tx_error		:   r_saxi_rd;
		tx_link_active	:  	std_logic;						-- asserted when a tx command is being executed.
		
	end record r_cmd_controller_logic_out;
	
	-- inputs from SpW IP
	type r_cmd_controller_spw_in is record 
	
		link_connected	:  	std_logic;						-- asserted when SpW CoDec is connected 
		spw_tx			:  	r_saxi_wr_nonet;
		
	end record r_cmd_controller_spw_in;
	
	-- outputs to SpW IP
	type r_cmd_controller_spw_out is record 
	
		spw_tx			:  	r_maxi_wr_nonet;
		
	end record r_cmd_controller_spw_out;
	
	--------------------------------------------------------------------------------------
	-- Rx Reply Controller IO Records 													--
	--------------------------------------------------------------------------------------	
	-- Inputs from user logic
	type r_reply_controller_logic_in is record 
	
		rx_header			:	r_maxi_rd_nonet;
		rx_data				: 	r_maxi_rd_nonet;
		rx_error			:	r_maxi_rd;
		link_idle			:  	std_logic;						-- asserted when link is ready for new command
		
	end record r_reply_controller_logic_in;

	-- outputs to user logic 
	type r_reply_controller_logic_out is record 
	
		rx_header			: 	r_saxi_rd_nonet;
		rx_data				: 	r_saxi_rd_nonet;
		rx_error			: 	r_saxi_rd;
		rx_link_active		:	std_logic;						-- asserted when a tx command is being executed. 
		crc_error			:  	std_logic;						-- asserted when CRC error is detected 
		
	end record r_reply_controller_logic_out;
	
	-- inputs from SpW IP
	type r_reply_controller_spw_in is record 
		link_connected		:  	std_logic;						-- asserted when SpW CoDec is connected 
		spw_rx				: 	r_saxi_rd_nonet;
	end record r_reply_controller_spw_in;
	

	-- outputs to SpW IP
	type r_reply_controller_spw_out is record 
	
		spw_rx 				: r_maxi_rd_nonet;
		
	end record r_reply_controller_spw_out;
	
	type r_rmap_init_interface is record
		tx_assert_path		: std_logic;
		tx_assert_char      : std_logic;
		tx_header			: t_byte;
		tx_header_valid		: std_logic;
		tx_header_ready		: std_logic;
		rx_assert_char		: std_logic;
		rx_header			: t_byte;
		rx_header_valid 	: std_logic;
		rx_header_ready		: std_logic;
		tx_data				: t_byte;
		tx_data_valid		: std_logic;
		tx_data_ready 		: std_logic;
		rx_data				: t_byte;
		rx_data_valid		: std_logic;
		rx_data_ready		: std_logic;
		tx_time 			: t_byte;
		tx_time_valid		: std_logic;
		tx_time_ready		: std_logic;
		rx_time				: t_byte;
		rx_time_valid		: std_logic;
		rx_time_ready		: std_logic;
		tx_error			: t_byte;
		tx_error_valid		: std_logic;
		tx_error_ready		: std_logic;
		rx_error			: t_byte;
		rx_error_valid		: std_logic;
		rx_error_ready  	: std_logic;
		spw_Rx_ESC_ESC      : std_logic;                                 
		spw_Rx_ESC_EOP      : std_logic;                                 
		spw_Rx_ESC_EEP      : std_logic;                                 
		spw_Rx_Parity_error : std_logic;                                 
		spw_Rx_bits         : std_logic_vector(1 downto 0);	
		spw_Rx_rate         : std_logic_vector(15 downto 0); 
		spw_Disable     	: std_logic;                                 
		spw_Connected       : std_logic;                                 
		spw_Error_select    : std_logic_vector(3 downto 0);  
		spw_Error_inject    : std_logic;                                 
		
	end record r_rmap_init_interface;
	
	type r_rmap_target_interface is record
		Rx_Time              	: 	t_byte;
		Rx_Time_OR           	: 	std_logic;
		Rx_Time_IR           	:  	std_logic;
		
		Tx_Time              	:  	t_byte;
		Tx_Time_OR           	:  	std_logic;
		Tx_Time_IR           	: 	std_logic;
		
		Rx_ESC_ESC           	: 	std_logic;
		Rx_ESC_EOP           	: 	std_logic;
		Rx_ESC_EEP           	: 	std_logic;
		Rx_Parity_error      	: 	std_logic;
		Rx_bits              	: 	std_logic_vector(1 downto 0);
		Rx_rate              	: 	std_logic_vector(15 downto 0);
		
		-- Control		
		Disable              	:  	std_logic;
		Connected            	: 	std_logic;
		Error_select         	:  	std_logic_vector(3 downto 0);
		Error_inject         	:  	std_logic;
		
		-- Memory Interface
		Address           	 	:  std_logic_vector(39 downto 0);
		wr_en             	 	:  std_logic;
		Write_data        	 	:  std_logic_vector(7 downto 0);
		Bytes             	 	:  std_logic_vector(23 downto 0);
		Read_data         	 	:  std_logic_vector(7 downto 0);
		Read_bytes        	 	:  std_logic_vector(23 downto 0);
		
		-- Bus handshake
		RW_request         		:  std_logic;
		RW_acknowledge     		:  std_logic;
		
		-- Control/Status 
		Echo_required      		:  std_logic;
		Echo_port          		:  t_byte;
		
		Logical_address    		:  std_logic_vector(7 downto 0);
		Key                		:  std_logic_vector(7 downto 0);
		Static_address     		:  std_logic;
		
		Checksum_fail      		:  std_logic;
		
		Request            		:  std_logic;
		Reject_target      		:  std_logic;
		Reject_key         		:  std_logic;
		Reject_request     		:  std_logic;
		Accept_request     		:  std_logic;
		
		Verify_overrun     		:  std_logic;

		OK                 		:  std_logic;
		Done               		:  std_logic;
	end record r_rmap_target_interface;
	
	type r_rmap_init_interface_array is array (natural range <>) of r_rmap_init_interface;
	type r_rmap_target_interface_array is array (natural range <>) of r_rmap_target_interface;
	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	-- base init constants 
	
	
	constant c_saxi_rd_init : r_saxi_rd :=(
		rdata	=> (others => '0'),
		rvalid	=> '0'
	);
	
	constant c_maxi_rd_init : r_maxi_rd :=(
		rready => '0'
	);
	
	constant c_maxi_wr_init : r_maxi_wr :=(
		wdata 	=> (others => '0'),
		wvalid	 => '0'
	);	
	
	constant c_saxi_wr_init : r_saxi_wr :=(
		wready => '0'
	);
	
	constant c_saxi_rd_nonet_init : r_saxi_rd_nonet :=(
		rdata	=> (others => '0'),
		rvalid	=> '0'
	);
	
	constant c_maxi_rd_nonet_init : r_maxi_rd_nonet :=(
		rready => '0'
	);
	
	constant c_maxi_wr_nonet_init : r_maxi_wr_nonet :=(
		wdata  => (others => '0'),
		wvalid => '0'
	);	
	
	constant c_saxi_wr_nonet_init : r_saxi_wr_nonet :=(
		wready => '0'
	);
	
	
	-- cmd controller IO init constants 
	constant c_cmd_logic_in_init : r_cmd_controller_logic_in :=(
		tx_header 		=> c_maxi_wr_nonet_init,
		tx_data  		=> c_maxi_wr_nonet_init,
		tx_error 		=> c_maxi_rd_init,
		assert_target	=> '0',
		link_idle 		=> '0'
	);
	
	constant c_cmd_logic_out_init : r_cmd_controller_logic_out :=(
		tx_header		=> c_saxi_wr_nonet_init,
		tx_data			=> c_saxi_wr_nonet_init,
		tx_error    	=> c_saxi_rd_init,
		tx_link_active 	=> '0'
	);
	
	constant c_cmd_spw_in_init : r_cmd_controller_spw_in :=(
		link_connected	=> '0',				
		spw_tx			=> c_saxi_wr_nonet_init
	);
	
	constant c_cmd_spw_out_init : r_cmd_controller_spw_out :=(
		spw_tx			=> c_maxi_wr_nonet_init
	);
	
	-- reply controller IO init constants 
	constant c_reply_logic_in_init : r_reply_controller_logic_in :=(
		rx_header 	=> c_maxi_rd_nonet_init,
		rx_data		=> c_maxi_rd_nonet_init,
		rx_error	=> c_maxi_rd_init,
		link_idle   => '0'
	);
	
	constant c_reply_logic_out_init : r_reply_controller_logic_out :=(
		rx_header			=> 	c_saxi_rd_nonet_init,
		rx_data				=> 	c_saxi_rd_nonet_init,
		rx_error			=> 	c_saxi_rd_init,
		rx_link_active		=>	'0',					
		crc_error			=>  '0'					
	);
	
	constant c_reply_spw_in_init : r_reply_controller_spw_in :=(
		link_connected		=>  '0',						
		spw_rx				=> 	c_saxi_rd_nonet_init
	);
	
	constant c_reply_spw_out_init : r_reply_controller_spw_out :=(
		spw_rx 				=> c_maxi_rd_nonet_init
	);
	
	constant c_rmap_init_interface : r_rmap_init_interface :=(
		tx_assert_path		=>  '0',
		tx_assert_char		=>  '0',
		tx_header			=>	(others => '0'),
	    tx_header_valid		=>  '0',
	    tx_header_ready		=>  '0',
		rx_assert_char		=>  '0',
	    rx_header			=>	(others => '0'),
	    rx_header_valid 	=>  '0',
	    rx_header_ready		=>  '0',
		tx_data				=> 	(others => '0'),
		tx_data_valid		=>	'0',
		tx_data_ready 		=>	'0',
		rx_data				=>	(others => '0'),
		rx_data_valid		=>	'0',
		rx_data_ready		=>	'0',
		tx_time 			=>	(others => '0'),
		tx_time_valid		=>	'0',
		tx_time_ready		=>	'0',
		rx_time				=>	(others => '0'),
		rx_time_valid		=>	'0',
		rx_time_ready		=>	'0',
		tx_error			=>	(others => '0'),	
		tx_error_valid		=>	'0',	
		tx_error_ready		=>	'0',	
		rx_error			=>	(others => '0'),	
		rx_error_valid		=>	'0',	
		rx_error_ready  	=>	'0',
		spw_Rx_ESC_ESC      =>	'0',
		spw_Rx_ESC_EOP      =>  '0',
		spw_Rx_ESC_EEP      =>  '0',
		spw_Rx_Parity_error =>  '0',
		spw_Rx_bits         =>	(others => '0'),
		spw_Rx_rate         =>	(others => '0'),
		spw_Disable     	=>	'0',
		spw_Connected       =>	'0',
		spw_Error_select    =>	(others => '0'),
		spw_Error_inject    =>	'0'
	
	);
	
	constant c_rmap_target_interface : r_rmap_target_interface :=(
		Rx_Time              	=> 	(others => '0'),
		Rx_Time_OR           	=>	'0',
		Rx_Time_IR           	=> 	'0',
		Tx_Time              	=> 	(others => '0'),
		Tx_Time_OR           	=>	'0',
		Tx_Time_IR           	=>	'0',
		Rx_ESC_ESC           	=>	'0',
		Rx_ESC_EOP           	=>	'0',
		Rx_ESC_EEP           	=>	'0',
		Rx_Parity_error      	=>	'0',
		Rx_bits              	=> 	(others => '0'),
		Rx_rate              	=> 	(others => '0'),
		Disable              	=> 	'0',
		Connected            	=> 	'0',
		Error_select         	=> 	(others => '0'),
		Error_inject         	=> 	'0',
		Address           	 	=> 	(others => '0'),
		wr_en             	 	=> 	'0',
		Write_data        	 	=> 	(others => '0'),
		Bytes             	 	=> 	(others => '0'),
		Read_data         	 	=> 	(others => '0'),
		Read_bytes        	 	=> 	(others => '0'),
		RW_request         		=> 	'0',
		RW_acknowledge     		=> 	'0',
		Echo_required      		=> 	'0',
		Echo_port          		=> 	(others => '0'),
		Logical_address    		=> 	(others => '0'),
		Key                		=> 	(others => '0'),
		Static_address     		=> 	'0',
		Checksum_fail      		=> 	'0',
		Request            		=> 	'0',
		Reject_target      		=> 	'0',
		Reject_key         		=> 	'0',
		Reject_request     		=> 	'0',
		Accept_request     		=> 	'0',
		Verify_overrun     		=> 	'0',
		OK                 		=> 	'0',
		Done               		=> 	'0'
	);
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- use these to convert between 4Links boolean ports and std_logic I/O as required.
	-- returns boolean value of std_logic
	function to_bool(std : std_logic) return boolean;
	
	-- returns std_logic value of boolean 
	function to_std(bool : boolean) return std_logic;

	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------

	
end package rmap_initiator_lib;

package body rmap_initiator_lib is 

	--------------------------------------------------------------------------------------------------------------------------
	--	Simulation Protected Type Bodies																					--
	--------------------------------------------------------------------------------------------------------------------------
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	-- returns boolean value of std_logic
	function to_bool(std : std_logic) return boolean is
		variable bool : boolean;
	begin
		if(std = '1' or std = 'H') then	-- assume weak-high as true... 
			bool := true;
		else							-- anything else false
			bool := false;
		end if;
		return bool;
	end function;
	
	-- returns std_logic value of boolean 
	function to_std(bool : boolean) return std_logic is
		variable std	: std_logic;
	begin
		if(bool = true) then
			std := '1';
		else
			std := '0';
		end if;
		return std;
	end function;
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	

end package body rmap_initiator_lib;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------