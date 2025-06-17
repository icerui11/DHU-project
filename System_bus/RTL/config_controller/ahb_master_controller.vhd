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
use config_controller.config_types_pkg.all;

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

    compressor_sel : in std_logic_vector(1 downto 0); -- "00"=CCSDS123+121, "01"=CCSDS121

    
    ctrli : out  ahbtbm_ctrl_in_type;          --! Control signals to communicate with AHB master module. 
    ctrlo : in ahbtbm_ctrl_out_type            --! Control signals to communicate with AHB master module. 
  );
end entity ahb_master_controller;

architecture rtl of ahb_master_controller is

  -- State machine states
  type config_state_type is (
    IDLE,              -- Waiting for start signal
 --   READ_CONFIG_SIZE,  -- Determine configuration size based on compressor selection
    READ_RAM,          -- Reading data from RAM
    AHB_REQUEST,       -- Requesting AHB bus
    AHB_ADDR_PHASE,    -- AHB address phase
    AHB_DATA_PHASE,    -- AHB data phase
    WAIT_RESPONSE,     -- Waiting for slave response
    CHECK_COMPLETE,    -- Check if all data transferred
    ERROR_STATE,       -- Error handling
    DONE               -- Configuration complete
  );
  type config_state_type is (IDLE, ARBITER, AHB_TRANSFER_HR, AHB_TRANSFER_LR, AHB_TRANSFER_H); 

   signal curr_state, next_state : config_state_type;
   signal ram_read_cnt : unsigned(3 downto 0); -- RAM read 

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
  signal data_valid, data_valid_cmb  : std_logic;
  -------------------------------
  
  --Trigger a write or read operation
  signal ahbwrite, ahbwrite_cmb, ahbread_cmb, ahbread : std_logic;
  --Counters
  -- Modified by AS: Counter width depending on compile-time parameters (instead of 32 fixed size)
  -- Modified by AS: new reverse counters in exchange of counter and counter_reg
  signal rev_counter, rev_counter_reg: unsigned((W_Nx_GEN + W_Nz_GEN - 1) downto 0);
  -- Modified by AS: beats, count_burst and burst_size widths reduced from 32 to 5 bits
  signal count_burst, count_burst_cmb, burst_size, burst_size_cmb, beats, beats_reg: unsigned (4 downto 0);
  ------------------
  
  -- Read flag for FIFO - allow reading from FIFO
  signal rd_in_reg, rd_in_out, allow_read, allow_read_reg: std_logic;
     
    -- Adapted clear to AHB clk. 
  signal clear_ahb: std_logic;
  -- Adapted config valid to AHB clk. 
  signal config_valid_adapted_ahb: std_logic;
  -- AHB status information
  signal ahb_status_s, ahb_status_ahb_cmb, ahb_status_ahb_reg: ahbm_123_status;

  -- arbitration signal
 -- signal grant : std_ulogic_vector(1 downto 0); -- AHB bus config abitration signal
 -- signal config_req : std_ulogic;               
  signal ram_start_addr : std_logic_vector(g_ram_addr_width downto 0); -- RAM start address for configuration data
  signal ram_read_num : std_logic_vector(2 downto 0);       -- Number of registers to read from RAM
  signal compressor_status : compressor_status_array; -- Compressor status for all compressors

 -- signal r, rin : reg_type;

  signal config_done : std_logic;  -- Configuration done signal, to execute the next compressor configuration  

  -- Signals for config_arbiter instance
  signal arbiter_grant       : std_logic_vector(1 downto 0);
  signal arbiter_grant_valid : std_logic;
  signal arbiter_config_req  : std_logic;

  -- determine ccsds123 or ccsds121
  signal ram_read_segment : std_logic := '0'; -- '0' for CCSDS123, '1' for CCSDS121

  -- Signals for config_ram_8to32
  signal ram_wr_en    : std_logic;                     -- Write enable signal
  signal ram_wr_addr  : std_logic_vector(6 downto 0);  -- Write address (7 bits)
  signal ram_wr_data  : std_logic_vector(7 downto 0);  -- Write data (8 bits)
  signal ram_rd_en    : std_logic;                     -- Read enable signal
  signal ram_rd_addr  : std_logic_vector(4 downto 0);  -- Read address (5 bits)
  signal ram_rd_data  : std_logic_vector(31 downto 0); -- Read data (32 bits)
  signal ram_rd_valid : std_logic;                     -- Read valid signal

  -- Function to get base address based on compressor selection
  function get_base_address(comp_sel : std_logic_vector(1 downto 0)) 
    return std_logic_vector is
  begin
    case comp_sel is
      when "00" => return ccsds123_1_base;
      when "01" => return ccsds123_2_base;
      when "10" => return ccsds121_base;
      when others => return ccsds123_1_base;
    end case;
  end function;

  -- Function to get configuration size
  function get_config_size(comp_sel : std_logic_vector(1 downto 0)) 
    return unsigned is
  begin
    case comp_sel is
      when "00" | "01" => return to_unsigned(ccsds123_cfg_size, 8);
      when "10" => return to_unsigned(ccsds121_cfg_size, 8);
      when others => return to_unsigned(ccsds123_cfg_size, 8);
    end case;
  end function;

--new definition
  signal r      : reg_type;
  signal rtrans : transfer_type;


begin

  -----------------------------------------------------------------------------  
  -- Output assignments
  -----------------------------------------------------------------------------
  ctrli <= ctrl.i;
  ctrl.o <= ctrlo;
  rd_in <= rd_in_out;

-- config request generation

process(clk, rst_n)
begin
    if rst_n = '0' then
        config_req <= '0';
    elsif clk'event and clk = '1' then
        if  then
            config_req <= '1'; -- Request configuration on entering IDLE state
        else
            config_req <= '0'; -- Clear request in other states
        end if;
    end if;
end process;

-- config fsm
process(clk, rst_n)
begin 
    if rst_n = '0' then
       curr_state <= IDLE;
    elsif clk'event and clk = '1' then
        curr_state <= next_state;
    end if;
end process;

process(arbiter_grant, arbiter_config_req, curr_state)
  variable v              : reg_type;
  variable inc            : unsigned(2 downto 0);  -- increment CFG number for CCSDS123 and CCSDS121 max 6, 
  variable tot_size       : std_logic_vector(15 downto 0);
  variable pointer        : std_logic_vector(4 downto 0);  -- RAM pointer for reading configuration data, 5 bits address
begin
    v := r; 

    case r.config_state is    
        when IDLE =>
           if arbiter_config_req = '1' and state_reg_ahbw = idle and rst_n = '1' then         -- arbiter grants config request
              v.config_state := ARBITER;      -- arbiter grant config request
           else 
              v.config_state := IDLE;           -- Stay in IDLE if no request
           end if;
        
        when ARBITER =>                    
          if arbiter_grant_valid = '1' then        -- Arbiter has granted a request
                v.config_state := AHB_TRANSFER;  -- Grant valid, proceed to AHB transfer
                v.ram_rd_en := '1';                -- Enable RAM read
                v.ram_rd_addr := r.ram_start_addr;
            else
                v.config_state :=  IDLE;             -- No valid grant, return to IDLE
            end if;
          end if;

        when AHB_TRANSFER =>
          v.ram_rd_en := '0';  -- Disable RAM read
          tot_size      := rtrans.size - inc;

          case arbiter_grant is
            when "00" => -- HR

              if ram_read_num - r.ahb_trans_cnt = 0 then 
                  v.config_state := IDLE;                       -- No more data to transfer, return to IDLE
              elsif r.hready
              if (ctrl.o.update = '1' and state_reg_ahbw = s0) then
                inc(conv_integer(r.trans_size(2 downto 0))) := '1';  -- 设置增量向量
                if tot_size > 0 then
                    v.ram_rd_en := '1';                  -- Enable RAM read
                    v.ram_rd_addr := std_logic_vector(unsigned(r.ram_start_addr) + inc);
                    v.ram_read_cnt := r.ram_read_cnt + 1;
                else
                    v.config_state := CHECK_COMPLETE;    -- All data transferred, check completion
                end if;
                   

           


                  if ram_addr_cnt < read_num then 
                    v.read_ram_en := '1';  --enable RAM read
                    v.ram_rd_addr := 
           
            when "01" =>  --LR


            when "10" =>   --H


            when others =>  -- No valid grant
                v.config_state := IDLE;  -- Return to IDLE state
          end case;
          


            
          

    end case;
end process;

process(curr_state, arbiter_grant)
begin
    ram_rd_en <= '0';
    ram_rd_addr <= (others => '0');
    case curr_state is
        when READ_RAM =>
            ram_rd_en <= '1';
            case arbiter_grant is
                when "00" => 
                    
                when "01" => ram_rd_addr <= some_address_01;
                when "10" => ram_rd_addr <= some_address_10;
                when others => ram_rd_addr <= (others => '0');
            end case;
        when others =>
            ram_rd_en <= '0';
            ram_rd_addr <= (others => '0');
    end case;
end process;



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




 -----------------------------------------------------------------------------  
  --! FSM to generate signals for AHB
  -----------------------------------------------------------------------------
  -- Modified by AS: signal appidle included in the sensitivity list. Data_burst removed from the sensitivity list --
  comb_ahb: process (state_reg_ahbw, address_write_cmb, address_read_cmb, data_cmb, size_cmb, appidle_cmb, appidle, htrans_cmb, hburst_cmb, debug_cmb, ahbwrite_cmb, rst_ahb, ctrl.o.update, ctrl_reg.i, ctrl.i, ahbread_cmb, beats, count_burst, burst_size)
    -------------------------------------
    begin  
      state_next_ahbw <= state_reg_ahbw;
      count_burst_cmb <= count_burst;
      burst_size_cmb <= burst_size;
      ctrl.i <= ctrl_reg.i;
      --ctrl.o <= ctrl_reg.o;
      case (state_reg_ahbw) is
        when idle =>
          --ctrl.o <= ctrlo_nodrive;
          ctrl.i <= ctrli_idle;
          if (rst_ahb = '1') then
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
config_arbiter_inst : entity work.config_arbiter
  generic map (
    g_ram_addr_width => g_ram_addr_width,  -- RAM address width
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
    grant              => arbiter_grant,
    grant_valid        => arbiter_grant_valid
  );


-- Instantiate config_ram_8to32
config_ram_inst : entity work.config_ram_8to32
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
    wr_addr     => ram_wr_addr,  -- Write address
    wr_data     => ram_wr_data,  -- Write data
    rd_en       => ram_rd_en,    -- Read enable signal
    rd_addr     => ram_rd_addr,  -- Read address
    rd_data     => ram_rd_data,  -- Read data output
    rd_valid    => ram_rd_valid  -- Read valid signal
  );
  
end architecture rtl;