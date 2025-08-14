

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- venspec U HR compressor parameters
package HR_ccsds121_parameters is
  -- TEST: 30_Test - High Resolution Configuration
  constant HR_EN_RUNCFG: integer := 1;            --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant HR_RESET_TYPE: integer := 0;           --! (0) Asynchronous reset; (1) Synchronous reset.
  constant HR_HSINDEX_121: integer := 1;          --! AHB slave index.
  constant HR_HSCONFIGADDR_121: integer := 16#100#; --! ADDR field of the AHB Slave.
  constant HR_HSADDRMASK_121: integer := 16#FFF#;  --! MASK field of the AHB slave.
  constant HR_EDAC: integer := 0;                 --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant HR_Nx_GEN: integer := 80;              --! Maximum allowed number of samples in a line.
  constant HR_Ny_GEN: integer := 30;              --! Maximum allowed number of samples in a row.
  constant HR_Nz_GEN: integer := 340;             --! Maximum allowed number of bands.
  constant HR_D_GEN: integer := 32;               --! Maximum dynamic range of the input samples.
  constant HR_IS_SIGNED_GEN: integer := 0;        --! Signed/Unsigned input samples.
  constant HR_ENDIANESS_GEN: integer := 1;        --! (0) Little-Endian; (1) Big-Endian.
  constant HR_J_GEN: integer := 32;               --! Block Size.
  constant HR_REF_SAMPLE_GEN: integer := 64;      --! Reference Sample Interval.
  constant HR_CODESET_GEN: integer := 0;          --! Code Option.
  constant HR_W_BUFFER_GEN: integer := 32;        --! Bit width of the output buffer.
  constant HR_PREPROCESSOR_GEN: integer := 1;     --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present.
  constant HR_DISABLE_HEADER_GEN: integer := 0;   --! Selects whether to disable (1) or not (0) the header.
  constant HR_TECH: integer := 0;                 --! Selects the memory type.
end HR_ccsds121_parameters;

package HR_ccsds123_parameters is
  -- SYSTEM - High Resolution Configuration
  constant HR_EN_RUNCFG: integer := 1;              --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant HR_RESET_TYPE: integer := 0;             --! (0) Asynchronous reset; (1) Synchronous reset.
  constant HR_EDAC: integer := 0;                   --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant HR_PREDICTION_TYPE: integer := 0;        --! (0) BIP-base architecture; (1) BIP-mem architecture; (2) BSQ architecture; (3) BIL architecture; (4) BIL-mem architecture.
  constant HR_ENCODING_TYPE: integer := 0;          --! (0) Only pre-processor is implemented (external encoder can be attached); (1) Sample-adaptive encoder implemented.
  
  -- AHB slave
  constant HR_HSINDEX_123: integer := 2;            --! AHB slave index.
  constant HR_HSCONFIGADDR_123: integer := 16#200#; --! ADDR field of the AHB Slave.
  constant HR_HSADDRMASK_123: integer := 16#FFF#;   --! MASK field of the AHB slave.
  
  -- AHB master
  constant HR_HMINDEX_123: integer := 1;            --! AHB master index.
  constant HR_HMAXBURST_123: integer := 16;         --! AHB master burst beat limit.
  constant HR_ExtMemAddress_GEN: integer := 16#300#; --! External memory address.
  
  -- IMAGE
  constant HR_Nx_GEN: integer := 80;                --! Maximum allowed number of samples in a line.
  constant HR_Ny_GEN: integer := 30;                --! Maximum allowed number of samples in a row.
  constant HR_Nz_GEN: integer := 340;               --! Maximum allowed number of bands.
  constant HR_D_GEN: integer := 16;                 --! Maximum dynamic range of the input samples.
  constant HR_IS_SIGNED_GEN: integer := 0;          --! (0) Unsigned samples; (1) Signed samples.
  constant HR_ENDIANESS_GEN: integer := 1;          --! (0) Little-Endian; (1) Big-Endian.
  constant HR_DISABLE_HEADER_GEN: integer := 0;     --! Selects whether to disable (1) or not (0) the header.
  
  -- PREDICTOR
  constant HR_P_MAX: integer := 3;                  --! Number of bands used for prediction.
  constant HR_PREDICTION_GEN: integer := 0;         --! Full (0) or reduced (1) prediction.
  constant HR_LOCAL_SUM_GEN: integer := 0;          --! Neighbour (0) or column (1) oriented local sum.
  constant HR_OMEGA_GEN: integer := 13;             --! Weight component resolution.
  constant HR_R_GEN: integer := 32;                 --! Register size.
  constant HR_VMAX_GEN: integer := 3;               --! Factor for weight update.
  constant HR_VMIN_GEN: integer := -1;              --! Factor for weight update.
  constant HR_T_INC_GEN: integer := 6;              --! Weight update factor change interval.
  constant HR_WEIGHT_INIT_GEN: integer := 0;        --! Weight initialization mode.
  constant HR_ENCODER_SELECTION_GEN: integer := 2;  --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (Block-Adaptive).
  constant HR_INIT_COUNT_E_GEN: integer := 1;       --! Initial count exponent.
  constant HR_ACC_INIT_TYPE_GEN: integer := 0;      --! Accumulator initialization type.
  constant HR_ACC_INIT_CONST_GEN: integer := 5;     --! Accumulator initialization constant.
  constant HR_RESC_COUNT_SIZE_GEN: integer := 6;    --! Rescaling counter size.
  constant HR_U_MAX_GEN: integer := 16;             --! Unary length limit.
  constant HR_W_BUFFER_GEN: integer := 32;          --! Bit width of the output buffer.
  constant HR_Q_GEN: integer := 5;                  --! Weight initialization resolution.
  constant HR_CWI_GEN: integer := 0;                --! Custom Weight Initialization mode.
  constant HR_TECH: integer := 0;                   --! Selects the memory type.
end HR_ccsds123_parameters;

--V-U LR compressor parameters
package LR_ccsds121_parameters is
  -- TEST: 30_Test - Low Resolution Configuration
  constant LR_EN_RUNCFG: integer := 1;            --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant LR_RESET_TYPE: integer := 0;           --! (0) Asynchronous reset; (1) Synchronous reset.
  constant LR_HSINDEX_121: integer := 4;          --! AHB slave index.
  constant LR_HSCONFIGADDR_121: integer := 16#400#; --! ADDR field of the AHB Slave.
  constant LR_HSADDRMASK_121: integer := 16#FFF#;  --! MASK field of the AHB slave.
  constant LR_EDAC: integer := 0;                 --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant LR_Nx_GEN: integer := 80;              --! Maximum allowed number of samples in a line.
  constant LR_Ny_GEN: integer := 30;              --! Maximum allowed number of samples in a row.
  constant LR_Nz_GEN: integer := 340;             --! Maximum allowed number of bands.
  constant LR_D_GEN: integer := 32;               --! Maximum dynamic range of the input samples.
  constant LR_IS_SIGNED_GEN: integer := 0;        --! Signed/Unsigned input samples.
  constant LR_ENDIANESS_GEN: integer := 1;        --! (0) Little-Endian; (1) Big-Endian.
  constant LR_J_GEN: integer := 32;               --! Block Size.
  constant LR_REF_SAMPLE_GEN: integer := 64;      --! Reference Sample Interval.
  constant LR_CODESET_GEN: integer := 0;          --! Code Option.
  constant LR_W_BUFFER_GEN: integer := 32;        --! Bit width of the output buffer.
  constant LR_PREPROCESSOR_GEN: integer := 1;     --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present.
  constant LR_DISABLE_HEADER_GEN: integer := 0;   --! Selects whether to disable (1) or not (0) the header.
  constant LR_TECH: integer := 0;                 --! Selects the memory type.
end LR_ccsds121_parameters;

package LR_ccsds123_parameters is
  -- SYSTEM - Low Resolution Configuration
  constant LR_EN_RUNCFG: integer := 1;              --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant LR_RESET_TYPE: integer := 0;             --! (0) Asynchronous reset; (1) Synchronous reset.
  constant LR_EDAC: integer := 0;                   --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant LR_PREDICTION_TYPE: integer := 0;        --! (0) BIP-base architecture; (1) BIP-mem architecture; (2) BSQ architecture; (3) BIL architecture; (4) BIL-mem architecture.
  constant LR_ENCODING_TYPE: integer := 0;          --! (0) Only pre-processor is implemented (external encoder can be attached); (1) Sample-adaptive encoder implemented.
  
  -- AHB slave
  constant LR_HSINDEX_123: integer := 5;            --! AHB slave index.
  constant LR_HSCONFIGADDR_123: integer := 16#500#; --! ADDR field of the AHB Slave.
  constant LR_HSADDRMASK_123: integer := 16#FFF#;   --! MASK field of the AHB slave.
  
  -- AHB master
  constant LR_HMINDEX_123: integer := 1;            --! AHB master index.
  constant LR_HMAXBURST_123: integer := 16;          --! AHB master burst beat limit.
  constant LR_ExtMemAddress_GEN: integer := 16#600#; --! External memory address.
  
  -- IMAGE
  constant LR_Nx_GEN: integer := 80;                --! Maximum allowed number of samples in a line.
  constant LR_Ny_GEN: integer := 30;                --! Maximum allowed number of samples in a row.
  constant LR_Nz_GEN: integer := 340;               --! Maximum allowed number of bands.
  constant LR_D_GEN: integer := 16;                 --! Maximum dynamic range of the input samples.
  constant LR_IS_SIGNED_GEN: integer := 0;          --! (0) Unsigned samples; (1) Signed samples.
  constant LR_ENDIANESS_GEN: integer := 1;          --! (0) Little-Endian; (1) Big-Endian.
  constant LR_DISABLE_HEADER_GEN: integer := 0;     --! Selects whether to disable (1) or not (0) the header.
  
  -- PREDICTOR
  constant LR_P_MAX: integer := 3;                  --! Number of bands used for prediction.
  constant LR_PREDICTION_GEN: integer := 0;         --! Full (0) or reduced (1) prediction.
  constant LR_LOCAL_SUM_GEN: integer := 0;          --! Neighbour (0) or column (1) oriented local sum.
  constant LR_OMEGA_GEN: integer := 13;             --! Weight component resolution.
  constant LR_R_GEN: integer := 32;                 --! Register size.
  constant LR_VMAX_GEN: integer := 3;               --! Factor for weight update.
  constant LR_VMIN_GEN: integer := -1;              --! Factor for weight update.
  constant LR_T_INC_GEN: integer := 6;              --! Weight update factor change interval.
  constant LR_WEIGHT_INIT_GEN: integer := 0;        --! Weight initialization mode.
  constant LR_ENCODER_SELECTION_GEN: integer := 2;  --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (Block-Adaptive).
  constant LR_INIT_COUNT_E_GEN: integer := 1;       --! Initial count exponent.
  constant LR_ACC_INIT_TYPE_GEN: integer := 0;      --! Accumulator initialization type.
  constant LR_ACC_INIT_CONST_GEN: integer := 5;     --! Accumulator initialization constant.
  constant LR_RESC_COUNT_SIZE_GEN: integer := 6;    --! Rescaling counter size.
  constant LR_U_MAX_GEN: integer := 16;             --! Unary length limit.
  constant LR_W_BUFFER_GEN: integer := 32;          --! Bit width of the output buffer.
  constant LR_Q_GEN: integer := 45;                  --! Weight initialization resolution.
  constant LR_CWI_GEN: integer := 0;                --! Custom Weight Initialization mode.
  constant LR_TECH: integer := 0;                   --! Selects the memory type.
end LR_ccsds123_parameters;
-- V-U compressor parameters, only 1D compression
package VH_ccsds121_parameters is
  -- TEST: 30_Test - Very High Resolution Configuration
  constant VH_EN_RUNCFG: integer := 1;            --! (0) Disables runtime configuration; (1) Enables runtime configuration.
  constant VH_RESET_TYPE: integer := 0;           --! (0) Asynchronous reset; (1) Synchronous reset.
  constant VH_HSINDEX_121: integer := 7;          --! AHB slave index.
  constant VH_HSCONFIGADDR_121: integer := 16#700#; --! ADDR field of the AHB Slave.
  constant VH_HSADDRMASK_121: integer := 16#FFF#;  --! MASK field of the AHB slave.
  constant VH_EDAC: integer := 0;                 --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant VH_Nx_GEN: integer := 256;             --! Maximum allowed number of samples in a line.
  constant VH_Ny_GEN: integer := 60;              --! Maximum allowed number of samples in a row.
  constant VH_Nz_GEN: integer := 384;             --! Maximum allowed number of bands.
  constant VH_D_GEN: integer := 32;               --! Maximum dynamic range of the input samples.
  constant VH_IS_SIGNED_GEN: integer := 1;        --! Signed/Unsigned input samples.
  constant VH_ENDIANESS_GEN: integer := 1;        --! (0) Little-Endian; (1) Big-Endian.
  constant VH_J_GEN: integer := 64;               --! Block Size.
  constant VH_REF_SAMPLE_GEN: integer := 128;     --! Reference Sample Interval.
  constant VH_CODESET_GEN: integer := 1;          --! Code Option.
  constant VH_W_BUFFER_GEN: integer := 32;        --! Bit width of the output buffer.
  constant VH_PREPROCESSOR_GEN: integer := 2;     --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present.
  constant VH_DISABLE_HEADER_GEN: integer := 0;   --! Selects whether to disable (1) or not (0) the header.
  constant VH_TECH: integer := 0;                 --! Selects the memory type.
end VH_ccsds121_parameters;
