--------------------------------------------------------------------------------
--== Filename ..... ahb_master_controller.vhd                                      ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... June 2025                                            ==--
-- AHB Master Controller for Compression Cores Configuration
-- This controller reads configuration data from RAM and writes to three
-- compression cores (2x CCSDS123+121, 1x CCSDS121) via AHB interface
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_utils;
use shyloc_utils.amba.all;

--library define in config_types_pkg
library config_controller;
use config_controller.config_pkg.all;

entity ahb_master_controller is
  generic (
    -- AHB Master parameters
    hindex      : integer := 0;                    -- AHB master index
    haddr_mask  : integer := 16#FFF#;              -- Address mask
    hmaxburst   : integer := 16;                   -- Maximum burst length

    -- Config RAM parameters
    g_input_data_width  : integer := c_input_data_width;   -- Input data width
    g_input_addr_width  : integer := c_input_addr_width;   -- Input address width
    g_input_depth       : integer := c_input_depth;        -- Input address depth
    g_output_data_width : integer := c_output_data_width;  -- Output data width
    g_output_addr_width : integer := c_output_addr_width;  -- Output address width
    g_output_depth      : integer := c_output_depth;       -- Output address depth
    
    -- Compression cores base addresses
    ccsds123_1_base : std_logic_vector(31 downto 0) := x"40010000";
    ccsds123_2_base : std_logic_vector(31 downto 0) := x"40020000";
    ccsds121_base   : std_logic_vector(31 downto 0) := x"40030000";
    
    -- Configuration sizes (in 32-bit words)
    ccsds123_cfg_size : integer := 6;             -- Number of config registers for CCSDS123
    ccsds121_cfg_size : integer := 4              -- Number of config registers for CCSDS121
  );
  port (
    clk         : in  std_ulogic;                 -- System clock
    rst_n       : in  std_ulogic;                 -- Active low reset
    
    -- Control interface
    compressor_status_HR : in compressor_status;
    compressor_status_LR : in compressor_status;
    compressor_status_H  : in compressor_status;
    
    -- ram configuration interface input
    ram_wr_en   : in  std_logic;                     -- Write enable signal for RAM
    wr_addr     : in  std_logic_vector(g_input_addr_width-1 downto 0); 
    wr_data     : in  std_logic_vector(7 downto 0);
    
    ctrli       : out  ahbtbm_ctrl_in_type;          --! Control signals to communicate with AHB master module. 
    ctrlo       : in ahbtbm_ctrl_out_type            --! Control signals to communicate with AHB master module. 
  );
end entity ahb_master_controller;

architecture rtl of ahb_master_controller is

   --signal ram_read_cnt : unsigned(3 downto 0); -- RAM read 
   signal read_ram_done : std_logic := '0'; -- Signal to indicate RAM read completion
  ---------------------------
  -- AHB related signals
  ---------------------------
   type state_type is (idle, s0, s1, s2, s3, s4, s5, clear);
--   signal state_reg, state_next: state_type;
   signal state_reg_ahbw, state_next_ahbw: state_type;
 
  -- control registers for AHB 
  signal ctrl, ctrl_reg  : ahbtb_ctrl_type;
  ---------------------
  signal remaining_reads, remaining_reads_cmb, remaining_writes, remaining_writes_cmb: unsigned(3 downto 0);    -- Total number of samples pending to read/write (reverse sample counters) 
  -- Write address
  signal address_write, address_write_cmb   : std_logic_vector(31 downto 0);
  -- Read address
  signal address_read, address_read_cmb   : std_logic_vector(31 downto 0);
  -- Data to be written/ read
    signal data,  data_cmb        : std_logic_vector(31 downto 0);
    signal size, size_cmb         : std_logic_vector(1 downto 0);
    signal htrans, htrans_cmb     : std_logic_vector(1 downto 0);
    signal hburst, hburst_cmb     : std_logic;
    signal debug, debug_cmb       : integer;
  -- if 0, next address stage takes place in the next cycle
    signal appidle, appidle_cmb   : boolean;
  -- Modified by AS: new signal to know if the written/read value has been consumed
  --signal data_valid, data_valid_cmb  : std_logic;
  -------------------------------
  
  --Trigger a write or read operation
  signal ahbwrite, ahbwrite_cmb, ahbread_cmb, ahbread : std_logic;
  --Counters
  -- Modified by AS: Counter width maximum is 4 bits, as max 10 CFG register
  -- Modified by AS: new reverse counters in exchange of counter and counter_reg
 -- signal rev_counter, rev_counter_reg: unsigned(3 downto 0);
  -- Modified by AS: beats, count_burst and burst_size widths reduced from 16 to 4 bits
  signal count_burst, count_burst_cmb, burst_size, burst_size_cmb, beats, beats_reg: unsigned (3 downto 0);
  ------------------
  signal ahb_wr_cnt_cmb, ahb_wr_cnt_reg : unsigned(3 downto 0); -- AHB write counter, counts how many registers have been written

  -- Read flag for FIFO - allow reading from FIFO
 -- signal rd_in_reg, rd_in_out, allow_read, allow_read_reg: std_logic;
     
    -- Adapted clear to AHB clk. 
 -- signal clear_ahb: std_logic;
  -- Adapted config valid to AHB clk. 
--  signal config_valid_adapted_ahb: std_logic;
  -- AHB status information
 -- signal ahb_status_s, ahb_status_ahb_cmb, ahb_status_ahb_reg: ahbm_123_status;
        
  signal ram_start_addr : std_logic_vector(g_output_addr_width-1 downto 0); -- RAM start address for configuration data
  signal ram_read_num :  integer range 0 to 10;       -- Number of registers to read from RAM
--  signal compressor_status : compressor_status_array; -- Compressor status for all compressors

  signal config_done, config_done_cmb : std_logic;  -- Configuration done signal, to execute the next compressor configuration  
  -- Signals for config_arbiter instance
  signal arbiter_grant       : std_logic_vector(1 downto 0);
  signal arbiter_grant_valid : std_logic;
  signal arbiter_config_req  : std_logic;
  
  signal ahb_base_addr_123, ahb_base_addr_121 : std_logic_vector(31 downto 0); -- AHB base addresses for CCSDS123 and CCSDS121

  -- Signals for config_ram_8to32 from input
  signal ram_rd_data_cmb : std_logic_vector(g_output_data_width-1 downto 0); -- Data read from RAM
  signal ram_rd_valid_cmb : std_logic; -- Valid signal for RAM read data
--------signals for fifo 
  signal empty_cmb, full_cmb, hfull_cmb, afull_cmb, aempty_cmb : std_logic; -- FIFO empty and full signals
  signal data_out_fifo : std_logic_vector(g_output_data_width-1 downto 0); -- Data output from FIFO
  signal r_update_reg, w_update_reg : std_logic; -- Read and write update signals for FIFO
--new definition
  signal r, rin      : reg_type;

  -- from GR712
  signal gr712_read_req : std_logic;  -- GR712 read request signal
begin

  -----------------------------------------------------------------------------  
  -- Output assignments
  -----------------------------------------------------------------------------
  ctrli <= ctrl.i;
  ctrl.o <= ctrlo;
 -- rd_in <= rd_in_out;
/*
preload_fifo : process(clk, rst_n)
begin
    if rst_n = '0' then
        ram_read_cnt <= (others => '0'); -- Reset RAM read counter          , defined in pckage reg_type
        ram_start_addr <= (others => '0'); -- Reset RAM start address
    elsif clk'event and clk = '1' then
        if r.start_preload_ram = '1' then
            if r.ram_rd_en = '1' then
                ram_rd_addr <= r.ram_rd_addr; -- Read from RAM
            end if;
        end if;
    end if;
end process preload_fifo;
*/

reg: process(clk, rst_n)
begin
  if rst_n = '0' then
    r <= RES;
 --   rev_counter_reg <= (others => '0');
    size <= (others => '0');
    htrans <= (others => '0');
    hburst <= '0';
    debug <= 0;
    appidle <= true;
    address_write <= (others => '0');
    address_read <= (others => '0');
    count_burst <= (others => '0');
    burst_size     <= (others => '0');
    ctrl_reg.i       <= ctrli_idle;
    ctrl_reg.o       <= ctrlo_nodrive;
    ahb_wr_cnt_reg   <= (others => '0'); -- Reset AHB write counter
    ahbwrite         <= '0';
    ahbread          <= '0';
    state_reg_ahbw   <= idle; 
    beats_reg        <= (others => '0');
    remaining_reads  <= (others => '0');
    remaining_writes <= (others => '0');
    config_done      <= '0';
    r_update_reg     <= '0';
    w_update_reg     <= '0';
  elsif clk'event and clk = '1' then
    r <= rin; 
   -- rev_counter_reg <= rev_counter;
    size             <= size_cmb;
    htrans           <= htrans_cmb;
    hburst           <= hburst_cmb;
    debug            <= debug_cmb;
    appidle          <= appidle_cmb;
    address_write    <= address_write_cmb;
    address_read     <= address_read_cmb;
    count_burst      <= count_burst_cmb;
    burst_size       <= burst_size_cmb;
    ctrl_reg.i       <= ctrl.i;  
    ahb_wr_cnt_reg   <= ahb_wr_cnt_cmb;  -- Update AHB write counter
    ahbwrite         <= ahbwrite_cmb; 
    ahbread          <= ahbread_cmb;
    state_reg_ahbw   <= state_next_ahbw; -- Update state register
    beats_reg        <= beats; 
    remaining_reads  <= remaining_reads_cmb;
    remaining_writes <= remaining_writes_cmb;
    config_done      <= config_done_cmb; 
    r_update_reg     <= r.r_update;     -- register read update signal
    w_update_reg     <= r.w_update; 
   end if;
end process reg;

process(arbiter_grant, arbiter_config_req, ram_wr_en, r, empty_cmb, arbiter_grant_valid, remaining_writes, state_next_ahbw, state_reg_ahbw, ctrl.o.update, address_write, ahb_wr_cnt_reg, ram_rd_data_cmb, ram_rd_valid_cmb)
  variable v              : reg_type;
  variable tot_size       : std_logic_vector(15 downto 0);
  variable pointer        : std_logic_vector(4 downto 0);  -- RAM pointer for reading configuration data, 5 bits address
  variable ahb_address_switch : std_logic; 
  variable beats_v: unsigned(3 downto 0);      -- Modified by AS: beats_v resized from 16 to 4 bits 
begin

    address_write_cmb <= address_write;     
    address_read_cmb <= address_read;  
    size_cmb <= size;
    htrans_cmb <= htrans;
    hburst_cmb <= hburst;
    debug_cmb <= debug;
    appidle_cmb <= appidle;
    ahb_wr_cnt_cmb <= ahb_wr_cnt_reg; 
    ahbwrite_cmb <= '0';
    ahbread_cmb <= '0'; 
    v := r; 
    beats <= beats_reg;
    remaining_reads_cmb <= remaining_reads;
    remaining_writes_cmb <= remaining_writes;
    config_done_cmb <= '0'; 
    v.data_valid := '0';
    
    case r.config_state is    
      when IDLE =>
         v.start_preload_ram := '0';
         ahb_address_switch := '0'; -- Reset address switch
         address_write_cmb <= (others => '0'); -- Reset write address
          if arbiter_config_req = '1' and state_reg_ahbw = s0 and ram_wr_en = '0' then         -- 这里arbiter_config_req需替换成是否有读写请求，而不是仅仅是confgi_req, ram_wr_en 避免读写冲突
            v.config_state := ARBITER_WR;      -- write_arbiter arbitrate   
 --         elsif gr712_read_req = '1' and state_reg_ahbw = idle and rst_n = '1' then 
 --           v.config_state := ARBITER_RD;
          else 
            v.config_state := IDLE;           -- Stay in IDLE if no request
          end if;

      when ARBITER_WR =>
          if ram_wr_en = '1' then
            v.config_state := IDLE;
          end if;
               
         if arbiter_grant_valid = '1' then        -- Arbiter has granted a request(write has high priority)
           v.start_preload_ram := '1'; -- Start preloading RAM data
            if empty_cmb = '0' then
              v.config_state := AHB_TRANSFER_WR;
  --            rev_counter <= to_unsigned(ram_read_num, 4);    
              remaining_writes_cmb <= to_unsigned(ram_read_num, 4); -- Set remaining writes to the number of registers to read
            end if; 
            case ram_read_num is     
              when 4 => 
                address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004");  -- Set initial address for CCSDS121

              when 10 =>
                address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_123) - x"00000004"); 

              when others =>
                v.config_state := ERROR; -- Error state if ram_read_num is not 4 or 10
            end case;
         end if;

      when AHB_TRANSFER_WR =>        -- write request 
        if ram_wr_en = '1' then
          v.config_state := IDLE;
        end if;

        if remaining_writes < to_unsigned(ram_read_num, 4) then
          beats_v := remaining_writes;
        else
          beats_v := to_unsigned(ram_read_num, 4); -- Set beats_v to the number of registers to read
        end if;
        beats <= beats_v;

        if (empty_cmb = '0' and ctrl.o.update = '1' and (state_next_ahbw = s0 or state_next_ahbw = s4)) then
          v.data_valid := '0';
          v.r_update := '1';                  -- read from FIFO
        end if; 
        
        if((state_next_ahbw = s0 or state_next_ahbw = s4) and r_update_reg = '1' and ctrl.o.update = '1') then
   --       v.data_valid := '1';
          appidle_cmb <= false; 
          case ram_read_num is 
            when 4 => 
              if unsigned(address_write) = unsigned(ahb_base_addr_121) + to_unsigned(12,5) then   -- (4-1) * 4 
                address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004");
                config_done_cmb <= '1'; 
                v.config_state := IDLE;  
                v.data_valid := '0';
              else 
                address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004"); -- 4 bytes per register
                v.data_valid := '1';
              end if;

            when 10 =>
              if ahb_address_switch = '1' then
                if unsigned(address_write) = unsigned(ahb_base_addr_123) + to_unsigned(20,6) then  -- (6-1) * 4
                  address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004"); -- Switch to CCSDS121 base address
                  v.data_valid := '0';
                  v.config_state := AHB_TRANSFER_WR; -- Switch to AHB_TRANSFER_WR state
                else 
                  address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
                  v.data_valid := '1';
                end if;
              else 
                if unsigned(address_write) = unsigned(ahb_base_addr_121) + to_unsigned(12,5) then   -- (4-1) * 4 
                  address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_123) - x"00000004");
                  v.config_state := IDLE;                  -- Switch to IDLE after writing all registers, maybe in future into state done
                  config_done_cmb <= '1'; 
                  v.data_valid := '0';
                else 
                  address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
                  v.data_valid := '1';
                end if;
              end if;

            when others =>
              v.config_state := error; -- Error state if ram_read_num is not 4 or 10
          end case;
          
          size_cmb <= "10";
          htrans_cmb <= "10";
          hburst_cmb <= '0';
          data_cmb <= data_out_fifo; -- Data to be written from fifo

          -- trigeger the write operation
          ahbwrite_cmb <= '1';
          remaining_writes_cmb <= remaining_writes - 1; -- Decrement remaining writes counter
          ahb_wr_cnt_cmb <= ahb_wr_cnt_reg + 1; -- Increment write counter 

          -- Modified by AS: initiating burst operation if there are enough data pending --
          if unsigned(beats_v) > 1 then
            hburst_cmb <= '1';
            v.config_state := AHB_Burst_WR;
          end if;
          -- ahb_address_switch logic , when ram_read_num = 10, need switch to CCSDS121
          
        end if; 

      when AHB_Burst_WR =>
        if ram_wr_en = '1' then
          v.config_state := IDLE;
        end if;

        hburst_cmb <= '1';
        size_cmb <= "10";
        data_cmb <= data_out_fifo;
        debug_cmb <= 2;
        if ctrl.o.update = '1' then
          htrans_cmb <= "11";
          if r_update_reg = '1' then
            v.data_valid := '1';
            -- Modified by AS: new counters updated --
            remaining_writes_cmb <= remaining_writes - 1;
            ahb_wr_cnt_cmb <= ahb_wr_cnt_reg + 1; -- Increment write counter 
            case ram_read_num is 
              when 4 => 
                if unsigned(address_write) = unsigned(ahb_base_addr_121) + to_unsigned(12,5) then   -- (4-1) * 4 
                  address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004");
                  v.config_state := IDLE;  
                  config_done_cmb <= '1'; 
           --       v.data_valid := '0';                 
                else 
                  address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
           --       v.data_valid := '1';
                end if;
  
              when 10 =>
                if ahb_address_switch = '1' then
                  if unsigned(address_write) = unsigned(ahb_base_addr_123) + to_unsigned(20,6) then  -- (6-1) * 4
                    address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004"); -- Switch to CCSDS121 base address
         --           v.data_valid := '0';
                    v.config_state := AHB_TRANSFER_WR; -- Switch to AHB_TRANSFER_WR state
                  else 
                    address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
          --          v.data_valid := '1';
                  end if;
                else 
                  if unsigned(address_write) = unsigned(ahb_base_addr_121) + to_unsigned(12,5) then   -- (4-1) * 4 
                    address_write_cmb <= std_logic_vector(unsigned(ahb_base_addr_121) - x"00000004");
                    v.config_state := IDLE;                  -- Switch to IDLE after writing all registers, maybe in future into state done
                    config_done_cmb <= '1';
          --          v.data_valid := '0'; 
                  else 
                    address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
          --          v.data_valid := '1';
                  end if;
                end if;
  
              when others =>
                v.config_state := ERROR; -- Error state if ram_read_num is not 4 or 10
            end case;
          end if;

          if (empty_cmb = '0' and v.data_valid = '1' and (count_burst_cmb /= 0) and (state_reg_ahbw = s4)) then
            v.r_update := '1';
            ahbwrite_cmb <= '1';
            appidle_cmb <= false;  --appidle = true if there will be more data in the next cycle
          end if;

          if (v.data_valid = '0') then
            appidle_cmb <= true;
          end if;

          if (state_reg_ahbw = s0) or (state_reg_ahbw = s2) then
              if ahb_wr_cnt_reg = ram_read_num then
                appidle_cmb <= true;               
                v.config_state := IDLE; -- Configuration done
              else 
                v.config_state := AHB_TRANSFER_WR; -- Continue writing
              end if;
          end if;
        end if;
      
    when ERROR =>
        --error signal indicate, tbd
        v.config_state := IDLE;

    when others =>
        v.config_state := IDLE;  -- Default case, return to IDLE state
   end case;

    if ram_read_num = 10 then 
      if ahb_wr_cnt_reg < 6 then
        ahb_address_switch := '1';  -- execute the CCSDS123 address, then switch to CCSDS121
      else 
        ahb_address_switch := '0'; 
      end if;
    else
      ahb_address_switch := '0'; -- No switch needed for 4 registers
    end if;

    if r.ram_read_cnt < ram_read_num then              -- buffer the CFG to FIFO
      if r.start_preload_ram = '1' then
        v.ram_rd_en := '1';                  -- Enable RAM read
        v.data_in := ram_rd_data_cmb;       -- Read data from RAM
 --       v.w_update := '1'; -- Update control signal
        v.ram_rd_addr := std_logic_vector(unsigned(ram_start_addr) + r.ram_read_cnt);
        v.ram_read_cnt := r.ram_read_cnt + 1;
      else
        v.ram_rd_en := '0';
  --      v.w_update := '0'; 
      end if;
    else
      v.start_preload_ram := '0'; -- Stop preloading RAM data
      v.ram_rd_en := '0';
      v.w_update := '0'; 
      v.ram_read_cnt := (others => '0'); -- Reset RAM read counter
    end if;
   
    if ram_rd_valid_cmb = '1' then       --pipeline the RAM read operation
      v.data_in := ram_rd_data_cmb; -- Read data from RAM
      v.w_update := '1'; -- Update control signal
    else
      v.w_update := '0'; -- No update if not reading  
    end if;



    rin <= v;    

end process;
  
comb_ahb: process (state_reg_ahbw, address_write_cmb, address_read_cmb, data_cmb, size_cmb, appidle_cmb, appidle, htrans_cmb, hburst_cmb, debug_cmb, 
  ahbwrite_cmb, ctrl.o.update, ctrl_reg.i, ctrl.i, ahbread_cmb, beats_reg, count_burst, burst_size)
  -------------------------------------
  begin  
    state_next_ahbw <= state_reg_ahbw;
    count_burst_cmb <= count_burst;
    burst_size_cmb <= burst_size;
    ctrl.i <= ctrl_reg.i;


    -- AHB state machine
    case (state_reg_ahbw) is
      when idle =>
        --ctrl.o <= ctrlo_nodrive;
        ctrl.i <= ctrli_idle;
        if (rst_n = '1') then
          state_next_ahbw <= s0;
        end if;
      when s0 =>      -- Modified by AS: if/else clauses reorganized
        --write
        if ahbwrite_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hprot <= "1110"; ctrl.i.ac.hwrite <= '1'; 
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          --if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            state_next_ahbw <= s4;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        --read
        elsif ahbread_cmb = '1' and ctrl.o.update = '1' then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_read_cmb; 
          ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hwrite <= '0';
          ctrl.i.ac.hprot <= "1110";
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          --if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            state_next_ahbw <= s4;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        elsif ahbwrite_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s1;
        elsif ahbread_cmb = '1' and ctrl.o.update = '0' then
          state_next_ahbw <= s3;
        end if;
      when s1 =>               -- Modified by AS: if/else clauses reorganized
        -- wait for ctrl.o.update = '1' to write 
        if (ctrl.o.update = '1') then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_write_cmb; ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hprot <= "1110"; ctrl.i.ac.hwrite <= '1'; 
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.htrans <= htrans_cmb;
            ctrl.i.ac.hburst <= "000";
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s0;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          -- if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s4;
            end if;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        end if;
      when s2 => 
        -- because of appidle, wait for ctrl.o.update = '1'
        if (ctrl.o.update = '1') then
          state_next_ahbw <= s0;
          ctrl.i <= ctrli_idle;          
        end if;
      when s3 =>
        -- wait for ctrl.o.update = '1' to read 
        if (ctrl.o.update = '1') then
          ctrl.i.ac.ctrl.use128 <= 0;
          ctrl.i.ac.ctrl.dbgl <= debug_cmb;
          ctrl.i.ac.hsize <= '0' & size_cmb;
          ctrl.i.ac.haddr <= address_read_cmb; 
          ctrl.i.ac.hdata <= data_cmb;
          ctrl.i.ac.hwrite <= '0'; 
          ctrl.i.ac.hprot <= "1110";
          -- Modified by AS: ctrl.i.ac.hburst assignment moved inside the if/else clause
          if hburst_cmb = '0' then
            ctrl.i.ac.hburst <= "000";
            ctrl.i.ac.htrans <= htrans_cmb; 
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s0;
            end if;
          -- Modified by AS: hburst signal value depending on the hburst_cmb flag and number of beats --
          else          -- if hburst_cmb = '1' then
            ctrl.i.ac.htrans <= "10";
            count_burst_cmb <= to_unsigned(1, count_burst_cmb'length);
            if (appidle_cmb = true) then
              state_next_ahbw <= s2;
            else
              state_next_ahbw <= s4;
            end if;
            burst_size_cmb <= beats_reg;        -- Modified by AS: assignment from beats_reg instead of beats
            case to_integer(beats) is
              when 4 =>    ctrl.i.ac.hburst <= "011";
              when 8 =>    ctrl.i.ac.hburst <= "101";
              when 16 =>    ctrl.i.ac.hburst <= "111";
              when others =>  ctrl.i.ac.hburst <= "001";
            end case;
          end if;
          ------------------------------------------------
        end if;
      -- Modified by AS: Burst transanction enabled --
      when s4 => 
        if (ctrl.o.update = '1') then
          -- ctrl.i <= ctrl_reg.i;    -- Modified by AS: cassignment not necessary
          if (appidle = false) then
            if (count_burst = burst_size - 1) then
              count_burst_cmb <= to_unsigned(0, count_burst_cmb'length);
              state_next_ahbw <= s2;
            else
              count_burst_cmb <= count_burst + 1;
            end if;
            ctrl.i.ac.htrans <= "11";  -- Sequential transfer
            if (ctrl_reg.i.ac.hwrite = '1') then
              ctrl.i.ac.haddr <= address_write_cmb;
            else
              ctrl.i.ac.haddr <= address_read_cmb;
            end if;
          else
            ctrl.i.ac.htrans <= "01";  -- Busy
            ctrl.i.ac.haddr <= ctrl_reg.i.ac.haddr; 
          end if;
          ctrl.i.ac.hdata <= data_cmb;               --data_burst (to_integer(count_burst));
        end if;
      ------------------------------------------------
      when others => 
        state_next_ahbw <= idle;
    end case;
  end process;
  

-- Instantiate config_arbiter
config_arbiter_inst : entity config_controller.config_arbiter
  generic map (
    g_ram_addr_width => g_output_addr_width  -- RAM address width
  )
  port map (
    clk                => clk,
    rst_n              => rst_n,
    compressor_status_HR => compressor_status_HR,
    compressor_status_LR => compressor_status_LR,
    compressor_status_H  => compressor_status_H,
    config_done        => config_done,
    config_req         => arbiter_config_req,
    start_add          => ram_start_addr,
    read_num           => ram_read_num,
    ahb_base_addr_123  => ahb_base_addr_123,
    ahb_base_addr_121  => ahb_base_addr_121,
    grant              => arbiter_grant,
    grant_valid        => arbiter_grant_valid
  );


-- Instantiate config_ram_8to32
config_ram_inst : entity config_controller.config_ram_8to32
  generic map (
    INPUT_DATA_WIDTH  => g_input_data_width,      -- Input data width
    INPUT_ADDR_WIDTH  => g_input_addr_width,      -- Input address width
    INPUT_DEPTH       => g_input_depth,           -- Input address depth
    OUTPUT_DATA_WIDTH => g_output_data_width,     -- Output data width
    OUTPUT_ADDR_WIDTH => g_output_addr_width,     -- Output address width
    OUTPUT_DEPTH      => g_output_depth           -- Output address depth
  )
  port map (
    clk         => clk,          -- System clock
    rst_n       => rst_n,        -- Active low reset
    wr_en       => ram_wr_en,    -- Write enable signal
    wr_addr     => wr_addr,  -- Write address
    wr_data     => wr_data,  -- Write data
    rd_en       => r.ram_rd_en,    -- Read enable signal
    rd_addr     => r.ram_rd_addr,  -- Read address
    rd_data     => ram_rd_data_cmb,  -- Read data output
    rd_valid    => ram_rd_valid_cmb  -- Read valid signal
  );
  
  fifo_no_edac: entity shyloc_utils.fifop2_base(arch)
  generic map (
      RESET_TYPE  => 0,
      W  => 32, 
      NE   => 10, 
      W_ADDR  => 4, 
      TECH => 0)
  port map (
    clk       => clk, 
    rst_n     => rst_n, 
    clr       => r.clr,
    w_update  => r.w_update, 
    r_update  => r.r_update, 
    hfull     => hfull_cmb, 
    empty     => empty_cmb, 
    full      => full_cmb, 
    afull     => afull_cmb, 
    aempty    => aempty_cmb, 
    data_in   => r.data_in,
    data_out  => data_out_fifo
  );

end architecture rtl;