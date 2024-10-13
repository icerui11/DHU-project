----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	dp_fifo_buffer
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

----------------------------------------------------------------------------------------------------------------------------------
-- Entity Declarations --
----------------------------------------------------------------------------------------------------------------------------------
entity dp_fifo_buffer is
	generic(
		g_data_width	: natural 	:= 8;
		g_addr_width	: natural 	:= 8;
		g_ram_style		: string	:= "auto"
	);
	port( 
		
		-- standard register control signals --
		wr_clk_in		: 	in 		std_logic 									:= '0';				-- write clk input, rising edge trigger
		rd_clk_in		: 	in 		std_logic 									:= '0';				-- read clk input, rising edge trigger
		wr_rst_in		: 	in 		std_logic 									:= '0';				-- reset input, active high hold for several clock cycles of both wr and rd
		rd_rst_in		: 	in 		std_logic 									:= '0';				-- reset input, active high hold for several clock cycles of both wr and rd
		
		-- FiFO buffer Wr/Rd Interface --
		FIFO_wr_data	: 	in 		std_logic_vector(g_data_width-1 downto 0) 	:= (others => '0');
		FIFO_wr_valid	:   in 		std_logic 									:= '0';
		FIFO_wr_ready	: 	out		std_logic  									:= '0';
		
		FIFO_rd_data	: 	out 	std_logic_vector(g_data_width-1 downto 0) 	:= (others => '0');
		FIFO_rd_valid	:   out  	std_logic 									:= '0';
		FIFO_rd_ready	: 	in  	std_logic  									:= '0';

		full			: 	out 	std_logic 									:= '0';				-- asserted when Fifo is Full (Write Clock Domain)
		empty			: 	out 	std_logic 									:= '0'				-- asserted when Fifo is Empty (Read Clock Domain)
		
    );
end dp_fifo_buffer;


---------------------------------------------------------------------------------------------------------------------------------
-- Code Description & Developer Notes --
---------------------------------------------------------------------------------------------------------------------------------


architecture rtl of dp_fifo_buffer is
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Constant Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Type Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	type t_ram is array (natural range <>) of std_logic_vector(g_data_width-1 downto 0);	-- create our memory array type 
	----------------------------------------------------------------------------------------------------------------------------
	-- Function Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Component Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Signal Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	signal wr_cnt_en        : std_logic := '0';
	signal rd_cnt_en        : std_logic := '0';
	signal wr_p_rdy			: std_logic := '0';
	signal rd_p_rdy			: std_logic := '0';
	signal wr_pointer 		: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	signal wr_pointer_reg 	: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	signal next_wr_pointer 	: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	signal rd_pointer 		: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	signal rd_pointer_reg 	: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	signal next_rd_pointer 	: std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
	----------------------------------------------------------------------------------------------------------------------------
	-- Variable Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	shared variable s_ram : t_ram(0 to (2**g_addr_width)-1) := (others => (others => '0'));	-- create shared RAM signal 
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Attribute Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	attribute ram_style 	: string;	-- Vivado
	attribute ramstyle 		: string;	-- Quartus
	attribute syn_ramstyle 	: string;	-- Libero

	attribute ram_style 	of s_ram : variable is g_ram_style;		-- declare ram style (Vivado synthesis attribute)
	attribute ramstyle		of s_ram : variable is g_ram_style;		-- declare ram style (Quartus synthesis attribute)
	attribute syn_ramstyle	of s_ram : variable is g_ram_style;		-- declare ram style (Libero synthesis attribute)
	
begin

	----------------------------------------------------------------------------------------------------------------------------
	-- Entity Declarations --
	----------------------------------------------------------------------------------------------------------------------------
	-- gray counters used for read/write pointers 
	wr_cnt_inst: entity work.fifo_gray_counter(rtl)
	generic map(
		g_count_size => g_addr_width
	)
	port map(
		clk		   =>	wr_clk_in,
		reset	   => 	wr_rst_in,
		enable	   =>   wr_cnt_en,
		gray_count => 	wr_pointer,
		gray_count_next => next_wr_pointer
	);
	
	rd_cnt_inst: entity work.fifo_gray_counter(rtl)
	generic map(
		g_count_size => g_addr_width
	)
	port map(
		clk		   =>	rd_clk_in,
		reset	   => 	rd_rst_in,
		enable	   =>   rd_cnt_en,
		gray_count => 	rd_pointer,
		gray_count_next => next_rd_pointer
	);
	
	
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Asynchronous Signal Assignments --
	----------------------------------------------------------------------------------------------------------------------------
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Synchronous Processes --
	----------------------------------------------------------------------------------------------------------------------------
	-- Write Clock Domain Process
	wr_proc: process(wr_clk_in)
	begin
		if(rising_edge(wr_clk_in)) then
			wr_cnt_en <= '0';
			FIFO_wr_ready <= '0';
			rd_pointer_reg <= rd_pointer;	-- register Read pointer
			if(wr_rst_in = '1') then
				full <= '1';	
			else
				full <= '0';														-- default full to '0';
				if(next_wr_pointer = rd_pointer_reg) then							-- next write pointer is rd pointer ?
					full <= '1';													-- fifo is full
				end if;
			
				FIFO_wr_ready <= '0';	
				if(next_wr_pointer /= rd_pointer_reg and FIFO_wr_valid = '1'  and wr_cnt_en = '0') then		-- fifo not full and write valid asserted ?
					FIFO_wr_ready <= '1';											-- assert write ready 
				end if;
			
				if(FIFO_wr_ready and FIFO_wr_valid) then							-- write ready x valid handshake ?
					FIFO_wr_ready <= '0';											-- de-assert write ready
					s_ram(to_integer(unsigned(wr_pointer))) := FIFO_wr_data;								-- write data to fifo address
					wr_cnt_en <= '1';
				end if;
			end if;
		end if;
	end process;
	
	-- Read Clock Domain Process
	rd_proc: process(rd_clk_in)
	begin
		if(rising_edge(rd_clk_in)) then
			rd_cnt_en <= '0';
			FIFO_rd_valid <= '0';
			wr_pointer_reg <= wr_pointer;											-- register write pointer
			if(rd_rst_in = '1') then
				empty <= '1';
			else
				FIFO_rd_data <= s_ram(to_integer(unsigned(rd_pointer)));			-- always output read data to interface
				empty <= '0';														-- default empty to '0';
				if(rd_pointer = wr_pointer_reg) then								-- read address is write address ?
					empty <= '1';													-- fifo is empty
				end if;
				
				FIFO_rd_valid <= '0';
				if(rd_pointer /= wr_pointer_reg and rd_cnt_en = '0') then			-- read address is NOT write pointer ?
					FIFO_rd_valid <= '1';											-- valid data to read
				end if;
				
				if(FIFO_rd_valid and FIFO_rd_ready) then							-- ready valid handshake for read interface ?
					FIFO_rd_valid <= '0';											-- de-assert valid 
					rd_cnt_en <= '1';
				end if;
			end if;
		end if;
	end process;
	

end rtl;