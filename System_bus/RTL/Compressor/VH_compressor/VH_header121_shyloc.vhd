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
-- Design unit  : header121_shyloc module
--
-- File name    : header121_shyloc.vhd
--
-- Purpose      : Creates the header and sends it to the bit packing module (CCSDS 121.0)
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
--============================================================================

--!@file #header121_shyloc.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Creates the header and sends it to the bit packing module (CCSDS 121.0)
--!@details This module will output a header word, with the size of the output buffer (W_BUFFER), 
--! except for the last word, whose size can be smaller.

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
      
--! header_funcs_121 package
package header_funcs_121 is
  ------------------------------------
  --! Saves the proper value for J code
  ------------------------------------
  function code_block_size (J: integer) return std_logic_vector;
  ------------------------------------
  --! Saves CODE restriction flag
  ------------------------------------
  function code_restricted (D: integer; CODESET: integer; PREPROCESSOR: integer) return std_logic_vector;
  ------------------------------------
  --! Saves the proper value for dynamic range
  ------------------------------------
  function code_dyn_range (D: integer) return std_logic_vector;
  ------------------------------------
  --! Calculates the total amount of samples
  ------------------------------------
  function number_of_samples_calc (Nx: unsigned; Ny: unsigned; Nz: unsigned) return unsigned;
  ----------------------------------------------------------
  --! Saves the proper value for the number of samples field
  ----------------------------------------------------------
  function code_n_samples_header (number_of_samples: unsigned; J: integer) return unsigned;
end header_funcs_121;

package body header_funcs_121 is 
  
  ------------------------------------
  --! Saves the proper value for J code
  ------------------------------------
  function code_block_size (J: integer) return std_logic_vector is
    variable code: std_logic_vector (1 downto 0) := "00";
  begin
    case J is
      when 8 =>
        code := "00";
      when 16 =>
        code := "01";
      when 32 =>
        code := "10";
      when 64 =>
        code := "11";
      when others =>
        code := "00";
    end case;
    return code;
  end function;
  
  ------------------------------------
  --! Saves the proper value for dynamic range
  ------------------------------------
  function code_dyn_range (D: integer) return std_logic_vector is
    variable code: std_logic_vector (1 downto 0) := "00";
  begin
    if (D <= 8) then
      code := "01";
    elsif (D > 8 and D <= 16) then
      code := "10";
    else
      code := "11";
    end if;
    return code;
  end function;
  
  ------------------------------------
  --! Saves CODE restriction flag
  ------------------------------------
  function code_restricted (D: integer; CODESET: integer; PREPROCESSOR: integer) return std_logic_vector is
    variable code: std_logic_vector(0 downto 0) := "1";
  begin
  -- Modified by YB: using the CCSDS-121 IP, this bit is always "1" is the restricted mode is selected
    if (D < 4 and CODESET = 1) or (PREPROCESSOR = 2 and CODESET = 1) then
      code := "1";
    else
      code := "0";
    end if;
    return code;
  end function;
  
  ------------------------------------
  --! Calculates the total amount of samples
  ------------------------------------
  function number_of_samples_calc (Nx: unsigned; Ny: unsigned; Nz: unsigned) return unsigned is
    variable mult : unsigned(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);
  begin
    mult := Nx*Ny*Nz;
    return mult;
  end function;
  
  ----------------------------------------------------------
  --! Saves the proper value for the number of samples field
  ----------------------------------------------------------
  function code_n_samples_header (number_of_samples: unsigned; J: integer) return unsigned is
    --variable mult: unsigned (Nx'length + Ny'length + Nz'length -1 downto 0) := (others => '0');
    variable result: unsigned (number_of_samples'length -1 downto 0) := (others => '0');
  begin
    case J is
      when 8 =>
        result := (number_of_samples srl 3) - to_unsigned(1, number_of_samples'length);
      when 16 =>
        result := (number_of_samples srl 4) - to_unsigned(1, number_of_samples'length);
      when 32 =>
        result := (number_of_samples srl 5) - to_unsigned(1, number_of_samples'length);
      when 64 =>
        result := (number_of_samples srl 6) - to_unsigned(1, number_of_samples'length);
      when others =>
        result := (others => '0');
    end case;
    return resize(result, 12);
  end function;
end package body;


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
--! Use header_funcs_121 functions
use VH_compressor.header_funcs_121.all;

--! header121_shyloc entity. Creates the header and sends it to the bit packing module (CCSDS 121.0)
--! This module will output a header word, with the size of the output buffer (W_BUFFER), except for the last word, whose size can be smaller.
entity header121_shyloc is
  generic (
    HEADER_ADDR     : integer := 5;   --! Bit width of the image header pointer.
    W_BUFFER_GEN    : integer := 32;  --! Bit width of the output buffer. It has to be always greater than the maximum possible bit width of the codewords (U_MAX + DRANGE).
    W_NBITS_HEAD_GEN  : integer := 6;   --! Bit width of the signal which represents the number of bits of each codeword.
    RESET_TYPE      : integer := 1    --! Reset type.
    );      
    
  port (
    -- System Interface
    clk   : in std_logic;               --! Clock signal.
    rst_n : in std_logic;               --! Reset signal. Active low.
    
    -- Configuration and Control Interface
    config_in   : in config_121;      --! Current configuration parameters.
    config_received : in std_logic;       --! Flag to validate configuration.
    en        : in std_logic;       --! Enable signal.
    clear     : in std_logic;       --! Compression has been forced to stop. Go back to idle state.
    Nx_times_Ny   : in std_logic_vector (W_Nx_GEN + W_Ny_GEN -1 downto 0); --! Initial multiplication of coordinates.
    
    -- Data Output Interface
    header_out  : out std_logic_vector(W_BUFFER_GEN-1 downto 0);    --! Header values to be sent to the bit packing module.
    n_bits    : out std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0); --! Number of bits of the header output.
    
    number_of_samples_out : out std_logic_vector(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0));  --! Number of samples to compress
end header121_shyloc;

--! @brief Architecture of header121_shyloc 
architecture arch_shyloc of header121_shyloc is
  
  -- Constants
  constant MAX_N_BYTES    : integer := W_BUFFER_GEN/8;    -- max number of bytes in output buffer.
  constant MAX_REMAINDER    : integer := MAX_N_BYTES-1;     -- max number of remainding bytes.
  
  -- Array for storing header values (grouped in bytes)
  type array_type is array (0 to MAX_HEADER_SIZE-1) of std_logic_vector (7 downto 0);   
  signal header: array_type;
  
  -- Control signals for generating the header words
  signal reference_sample_mod : std_logic_vector (11 downto 0);
  signal n_samples_header   : std_logic_vector (11 downto 0);
  signal N_BYTES        : unsigned(3 downto 0);           
  signal counter_local    : unsigned (HEADER_ADDR-1 downto 0);
  signal rem_bytes      : unsigned(3 downto 0);   

  signal number_of_samples  : unsigned(W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0); 
  
begin
  
  ----------------------------
  --! Header fields assignments
  ----------------------------
  reference_sample_mod <= std_logic_vector(resize(unsigned(config_in.REF_SAMPLE), 12));
  --number_of_samples <= number_of_samples_calc(unsigned(config_in.Nx), unsigned(config_in.Ny), unsigned(config_in.Nz));
  number_of_samples <= unsigned(Nx_times_Ny)*unsigned(config_in.Nz);
  number_of_samples_out <= std_logic_vector(number_of_samples);
  n_samples_header <= std_logic_vector (code_n_samples_header(number_of_samples, to_integer(unsigned(config_in.J)))) when config_received = '1' else (others => '0');
  
  -------------------------------------------------------
  --! Process to compute needed values from configuration
  -------------------------------------------------------
  process(config_in, n_samples_header, reference_sample_mod) 
  begin
    -- Modified by AS: header generation when the CCSDS123 IP is not present (instead of config_in.PREPROCESSOR=0) --
    if (unsigned(config_in.PREPROCESSOR)=0) or (unsigned(config_in.PREPROCESSOR)= 2) then
    ------------------------------------
      -- CCSDS 121 header
      header(0)(7 downto 0) <= (others => '0');
      -- Modified by AS: preprocessor field when unit-delay predictor or custom predictor is included --
      if (unsigned(config_in.PREPROCESSOR) = 2) then    -- unit-delay predictor
        header(0)(5 downto 5) <= "1";
        header(0)(4 downto 2) <= "001";
      --elsif (unsigned(config_in.PREPROCESSOR) = 3) then  -- custom predictor
      --  header(0)(5 downto 5) <= "1";
      --  header(0)(4 downto 2) <= "111";
      end if;
      ------------------------------------
      header(1)(7 downto 6) <= code_block_size(to_integer(unsigned(config_in.J)));
      header(1)(5 downto 5) <= "1";
      -- Modified by AS: sign of input samples included when unit-delay predictor or custom predictor is included --
      if ((unsigned(config_in.PREPROCESSOR) = 2) or (unsigned(config_in.PREPROCESSOR) = 3)) then
        header(1)(5 downto 5) <= not(config_in.IS_SIGNED);
      end if;
      ------------------------------------
      header(1)(4 downto 0) <= std_logic_vector(resize(unsigned(config_in.D)-1, 5));
      header(2)(7 downto 6) <= "01";
      header(2)(5 downto 4) <= code_dyn_range(to_integer(unsigned(config_in.D)));
      header(2)(3 downto 0) <= n_samples_header(11 downto 8);
      header(3) <= n_samples_header(7 downto 0);
  
      --this part shall only be generated in certain circumstances ((CoderSettings.J.read().to_uint() > 16 || CoderSettings.REF_SAMPLE.read().to_uint() > 256 ||CoderSettings.CODESET.read() == 1))
      header(4)(7 downto 6) <= "11";
      header(4)(5 downto 4) <= "00";
      header(4)(3 downto 0) <= "00"& code_block_size(to_integer(unsigned(config_in.J)));
      -- Modified by YB & AS: this reserved value is defined in the standard as "0"
      header(5)(7 downto 7) <= "0";
      --header(5)(7 downto 7) <= "1";
      header(5)(6 downto 6) <= code_restricted (to_integer(unsigned(config_in.D)), to_integer(unsigned(config_in.CODESET)),to_integer(unsigned(config_in.PREPROCESSOR)));
      header(5)(5 downto 4) <= "00";
      header(5)(3 downto 0) <= std_logic_vector(resize((unsigned(config_in.REF_SAMPLE)-1) srl 8,4));

    elsif (unsigned(config_in.PREPROCESSOR)=1) or (unsigned(config_in.PREPROCESSOR)=3) then
      -- CCSDS 123 header
      header (0)(7 downto 7) <= "0";
      header (0)(6 downto 5) <= code_block_size(to_integer(unsigned(config_in.J)));
      header (0)(4 downto 4) <= code_restricted (to_integer(unsigned(config_in.D)), to_integer(unsigned(config_in.CODESET)),to_integer(unsigned(config_in.PREPROCESSOR)));
      header (0)(3 downto 0) <= reference_sample_mod(11 downto 8);
      header (1) <= reference_sample_mod(7 downto 0);
      header(2 to header'length -1) <= (others => (others => '0'));
    end if;
  end process;
  
  --------------------------------------------------------------------
  --! Process to obtain header words fitting with the output word size
  --------------------------------------------------------------------
  process (clk, rst_n)
    variable pointer_high: integer := 0;
    variable pointer_low: integer := 0;
    variable header_out_tmp: std_logic_vector(W_BUFFER_GEN-1 downto 0) := (others => '0');
    variable shift_bits: unsigned(6 downto 0) := (others => '0');
    variable byte_pointer : unsigned (3 downto 0) := (others => '0');
    variable ACTUAL_HEADER_SIZE : unsigned (rem_bytes'high downto 0); 
    variable ini: std_logic := '1';
  begin
  if (rst_n = '0' and RESET_TYPE = 0) then
    header_out <= (others => '0');
    n_bits <= (others => '0');
    counter_local <= (others => '0');
    rem_bytes <= (others => '0');
    N_BYTES <= (others => '0');
    ini := '1';
    header_out_tmp := (others => '0');
    ACTUAL_HEADER_SIZE := (others => '0');
    pointer_high := 0;
    pointer_low := 0;
    shift_bits := (others => '0');
    byte_pointer := (others => '0');
  elsif (clk'event and clk = '1') then
    if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
      header_out <= (others => '0');
      n_bits <= (others => '0');
      counter_local <= (others => '0');
      rem_bytes <= (others => '0');
      N_BYTES <= (others => '0');
      ini := '1';
      header_out_tmp := (others => '0');
      ACTUAL_HEADER_SIZE := (others => '0');
      shift_bits := (others => '0');
      byte_pointer := (others => '0');
    else
      if (config_received = '1' and ini = '1') then
        -- Computation of the number of words for the header
        -- Modified by AS: case PREPROCESSOR = 2 shall be considered too
        if (unsigned(config_in.PREPROCESSOR) = 0) or (unsigned(config_in.PREPROCESSOR) = 2) then
          if (unsigned(config_in.J) > 16 or unsigned(config_in.REF_SAMPLE) > 256 or unsigned(config_in.CODESET) = 1) then
            ACTUAL_HEADER_SIZE := to_unsigned(6, ACTUAL_HEADER_SIZE'length);
          else
            ACTUAL_HEADER_SIZE := to_unsigned(4, ACTUAL_HEADER_SIZE'length);
          end if;
        else
          ACTUAL_HEADER_SIZE := to_unsigned(2, ACTUAL_HEADER_SIZE'length);
        end if;
        ini := '0';
        rem_bytes <= ACTUAL_HEADER_SIZE;
        N_BYTES <= resize((unsigned(config_in.W_BUFFER(W_W_BUFFER_GEN-1 downto 0)) srl 3), N_BYTES'length);
      -- Prepares the header output words (output word size; last might be smaller)
      elsif (en = '1') then 
        if (rem_bytes >= N_BYTES) then
          for i in 0 to MAX_N_BYTES-1 loop
            pointer_high := 7+i*8;
            pointer_low := i*8;
            byte_pointer := resize(counter_local, byte_pointer'length) + resize(N_BYTES, byte_pointer'length) - to_unsigned(i, byte_pointer'length)-1;
            header_out_tmp (pointer_high downto pointer_low) := header(to_integer(byte_pointer));
            if (i = N_BYTES-1) then 
              exit;
            end if;
          end loop;
          header_out <= std_logic_vector (header_out_tmp);
          counter_local <= counter_local + resize(N_BYTES, counter_local'length);
          rem_bytes <= rem_bytes - N_BYTES;
          n_bits <= std_logic_vector(resize(unsigned(config_in.W_BUFFER), W_NBITS_HEAD_GEN));
        else  
          header_out_tmp := (others => '0');
          for i in 0 to MAX_REMAINDER-1 loop
            pointer_high := 7+i*8;
            pointer_low := i*8; 
            byte_pointer := resize(counter_local, byte_pointer'length) + resize(rem_bytes, byte_pointer'length) - to_unsigned(i, byte_pointer'length)-1;
            header_out_tmp(pointer_high downto pointer_low) := header(to_integer(byte_pointer));
            if (i = rem_bytes-1) then
              exit;
            end if;
          end loop;
          header_out <= std_logic_vector (header_out_tmp);
          n_bits <= std_logic_vector(resize(rem_bytes*8, n_bits'length));
        end if;
      end if;
    end if;
  end if; 
  end process;
end arch_shyloc;
    
