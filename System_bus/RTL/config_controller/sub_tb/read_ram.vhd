
read_prc: process(clk, rst_n)
begin
    if rst_n = '0' then
        ram_rd_en <= '0';
        read_ram_done <= '0';          
    elsif rising_edge(clk) then
        case curr_state is   
            when READ_RAM =>
          
              case arbiter_grant is
                when "00" => -- HR
                    if ram_read_segment = '0' then -- CCSDS123
                        ram_rd_addr <= std_logic_vector(unsigned(c_hr_ccsds123_base) + ram_read_cnt);
                        ram_rd_en <= '1'; 
                        if ram_read_cnt > CCSDS123_CFG_NUM - 1 then
                            ram_read_cnt <= 0;
                            ram_read_segment <= '1'; -- Switch to CCSDS121
                            ram_rd_en <= '0'; 
                        else
                            ram_read_cnt <= ram_read_cnt + 1;
                        end if;
                    else -- CCSDS121
                        ram_rd_addr <= std_logic_vector(unsigned(c_hr_ccsds121_base) + ram_read_cnt);
                        ram_rd_en <= '1'; 
                        if ram_read_cnt > CCSDS121_CFG_NUM - 1 then
                            ram_read_cnt <= 0;
                            ram_rd_en <= '0'; 
                            read_ram_done <= '1';         -- Configuration done to let arbiter know
                        else
                            ram_read_cnt <= ram_read_cnt + 1;
                        end if;
                    end if;

                when "01" => -- LR
                    if ram_read_segment = '0' then -- CCSDS123
                        ram_rd_addr <= std_logic_vector(unsigned(c_lr_ccsds123_base) + ram_read_cnt);
                        ram_rd_en <= '1'; 
                        if ram_read_cnt > CCSDS123_CFG_NUM - 1 then
                            ram_read_cnt <= 0;
                            ram_read_segment <= '1'; -- Switch to CCSDS121
                            ram_rd_en <= '0'; 
                        else
                            ram_read_cnt <= ram_read_cnt + 1;
                        end if;
                    else -- CCSDS121
                        ram_rd_addr <= std_logic_vector(unsigned(c_lr_ccsds121_base) + ram_read_cnt);
                        ram_rd_en <= '1'; 
                        if ram_read_cnt > CCSDS121_CFG_NUM - 1 then
                            ram_read_cnt <= 0;
                            ram_rd_en <= '0'; 
                            read_ram_done <= '1'; 
                        else
                            ram_read_cnt <= ram_read_cnt + 1;
                        end if;
                    end if;

                when "10" => -- H
                    ram_rd_addr <= std_logic_vector(unsigned(c_h_ccsds121_base) + ram_read_cnt);
                    ram_rd_en <= '1'; 
                    if ram_read_cnt > CCSDS121_CFG_NUM - 1 then
                        ram_read_cnt <= 0;
                        ram_rd_en <= '0'; 
                        read_ram_done <= '1'; 
                    else
                        ram_read_cnt <= ram_read_cnt + 1;
                    end if;

                when others =>
                    ram_rd_en <= '0'; 
              end case;

            when others =>
                ram_rd_en <= '0';
        end case;

end process read_prc;

