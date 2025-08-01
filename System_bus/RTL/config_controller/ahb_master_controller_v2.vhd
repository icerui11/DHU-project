--------------------------------------------------------------------------------
--== Filename ..... ahb_master_controller_v2.vhd                              ==--
--== Institute .... IDA TU Braunschweig RoSy                                  ==--
--== Authors ...... Rui Yin (Modified)                                        ==--
--== Copyright .... Copyright (c) 2025 IDA                                    ==--
--== Project ...... Compression Core Configuration                            ==--
--== Version ...... 2.00                                                      ==--
--== Conception ... July 2025                                                 ==--
-- AHB Master Controller for Compression Cores Configuration
-- Modified to work with individual target arbitration
-- This controller reads configuration data from RAM and writes to compression
-- cores via AHB interface based on individual target grants
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
use shyloc_123.ccsds_ahb_types.all;
use shyloc_123.ahb_utils.all;

library shyloc_utils;
use shyloc_utils.amba.all;

library config_controller;
use config_controller.config_pkg.all;

entity ahb_master_controller_v2 is
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
    g_output_depth      : integer := c_output_depth        -- Output address depth
  );
  port (
    clk         : in  std_ulogic;                 -- System clock
    rst_n       : in  std_ulogic;                 -- Active low reset
    
    -- Control interface
    compressor_status_HR : in compressor_status;
    compressor_status_LR : in compressor_status;
    compressor_status_H  : in compressor_status;
    
    -- RAM configuration interface input
    ram_wr_en   : in  std_logic;                     -- Write enable signal for RAM
    wr_addr     : in  std_logic_vector(g_input_addr_width-1 downto 0); 
    wr_data     : in  std_logic_vector(7 downto 0);
    
    ctrli       : out  ahbtbm_ctrl_in_type;          -- Control signals to communicate with AHB master module
    ctrlo       : in ahbtbm_ctrl_out_type            -- Control signals to communicate with AHB master module
  );
end entity ahb_master_controller_v2;

architecture rtl of ahb_master_controller_v2 is

  ---------------------------
  -- AHB related signals
  ---------------------------
  type state_type is (idle, s0, s1, s2, s3, s4, s5, clear);
  signal state_reg_ahbw, state_next_ahbw: state_type;
 
  -- Control registers for AHB 
  signal ctrl, ctrl_reg  : ahbtb_ctrl_type;
  
  -- Configuration state machine
  signal remaining_writes, remaining_writes_cmb: unsigned(3 downto 0);    -- Remaining writes counter
  
  -- Write address
  signal address_write, address_write_cmb   : std_logic_vector(31 downto 0);
  -- Read address
  signal address_read, address_read_cmb   : std_logic_vector(31 downto 0);
  -- Data to be written
  signal data, data_cmb        : std_logic_vector(31 downto 0);
  signal size, size_cmb        : std_logic_vector(1 downto 0);
  signal htrans, htrans_cmb    : std_logic_vector(1 downto 0);
  signal hburst, hburst_cmb    : std_logic;
  signal debug, debug_cmb      : integer;
  
  -- If false, next address stage takes place in the next cycle
  signal appidle, appidle_cmb  : boolean;
  
  -- Trigger a write or read  operation
  signal ahbwrite, ahbwrite_cmb, ahbread_cmb, ahbread : std_logic;
  
  -- Burst counters
  signal count_burst, count_burst_cmb, burst_size, burst_size_cmb, beats, beats_reg: unsigned (3 downto 0);
  
  -- AHB write counter
  signal ahb_wr_cnt_cmb, ahb_wr_cnt_reg : unsigned(3 downto 0);

  -- RAM interface signals
  signal ram_start_addr : std_logic_vector(g_output_addr_width-1 downto 0);
  signal ram_read_num   : integer range 0 to 6;       -- Updated range for new arbiter
  
  -- Configuration done signal
  signal config_done, config_done_cmb : std_logic;
  
  -- Signals for config_arbiter_v2 instance
  signal arbiter_grant       : std_logic_vector(1 downto 0);  -- 2-bit grant for 3 targets
  signal arbiter_grant_valid : std_logic;
  signal arbiter_config_req  : std_logic;
  signal ahb_target_addr     : std_logic_vector(31 downto 0); -- Single target address from arbiter

  -- Signals for config_ram_8to32
  signal ram_rd_data_cmb  : std_logic_vector(g_output_data_width-1 downto 0);
  signal ram_rd_valid_cmb : std_logic;
  
  -- Signals for FIFO 
  signal empty_cmb, full_cmb, hfull_cmb, afull_cmb, aempty_cmb : std_logic;
  signal data_out_fifo : std_logic_vector(g_output_data_width-1 downto 0);
  signal r_update_reg, w_update_reg : std_logic;
  signal r_update_out, w_update_out : std_logic;  -- Read and write update signals for FIFO
  -- New definition
  signal r, rin : config_reg_type;
  signal should_return_to_idle_cmb, should_return_to_idle_reg : boolean;
begin

  -----------------------------------------------------------------------------  
  -- Output assignments
  -----------------------------------------------------------------------------
  ctrli <= ctrl.i;
  ctrl.o <= ctrlo;

  -- Main register process
  reg: process(clk, rst_n)
  begin
    if rst_n = '0' then
      r <= RES;
      size <= (others => '0');
      htrans <= (others => '0');
      hburst <= '0';
      debug <= 0;
      appidle <= true;
      address_write <= (others => '0');
      count_burst <= (others => '0');
      burst_size <= (others => '0');
      ctrl_reg.i <= ctrli_idle;
      ctrl_reg.o <= ctrlo_nodrive;
      ahb_wr_cnt_reg <= (others => '0');
      ahbwrite <= '0';
      state_reg_ahbw <= idle; 
      beats_reg <= (others => '0');
      remaining_writes <= (others => '0');
      config_done <= '0';
      r_update_reg <= '0';
      w_update_reg <= '0';
      should_return_to_idle_reg <= true;
    elsif clk'event and clk = '1' then
      r <= rin; 
      size <= size_cmb;
      htrans <= htrans_cmb;
      hburst <= hburst_cmb;
      debug <= debug_cmb;
      appidle <= appidle_cmb;
      address_write <= address_write_cmb;
      count_burst <= count_burst_cmb;
      burst_size <= burst_size_cmb;
      ctrl_reg.i <= ctrl.i;  
      ahb_wr_cnt_reg <= ahb_wr_cnt_cmb;
      ahbwrite <= ahbwrite_cmb; 
      state_reg_ahbw <= state_next_ahbw;
      beats_reg <= beats; 
      remaining_writes <= remaining_writes_cmb;
      config_done <= config_done_cmb; 
      w_update_reg <= w_update_out;
      should_return_to_idle_reg <= should_return_to_idle_cmb;
      if (ctrl.o.update = '1') then
        r_update_reg <= r_update_out;
      end if; 
    end if;
  end process reg;

  -- Main combinational process
  process(should_return_to_idle_reg, arbiter_grant, arbiter_config_req, ram_wr_en, r, empty_cmb, arbiter_grant_valid, r_update_reg, w_update_reg,
          remaining_writes, state_next_ahbw, state_reg_ahbw, ctrl.o.update, address_write, 
          ahb_wr_cnt_reg, ram_rd_data_cmb, ram_rd_valid_cmb, ahb_target_addr, ram_read_num, data_out_fifo)
    variable v : config_reg_type;
    variable beats_v : unsigned(3 downto 0);
    variable should_return_to_idle : boolean;
  begin

    -- Default assignments to maintain current values
    address_write_cmb <= address_write;     
    size_cmb <= size;
    htrans_cmb <= htrans;
    hburst_cmb <= hburst;
    debug_cmb <= debug;
    appidle_cmb <= appidle;
    ahb_wr_cnt_cmb <= ahb_wr_cnt_reg; 
    ahbwrite_cmb <= '0';
    v := r; 
    r_update_out <= '0';  -- Default to read update
    w_update_out <= '0';  -- Default to write update
    beats <= beats_reg;
    remaining_writes_cmb <= remaining_writes;
    config_done_cmb <= '0'; 
  --  v.data_valid := '0';
    /*
    should_return_to_idle_cmb <= (arbiter_config_req = '0') or (ram_wr_en = '1');
    if should_return_to_idle_reg then
      v.config_state := IDLE;
      v.start_preload_ram := '0';
      ahb_wr_cnt_cmb <= (others => '0');
      remaining_writes_cmb <= (others => '0');
      address_write_cmb <= (others => '0');
    --/ Clear all state-related signals
      appidle_cmb <= true;
    end if;
*/
    case r.config_state is    
      when IDLE =>
        v.start_preload_ram := '0';
        ahb_wr_cnt_cmb <= (others => '0');
        remaining_writes_cmb <= (others => '0');
        address_write_cmb <= (others => '0');
        
        -- Check for arbitration request and ensure no RAM write conflict
        if arbiter_config_req = '1' and ram_wr_en = '0' then             -- and state_reg_ahbw = s0
          v.config_state := ARBITER_WR;
        else 
          v.config_state := IDLE;
        end if;

      when ARBITER_WR =>
        -- Exit if RAM write is active (to avoid conflict)
        if ram_wr_en = '1' then
          v.config_state := IDLE;
        end if;
        
        -- Process granted request
        if arbiter_grant_valid = '1' then
          v.start_preload_ram := '1';
          if empty_cmb = '0' then
            v.config_state := WRITE_REQ;
            remaining_writes_cmb <= to_unsigned(ram_read_num, 4);
            -- Set initial address directly from arbiter
            address_write_cmb <= std_logic_vector(unsigned(ahb_target_addr) - x"00000004");
          end if; 
        end if;

      when WRITE_REQ =>
        -- Exit if RAM write is active
        if (arbiter_config_req = '0') or (ram_wr_en = '1') then
          v.config_state := IDLE;
        end if;
        
        -- Determine burst size
  --      if remaining_writes > 4 then 
  --        beats_v := to_unsigned(4, beats'length);  -- Max burst of 4
  --      else
          beats_v := resize(remaining_writes, beats'length);
  --      end if;
          beats <= beats_v;

        -- Trigger FIFO read when ready
        if (empty_cmb = '0' and ctrl.o.update = '1' and (state_next_ahbw = s0 or state_next_ahbw = s4)) then
          v.data_valid := '1';
          r_update_out <= '1';  -- Read from FIFO
        end if; 
        
        -- Process write when data is ready
        if((state_reg_ahbw = s0 or state_reg_ahbw = s4) and r_update_reg = '1' and ctrl.o.update = '1') then
          v.data_valid := '0';
          
          -- Check if this is the last register
          if ahb_wr_cnt_reg = ram_read_num - 1 then
       --     address_write_cmb <= std_logic_vector(unsigned(ahb_target_addr) - x"00000004");
   --         config_done_cmb <= '1';
            v.config_state := config_enable;
            v.data_valid := '0';
          else 
            address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
            v.data_valid := '1';
          end if;
          
          -- Set up AHB transaction
          size_cmb <= "10";      -- 32-bit transfer
          htrans_cmb <= "10";    -- Non-sequential
          hburst_cmb <= '0';
          data_cmb <= data_out_fifo;
          
          -- Trigger write operation
          ahbwrite_cmb <= '1';
          remaining_writes_cmb <= remaining_writes - 1;
          ahb_wr_cnt_cmb <= ahb_wr_cnt_reg + 1;
          
          -- Start burst if multiple beats available
          if unsigned(beats_v) > 1 then
            hburst_cmb <= '1';
            v.config_state := AHB_Burst_WR;
          end if;
          if empty_cmb = '0' then
            appidle_cmb <= false;  -- Not idle if data is available
          else
            appidle_cmb <= true;   -- Set to idle if no data
          end if;
        end if; 

      when AHB_Burst_WR =>
        -- Exit if RAM write is active
        if (arbiter_config_req = '0') or (ram_wr_en = '1') then
          v.config_state := IDLE;
        end if;

        hburst_cmb <= '1';
        size_cmb <= "10";
        data_cmb <= data_out_fifo;
        debug_cmb <= 2;
        
        if ctrl.o.update = '1' then
          htrans_cmb <= "11";  -- Sequential transfer
          if r_update_reg = '1' then
            v.data_valid := '0';
            remaining_writes_cmb <= remaining_writes - 1;
            -- Check if this is the last register
            if ahb_wr_cnt_reg = ram_read_num  then
        --      address_write_cmb <= std_logic_vector(unsigned(ahb_target_addr) - x"00000004");
              v.config_state := config_enable;
            else 
              address_write_cmb <= std_logic_vector(unsigned(address_write) + x"00000004");
              ahb_wr_cnt_cmb <= ahb_wr_cnt_reg + 1;
            end if;
          end if;

          -- Trigger next FIFO read if needed
          if (empty_cmb = '0' and v.data_valid = '0' and (count_burst_cmb /= 0) and (state_reg_ahbw = s4)) then
            r_update_out <= '1';
            ahbwrite_cmb <= '1';
            appidle_cmb <= false;
            v.data_valid := '1';
          elsif v.data_valid = '0' then 
            appidle_cmb <= true;  
          end if;

          -- Check for end of burst
          if (state_reg_ahbw = s0) or (state_reg_ahbw = s2) then
            if ahb_wr_cnt_reg = ram_read_num then
 --             appidle_cmb <= true;               
              v.config_state := config_enable;
 --             config_done_cmb <= '1';
            end if;
          end if;
        end if;

      when config_enable =>                 -- write control register (0) assert
          beats <= to_unsigned(1, beats'length);  -- Reset beats to 1
          if ctrl.o.update = '1' and state_reg_ahbw = s0 then
            ahbwrite_cmb <= '1';
            address_write_cmb <= ahb_target_addr;
            data_cmb <= x"00000001";
            htrans_cmb <= "10";  -- non-Sequential transfer
            size_cmb <= "10";   -- 32-bit transfer
            hburst_cmb <= '0';  -- Single transfer
            /*
            if appidle = true then  
              appidle_cmb <= false;
              ahb_wr_cnt_cmb <= ahb_wr_cnt_reg + 1;
            else 
              v.config_state := IDLE;  -- Return to IDLE after writing control register
              config_done_cmb <= '1';
              appidle_cmb <= true;
            end if;
          end if;
        */
        config_done_cmb <= '1';
        v.config_state := IDLE;  -- Return to IDLE after writing control register
        end if;

      when ERROR =>
        -- Error handling - return to IDLE
        v.config_state := IDLE;

      when others =>
        v.config_state := IDLE;
    end case;

    -- RAM read control logic
    if r.ram_read_cnt < ram_read_num then
      if r.start_preload_ram = '1' then
        v.ram_rd_en := '1';
    --    v.data_in := ram_rd_data_cmb;
        v.ram_rd_addr := std_logic_vector(unsigned(ram_start_addr) + r.ram_read_cnt);
        v.ram_read_cnt := r.ram_read_cnt + 1;
      else
        v.ram_rd_en := '0';
      end if;
    else
      v.start_preload_ram := '0';
      v.ram_rd_en := '0';
      w_update_out <= '0'; 
      v.ram_read_cnt := (others => '0');
    end if;
   
    -- Pipeline RAM read operation
    if ram_rd_valid_cmb = '1' then
      v.data_in := ram_rd_data_cmb;
      w_update_out <= '1';
    else
      w_update_out <= '0';
    end if;

    rin <= v;    

  end process;
  
  comb_ahb: process (state_reg_ahbw, address_write_cmb, address_read_cmb, data_cmb, size_cmb, appidle_cmb, appidle, htrans_cmb, hburst_cmb, debug_cmb, 
  ahbwrite_cmb, rst_n, ctrl.o.update, ctrl_reg.i, ctrl.i, ahbread_cmb, beats, count_burst, burst_size)
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
  
  -- Instantiate config_arbiter_v3
  config_arbiter_inst : entity config_controller.config_arbiter_v3
    generic map (
      g_ram_addr_width => g_output_addr_width
    )
    port map (
      clk                  => clk,
      rst_n                => rst_n,
      compressor_status_HR => compressor_status_HR,
      compressor_status_LR => compressor_status_LR,
      compressor_status_H  => compressor_status_H,
      config_done          => config_done,
      config_req           => arbiter_config_req,
      start_add            => ram_start_addr,
      read_num             => ram_read_num,
      ahb_target_addr      => ahb_target_addr,
      grant                => arbiter_grant,
      grant_valid          => arbiter_grant_valid
    );

  -- Instantiate config_ram_8to32
  config_ram_inst : entity config_controller.config_ram_8to32
    generic map (
      INPUT_DATA_WIDTH  => g_input_data_width,
      INPUT_ADDR_WIDTH  => g_input_addr_width,
      INPUT_DEPTH       => g_input_depth,
      OUTPUT_DATA_WIDTH => g_output_data_width,
      OUTPUT_ADDR_WIDTH => g_output_addr_width,
      OUTPUT_DEPTH      => g_output_depth
    )
    port map (
      clk      => clk,
      rst_n    => rst_n,
      wr_en    => ram_wr_en,
      wr_addr  => wr_addr,
      wr_data  => wr_data,
      rd_en    => r.ram_rd_en,
      rd_addr  => r.ram_rd_addr,
      rd_data  => ram_rd_data_cmb,
      rd_valid => ram_rd_valid_cmb
    );
  
  -- Instantiate FIFO
  fifo_no_edac: entity shyloc_utils.fifop2_base(arch)
    generic map (
      RESET_TYPE => 0,
      W          => 32, 
      NE         => 10, 
      W_ADDR     => 4, 
      TECH       => 0
    )
    port map (
      clk      => clk, 
      rst_n    => rst_n, 
      clr      => r.clr,
      w_update => w_update_reg,
      r_update => r_update_out,
      hfull    => hfull_cmb, 
      empty    => empty_cmb, 
      full     => full_cmb, 
      afull    => afull_cmb, 
      aempty   => aempty_cmb, 
      data_in  => r.data_in,
      data_out => data_out_fifo
    );

end architecture rtl;