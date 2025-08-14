--============================================================================--
-- Copyright 2019 University of Las Palmas de Gran Canaria 
--
-- Institute for Applied Microelectronics (IUMA)
-- Campus Universitario de Tafira s/n
-- 35017, Las Palmas de Gran Canaria
-- Canary Islands, Spain
--
-- This code may be freely used, copied, modified, and redistributed
-- by the European Space Agency for the Agency's own requirements.
--============================================================================--
-- ESA IP-CORE LICENSE
--
-- This code is provided under the terms of the
-- ESA Licence (Agreement) on Synthesisable HDL Models,
-- which you have signed prior to receiving the code.
--
-- The code is provided "as is", there is no warranty that
-- the code is correct or suitable for any purpose,
-- neither implicit nor explicit. The code and the information in it
-- contained do not necessarily reflect the policy of the
-- European Space Agency or of <originator>.
--
-- No technical support is available from ESA for this IP core,
-- however, news on the IP will be posted on the web page:
-- http://www.esa.int/TEC/Microelectronics
--
-- Any feedback (bugs, improvements etc.) shall be reported to ESA
-- at E-Mail IpCoreRequest@esa.int
--============================================================================--
-- Design unit  : block coder top module (old ccsds121 top module)
--
-- File name    : ccsds121_blockcoder_top.vhd
--
-- Purpose      : Component instantiation of the ccsds121 block coder components, and control signals management 
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es, ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es
--
-- Instantiates : fsm (ccsds121_shyloc_fsm), sync_ahb_reset(reset_sync(two_ff)), sync_s_reset(reset_sync(two_ff)), ahbtbslv (ccsds121_ahbtbs), clk_adapt(ccsds121_clk_adapt), fifo_datain (fifop2), fifo_headerin (fifop2), fifo_nbits_headerin (fifop2), outputfifo (fifop2), components (ccsds121_shyloc_comp)
--============================================================================

--!@file #ccsds121_shyloc_top.vhd#
-- File history:
--      v2.0 modified by Rui Yin, 08.2025 for seperate compressor instantiation

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;


library VH_compressor;
--! Use specific shyloc121 parameters
use VH_compressor.VH_ccsds121_parameters.all;
use VH_compressor.ccsds121_constants_VH.all;

--! Use shyloc_utils library
library shyloc_utils;
--! Use shyloc functions
use shyloc_utils.shyloc_functions.all;
--! Use amba functions
use shyloc_utils.amba.all;

--! ccsds121_blockcoder_top entity  Top module of the CCSDS121- Block Coder
--! Component instantiation of the ccsds121 components, and control signals management 
entity ccsds121_blockcoder_top_VH is
    generic (
    RESET_TYPE           : integer := RESET_TYPE;         --! (0) Asynchronous reset; (1) Synchronous reset   
    HSINDEX_121          : integer := HSINDEX_121;        --! AHB slave index   
    HSCONFIGADDR_121     : integer := HSCONFIGADDR_121;   --! ADDR field of the AHB Slave  
  
    D_GEN                : integer := D_GEN;              --! Maximum dynamic range of the input samples  

    J_GEN                : integer := J_GEN;              --! Block Size  

    W_BUFFER_GEN         : integer := W_BUFFER_GEN;       --! Bit width of the output buffer  
    -- These parameters control integration with external systems  
    PREPROCESSOR_GEN     : integer := PREPROCESSOR_GEN;   --! (0) No preprocessor; (1) CCSDS123 preprocessor; (2) Other preprocessor  
    TECH                 : integer := TECH               --! Memory technology selection  
    );
  port (
    -- System Interface
    Clk_S: in std_logic;            --! Clock signal.
    Rst_N: in std_logic;            --! Reset signal. Active low.
    
    -- Amba Interface
    AHBSlave121_In   : in ahb_slv_in_type;    --! AHB slave input signals.
    Clk_AHB      : in std_logic;        --!  AHB clock.
    Reset_AHB    : in std_logic;        --! AHB reset.
    AHBSlave121_Out  : out ahb_slv_out_type;    --! AHB slave output signals.
    
    -- Data Input Interface
    DataIn      : in std_logic_vector(D_GEN-1 downto 0);  --! Input data sample (uncompressed samples).
    DataIn_NewValid  : in std_logic;                --! Flag to validate input signals.
    IsHeaderIn    : in std_logic;               --! The data in DataIn corresponds to the header of a pre-processor block.
    NbitsIn      : in Std_Logic_Vector (5 downto 0);      --! Number of valid bits in the input header.      
    
    -- Data Output Interface
    DataOut        : out std_logic_vector (W_BUFFER_GEN-1 downto 0);  --! Output compressed bit stream.
    DataOut_NewValid  : out std_logic;                  --! Flag to validate output bit stream.
        
    -- Control Interface
    ForceStop    : in std_logic;             --! Force the stop of the compression.
    Ready_Ext    : in std_logic;             --! External receiver not ready.
    -- Modified by AS: new interface ports --
    config_s_out    : out config_121;            --! Configuration for the unit-delay predictor
    config_valid_out: out std_logic;            --! Config valid signal for the unit-delay predictor
    Stop_pred    : out std_Logic;            --! Stop signal for the unit-delay predictor
    control_pred  : in ctrls;                --! Status flags from predictor
    ------------------------------------
    AwaitingConfig  : out std_logic;             --! The IP core is waiting to receive the configuration.
    Ready      : out std_logic;             --! Configuration has been received and the IP is ready to receive new samples.
    FIFO_Full    : out std_logic;             --! The input FIFO is full.
    EOP        : out std_logic;             --! Compression of last sample has started.
    Finished    : out std_logic;             --! The IP has finished compressing all samples.
    Error      : out std_logic             --! There has been an error during the compression.
      
  );
end ccsds121_blockcoder_top_VH;

--! @brief Architecture of ccsds121_blockcoder_top 
architecture arch of ccsds121_blockcoder_top_VH is

  -- AHB slave interface signals
  signal ahb_clear     : std_logic;
  signal control_out_ahb  : ctrls;
  signal ahb_config    : config_121;
  signal error_ahb    : std_logic;
  signal ahb_valid     : std_logic;
  
  -- Clock adatation signals
  signal config_s      : config_121;
  signal control_out_s   : ctrls;
  signal clear_ahb_ack_s  : std_logic;  
  signal error_s_out    : std_logic;  
  signal valid_s      : std_logic;
  -- Modified by AS: new signal to combine the status flags of predictor and entropy coder --
  signal control_comb_s  : ctrls;
  ------------------------------------
  
  -- FIFO data_in signals
  signal mapped_DataIn      : std_logic_vector (D_GEN-1 downto 0);  
  signal w_fifo_datain      : std_logic;
  signal fifo_datain_empty    : std_logic;
  signal fifo_datain_aempty    : std_logic;
  signal r_fifo_datain      : std_logic;
  signal DataIn_end_reg      : std_logic_vector(D_GEN-1 downto 0);
  signal fifo_datain_full_aux    : std_logic;
  signal fifo_datain_afull_aux   : std_logic;
  
  -- FIFO header_in signals
  signal w_fifo_headerin      : std_logic;
  signal r_fifo_headerin      : std_logic;
  signal fifo_headerin_full    : std_logic;
  signal fifo_headerin_empty    : std_logic;
  signal fifo_headerin_aempty    : std_logic;
  signal header_DataIn      : std_logic_vector(D_GEN-1 downto 0);  
    
  -- FIFO header_in_NBits
  signal fifo_nbits_headerin_full    : std_logic;
  signal fifo_nbits_headerin_empty  : std_logic;
  signal fifo_nbits_headerin_aempty  : std_logic;
  signal header_nbits_DataIn      : std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0);
  
  -- Output FIFO
  signal buff_full_aux      : std_logic;
  signal r_fifo_dataout      : std_logic;
  signal buff_out_aux       : std_logic_vector(W_BUFFER_GEN-1 downto 0);
  signal output_fifo_dataout_d   : std_logic_vector(W_BUFFER_GEN-1 downto 0);
  signal fifo_dataout_empty    : std_logic;
  signal fifo_dataout_aempty    : std_logic;
  signal fifo_dataout_full    : std_logic;
  
  -- Component interconecction signals 
  
    -- Configuration signals 
    signal en_interface    : std_logic;
    signal config_valid    : std_logic;
    signal config_int    : config_121;
    signal error_out    : std_logic;
    signal error_code_out  : std_logic_vector(3 downto 0);
    
    -- header signals
    signal en_header121    : std_logic;
    
    -- second extension signals 
    signal en_sndextension    : std_logic;
    signal clear_sndextension  : std_logic;
    
    -- lk_computation signals
    signal en_lk      : std_logic;
    signal en_k_winner    : std_logic;
    signal clear_lkoptions  : std_logic;
    signal zero_code    : std_logic_vector (1 downto 0);
    signal eos        : std_logic;
    signal dump_zeroes    : std_logic;
    -- Modified by AS: new interconnection signal --
    signal zero_count_int    : std_logic_vector (W_ZERO_GEN-1 downto 0);
    signal ref_block_lk    : std_logic;
    ------------------------------------
    
    -- option coder signals 
    signal en_optcoder    : std_logic;
    signal option       : std_logic_vector (W_OPT_GEN-1 downto 0);
    
    -- fscoder signals
    signal en_fscoder    : std_logic;
    signal start_fscoder  : std_logic;
    -- Modified by AS: new interconnection signal --
    signal ref_block_fs    : std_logic;
    ------------------------------------
  
    -- splitpacker signals
    signal en_bitpack_split    : std_logic;
    signal flush_split      : std_logic;
    
    -- split signals
    signal en_splitter    : std_logic;
    signal start_splitter  : std_logic;
    
    -- packing final signals
    signal flag_pack_fs          : std_logic;
    signal en_bitpack_final        : std_logic;
    signal flag_split_fifo        : std_logic;
    signal flag_split_flush_register  : std_logic;
    signal flush_final          : std_logic;
    signal flag_pack_header        : std_logic;
    signal flag_pack_header_prep    : std_logic;
    signal flag_pack_bypass        : std_logic;
    
    
    -- mapped FIFO
    signal w_update_mapped  : std_logic;
    signal r_update_mapped  : std_logic;
    signal empty_mapped    : std_logic;
    signal full_mapped    : std_logic;
    signal afull_mapped    : std_logic;
    signal aempty_mapped  : std_logic;  
    
    -- gamma fifo
    signal r_update_gamma  : std_logic;
    signal empty_gamma    : std_logic;
    signal full_gamma    : std_logic;
    signal afull_gamma    : std_logic;
    signal aempty_gamma    : std_logic;
    
    -- FIFO split
    signal r_update_split  : std_logic;
    signal we_fifo_split  : std_logic;
    signal empty_split    : std_logic;
    signal full_split    : std_logic;
    signal afull_split    : std_logic;
    signal aempty_split    : std_logic;
  
  -- fsm signals
  signal clear_f        : std_logic;
  signal eop_fsm        : std_logic;
  signal last_DataIn      : std_logic;
  signal last_DataIn_Reg, last_DataIn_cmb    : std_logic;
  signal w_update_fifo_datain  : std_logic;
  signal zero_mapped      : std_logic;
  signal fsm_invalid_state  : std_logic;
  signal comp_error      : std_logic;
  
  -- General purpose signals 
  signal clear            : std_logic;
  signal counter_requested_samples  : unsigned(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);
  -- Constants for fifo_datain and fifo_headerin FIFOs
  constant NE_FIFO          : integer := 2*J_GEN + 4;         
  constant W_ADDR_FIFO        : integer := shyloc_utils.shyloc_functions.log2(NE_FIFO);
  constant NE_FIFO_NBITSHEADER    : integer := 2*J_GEN + 4;
  constant W_ADDR_FIFO_NBITSHEADER  : integer := shyloc_utils.shyloc_functions.log2(NE_FIFO_NBITSHEADER);
  signal DataIn_end          : std_logic_vector(D_GEN-1 downto 0);  
  
  type state_type is (idle, compressing, stopped);
  signal state_next, state_reg    : state_type;
  
  ---------------
  signal buff_out        : std_logic_vector (W_BUFFER_GEN-1 downto 0);
  signal buff_full      : std_logic;
  signal SAwaitingConfig_reg  : std_logic;
  signal SAwaitingConfig_cmb  : std_logic;
  signal SReady_reg      : std_logic;
  signal SReady_cmb      : std_logic;
  signal SError_reg      : std_logic;
  signal SError_cmb      : std_logic;
  signal SErrorCode_reg    : std_logic_vector(3 downto 0);
  signal SErrorCode_cmb    : std_logic_vector(3 downto 0);
  signal SFinished_reg     : std_logic;
  signal SFinished_cmb     : std_logic;
  signal Ready_Ext_reg    : std_logic;
  signal ErrorCode    : std_logic_vector(3 downto 0);    --! Code of the error.
  ---------------
  
  -- Local reset
   signal rst_n_sync: std_Logic;       
   signal rst_ahb_sync: std_Logic; 
  
  signal number_of_samples_out  : std_logic_vector(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);
  signal number_of_samples    : unsigned(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);
  
begin

  ------------------------------------
  --! Data Output Interface assignments
  ------------------------------------
  DataOut <= buff_out;
  DataOut_NewValid <= buff_full;
  
  ---------------------------------------
  --! Control Output Interface assignments
  ---------------------------------------
  Ready <= SReady_cmb;
  EOP <= (eop_fsm);
  -- Modified by AS: control output assignments when unit-delay predictor is not present --
  -- -- FIFO_Full beheaviour is modified to match specifications (detect write error) --
  gen_ctrlout_nopred: if (PREPROCESSOR_GEN /= 2) generate
    AwaitingConfig <= SAwaitingConfig_cmb;
    Finished <= SFinished_cmb;
    --FIFO_Full <= fifo_datain_full_aux or fifo_datain_afull_aux;
    FIFO_Full <= fifo_datain_full_aux and w_fifo_datain;
    Error <= SError_cmb or fsm_invalid_state;
    ErrorCode <= SErrorCode_cmb;
  end generate gen_ctrlout_nopred;
  -- Control output assignments with unit-delay predictor --
  gen_ctrlout_pred: if (PREPROCESSOR_GEN = 2) generate
    AwaitingConfig <= control_comb_s.AwaitingConfig;
    Finished <= control_comb_s.Finished;
    FIFO_Full <= control_comb_s.FIFO_Full;
    Error <= control_comb_s.Error;
    ErrorCode <= control_comb_s.ErrorCode;
  end generate gen_ctrlout_pred;
  
  
  --config_s_out <= config_s;
  config_s_out <= config_int;
  ------------------------------------
  
  --
  --ErrorCode <= SErrorCode_cmb;
  -- Modified by AS: clear (stop) and config_valid signals made external for the unit-delay predictor
  config_valid_out <= config_valid;
  Stop_pred <= clear_f;
  ------------------------------------
  
  --------------------------------------
  --! Control output register assignments
  --------------------------------------
  control_out_s.EOP <= (eop_fsm);
  -- Modified by AS: control register assignments when unit-delay predictor is not present --
  -- -- FIFO_Full beheaviour is modified to match specifications (detect write error) --
  gen_ctrlreg_nopred: if (PREPROCESSOR_GEN /= 2) generate
    control_out_s.AwaitingConfig <= SAwaitingConfig_cmb;
    control_out_s.Ready <= SReady_cmb;
    control_out_s.FIFO_Full <= fifo_datain_full_aux and w_fifo_datain;
    control_out_s.Finished <= SFinished_cmb;
    control_out_s.Error <= SError_cmb or fsm_invalid_state;
    control_out_s.ErrorCode <= SErrorCode_cmb;
  end generate gen_ctrlreg_nopred;
  -- Control output assignments with unit-delay predictor --
  gen_ctrlreg_pred: if (PREPROCESSOR_GEN = 2) generate
    control_out_s.AwaitingConfig <= control_comb_s.AwaitingConfig;
    control_out_s.Ready <= control_pred.Ready;
    control_out_s.FIFO_Full <= control_comb_s.FIFO_Full;
    control_out_s.Finished <= control_comb_s.Finished;
    control_out_s.Error <= control_comb_s.Error;
    control_out_s.ErrorCode <= control_comb_s.ErrorCode;
  end generate gen_ctrlreg_pred;
  ------------------------------------
  
  --
  --control_out_s.ErrorCode <= SErrorCode_cmb;

  clear <= clear_f;
  comp_error <= fsm_invalid_state or error_out;
  
  -- Modified by AS: combination of status flags from predictor and block coder (with unit-delay predictor) --
  gen_ctrl_comb: if (PREPROCESSOR_GEN = 2) generate
    control_comb_s.AwaitingConfig <= SAwaitingConfig_cmb and control_pred.AwaitingConfig;
    control_comb_s.FIFO_Full <= (fifo_datain_full_aux and w_fifo_datain) or control_pred.FIFO_Full;
    --control_comb_s.Finished <= SFinished_cmb and control_pred.Finished;
    control_comb_s.Finished <= SFinished_cmb;
    control_comb_s.Error <= SError_cmb or fsm_invalid_state or control_pred.Error;
    control_comb_s.ErrorCode <= SErrorCode_cmb or control_pred.ErrorCode;
  end generate gen_ctrl_comb;
  ------------------------------------
  
  ----------------------
  --! Input data control 
  ----------------------
  --w_fifo_datain <= ((DataIn_NewValid and not IsHeaderIn)) when (last_DataIn = '0' and SReady_reg = '1')else
     w_fifo_datain <= ((DataIn_NewValid and not IsHeaderIn)) when (last_DataIn = '0' and last_DataIn_reg = '0') else
            w_update_fifo_datain;
  DataIn_end_reg <= DataIn_end when w_update_fifo_datain= '0' else
            (others => '0');
  
  ---------------------------
  --! Endianess consideration - now moved to top
  ---------------------------
  
  DataIn_end <= DataIn;
  
  -- gen_endianess_swap: if ((D_GEN > 8) and (PREPROCESSOR_GEN /= 2)) generate
  --  DataIn_end <=  DataIn(D_GEN-9 downto 0)& DataIn(D_GEN-1 downto D_GEN-8) when (config_int.ENDIANESS = "0" and config_int.BYPASS = "0" and unsigned(config_int.D) > 8) else
  --          DataIn;
  --end generate gen_endianess_swap;

  --gen_endianess_noswap: if ((D_GEN <= 8) or (PREPROCESSOR_GEN = 2)) generate
  --  DataIn_end <= DataIn;
  --end generate gen_endianess_noswap;

  --gen_endianess_swap_32: if (D_GEN > 24 and (PREPROCESSOR_GEN /= 2)) generate
  --  DataIn_end <= DataIn(7 downto 0)&DataIn(15 downto 8)&DataIn(23 downto 16)&DataIn(D_GEN-1 downto 24) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 24)) 
  --    else DataIn(D_GEN-1 downto 24)&DataIn(7 downto 0)&DataIn(15 downto 8)&DataIn(23 downto 16) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 16)) 
  --    else DataIn(D_GEN-1 downto 16)&DataIn(7 downto 0)&DataIn(15 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
  --    else DataIn;
  --end generate gen_endianess_swap_32;

  --gen_endianess_swap_24: if (((D_GEN > 16) and(D_GEN <= 24)) and (PREPROCESSOR_GEN /= 2)) generate
  --  DataIn_end <= DataIn(7 downto 0)&DataIn(15 downto 8)&DataIn(D_GEN-1 downto 16) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 16)) 
  --    else DataIn(D_GEN-1 downto 16)&DataIn(7 downto 0)&DataIn(15 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
  --    else DataIn;
  --end generate gen_endianess_swap_24;

  --gen_endianess_swap_16: if (((D_GEN > 8) and(D_GEN <= 16))and (PREPROCESSOR_GEN /= 2)) generate
  --  DataIn_end <= DataIn(7 downto 0)&DataIn(D_GEN-1 downto 8) when ((config_s.ENDIANESS = "0") and (config_s.BYPASS) = "0" and (unsigned(config_s.D) > 8))
  --    else DataIn;
  --end generate gen_endianess_swap_16;
  
  --gen_endianess_noswap: if ((D_GEN <= 8) or (PREPROCESSOR_GEN = 2)) generate
  --  DataIn_end <= DataIn;
  --end generate gen_endianess_noswap;
  
  ---------------------------------
  --! fifo_headerin writing control
  ---------------------------------
  w_fifo_headerin <= (DataIn_NewValid and IsHeaderIn); 
  
  --------------------------------
  --! fifo_dataout reading control
  --------------------------------
  r_fifo_dataout <= not (fifo_dataout_empty) and Ready_Ext when SAwaitingConfig_cmb = '0' else
            '0';
  buff_out <= output_fifo_dataout_d;

  
  ---------------------------
  --!@brief fsm
  ---------------------------
  fsm: entity VH_compressor.ccsds121_shyloc_fsm(arch)
    generic map (
      W_MAP => D_GEN,
      W_NBITS_K =>W_NBITS_K_GEN, 
      W_BUFFER => W_BUFFER_GEN,
      --N_SAMPLES => N_SAMPLES_GEN, 
      W_N_SAMPLES => W_N_SAMPLES_GEN,
      BLOCK_SIZE => J_GEN,
      RESET_TYPE => RESET_TYPE,
      -- Modified by AS & YB: new generic assigment 
      W_ZERO => W_ZERO_GEN
      --------------------
    )
    port map (
      Clk => Clk_S, 
      rst_n => rst_n_sync, 
      config_valid => config_valid,
      error => comp_error,
      enable => config_s.ENABLE(0),
      config_int => config_int,
      valid_ahb_s => valid_s,
      clear => ForceStop,
      finished_out => clear_f,      
      eop => eop_fsm,
      en_interface_out => en_interface,
      en_header_out => en_header121,
      --last_DataIn => last_DataIn,
      -- Modified by AS: new interface ports --
      zero_count => zero_count_int,
      ref_block_lk => ref_block_lk,
      ref_block_fs => ref_block_fs,
      ------------------------------------
      number_of_samples => number_of_samples_out,
      r_update_mapped_in_out => r_fifo_datain, 
      r_update_headerin_out => r_fifo_headerin, 
      w_update_fifo_datain => w_update_fifo_datain,
      mapped_fifo_empty => fifo_datain_empty,
      mapped_fifo_aempty => fifo_datain_aempty,
      fifo_headerin_empty => fifo_headerin_empty,
      fifo_headerin_aempty => fifo_headerin_aempty,
      en_sndextension_out => en_sndextension,
      clear_sndextension_out => clear_sndextension,
      clear_lkoptions_out => clear_lkoptions, 
      en_lk_out => en_lk,   
      en_k_winner_out => en_k_winner, 
      w_update_mapped_out => w_update_mapped, 
      en_optcoder_out => en_optcoder, 
      r_update_mapped_out => r_update_mapped,
      r_update_gamma_out => r_update_gamma,  
      en_fscoder_out => en_fscoder, 
      start_fscoder_out => start_fscoder,
      en_bitpack_split_out => en_bitpack_split, 
      flush_split_out => flush_split,
      en_splitter_out => en_splitter,
      start_splitter_out => start_splitter,
      we_fifo_split_in => we_fifo_split,
      r_update_split_out => r_update_split,
      en_bitpack_final_out => en_bitpack_final,
      flag_pack_header_prep_out => flag_pack_header_prep,
      flag_pack_header_out => flag_pack_header,
      flag_pack_fs_out => flag_pack_fs,
      flag_split_fifo_out => flag_split_fifo, 
      flag_split_flush_register_out => flag_split_flush_register,
      flag_pack_bypass_out => flag_pack_bypass,
      flush_final_out => flush_final, 
      zero_code => zero_code,
      option_in => option,
      zero_mapped_out => zero_mapped,
      eos_out => eos,
      dump_zeroes_out => dump_zeroes, 
      fsm_invalid_state => fsm_invalid_state
    );

    
    
  -----------------------------------------------------------------------------
   --! Reset synchronization
   -----------------------------------------------------------------------------
   sync_ahb_reset: entity shyloc_utils.reset_sync(two_ff) 
   port map (
     clk => Clk_AHB, 
     reset_in => Reset_AHB, 
     reset_out => rst_ahb_sync);
  --rst_ahb_sync <= Reset_AHB;

  sync_s_reset: entity shyloc_utils.reset_sync(two_ff)
   port map (
     clk => Clk_S, 
     reset_in => Rst_N, 
     reset_out => rst_n_sync);
  --rst_n_sync <= Rst_N;
  
  ---------------------------
  --!@brief ahb slave
  ---------------------------
  ahbslv : entity VH_compressor.ccsds121_ahbs(rtl)
  generic map(
    hindex => HSINDEX_121,
    haddr => HSCONFIGADDR_121,
    RESET_TYPE => RESET_TYPE) -- AMBA slave
  port map(rst => rst_ahb_sync,
    clk => Clk_AHB,
    ahbsi => AHBSlave121_In,
    ahbso => AHBSlave121_Out,
    clear => ahb_clear,
    control_out_ahb => control_out_ahb,
    config => ahb_config,
    error => error_ahb,
    valid => ahb_valid);

  ---------------------------
  --!@brief Clock adaptation
  ---------------------------
  clk_adapt: entity VH_compressor.ccsds121_clk_adapt(registers)
  port map (
    rst => rst_ahb_sync,
    clk_ahb => Clk_AHB, 
    clk_s => Clk_S, 
    valid_ahb => ahb_valid,
    config_ahb => ahb_config,
    config_s => config_s, 
    control_out_s => control_out_s, 
    control_out_ahb => control_out_ahb,
    clear_s => clear, 
    clear_ahb_out => ahb_clear,
    clear_ahb_ack_s => clear_ahb_ack_s,
    error_ahb_in => error_ahb,  
    error_s_out => error_s_out,
    valid_s_out => valid_s);

  ---------------------------
  --!@brief input data FIFO
  ---------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  fifo_datain: entity shyloc_utils.fifop2(arch)
  generic map (
    W => D_GEN,
    NE => NE_FIFO,
    W_ADDR => W_ADDR_FIFO,
    RESET_TYPE => RESET_TYPE, 
    EDAC => 0, 
    TECH => TECH)
  port map (
     Clk => Clk_S, 
     rst_n => rst_n_sync, 
     clr => clear, 
     w_update => w_fifo_datain,
     r_update => r_fifo_datain, 
     data_in => DataIn_end_reg, 
     data_out => mapped_DataIn,
     full => fifo_datain_full_aux,
     afull => fifo_datain_afull_aux,
     empty => fifo_datain_empty,
     aempty => fifo_datain_aempty
   );
   
  -----------------------------------
  --!@brief pre-processor header FIFO
  -----------------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  fifo_headerin: entity shyloc_utils.fifop2(arch)
    generic map (
      W => D_GEN,
      NE => NE_FIFO,
      W_ADDR => W_ADDR_FIFO,
      RESET_TYPE => RESET_TYPE,
      EDAC => 0, 
      TECH => TECH)
    port map (
      Clk => Clk_S, 
      rst_n => rst_n_sync, 
      clr => clear, 
      w_update => w_fifo_headerin,
      r_update => r_fifo_headerin, 
      data_in => DataIn, 
      data_out => header_DataIn,
      full => fifo_headerin_full,
      empty => fifo_headerin_empty,
      aempty => fifo_headerin_aempty
    );
    
  ----------------------------------------
  --!@brief nbits-preprocessor-header FIFO
  ----------------------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  fifo_nbits_headerin: entity shyloc_utils.fifop2(arch)
    generic map (
      W => W_NBITS_HEAD_GEN,
      NE => NE_FIFO_NBITSHEADER,
      W_ADDR => W_ADDR_FIFO_NBITSHEADER,
      RESET_TYPE => RESET_TYPE, 
      EDAC => 0, 
      TECH => TECH)
    port map (
      Clk => Clk_S, 
      rst_n => rst_n_sync, 
      clr => clear, 
      w_update => w_fifo_headerin,
      r_update => r_fifo_headerin, 
      data_in => NBitsIn, 
      data_out => header_nbits_DataIn,
      full => fifo_nbits_headerin_full,
      empty => fifo_nbits_headerin_empty,
      aempty => fifo_nbits_headerin_aempty
    );


  ---------------------------
  --!@brief output data FIFO
  ---------------------------
  -- EDAC here disabled, this FIFO is expected to be
  -- implemented by FFs instead of BRAM due to limited size.
  -- assign EDAC => EDAC if you wish generic parameter value to 
  -- be passed.
  -- Check your synthesis results to ensure no BRAM is used, otherwise
  -- enable edac by assigning EDAC => EDAC
  -- and use output from FIFO  edac_double_error =>  to signal the EDAC error
  outputfifo:  entity shyloc_utils.fifop2(arch)
    generic map (
      W => W_BUFFER_GEN,
      NE => NE_SPLIT_FIFO_GEN,
      W_ADDR => W_ADDR_SPLIT_FIFO_GEN,
      RESET_TYPE => RESET_TYPE, 
      EDAC => 0, 
      TECH => TECH)
    port map (
      Clk => Clk_S,
      rst_n => rst_n_sync, 
      clr => clear, 
      w_update => buff_full_aux, 
      r_update => r_fifo_dataout, 
      data_in => buff_out_aux, 
      data_out => output_fifo_dataout_d,
      empty => fifo_dataout_empty,
      aempty => fifo_dataout_aempty,
      full => fifo_dataout_full
    );
    
  ---------------------------
  --!@brief components module
  ---------------------------
  components: entity VH_compressor.ccsds121_shyloc_comp(arch)
    generic map (
      W_MAP => D_GEN,
      W_BUFFER => W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE)
    port map (
      Clk => Clk_S,
      rst_n => rst_n_sync, 
      config_valid => config_valid,
      config_in => config_s,
      config_int => config_int,
      error => error_out,
      error_code => error_code_out,
      clear => clear,
      mapped => mapped_DataIn, 
      header_prep => header_DataIn, 
      n_bits_header_prep => header_nbits_DataIn,
      en_sndextension => en_sndextension,
      clear_sndextension => clear_sndextension, 
      r_update_gamma => r_update_gamma, 
      en_interface => en_interface,
      en_lk => en_lk, 
      en_k_winner => en_k_winner, 
      en_optcoder => en_optcoder, 
      en_fscoder => en_fscoder,
      en_bitpack_split => en_bitpack_split, 
      flush_split => flush_split, 
      start_fscoder => start_fscoder,
      clear_lkoptions => clear_lkoptions, 
      w_update_mapped => w_update_mapped, 
      r_update_mapped => r_update_mapped,
      r_update_split => r_update_split,
      en_splitter => en_splitter, 
      start_splitter => start_splitter,
      we_fifo_split_out => we_fifo_split,
      flag_pack_fs => flag_pack_fs, 
      en_bitpack_final => en_bitpack_final,
      flag_split_fifo => flag_split_fifo, 
      flag_split_flush_register => flag_split_flush_register,
      flush_final => flush_final, 
      zero_code => zero_code,
      option_out => option, 
      buff_out => buff_out_aux,
      zero_mapped => zero_mapped,
      eos => eos,
      dump_zeroes => dump_zeroes,
      -- Modified by AS: new interface ports --
      zero_count_out => zero_count_int,
      ref_block_lk => ref_block_lk,
      ref_block_fs => ref_block_fs,
      ------------------------------------
      buff_full => buff_full_aux,
      flag_pack_header => flag_pack_header,
      flag_pack_header_prep =>  flag_pack_header_prep,
      en_header121 =>  en_header121,
      flag_pack_bypass => flag_pack_bypass,
      empty_gamma => empty_gamma,
      full_gamma => full_gamma,
      afull_gamma => afull_gamma,
      aempty_gamma => aempty_gamma,
      empty_mapped => empty_mapped,
      full_mapped => full_mapped,
      afull_mapped => afull_mapped,
      aempty_mapped => aempty_mapped,
      empty_split => empty_split,
      full_split => full_split,
      afull_split => afull_split,
      aempty_split => aempty_split,
      number_of_samples_out => number_of_samples_out
    );
    
  number_of_samples <= (unsigned(number_of_samples_out));
  ---------------------------
  --! Control signal management
  ---------------------------
  process (Clk_S, rst_n_sync)
    variable first_comp: std_logic := '1';
  begin
    if (rst_n_sync = '0' and RESET_TYPE = 0) then
      state_reg <= idle;
      SFinished_reg <= '0';
      SReady_reg <= '0';
      SAwaitingConfig_reg <= '1';
      SError_reg <= '0';
      SErrorCode_reg <= (others => '0');
      Ready_Ext_reg <= '1';
      buff_full <= '0';
      counter_requested_samples <= (others => '0');
      last_DataIn <= '0';
      last_DataIn_Reg <= '0';
    elsif (Clk_S'event and Clk_S = '1') then
      if (rst_n_sync = '0' and RESET_TYPE = 1) then
        state_reg <= idle;
        SFinished_reg <= '0';
        SReady_reg <= '0';
        SAwaitingConfig_reg <= '1';
        SError_reg <= '0';
        SErrorCode_reg <= (others => '0');
        Ready_Ext_reg <= '1';
        buff_full <= '0';
        counter_requested_samples <= (others => '0');
        last_DataIn <= '0';
        last_DataIn_Reg <= '0';
      else
        state_reg <= state_next;
        SFinished_reg <= SFinished_cmb;
        SReady_reg <= SReady_cmb;
        SAwaitingConfig_reg <= SAwaitingConfig_cmb;
        SError_reg <= SError_cmb;
        SErrorCode_reg <= SErrorCode_cmb;
        Ready_Ext_reg <= Ready_Ext;
        last_DataIn <= '0';
        buff_full <= r_fifo_dataout;
        if (config_valid = '0' or ForceStop = '1') then
          counter_requested_samples <= (others => '0');
        elsif (DataIn_NewValid = '1' and IsHeaderIn = '0') then
          if (config_valid = '1' and counter_requested_samples = number_of_samples-1) then
            counter_requested_samples <= (others => '0');
            last_DataIn <= '1';
          else
            counter_requested_samples <= counter_requested_samples + 1;
          end if;
        end if;
        last_DataIn_Reg <= last_DataIn_cmb;
      end if;
    end if;
  end process;
    
  ---------------------------
  --! Control signal management
  ---------------------------
  fsm_phase: process (config_valid, clear, state_reg, rst_n_sync, error_out, Ready_Ext, Ready_Ext_reg, fifo_datain_afull_aux, fifo_datain_full_aux, config_int, SFinished_reg, SReady_reg, SAwaitingConfig_reg, SError_reg, SErrorCode_reg, error_code_out, last_DataIn, last_DataIn_Reg)
  begin
    state_next <= state_reg;
    SFinished_cmb <= SFinished_reg;
    SReady_cmb <= SReady_reg;
    SAwaitingConfig_cmb <= SAwaitingConfig_reg;
    SError_cmb <= SError_reg;
    SErrorCode_cmb <= SErrorCode_reg;
    last_DataIn_cmb <= last_DataIn_Reg;
    case (state_reg) is
      when idle =>
        last_DataIn_cmb <= '0';
        if (rst_n_sync = '1' and config_valid = '1') then
          SFinished_cmb <= '0';
          SReady_cmb <= '1';
          SAwaitingConfig_cmb <= '0';
          SError_cmb <= '0';
          SErrorCode_cmb <= (others => '0');
          state_next <= compressing;
        elsif (rst_n_sync = '1' and error_out = '1') then
          SFinished_cmb <= '1';
          SReady_cmb <= '0';
          SAwaitingConfig_cmb <= '0';
          SError_cmb <= '1';
          SErrorCode_cmb <= error_code_out;
          state_next <= stopped;
        end if;
      when compressing =>
        if (last_DataIn = '1') then
          last_DataIn_cmb <= '1';
        end if;
        -- Control to re-assert Ready, check if Ready was previously de-asserted, and in that case, wait until datain FIFO is almost empty - we make sure the FIFO does not get full
        if SReady_reg = '1' then 
            if (fifo_datain_full_aux = '1' or fifo_datain_afull_aux = '1' or clear = '1' or error_out = '1' or (Ready_Ext_reg = '0' and Ready_Ext = '0') or last_DataIn = '1') then
              SReady_cmb <= '0';
            elsif (Ready_Ext_reg = '0' or (last_DataIn_Reg = '1')) then
              SReady_cmb <= '0';
            else 
              SReady_cmb <= '1';
            end if;
        else 
            if (fifo_datain_full_aux = '1' or fifo_datain_afull_aux = '1' or clear = '1' or error_out = '1' or (Ready_Ext_reg = '0' and Ready_Ext = '0') or last_DataIn = '1') then
              SReady_cmb <= '0';
            elsif (Ready_Ext_reg = '0' or (last_DataIn_Reg = '1')) then
              SReady_cmb <= '0';
            elsif fifo_datain_aempty = '1' or fifo_datain_empty = '1' then
              SReady_cmb <= '1';
            end if;
         end if;
        
        
        --if (fifo_datain_full_aux = '1' or fifo_datain_afull_aux = '1' or clear = '1' or error_out = '1' or (Ready_Ext_reg = '0' and Ready_Ext = '0') or --last_DataIn = '1') then
          --SReady_cmb <= '0';
        --elsif (Ready_Ext_reg = '1') then
          --SReady_cmb <= '1';
        --else 
          --SReady_cmb <= SReady_reg;
        --end if;
        if (clear = '1' or error_out = '1') then 
          SFinished_cmb <= '1';
          state_next <= stopped;
        end if;
      when stopped =>
        SAwaitingConfig_cmb <= '1';
        if config_valid = '1' then 
          state_next <= idle;
        end if;
      when others =>
        state_next <= idle;
    end case;
  end process;
    
end arch;
