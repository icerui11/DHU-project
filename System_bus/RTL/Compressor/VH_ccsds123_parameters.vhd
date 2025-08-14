

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package ccsds123_parameters is

-- TEST: 30_Test

--SYSTEM
  constant EN_RUNCFG: integer  := 1;        --! --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant RESET_TYPE : integer := 0;        --! (0) Asynchronous reset; (1) Synchronous reset.
  constant EDAC: integer  :=  0;          --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant PREDICTION_TYPE: integer := 0;          --! (0) BIP-base architecture; (1) BIP-mem architecture; (2) BSQ architecture; (3) BIL architecture; (4) BIL-mem architecture.
  constant ENCODING_TYPE: integer  := 0;      --! (0) Only pre-processor is implemented (external encoder can be attached); (1) Sample-adaptive encoder implemented.
--AHB

--slave
  constant HSINDEX_123: integer := 1;              --! AHB slave index.
  constant HSCONFIGADDR_123: integer := 16#600#;        --! ADDR field of the AHB Slave.
  constant HSADDRMASK_123: integer := 16#FFF#;        --! MASK field of the AHB slave.

--master
  constant HMINDEX_123: integer := 1;              --! AHB master index.
  constant HMAXBURST_123: integer := 16;            --! AHB master burst beat limit.
  constant ExtMemAddress_GEN: integer := 16#400#;        --! External memory address.

--IMAGE
  constant Nx_GEN: integer := 80;          --! Maximum allowed number of samples in a line.
  constant Ny_GEN: integer := 30;          --! Maximum allowed number of samples in a row.
  constant Nz_GEN: integer := 340;          --! Maximum allowed number of bands.
  constant D_GEN: integer := 16;            --! Maximum dynamic range of the input samples.
  constant IS_SIGNED_GEN: integer := 0;        --! (0) Unsigned samples; (1) Signed samples.
  constant ENDIANESS_GEN: integer := 1;        --! (0) Little-Endian; (1) Big-Endian.

  constant DISABLE_HEADER_GEN: integer := 0;      --! Selects whether to disable (1) or not (0) the header.

--PREDICTOR
  constant P_MAX: integer := 3;            --! Number of bands used for prediction.
  constant PREDICTION_GEN: integer := 0;        --! Full (0) or reduced (1) prediction.
  constant LOCAL_SUM_GEN: integer := 0;        --! Neighbour (0) or column (1) oriented local sum.
  constant OMEGA_GEN: integer := 13;          --! Weight component resolution.
  constant R_GEN: integer := 32;            --! Register size.

  constant VMAX_GEN: integer := 3;          --! Factor for weight update.
  constant VMIN_GEN: integer := -1;          --! Factor for weight update.
  constant T_INC_GEN: integer := 6;          --! Weight update factor change interval.
  constant WEIGHT_INIT_GEN: integer := 0;        --! Weight initialization mode.
  constant ENCODER_SELECTION_GEN: integer := 2;    --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (Block-Adaptive).
  constant INIT_COUNT_E_GEN: integer := 1;      --! Initial count exponent.
  constant ACC_INIT_TYPE_GEN: integer := 0;      --! Accumulator initialization type.
  constant ACC_INIT_CONST_GEN: integer := 5;      --! Accumulator initialization constant.
  constant RESC_COUNT_SIZE_GEN: integer := 6;      --! Rescaling counter size.
  constant U_MAX_GEN: integer := 16;          --! Unary length limit.
  constant W_BUFFER_GEN: integer := 32;        --! Bit width of the output buffer.

  constant Q_GEN: integer := 5;                      --! Weight initialization resolution.
  constant CWI_GEN: integer := 0;                      --! Custom Weight Initialization mode.

  constant TECH: integer := 0;            --! Selects the memory type.

end ccsds123_parameters;
