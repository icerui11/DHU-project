--================================================================================================================================--
-- Engineer: Rui Yin
-- Create Date: 2025-08-21
--
-- Purpose: SpaceWire Data Assembly and FIFO Controller for SHyLoC Compressor
--
-- Description: This module receives 8-bit SpaceWire data packets and assembles them 
-- into wider data words based on D_GEN parameter for CCSDS123 compressor input
--
-- - D_GEN <= 8:  Direct pass-through 
-- - 8 < D_GEN <= 16: Assemble 2 SpW packets 
-- - 16 < D_GEN <= 24: Assemble 3 SpW packets 
-- - 24 < D_GEN <= 32: Assemble 4 SpW packets 
--================================================================================================================================--

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;
--! Use math functions
use ieee.math_real.all;

--! Use shyloc_utils for FIFO
library shyloc_utils;


library VH_compressor;
use VH_compressor.VH_ccsds121_parameters.all;

entity router_shyloc_fifo is
    generic (
        RESET_TYPE      : integer := 1;                             --! Reset type (0: async, 1: sync)
        FIFO_DEPTH      : integer := 32;                            --! FIFO depth (power of 2)
        FIFO_ADDR_WIDTH : integer := 5;                             --! FIFO address width
        TECH            : integer := 0;                             --! Technology selection
        EDAC            : integer := 0                             --! EDAC enable (0: disabled, 1: enabled)
  --      g_router_port_addr : integer range 1 to 32 := 1             --! Router port address
    );
    port (
        clk_in          : in  std_logic;                            --! Clock input
        rst_n          : in  std_logic;                            --! Reset input (active low)

        -- configuration interface
        config_s        : in config_121;                            
        
        -- Data Interface from SpW Controller 
        rx_data_in      : in  std_logic_vector(7 downto 0);         --! Data from SpW controller
        rx_data_valid   : in  std_logic;                            --! Data valid from SpW controller
        rx_data_ready   : out std_logic;                            --! Ready to receive data
        
        -- CCSDS Compressor Interface 
        ccsds_data_input  : out std_logic_vector(D_GEN-1 downto 0);   --! Output data to compressor
        ccsds_data_valid: out std_logic;                            --! Data valid signal
        ccsds_data_ready: in  std_logic;                            --! Compressor ready to receive
        
        -- Control Interface 
        enable          : in  std_logic;                            --! Module enable
        clear_fifo      : in  std_logic;                            --! Clear FIFO
        
        -- Status and Control 

        error_out       : out std_logic;                            --! Error indicator
        
        -- Debug Interface 
        debug_state     : out std_logic_vector(3 downto 0);         --! Current state for debug
        debug_byte_count: out std_logic_vector(2 downto 0)          --! Current byte count for debug
    );
end router_shyloc_fifo;

--! Architecture of router_shyloc_fifo
architecture rtl of router_shyloc_fifo is

    --! Calculate number of bytes needed based on D_GEN
    function calc_bytes_needed(d_gen : integer) return integer is
    begin
        if d_gen <= 8 then
            return 1;
        elsif d_gen <= 16 then
            return 2;
        elsif d_gen <= 24 then
            return 3;
        else
            return 4;  -- For D_GEN <= 32
        end if;
    end function;
    
    --! Constants 
    constant BYTES_NEEDED   : integer := calc_bytes_needed(to_integer(unsigned(config_s.D))-1);
    constant BYTE_COUNT_WIDTH : integer := integer(ceil(log2(real(BYTES_NEEDED + 1))));
    
   signal bytes_needed_int : integer range 1 to 4;
   signal assemble_cnt     : integer range 0 to 4 := 0;
   signal assemble_finished: std_logic := '0';
    --! State machine states 
    type assemble_state is (
        IDLE,          
        COLLECT_DATA,   
        ASSEMBLE_DATA   
    );
    --! Internal signals 
    signal assemble_state         : assemble_state := IDLE;
    signal byte_counter     : unsigned(BYTE_COUNT_WIDTH-1 downto 0) := (others => '0');
    signal data_buffer      : std_logic_vector(D_GEN-1 downto 0) := (others => '0'); -- Max 4 bytes
    signal assembled_data   : std_logic_vector(D_GEN-1 downto 0) := (others => '0');
    signal data_valid_reg   : std_logic := '0';
    signal rx_ready_reg     : std_logic := '1';
    
    --! FIFO signals FIFO信号
    signal fifo_wr_en       : std_logic := '0';
    signal fifo_rd_en       : std_logic := '0';
    signal fifo_data_in     : std_logic_vector(D_GEN-1 downto 0) := (others => '0');
    signal fifo_data_out    : std_logic_vector(D_GEN-1 downto 0);
    signal fifo_full        : std_logic;
    signal fifo_empty       : std_logic;
    signal fifo_afull       : std_logic;
    signal fifo_aempty      : std_logic;
    signal fifo_hfull       : std_logic;
    signal fifo_edac_error  : std_logic;
    
    --! Control signals 控制信号
    signal rst_n            : std_logic;
    signal error_reg        : std_logic := '0';
    
begin

    process(config_s)
    begin
       if to_integer(unsigned(config_s.D)) <= 8 then
            bytes_needed_int <= 1;
        elsif to_integer(unsigned(config_s.D)) <= 16 then
            bytes_needed_int <= 2;
        elsif to_integer(unsigned(config_s.D)) <= 24 then
            bytes_needed_int <= 3;
        else
            bytes_needed_int <= 4;  -- For D_GEN <= 32
        end if;
    end process;
    
    --! FIFO instantiation for buffering assembled data
    u_data_fifo : entity shyloc_utils.fifop2(arch)
        generic map (
            RESET_TYPE  => RESET_TYPE,
            W           => D_GEN,
            NE          => FIFO_DEPTH,
            W_ADDR      => FIFO_ADDR_WIDTH,
            EDAC        => EDAC,
            TECH        => TECH
        )
        port map (
            clk             => clk_in,
            rst_n           => rst_n,
            clr             => clear_fifo,
            w_update        => fifo_wr_en,
            r_update        => fifo_rd_en,
            hfull           => fifo_hfull,
            empty           => fifo_empty,
            full            => fifo_full,
            afull           => fifo_afull,
            aempty          => fifo_aempty,
            edac_double_error => fifo_edac_error,
            data_in         => fifo_data_in,
            data_out        => fifo_data_out
        );
    
    assemble_proc : process(clk_in)
    begin
        if rising_edge(clk_in) then 
            if rst_n = '0' then  
                assemble_cnt <= 0; 
                assemble_finished <= '0';
            else
               if rx_data_valid = '1' then 
                   if assemble_cnt < bytes_needed_int then
                       --! Collect data bytes into buffer
                       data_buffer(assemble_cnt * 8 + 7 downto assemble_cnt * 8) <= rx_data_in;
                       assemble_cnt <= assemble_cnt + 1;
                       assemble_finished <= '0';
                   else 
                       data_buffer(assemble_cnt * 8 + 7 downto assemble_cnt * 8) <= rx_data_in;
                       assemble_cnt <= 0;
                       assemble_finished <= '1';
                   end if;
                end if;
            end if;
        end if;
    end process;

    fifo_wr_en <= assemble_finished; 
    fifo_data_in <= data_buffer;
/*
    rx_assemby_proc : process(clk_in)
    begin 
        if rising_edge(clk_in) then 
            if rst_n = '0' then 
                assemble_cnt <= 0; 
                assemble_state <= IDLE;
                fifo_wr_en <= '0';
            else
                case assemble_state is
                    when IDLE =>
                        if rx_data_valid = '1' then 
                            data_buffer(7 downto 0) <= rx_data_in;
                            assemble_cnt <= 1;
                            if bytes_needed_int = 1 then 
                                assemble_state <= ASSEMBLE_DATA;
                            else
                                assemble_state <= COLLECT_DATA;
                            end if;
                        end if;
                    
                    when COLLECT_DATA =>
                        if rx_data_valid = '1' then 
                            data_buffer(assemble_cnt * 8 + 7 downto assemble_cnt * 8) <= rx_data_in;
                            assemble_cnt <= assemble_cnt + 1;
                            if assemble_cnt + 1 = bytes_needed_int then 
                                assemble_state <= ASSEMBLE_DATA;
                            end if;
                        end if;
                    
                    when ASSEMBLE_DATA =>
                        --! Assemble final data word based on D_GEN
                        case bytes_needed_int is
                            when 1 =>
                                assembled_data(D_GEN-1 downto 0) <= x"000" & data_buffer(7 downto 0);
                            when 2 =>
                                assembled_data(D_GEN-1 downto 0) <= x"00" & data_buffer(15 downto 0);
                            when 3 =>
                                assembled_data(D_GEN-1 downto 0) <= x"0" & data_buffer(23 downto 0);
                            when others => -- 4 bytes
                                assembled_data(D_GEN-1 downto 0) <= data_buffer(31 downto 0);
                        end case;
                        
                        fifo_data_in <= assembled_data(D_GEN-1 downto 0);
                        fifo_wr_en <= '1';
                        assemble_cnt <= 0;
                        assemble_state <= IDLE; -- Return to IDLE or COLLECT_DATA based on next input
                        
                    when others =>
                        assemble_state <= IDLE;
                end case;
            end if;
        end if;     
*/
    --! FIFO read control and output to compressor
    fifo_read_proc : process(clk_in)
    begin
        if rising_edge(clk_in) then
            if rst_n = '0' then
                fifo_rd_en <= '0';
                data_valid_reg <= '0';
            else      
                -- Read from FIFO when compressor is ready and FIFO has data
                if ccsds_data_ready = '1' and fifo_empty = '0' then
                    fifo_rd_en <= '1';
                    data_valid_reg <= '1';
                else
                    fifo_rd_en <= '0';
                    data_valid_reg <= '0';
                end if;
            end if;
        end if;
    end process;
    
    --! Output assignments 输出赋值
    ccsds_data_input      <= fifo_data_out;
    ccsds_data_valid    <= data_valid_reg;
    error_out           <= error_reg or fifo_edac_error;
    rx_data_ready       <= rx_ready_reg;
    

end rtl;