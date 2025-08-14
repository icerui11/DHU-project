--
-- This module is used to debounce any switch or button coming into the FPGA.
-- Does not allow the output of the switch to change unless the switch is
-- steady for enough time (not toggling).
-- Input i_Switch is the unstable input
-- Output o_Switch is the debounced version of i_Switch
-- Set the DEBOUNCE_LIMIT in i_Clk clock ticks to ensure signal is steady.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Debounce_Single_Input is
  generic (
    DEBOUNCE_LIMIT : integer := 250000);
  port (
    i_Clk       : in  std_logic;
    rst_n       : in  std_logic;
    rst_n_spw   : in std_logic;
    locked      : in std_logic;
    spw_fmc_en  : out std_logic;
    spw_fmc_en_2 : out std_logic;
    spw_fmc_en_3 : out std_logic;
    spw_fmc_en_4 : out std_logic;
    reset_n_spw : out std_logic;
    rst_spw     : out std_logic;            --spacewire reset active high 
    reset_n     : out std_logic
    );
end entity Debounce_Single_Input;

architecture rtl of Debounce_Single_Input is

  signal r_Debounce_Count     : integer range 0 to DEBOUNCE_LIMIT := 0;
  signal r_Debounce_Count_spw : integer range 0 to DEBOUNCE_LIMIT := 0;
  signal r_Switch_State       : std_logic:= '1' ;
  signal rst_n_r1             : std_logic;
  signal rst_n_r2             : std_logic;
  signal rst_n_spwr1             : std_logic;
  signal rst_n_spwr2             : std_logic;
  signal r_Switch_State_spw   : std_logic:= '1' ;
begin

  p_Debounce : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if ((rst_n xor r_Switch_State) = '1' and r_Debounce_Count < DEBOUNCE_LIMIT) then
        r_Debounce_Count <= r_Debounce_Count + 1;
      elsif r_Debounce_Count = DEBOUNCE_LIMIT and locked = '1' then
        r_Switch_State <= rst_n;  
        r_Debounce_Count <= 0;
      end if;
    end if;
  end process p_Debounce;
  
spw_Debounce :process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if ((rst_n_spw xor r_Switch_State_spw) = '1' and r_Debounce_Count_spw < DEBOUNCE_LIMIT) then
        r_Debounce_Count_spw <= r_Debounce_Count_spw + 1;
 --       spw_en_r <= '1';
      elsif r_Debounce_Count_spw = DEBOUNCE_LIMIT and locked = '1' then
        r_Switch_State_spw <= rst_n_spw;  
        r_Debounce_Count_spw <= 0;
--        spw_en_r <= '0';
      end if;
    end if;
  end process spw_Debounce;
  
  -- Assign internal register to output (debounced!)
    process(i_Clk)
    begin
      if rising_edge(i_Clk) then
         rst_n_r1 <= r_Switch_State;
         rst_n_r2  <=rst_n_r1;
         reset_n  <=rst_n_r2;
         rst_n_spwr1 <= r_Switch_State_spw;
         rst_n_spwr2 <= rst_n_spwr1;
         reset_n_spw <= rst_n_spwr2;
      end if;
      if rst_n_spwr2 = '0' then
          spw_fmc_en <= '0';
          spw_fmc_en_2 <= '0';
          spw_fmc_en_3 <= '0';
          spw_fmc_en_4 <= '0';      
       else 
          spw_fmc_en <= '1';
          spw_fmc_en_2 <= '1';
          spw_fmc_en_3 <= '1';
          spw_fmc_en_4 <= '1';
       end if;
    end process;

   rst_spw <= '1' when reset_n_spw ='0' else '0';           --active when press button 
end architecture rtl;