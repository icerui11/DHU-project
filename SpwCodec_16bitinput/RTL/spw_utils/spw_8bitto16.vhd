-- covert 8-bit data to 16-bit data for SHyLoC BIP 16 bit input
--15.09.2024 
--Author: Rui Yin


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity spw_8bitto16 is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;                                   --spw_datactrl reset  high active
           rx_datavalid : in  STD_LOGIC;                             --spw_datactrl rx_datavalid
           ccsds_datanewValid : out  STD_LOGIC;                     --enable ccsds data input
           data_in_spw : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out_ccsds : out  STD_LOGIC_VECTOR (15 downto 0));
end spw_8bitto16;

architecture rtl of spw_8bitto16 is
    signal data_out_ccsds_temp : STD_LOGIC_VECTOR (15 downto 0);
    type state_type is (wait_high, wait_low);
    signal state : state_type;

begin

process(clk)
begin 
    if rising_edge(clk) then
        if reset = '1' then
            state <= wait_high;
            data_out_ccsds_temp <= (others => '0');
        else
            case state is 
                when wait_high =>
                    ccsds_datanewValid <= '0';
                    if rx_datavalid = '1' then
                        data_out_ccsds_temp(15 downto 8) <= data_in_spw;
                        state <= wait_low;
                    end if;

                when wait_low =>
                    if rx_datavalid = '1' then
                        data_out_ccsds_temp(7 downto 0) <= data_in_spw;
                        ccsds_datanewValid <= '1';
                        state <= wait_high;
                    end if;

                when others =>
                    state <= wait_high;
            end case;
        end if;
    end if;
end process;

data_out_ccsds <= data_out_ccsds_temp;

end rtl;