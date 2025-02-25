----------------------------------------------------------------------------------------------------------------------------------
-- File Description  -- test harness for router_fifo_ctrl_top_tb_uvvm
-- introduced the UVVM framework for testbench, separate the instantiation
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	router_fifo_ctrl_top_th_uvvm.vhd
-- @ Engineer				  :	Rui yin
-- @ Date				    	:	24.02.2024
-- @ Version				  :	1.0
-- @ VHDL Version			:   2008

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;    -- t_channel (RX/TX)

library bitvis_vip_scoreboard;
use bitvis_vip_scoreboard.generic_sb_support_pkg.all;

library shyloc_121;
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

library shyloc_utils;
use shyloc_utils.amba.all;

context work.router_context;

library work;
use work.system_constant_pckg.all;

-- Test harness entity
entity router_fifo_ctrl_top_th_uvvm is
  generic(
    -- Clock and bit period settings
    GC_CLK_PERIOD                : time                 := 10 ns;
    GC_BIT_PERIOD                : time                 := 16 * GC_CLK_PERIOD;
  );
end entity router_fifo_ctrl_top_th_uvvm;

-- Test harness architecture
architecture struct of router_fifo_ctrl_top_th_uvvm is

    signal rst_n              : std_logic := '0';
    signal clk                : std_logic := '0';

    -- VVC spw
    signal spw_vvc_tx_data    : std_logic_vector(8 downto 0);
    signal spw_vvc_rx_data    : std_logic_vector(8 downto 0);

    -- Data Interface signals
    signal data_in_shyloc     : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    signal data_in_newvalid   : std_logic;
    signal data_out_shyloc    : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
    signal data_out_newvalid  : std_logic;
    
    -- Control signals

    signal force_stop         : std_logic;
    signal awaiting_config    : std_logic;
    signal ready              : std_logic;
    signal fifo_full          : std_logic;
    signal eop                : std_logic;
    signal finished           : std_logic;
    signal error              : std_logic;

    ----------------------------------------------------------------------
    -- Signal declarations for router_fifo_ctrl_top
    ----------------------------------------------------------------------
    signal rx_data_out		 : 	std_logic_vector(7 downto 0);
    signal rx_data_valid	 : 	std_logic;
    signal ccsds_ready_ext :  std_logic;
    -- SpaceWire Interface signals (using single mode)
    signal din_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal sin_p  : std_logic_vector(1 to g_num_ports-1) := (others => '0');
    signal dout_p : std_logic_vector(1 to g_num_ports-1);
    signal sout_p : std_logic_vector(1 to g_num_ports-1);
    
    signal spw_error : std_logic;

    -- create signal arrary for spw tx
    signal codecs               : r_codec_interface_array(1 to c_num_ports-1) := (others => c_codec_interface);
    signal reset_spw            : std_logic := '0';                                      -- activ high

begin
   
  -----------------------------------------------------------------------------
  -- Clock & Reset Generation
  -----------------------------------------------------------------------------
  clock_generator(clk, C_CLK_PERIOD);

  -----------------------------------------------------------------------------
  -- Instantiate the concurrent procedure that initializes UVVM
  -----------------------------------------------------------------------------
  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  -----------------------------------------------------------------------------
  -- Instantiate DUT
  -----------------------------------------------------------------------------
  --! Instantiate the SHyLoC_subtop component
  i_ShyLoc_top : entity work.ShyLoc_top_Wrapper(arch)
  port map(
      -- System Interface
      Clk_S             => clk,                    
      Rst_N             => reset_n_s,                   -- differe from reset_n
      
      -- Amba Interface
      AHBSlave121_In    => C_AHB_SLV_IN_ZERO,          --declared in router_package.vhd
      Clk_AHB           => clk_AHB,                  
      Reset_AHB         => reset_n_s,          
      AHBSlave121_Out   => open,
      
      -- AHB 123 Interfaces
      AHBSlave123_In    => C_AHB_SLV_IN_ZERO,
      AHBSlave123_Out   => open,
      AHBMaster123_In   => C_AHB_MST_IN_ZERO,
      AHBMaster123_Out  => open,
      
      -- Data Input Interface
      DataIn_shyloc     => rx_data_out,
      DataIn_NewValid   => rx_data_valid,
      
      -- Data Output Interface CCSDS121
      DataOut           => data_out_shyloc,
      DataOut_NewValid  => data_out_newvalid,

      Ready_Ext         => ccsds_ready_ext,           --input, external receiver not ready such external fifo is full
      
      -- CCSDS123 IP Core Interface
      ForceStop         => force_stop,
      AwaitingConfig    => awaiting_config,
      Ready             => ready,                     --output, configuration received and IP ready for new samples
      FIFO_Full         => fifo_full,
      EOP               => eop,
      Finished          => finished,
      Error             => error
  );

  i_router_ctrl_top: entity work.router_fifo_ctrl_top 
  generic map(
      g_num_ports        => g_num_ports,
      g_data_width       => g_data_width,
      g_addr_width       => g_addr_width
  )
  port map(
      rst_n              => rst_n,
      clk                => clk,
      rx_cmd_out         => open,
      rx_cmd_valid       => open,
      rx_cmd_ready       => '0',
      rx_data_out        => rx_data_out,
      rx_data_valid      => rx_data_valid,
      rx_data_ready      => ready,                      -- from SHyLoC
      ccsds_datain       => data_out_shyloc,            -- output data from SHyLoC 32-bit
      w_update           => data_out_newvalid,          -- write update signal
      asym_fifo_full     => open,
      ccsds_ready_ext    => ccsds_ready_ext,

      -- SpaceWire Interface
      din_p              => din_p,
      sin_p              => sin_p,
      dout_p             => dout_p,
      sout_p             => sout_p,

      spw_error          => spw_error,
      router_connected   => router_connected
  );
  

  gen_dut_tx: for i in 1 to g_num_ports-1 generate
     gen_spw_tx: if c_fifo_ports(i) = '0' generate
      SPW_inst: entity work.spw_wrap_top_level_RTG4(rtl)
        generic map(
        g_clock_frequency   =>	c_clock_frequency,  
        g_rx_fifo_size      =>  c_rx_fifo_size,      
        g_tx_fifo_size      =>  c_tx_fifo_size,      
        g_mode				=>  c_mode				
      )
      port map( 
        clock                => clk 					            	,
        reset                =>	reset_spw    				        ,

        -- Channels
        Tx_data              => codecs(i).Tx_data			      ,
        Tx_OR                =>	codecs(i).Tx_OR             ,
        Tx_IR                => codecs(i).Tx_IR             ,
        
        Rx_data              =>	codecs(i).Rx_data           ,
        Rx_OR                => codecs(i).Rx_OR             ,
        Rx_IR                => codecs(i).Rx_IR             ,
        
        Rx_ESC_ESC           => codecs(i).Rx_ESC_ESC        ,
        Rx_ESC_EOP           => codecs(i).Rx_ESC_EOP        ,
        Rx_ESC_EEP           => codecs(i).Rx_ESC_EEP        ,
        Rx_Parity_error      => codecs(i).Rx_Parity_error   ,
        Rx_bits              => codecs(i).Rx_bits           ,
        Rx_rate              => codecs(i).Rx_rate           ,
        
        Rx_Time              => codecs(i).Rx_Time           ,
        Rx_Time_OR           => codecs(i).Rx_Time_OR        ,
        Rx_Time_IR           => codecs(i).Rx_Time_IR        ,

        Tx_Time              => codecs(i).Tx_Time           ,
        Tx_Time_OR           => codecs(i).Tx_Time_OR        ,
        Tx_Time_IR           => codecs(i).Tx_Time_IR        ,
    
        -- Control	                                        
        Disable              => codecs(i).Disable           ,
        Connected            => codecs(i).Connected         ,
        Error_select         => codecs(i).Error_select      ,
        Error_inject         => codecs(i).Error_inject      ,
        
        -- SpW	                                           
        Din_p                => dout_p(i)             		  ,
        Sin_p                => sout_p(i)          		    	,
        Dout_p               => din_p(i)          			    ,
        Sout_p               => sin_p(i)          					         
    );
    codecs(i).Rx_IR <= '1';
    codecs(i).Rx_Time_IR <= '1';

    end generate gen_spw_tx;
  end generate gen_dut_tx;

  -----------------------------------------------------------------------------
  -- Clock Generator VVC
  -----------------------------------------------------------------------------

  i_clock_generator_vvc : entity bitvis_vip_clock_generator.clock_generator_vvc
    generic map(
      GC_INSTANCE_IDX    => 1,
      GC_CLOCK_NAME      => "Clock",
      GC_CLOCK_PERIOD    => GC_CLK_PERIOD,
      GC_CLOCK_HIGH_TIME => GC_CLK_PERIOD / 2
    )
    port map(
      clk => clk
    );

  p_model : process
 
  end process p_model;
  -----------------------------------------------------------------------------
  -- Reset
  -----------------------------------------------------------------------------
  p_arst : process
  begin
    rst_n <= '0';  
    reset_n_s <= '0';
    wait for 5 * GC_CLK_PERIOD;
    wait until rising_edge(clk);
    rst_n <= '1'; 
    reset_n_s <= '1'; 
    wait;
  end process p_arst;

end struct;
