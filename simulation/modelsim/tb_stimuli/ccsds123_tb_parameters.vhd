

library ieee;
use ieee.std_logic_1164.all;
library shyloc_123;
use shyloc_123.ccsds123_parameters.all;
library shyloc_utils;
 use shyloc_utils.shyloc_functions.all;

package ccsds123_tb_parameters is
     constant stim_file: string :="C:\Users\yinrui\Desktop\SHyLoc_ip\shyloc_ip-main\CCSDS123IP-VHDL\images\raw\artifacts_h8w7b17_8int_le.bip";
     constant ref_file: string := "C:\Users\yinrui\Desktop\SHyLoc_ip\shyloc_ip-main\CCSDS123IP-VHDL\images\reference\comp_43.esa";
     constant out_file: string := "C:\Users\yinrui\Desktop\SHyLoc_ip\shyloc_ip-main\CCSDS123IP-VHDL\images\compressed\comp_43.esa.vhd";

-- TEST: 43_Test
     constant test_id: integer := 0;

   constant test_identifier: string := "43_Test";                         --! Indicates the test identifiern

     constant clk_ip: time := 100 ns;

 constant PREDICTION_TYPE_tb: integer := 1;
 constant ENCODING_TYPE_G_tb: integer :=1;

 constant HSINDEX_tb: integer := shyloc_123.ccsds123_parameters.HSINDEX_123;
 constant HSCONFIGADDR_tb: integer := shyloc_123.ccsds123_parameters.HSCONFIGADDR_123;

 constant HSADDRMASK_tb: integer := shyloc_123.ccsds123_parameters.HSADDRMASK_123;
 constant HMINDEX_tb: integer := shyloc_123.ccsds123_parameters.HMINDEX_123;
 constant HMAXBURST_tb: integer := shyloc_123.ccsds123_parameters.HMAXBURST_123;
 constant ExtMemAddress_G_tb: integer := shyloc_123.ccsds123_parameters.ExtMemAddress_GEN;

 constant EN_RUNCFG_G: integer := shyloc_123.ccsds123_parameters.EN_RUNCFG;
 constant RESET_TYPE: integer := shyloc_123.ccsds123_parameters.RESET_TYPE;
   constant POST_SYN : integer := 0;                            --! Indicates whether the post-synthesis model should be instantiated (1) or not (0)

 constant D_G_tb: integer := shyloc_123.ccsds123_parameters.D_GEN;
 constant W_BUFFER_G_tb: integer := shyloc_123.ccsds123_parameters.W_BUFFER_GEN;

 constant Nx_tb: integer := 16;             --! Number of columns.
 constant Ny_tb: integer := 16;             --! Number of rows.
 constant Nz_tb: integer := 6;             --! Number of bands.

 constant DISABLE_HEADER_tb: integer := 0;       --! Selects whether to disable (1) or not (0) the header generation.
 constant ENCODER_SELECTION_tb: integer := 1;     --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (block-adaptive).
 constant D_tb: integer := 16;             --! Dynamic range of the input samples.
 constant IS_SIGNED_tb: integer := 1;         --! (0) Unsigned samples; (1) Signed samples.
 constant ENDIANESS_tb: integer := 0;

         --! (0) Little-Endian; (1) Big-Endian.

 constant BYPASS_tb: integer := 0;           --! (0) Compression; (1) Bypass Compression.

 constant P_tb: integer := 3;             --! Number of bands used for prediction.
 constant PREDICTION_tb: integer := 0;         --! Full (0) or reduced (1) mode.
 constant LOCAL_SUM_tb: integer := 0;         --! Neighbour (0) or column (1) oriented local sum.
 constant OMEGA_tb: integer := 19;           --! Weight component resolution.
 constant R_tb: integer := 32;             --! Register size.

 constant VMAX_tb: integer := 6;             --! Factor for weight update.
 constant VMIN_tb: integer := 0;           --! Factor for weight update.
 constant TINC_tb: integer := 6;           --! Weight update factor change interval.
 constant WEIGHT_INIT_tb: integer := 0;         --! Weight initialization mode.

 constant INIT_COUNT_E_tb: integer := 6;         --! Initial count exponent.
 constant ACC_INIT_TYPE_tb: integer := 0;       --! Accumulator initialization type.
 constant ACC_INIT_CONST_tb: integer := 6;       --! Accumulator initialization constant.
 constant RESC_COUNT_SIZE_tb: integer := 9;       --! Rescaling counter size.
 constant U_MAX_tb: integer := 16;           --! Unary length limit.
 constant W_BUFFER_tb: integer := 32;         --! Bit width of the output buffer.

 constant Q_tb: integer := 5;             --! Weight initialization resolution.

  constant WR_tb: integer := 1;                      --! Weight Reset.

  constant CWI_tb: integer := 0;                      --! Custom Weight Initialization mode.

 constant W_NBITS_HEAD_G_tb : integer := 7;
 constant W_LS_G_tb: integer := D_G_tb + 3;
end ccsds123_tb_parameters;
