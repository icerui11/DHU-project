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
-- Design unit  : packing_top module
--
-- File name    : packing_top.vhd
--
-- Purpose      : Performs the bit packing of the output bitstream as it is calculated
--
-- Note         :
--
-- Library      : shyloc_121
--
--
-- Instantiates : final_packer (bitpackv2)
--============================================================================

--!@file #packing_top.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Performs the bit packing of the output bitstream as it is calculated 

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
--! Use shyloc_functions functions
use shyloc_utils.shyloc_functions.all;

--! packing_top entity  
--! Performs the bit packing for the final bit stream, providing the proper input to the bit-packer module between all posibilities (fundamental sequences, header words, split bits)
entity packing_top is
      generic (
        W_BUFFER : integer := 32;       --! Number of bits of the output buffer.
        W_NBITS_K : integer := 6;     --! Number of bits of the "k" value.
        W_NBITS: integer:= 7;       --! Number of bit of the fs or k-split sequence.
        W_OPT : integer := 5;       --! Number of bits of the option ID.
        W_MAP: integer := 16;       --! Number of bits of the mapped prediction residuals.
        RESET_TYPE  : integer := 1      --! Reset type.
        );
      port (
        -- System Interface
        clk   : in std_logic;                     --! Clock signal.
        rst_n : in std_logic;                     --! Reset signal. Active low.
        
        -- Configuration and control Interface
        config_in     : in config_121;              --! Current configuration parameters.
        config_valid    : in std_logic;               --! Flag to validate the configuration parameters.
        en_bitpack_final  : in std_logic;               --! Flag to enable packing of the final codewords.
        flush_final     : in std_logic;               --! Flag to perform a flush at the end of the compressed file.
        clear       : in std_logic;               --! It forces the module to its initial state.
        
        -- Header data Interface
        flag_pack_header  : in std_logic;                     --! Flag to enable packing the generated header.
        header        : in  std_logic_vector (W_BUFFER-1 downto 0);     --! 121 Header values.
        n_bits_header   : in std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0);   --! Number of bits in the header.
        
        -- Preprocessor-header data Interface
        flag_pack_header_prep : in std_logic;                   --! Flag to pack header from pre-processor.
        header_prep       : in  std_logic_vector (W_MAP-1 downto 0);      --! pre-processor header values.
        n_bits_header_prep    : in std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0); --! Number of bits in the preprocessor header.
        
        -- Fundamental sequence data Interface
        flag_pack_fs    : in std_logic;                 --! Flag to enable packing of the FS codeword.
        fs_buffered     : in std_logic_vector (W_BUFFER-1 downto 0);  --! FS sequence in chunks of W_BUFFER bits.
        n_bits_fs_buffered  : in std_logic_vector (W_NBITS-1 downto 0);   --! Number of bits in each chunk.
        
        -- split bits data Interface
        flag_split_fifo : in std_logic;                   --! Flag to enable packing of split bits allocated in split FIFO.
        split_bits    : in  std_logic_vector (W_BUFFER-1 downto 0);   --! Split bits.
        n_bits_split  : in std_logic_vector(W_W_BUFFER_GEN-1 downto 0); --! Number of bits in each of the split bits (is the same as "k").
        
        -- remaining split bits data Interface
        flag_split_flush_register : in std_logic;                   --! Flag to pack the flush register of split bits.
        buff_left         : in std_logic_vector (W_BUFFER -1 downto 0);   --! Flush register.
        bits_flush          : in std_logic_vector (W_W_BUFFER_GEN-1 downto 0);  --! Number of bits in the flush register.
        
        -- residuals data Interface
        flag_pack_bypass    : in std_logic;               --! Flag to enable packing of the residuals.
        residuals_buffered    : in std_logic_vector (D_GEN-1 downto 0); --! residuals sequence in chunks of D bits.
        
        -- Data Output Interface
        buff_out  : out std_logic_vector (W_BUFFER-1 downto 0);   --! Output word.
        buff_full : out std_logic                   --! Flag to validate the output word.
      );
end packing_top;

--! @brief Architecture of packing_top 
architecture arch of packing_top is

  --! Signals for transfering the proper values of codeword and the proper number of bits
  constant W_NBITS_PACKER : integer := maximum (W_NBITS_K, W_NBITS);
  signal n_bits     : std_logic_vector (W_NBITS_PACKER-1 downto 0);
  signal codeword     : std_logic_vector (W_BUFFER-1 downto 0);

begin
    
  --------------------------------------------------------------
  --! Selection of the proper input to the bitpack module
  --------------------------------------------------------------
  process (config_in, flag_pack_fs, fs_buffered, flag_split_fifo, split_bits, n_bits_split, n_bits_fs_buffered, n_bits_header, n_bits_header_prep, flag_split_flush_register, buff_left, bits_flush, flag_pack_header, header, flag_pack_header_prep, flag_pack_bypass, header_prep, residuals_buffered)
    variable shift: integer := 0;
    variable bits: std_logic_vector (n_bits'high +1 downto 0);
    variable W_BUFFER_conf : integer := 0;
  begin
    W_BUFFER_conf := to_integer(unsigned(config_in.W_BUFFER));
    bits := std_logic_vector(to_signed(W_BUFFER_conf, n_bits'length+1) - signed('0'&bits_flush));
    shift := to_integer(unsigned(bits_flush));
    -- fs_sequence to pack
    if (flag_pack_fs = '1') then
      codeword <= fs_buffered;
      n_bits <= std_logic_vector(resize(unsigned(n_bits_fs_buffered), n_bits'length));
    -- split bits to pack
    elsif (flag_split_fifo = '1') then
      codeword <= split_bits;
      n_bits <= std_logic_vector(resize (unsigned(n_bits_split), n_bits'length));
    -- remaining split bits to pack
    elsif (flag_split_flush_register = '1') then
      codeword <= std_logic_vector(shift_right (unsigned(buff_left), shift));
      n_bits <= bits (n_bits'high downto 0);
    -- header to pack
    elsif (flag_pack_header = '1') then
      codeword <= header;
      n_bits <= std_logic_vector(resize(unsigned(n_bits_header), n_bits'length));
    -- pre-processing header to pack
    elsif flag_pack_header_prep = '1' then
      codeword <= std_logic_vector(resize(unsigned(header_prep), W_BUFFER_GEN));
      n_bits <= std_logic_vector(resize(unsigned(n_bits_header_prep), n_bits'length));
    -- residuals to pack
    elsif flag_pack_bypass = '1' then
      codeword <= std_logic_vector(resize(unsigned(residuals_buffered), W_BUFFER_GEN));
      --if (EN_RUNCFG = 0) then
        --n_bits <= std_logic_vector(to_unsigned(W_BUFFER_GEN, n_bits'length));
      --else
        n_bits <= std_logic_vector(resize(unsigned(config_in.W_BUFFER), n_bits'length));
      --end if;
    else
      codeword <= (others => '0');
      n_bits <= (others => '0');
    end if;
  end process;
    
  ------------------------------------
  --!@brief Bit packing module
  ------------------------------------
  final_packer: entity shyloc_utils.bitpackv2(arch)
    generic map (
      W_W_BUFFER_GEN => W_W_BUFFER_GEN, 
      RESET_TYPE => RESET_TYPE,
      W_BUFFER => W_BUFFER, 
      W_NBITS => W_NBITS_PACKER)
    port map (
      clk => clk, 
      rst_n => rst_n, 
      en => en_bitpack_final, 
      clear => clear,
      W_BUFFER_configured => config_in.W_BUFFER,
      config_valid => config_valid,     
      n_bits => n_bits,
      flush => (flush_final), 
      codeword => codeword, 
      buff_out => buff_out, 
      buff_full => buff_full
    );  
      
end arch;
