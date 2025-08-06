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
-- Design unit  : splitter module
--
-- File name    : splitter.vhd
--
-- Purpose      : This module splits the FS sequence in chunks, according to the size of the output buffer, to pass it to the bit packing module.
--
-- Note         :
--
-- Library      : shyloc_121
--
-- Author       : Lucana Santos, Ana Gomez
--
-- Instantiates : 
--============================================================================

--!@file #splitter.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief   This module splits the FS sequence in chunks, according to the size of the output buffer, to pass it to the bit packing module.


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
--! Use shyloc_utils functions
use shyloc_utils.shyloc_functions.all;

--! splitter entity  Splits the FS sequence in chunks
entity splitter is
  generic (
    W_BUFFER  : integer := 32;    --! Size of the output buffer
    W_FS_OPT  : integer := 52;    --! Maximum FS sequence + option id bits.
    W_NBITS   : integer := 7;     --! Bit width of the register storing the number of bits of the sequence.
    W_NBITS_K : integer := 6;     --! Bit width of the register storing the number of bits of the 'k' value.
    RESET_TYPE  : integer := 1      --! Reset type
  );
  port (
    -- System Interface
    clk   : in std_logic;       --! Clock signal.
    rst_n : in std_logic;       --! Reset. Active low.
    
    -- Configuration and control Interface
    config_in : in config_121;    --! Current configuration parameters
    start   : in std_logic;     --! Flag to indicate the beginning of a block
    en      : in std_logic;     --! Enable signal.
    clear     : in std_logic;     --! It forces the module to its initial state
    
    -- Data interface
    fs_sequence     : in std_logic_vector (W_FS_OPT-1 downto 0);    --! FS sequence
    n_bits_fs     : in std_logic_vector (W_NBITS-1 downto 0);     --! Number of bits in the FS sequence
    fs_buffered     : out std_logic_vector(W_BUFFER-1 downto 0);    --! FS sequence split in W_BUFFER-bits chunks
    n_bits_fs_buffered  : out std_logic_vector(W_NBITS-1 downto 0)      --! Number of bits in each chunk
    );
end splitter;

--! @brief Architecture of splitter 
architecture arch of splitter is

  -- Signal to capture and shift the input fs_sequence
  signal fs_sequence_reg1: std_logic_vector (W_FS_OPT-1 downto 0);
  
  -- Signals for controlling the bits of the output word and the remaining bits to process
  signal n_bits_fs_buffered_cmb : unsigned (W_NBITS-1 downto 0);
  signal n_bits_fs_buffered_out : unsigned (W_NBITS-1 downto 0);
  signal n_bits_left    : unsigned (W_NBITS-1 downto 0);
  signal n_bits_left_cmb  : unsigned (W_NBITS-1 downto 0);
  
  -- Signals for the output word
  signal fs_buffered_cmb  : std_logic_vector(W_BUFFER-1 downto 0) := (others => '0');
  signal fs_buffered_out  : std_logic_vector(W_BUFFER-1 downto 0);
  
  signal fs_sequence_cmb  : std_logic_vector (W_FS_OPT-1 downto 0);
  signal fs_sequence_reg  : std_logic_vector (W_FS_OPT-1 downto 0);
    
  
begin

  ------------------------------------
  --! Data Output assignments
  ------------------------------------
  fs_buffered <= fs_buffered_out;
  n_bits_fs_buffered <= std_logic_vector(n_bits_fs_buffered_out(n_bits_fs_buffered'high downto 0));
  
  ---------------------------------------------------------------------------------------
  --! Process for n_bits_left and chunks of fs sequence, considering the output word size
  ---------------------------------------------------------------------------------------
  process (start, n_bits_fs, n_bits_left, config_in, fs_sequence_reg1, en, fs_sequence, fs_buffered_out, n_bits_fs_buffered_out, fs_sequence_reg)
    variable temp : signed (n_bits_fs'length downto 0);
    variable W_BUFFER_conf: integer := 0;
    variable i1, i2, amt_right: integer := 0;
    variable fs_sequence_chunks: std_logic_vector (W_BUFFER_GEN-1 downto 0);
    variable fs_sequence_shift : std_logic_vector(fs_sequence'high downto 0);
  begin
    fs_sequence_cmb <= fs_sequence_reg;
    -- Output word size and indexes computation for getting data from fs_qequence
    W_BUFFER_conf := to_integer(unsigned(config_in.W_BUFFER));
    i1:= fs_sequence'high;
    if (fs_sequence'high - W_BUFFER + 1 > 0) then
      i2:= fs_sequence'high - W_BUFFER + 1 ;
    else 
      i2:= 0;
    end if;
    -- default assignment to variable to avoid latches
    fs_sequence_chunks := (others => '0');
    if (start = '1') then
      if (unsigned(n_bits_fs) >= to_unsigned(W_BUFFER_conf, n_bits_left'length)) then           
        -- amount to shift
        amt_right := get_amt_shift(W_BUFFER, W_BUFFER_conf);
        fs_sequence_shift := std_logic_vector(shift_right (unsigned (fs_sequence), amt_right));
        fs_sequence_cmb <= fs_sequence_shift;
        -- chunk of size W_BUFFER (and I use all the bits)
        fs_sequence_chunks(W_BUFFER - 1 downto W_BUFFER -(i1-i2+1)):= fs_sequence_shift (i1 downto i2);
        -- shift chunk according to W_BUFFER_conf
        fs_buffered_cmb <= fs_sequence_chunks;
        -- compute bits left 
        n_bits_fs_buffered_cmb <= to_unsigned(W_BUFFER_conf, n_bits_left'length);
        temp := signed('0'&n_bits_fs) - to_signed(W_BUFFER_conf, n_bits_fs'length);       
        n_bits_left_cmb <= unsigned(temp(n_bits_left_cmb'high downto 0));
      elsif (unsigned(n_bits_fs) > 0) then
        -- amount to shift
        amt_right := W_BUFFER - to_integer(unsigned(n_bits_fs));
        -- chunk of size W_BUFFER
        fs_sequence_chunks(W_BUFFER-1 downto W_BUFFER - (i1-i2+1)):= fs_sequence(i1 downto i2);
        -- shift chunk according to W_BUFFER_conf
        fs_sequence_chunks:= std_logic_vector(shift_right (unsigned (fs_sequence_chunks), amt_right));
        fs_buffered_cmb <= fs_sequence_chunks;
        -- compute bits left 
        n_bits_fs_buffered_cmb <= unsigned(n_bits_fs);
        n_bits_left_cmb <= (others => '0');
      else 
        fs_buffered_cmb <= (others => '0');
        n_bits_fs_buffered_cmb <= (others => '0');
        n_bits_left_cmb <= (others => '0');
      end if;
    elsif en = '1' then
      if (n_bits_left >= to_unsigned(W_BUFFER_conf, n_bits_left'length)) then 
        -- amount to shift
        amt_right := get_amt_shift(W_BUFFER, W_BUFFER_conf);
        fs_sequence_shift := std_logic_vector(shift_right (unsigned (fs_sequence_reg1), amt_right));
        fs_sequence_cmb <= fs_sequence_shift;
        -- chunk of size W_BUFFER
        fs_sequence_chunks(W_BUFFER-1 downto W_BUFFER -(i1-i2+1)):= fs_sequence_shift (i1 downto i2);
        -- shift chunk according to W_BUFFER_conf
        fs_buffered_cmb <= fs_sequence_chunks;
        -- compute bits left 
        n_bits_fs_buffered_cmb <= to_unsigned(W_BUFFER_conf, n_bits_left'length); 
        n_bits_left_cmb <= n_bits_left - to_unsigned(W_BUFFER_conf, n_bits_left'length); 
      elsif (n_bits_left > 0) then
        -- amount to shift
        amt_right := W_BUFFER - to_integer(n_bits_left);
        -- chunk of size W_BUFFER
        fs_sequence_chunks(W_BUFFER-1 downto W_BUFFER -(i1-i2+1)):= fs_sequence_reg1(i1 downto i2);
        -- shift chunk according to W_BUFFER_conf
        fs_sequence_chunks:= std_logic_vector(shift_right (unsigned (fs_sequence_chunks), amt_right));
        fs_buffered_cmb <= fs_sequence_chunks;
        -- compute bits left 
        n_bits_left_cmb <= (others => '0');
        n_bits_fs_buffered_cmb <= n_bits_left;
      else
        n_bits_fs_buffered_cmb <= (others => '0');
        n_bits_left_cmb <= (others => '0');
        fs_buffered_cmb <= (others => '0');
      end if;
    else
      n_bits_fs_buffered_cmb <= n_bits_fs_buffered_out;
      n_bits_left_cmb <= n_bits_left;
      fs_buffered_cmb <= fs_buffered_out;
    end if;
  end process;
  
  ----------------------------------------------------
  --! Registration process and fs_sequence_reg1 update
  ----------------------------------------------------
    process (clk, rst_n) 
      variable amt_left : integer := 0;
    begin
      if (rst_n = '0' and RESET_TYPE = 0) then
        n_bits_fs_buffered_out <= (others => '0');
        n_bits_left <= (others => '0');
        fs_buffered_out <= (others => '0');
        fs_sequence_reg1 <= (others => '0');
        amt_left:= 0;
        fs_sequence_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
        if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
          n_bits_fs_buffered_out <= (others => '0');
          n_bits_left <= (others => '0');
          fs_buffered_out <= (others => '0');
          fs_sequence_reg1 <= (others => '0');
          amt_left:= 0;
          fs_sequence_reg <= (others => '0');
        else
          fs_sequence_reg <= fs_sequence_cmb;
          amt_left := W_BUFFER;
          if (en = '1') then
            if (start = '1') then 
              fs_sequence_reg1 <= std_logic_vector(shift_left(unsigned(fs_sequence_cmb), amt_left));
            else
              fs_sequence_reg1 <= std_logic_vector(shift_left(unsigned(fs_sequence_cmb), amt_left));
            end if;
            n_bits_left <= n_bits_left_cmb;
            fs_buffered_out <= fs_buffered_cmb;
            n_bits_fs_buffered_out <= n_bits_fs_buffered_cmb;
          end if; 
        end if;   
      end if;
    end process;


end arch;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


