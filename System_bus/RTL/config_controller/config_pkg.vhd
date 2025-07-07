--------------------------------------------------------------------------------
--== Filename ..... config_pkg.vhd                                      ==--
--== Institute .... IDA TU Braunschweig RoSy ==--
--== Authors ...... Rui Yin                                             ==--
--== Copyright .... Copyright (c) 2025 IDA                              ==--
--== Project ...... Compression Core Configuration                      ==--
--== Version ...... 1.00                                                ==--
--== Conception ... June 2025                                            ==--

library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should compile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library shyloc_123; 
use shyloc_123.ccsds123_constants.all; 

package config_pkg is

    -- Constants
    constant c_num_compressors : integer := 3; -- Number of compressors    
--    constant c_ram_addr_width : integer := 8;               -- RAM address width
    -- Config RAM parameters
    constant c_input_data_width  : integer := 8;   -- Input data width
    constant c_input_addr_width  : integer := 7;   -- Input address width
    constant c_input_depth       : integer := 96;  -- Input address depth
    constant c_output_data_width : integer := 32;  -- Output data width
    constant c_output_addr_width : integer := 5;   -- Output address width
    constant c_output_depth      : integer := 24;  -- Output address depth

    -- Base addresses for each module (5 bits)
    constant c_hr_ccsds123_base : std_logic_vector(4 downto 0) := "00010"; -- 0x08 >> 2
    constant c_hr_ccsds121_base : std_logic_vector(4 downto 0) := "00111"; -- 0x1C >> 2
    constant c_lr_ccsds123_base : std_logic_vector(4 downto 0) := "11000"; -- 0x30 >> 2
    constant c_lr_ccsds121_base : std_logic_vector(4 downto 0) := "10001"; -- 0x44 >> 2
    constant c_h_ccsds121_base  : std_logic_vector(4 downto 0) := "10101"; -- 0x54 >> 2
      -- Number of registers for each configuration
    constant CCSDS123_CFG_NUM : integer := 6; -- 6 registers for CCSDS123
    constant CCSDS121_CFG_NUM : integer := 4; -- 4 registers for CCSDS121

    -- Compressor status type 
    type compressor_status is record
        AwaitingConfig : std_logic;  
        Ready          : std_logic;
        Finished       : std_logic;
        Error          : std_logic;
    end record;

    type compressor_status_array is array (0 to c_num_compressors-1) of compressor_status;
    
    constant compressor_status_init : compressor_status := (                -- compressor after reset state
        AwaitingConfig => '1',
        Ready          => '0',
        Finished       => '0',
        Error          => '0'
    );

    type config_state_type is (IDLE, ARBITER_WR, AHB_TRANSFER_WR, AHB_Burst_WR, ERROR); 
    type reg_type is record
      config_state              : config_state_type;
      ram_read_cnt              : unsigned(3 downto 0); -- RAM read counter (4 bits) 
      ram_rd_en                 : std_logic; -- RAM read enable signal
      ram_rd_addr               : std_logic_vector(c_output_addr_width-1 downto 0); -- RAM read address
      ram_rd_data               : std_logic_vector(c_output_data_width-1 downto 0); -- RAM read data
      ram_rd_valid              : std_logic; 
      start_preload_ram         : std_logic; -- Signal to start preloading RAM 
      data_valid                : std_logic; -- Data valid signal
      r_update                  : std_logic; 
      w_update                  : std_logic; 
      clr                       : std_logic; 
      hfull                     : std_logic;
      empty                     : std_logic;
      full                      : std_logic;
      afull                     : std_logic;
      aempty                    : std_logic;
      data_in                   : std_logic_vector(31 downto 0);
      data_out                  : std_logic_vector(31 downto 0);   
    end record;
 
    constant RES : reg_type :=
    ( config_state           => idle,
      ram_read_cnt           => (others => '0'),  -- Initialize read counter to 0
      ram_rd_en             => '0',
      ram_rd_addr           => (others => '0'),
      ram_rd_data           => (others => '0'),  
      ram_rd_valid          => '0',
      start_preload_ram     => '0',
      data_valid            => '0',
      r_update              => '0',
      w_update              => '0',
      clr                   => '0',
      hfull                 => '0',
      empty                 => '0',
      full                  => '0',
      afull                 => '0',
      aempty                => '0',
      data_in               => (others => '0'),
      data_out              => (others => '0')
    );

      ---------------------------------------------------------------------------
  --! AHB master control record.
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_type is record
    delay   : std_logic_vector(7 downto 0);
    dbgl    : integer;
    reset   : std_logic;
    use128  : integer;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master access type record.
  ---------------------------------------------------------------------------
  type ahbtbm_access_type is record
    haddr     : std_logic_vector(31 downto 0);
    hdata     : std_logic_vector(31 downto 0);
    hdata128  : std_logic_vector(127 downto 0);
    htrans    : std_logic_vector(1 downto 0);
    hburst    : std_logic_vector(2 downto 0);
    hsize     : std_logic_vector(2 downto 0);
    hprot     : std_logic_vector(3 downto 0);
    hwrite    : std_logic;
    ctrl      : ahbtbm_ctrl_type;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master status type record
  ---------------------------------------------------------------------------
  type ahbtbm_status_type is record
    err     : std_logic;
    ecount  : std_logic_vector(15 downto 0);
    eaddr   : std_logic_vector(31 downto 0);
    edatac  : std_logic_vector(31 downto 0);
    edatar  : std_logic_vector(31 downto 0);
    hresp   : std_logic_vector(1 downto 0);
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master access array type
  ---------------------------------------------------------------------------
  type ahbtbm_access_array_type is array (0 to 1) of ahbtbm_access_type;

  ---------------------------------------------------------------------------
  --! AHB master ctrl type
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_in_type is record
    ac  : ahbtbm_access_type;
  end record;
  
  ---------------------------------------------------------------------------
  --! AHB master ctrl out type
  ---------------------------------------------------------------------------
  type ahbtbm_ctrl_out_type is record
    rst       : std_logic;
    clk       : std_logic;
    update    : std_logic;
    dvalid    : std_logic;
    hrdata    : std_logic_vector(31 downto 0);
    hrdata128 : std_logic_vector(127 downto 0);
    status    : ahbtbm_status_type;
  end record;

  --------------------------------------------------------------------------
  --! AHB ctrl type
  ---------------------------------------------------------------------------
  type ahbtb_ctrl_type is record
    i : ahbtbm_ctrl_in_type;
    o : ahbtbm_ctrl_out_type;
  end record;
  --------------------------------------------------------------------------
  --! AHB idle constant
  ---------------------------------------------------------------------------
  constant ac_idle : ahbtbm_access_type :=
    (haddr => x"00000000", hdata => x"00000000", 
     hdata128 => x"00000000000000000000000000000000", 
     htrans => "00", hburst =>"000", hsize => "000", hprot => "0000", hwrite => '0', 
     ctrl => (delay => x"00", dbgl => 100, reset =>'0', use128 => 0));

  --------------------------------------------------------------------------
  --! AHB cltr idle constant
  ---------------------------------------------------------------------------    
  constant ctrli_idle : ahbtbm_ctrl_in_type :=(ac => ac_idle);

 /*   
-----------------------------------------------------------------------------
--! Read configuration values from config record and format them as AHB data
--! This is the inverse operation of ahb_read_config_123
-----------------------------------------------------------------------------
procedure ahb_write_config_123 (
    config: in config_123_f;           -- Input: Configuration structure
    address: in std_logic_vector;      -- Input: Address to read from
    dataout: out std_logic_vector(31 downto 0);  -- Output: Formatted 32-bit data
    valid: out std_logic;              -- Output: Indicates if address is valid
    error: out std_logic               -- Output: Error flag
) is
    -- Same address mapping constants as ahb_read_config_123
    constant off0: integer := 16#0#;    -- Control/Enable register
    constant off4: integer := 16#1#;    -- External memory address
    constant off8: integer := 16#2#;    -- Image dimensions and basic params
    constant offC: integer := 16#3#;    -- Prediction and algorithm params
    constant off10: integer := 16#4#;   -- Advanced algorithm parameters
    constant off14: integer := 16#5#;   -- Encoder-specific parameters
    constant off18: integer := 16#6#;   -- Weight table (future use)
    constant off1C: integer := 16#7#;   -- Weight table (future use)
    constant off20: integer := 16#8#;   -- Weight table (future use)
    constant off24: integer := 16#9#;   -- Weight table (future use)
    constant off28: integer := 16#A#;   -- Weight table (future use)
    constant off2C: integer := 16#B#;   -- Weight table (future use)
    constant off30: integer := 16#C#;   -- Weight table (future use)
    constant off34: integer := 16#D#;   -- Weight table (future use)
    constant off38: integer := 16#E#;   -- Weight table (future use)
    constant off3C: integer := 16#F#;   -- Weight table (future use)
    constant off40: integer := 16#10#;  -- Weight table (future use)
    constant off44: integer := 16#11#;  -- Weight table (future use)
    constant off48: integer := 16#12#;  -- Weight table (future use)
    constant off4C: integer := 16#13#;  -- Weight table (future use)
    constant off50: integer := 16#14#;  -- Weight table (future use)
    constant off54: integer := 16#15#;  -- Weight table (future use)
    constant off58: integer := 16#16#;  -- Weight table (future use)
    constant off5C: integer := 16#17#;  -- Weight table (future use)
    constant off60: integer := 16#18#;  -- Weight table (future use)
    
    variable vaddress: integer;         -- Converted address
    variable temp_data: std_logic_vector(31 downto 0);  -- Temporary data assembly
    variable reserved_bits: std_logic_vector(31 downto 0);  -- For reserved bit handling
    
begin
    -- Initialize outputs
    dataout := (others => '0');
    valid := '0';
    error := '0';
    temp_data := (others => '0');
    reserved_bits := (others => '0');
    
    -- Convert address to integer
    vaddress := to_integer(unsigned(address));
    
    -- Address decoder - pack configuration data according to memory map
    case (vaddress) is
        when off0 =>
            -- Control/Enable Register (Address 0x0)
            -- Bit 0: ENABLE
            -- Bits 31:1: Reserved (set to 0)
            temp_data(config.ENABLE'high downto 0) := config.ENABLE;
            -- Reserved bits are already initialized to 0
            dataout := temp_data;
            valid := '1';
            
        when off4 =>
            -- External Memory Address Register (Address 0x4)
            -- Bits [ExtMemAddress'high:0]: External memory address
            -- Remaining bits: Reserved
            temp_data(config.ExtMemAddress'high downto 0) := config.ExtMemAddress;
            dataout := temp_data;
            valid := '1';
            
        when off8 =>
            -- Image Dimensions and Basic Parameters (Address 0x8)
            -- Bits [16+Nx'high:16]: Image width (Nx)
            -- Bits [11+D'high:11]: Dynamic range (D)
            -- Bit 10: IS_SIGNED
            -- Bit 9: DISABLE_HEADER
            -- Bits [7+ENCODER_SELECTION'high:7]: Encoder selection
            -- Bits [3+P'high:3]: Predictor parameter P
            -- Bit 2: BYPASS
            -- Bits 1:0: Reserved
            temp_data(16+config.Nx'high downto 16) := config.Nx;
            temp_data(11+config.D'high downto 11) := config.D;
            temp_data(10 downto 10) := config.IS_SIGNED;
            temp_data(9 downto 9) := config.DISABLE_HEADER;
            temp_data(7+config.ENCODER_SELECTION'high downto 7) := config.ENCODER_SELECTION;
            temp_data(3+config.P'high downto 3) := config.P;
            temp_data(2 downto 2) := config.BYPASS;
            -- Bits 1:0 remain reserved (0)
            dataout := temp_data;
            valid := '1';
            
        when offC =>
            -- Prediction and Algorithm Parameters (Address 0xC)
            -- Bits [16+Ny'high:16]: Image height (Ny)
            -- Bit 15: PREDICTION
            -- Bit 14: LOCAL_SUM
            -- Bits [9+OMEGA'high:9]: OMEGA parameter
            -- Bits [2+R'high:2]: R parameter
            -- Bits 1:0: Reserved
            temp_data(16+config.Ny'high downto 16) := config.Ny;
            temp_data(15 downto 15) := config.PREDICTION;
            temp_data(14 downto 14) := config.LOCAL_SUM;
            temp_data(9+config.OMEGA'high downto 9) := config.OMEGA;
            temp_data(2+config.R'high downto 2) := config.R;
            -- Bits 1:0 remain reserved (0)
            dataout := temp_data;
            valid := '1';
            
        when off10 =>
            -- Advanced Algorithm Parameters (Address 0x10)
            -- Bits [16+Nz'high:16]: Image depth (Nz)
            -- Bits [11+VMAX'high:11]: VMAX parameter
            -- Bits [6+VMIN'high:6]: VMIN parameter
            -- Bits [2+TINC'high:2]: TINC parameter
            -- Bit 1: WEIGHT_INIT
            -- Bit 0: ENDIANESS
            temp_data(16+config.Nz'high downto 16) := config.Nz;
            temp_data(11+config.VMAX'high downto 11) := config.VMAX;
            temp_data(6+config.VMIN'high downto 6) := config.VMIN;
            temp_data(2+config.TINC'high downto 2) := config.TINC;
            temp_data(1 downto 1) := config.WEIGHT_INIT;
            temp_data(0 downto 0) := config.ENDIANESS;
            dataout := temp_data;
            valid := '1';
            
        when off14 =>
            -- Encoder-Specific Parameters (Address 0x14)
            -- Bits [28+INIT_COUNT_E'high:28]: Initial count E
            -- Bit 27: ACC_INIT_TYPE
            -- Bits [23+ACC_INIT_CONST'high:23]: Accumulator init constant
            -- Bits [19+RESC_COUNT_SIZE'high:19]: Rescaling count size
            -- Bits [13+U_MAX'high:13]: U_MAX parameter
            -- Bits [6+W_BUFFER'high:6]: W_BUFFER parameter
            -- Bits [1+Q'high:1]: Q parameter
            -- Bit 0: WR parameter
            temp_data(28+config.INIT_COUNT_E'high downto 28) := config.INIT_COUNT_E;
            temp_data(27 downto 27) := config.ACC_INIT_TYPE;
            temp_data(23+config.ACC_INIT_CONST'high downto 23) := config.ACC_INIT_CONST;
            temp_data(19+config.RESC_COUNT_SIZE'high downto 19) := config.RESC_COUNT_SIZE;
            temp_data(13+config.U_MAX'high downto 13) := config.U_MAX;
            temp_data(6+config.W_BUFFER'high downto 6) := config.W_BUFFER;
            temp_data(1+config.Q'high downto 1) := config.Q;
            temp_data(0 downto 0) := config.WR;
            dataout := temp_data;
            valid := '1';
            
        -- Future implementation for weight tables (currently commented out)
        -- These cases are preserved for future extensibility
        -- when off18 =>
        --     -- Weight Table Entry 0
        --     temp_data(6+config.WEIGHT_TAB(0)'high downto 6) := config.WEIGHT_TAB(0);
        --     dataout := temp_data;
        --     valid := '1';
        --     
        -- when off1C =>
        --     -- Weight Table Entry 1
        --     temp_data(11+config.WEIGHT_TAB(1)'high downto 11) := config.WEIGHT_TAB(1);
        --     dataout := temp_data;
        --     valid := '1';
        --     
        -- ... (other weight table entries)
        
        when others =>
            -- Invalid address
            dataout := (others => '0');
            valid := '0';
            error := '1';
            
    end case;
    
end procedure ahb_write_config_123;
*/

end package config_pkg;