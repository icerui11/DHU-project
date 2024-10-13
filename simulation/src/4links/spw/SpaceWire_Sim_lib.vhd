----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	SpaceWire_Sim_lib.vhd
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

package SpaceWire_Sim_lib is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------
	
	-- SpaceWire Control Characters -- 
	constant c_SpW_FCT_code		: 	std_logic_vector(2 downto 0) := "001";	-- note documentation usually shows LSB -> MSB bit arrangement. Parity excluded
	constant c_SpW_EOP_code		: 	std_logic_vector(2 downto 0) := "101";
	constant c_SpW_EEP_code		: 	std_logic_vector(2 downto 0) := "011";
	constant c_SpW_ESC_code		: 	std_logic_vector(2 downto 0) := "111";
	
	-- SpaceWire Simulation Debug Output Codes	--
	constant c_SpW_Sim_FCT		: 	string(1 to 3) := "FCT";
	constant c_SpW_Sim_EOP		: 	string(1 to 3) := "EOP";
	constant c_SpW_Sim_EEP		: 	string(1 to 3) := "EEP";
	constant c_SpW_Sim_ESC		: 	string(1 to 3) := "ESC";
	constant c_SpW_Sim_DAT		: 	string(1 to 3) := "DAT";
	constant c_SpW_Sim_TIM		: 	string(1 to 3) := "TIM";
	
	constant c_mem_width		: natural := 8;
	constant c_mem_addr_width	: natural := 13;
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	-- record of signals for SpW Debugger 
	type r_spw_debug_signals is record
		raw  		: std_logic_vector(13 downto 0);
		data 		: std_logic_vector(8 downto 0);
		time_code	: std_logic_vector(7 downto 0);
		char		: string(1 to 3);
		parity		: std_logic;
	end record r_spw_debug_signals;
    

	type r_spw_debug_signals_array is array (natural range <>) of r_spw_debug_signals;
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------

	
--	subtype t_byte 		is std_logic_vector(7 downto 0);
--	subtype t_nibble 	is std_logic_vector(3 downto 0);
--	subtype t_nonet		is std_logic_vector(8 downto 0);
	
	subtype mem_element is std_logic_vector(c_mem_width-1 downto 0);				-- declare size of each memory element in RAM
	type t_ram is array (0 to (2**c_mem_addr_width)-1) of mem_element;						-- declare RAM as array of memory element
	
--	type t_byte_array	is array (natural range <>) of t_byte;
--	type t_nonet_array 	is array (natural range <>) of t_nonet;
	
	
	constant c_path_addr_1	: t_byte_array(0 to 0) :=(
		0 => x"09"
	--	1 => x"22",
	--	2 => x"33",	 
	--	3 => x"44",
	--	4 => x"55",
	--	5 => x"66",
	--	6 => x"77"
	);
	
	
	
	constant c_router_header_pattern_1	: t_byte_array(0 to 15) :=(
		0	=> x"00",	-- path address
		1 	=> x"FE",	-- target logical address
		2 	=> x"01",	-- protocol ID
		3 	=> b"0110_0100",	-- Instruction
		4 	=> x"01",	-- key
		5 	=> x"33",  	-- initiaitor logical address
		6 	=> x"00",	-- transaction ID MSB
		7 	=> x"00",	-- transaction ID LSB
		8 	=> x"00",	-- extended address
		9 	=> x"00",	-- address MSB(3)
		10	=> x"00",	-- address(2)
		11 	=> x"00",	-- address(1)
		12	=> x"CC",	-- address LSB (0)
		13  => x"00",	-- data length MSB(2)
		14  => x"00",	-- data length (1)
		15  => x"04"	-- data length LSB(0)
	);
	
	constant c_router_header_pattern_2	: t_byte_array(0 to 14) :=(
		0 	=> x"33",	-- target logical address
		1 	=> x"01",	-- protocol ID
		2 	=> x"6C",	-- Instruction
		3 	=> x"00",	-- key
		4 	=> x"89",  	-- initiaitor logical address
		5 	=> x"00",	-- transaction ID MSB
		6 	=> x"00",	-- transaction ID LSB
		7 	=> x"00",	-- extended address
		8 	=> x"00",	-- address MSB(3)
		9 	=> x"00",	-- address(2)
		10 	=> x"00",	-- address(1)
		11	=> x"A5",	-- address LSB (0)
		12  => x"00",	-- data length MSB(2)
		13  => x"00",	-- data length (1)
		14  => x"10"	-- data length LSB(0)
	);
	
	constant c_router_header_pattern_3	: t_byte_array(0 to 15) :=(
		0	=> x"00",	-- path address
		1 	=> x"FE",	-- target logical address
		2 	=> x"01",	-- protocol ID
		3 	=> b"0100_1100",	-- Instruction
		4 	=> x"01",	-- key
		5 	=> x"05",  	-- initiaitor logical address
		6 	=> x"00",	-- transaction ID MSB
		7 	=> x"00",	-- transaction ID LSB
		8 	=> x"00",	-- extended address
		9 	=> x"00",	-- address MSB(3)
		10	=> x"00",	-- address(2)
		11 	=> x"00",	-- address(1)
		12	=> x"CC",	-- address LSB (0)
		13  => x"00",	-- data length MSB(2)
		14  => x"00",	-- data length (1)
		15  => x"04"	-- data length LSB(0)
	);
	
	
	constant c_router_data_pattern_1	: t_byte_array(0 to 3) :=(
		0 	=> b"0000_0000",	-- LSB
		1 	=> b"0100_0000",	
		2 	=> b"0010_0000",	
		3 	=> b"0000_0000"	-- MSB
	);
	
	constant c_header_test_pattern_1	: 	t_byte_array(0 to 14) 	:=(	
		0 	=> x"FE",	-- target logical address
		1 	=> x"01",	-- protocol ID
		2 	=> x"6C",	-- Instruction
		3 	=> x"00",	-- key
		4 	=> x"67",  	-- initiaitor logical address
		5 	=> x"00",	-- transaction ID MSB
		6 	=> x"00",	-- transaction ID LSB
		7 	=> x"00",	-- extended address
		8 	=> x"A0",	-- address MSB(3)
		9 	=> x"00",	-- address(2)
		10 	=> x"00",	-- address(1)
		11	=> x"00",	-- address LSB (0)
		12  => x"00",	-- data length MSB(2)
		13  => x"00",	-- data length (1)
		14  => x"10"	-- data length LSB(0)
	);
	constant c_header_test_pattern_1_crc : t_byte := x"9F";
	
	
	-- header crc should be 0x9F (inserted automatically)

	constant c_data_test_pattern_1	: 	t_byte_array(0 to 15) :=( 
		0 	=> x"01",	
		1 	=> x"23",	
		2 	=> x"45",	
		3 	=> x"67",	
		4 	=> x"89",  	
		5 	=> x"AB",	
		6 	=> x"CD",	
		7 	=> x"EF",	
		8 	=> x"10",	
		9 	=> x"11",	
		10 	=> x"12",	
		11	=> x"13",	
		12  => x"14",	
		13  => x"15",	
		14  => x"16",	
		15  => x"17"
	);
	
	constant c_data_test_pattern_1_crc : t_byte := x"56";
	
	constant c_header_test_pattern_2 : t_byte_array(0 to 14) := (
		0 	=> x"FE",	-- target logical address
		1 	=> x"01",   -- protocol ID
		2 	=> x"4C",   -- Instruction
		3 	=> x"00",   -- key
	    4 	=> x"67",   -- initiaitor logical address
	    5 	=> x"00",   -- transaction ID MSB
	    6 	=> x"01",   -- transaction ID LSB
	    7 	=> x"00",   -- extended address
	    8 	=> x"A0",   -- address MSB(3)
	    9 	=> x"00",   -- address(2)
	    10 	=> x"00",   -- address(1)
	    11	=> x"00",   -- address LSB (0)
	    12  => x"00",   -- data length MSB(2)
	    13  => x"00",   -- data length (1)
	    14  => x"10"    -- data length LSB(0)
	);
	
	constant c_data_test_pattern_2	: t_byte_array(0 to 14) := (
		0 to 13 => x"00",
		14 => x"11"
	);
	
	constant c_header_test_pattern_3 : t_byte_array(0 to 18) :=(
		0 	=>	x"FE",	-- target logical address
		1 	=>	x"01",  -- protocol ID
		2 	=>	x"4D",  -- Instruction
		3 	=>	x"00",  -- key
		4 	=>	x"99",	-- reply addr 1
		5 	=>	x"AA",	-- reply addr 2
		6 	=>	x"BB",	-- reply addr 3
		7 	=>	x"CC",	-- reply addr 4 
		8 	=>	x"67",	-- initiaitor logical address
		9 	=>	x"00",  -- transaction ID MSB
		10	=>	x"03",  -- transaction ID LSB
		11	=>	x"00",  -- extended address
		12	=>	x"A0",  -- address MSB(3)
		13	=>	x"00",  -- address(2)
		14	=>	x"00",  -- address(1)
		15	=>	x"10",  -- address LSB (0)
		16	=>	x"00",  -- data length MSB(2)
		17	=>	x"00",  -- data length (1)
		18	=>	x"10"   -- data length LSB(0)
	);
	
	
	-- data_length set to write 4096 bytes --
	constant c_header_test_pattern_4	: 	t_byte_array(0 to 14) 	:=(	
		0 	=> x"FE",	-- target logical address
		1 	=> x"01",	-- protocol ID
		2 	=> x"6C",	-- Instruction
		3 	=> x"00",	-- key
		4 	=> x"67",  	-- initiaitor logical address
		5 	=> x"00",	-- transaction ID MSB
		6 	=> x"00",	-- transaction ID LSB
		7 	=> x"00",	-- extended address
		8 	=> x"A0",	-- address MSB(3)
		9 	=> x"00",	-- address(2)
		10 	=> x"00",	-- address(1)
		11	=> x"00",	-- address LSB (0)
		12  => x"00",	-- data length MSB(2)
		13  => x"10",	-- data length (1)		
		14  => x"00"	-- data length LSB(0)
	);
	
	-- data_length set to read 4096 bytes --
	constant c_header_test_pattern_5 : t_byte_array(0 to 14) := (
		0 	=> x"FE",	-- target logical address
		1 	=> x"01",   -- protocol ID
		2 	=> x"4C",   -- Instruction
		3 	=> x"00",   -- key
	    4 	=> x"67",   -- initiaitor logical address
	    5 	=> x"00",   -- transaction ID MSB
	    6 	=> x"01",   -- transaction ID LSB
	    7 	=> x"00",   -- extended address
	    8 	=> x"A0",   -- address MSB(3)
	    9 	=> x"00",   -- address(2)
	    10 	=> x"00",   -- address(1)
	    11	=> x"00",   -- address LSB (0)
	    12  => x"00",   -- data length MSB(2)
	    13  => x"10",   -- data length (1)
	    14  => x"00"    -- data length LSB(0)
	);
	
	-- data crc should be 0x56 (inserted automatically)
	--------------------------------------------------------------------------------------------------------------------------
	--	Simulation Protected Type Declerations 																				--
	--------------------------------------------------------------------------------------------------------------------------
	-- new RMAP frame protected type (for 4Links RMAP Router Testbench model)
	type t_rmap_frame is protected
	
		-- set path address bytes (maximum 32)
		procedure set_path_bytes(
			bytes: t_byte_array
		);
		
		-- set path address bytes (integer arguement) (maximum 32)
		procedure set_path_bytes(
			bytes : t_integer_array_256	
		);
		-- set if path address bytes are used
		procedure has_path_addr(
			bool : boolean
		);
		
		-- set logical address 
		procedure set_logical_addr(
			int : integer range 0 to 255
		);
		
		-- set RMAP protocol ID 
		procedure set_pid(
			int : integer range 0 to 255
		);
		
		-- set instruction byte
		procedure set_instruction(
			rw 				: string;						-- "read" or "write"	 read-mod write not yet supported 
			verify 			: boolean;						-- true to assert verify
			reply 			: boolean;						-- true if reply required
			increment_addr	: boolean;						-- true if increment address required
			addr_len 		: std_logic_vector(1 downto 0)	-- Reply SpW Address Length Field ("00" if no replies, else 01, 10, 11)
		);
		
		-- set key byte 
		procedure set_key(
			int : integer range 0 to 255
		);
		
		-- set reply address bytes (if present in instruction)
		procedure set_reply_addresses(
			bytes : t_byte_array
		);
		
		-- set initiator logical address 
		procedure set_init_address(
			int : integer range 0 to 255
		);
		
		-- set rmap transaction ID 
		procedure set_trans_id(
			int : integer range 0 to (2**16)-1
		);
			
		-- set 32-bit RMAP memory address + Extended address field 
		procedure set_mem_address(
			int : integer
		);
		
		-- set data length field 
		procedure set_data_length(
			int : integer range 0 to (2**24)-1
		);
		
		-- set header CRC byte buffer (used for verificaiton)
		procedure set_header_crc;
		
		-- create the RMAP header bytes and store in a buffer. CRC is NOT Added to header (for RMAP Initiator IP)
		procedure create_rmap_header;
		
		-- return header CRC byte (used for verification)
		impure function get_header_crc return t_byte;
		
		-- set data bytes for RMAP payload
		procedure set_data_bytes(
			bytes: t_byte_array-- := (others => (others => '0'))
		);
		
		-- calculate and set data crc byte buffer 
		procedure set_data_crc;
		
		-- returns calculated data CRC (for verification only) 
		impure function get_data_crc return t_byte;
		
		-- create the full RMAP frame (Header + Data Bytes)
		procedure create_rmap_frame;
		
		-- create a full RMAP frame with CRCs
		procedure create_rmap_frame_full;
		
		-- return size of constructed RMAP frame 
		impure function get_frame_size return integer;
		
		-- return addressed byte in frame (used for writing to RMAP Initiator interface)
		impure function get_frame_byte(addr : integer) return t_byte;	
		
		-- returns length of created RMAP header
		impure function get_header_size return integer;
		
		--returns length of created RMAP Data payload 
		impure function get_data_size return integer;
	
	end protected t_rmap_frame;
	
	type t_rmap_frame_array is protected
	
	-- RMAP header bytes (split into lower (before reply address field) and upper (after reply address field))
		
		
		-- set path address bytes (maximum 32)
		procedure set_path_bytes(
		    channel : integer;
			bytes: t_byte_array
		);
		
		-- set path address bytes (integer argument)
		procedure set_path_bytes(
			channel : integer;
			bytes : t_integer_array_256	
		);
		
		-- set if path address bytes are used
		procedure has_path_addr(
			channel : integer;
			bool : boolean
		);
		
		-- set logical address 
		procedure set_logical_addr(
			channel : integer;
			int : integer range 0 to 255
		);
		
		-- set RMAP protocol ID 
		procedure set_pid(
			channel : integer;
			int : integer range 0 to 255
		);
		
		-- set instruction byte
		procedure set_instruction(
			channel 		: integer;
			rw 				: string;						-- "read" or "write"
			verify 			: boolean;						-- true to verify
			reply 			: boolean;						-- true if reply required
			increment_addr	: boolean;						-- true if increment address required
			addr_len 		: std_logic_vector(1 downto 0)	-- Reply SpW Address Length Field 
		);
		
		-- set key byte 
		procedure set_key(
			channel : integer;
			int : integer range 0 to 255
		);
		
		-- set reply address bytes (if present in instruction)
		procedure set_reply_addresses(
			channel : integer;
			bytes : t_byte_array
		);
		
		-- set initiator logical address 
		procedure set_init_address(
			channel : integer;
			int : integer range 0 to 255
		);
		
		-- set rmap transaction ID 
		procedure set_trans_id(
			channel : integer;
			int : integer range 0 to (2**16)-1
		);
			
		-- set 32-bit RMAP memory address + Extended address field 
		procedure set_mem_address(
			channel : integer;
			int : integer
		);
		
		procedure set_mem_address(
			channel : integer;
			bytes : t_byte_array(0 to 3)
		);
		-- set data length field 
		procedure set_data_length(
			channel : integer;
			int : integer range 0 to (2**16)-1
		);
		
		-- set header CRC byte buffer (used for verificaiton)
		procedure set_header_crc(
			channel : integer
		);
		
		-- create the RMAP header bytes and store in a buffer. CRC is NOT Added to header (for RMAP Initiator IP)
		procedure create_rmap_header(
			channel : integer
		);
		
		-- return header CRC byte (used for verification)
		impure function get_header_crc(channel : integer)return t_byte;
		
		-- set data bytes for RMAP payload
		procedure set_data_bytes(
			channel : integer;
			bytes: t_byte_array -- := (others => (others => '0'))
		);
		
		-- calculate and set data crc byte buffer 
		procedure set_data_crc(
			channel : integer
		);
		
		-- returns calculated data CRC (for verification only) 
		impure function get_data_crc(channel : integer) return t_byte;
		
		-- create the full RMAP frame (Header + Data Bytes)
		procedure create_rmap_frame(
			channel : integer
		);
		
		-- create a full RMAP frame with CRCs
		procedure create_rmap_frame_full(
			channel : integer
		);
		
		-- return size of constructed RMAP frame 
		impure function get_frame_size(channel : integer) return integer;
		
		-- return addressed byte in frame 
		impure function get_frame_byte(channel : integer; addr : integer) return t_byte;
		
		-- return number of bytes in header
		impure function get_header_size(channel : integer) return integer;
		
		--return number of bytes in data payload
		impure function get_data_size(channel : integer) return integer;
	
		-- check byte matches frame byte, return boolean true/false
		impure function check_response(channel : integer; addr : integer; byte : t_byte) return boolean;
		
		impure function get_rw(channel : integer) return string;
		
	
	end protected t_rmap_frame_array;
	
	type t_rmap_command is protected 	-- type for SpaceWire test pattern storage 

		-- Set Header Bytes
		procedure set_header_bytes(
			bytes : t_byte_array
		);
		
		-- Set Data Bytes
		procedure set_data_bytes(
			bytes : t_byte_array
		);
		
		-- set path addresses 
		procedure set_path_bytes(
			bytes : t_byte_array
		);

		-- set if RMAP command uses path addresses or not 
		procedure set_paths(
			bool : boolean
		);

		-- functions (always impure within protected type) 
		
		-- return true if path addresses are used 
		impure function has_paths return boolean;
		
		-- get path byte at location addr
		impure function get_path_byte(addr : natural) return t_byte;
		
		-- returns number of bytes in path 
		impure function get_path_size return integer;
		
		-- return header byte at address addr
		impure function get_header_byte(addr: natural) return t_byte;
		-- return header CRC byte 
		impure function get_header_crc return t_byte; 
		
		-- return data byte at address addr
		impure function get_data_byte(addr: natural) return t_byte;
		-- return daa CRC byte 
		impure function get_data_crc return t_byte;
		
		--return size of header byte array 
		impure function get_header_size return natural;
		--return size of data byte array 
		impure function get_data_size return natural;
		
		-- calculate Header CRC and store in protected variable
		procedure set_header_crc;
		-- calculate data CRC and store in protected variable
		procedure set_data_crc;
	
		-- set size of header byte array (default = 15)
		procedure set_header_size(
			h_size : natural range 0 to natural'high
		);
		-- set size of data byte array (default = 16)
		procedure set_data_size(
			d_size : natural range 0 to natural'high
		);
		
	end protected t_rmap_command;
	
	-- protected type for RMAP reply storage and checking...
	type t_rmap_reply_pattern is protected		-- protected type for reply storage and checking
	
		procedure set_header_size(
			h_size: natural range 0 to natural'high
		);
		
		impure function get_header_size return natural;

		-- set size of data byte array 
		procedure set_data_size(
			d_size : natural range 0 to natural'high
		);
		
		impure function get_data_size return natural;

		
		procedure write_header_byte(
			byte	: t_byte;
			addr 	: natural range 0 to natural'high
		);
		
		procedure write_data_byte(
			byte	: t_byte;
			addr 	: natural range 0 to natural'high
		);
		
	
	end protected t_rmap_reply_pattern;
	
	
	type t_spw_frame is protected	-- spw debug frame protected type. 
	
		-- sets raw 13-bit SpaceWire data
		procedure set_raw_data(
			variable raw_data : in std_logic_vector(13 downto 0)
		);
		
		-- Set Spw Data Buffer
		procedure set_spw_data(
			variable spw_data : in std_logic_vector(8 downto 0)
		);
		
		-- Set SpaceWire TimeCode buffer
		procedure set_spw_time(
			variable spw_time : in std_logic_vector(7 downto 0)
		);
		
		-- Set SpaceWire Character Buffer
		procedure set_spw_char(
			variable spw_char : in string (1 to 3)
		);
		
		-- Set SpaceWire Parity bit
		procedure set_spw_parity(
			variable spw_parity : in std_logic
		);
	
		impure function get_raw_data return std_logic_vector;
		
		impure function get_data_nonet return std_logic_vector;
		
		impure function get_data_byte return std_logic_vector;
		
		impure function get_spw_time return std_logic_vector;
		
		impure function get_spw_char return string;
		
		impure function get_spw_parity return std_logic;
		
	end protected t_spw_frame;
	
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Interface Record Declerations 																						--
	--------------------------------------------------------------------------------------------------------------------------
	

	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- returns log2 of arguement 
	function log2(i1 : integer) return integer;
	
	-- perform i1 - i2 using 2's compliment addition
--	function subtract_2s(i1: signed; i2: signed) return signed;
	
	-- enter 4-bit SPW code, returns spacewire Token Code
	function get_spw_char(spw_char: std_logic_vector(3 downto 0)) return string;
	
	function gen_data(size: natural) return t_byte_array;
	

	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- generates clock signal for test-benching...
	procedure clock_gen(
		signal clock			: inout std_logic;	-- clock signal
		constant clock_period 	: time				-- clock period
	);
	
	procedure spw_get_poll(
		signal spw_signals		: inout		r_spw_debug_signals;
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 		natural							-- polling period (ns)
	);
	
	procedure spw_get_poll(
		variable spw_frame		: inout		t_spw_frame;
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 		natural							-- polling period (ns)
	);
	
	
	-- poll spacewire D/S lines, output debug data
	procedure spw_get_poll(
		signal spw_raw			: out 	std_logic_vector(13 downto 0);	-- raw packet received
		signal spw_data			: out 	std_logic_vector(8 downto 0);	-- data packet received (Con_bit & (7 downto 0))
		signal spw_time			: out 	std_logic_vector(7 downto 0);	-- space_wire timecode data received
		signal spw_char			: out 	string(1 to 3);					-- command nibble received
		signal spw_parity		: out 	std_logic;						-- parity bit output
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 	    natural							-- polling period (ns)
	);
	
	procedure wait_clocks(
		constant clk_period		: time;
		variable clk_num		: natural
	);
	
	-- send header bytes procedure (cannot be inside protected type)
	procedure send_header_bytes(
		signal assert_target 	: out 	std_logic;
		signal axi_rdata  		: out 	t_byte;
		signal axi_rvalid 		: out	std_logic;
		signal axi_rready 		: in 	std_logic;
		variable rmap_data 		: inout t_rmap_command
	);
	
	-- send data bytes procedure (cannot be inside protected type)
	procedure send_data_bytes(
		signal axi_rdata  : out 	t_byte;
		signal axi_rvalid : out		std_logic;
		signal axi_rready : in 		std_logic;
		variable rmap_data : inout 	t_rmap_command
	);
	
	-- send an RMAP frame using rmap_frame protected type (for RMAP Initiator IP Interface) 
	procedure send_rmap_frame(
		signal 	wr_header		: out 	t_byte;
		signal  wr_header_valid : out 	std_logic;
		signal 	wr_header_ready : in 	std_logic;
		signal  wr_data			: out 	t_byte;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame
	);
	
	procedure send_rmap_frame_raw(
		signal  wr_data			: out 	t_nonet;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame
	);
	
	
	procedure send_rmap_frame_array(
		variable channel 		: in integer;
		signal 	wr_header		: out 	t_byte;
		signal  wr_header_valid : out 	std_logic;
		signal 	wr_header_ready : in 	std_logic;
		signal  wr_data			: out 	t_byte;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame_array
	);
	
	-- used to send RMAP directly over SpaceWire IP with no RMAP Initiator
	procedure send_rmap_frame_raw_array(
		variable channel 		: in integer;
		signal  wr_data			: out 	t_nonet;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame_array
	);
	
	
	procedure rmap_rd_buffer_raw(
		variable	channel 		: in integer;
		signal		rx_data 		: in t_nonet;
		signal		rx_data_valid 	: in std_logic;
		signal		rx_data_ready 	: out std_logic;
		signal		bool			: out boolean;
		variable	rmap_frame 		: inout t_rmap_frame_array
		
	);
	
end package SpaceWire_Sim_lib;

package body SpaceWire_Sim_lib is 

	--------------------------------------------------------------------------------------------------------------------------
	--	Simulation Protected Type Bodies																					--
	--------------------------------------------------------------------------------------------------------------------------
	type t_rmap_frame is protected body
	
	-- RMAP header bytes (split into lower (before reply address field) and upper (after reply address field))
		variable rmap_header_size 	: integer range 1 to 256 := 16;	    -- sets length of RMAP header on transmission 
		variable rmap_header_total  : t_byte_array(0 to 255); 		-- total RMAP header with Path addresses and reply bytes, maximum 256 bytes
		variable rmap_header_lower	: t_byte_array(0 to 3);			-- rmap lower bytes 
		variable rmap_header_upper	: t_byte_array(0 to 10);		-- rmap upper bytes 
		
		variable wr_flag			: boolean := false;				-- tracks if rmap command was a read/write command. True if write. 
		
		variable path_bytes 	: t_byte_array(0 to 32);			-- path address field (can be up to 65536 in length)
		variable path_size 		: integer range 0 to 32 := 2;		-- number of path bytes, limited to 32. 
		variable has_paths		: boolean := false;					-- if true, has path bytes 
		
		variable reply_bytes	: t_byte_array(0 to 12);			-- reply bytes buffer (max 12)
		variable reply_size 	: integer range 0 to 12 := 0;		-- set number of reply bytes (0, 4, 8, 12)
		variable has_reply_addr : boolean := false;					-- if true, uses reply address field (set in RMAP instruction byte) 
		
		variable header_crc		: t_byte;							-- buffer to store a pre-calculated Header CRC byte (for verificaiton)
		variable data_crc		: t_byte;							-- buffer to store a pre-calculated Data CRC byte (for verificaiton)
		
		variable data_size		: integer range 0 to (2**24)-1 := 0;
		variable data_bytes		: t_byte_array (0 to (2**24)-1);	-- buffer for writing Data bytes over RMAP 
		
		variable rmap_frame		: t_byte_array(0 to (2**25)-1);
		variable rmap_frame_size: integer range 0 to (2**25)-1;
		
		-- set path address bytes (maximum 32)
		procedure set_path_bytes(
			bytes: t_byte_array
		) is
		begin
			path_size := bytes'length;
			path_bytes(0 to bytes'length-1) := bytes;
		--	for i in 0 to bytes'length-1 loop
		--		path_bytes(i) := bytes(i);
		--	end loop;
		end procedure set_path_bytes;
		
		-- set path address bytes (integer argument)
		procedure set_path_bytes(
			bytes : t_integer_array_256	
		)is
		begin
			path_size := bytes'length;
			path_bytes(0 to bytes'length-1) := int_to_byte_array(bytes);
		end procedure set_path_bytes;
		
		-- set if path address bytes are used
		procedure has_path_addr(
			bool : boolean
		) is
		begin	
			has_paths := bool;
		end procedure has_path_addr;
		
		-- set logical address 
		procedure set_logical_addr(
			int : integer range 0 to 255
		) is 
		begin
			rmap_header_lower(0) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure;
		
		-- set RMAP protocol ID 
		procedure set_pid(
			int : integer range 0 to 255
		) is 
		begin
			rmap_header_lower(1) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_pid;
		
		-- set instruction byte
		procedure set_instruction(
			rw 				: string;						-- "read" or "write"
			verify 			: boolean;						-- true to verify
			reply 			: boolean;						-- true if reply required
			increment_addr	: boolean;						-- true if increment address required
			addr_len 		: std_logic_vector(1 downto 0)	-- Reply SpW Address Length Field 
		) is 
			variable inst_byte : t_byte := b"0100_0000";
		begin
			if(rw = "read") then
				inst_byte(5) := '0';
				wr_flag := false;
			else
				inst_byte(5) := '1';
				wr_flag := true;
			end if;
			
			if(verify = true) then
				inst_byte(4) := '1';
			end if;
			
			if(reply = true) then
				inst_byte(3) := '1';
			end if;
			
			if(increment_addr = true) then
				inst_byte(2) := '1';
			end if;
			
			has_reply_addr := true;
			inst_byte(1 downto 0) := addr_len;
			if(addr_len = "00") then
				reply_size := 0;
				has_reply_addr := false;
			elsif(addr_len = "01")then
				reply_size := 4;
			elsif(addr_len = "10") then
				reply_size := 8;
			elsif(addr_len = "11") then
				reply_size := 12;
			end if;
			
			rmap_header_lower(2) := inst_byte;
		
		end procedure set_instruction;
		
		-- set key byte 
		procedure set_key(
			int : integer range 0 to 255
		) is
		begin
			rmap_header_lower(3) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_key;
		
		-- set reply address bytes (if present in instruction)
		procedure set_reply_addresses(
			bytes : t_byte_array
		) is
		begin
			if has_reply_addr = true then
				for i in 0 to bytes'length-1 loop
					reply_bytes(i) := bytes(i);
				end loop;
			end if;
		end procedure set_reply_addresses;
		
		-- set initiator logical address 
		procedure set_init_address(
			int : integer range 0 to 255
		) is
		begin
			rmap_header_upper(0) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_init_address;
		
		-- set rmap transaction ID 
		procedure set_trans_id(
			int : integer range 0 to (2**16)-1
		) is 
			variable std: unsigned(15 downto 0) := (others => '0');
		begin
			std := to_unsigned(int, std'length);
			rmap_header_upper(1) := std_logic_vector(std(15 downto 8));
			rmap_header_upper(2) := std_logic_vector(std(7 downto 0));
		end procedure set_trans_id;
			
		-- set 32-bit RMAP memory address + Extended address field 
		procedure set_mem_address(
			int : integer
		) is
			variable std : unsigned(31 downto 0) := (others => '0');
		begin
			std := to_unsigned(int, std'length);
			rmap_header_upper(3) := std_logic_vector(std(7 downto 0));		-- extended address field
			rmap_header_upper(4) := std_logic_vector(std(31 downto 24));	-- address MSByte
			rmap_header_upper(5) := std_logic_vector(std(23 downto 16));
			rmap_header_upper(6) := std_logic_vector(std(15 downto 8));
			rmap_header_upper(7) := std_logic_vector(std(7 downto 0));		-- address LSByte
		end procedure set_mem_address;
		
		
		-- set data length field 
		procedure set_data_length(
			int : integer range 0 to (2**24)-1
		)is
			variable std : unsigned(23 downto 0);
		begin
			data_size := int;			-- set data size variable 
			std := to_unsigned(int, std'length);
			rmap_header_upper(8) 	:=  std_logic_vector(std(23 downto 16));	-- set data length MSByte
			rmap_header_upper(9) 	:=  std_logic_vector(std(15 downto 8));
			rmap_header_upper(10)	:=  std_logic_vector(std(7 downto 0));		-- set data length LSByte
		end procedure set_data_length;
		
		-- set header CRC byte buffer (used for verificaiton)
		procedure set_header_crc is
			variable header_comb : t_byte_array(0 to 14);
			variable CRC_buf : t_byte := (others => '0');
			variable CRC_out : t_byte := (others => '0');
		begin
			header_comb(0 to 3) := rmap_header_lower;
			header_comb(4 to 14) := rmap_header_upper;
			for i in 0 to (header_comb'length)-1 loop		-- loop through all bytes in data 
				for j in 0 to 7 loop
					CRC_buf := 	CRC_buf(6 downto 2)
							& (header_comb(i)(j) xor CRC_buf(7) xor CRC_buf(1))
							& (header_comb(i)(j) xor CRC_buf(7) xor CRC_buf(0))
							& (header_comb(i)(j) xor CRC_buf(7));
				end loop;
			end loop;
			for k in 0 to 7 loop
				CRC_out(7-k) := CRC_buf(k);	
			end loop;
			header_crc := CRC_out;	-- write new CRC value
		end procedure set_header_crc;
		
		-- create the RMAP header bytes and store in a buffer. CRC is NOT Added to header (for RMAP Initiator IP)
		procedure create_rmap_header is
		begin
			if(has_paths = false) then						--doesn't use Path Address Bytes ?
				rmap_header_total(0 to 3) := rmap_header_lower;
				if has_reply_addr = true then	-- has reply address field ?
					rmap_header_total(4 to (4+reply_size)-1) := reply_bytes(0 to reply_size-1);
					rmap_header_total(4+reply_size to 14+reply_size) := rmap_header_upper;
					rmap_header_size := 15 + reply_size;
				else							-- does not use reply address field 
					rmap_header_total(4 to 14) := rmap_header_upper;
					rmap_header_size := 15;
				end if;
			else											-- uses path address bytes (path address size as offset)
				rmap_header_total(0 to path_size-1) := path_bytes(0 to path_size-1);
				rmap_header_total(path_size to path_size+3) := rmap_header_lower;
				if has_reply_addr = true then	-- has reply address field ?
					rmap_header_total(path_size+4 to path_size+(4+reply_size)-1) := reply_bytes(0 to reply_size-1);
					rmap_header_total(path_size+4+reply_size to path_size+14+reply_size) := rmap_header_upper;
					rmap_header_size := path_size + 15 + reply_size;
				else							-- does not use reply address field 
					rmap_header_total(path_size+4 to path_size+14) := rmap_header_upper;
					rmap_header_size := path_size+15;
				end if;
			end if;
		end procedure create_rmap_header;
		
		-- return header CRC byte (used for verification)
		impure function get_header_crc return t_byte is
		begin
			set_header_crc;
			return header_crc;
		end function get_header_crc;
		
		-- set data bytes for RMAP payload
		procedure set_data_bytes(
			bytes: t_byte_array-- := (others => (others => '0'))
		) is
		begin
			if(data_size > 0) then		-- only run when data size is at least 1 byte 
				for i in 0 to data_size-1 loop	
					data_bytes(i) := bytes(i);
				end loop;
			end if;
		end procedure set_data_bytes;
		
		-- calculate and set data crc byte buffer 
		procedure set_data_crc is
			variable CRC_buf : t_byte := (others => '0');
			variable CRC_out : t_byte := (others => '0');
		begin
			if(data_size > 0 ) then					-- only exec if data size is valid (1 byte or more)
				for i in 0 to data_size-1 loop		-- loop through all bytes in data 
					for j in 0 to 7 loop
						CRC_buf := 	CRC_buf(6 downto 2)
								& (data_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(1))
								& (data_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(0))
								& (data_bytes(i)(j) xor CRC_buf(7));
					end loop;
				end loop;
				for k in 0 to 7 loop
					CRC_out(7-k) := CRC_buf(k);	
				end loop;
			end if;
			data_crc := CRC_out;	-- write new CRC value
		end procedure set_data_crc;
		
		-- returns calculated data CRC (for verification only) 
		impure function get_data_crc return t_byte is
		begin
			set_data_crc;
			return data_crc;
		end function get_data_crc;
		
		-- create the full RMAP frame (Header + Data Bytes)
		procedure create_rmap_frame is
		begin
			if(wr_flag = true) then	-- is a write command (has data bytes in frame)
				rmap_frame_size := rmap_header_size + data_size;
				rmap_frame(0 to rmap_header_size-1) := rmap_header_total(0 to rmap_header_size-1) ;
				rmap_frame(rmap_header_size to rmap_frame_size-1) := data_bytes(0 to data_size-1);
			else					-- is a read command (no data bytes in frame)
				data_size := 0;
				rmap_frame_size := rmap_header_size;
				rmap_frame(0 to rmap_header_size-1) := rmap_header_total(0 to rmap_header_size-1);
			end if;
			
		end procedure create_rmap_frame;
		
		-- create a full RMAP frame with CRCs
		procedure create_rmap_frame_full is
		begin
			if(wr_flag = true) then	-- is a write command (has data bytes in frame)
				rmap_frame_size := rmap_header_size + data_size + 2;	-- plus 2 for Header and Data CRC bytes
				rmap_frame(0 to rmap_header_size) := rmap_header_total(0 to rmap_header_size-1) & get_header_crc; 	-- concatenate header CRC
				rmap_frame(rmap_header_size+1 to rmap_frame_size) := data_bytes(0 to data_size-1) & get_data_crc;	-- concatenate data CRC
			else					-- is a read command (no data bytes in frame)
				data_size := 0;
				rmap_frame_size := rmap_header_size + 1;
				rmap_frame(0 to rmap_header_size) := rmap_header_total(0 to rmap_header_size-1) & get_header_crc;	-- concatenate header CRC
			end if;
		end procedure;
		
		-- return size of constructed RMAP frame 
		impure function get_frame_size return integer is 
		begin
			return rmap_frame_size;
		end function get_frame_size;
		
		-- return addressed byte in frame 
		impure function get_frame_byte(addr : integer) return t_byte is 
		begin
			return rmap_frame(addr);
		end function get_frame_byte;
		
		-- return number of bytes in header
		impure function get_header_size return integer is
		begin
			return rmap_header_size;
		end function get_header_size;
		
		--return number of bytes in data payload
		impure function get_data_size return integer is
		begin
			return data_size;
		end function get_data_size;
		
	
	end protected body t_rmap_frame;
	
	-- creates an array of 32 RMAP Channels 
	type t_rmap_frame_array is protected body
	
	-- RMAP header bytes (split into lower (before reply address field) and upper (after reply address field))
		variable rmap_header_size 	: t_integer_array(0 to 31) := (others => 16);	    -- sets length of RMAP header on transmission 
		variable rmap_header_total  : t_byte_array_3d(0 to 31)(0 to 255); 		-- total RMAP header with Path addresses and reply bytes, maximum 256 bytes
		variable rmap_header_lower	: t_byte_array_3d(0 to 31)(0 to 3);			-- rmap lower bytes 
		variable rmap_header_upper	: t_byte_array_3d(0 to 31)(0 to 10);		-- rmap upper bytes 
		
		variable wr_flag			:  t_bool_array(0 to 31) := (others => false);				-- tracks if rmap command was a read/write command. True if write. 
		
		variable path_bytes 	: t_byte_array_3d(0 to 31)(0 to 32);			-- path address field (can be up to 65536 in length)
		variable path_size 		: t_integer_array(0 to 31) := (others => 2);		-- number of path bytes, limited to 32. 
		variable has_paths		: t_bool_array(0 to 31) := (others => false);					-- if true, has path bytes 
		
		variable reply_bytes	: t_byte_array_3d(0 to 31)(0 to 12);			-- reply bytes buffer (max 12)
		variable reply_size 	: t_integer_array(0 to 31) := (others => 0);		-- set number of reply bytes (0, 4, 8, 12)
		variable has_reply_addr :  t_bool_array(0 to 31) := (others => false);					-- if true, uses reply address field (set in RMAP instruction byte) 
		
		variable header_crc		: t_byte_array(0 to 31);							-- buffer to store a pre-calculated Header CRC byte (for verificaiton)
		variable data_crc		: t_byte_array(0 to 31);							-- buffer to store a pre-calculated Data CRC byte (for verificaiton)
		
		variable data_size		: t_integer_array(0 to 31) := (others => 0);
		variable data_bytes		: t_byte_array_3d(0 to 31)(0 to (2**16)-1);			-- buffer for writing Data bytes over RMAP 
		
		variable rmap_frame		: t_byte_array_3d(0 to 31)(0 to (2**16)-1);			-- data buffer to store full RMAP frame 
		variable rmap_frame_size: t_integer_array(0 to 31):= (others => 0);			-- size of generated RMAP frame. 
		variable rmap_rd_frame 	: t_byte_array_3d(0 to 31)(0 to (2**16)-1);			-- data buffer to store a full READ rmap frome 
		
		-- set path address bytes (maximum 32)
		
		procedure set_path_bytes(
		    channel : integer;
			bytes: t_byte_array
		) is
		begin
			path_size(channel) := bytes'length;
			path_bytes(channel)(0 to bytes'length-1) := bytes;
		--	for i in 0 to bytes'length-1 loop
		--		path_bytes(i) := bytes(i);
		--	end loop;
		end procedure set_path_bytes;
		
		-- set path address bytes (integer argument)
		procedure set_path_bytes(
			channel : integer;
			bytes : t_integer_array_256	
		)is
		begin
			path_size(channel) := bytes'length;
			path_bytes(channel)(0 to bytes'length-1) := int_to_byte_array(bytes);
		end procedure set_path_bytes;
		
		-- set if path address bytes are used
		procedure has_path_addr(
			channel : integer;
			bool : boolean
		) is
		begin	
			has_paths(channel) := bool;
		end procedure has_path_addr;
		
		-- set logical address 
		procedure set_logical_addr(
			channel : integer;
			int : integer range 0 to 255
		) is 
		begin
			rmap_header_lower(channel)(0) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure;
		
		-- set RMAP protocol ID 
		procedure set_pid(
			channel : integer;
			int : integer range 0 to 255
		) is 
		begin
			rmap_header_lower(channel)(1) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_pid;
		
		-- set instruction byte
		procedure set_instruction(
			channel 		: integer;
			rw 				: string;						-- "read" or "write"
			verify 			: boolean;						-- true to verify
			reply 			: boolean;						-- true if reply required
			increment_addr	: boolean;						-- true if increment address required
			addr_len 		: std_logic_vector(1 downto 0)	-- Reply SpW Address Length Field 
		) is 
			variable inst_byte : t_byte := b"0100_0000";
		begin
			if(rw = "read") then
				inst_byte(5) := '0';
				wr_flag(channel) := false;
			else
				inst_byte(5) := '1';
				wr_flag(channel) := true;
			end if;
			
			if(verify = true) then
				inst_byte(4) := '1';
			end if;
			
			if(reply = true) then
				inst_byte(3) := '1';
			end if;
			
			if(increment_addr = true) then
				inst_byte(2) := '1';
			end if;
			
			has_reply_addr(channel) := true;
			inst_byte(1 downto 0) := addr_len;
			if(addr_len = "00") then
				reply_size(channel) := 0;
				has_reply_addr(channel) := false;
			elsif(addr_len = "01")then
				reply_size(channel) := 4;
			elsif(addr_len = "10") then
				reply_size(channel) := 8;
			elsif(addr_len = "11") then
				reply_size(channel) := 12;
			end if;
			
			rmap_header_lower(channel)(2) := inst_byte;
		
		end procedure set_instruction;
		
		-- set key byte 
		procedure set_key(
			channel : integer;
			int : integer range 0 to 255
		) is
		begin
			rmap_header_lower(channel)(3) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_key;
		
		-- set reply address bytes (if present in instruction)
		procedure set_reply_addresses(
			channel : integer;
			bytes : t_byte_array
		) is
		begin
			if has_reply_addr(channel) = true then
				for i in 0 to bytes'length-1 loop
					reply_bytes(channel)(i) := bytes(i);
				end loop;
			end if;
		end procedure set_reply_addresses;
		
		-- set initiator logical address 
		procedure set_init_address(
			channel : integer;
			int : integer range 0 to 255
		) is
		begin
			rmap_header_upper(channel)(0) := std_logic_vector(to_unsigned(int, t_byte'length));
		end procedure set_init_address;
		
		-- set rmap transaction ID 
		procedure set_trans_id(
			channel : integer;
			int : integer range 0 to (2**16)-1
		) is 
			variable std: unsigned(15 downto 0) := (others => '0');
		begin
			std := to_unsigned(int, std'length);
			rmap_header_upper(channel)(1) := std_logic_vector(std(15 downto 8));
			rmap_header_upper(channel)(2) := std_logic_vector(std(7 downto 0));
		end procedure set_trans_id;
			
		-- set 32-bit RMAP memory address + Extended address field 
		procedure set_mem_address(
			channel : integer;
			int : integer
		) is
			variable std : unsigned(31 downto 0) := (others => '0');
		begin
			std := to_unsigned(int, std'length);
			rmap_header_upper(channel)(3) := std_logic_vector(std(7 downto 0));		-- extended address field
			rmap_header_upper(channel)(4) := std_logic_vector(std(31 downto 24));	-- address MSByte
			rmap_header_upper(channel)(5) := std_logic_vector(std(23 downto 16));
			rmap_header_upper(channel)(6) := std_logic_vector(std(15 downto 8));
			rmap_header_upper(channel)(7) := std_logic_vector(std(7 downto 0));		-- address LSByte
		end procedure set_mem_address;
		
		procedure set_mem_address(
			channel : integer;
			bytes : t_byte_array(0 to 3)
		) is
		begin
			rmap_header_upper(channel)(3) := bytes(0);		-- extended address field
			rmap_header_upper(channel)(4) := bytes(3);	-- address MSByte
			rmap_header_upper(channel)(5) := bytes(2);
			rmap_header_upper(channel)(6) := bytes(1);
			rmap_header_upper(channel)(7) := bytes(0);	-- address LSByte
		end procedure set_mem_address;
		
		-- set data length field 
		procedure set_data_length(
			channel : integer;
			int : integer range 0 to (2**16)-1
		)is
			variable std : unsigned(23 downto 0);
		begin
			data_size(channel) := int;			-- set data size variable 
			std := to_unsigned(int, std'length);
			rmap_header_upper(channel)(8) 	:=  std_logic_vector(std(23 downto 16));	-- set data length MSByte
			rmap_header_upper(channel)(9) 	:=  std_logic_vector(std(15 downto 8));
			rmap_header_upper(channel)(10)	:=  std_logic_vector(std(7 downto 0));		-- set data length LSByte
		end procedure set_data_length;
		
		-- set header CRC byte buffer (used for verificaiton)
		procedure set_header_crc(
			channel : integer
		) is
			variable header_comb : t_byte_array(0 to 14);
			variable CRC_buf : t_byte := (others => '0');
			variable CRC_out : t_byte := (others => '0');
		begin
			header_comb(0 to 3) := rmap_header_lower(channel)(0 to 3);
			header_comb(4 to 14) := rmap_header_upper(channel)(0 to 10);
			for i in 0 to 14 loop		-- loop through all bytes in data 
				for j in 0 to 7 loop
					CRC_buf := 	CRC_buf(6 downto 2)
							& (header_comb(i)(j) xor CRC_buf(7) xor CRC_buf(1))
							& (header_comb(i)(j) xor CRC_buf(7) xor CRC_buf(0))
							& (header_comb(i)(j) xor CRC_buf(7));
				end loop;
			end loop;
			for k in 0 to 7 loop
				CRC_out(7-k) := CRC_buf(k);	
			end loop;
			header_crc(channel) := CRC_out;	-- write new CRC value
		end procedure set_header_crc;
		
		-- create the RMAP header bytes and store in a buffer. CRC is NOT Added to header (for RMAP Initiator IP)
		procedure create_rmap_header(
			channel : integer
		)is
		begin
			if(has_paths(channel) = false) then						--doesn't use Path Address Bytes ?
				rmap_header_total(channel)(0 to 3) := rmap_header_lower(channel);
				if has_reply_addr(channel) = true then	-- has reply address field ?
					rmap_header_total(channel)(4 to (4+reply_size(channel))-1) := reply_bytes(channel)(0 to reply_size(channel)-1);
					rmap_header_total(channel)(4+reply_size(channel) to 14+reply_size(channel)) := rmap_header_upper(channel);
					rmap_header_size(channel) := 15 + reply_size(channel);
				else							-- does not use reply address field 
					rmap_header_total(channel)(4 to 14) := rmap_header_upper(channel);
					rmap_header_size(channel) := 15;
				end if;
			else											-- uses path address bytes (path address size as offset)
				rmap_header_total(channel)(0 to path_size(channel)-1) := path_bytes(channel)(0 to path_size(channel)-1);
				rmap_header_total(channel)(path_size(channel) to path_size(channel)+3) := rmap_header_lower(channel);
				if has_reply_addr(channel) = true then	-- has reply address field ?
					rmap_header_total(channel)(path_size(channel)+4 to path_size(channel)+(4+reply_size(channel))-1) := reply_bytes(channel)(0 to reply_size(channel)-1);
					rmap_header_total(channel)(path_size(channel)+4+reply_size(channel) to path_size(channel)+14+reply_size(channel)) := rmap_header_upper(channel);
					rmap_header_size(channel) := path_size(channel) + 15 + reply_size(channel);
				else							-- does not use reply address field 
					rmap_header_total(channel)(path_size(channel)+4 to path_size(channel)+14) := rmap_header_upper(channel);
					rmap_header_size(channel) := path_size(channel)+15;
				end if;
			end if;
		end procedure create_rmap_header;
		
		-- return header CRC byte (used for verification)
		impure function get_header_crc(channel : integer)return t_byte is
		begin
			set_header_crc(channel);
			return header_crc(channel);
		end function get_header_crc;
		
		-- set data bytes for RMAP payload
		procedure set_data_bytes(
			channel : integer;
			bytes: t_byte_array --:= (others => (others => '0'))
		) is
		begin
			if(data_size(channel) > 0) then		-- only run when data size is at least 1 byte 
				for i in 0 to data_size(channel)-1 loop	
					data_bytes(channel)(i) := bytes(i);
				end loop;
			end if;
		end procedure set_data_bytes;
		
		-- calculate and set data crc byte buffer 
		procedure set_data_crc(
			channel : integer
		)is
			variable CRC_buf : t_byte := (others => '0');
			variable CRC_out : t_byte := (others => '0');
		begin
			if(data_size(channel) > 0 ) then					-- only exec if data size is valid (1 byte or more)
				for i in 0 to data_size(channel)-1 loop		-- loop through all bytes in data 
					for j in 0 to 7 loop
						CRC_buf := 	CRC_buf(6 downto 2)
								& (data_bytes(channel)(i)(j) xor CRC_buf(7) xor CRC_buf(1))
								& (data_bytes(channel)(i)(j) xor CRC_buf(7) xor CRC_buf(0))
								& (data_bytes(channel)(i)(j) xor CRC_buf(7));
					end loop;
				end loop;
				for k in 0 to 7 loop
					CRC_out(7-k) := CRC_buf(k);	
				end loop;
			end if;
			data_crc(channel) := CRC_out;	-- write new CRC value
		end procedure set_data_crc;
		
		-- returns calculated data CRC (for verification only) 
		impure function get_data_crc(channel : integer) return t_byte is
		begin
			set_data_crc(channel);
			return data_crc(channel);
		end function get_data_crc;
		
		-- create the full RMAP frame (Header + Data Bytes)
		procedure create_rmap_frame(
			channel : integer
		) is
		begin
			if(wr_flag(channel) = true) then	-- is a write command (has data bytes in frame)
				rmap_frame_size(channel) := rmap_header_size(channel) + data_size(channel);
				rmap_frame(channel)(0 to rmap_header_size(channel)-1) := rmap_header_total(channel)(0 to rmap_header_size(channel)-1) ;
				rmap_frame(channel)(rmap_header_size(channel) to rmap_frame_size(channel)-1) := data_bytes(channel)(0 to data_size(channel)-1);
			else					-- is a read command (no data bytes in frame)
				data_size(channel) := 0;
				rmap_frame_size(channel) := rmap_header_size(channel);
				rmap_frame(channel)(0 to rmap_header_size(channel)-1) := rmap_header_total(channel)(0 to rmap_header_size(channel)-1);
			end if;
			
		end procedure create_rmap_frame;
		
		-- create a full RMAP frame with CRCs
		procedure create_rmap_frame_full(
			channel : integer
		)is
		begin
			if(wr_flag(channel) = true) then	-- is a write command (has data bytes in frame)
				rmap_frame_size(channel) := rmap_header_size(channel) + data_size(channel) + 2;	-- plus 2 for Header and Data CRC bytes
				rmap_frame(channel)(0 to (rmap_header_size(channel))) := (rmap_header_total(channel)(0 to (rmap_header_size(channel)-1))) & (get_header_crc(channel)); 	-- concatenate header CRC
				rmap_frame(channel)((rmap_header_size(channel)+1) to (rmap_frame_size(channel))-2) := data_bytes(channel)(0 to (data_size(channel)-1)); 
				rmap_frame(channel)(rmap_frame_size(channel)-1) := get_data_crc(channel);	-- concatenate data CRC
		
			else					-- is a read command (no data bytes in frame)
				data_size(channel) := 0;
				rmap_frame_size(channel) := rmap_header_size(channel) + 1;
				rmap_frame(channel)(0 to rmap_header_size(channel)) := rmap_header_total(channel)(0 to rmap_header_size(channel)-1) & get_header_crc(channel);	-- concatenate header CRC
			end if;
		end procedure;
		
		-- return size of constructed RMAP frame 
		impure function get_frame_size(channel : integer) return integer is 
		begin
			return rmap_frame_size(channel);
		end function get_frame_size;
		
		-- return addressed byte in frame 
		impure function get_frame_byte(channel : integer; addr : integer) return t_byte is 
		begin
			return rmap_frame(channel)(addr);
		end function get_frame_byte;
		
		-- return number of bytes in header
		impure function get_header_size(channel : integer) return integer is
		begin
			return rmap_header_size(channel);
		end function get_header_size;
		
		--return number of bytes in data payload
		impure function get_data_size(channel : integer) return integer is
		begin
			return data_size(channel);
		end function get_data_size;
		
		-- check byte matches frame byte, return boolean true/false
		impure function check_response(channel : integer; addr : integer; byte : t_byte) return boolean is
		begin
			if(rmap_frame(channel)(addr) /= byte) then
				return false;
			end if;
			return true;
		end function check_response;
		
		impure function get_rw(channel : integer) return string is
		begin
			if(rmap_header_lower(channel)(2)(5) = '0') then
				return "read";
			else
				return "write";
			end if;
		end function get_rw;

	
	end protected body t_rmap_frame_array;
	
	type t_rmap_command is protected body	-- spacewire test pattern 1 
		-- variables
		variable header_size	: natural range 0 to natural'high := 15;	-- number of bytes in header frame. (default 15)
		variable data_size		: natural range 0 to natural'high := 16;	-- number of bytes in data frame (default 16)
		variable num_paths		: natural range 0 to natural'high := 0;
		variable has_path_addr	: boolean := false;
		
		variable header_bytes 	: t_byte_array(0 to (2**16)-1);--	:= c_header_test_pattern_1;			-- header bytes
		variable header_crc		: t_byte 							:= (others => '0');--c_header_test_pattern_1_crc;		-- header CRC byte
		
		variable data_bytes		: t_byte_array(0 to (2**16)-1);-- 	:= c_data_test_pattern_1;			-- data bytes
		variable data_crc		: t_byte 							:= (others => '0'); --c_data_test_pattern_1_crc;;		-- data CRC byte
		
		variable path_bytes		: t_byte_array(0 to (2**16)-1);		-- path address bytes in RMAP command 
		
		-- set path addresses 
		procedure set_path_bytes(
			bytes : t_byte_array
		) is
		begin
			num_paths := bytes'length;
			path_bytes(0 to num_paths-1) := bytes;
		end procedure set_path_bytes;
		
		-- returns path byte at location ADDR
		impure function get_path_byte(addr : natural) return t_byte is
		begin
			return path_bytes(addr);
		end function get_path_byte;
		
		-- returns number of bytes in loaded path address  
		impure function get_path_size return integer is
		begin
			return num_paths;
		end function get_path_size;
		
		-- set if RMAP command uses path addresses or not 
		procedure set_paths(
			bool : boolean
		) is
		begin
			has_path_addr := bool;
		end procedure set_paths;
		
		-- return true if path addresses are used 
		impure function has_paths return boolean is
		begin
			return has_path_addr;
		end function has_paths;
		
		-- set new header bytes, calculate new header CRC 
		procedure set_header_bytes(
			bytes : t_byte_array
		) is 
		begin
			header_size := bytes'length;					-- set header bytes length	
			header_bytes(0 to header_size-1) := bytes;		-- load new header bytes 
			set_header_crc;									-- calculate and set new header CRC
		end procedure set_header_bytes;
		
		-- set new data bytes, calculate new data CRC
		procedure set_data_bytes(
			bytes : t_byte_array
		) is
		begin
			data_size := bytes'length;						-- set data bytes length 
			data_bytes(0 to data_size-1) := bytes;			-- load new data bytes 
			set_data_crc;									-- calculate and set new data CRC 
		end procedure set_data_bytes;
		
		-- read header CRC
		impure function get_header_crc return t_byte is
		begin
			return header_crc;
		end function get_header_crc;
		
		-- read data crc 
		impure function get_data_crc return t_byte is 
		begin
			return data_crc;
		end function get_data_crc;
		
		-- functions (always impure within protected type) 
		-- read header byte 
		impure function get_header_byte(addr: natural) return t_byte is	-- read header byte memory
		begin
			return header_bytes(addr);
		end function get_header_byte;
		
		-- read data byte 
		impure function get_data_byte(addr: natural) return t_byte is		-- read data byte memory
		begin
			return data_bytes(addr);
		end function get_data_byte;
		
		-- calculate header CRC and store in buffer
		procedure set_header_crc is 
			variable CRC_buf	: t_byte := (others => '0');
			variable CRC_out	: t_byte := (others => '0');
		begin
			for i in 0 to header_size-1 loop	-- loop through all bytes in header 
				for j in 0 to 7 loop
					CRC_buf := 	CRC_buf(6 downto 2)
							& (header_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(1))
							& (header_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(0))
							& (header_bytes(i)(j) xor CRC_buf(7));
				end loop;
			end loop;
			for k in 0 to 7 loop
				CRC_out(7-k) := CRC_buf(k);
			end loop;
			header_crc := CRC_out;	-- write new CRC value 
		end procedure set_header_crc;
		
		-- calculate data CRC and store in buffer 
		procedure set_data_crc is
			variable CRC_buf	: t_byte := (others => '0');
			variable CRC_out	: t_byte := (others => '0');
		begin
			for i in 0 to data_size-1 loop		-- loop through all bytes in data 
				for j in 0 to 7 loop
					CRC_buf := 	CRC_buf(6 downto 2)
							& (data_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(1))
							& (data_bytes(i)(j) xor CRC_buf(7) xor CRC_buf(0))
							& (data_bytes(i)(j) xor CRC_buf(7));
				end loop;
			end loop;
			for k in 0 to 7 loop
				CRC_out(7-k) := CRC_buf(k);	
			end loop;
			data_crc := CRC_out;	-- write new CRC value
		end procedure set_data_crc;
		
		
		-- get header and data array sizes 
		impure function get_header_size return natural is		
		begin
			return header_size;							-- return length of loaded header bytes string  
		end function;
		
		impure function get_data_size return natural is 
		begin	
			return data_size;							-- return length of loaded data bytes string 
		end function;
		
		-- set size of header byte array 
		procedure set_header_size(
			h_size : natural range 0 to natural'high
		) is
		begin
			header_size := h_size;
		end procedure set_header_size;
		
		-- set size of data byte array 
		procedure set_data_size(
			d_size : natural range 0 to natural'high
		) is
		begin
			data_size := d_size;
		end procedure set_data_size;
		
	end protected body t_rmap_command;
	
	
	type t_rmap_reply_pattern is protected body		-- protected type for reply storage and checking 
		
		variable reply_header 	: 	t_byte_array(0 to (2**16)-1);
		variable reply_data		:	t_byte_array(0 to (2**16)-1);
		
		variable header_size  	: 	natural range 0 to natural'high;
		variable data_size      : 	natural range 0 to natural'high;
		
		procedure set_header_size(
			h_size: natural range 0 to natural'high
		) is
		begin
			header_size := h_size;
		end procedure set_header_size;
		
		impure function get_header_size return natural is
		begin
			return header_size;
		end function get_header_size;
		
		-- set size of data byte array 
		procedure set_data_size(
			d_size : natural range 0 to natural'high
		) is
		begin
			data_size := d_size;
		end procedure set_data_size;
		
		impure function get_data_size return natural is
		begin
			return data_size;
		end function get_data_size;
		
		procedure write_header_byte(
			byte	: t_byte;
			addr 	: natural range 0 to natural'high
		) is
		begin
			reply_header(addr) := byte; 
		end procedure write_header_byte;
		
		procedure write_data_byte(
			byte	: t_byte;
			addr 	: natural range 0 to natural'high
		) is
		begin
			reply_data(addr) := byte; 
		end procedure write_data_byte;
	
	end protected body t_rmap_reply_pattern;
	
	-- data buffers in a spacewire frame 
	type t_spw_frame is protected body
	
		variable frame_spw_raw 			: std_logic_vector(13 downto 0) := (others => '0');
		variable frame_spw_data			: std_logic_vector(8 downto 0) := (others => '0');
		variable frame_spw_time			: std_logic_vector(7 downto 0) := (others => '0');
		variable frame_spw_char 		: string(1 to 3) := "NUL";
		variable frame_spw_parity		: std_logic := '0';
		
		procedure set_raw_data(
			variable raw_data : in std_logic_vector(13 downto 0)
		) is
		begin
			frame_spw_raw := raw_data;
		end procedure set_raw_data;
		
		procedure set_spw_data(
			variable spw_data : in std_logic_vector(8 downto 0)
		) is
		begin
			frame_spw_data := spw_data;
		end procedure set_spw_data;
		
		procedure set_spw_time(
			variable spw_time : in std_logic_vector(7 downto 0)
		) is
		begin
			frame_spw_time := spw_time;
		end procedure set_spw_time;
		
		procedure set_spw_char(
			variable spw_char : in string (1 to 3)
		) is 
		begin
			frame_spw_char := spw_char;
		end procedure set_spw_char;
		
		procedure set_spw_parity(
			variable spw_parity : in std_logic
		) is
		begin
			frame_spw_parity := spw_parity;
		end procedure set_spw_parity;
		
		impure function get_raw_data return std_logic_vector is 
		begin
			return frame_spw_raw;
		end function get_raw_data;
		
		impure function get_data_nonet return std_logic_vector is 
		begin
			return frame_spw_data;
		end function get_data_nonet;
	
		
		impure function get_data_byte return std_logic_vector is 
		begin
			return frame_spw_data(7 downto 0);
		end function get_data_byte;
		
		impure function get_spw_time return std_logic_vector is
		begin
			return frame_spw_time;
		end function get_spw_time;
		
		impure function get_spw_char return string is 
		begin
			return frame_spw_char;
		end function get_spw_char;
		
		impure function get_spw_parity return std_logic is
		begin
			return frame_spw_parity;
		end function get_spw_parity;
		
	
	end protected body;
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------
	-- returns XORed value of two 4-bit unsigned numbers

	
	-- return log2 of function
	function log2(i1 : integer) return integer is
		variable log_val  : integer := 1;
		variable v_i1     : integer := i1;
	begin
		if(i1 > 1) then		-- valid input (i1 > 1)
			while (v_i1 > 1) loop
				log_val := log_val + 1;
				v_i1	:= v_i1/2;
			end loop;
		end if;
		return log_val;
	end function;
	/*
	-- perform 2's compliment subtraction by using addition (good for simulation)
	function subtract_2s(i1: signed; i2: signed) return signed is
		variable  retval : signed := (others => '0');
	begin
		retval := i1 + (not(i2) + 1);	-- performs i1 - i2;
		return retval;
	end function;
*/
		-- enter 4-bit SPW code, returns spacewire Token Code
	function get_spw_char(spw_char: std_logic_vector(3 downto 0)) return string is
		variable return_string	:	string(1 to 3);				-- string to return
		variable v_char			: 	std_logic_vector(2 downto 0);
	begin
		v_char 	:= spw_char(3 downto 1);
		case(v_char) is							-- check input matches valid Character values
			when c_SpW_FCT_code =>
				return_string := "NUL";
			
			when c_SpW_EOP_code =>
				return_string := "EOP";
			
			when c_SpW_EEP_code =>
				return_string := "EEP";
			
			when c_SpW_ESC_code =>
				return_string := "ESC";
				
			when others =>								-- no match with valid char values ?
				return_string := "BAD";				-- return invalid argument
				
		end case;
		
		return return_string;
	end function;	
	
	function gen_data(size: natural) return t_byte_array is
		variable v_bytes 	: t_byte_array(0 to size-1);
	begin
		for i in 0 to size-1 loop
			v_bytes(i) := std_logic_vector(to_unsigned(i, 8));
		end loop;
		return v_bytes;
	end function gen_data;
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	
	-- generates clock signal for test-benching
	procedure clock_gen(
		signal   clock			: inout std_logic;	-- clock signal
		constant clock_period 	: time				-- clock period
	) is
	begin
		wait for clock_period/2;
		clock <= not clock;
		wait for clock_period/2;
		clock <= not clock;
	end clock_gen;
	
	-- used to poll the SpW Channel. Outputs Debug data (via records types)
	procedure spw_get_poll(
		signal spw_signals		: inout		r_spw_debug_signals;
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 		natural							-- polling period (ns)
	)is 
		variable data_bits		: std_logic_vector(13 downto 0);			-- buffer to store data bits
		variable xor_val 		: std_logic	:= '0';							-- buffer to store XOR value of D/S
		variable v_period		: time 		:= period * 1 ns;				-- period to wait (ns)
		variable spw_char		: string(1 to 3);
		variable spw_data		: std_logic_vector(8 downto 0);
		variable spw_raw		: std_logic_vector(13 downto 0);
		variable spw_time		: std_logic_vector(7 downto 0);
		
	begin	
		data_bits 	:= (others => 'U');									-- manually buffers unknown (for debug)
		init: loop														-- wait around for first clock edge
			xor_val := spw_d xor spw_s;
			wait for v_period;
			exit init when xor_val /= (spw_d xor spw_s);		
		end loop init;
		
		data_bits(0) := spw_d;											-- load first bit from first clock edge (parity bit)
		
		for i in 1 to 3 loop											-- get the rest of the nibble
			rx_loop: loop
				xor_val := spw_d xor spw_s;
				wait for v_period;		
				exit rx_loop when xor_val /= (spw_d xor spw_s);
			end loop rx_loop;
			data_bits(i) := spw_d;
		end loop;
		
	
		if(data_bits(1) = '0') then													-- data SPW frame ?
			spw_char := "DAT";														-- report DATA info packet
			for i in 4 to 9 loop													-- repeat to get the rest of the fata frame (10 bits total. 6 more to go)
				rx_loop2: loop
					xor_val := spw_d xor spw_s;
					wait for v_period;	
					exit rx_loop2 when xor_val /= (spw_d xor spw_s);
				end loop rx_loop2;
				data_bits(i) := spw_d;
			end loop;
			spw_data(7 downto 0) := data_bits(9 downto 2);							-- assign output variable data bit
			spw_data(8)			 := data_bits(1);
		else																		-- else, Control SPW frame ?
		
			case(data_bits(3 downto 1)) is
				when c_SpW_FCT_code =>
					spw_char := "FCT";
					
				when c_SpW_EOP_code =>
					spw_char := "EOP";
				
				when c_SpW_EEP_code =>
					spw_char := "EEP";
				
				when c_SpW_ESC_code =>
					spw_char := "ESC";													-- output Escape character
	
					for i in 4 to 5 loop												-- read in next two bits, check for time code
						rx_loop3: loop
							xor_val := spw_d xor spw_s;
							wait for v_period;		
							exit rx_loop3  when xor_val /= (spw_d xor spw_s);
						end loop rx_loop3;
						data_bits(i) := spw_d;											-- for 5th data bit
					end loop;
					
					if(data_bits(5) = '1') then											-- not a time code ?
						for i in 6 to 7 loop											-- get the rest of the packet
							rx_loop4: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop4  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop4;
							data_bits(i) := spw_d;
						end loop;	
						spw_char := get_spw_char(data_bits(7 downto 4));				-- output 
					else																-- is a time code ?
						spw_char := "TIM";												-- report TIME info packet
						for i in 6 to 13 loop											-- get the time code data...
							rx_loop5: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop5  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop5;
							data_bits(i) := spw_d;									
						end loop; 
						spw_time := data_bits(13 downto 6);								-- output timecode data 
					end if;
				
				when others =>
					spw_char := "BAD";
				
			end case;
		end if;
		
		spw_signals.raw 		<= data_bits;
		spw_signals.data 		<= spw_data;
		spw_signals.time_code 	<= spw_time;
		spw_signals.char		<= spw_char;
		spw_signals.parity		<= data_bits(0);

	end spw_get_poll;
	
	
	
	-- used to poll the SpW Channel. Outputs Debug data (via protected types)
	procedure spw_get_poll(
		variable spw_frame		: inout		t_spw_frame;
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 		natural							-- polling period (ns)
	)is 
		variable data_bits		: std_logic_vector(13 downto 0);			-- buffer to store data bits
		variable xor_val 		: std_logic	:= '0';							-- buffer to store XOR value of D/S
		variable v_period		: time 		:= period * 1 ns;				-- period to wait (ns)
		variable spw_char		: string(1 to 3);
		variable spw_data		: std_logic_vector(8 downto 0);
		variable spw_raw		: std_logic_vector(13 downto 0);
		variable spw_time		: std_logic_vector(7 downto 0);
		
	begin	
		data_bits 	:= (others => 'U');									-- manually buffers unknown (for debug)
		init: loop														-- wait around for first clock edge
			xor_val := spw_d xor spw_s;
			wait for v_period;
			exit init when xor_val /= (spw_d xor spw_s);		
		end loop init;
		
		data_bits(0) := spw_d;											-- load first bit from first clock edge (parity bit)
		
		for i in 1 to 3 loop											-- get the rest of the nibble
			rx_loop: loop
				xor_val := spw_d xor spw_s;
				wait for v_period;		
				exit rx_loop when xor_val /= (spw_d xor spw_s);
			end loop rx_loop;
			data_bits(i) := spw_d;
		end loop;
		
	
		if(data_bits(1) = '0') then													-- data SPW frame ?
			spw_char := "DAT";														-- report DATA info packet
			for i in 4 to 9 loop													-- repeat to get the rest of the fata frame (10 bits total. 6 more to go)
				rx_loop2: loop
					xor_val := spw_d xor spw_s;
					wait for v_period;	
					exit rx_loop2 when xor_val /= (spw_d xor spw_s);
				end loop rx_loop2;
				data_bits(i) := spw_d;
			end loop;
			spw_data(7 downto 0) := data_bits(9 downto 2);							-- assign output variable data bit
			spw_data(8)			 := data_bits(1);
		else																		-- else, Control SPW frame ?
		
			case(data_bits(3 downto 1)) is
				when c_SpW_FCT_code =>
					spw_char := "FCT";
					
				when c_SpW_EOP_code =>
					spw_char := "EOP";
				
				when c_SpW_EEP_code =>
					spw_char := "EEP";
				
				when c_SpW_ESC_code =>
					spw_char := "ESC";													-- output Escape character
	
					for i in 4 to 5 loop												-- read in next two bits, check for time code
						rx_loop3: loop
							xor_val := spw_d xor spw_s;
							wait for v_period;		
							exit rx_loop3  when xor_val /= (spw_d xor spw_s);
						end loop rx_loop3;
						data_bits(i) := spw_d;											-- for 5th data bit
					end loop;
					
					if(data_bits(5) = '1') then											-- not a time code ?
						for i in 6 to 7 loop											-- get the rest of the packet
							rx_loop4: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop4  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop4;
							data_bits(i) := spw_d;
						end loop;	
						spw_char := get_spw_char(data_bits(7 downto 4));				-- output 
					else																-- is a time code ?
						spw_char := "TIM";												-- report TIME info packet
						for i in 6 to 13 loop											-- get the time code data...
							rx_loop5: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop5  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop5;
							data_bits(i) := spw_d;									
						end loop; 
						spw_time := data_bits(13 downto 6);								-- output timecode data 
					end if;
				
				when others =>
					spw_char := "BAD";
				
			end case;
		end if;
		
		spw_frame.set_spw_char(spw_char);
		spw_frame.set_spw_data(spw_data);
		spw_frame.set_spw_time(spw_time);
		spw_frame.set_spw_parity(data_bits(0));
		spw_frame.set_raw_data(data_bits);													-- output raw spw data

	end spw_get_poll;
	
	-- used to poll the SpW Channel. Outputs Debug data (via signals)
	procedure spw_get_poll(
		signal spw_raw			: out 	std_logic_vector(13 downto 0);	-- raw packet received (defaults bits to unknown if not used)
		signal spw_data			: out 	std_logic_vector(8 downto 0);	-- data packet received (Con_bit & (7 downto 0))
		signal spw_time			: out 	std_logic_vector(7 downto 0);	-- space_wire timecode data received
		signal spw_char			: out 	string(1 to 3);					-- command nibble received
		signal spw_parity		: out 	std_logic;						-- parity bit output
		signal spw_d			: in 	std_logic;						-- spacewire data signal
		signal spw_s			: in 	std_logic;						-- spacewire strobe signal
		constant period		    : 		natural							-- polling period (ns)
	)is 
		variable data_bits		: std_logic_vector(13 downto 0);			-- buffer to store data bits
		variable xor_val 		: std_logic	:= '0';							-- buffer to store XOR value of D/S
		variable v_period		: time 		:= period * 1 ns;				-- period to wait (ns)
		
	begin	
		data_bits 	:= (others => 'U');									-- manually buffers unknown (for debug)
		init: loop														-- wait around for first clock edge
			xor_val := spw_d xor spw_s;
			wait for v_period;
			exit init when xor_val /= (spw_d xor spw_s);		
		end loop init;
		
		data_bits(0) := spw_d;											-- load first bit from first clock edge (parity bit)
		
		for i in 1 to 3 loop											-- get the rest of the nibble
			rx_loop: loop
				xor_val := spw_d xor spw_s;
				wait for v_period;		
				exit rx_loop when xor_val /= (spw_d xor spw_s);
			end loop rx_loop;
			data_bits(i) := spw_d;
		end loop;
		
	
		if(data_bits(1) = '0') then													-- data SPW frame ?
			spw_char <= "DAT";														-- report DATA info packet
			for i in 4 to 9 loop													-- repeat to get the rest of the fata frame (10 bits total. 6 more to go)
				rx_loop2: loop
					xor_val := spw_d xor spw_s;
					wait for v_period;	
					exit rx_loop2 when xor_val /= (spw_d xor spw_s);
				end loop rx_loop2;
				data_bits(i) := spw_d;
			end loop;
			spw_data(7 downto 0) <= data_bits(9 downto 2);							-- assign output variable data bit
			spw_data(8)			 <= data_bits(1);
		else																		-- else, Control SPW frame ?
		
			case(data_bits(3 downto 1)) is
				when c_SpW_FCT_code =>
					spw_char <= "FCT";
					
				when c_SpW_EOP_code =>
					spw_char <= "EOP";
				
				when c_SpW_EEP_code =>
					spw_char <= "EEP";
				
				when c_SpW_ESC_code =>
					spw_char <= "ESC";													-- output Escape character
	
					for i in 4 to 5 loop												-- read in next two bits, check for time code
						rx_loop3: loop
							xor_val := spw_d xor spw_s;
							wait for v_period;		
							exit rx_loop3  when xor_val /= (spw_d xor spw_s);
						end loop rx_loop3;
						data_bits(i) := spw_d;											-- for 5th data bit
					end loop;
					
					if(data_bits(5) = '1') then											-- not a time code ?
						for i in 6 to 7 loop											-- get the rest of the packet
							rx_loop4: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop4  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop4;
							data_bits(i) := spw_d;
						end loop;	
						spw_char <= get_spw_char(data_bits(7 downto 4));				-- output 
					else																-- is a time code ?
						spw_char <= "TIM";												-- report TIME info packet
						for i in 6 to 13 loop											-- get the time code data...
							rx_loop5: loop
								xor_val := spw_d xor spw_s;
								wait for v_period;		
								exit rx_loop5  when xor_val /= (spw_d xor spw_s);
							end loop rx_loop5;
							data_bits(i) := spw_d;									
						end loop; 
						spw_time <= data_bits(13 downto 6);								-- output timecode data 
					end if;
				
				when others =>
					spw_char <= "BAD";
				
			end case;
		end if;
		spw_parity <= data_bits(0);
		spw_raw <= data_bits;														-- output raw spw data

	end spw_get_poll;
	
	procedure wait_clocks(
		constant clk_period		: time;			-- clock period
		variable clk_num		: natural		-- number of clocks to wait for 
	) is
	begin
		for i in 0 to clk_num-1 loop			-- create for loop in range
			wait for clk_period;				-- wait for clk_period
		end loop;								-- end loop, will exit once all iterations complete
	end wait_clocks;	

	-- send header bytes via AXI handshake 
	procedure send_header_bytes(
		signal assert_target 	: out 	std_logic;
		signal axi_rdata  		: out 	t_byte;				-- axi read data 
		signal axi_rvalid 		: out	std_logic;			-- axi read valid
		signal axi_rready		: in 	std_logic;			-- axi read ready
		variable rmap_data 		: inout t_rmap_command	-- protected type containing RMAP header data 
	) is
	begin
		if(rmap_data.has_paths = true) then						-- has paths ? is ignored if false. 
			assert_target <= '1';
			for j in 0 to rmap_data.get_path_size-1 loop			-- loop for each path byte 
				axi_rdata <= rmap_data.get_path_byte(j);		-- set output to path byte 
				axi_rvalid <= '0';								-- keep valid de-asserted
				if(axi_rready = '0') then						-- is axi not ready ?
					wait until axi_rready = '1';				-- wait until ready 
				end if;
				axi_rvalid <= '1';								-- assert valid once ready 
				wait until axi_rready = '0';					-- wait until ready is de-asserted
			end loop;
			axi_rvalid <= '0';		
		end if;
		assert_target <= '0';
		for i in 0 to (rmap_data.get_header_size)-1 loop		-- loop around for all bytes in header 
			axi_rdata <= rmap_data.get_header_byte(i);			-- set output to header byte 
			axi_rvalid <= '0';									-- keep valid de-asserted
			if(axi_rready = '0') then							-- is axi not ready ?
				wait until axi_rready = '1';					-- wait until ready 
			end if;	
			axi_rvalid <= '1';									-- assert valid once ready 
			wait until axi_rready = '0';						-- wait until ready is de-asserted
		end loop;	
		axi_rvalid <= '0';										-- keep valid de-asserted on end of loop. 
	end procedure send_header_bytes;
	
	-- send data bytes via AXI handshake 
	procedure send_data_bytes(						
		signal axi_rdata  : out 	t_byte;						-- axi read data 
		signal axi_rvalid : out		std_logic;          		-- axi read valid
		signal axi_rready : in 		std_logic;          		-- axi read ready
		variable rmap_data : inout 	t_rmap_command 				-- protected type containing RMAP header data
	) is	
	begin	
		for i in 0 to (rmap_data.get_data_size)-1 loop			-- loop around for all bytes in data frame 
			axi_rdata <= rmap_data.get_data_byte(i);     		-- set output to data byte 
			axi_rvalid <= '0';                          		-- keep valid de-asserted
			if(axi_rready = '0') then                   		-- is axi not ready ?
				wait until axi_rready = '1';            		-- wait until ready 
			end if;   		
			axi_rvalid <= '1';                          		-- assert valid once ready 
			if(axi_rready = '1') then
				wait until axi_rready = '0';                		-- wait until ready is de-asserted
			end if;
		end loop;                                       		
		axi_rvalid <= '0';                              		-- keep valid de-asserted on end of loop.
	
	end procedure send_data_bytes;
	
	-- get rmap reply header bytes 
	procedure get_header_bytes(
		signal axi_rdata  : in t_byte;
		signal axi_rvalid : in std_logic;
		signal axi_rready : out std_logic;
		variable rmap_data : inout t_rmap_reply_pattern
	) is
		variable byte_counter : natural;
	begin
		addr_loop: loop
			axi_rready <= '1';
			if(axi_rvalid = '0') then
				wait until axi_rvalid = '1';
			end if;
			rmap_data.write_header_byte(axi_rdata, byte_counter);
			byte_counter := byte_counter + 1;
			axi_rready <= '0';
			exit addr_loop when axi_rdata(7 downto 0) /= "000";
		end loop addr_loop;
		
		
	end procedure;
	
	
	procedure send_rmap_frame(
		signal 	wr_header		: out 	t_byte;
		signal  wr_header_valid : out 	std_logic;
		signal 	wr_header_ready : in 	std_logic;
		signal  wr_data			: out 	t_byte;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame
	)is
		variable header_size : integer := 0;
		variable data_size 	: integer := 0;
	begin
		rmap_frame.create_rmap_header;
		rmap_frame.create_rmap_frame;
		header_size := rmap_frame.get_header_size;	-- get length of header
		data_size 	:= rmap_frame.get_data_size;	-- get length of data payload 
		
		wr_header_valid <= '0';
		wr_data_valid <= '0';
		
		for i in 0 to header_size-1 loop
			wr_header <= rmap_frame.get_frame_byte(i);
			if(wr_header_ready = '0') then
				wait until wr_header_ready = '1';
			end if;
			wr_header_valid <= '1';
			if(wr_header_ready = '1') then
				wait until wr_header_ready = '0';
			end if;
			wr_header_valid <= '0';
		end loop;
		
		for i in header_size to (header_size + data_size)-1 loop
			wr_data <= rmap_frame.get_frame_byte(i);
			if(wr_data_ready = '0') then
				wait until wr_data_ready = '1';
			end if;
			wr_data_valid <= '1';
			if(wr_data_ready = '1') then
				wait until wr_data_ready = '0';
			end if;
			wr_data_valid <= '0';
		end loop;
	
	end procedure send_rmap_frame;
	
	-- used to send RMAP directly over SpaceWire IP with no RMAP Initiator
	procedure send_rmap_frame_raw(
		signal  wr_data			: out 	t_nonet;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame
	) is
		variable frame_size : integer;
	begin
		rmap_frame.create_rmap_frame_full;
		wr_data 		<= (others => '0');
		wr_data_valid 	<= '0';
		frame_size := rmap_frame.get_frame_size;
		-- send frame data 
		for i in 0 to frame_size-1 loop
			wr_data(7 downto 0) <= rmap_frame.get_frame_byte(i);
			if(wr_data_ready = '0') then
				wait until wr_data_ready = '1';
			end if;
			wr_data_valid <= '1';
			if(wr_data_ready = '1') then
				wait until wr_data_ready = '0';
			end if;
			wr_data_valid <= '0';
		end loop;
		
		-- append EOP to data stream 
		wr_data <= b"1_0000_0010";		-- put EOP on interface 
		if(wr_data_ready = '0') then
			wait until wr_data_ready = '1';
		end if;
		wr_data_valid <= '1';
		if(wr_data_ready = '1') then
			wait until wr_data_ready = '0';
		end if;
		wr_data_valid <= '0';
		
	end procedure send_rmap_frame_raw;
	
	
	procedure send_rmap_frame_array(
		variable channel 		: in integer;
		signal 	wr_header		: out 	t_byte;
		signal  wr_header_valid : out 	std_logic;
		signal 	wr_header_ready : in 	std_logic;
		signal  wr_data			: out 	t_byte;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame_array
	)is
		variable header_size : integer := 0;
		variable data_size 	: integer := 0;
	begin
		rmap_frame.create_rmap_header(channel);
		rmap_frame.create_rmap_frame(channel);
		header_size := rmap_frame.get_header_size(channel);	-- get length of header
		data_size 	:= rmap_frame.get_data_size(channel);	-- get length of data payload 
		
		wr_header_valid <= '0';
		wr_data_valid <= '0';
		
		for i in 0 to header_size-1 loop
			wr_header <= rmap_frame.get_frame_byte(channel,i);
			if(wr_header_ready = '0') then
				wait until wr_header_ready = '1';
			end if;
			wr_header_valid <= '1';
			if(wr_header_ready = '1') then
				wait until wr_header_ready = '0';
			end if;
			wr_header_valid <= '0';
		end loop;
		if(rmap_frame.get_rw(channel) = "write") then
			for i in header_size to (header_size + data_size)-1 loop
				wr_data <= rmap_frame.get_frame_byte(channel, i);
				if(wr_data_ready = '0') then
					wait until wr_data_ready = '1';
				end if;
				wr_data_valid <= '1';
				if(wr_data_ready = '1') then
					wait until wr_data_ready = '0';
				end if;
				wr_data_valid <= '0';
			end loop;
		end if;
	end procedure send_rmap_frame_array;
	
	-- used to send RMAP directly over SpaceWire IP with no RMAP Initiator
	procedure send_rmap_frame_raw_array(
		variable channel 		: in integer;
		signal  wr_data			: out 	t_nonet;
		signal  wr_data_valid   : out 	std_logic;
		signal  wr_data_ready	: in 	std_logic;
		variable rmap_frame		: inout t_rmap_frame_array
	) is
		variable frame_size : integer;
	begin
		rmap_frame.create_rmap_header(channel);
		rmap_frame.create_rmap_frame_full(channel);
		wr_data 		<= (others => '0');
		wr_data_valid 	<= '0';
		frame_size := rmap_frame.get_frame_size(channel);
		-- send frame data 
		for i in 0 to frame_size-1 loop
			wr_data(7 downto 0) <= rmap_frame.get_frame_byte(channel, i);
			if(wr_data_ready = '0') then
				wait until wr_data_ready = '1';
			end if;
			wr_data_valid <= '1';
			if(wr_data_ready = '1') then
				wait until wr_data_ready = '0';
			end if;
			wr_data_valid <= '0';
		end loop;
		
		-- append EOP to data stream 
		wr_data <= b"1_0000_0010";		-- put EOP on interface 
		if(wr_data_ready = '0') then
			wait until wr_data_ready = '1';
		end if;
		wr_data_valid <= '1';
		if(wr_data_ready = '1') then
			wait until wr_data_ready = '0';
		end if;
		wr_data_valid <= '0';
		wr_data <= b"0_0000_0000";		-- put EOP on interface 
		
	end procedure send_rmap_frame_raw_array;
	
	-- not yet implemented...
	procedure rmap_rd_buffer_raw(
		variable	channel 		: in integer;
		signal		rx_data 		: in t_nonet;
		signal		rx_data_valid 	: in std_logic;
		signal		rx_data_ready 	: out std_logic;
		signal		bool			: out boolean;
		variable	rmap_frame 		: inout t_rmap_frame_array
		
	) is
		variable frame_size : integer;
		variable data_buf   : t_byte;
		variable v_bool 	: boolean;
		variable v_count	: integer;
	begin
		bool <= false;
		frame_size := rmap_frame.get_frame_size(channel);
		L1:	for i in 0 to frame_size-1 loop
			v_count := i;
			rx_data_ready <= '1';
			if(rx_data_valid = '0') then
				wait until rx_data_valid = '1';
			end if;
			data_buf := rx_data(7 downto 0);
			v_bool := rmap_frame.check_response(channel, i, data_buf);
			if(rx_data_valid = '1') then
				wait until rx_data_valid = '0';
			end if;
			exit L1 when v_bool = false;
		end loop L1;
		rx_data_ready <= '0';
		
		if(v_count /= frame_size-1) then	-- exit before full frame could be read ?
			report "mismatch @ " & to_string(v_count) &  "in channel : "& to_string(channel) severity failure;
		else
			report "frame OKAY" severity note;
			bool <= true;
		end if;
	
	end procedure rmap_rd_buffer_raw;
	

end package body SpaceWire_Sim_lib;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------
