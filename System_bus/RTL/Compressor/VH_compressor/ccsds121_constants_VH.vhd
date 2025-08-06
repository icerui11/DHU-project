--============================================================================--
-- Copyright 2017 University of Las Palmas de Gran Canaria 
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
-- Design unit  : ccsds121_constants module
--
-- File name    : ccsds121_constants.vhd
--
-- Purpose      : Package of constant values for the CCSDS-121 compressor. Some of these constants come from the generic values of certain parameters.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--============================================================================

--!@file #ccsds121_constants.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief   Package of constant values for the CCSDS-121 compressor.
--!@details Some of these constants come from the generic values of certain parameters.

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils library
library shyloc_utils; 
--! Use shyloc_functions functions
use shyloc_utils.shyloc_functions.all;


library VH_compressor;
--! Use specific V-H shyloc121 parameters
use VH_compressor.VH_ccsds121_parameters.all;
-------------------------------------------------------------------------------
--**********************************************************************---
-- Comment or un-comment to change set of parameters --

--use shyloc_121.ccsds_121_teletel_parameters1.all;
--use shyloc_121.ccsds_121_teletel_parameters2.all;
--use shyloc_121.ccsds_121_teletel_parameters3.all;
--use shyloc_121.ccsds_121_teletel_parameters4.all;
--**********************************************************************---

--! ccsds121_constants package. Package of constant values for the CCSDS-121 compressor.
package ccsds121_constants_VH is

  constant SEGMENT_GEN  : integer := 64;                --! Size of a segment.
  constant BYPASS_GEN   : integer := 0;                 --! Generic BYPASS value
  --constant IS_SIGNED_GEN  : integer := 0;                    --! Generic value to indicate signed samples (1) or unsigned (0).
  --constant N_SAMPLES_GEN  : integer := (Nx_GEN*Ny_GEN*Nz_GEN);      --! Number of samples to encode.
  constant MAX_SIZE_GEN : integer := J_GEN*D_GEN;           --! Maximum size of the compressed sequence.
  --constant K_MAX_GEN    : integer := get_n_k_options (D_GEN,1);                --! Maximum number of K options.  
  constant K_MAX_GEN    : integer := maximum(14,get_n_k_options (D_GEN,1));                --! Maximum number of K options.
  
  --! Number of bits for the corresponding signals (for more information see ccsds121_parameters package)
  constant W_Nx_GEN     : integer := log2(Nx_GEN);                                
  constant W_Ny_GEN     : integer := log2(Ny_GEN);
  constant W_Nz_GEN     : integer := log2(Nz_GEN);
  constant W_D_GEN      : integer := log2(D_GEN);
  constant W_J_GEN      : integer := log2(J_GEN);
  constant W_W_BUFFER_GEN   : integer := log2(W_BUFFER_GEN);
  constant W_CODESET_GEN    : integer := 1;
  constant W_OPT_GEN      : integer := get_n_bits_option(D_GEN, CODESET_GEN);           --! Number of bits for the option identifier.
  constant W_GAMMA_GEN    : integer := get_gamma_val (J_GEN, D_GEN);           --! Bit width of gamma.
  constant N_K_GEN      : integer := get_n_k_options (D_GEN, CODESET_GEN);            --! Maximum k option.
  constant W_K_GEN      : integer := maximum(3,log2(N_K_GEN)+1);                --! Bits needed to represent k.
  constant W_NBITS_K_GEN    : integer := get_k_bits_option(W_BUFFER_GEN, CODESET_GEN, W_K_GEN);   --! Bit width of "k" value.
  constant W_REF_SAMPLE_GEN : integer := log2(REF_SAMPLE_GEN);                    --! Bit width of the reference sample counter.
  constant W_ZERO_GEN     : integer := log2(SEGMENT_GEN);                     --! Bit width of the zero block counter.
  constant W_FS_OPT_GEN   : integer := J_GEN*3 + 4 + (PREPROCESSOR_GEN/2)*D_GEN;  --! Maximum bit width of the FS sequence + Option ID. When pre-processor is 2 or 3, it spares room for inserting a non-compressed sample in the CDS.
  constant W_N_SAMPLES_GEN  : integer := log2(Nx_GEN) + log2(Ny_GEN) + log2(Ny_GEN);  
  constant W_L_GAMMA_GEN    : integer := log2(MAX_SIZE_GEN);                    --! Maximum size of length for gamma option.
  constant W_L_K_GEN      : integer := log2(MAX_SIZE_GEN);                    --! Maximum size of length for k option.
  constant W_L_GEN      : integer := log2(MAX_SIZE_GEN+W_OPT_GEN);                --! Bit width of the different options.
  constant W_NBITS_GEN    : integer := log2(K_MAX_GEN*J_GEN);                   --! Bit width of the number of bits of the fs or k-split sequence.
  
  --! Number of elements for certain FIFO's
  constant NE_SPLIT_FIFO_GEN  : integer := J_GEN/2+1;             --! Number of elements in the split FIFOs.
  constant NE_GAMMA_FIFO_GEN  : integer := J_GEN;               --! Number of elements in FIFO. Always power-of-two.
  constant NE_MAP_FIFO_GEN  : integer := 2**(log2(J_GEN+4));        --! Number of elements in FIFO for mapped prediction residuals.
      
  --! Bit width of the addresses of certain FIFO's
  constant W_ADDR_FIFO_GAMMA_GEN  : integer := log2 (NE_GAMMA_FIFO_GEN);    --! Bit width of the addresses for the gamma FIFOs.   
  constant W_ADDR_MAP_FIFO_GEN  : integer := log2(NE_MAP_FIFO_GEN-1);   --! Bit width of the addresses for the mapped FIFOs.
  constant W_ADDR_SPLIT_FIFO_GEN  : integer := log2(NE_SPLIT_FIFO_GEN-1);   --! Bit width of the address signal for the split FIFOs.
  
  --! Constants required to deal with the header
  constant MAX_HEADER_SIZE  : integer := 6;
  constant HEADER_ADDR    : integer := log2(MAX_HEADER_SIZE);
  constant W_NBITS_HEAD_GEN : integer := 6;
  
  --! End of File is end of segment flag
  constant EOF_IS_EOS     : integer := 1;                   --! Barcelona software does 1; ESA's software does 0.
  constant EOF_IS_EOS_GEN   : integer := 1;                   --! Barcelona software does 1; ESA's software does 0.
  
  --------------------------------------
  --! Configuration set for the CCSDS121
  --------------------------------------
  type config_121 is
    record
      Nx        : std_logic_vector (W_Nx_GEN-1 downto 0);       --! Number of columns.
      Nz        : std_logic_vector (W_Nz_GEN-1 downto 0);       --! Number of lines.
      Ny        : std_logic_vector (W_Ny_GEN-1 downto 0);       --! Number of bands.
      IS_SIGNED    : std_logic_vector(0 downto 0);              --! Signed (1) or unsigned (0) samples.
      ENDIANESS   : std_logic_vector(0 downto 0);             --! Big Endian (1) or Litle Endian (0).
      D       : std_logic_vector(W_D_GEN-1 downto 0);         --! Dynamic Range of the input samples.
      J       : std_logic_vector (W_J_GEN-1 downto 0);        --! Block Size.
      REF_SAMPLE    : std_logic_vector (W_REF_SAMPLE_GEN-1 downto 0);   --! Reference Sample Interval (Determine how often to insert references not coded).
      CODESET     : std_logic_vector(0 downto 0);             --! Code Option (If specified and the dynamic range D is <= 4, the restricted mode will be used).
      W_BUFFER    : std_logic_vector (W_W_BUFFER_GEN-1 downto 0);     --! Output word size.
      BYPASS      : std_logic_vector(0 downto 0);             --! Compression (0) or Bypass Compression (1).
      PREPROCESSOR  : std_logic_vector(1 downto 0);              --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) CCSDS121 unit-delay preprocessor is present; (3) Any-other preprocessor is present.
      DISABLE_HEADER  : std_logic_vector(0 downto 0);             --! Selects whether to disable (1) or not (0) the header generation.
      ENABLE      : std_logic_vector(0 downto 0);             --! Enable compression with AMBA configuration parameters.
    end record; 
  
  --------------------------------
  --! Control set for the CCSDS121
  --------------------------------
  type ctrls is
    record
      AwaitingConfig  : std_logic;            --! IP is waiting to be configured (1) or not (0).  
      Ready     : std_logic;            --! IP is ready to receive new samples for compression (1) or not (0).
      FIFO_Full   : std_logic;            --! If asserted, FIFO is full. Input data might have been lost.
      EOP       : std_logic;            --! When asserted (1), compression of last sample has started.
      Finished    : std_logic;            --! When asserted (1), the IP core has finished processing all samples in the image.
      Error     : std_logic;            --! If asserted, there has been a configuration error.
      ErrorCode   : std_logic_vector(3 downto 0);   --! Code of the configuration error asserted with Error signal.
  end record; 
  
end ccsds121_constants_VH;
