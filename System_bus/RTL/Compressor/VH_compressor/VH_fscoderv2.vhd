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
-- Design unit  : fscoderv2 module
--
-- File name    : fscoderv2.vhd
--
-- Purpose      : This module will create the FS codewords and send the split bits to the split FIFOs. 
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
-- Instantiates : barrel (barrel_shifter)
--============================================================================

--!@file #fscoderv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es, ajsanchez@iuma.ulpgc.es, ybarrios@iuma.ulpgc.es, dventura@iuma.ulpgc.es
--!@brief  This module will create the FS codewords and send the split bits to the split FIFOs. Its behaviour depends on the encoding option.

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

--! fscoderv2 This module will create the FS codewords and send the split bits to the split FIFOs. Its behaviour depends on the encoding option.
entity fscoderv2 is
  generic (
    W_BUFFER: integer := 32;      --! Size in bits of the output buffer.
    BLOCK_SIZE: integer := 16;    --! Number of samples in a block.
    W_K: integer := 4;        --! Bit width of the number of bits to split (k).
    W_OPT: integer := 5;      --! Number of bits for the option identifier.
    W_L: integer := 9;        --! Bit width of the encoded block length.
    W_NBITS: integer := 7;      --! Bit width of the register storing the number of bits of the FS option.
    W_NBITS_K: integer := 6;    --! Bit width of the register storing "k".
    W_MAP: integer := 16;     --! Bit width of the mapped prediction residuals.
    W_FS_OPT: integer := 52;    --! Maximum number of bits of an FS codeword for any encoding option. 
    K_MAX : integer := 14;      --! Maximum possible value of "k".
    W_GAMMA: integer := 4;      --! Bit width of Gamma (see second extension block sndextension.vhd).
    W_ZERO: integer := 7;     --! Bit width of the zero_block counter.
    RESET_TYPE : integer := 1   --! Reset type.
    ); 
  port (
    -- System Interface
    clk   : in std_logic;                 --! Clock signal.
    rst_n : in std_logic;                 --! Reset signal. Active low.
    
    -- Configuration  Interface
    config_in : in config_121;              --! Current configuration parameters.
    
    -- Data and Control Interface
    start   : in std_logic;                 --! Flag to indicate the beginning of a new block.
    en      : in std_logic;                 --! Enable signal.
    clear   : in std_logic;                 --! It forces the module to its initial state.
    -- Modified by AS: new interface port --
    ref_block  : in std_logic;                  --! Reference sample included in the current block
    ------------------------------------
    winner_k  : in std_logic_vector (W_K -1 downto 0);    --! "k" value for the sample split option.
    winner_l  : in std_logic_vector (W_L-1 downto 0);     --! Length of the encoded block with the selected option.
    option    : in std_logic_vector (W_OPT-1 downto 0);   --! Selected encoding option.
    mapped    : in std_logic_vector (W_MAP-1 downto 0);   --! Mapped prediction residuals.
    gamma   : in std_logic_vector (W_GAMMA-1 downto 0);   --! Gamma value.
    zero_count  : in std_logic_vector (W_ZERO-1 downto 0);    --! Number of zero block.
    zero_code : in std_logic_vector (1 downto 0);       --! Operation code for zero block option.
    fs_sequence : out std_logic_vector (W_FS_OPT-1 downto 0); --! Resulting FS codeword.
    nbits_fs  : out std_logic_vector (W_NBITS-1 downto 0);  --! Number of bits of the FS codeword.
    nbits_k   : out std_logic_vector (W_NBITS_K-1 downto 0);  --! Number of bits of the "k" value.
    split_bits  : out std_logic_vector (W_BUFFER-1 downto 0)  --! Split bits for the sample split option.
    );
end fscoderv2;

--! @brief Architecture of fscoderv2
--! @details This module will create the FS codewords and send the split bits to the split FIFOs. Its behaviour depends on the encoding option.
architecture arch of fscoderv2 is

  -- Constants and pre-defined values
  constant W_K_OPT : integer := W_OPT - 1;
  constant N_INDEX: integer := log2(W_FS_OPT);
  constant ones: std_logic_vector (option'high downto 0) := (others => '1');
  constant opt_zero: std_logic_vector (option'high downto 0) := (others => '0');
  constant opt_no_encode: std_logic_vector (option'high downto 0) := (others => '1');
    
  -- Signals for control and intermediate calculations
  signal input      : std_logic_vector (W_MAP-1 downto 0);  
  signal input_shifted  : std_logic_vector (W_MAP-1 downto 0);  
  signal fs_sequence_seq  : std_logic_vector (W_FS_OPT-1 downto 0);   -- register to store FS
  signal fs_sequence_cmb  : std_logic_vector (W_FS_OPT-1 downto 0);   -- register to store FS
  signal index      : unsigned (N_INDEX-1 downto 0);      -- register to store index
  signal index_cmb    : unsigned (N_INDEX-1 downto 0);      -- register to store index
  signal split_bits_cmb : std_logic_vector (W_MAP-1 downto 0);  
  signal nbits_fs_cmb   : signed (winner_l'high+1 downto 0);
  signal nbits_k_cmb    : signed (winner_l'high+1 downto 0);
  -- Modified by AS: new register to store the reference sample
  signal ref_sample    : std_logic_vector (W_MAP-1 downto 0);
  ------------------------------------
  
begin

  -----------------
  --! Input capture
  -----------------
  input <= std_logic_vector(resize(unsigned(gamma),input'length)) when option(option'high) = '0' and option(0) = '1' else mapped;
  
  ------------------------------------
  --! Data Output assignments
  ------------------------------------
  fs_sequence <= fs_sequence_seq;

  ---------------------------------------------------------
  --! Computation of nbits according to the selected option 
  ---------------------------------------------------------
  -- Here be sure to compute correctly the length for the FS sequence and the K split bits.
  -- In case a reference sample has to be inserted, the number of K split bits of the first
  -- sample shoud be 0. this ensures those split bits are not packed to the output
  -- Even if anyway the split bits are stored in the FIFO. 
  -- Modified by AS: start and ref_block signals included in the sensitivity list --
  process (winner_k, winner_l, option, zero_code, zero_count, config_in, start, ref_block)
  ------------------------------------
    variable logBLOCK_conf: integer := 0;
    variable v0: signed (winner_k'high + 1 downto 0);
    variable v1: signed (nbits_fs_cmb'high downto 0);
    variable W_OPT_conf : integer := 0;
    -- Modified by AS: new variable to conditionally increase the codeword length for the Zero-Block option --
    variable nbits_ref: signed (nbits_fs_cmb'high downto 0);
    ------------------------------------
  begin
    v0 := signed('0'&winner_k);
    W_OPT_conf := get_n_bits_option(to_integer(unsigned(config_in.D)),to_integer(unsigned(config_in.CODESET)));
    logBLOCK_conf:= log2_simp(to_integer(unsigned(config_in.J))-1);
    v1 := resize(v0, nbits_fs_cmb'length) sll logBLOCK_conf;
    -- Modified by AS: When the reference sample is inserted, the number of samples in the split segment is reduced by 1 --
    -- -- The length of the split segment (v1) is then reduced by winner_k --
    --if ((start = '1') and (ref_block = '1')) then
    if ((ref_block = '1')) then
      v1 := v1 - resize(signed(winner_k), nbits_fs_cmb'length);
    end if;
    ------------------------------------
    if (zero_code = "01" and unsigned(zero_count) > 0) then 
      nbits_fs_cmb <= (others => '0');
      nbits_k_cmb <= (others => '0');
    -- there are bits to encode from zero_block
    elsif (option = opt_zero) then 
      nbits_k_cmb <= (others => '0');
      -- Modified by AS: When a Zero-Block includes a reference sample, the codeword length is increased by D --
      if (ref_block = '1') then
        nbits_ref := resize(signed('0' & config_in.D), nbits_fs_cmb'length);
      else
        nbits_ref := to_signed(0, nbits_fs_cmb'length);
      end if;
      ------------------------------------
      if (unsigned(zero_count) < 5) then
        -- because of option 
        nbits_fs_cmb <= resize(signed ('0'&zero_count), nbits_fs_cmb'length) + to_signed(W_OPT_conf, nbits_fs_cmb'length) + nbits_ref; 
      else
        if (zero_code(0) = '1') then
          --ROS CONDITION 
          nbits_fs_cmb <= to_signed(W_OPT_conf+5, nbits_fs_cmb'length) + nbits_ref; 
        else
          nbits_fs_cmb <= resize(signed ('0'&zero_count), nbits_fs_cmb'length) + to_signed((W_OPT_conf+1), nbits_fs_cmb'length) + nbits_ref; 
        end if;
      end if;
    -- no compression
    elsif (option = opt_no_encode) then 
      nbits_fs_cmb <= to_signed(W_OPT_conf-1, nbits_fs_cmb'length); 
      nbits_k_cmb <= resize (signed('0'&winner_k), nbits_k_cmb'length);
    else
      nbits_fs_cmb <= signed ('0'&winner_l) - v1 + to_signed(W_OPT_conf-1, nbits_fs_cmb'length); 
      nbits_k_cmb <= resize (signed('0'&winner_k), nbits_k_cmb'length);
      -- Modified by AS: With the FS option, the reference sample has no split bits --
      if ((start = '1') and (ref_block = '1')) then
        nbits_k_cmb <= to_signed(0, nbits_k_cmb'length);
      end if;
      ------------------------------------
    end if;
  end process;
  
  ------------------------------------
  --!@brief barrel_shifter
  ------------------------------------
  barrel: entity shyloc_utils.barrel_shifter(arch)
  generic map (W => W_MAP, S_MODE => 1, STAGES => W_K)
  port map(barrel_data_in => input, amt => winner_k, barrel_data_out => input_shifted);
  
  -----------------------------------------------------------------------------------------------------------------------------------
  --! fs_sequence update if applicable (Controls the mask also, placing the ones in the correct places of the buffer when start == 1)
  -----------------------------------------------------------------------------------------------------------------------------------
  -- Modified by AS: ref_block signal included in the sensitivity list --
  process (input_shifted, start, fs_sequence_seq, option, index, en, zero_code, zero_count, config_in, ref_block, mapped, ref_sample)
  ------------------------------------
    variable i1, i2, i3: natural := 0;
    -- Modified by AS: new variable to compute the field lengths --
    variable i2ref: natural := 0;
    ------------------------------------
    variable mapped_var: unsigned (W_MAP -1 downto 0);
    variable fs_sequence_var: std_logic_vector (fs_sequence_seq'high downto 0);
    variable mask_tmp: unsigned (fs_sequence_seq'high downto 0);
    variable mask: std_logic_vector (fs_sequence_seq'high downto 0);
    variable W_K_OPT_conf : integer := 0;
    variable W_OPT_conf : integer := 0;
    variable amt_left: integer := 0;
  begin
    fs_sequence_var := fs_sequence_seq;
    -- Modified by AS: Initial assignment to variable i2ref to avoid latch inferences
    i2ref := 0;
    ------------------
    -- no compression
    if (option = ones) then             
      mask_tmp := (others => '0');
    -- fs sequence
    else                      
      mask_tmp := (0 => '1', others => '0');
    end if;
    W_OPT_conf := get_n_bits_option(to_integer(unsigned(config_in.D)),to_integer(unsigned(config_in.CODESET)));
    W_K_OPT_conf := get_n_bits_option(to_integer(unsigned(config_in.D)),to_integer(unsigned(config_in.CODESET))) - 1;
    fs_sequence_cmb  <= fs_sequence_seq;
    index_cmb <= index;
    --For the first sample in a block (start = '1') I attach the first FS-encoded mapped value to the option code.
    --When a reference sample needs to be inserted, this would be a sample uncompressed. 
    if (start = '1') then 
      mapped_var := unsigned (input_shifted);
      i1 := fs_sequence_seq'high; 
      -- second extension
      if (option(option'high) = '0' and option(0) = '1') then
        i2 := fs_sequence_seq'high - W_OPT + 1;
        -- Modified by AS: allocating space for the reference sample in the codeword
        if (ref_block = '1') then
          i2ref := i2 - to_integer(unsigned(config_in.D));
        else
          i2ref := i2;
        end if;
        ------------------------------------
        -- Modified by AS: i2 substituted by i2ref --
        if (i2ref > to_integer(mapped_var)) then
          i3 := i2ref - to_integer(mapped_var);
        ------------------------------------
        else
          i3 := fs_sequence_seq'high;
        end if;
        mask := std_logic_vector(shift_left(mask_tmp, i3-1));
        --With the refence sample, just attach the uncompressed sample after the option and do not insert the "one"
        -- of the FS code of the first mapped residual or second extension value. 
        fs_sequence_var (fs_sequence_cmb'high downto i2) := option; 
        fs_sequence_var (i2-1 downto 0) := mask(i2-1 downto 0);
        -- Modified by AS: the reference sample is inserted after optcode in addition to the FS codeword --
        -- -- Note: it must be checked if the reference sample arrives in the correct cycle, or it is necessary to register it --
        if (ref_block = '1' and option /= opt_no_encode) then
          fs_sequence_var (i2-1 downto i2ref) := mapped ((i2 - i2ref)-1 downto 0);
          fs_sequence_var (i2ref-1 downto 0)  := mask(i2ref-1 downto 0);
        end if;
        ------------------------------------
        amt_left := W_OPT - W_OPT_conf;
        fs_sequence_cmb <= std_logic_vector(shift_left(unsigned(fs_sequence_var), amt_left));
        index_cmb <= to_unsigned(i3-1, index_cmb'length) + amt_left;
      -- k-split or FS
      else 
        i2 := fs_sequence_seq'high - W_K_OPT + 1; 
        if (i2 > to_integer(mapped_var)) then
          i3 := i2 - to_integer(mapped_var);
        else
          i3 := fs_sequence_seq'high;
        end if;
        -- Modified by AS: the reference sample substitutes the first FS codeword of the block, so the field lengths are adjusted --
        if (ref_block = '1') then
          i2ref := i2 - to_integer(unsigned(config_in.D));
          i3 := i2ref;
        else
          i2ref := i2;
        end if;
        ------------------------------------
        mask := std_logic_vector(shift_left(mask_tmp, i3-1));
        amt_left := W_K_OPT - W_K_OPT_conf;
        fs_sequence_var (fs_sequence_cmb'high downto i2) := option (W_K_OPT -1 downto 0);
        fs_sequence_var (i2-1 downto 0) := mask(i2-1 downto 0);
        -- Modified by AS: the reference sample substitutes the first FS codeword of the block --
        if (ref_block = '1') then
          fs_sequence_var (i2-1 downto i2ref) := mapped ((i2 - i2ref)-1 downto 0);
          fs_sequence_var (i2ref-1 downto 0)  := (others => '0');
        end if;
        ------------------------------------
        fs_sequence_cmb <= std_logic_vector(shift_left(unsigned(fs_sequence_var), amt_left));
        index_cmb <= to_unsigned(i3-1, index_cmb'length)+ amt_left;
        -- Modified by AS: index adjusted when a reference sample is inserted --
        if (ref_block = '1') then
          index_cmb <= to_unsigned(i3, index_cmb'length)+ amt_left;
        end if;
        -------------------------
      end if; 
    elsif (en = '1') then
      --Here we are counting zeros
      if ((zero_code = "01" and unsigned(zero_count) > 1)) then     
        fs_sequence_cmb <= (others => '0');
        index_cmb <= (others => '0');
      -- FS sequence for zero_block option
      -- Here we encode the pending zero blocks. This has to be done before the encoding of the 
      -- next non-zero block. It's good to check the waveform of these values to have an idea of
      -- what happens, because there is a small trick that enables the processing to keep a rate
      -- of one sample/cycle despite the fact that it's somehow "late" when we realize we have to
      -- encode zero blocks. 
      elsif (zero_code(1) = '1' and option = opt_zero) then 
        if (unsigned(zero_count) < 5) then
          mapped_var := resize(unsigned (zero_count), mapped_var'length) - 1;
        else
          -- end of segment
          if zero_code (0) = '1' then 
            --ROS
            mapped_var := to_unsigned (4, mapped_var'length); 
          else
            mapped_var := resize(unsigned (zero_count), mapped_var'length);
          end if;
        end if;
        i1 := fs_sequence_seq'high;  
        i2 := fs_sequence_seq'high - W_OPT + 1;
        -- Modified by AS: allocating space for the reference sample in the codeword
        if (ref_block = '1') then
          i2ref := i2 - to_integer(unsigned(config_in.D));
        else
          i2ref := i2;
        end if;
        ------------------------------------
        -- Modified by AS: i2 substituted by i2ref --
        if (i2ref > to_integer(mapped_var)) then 
          i3 := i2ref - to_integer(mapped_var);
        ------------------------------------
        else
          i3 := fs_sequence_seq'high;
        end if;
        mask := std_logic_vector(shift_left(mask_tmp, i3-1));
        amt_left := W_OPT - W_OPT_conf;
        -- If you need to insert a reference sample, you can attach it to the option. 
        fs_sequence_var (fs_sequence_cmb'high downto i2) := option; 
        fs_sequence_var (i2-1 downto 0) := mask(i2-1 downto 0);
        -- Modified by AS: the reference sample is inserted after optcode in addition to the Zero-block codeword --
        -- -- Note: it must be checked if the reference sample is correctly stored --
        if (ref_block = '1') then
          fs_sequence_var (i2-1 downto i2ref) := ref_sample ((i2 - i2ref)-1 downto 0);
          fs_sequence_var (i2ref-1 downto 0)  := mask(i2ref-1 downto 0);
        end if;
        ------------------------------------
        fs_sequence_cmb <= std_logic_vector(shift_left(unsigned(fs_sequence_var), amt_left));       
        index_cmb <= to_unsigned(i3-1, index_cmb'length);
      --elsif (option /= opt_zero) then
      else
        mapped_var := unsigned (input_shifted);
        if (to_integer(index) > to_integer(mapped_var)) then
          i3 := to_integer(index) - to_integer(mapped_var);
        else
          i3:= to_integer(index);
        end if;
        mask := std_logic_vector(shift_left(mask_tmp, i3-1));
        fs_sequence_cmb  <= fs_sequence_seq or mask;
        if (i3 = 0) then
          index_cmb <= to_unsigned(i3, index_cmb'length);
        else
          index_cmb <= to_unsigned(i3-1, index_cmb'length);
        end if;
      --else
        --fs_sequence_cmb  <= fs_sequence_seq;
        --index_cmb <= index;
      end if;     
    end if;
  end process;

  --------------
  --! split_bits 
  --------------
  -- Modified by AS: start and ref_block signals included in the sensitivity list --
  process (input, winner_k, start, ref_block)
  ------------------------------------
     variable k_ind: natural := 0;
     variable mask_tmp, mask: unsigned (split_bits_cmb'high downto 0);
     variable mask1: std_logic_vector (split_bits_cmb'high downto 0); 
   begin
     k_ind := to_integer(unsigned(winner_k));
     mask_tmp := (0 => '1', others => '0');
     mask := shift_left(mask_tmp, k_ind);
     mask1 := std_logic_vector(mask - 1);
     split_bits_cmb <= input and mask1;
     -- Modified by AS: split bits not used when reference sample is inserted
     if ((start = '1') and (ref_block = '1') and (option /= opt_no_encode)) then
      split_bits_cmb <= (others => '0');
     end if;
     ------------------------------------
   end process;
  
  ----------------------------------------------
  --! split_bits and n_bits signals registration
  ----------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      fs_sequence_seq <= (others => '0');
      split_bits <= (others => '0');
      index <= (others => '0');
      nbits_fs <= (others => '0');
      nbits_k <= (others => '0');
      split_bits <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        fs_sequence_seq <= (others => '0');
        split_bits <= (others => '0');
        index <= (others => '0');
        nbits_fs <= (others => '0');
        nbits_k <= (others => '0');
        split_bits <= (others => '0');
      else
        if (en = '1') then
          fs_sequence_seq <= fs_sequence_cmb;
          index <= index_cmb;
          split_bits <= std_logic_vector(resize(unsigned(split_bits_cmb), split_bits'length));
          if not(zero_code = "01" and unsigned(zero_count) = 1) then
            --nbits_fs <= std_logic_vector(resize(nbits_fs_cmb,nbits_fs'length));
            --nbits_k <= std_logic_vector(resize(nbits_k_cmb,nbits_k'length));
            nbits_fs <= std_logic_vector (nbits_fs_cmb(nbits_fs'high downto 0));
            nbits_k <= std_logic_vector (nbits_k_cmb(nbits_k'high downto 0));
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Modified by AS: reference sample registration for zero-block code option
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      ref_sample <= (others => '1');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ref_sample <= (others => '1');
      else
        --if ((en = '1') and (start = '1')) then
        if (start = '1') then
          if (ref_block = '1') then
            ref_sample <= mapped;
          else
            ref_sample <= (others => '1');
          end if;
        end if;
      end if;
    end if;
  end process;
  ------------------------------------

end arch;
