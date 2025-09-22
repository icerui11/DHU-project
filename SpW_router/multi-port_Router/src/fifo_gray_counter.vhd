
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_gray_counter is
	generic(
		g_count_size : natural := 32
	);
	port(
		clk		   		: in std_logic	:= '0';
		reset	   		: in std_logic	:= '0';
		enable	   		: in std_logic	:= '0';
		gray_count 		: out std_logic_vector(g_count_size-1 downto 0) := (others => '0');
		gray_count_next	: out std_logic_vector(g_count_size-1 downto 0) := (others => '0')
	);
	
end entity;

-- Implementation:

-- There is an imaginary bit in the counter, at q(0), that resets to 1
-- (unlike the rest of the bits of the counter) and flips every clock cycle.
-- The decision of whether to flip any non-imaginary bit in the counter
-- depends solely on the bits below it, down to the imaginary bit.	It flips
-- only if all these bits, taken together, match the pattern 10* (a one
-- followed by any number of zeros).

-- Almost every non-imaginary bit has a component instance that sets the 
-- bit based on the values of the lower-order bits, as described above.
-- The rules have to differ slightly for the most significant bit or else 
-- the counter would saturate at it's highest value, 1000...0.

architecture rtl of fifo_gray_counter is

	-- q contains all the values of the counter, plus the imaginary bit
	-- (values are shifted to make room for the imaginary bit at q(0))
	signal q  		: std_logic_vector (g_count_size downto 0) := (0 => '1', others => '0');
	signal q_next  	: std_logic_vector (g_count_size downto 0) := (1 => '1', others => '0');
	-- no_ones_below(x) = 1 iff there are no 1's in q below q(x)
	signal no_ones_below  		: std_logic_vector (g_count_size downto 0) := (0 => '1', others => '0');
	signal no_ones_below_next  	: std_logic_vector (g_count_size downto 0) := (0 => '1', 1 => '1', others => '0');
	
	-- q_msb is a modification to make the msb logic work
	signal q_msb 		: std_logic := '0';
	signal q_msb_next 	: std_logic := '0';
	signal enable_old 	: std_logic := '0';
	


begin

	q_msb <= q(g_count_size-1) or q(g_count_size);
	q_msb_next <= q_next(g_count_size-1) or q_next(g_count_size);
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				-- Resetting involves setting the imaginary bit to 1
				q(0) <= '1';
				q_next(0) <= '0';
				q(g_count_size downto 1) <= (others => '0');
				q_next(g_count_size downto 1) <= (1 => '1', others => '0');
			elsif(enable = '1') then
			
				-- Toggle the imaginary bit
				q(0) <= not q(0);
				q_next(0) <= not q_next(0);
				
				for i in 1 to g_count_size loop
					-- Flip q(i) if lower bits are a 1 followed by all 0's
					q(i) 		<= q(i) xor (q(i-1) and no_ones_below(i-1));
					q_next(i) 	<= q_next(i) xor (q_next(i-1) and no_ones_below_next(i-1));
				end loop;  -- i
			
				q(g_count_size) 		<= q(g_count_size) xor (q_msb and no_ones_below(g_count_size-1));
				q_next(g_count_size) 	<= q_next(g_count_size) xor (q_msb_next and no_ones_below_next(g_count_size-1));

			end if;
		end if;
	end process;
	
	-- There are never any 1's beneath the lowest bit
	no_ones_below(0) <= '1';
	no_ones_below_next(0) <= '1';
	
	below_gen: for j in 1 to g_count_size generate
		no_ones_below(j) <= no_ones_below(j-1) and not q(j-1);
		no_ones_below_next(j) <= no_ones_below_next(j-1) and not q_next(j-1);
	end generate below_gen;
	
--	process(clk)
--	begin
--		if(rising_edge(clk)) then
--			if(enable_old = '1') then
--				for j in 1 to g_count_size loop
--					no_ones_below(j) <= no_ones_below(j-1) and not q(j-1);
--					no_ones_below_next(j) <= no_ones_below_next(j-1) and not q_next(j-1);
--				end loop;
--			end if;
--		end if;
--	end process;
--	
--	process(q, no_ones_below)
--	begin
--		for j in 1 to g_count_size loop
--			no_ones_below(j) <= no_ones_below(j-1) and not q(j-1);
--		end loop;
--	end process;
--
--	process(q_next, no_ones_below_next)
--	begin
--		for j in 1 to g_count_size loop
--			no_ones_below_next(j) <= no_ones_below_next(j-1) and not q_next(j-1);
--		end loop;
--	end process;
	
	-- Copy over everything but the imaginary bit
	gray_count <= q(g_count_size downto 1);
	gray_count_next <= q_next(g_count_size downto 1);
	
end rtl;