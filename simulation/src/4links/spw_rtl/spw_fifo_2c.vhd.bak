----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:
-- @ Engineer				:	James E Logan
-- @ Role					:	
-- @ Company				:	
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

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity spw_fifo_2c is
	generic(
        constant fifo_size : integer := 24 --IGNORED
	);
	port( 
		-- FIFO control signals
        clear               : in    boolean;
         -- FIFO data input signals
        In_clock            : in    std_logic;
		In_reset            : in    std_logic;

        Din                 : in    nonet;
        Din_OR              : in    boolean;
        Din_IR              : out 	boolean;

		-- FIFO data output signals
        Out_clock           : in    std_logic;
 		Out_reset           : in    std_logic;
		
        Dout                : out 	nonet;
        Dout_IR             : in    boolean;
        Dout_OR             : out 	boolean
    );
end spw_fifo_2c;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of spw_fifo_2c is

	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type mem_type is array ( 2047 downto 0 ) of nonet;
	
	-- shared variable MUST use protected type for true modeling (VHDL 2008 Onwards)
 /*   type mem_prot_t is protected						-- create protected type for memory and memory operations
        procedure write_mem(						-- procedure to WRITE to memory
			signal    addr		: in 	integer;	-- Write address	
			signal    wr_data	: in 	nonet		-- data to write to memory
        );
        
        procedure read_mem(							-- procedure to READ from memory
			signal    addr		: in  	integer;	-- Read address
			signal    rd_data	: out 	nonet		-- data read from memory
        );
    
    end protected mem_prot_t;	
	
    type mem_prot_t is protected body					-- protected type body
        variable mem : mem_type;					-- instantiate variable as memory. 
        
        procedure write_mem(						-- write_memory procedure body
            signal    addr    	: in	integer;
            signal    wr_data	: in 	nonet
        )is
        
        begin
            mem(addr) := wr_data;					-- assign memory @ address to write data
        end procedure write_mem;
        
        procedure read_mem(
            signal    addr      : in 	integer;
            signal    rd_data   : out 	nonet
        ) is      
        begin
            rd_data <= mem(addr);					-- assign rd_data to memory @ address;
        end procedure read_mem;
        
    end protected body mem_prot_t; */

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
/*	signal wr_en         : std_logic                	:= '0';
  
	signal WA            : integer range 0 to 2047;--  	:= 0;
	signal WAd           : integer range 0 to 2047;--  	:= 0;
	signal next_WA       : integer range 0 to 2047		:= 0;
	
	signal RA            : integer range 0 to 2047;--  	:= 0;
	signal next_RA       : integer range 0 to 2047;
	
	signal OE            : boolean;--                  	:= false;
	
	signal Din_reg		 : t_nonet := (others => '0');
	signal Clear_reg	 : boolean;
	signal Din_OR_reg	 : boolean;
	signal next_WA_reg   : integer range 0 to 2047;--  	:= 0;
	signal RA_reg		 : integer range 0 to 2047;--  	:= 0;
*/
	signal memory			: t_nonet_array(0 to 31);
	signal wr_ptr			: unsigned(4 downto 0);
	signal rd_ptr			: unsigned(4 downto 0);
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- declare shared variable as PROTECTED type if supported  
	-- shared variable sv_mem : mem_prot_t;		-- see work.ip4l_data_types for mem_prot_t decleration	
--	shared variable mem : mem_type;
	
	
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
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Instantiations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
--	next_WA 	<= (WA + 1) mod 2048;
--  Din_IR  	<= not Clear and next_WA /= RA;
--  wr_en   	<= '1' when not Clear and Din_OR and next_WA /= RA else '0';
--	next_RA 	<= (RA + 1) mod 2048;
--  Dout_OR  	<= not clear and OE and WAd /= RA;
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	

--   process(In_clock)
--	--	variable v_next_WA : natural range 0 to 2047 := 0;
--   begin 
--		if rising_edge(In_clock) then
--			next_WA <= (WA + 1) mod 2048;
--			if (In_reset = '1' or clear = true) then
--				WA <= 0;
--				next_WA <= 1;
--				WAd <= 0;
--           else
--				Wad <= WA;
--				if Din_OR and next_WA /= RA then
--					WA <= next_WA;
--				end if;
--			end if;
--		end if;
--		--next_WA <= v_next_WA;
--   end process;
--	
--	process(Out_clock)
--   begin
--		if rising_edge(Out_clock) then
--			next_RA 	<= (RA + 1) mod 2048;
--			OE <= true;
--			if OE and Dout_IR and WAd /= RA then
--				RA <= next_RA;
--				OE <= false;
--			end if;
--			
--			if clear = true or Out_reset = '1' then
--				RA <= 0;
--				next_RA <= 1;
--				OE <= false;
--			end if;
--		
--     end if;
--   end process;
--	
--	-- Dual Port RAM inference, contents not cleared by reset
--
--	-- Port A
--	process(In_clock)
--	begin
--		if rising_edge (In_clock) then
--		--	wr_en <= '0';
--		--	if(Clear_reg = false and Din_OR_reg = true and next_WA_reg /= RA_reg) then
--		--		wr_en   	<= '1';
--		--	end if;
--			
--			if(Clear = false and Din_OR = true /* and next_WA /= RA */) then
--				mem(WA) := Din;
--			end if;
--		end if;
--	end process;
--	 
--	-- Port B
--	process(Out_clock)
--	begin
--		if rising_edge(Out_clock) then
--			Dout <= mem(RA);
--		end if;
--	end process;
	

	
	wr_proc: process(In_clock)
	begin
		if(rising_edge(In_clock)) then 
			if(clear = true or In_reset = '1') then 
				wr_ptr 	<= (others => '0');
				Din_IR	<= false;
			else
				Din_IR <= true;
				if(wr_ptr+1 = rd_ptr) then 
					Din_IR <= false;
				end if;
				
				if(Din_IR and Din_OR) then 
					wr_ptr <= wr_ptr + 1;
					Din_IR <= true;
					if(wr_ptr+2 = rd_ptr) then 
						Din_IR <= false;
					end if;
				end if;
			
				memory(to_integer(wr_ptr)) <= Din;
				
			end if;
		
		end if;
	end process;
	
	
	rd_proc: process(In_clock)
	begin
		if(rising_edge(In_clock)) then 
			if(clear = true or In_reset = '1') then 
				rd_ptr 	<= (others => '0');
				Dout_OR <= false;
			else
				
				Dout_OR <= false;
				if(rd_ptr /= wr_ptr) then 
					Dout_OR <= true;
				end if;
				
				Dout <= memory(to_integer(rd_ptr));
				
				if(Dout_IR and Dout_OR) then 
				
					rd_ptr 	<= rd_ptr + 1;
					Dout 	<= memory(to_integer(rd_ptr+1));
					
					Dout_OR <= false;
					if(rd_ptr+1 /= wr_ptr) then 
						Dout_OR <= true;
					end if;
					
				end if;
			
			end if;
			
		end if;
	end process;
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------


end rtl;