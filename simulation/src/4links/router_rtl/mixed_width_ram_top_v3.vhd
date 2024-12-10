----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	mixed_width_ram.vhd
-- @ Engineer				:	James E Logan
-- @ Role					:	FPGA Engineer
-- @ Company				:	4Links ltd
-- @ Date					: 	dd/mm/yyyy

-- @ VHDL Version			:   1987, 1993, 2008
-- @ Supported Toolchain	:	Xilinx Vivado IDE
-- @ Target Device			: 	Xilinx US+ Family

-- @ Revision #				:	2

-- File Description         : 	implemented mixed-width ram, modified for use with RMAP router for routing table memeory 

-- Document Number			:  	xxx-xxxx-xxx
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
context work.router_context;
----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity mixed_width_ram is
	port( 
		
		-- standard register control signals --
		clk_in	: in 	std_logic := '0';										-- clk input, rising edge trigger
		
		rst_in  : in 	std_logic := '0';										-- reset input, active high
		wr_en	: in 	std_logic 						:= '0';					-- assert to enable write 
		r_addr 	: in 	std_logic_vector(7 downto 0) 	:= (others => '0');		-- 0 to 255
		w_addr 	: in 	std_logic_vector(9 downto 0)	:= (others => '0'); 	-- 0 to 1023
		
		
		w_data	: in	std_logic_vector(7 downto 0)	:= (others => '0');		-- write bytes
		r_data	: out 	std_logic_vector(31 downto 0)	:= (others => '0')	   	-- read dwords

    );
end mixed_width_ram;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of mixed_width_ram is

 --   attribute ram_style : string;
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	function ret_ratio(int_1 : integer; int_2 : integer) return integer is 
		variable retval : integer;
	begin
		if(int_1 > int_2) then
			retval := int_1/int_2;
		else
			retval := int_2/int_1;
		end if;
		return retval;
	end function ret_ratio;
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	constant c_ratio : integer := ret_ratio(r_data'length, w_data'length);	-- r_data must be larger than w_data. Ratio best if power of 2
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_byte_ram is array (natural range <> ) of std_logic_vector(7 downto 0);

	function init_router_mem (ram_depth : integer) return t_byte_ram is
		variable ratio : integer := 4;
		variable v_counter : integer range 1 to c_num_ports-1 := 1;
		variable v_ram : t_byte_ram(0 to (ram_depth*ratio)-1);
		Variable element : std_logic_vector(31 downto 0) := (others => '0');
	begin
		v_ram(0) := (0 => '1', others => '0');
		v_ram(1) := (others => '0');
		v_ram(2) := (others => '0');
		v_ram(3) := (others => '0');
		for i in 1 to ram_depth-1 loop
			element := (others => '0');
			element(v_counter) := '1';
			if(v_counter = c_num_ports-1) then
				v_counter := 1;
			else
				v_counter := (v_counter + 1);
			end if;
			
			for j in 0 to ratio-1 loop
				v_ram(j+(ratio*i)) := element(((8*(j+1))-1) downto (8*j));
			end loop;
		
		end loop;
		
		return v_ram;
	end function;

	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal r_addr_int 	: integer range 0 to (2**r_addr'length)-1 := 0;
	signal w_addr_int	: integer range 0 to (2**w_addr'length)-1 := 0;	
	signal s_ram 		: t_byte_ram(0 to (2**w_addr'length)-1) := init_router_mem(256);
	signal rd_conn      : t_byte_ram(0 to 3);
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------

	
	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
--	attribute ram_style of s_ram : signal is "block";
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	r_addr_int <= to_integer(unsigned(r_addr));
	w_addr_int <= to_integer(unsigned(w_addr));
	r_data(7 downto 0) <= rd_conn(0);
	r_data(15 downto 8) <= rd_conn(1);
	r_data(23 downto 16) <= rd_conn(2);
	r_data(31 downto 24) <= rd_conn(3);
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	ram_proc: process(clk_in)
	variable ram_index : integer range 0 to 255 := 0;
	--variable init_done : std_logic := '0';
	variable row       : integer range 0 to 3 := 0;
	begin
		if(rising_edge(clk_in)) then
			if rst_in = '1' then
	--			if init_done = '0' then
					if ram_index < 255 then
						for i in 0 to 3 loop                  
						   s_ram(ram_index*4+i) <= init_router_mem(ram_index)(8*(i+1)-1 downto 8*i);
						end loop;
						ram_index := ram_index + 1;
					elsif ram_index = 255 then
	--					init_done := '1';
						for i in 0 to 3 loop                  
							s_ram(ram_index*4+i) <= init_router_mem(ram_index)(8*(i+1)-1 downto 8*i);
						 end loop;
						ram_index := ram_index + 1;
					end if;
	--			end if;
			else
				if(wr_en = '1') then
					s_ram(w_addr_int) <= w_data;
				end if;
				for i in 0 to c_ratio-1 loop
					rd_conn(i) <= s_ram((r_addr_int*c_ratio)+i);
				end loop;
			end if;
		end if;
	
	end process;


end rtl;