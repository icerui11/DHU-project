

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package VH_ccsds121_parameters is

-- TEST: 30_Test
   constant EN_RUNCFG: integer  := 1;          --! (0) Disables runtime configuration; (1) Enables runtime configuration.
   constant RESET_TYPE: integer :=  0;          --! (0) Asynchronous reset; (1) Synchronous reset.
   constant HSINDEX_121: integer := 3;          --! AHB slave index.
   constant HSCONFIGADDR_121: integer := 16#700#;    --! ADDR field of the AHB Slave.
   constant HSADDRMASK_121: integer := 16#FFF#;      --! MASK field of the AHB slave.
   constant EDAC: integer := 0;              --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.
  constant Nx_GEN: integer := 80;          --! Maximum allowed number of samples in a line.
  constant Ny_GEN: integer := 30;          --! Maximum allowed number of samples in a row.
  constant Nz_GEN: integer := 340;          --! Maximum allowed number of bands.
   constant D_GEN : integer := 32;            --! Maximum dynamic range of the input samples.
   constant IS_SIGNED_GEN : integer := 0;   constant ENDIANESS_GEN : integer := 1;        --! (0) Little-Endian; (1) Big-Endian.
   constant J_GEN: integer := 32;            --! Block Size.
   constant REF_SAMPLE_GEN: integer := 64;      --! Reference Sample Interval.
   constant CODESET_GEN: integer := 0;          --! Code Option.
   constant W_BUFFER_GEN: integer := 32;        --! Bit width of the output buffer.
   constant PREPROCESSOR_GEN : integer := 2;      --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present.
   constant DISABLE_HEADER_GEN : integer := 0;      --! Selects whether to disable (1) or not (0) the header.

  constant TECH: integer := 0;            --! Selects the memory type.


end VH_ccsds121_parameters;
