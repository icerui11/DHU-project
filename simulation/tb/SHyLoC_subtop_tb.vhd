--============================================================================--
-- Design unit  : SHyLoC_subtop_tb Testbench for CCSDS-123 and CCSDS-121 top-level
--
-- File name    : SHyLoC_subtop_tb.vhd
--
-- Purpose      : Takes care of setting off configuration values, provide input samples and control signals received from the the IP core.
--
-- Note         :
--
-- Library      : work
--
-- Author       :Rui
--===============================================================


--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use standard library
library std;
--! Use user input/output
use std.textio.all;
use ieee.std_logic_textio.all;  
--! Use finish and stop
use std.env.all;

use work.ccsds_ahbtbp.all;
use work.ahbtbp.all;

--! Use shyloc_123 library
library shyloc_123;
--! Use testbench 123_parameters
use work.ccsds123_tb_parameters.all;
--! Use shyloc_123 ahb types
use shyloc_123.ccsds_ahb_types.all;
--! Use shyloc_123 configuration package
use shyloc_123.config123_package.all;

--! Use shyloc_121 library
library shyloc_121;
library post_syn_lib;
--! Use testbench 121_parameters
use work.ccsds121_tb_parameters.all;

--! Use grlib library and elements
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;

library shyloc_utils;
use shyloc_utils.amba.all;
use shyloc_utils.shyloc_functions.all;
entity SHyLoC_subtop_tb is
end SHyLoC_subtop_tb;

--! @brief Architecture of SHyLoC_subtop_tb 
architecture arch of SHyLoC_subtop_tb is
  
  signal clk, rst_n, clk_ahb, rst_ahb: std_logic;
  signal DataIn, s: std_logic_vector (work.ccsds123_tb_parameters.D_G_tb-1 downto 0);
  signal DataIn_NewValid, s_valid: std_logic;
  signal ls_out: std_logic_vector (work.ccsds123_tb_parameters.W_LS_G_tb-1 downto 0);
  signal sign: std_logic;
  signal counter: unsigned(1 downto 0);
  signal counter_samples: unsigned (31 downto 0);
  
  
  signal msto: grlib.amba.ahb_mst_out_vector;
  signal slvo: grlib.amba.ahb_slv_out_vector;

  signal ahbmi: grlib.amba.ahb_mst_in_type; --testbench
  signal ahbmo: grlib.amba.ahb_mst_out_type;
  
  signal ctrl  : work.ahbtbp.ahbtb_ctrl_type;
  signal ahbsi: grlib.amba.ahb_slv_in_type;
  signal ahbso: grlib.amba.ahb_slv_out_type;
  
  --for configuration
  signal AHBSlave123_In: shyloc_utils.amba.ahb_slv_in_type;
  signal AHBSlave123_Out: shyloc_utils.amba.ahb_slv_out_type;
  
  --for configuration for 121
  signal AHBSlave121_In: shyloc_utils.amba.ahb_slv_in_type;
  signal AHBSlave121_Out: shyloc_utils.amba.ahb_slv_out_type;
  
  signal AHBMaster123_In: shyloc_utils.amba.ahb_mst_in_type; --shyloc
  signal AHBMaster123_Out: shyloc_utils.amba.ahb_mst_out_type;
  
  signal config_valid: std_logic; 
  
  
  signal AwaitingConfig: Std_Logic;   --! The IP core is waiting to receive the configuration.
  signal Ready: Std_Logic;      --! Configuration has been received and the IP is ready to receive new samples.
  signal FIFO_Full: Std_Logic;    --! The input FIFO is full.
  signal EOP: Std_Logic;        --! Compression of last sample has started.
  signal Finished: Std_Logic;     --! The IP has finished compressing all samples.
  signal Error_s: Std_Logic;      --! There has been an error during the compression
  signal DataOut: Std_Logic_Vector (work.ccsds121_tb_parameters.W_BUFFER_G_tb-1 downto 0); 
  signal DataOut_Valid: Std_Logic; 
  signal IsHeaderOut: Std_Logic;    --! The data in DataOut corresponds to the header when the core is working as a pre-processor.
  signal NbitsOut: Std_Logic_Vector (6 downto 0);   --! Number of valid bits in the DataOut signal

  signal  AwaitingConfig_Ext: Std_Logic;  --! The IP core is waiting to receive the configuration.
  signal  Ready_Ext: Std_Logic;       --! Configuration has been received and the IP is ready to receive new samples.
  signal  FIFO_Full_Ext: Std_Logic;     --! The input FIFO is full.
  signal  EOP_Ext: Std_Logic;       --! Compression of last sample has started.
  signal  Finished_Ext: Std_Logic;    --! The IP has finished compressing all samples.
  signal  Error_Ext: Std_Logic;       --! There has been an error during the compression  
  
  signal clear: std_logic;
  
  --constant PREDICTION_TYPE: integer := 0;
  constant test_id: integer := 1;         --test 0 sends just sequential data.
  signal ForceStop,  ForceStop_Ext: std_logic;
  signal ForceStop_i : std_logic;
  
  ------------------files---------------------
  type bin_file_type is file of character;
  file stimulus: bin_file_type;
  file reference: bin_file_type;
  file output: bin_file_type;
  type ref_value_byte_type is array (0 to 7) of natural;
  signal ForceStop_reg: std_logic;  
  
  signal config_reg: config_word (0 to N_CONFIG_WORDS-1);
  
  signal Block_DataIn_Valid, Block_Ready_Ext, Block_IsHeaderIn, Ready_Ext_123: std_logic;
  signal Block_DataIn : std_logic_vector(work.ccsds123_tb_parameters.W_BUFFER_G_tb-1 downto 0); 
  signal Block_NBitsIn: std_logic_vector(5 downto 0);
  signal ErrorCode_Ext: std_logic_vector(3 downto 0);
  signal sim_successful: boolean := false;

begin

  
  ---------------------
  --! Clock generation
  ---------------------
  gen_clk: process
  begin
    clk <= '1';
    wait for work.ccsds123_tb_parameters.clk_ip;
    clk <= '0';
    wait for work.ccsds123_tb_parameters.clk_ip;
  end process;
  
  -------------------------
  --! Amba clock generation
  -------------------------
  gen_clk_ahb: process
  begin
    clk_ahb <= '1';
    wait for 50 ns;
    clk_ahb <= '0';
    wait for 50 ns;
  end process;
  
  ---------------------
  --! Reset generation
  ---------------------
  gen_rst: process
  begin
    rst_n <= '0';
    wait for 1000 ns;
    rst_n <= '1';
    wait for 200 ns;
    rst_n <= '1';
    wait;
  end process;
  
  ---------------
  --! Assignments
  ---------------
  Ready_Ext <= '1';
  sign <= '1';
  rst_ahb <= rst_n;
  
  ------------------------------------------------------------------------------------------
  --! Process to provide input input samples and control
  --! Read process is perform byte per byte and controlled to obtain the proper input sample
  ------------------------------------------------------------------------------------------
  gen_stim: process (clk, rst_n)
    variable pixel_file: character;
    variable value_high: natural;
    variable value_low: natural;
    variable s_in_var: std_logic_vector (work.ccsds123_tb_parameters.D_G_tb-1 downto 0);    
    variable ini : std_logic:= '1';
  begin
    if (rst_n = '0') then
      s <= (others => '0');
      counter <= (others => '0');
      counter_samples <= (others => '0');
      s_valid <= '0';
      ini := '1';
      ForceStop_reg <= '0';
    elsif (clk'event and clk = '1') then
      s_valid <= '0';
      counter <= counter + 1;
      ForceStop_reg <= ForceStop;
      if (Finished = '1' or ForceStop = '1') then
        file_close(stimulus);
        ini := '1';
        counter_samples <= (others => '0');
      else
        if (ini = '1') then
          file_open(stimulus, work.ccsds123_tb_parameters.stim_file, read_mode);
          ini := '0';
        else
          if counter_samples < work.ccsds123_tb_parameters.Nz_tb*work.ccsds123_tb_parameters.Nx_tb*work.ccsds123_tb_parameters.Ny_tb + 4 then 
            if (Ready = '1' and AwaitingConfig = '0') then
              if (test_id /= 0) then
                if (work.ccsds123_tb_parameters.EN_RUNCFG_G = 0) then
                  if (work.ccsds123_tb_parameters.D_G_tb <= 8) then
                    read(stimulus, pixel_file);
                    value_high := character'pos(pixel_file);
                    s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb)); --16 bits only
                  else
                    read(stimulus, pixel_file);
                    value_high := character'pos(pixel_file);
                    read(stimulus, pixel_file);         --16 bits only
                    value_low := character'pos(pixel_file);   --16 bits only
                    if (work.ccsds123_tb_parameters.ENDIANESS_tb = 0) then
                      s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, work.ccsds123_tb_parameters.D_G_tb-8));
                    else
                      s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb-8))   --16 bits only
                      & std_logic_vector(to_unsigned(value_low, 8));                          --16 bits only
                    end if;
                  end if;
                else
                  if (work.ccsds123_tb_parameters.D_tb <= 8) then
                    read(stimulus, pixel_file);
                    value_high := character'pos(pixel_file);
                    if (work.ccsds123_tb_parameters.D_G_tb = 16) then
                      s_in_var := "00000000" & std_logic_vector(to_unsigned(value_high, 8)); --16 bits only
                    else
                      s_in_var := std_logic_vector(to_unsigned(value_low, 8));        --16 bits only
                    end if;
                  else
                    read(stimulus, pixel_file);
                    value_high := character'pos(pixel_file);
                    read(stimulus, pixel_file);       --16 bits only
                    value_low := character'pos(pixel_file); --16 bits only
                    if (work.ccsds123_tb_parameters.ENDIANESS_tb = 0) then
                      s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, work.ccsds123_tb_parameters.D_G_tb-8));
                    else
                      s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb-8)) --16 bits only
                      & std_logic_vector(to_unsigned(value_low, 8)); --16 bits only
                    end if;
                  end if;
                end if;
                
              end if;
              counter_samples <= counter_samples+1;
              if (test_id = 0) then
                s <= std_logic_vector(unsigned(s) + 1);
              else
                s <= s_in_var;
              end if;
              s_valid <= '1';
            else
              s_valid <= '0';
            end if;
          else
            s_valid <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
--dataout process
  process (clk, rst_n)
  variable ini: integer := 0;
  variable fin: integer := 0;
  variable error_f : integer := 1;
  variable probe: std_logic_vector(7 downto 0);
  variable uns: unsigned (7 downto 0);
  variable int: integer;
  variable pixel_file: character;
  variable size: integer;
  variable status: FILE_OPEN_STATUS;
  variable AwaitingConfig_count: integer := 0;
begin
  if (clk'event and clk = '0') then
    if (rst_n = '0') then
      ini:= 0;
      fin := 0;
      AwaitingConfig_count := 0;
--			sim_successful <= false;
    elsif (ForceStop = '1') then
      assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
      file_close(output);
      ini:= 0;
      fin := 0;
      error_f := 0;
  --		sim_successful <= false;
    elsif (Error_s = '1') then
      if (error_f = 1) then
        assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
        file_close(output);
        ini:= 0;
        fin := 0;
        error_f := 0;
      end if;
--			sim_successful <= false;
    else
        if (DataOut_Valid = '1' and (AwaitingConfig = '0')) then 
          if (ini = 0) then
              file_open(output, work.ccsds123_tb_parameters.out_file, write_mode);
              ini:= 1;
              fin := 1;     
          end if;
--          sim_successful <= false;
          if (work.ccsds123_tb_parameters.EN_RUNCFG_G = 1) then
              size := work.ccsds121_tb_parameters.W_BUFFER_tb;
          else
              size := work.ccsds121_tb_parameters.W_BUFFER_tb;
          end if;
          for i in 0 to (size/8) -1 loop
                    probe:= DataOut((((size/8) -1-i)+1)*8-1 downto ((size/8) -1-i)*8);
                    uns := unsigned(probe);
                    int := to_integer(uns);
                    pixel_file:= character'val(int);
                    write(output,pixel_file);
             end loop;             
       end if;
       if AwaitingConfig = '1' then
          AwaitingConfig_count := AwaitingConfig_count + 1;
        end if;
       if (AwaitingConfig_count = 2) then
        if (fin = 1) then
          file_close(output);
          ini:= 0;
          fin := 0;
          error_f := 0;
          
        end if;
      end if;
    end if;
  end if;
end process;
  -----------------------------------------------------------------------------------------------------------------------------------------
  --! Process to read output words after some control, and to compare output words generated by the IP Core and the reference file provided
  -----------------------------------------------------------------------------------------------------------------------------------------
  gen_reference: process (clk, rst_n)
      variable pixel_file: character;
      variable ref_value_byte: ref_value_byte_type;
      variable value_high: natural;
      variable value_low: natural;
      variable value_high1: natural;
      variable value_low1: natural;
      variable pixel_read: std_logic_vector (work.ccsds121_tb_parameters.W_BUFFER_G_tb-1 downto 0);
      variable ini: integer := 1;
      variable compression_started: integer := 0;
      variable num_bytes: integer := 0;
      
      function ceil (A: integer; B: integer) return integer is
        variable q: integer := 0;
        variable r: integer := 0;
      begin
        q := A/B;
        r := A-q*B;
        if (r > 0) then
          q := q+1;
        end if; 
        return q;
      end function;
    begin
      if (rst_n = '0') then
        if (ini = 1) then
          file_open(reference, work.ccsds123_tb_parameters.ref_file, read_mode);
          ini := 0;
        end if;
      elsif (clk'event and clk = '1') then
        if DataOut_Valid = '1' then
          compression_started := 1;
          if Finished = '1' then
            if (Error_s = '1' or ForceStop = '1') then
              if (Error_s = '1') then
              assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
            else
              assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
            end if;file_close(reference);
              file_open(reference, work.ccsds123_tb_parameters.ref_file, read_mode);
              compression_started := 0;
            else 
              if (compression_started = 1) then
                if (not endfile(reference)) then
                  assert false report "Reference file has more samples" severity error;
                else
                  assert false report "Comparison was successful!" severity note;
                end if;
              file_close(reference);
              file_open(reference, work.ccsds123_tb_parameters.ref_file, read_mode);
              compression_started := 0;
              end if;
            end if;
          
          end if;
          
          if (work.ccsds123_tb_parameters.EN_RUNCFG_G = 1) then
          -- to consider: note that this will give problems if D_G_tb is not a multiple of 8
            if (work.ccsds123_tb_parameters.ENCODER_SELECTION_tb = 1 and work.ccsds123_tb_parameters.BYPASS_tb = 0) then    --sample_adaptive
              num_bytes := work.ccsds123_tb_parameters.W_BUFFER_tb/8;                         -- to consider: with the configurable or with the generic?!
            elsif (work.ccsds123_tb_parameters.ENCODER_SELECTION_tb = 2 and work.ccsds123_tb_parameters.BYPASS_tb = 0) then   --block_adaptive
              num_bytes := work.ccsds121_tb_parameters.W_BUFFER_tb/8;                         -- take into account bit width of CCSDS121 output
            else --only residuals
              if work.ccsds123_tb_parameters.D_tb = 8 then
                num_bytes := 2;
              else 
                num_bytes := ceil(work.ccsds123_tb_parameters.D_tb,8);
              end if;
            end if;
          else
            if (work.ccsds123_tb_parameters.ENCODING_TYPE_G_tb = 1) then      -- sample_adaptive
              num_bytes := work.ccsds123_tb_parameters.W_BUFFER_G_tb/8;
            elsif work.ccsds123_tb_parameters.ENCODER_SELECTION_tb = 2 then     -- block_adaptive
              num_bytes := work.ccsds121_tb_parameters.W_BUFFER_G_tb/8;
            else -- only residuals
              if work.ccsds123_tb_parameters.D_G_tb = 8 then
                num_bytes := 2;
              else
                num_bytes := ceil(work.ccsds123_tb_parameters.D_G_tb,8);
              end if;
            end if;
          end if;
          
--          for i in num_bytes - 1 downto 0 loop
--            read(reference, pixel_file);
--            ref_value_byte(i) := character'pos(pixel_file);
--            pixel_read((i+1)*8-1 downto i*8) := std_logic_vector(to_unsigned(ref_value_byte(i), 8));
--          end loop;
--          for i in pixel_read'high downto num_bytes*8 loop
--            pixel_read(i) := '0';
--          end loop;
--          
--          pixel_read := std_logic_vector(resize (unsigned(pixel_read), DataOut'length));
  --        if (pixel_read /= DataOut) then 
  --          assert false report "Problems in final stream" severity error;
   --       end if;
        end if;
        if Finished = '1' then
          if (Error_s = '1' or ForceStop_reg = '1') then
            if (Error_s = '1') then
              assert false report "Comparison not possible because there has not been compression performed (configuration error)" severity note;
            else
              assert false report "Comparison not possible because there has been a ForceStop assertion" severity note;
            end if;
            file_close(reference);
            file_open(reference, work.ccsds123_tb_parameters.ref_file, read_mode);
            compression_started := 0;
          else 
            if (compression_started = 1) then
--              if (not endfile(reference)) then
--                assert false report "Reference file has more samples" severity error;
--              else
                assert false report "Comparison was successful!" severity note;
              end if;
            file_close(reference);
            file_open(reference, work.ccsds123_tb_parameters.ref_file, read_mode);
            compression_started := 0;
            
          end if;
        
        end if;
      end if;
    end process;
  
  ---------------------
  --!@brief AMBA master
  ---------------------
  ahbtbm0 : entity work.ahbtbm(rtl)
  generic map(hindex => 0)
  port map(rst_ahb, clk_ahb, ctrl.i, ctrl.o, ahbmi, ahbmo);
  
  ----------------------
  --! AMBA masters vector
  ----------------------
  masters: for i in 2 to NAHBMST-1 generate
    msto(i).hconfig <= (others => (others => '0'));
  end generate;
  
  ---------------------
  --! AMBA slaves vector
  ---------------------
  slaves: for i in 3 to NAHBSLV-1 generate
    slvo(i).hconfig <= (others => (others => '0'));
  end generate;
  
  ----------------
  --! Memory slave
  ----------------
	-- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
	gen_slave_sim_memory: if PREDICTION_TYPE_tb = 1 or PREDICTION_TYPE_tb = 2 or PREDICTION_TYPE_tb = 4 generate
	---------------------
    ahbtbslv0 : entity work.ahbtbs(rtl)
    generic map(hindex => 0, haddr => ExtMemAddress_G_tb, hmask => 16#f00#, kbytes => 8196)
    port map(rst_ahb, clk_ahb, ahbsi, ahbso);
  end generate;
  
  ------------------------------------
  --! Memory slave (small size memory)
  ------------------------------------
  gen_slave_sim_memory_small: if PREDICTION_TYPE_tb = 0 or PREDICTION_TYPE_tb = 3 generate 
    ahbtbslv0 : entity work.ahbtbs(rtl)
    generic map(hindex => 0, haddr => ExtMemAddress_G_tb, hmask => 16#f00#, kbytes => 512)
    port map(rst_ahb, clk_ahb, ahbsi, ahbso);
  end generate;
  
  -----------------------------------------------------------------------------------------------
  --! AMBA configuration: 2 slaves (CCSDS-123 and memory) and 2 masters (testbench and CCSDS-123)
  -----------------------------------------------------------------------------------------------
	-- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
	gen_mst_2slv:  if ((PREDICTION_TYPE_tb = 1 or PREDICTION_TYPE_tb = 2 or PREDICTION_TYPE_tb = 4) and ENCODER_SELECTION_tb /= 2) generate  --two masters
	-----------------------
    -- 1 master: testbench
    -- 2nd master: ccsds123 ip
    -- 1 slave : ccsds123 ip
    -- 2nd slave : simulation memory
    msto(1).hbusreq <= AHBMaster123_Out.HBUSREQ;
    msto(1).HLOCK <= AHBMaster123_Out.HLOCK;
    msto(1).HTRANS <= AHBMaster123_Out.HTRANS;
    msto(1).HADDR <= AHBMaster123_Out.HADDR;
    msto(1).HWRITE <= AHBMaster123_Out.HWRITE;
    msto(1).HSIZE <= AHBMaster123_Out.HSIZE;
    msto(1).HBURST <= AHBMaster123_Out.HBURST;
    msto(1).HPROT <= AHBMaster123_Out.HPROT;
    msto(1).HWDATA <= AHBMaster123_Out.HWDATA;
    msto(1).hconfig <= (others => (others => '0'));
    msto(1).hindex <= 1;
    
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl)
      generic map (nahbm => 2, nahbs => 2, assertwarn => 1)
      port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo); 
  end generate;
  
  ----------------------------------------------------------------------------------------------------------
  --! AMBA configuration: 3 slaves (CCSDS-123, memory and CCSDS-121) and 2 masters (testbench and CCSDS-123)  
  ----------------------------------------------------------------------------------------------------------
	-- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
	gen_mst_3slv: if ((PREDICTION_TYPE_tb = 1 or PREDICTION_TYPE_tb = 2 or PREDICTION_TYPE_tb = 4) and ENCODER_SELECTION_tb = 2) generate
	------------------
    msto(1).hbusreq <= AHBMaster123_Out.HBUSREQ;
    msto(1).HLOCK <= AHBMaster123_Out.HLOCK;
    msto(1).HTRANS <= AHBMaster123_Out.HTRANS;
    msto(1).HADDR <= AHBMaster123_Out.HADDR;
    msto(1).HWRITE <= AHBMaster123_Out.HWRITE;
    msto(1).HSIZE <= AHBMaster123_Out.HSIZE;
    msto(1).HBURST <= AHBMaster123_Out.HBURST;
    msto(1).HPROT <= AHBMaster123_Out.HPROT;
    msto(1).HWDATA <= AHBMaster123_Out.HWDATA;
    msto(1).hconfig <= (others => (others => '0'));
    msto(1).hindex <= 1;
    
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl) 
      generic map (nahbm => 2, nahbs => 3, assertwarn => 1)
      port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo); 
  end generate;
  
  --------------------------------------------------------------------------------------------
  --! AMBA configuration: 2 slaves (CCSDS-123 and memory) and 1 master (testbench)
  --------------------------------------------------------------------------------------------
  not_gen_mst_2slv: if ((PREDICTION_TYPE_tb = 0 or PREDICTION_TYPE_tb = 3) and (ENCODER_SELECTION_tb /= 2)) generate 
    msto(1).hconfig <= (others => (others => '0'));
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl)
    generic map (nahbm => 1, nahbs => 2, assertwarn => 1) 
    port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo);
  end generate;
  
  -------------------------------------------------------------------------------------------
  --! AMBA configuration: 3 slaves (CCSDS-123, memory and CCSDS-121) and 1 master (testbench)
  -------------------------------------------------------------------------------------------
  not_gen_mst_3slv: if ((PREDICTION_TYPE_tb = 0 or PREDICTION_TYPE_tb = 3) and (ENCODER_SELECTION_tb = 2)) generate 
    msto(1).hconfig <= (others => (others => '0'));
    ----------------
    --! AMBA decoder
    ----------------
    ahbtbctrl : entity work.ahbctrl(rtl)
    generic map (nahbm => 1, nahbs => 3, assertwarn => 1) 
    port map(rst_ahb, clk_ahb, ahbmi, msto, ahbsi, slvo);
  end generate;
  
  ---------------
  --! Assignments
  ---------------
  msto(0) <= ahbmo;
  
  slvo(0) <= ahbso;
  
  slvo(1).hready <= AHBSlave123_Out.HREADY; 
  slvo(1).hresp <=  AHBSlave123_Out.HRESP;
  slvo(1).hrdata <=  AHBSlave123_Out.HRDATA;
  slvo(1).hsplit <=  AHBSlave123_Out.HSPLIT;
  slvo(1).hconfig <= (0 => zero32,  4 => ahb_membar(HSCONFIGADDR_tb, '1', '1', HSADDRMASK_tb),  others => zero32);
  slvo(1).hindex <= 1;
  
  slvo(2).hready <= AHBSlave121_Out.HREADY; 
  slvo(2).hresp <=  AHBSlave121_Out.HRESP;
  slvo(2).hrdata <=  AHBSlave121_Out.HRDATA;
  slvo(2).hsplit <=  AHBSlave121_Out.HSPLIT;
  slvo(2).hconfig <= (0 => zero32,  4 => ahb_membar(HSCONFIGADDR_121, '1', '1', HSADDRMASK_121),  others => zero32);
  slvo(2).hindex <= HSINDEX_121;
  
  AHBSlave123_In.HSEL <= ahbsi.hsel(1) after 5 ns;  
  AHBSlave123_In.HADDR <= ahbsi.haddr after 5 ns;   
  AHBSlave123_In.HWRITE <= ahbsi.hwrite after 5 ns;   
  AHBSlave123_In.HTRANS <= ahbsi.htrans after 5 ns;   
  AHBSlave123_In.HSIZE <= ahbsi.hsize after 5 ns; 
  AHBSlave123_In.HBURST <= ahbsi.hburst after 5 ns;   
  AHBSlave123_In.HWDATA <= ahbsi.hwdata after 5 ns;
  AHBSlave123_In.HPROT <= ahbsi.hprot after 5 ns;
  AHBSlave123_In.HREADY <= ahbsi.hready after 5 ns;
  AHBSlave123_In.HMASTER <= ahbsi.hmaster after 5 ns;
  AHBSlave123_In.HMASTLOCK <= ahbsi.hmastlock after 5 ns;
  
  AHBMaster123_In.HGRANT <= ahbmi.hgrant(1) after 5 ns;  
  AHBMaster123_In.HREADY <= ahbmi.hready after 5 ns;
  AHBMaster123_In.HRESP <= ahbmi.hresp after 5 ns;
  AHBMaster123_In.HRDATA <= ahbmi.hrdata after 5 ns;
  
  AHBSlave121_In.HSEL <= ahbsi.hsel(2);   
  AHBSlave121_In.HADDR <= ahbsi.haddr;  
  AHBSlave121_In.HWRITE <= ahbsi.hwrite; 
  AHBSlave121_In.HTRANS <= ahbsi.htrans;
  AHBSlave121_In.HSIZE <= ahbsi.hsize;  
  AHBSlave121_In.HBURST <= ahbsi.hburst; 
  AHBSlave121_In.HWDATA <= ahbsi.hwdata;
  AHBSlave121_In.HPROT <= ahbsi.hprot;
  AHBSlave121_In.HREADY <= ahbsi.hready;
  AHBSlave121_In.HMASTER <= ahbsi.hmaster;
  AHBSlave121_In.HMASTLOCK <= ahbsi.hmastlock;
  DataIn <= s after 10 ns;
  DataIn_NewValid <= s_valid after 10 ns;
  ForceStop_i <= ForceStop after 10 ns;
  
  ----------------------------
  --! External Ready selection
  ----------------------------
  Ready_Ext_123 <= Block_Ready_Ext when ENCODER_SELECTION_tb = 2 else '1';
  
  shyloc_wrapper: entity work.ShyLoc_top_Wrapper 
  port map (
    -- System Interface
    Clk_S => clk,
    Rst_N => rst_n,
    
    -- AHB Interfaces  
    AHBSlave121_In => AHBSlave121_In,
    AHBSlave121_Out => AHBSlave121_Out,
    Clk_AHB => clk_ahb,
    Reset_AHB => rst_ahb,
    AHBSlave123_In => AHBSlave123_In,
    AHBSlave123_Out => AHBSlave123_Out,
    AHBMaster123_In => AHBMaster123_In, 
    AHBMaster123_Out => AHBMaster123_Out,
  
    -- Data Interfaces
    DataIn_shyloc => s,                                           
    DataIn_NewValid => s_valid,

    DataOut => DataOut,
    DataOut_NewValid => DataOut_Valid,
    Ready_Ext => Ready_Ext,
  
    -- Control Signals
    ForceStop => ForceStop,
    AwaitingConfig => AwaitingConfig,
    Ready => Ready,
    FIFO_Full => FIFO_Full,
    EOP => EOP, 
    Finished => Finished,
    Error => Error_s
  );
  
    
    ----------------------------------------------------------
    --! Process to configurate CCSDS-123 and CCSDS-121 modules
    ----------------------------------------------------------
    configure: process
      variable address: std_logic_vector(31 downto 0);
        ---------------------
        --! 123 configuration
        ---------------------
        procedure test0 is
            variable ExtMemAddress_conf : integer := ExtMemAddress_G_tb;
            variable n_words: integer := 0;
        begin
            assert false report "Sending 123 configuration..." severity note;
            config_reg <= (others => (others => '0'));
            config_reg(1)(31 downto 0) <= std_logic_vector(to_unsigned(ExtMemAddress_conf, 12)) & std_logic_vector(to_unsigned(0, 20));
        
            config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.Nx_tb,16));
            config_reg(2)(15 downto 11) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.D_tb,5));
            config_reg(2)(10 downto 10) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.IS_SIGNED_tb,1));
            config_reg(2)(9 downto 9) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.DISABLE_HEADER_tb,1));
            config_reg(2)(8 downto 7) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.ENCODER_SELECTION_tb,2));
            config_reg(2)(6 downto 3) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.P_tb,4));
            config_reg(2)(2 downto 0) <= (others => '0');     

            config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.Ny_tb,16));
            config_reg(3)(15 downto 15) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.PREDICTION_tb,1));
            config_reg(3)(14 downto 14) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.LOCAL_SUM_tb,1));
            config_reg(3)(13 downto 9) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.OMEGA_tb,5));
            config_reg(3)(8 downto 2) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.R_tb,7));
            config_reg(3)(1 downto 0) <= (others => '0');   
        
            config_reg(4)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.Nz_tb,16));
            config_reg(4)(15 downto 11) <= std_logic_vector(to_signed(work.ccsds123_tb_parameters.VMAX_tb,5));
            config_reg(4)(10 downto 6) <= std_logic_vector(to_signed(work.ccsds123_tb_parameters.VMIN_tb,5));
            config_reg(4)(5 downto 2) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.TINC_tb,4));
            config_reg(4)(1 downto 1) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.WEIGHT_INIT_tb,1));
            config_reg(4)(0 downto 0) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.ENDIANESS_tb,1));
            
            config_reg(5)(31 downto 28) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.INIT_COUNT_E_tb,4));
            config_reg(5)(27 downto 27) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.ACC_INIT_TYPE_tb,1));
            config_reg(5)(26 downto 23) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.ACC_INIT_CONST_tb,4));
            config_reg(5)(22 downto 19) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.RESC_COUNT_SIZE_tb,4));
            config_reg(5)(18 downto 13) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.U_MAX_tb,6));
            config_reg(5)(12 downto 6) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.W_BUFFER_tb,7));
						-- Modified by AS: assigning new configuration parameters Q and WR --
						config_reg(5)(5 downto 1) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.Q_tb,5));
						config_reg(5)(0 downto 0) <= std_logic_vector(to_unsigned(work.ccsds123_tb_parameters.WR_tb,1));
						--config_reg(5)(5 downto 0) <= (others => '0');
						---------------------------

            config_reg(0)(0) <= '0';
            address := std_logic_vector(to_unsigned(16#200#, 12)) & std_logic_vector(to_unsigned(0, 20));
            wait until clk'event and clk = '1'; 
            --n_words := 7 + P_MAX + FULL*3 - 1;
            n_words := 6;
            ahbwrite(address, config_reg, "10", n_words, 2, ctrl);
            config_reg(0)(0) <= '1';
            ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
            wait until clk'event and clk = '1';
            
        end test0;
        ---------------------
        --! 121 configuration
        ---------------------
        procedure test0_121 is
          variable address: std_logic_vector(31 downto 0);
        begin
          assert false report "Sending 121 configuration..." severity note;
          config_reg(1)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.Nx_tb, 16));
          config_reg(1)(15 downto 15) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.CODESET_tb, 1));
          config_reg(1)(14 downto 14) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.DISABLE_HEADER_tb, 1));
          config_reg(1)(13 downto 7) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.J_tb, 7));
          config_reg(1)(6 downto 0)  <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.W_BUFFER_tb, 7));
          
          config_reg(2)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.Ny_tb, 16));
          config_reg(2)(15 downto 3) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.REF_SAMPLE_tb, 13));
          config_reg(2)(2 downto 0) <= (others => '0');
          
          config_reg(3)(31 downto 16) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.Nz_tb, 16));
          config_reg(3)(15 downto 10) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.D_tb, 6));
          config_reg(3)(8 downto 8) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.ENDIANESS_tb, 1));
          config_reg(3)(7 downto 6) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.PREPROCESSOR_tb, 2));
          config_reg(3)(5 downto 5) <= std_logic_vector(to_unsigned(work.ccsds121_tb_parameters.BYPASS_tb, 1));
          config_reg(3)(4 downto 0) <= (others => '0');     
          config_reg(0)(0) <= '0';
          address := x"10000000";
          wait until clk'event and clk = '1'; 
          ahbwrite(x"10000000", config_reg, "10", 4, 2, ctrl);
          config_reg(0)(0) <= '1';
          ahbwrite(address, config_reg(0), "10", "10", '1', 2, true , ctrl);
        end test0_121;
        
      -------------------------------------------------------------------------------------
      --! Check configuration (Necessary configuration rules to perform test with both IPs)
      -------------------------------------------------------------------------------------
      procedure check_tb_config is
      begin
        --IPs have to have the same image size
        if (work.ccsds121_tb_parameters.Nx_tb /= work.ccsds123_tb_parameters.Nx_tb) then
          assert false report "Wrong testbench configuration: configured Nx for CCSDS123 differs from CCSDS121" severity failure; 
        end if;
        if (work.ccsds121_tb_parameters.Ny_tb /= work.ccsds123_tb_parameters.Ny_tb) then
          assert false report "Wrong testbench configuration: configured Ny for CCSDS123 differs from CCSDS121" severity failure; 
        end if;
        if (work.ccsds121_tb_parameters.Nz_tb /= work.ccsds123_tb_parameters.Nz_tb) then
          assert false report "Wrong testbench configuration: configured Nz for CCSDS123 differs from CCSDS121" severity failure; 
        end if;
        -- IPs have to have the same EN_RUNCFG and RESET_TYPES
        if (work.ccsds121_tb_parameters.EN_RUNCFG_G /= work.ccsds123_tb_parameters.EN_RUNCFG_G) then
          assert false report "Wrong parameters configuration: selected EN_RUNCFG value for CCSDS123 differs from EN_RUNCFG value in CCSDS121 check your ccsds121_parameters.vhd and ccsds123_parameters.vhd files" severity failure; 
        end if;
        
        if (work.ccsds121_tb_parameters.RESET_TYPE /= work.ccsds123_tb_parameters.RESET_TYPE) then
          assert false report "Wrong parameters configuration: selected RESET_TYPE value for CCSDS123 differs from RESET_TYPE value in CCSDS121 check your ccsds121_parameters.vhd and ccsds123_parameters.vhd files" severity failure; 
        end if;
        
        if (work.ccsds123_tb_parameters.ENCODER_SELECTION_tb = 2) then
          if (work.ccsds123_tb_parameters.W_BUFFER_tb /= work.ccsds123_tb_parameters.W_BUFFER_tb) then
            assert false report "Wrong testbench configuration: configured output bit widths in IP cores differ" severity failure;
          end if;
        end if;
      
      end check_tb_config;
    
   begin
    print("**********************************************************");
    print("Starting simulation of test: "&test_identifier);
    print("**********************************************************");
    -- Initialize the control signals
    ForceStop <= '0';
    clear <= '0';
    -- take a moment to see if the tb configuration is ok
    check_tb_config;
    wait for (500 ns);
    -- Initialize the control signals
    ahbtbminit(ctrl);
    assert (Finished /= '1') report "Finished started with a high value" severity warning;
    assert (Ready /= '1') report "Ready started with a high value" severity warning;
    assert (AwaitingConfig /= '0') report "AwaitingConfig started with a low value" severity warning;
    test0;
    test0_121;
    wait until Finished = '1';
    assert false report "One compressions test performed" severity note;
    sim_successful <= true;
    ahbtbmdone(1, ctrl);
    print("**********************************************************");
    print("         CCSDS-123+CCSDS-121    Testbench Done");
    print("**********************************************************");
    assert false report "**** CCSDS-123+CCSDS-121 Testbench done ****" severity note; 
    stop(0);
   end process;
    
end arch;
