----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	system_constant_pckg.vhd
-- @ Engineer				: 	RUI YIN
-- @ Role					:	FPGA  Engineer
-- @ Company				:	IDA TUBS

-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Modelsim
-- @ Target Device			:	N/A

-- @ Revision #				: 	1

-- File Description         :	use for system top-level constant definition
--								

-- Document Number			:	TBD
----------------------------------------------------------------------------------------------------------------------------------
library ieee;			
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;	-- for extended textio functions
use ieee.math_real.all;

library std;					-- should compile by default, added just in case....
use std.textio.all;				-- for basic textio functions

library shyloc_utils;
use shyloc_utils.amba.all;        

library shyloc_121;
use shyloc_121.ccsds121_parameters.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

package system_constant_pckg is

    -- AHB Master Input initialization
    constant C_AHB_MST_IN_ZERO : AHB_Mst_In_Type := (               -- declared in amba package
        HGRANT     => '0',                    -- Single bit signal
        HREADY     => '0',                    -- Single bit signal
        HRESP      => (others => '0'),        -- 2-bit response vector
        HRDATA     => (others => '0')         -- HDMAX-width data bus
    );
    constant C_AHB_SLV_IN_ZERO : AHB_Slv_In_Type := (
        HSEL       => '0',                    -- Slave select signal
        HADDR      => (others => '0'),        -- HAMAX-width address bus
        HWRITE     => '0',                    -- Read/Write signal
        HTRANS     => (others => '0'),        -- 2-bit transfer type
        HSIZE      => (others => '0'),        -- 3-bit transfer size
        HBURST     => (others => '0'),        -- 3-bit burst type
        HWDATA     => (others => '0'),        -- HDMAX-width data bus
        HPROT      => (others => '0'),        -- 4-bit protection control
        HREADY     => '0',                    -- Transfer done signal
        HMASTER    => (others => '0'),        -- 4-bit master identifier
        HMASTLOCK  => '0'                     -- Locked access signal
    );

    -- Record type for CCSDS123 interface signals
    type CCSDS123_Interface_Type is record
        ForceStop      : std_logic;  -- Force the stop of the compression
        AwaitingConfig : std_logic;  -- IP core waiting for configuration
        Ready         : std_logic;  -- Ready to receive new samples
        FIFO_Full     : std_logic;  -- Input FIFO is full
        EOP           : std_logic;  -- Compression of last sample started
        Finished      : std_logic;  -- IP finished compressing all samples
        Error         : std_logic;  -- Error during compression
    end record;
    
    -- Array type for the CCSDS123 interface record
    type CCSDS123_Interface_Array_Type is array (natural range <>) of CCSDS123_Interface_Type;

    -- Define array types for AHB interface signals
    type AHB_Slv_In_Array_Type is array (natural range <>) of AHB_Slv_In_Type;
    type AHB_Slv_Out_Array_Type is array (natural range <>) of AHB_Slv_Out_Type;
    type AHB_Mst_In_Array_Type is array (natural range <>) of AHB_Mst_In_Type;
    type AHB_Mst_Out_Array_Type is array (natural range <>) of AHB_Mst_Out_Type;
    
    -- Define array type for DataIn
    type DataIn_Array_Type is array (natural range <>) of 
        std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    
    -- Define array type for DataOut
    type DataOut_Array_Type is array (natural range <>) of 
        std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);

end package system_constant_pckg;