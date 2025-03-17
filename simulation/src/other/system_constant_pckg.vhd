----------------------------------------------------------------------------------------------------------------------------------
-- File Description  --
----------------------------------------------------------------------------------------------------------------------------------
-- @ File Name				:	system_constant_pckg.vhd
-- @ Engineer				  : RUI YIN
-- @ Role					    :	FPGA  Engineer
-- @ Company				  :	IDA TUBS
-- @ VHDL Version			:	2008
-- @ Supported Toolchain	:	Modelsim
-- @ Target Device		:	N/A
-- @ Revision #				: 2
-- @ Last Revised			:	17.03.2025
-- File Description   :	use for system top-level constant definition
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
/*
    -- Define array types for AHB interface signals
    type AHB_Mst_In_Vector  is array (Natural range <> ) of AHB_Mst_In_Type;
    type AHB_Mst_Out_Vector is array (Natural range <> ) of AHB_Mst_Out_Type;
    type AHB_Slv_In_Vector  is array (Natural range <> ) of AHB_Slv_In_Type;
    type AHB_Slv_Out_Vector is array (Natural range <> ) of AHB_Slv_Out_Type;
    --define in amba package   
    -- define AHB 3d array signal 
    type AHB_Mst_In_Vector_3d  is array (Natural range <> ) of AHB_Mst_In_Vector;
    type AHB_Mst_Out_Vector_3d is array (Natural range <> ) of AHB_Mst_Out_Vector;
    type AHB_Slv_In_Vector_3d  is array (Natural range <> ) of AHB_Slv_In_Vector;
    type AHB_Slv_Out_Vector_3d is array (Natural range <> ) of AHB_Slv_Out_Vector;
    */
    --all zero constant for AHB vector array signal (only for 3 AHB master/slave)
    constant C_AHB_MST_IN_VECTOR_ZERO : AHB_Mst_In_Vector(1 to 3) :=
    (
      others => C_AHB_MST_IN_ZERO
    );

    constant C_AHB_SLV_IN_VECTOR_ZERO : AHB_Slv_In_Vector(1 to 3) :=
    (
      others => C_AHB_SLV_IN_ZERO
    );
    -- Define array type for DataIn
    type DataIn_Array_Type is array (natural range <>) of 
        std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    
    -- Define array type for DataOut
    type DataOut_Array_Type is array (natural range <>) of 
        std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);

    type shyloc_record is record
        DataIn_shyloc      : std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
        DataIn_NewValid    : std_logic;
        DataOut            : std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);
        DataOut_NewValid   : std_logic;
        Ready_Ext          : std_logic;
        ForceStop          : std_logic;
        AwaitingConfig     : std_logic;
        Ready              : std_logic;
        FIFO_Full          : std_logic;
        EOP                : std_logic;
        Finished           : std_logic;
        Error              : std_logic;
    end record shyloc_record;

    type ccsds_datain_array is array (natural range <>) of std_logic_vector(shyloc_121.ccsds121_parameters.W_BUFFER_GEN-1 downto 0);   
    type raw_ccsds_data_array is array (natural range <>) of std_logic_vector(shyloc_123.ccsds123_parameters.D_GEN-1 downto 0);
    
    --spw router_fifo_ctrl
    type rx_cmd_out_array  is array (natural range <>) of std_logic_vector(2 downto 0);             --spw control char output bits
    type rx_data_out_array is array (natural range <>) of std_logic_vector(7 downto 0);		
    type fifo_data_array   is array (natural range <>) of std_logic_vector(7 downto 0);             --asym fifo data output to tx_data
   
end package system_constant_pckg;

/*
procedure spw_send_file_data(
    signal   spw_codec  : inout r_codec_interface;         -- define in spw_data_type
    signal   r_shyloc   : inout shyloc_record;             -- define in system_constant_type
    constant file_path  : in string;                       -- in ccsds123_tb_parameters.vhd
    constant router_port: in integer;                      -- 目标路由端口
    constant data_width : in integer;                      -- 数据位宽
    constant endianness : in integer;                      -- 端序 (0=小端, 1=大端)
    constant nx, ny, nz : in integer                       -- 图像尺寸参数
) is
    file stimulus      : character;
    variable pixel_file : character;
    variable value_high : natural;
    variable value_low  : natural;
    variable data_byte  : std_logic_vector(7 downto 0);
    variable counter_samples: unsigned (31 downto 0);
    variable route_addr : std_logic_vector(8 downto 0);
    variable s_in_var: std_logic_vector (work.ccsds123_tb_parameters.D_G_tb-1 downto 0);    
    variable ini        : std_logic := '1';
begin
    -- generate routing address
    route_addr := '0' & std_logic_vector(to_unsigned(router_port, 8));
    
    -- open file
    report "open the stim_file: " & file_path severity note;
    file_open(stimulus, file_path, read_mode);
    
    -- send path address
    wait until spw_codec.Tx_IR = '1';
    wait for clk_period;
    spw_codec.Tx_data <= route_addr;
    spw_codec.Tx_OR <= '1';
    wait for clk_period;
    spw_codec.Tx_OR <= '0';
    report "send path address: " & integer'image(router_port) severity note;
    wait for clk_period * 2;
    
    if rst_n = '0' then 
       spw_codec.Tx_data <= (others => '0');
       spw_codec.Tx_IR   <= '0';
       data_byte         := (others => '0');
       ini               := '0';
    elsif rising_edge(clk) then
        spw_codec.Tx_IR <= '0';
        if r_shyloc.Finished = '1' or r_shyloc.ForceStop = '1' then
            file_close(stimulus);
            ini := '1';
        else 
            if (ini = '1') then
                file_open(stimulus, work.ccsds123_tb_parameters.stim_file, read_mode);
                ini := '0';
              else
                if counter_samples < work.ccsds123_tb_parameters.Nz_tb*work.ccsds123_tb_parameters.Nx_tb*work.ccsds123_tb_parameters.Ny_tb + 4 then 
                    if (r_shyloc.Ready = '1' and r_shyloc.AwaitingConfig = '0' and spw_codec.Tx_OR = '1';) then
                      if (work.ccsds123_tb_parameters.EN_RUNCFG_G = 0) then
                        if (work.ccsds123_tb_parameters.D_G_tb <= 8) then
                          read(stimulus, pixel_file);
                          value_high := character'pos(pixel_file);
                          s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb)); --16 bits only
                        else
                          read(stimulus, pixel_file);
                          value_high := character'pos(pixel_file);
                          read(stimulus, pixel_file);         --16 bits only
                          value_low := character'pos(pixel_file);   --16 bits only
                          if (work.ccsds123_tb_parameters.ENDIANESS_tb = 0) then
                            s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, work.ccsds123_tb_parameters.D_G_tb-8));
                          else
                            s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb-8))   --16 bits only
                            & std_logic_vector(to_unsigned(value_low, 8));                          --16 bits only
                          end if;
                        end if;
                      else
                        if (work.ccsds123_tb_parameters.D_tb <= 8) then
                          read(stimulus, pixel_file);
                          value_high := character'pos(pixel_file);
                          if (work.ccsds123_tb_parameters.D_G_tb = 16) then
                            s_in_var := "00000000" & std_logic_vector(to_unsigned(value_high, 8)); --16 bits only
                          else
                            s_in_var := std_logic_vector(to_unsigned(value_low, 8));        --16 bits only
                          end if;
                        else
                          read(stimulus, pixel_file);
                          value_high := character'pos(pixel_file);
                          read(stimulus, pixel_file);       --16 bits only
                          value_low := character'pos(pixel_file); --16 bits only
                          if (work.ccsds123_tb_parameters.ENDIANESS_tb = 0) then
                            s_in_var :=  std_logic_vector(to_unsigned(value_high, 8)) & std_logic_vector(to_unsigned(value_low, work.ccsds123_tb_parameters.D_G_tb-8));
                          else
                            s_in_var := std_logic_vector(to_unsigned(value_high, work.ccsds123_tb_parameters.D_G_tb-8)) --16 bits only
                            & std_logic_vector(to_unsigned(value_low, 8)); --16 bits only
                          end if;
                        end if;
                      end if;                                          
                    spw_codec.Tx_IR <= '1';
                    end if;
                    if (spw_codec.Tx_IR = '1' and spw_codec.Tx_OR = '1') then
                        spw_codec.Tx_IR <= '0';
                        counter_samples <= counter_samples+1;
                        s_valid <= '1';
                    end if;
                  else
                    s_valid <= '0';
                    spw_codec.Tx_OR <= '0';
                  end if;
                else
                  s_valid <= '0';
                  spw_codec.Tx_OR <= '0';
                end if;
              end if;
            end if;
          end if;

    -- read file and sent it via spw
    while not endfile(stimulus) and pixel_count < nx*ny*nz loop
        -- 读取一个字节的数据
        read(stimulus, pixel_char);
        value_high := character'pos(pixel_char);
        
        -- 如果数据宽度大于8位，需要读取第二个字节
        if data_width > 8 then
            read(stimulus, pixel_char);
            value_low := character'pos(pixel_char);
            
            -- 根据端序设置要发送的第一个字节
            if endianness = 0 then  -- 小端序
                data_byte := std_logic_vector(to_unsigned(value_high, 8));
            else  -- 大端序
                data_byte := std_logic_vector(to_unsigned(value_low, 8));
            end if;
        else
            -- 8位或更少的数据
            data_byte := std_logic_vector(to_unsigned(value_high, 8));
        end if;
        
        -- 等待SpaceWire准备好接收数据
        if spw_codec.Tx_IR = '0' then
            wait until spw_codec.Tx_IR = '1';
        end if;
        
        -- 发送第一个字节
        wait for clk_period;
        spw_codec.Tx_data <= '0' & data_byte;  -- 非控制字符
        spw_codec.Tx_OR <= '1';
        wait for clk_period;
        spw_codec.Tx_OR <= '0';
        
        -- 如果数据宽度大于8位，发送第二个字节
        if data_width > 8 then
            -- 准备第二个字节
            if endianness = 0 then  -- 小端序
                data_byte := std_logic_vector(to_unsigned(value_low, 8));
            else  -- 大端序
                data_byte := std_logic_vector(to_unsigned(value_high, 8));
            end if;
            
            -- 等待SpW准备好
            if spw_codec.Tx_IR = '0' then
                wait until spw_codec.Tx_IR = '1';
            end if;
            
            -- 发送第二个字节
            wait for clk_period;
            spw_codec.Tx_data <= '0' & data_byte;
            spw_codec.Tx_OR <= '1';
            wait for clk_period;
            spw_codec.Tx_OR <= '0';
        end if;
        
        -- 计数并适时等待
        pixel_count := pixel_count + 1;
        if pixel_count mod 100 = 0 then
            report "已发送 " & integer'image(pixel_count) & " 像素" severity note;
            wait for clk_period * 10;
        else
            wait for clk_period * 2;
        end if;
    end loop;
    
    -- send EOP packet
    wait until spw_codec.Tx_IR = '1';
    wait for clk_period;
    spw_codec.Tx_data <= "100000010";  -- EOP
    spw_codec.Tx_OR <= '1';
    wait for clk_period;
    spw_codec.Tx_OR <= '0';
    report "transmit finish, send EOP" severity note;
    
    -- 关闭文件
    file_close(stimulus);
end procedure spw_send_file_data;

spw_send_file_data(
    spw_codec    => codecs(1),    
    r_shyloc     => r_shyloc,           
    file_path    =  work.ccsds123_tb_parameters.stim_file,        
    router_port  => 5,                       
    data_width   => work.ccsds123_tb_parameters.D_tb,                      
    endianness   => work.ccsds123_tb_parameters.ENDIANESS_tb,                       
    nx           => work.ccsds123_tb_parameters.Nx_tb,                      
    ny           => work.ccsds123_tb_parameters.Ny_tb,                      
    nz           => work.ccsds123_tb_parameters.Nz_tb                        
);

procedure read_pixel_data(
  file     bin_file      : character;
  variable data_out      : out std_logic_vector(work.ccsds123_tb_parameters.D_G_tb-1 downto 0);
  constant data_width    : in integer;
  constant endianness    : in integer
) is
  variable pixel_file    : character;
  variable value_high    : natural;
  variable value_low     : natural;
begin
  -- read data depending on data width
  if data_width <= 8 then
    -- single byte data
    read(bin_file, pixel_file);
    value_high := character'pos(pixel_file);
    data_out := std_logic_vector(to_unsigned(value_high, data_width));
  else
    -- 处理多字节数据并应用正确的字节序
    read(bin_file, pixel_file);
    value_high := character'pos(pixel_file);
    read(bin_file, pixel_file);
    value_low := character'pos(pixel_file);
    
    if endianness = 0 then
      -- 小端序
      data_out := std_logic_vector(to_unsigned(value_high, 8)) & 
                 std_logic_vector(to_unsigned(value_low, data_width-8));
    else
      -- 大端序
      data_out := std_logic_vector(to_unsigned(value_high, data_width-8)) & 
                 std_logic_vector(to_unsigned(value_low, 8));
    end if;
  end if;
end procedure;

*/