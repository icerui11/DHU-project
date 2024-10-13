----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	spw_data_types.vhd
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


package spw_data_types is

	--------------------------------------------------------------------------------------------------------------------------
	-- Global config constants -- 
	--------------------------------------------------------------------------------------------------------------------------
	constant c_num_edges : positive := 4; -- multiple of 2, default is 4, max recommended is 8.  Always Multipe of 2. 
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Declarations --
	--------------------------------------------------------------------------------------------------------------------------

	subtype t_edges 		is 	std_logic_vector(c_num_edges-1 downto 0);
	subtype t_bin_counts 	is natural range 0 to 2;
	
	subtype t_binary		is std_logic_vector(1 downto 0);
	subtype t_triple		is std_logic_vector(2 downto 0);
	subtype t_nibble 		is std_logic_vector(3 downto 0);
	subtype t_pentabit		is std_logic_vector(4 downto 0);
	subtype t_hexbit 		is std_logic_vector(5 downto 0);
	subtype t_byte 			is std_logic_vector(7 downto 0);
	subtype t_nonet			is std_logic_vector(8 downto 0);
	subtype t_dword			is std_logic_vector(31 downto 0);
	
	type t_edges_array		is array (natural range <>) of t_edges;
	
	type t_binary_array		is array (natural range <>) of t_binary;
	type t_nibble_array		is array (natural range <>) of t_nibble;
	type t_pentabit_array	is array (natural range <>) of t_pentabit;
	type t_hexbit_array		is array (natural range <>) of t_hexbit;
	type t_byte_array		is array (natural range <>) of t_byte;
	type t_nonet_array 		is array (natural range <>) of t_nonet;
	type t_dword_array 		is array (natural range <>) of t_dword;
	
	type t_bin_counts_arr 	is array (natural range <>) of t_bin_counts;
	
	type t_integer_array	is array (natural range <>) of integer;
	type t_integer_array_256 is array (natural range <>) of integer range 0 to 255;
	
	type t_byte_array_3d is array (natural range <>) of t_byte_array;
	type t_int_array_3d is array (natural range <>) of t_integer_array;
	type t_bool_array is array (natural range <>) of boolean;
	
	
	-- legacy data types 
	subtype nonet is std_logic_vector(8 downto 0);
	subtype octet is std_logic_vector(7 downto 0);
	subtype long  is std_logic_vector(31 downto 0);
	
	type nonet_array 	is array (natural range <>) of nonet;
	type octet_array 	is array (natural range <>) of octet;
	type long_array		is array (natural range <>) of long;

	--------------------------------------------------------------------------------------------------------------------------
	-- Subtype & Type Constants --
	--------------------------------------------------------------------------------------------------------------------------

	
	--------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	--------------------------------------------------------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Records	Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	type r_codec_interface is record
	-- Channels
		Tx_data         : 	t_nonet;
		Tx_OR           : 	std_logic;
		Tx_IR           : 	std_logic;

		Rx_data         : 	t_nonet;
		Rx_OR           : 	std_logic;
		Rx_IR           : 	std_logic;

		Rx_ESC_ESC      : 	std_logic;
		Rx_ESC_EOP      : 	std_logic;
		Rx_ESC_EEP      : 	std_logic;
		Rx_Parity_error : 	std_logic;
		Rx_bits         : 	std_logic_vector(1 downto 0);
		Rx_rate         : 	std_logic_vector(15 downto 0);

		Rx_Time         : 	t_byte;
		Rx_Time_OR      : 	std_logic;
		Rx_Time_IR      : 	std_logic;

		Tx_Time         : 	t_byte;
		Tx_Time_OR      : 	std_logic;
		Tx_Time_IR      : 	std_logic;

		-- Contol	
		Disable         : 	std_logic;
		Connected       : 	std_logic;
		Error_select    : 	std_logic_vector(3 downto 0);
		Error_inject    : 	std_logic;
		
		-- DDR/SDR IO, only when "custom" mode is used
		-- when instantiating, if not used, you can ignore these ports. 
		DDR_din_r		: 	std_logic;
		DDR_din_f   	: 	std_logic;
		DDR_sin_r   	: 	std_logic;
		DDR_sin_f   	: 	std_logic;
		SDR_Dout		:  	std_logic;
		SDR_Sout		:  	std_logic;
		
		-- SpW	
		Din_p    		:  	std_logic;
		Din_n    		:  	std_logic;
		Sin_p    		:  	std_logic;
		Sin_n    		:  	std_logic;
		Dout_p   		: 	std_logic;
		Dout_n   		: 	std_logic;
		Sout_p   		:	std_logic;
		Sout_n   		: 	std_logic;
	
	end record r_codec_interface;
	
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Record Init Constant Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	constant c_codec_interface : r_codec_interface :=(
		Tx_data   			=>	(others => '0')		,		      
		Tx_OR               =>	'0'			        ,
		Tx_IR               =>	'0'			        ,
		Rx_data             =>	(others => '0')		,		
		Rx_OR               =>	'0'					,	
		Rx_IR               =>	'0'					,	
		Rx_ESC_ESC          =>	'0'			        ,
		Rx_ESC_EOP          =>	'0'			        ,
		Rx_ESC_EEP          =>	'0'			        ,
		Rx_Parity_error     =>	'0'			        ,
		Rx_bits             =>	(others => '0')		,	
		Rx_rate             =>	(others => '0')		,	
		Rx_Time             =>	(others => '0')		,		
		Rx_Time_OR          =>	'0'					,	
		Rx_Time_IR          =>	'0'					,	
		Tx_Time             =>	(others => '0')		,		
		Tx_Time_OR          =>	'0'					,	
		Tx_Time_IR          =>	'0'					,	
		Disable             =>	'0'		            ,
		Connected           =>	'0'			        ,
		Error_select        =>	(others => '0')		,	
		Error_inject        =>	'0'			        ,
		DDR_din_r		    =>	'0'			        ,
		DDR_din_f   	    =>	'0'			        ,
		DDR_sin_r   	    =>	'0'			        ,
		DDR_sin_f   	    =>	'0'			        ,
		SDR_Dout		    =>	'0'			        ,
		SDR_Sout		    =>	'0'			        ,
		Din_p    		    =>	'0'			        ,
		Din_n    		    =>	'0'			        ,
		Sin_p    		    =>	'0'			        ,
		Sin_n    		    =>	'0'			        ,
		Dout_p   		    =>	'0'			        ,
		Dout_n   		    =>	'0'			        ,
		Sout_p   		    =>	'0'			        ,
		Sout_n   		    =>	'0'			
	
	);
	
	type r_codec_interface_array is array (natural range <>) of r_codec_interface;
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	function bitrev ( A : in std_logic_vector ) return std_logic_vector;
	
	function shr ( X : in std_logic; V : in std_logic_vector; N : in natural ) return std_logic_vector;
	function shr ( X : in std_logic_vector; V : in std_logic_vector ) return std_logic_vector;
	function shr ( X : in std_logic; V : in std_logic_vector ) return std_logic_vector;
	
	function int_to_byte_array(int_arr : t_integer_array_256) return t_byte_array;
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Prototype Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	

	
end package spw_data_types;

package body spw_data_types is 
	
	--------------------------------------------------------------------------------------------------------------------------
	--	Function Body Declerations  --
	--------------------------------------------------------------------------------------------------------------------------
	function bitrev ( A : in std_logic_vector ) return std_logic_vector is
		variable r : std_logic_vector(A'range);
	begin
		for i in A'range loop
			r(i) := A(A'high + A'low - i);
		end loop;
		return r;
	end function;
	
	function shr ( X : in std_logic; V : in std_logic_vector; N : in natural ) return std_logic_vector is
		variable r : std_logic_vector( V'high downto V'low );
	begin
		r( r'high downto r'high-N+1                       ) := ( others => X );
		r(                          r'high-N downto r'low ) :=               V(V'high downto V'low+N);
		return r;
    end function;


	function shr ( X : in std_logic; V : in std_logic_vector ) return std_logic_vector is
		variable r : std_logic_vector( V'high downto V'low );
	begin
		r( r'high                       ) := X;
		r(        r'high-1 downto r'low ) :=  V(V'high downto V'low+1);
		return r;
	end function;


	function shr ( X : in std_logic_vector; V : in std_logic_vector ) return std_logic_vector is
		variable N : natural := X'high - X'low + 1;
		variable r : std_logic_vector( V'high downto V'low );
    begin
      r( r'high downto r'high-N+1                       ) := X;
      r(                          r'high-N downto r'low ) :=   V(V'high downto V'low+N);
      return r;
    end function;
	
	-- convert an array of integers (values 0 to 255) to Bytes 
	function int_to_byte_array(int_arr : t_integer_array_256) return t_byte_array is
		variable bytes : t_byte_array(0 to int_arr'length-1);
	begin
		for i in 0 to int_arr'length-1 loop
			bytes(i) := std_logic_vector(to_unsigned(int_arr(i), 8));
		end loop;
		return bytes;
	end function;
	--------------------------------------------------------------------------------------------------------------------------
	--	Procedure Body Declerations --
	--------------------------------------------------------------------------------------------------------------------------
	

	

end package body spw_data_types;

--------------------------------------------------------------------------------------------------------------------------
--	END OF FILE --
--------------------------------------------------------------------------------------------------------------------------